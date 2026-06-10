# Host Glow Wellness live

Two options:

| Option | Best for | App URL | API URL |
|--------|----------|---------|---------|
| **A — Netlify + Render** | Easiest, free tiers | `https://your-app.netlify.app` | `https://your-api.onrender.com` |
| **B — Render only** | One URL, one service | `https://your-api.onrender.com` | same host `/api` |

---

## Before you deploy

1. **MongoDB Atlas** — cluster running, IP allow list includes `0.0.0.0/0` (or Render’s IPs).
2. **Secrets ready** (never commit these):
   - `MONGO_URI` / `MONGODB_URI`
   - `JWT_SECRET` (long random string)
   - `GOOGLE_CLIENT_ID` (Web client)
   - `OPENAI_API_KEY` (optional, for Dr. Najaat AI)

---

## Option A — Netlify (app) + Render (API) — recommended

### 1. Deploy API on Render

1. Push this project to **GitHub**.
2. Go to [render.com](https://render.com) → **New** → **Web Service** → connect the repo.
3. Settings:
   - **Root directory:** `server`
   - **Build command:** `npm install`
   - **Start command:** `npm start`
   - **Health check path:** `/api/health`
4. **Environment variables:**

   | Key | Value |
   |-----|--------|
   | `NODE_ENV` | `production` |
   | `JWT_SECRET` | your long secret |
   | `MONGO_URI` | your Atlas `mongodb://` or `mongodb+srv://` URI |
   | `GOOGLE_CLIENT_ID` | `….apps.googleusercontent.com` |
   | `OPENAI_API_KEY` | your key (optional) |
   | `CORS_ORIGIN` | `https://YOUR-SITE.netlify.app` (after step 2) |

5. Deploy. Copy your API URL, e.g. `https://glow-wellness-api.onrender.com`.

6. Test: open `https://YOUR-API.onrender.com/api/health` → should show `"ok": true`.

### 2. Build Flutter for production

In PowerShell:

```powershell
cd "c:\Users\ADMIN\Desktop\WOMEN TRACKER"
.\scripts\build-for-live.ps1 -ApiUrl "https://YOUR-API.onrender.com/api"
```

### 3. Deploy app on Netlify

1. [netlify.com](https://www.netlify.com) → **Add new site** → **Deploy manually**.
2. Drag the folder `glow_mobile\build\web` onto the page.
3. Copy your site URL, e.g. `https://glow-wellness.netlify.app`.
4. Install guide (share with users): `https://YOUR-SITE.netlify.app/install.html`
5. Privacy policy: `https://YOUR-SITE.netlify.app/privacy.html`

### 4. Finish CORS + Google Sign-In

1. **Render** → your service → **Environment** → set  
   `CORS_ORIGIN` = `https://YOUR-SITE.netlify.app` → **Save** (redeploy if needed).
2. **Google Cloud Console** → Credentials → your **Web** OAuth client:
   - **Authorized JavaScript origins:**  
     `https://YOUR-SITE.netlify.app`
   - **Authorized redirect URIs:**  
     `https://YOUR-SITE.netlify.app`
3. Update `glow_mobile/web/index.html` meta `google-signin-client_id` if you change client ID, then rebuild and redeploy Netlify.

---

## Option B — Single Render service (app + API)

### 1. Build and copy web into the server

```powershell
cd "c:\Users\ADMIN\Desktop\WOMEN TRACKER"
.\scripts\build-for-live.ps1 -CopyToServer
```

This fills `server/public/` with the Flutter build. The API serves it at `/` and `/api/*`.

### 2. Deploy on Render

Same as Option A step 1, but after build you can deploy from GitHub (include `server/public` in the repo) or use Render with the files present.

Environment variables: same as Option A, but **omit** `CORS_ORIGIN` (same origin) or set it to your Render URL.

### 3. Google OAuth

Use your Render URL in Google Console origins, e.g. `https://glow-wellness-api.onrender.com`.

---

## After go-live

- Sign up / sign in on the **live** URL (not localhost).
- Each user’s data is stored under their account in MongoDB when Atlas is connected.
- Render free tier sleeps after ~15 min idle — first request may be slow.

---

## Quick commands

```powershell
# API locally
cd server
node server.js

# Production web build (Netlify)
.\scripts\build-for-live.ps1 -ApiUrl "https://YOUR-API.onrender.com/api"

# Android app (APK for your phone) — see BUILD_ANDROID_APP.md
.\scripts\build-android-app.ps1 -ApiUrl "https://women-tracker.onrender.com/api"

# All-in-one Render
.\scripts\build-for-live.ps1 -CopyToServer
```
