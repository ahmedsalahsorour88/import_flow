@echo off
title ImportFlow ERP - Production Sync Tool
setlocal
cd /d "%~dp0"

python sync_to_production.py

if errorlevel 1 (
    echo.
    echo [ERROR] حدث خطأ أثناء تنفيذ عملية المزامنة.
    pause
)
