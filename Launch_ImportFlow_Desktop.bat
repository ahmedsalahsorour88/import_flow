@echo off
title ImportFlow ERP Desktop
setlocal

echo ====================================================
echo   ImportFlow ERP - Windows Desktop Application
echo ====================================================
echo.

:: Free port 8000 if already in use
echo Freeing port 8000 if occupied...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8000"') do taskkill /f /pid %%p >nul 2>&1

:: Start Backend API in minimized background process
echo Starting Backend API...
start "ImportFlow Backend" /min cmd /c "cd /d %~dp0 && python -m uvicorn main:app --host 127.0.0.1 --port 8000"

:: Wait 2 seconds for API server ready
ping 127.0.0.1 -n 3 >nul 2>&1

:: Launch Native Windows Desktop Executable (.EXE)
echo Launching ImportFlow Desktop Application...
if exist "%~dp0frontend\build\windows\x64\runner\Release\frontend.exe" (
    start "" "%~dp0frontend\build\windows\x64\runner\Release\frontend.exe"
) else (
    start "ImportFlow Desktop" cmd /k "cd /d %~dp0frontend && flutter run -d windows"
)

exit /b 0
