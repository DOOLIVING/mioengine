local ffi = require("ffi")
local math3d = require("engine.core.math")

local M = {}
M.__index = M

function M.new(node, name)
    local self = setmetatable({}, M)
    self.node = node
    self.name = name or "object"
    self.x = node.position[0] or 0
    self.y = node.position[1] or 0
    self.z = node.position[2] or 0
    self.scale = 1
    self.angleX = 0
    self.angleY = 0
    self.rotSpeedX = 0
    self.rotSpeedY = 0
    self.shader = nil
    self.shader_uniforms = {}
    self._physicsId = nil
    self._physics3dId = nil
    return self
end

function M:markDirty()
    if self.node then
        self.node:set_position(self.x, self.y, self.z)
        self.node:set_rotation(self.angleX, self.angleY, 0)
        self.node:set_scale(self.scale, self.scale, self.scale)
        if self.shader then
            self.node.shader = self.shader
        end
        if self.shader_uniforms then
            self.node.shader_uniforms = self.shader_uniforms
        end
    end
end

return M
