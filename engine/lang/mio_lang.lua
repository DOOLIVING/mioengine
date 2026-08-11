local Lexer = require("engine.lang.lexer")
local Parser = require("engine.lang.parser")
local EvalMixin = require("engine.lang.evaluator")
local ExecMixin = require("engine.lang.executor")

local MioLang = {}
MioLang.__index = MioLang

for k, v in pairs(EvalMixin) do MioLang[k] = v end
for k, v in pairs(ExecMixin) do MioLang[k] = v end

function MioLang.new(ctx)
    local self = setmetatable({}, MioLang)
    self.ctx = ctx or {}
    self.vars = {}
    self.imported = {}
    self.onUpdateBodies = {}
    self.onDrawBodies = {}
    self.onKeyHandlers = {}
    self.onClickHandlers = {}
    self.onCollisionPairs = {}
    self.onMouseBodies = {}
    self.timers = {}
    self.name = ""
    self.initialized = false
    self._break = false
    self.imageCache = {}

    local math3d = require("engine.core.math")

    self.vars["Camera"] = {
        MoveForward = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            local flat = math3d.vec3(cam.front[0], 0, cam.front[2])
            flat = math3d.vec3_normalize(flat)
            local move = math3d.vec3_scale(flat, (speed or cam.speed) * dt)
            cam.position = math3d.vec3_add(cam.position, move)
        end,
        MoveBack = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            local flat = math3d.vec3(cam.front[0], 0, cam.front[2])
            flat = math3d.vec3_normalize(flat)
            local move = math3d.vec3_scale(flat, (speed or cam.speed) * dt)
            cam.position = math3d.vec3_sub(cam.position, move)
        end,
        MoveLeft = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            local move = math3d.vec3_scale(cam.right, (speed or cam.speed) * dt)
            cam.position = math3d.vec3_sub(cam.position, move)
        end,
        MoveRight = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            local move = math3d.vec3_scale(cam.right, (speed or cam.speed) * dt)
            cam.position = math3d.vec3_add(cam.position, move)
        end,
        MoveUp = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            cam.position[1] = cam.position[1] + (speed or cam.speed) * dt
        end,
        MoveDown = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            local dt = self.ctx.dt or 0.016
            cam.position[1] = cam.position[1] - (speed or cam.speed) * dt
        end,
        RotateYaw = function(_, angle)
            local cam = self.ctx.camera
            if not cam then return end
            cam.yaw = cam.yaw + angle
            cam:update_vectors()
        end,
        RotatePitch = function(_, angle)
            local cam = self.ctx.camera
            if not cam then return end
            cam.pitch = cam.pitch + angle
            if cam.pitch > 89 then cam.pitch = 89 end
            if cam.pitch < -89 then cam.pitch = -89 end
            cam:update_vectors()
        end,
        GetPosition = function(_)
            local cam = self.ctx.camera
            if not cam then return 0, 0, 0 end
            return cam.position[0], cam.position[1], cam.position[2]
        end,
        GetDirection = function(_)
            local cam = self.ctx.camera
            if not cam then return 0, 0, -1 end
            return cam.front[0], cam.front[1], cam.front[2]
        end,
        GetRotation = function(_)
            local cam = self.ctx.camera
            if not cam then return 0, 0 end
            return cam.yaw, cam.pitch
        end,
        SetPosition = function(_, x, y, z)
            local cam = self.ctx.camera
            if not cam then return end
            cam.position = math3d.vec3(x or 0, y or 0, z or 0)
        end,
        SetYaw = function(_, yaw)
            local cam = self.ctx.camera
            if not cam then return end
            cam.yaw = yaw or 0
            cam:update_vectors()
        end,
        SetPitch = function(_, pitch)
            local cam = self.ctx.camera
            if not cam then return end
            cam.pitch = pitch or 0
            if cam.pitch > 89 then cam.pitch = 89 end
            if cam.pitch < -89 then cam.pitch = -89 end
            cam:update_vectors()
        end,
        SetSpeed = function(_, speed)
            local cam = self.ctx.camera
            if not cam then return end
            cam.speed = speed or 5
        end,
        SetSensitivity = function(_, sens)
            local cam = self.ctx.camera
            if not cam then return end
            cam.sensitivity = (sens or 2) * 0.001
        end,
        SetFOV = function(_, fov)
            local cam = self.ctx.camera
            if not cam then return end
            cam.fov = math.rad(fov or 60)
        end,
        SetLocked = function(_, locked)
            local cam = self.ctx.camera
            if not cam then return end
            cam.locked = locked
        end,
        SetFPSMode = function(_, enabled)
            local cam = self.ctx.camera
            if not cam then return end
            cam.fps_mode = enabled
        end,
        DisableEngineCamera = function(_)
            self.ctx.auto_camera = false
        end,
        EnableEngineCamera = function(_)
            self.ctx.auto_camera = true
        end,
        ProcessMouse = function(_, dx, dy)
            local cam = self.ctx.camera
            if not cam then return end
            cam.yaw = cam.yaw + dx * cam.sensitivity * 50
            cam.pitch = cam.pitch - dy * cam.sensitivity * 50
            if cam.pitch > 89 then cam.pitch = 89 end
            if cam.pitch < -89 then cam.pitch = -89 end
            cam:update_vectors()
        end,
        ProcessMouseFromInput = function(_)
            local cam = self.ctx.camera
            if not cam then return end
            if not self.ctx.input then return end
            local dx, dy = self.ctx.input:get_mouse_delta()
            cam.yaw = cam.yaw + dx * cam.sensitivity * 50
            cam.pitch = cam.pitch - dy * cam.sensitivity * 50
            if cam.pitch > 89 then cam.pitch = 89 end
            if cam.pitch < -89 then cam.pitch = -89 end
            cam:update_vectors()
        end,
        GetPositionX = function(_)
            local cam = self.ctx.camera
            if not cam then return 0 end
            return cam.position[0]
        end,
        GetPositionY = function(_)
            local cam = self.ctx.camera
            if not cam then return 0 end
            return cam.position[1]
        end,
        GetPositionZ = function(_)
            local cam = self.ctx.camera
            if not cam then return 0 end
            return cam.position[2]
        end,
        IsLocked = function(_)
            local cam = self.ctx.camera
            if not cam then return true end
            return cam.locked
        end,
    }

    self.vars["Input"] = {
        IsPressed = function(_, key)
            if self.ctx.input then return self.ctx.input:is_down(key) end
            return false
        end,
        WasPressed = function(_, key)
            if self.ctx.input then return self.ctx.input:is_pressed(key) end
            return false
        end,
        IsMousePressed = function(_, btn)
            if self.ctx.input then return self.ctx.input:mouse_down(btn or 0) end
            return false
        end,
        GetMousePos = function(_)
            if self.ctx.input then return self.ctx.input.mouse_x, self.ctx.input.mouse_y end
            return 0, 0
        end,
        GetMouseDelta = function(_)
            if self.ctx.input then return self.ctx.input.mouse_dx, self.ctx.input.mouse_dy end
            return 0, 0
        end,
        SetMouseMode = function(_, mode)
            if self.ctx.set_mouse then self.ctx.set_mouse(mode) end
        end,
    }

    self.vars["Time"] = {
        GetDelta = function(_)
            return self.ctx.dt or 0.016
        end,
        GetTotal = function(_)
            if self.ctx.time then return self.ctx.time() end
            return 0
        end,
    }

    return self
