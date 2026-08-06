# mioengine

3D игровой движок на Lua + Love2D с кастомным языком скриптинга **MioLang**.

Ретро-стиль PS1: софтверный рендеринг, низкополигоные модели, пиксельные текстуры.

---

## Быстрый старт

### Что нужно

| Инструмент | Зачем | Скачать |
|---|---|---|
| **Love2D** | Запуск игры | [love2d.org](https://love2d.org) |
| **VS Code** | Редактор кода | [code.visualstudio.com](https://code.visualstudio.com) |
| **Расширение MioLang** | Подсветка синтаксиса .mio файлов | `vscode-mio/mio-lang-1.0.0.vsix` |

### Запуск

```bash
# Из корня проекта
love .

# Или перетащи папку проекта на иконку Love2D
```

---

## Структура проекта

```
alone/
├── main.lua              ← точка входа
├── conf.lua              ← настройки окна (1024x768)
│
├── mioengine/            ← ДВИЖОК (не трогай без необходимости)
│   ├── core/             ← ядро: рендерер, камера, физика, звук
│   ├── lang/             ← язык MioLang (парсер + интерпретатор)
│   └── ui/               ← HUD библиотека (HP бар, кнопки, слайдеры)
│
├── game/                 ← ИГРА
│   ├── scripts/          ← .mio скрипты (вся логика игры)
│   └── scenes/           ← Lua-обёртки сцен
│
├── sdk/                  ← РЕДАКТОРЫ (standalone Love2D проекты)
│   ├── miored/           ← редактор 3D моделей
│   └── mioscene/         ← редактор сцен
│
├── models/               ← 3D модели (.txt формат)
├── assets/               ← текстуры (.png), звуки (.mp3)
└── vscode-mio/           ← VS Code расширение для подсветки
```

---

## Создание игры

### 1. Создай .mio скрипт уровня

Создай файл `game/scripts/my_level.mio`:

```
// Настройка движка
setup_camera 0, 2.5, -3 speed 4 sensitivity 0.0025
setup_renderer 320, 240 fov 200
load_texture "assets/texture.png"
set_mouse relative

// Пол
add_object floor from "models/floor.txt" at 0, 0, 0 draworder 0

// Стена
add_object wall from "models/wall.txt" at 0, 0, 8

// Куб с вращением
let myCube = create_model from "models/cube.txt" at 0, 1, 3 rotatex 0.5 rotatey 0.3

// Камера обновляется каждый кадр
on_update
    camera_update
end
```

### 2. Добавь сцену в меню

Открой `game/scenes/menu.lua` и добавь пункт:

```lua
{ label = "My Level", action = function()
    sm:switch("game", { script = "game/scripts/my_level.mio" })
end },
```

### 3. Запусти

```bash
love .
```

---

## Язык MioLang

### Переменные

```
let health = 100
let name = "player"
let coins = []
```

### Условия

```
if health > 50 then
    say "Полно HP"
else
    say "Мало HP"
end
```

### Циклы

```
// Бесконечный цикл
loop forever
    camera_update
end

// Цикл с шагом
for i = 0 to 10 step 2
    say "" + i
end
```

### События

```
on_update
    // Вызывается каждый кадр
    camera_update
end

on_draw
    // Рисование поверх 3D сцены
    draw_text "HP: 100", 10, 10, 12, 1, 1, 1, 1, left
end

on_key "e"
    // Нажатие клавиши
    say "Нажата E"
end

on_key "escape"
    switch_scene "menu"
end
```

### Команды

| Команда | Описание |
|---|---|
| `setup_camera x, y, z` | Создать камеру |
| `setup_renderer w, h` | Создать рендерер |
| `load_texture "file.png"` | Загрузить текстуру |
| `add_object name from "file.txt" at x, y, z` | Добавить объект |
| `create_model name from "file.txt" at x, y, z` | Создать и получить ссылку |
| `move obj by dx, dy, dz` | Двинуть объект |
| `set_pos obj to x, y, z` | Установить позицию |
| `get_pos obj => x, y, z` | Получить позицию |
| `set_rot axis obj value` | Установить вращение |
| `destroy obj` | Удалить объект |
| `say "text"` | Вывести в консоль |
| `switch_scene "name"` | Переключить сцену |
| `camera_update` | Обновить камеру |
| `play_sound name from "file.mp3"` | Запустить звук |
| `mute` | Выключить/включить звук |

### Математика

```
let x = sin(3.14)
let y = cos(0)
let d = dist(x1, y1, z1, x2, y2, z2)
let r = random(10)
let s = sqrt(16)
```

### Импорт скриптов

```
import("game/scripts/coins.mio")
import("game/scripts/doors.mio")
```

---

## Создание 3D моделей

### Формат моделей (.txt)

Модели — текстовые файлы в формате, похожем на OBJ:

```
# cube.txt
v -0.5 -0.5 -0.5
v  0.5 -0.5 -0.5
v  0.5  0.5 -0.5
v -0.5  0.5 -0.5
v -0.5 -0.5  0.5
v  0.5 -0.5  0.5
v  0.5  0.5  0.5
v -0.5  0.5  0.5

f 1 2 3 4 color 0.8 0.2 0.1
f 5 6 7 8 color 0.1 0.8 0.2 textured texture.png
f 1 2 6 5 color 0.2 0.2 0.8
```

**Строки `v`** — вершины (x y z).
**Строки `f`** — грани (индексы вершин).

Параметры грани:
- `color r g b` — цвет (0.0 - 1.0)
- `textured` — текстурированная грань
- `имя.png` — файл текстуры (опционально)

### Создание модели в miored

1. Запусти редактор: `love sdk/miored/`
2. Нажми **C** — добавить куб
3. Нажми **F** — добавить грань
4. **Tab** — выбрать вершину
5. **Стрелки** — двигать грань/вершину
6. **1-5** — вращать
7. **+/-** — масштабировать
8. **Space** — сменить цвет
9. **I** — назначить текстуру
10. **S** — сохранить в .txt

### Создание сцены в mioscene

1. Запусти: `love sdk/mioscene/`
2. **A** — добавить модель (.txt)
3. **Tab** — выбрать объект
4. **Стрелки/QE** — двигать
5. **1-6** — вращать XYZ
6. **+/-** — масштаб
7. **D** — дублировать
8. **S** — сохранить .scene

---

## Редактирование HUD

В .mio скрипте внутри `on_draw`:

```
on_draw
    // Текст
    draw_text "Score: 100", 10, 10, 12, 1, 1, 1, 1, left
    draw_text "center", 160, 10, 12, 1, 1, 0.3, 1, center

    // Прямоугольник
    draw_rect 0, 200, 320, 40, 0.05, 0.05, 0.08, 0.85

    // Линия
    draw_line 0, 200, 320, 200, 0.5, 0.5, 0.5, 1, 1

    // Круг
    draw_circle 160, 120, 5, 1, 1, 1, 0.8
end
```

---

## Сборка релиза

```bash
# Все платформы
python3 install/build.py

# Только macOS
python3 install/build.py macos

# macOS + Windows
python3 install/build.py macos windows
```

Результат: `install/dist/`

---

## Клавиши по умолчанию

| Клавиша | Действие |
|---|---|
| W/A/S/D | Движение |
| Пробел | Прыжок |
| Мышь | Обзор |
| E | Взаимодействие |
| Escape | Меню / Выход |

---

## FAQ

**Где добавить новую модель?**
Положи .txt файл в `models/`.

**Как добавить звук?**
Положи .mp3 в `assets/temp/`, затем:
```
play_sound bg from "assets/temp/music.mp3" loop
```

**Как сменить размер окна?**
Отредактируй `conf.lua`:
```lua
t.window.width = 1280
t.window.height = 720
```

**Как добавить уровень в меню?**
1. Создай `game/scripts/level3.mio`
2. В `game/scenes/menu.lua` добавь пункт меню
