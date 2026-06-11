const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const http = require('http');
const { initSocket } = require('./socket');

dotenv.config({ path: path.join(__dirname, '.env') });
if (!process.env.JWT_SECRET) console.error('CRITICAL: JWT_SECRET missing from .env');
else console.log('Environment variables loaded successfully');


const mongoose = require('mongoose');
const db = require('./db');

// Database Connection
const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/glow_wellness';
let lastMongoError = '';
function maskMongoUri(uri) {
    return String(uri).replace(/:([^:@/]+)@/, ':***@');
}

const mongoOptions = {
    serverSelectionTimeoutMS: 20000,
    family: 4,
};

function connectMongo() {
    if (mongoose.connection.readyState === 1) return Promise.resolve();
    return mongoose.connect(mongoUri, mongoOptions).then(async () => {
        lastMongoError = '';
        console.log(`✓ MongoDB connected: ${maskMongoUri(mongoUri)}`);
        try {
            await db.seedAmaIfEmpty();
        } catch (e) {
            console.warn('[ama] seed skipped:', e?.message || e);
        }
    });
}

function scheduleMongoRetries() {
    const delays = [15000, 30000, 60000, 120000];
    delays.forEach((ms) => {
        setTimeout(() => {
            if (mongoose.connection.readyState === 1) return;
            console.log(`[mongo] retrying connection in background (${ms / 1000}s)...`);
            connectMongo().catch((err) => {
                lastMongoError = err?.message || String(err);
                console.log('[mongo] retry failed:', lastMongoError);
            });
        }, ms);
    });
}

function mountWebApp() {
    const webDir = path.join(__dirname, 'public');
    const indexHtml = path.join(webDir, 'index.html');
    const adminHtml = path.join(webDir, 'admin.html');
    // Serve static files (css, js, icons etc.)
    app.use(express.static(webDir, { maxAge: process.env.NODE_ENV === 'production' ? '1h' : 0 }));
    // Explicit admin page route – must come BEFORE the catch-all
    if (fs.existsSync(adminHtml)) {
        app.get('/admin', (req, res) => res.sendFile(adminHtml));
        console.log('Admin dashboard available at /admin');
    }
    if (!fs.existsSync(indexHtml)) return false;
    app.get(/^(?!\/api\/|\/uploads\/|\/admin).*/, (req, res) => {
        res.sendFile(indexHtml);
    });
    console.log(`Serving Flutter web from ${webDir}`);
    return true;
}

function startHttpServer() {
    const host = process.env.HOST || '0.0.0.0';
    mountWebApp();
    
    const server = http.createServer(app);
    initSocket(server);
    
    server.listen(PORT, host, () => {
        const mode = mongoose.connection.readyState === 1 ? 'MongoDB' : 'in-memory fallback';
        console.log(`Server running on http://${host}:${PORT} (${mode})`);
    });
}

connectMongo()
  .then(() => startHttpServer())
  .catch((err) => {
      lastMongoError = err?.message || String(err);
      console.log('--- PRESENTATION SAFE MODE ACTIVATED ---');
      console.log(`MongoDB not reachable (${maskMongoUri(mongoUri)}).`);
      console.log(lastMongoError);
      console.log('Falling back to in-memory store + server/data/memory_users.json for auth.');
      scheduleMongoRetries();
      startHttpServer();
  });

const multer = require('multer');
const fs = require('fs');

const app = express();

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

// Multer Storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}.m4a`)
});
const upload = multer({ storage });

// Middleware — production: set CORS_ORIGIN=https://your-app.netlify.app (comma-separated for several)
const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((s) => s.trim()).filter(Boolean)
    : null;
app.use(cors({
    origin: corsOrigins && corsOrigins.length ? corsOrigins : true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-token'],
}));
app.use(express.json({ limit: '2mb' }));
app.use('/uploads', express.static(uploadDir));

const chatRouter = require('./routes/chat');

