# Google Sign-In on web needs a FIXED origin (port 7357).
# Google Cloud -> Credentials -> Web client -> Authorized JavaScript origins:
#   http://localhost:7357

$apiPort = if ($env:GLOW_API_PORT) { $env:GLOW_API_PORT } else { "8081" }
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "Opening app at: http://localhost:7357" -ForegroundColor Cyan
Write-Host ""

Write-Host "Resolving packages..." -ForegroundColor DarkGray
flutter pub get 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Online pub get failed - using offline cache." -ForegroundColor Yellow
    flutter pub get --offline
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Package resolve failed. Check internet/DNS, then run: flutter pub get" -ForegroundColor Red
        exit 1
    }
}

$apiUrl = "http://localhost:$apiPort/api"
flutter run -d chrome --web-hostname localhost --web-port 7357 --no-pub --dart-define=API_BASE_URL=$apiUrl
