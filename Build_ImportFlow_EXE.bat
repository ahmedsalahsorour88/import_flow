@echo off
title Build ImportFlow ERP Desktop Executable (.EXE)
setlocal

echo ===============================================================================
echo            ImportFlow ERP - Windows Release Executable Builder
echo ===============================================================================
echo.

echo [1/3] Checking Flutter and Environment...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not found in system PATH.
    echo Please install Flutter and ensure it is added to PATH.
    pause
    exit /b 1
)

echo [2/3] Analyzing code and verifying dependencies...
cd /d "%~dp0frontend"
call flutter pub get
if errorlevel 1 (
    echo [ERROR] Failed to get flutter packages.
    pause
    exit /b 1
)

echo [3/3] Compiling Native Windows Release Executable (.EXE)...
call flutter build windows --release
if errorlevel 1 (
    echo [ERROR] Build failed! Please review the error messages above.
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo [SUCCESS] Build completed successfully!
echo Binary path: frontend\build\windows\x64\runner\Release\frontend.exe
echo.
echo You can run the application directly using:
echo   - Launch_ImportFlow_Desktop.bat
echo   - run.bat (Option 1)
echo ===============================================================================
echo.
pause
exit /b 0
