local M = {}
M.__index = M

local ASSIMP_EXTS = {
    fbx = true, obj = true, glb = true, gltf = true, dae = true,
    blend = true, stl = true, ply = true, x = true, ["3ds"] = true,
}

local function extension(path)
    local ext = path:match("%.([^%.\\/]+)$")
    if ext then return ext:lower() end
    return ""
end

function M.new()
    return setmetatable({
        models = {},
        model_roots = {},
        textures = {},
        shaders = {},
        scripts = {},
        scenes = {},
    }, M)
end

function M:load_model(name, path)
    if self.model_roots[name] then
        return self.model_roots[name]
    end
    local mesh_mod = require("engine.core.render.mesh")
    local SceneNode = require("engine.core.scene.scene_graph")
    local ext = extension(path)
    if ASSIMP_EXTS[ext] then
        local root = mesh_mod.load_scene_with_node(path, SceneNode)
        self.model_roots[name] = root
        local meshes = {}
        local function collect(n)
            for _, m in ipairs(n.meshes) do
                meshes[#meshes + 1] = m
            end
            for _, c in ipairs(n.children) do
                collect(c)
            end
        end
        collect(root)
        self.models[name] = meshes
        return root
    end
    local meshes = mesh_mod.load(path)
    self.models[name] = meshes
    return meshes
end

function M:get_model(name)
    return self.models[name]
end

function M:get_model_root(name)
    return self.model_roots[name]
end

function M:load_texture(name, path, params)
    if self.textures[name] then return self.textures[name] end
    local tex_mod = require("engine.core.render.texture")
    local tex = tex_mod.load(path, params)
    self.textures[name] = tex
    return tex
end

function M:get_texture(name)
    return self.textures[name]
end

function M:load_script(name, path)
    if self.scripts[name] then return self.scripts[name] end
    local f = io.open(path, "r")
    if not f then error("Cannot open script: " .. path) end
    local src = f:read("*a")
    f:close()
    self.scripts[name] = src
    return src
end

function M:get_script(name)
    return self.scripts[name]
end

function M:load_scene_config(name, path)
    if self.scenes[name] then return self.scenes[name] end
    local conf = require("engine.core.conf_parser")
    local data = conf.parse(path)
    self.scenes[name] = data
    return data
end

function M:stats()
    local n_models = 0
    for _ in pairs(self.models) do n_models = n_models + 1 end
    local n_textures = 0
    for _ in pairs(self.textures) do n_textures = n_textures + 1 end
    return {
        models = n_models,
        textures = n_textures,
    }
end

return M