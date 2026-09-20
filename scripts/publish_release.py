"""
Sorour Logistics ERP — Release & Version Manager
Automates version bumping, single-source-of-truth synchronization across all project files,
release packaging verification, and rollback control.
"""
import os
import re
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(__file__).resolve().parent.parent
VERSION_JSON = ROOT_DIR / "version.json"
PUBSPEC_YAML = ROOT_DIR / "frontend" / "pubspec.yaml"
INNO_ISS = ROOT_DIR / "installer" / "importflow_setup.iss"
API_CONSTANTS = ROOT_DIR / "frontend" / "lib" / "core" / "constants" / "api_constants.dart"
RELEASES_DIR = ROOT_DIR / "dist" / "releases"


def load_version_json():
    if not VERSION_JSON.exists():
        raise FileNotFoundError(f"Missing {VERSION_JSON}")
    with open(VERSION_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


def save_version_json(data):
    with open(VERSION_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def parse_semver(v_str):
    parts = v_str.strip().split(".")
    if len(parts) != 3:
        raise ValueError(f"Invalid semver: {v_str}")
    return int(parts[0]), int(parts[1]), int(parts[2])


def sync_pubspec_yaml(version_str, build_number):
    if not PUBSPEC_YAML.exists():
        return False
    content = PUBSPEC_YAML.read_text(encoding="utf-8")
    new_content = re.sub(
        r"^version:\s*[\d\.\+]+",
        f"version: {version_str}+{build_number}",
        content,
        flags=re.MULTILINE,
    )
    PUBSPEC_YAML.write_text(new_content, encoding="utf-8")
    return True


def sync_inno_setup(version_str):
    if not INNO_ISS.exists():
        return False
    content = INNO_ISS.read_text(encoding="utf-8")
    content = re.sub(
        r'#define MyAppVersion\s*"[^"]+"',
        f'#define MyAppVersion "{version_str}"',
        content,
    )
    content = re.sub(
        r"OutputBaseFilename=Sorour_Logistics_Setup_v[^\r\n]+",
        f"OutputBaseFilename=Sorour_Logistics_Setup_v{version_str}",
        content,
    )
    INNO_ISS.write_text(content, encoding="utf-8")
    return True


def sync_api_constants(version_str, build_number):
    if not API_CONSTANTS.exists():
        return False
    content = API_CONSTANTS.read_text(encoding="utf-8")
    if "clientVersion" not in content:
        content = re.sub(
            r"class ApiConstants\s*\{",
            f"class ApiConstants {{\n  static const String clientVersion = '{version_str}';\n  static const int clientBuildNumber = {build_number};\n",
            content,
        )
    else:
        content = re.sub(
            r"static const String clientVersion\s*=\s*'[^']+';",
            f"static const String clientVersion = '{version_str}';",
            content,
        )
        content = re.sub(
            r"static const int clientBuildNumber\s*=\s*\d+;",
            f"static const int clientBuildNumber = {build_number};",
            content,
        )
    API_CONSTANTS.write_text(content, encoding="utf-8")
    return True


def bump_version(bump_type="patch", release_notes=None, min_compatible_version=None):
    data = load_version_json()
    major = data.get("major", 1)
    minor = data.get("minor", 0)
    patch = data.get("patch", 0)
    build_number = data.get("build_number", 1) + 1

    if bump_type == "major":
        major += 1
        minor = 0
        patch = 0
    elif bump_type == "minor":
        minor += 1
        patch = 0
    elif bump_type == "patch":
        patch += 1

    version_str = f"{major}.{minor}.{patch}"
    data["major"] = major
    data["minor"] = minor
    data["patch"] = patch
    data["version"] = version_str
    data["build_number"] = build_number
    data["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    if min_compatible_version:
        data["min_compatible_version"] = min_compatible_version
    elif "min_compatible_version" not in data:
        data["min_compatible_version"] = f"{major}.{minor}.0"

    installer_fn = f"Sorour_Logistics_Setup_v{version_str}.exe"
    data["installer_filename"] = installer_fn
    data["installer_url"] = (
        f"https://github.com/ahmedsalahsorour88/import_flow/releases/download/v{version_str}/{installer_fn}"
    )

    if release_notes:
        if isinstance(release_notes, str):
            data["release_notes"] = [n.strip() for n in release_notes.split(";") if n.strip()]
        elif isinstance(release_notes, list):
            data["release_notes"] = release_notes

    save_version_json(data)
    sync_pubspec_yaml(version_str, build_number)
    sync_inno_setup(version_str)
    sync_api_constants(version_str, build_number)

    print(f"[SUCCESS] Version bumped to v{version_str} (Build {build_number})")
    print(f" - Updated {VERSION_JSON.name}")
    print(f" - Updated {PUBSPEC_YAML.name}")
    print(f" - Updated {INNO_ISS.name}")
    print(f" - Updated {API_CONSTANTS.name}")
    return version_str, build_number


def check_version_status():
    data = load_version_json()
    canonical_version = data.get("version", "unknown")
    canonical_build = data.get("build_number", 0)
    min_compatible = data.get("min_compatible_version", "unknown")

    print("================================================================================")
    print("           Sorour Logistics ERP — System Version Status & Drift Audit           ")
    print("================================================================================")
    print(f" Canonical Source (`version.json`) : v{canonical_version} (Build {canonical_build})")
    print(f" Minimum Compatible Version         : v{min_compatible}")
    print(f" Last Updated                       : {data.get('updated_at', 'unknown')}")
    print(f" Installer Target                   : {data.get('installer_filename', 'unknown')}")
    print("--------------------------------------------------------------------------------")

    drift_found = False

    # Check pubspec.yaml
    if PUBSPEC_YAML.exists():
        match = re.search(r"^version:\s*([^\r\n]+)", PUBSPEC_YAML.read_text(encoding="utf-8"), re.MULTILINE)
        pubspec_ver = match.group(1).strip() if match else "NOT FOUND"
        expected = f"{canonical_version}+{canonical_build}"
        status = "[MATCH]" if pubspec_ver == expected else "[DRIFT DETECTED]"
        if status != "[MATCH]":
            drift_found = True
        print(f" {status:<18} frontend/pubspec.yaml        : {pubspec_ver} (Expected: {expected})")

    # Check inno iss
    if INNO_ISS.exists():
        match = re.search(r'#define MyAppVersion\s*"([^"]+)"', INNO_ISS.read_text(encoding="utf-8"))
        iss_ver = match.group(1).strip() if match else "NOT FOUND"
        status = "[MATCH]" if iss_ver == canonical_version else "[DRIFT DETECTED]"
        if status != "[MATCH]":
            drift_found = True
        print(f" {status:<18} installer/importflow_setup.iss: v{iss_ver} (Expected: v{canonical_version})")

    # Check ApiConstants
    if API_CONSTANTS.exists():
        match = re.search(r"clientVersion\s*=\s*'([^']+)'", API_CONSTANTS.read_text(encoding="utf-8"))
        dart_ver = match.group(1).strip() if match else "NOT FOUND"
        status = "[MATCH]" if dart_ver == canonical_version else "[DRIFT DETECTED]"
        if status != "[MATCH]":
            drift_found = True
        print(f" {status:<18} api_constants.dart             : v{dart_ver} (Expected: v{canonical_version})")

    print("================================================================================")
    if not drift_found:
        print(" [STATUS] ALL FILES SYNCHRONIZED — ZERO VERSION DRIFT DETECTED.")
    else:
        print(" [WARNING] VERSION DRIFT DETECTED. Run `python scripts/publish_release.py --sync` to fix.")
    print("================================================================================")
    return not drift_found


def sync_all():
    data = load_version_json()
    v = data.get("version", "1.0.198")
    b = data.get("build_number", 199)
    sync_pubspec_yaml(v, b)
    sync_inno_setup(v)
    sync_api_constants(v, b)
    print(f"[SUCCESS] Synchronized all project files to canonical v{v} (Build {b}).")
    check_version_status()


def rollback_to(target_version):
    major, minor, patch = parse_semver(target_version)
    data = load_version_json()
    build_number = data.get("build_number", 1) + 1
    data["major"] = major
    data["minor"] = minor
    data["patch"] = patch
    data["version"] = target_version
    data["build_number"] = build_number
    data["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    installer_fn = f"Sorour_Logistics_Setup_v{target_version}.exe"
    data["installer_filename"] = installer_fn
    data["installer_url"] = (
        f"https://github.com/ahmedsalahsorour88/import_flow/releases/download/v{target_version}/{installer_fn}"
    )
    save_version_json(data)
    sync_pubspec_yaml(target_version, build_number)
    sync_inno_setup(target_version)
    sync_api_constants(target_version, build_number)
    print(f"[SUCCESS] Rollback executed. System active release set to v{target_version} (Build {build_number}).")
    check_version_status()


def main():
    parser = argparse.ArgumentParser(description="Sorour Logistics ERP Release & Version Publisher")
    parser.add_argument("--status", action="store_true", help="Check current version across all project files")
    parser.add_argument("--sync", action="store_true", help="Sync all files with version.json")
    parser.add_argument("--bump", choices=["patch", "minor", "major"], help="Bump version type")
    parser.add_argument("--notes", type=str, help="Release notes semicolon-separated")
    parser.add_argument("--min-compat", type=str, help="Minimum compatible client version")
    parser.add_argument("--rollback-to", type=str, help="Set active release back to a previous version")

    args = parser.parse_args()

    if args.status:
        check_version_status()
    elif args.sync:
        sync_all()
    elif args.bump:
        bump_version(args.bump, release_notes=args.notes, min_compatible_version=args.min_compat)
    elif args.rollback_to:
        rollback_to(args.rollback_to)
    else:
        check_version_status()


if __name__ == "__main__":
    main()
