#!/usr/bin/env python3
"""
Build script for mioengine — packages game for macOS, Windows, Ubuntu.
Downloads Love2D, bundles engine + game + assets into distributable.
"""

import os
import sys
import shutil
import zipfile
import urllib.request
import subprocess
import platform
import json

# ── Config ──────────────────────────────────────────────────────────────
LOVE_VERSION = "11.5"
LOVE_VERSION_FULL = "11.5"
GAME_NAME = "mioengine"
GAME_TITLE = "mioengine"

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_DIR = os.path.join(PROJECT_ROOT, "install", "build")
DIST_DIR = os.path.join(PROJECT_ROOT, "install", "dist")

# Love2D download URLs
LOVE_URLS = {
    "macos-arm64": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-macos-arm64.zip",
    "macos-x64": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-macos-x64.zip",
    "windows-x64": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-win64.zip",
    "windows-x86": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-win32.zip",
    "linux-x64": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-linux-x86_64.AppImage",
    "linux-arm64": f"https://github.com/love2d/love/releases/download/{LOVE_VERSION_FULL}/love-{LOVE_VERSION_FULL}-linux-aarch64.AppImage",
}

GAME_DIRS = ["mioengine", "game", "models", "assets"]
GAME_FILES = ["main.lua", "conf.lua"]


def log(msg):
    print(f"\033[36m→\033[0m {msg}")


def error(msg):
    print(f"\033[31m✗ ERROR:\033[0m {msg}")
    sys.exit(1)


def run(cmd, **kwargs):
    log(f"  $ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, **kwargs)
    if result.returncode != 0:
        error(f"Command failed:\n{result.stderr}")
    return result


def download(url, dest):
    log(f"Downloading: {url}")
    if os.path.exists(dest):
        log("  (cached)")
        return dest
    urllib.request.urlretrieve(url, dest)
    return dest


def copy_game_files(dest_dir):
    """Copy engine, game, models, assets into dest_dir."""
    for d in GAME_DIRS:
        src = os.path.join(PROJECT_ROOT, d)
        dst = os.path.join(dest_dir, d)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
    for f in GAME_FILES:
        src = os.path.join(PROJECT_ROOT, f)
        dst = os.path.join(dest_dir, f)
        if os.path.isfile(src):
            shutil.copy2(src, dst)


# ════════════════════════════════════════════════════════════════════════
#  macOS
# ════════════════════════════════════════════════════════════════════════
def build_macos():
    log("═══ Building macOS ═══")
    arch = "arm64" if platform.machine() == "arm64" else "x64"
    key = f"macos-{arch}"

    love_zip = os.path.join(BUILD_DIR, f"love-macos-{arch}.zip")
    download(LOVE_URLS[key], love_zip)

    # Unzip Love2D
    love_dir = os.path.join(BUILD_DIR, "love-macos")
    if os.path.exists(love_dir):
        shutil.rmtree(love_dir)
    os.makedirs(love_dir)
    with zipfile.ZipFile(love_zip, "r") as zf:
        zf.extractall(love_dir)

    # Find Love.app
    love_app = None
    for root, dirs, files in os.walk(love_dir):
        if root.endswith(".app"):
            love_app = root
            break
    if not love_app:
        # Try finding it
        for item in os.listdir(love_dir):
            if item.endswith(".app"):
                love_app = os.path.join(love_dir, item)
                break
    if not love_app:
        error("Could not find Love.app in downloaded archive")

    # Create .app bundle
    app_name = f"{GAME_NAME}.app"
    app_dir = os.path.join(DIST_DIR, "macos", app_name)
    if os.path.exists(app_dir):
        shutil.rmtree(app_dir)

    log(f"Creating {app_name}...")
    shutil.copytree(love_app, app_dir)

    # Find the actual love binary inside the bundle
    love_bin = os.path.join(app_dir, "Contents", "MacOS", "love")
    if not os.path.exists(love_bin):
        # Some versions have it differently
        for item in os.listdir(os.path.join(app_dir, "Contents", "MacOS")):
            if "love" in item.lower():
                love_bin = os.path.join(app_dir, "Contents", "MacOS", item)
                break

    # Create game.love (zip of game files)
    game_love = os.path.join(BUILD_DIR, "game.love")
    with zipfile.ZipFile(game_love, "w", zipfile.ZIP_DEFLATED) as zf:
        for d in GAME_DIRS:
            src = os.path.join(PROJECT_ROOT, d)
            if os.path.isdir(src):
                for root, dirs, files in os.walk(src):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, PROJECT_ROOT)
                        zf.write(file_path, arcname)
        for f in GAME_FILES:
            src = os.path.join(PROJECT_ROOT, f)
            if os.path.isfile(src):
                zf.write(src, f)

    # Append game.love to love binary
    log("Patching love binary with game data...")
    with open(love_bin, "rb") as f:
        love_data = f.read()
    with open(game_love, "rb") as f:
        game_data = f.read()
    with open(love_bin, "wb") as f:
        f.write(love_data)
        f.write(game_data)
    os.chmod(love_bin, 0o755)

    # Update Info.plist
    plist_path = os.path.join(app_dir, "Contents", "Info.plist")
    if os.path.exists(plist_path):
        with open(plist_path, "r") as f:
            plist = f.read()
        plist = plist.replace("love2d.org", f"{GAME_NAME}")
        plist = plist.replace("LÖVE", GAME_TITLE)
        with open(plist_path, "w") as f:
            f.write(plist)

    log(f"✓ macOS build: {app_dir}")
    return app_dir


