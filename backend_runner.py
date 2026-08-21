"""
ImportFlow ERP — Standalone Backend Entrypoint
Runs FastAPI with Uvicorn inside PyInstaller bundle or local python.
"""
import sys
import os
import asyncio
import warnings
from pathlib import Path

# Suppress deprecation warnings on Windows
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Set Windows Selector Event Loop for Python 3.12+
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

class SafeLogStream:
    def __init__(self, file_path=None):
        self.file_path = file_path
        self._file = None
        if file_path:
            try:
                self._file = open(file_path, "a", encoding="utf-8")
            except Exception:
                self._file = None

    def write(self, message):
        if self._file:
            try:
                self._file.write(message)
                self._file.flush()
            except Exception:
                pass

    def flush(self):
        if self._file:
            try:
                self._file.flush()
            except Exception:
                pass

    def isatty(self):
        return False

# If running frozen (PyInstaller executable)
if getattr(sys, 'frozen', False):
    app_dir = Path(sys.executable).parent
    os.chdir(app_dir)
    sys.path.insert(0, str(app_dir))
    if hasattr(sys, '_MEIPASS'):
        sys.path.insert(0, str(sys._MEIPASS))
    
    # Safe logging stream for windowed/noconsole mode
    safe_stream = SafeLogStream(app_dir / "backend_server.log")
    sys.stdout = safe_stream
    sys.stderr = safe_stream
    sys.stdin = SafeLogStream()

    # Background watchdog: monitors frontend.exe and shuts down backend when frontend exits
    def _frontend_watchdog():
        import time
        import subprocess
        time.sleep(12)  # Grace period during application startup
        while True:
            time.sleep(2.5)
            try:
                cmd = 'tasklist /FI "IMAGENAME eq frontend.exe"'
                flags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
                output = subprocess.check_output(cmd, shell=True, creationflags=flags).decode("utf-8", errors="ignore")
                if "frontend.exe" not in output:
                    os._exit(0)
            except Exception:
                pass

    import threading
    threading.Thread(target=_frontend_watchdog, daemon=True).start()
else:
    app_dir = Path(__file__).resolve().parent
    sys.path.insert(0, str(app_dir))

import uvicorn
from main import app

DEFAULT_PORT = int(os.getenv("PORT", "28080"))

def main():
    # Run uvicorn server programmatically with log_config=None to prevent isatty crash
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=DEFAULT_PORT,
        log_config=None,
        use_colors=False,
        access_log=False,
    )

if __name__ == "__main__":
    main()
