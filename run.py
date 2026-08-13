#!/usr/bin/env python3

import os
import sys
import subprocess
import platform
import shutil
import ctypes
import pathlib

ENGINE_DIR = pathlib.Path(__file__).parent.resolve()
DEPS_DIR = ENGINE_DIR / "deps"

SYSTEM = platform.system()


def color(text, code):
    if SYSTEM == "Windows":
        os.system("")
    return f"\033[{code}m{text}\033[0m"

def green(t): return color(t, "92")
def red(t): return color(t, "91")
def yellow(t): return color(t, "93")
def cyan(t): return color(t, "96")
def dim(t): return color(t, "2")
def bold(t): return color(t, "1")

def info(msg): print(f"  {msg}")
def ok(msg): print(green(f"  [OK] {msg}"))
def warn(msg): print(yellow(f"  [!!] {msg}"))
def fail(msg): print(red(f"  [ERR] {msg}"))


def run(cmd, **kwargs):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120, **kwargs)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "timeout"
    except FileNotFoundError:
        return -1, "", "not found"


def which(name):
    return shutil.which(name) is not None


def check_command(cmd):
    try:
        r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False



def find_luajit():
    for name in ["luajit", "luajit-2.1.0-beta3"]:
        p = shutil.which(name)
        if p:
            return p
    if SYSTEM == "Windows":
        bundled = DEPS_DIR / "luajit.exe"
        if bundled.exists():
            return str(bundled)
    return None


def find_compiler():
    if SYSTEM == "Windows":
        for cmd in [["gcc", "--version"], ["cl"], ["clang", "--version"]]:
            if check_command(cmd):
                return cmd[0]
        return None
    else:
        for cc in ["cc", "gcc", "clang"]:
            if which(cc):
                return cc
        return None


def check_system_dep_linux(name, pkg_config_name=None):
    if pkg_config_name:
        rc, _, _ = run(["pkg-config", "--exists", pkg_config_name])
        if rc == 0:
            return True
    return which(name)


def ensure_deps():
    print()
    print(bold("  Checking dependencies..."))
    print()

    lj = find_luajit()
    if lj:
        rc, out, _ = run([lj, "-v"])
        ok(f"LuaJIT: {out}")
    else:
        fail("LuaJIT not found!")
        info("Install instructions:")
        if SYSTEM == "Darwin":
            info("  brew install luajit")
        elif SYSTEM == "Linux":
            info("  sudo apt install luajit")
        elif SYSTEM == "Windows":
            info("  scoop install luajit")
            info("  Or download from: https://luajit.org/download.html")
        return False

    cc = find_compiler()
    if cc:
        ok(f"Compiler: {cc}")
    else:
        warn("No C compiler found (needed for stb libraries)")

    if SYSTEM == "Darwin":
        if which("brew"):
            rc, out, _ = run(["brew", "list", "glfw"])
            if rc == 0:
                ok("GLFW (brew)")
            else:
                warn("GLFW not found. Install: brew install glfw")
        else:
            warn("Homebrew not found, can't check GLFW")
    elif SYSTEM == "Linux":
        if check_system_dep_linux("libglfw3", "glfw3"):
            ok("GLFW")
        else:
            warn("GLFW not found. Install: sudo apt install libglfw3-dev")
    elif SYSTEM == "Windows":
        dll = DEPS_DIR / "glfw3.dll"
        if dll.exists():
            ok("GLFW (bundled)")
        elif which("vcpkg"):
            warn("GLFW DLL not in deps/. Use: vcpkg install glfw3")
        else:
            warn("GLFW DLL not found in deps/")

    if SYSTEM == "Darwin":
        if which("brew"):
            rc, _, _ = run(["brew", "list", "assimp"])
            if rc == 0:
                ok("Assimp (brew)")
            else:
                warn("Assimp not found. Install: brew install assimp")
    elif SYSTEM == "Linux":
        if check_system_dep_linux("libassimp", "assimp"):
            ok("Assimp")
        else:
            warn("Assimp not found. Install: sudo apt install libassimp-dev")
    elif SYSTEM == "Windows":
        dll = DEPS_DIR / "assimp.dll"
        if dll.exists():
            ok("Assimp (bundled)")
        else:
            warn("Assimp DLL not found in deps/")

    if SYSTEM == "Darwin":
        ok("OpenAL (built-in on macOS)")
    elif SYSTEM == "Linux":
        if check_system_dep_linux("libopenal", "openal"):
            ok("OpenAL")
        else:
            warn("OpenAL not found. Install: sudo apt install libopenal-dev")
    elif SYSTEM == "Windows":
        dll = DEPS_DIR / "OpenAL32.dll"
        if dll.exists():
            ok("OpenAL (bundled)")
        else:
            warn("OpenAL DLL not found in deps/")

    stb_ok = True
    if SYSTEM == "Darwin":
        if not (DEPS_DIR / "libstb_image.dylib").exists():
            stb_ok = False
        if not (DEPS_DIR / "libstb_truetype.dylib").exists():
            stb_ok = False
    elif SYSTEM == "Linux":
        if not (DEPS_DIR / "libstb_image.so").exists():
            stb_ok = False
        if not (DEPS_DIR / "libstb_truetype.so").exists():
            stb_ok = False
    elif SYSTEM == "Windows":
        if not (DEPS_DIR / "stb_image.dll").exists():
            stb_ok = False
        if not (DEPS_DIR / "stb_truetype.dll").exists():
            stb_ok = False

    if stb_ok:
        ok("stb libraries (built)")
    else:
        warn("stb libraries not built")

    return lj is not None


