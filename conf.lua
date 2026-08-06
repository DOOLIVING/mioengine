local ConfigParser = require("mioengine.core.conf_parser")

function love.conf(t)
    local config = ConfigParser.parse("game/main.mioconf")
    t.window.title = config.window.title
    t.window.width = config.window.width
    t.window.height = config.window.height
    t.window.resizable = config.window.resizable
    t.window.minwidth = config.window.minwidth
    t.window.minheight = config.window.minheight
end
