# MioEngine — Запуск через run.py

## Что делает `run.py`

Кроссплатформенный лаунчер: проверяет зависимости, собирает библиотеки, запускает движок. Работает на macOS, Linux, Windows.

## Установка зависимостей

### macOS
```bash
brew install luajit glfw assimp
cd deps && bash build.sh && cd ..
```

### Linux
```bash
sudo apt install luajit libglfw3-dev libassimp-dev libopenal-dev
cd deps && bash build.sh && cd ..
```

### Windows
Скачайте и положите в `deps/`:
- `glfw3.dll` — https://www.glfw.org/download.html
- `assimp.dll` — https://github.com/assimp/assimp/releases
- `OpenAL32.dll` — https://openal-soft.org/openal-binaries/

Затем соберите stb (нужен gcc/clang):
```bat
cd deps
build.bat
```

## Запуск

### Интерактивное меню
```bash
python3 run.py
```

### Напрямую
```bash
python3 run.py main.lua
python3 run.py editor_main.lua
```

### CLI команды
```bash
python3 run.py --check      # проверить зависимости
python3 run.py --build      # собрать stb библиотеки
python3 run.py --install    # автоустановка (brew/apt)
```

---

## Конфигурация: `game/main.mioconf`

Формат: INI-подобный, секции в `[квадратных скобках]`, ключ=значение.

```ini
default_scene=demo

[window]
title=MioEngine Test
width=800
height=600
resizable=true

[renderer]
width=320
height=240
fov=60
snap_size=40
fog_density=0.015

[camera]
x=0
y=1.5
z=5
speed=5
sensitivity=2
fov=60

[scene:menu]
script=game/scripts/menu.mio

[scene:demo]
script=game/scripts/demo.mio
```

### Параметры конфига

| Секция | Ключ | Значение по умолчанию | Описание |
|---|---|---|---|
| `window` | `title` | MioEngine | Заголовок окна |
| `window` | `width` | 800 | Ширина окна |
| `window` | `height` | 600 | Высота окна |
| `window` | `resizable` | true | Можно ли менять размер |
| `renderer` | `width` | 320 | Внутреннее разрешение (PS1 стиль) |
| `renderer` | `height` | 240 | Внутреннее разрешение |
| `renderer` | `fov` | 60 | Поле зрения |
| `renderer` | `snap_size` | 40 | Размер вершинного snapping |
| `renderer` | `fog_density` | 0.015 | Плотность тумана |
| `camera` | `x`, `y`, `z` | 0, 1.5, 5 | Стартовая позиция камеры |
| `camera` | `speed` | 5 | Скорость камеры |
| `camera` | `sensitivity` | 2 | Чувствительность мыши |
| `camera` | `fov` | 60 | Поле зрения камеры |
| `scene:NAME` | `script` | — | Путь к .mio скрипту сцены |

---

## Язык MioLang — синтаксис

### Переменные и присваивание

```
let x = 10
let name = "player"
let flag = true
let arr = [1, 2, 3]

let x += 5
let x -= 2
let x *= 3
let x /= 2
```

### Условия

```
if x == 10 then
    ...
end

if x > 5 then
    ...
else
    ...
end
```

### Циклы

```
for i = 0, 10 do
    ...
end

for i = 10, 0, -1 do
    ...
end

loop forever do
    ...
end
```

### Операторы

| Оператор | Описание |
|---|---|
| `+` `-` `*` `/` `%` | Арифметика |
| `==` `~=` `<` `>` `<=` `>=` | Сравнение |
| `and` `or` `not` | Логика |
| `+=` `-=` `*=` `/=` | Комбинированное присваивание |

### Комментарии

```
// это комментарий
```

---

## События (обработчики)

```
on_update
    // вызывается каждый кадр
end

on_draw
    // вызывается при отрисовке 2D
end

on_key "w"
    // вызывается при нажатии клавиши
end

on_key "escape"
    ...
end

on_click "button_id"
    // вызывается при клике на UI элемент
end

on_collision "obj1", "obj2"
    // вызывается при столкновении объектов
end

on_mouse
    // _mousex, _mousey, _mousebutton, _mouseaction доступны
end
```

---

## Встроенные объекты

### Camera

