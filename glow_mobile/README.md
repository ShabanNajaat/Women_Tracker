# Glow mobile

Flutter client for Glow Wellness. Point it at the Node API in `../server` (default port **8081**).

## API URL

Override the base URL when testing on a device or emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:8081/api
```

The Android emulator uses `http://10.0.2.2:8081/api` by default so it can reach the API on your development machine.

## Email / password auth

No extra configuration — the app posts to `/api/auth/login` and `/api/auth/register`.

## Google Sign-In

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials), create an OAuth **Web application** client.

2. **Authorized JavaScript origins** (examples):
   - `http://localhost` (and the exact port Flutter uses for web, e.g. `http://localhost:54321`)
   - Your production site URL with HTTPS

3. Set **`GOOGLE_CLIENT_ID`** in `server/.env` to that Web client ID (e.g. `123.apps.googleusercontent.com`). Restart `npm start`.

4. The Flutter app loads this ID automatically from **`GET /api/auth/public-config`** so you usually **do not** need `--dart-define=GOOGLE_SERVER_CLIENT_ID` unless you’re offline from your API.

5. Keep **`web/index.html`** meta `google-signin-client_id` **in sync** with the same ID (helps Google Sign-In on web).

6. **Android / iOS:** You may still pass  
   `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com`  
   if the API is unreachable during first launch; it must match `GOOGLE_CLIENT_ID` on the server.

## Learn Flutter

- [Flutter documentation](https://docs.flutter.dev/)
