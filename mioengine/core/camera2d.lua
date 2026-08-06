local Camera2D = {}
Camera2D.__index = Camera2D

function Camera2D.new(config)
    config = config or {}
    local self = setmetatable({}, Camera2D)
    self.x = config.x or 0
    self.y = config.y or 0
    self.zoom = config.zoom or 1
    self.rotation = config.rotation or 0
    self.width = config.width or love.graphics.getWidth()
    self.height = config.height or love.graphics.getHeight()
    self.smoothing = config.smoothing or 0
    self._targetX = self.x
    self._targetY = self.y
    self._targetZoom = self.zoom
    return self
end

function Camera2D:setPosition(x, y)
    if x then self._targetX = x end
    if y then self._targetY = y end
end

function Camera2D:getPosition()
    return self.x, self.y
end

function Camera2D:setZoom(z)
    self._targetZoom = math.max(0.1, z or 1)
end

function Camera2D:getZoom()
    return self.zoom
end

function Camera2D:setRotation(r)
    self.rotation = r or 0
end

function Camera2D:move(dx, dy)
    self._targetX = self._targetX + (dx or 0)
    self._targetY = self._targetY + (dy or 0)
end

function Camera2D:zoomIn(amount)
    self._targetZoom = self._targetZoom * (1 + (amount or 0.1))
end

function Camera2D:zoomOut(amount)
    self._targetZoom = self._targetZoom * (1 - (amount or 0.1))
    if self._targetZoom < 0.1 then self._targetZoom = 0.1 end
end

function Camera2D:update(dt)
    if self.smoothing > 0 then
        local t = 1 - math.exp(-self.smoothing * dt)
        self.x = self.x + (self._targetX - self.x) * t
        self.y = self.y + (self._targetY - self.y) * t
        self.zoom = self.zoom + (self._targetZoom - self.zoom) * t
    else
        self.x = self._targetX
        self.y = self._targetY
        self.zoom = self._targetZoom
    end
end

function Camera2D:apply()
    love.graphics.push()
    love.graphics.translate(self.width / 2, self.height / 2)
    love.graphics.rotate(-self.rotation)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-self.x, -self.y)
end

function Camera2D:release()
    love.graphics.pop()
end

function Camera2D:screenToWorld(sx, sy)
    local wx = (sx - self.width / 2) / self.zoom + self.x
    local wy = (sy - self.height / 2) / self.zoom + self.y
    return wx, wy
end

function Camera2D:worldToScreen(wx, wy)
    local sx = (wx - self.x) * self.zoom + self.width / 2
    local sy = (wy - self.y) * self.zoom + self.height / 2
    return sx, sy
end

function Camera2D:isVisible(x, y, w, h)
    local hw = (self.width / 2) / self.zoom
    local hh = (self.height / 2) / self.zoom
    local cx, cy = self.x, self.y
    return not (x + w < cx - hw or x > cx + hw or y + h < cy - hh or y > cy + hh)
end

return Camera2D
