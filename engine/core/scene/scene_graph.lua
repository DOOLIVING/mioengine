local ffi = require("ffi")
local math3d = require("engine.core.math")
local M = {}
M.__index = M

function M.new(name)
    local node = setmetatable({}, M)
    node.name = name or "entity"
    node.position = math3d.vec3(0, 0, 0)
    node.rotation = math3d.vec3(0, 0, 0)
    node.scale_val = math3d.vec3(1, 1, 1)
    node.meshes = {}
    node.texture = nil
    node.color = math3d.vec3(1, 1, 1)
    node.visible = true
    node.children = {}
    node.parent = nil
    node.tag = ""
    node.children_map = {}
    node.local_matrix = nil
    node.shader = nil
    node.shader_uniforms = {}
    return node
end

function M:add_child(child)
    child.parent = self
    self.children[#self.children+1] = child
    self.children_map[child.name] = child
    return child
end

function M:remove_child(name)
    for i, child in ipairs(self.children) do
        if child.name == name then
            child.parent = nil
            table.remove(self.children, i)
            self.children_map[name] = nil
            return child
        end
    end
    return nil
end

function M:find(name)
    if self.children_map[name] then return self.children_map[name] end
    for _, child in ipairs(self.children) do
        local found = child:find(name)
        if found then return found end
    end
    return nil
end

function M:set_position(x, y, z)
    self.position = math3d.vec3(x or 0, y or 0, z or 0)
end

function M:set_rotation(pitch, yaw, roll)
    self.rotation = math3d.vec3(pitch or 0, yaw or 0, roll or 0)
end

function M:set_scale(sx, sy, sz)
    if sy == nil and sz == nil then
        self.scale_val = math3d.vec3(sx, sx, sx)
    else
        self.scale_val = math3d.vec3(sx or 1, sy or 1, sz or 1)
    end
end

function M:get_local_matrix()
    local t = math3d.mat4_translate(self.position[0], self.position[1], self.position[2])
    local r = math3d.mat4_from_euler(
        math.rad(self.rotation[0]),
        math.rad(self.rotation[1]),
        math.rad(self.rotation[2])
    )
    local s = math3d.mat4_scale(self.scale_val[0], self.scale_val[1], self.scale_val[2])
    local user = math3d.mat4_multiply(t, math3d.mat4_multiply(r, s))
    if self.local_matrix then
        return math3d.mat4_multiply(user, self.local_matrix)
    end
    return user
end

function M:get_model_matrix()
    local local_m = self:get_local_matrix()
    if self.parent then
        return math3d.mat4_multiply(self.parent:get_model_matrix(), local_m)
    end
    return local_m
end

function M:set_mesh(m)
    self.meshes = {m}
end

function M:set_meshes(mesh_list)
    self.meshes = mesh_list
end

function M:get_position()
    return self.position[0], self.position[1], self.position[2]
end

function M:get_rotation()
    return self.rotation[0], self.rotation[1], self.rotation[2]
end

function M:get_scale()
    return self.scale_val[0], self.scale_val[1], self.scale_val[2]
end

function M:set_visible(visible)
    self.visible = visible
end

function M:is_visible()
    return self.visible
end

function M:set_color(r, g, b)
    self.color = math3d.vec3(r or 1, g or 1, b or 1)
end

function M:get_color()
    return self.color[0], self.color[1], self.color[2]
end

function M:set_tag(tag)
    self.tag = tag
end

function M:get_tag()
    return self.tag
end

function M:get_children()
    return self.children
end

return M