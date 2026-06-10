# Builds a release Android APK for Glow Wellness (install on phone).
param(
  [string]$ApiUrl = "https://women-tracker.onrender.com/api",
  [string]$GoogleServerClientId = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "glow_mobile"

Set-Location $mobile

$defines = @("--dart-define=API_BASE_URL=$($ApiUrl.Trim())")
if ($GoogleServerClientId.Trim().Length -gt 0) {
  $defines += "--dart-define=GOOGLE_SERVER_CLIENT_ID=$($GoogleServerClientId.Trim())"
}

Write-Host "API_BASE_URL=$($ApiUrl.Trim())" -ForegroundColor Cyan
Write-Host "Building Android APK (release)..." -ForegroundColor Cyan

flutter pub get
if ($LASTEXITCODE -ne 0) { exit 1 }

flutter build apk --release @defines
if ($LASTEXITCODE -ne 0) { exit 1 }

$apk = Join-Path $mobile "build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""
Write-Host "Done! Install this file on your Android phone:" -ForegroundColor Green
Write-Host $apk -ForegroundColor Yellow
Write-Host ""
Write-Host "Copy to phone (USB/cloud), open it, allow Install unknown apps if asked." -ForegroundColor Cyan