```
Camera.DisableEngineCamera()
Camera.EnableEngineCamera()
Camera.SetPosition(x, y, z)
Camera.SetSpeed(speed)
Camera.SetSensitivity(sens)
Camera.SetFOV(fov)
Camera.SetYaw(angle)
Camera.SetPitch(angle)
Camera.SetLocked(bool)
Camera.SetFPSMode(bool)

Camera.MoveForward(speed)
Camera.MoveBack(speed)
Camera.MoveLeft(speed)
Camera.MoveRight(speed)
Camera.MoveUp(speed)
Camera.MoveDown(speed)
Camera.RotateYaw(angle)
Camera.RotatePitch(angle)

Camera.ProcessMouse(dx, dy)
Camera.ProcessMouseFromInput()

Camera.GetPosition()      // возвращает x, y, z
Camera.GetPositionX()
Camera.GetPositionY()
Camera.GetPositionZ()
Camera.GetDirection()     // возвращает x, y, z
Camera.GetRotation()      // возвращает yaw, pitch
Camera.IsLocked()
```

### Input

```
Input.IsPressed("w")        // зажата ли клавиша
Input.WasPressed("space")   // была ли нажата в этом кадру
Input.IsMousePressed(0)     // зажата ли мышь (0=левая, 1=правая)
Input.GetMousePos()         // возвращает x, y
Input.GetMouseDelta()       // возвращает dx, dy
Input.SetMouseMode("relative")  // скрыть курсор
Input.SetMouseMode("visible")   // показать курсор
```

### Time

```
Time.GetDelta()    // время кадра (float)
Time.GetTotal()    // общее время (float)
```

---

## Создание объектов

```
add_object name from "path/to/model.fbx" at x, y, z
add_object name from "model.fbx" at x, y, z scale 2
add_object name from "model.fbx" at x, y, z scale 2 rotatex 90 rotatey 45
```

### Управление объектами

```
set_pos name at x, y, z
getpos name => x, y, z
move name by dx, dy, dz
set_scale name factor
set_rot name axis angle
destroy name
```

### Текстуры

```
load_texture "tex_name", "path/to/texture.png"
set_texture obj_name, "tex_name"
```

---

## Шейдеры

```
load_shader "name", "vert_path", "frag_path"
set_shader obj_name, "shader_name"
set_shader_uniform obj_name, "uniform_name", value
set_shader_uniform obj_name, "uniform_name", r, g, b
reload_shader "name"
```

---

## Звук

```
play_sound name from "path/to/sound.wav"
play_sound name from "sound.wav" loop
stop_sound
mute
volume 0.5
```

---

## 2D рисование

```
draw_rect x, y, w, h, r, g, b
draw_text "message", x, y, size, r, g, b, a
draw_text "message", x, y, size, r, g, b, a, center
draw_circle x, y, radius, r, g, b
draw_line x1, y1, x2, y2, r, g, b
draw_image "texture_name", x, y, w, h
draw_model obj_name
```

---

## Камера и рендер

```
setup_camera x, y, z speed 5 sensitivity 2
setup_renderer 320, 240 fov 60
set_mouse relative
set_mouse visible
set_fog 0.02, 0.5, 0.5, 0.6

set_fps_camera x, y, z speed 5 sensitivity 2 ground_y 1.7 jump_force 8 gravity -20
set_fly_camera
set_static_camera

set_camera_pos x, y, z
camera_speed 5
camera_sensitivity 2
camera_jump 8
camera_gravity -20
camera_ground 1.7
camera_update
camera_collide
```

---

## Физика 2D

```
set_gravity 0, -9.81

add_body "id" at x, y w 32 h 32
add_body "id" at x, y w 32 h 32 dynamic
add_body "id" at x, y w 32 h 32 dynamic bounce 0.3
add_body "id" at x, y w 32 h 32 dynamic bounce 0.3 mass 1
add_body "id" at x, y w 32 h 32 static

set_body_vel "id", vx, vy
get_body_vel "id" => vx, vy
body_apply_force "id", fx, fy
body_apply_impulse "id", ix, iy
set_body_pos "id", x, y
get_body_pos "id" => x, y
is_grounded "id"
body_colliding "id", "tag"

physics_update
remove_body "id"
```

---

## Физика 3D

```
add_body3d "id" at x, y, z w 1 h 1 d 1 shape "box"
add_body3d "id" at x, y, z w 1 h 1 d 1 shape "box" dynamic
add_body3d "id" at x, y, z w 1 h 1 d 1 shape "box" dynamic bounce 0.3 mass 1

set_body3d_vel "id", vx, vy, vz
get_body3d_vel "id" => vx, vy, vz
body3d_apply_force "id", fx, fy, fz
body3d_apply_impulse "id", ix, iy, iz
set_body3d_pos "id", x, y, z
get_body3d_pos "id" => x, y, z
obj3d_is_grounded "id"
obj3d_colliding "id", "tag"

physics3d_update
remove_body3d "id"
```

---

## Частицы 2D

