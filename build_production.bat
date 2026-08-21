@echo off
title ImportFlow ERP - Full Production Builder
setlocal

echo ===============================================================================
echo                ImportFlow ERP - Full Production Builder
echo ===============================================================================
echo.

echo [1/5] Running Backend Unit Tests (pytest)...
python -m pytest -q
if errorlevel 1 (
    echo [ERROR] Backend tests failed! Aborting production build.
    pause
    exit /b 1
)
echo [PASS] Backend tests passed!

echo.
echo [2/5] Running Frontend Unit Tests (flutter test)...
cd /d "%~dp0frontend"
call flutter test
if errorlevel 1 (
    echo [ERROR] Frontend tests failed! Aborting production build.
    pause
    exit /b 1
)
echo [PASS] Frontend tests passed!

echo.
echo [3/5] Compiling Windows Desktop Release Binary (.EXE)...
call flutter build windows --release
if errorlevel 1 (
    echo [ERROR] Windows Desktop build failed!
    pause
    exit /b 1
)

echo.
echo [4/5] Compiling Web Production Bundle...
call flutter build web --release --base-href /
if errorlevel 1 (
    echo [ERROR] Web build failed!
    pause
    exit /b 1
)

echo.
echo [5/5] Packaging Production Distribution in dist/...
cd /d "%~dp0"
python package_production.py
if errorlevel 1 (
    echo [ERROR] Packaging failed!
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo [SUCCESS] Full Production Build & Packaging Complete!
echo Production Directory: %~dp0dist
echo Launcher:            %~dp0dist\Start_ImportFlow_Production.bat
echo ===============================================================================
echo.
pause
exit /b 0
