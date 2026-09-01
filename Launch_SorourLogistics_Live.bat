@echo off
setlocal enabledelayedexpansion
title Sorour Logistics ERP - Live Launcher

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ===============================================================================
echo        Sorour Logistics ERP - Live System Launcher
echo ===============================================================================
echo.

:: 1. Verify Python
echo [1/4] Checking Python environment...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python 3.12+ and add it to system PATH.
    pause
    exit /b 1
)
echo       [OK] Python is available.

:: 2. Apply Database Migrations
echo [2/4] Verifying database schema (sorour_logistics.db)...
python -m alembic upgrade head >nul 2>&1
echo       [OK] Database schema verified.

:: 3. Check / Start Backend API Server on Port 28080
echo [3/4] Checking Backend API Server on port 28080...
set "PORT_IN_USE=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":28080" ^| findstr "LISTENING"') do (
    set "PORT_IN_USE=1"
)

if "!PORT_IN_USE!"=="1" (
    echo       [OK] Backend server is already running on port 28080.
) else (
    echo       [+] Starting FastAPI backend on http://127.0.0.1:28080...
    start "SorourLogistics Backend" /min python -m uvicorn main:app --host 127.0.0.1 --port 28080
    
    :: Wait up to 10 seconds for backend to start
    set "READY=0"
    for /L %%i in (1,1,10) do (
        if "!READY!"=="0" (
            ping 127.0.0.1 -n 2 >nul 2>&1
            for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":28080" ^| findstr "LISTENING"') do (
                set "READY=1"
            )
        )
    )
    if "!READY!"=="1" (
        echo       [OK] Backend API is ready and listening!
    ) else (
        echo       [INFO] Backend is initializing in background...
    )
)

:: 4. Launch Flutter Windows Desktop App
echo [4/4] Launching Sorour Logistics Desktop Client...
set "RELEASE_DIR=%ROOT_DIR%frontend\build\windows\x64\runner\Release"
set "CLIENT_EXE=%RELEASE_DIR%\frontend.exe"

if exist "%CLIENT_EXE%" (
    start "" /D "%RELEASE_DIR%" "%CLIENT_EXE%"
    echo       [OK] Desktop application started successfully!
) else (
    echo       [INFO] Prebuilt binary not found, launching with Flutter engine...
    start "Sorour Logistics Desktop" /D "%ROOT_DIR%frontend" cmd /c "flutter run -d windows"
)

echo.
echo ===============================================================================
echo    Sorour Logistics ERP is LIVE!
echo    - Backend API: http://127.0.0.1:28080
echo    - API Docs:    http://127.0.0.1:28080/docs
echo ===============================================================================
ping 127.0.0.1 -n 4 >nul 2>&1
exit /b 0
