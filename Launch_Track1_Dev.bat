@echo off
setlocal enabledelayedexpansion
title Sorour Logistics ERP ? Track 1 (Fast Iteration Dev Mode)

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ===============================================================================
echo        Sorour Logistics ERP ? Track 1: Fast Iteration (Dev Mode)
echo ===============================================================================
echo.

:: 1. Safety Backup (Non-negotiable 0.05s habit)
echo [1/3] Creating instant safety snapshot of real database...
python scripts/daily_backup.py --test
if errorlevel 1 (
    echo [WARN] Backup script had an issue, but proceeding with caution.
)
echo.

:: 2. Start / Verify Backend on Port 28080
echo [2/3] Checking Backend API Server on port 28080...
set "BACKEND_HEALTHY=0"
curl -s -m 2 http://127.0.0.1:28080/api/v1/health >nul 2>&1
if not errorlevel 1 (
    set "BACKEND_HEALTHY=1"
)

if "!BACKEND_HEALTHY!"=="1" (
    echo       [OK] Backend server is already running and responding on port 28080.
) else (
    echo       [i] Freeing port 28080 from any unresponsive or zombie processes...
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":28080"') do taskkill /f /pid %%p >nul 2>&1
    ping 127.0.0.1 -n 2 >nul 2>&1

    echo       [+] Starting Live Backend with auto-reload...
    start "Sorour Logistics - Backend API Server (Track 1)" cmd /k "cd /d "%ROOT_DIR%" && python -m uvicorn main:app --host 127.0.0.1 --port 28080 --reload"
    
    :: Wait for backend to be ready
    set "READY=0"
    for /L %%i in (1,1,12) do (
        if "!READY!"=="0" (
            ping 127.0.0.1 -n 2 >nul 2>&1
            curl -s -m 1 http://127.0.0.1:28080/api/v1/health >nul 2>&1
            if not errorlevel 1 (
                set "READY=1"
            )
        )
    )
    if "!READY!"=="1" (
        echo       [OK] Backend API is ready on http://127.0.0.1:28080
    ) else (
        echo       [INFO] Backend is initializing in background window...
    )
)
echo.

:: 3. Choose Client & Launch with Hot Reload
echo [3/3] Client Target Selection...
echo ===============================================================================
echo  Select Frontend Client Mode:
echo    [1] Windows Desktop Client  (flutter run -d windows)  [Standard]
echo    [2] Google Chrome Web       (flutter run -d chrome)   [Ultra-stable, No GPU crash]
echo    [3] Backend API Only        (FastAPI Interactive Docs)
echo ===============================================================================
set "TARGET_MODE=1"
set /p "TARGET_MODE=Enter choice [1, 2, or 3 - Press ENTER for 1]: "

cd /d "%ROOT_DIR%frontend"

if "%TARGET_MODE%"=="2" (
    echo.
    echo [*] Launching Google Chrome Web Client on port 3000...
    echo  CONTROLS: Press [r] for Hot Reload, [R] for Hot Restart, [q] to Quit.
    flutter run -d chrome --web-port 3000
) else if "%TARGET_MODE%"=="3" (
    echo.
    echo [*] Opening API Documentation in default browser...
    start http://127.0.0.1:28080/docs
    echo Backend is running at http://127.0.0.1:28080. Press any key to exit.
    pause >nul
) else (
    echo.
    echo [*] Launching Windows Desktop Client (Debug Mode)...
    echo  CONTROLS: Press [r] for Hot Reload, [R] for Hot Restart, [q] to Quit.
    flutter run -d windows
)

pause
