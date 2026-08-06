Camera = require("camera")
Scene = require("scene")
Input = require("input")
UI = require("ui")

local state = {
    W = 0, H = 0,
    cam = Camera.new(),
    scene = Scene.new(),
    statusMsg = "",
    statusTimer = 0,
    isDragging = false,
    dragButton = 0,
    inputMode = false,
    inputTitle = "",
    inputText = "",
    inputCallback = nil
}

function state.setStatus(msg)
    state.statusMsg = msg
    state.statusTimer = 3
end

function state.openInput(title, default, callback)
    state.inputMode = true
    state.inputTitle = title
    state.inputText = default or ""
    state.inputCallback = callback
end

function love.load()
    state.W, state.H = love.graphics.getDimensions()
    love.keyboard.setKeyRepeat(true)
    Input.init(state)
    UI.init(state)
    Scene.addObject(state.scene, "cube.txt", 0, 0.5, 5)
    state.setStatus("A=add Del=delete D=dup S=save L=load Tab=select 1-6=rot +/-=scale Arrows/QE=move G=grid RMB=rotate MMB=pan")
end

function love.resize(w, h)
    state.W, state.H = w, h
end

function love.update(dt)
    Camera.update(state.cam)
    if state.statusTimer > 0 then
        state.statusTimer = state.statusTimer - dt
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.12, 0.18)
    UI.drawGrid()
    UI.drawObjects()
    UI.drawCrosshair()
    UI.drawUI()
end

function love.keypressed(key)
    if key == "escape" and not state.inputMode then
        love.event.quit()
    end
    Input.keypressed(key)
end
function love.textinput(text)
    Input.textinput(text)
end
function love.mousepressed(x, y, button) Input.mousepressed(x, y, button) end
function love.mousereleased(x, y, button) Input.mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy) Input.mousemoved(x, y, dx, dy) end
function love.wheelmoved(x, y) Input.wheelmoved(x, y) end