```
create_particles "name" x=100 y=200 gravity=500 max=100 life=2 speed=100 size=4
particles_set_pos "name", x, y
particles_emit "name", count
particles_burst "name", count
particles_start "name"
particles_stop "name"
particles_clear "name"
particles_configure "name" gravity=500 max=100
draw_particles "name"
particles_get_count "name"
```

---

## Частицы 3D

```
create_particles3d "name" x=0 y=0 z=0 gravity=500 max=100 life=2
particles3d_set_pos "name", x, y, z
particles3d_emit "name", count
particles3d_burst "name", count
particles3d_start "name"
particles3d_stop "name"
particles3d_clear "name"
particles3d_configure "name" gravity=500 max=100
draw_particles3d "name"
particles3d_get_count "name"
```

---

## Анимация

```
create_anim "name" frames=4 fps=12 loop=true
anim_add "name" from=0 to=3
anim_play "name"
anim_stop "name"
anim_pause "name"
anim_resume "name"
anim_set_speed "name", fps
anim_set_frame "name", frame
anim_is_done "name"
draw_animated_sprite "name", x, y, w, h
```

---

## UI виджеты

```
ui_button x, y, w, h, "label", "id"
ui_checkbox x, y, size, checked, "id"
ui_slider x, y, w, h, value, min, max, "id"
ui_label x, y, "text", size, "id"

ui_clicked "id"      // true если нажали в этом кадру
ui_checked "id"      // текущее значение чекбокса
ui_slider_value "id" // текущее значение слайдера

ui_visible "id"
ui_hidden "id"
ui_clear
```

---

## Панели

```
create_panel "id" x=0 y=0 w=200 h=300
panel_add_button "panel_id", "label", "btn_id"
panel_add_label "panel_id", "text", "lbl_id"
panel_add_separator "panel_id"
draw_panel "panel_id"
panel_set_visible "panel_id", bool
panel_set_position "panel_id", x, y
```

---

## Переключение сцен

```
switch_scene "scene_name"
exit_game
```

---

## Импорт файлов

```
import "game/scripts/other.mio"
```

---

## Встроенные функции

| Функция | Описание |
|---|---|
| `sin(x)` | Синус (радианы) |
| `cos(x)` | Косинус |
| `atan2(y, x)` | Арктангенс |
| `sqrt(x)` | Квадратный корень |
| `abs(x)` | Модуль |
| `floor(x)` | Округление вниз |
| `ceil(x)` | Округление вверх |
| `min(a, b)` | Минимум |
| `max(a, b)` | Максимум |
| `random()` | Случайное число 0..1 |
| `random(n)` | Случайное число 1..n |
| `random(a, b)` | Случайное число a..b |
| `dist(x1,y1,z1, x2,y2,z2)` | Расстояние между точками |
| `pi()` | Число Pi |
| `time()` | Текущее время |
| `type(val)` | Тип переменной |
| `tostring(val)` | Преобразование в строку |
| `tonumber(val)` | Преобразование в число |
| `str(a, b, ...)` | Конкатенация строк |
| `print(msg)` | Вывод в консоль |

---

## Свойства объектов

Объекты, созданные через `add_object`, имеют свойства:

```
obj.x
obj.y
obj.z
obj.angleX
obj.angleY
obj.angleZ
obj.markDirty()      // вызывать после изменения свойств
```

---

## Пример: FPS камера

```mio
Camera.DisableEngineCamera()
Camera.SetPosition(0, 1.7, 5)
Camera.SetSpeed(5)
Input.SetMouseMode("relative")

add_object floor from "Cube.fbx" at 0, -20, 0

on_update
    Camera.ProcessMouseFromInput()

    if Input.IsPressed("w") then
        Camera.MoveForward(5)
    end
    if Input.IsPressed("s") then
        Camera.MoveBack(5)
    end
    if Input.IsPressed("a") then
        Camera.MoveLeft(5)
    end
    if Input.IsPressed("d") then
        Camera.MoveRight(5)
    end
end

on_key "escape"
    Input.SetMouseMode("visible")
    switch_scene "menu"
end
```

---

## Пример: Меню

```mio
setup_camera 0, 1, 5 speed 3 sensitivity 2
setup_renderer 320, 240 fov 60
set_mouse visible

on_draw
    draw_rect 0, 0, 320, 240, 0.05, 0.05, 0.1
    draw_text "MIOENGINE", 160, 60, 20, 1, 1, 1, 1, center
    draw_text "Press 1 - Demo", 160, 150, 12, 0.8, 0.9, 1.0, 1, center
end

on_key "1"
    switch_scene "demo"
end

on_key "escape"
    exit_game
end
```