app.get('/api/health', (req, res) => {
    const connected = mongoose.connection.readyState === 1;
    const body = {
        ok: true,
        mongo: connected,
        env: process.env.NODE_ENV || 'development',
        chat: typeof chatRouter.getChatAiStatus === 'function' ? chatRouter.getChatAiStatus() : {},
    };
    if (!connected && lastMongoError) {
        body.mongoError = lastMongoError;
    }
    if (!connected && process.env.NODE_ENV === 'production') {
        body.mongoHost = maskMongoUri(mongoUri).replace(/^mongodb(\+srv)?:\/\//, '').split('/')[0];
    }
    res.json(body);
});


// ── Developer Admin Dashboard (private – not linked from app) ──────────────
app.get('/admin', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Glow Wellness — Developer Dashboard</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0d0d1a;color:#e8e0f0;min-height:100vh}
    .login-wrap{display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px}
    .login-card{background:linear-gradient(135deg,#1a1030 0%,#0d1a2e 100%);border:1px solid rgba(255,120,200,.18);border-radius:20px;padding:48px 40px;width:100%;max-width:420px;box-shadow:0 20px 60px rgba(0,0,0,.5)}
    .logo{font-size:48px;text-align:center;margin-bottom:12px}
    h1{text-align:center;font-size:22px;font-weight:700;color:#ff8fc8;margin-bottom:6px}
    p.sub{text-align:center;color:#9980b0;font-size:14px;margin-bottom:32px}
    label{display:block;font-size:13px;color:#bb90d0;margin-bottom:6px;font-weight:600}
    input[type=password]{width:100%;padding:12px 16px;background:rgba(255,255,255,.05);border:1px solid rgba(255,120,200,.25);border-radius:10px;color:#e8e0f0;font-size:15px;outline:none;transition:border-color .2s}
    input:focus{border-color:#ff8fc8}
    .err{color:#ff6b6b;font-size:13px;margin-top:8px;display:none}
    .btn{width:100%;margin-top:24px;padding:13px;font-size:16px;font-weight:700;background:linear-gradient(90deg,#e040a0,#9b40e0);border:none;border-radius:10px;color:#fff;cursor:pointer;transition:opacity .2s}
    .btn:hover{opacity:.88}
    .btn:disabled{opacity:.5;cursor:default}
    #dashboard{display:none}
    .nav{background:linear-gradient(90deg,#1a0830,#0a1420);border-bottom:1px solid rgba(255,120,200,.15);padding:16px 32px;display:flex;align-items:center;gap:16px}
    .nav-logo{font-size:24px}
    .nav-title{font-size:18px;font-weight:700;color:#ff8fc8;flex:1}
    .nav-badge{background:rgba(255,120,200,.15);border:1px solid rgba(255,120,200,.3);border-radius:20px;padding:4px 14px;font-size:13px;color:#ff8fc8}
    .logout-btn{background:rgba(255,50,50,.15);border:1px solid rgba(255,50,50,.3);border-radius:8px;color:#ff8080;padding:6px 14px;font-size:13px;cursor:pointer}
    .container{max-width:1100px;margin:0 auto;padding:32px 24px}
    .stats-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;margin-bottom:32px}
    .stat-card{background:linear-gradient(135deg,#1a1030,#0d1a2e);border:1px solid rgba(255,120,200,.15);border-radius:14px;padding:20px 24px}
    .stat-label{font-size:13px;color:#9980b0;margin-bottom:6px;font-weight:600}
    .stat-value{font-size:36px;font-weight:800;color:#ff8fc8}
    .stat-sub{font-size:13px;color:#7060a0;margin-top:4px}
    .tabs{display:flex;gap:8px;margin-bottom:20px}
    .tab-btn{padding:9px 20px;border-radius:8px;border:1px solid rgba(255,120,200,.25);background:transparent;color:#9980b0;cursor:pointer;font-size:14px;font-weight:600;transition:all .2s}
    .tab-btn.active{background:rgba(255,120,200,.15);color:#ff8fc8;border-color:#ff8fc8}
    .tab-pane{display:none}
    .tab-pane.active{display:block}
    table{width:100%;border-collapse:collapse}
    thead th{text-align:left;font-size:12px;color:#9980b0;font-weight:700;text-transform:uppercase;letter-spacing:.08em;padding:12px 16px;border-bottom:1px solid rgba(255,120,200,.12)}
    tbody tr{border-bottom:1px solid rgba(255,255,255,.05);transition:background .15s}
    tbody tr:hover{background:rgba(255,120,200,.05)}
    tbody td{padding:14px 16px;font-size:14px}
    .avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#e040a0,#9b40e0);display:inline-flex;align-items:center;justify-content:center;font-size:14px;font-weight:700;color:#fff;margin-right:10px}
    .user-cell{display:flex;align-items:center}
    .stars{color:#fbbf24;font-size:16px}
    .muted{color:#7060a0;font-size:13px}
    .section-card{background:linear-gradient(135deg,#1a1030,#0d1a2e);border:1px solid rgba(255,120,200,.12);border-radius:16px;overflow:hidden}
    .section-header{padding:20px 24px;border-bottom:1px solid rgba(255,120,200,.12)}
    .section-header h2{font-size:16px;font-weight:700;color:#e8e0f0}
    .empty{text-align:center;padding:48px;color:#7060a0}
    .spinner{border:3px solid rgba(255,120,200,.2);border-top:3px solid #ff8fc8;border-radius:50%;width:32px;height:32px;animation:spin .8s linear infinite;margin:0 auto}
    @keyframes spin{to{transform:rotate(360deg)}}
  </style>
</head>
<body>
<div class="login-wrap" id="loginScreen">
  <div class="login-card">
    <div class="logo">🌸</div>
    <h1>Glow Wellness</h1>
    <p class="sub">Developer Dashboard — Private Access Only</p>
    <label for="adminKey">Admin Password</label>
    <input type="password" id="adminKey" placeholder="Enter admin password"/>
    <div class="err" id="loginErr"></div>
    <button class="btn" id="loginBtn" onclick="doLogin()">Access Dashboard</button>
  </div>
</div>
<div id="dashboard">
  <div class="nav">
    <span class="nav-logo">🌸</span>
    <span class="nav-title">Glow Wellness — Developer Dashboard</span>
    <span class="nav-badge" id="navBadge">Loading...</span>
    <button class="logout-btn" onclick="logout()">Log Out</button>
  </div>
  <div class="container">
    <div class="stats-row">
      <div class="stat-card"><div class="stat-label">Total Users</div><div class="stat-value" id="statUsers">–</div><div class="stat-sub">Registered accounts</div></div>
      <div class="stat-card"><div class="stat-label">Total Ratings</div><div class="stat-value" id="statRatings">–</div><div class="stat-sub">App reviews submitted</div></div>
      <div class="stat-card"><div class="stat-label">Average Rating</div><div class="stat-value" id="statAvg">–</div><div class="stat-sub">out of 5 stars</div></div>
    </div>
    <div class="tabs">
      <button class="tab-btn active" onclick="switchTab('users',this)">👤 Users</button>
      <button class="tab-btn" onclick="switchTab('ratings',this)">⭐ Ratings</button>
    </div>
    <div class="section-card">
      <div class="section-header"><h2 id="sectionTitle">Registered Users</h2></div>
      <div class="tab-pane active" id="tab-users"><div id="usersContent" style="padding:32px;text-align:center"><div class="spinner"></div></div></div>
      <div class="tab-pane" id="tab-ratings"><div id="ratingsContent" style="padding:32px;text-align:center"><div class="spinner"></div></div></div>
    </div>
  </div>
</div>
<script>
let adminKey='';
async function doLogin(){
  const key=document.getElementById('adminKey').value.trim();
  const btn=document.getElementById('loginBtn');
  const err=document.getElementById('loginErr');
  if(!key)return;
  btn.disabled=true;btn.textContent='Verifying...';err.style.display='none';
  try{
    const res=await fetch('/api/admin/dashboard',{headers:{'x-admin-key':key}});
    if(res.ok){
      adminKey=key;
      const data=await res.json();
      document.getElementById('loginScreen').style.display='none';
      document.getElementById('dashboard').style.display='block';
      renderDashboard(data);
    }else{
      err.textContent='Invalid admin password. Please try again.';
      err.style.display='block';
    }
  }catch(e){
    err.textContent='Network error. Make sure the server is reachable.';
    err.style.display='block';
  }
  btn.disabled=false;btn.textContent='Access Dashboard';
}
function renderDashboard(data){
  const users=data.users||[];
  const ratings=data.ratings||[];
  document.getElementById('statUsers').textContent=users.length;
  document.getElementById('statRatings').textContent=ratings.length;
  const avg=ratings.length?(ratings.reduce((s,r)=>s+(r.stars||0),0)/ratings.length).toFixed(1):'–';
  document.getElementById('statAvg').textContent=avg;
  document.getElementById('navBadge').textContent=users.length+' Users';
  if(users.length===0){
    document.getElementById('usersContent').innerHTML='<div class="empty">No registered users yet.</div>';
  }else{
    let html='<table><thead><tr><th>Username</th><th>Email</th><th>Joined</th></tr></thead><tbody>';
    users.forEach(u=>{
      const init=(u.username||'?')[0].toUpperCase();
      const date=u.createdAt?new Date(u.createdAt).toLocaleDateString():'–';
      html+=\`<tr><td><div class="user-cell"><div class="avatar">\${init}</div>\${u.username||'–'}</div></td><td class="muted">\${u.email||'–'}</td><td class="muted">\${date}</td></tr>\`;
    });
    html+='</tbody></table>';
    document.getElementById('usersContent').innerHTML=html;
  }
  if(ratings.length===0){
    document.getElementById('ratingsContent').innerHTML='<div class="empty">No ratings submitted yet.</div>';
  }else{
    let html='<table><thead><tr><th>User</th><th>Stars</th><th>Feedback</th><th>Date</th></tr></thead><tbody>';
    ratings.forEach(r=>{
      const uname=r.user?.username||'Deleted User';
      const init=uname[0].toUpperCase();
      const stars='★'.repeat(r.stars||0)+'☆'.repeat(5-(r.stars||0));
      const date=r.createdAt?new Date(r.createdAt).toLocaleDateString():'–';
      html+=\`<tr><td><div class="user-cell"><div class="avatar">\${init}</div>\${uname}</div></td><td><span class="stars">\${stars}</span></td><td>\${r.feedback||'<span class="muted">No comment</span>'}</td><td class="muted">\${date}</td></tr>\`;
    });
    html+='</tbody></table>';
    document.getElementById('ratingsContent').innerHTML=html;
  }
}
function switchTab(tab,btn){
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  document.querySelectorAll('.tab-pane').forEach(p=>p.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('tab-'+tab).classList.add('active');
  document.getElementById('sectionTitle').textContent=tab==='users'?'Registered Users':'App Ratings';
}
function logout(){
  adminKey='';
  document.getElementById('dashboard').style.display='none';
  document.getElementById('loginScreen').style.display='flex';
  document.getElementById('adminKey').value='';
}
document.addEventListener('DOMContentLoaded',()=>{
  document.getElementById('adminKey').addEventListener('keydown',e=>{if(e.key==='Enter')doLogin();});
});
</script>
</body>
</html>`);
});

app.post('/api/tracking/upload-voice', upload.single('audio'), (req, res) => {
    if (!req.file) return res.status(400).json({ msg: 'No file uploaded' });
    res.json({ filePath: `/uploads/${req.file.filename}` });
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/tracking', require('./routes/tracking'));
app.use('/api/partner', require('./routes/partner'));
app.use('/api/chat', chatRouter);
app.use('/api/community', require('./routes/community'));
app.use('/api/ama', require('./routes/ama'));
app.use('/api/forecast', require('./routes/forecast'));
app.use('/api/friends', require('./routes/friends'));
app.use('/api/admin', require('./routes/admin'));

const PORT = Number(process.env.PORT) || 8081;
