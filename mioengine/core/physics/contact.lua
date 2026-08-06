



local insert, remove = table.insert, table.remove




local ContactPoint = {}
ContactPoint.__index = ContactPoint

function ContactPoint.new()
    return setmetatable({
        px = 0, py = 0, pz = 0,  
        nx = 0, ny = 0, nz = 0,  
        depth = 0,                 
    }, ContactPoint)
end

function ContactPoint:set(px, py, pz, nx, ny, nz, depth)
    self.px = px; self.py = py; self.pz = pz
    self.nx = nx; self.ny = ny; self.nz = nz
    self.depth = depth
end

function ContactPoint:copy(c)
    self.px = c.px; self.py = c.py; self.pz = c.pz
    self.nx = c.nx; self.ny = c.ny; self.nz = c.nz
    self.depth = c.depth
end




local MAX_CONTACT_POINTS = 4

local ContactManifold = {}
ContactManifold.__index = ContactManifold

function ContactManifold.new()
    local self = setmetatable({}, ContactManifold)
    self.bodyA = nil
    self.bodyB = nil
    self.points = {}
    self.normalX = 0; self.normalY = 0; self.normalZ = 0
    self.pointCount = 0
    self.active = false
    for i = 1, MAX_CONTACT_POINTS do
        self.points[i] = ContactPoint.new()
    end
    return self
end

function ContactManifold:reset()
    self.bodyA = nil
    self.bodyB = nil
    self.normalX = 0; self.normalY = 0; self.normalZ = 0
    self.pointCount = 0
    self.active = false
end

function ContactManifold:addContact(px, py, pz, nx, ny, nz, depth)
    if self.pointCount >= MAX_CONTACT_POINTS then return false end
    self.pointCount = self.pointCount + 1
    self.points[self.pointCount]:set(px, py, pz, nx, ny, nz, depth)
    return true
end

function ContactManifold:removeContact(index)
    if index < 1 or index > self.pointCount then return end
    local last = self.pointCount
    if index < last then
        self.points[index]:copy(self.points[last])
    end
    self.points[last]:set(0,0,0, 0,0,0, 0)
    self.pointCount = self.pointCount - 1
end

function ContactManifold:setNormal(nx, ny, nz)
    self.normalX = nx; self.normalY = ny; self.normalZ = nz
end

function ContactManifold:computeNormalFromPoints()
    if self.pointCount == 0 then return end
    local nx, ny, nz = 0, 0, 0
    for i = 1, self.pointCount do
        local p = self.points[i]
        nx = nx + p.nx
        ny = ny + p.ny
        nz = nz + p.nz
    end
    local inv = 1 / self.pointCount
    self.normalX = nx * inv
    self.normalY = ny * inv
    self.normalZ = nz * inv
end




local ManifoldPool = {}
ManifoldPool.__index = ManifoldPool

function ManifoldPool.new(initialSize)
    local self = setmetatable({}, ManifoldPool)
    self.free = {}
    self.active = {}
    initialSize = initialSize or 32
    for _ = 1, initialSize do
        insert(self.free, ContactManifold.new())
    end
    return self
end

function ManifoldPool:acquire()
    local m
    local n = #self.free
    if n > 0 then
        m = self.free[n]
        self.free[n] = nil
    else
        m = ContactManifold.new()
    end
    m:reset()
    m.active = true
    insert(self.active, m)
    return m
end

function ManifoldPool:release(m)
    m.active = false
    m:reset()
    for i = #self.active, 1, -1 do
        if self.active[i] == m then
            remove(self.active, i)
            break
        end
    end
    insert(self.free, m)
end

function ManifoldPool:releaseAll()
    for i = #self.active, 1, -1 do
        local m = self.active[i]
        m.active = false
        m:reset()
        insert(self.free, m)
        self.active[i] = nil
    end
end

function ManifoldPool:getActive()
    return self.active
end


return {
    ContactPoint    = ContactPoint,
    ContactManifold = ContactManifold,
    ManifoldPool    = ManifoldPool,
    MAX_CONTACT_POINTS = MAX_CONTACT_POINTS,
}
