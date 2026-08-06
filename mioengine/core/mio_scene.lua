local Camera = require("mioengine.core.camera")
local Objects = require("mioengine.core.objects")
local Renderer = require("mioengine.core.renderer")
local Sound = require("mioengine.core.sound")
local ScriptEngine = require("mioengine.core.script_engine")

local MioScene = {}
MioScene.__index = MioScene

function MioScene.new(scriptPath)
    local self = setmetatable({}, MioScene)
    self.scriptPath = scriptPath
    return self
end

function MioScene:enter(sceneManager, args)
    self.sm = sceneManager
    self.is3D = false
    self.is2D = false

    local allObjects = {}

    self.ctx = {
        camera = nil,
        renderer = nil,
        objects = allObjects,
        switchScene = function(name, ...)
            self.sm:switch(name, ...)
        end,
        dt = 0,
        colliders = {},
        ui = nil,
        resources = sceneManager.resources,
        camera2d = nil,
        is2D = false,
        physics = nil,
        physics3d = nil,
        flagPhysics = nil,
        flagPhysics3d = nil,
        hotReload = sceneManager.hotReload,
        inputMapper = sceneManager.inputMapper,
        debugConsole = sceneManager.debugConsole,
        particles = {},
        particles3d = {},
        particles3dList = {},
        panels = {},
        animatedSprites = {},
    }

    self.scripts = ScriptEngine.new(self.ctx)
    self.scripts:load(self.scriptPath, self.scriptPath)

    if self.ctx.camera and self.ctx.renderer then
        self.is3D = true
        love.mouse.setRelativeMode(true)
    elseif self.ctx.camera2d or self.ctx.is2D then
        self.is2D = true
        love.mouse.setRelativeMode(false)
        love.mouse.setVisible(true)
    else
        love.mouse.setRelativeMode(false)
        love.mouse.setVisible(true)
    end
end

function MioScene:exit()
    if self.scripts then self.scripts:clear() end
    Sound.stopAll()
    if self.is3D then
        love.mouse.setRelativeMode(false)
    end
end

function MioScene:update(dt)
    if self.scripts then
        self.scripts.ctx.dt = dt
        self.scripts:update(dt)
    end
    
    if self.ctx and self.ctx.particles3dList then
        self.ctx.particles3dList = {}
    end
    if self.is2D and self.ctx and self.ctx.camera2d then
        self.ctx.camera2d:update(dt)
    end
    if self.ctx and self.ctx.physics then
        self.ctx.physics:update(dt)
    end
    if self.ctx and self.ctx.physics3d then
        self.ctx.physics3d:update(dt)
    end
    if self.ctx and self.ctx.flagPhysics then
        self.ctx.flagPhysics:update(dt)
    end
    if self.ctx and self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d:update(dt)
    end
end

function MioScene:draw()
    if not self.scripts then return end
    local renderer = self.scripts.ctx.renderer
    local camera = self.scripts.ctx.camera

    if renderer and camera then
        local allVerts = {}
        local allFaces = {}
        local offset = 0

        local objs = self.scripts.ctx.objects or {}
        for _, obj in ipairs(objs) do
            local verts = obj:getTransformedVertices()
            for _, v in ipairs(verts) do
                allVerts[#allVerts + 1] = v
            end
            for _, f in ipairs(obj.faces) do
                local newIndices = {}
                for _, idx in ipairs(f.indices) do
                    newIndices[#newIndices + 1] = idx + offset
                end
                allFaces[#allFaces + 1] = {
                    indices = newIndices,
                    color = f.color,
                    is_textured = f.is_textured,
                    texture_file = f.texture_file,
                    drawOrder = f.drawOrder,
                }
            end
            offset = offset + #verts
        end

        local projected, renderList = renderer:projectAndSort(camera, allVerts, allFaces)
        renderer:drawScene(projected, renderList, camera)

        
        local ps3dList = self.scripts.ctx.particles3dList
        if ps3dList then
            for _, ps in ipairs(ps3dList) do
                ps:update(self.ctx.dt or 0)
                local particles = ps:getSortedList()
                for _, p in ipairs(particles) do
                    local sx, sy, depth = renderer:projectPoint(camera, p.x, p.y, p.z)
                    if sx and sy then
                        local size = p.size * (renderer.fov / math.max(depth, 0.1))
                        size = math.max(1, math.min(size, 40))
                        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4])
                        love.graphics.circle("fill", sx, sy, size)
                    end
                end
            end
            love.graphics.setColor(1, 1, 1, 1)
        end

        renderer:beginUI()
        self.scripts:draw()
        renderer:endUI()
    elseif self.is2D and self.ctx.camera2d then
        self.ctx.camera2d:apply()
        self.scripts:draw()
        self.ctx.camera2d:release()
    else
        self.scripts:draw()
    end

    if self.ctx.debugConsole then
        self.ctx.debugConsole:profilerDraw()
    end
end

function MioScene:mousemoved(x, y, dx, dy)
    if self.is3D and self.scripts and self.scripts.ctx.camera then
        self.scripts.ctx.camera:handleMouseMoved(dx, dy)
    end
    if self.scripts then self.scripts:mousemoved(x, y, dx, dy) end
end

function MioScene:mousepressed(x, y, button)
    if self.is3D and self.scripts and self.scripts.ctx.camera then
        self.scripts.ctx.camera:handleMousePressed(button)
    end
    if self.scripts then self.scripts:mousepressed(x, y, button) end
end

function MioScene:keypressed(key)
    if key == "escape" then self.sm:switch("menu") end
    if self.scripts then self.scripts:keypressed(key) end
end

function MioScene:resize(w, h)
end

return MioScene
