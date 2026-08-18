@echo off
setlocal enabledelayedexpansion
echo ====================================================
echo Starting ImportFlow ERP (Backend & Frontend)
echo ====================================================

:: Free port 8000 if already occupied
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do (
    echo Freeing port 8000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

:: Free port 3000 if already occupied
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do (
    echo Freeing port 3000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

timeout /t 1 /nobreak > nul

:: Start FastAPI Backend in background window
start "ImportFlow Backend (FastAPI)" cmd /k "cd /d %~dp0 && python -m uvicorn main:app --host 0.0.0.0 --port 8000"

:: Wait 2 seconds for backend initialization
timeout /t 2 /nobreak > nul

:: Start Flutter Web Frontend in background window
start "ImportFlow Frontend (Flutter Web)" cmd /k "cd /d %~dp0frontend && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"

echo.
echo Backend running at:  http://localhost:8000
echo Frontend running at: http://localhost:3000
echo ====================================================
