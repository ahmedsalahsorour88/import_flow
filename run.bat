@echo off
echo ====================================================
echo Starting ImportFlow ERP (Backend & Frontend)
echo ====================================================

:: Start FastAPI Backend in background window
start "ImportFlow Backend (FastAPI)" cmd /k "cd /d %~dp0 && python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

:: Wait 2 seconds for backend initialization
timeout /t 2 /nobreak > nul

:: Start Flutter Web Frontend in background window
start "ImportFlow Frontend (Flutter Web)" cmd /k "cd /d %~dp0frontend && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"

echo.
echo Backend running at:  http://localhost:8000
echo Frontend running at: http://localhost:3000
echo.