end

function MioLang:log(msg)
    print("[.mio:" .. self.name .. "] " .. tostring(msg))
end

function MioLang:load(source, name)
    self.name = name or "anon"

    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    local parser = Parser.new(tokens)
    local ast = parser:parse()

    self.ast = ast
    self.initialized = true

    self:runTopLevel(ast)
end

function MioLang:runTopLevel(stmts)
    for _, stmt in ipairs(stmts) do
        if stmt.type == "on_update" then
            self.onUpdateBodies[#self.onUpdateBodies+1] = stmt.body
        elseif stmt.type == "on_draw" then
            self.onDrawBodies[#self.onDrawBodies+1] = stmt.body
        elseif stmt.type == "on_key" then
            self.onKeyHandlers[stmt.key] = self.onKeyHandlers[stmt.key] or {}
            self.onKeyHandlers[stmt.key][#self.onKeyHandlers[stmt.key]+1] = stmt.body
        elseif stmt.type == "on_click" then
            self.onClickHandlers[stmt.obj] = self.onClickHandlers[stmt.obj] or {}
            self.onClickHandlers[stmt.obj][#self.onClickHandlers[stmt.obj]+1] = stmt.body
        elseif stmt.type == "on_collision" then
            self.onCollisionPairs[#self.onCollisionPairs+1] = {
                obj1 = stmt.obj1, obj2 = stmt.obj2, body = stmt.body,
            }
        elseif stmt.type == "on_mouse" then
            self.onMouseBodies[#self.onMouseBodies+1] = stmt.body
        elseif stmt.type == "import" then
            self:doImport(stmt)
        else
            local ok, err = pcall(function() self:exec(stmt) end)
            if not ok then self:log("exec error: " .. tostring(err)) end
        end
    end
end

function MioLang:doImport(stmt)
    local path = self:evalExpr(stmt.path)
    if type(path) ~= "string" then
        self:log("import: path must be a string")
        return
    end
    if self.imported[path] then return end
    self.imported[path] = true

    local f = io.open(path, "r")
    if not f then
        self:log("import: cannot load " .. path)
        return
    end
    local content = f:read("*a")
    f:close()
    if not content then
        self:log("import: cannot read " .. path)
        return
    end

    local sub = MioLang.new(self.ctx)
    sub.vars = self.vars
    sub.imported = self.imported
    sub.name = path
    local ok, err = pcall(function() sub:load(content, path) end)
    if not ok then
        self:log("import error in " .. path .. ": " .. tostring(err))
        return
    end

    for _, body in ipairs(sub.onUpdateBodies) do
        self.onUpdateBodies[#self.onUpdateBodies+1] = body
    end
    for _, body in ipairs(sub.onDrawBodies) do
        self.onDrawBodies[#self.onDrawBodies+1] = body
    end
    for key, handlers in pairs(sub.onKeyHandlers) do
        self.onKeyHandlers[key] = self.onKeyHandlers[key] or {}
        for _, body in ipairs(handlers) do
            self.onKeyHandlers[key][#self.onKeyHandlers[key]+1] = body
        end
    end
    for obj, handlers in pairs(sub.onClickHandlers) do
        self.onClickHandlers[obj] = self.onClickHandlers[obj] or {}
        for _, body in ipairs(handlers) do
            self.onClickHandlers[obj][#self.onClickHandlers[obj]+1] = body
        end
    end
    for _, pair in ipairs(sub.onCollisionPairs) do
        self.onCollisionPairs[#self.onCollisionPairs+1] = pair
    end
    for _, body in ipairs(sub.onMouseBodies) do
        self.onMouseBodies[#self.onMouseBodies+1] = body
    end

    self:log("imported: " .. path)
end

function MioLang:update(dt)
    if self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d:update(dt)
    end
    if self.ctx.flagPhysics then
        self.ctx.flagPhysics:update(dt)
    end

    for i = #self.timers, 1, -1 do
        local t = self.timers[i]
        t.elapsed = t.elapsed + dt
        if t.elapsed >= t.time then
            t.elapsed = t.elapsed - t.time
            if t.fn then pcall(t.fn) end
            if t.once then table.remove(self.timers, i) end
        end
    end

    for _, obj in ipairs(self.ctx.objects or {}) do
        if obj.rotSpeedX and obj.rotSpeedX ~= 0 then
            obj.angleX = (obj.angleX or 0) + obj.rotSpeedX * dt * 60
            obj:markDirty()
        end
        if obj.rotSpeedY and obj.rotSpeedY ~= 0 then
            obj.angleY = (obj.angleY or 0) + obj.rotSpeedY * dt * 60
            obj:markDirty()
        end
    end

    for _, body in ipairs(self.onUpdateBodies) do
        self:execBlock(body)
    end
end

function MioLang:draw()
    for _, body in ipairs(self.onDrawBodies) do
        local ok, err = pcall(function() self:execBlock(body) end)
        if not ok then self:log("draw error: " .. tostring(err)) end
    end
end

function MioLang:onKey(key)
    local handlers = self.onKeyHandlers[key]
    if handlers then
        for _, body in ipairs(handlers) do
            self:execBlock(body)
        end
    end
end

function MioLang:onMouse(x, y, button, action)
    for _, body in ipairs(self.onMouseBodies) do
        self.vars["_mousex"] = x
        self.vars["_mousey"] = y
        self.vars["_mousebutton"] = button
        self.vars["_mouseaction"] = action
        self:execBlock(body)
    end
end

function MioLang:checkCollisions()
    for _, pair in ipairs(self.onCollisionPairs) do
        local a = self.vars[pair.obj1]
        local b = self.vars[pair.obj2]
        if a and b then
            local dx = (a.x or 0) - (b.x or 0)
            local dy = (a.y or 0) - (b.y or 0)
            local dz = (a.z or 0) - (b.z or 0)
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist < 1.0 then
                self:execBlock(pair.body)
            end
        end
    end
end

function MioLang:isRunning()
    return self.initialized
end

return MioLang
