"""
ImportFlow ERP — Automated Version Manager
Increments version numbers across all backend, frontend, installer, and packaging files.
Usage:
    python version_manager.py bump [patch|minor|major]
    python version_manager.py get
"""
import sys
import json
import re
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(r"C:\Users\Hp\Desktop\ImportFlow")
VERSION_FILE = ROOT_DIR / "version.json"


def get_current_version_info():
    if VERSION_FILE.exists():
        try:
            with open(VERSION_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "major": 1,
        "minor": 0,
        "patch": 0,
        "version": "1.0.0",
        "build_number": 1,
        "updated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }


def save_version_info(info):
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        json.dump(info, f, indent=2, ensure_ascii=False)


def bump_version(bump_type="patch"):
    info = get_current_version_info()
    old_version = info["version"]

    if bump_type == "major":
        info["major"] += 1
        info["minor"] = 0
        info["patch"] = 0
    elif bump_type == "minor":
        info["minor"] += 1
        info["patch"] = 0
    else:  # patch
        info["patch"] += 1

    info["build_number"] = info.get("build_number", 1) + 1
    new_version = f"{info['major']}.{info['minor']}.{info['patch']}"
    info["version"] = new_version
    info["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    save_version_info(info)
    print(f"[VERSION BUMP] {old_version} -> {new_version} (Build {info['build_number']})")

    # 1. Update pubspec.yaml
    pubspec_path = ROOT_DIR / "frontend" / "pubspec.yaml"
    if pubspec_path.exists():
        content = pubspec_path.read_text(encoding="utf-8")
        content = re.sub(r"version:\s*[\d\.\+\w]+", f"version: {new_version}+{info['build_number']}", content)
        pubspec_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated frontend/pubspec.yaml -> {new_version}+{info['build_number']}")

    # 2. Update installer/importflow_setup.iss
    iss_path = ROOT_DIR / "installer" / "importflow_setup.iss"
    if iss_path.exists():
        content = iss_path.read_text(encoding="utf-8")
        content = re.sub(r'#define MyAppVersion "[^"]+"', f'#define MyAppVersion "{new_version}"', content)
        iss_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated installer/importflow_setup.iss -> {new_version}")

    # 3. Update main.py
    main_py_path = ROOT_DIR / "main.py"
    if main_py_path.exists():
        content = main_py_path.read_text(encoding="utf-8")
        content = re.sub(r'version="[\d\.]+"', f'version="{new_version}"', content)
        content = re.sub(r'"version":\s*"[\d\.]+"', f'"version": "{new_version}"', content)
        main_py_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated main.py -> {new_version}")

    # 4. Update frontend/lib/main.dart
    main_dart_path = ROOT_DIR / "frontend" / "lib" / "main.dart"
    if main_dart_path.exists():
        content = main_dart_path.read_text(encoding="utf-8")
        content = re.sub(r"\(v[\d\.]+\)", f"(v{new_version})", content)
        main_dart_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated frontend/lib/main.dart -> v{new_version}")

    # 5. Update frontend/lib/features/home/home_screen.dart
    home_screen_path = ROOT_DIR / "frontend" / "lib" / "features" / "home" / "home_screen.dart"
    if home_screen_path.exists():
        content = home_screen_path.read_text(encoding="utf-8")
        content = re.sub(r"'v[\d\.]+\s*\(Build\s*[^']+\)'", f"'v{new_version} (Build {datetime.now().strftime('%Y.%m')})'", content)
        content = re.sub(r"'v[\d\.]+\s*\(Release\)'", f"'v{new_version} (Release)'", content)
        home_screen_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated home_screen.dart -> v{new_version}")

    # 6. Update frontend/windows/runner/main.cpp
    main_cpp_path = ROOT_DIR / "frontend" / "windows" / "runner" / "main.cpp"
    if main_cpp_path.exists():
        content = main_cpp_path.read_text(encoding="utf-8")
        content = re.sub(r"\(v[\d\.]+\)", f"(v{new_version})", content)
        main_cpp_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated windows/runner/main.cpp -> v{new_version}")

    return new_version


if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "bump":
        b_type = sys.argv[2] if len(sys.argv) > 2 else "patch"
        bump_version(b_type)
    else:
        info = get_current_version_info()
        print(f"Current version: {info['version']} (Build {info.get('build_number', 1)})")
