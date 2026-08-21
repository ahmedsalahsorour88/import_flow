@echo off
title ImportFlow ERP - Export Release Package
setlocal

echo ===============================================================================
echo            ImportFlow ERP - Export Release Package (ZIP for Upload)
echo ===============================================================================
echo.

python create_release_bundle.py
if errorlevel 1 (
    echo [ERROR] Export failed!
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo [SUCCESS] Package exported to dist\releases!
echo You can now upload the ZIP file to your server, Google Drive, or cloud storage.
echo ===============================================================================
echo.
pause
exit /b 0
