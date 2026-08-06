local ConfigParser = require("mioengine.core.conf_parser")
local SceneManager = require("mioengine.core.scene_manager")
local MioScene = require("mioengine.core.mio_scene")
local ResourceManager = require("mioengine.core.resource_manager")
local HotReload = require("mioengine.core.hot_reload")
local InputMapper = require("mioengine.core.input_mapper")
local DebugConsole = require("mioengine.core.debug_console")

local config
local sceneManager
local resources
local hotReload
local inputMapper
local debugConsole

function love.conf(t)
    config = ConfigParser.parse("game/main.mioconf")
    t.window.title = config.window.title
    t.window.width = config.window.width
    t.window.height = config.window.height
    t.window.resizable = config.window.resizable
    t.window.minwidth = config.window.minwidth
    t.window.minheight = config.window.minheight
end

function love.load()
    config = ConfigParser.parse("game/main.mioconf")
    resources = ResourceManager.new()
    hotReload = HotReload.new()
    inputMapper = InputMapper.new()
    debugConsole = DebugConsole.new()

    sceneManager = SceneManager.new(resources)
    sceneManager.hotReload = hotReload
    sceneManager.inputMapper = inputMapper
    sceneManager.debugConsole = debugConsole

    for _, scene in ipairs(config.scenes) do
        local sceneObj = MioScene.new(scene.script)
        sceneObj.sharedCtx = {
            hotReload = hotReload,
            inputMapper = inputMapper,
            debugConsole = debugConsole,
            resources = resources,
        }
        sceneManager:add(scene.name, sceneObj)
    end

    if config.default_scene ~= "" then
        sceneManager:switch(config.default_scene)
    elseif #config.scenes > 0 then
        sceneManager:switch(config.scenes[1].name)
    end
end

function love.update(dt)
    hotReload:update(dt)
    inputMapper:update()
    sceneManager:update(dt)
end

function love.draw()
    sceneManager:draw()
    debugConsole:profilerDraw()
    debugConsole:draw()
end

function love.keypressed(key)
    if key == "f3" then
        local stats = resources:stats()
        local fps = love.timer.getFPS()
        print(string.format("[Resources] images=%d fonts=%d sounds=%d models=%d | FPS=%d",
            stats.images, stats.fonts, stats.sounds, stats.models, fps))
    end
    if key == "f1" then
        debugConsole:toggle()
    end
    if debugConsole.visible then
        debugConsole:keypressed(key)
        return
    end
    inputMapper:keypressed(key)
    sceneManager:keypressed(key)
end

function love.keyreleased(key)
    if debugConsole.visible then return end
    inputMapper:keyreleased(key)
    sceneManager:keyreleased(key)
end

function love.textinput(text)
    if debugConsole.visible then
        debugConsole:textinput(text)
        return
    end
    sceneManager:textinput(text)
end

function love.mousepressed(x, y, button)
    sceneManager:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    sceneManager:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    sceneManager:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    sceneManager:wheelmoved(x, y)
end

function love.resize(w, h)
    sceneManager:resize(w, h)
end