def build_stb():
    print()
    print(bold("  Building stb libraries..."))
    print()

    cc = find_compiler()
    if not cc:
        fail("No C compiler found. Cannot build stb libraries.")
        info("Install gcc/clang and try again.")
        return False

    build_script = DEPS_DIR / ("build.bat" if SYSTEM == "Windows" else "build.sh")

    if SYSTEM == "Windows":
        if which("gcc"):
            for lib in ["stb_image", "stb_truetype"]:
                src = DEPS_DIR / f"{lib}_impl.c"
                out = DEPS_DIR / f"{lib}.dll"
                rc, _, err = run(["gcc", "-shared", "-o", str(out), str(src), f"-I{DEPS_DIR}", "-lm"])
                if rc == 0 and out.exists():
                    ok(f"{lib}.dll")
                else:
                    fail(f"{lib}.dll: {err}")
        else:
            warn("Need gcc to build stb on Windows")
            return False
    else:
        flags = "-shared -framework CoreServices" if SYSTEM == "Darwin" else "-shared -lm"
        for lib in ["stb_image", "stb_truetype"]:
            src = DEPS_DIR / f"{lib}_impl.c"
            ext = "dylib" if SYSTEM == "Darwin" else "so"
            prefix = "lib" if SYSTEM != "Windows" else ""
            out = DEPS_DIR / f"{prefix}{lib}.{ext}"
            cmd = [cc, "-shared", "-o", str(out), str(src), f"-I{DEPS_DIR}"] + flags.split()
            rc, _, err = run(cmd)
            if rc == 0 and out.exists():
                ok(f"{prefix}{lib}.{ext}")
            else:
                fail(f"{prefix}{lib}.{ext}: {err}")
                return False

    return True


def set_library_path():
    deps = str(DEPS_DIR)

    if SYSTEM == "Darwin":
        var = "DYLD_LIBRARY_PATH"
    else:
        var = "LD_LIBRARY_PATH"

    current = os.environ.get(var, "")
    if deps not in current:
        os.environ[var] = deps + (":" + current if current else "")


def launch_engine(script="main.lua", extra_args=None):
    lj = find_luajit()
    if not lj:
        fail("LuaJIT not found. Cannot launch engine.")
        return False

    set_library_path()

    cmd = [lj, script] + (extra_args or [])
    print()
    print(bold("  Launching MioEngine..."))
    print(dim(f"  > {' '.join(cmd)}"))
    print()

    try:
        proc = subprocess.run(cmd, cwd=str(ENGINE_DIR))
        return proc.returncode == 0
    except KeyboardInterrupt:
        print()
        info("Engine stopped.")
        return True