# ════════════════════════════════════════════════════════════════════════
#  Windows
# ════════════════════════════════════════════════════════════════════════
def build_windows():
    log("═══ Building Windows ═══")

    win_dir = os.path.join(DIST_DIR, "windows")
    os.makedirs(win_dir, exist_ok=True)

    for arch_key, arch_name in [("windows-x64", "win64"), ("windows-x86", "win32")]:
        love_zip = os.path.join(BUILD_DIR, f"love-{arch_name}.zip")
        download(LOVE_URLS[arch_key], love_zip)

        out_dir = os.path.join(win_dir, arch_name)
        if os.path.exists(out_dir):
            shutil.rmtree(out_dir)
        os.makedirs(out_dir)

        log(f"Extracting {arch_name}...")
        with zipfile.ZipFile(love_zip, "r") as zf:
            zf.extractall(out_dir)

        # Copy game files
        copy_game_files(out_dir)

        # Create .love file
        love_file = os.path.join(out_dir, f"{GAME_NAME}.love")
        with zipfile.ZipFile(love_file, "w", zipfile.ZIP_DEFLATED) as zf:
            for d in GAME_DIRS:
                src = os.path.join(PROJECT_ROOT, d)
                if os.path.isdir(src):
                    for root, dirs, files in os.walk(src):
                        for file in files:
                            file_path = os.path.join(root, file)
                            arcname = os.path.relpath(file_path, PROJECT_ROOT)
                            zf.write(file_path, arcname)
            for f in GAME_FILES:
                src = os.path.join(PROJECT_ROOT, f)
                if os.path.isfile(src):
                    zf.write(src, f)

        # Rename love.exe to game.exe
        love_exe = os.path.join(out_dir, "love.exe")
        game_exe = os.path.join(out_dir, f"{GAME_NAME}.exe")
        if os.path.exists(love_exe):
            shutil.copy2(love_exe, game_exe)

        # Create launcher batch
        batch_path = os.path.join(out_dir, "play.bat")
        with open(batch_path, "w") as f:
            f.write(f'@echo off\nstart "" "%~dp0{GAME_NAME}.exe" "%~dp0{GAME_NAME}.love"\n')

        log(f"✓ Windows {arch_name}: {out_dir}")

    return win_dir


