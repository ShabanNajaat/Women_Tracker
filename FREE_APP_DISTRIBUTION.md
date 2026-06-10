# Distribute Glow Wellness for FREE (no Play Store / App Store fees)

Official stores cost money:

| Store | Cost |
|-------|------|
| Google Play | **$25** one-time |
| Apple App Store | **$99/year** |

You can still give people a **real app experience** on their phone **without paying** those fees.

---

## Option 1 — Install from the web (best, $0) ✅ You already have this

**Link:** https://tubular-pixie-00c69b.netlify.app  
**Install guide:** https://tubular-pixie-00c69b.netlify.app/install.html

### Android (Chrome)

1. Open the link on the phone  
2. Menu (⋮) → **Install app** or **Add to Home screen**  
3. **Glow** icon appears on the home screen — opens full screen like an app  

### iPhone (Safari)

1. Open the link in **Safari** (not Chrome)  
2. Share button → **Add to Home Screen**  
3. Tap **Glow Wellness** on the home screen  

**Cost:** $0 (Netlify free tier + Render free tier you already use)  
**Works for:** classmates, friends, portfolio — share the link or a QR code  

After code changes, rebuild and redeploy Netlify:

```powershell
.\scripts\build-for-live.ps1 -ApiUrl "https://women-tracker.onrender.com/api"
```

Then upload `glow_mobile\build\web` again.

---

## Option 2 — Free APK file (Android only, $0)

Build an install file **without** Google Play:

```powershell
.\scripts\build-android-app.ps1
```

File: `glow_mobile\build\app\outputs\flutter-apk\app-release.apk`

**Share for free via:**

- WhatsApp / Telegram  
- Google Drive (set link to “Anyone with link”)  
- GitHub Releases (free if repo is on GitHub)  

**On the phone:** open APK → Install → allow “unknown apps” if asked.

**Cost:** $0  
**Note:** Users must trust you (not from Play Store). Fine for school projects and friends.

---

## Option 3 — Amazon Appstore (Android, $0 to publish)

Amazon’s developer registration is **free** (no $25 like Google).

1. [developer.amazon.com](https://developer.amazon.com) → create account  
2. Submit the same `.aab` from `.\scripts\build-play-store.ps1` (needs Android Studio + keystore — see STORE_RELEASE.md for build steps only, skip Play payment)  
3. Review can take a few days  

Smaller audience than Play Store, but **legit store listing at $0**.

---

## Option 4 — Samsung Galaxy Store (often free)

Samsung sometimes offers **free** developer registration for Galaxy Store.

- [seller.samsungapps.com](https://seller.samsungapps.com)  
- Good for Samsung phone users  

Check their current terms — registration fee policies can change.

---

## What is NOT free (be honest)

| Path | Free? |
|------|--------|
| Google Play public listing | **No** ($25) |
| Apple App Store | **No** ($99/year) |
| Netlify + Render + MongoDB free tiers | **Yes** (with limits) |
| Web “Install app” / Add to Home Screen | **Yes** |
| Share APK yourself | **Yes** |
| Amazon Appstore | **Yes** (registration) |

There is **no way** to list on **Apple App Store** without paying Apple.

---

## Recommended path for you (no money)

1. **Share Netlify link** + teach users **Add to Home Screen** (Option 1)  
2. Optional: build **APK** and share on Drive/WhatsApp (Option 2)  
3. Later, if you get $25 once → Google Play  

**QR code (free):** use [qr-code-generator.com](https://www.qr-code-generator.com) with your Netlify URL — print or post in class.

---

## What you already have live (all free tier)

| Piece | URL |
|-------|-----|
| App (web) | https://tubular-pixie-00c69b.netlify.app |
| API | https://women-tracker.onrender.com |
| Privacy | Add `privacy.html` to Netlify after rebuild |

---

## Class / portfolio wording

> “Glow Wellness is available as a progressive web app and Android install package. Install from [link] or add to your home screen. Full native store release planned when budget allows.”

That is honest and professional.
