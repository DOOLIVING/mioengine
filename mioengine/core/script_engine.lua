local ScriptEngine = {}
ScriptEngine.__index = ScriptEngine

local Objects = require("mioengine.core.objects")
local Sound = require("mioengine.core.sound")
local MioLang = require("mioengine.lang.mio_lang")

function ScriptEngine.new(ctx)
    local self = setmetatable({}, ScriptEngine)
    self.scripts = {}
    self.mioscripts = {}
    self.timers = {}
    self.timerId = 0
    self.inputCallbacks = {}
    self.ctx = ctx or {}
    return self
end

local function buildMio(self)
    local mio = {}

    mio.log = function(msg)
        print("[.mio] " .. tostring(msg))
    end

    mio.spawn = function(model, x, y, z, opts)
        opts = opts or {}
        local obj = Objects.create({
            model = model,
            x = x or 0,
            y = y or 0,
            z = z or 0,
            rotSpeedX = opts.rotSpeedX or 0,
            rotSpeedY = opts.rotSpeedY or 0,
            scale = opts.scale or 1,
            drawOrder = opts.drawOrder,
            size = opts.size,
            static = opts.static or false,
            resources = self.ctx.resources,
        })
        self.ctx.objects = self.ctx.objects or {}
        self.ctx.objects[#self.ctx.objects + 1] = obj
        return obj
    end

    mio.destroy = function(obj)
        local objs = self.ctx.objects or {}
        for i = #objs, 1, -1 do
            if objs[i] == obj then
                table.remove(objs, i)
                return true
            end
        end
        return false
    end

    mio.move = function(obj, dx, dy, dz)
        if not obj then return end
        obj.x = obj.x + (dx or 0)
        obj.y = obj.y + (dy or 0)
        obj.z = obj.z + (dz or 0)
    end

    mio.setPos = function(obj, x, y, z)
        if not obj then return end
        if x then obj.x = x end
        if y then obj.y = y end
        if z then obj.z = z end
    end

    mio.getPos = function(obj)
        if not obj then return 0, 0, 0 end
        return obj.x, obj.y, obj.z
    end

    mio.rotate = function(obj, axis, speed)
        if not obj then return end
        if axis == "x" then obj.rotSpeedX = speed or 0
        elseif axis == "y" then obj.rotSpeedY = speed or 0
        end
    end

    mio.setRot = function(obj, ax, ay)
        if not obj then return end
        if ax then obj.angleX = ax end
        if ay then obj.angleY = ay end
    end

    mio.getRot = function(obj)
        if not obj then return 0, 0 end
        return obj.angleX, obj.angleY
    end

    mio.setScale = function(obj, s)
        if not obj then return end
        local factor = s / (obj.scale or 1)
        obj.scale = s
        for _, v in ipairs(obj.vertices) do
            v[1] = v[1] * factor
            v[2] = v[2] * factor
            v[3] = v[3] * factor
        end
    end

    mio.cam = {}
    mio.cam.getPos = function()
        local c = self.ctx.camera
        if not c then return 0, 0, 0 end
        return c.x, c.y, c.z
    end
    mio.cam.setPos = function(x, y, z)
        local c = self.ctx.camera
        if not c then return end
        if x then c.x = x end
        if y then c.y = y end
        if z then c.z = z end
    end
    mio.cam.getLook = function()
        local c = self.ctx.camera
        if not c then return 0, 0 end
        return c.yaw, c.pitch
    end
    mio.cam.setLook = function(yaw, pitch)
        local c = self.ctx.camera
        if not c then return end
        if yaw then c.yaw = yaw end
        if pitch then c.pitch = pitch end
    end
    mio.cam.getSpeed = function()
        local c = self.ctx.camera
        if not c then return 4 end
        return c.moveSpeed
    end
    mio.cam.setSpeed = function(s)
        local c = self.ctx.camera
        if not c then return end
        c.moveSpeed = s
    end

    mio.sound = {}
    mio.sound.load = function(name, path)
        Sound.load(name, path, self.ctx.resources)
    end
    mio.sound.play = function(name, loop)
        Sound.play(name, loop)
    end
    mio.sound.stop = function(name)
        Sound.stop(name)
    end
    mio.sound.stopAll = function()
        Sound.stopAll()
    end
    mio.sound.mute = function()
        Sound.toggleMute()
    end
    mio.sound.volume = function(vol)
        Sound.setMasterVolume(vol)
    end

    mio.time = {}
    mio.time.after = function(seconds, callback)
        self.timerId = self.timerId + 1
        self.timers[self.timerId] = {
            type = "once",
            time = seconds,
            elapsed = 0,
            callback = callback,
        }
        return self.timerId
    end
    mio.time.every = function(seconds, callback)
        self.timerId = self.timerId + 1
        self.timers[self.timerId] = {
            type = "repeat",
            time = seconds,
            elapsed = 0,
            callback = callback,
        }
        return self.timerId
    end
    mio.time.cancel = function(id)
        self.timers[id] = nil
    end

    mio.draw = {}
    mio.draw.rect = function(x, y, w, h, r, g, b, a)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(1, 1, 1, 1)
    end
    mio.draw.rectOutline = function(x, y, w, h, r, g, b, a, lw)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        love.graphics.setLineWidth(lw or 1)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end
    mio.draw.text = function(str, x, y, size, r, g, b, a, align)
        local res = self.ctx.resources
        local font = res and res:getFont(size) or love.graphics.newFont(size or 12)
        love.graphics.setFont(font)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        if align == "center" then
            local w = font:getWidth(str)
            love.graphics.print(str, x - w / 2, y)
        elseif align == "right" then
            local w = font:getWidth(str)
            love.graphics.print(str, x - w, y)
        else
            love.graphics.print(str, x, y)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
    mio.draw.circle = function(cx, cy, radius, r, g, b, a)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        love.graphics.circle("fill", cx, cy, radius)
        love.graphics.setColor(1, 1, 1, 1)
    end
    mio.draw.circleOutline = function(cx, cy, radius, r, g, b, a, lw)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        love.graphics.setLineWidth(lw or 1)
        love.graphics.circle("line", cx, cy, radius)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end
    mio.draw.line = function(x1, y1, x2, y2, r, g, b, a, lw)
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
        love.graphics.setLineWidth(lw or 1)
        love.graphics.line(x1, y1, x2, y2)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end

    mio.input = {}
    mio.input.on = function(key, callback)
        self.inputCallbacks[key] = self.inputCallbacks[key] or {}
        self.inputCallbacks[key][#self.inputCallbacks[key] + 1] = callback
    end
    mio.input.off = function(key, callback)
        local list = self.inputCallbacks[key]
        if list then
            for i = #list, 1, -1 do
                if list[i] == callback then
                    table.remove(list, i)
                end
            end
        end
    end
    mio.input.isDown = function(key)
        return love.keyboard.isDown(key)
    end

    mio.math = {}
    mio.math.lerp = function(a, b, t)
        return a + (b - a) * t
    end
    mio.math.clamp = function(v, lo, hi)
        return math.max(lo, math.min(hi, v))
    end
    mio.math.dist = function(x1, y1, z1, x2, y2, z2)
        local dx = (x2 or 0) - (x1 or 0)
        local dy = (y2 or 0) - (y1 or 0)
        local dz = (z2 or 0) - (z1 or 0)
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    mio.math.sin = math.sin
    mio.math.cos = math.cos
    mio.math.random = math.random
    mio.math.pi = math.pi

    mio.scene = {}
    mio.scene.switch = function(name, ...)
        if self.ctx.switchScene then
            self.ctx.switchScene(name, ...)
        end
    end

    mio.timer = function(seconds, callback)
        return mio.time.after(seconds, callback)
    end
    mio.every = function(seconds, callback)
        return mio.time.every(seconds, callback)
    end

    mio.getObjects = function()
        return self.ctx.objects or {}
    end

    mio.getDT = function()
        return self.ctx.dt or 0
    end

    mio.getCanvasSize = function()
        if self.ctx.renderer then
            return self.ctx.renderer:getCanvasW(), self.ctx.renderer:getCanvasH()
        end
        return love.graphics.getWidth(), love.graphics.getHeight()
    end

    return mio
end

function ScriptEngine:load(path, name)
    name = name or path

    if path:match("%.mio$") and not path:match("%.lua$") then
        return self:loadMio(path, name)
    end

    return self:loadLua(path, name)
end

function ScriptEngine:loadLua(path, name)
    local content = love.filesystem.read(path)
    if not content then
        print("[ScriptEngine] Cannot load: " .. path)
        return false
    end

    local fn, err = loadstring(content, path)
    if not fn then
        print("[ScriptEngine] Syntax error in " .. path .. ": " .. tostring(err))
        return false
    end

    local mio = buildMio(self)
    local env = setmetatable({}, { __index = _G })
    env.mio = mio
    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        print("[.mio:" .. name .. "] " .. table.concat(parts, "\t"))
    end

    setfenv(fn, env)

    local ok, result = pcall(fn)
    if not ok then
        print("[ScriptEngine] Runtime error in " .. path .. ": " .. tostring(result))
        return false
    end

    if type(result) ~= "table" then
        print("[ScriptEngine] " .. path .. " must return a table")
        return false
    end

    local script = {
        name = name,
        path = path,
        env = env,
        api = mio,
        mod = result,
        enabled = true,
    }

    self.scripts[name] = script

    if script.mod.onLoad then
        local ok2, err2 = pcall(script.mod.onLoad, mio)
        if not ok2 then
            print("[ScriptEngine] onLoad error in " .. name .. ": " .. tostring(err2))
        end
    end

    print("[ScriptEngine] Loaded: " .. name)
    return true
end

function ScriptEngine:loadMio(path, name)
    local content = love.filesystem.read(path)
    if not content then
        print("[ScriptEngine] Cannot load: " .. path)
        return false
    end

    local lang = MioLang.new(self.ctx)
    lang.name = name

    local ok, err = pcall(function() lang:load(content, name) end)
    if not ok then
        print("[ScriptEngine] Parse error in " .. path .. ": " .. tostring(err))
        return false
    end

    self.mioscripts[name] = {
        name = name,
        path = path,
        lang = lang,
        enabled = true,
    }

    print("[ScriptEngine] Loaded .mio: " .. name)
    return true
end

function ScriptEngine:loadDir(dir)
    local items = love.filesystem.getDirectoryItems(dir)
    for _, item in ipairs(items) do
        if item:match("%.mio$") then
            self:load(dir .. "/" .. item)
        end
    end
end

function ScriptEngine:unload(name)
    local script = self.scripts[name]
    if script then
        if script.mod.onUnload then
            pcall(script.mod.onUnload, script.api)
        end
        self.scripts[name] = nil
        print("[ScriptEngine] Unloaded: " .. name)
        return
    end

    local mio = self.mioscripts[name]
    if mio then
        self.mioscripts[name] = nil
        print("[ScriptEngine] Unloaded .mio: " .. name)
    end
end

function ScriptEngine:update(dt)
    self.ctx.dt = dt

    for id, timer in pairs(self.timers) do
        timer.elapsed = timer.elapsed + dt
        if timer.elapsed >= timer.time then
            timer.elapsed = timer.elapsed - timer.time
            local ok, err = pcall(timer.callback)
            if not ok then
                print("[ScriptEngine] Timer error: " .. tostring(err))
                self.timers[id] = nil
            elseif timer.type == "once" then
                self.timers[id] = nil
            end
        end
    end

    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onUpdate then
            local ok, err = pcall(script.mod.onUpdate, script.api, dt)
            if not ok then
                print("[ScriptEngine] onUpdate error in " .. name .. ": " .. tostring(err))
            end
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang.ctx.dt = dt
            mio.lang:update(dt)
            mio.lang:checkCollisions()
        end
    end
end

function ScriptEngine:draw()
    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onDraw then
            local ok, err = pcall(script.mod.onDraw, script.api)
            if not ok then
                print("[ScriptEngine] onDraw error in " .. name .. ": " .. tostring(err))
            end
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang:draw()
        end
    end
end

function ScriptEngine:keypressed(key)
    local list = self.inputCallbacks[key]
    if list then
        for _, cb in ipairs(list) do
            pcall(cb, key)
        end
    end

    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onKey then
            pcall(script.mod.onKey, script.api, key)
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang:onKey(key)
        end
    end
end

function ScriptEngine:keyreleased(key)
    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onKeyRelease then
            pcall(script.mod.onKeyRelease, script.api, key)
        end
    end
end

function ScriptEngine:mousepressed(x, y, button)
    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onMouse then
            pcall(script.mod.onMouse, script.api, x, y, button, "pressed")
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang:onMouse(x, y, button, "pressed")
        end
    end
end

function ScriptEngine:mousereleased(x, y, button)
    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onMouse then
            pcall(script.mod.onMouse, script.api, x, y, button, "released")
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang:onMouse(x, y, button, "released")
        end
    end
end

function ScriptEngine:mousemoved(x, y, dx, dy)
    for name, script in pairs(self.scripts) do
        if script.enabled and script.mod.onMouseMove then
            pcall(script.mod.onMouseMove, script.api, x, y, dx, dy)
        end
    end

    for name, mio in pairs(self.mioscripts) do
        if mio.enabled and mio.lang:isRunning() then
            mio.lang:onMouse(x, y, dx, dy)
        end
    end
end

function ScriptEngine:clear()
    for name, _ in pairs(self.scripts) do
        self:unload(name)
    end
    for name, _ in pairs(self.mioscripts) do
        self:unload(name)
    end
    self.timers = {}
    self.inputCallbacks = {}
end

function ScriptEngine:get(name)
    return self.scripts[name] or self.mioscripts[name]
end

function ScriptEngine:enable(name, v)
    local s = self.scripts[name]
    if s then
        s.enabled = (v ~= false)
        return
    end
    local mio = self.mioscripts[name]
    if mio then
        mio.enabled = (v ~= false)
    end
end

function ScriptEngine:list()
    local out = {}
    for name, s in pairs(self.scripts) do
        out[#out + 1] = { name = name, enabled = s.enabled, type = "lua" }
    end
    for name, s in pairs(self.mioscripts) do
        out[#out + 1] = { name = name, enabled = s.enabled, type = "mio" }
    end
    return out
end

return ScriptEngine
