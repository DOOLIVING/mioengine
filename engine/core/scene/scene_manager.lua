local M = {}
M.__index = M

function M.new(resources)
    return setmetatable({
        scenes = {},
        active = nil,
        active_name = "",
        resources = resources,
    }, M)
end

function M:add(name, scene)
    self.scenes[name] = scene
end

function M:switch(name)
    if self.active and self.active.on_exit then
        self.active:on_exit()
    end
    self.active = self.scenes[name]
    self.active_name = name
    if self.active and self.active.on_enter then
        self.active:on_enter()
    end
end

function M:update(dt)
    if self.active and self.active.update then
        self.active:update(dt)
    end
end

function M:draw()
    if self.active and self.active.draw then
        self.active:draw()
    end
end

function M:keypressed(key)
    if self.active and self.active.keypressed then
        self.active:keypressed(key)
    end
end

function M:keyreleased(key)
    if self.active and self.active.keyreleased then
        self.active:keyreleased(key)
    end
end

function M:mousepressed(x, y, button)
    if self.active and self.active.mousepressed then
        self.active:mousepressed(x, y, button)
    end
end

function M:mousereleased(x, y, button)
    if self.active and self.active.mousereleased then
        self.active:mousereleased(x, y, button)
    end
end

function M:mousemoved(x, y, dx, dy)
    if self.active and self.active.mousemoved then
        self.active:mousemoved(x, y, dx, dy)
    end
end

function M:wheelmoved(x, y)
    if self.active and self.active.wheelmoved then
        self.active:wheelmoved(x, y)
    end
end

function M:resize(w, h)
    if self.active and self.active.resize then
        self.active:resize(w, h)
    end
end

return M
