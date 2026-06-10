# Publish Glow Wellness on Google Play & Apple App Store

This guide turns your Flutter project into **installable store apps** (not just a website).

| Store | Cost | You need |
|-------|------|----------|
| **Google Play** | $25 one-time | Windows PC + Android Studio |
| **Apple App Store** | $99/year | **Mac** + Xcode + Apple Developer account |

**App ID (both stores):** `com.glowwellness.app`  
**Live API:** `https://women-tracker.onrender.com/api`  
**Privacy policy URL (required):** host `glow_mobile/web/privacy.html` — e.g. `https://tubular-pixie-00c69b.netlify.app/privacy.html` after you add it to Netlify (see step 0).

---

## Step 0 — Privacy policy on the web (required by both stores)

1. Rebuild and redeploy Netlify, **or** upload only `glow_mobile/web/privacy.html` to your site root.
2. Confirm it opens: `https://tubular-pixie-00c69b.netlify.app/privacy.html`
3. Use that URL in Play Console and App Store Connect.

---

## Part A — Google Play Store (Android)

### A1. Developer account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay **$25** (one-time) and complete developer profile.

### A2. Install tools on your PC

1. [Android Studio](https://developer.android.com/studio)
2. In terminal:

```powershell
flutter doctor --android-licenses
flutter doctor
```

All checks should pass for Android.

### A3. Create upload keystore (one time, keep safe!)

```powershell
cd "C:\Users\ADMIN\Desktop\WOMEN TRACKER"
.\scripts\create-android-keystore.ps1
```

Follow prompts. **Back up** `glow_mobile\android\keystore\glow-upload-keystore.jks` and passwords — you need the same key for every update.

### A4. Configure signing

```powershell
copy glow_mobile\android\key.properties.example glow_mobile\android\key.properties
```

Edit `glow_mobile\android\key.properties` with your real passwords and paths.

### A5. Firebase / Google Sign-In (Android)

1. [Firebase Console](https://console.firebase.com) → project **glow-wellness-68460**
2. **Add app** → Android → package name: **`com.glowwellness.app`**
3. Download new `google-services.json` → replace `glow_mobile/android/app/google-services.json`

4. Get **SHA-1** of your **upload** keystore:

```powershell
cd glow_mobile\android
keytool -list -v -keystore keystore\glow-upload-keystore.jks -alias glow-upload
```

5. [Google Cloud](https://console.cloud.google.com) → Credentials → **OAuth Android client**
   - Package: `com.glowwellness.app`
   - SHA-1: from step above

Email login works without Google; Google login needs this.

### A6. Build Play Store bundle (.aab)

```powershell
.\scripts\build-play-store.ps1
```

Output:

```text
glow_mobile\build\app\outputs\bundle\release\app-release.aab
```

### A7. Upload to Play Console

1. **Create app** → name **Glow Wellness**
2. **Release** → **Production** (or Internal testing first)
3. Upload **app-release.aab**
4. Fill required forms:
   - **Privacy policy URL**
   - **App category:** Health & fitness
   - **Content rating** questionnaire
   - **Data safety** (health data, account email, etc.)
   - **Screenshots** (phone): at least 2 from the app
5. Submit for review (often 1–7 days).

---

## Part B — Apple App Store (iPhone / iPad)

**You must use a Mac** for the final upload. (Borrow a Mac, use MacinCloud, or a school lab.)

### B1. Apple Developer Program

1. [developer.apple.com](https://developer.apple.com) → enroll (**$99/year**)

### B2. On the Mac

```bash
cd glow_mobile
flutter pub get
flutter build ios --release --dart-define=API_BASE_URL=https://women-tracker.onrender.com/api
open ios/Runner.xcworkspace
```

In **Xcode**:

1. Select **Runner** → **Signing & Capabilities**
2. Team: your Apple Developer team
3. Bundle ID: **`com.glowwellness.app`** (must match project)
4. **Product** → **Archive** → **Distribute App** → **App Store Connect**

### B3. App Store Connect

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **New App** → iOS → name **Glow Wellness** → bundle ID `com.glowwellness.app`
3. Privacy policy URL, screenshots, description, age rating
4. Submit build from Xcode for review

### B4. Google Sign-In on iOS

Add **iOS OAuth client** in Google Cloud with bundle ID `com.glowwellness.app`.

---

## What users get

- **Play Store:** search “Glow Wellness” → Install  
- **App Store:** same on iPhone  
- App talks to your **Render API** and **MongoDB** (same as the website)

---

## Checklist before submit

- [ ] API live: `https://women-tracker.onrender.com/api/health` → `mongo: true`
- [ ] `OPENAI_API_KEY` on Render (for chat)
- [ ] Privacy policy URL public
- [ ] App ID `com.glowwellness.app` on both platforms
- [ ] Store screenshots (1080×1920 or similar)
- [ ] Short description + full description written
- [ ] Test sign-up, login, chat on a real phone

---

## Quick commands

```powershell
# Play Store bundle
.\scripts\build-play-store.ps1

# Test APK on your phone (before store)
.\scripts\build-android-app.ps1

# Web (Netlify) — include privacy.html in deploy
.\scripts\build-for-live.ps1 -ApiUrl "https://women-tracker.onrender.com/api"
```

---

## Help

- **Play rejected?** Read the email — often missing privacy policy, data safety, or `com.example` package (we fixed to `com.glowwellness.app`).
- **No Mac for iOS?** Ship **Android first** on Play Store; add iOS when you have Mac access.
