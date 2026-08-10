#!/usr/bin/env python3

import os
import sys
import shutil
import subprocess
import platform
import time

ENGINE_NAME = "MioEngine"
ENGINE_VERSION = "0.1"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

COPY_DIRS = ["engine", "game", "deps"]
COPY_FILES = ["main.lua", "README.md", ".gitignore"]

LUAJIT_URL = {
    "Darwin": "https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz",
    "Linux": "https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz",
    "Windows": "https://luajit.org/download/LuaJIT-2.1.0-beta3.zip",
}

LOVE_URL = {
    "Darwin": "https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip",
    "Linux": None,
    "Windows": "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip",
}

DEPENDENCIES = {
    "Darwin": {
        "package_manager": "Homebrew",
        "install_cmd": "brew install",
        "packages": {
            "luajit": {"check": "luajit", "args": ["-v"], "critical": True},
            "glfw": {"check": "brew", "args": ["list", "glfw"], "critical": True},
            "assimp": {"check": "brew", "args": ["list", "assimp"], "critical": True},
            "love": {"check": "love", "args": ["--version"], "critical": False},
        },
    },
    "Linux": {
        "package_manager": "apt/pacman",
        "install_cmd": "sudo apt install -y",
        "packages": {
            "luajit": {"check": "luajit", "args": ["-v"], "critical": True},
            "libglfw3-dev": {"check": "pkg-config", "args": ["--exists", "glfw3"], "critical": True},
            "libassimp-dev": {"check": "pkg-config", "args": ["--exists", "assimp"], "critical": True},
            "libopenal-dev": {"check": "pkg-config", "args": ["--exists", "openal"], "critical": True},
            "love": {"check": "love", "args": ["--version"], "critical": False},
        },
    },
    "Windows": {
        "package_manager": "scoop/choco/vcpkg",
        "install_cmd": "scoop install",
        "packages": {
            "luajit": {"check": "luajit", "args": ["-v"], "critical": True},
            "glfw": {"check": "where", "args": ["glfw3.dll"], "critical": True},
            "assimp": {"check": "where", "args": ["assimp.dll"], "critical": True},
            "openal": {"check": "where", "args": ["OpenAL32.dll"], "critical": True},
            "love": {"check": "love", "args": ["--version"], "critical": False},
        },
    },
}


def clear():
    os.system("cls" if platform.system() == "Windows" else "clear")


def pause():
    input("\n  Нажмите Enter для продолжения...")


def color(text, code):
    if platform.system() == "Windows":
        os.system("")
    return f"\033[{code}m{text}\033[0m"


def bold(text):
    return color(text, "1")


def green(text):
    return color(text, "92")


def red(text):
    return color(text, "91")


def yellow(text):
    return color(text, "93")


def cyan(text):
    return color(text, "96")


def dim(text):
    return color(text, "2")


def check_command(cmd):
    try:
        r = subprocess.run(
            [cmd] if isinstance(cmd, str) else cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
        )
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def run_cmd(cmd, cwd=None):
    try:
        r = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=120,
        )
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "timeout"
    except FileNotFoundError:
        return -1, "", "command not found"



BANNER = r"""
    MIOENGINE
"""


def print_banner():
    print()
    print(cyan(BANNER))
    print(dim(f"  {ENGINE_NAME} v{ENGINE_VERSION} — CLI-менеджер"))
    print()


def create_project():
    clear()
    print_banner()
    print(bold("  [1] Создать новый проект\n"))

    dest = input("  Путь для нового проекта: ").strip()
    if not dest:
        print(red("  Ошибка: путь не может быть пустым"))
        pause()
        return

    dest = os.path.expanduser(dest)
    dest = os.path.abspath(dest)

    if os.path.exists(dest) and os.listdir(dest):
        confirm = input(yellow(f"  Папка '{dest}' не пустая. Продолжить? (y/N): ")).strip().lower()
        if confirm != "y":
            print(dim("  Отмена"))
            pause()
            return

    print()
    print(dim(f"  Копирование в {dest}..."))
    print()

    os.makedirs(dest, exist_ok=True)
    copied = 0

    for d in COPY_DIRS:
        src = os.path.join(SCRIPT_DIR, d)
        if not os.path.isdir(src):
            print(yellow(f"  Пропуск (нет): {d}/"))
            continue
        dst = os.path.join(dest, d)
        if os.path.exists(dst):
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print(green(f"  + {d}/"))
        copied += 1

    for f in COPY_FILES:
        src = os.path.join(SCRIPT_DIR, f)
        if not os.path.isfile(src):
            print(yellow(f"  Пропуск (нет): {f}"))
            continue
        shutil.copy2(src, os.path.join(dest, f))
        print(green(f"  + {f}"))
        copied += 1

    mioconf = os.path.join(SCRIPT_DIR, "game", "main.mioconf")
    if os.path.isfile(mioconf):
        print(green(f"  + game/main.mioconf (уже в game/)"))

    print()
    print(green(f"  Готово! Скопировано {copied} элементов в:"))
    print(f"  {bold(dest)}")
    print()
    print(dim(f"  Запуск:  cd {dest} && love ."))
    print(dim(f"  Или:     love \"{dest}\""))
    pause()


