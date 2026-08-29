"""
Sorour Logistics ERP — Automated Sequential Version & Build Manager
===================================================================
Automatically increments version and build numbers sequentially across
all backend, frontend, installer, and packaging files.

Usage:
    python version_manager.py bump [patch|minor|major]
    python version_manager.py get
"""
import sys
import json
import re
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(__file__).resolve().parent
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
        "patch": 3,
        "version": "1.0.3",
        "build_number": 4,
        "updated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }


def save_version_info(info):
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        json.dump(info, f, indent=2, ensure_ascii=False)


def extract_recent_release_notes():
    """Extracts top 3-5 latest feature highlights and task completions from history/."""
    history_dir = ROOT_DIR / "history"
    if not history_dir.exists():
        return [
            "تحسينات شاملة في أداء النظام واستقرار قاعدة البيانات",
            "تحديثات في محرك استخراج وثائق الشحن والجمارك",
            "ترقية وتطوير واجهات الاستيراد ومطابقة البيانات",
        ]
    
    files = sorted(history_dir.glob("*.md"), reverse=True)
    notes = []
    for f in files:
        try:
            content = f.read_text(encoding="utf-8")
            matches = re.findall(r"##\s*📝\s*\[[^\]]+\]\s*-\s*Completed\s+Task:\s*([^\n\r]+)", content, re.IGNORECASE)
            for m in reversed(matches):
                clean_title = m.strip()
                # Clean any task codes like (AI-EXTRACT-003) or (BP-001) for cleaner display
                clean_title = re.sub(r"\([A-Z0-9\-_/]+\)", "", clean_title).strip()
                if clean_title and clean_title not in notes:
                    notes.append(clean_title)
                if len(notes) >= 4:
                    break
        except Exception:
            continue
        if len(notes) >= 4:
            break

    if not notes:
        return [
            "تحسينات شاملة في أداء النظام واستقرار قاعدة البيانات",
            "تحديثات في محرك استخراج وثائق الشحن والجمارك",
            "ترقية وتطوير واجهات الاستيراد ومطابقة البيانات",
        ]
    return notes


def bump_version(bump_type="patch"):
    info = get_current_version_info()
    old_version = info.get("version", "1.0.0")
    old_build = info.get("build_number", 1)

    if bump_type == "major":
        info["major"] = info.get("major", 1) + 1
        info["minor"] = 0
        info["patch"] = 0
    elif bump_type == "minor":
        info["minor"] = info.get("minor", 0) + 1
        info["patch"] = 0
    elif bump_type == "build_only":
        pass
    else:  # patch (default)
        info["patch"] = info.get("patch", 0) + 1

    info["build_number"] = old_build + 1
    new_version = f"{info['major']}.{info['minor']}.{info['patch']}"
    info["version"] = new_version
    info["release_notes"] = extract_recent_release_notes()
    info["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    save_version_info(info)
    print(f"[SEQUENTIAL VERSION BUMP] v{old_version} (Build {old_build}) -> v{new_version} (Build {info['build_number']})")

    # 1. Update frontend/pubspec.yaml
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
        content = re.sub(r'#define MyAppName "[^"]+"', '#define MyAppName "Sorour Logistics"', content)
        content = re.sub(r'OutputBaseFilename=.*', f'OutputBaseFilename=Sorour_Logistics_Setup_v{new_version}', content)
        iss_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated installer/importflow_setup.iss -> v{new_version}")

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
        content = re.sub(r"'v[\d\.]+\s*\(Build\s*[^']+\)'", f"'v{new_version} (Build {info['build_number']})'", content)
        content = re.sub(r"'v[\d\.]+\s*\(Release\)'", f"'v{new_version} (Release)'", content)
        content = re.sub(r"'Build\s*[\d\.\+]+'", f"'Build {new_version}+{info['build_number']}'", content)
        home_screen_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated home_screen.dart -> v{new_version} (Build {info['build_number']})")

    # 6. Update frontend/windows/runner/main.cpp
    main_cpp_path = ROOT_DIR / "frontend" / "windows" / "runner" / "main.cpp"
    if main_cpp_path.exists():
        content = main_cpp_path.read_text(encoding="utf-8")
        content = re.sub(r"\(v[\d\.]+\)", f"(v{new_version})", content)
        main_cpp_path.write_text(content, encoding="utf-8")
        print(f"  [+] Updated windows/runner/main.cpp -> v{new_version}")

    return info


if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "bump":
        b_type = sys.argv[2] if len(sys.argv) > 2 else "patch"
        bump_version(b_type)
    else:
        info = get_current_version_info()
        print(f"Current version: v{info.get('version', '1.0.0')} (Build {info.get('build_number', 1)})")
