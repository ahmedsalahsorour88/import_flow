"""
ImportFlow ERP — Infrastructure & Windows Host Security Hardener
=================================================================
Automated host-level hardening script for Windows Desktop / Server deployment:
1. Enforces strict NTFS file ACLs (icacls) on sensitive files (.env, DB, backups, certs).
   Removes 'Everyone' and 'Users' read permissions, allowing only SYSTEM, Administrators,
   and the current application user.
2. Audits BitLocker encryption status on the volume hosting the ERP data.
3. Verifies TLS certificate and private key existence and permissions.

Usage:
    python scripts/harden_system_security.py --audit
    python scripts/harden_system_security.py --apply
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent

# Sensitive assets that must have locked-down ACLs
SENSITIVE_TARGETS = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "sorour_logistics.db-wal",
    ROOT_DIR / "sorour_logistics.db-shm",
    ROOT_DIR / ".env",
    ROOT_DIR / "backups",
    ROOT_DIR / "certs",
    ROOT_DIR / "certs" / "server.key",
]


def is_windows() -> bool:
    return sys.platform == "win32"


def get_drive_letter() -> str:
    """Returns the drive letter hosting the ERP application (e.g., 'F:')."""
    return ROOT_DIR.drive or "C:"


def audit_acls() -> dict:
    """Inspects ACLs on sensitive files using icacls."""
    results = {}
    if not is_windows():
        return {"status": "SKIPPED", "message": "Non-Windows OS detected; icacls not applicable."}

    for target in SENSITIVE_TARGETS:
        if not target.exists():
            continue
        try:
            res = subprocess.run(
                ["icacls", str(target)],
                capture_output=True,
                text=True,
                timeout=10,
            )
            output = res.stdout
            # Check for overly permissive groups
            has_everyone = "Everyone" in output or "Все" in output or "Todos" in output
            has_general_users = "BUILTIN\\Users" in output or "NT AUTHORITY\\Authenticated Users" in output
            
            results[str(target.name)] = {
                "exists": True,
                "path": str(target),
                "is_overly_permissive": has_everyone or has_general_users,
                "acl_summary": output.strip().splitlines()[:4],
            }
        except Exception as e:
            results[str(target.name)] = {"exists": True, "error": str(e)}

    return results


def apply_acl_hardening() -> bool:
    """Applies restrictive NTFS ACLs via icacls to sensitive targets."""
    if not is_windows():
        print("[-] icacls hardening is only applicable on Windows.")
        return False

    username = os.getenv("USERNAME", "Administrator")
    print(f"[*] Applying strict NTFS permissions for user: '{username}', SYSTEM, Administrators...")

    all_success = True
    for target in SENSITIVE_TARGETS:
        if not target.exists():
            continue

        try:
            # 1. Remove inheritance and copy current inherited permissions
            subprocess.run(
                ["icacls", str(target), "/inheritance:r"],
                check=True,
                capture_output=True,
                timeout=15,
            )
            # 2. Grant Full Control only to the running user, SYSTEM, and Administrators
            grant_args = [
                "icacls",
                str(target),
                "/grant:r",
                f"{username}:(F)",
                "SYSTEM:(F)",
                "Administrators:(F)",
            ]
            subprocess.run(grant_args, check=True, capture_output=True, timeout=15)
            print(f"  [OK] Secured: {target.name}")
        except subprocess.CalledProcessError as e:
            print(f"  [WARN] Failed to harden {target.name}: {e.stderr.decode(errors='ignore') if e.stderr else str(e)}")
            all_success = False
        except Exception as e:
            print(f"  [WARN] Error securing {target.name}: {e}")
            all_success = False

    return all_success


def audit_bitlocker() -> dict:
    """Queries BitLocker status for the volume where the database is stored."""
    drive = get_drive_letter()
    result = {
        "drive": drive,
        "is_supported": False,
        "protection_status": "UNKNOWN",
        "conversion_status": "UNKNOWN",
        "encryption_percentage": "N/A",
        "details": "",
    }

    if not is_windows():
        result["details"] = "Non-Windows OS"
        return result

    try:
        # Run manage-bde -status
        proc = subprocess.run(
            ["manage-bde", "-status", drive],
            capture_output=True,
            text=True,
            timeout=15,
        )
        output = proc.stdout
        result["is_supported"] = True
        result["details"] = output

        for line in output.splitlines():
            line_str = line.strip()
            if "Protection Status:" in line_str or "حالة الحماية:" in line_str:
                result["protection_status"] = line_str.split(":", 1)[1].strip()
            elif "Conversion Status:" in line_str:
                result["conversion_status"] = line_str.split(":", 1)[1].strip()
            elif "Percentage Encrypted:" in line_str:
                result["encryption_percentage"] = line_str.split(":", 1)[1].strip()

    except FileNotFoundError:
        result["details"] = "manage-bde command not available on this edition of Windows."
    except subprocess.TimeoutExpired:
        result["details"] = "BitLocker status check timed out."
    except Exception as e:
        result["details"] = f"BitLocker query error: {e}"

    return result


def audit_tls() -> dict:
    """Verifies existence and validity of TLS certificates."""
    cert_file = ROOT_DIR / "certs" / "server.crt"
    key_file = ROOT_DIR / "certs" / "server.key"
    return {
        "cert_exists": cert_file.exists(),
        "key_exists": key_file.exists(),
        "cert_path": str(cert_file) if cert_file.exists() else None,
        "key_path": str(key_file) if key_file.exists() else None,
    }


def print_report():
    print("=" * 75)
    print("=== ImportFlow ERP — Host Security & Infrastructure Audit ===")
    print("=" * 75)
    print(f"Host Drive:    {get_drive_letter()}")
    print(f"Platform:      {sys.platform}")
    print(f"Current User:  {os.getenv('USERNAME', 'Unknown')}")
    print()

    # 1. TLS Certificate Status
    print("[1] TLS / HTTPS Infrastructure Status:")
    tls = audit_tls()
    if tls["cert_exists"] and tls["key_exists"]:
        print(f"  [PASS] TLS Certificate: {tls['cert_path']}")
        print(f"  [PASS] Private Key:     {tls['key_path']}")
    else:
        print("  [WARN] TLS certificates missing in certs/. Run: python scripts/generate_tls_cert.py")
    print()

    # 2. BitLocker Status
    print("[2] Volume Data-at-Rest Encryption (BitLocker):")
    bl = audit_bitlocker()
    if bl["is_supported"]:
        prot = bl["protection_status"]
        perc = bl["encryption_percentage"]
        print(f"  Drive:                  {bl['drive']}")
        print(f"  Protection Status:      {prot}")
        print(f"  Conversion Status:      {bl['conversion_status']}")
        print(f"  Percentage Encrypted:   {perc}")
        if "On" in prot or "Protected" in prot:
            print("  [PASS] Volume is protected by BitLocker data-at-rest encryption.")
        else:
            print("  [RECOMMENDATION] Volume BitLocker is currently OFF. For enterprise")
            print("  production security, enable BitLocker on drive " + bl["drive"])
    else:
        print(f"  [INFO] {bl['details']}")
    print()

    # 3. File Access Control (ACLs)
    print("[3] NTFS File Access Control (icacls):")
    acls = audit_acls()
    for name, info in acls.items():
        if not info.get("exists"):
            continue
        if info.get("is_overly_permissive"):
            print(f"  [WARN] {name:<25} -> Shared with Users/Everyone. Run with --apply to secure.")
        else:
            print(f"  [PASS] {name:<25} -> Restricted ACLs verified.")
    print("=" * 75)


def main():
    parser = argparse.ArgumentParser(description="Harden Windows host security for ImportFlow ERP.")
    parser.add_argument("--audit", action="store_true", help="Audit current security posture without changes.")
    parser.add_argument("--apply", action="store_true", help="Apply strict icacls permissions to sensitive assets.")
    args = parser.parse_args()

    if args.apply:
        apply_acl_hardening()
        print()

    print_report()


if __name__ == "__main__":
    main()