def test_project():
    clear()
    print_banner()
    print(bold("  [2] Проверить проект\n"))

    path = input("  Путь к папке проекта: ").strip()
    if not path:
        print(red("  Ошибка: путь не может быть пустым"))
        pause()
        return

    path = os.path.expanduser(path)
    path = os.path.abspath(path)

    if not os.path.isdir(path):
        print(red(f"  Ошибка: папка не найдена: {path}"))
        pause()
        return

    print()
    print(dim(f"  Проверка: {path}"))
    print()

    required = ["main.lua", "engine", "game"]
    optional = ["deps", "README.md", ".gitignore"]
    missing = []

    for item in required:
        full = os.path.join(path, item)
        if not os.path.exists(full):
            missing.append(item)
            print(red(f"  ✗ {item} — ОТСУТСТВУЕТ"))
        else:
            kind = "папка" if os.path.isdir(full) else "файл"
            print(green(f"  ✓ {item} ({kind})"))

    for item in optional:
        full = os.path.join(path, item)
        if os.path.exists(full):
            kind = "папка" if os.path.isdir(full) else "файл"
            print(green(f"  ✓ {item} ({kind})"))
        else:
            print(dim(f"  · {item} — нет (опционально)"))

    conf_path = os.path.join(path, "game", "main.mioconf")
    if os.path.isfile(conf_path):
        print(green(f"  ✓ game/main.mioconf"))
    else:
        print(red(f"  ✗ game/main.mioconf — ОТСУТСТВУЕТ"))
        missing.append("game/main.mioconf")

    scripts_dir = os.path.join(path, "game", "scripts")
    if os.path.isdir(scripts_dir):
        scripts = [f for f in os.listdir(scripts_dir) if f.endswith(".mio")]
        if scripts:
            print(green(f"  ✓ Скрипты MioLang: {', '.join(scripts)}"))
        else:
            print(yellow(f"  ⚠ Нет .mio скриптов в game/scripts/"))
    else:
        print(yellow(f"  ⚠ Папка game/scripts/ не найдена"))

    engine_modules = [
        "engine/main.lua",
        "engine/core/math.lua",
        "engine/core/camera.lua",
        "engine/core/input.lua",
        "engine/core/render/renderer.lua",
        "engine/core/render/mesh.lua",
        "engine/core/render/shader.lua",
        "engine/core/render/texture.lua",
        "engine/core/render/assimp.lua",
        "engine/core/scene/scene_graph.lua",
        "engine/core/scene/scene_manager.lua",
        "engine/lang/mio_lang.lua",
        "engine/lang/lexer.lua",
        "engine/lang/parser.lua",
        "engine/lang/evaluator.lua",
        "engine/lang/executor.lua",
    ]

    print()
    print(dim("  Проверка модулей движка:"))
    engine_ok = 0
    for mod in engine_modules:
        full = os.path.join(path, mod)
        if os.path.isfile(full):
            engine_ok += 1
        else:
            print(red(f"  ✗ {mod}"))

    if engine_ok == len(engine_modules):
        print(green(f"  ✓ Все {engine_ok} модулей движка на месте"))
    else:
        print(yellow(f"  ⚠ {engine_ok}/{len(engine_modules)} модулей движка"))

    shaders_dir = os.path.join(path, "game", "shaders")
    if os.path.isdir(shaders_dir):
        shaders = [f for f in os.listdir(shaders_dir) if f.endswith((".vert", ".frag", ".glsl"))]
        if shaders:
            print(green(f"  ✓ Шейдеры: {', '.join(shaders)}"))
        else:
            print(dim(f"  · Нет шейдеров в game/shaders/"))
    else:
        print(dim(f"  · Папка game/shaders/ не найдена"))

    print()
    print(dim("  Проверка системных зависимых библиотек:"))
    check_system_deps()

    print()
    if missing:
        print(red(f"  Проект неполный: отсутствуют {', '.join(missing)}"))
    else:
        print(green(f"  Проект в порядке!"))
        print()
        print(dim(f"  Запуск:  cd \"{path}\" && love ."))
        print(dim(f"  Или:     love \"{path}\""))

    pause()


