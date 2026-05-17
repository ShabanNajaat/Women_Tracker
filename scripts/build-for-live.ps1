# Builds Flutter web and optionally copies into server/public for single-host Render deploy.
param(
  [string]$ApiUrl = "",
  [switch]$CopyToServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "glow_mobile"
$serverPublic = Join-Path $root "server\public"

Set-Location $mobile

$defineArgs = @()
if ($ApiUrl.Trim().Length -gt 0) {
  $defineArgs += "--dart-define=API_BASE_URL=$($ApiUrl.Trim())"
  Write-Host "API_BASE_URL=$($ApiUrl.Trim())" -ForegroundColor Cyan
} else {
  Write-Host "No API_BASE_URL — web will use same-origin /api (Render all-in-one) or localhost:8081 locally." -ForegroundColor Yellow
}

Write-Host "Building Flutter web (release)..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit 1 }
flutter build web --release @defineArgs
if ($LASTEXITCODE -ne 0) { exit 1 }

$buildWeb = Join-Path $mobile "build\web"
if ($CopyToServer) {
  Write-Host "Copying to server/public for Render single-service deploy..." -ForegroundColor Cyan
  if (Test-Path $serverPublic) { Remove-Item $serverPublic -Recurse -Force }
  New-Item -ItemType Directory -Path $serverPublic | Out-Null
  Copy-Item -Path (Join-Path $buildWeb "*") -Destination $serverPublic -Recurse -Force
  Write-Host "Done. Deploy the server folder to Render (see DEPLOY_LIVE.md)." -ForegroundColor Green
} else {
  Write-Host "Build output: $buildWeb" -ForegroundColor Green
  Write-Host "Deploy build/web to Netlify, or re-run with -CopyToServer for Render all-in-one." -ForegroundColor Green
}
