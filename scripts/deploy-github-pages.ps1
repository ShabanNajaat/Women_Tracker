# Deploy Flutter web build to GitHub Pages (gh-pages branch)
# Run from: C:\Users\ADMIN\Desktop\WOMEN TRACKER

$buildDir = "glow_mobile\build\web"
$ghPagesDir = ".gh-pages-deploy"

Write-Output "==> Preparing GitHub Pages deploy..."

# Copy index.html as 404.html for SPA routing
Copy-Item "$buildDir\index.html" "$buildDir\404.html" -Force
Write-Output "  Copied index.html -> 404.html (SPA routing fix)"

# Create a .nojekyll file to prevent GitHub from processing the site
New-Item -ItemType File -Path "$buildDir\.nojekyll" -Force | Out-Null
Write-Output "  Created .nojekyll"

# Create a temp directory for the gh-pages branch
if (Test-Path $ghPagesDir) { Remove-Item -Recurse -Force $ghPagesDir }
New-Item -ItemType Directory -Path $ghPagesDir | Out-Null

# Initialize a fresh git repo in the temp dir pointing to the same remote
git -C $ghPagesDir init
git -C $ghPagesDir remote add origin (git remote get-url origin)

# Try to fetch the existing gh-pages branch
git -C $ghPagesDir fetch origin gh-pages --depth=1 2>$null
git -C $ghPagesDir checkout gh-pages 2>$null
if ($LASTEXITCODE -ne 0) {
    git -C $ghPagesDir checkout --orphan gh-pages
    git -C $ghPagesDir rm -rf . 2>$null
}

# Copy the built files into the temp dir
Write-Output "  Copying build output..."
Copy-Item "$buildDir\*" $ghPagesDir -Recurse -Force

# Commit and push
git -C $ghPagesDir config user.email "najaatmohammedshaban@gmail.com"
git -C $ghPagesDir config user.name "Shaban Najaat"
git -C $ghPagesDir add -A
git -C $ghPagesDir commit -m "Deploy Glow app to GitHub Pages $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git -C $ghPagesDir push origin gh-pages --force

# Cleanup
Remove-Item -Recurse -Force $ghPagesDir

Write-Output ""
Write-Output "✅ Deployed! Site will be live at:"
Write-Output "   https://shabanNajaat.github.io/Women_Tracker/"
Write-Output ""
Write-Output "NOTE: First publish may take 1-2 minutes to go live."
