@echo off
chcp 65001 >nul
set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"
call "%ROOT_DIR%Launch_SorourLogistics_Live.bat"
