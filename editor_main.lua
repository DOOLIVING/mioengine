package.path = "./?.lua;./?/init.lua;" .. package.path
local ffi = require("ffi")
if ffi.os == "Windows" then
    package.cpath = "./?.dll;" .. package.cpath
else
    package.cpath = "./?.so;./?.dylib;" .. package.cpath
end

local Editor = require("engine.editor.init")
local editor = Editor.new()
editor:run("game/main.mioconf")
