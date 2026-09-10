@echo off
title Sorour Logistics ERP - Build Setup Wizard (.EXE Installer)
setlocal

echo ===============================================================================
echo            Sorour Logistics ERP - Windows Setup Wizard (.EXE) Builder
echo ===============================================================================
echo.

set "ISCC_PATH="
if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" set "ISCC_PATH=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set "ISCC_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"

if "%ISCC_PATH%"=="" (
    echo [ERROR] Inno Setup compiler (ISCC.exe) not found.
    echo Please install Inno Setup 6 or run `winget install JRSoftware.InnoSetup`.
    pause
    exit /b 1
)

echo [1/2] Verifying Standalone package in dist\Sorour_Logistics_Standalone...
if not exist "%~dp0dist\Sorour_Logistics_Standalone\backend.exe" (
    echo [INFO] Standalone package not found. Generating now...
    python package_production.py
)

echo.
echo [2/2] Compiling Windows Setup Wizard (.EXE Installer)...
"%ISCC_PATH%" "%~dp0installer\importflow_setup.iss"
if errorlevel 1 (
    echo [ERROR] Compilation failed!
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo [SUCCESS] Windows Setup Installer Created Successfully!
echo Installer Location in: %~dp0dist\releases\
echo ===============================================================================
echo.
pause
exit /b 0
