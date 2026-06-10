# Creates upload keystore for Google Play (run once, back up the .jks file!).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$keystoreDir = Join-Path $root "glow_mobile\android\keystore"
$keystoreFile = Join-Path $keystoreDir "glow-upload-keystore.jks"

if (Test-Path $keystoreFile) {
  Write-Host "Keystore already exists: $keystoreFile" -ForegroundColor Yellow
  exit 0
}

New-Item -ItemType Directory -Path $keystoreDir -Force | Out-Null

Write-Host "Create a STRONG password and remember it — Google needs this same keystore for all future updates." -ForegroundColor Cyan
Write-Host ""

$keytool = "keytool"
if (Get-Command keytool -ErrorAction SilentlyContinue) {
  & keytool -genkey -v `
    -keystore $keystoreFile `
    -alias glow-upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storetype JKS
} else {
  Write-Host "keytool not found. Install Android Studio (includes JDK), then run again." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Keystore saved: $keystoreFile" -ForegroundColor Green
Write-Host "Next: copy android\key.properties.example to android\key.properties and fill passwords." -ForegroundColor Cyan