def install_deps_interactive():
    print()
    print(bold("  Installing dependencies..."))
    print()

    if SYSTEM == "Darwin":
        if not which("brew"):
            fail("Homebrew not found. Install from: https://brew.sh")
            return False
        pkgs = ["luajit", "glfw", "assimp"]
        info(f"Running: brew install {' '.join(pkgs)}")
        rc, out, err = run(["brew", "install"] + pkgs)
        if rc == 0:
            ok("Installed via Homebrew")
            return True
        else:
            fail(f"brew install failed: {err}")
            return False

    elif SYSTEM == "Linux":
        pkgs = ["luajit", "libglfw3-dev", "libassimp-dev", "libopenal-dev"]
        info(f"Running: sudo apt install -y {' '.join(pkgs)}")
        rc, out, err = run(["sudo", "apt", "install", "-y"] + pkgs)
        if rc == 0:
            ok("Installed via apt")
            return True
        else:
            fail(f"apt install failed: {err}")
            info("Try: sudo apt update first")
            return False

    elif SYSTEM == "Windows":
        info("On Windows, install dependencies manually:")
        info("  scoop install luajit")
        info("  Or download DLLs into deps/:")
        info("    GLFW:  https://www.glfw.org/download")
        info("    Assimp: https://github.com/assimp/assimp/releases")
        info("    OpenAL: https://openal-soft.org/openal-binaries/")
        return False

    return False


BANNER = r"""
		MIOENGINE LAUNCH
"""

def main_menu():
    while True:
        print()
        print(cyan(BANNER))
        print(dim(f"  Cross-Platform Launcher"))
        print(dim(f"  OS: {SYSTEM} {platform.release()}"))
        print()

        print(bold("  Commands:\n"))
        print(f"  {cyan('1')}  Run engine       - launch main.lua")
        print(f"  {cyan('2')}  Run editor       - launch editor_main.lua")
        print(f"  {cyan('3')}  Check deps       - verify all dependencies")
        print(f"  {cyan('4')}  Build stb libs   - compile stb_image/stb_truetype")
        print(f"  {cyan('5')}  Install deps     - auto-install via package manager")
        print(f"  {cyan('6')}  Run custom script - launch a specific .lua file")
        print(f"  {cyan('0')}  Exit")
        print()

        choice = input(f"  {dim('>')} ").strip()

        if choice == "1":
            launch_engine("main.lua")
        elif choice == "2":
            launch_engine("editor_main.lua")
        elif choice == "3":
            ensure_deps()
            input("\n  Press Enter to continue...")
        elif choice == "4":
            build_stb()
            input("\n  Press Enter to continue...")
        elif choice == "5":
            install_deps_interactive()
            input("\n  Press Enter to continue...")
        elif choice == "6":
            path = input("  Path to .lua file: ").strip()
            if path and os.path.isfile(path):
                launch_engine(path)
            elif path:
                fail(f"File not found: {path}")
                input("\n  Press Enter to continue...")
        elif choice == "0":
            print(dim("\n  Bye!"))
            break
        else:
            print(red(f"  Unknown: {choice}"))


if __name__ == "__main__":
    if len(sys.argv) > 1:
        script = sys.argv[1]
        if script in ("--check", "-c"):
            ensure_deps()
        elif script in ("--build", "-b"):
            build_stb()
        elif script in ("--install", "-i"):
            install_deps_interactive()
        elif script in ("--help", "-h"):
            print("Usage: python run.py [script.lua|--check|--build|--install]")
        else:
            if not os.path.isfile(script):
                script = str(ENGINE_DIR / script)
            launch_engine(script, sys.argv[2:])
    else:
        try:
            main_menu()
        except KeyboardInterrupt:
            print(dim("\n  Bye!"))
