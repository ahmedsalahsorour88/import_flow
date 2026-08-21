"""
ImportFlow ERP — Backend PyInstaller Builder
Compiles FastAPI backend into a standalone `backend.exe` executable.
"""
import os
import sys
import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent

def build_backend():
    print("===============================================================================")
    print("           ImportFlow ERP - Compiling Standalone Backend Executable            ")
    print("===============================================================================")

    hidden_imports = [
        "uvicorn",
        "uvicorn.logging",
        "uvicorn.loops",
        "uvicorn.loops.auto",
        "uvicorn.loops.asyncio",
        "uvicorn.protocols",
        "uvicorn.protocols.http",
        "uvicorn.protocols.http.auto",
        "uvicorn.protocols.http.h11_impl",
        "uvicorn.protocols.websockets",
        "uvicorn.protocols.websockets.auto",
        "uvicorn.lifespan",
        "uvicorn.lifespan.on",
        "uvicorn.lifespan.off",
        "fastapi",
        "fastapi.middleware.cors",
        "starlette",
        "starlette.middleware",
        "starlette.middleware.base",
        "pydantic",
        "pydantic_core",
        "sqlalchemy",
        "sqlalchemy.dialects.sqlite",
        "alembic",
        "sqlite3",
        "multipart",
        "reportlab",
        "openpyxl",
        "pandas",
        "pdfplumber",
        "pypdf",
        "docx",
        "httpx",
        "requests",
        "anyio",
        "seed",
        "seed_clearance_expenses",
        "main",
    ]

    # Collect all modules
    modules_dir = ROOT_DIR / "modules"
    for item in modules_dir.iterdir():
        if item.is_dir() and not item.name.startswith("__"):
            hidden_imports.extend([
                f"modules.{item.name}",
                f"modules.{item.name}.model",
                f"modules.{item.name}.schemas",
                f"modules.{item.name}.repository",
                f"modules.{item.name}.service",
                f"modules.{item.name}.validators",
                f"modules.{item.name}.router",
            ])

    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--onefile",
        "--noconsole",
        "--name", "backend",
        "--distpath", str(ROOT_DIR / "dist_backend"),
        "--workpath", str(ROOT_DIR / "build_backend"),
    ]

    # Add hidden imports
    for imp in hidden_imports:
        cmd.extend(["--hidden-import", imp])

    # Add app entrypoint
    cmd.append(str(ROOT_DIR / "backend_runner.py"))

    print("Running PyInstaller command...")
    result = subprocess.run(cmd, cwd=str(ROOT_DIR))
    if result.returncode != 0:
        print(f"[ERROR] PyInstaller build failed with return code {result.returncode}")
        return False

    print("===============================================================================")
    print(f"[SUCCESS] Standalone backend.exe successfully created at: {ROOT_DIR / 'dist_backend' / 'backend.exe'}")
    print("===============================================================================")
    return True

if __name__ == "__main__":
    success = build_backend()
    sys.exit(0 if success else 1)
