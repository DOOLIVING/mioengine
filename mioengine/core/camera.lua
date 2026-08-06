local Camera = {}
Camera.__index = Camera

function Camera.new(config)
    local self = setmetatable({}, Camera)
    self.x = config.x or 0
    self.y = config.y or 0.5
    self.z = config.z or 0
    self.yaw = 0
    self.pitch = 0
    self.moveSpeed = config.moveSpeed or 7
    self.mouseSensitivity = config.mouseSensitivity or 0.0025
    self.pitchLimit = math.rad(85)
    self.velY = 0
    self.groundY = config.groundY or 0
    self.startY = config.y or 0.5
    self.gravity = 12
    self.jumpForce = 9
    self.onGround = true
    self.radius = 0.3
    self.height = 1.0
    self.sprinting = false
    self.sprintMultiplier = 1.6
    self.stamina = 100
    self.maxStamina = 100
    self.sprintDrain = 30
    self.sprintRegen = 15
    self.slamSpeed = 35
    self.slamming = false
    return self
end

function Camera:handleMouseMoved(dx, dy)
    self.yaw = self.yaw - dx * self.mouseSensitivity
    self.pitch = self.pitch + dy * self.mouseSensitivity
    if self.pitch > self.pitchLimit then self.pitch = self.pitchLimit end
    if self.pitch < -self.pitchLimit then self.pitch = -self.pitchLimit end
end

function Camera:update(dt, colliders)
    dt = math.min(dt, 0.05)
    local cosYaw, sinYaw = math.cos(self.yaw), math.sin(self.yaw)

    local wantSprint = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    if wantSprint and self.stamina > 0 then
        self.slamming = true
        self.sprinting = true
        self.stamina = math.max(0, self.stamina - self.sprintDrain * dt)
    else
        self.slamming = false
        self.sprinting = false
        self.stamina = math.min(self.maxStamina, self.stamina + self.sprintRegen * dt)
    end

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

    local lookX, lookZ, lookY = 0, 0, 0
    if self.slamming then
        lookX = -sinYaw * math.cos(self.pitch)
        lookZ = cosYaw * math.cos(self.pitch)
        lookY = -math.sin(self.pitch)
    end

    if not self.slamming then
        if love.keyboard.isDown("space") and self.onGround then
            self.velY = self.jumpForce
            self.onGround = false
        end
    end

    local stepSize = 0.016
    local remaining = dt
    while remaining > 0 do
        local step = math.min(remaining, stepSize)

        if self.slamming then
            self.x = self.x + lookX * self.slamSpeed * step
            self.z = self.z + lookZ * self.slamSpeed * step
            self.y = self.y + lookY * self.slamSpeed * step
        else
            self.x = self.x + moveDirX * self.moveSpeed * step
            self.z = self.z + moveDirZ * self.moveSpeed * step
            self.velY = self.velY - self.gravity * step
            self.y = self.y + self.velY * step
        end

        if colliders then
            self:resolveCollisions(colliders)
        end

        remaining = remaining - step
    end

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
    if self.y - self.height < self.groundY then
        self.y = self.groundY + self.height
        self.velY = 0
        self.onGround = true
    end

    for _, c in ipairs(colliders) do
        local halfX = c.halfSizeX or c.halfSize or 0.5
        local halfY = c.halfSizeY or c.halfSize or 0.5
        local halfZ = c.halfSizeZ or c.halfSize or 0.5
        local minX = c.x - halfX
        local maxX = c.x + halfX
        local minY = c.y - halfY
        local maxY = c.y + halfY
        local minZ = c.z - halfZ
        local maxZ = c.z + halfZ

        local closestX = math.max(minX, math.min(self.x, maxX))
        local closestY = math.max(minY, math.min(self.y, maxY))
        local closestZ = math.max(minZ, math.min(self.z, maxZ))

        local dx = self.x - closestX
        local dy = self.y - closestY
        local dz = self.z - closestZ

        local distSq = dx * dx + dy * dy + dz * dz
        if distSq < self.radius * self.radius then
            local dist = math.sqrt(distSq)
            if dist > 0.0001 then
                local push = self.radius - dist
                self.x = self.x + (dx / dist) * push
                self.y = self.y + (dy / dist) * push
                self.z = self.z + (dz / dist) * push
                if dy / dist > 0.5 then
                    self.onGround = true
                    self.velY = 0
                end
            else
                local ex = halfX + self.radius - math.abs(self.x - c.x)
                local ey = halfY + self.radius - math.abs(self.y - c.y)
                local ez = halfZ + self.radius - math.abs(self.z - c.z)
                if ex <= ey and ex <= ez then
                    self.x = self.x + (self.x >= c.x and ex or -ex)
                elseif ey <= ex and ey <= ez then
                    self.y = self.y + (self.y >= c.y and ey or -ey)
                    if self.y > c.y then
                        self.onGround = true
                        self.velY = 0
                    end
                else
                    self.z = self.z + (self.z >= c.z and ez or -ez)
                end
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

function Camera:isInFrustum(wx, wy, wz, radius)
    radius = radius or 1
    local rx, ry, rz = self:transformPoint(wx, wy, wz)
    if rz < radius then return false end
    local fovFactor = 1.2
    local halfW = rz * fovFactor
    local halfH = rz * fovFactor
    if rx < -halfW - radius or rx > halfW + radius then return false end
    if ry < -halfH - radius or ry > halfH + radius then return false end
    return true
end

return Camera
