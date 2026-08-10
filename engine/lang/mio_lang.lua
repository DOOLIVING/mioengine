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
