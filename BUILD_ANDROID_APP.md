# Glow Wellness — Android app (install on your phone)

**For Google Play & App Store:** see **[STORE_RELEASE.md](STORE_RELEASE.md)** in the project root.

Your project is already a **Flutter app**. The website on Netlify is the web build; this guide builds the **Android APK** you install like any other app.

---

## 1. Build the APK (on your PC)

PowerShell:

```powershell
cd "C:\Users\ADMIN\Desktop\WOMEN TRACKER"
.\scripts\build-android-app.ps1
```

Default API: `https://women-tracker.onrender.com/api`

Output file:

```text
glow_mobile\build\app\outputs\flutter-apk\app-release.apk
```

---

## 2. Install on your phone

1. Copy `app-release.apk` to the phone (USB, Google Drive, WhatsApp, etc.).
2. Open the file on the phone → **Install**.
3. If Android blocks it: **Settings → Security → Install unknown apps** → allow your file manager or browser.

Open **Glow Wellness** — sign in — use Chat, Calendar, etc. (needs internet for the API).

---

## 3. Google Sign-In on the phone (optional)

Native Google login needs your app’s **SHA-1** in Google Cloud:

```powershell
cd "C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile\android"
.\gradlew signingReport
```

Copy **SHA-1** under `Variant: debug` (release build uses debug signing until you add a release keystore).

1. [Google Cloud Console](https://console.cloud.google.com) → **APIs & Services → Credentials**
2. **Create credentials → OAuth client ID → Android**
3. Package name: `com.example.glow_mobile`
4. Paste SHA-1 → Save

Email/password login works without this step.

---

## 4. Play Store (later)

1. Create a **release keystore** (one-time).
2. Configure signing in `android/app/build.gradle.kts`.
3. Run `flutter build appbundle --release` for Google Play upload.

For a class project or friends, the **APK** above is enough.

---

## 5. iPhone (needs a Mac)

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://women-tracker.onrender.com/api
```

Then open `ios/Runner.xcworkspace` in Xcode and archive for TestFlight/App Store.

---

## Quick checklist

| Step | Done? |
|------|--------|
| Render API live (`/api/health` → mongo true) | |
| `OPENAI_API_KEY` on Render (for chat) | |
| Built APK with `build-android-app.ps1` | |
| Installed on phone | |
| Signed in on the app | |
