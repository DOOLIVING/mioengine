










local sqrt, abs, min, max, floor = math.sqrt, math.abs, math.min, math.max, math.floor

local FlagPhysics3D = {}
FlagPhysics3D.__index = FlagPhysics3D




local SHG3D = {}
SHG3D.__index = SHG3D

function SHG3D.new(cellSize)
    return setmetatable({
        cellSize = cellSize or 4,
        invCell = 1 / (cellSize or 4),
        cells = {},
        bodyCells = {},
    }, SHG3D)
end

function SHG3D:clear()
    self.cells = {}
    self.bodyCells = {}
end

function SHG3D:_hash(cx, cy, cz)
    return cx * 73856093 + cy * 19349669 + cz * 83492791
end

function SHG3D:insert(body)
    local hw, hh, hd = body.hw, body.hh, body.hd
    local px, py, pz = body.x, body.y, body.z
    local x0 = floor((px - hw) * self.invCell)
    local y0 = floor((py - hh) * self.invCell)
    local z0 = floor((pz - hd) * self.invCell)
    local x1 = floor((px + hw) * self.invCell)
    local y1 = floor((py + hh) * self.invCell)
    local z1 = floor((pz + hd) * self.invCell)
    local hashes = {}
    local idx = 0
    for cx = x0, x1 do
        for cy = y0, y1 do
            for cz = z0, z1 do
                idx = idx + 1
                local h = self:_hash(cx, cy, cz)
                hashes[idx] = h
                local cell = self.cells[h]
                if not cell then
                    self.cells[h] = {}
                    cell = self.cells[h]
                end
                cell[#cell + 1] = body
            end
        end
    end
    self.bodyCells[body.id] = hashes
end

function SHG3D:remove(body)
    local hashes = self.bodyCells[body.id]
    if not hashes then return end
    for i = 1, #hashes do
        local cell = self.cells[hashes[i]]
        if cell then
            for j = #cell, 1, -1 do
                if cell[j] == body then
                    cell[j] = cell[#cell]
                    cell[#cell] = nil
                    break
                end
            end
        end
    end
    self.bodyCells[body.id] = nil
end

function SHG3D:updateBody(body)
    self:remove(body)
    self:insert(body)
end

function SHG3D:broadphasePairs(out)
    local n = 0
    local seen = {}
    local cells = self.cells
    for _, cell in pairs(cells) do
        local cn = #cell
        for i = 1, cn do
            local a = cell[i]
            for j = i + 1, cn do
                local b = cell[j]
                if a.id ~= b.id then
                    local minId, maxId
                    if a.id < b.id then
                        minId, maxId = a.id, b.id
                    else
                        minId, maxId = b.id, a.id
                    end
                    local key = tostring(minId) .. "#" .. tostring(maxId)
                    if not seen[key] then
                        seen[key] = true
                        n = n + 1
                        out[n] = a
                        n = n + 1
                        out[n] = b
                    end
                end
            end
        end
    end
    return n
end




local function testSphereSphere(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dz = b.z - a.z
    local distSq = dx * dx + dy * dy + dz * dz
    local rSum = a.radius + b.radius
    if distSq >= rSum * rSum then return nil end
    local dist = sqrt(distSq)
    if dist < 1e-8 then return rSum, 1, 0, 0 end
    local inv = 1 / dist
    return rSum - dist, dx * inv, dy * inv, dz * inv
end

local function testAABB3D(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dz = b.z - a.z
    local overlapX = (a.hw + b.hw) - abs(dx)
    local overlapY = (a.hh + b.hh) - abs(dy)
    local overlapZ = (a.hd + b.hd) - abs(dz)
    if overlapX <= 0 or overlapY <= 0 or overlapZ <= 0 then return nil end
    if overlapX < overlapY and overlapX < overlapZ then
        return overlapX, dx > 0 and 1 or -1, 0, 0
    elseif overlapY < overlapZ then
        return overlapY, 0, dy > 0 and 1 or -1, 0
    else
        return overlapZ, 0, 0, dz > 0 and 1 or -1
    end
end

local function testBoxSphere(box, sph)
    local dx = sph.x - box.x
    local dy = sph.y - box.y
    local dz = sph.z - box.z
    local cx = max(-box.hw, min(dx, box.hw))
    local cy = max(-box.hh, min(dy, box.hh))
    local cz = max(-box.hd, min(dz, box.hd))
    local closeX, closeY, closeZ = box.x + cx, box.y + cy, box.z + cz
    local ddx = sph.x - closeX
    local ddy = sph.y - closeY
    local ddz = sph.z - closeZ
    local distSq = ddx * ddx + ddy * ddy + ddz * ddz
    if distSq >= sph.radius * sph.radius then return nil end
    local dist = sqrt(distSq)
    if dist < 1e-8 then
        local penX = box.hw - abs(dx) + sph.radius
        local penY = box.hh - abs(dy) + sph.radius
        local penZ = box.hd - abs(dz) + sph.radius
        if penX < penY and penX < penZ then
            return penX, dx > 0 and 1 or -1, 0, 0
        elseif penY < penZ then
            return penY, 0, dy > 0 and 1 or -1, 0
        else
            return penZ, 0, 0, dz > 0 and 1 or -1
        end
    end
    local inv = 1 / dist
    return sph.radius - dist, ddx * inv, ddy * inv, ddz * inv
end

local function collide3D(a, b)
    local tA = a.shape
    local tB = b.shape
    if tA == "sphere" and tB == "sphere" then
        return testSphereSphere(a, b)
    elseif tA == "box" and tB == "box" then
        return testAABB3D(a, b)
    elseif tA == "box" and tB == "sphere" then
        return testBoxSphere(a, b)
    elseif tA == "sphere" and tB == "box" then
        local d, nx, ny, nz = testBoxSphere(b, a)
        if d then return d, -nx, -ny, -nz end
    end
    return nil
end




function FlagPhysics3D.new(config)
    config = config or {}
    local self = setmetatable({}, FlagPhysics3D)
    self.gravity = config.gravity or { x = 0, y = 980, z = 0 }
    if type(self.gravity) == "number" then
        self.gravity = { x = 0, y = self.gravity, z = 0 }
    end
    self.groundY = config.groundY or nil
    self.backWall = config.backWall or nil
    self.floorFriction = config.floorFriction or 0.15
    self.bodies = {}
    self.bodyList = {}
    self.bodyListN = 0
    self.onCollide = config.onCollide or nil
    self.broadphase = SHG3D.new(4)
    self._pairBuf = {}
    self._manifoldBuf = {}
    self._manifoldN = 0

    
    self.fixedDt = config.fixedDt or (1 / 60)
    self.accumulator = 0
    self.maxAccum = config.maxAccum or 0.25

    
    self.iterations = config.iterations or 8
    self.baumgarte = config.baumgarte or 0.2
    self.slop = config.slop or 0.01

    return self
end


function FlagPhysics3D:addBody(id, obj, config)
    local hw = (config.w or 1) / 2
    local hh = (config.h or 1) / 2
    local hd = (config.d or 1) / 2
    local body = {
        id = id,
        obj = obj,
        x = obj.x or 0,
        y = obj.y or 0,
        z = obj.z or 0,
        vx = 0,
        vy = 0,
        vz = 0,
        w = config.w or 1,
        h = config.h or 1,
        d = config.d or 1,
        hw = hw, hh = hh, hd = hd,
        radius = config.radius or 0.5,
        shape = config.shape or "box",
        mass = config.mass or 1,
        invMass = 1,
        restitution = config.bounce or 0.3,
        friction = config.friction or 0.5,
        static = config.static or false,
        dynamic = config.dynamic or false,
        trigger = config.trigger or false,
        tag = config.tag or "",
        grounded = false,
        collisions = {},
    }
    if body.static then body.invMass = 0 end
    self.bodies[id] = body
    self.broadphase:insert(body)
    return body
end

function FlagPhysics3D:removeBody(id)
    local body = self.bodies[id]
    if body then
        self.broadphase:remove(body)
        self.bodies[id] = nil
    end
end

function FlagPhysics3D:getBody(id)
    return self.bodies[id]
end

function FlagPhysics3D:applyImpulse(id, ix, iy, iz)
    local b = self.bodies[id]
    if not b or b.static then return end
    b.vx = b.vx + (ix or 0)
    b.vy = b.vy + (iy or 0)
    b.vz = b.vz + (iz or 0)
end

function FlagPhysics3D:setVelocity(id, vx, vy, vz)
    local b = self.bodies[id]
    if not b then return end
    b.vx = vx or 0
    b.vy = vy or 0
    b.vz = vz or 0
end

function FlagPhysics3D:getVelocity(id)
    local b = self.bodies[id]
    if not b then return 0, 0, 0 end
    return b.vx, b.vy, b.vz
end

function FlagPhysics3D:setPosition(id, x, y, z)
    local b = self.bodies[id]
    if not b then return end
    if x then b.x = x end
    if y then b.y = y end
    if z then b.z = z end
    if b.obj then
        if x then b.obj.x = x end
        if y then b.obj.y = y end
        if z then b.obj.z = z end
    end
    self.broadphase:updateBody(b)
end

function FlagPhysics3D:isGrounded(id)
    local b = self.bodies[id]
    if not b then return false end
    return b.grounded
end

function FlagPhysics3D:collidingWithTag(id, tag)
    local b = self.bodies[id]
    if not b then return false end
    for _, col in ipairs(b.collisions) do
        if col.other.tag == tag then return true end
    end
    return false
end




function FlagPhysics3D:update(dt)
    dt = min(dt, self.maxAccum)
    self.accumulator = self.accumulator + dt

    while self.accumulator >= self.fixedDt do
        self:_fixedStep(self.fixedDt)
        self.accumulator = self.accumulator - self.fixedDt
    end

    
    for _, b in pairs(self.bodies) do
        if b.obj then
            b.obj.x = b.x
            b.obj.y = b.y
            b.obj.z = b.z
            b.obj.vx = b.vx
            b.obj.vy = b.vy
            b.obj.vz = b.vz
            b.obj.grounded = b.grounded
        end
    end
end

function FlagPhysics3D:_fixedStep(dt)
    local bodies = self.bodies

    
    self.bodyListN = 0
    for _, b in pairs(bodies) do
        self.bodyListN = self.bodyListN + 1
        self.bodyList[self.bodyListN] = b
    end
    local n = self.bodyListN

    
    for i = 1, n do
        local b = self.bodyList[i]
        b.grounded = false
        b.collisions = {}

        if b.dynamic and not b.static then
            b.vy = b.vy + (self.gravity.y or 0) * dt
            b.vx = b.vx + (self.gravity.x or 0) * dt
            b.vz = b.vz + (self.gravity.z or 0) * dt

            
            b.vx = b.vx * (1 - 0.5 * dt)
            b.vz = b.vz * (1 - 0.5 * dt)
            b.vy = b.vy * (1 - 0.1 * dt)
        end
    end

    
    for i = 1, n do
        local b = self.bodyList[i]
        if not b.static then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            b.z = b.z + b.vz * dt
        end
    end

    
    local pairCount = self.broadphase:broadphasePairs(self._pairBuf)

    
    self._manifoldN = 0
    local pairN = pairCount / 2
    for i = 1, pairN do
        local a = self._pairBuf[i * 2 - 1]
        local b = self._pairBuf[i * 2]
        local d, nx, ny, nz = collide3D(a, b)
        if d and d > 0 then
            self._manifoldN = self._manifoldN + 1
            self._manifoldBuf[self._manifoldN] = self._manifoldBuf[self._manifoldN] or {}
            local m = self._manifoldBuf[self._manifoldN]
            m.a = a; m.b = b
            m.d = d; m.nx = nx; m.ny = ny; m.nz = nz
        end
    end

    
    for iter = 1, self.iterations do
        for i = 1, self._manifoldN do
            local m = self._manifoldBuf[i]
            if not (m.a.trigger or m.b.trigger) then
                self:_solveContact3D(m, dt)
            end
        end
    end

    
    if self.groundY ~= nil then
        for i = 1, n do
            local b = self.bodyList[i]
            if not b.static then
                local bottom = b.y - b.hh
                if bottom < self.groundY then
                    local overlap = self.groundY - bottom
                    b.y = b.y + overlap
                    if b.vy < 0 then
                        b.vy = -b.vy * b.restitution
                    end
                    if abs(b.vy) < 0.5 then
                        b.vy = 0
                        b.grounded = true
                    end
                    
                    b.vx = b.vx * (1 - self.floorFriction * 5 * dt)
                    b.vz = b.vz * (1 - self.floorFriction * 5 * dt)
                end
            end
        end
    end

    
    for i = 1, n do
        self.broadphase:updateBody(self.bodyList[i])
    end
end




function FlagPhysics3D:_solveContact3D(m, dt)
    local a, b = m.a, m.b
    if a.static and b.static then return end

    local nx, ny, nz = m.nx, m.ny, m.nz
    local d = m.d
    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    
    local correction = max(d - self.slop, 0) * self.baumgarte / totalInvMass
    a.x = a.x - nx * correction * a.invMass
    a.y = a.y - ny * correction * a.invMass
    a.z = a.z - nz * correction * a.invMass
    b.x = b.x + nx * correction * b.invMass
    b.y = b.y + ny * correction * b.invMass
    b.z = b.z + nz * correction * b.invMass

    
    local rvx = b.vx - a.vx
    local rvy = b.vy - a.vy
    local rvz = b.vz - a.vz
    local vn = rvx * nx + rvy * ny + rvz * nz

    
    if ny > 0.5 and a.invMass > 0 then a.grounded = true end
    if ny < -0.5 and b.invMass > 0 then b.grounded = true end

    if vn >= 0 then
        a.collisions[#a.collisions + 1] = { other = b, nx = nx, ny = ny, nz = nz }
        b.collisions[#b.collisions + 1] = { other = a, nx = -nx, ny = -ny, nz = -nz }
        return
    end

    
    local e = min(a.restitution, b.restitution)
    local j = -(1 + e) * vn / totalInvMass

    a.vx = a.vx - j * nx * a.invMass
    a.vy = a.vy - j * ny * a.invMass
    a.vz = a.vz - j * nz * a.invMass
    b.vx = b.vx + j * nx * b.invMass
    b.vy = b.vy + j * ny * b.invMass
    b.vz = b.vz + j * nz * b.invMass

    
    rvx = b.vx - a.vx
    rvy = b.vy - a.vy
    rvz = b.vz - a.vz
    
    local tx = rvx - vn * nx
    local ty = rvy - vn * ny
    local tz = rvz - vn * nz
    local tl = sqrt(tx * tx + ty * ty + tz * tz)
    if tl > 1e-6 then
        tx, ty, tz = tx / tl, ty / tl, tz / tl
        local vt = rvx * tx + rvy * ty + rvz * tz
        local mu = sqrt(a.friction * b.friction)
        local jt = -vt / totalInvMass
        jt = max(-mu * abs(vn), min(jt, mu * abs(vn)))

        a.vx = a.vx - jt * tx * a.invMass
        a.vy = a.vy - jt * ty * a.invMass
        a.vz = a.vz - jt * tz * a.invMass
        b.vx = b.vx + jt * tx * b.invMass
        b.vy = b.vy + jt * ty * b.invMass
        b.vz = b.vz + jt * tz * b.invMass
    end

    a.collisions[#a.collisions + 1] = { other = b, nx = nx, ny = ny, nz = nz }
    b.collisions[#b.collisions + 1] = { other = a, nx = -nx, ny = -ny, nz = -nz }

    if self.onCollide then
        self.onCollide(a, b, nx, ny, nz)
    end
end


function FlagPhysics3D:clear()
    self.bodies = {}
    self.bodyListN = 0
    self.broadphase:clear()
    self._manifoldN = 0
end

return FlagPhysics3D
