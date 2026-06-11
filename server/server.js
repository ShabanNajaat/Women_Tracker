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


// Audio Upload Route
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
