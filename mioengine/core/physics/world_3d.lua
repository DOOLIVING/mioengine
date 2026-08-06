





local sqrt, abs, max, min = math.sqrt, math.abs, math.max, math.min

local BodyPool         = require("mioengine.core.physics.rigid_body")
local Shapes           = require("mioengine.core.physics.collision_shapes")
local Broadphase       = require("mioengine.core.physics.broadphase")
local Contact          = require("mioengine.core.physics.contact")
local Narrowphase3D    = require("mioengine.core.physics.narrowphase_3d")
local Solver           = require("mioengine.core.physics.solver")
local RigidBody        = BodyPool.RigidBody

local SHG3D = Broadphase.SHG3D


local World3D = {}
World3D.__index = World3D

function World3D.new(config)
    config = config or {}
    local self = setmetatable({}, World3D)

    self.gravityX = config.gravityX or 0
    self.gravityY = config.gravityY or -9.8
    self.gravityZ = config.gravityZ or 0
    self.linearDamping  = config.linearDamping  or 0.01
    self.angularDamping = config.angularDamping  or 0.05

    self.bodies = {}
    self.bodyMap = {}
    self.broadphase = SHG3D.new(config.cellSize or 64)
    self.manifoldPool = Contact.ManifoldPool.new(config.maxManifolds or 64)

    
    self.fixedDt    = config.fixedDt or (1 / 60)
    self.accumulator = 0
    self.maxAccumulator = config.maxAccumulator or 0.25

    
    Solver.BAUMGARTE      = config.baumgarte      or 0.2
    Solver.SLOP           = config.slop            or 0.005
    Solver.VEL_ITERATIONS = config.velIterations   or 8
    Solver.POS_ITERATIONS = config.posIterations   or 3

    
    self.onCollide  = config.onCollide  or nil
    self.onSeparate = config.onSeparate or nil

    
    self.debugDrawAABB     = config.debugDrawAABB     or false
    self.debugDrawNormals  = config.debugDrawNormals  or true
    self.debugDrawContacts = config.debugDrawContacts or true

    return self
end




