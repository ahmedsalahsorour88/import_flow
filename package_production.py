"""
ImportFlow ERP — Production Packaging Script
Creates standalone portable packages and distribution bundles for Windows and Web.
"""
import os
import shutil
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
DIST_DIR = ROOT_DIR / "dist"
STANDALONE_DEST = DIST_DIR / "ImportFlow_Standalone"
DESKTOP_DEST = DIST_DIR / "ImportFlow_Desktop"
WEB_DEST = DIST_DIR / "ImportFlow_Web"

DESKTOP_SRC = ROOT_DIR / "frontend" / "build" / "windows" / "x64" / "runner" / "Release"
WEB_SRC = ROOT_DIR / "frontend" / "build" / "web"
BACKEND_EXE = ROOT_DIR / "dist_backend" / "backend.exe"
DB_SRC = ROOT_DIR / "sorour_logistics.db"
APP_ICON_SRC = ROOT_DIR / "installer" / "app_icon.ico"


def clean_dist():
    print(f"[1/5] Preparing clean dist directory: {DIST_DIR}...")
    # Backup current standalone db before cleaning
    if (STANDALONE_DEST / "sorour_logistics.db").exists():
        backup_dir = ROOT_DIR / "backups"
        backup_dir.mkdir(parents=True, exist_ok=True)
        from datetime import datetime
        backup_snapshot = backup_dir / f"sorour_logistics_prod_before_pack_{datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
        try:
            shutil.copy2(STANDALONE_DEST / "sorour_logistics.db", backup_snapshot)
        except Exception:
            pass

    if DIST_DIR.exists():
        for item in DIST_DIR.iterdir():
            if item.name in ["releases", "backups"]:
                continue
            if item.is_dir():
                shutil.rmtree(item, ignore_errors=True)
            else:
                try:
                    item.unlink()
                except Exception:
                    pass
    else:
        DIST_DIR.mkdir(parents=True, exist_ok=True)

    print(f"[1/5] Prepared dist directory: {DIST_DIR}")


def copy_standalone_package():
    print(f"[2/5] Creating All-In-One Standalone Portable Package (No Python Required)...")
    if not DESKTOP_SRC.exists() or not (DESKTOP_SRC / "frontend.exe").exists():
        print(f"[ERROR] Windows release binary not found at {DESKTOP_SRC}")
        return False

    STANDALONE_DEST.mkdir(parents=True, exist_ok=True)

    # 1. Copy desktop files
    for item in DESKTOP_SRC.iterdir():
        dest = STANDALONE_DEST / item.name
        if item.is_dir():
            shutil.copytree(item, dest, dirs_exist_ok=True)
        else:
            shutil.copy2(item, dest)
    
    # 2. Copy backend.exe
    if BACKEND_EXE.exists():
        shutil.copy2(BACKEND_EXE, STANDALONE_DEST / "backend.exe")
        print(f"      Included backend.exe into {STANDALONE_DEST}")
    else:
        print(f"[WARN] backend.exe not found at {BACKEND_EXE}")

    # 3. Copy Full Master Database (With 3,952 World Ports & Full Master Data)
    prod_db_file = STANDALONE_DEST / "sorour_logistics.db"
    if DB_SRC.exists():
        shutil.copy2(DB_SRC, prod_db_file)
        print(f"      Included master sorour_logistics.db (3,952 Ports & Full Data) into {STANDALONE_DEST}")

    # 4. Copy App Icon
    if APP_ICON_SRC.exists():
        shutil.copy2(APP_ICON_SRC, STANDALONE_DEST / "app_icon.ico")
        print(f"      Included app_icon.ico into {STANDALONE_DEST}")

    # 5. Create Standalone Silent VBS Launcher (0 Terminal Windows)
    vbs_launcher = r'''Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
strPath = fso.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' 1. Free Port 28080 silently
WshShell.Run "cmd /c for /f ""tokens=5"" %p in ('netstat -ano ^| findstr "":28080""') do taskkill /f /pid %p", 0, True

' 2. Start Embedded Backend Server invisibly in background (0 = hidden)
If fso.FileExists(strPath & "\backend.exe") Then
    WshShell.Run Chr(34) & strPath & "\backend.exe" & Chr(34), 0, False
End If

' 3. Wait 1.2s for backend server ready
WScript.Sleep 1200

' 4. Start Native Windows Desktop App and WAIT until closed (1 = normal window, True = wait for exit)
If fso.FileExists(strPath & "\frontend.exe") Then
    WshShell.Run Chr(34) & strPath & "\frontend.exe" & Chr(34), 1, True
End If

' 5. When frontend is closed by the user, terminate backend.exe cleanly and silently
WshShell.Run "taskkill /f /im backend.exe", 0, True
'''
    vbs_file = STANDALONE_DEST / "Launch_ImportFlow.vbs"
    with open(vbs_file, "w", encoding="utf-8") as f:
        f.write(vbs_launcher)

    # 6. Create Standalone Batch Launcher (Optional Fallback)
    launcher_content = """@echo off
title ImportFlow ERP
setlocal

:: 1. Free Port 28080 if occupied
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":28080"') do taskkill /f /pid %%p >nul 2>&1

:: 2. Start Embedded Backend Engine (Silent Mode)
if exist "%~dp0backend.exe" (
    start "" "%~dp0backend.exe"
)

:: 3. Wait for API Server
ping 127.0.0.1 -n 2 >nul 2>&1

:: 4. Launch Desktop Client (.EXE)
start "" "%~dp0frontend.exe"
exit /b 0
"""
    standalone_launcher = STANDALONE_DEST / "ImportFlow_App.bat"
    with open(standalone_launcher, "w", encoding="utf-8") as f:
        f.write(launcher_content)

    print(f"      Created Silent Launcher: {vbs_file}")
    return True


