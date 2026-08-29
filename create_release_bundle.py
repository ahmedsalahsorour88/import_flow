"""
ImportFlow ERP — Release Bundle Generator
Packages the standalone build into a compressed ZIP file with a version manifest for easy distribution & server upload.
"""
import os
import sys
import json
import zipfile
import hashlib
from datetime import datetime
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
DIST_DIR = ROOT_DIR / "dist"
_STANDALONE_PRIMARY = DIST_DIR / "Sorour_Logistics_Standalone"
_STANDALONE_LEGACY = DIST_DIR / "ImportFlow_Standalone"
STANDALONE_DIR = _STANDALONE_PRIMARY if _STANDALONE_PRIMARY.exists() else _STANDALONE_LEGACY
RELEASES_DIR = DIST_DIR / "releases"


def get_version():
    pubspec_path = ROOT_DIR / "frontend" / "pubspec.yaml"
    if pubspec_path.exists():
        with open(pubspec_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("version:"):
                    return line.split(":")[1].strip().split("+")[0]
    return "1.0.0"


def calculate_sha256(file_path):
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()


def create_release_zip(version):
    RELEASES_DIR.mkdir(parents=True, exist_ok=True)
    zip_filename = f"ImportFlow_v{version}_Windows_Portable.zip"
    zip_path = RELEASES_DIR / zip_filename

    print("===============================================================================")
    print(f"       ImportFlow ERP - Packaging Release v{version} for Cloud/Server Upload    ")
    print("===============================================================================")

    if not STANDALONE_DIR.exists():
        print(f"[ERROR] Standalone directory not found at {STANDALONE_DIR}")
        print("Please run `build_production.bat` first.")
        return None

    print(f"[1/3] Compressing standalone package into: {zip_path.name}...")
    
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zipf:
        for root, dirs, files in os.walk(STANDALONE_DIR):
            for file in files:
                abs_file = Path(root) / file
                rel_path = abs_file.relative_to(DIST_DIR)
                zipf.write(abs_file, arcname=str(rel_path))

    size_mb = zip_path.stat().st_size / (1024 * 1024)
    print(f"      Compression complete! Size: {size_mb:.2f} MB")

    print("[2/3] Generating SHA256 Checksum...")
    checksum = calculate_sha256(zip_path)
    print(f"      SHA256: {checksum}")

    print("[3/3] Generating Version Manifest (`latest_release.json`)...")
    manifest = {
        "app_name": "ImportFlow ERP",
        "version": version,
        "release_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "package_name": zip_filename,
        "file_size_mb": round(size_mb, 2),
        "sha256": checksum,
        "platform": "Windows x64",
        "type": "Standalone Portable (No Python Required)",
        "download_url": f"https://your-server.com/downloads/{zip_filename}",
        "changelog": [
            "Full Stage 4 Separation: Original Documents Collection & CargoX Hub",
            "Shipment Stage Lifecycle Control (Hold & Resume at any stage)",
            "Embedded Standalone Backend Engine (No Python installation required)",
            "All-In-One Windows Desktop Native Client"
        ]
    }

    manifest_path = RELEASES_DIR / "latest_release.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=4, ensure_ascii=False)

    print(f"      Manifest created: {manifest_path}")

    print("===============================================================================")
    print(f"[SUCCESS] Release v{version} ready for upload!")
    print(f" - Compressed ZIP: {zip_path}")
    print(f" - Version Manifest: {manifest_path}")
    print("===============================================================================")
    return zip_path


def main():
    version = get_version()
    create_release_zip(version)


if __name__ == "__main__":
    main()
