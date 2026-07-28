@echo off
setlocal enabledelayedexpansion

set PORT=8080
set URL=http://localhost:%PORT%
set WEB_DIR=%~dp0build\web
set PYTHON_CMD=python

echo.
echo ========================================
echo   EconoMia Flutter - Build ^& Open Web
echo ========================================
echo.

echo Getting Flutter packages...
call flutter pub get

if errorlevel 1 (
    echo.
    echo Package restore failed!
    pause
    exit /b 1
)

echo.
echo Building web release...
call flutter build web --release

if errorlevel 1 (
    echo.
    echo Web build failed!
    pause
    exit /b 1
)

where python >nul 2>nul
if errorlevel 1 (
    where py >nul 2>nul
    if errorlevel 1 (
        echo.
        echo Python was not found. Install Python or serve build\web with another web server.
        pause
        exit /b 1
    )
    set PYTHON_CMD=py
)

echo.
echo Checking local web server on %URL%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $client = [Net.Sockets.TcpClient]::new(); $client.Connect('127.0.0.1', %PORT%); $client.Close(); exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo Starting local web server...
    start "EconoMia Web Server" /min cmd /c "cd /d "%WEB_DIR%" && %PYTHON_CMD% -m http.server %PORT%"
    timeout /t 2 /nobreak >nul
) else (
    echo A local server is already running on port %PORT%.
)

echo.
echo Opening %URL%...
start "" "%URL%"

echo.
echo ========================================
echo   Web app is available at %URL%
echo ========================================
echo.
pause
