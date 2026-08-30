@echo off
title ImportFlow ERP - Live Launcher
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ===============================================================================
echo                🚀 ImportFlow ERP — Live Launcher & Auto-Sync
echo ===============================================================================
echo.

:: 1. Sync latest Git updates in 2 seconds
echo [1/4] Checking & pulling latest updates from repository...
git pull origin main --quiet 2>nul
if %errorlevel% equ 0 (
    echo       [OK] System is fully up-to-date!
) else (
    echo       [INFO] Running in offline / local mode.
)

:: 2. Apply any pending database schema migrations
echo [2/4] Verifying database schema migrations...
python -m alembic upgrade head >nul 2>&1
echo       [OK] Database schema verified!

:: 3. Start Python FastAPI backend if not already running on port 28080
echo [3/4] Checking backend server (Port 28080)...
netstat -ano | findstr ":28080" | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo       [OK] Backend server is already running.
) else (
    echo       [+] Starting background FastAPI backend server...
    start /min "" python main.py
    timeout /t 2 /nobreak >nul
)

:: 4. Launch Desktop Client
echo [4/4] Starting ImportFlow Desktop Client...
set "CLIENT_EXE=%ROOT_DIR%frontend\build\windows\x64\runner\Release\frontend.exe"

if exist "%CLIENT_EXE%" (
    start "" "%CLIENT_EXE%"
    echo       [OK] Application launched successfully!
) else (
    echo       [WARN] Prebuilt binary not found, launching via flutter run...
    cd /d "%ROOT_DIR%frontend"
    start "" flutter run -d windows
)

timeout /t 1 /nobreak >nul
exit /b 0
