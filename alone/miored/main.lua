Camera = require("camera")
Model = require("model")
Texture = require("texture")
Input = require("input")
UI = require("ui")
Audio = require("AudioManager")

local state = {
    W = 0, H = 0,
    cam = Camera.new(),
    faces = {},
    selectedFace = -1,
    selectedVertex = -1,
    hoveredFace = -1,
    colorIndex = 1,
    gridVisible = true,
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

function state.findFaceAt(mx, my)
    return UI.findFaceAt(mx, my)
end

function love.load()
    state.W, state.H = love.graphics.getDimensions()
    love.keyboard.setKeyRepeat(true)
    Input.init(state)
    UI.init(state)
    state.selectedFace = Model.addCube(state.faces, 0, 0.5, 0, state.colorIndex)
    state.setStatus("C=cube F=face Del=delete S=save I=texture +/-=scale 1-5=rotate Arrows=move")

    Audio:playAt("tmp.mp3", 0, 0, 0, 1.0)
end

function love.resize(w, h)
    state.W, state.H = w, h
end

function love.update(dt)
    Camera.update(state.cam)
    if state.statusTimer > 0 then
        state.statusTimer = state.statusTimer - dt
    end
    state.hoveredFace = UI.findFaceAt(love.mouse.getPosition())

    Audio:setListenerPosition(Camera.x, Camera.y, Camera.z)
end

function love.draw()
    love.graphics.clear(0.1, 0.12, 0.18)
    UI.drawGrid()
    UI.drawFaces()
    UI.drawCrosshair()
    UI.drawUI()
end

function love.keypressed(key) Input.keypressed(key) end
function love.textinput(text) Input.textinput(text) end
function love.mousepressed(x, y, button) Input.mousepressed(x, y, button) end
function love.mousereleased(x, y, button) Input.mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy) Input.mousemoved(x, y, dx, dy) end
function love.wheelmoved(x, y) Input.wheelmoved(x, y) end
