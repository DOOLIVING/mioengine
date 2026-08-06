# mioengine — Build & Install

## Быстрый старт

```bash
# Собрать под все платформы
python3 install/build.py

# Собрать только под macOS
python3 install/build.py macos

# Собрать под macOS и Windows
python3 install/build.py macos windows
```

## Требования

- Python 3.6+
- Internet (для скачивания Love2D)
- tar (для Linux .tar.gz)

## Структура output

```
install/dist/
├── macos/
│   └── mioengine.app      ← перетащи в /Applications
├── windows/
│   ├── win64/
│   │   ├── mioengine.exe   ← запусти play.bat
│   │   ├── mioengine.love
│   │   └── play.bat
│   └── win32/
└── linux/
    └── mioengine-x64/
        ├── mioengine.AppImage
        ├── mioengine.love
        └── play.sh
```

## Установка

### macOS
```bash
cp -r install/dist/macos/mioengine.app /Applications/
```

### Windows
Распаковать `windows/win64/` и запустить `play.bat`

### Ubuntu / Linux
```bash
tar -xzf install/dist/linux/mioengine-linux-x64.tar.gz
cd mioengine-x64
chmod +x mioengine.AppImage play.sh
./play.sh
```

## Что внутри

- `mioengine/` — движок (Lua)
- `game/` — .mio скрипты уровня
- `models/` — 3D модели
- `assets/` — текстуры, звуки
