local gl = require("engine.core.platform.gl")
local shader = require("engine.core.render.shader")

local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    self.shaders = {}
    return self
end

function M:load(name, vert_path, frag_path)
    if self.shaders[name] then
        return self.shaders[name]
    end

    local vert_file = io.open(vert_path, "r")
    if not vert_file then
        io.stderr:write("[ShaderManager] Cannot open vertex shader: " .. vert_path .. "\n")
        return nil
    end
    local vert_src = vert_file:read("*a")
    vert_file:close()

    local frag_file = io.open(frag_path, "r")
    if not frag_file then
        io.stderr:write("[ShaderManager] Cannot open fragment shader: " .. frag_path .. "\n")
        return nil
    end
    local frag_src = frag_file:read("*a")
    frag_file:close()

    local ok, s = pcall(shader.new, vert_src, frag_src)
    if not ok then
        io.stderr:write("[ShaderManager] Compile error in '" .. name .. "': " .. tostring(s) .. "\n")
        return nil
    end

    s.name = name
    s.vert_path = vert_path
    s.frag_path = frag_path
    self.shaders[name] = s
    print("[ShaderManager] Loaded shader: " .. name)
    return s
end

function M:get(name)
    return self.shaders[name]
end

function M:reload(name)
    local s = self.shaders[name]
    if not s then return nil end
    return self:load(name, s.vert_path, s.frag_path)
end

function M:delete(name)
    local s = self.shaders[name]
    if s then
        shader.delete(s)
        self.shaders[name] = nil
    end
end

function M:delete_all()
    for name, _ in pairs(self.shaders) do
        self:delete(name)
    end
end

function M:set_uniform(name, uname, ...)
    local s = self.shaders[name]
    if s then
        shader.set_uniform(s, uname, ...)
    end
end

return M
