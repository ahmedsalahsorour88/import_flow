"""
Sorour Logistics ERP — Automated Daily Observability Report Runner & Task Scheduler
===================================================================================
Generates the daily observability report, delivers via multi-channel alerts (Email,
Windows Toast, WebSocket), and manages registration in Windows Task Scheduler.

Usage:
    python scripts/daily_report.py --preview           # Print today's report to stdout
    python scripts/daily_report.py --run               # Generate, save, and deliver via alerts
    python scripts/daily_report.py --register-task     # Register daily Windows task at 23:15
    python scripts/daily_report.py --unregister-task   # Remove Windows scheduled task
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path
from datetime import datetime, timezone

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

from database.database import SessionLocal
from modules.system_observability.daily_report_service import (
    DailyReportService,
    DEFAULT_RETENTION_DAYS,
)

TASK_NAME = "SorourLogistics_DailyReport"
DEFAULT_SCHEDULE_TIME = "23:15"


def register_windows_task(time_str: str = DEFAULT_SCHEDULE_TIME) -> bool:
    """Registers the daily report generation job in Windows Task Scheduler."""
    python_exe = sys.executable
    script_path = ROOT_DIR / "scripts" / "daily_report.py"

    action = f'"{python_exe}" "{script_path}" --run'
    cmd = f'schtasks /create /tn "{TASK_NAME}" /tr "\"{python_exe}\" \"{script_path}\" --run" /sc daily /st {time_str} /f'

    print(f"Registering Windows Task: {TASK_NAME} at {time_str} daily...")
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode == 0:
            print("================================================================================")
            print("[SUCCESS] Windows Scheduled Task registered successfully!")
            print(f" Task Name : {TASK_NAME}")
            print(f" Schedule  : Daily at {time_str} (15 minutes after 23:00 daily backup)")
            print(f" Action    : {action}")
            print("================================================================================")
            return True
        else:
            print(f"[ERROR] Failed to register task: {res.stderr.strip() or res.stdout.strip()}")
            return False
    except Exception as e:
        print(f"[ERROR] Exception during task registration: {e}")
        return False


def unregister_windows_task() -> bool:
    """Removes the daily report task from Windows Task Scheduler."""
    cmd = f'schtasks /delete /tn "{TASK_NAME}" /f'
    print(f"Unregistering Windows Task: {TASK_NAME}...")
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"[SUCCESS] Windows Task '{TASK_NAME}' deleted successfully.")
            return True
        else:
            print(f"[INFO] Task was not registered or could not be removed: {res.stderr.strip()}")
            return False
    except Exception as e:
        print(f"[ERROR] {e}")
        return False


def run_daily_report(deliver: bool = True, preview: bool = False):
    """Executes the daily report generation."""
    db = SessionLocal()
    try:
        print("=" * 80)
        print("   ImportFlow ERP — Daily Observability Report Generation Engine")
        print("=" * 80)
        print(f" Timestamp: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f" Delivery : {'Enabled (Email + Windows Toast)' if deliver and not preview else 'Disabled (Preview Mode)'}")
        print("-" * 80)

        report = DailyReportService.generate_report(db, deliver=(deliver and not preview))

        if preview or not deliver:
            print(report.markdown_content)
        else:
            print(f"\n[REPORT GENERATED] Date: {report.report_date}")
            print(f" Headline Verdict : {report.headline_message}")
            print(f" File Saved       : {report.report_file}")
            print(f" Delivery Channels: {', '.join(report.delivered_channels)}")
            print("\n--- Summary Snapshot ---")
            print(f" - Health Verdict : {report.summary_data.get('health_verdict')}")
            print(f" - System Uptime  : {report.summary_data.get('uptime_human')}")
            print(f" - Total Requests : {report.summary_data.get('total_requests')}")
            print(f" - Latency P50/P95: {report.summary_data.get('p50_latency_ms')}ms / {report.summary_data.get('p95_latency_ms')}ms")
            print(f" - Needs Attention: {report.summary_data.get('needs_attention_count')} item(s)")
            if report.needs_attention_items:
                for itm in report.needs_attention_items:
                    print(f"   * {itm}")

        print("=" * 80)
        print("[SUCCESS] Daily observability report processing finished.")
        print("=" * 80)
        return report
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="ImportFlow ERP Daily Observability Report")
    parser.add_argument("--run", action="store_true", help="Generate and deliver daily report via alert channels")
    parser.add_argument("--preview", action="store_true", help="Print report to terminal without sending email/toast")
    parser.add_argument("--register-task", action="store_true", help="Register Windows Scheduled Task at 23:15 daily")
    parser.add_argument("--unregister-task", action="store_true", help="Remove Windows Scheduled Task")
    parser.add_argument("--time", type=str, default=DEFAULT_SCHEDULE_TIME, help="Scheduled time in HH:MM format (default: 23:15)")
    args = parser.parse_args()

    if args.register_task:
        register_windows_task(args.time)
    elif args.unregister_task:
        unregister_windows_task()
    elif args.preview:
        run_daily_report(deliver=False, preview=True)
    elif args.run:
        run_daily_report(deliver=True, preview=False)
    else:
        # Default behavior: run report with delivery
        run_daily_report(deliver=True, preview=False)


if __name__ == "__main__":
    main()
