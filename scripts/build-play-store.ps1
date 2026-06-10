# Google Play upload bundle (.aab) — requires android/key.properties + keystore.
param(
  [string]$ApiUrl = "https://women-tracker.onrender.com/api"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "glow_mobile"
$keyProps = Join-Path $mobile "android\key.properties"

if (-not (Test-Path $keyProps)) {
  Write-Host "Missing android\key.properties" -ForegroundColor Red
  Write-Host "1) Run .\scripts\create-android-keystore.ps1" -ForegroundColor Yellow
  Write-Host "2) copy glow_mobile\android\key.properties.example to key.properties and edit" -ForegroundColor Yellow
  exit 1
}

Set-Location $mobile
$defines = @("--dart-define=API_BASE_URL=$($ApiUrl.Trim())")

Write-Host "Building Google Play App Bundle..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit 1 }

flutter build appbundle --release @defines
if ($LASTEXITCODE -ne 0) { exit 1 }

$aab = Join-Path $mobile "build\app\outputs\bundle\release\app-release.aab"
Write-Host ""
Write-Host "Upload this file to Google Play Console:" -ForegroundColor Green
Write-Host $aab -ForegroundColor Yellow
Write-Host "See STORE_RELEASE.md for full steps." -ForegroundColor Cyan
