@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   EconoMia Flutter - Build & Install
echo ========================================
echo.

echo Building debug APK...
call flutter build apk --debug

if errorlevel 1 (
    echo.
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Installing on device...
"C:\Users\Arthur\AppData\Local\Android\Sdk\platform-tools\adb.exe" install "build\app\outputs\flutter-apk\app-debug.apk"

if errorlevel 1 (
    echo.
    echo Installation failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SUCCESS! App installed on device
echo ========================================
echo.
pause
