@echo off
setlocal
title ImportFlow ERP Launcher

echo ===============================================================================
echo                 ImportFlow ERP - Enterprise Launcher
echo ===============================================================================
echo.

:: 1. Free ports 8000 and 3000
echo [1/3] Checking and freeing ports 8000 and 3000...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8000"') do taskkill /f /pid %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000"') do taskkill /f /pid %%p >nul 2>&1

:: 2. Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not found in system PATH.
    echo Please install Python 3.12+ and ensure it is added to PATH.
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo   Select Launch Mode:
echo ===============================================================================
echo   [1] Desktop Application (Native Windows Release EXE) - [Default]
echo   [2] Web Application (Chrome / Browser at http://localhost:3000)
echo   [3] Backend API Only (FastAPI + Swagger Docs at http://localhost:8000/docs)
echo   [4] Run Backend Unit Tests
echo ===============================================================================
echo.

choice /c 1234 /t 6 /d 1 /m "Select option [1-4] (Auto-launching Desktop in 6s):"
if errorlevel 4 goto launch_tests
if errorlevel 3 goto launch_backend_only
if errorlevel 2 goto launch_web
if errorlevel 1 goto launch_desktop

:launch_desktop
echo.
echo [2/3] Starting FastAPI Backend on http://127.0.0.1:8000...
start "ImportFlow Backend" /min cmd /c "cd /d %~dp0 && python -m uvicorn main:app --host 127.0.0.1 --port 8000"

echo [3/3] Launching ImportFlow Desktop...
ping 127.0.0.1 -n 3 >nul 2>&1

if exist "%~dp0frontend\build\windows\x64\runner\Release\frontend.exe" (
    start "" "%~dp0frontend\build\windows\x64\runner\Release\frontend.exe"
    echo.
    echo ===============================================================================
    echo [SUCCESS] ImportFlow ERP Desktop is running!
    echo    - Backend API: http://127.0.0.1:8000
    echo    - API Docs:    http://127.0.0.1:8000/docs
    echo ===============================================================================
    ping 127.0.0.1 -n 3 >nul 2>&1
    exit /b 0
) else (
    echo [INFO] Release binary not found. Launching via Flutter Desktop Debug...
    start "ImportFlow Desktop" cmd /k "cd /d %~dp0frontend && flutter run -d windows"
    exit /b 0
)

:launch_web
echo.
echo [2/3] Starting FastAPI Backend on http://0.0.0.0:8000...
start "ImportFlow Backend" /min cmd /c "cd /d %~dp0 && python -m uvicorn main:app --host 0.0.0.0 --port 8000"

echo [3/3] Starting Flutter Web on http://localhost:3000...
start "ImportFlow Frontend" cmd /k "cd /d %~dp0frontend && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"

echo Waiting for Web Server to initialize...
ping 127.0.0.1 -n 5 >nul 2>&1
start http://localhost:3000

echo.
echo ===============================================================================
echo [SUCCESS] ImportFlow Web is launching at http://localhost:3000
echo ===============================================================================
ping 127.0.0.1 -n 3 >nul 2>&1
exit /b 0

:launch_backend_only
echo.
echo Starting FastAPI Backend on http://127.0.0.1:8000...
start "ImportFlow Backend" cmd /k "cd /d %~dp0 && python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"
ping 127.0.0.1 -n 3 >nul 2>&1
start http://127.0.0.1:8000/docs
exit /b 0

:launch_tests
echo.
echo Running Unit Tests...
python -m pytest -v
echo.
pause
exit /b 0