# ════════════════════════════════════════════════════════════════════════
#  Linux (Ubuntu)
# ════════════════════════════════════════════════════════════════════════
def build_linux():
    log("═══ Building Linux ═══")

    linux_dir = os.path.join(DIST_DIR, "linux")
    os.makedirs(linux_dir, exist_ok=True)

    arch = "x64" if platform.machine() in ("x86_64", "AMD64") else "arm64"
    key = f"linux-{arch}"

    love_appimage = os.path.join(BUILD_DIR, f"love-linux-{arch}.AppImage")
    download(LOVE_URLS[key], love_appimage)
    os.chmod(love_appimage, 0o755)

    out_dir = os.path.join(linux_dir, f"{GAME_NAME}-{arch}")
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(out_dir)

    # Copy AppImage
    shutil.copy2(love_appimage, os.path.join(out_dir, f"{GAME_NAME}.AppImage"))

    # Copy game files
    copy_game_files(out_dir)

    # Create .love file
    love_file = os.path.join(out_dir, f"{GAME_NAME}.love")
    with zipfile.ZipFile(love_file, "w", zipfile.ZIP_DEFLATED) as zf:
        for d in GAME_DIRS:
            src = os.path.join(PROJECT_ROOT, d)
            if os.path.isdir(src):
                for root, dirs, files in os.walk(src):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, PROJECT_ROOT)
                        zf.write(file_path, arcname)
        for f in GAME_FILES:
            src = os.path.join(PROJECT_ROOT, f)
            if os.path.isfile(src):
                zf.write(src, f)

    # Create launcher script
    launcher = os.path.join(out_dir, "play.sh")
    with open(launcher, "w") as f:
        f.write(f"""#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/{GAME_NAME}.AppImage" "$DIR/{GAME_NAME}.love"
""")
    os.chmod(launcher, 0o755)

    # Create .desktop file
    desktop = os.path.join(out_dir, f"{GAME_NAME}.desktop")
    with open(desktop, "w") as f:
        f.write(f"""[Desktop Entry]
Name={GAME_TITLE}
Exec=bash play.sh
Type=Application
Categories=Game;
Terminal=false
""")

    # Package as tar.gz
    tar_path = os.path.join(linux_dir, f"{GAME_NAME}-linux-{arch}.tar.gz")
    log(f"Creating {tar_path}...")
    run(f"tar -czf '{tar_path}' -C '{linux_dir}' '{os.path.basename(out_dir)}'")

    log(f"✓ Linux {arch}: {out_dir}")
    return linux_dir


# ════════════════════════════════════════════════════════════════════════
#  Main
# ════════════════════════════════════════════════════════════════════════
def main():
    os.makedirs(BUILD_DIR, exist_ok=True)
    os.makedirs(DIST_DIR, exist_ok=True)

    targets = sys.argv[1:] if len(sys.argv) > 1 else ["macos", "windows", "linux"]

    log(f"Building {GAME_NAME} for: {', '.join(targets)}")
    log(f"Project root: {PROJECT_ROOT}")
    log(f"Output: {DIST_DIR}")

    results = {}

    if "macos" in targets:
        try:
            results["macos"] = build_macos()
        except Exception as e:
            error(f"macOS build failed: {e}")

    if "windows" in targets:
        try:
            results["windows"] = build_windows()
        except Exception as e:
            error(f"Windows build failed: {e}")

    if "linux" in targets:
        try:
            results["linux"] = build_linux()
        except Exception as e:
            error(f"Linux build failed: {e}")

    print("\n" + "═" * 50)
    log("BUILD COMPLETE")
    print("═" * 50)
    for platform_name, path in results.items():
        print(f"  {platform_name:10s} → {path}")

    print(f"\n\033[32mDistributables ready in: {DIST_DIR}\033[0m")


if __name__ == "__main__":
    main()
