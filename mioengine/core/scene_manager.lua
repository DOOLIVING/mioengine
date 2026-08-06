local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new(resources)
    local self = setmetatable({}, SceneManager)
    self.scenes = {}
    self.current = nil
    self.currentName = nil
    self.pending = nil
    self.resources = resources
    return self
end

function SceneManager:add(name, scene)
    self.scenes[name] = scene
end

function SceneManager:switch(name, ...)
    self.pending = { name = name, args = { ... } }
end

function SceneManager:applySwitch()
    if not self.pending then return end
    local name = self.pending.name
    local args = self.pending.args
    self.pending = nil

    if self.current and self.current.exit then
        self.current:exit(self)
    end

    self.currentName = name
    self.current = self.scenes[name]

    if self.current and self.current.enter then
        self.current:enter(self, args)
    end
end

function SceneManager:update(dt)
    self:applySwitch()
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function SceneManager:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

function SceneManager:keypressed(key)
    if self.current and self.current.keypressed then
        self.current:keypressed(key)
    end
end

function SceneManager:keyreleased(key)
    if self.current and self.current.keyreleased then
        self.current:keyreleased(key)
    end
end

function SceneManager:textinput(text)
    if self.current and self.current.textinput then
        self.current:textinput(text)
    end
end

function SceneManager:mousepressed(x, y, button)
    if self.current and self.current.mousepressed then
        self.current:mousepressed(x, y, button)
    end
end

function SceneManager:mousereleased(x, y, button)
    if self.current and self.current.mousereleased then
        self.current:mousereleased(x, y, button)
    end
end

function SceneManager:mousemoved(x, y, dx, dy)
    if self.current and self.current.mousemoved then
        self.current:mousemoved(x, y, dx, dy)
    end
end

function SceneManager:wheelmoved(x, y)
    if self.current and self.current.wheelmoved then
        self.current:wheelmoved(x, y)
    end
end

function SceneManager:resize(w, h)
    if self.current and self.current.resize then
        self.current:resize(w, h)
    end
end

return SceneManager
