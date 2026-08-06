










local sqrt, abs, min, max, floor = math.sqrt, math.abs, math.min, math.max, math.floor

local FlagPhysics = {}
FlagPhysics.__index = FlagPhysics




local SHG = {}
SHG.__index = SHG

function SHG.new(cellSize)
    return setmetatable({
        cellSize = cellSize or 64,
        invCell = 1 / (cellSize or 64),
        cells = {},
        bodyCells = {},
    }, SHG)
end

function SHG:clear()
    self.cells = {}
    self.bodyCells = {}
end

function SHG:_hash(cx, cy)
    return cx * 73856093 + cy * 19349669
end

function SHG:insert(body)
    local hw, hh = body.w / 2, body.h / 2
    local x0 = floor((body.x - hw) * self.invCell)
    local y0 = floor((body.y - hh) * self.invCell)
    local x1 = floor((body.x + hw) * self.invCell)
    local y1 = floor((body.y + hh) * self.invCell)
    local hashes = {}
    local idx = 0
    for cx = x0, x1 do
        for cy = y0, y1 do
            idx = idx + 1
            local h = self:_hash(cx, cy)
            hashes[idx] = h
            local cell = self.cells[h]
            if not cell then
                self.cells[h] = {}
                cell = self.cells[h]
            end
            cell[#cell + 1] = body
        end
    end
    self.bodyCells[body.id] = hashes
end

function SHG:remove(body)
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

function SHG:updateBody(body)
    self:remove(body)
    self:insert(body)
end

function SHG:broadphasePairs(out)
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




local function testAABB(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local overlapX = (a.w / 2 + b.w / 2) - abs(dx)
    local overlapY = (a.h / 2 + b.h / 2) - abs(dy)
    if overlapX <= 0 or overlapY <= 0 then return nil end
    if overlapX < overlapY then
        return overlapX, dx > 0 and 1 or -1, 0
    else
        return overlapY, 0, dy > 0 and 1 or -1
    end
end

local function testCircle(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local distSq = dx * dx + dy * dy
    local rSum = a.radius + b.radius
    if distSq >= rSum * rSum then return nil end
    local dist = sqrt(distSq)
    if dist < 1e-8 then return rSum, 1, 0 end
    local inv = 1 / dist
    return rSum - dist, dx * inv, dy * inv
end

local function testRectCircle(rect, circ)
    local hw, hh = rect.w / 2, rect.h / 2
    local cx = max(-hw, min(circ.x - rect.x, hw)) + rect.x
    local cy = max(-hh, min(circ.y - rect.y, hh)) + rect.y
    local dx = circ.x - cx
    local dy = circ.y - cy
    local distSq = dx * dx + dy * dy
    if distSq >= circ.radius * circ.radius then return nil end
    local dist = sqrt(distSq)
    if dist < 1e-8 then
        local penX = hw - abs(circ.x - rect.x) + circ.radius
        local penY = hh - abs(circ.y - rect.y) + circ.radius
        if penX < penY then
            return penX, circ.x > rect.x and 1 or -1, 0
        else
            return penY, 0, circ.y > rect.y and 1 or -1
        end
    end
    local inv = 1 / dist
    return circ.radius - dist, dx * inv, dy * inv
end

local function collide(a, b)
    local tA = a.shape
    local tB = b.shape
    if tA == "rect" and tB == "rect" then
        return testAABB(a, b)
    elseif tA == "circle" and tB == "circle" then
        return testCircle(a, b)
    elseif tA == "rect" and tB == "circle" then
        return testRectCircle(a, b)
    elseif tA == "circle" and tB == "rect" then
        local d, nx, ny = testRectCircle(b, a)
        if d then return d, -nx, -ny end
    end
    return nil
end




function FlagPhysics.new(config)
    config = config or {}
    local self = setmetatable({}, FlagPhysics)
    self.gravity = config.gravity or 980
    self.groundY = config.groundY or nil
    self.bodies = {}
    self.bodyList = {}       
    self.bodyListN = 0
    self.onCollide = config.onCollide or nil
    self.broadphase = SHG.new(64)
    self._pairBuf = {}       
    self._manifoldBuf = {}   
    self._manifoldN = 0

    
    self.fixedDt = config.fixedDt or (1 / 60)
    self.accumulator = 0
    self.maxAccum = config.maxAccum or 0.25

    
    self.iterations = config.iterations or 8
    self.baumgarte = config.baumgarte or 0.2
    self.slop = config.slop or 0.005

    return self
end




function FlagPhysics:addBody(id, obj, config)
    local body = {
        id = id,
        obj = obj,
        x = obj.x or 0,
        y = obj.y or 0,
        vx = 0,
        vy = 0,
        w = config.w or 32,
        h = config.h or 32,
        radius = config.radius or 16,
        shape = config.shape or "rect",
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
        
        aabbDirty = true,
    }
    if body.static then body.invMass = 0 end
    self.bodies[id] = body
    self.broadphase:insert(body)
    return body
end

function FlagPhysics:removeBody(id)
    local body = self.bodies[id]
    if body then
        self.broadphase:remove(body)
        self.bodies[id] = nil
    end
end

function FlagPhysics:getBody(id)
    return self.bodies[id]
end

function FlagPhysics:applyImpulse(id, ix, iy)
    local b = self.bodies[id]
    if not b or b.static then return end
    b.vx = b.vx + ix
    b.vy = b.vy + iy
end

function FlagPhysics:setVelocity(id, vx, vy)
    local b = self.bodies[id]
    if not b then return end
    b.vx = vx or 0
    b.vy = vy or 0
end

function FlagPhysics:getVelocity(id)
    local b = self.bodies[id]
    if not b then return 0, 0 end
    return b.vx, b.vy
end

function FlagPhysics:setPosition(id, x, y)
    local b = self.bodies[id]
    if not b then return end
    if x then b.x = x end
    if y then b.y = y end
    if b.obj then
        if x then b.obj.x = x end
        if y then b.obj.y = y end
    end
    self.broadphase:updateBody(b)
end

function FlagPhysics:isGrounded(id)
    local b = self.bodies[id]
    if not b then return false end
    return b.grounded
end

function FlagPhysics:collidingWithTag(id, tag)
    local b = self.bodies[id]
    if not b then return false end
    for _, col in ipairs(b.collisions) do
        if col.other.tag == tag then return true end
    end
    return false
end




function FlagPhysics:update(dt)
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
            b.obj.vx = b.vx
            b.obj.vy = b.vy
            b.obj.grounded = b.grounded
        end
    end
end

function FlagPhysics:_fixedStep(dt)
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
            b.vy = b.vy + self.gravity * dt

            
            b.vx = b.vx * (1 - 0.5 * dt)
            b.vy = b.vy * (1 - 0.1 * dt)
        end
    end

    
    for i = 1, n do
        local b = self.bodyList[i]
        if not b.static then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
        end
    end

    
    local pairCount = self.broadphase:broadphasePairs(self._pairBuf)

    
    self._manifoldN = 0
    local pairN = pairCount / 2
    for i = 1, pairN do
        local a = self._pairBuf[i * 2 - 1]
        local b = self._pairBuf[i * 2]
        if a.active ~= false and b.active ~= false then
            local d, nx, ny = collide(a, b)
            if d and d > 0 then
                self._manifoldN = self._manifoldN + 1
                self._manifoldBuf[self._manifoldN] = self._manifoldBuf[self._manifoldN] or {}
                local m = self._manifoldBuf[self._manifoldN]
                m.a = a; m.b = b
                m.d = d; m.nx = nx; m.ny = ny
            end
        end
    end

    
    for iter = 1, self.iterations do
        for i = 1, self._manifoldN do
            local m = self._manifoldBuf[i]
            local a, b = m.a, m.b
            if not (a.trigger or b.trigger) then
                self:_solveContact(m, dt)
            end
        end
    end

    
    if self.groundY then
        for i = 1, n do
            local b = self.bodyList[i]
            if not b.static then
                local bottom
                if b.shape == "circle" then
                    bottom = b.y + b.radius
                else
                    bottom = b.y + b.h / 2
                end
                if bottom > self.groundY then
                    local overlap = bottom - self.groundY
                    b.y = b.y - overlap
                    if b.vy > 0 then
                        b.vy = -b.vy * b.restitution
                    end
                    if abs(b.vy) < 20 then
                        b.vy = 0
                        b.grounded = true
                    end
                    
                    b.vx = b.vx * (1 - b.friction * 0.3)
                end
            end
        end
    end

    
    for i = 1, n do
        self.broadphase:updateBody(self.bodyList[i])
    end
end




function FlagPhysics:_solveContact(m, dt)
    local a, b = m.a, m.b
    if a.static and b.static then return end

    local nx, ny = m.nx, m.ny
    local d = m.d
    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    
    local correction = max(d - self.slop, 0) * self.baumgarte / totalInvMass
    a.x = a.x - nx * correction * a.invMass
    a.y = a.y - ny * correction * a.invMass
    b.x = b.x + nx * correction * b.invMass
    b.y = b.y + ny * correction * b.invMass

    
    
    local rvx = b.vx - a.vx
    local rvy = b.vy - a.vy
    local vn = rvx * nx + rvy * ny

    
    
    if ny > 0.5 and a.invMass > 0 then a.grounded = true end
    if ny < -0.5 and b.invMass > 0 then b.grounded = true end

    
    if vn >= 0 then
        
        a.collisions[#a.collisions + 1] = { other = b, nx = nx, ny = ny }
        b.collisions[#b.collisions + 1] = { other = a, nx = -nx, ny = -ny }
        return
    end

    
    local e = min(a.restitution, b.restitution)
    local j = -(1 + e) * vn / totalInvMass

    
    a.vx = a.vx - j * nx * a.invMass
    a.vy = a.vy - j * ny * a.invMass
    b.vx = b.vx + j * nx * b.invMass
    b.vy = b.vy + j * ny * b.invMass

    
    
    rvx = b.vx - a.vx
    rvy = b.vy - a.vy
    
    local tx, ty = -ny, nx
    local vt = rvx * tx + rvy * ty

    
    local mu = sqrt(a.friction * b.friction)
    local jt
    if abs(vt) < e * abs(vn) then
        
        jt = -vt / totalInvMass
        if abs(jt) > mu * abs(j) then
            jt = mu * abs(j) * (vt > 0 and 1 or -1)
        end
    else
        
        jt = -mu * abs(vn) / totalInvMass
    end

    
    a.vx = a.vx - jt * tx * a.invMass
    a.vy = a.vy + jt * ty * a.invMass
    b.vx = b.vx + jt * tx * b.invMass
    b.vy = b.vy + jt * ty * b.invMass

    
    a.collisions[#a.collisions + 1] = { other = b, nx = nx, ny = ny }
    b.collisions[#b.collisions + 1] = { other = a, nx = -nx, ny = -ny }

    
    if self.onCollide then
        self.onCollide(a, b, nx, ny)
    end
end


function FlagPhysics:clear()
    self.bodies = {}
    self.bodyListN = 0
    self.broadphase:clear()
    self._manifoldN = 0
end

return FlagPhysics
