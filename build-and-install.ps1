#!/usr/bin/env pwsh
# Build and install EconoMia Flutter app on connected Android device

Write-Host "🔨 Building debug APK..." -ForegroundColor Cyan
flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n📱 Installing on device..." -ForegroundColor Cyan
$adbPath = "C:\Users\Arthur\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adbPath install "build\app\outputs\flutter-apk\app-debug.apk"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Installation successful!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Installation failed" -ForegroundColor Red
    exit 1
}
