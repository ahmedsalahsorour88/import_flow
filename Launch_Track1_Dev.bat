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
set "PORT_IN_USE=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":28080" ^| findstr "LISTENING"') do (
    set "PORT_IN_USE=1"
)

if "!PORT_IN_USE!"=="1" (
    echo       [OK] Backend server is already running on port 28080.
) else (
    echo       [+] Starting Live Backend with auto-reload...
    start "Sorour Logistics ? Backend API Server (Track 1)" cmd /k "cd /d "%ROOT_DIR%" && python -m uvicorn main:app --host 127.0.0.1 --port 28080 --reload"
    
    :: Wait for backend to be ready
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
        echo       [OK] Backend API is ready on http://127.0.0.1:28080
    ) else (
        echo       [INFO] Backend is initializing in background window...
    )
)
echo.

:: 3. Launch Flutter Windows with Hot Reload in this interactive terminal
echo [3/3] Launching Flutter Desktop Client (Debug Mode with Hot Reload)...
echo ===============================================================================
echo  CONTROLS:
echo    Press [r] : Instant Hot Reload  (^<1 second)
echo    Press [R] : Full Hot Restart    (1-2 seconds)
echo    Press [q] : Quit Application
echo ===============================================================================
echo.

cd /d "%ROOT_DIR%frontend"
flutter run -d windows

pause