def copy_desktop_release():
    print(f"[3/5] Packaging Windows Desktop Release Client from {DESKTOP_SRC}...")
    if not DESKTOP_SRC.exists() or not (DESKTOP_SRC / "frontend.exe").exists():
        print(f"[ERROR] Windows release binary not found at {DESKTOP_SRC}")
        return False
    shutil.copytree(DESKTOP_SRC, DESKTOP_DEST, dirs_exist_ok=True)
    print(f"      Copied desktop client to: {DESKTOP_DEST}")
    return True


def copy_web_release():
    print(f"[4/5] Packaging Web Release from {WEB_SRC}...")
    if not WEB_SRC.exists():
        print(f"[WARN] Web release build not found at {WEB_SRC}, skipping web packaging.")
        return True
    shutil.copytree(WEB_SRC, WEB_DEST, dirs_exist_ok=True)
    print(f"      Copied web release to: {WEB_DEST}")
    return True


def create_production_launchers():
    print(f"[5/5] Generating Root Production Launchers in dist/...")

    # Root Dist Launcher
    root_launcher_content = """@echo off
title ImportFlow ERP Production
setlocal

echo ===============================================================================
echo                 ImportFlow ERP - Production Standalone Launcher
echo ===============================================================================
echo.

if exist "%~dp0ImportFlow_Standalone\\Launch_ImportFlow.vbs" (
    start "" "%~dp0ImportFlow_Standalone\\Launch_ImportFlow.vbs"
    echo Application launched silently!
    exit /b 0
)

if exist "%~dp0ImportFlow_Standalone\\ImportFlow_App.bat" (
    start "" "%~dp0ImportFlow_Standalone\\ImportFlow_App.bat"
    exit /b 0
)

echo [ERROR] ImportFlow_Standalone directory or launcher not found!
pause
exit /b 1
"""
    root_launcher = DIST_DIR / "Start_ImportFlow_Production.bat"
    with open(root_launcher, "w", encoding="utf-8") as f:
        f.write(root_launcher_content)
    print(f"      Generated: {root_launcher}")
    return True


def main():
    print("================================================================================")
    print("           ImportFlow ERP - Production Standalone Release Packaging            ")
    print("================================================================================")
    clean_dist()
    s1 = copy_standalone_package()
    s2 = copy_desktop_release()
    s3 = copy_web_release()
    s4 = create_production_launchers()

    if s1 and s2 and s4:
        print("================================================================================")
        print(f"[SUCCESS] Standalone production packages successfully created at: {DIST_DIR}")
        print("================================================================================")
        return True
    else:
        print("[ERROR] Packaging failed.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
