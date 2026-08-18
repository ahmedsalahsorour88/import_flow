@echo off
title ImportFlow ERP Desktop
setlocal enabledelayedexpansion

echo ====================================================
echo   ImportFlow ERP - Windows Desktop Application
echo ====================================================
echo.

:: Free port 8000 if already in use
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do (
    echo Freeing port 8000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

:: Start Backend API in minimized background process
start "ImportFlow Backend (FastAPI)" /min cmd /c "cd /d %~dp0 && python -m uvicorn main:app --host 127.0.0.1 --port 8000"

:: Wait 1.5 seconds for API server ready
timeout /t 2 /nobreak > nul

:: Launch Native Windows Desktop Executable (.EXE)
echo Launching ImportFlow Desktop...
start "" "%~dp0frontend\build\windows\x64\runner\Release\frontend.exe"

exit
