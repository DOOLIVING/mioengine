local Camera = {}

function Camera.new()
    local self = {}
    self.x = 0
    self.y = 3
    self.z = -8
    self.targetX = 0
    self.targetY = 0
    self.targetZ = 0
    self.yaw = 0
    self.pitch = 0.4
    self.dist = 10
    self.fov = 500
    return self
end

function Camera.update(cam)
    cam.x = cam.targetX + math.sin(cam.yaw) * math.cos(cam.pitch) * cam.dist
    cam.y = cam.targetY + math.sin(cam.pitch) * cam.dist
    cam.z = cam.targetZ - math.cos(cam.yaw) * math.cos(cam.pitch) * cam.dist
end

function Camera.transformPoint(cam, wx, wy, wz)
    local rx = wx - cam.x
    local ry = wy - cam.y
    local rz = wz - cam.z

    local cosY, sinY = math.cos(-cam.yaw), math.sin(-cam.yaw)
    local x1 = rx * cosY - rz * sinY
    local z1 = rx * sinY + rz * cosY

    local cosP, sinP = math.cos(-cam.pitch), math.sin(-cam.pitch)
    local y1 = ry * cosP - z1 * sinP
    local z2 = ry * sinP + z1 * cosP

    return x1, y1, z2
end

function Camera.projectPoint(cam, wx, wy, wz, W, H)
    local rx, ry, rz = Camera.transformPoint(cam, wx, wy, wz)
    if rz < 0.1 then rz = 0.1 end
    local sx = (rx * cam.fov) / rz + W / 2
    local sy = (-ry * cam.fov) / rz + H / 2
    return sx, sy, rz
end

return Camera