def check_system_deps():
    system = platform.system()
    deps = DEPENDENCIES.get(system)
    if not deps:
        print(red(f"  Неподдерживаемая ОС: {system}"))
        return

    all_ok = True
    for name, info in deps["packages"].items():
        cmd = info["check"]
        args = info["args"]
        ok = check_command([cmd] + args)

        if ok:
            print(green(f"  ✓ {name}"))
        elif info["critical"]:
            print(red(f"  ✗ {name} — ОБЯЗАТЕЛЕН"))
            all_ok = False
        else:
            print(yellow(f"  ⚠ {name} — не найден (опционально)"))

    print()
    print(dim("  Проверка Lua/LuaJIT:"))

    luajit_ok = check_command(["luajit", "-v"])
    lua_ok = check_command(["lua", "-v"])
    lua51_ok = check_command(["lua5.1", "-v"])

    if luajit_ok:
        _, out, _ = run_cmd(["luajit", "-v"])
        print(green(f"  ✓ LuaJIT: {out}"))
    elif lua_ok:
        _, out, _ = run_cmd(["lua", "-v"])
        print(yellow(f"  ⚠ Lua (не LuaJIT): {out}"))
    elif lua51_ok:
        _, out, _ = run_cmd(["lua5.1", "-v"])
        print(yellow(f"  ⚠ Lua 5.1 (не LuaJIT): {out}"))
    else:
        print(red(f"  ✗ Lua/LuaJIT не найден"))
        all_ok = False

    love_ok = check_command(["love", "--version"])
    if love_ok:
        _, out, _ = run_cmd(["love", "--version"])
        print(green(f"  ✓ Love2D: {out}"))
    else:
        print(yellow(f"  ⚠ Love2D не найден (опционально для запуска .mio)"))

    py_ok = check_command(["python3", "--version"]) or check_command(["python", "--version"])
    if py_ok:
        print(green(f"  ✓ Python3"))
    else:
        print(dim(f"  · Python3 не найден (не критично)"))

    return all_ok


def check_dependencies():
    clear()
    print_banner()
    print(bold("  [3] Проверить зависимости\n"))

    system = platform.system()
    print(f"  ОС: {bold(platform.system())} {platform.release()}")
    print(f"  Архитектура: {platform.machine()}")
    print(f"  Python: {sys.version.split()[0]}")
    print()

    check_system_deps()

    print()
    deps = DEPENDENCIES.get(system, {})
    pm = deps.get("package_manager", "?")

    print(dim("  ────────────────────────────────────────────"))
    print()
    print(f"  Пакетный менеджер: {bold(pm)}")
    print()

    print(bold("  Установка зависимых библиотек:"))
    print()

    if system == "Darwin":
        print(dim("  brew update"))
        print(dim("  brew install luajit glfw assimp"))
        print(dim("  brew install love2d    # опционально"))
    elif system == "Linux":
        print(dim("  sudo apt update"))
        print(dim("  sudo apt install -y luajit libglfw3-dev libassimp-dev libopenal-dev"))
        print(dim("  sudo apt install -y love    # опционально"))
    elif system == "Windows":
        print(dim("  # Через Scoop:"))
        print(dim("  scoop install luajit"))
        print(dim("  # Или vcpkg:"))
        print(dim("  vcpkg install glfw3 assimp openal-soft"))
        print(dim("  # Love2D: https://love2d.org/"))
    print()

    print(bold("  Структура движка в этой папке:"))
    print()

    items = []
    for item in sorted(os.listdir(SCRIPT_DIR)):
        if item.startswith(".") or item == "__pycache__":
            continue
        full = os.path.join(SCRIPT_DIR, item)
        kind = "папка" if os.path.isdir(full) else "файл"
        if os.path.isdir(full):
            count = sum(1 for _ in os.listdir(full))
            kind += f" ({count} элементов)"
        items.append((item, kind))

    for name, kind in items:
        if name in COPY_DIRS or name in COPY_FILES:
            print(green(f"  ✓ {name:30s} {dim(kind)}"))
        else:
            print(dim(f"    {name:30s} {dim(kind)}"))

    print()
    pause()


def main_menu():
    while True:
        clear()
        print_banner()

        print(bold("  Выберите действие:\n"))
        print(f"  {cyan('1')}  Создать проект     — копирование файлов движка в новую папку")
        print(f"  {cyan('2')}  Проверить проект   — проверка структуры и зависимых библиотек")
        print(f"  {cyan('3')}  Проверить зависимости — системные библиотеки и компилятор LuaJIT")
        print(f"  {cyan('0')}  Выход")
        print()

        choice = input(f"  {dim('►')} ").strip()

        if choice == "1":
            create_project()
        elif choice == "2":
            test_project()
        elif choice == "3":
            check_dependencies()
        elif choice == "0":
            print()
            print(dim("  До встречи!"))
            print()
            break
        else:
            print(red(f"  Неизвестный выбор: {choice}"))
            time.sleep(1)


if __name__ == "__main__":
    try:
        main_menu()
    except KeyboardInterrupt:
        print()
        print(dim("\n  Выход (Ctrl+C)"))
        sys.exit(0)
