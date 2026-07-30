local Camera = {}
Camera.__index = Camera

function Camera.new(config)
    local self = setmetatable({}, Camera)
    self.x = config.x or 0
    self.y = config.y or 0.5
    self.z = config.z or 0
    self.yaw = 0
    self.pitch = 0
    self.moveSpeed = config.moveSpeed or 4
    self.mouseSensitivity = config.mouseSensitivity or 0.0025
    self.pitchLimit = math.rad(85)
    self.velY = 0
    self.groundY = config.y or 0.5
    self.startY = config.y or 0.5
    self.gravity = 12
    self.jumpForce = 6
    self.onGround = true
    self.radius = 0.3
    self.height = 1.0
    return self
end

function Camera:handleMouseMoved(dx, dy)
    self.yaw = self.yaw + dx * self.mouseSensitivity
    self.pitch = self.pitch - dy * self.mouseSensitivity
    if self.pitch > self.pitchLimit then self.pitch = self.pitchLimit end
    if self.pitch < -self.pitchLimit then self.pitch = -self.pitchLimit end
end

function Camera:update(dt)
    local cosYaw, sinYaw = math.cos(self.yaw), math.sin(self.yaw)

    local moveDirX, moveDirZ = 0, 0
    if love.keyboard.isDown("w") then
        moveDirX = moveDirX - sinYaw
        moveDirZ = moveDirZ + cosYaw
    end
    if love.keyboard.isDown("s") then
        moveDirX = moveDirX + sinYaw
        moveDirZ = moveDirZ - cosYaw
    end
    if love.keyboard.isDown("a") then
        moveDirX = moveDirX - cosYaw
        moveDirZ = moveDirZ - sinYaw
    end
    if love.keyboard.isDown("d") then
        moveDirX = moveDirX + cosYaw
        moveDirZ = moveDirZ + sinYaw
    end

    local len = math.sqrt(moveDirX * moveDirX + moveDirZ * moveDirZ)
    if len > 0 then
        moveDirX = moveDirX / len
        moveDirZ = moveDirZ / len
    end
    self.x = self.x + moveDirX * self.moveSpeed * dt
    self.z = self.z + moveDirZ * self.moveSpeed * dt

    if love.keyboard.isDown("space") and self.onGround then
        self.velY = self.jumpForce
        self.onGround = false
    end

    self.velY = self.velY - self.gravity * dt
    self.y = self.y + self.velY * dt

    if love.keyboard.isDown("escape") then
        love.mouse.setRelativeMode(false)
    end
end

function Camera:handleMousePressed(button)
    if button == 1 then
        love.mouse.setRelativeMode(true)
    end
end

function Camera:resolveCollisions(colliders)
    if self.y - 1.5 < 0 then
        self.y = 1.5
        self.velY = 0
        self.onGround = true
    end

    for _, c in ipairs(colliders) do
        local halfW = c.halfSize
        local minX = c.x - halfW
        local maxX = c.x + halfW
        local minY = c.y - halfW
        local maxY = c.y + halfW
        local minZ = c.z - halfW
        local maxZ = c.z + halfW

        local closestX = math.max(minX, math.min(self.x, maxX))
        local closestY = math.max(minY, math.min(self.y, maxY))
        local closestZ = math.max(minZ, math.min(self.z, maxZ))

        local dx = self.x - closestX
        local dy = self.y - closestY
        local dz = self.z - closestZ

        local penX = self.radius - math.abs(dx)
        local penY = self.radius - math.abs(dy)
        local penZ = self.radius - math.abs(dz)

        if penX > 0 and penY > 0 and penZ > 0 then
            if penX <= penY and penX <= penZ then
                self.x = self.x + (dx >= 0 and penX or -penX)
            elseif penY <= penX and penY <= penZ then
                self.y = self.y + (dy >= 0 and penY or -penY)
                if dy > 0 then
                    self.onGround = true
                    self.velY = 0
                end
            else
                self.z = self.z + (dz >= 0 and penZ or -penZ)
            end
        end
    end
end

function Camera:transformPoint(wx, wy, wz)
    local relX = wx - self.x
    local relY = wy - self.y
    local relZ = wz - self.z

    local cosCamY, sinCamY = math.cos(-self.yaw), math.sin(-self.yaw)
    local rotX = relX * cosCamY - relZ * sinCamY
    local rotZ = relX * sinCamY + relZ * cosCamY

    local cosCamX, sinCamX = math.cos(-self.pitch), math.sin(-self.pitch)
    local finalY = relY * cosCamX - rotZ * sinCamX
    local finalZ = relY * sinCamX + rotZ * cosCamX

    return rotX, finalY, finalZ
end

return Camera