function World3D:addBody(config)
    config = config or {}
    local body = RigidBody.new()

    body.pos3.x = config.x or 0
    body.pos3.y = config.y or 0
    body.pos3.z = config.z or 0
    body.pos.x = body.pos3.x  
    body.pos.y = body.pos3.y

    body.velocity3.x = config.vx or 0
    body.velocity3.y = config.vy or 0
    body.velocity3.z = config.vz or 0

    body.mass = config.mass or 1
    body.invMass = body.mass > 0 and (1 / body.mass) or 0
    body.restitution = config.bounce or config.restitution or 0.3
    body.friction    = config.friction or 0.5
    body.linearDamping  = config.linearDamping  or self.linearDamping
    body.angularDamping = config.angularDamping or self.angularDamping

    if config.static then
        body:setStatic(true)
    end

    
    local shape = config.shape or "sphere"
    if shape == "sphere" then
        body.shapeType = BodyPool.SHAPE_SPHERE
        body.shapeData = Shapes.sphere(config.radius or 0.5)
        body:setInertiaSphere3(config.radius or 0.5)
    elseif shape == "box" or shape == "aabb" then
        body.shapeType = BodyPool.SHAPE_AABB3D
        body.shapeData = Shapes.aabb3d(
            (config.w or 1) / 2,
            (config.h or 1) / 2,
            (config.d or 1) / 2
        )
        body:setInertiaBox3(
            (config.w or 1) / 2,
            (config.h or 1) / 2,
            (config.d or 1) / 2
        )
    elseif shape == "obb" then
        body.shapeType = BodyPool.SHAPE_OBB3D
        body.shapeData = Shapes.obb3d(
            (config.w or 1) / 2,
            (config.h or 1) / 2,
            (config.d or 1) / 2
        )
        body:setInertiaBox3(
            (config.w or 1) / 2,
            (config.h or 1) / 2,
            (config.d or 1) / 2
        )
    end

    body.grounded3 = false
    body.tags = {}
    body.linkedObject = config.linkedObject or nil
    body.userData = config.userData

    if config.tag then body.tags[config.tag] = true end

    Shapes.computeAABB3D(body)

    body.active = true
    body.id = #self.bodies + 200000 + 1
    self.bodies[#self.bodies + 1] = body
    self.bodyMap[body.id] = body
    self.broadphase:insert(body)

    return body
end

function World3D:removeBody(body)
    if not body then return end
    body.active = false
    self.broadphase:remove(body)
    self.bodyMap[body.id] = nil
    for i = #self.bodies, 1, -1 do
        if self.bodies[i] == body then
            self.bodies[i] = self.bodies[#self.bodies]
            self.bodies[#self.bodies] = nil
            break
        end
    end
end

function World3D:getBody(id)
    return self.bodyMap[id]
end

function World3D:applyForce(body, fx, fy, fz)
    body.force3.x = body.force3.x + fx
    body.force3.y = body.force3.y + fy
    body.force3.z = body.force3.z + fz
end

function World3D:applyImpulse(body, ix, iy, iz)
    if body.invMass == 0 then return end
    body.velocity3.x = body.velocity3.x + ix * body.invMass
    body.velocity3.y = body.velocity3.y + iy * body.invMass
    body.velocity3.z = body.velocity3.z + iz * body.invMass
end

function World3D:setVelocity(body, vx, vy, vz)
    body.velocity3.x = vx or 0
    body.velocity3.y = vy or 0
    body.velocity3.z = vz or 0
end

function World3D:getVelocity(body)
    return body.velocity3.x, body.velocity3.y, body.velocity3.z
end

function World3D:setPosition(body, x, y, z)
    if x then body.pos3.x = x; body.pos.x = x end
    if y then body.pos3.y = y; body.pos.y = y end
    if z then body.pos3.z = z end
    Shapes.computeAABB3D(body)
    self.broadphase:updateBody(body)
end

function World3D:getPosition(body)
    return body.pos3.x, body.pos3.y, body.pos3.z
end

function World3D:isGrounded(body)
    return body.grounded3
end




function World3D:update(dt)
    dt = min(dt, self.maxAccumulator)
    self.accumulator = self.accumulator + dt

    while self.accumulator >= self.fixedDt do
        self:_fixedUpdate(self.fixedDt)
        self.accumulator = self.accumulator - self.fixedDt
    end
end

function World3D:_fixedUpdate(dt)
    local bodies = self.bodies
    local n = #bodies

    
    for i = 1, n do
        local b = bodies[i]
        if b.bodyType == BodyPool.BODY_DYNAMIC and b.invMass > 0 then
            b.velocity3.x = b.velocity3.x + self.gravityX * dt
            b.velocity3.y = b.velocity3.y + self.gravityY * dt
            b.velocity3.z = b.velocity3.z + self.gravityZ * dt

            b.velocity3.x = b.velocity3.x + b.force3.x * dt
            b.velocity3.y = b.velocity3.y + b.force3.y * dt
            b.velocity3.z = b.velocity3.z + b.force3.z * dt

            b.velocity3.x = b.velocity3.x * (1 - b.linearDamping * dt)
            b.velocity3.y = b.velocity3.y * (1 - b.linearDamping * dt)
            b.velocity3.z = b.velocity3.z * (1 - b.linearDamping * dt)
            b.angularVelocity3.x = b.angularVelocity3.x * (1 - b.angularDamping * dt)
            b.angularVelocity3.y = b.angularVelocity3.y * (1 - b.angularDamping * dt)
            b.angularVelocity3.z = b.angularVelocity3.z * (1 - b.angularDamping * dt)
        end
        b.force3.x = 0; b.force3.y = 0; b.force3.z = 0
        b.grounded3 = false
        b.collisions = {}
    end

    
    for i = 1, n do
        local b = bodies[i]
        if b.bodyType == BodyPool.BODY_DYNAMIC and b.invMass > 0 then
            b.pos3.x = b.pos3.x + b.velocity3.x * dt
            b.pos3.y = b.pos3.y + b.velocity3.y * dt
            b.pos3.z = b.pos3.z + b.velocity3.z * dt
            b.pos.x = b.pos3.x
            b.pos.y = b.pos3.y
        end
    end

    
    self.manifoldPool:releaseAll()
    local pairs = self.broadphase:broadphasePairs()

    
    local pairCount = #pairs / 2
    for i = 1, pairCount do
        local a = pairs[i * 2 - 1]
        local b = pairs[i * 2]
        if a.active and b.active then
            local manifold = self.manifoldPool:acquire()
            manifold.bodyA = a
            manifold.bodyB = b
            local hit = Narrowphase3D.test(a, b, manifold)
            if not hit then
                self.manifoldPool:release(manifold)
            end
        end
    end

    
    local activeManifolds = self.manifoldPool:getActive()
    for iter = 1, Solver.VEL_ITERATIONS do
        for i = 1, #activeManifolds do
            Solver.solveContact3D(activeManifolds[i], dt)
        end
    end

    
    for i = 1, Solver.POS_ITERATIONS do
        for j = 1, #activeManifolds do
            Solver.positionalCorrection3D(activeManifolds[j])
        end
    end

    
    for i = 1, n do
        local b = bodies[i]
        Shapes.computeAABB3D(b)
        self.broadphase:updateBody(b)
        if b.linkedObject then
            local obj = b.linkedObject
            obj.x = b.pos3.x
            obj.y = b.pos3.y
            obj.z = b.pos3.z
            obj.vx = b.velocity3.x
            obj.vy = b.velocity3.y
            obj.vz = b.velocity3.z
            obj.grounded = b.grounded3
        end
    end

    if self.onCollide then
        for i = 1, #activeManifolds do
            local m = activeManifolds[i]
            if m.pointCount > 0 then
                self.onCollide(m.bodyA, m.bodyB, m.normalX, m.normalY, m.normalZ)
            end
        end
    end
end




function World3D:queryPoint(x, y, z)
    local results = {}
    local invCellSize = self.broadphase.invCellSize
    local cx = math.floor(x * invCellSize)
    local cy = math.floor(y * invCellSize)
    local cz = math.floor(z * invCellSize)
    local h = cx * 73856093 + cy * 19349669 + cz * 83492791
    local cell = self.broadphase.cells[h]
    if cell then
        for i = 1, #cell do
            local b = cell[i]
            local s = b.shapeData
            if s and s.type == "sphere" then
                local dx, dy, dz = x - b.pos3.x, y - b.pos3.y, z - b.pos3.z
                if dx*dx + dy*dy + dz*dz <= s.radius*s.radius then
                    results[#results + 1] = b
                end
            end
        end
    end
    return results
end

function World3D:clear()
    self.bodies = {}
    self.bodyMap = {}
    self.broadphase:clear()
    self.manifoldPool:releaseAll()
end




function World3D:drawDebug()
    local lg = love.graphics

    if self.debugDrawAABB then
        lg.setColor(0, 1, 0, 0.3)
        lg.setLineWidth(1)
        for _, b in ipairs(self.bodies) do
            
            local sx = b.pos3.x - (b.aabbMaxX3 - b.aabbMinX3) / 2
            local sy = b.pos3.y - (b.aabbMaxY3 - b.aabbMinY3) / 2
            lg.rectangle("line", sx, sy,
                b.aabbMaxX3 - b.aabbMinX3,
                b.aabbMaxY3 - b.aabbMinY3
            )
        end
    end

    for _, b in ipairs(self.bodies) do
        local s = b.shapeData
        if s then
            if s.type == "sphere" then
                lg.setColor(0.4, 0.8, 1, 0.7)
                lg.circle("line", b.pos3.x, b.pos3.y, s.radius * 50)
            elseif s.type == "aabb3d" then
                lg.setColor(0.4, 0.8, 1, 0.7)
                lg.rectangle("line",
                    b.pos3.x - s.halfW, b.pos3.y - s.halfH,
                    s.halfW * 2, s.halfH * 2
                )
            end
        end
    end

    if self.debugDrawNormals then
        local activeManifolds = self.manifoldPool:getActive()
        lg.setColor(1, 0.3, 0.3, 0.8)
        lg.setLineWidth(2)
        for i = 1, #activeManifolds do
            local m = activeManifolds[i]
            for j = 1, m.pointCount do
                local p = m.points[j]
                local len = 20
                lg.line(p.px, p.py, p.px + p.nx * len, p.py + p.ny * len)
            end
        end
    end

    if self.debugDrawContacts then
        local activeManifolds = self.manifoldPool:getActive()
        lg.setColor(1, 1, 0, 1)
        for i = 1, #activeManifolds do
            local m = activeManifolds[i]
            for j = 1, m.pointCount do
                local p = m.points[j]
                lg.circle("fill", p.px, p.py, 3)
            end
        end
    end
end




function World3D:addBodyLegacy(config)
    local body = self:addBody(config)
    body._legacyId = config.id or ("body3d_" .. #self.bodies)
    return body._legacyId, body
end

function World3D:removeBodyLegacy(id)
    for _, b in ipairs(self.bodies) do
        if b._legacyId == id then
            self:removeBody(b)
            return
        end
    end
end

function World3D:getBodyLegacy(id)
    for _, b in ipairs(self.bodies) do
        if b._legacyId == id then
            return b
        end
    end
end


return World3D
