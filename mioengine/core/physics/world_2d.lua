





local sqrt, abs, max, min, floor = math.sqrt, math.abs, math.max, math.min, math.floor

local BodyPool         = require("mioengine.core.physics.rigid_body")
local Shapes           = require("mioengine.core.physics.collision_shapes")
local Broadphase       = require("mioengine.core.physics.broadphase")
local Contact          = require("mioengine.core.physics.contact")
local Narrowphase2D    = require("mioengine.core.physics.narrowphase_2d")
local Solver           = require("mioengine.core.physics.solver")
local RigidBody        = BodyPool.RigidBody

local SHG2D = Broadphase.SHG2D


local World2D = {}
World2D.__index = World2D

function World2D.new(config)
    config = config or {}
    local self = setmetatable({}, World2D)

    self.gravityX = config.gravityX or 0
    self.gravityY = config.gravityY or 980
    self.linearDamping  = config.linearDamping  or 0.001
    self.angularDamping = config.angularDamping  or 0.001

    self.bodies = {}            
    self.bodyMap = {}           
    self.broadphase = SHG2D.new(config.cellSize or 64)
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

    
    self.debugDrawAABB      = config.debugDrawAABB      or false
    self.debugDrawNormals   = config.debugDrawNormals   or true
    self.debugDrawContacts  = config.debugDrawContacts  or true
    self.debugDrawForces    = config.debugDrawForces    or false
    self.debugDrawCOM       = config.debugDrawCOM       or false

    return self
end




function World2D:addBody(config)
    config = config or {}
    local body = RigidBody.new()

    body.pos.x = config.x or 0
    body.pos.y = config.y or 0
    body.angle = config.angle or 0

    body.velocity.x = config.vx or 0
    body.velocity.y = config.vy or 0
    body.angularVelocity = config.angularVel or 0

    body.mass = config.mass or 1
    body.invMass = body.mass > 0 and (1 / body.mass) or 0
    body.restitution = config.bounce or config.restitution or 0.3
    body.friction    = config.friction or 0.5
    body.linearDamping  = config.linearDamping  or self.linearDamping
    body.angularDamping = config.angularDamping or self.angularDamping

    if config.static then
        body:setStatic(true)
    end

    
    local shape = config.shape or "rect"
    if shape == "rect" then
        body.shapeType = BodyPool.SHAPE_AABB
        body.shapeData = Shapes.aabb((config.w or 32) / 2, (config.h or 32) / 2)
    elseif shape == "circle" then
        body.shapeType = BodyPool.SHAPE_CIRCLE
        body.shapeData = Shapes.circle(config.radius or 16)
    elseif shape == "obb" then
        body.shapeType = BodyPool.SHAPE_OBB
        body.shapeData = Shapes.obb((config.w or 32) / 2, (config.h or 32) / 2, body.angle)
    end

    body.grounded = false
    body.tags = {}
    body.linkedObject = config.linkedObject or nil
    body.userData = config.userData

    if config.tag then body.tags[config.tag] = true end

    Shapes.computeAABB2D(body)

    body.active = true
    body.id = #self.bodies + 100000 + 1  
    self.bodies[#self.bodies + 1] = body
    self.bodyMap[body.id] = body
    self.broadphase:insert(body)

    return body
end

function World2D:removeBody(body)
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

function World2D:getBody(id)
    return self.bodyMap[id]
end

function World2D:applyForce(body, fx, fy)
    body.force.x = body.force.x + fx
    body.force.y = body.force.y + fy
end

function World2D:applyImpulse(body, ix, iy)
    if body.invMass == 0 then return end
    body.velocity.x = body.velocity.x + ix * body.invMass
    body.velocity.y = body.velocity.y + iy * body.invMass
end

function World2D:setVelocity(body, vx, vy)
    body.velocity.x = vx or 0
    body.velocity.y = vy or 0
end

function World2D:getVelocity(body)
    return body.velocity.x, body.velocity.y
end

function World2D:setPosition(body, x, y)
    if x then body.pos.x = x end
    if y then body.pos.y = y end
    Shapes.computeAABB2D(body)
    self.broadphase:updateBody(body)
end

function World2D:getPosition(body)
    return body.pos.x, body.pos.y
end

function World2D:isGrounded(body)
    return body.grounded
end




function World2D:update(dt)
    dt = min(dt, self.maxAccumulator)
    self.accumulator = self.accumulator + dt

    while self.accumulator >= self.fixedDt do
        self:_fixedUpdate(self.fixedDt)
        self.accumulator = self.accumulator - self.fixedDt
    end
end

function World2D:_fixedUpdate(dt)
    local bodies = self.bodies
    local n = #bodies

    
    for i = 1, n do
        local b = bodies[i]
        if b.bodyType == BodyPool.BODY_DYNAMIC and b.invMass > 0 then
            
            b.velocity.x = b.velocity.x + self.gravityX * dt
            b.velocity.y = b.velocity.y + self.gravityY * dt

            
            b.velocity.x = b.velocity.x + b.force.x * dt
            b.velocity.y = b.velocity.y + b.force.y * dt

            
            b.velocity.x = b.velocity.x * (1 - b.linearDamping * dt)
            b.velocity.y = b.velocity.y * (1 - b.linearDamping * dt)
            b.angularVelocity = b.angularVelocity * (1 - b.angularDamping * dt)
        end
        b.force.x = 0; b.force.y = 0
        b.grounded = false
        b.collisions = {}
    end

    
    for i = 1, n do
        local b = bodies[i]
        if b.bodyType == BodyPool.BODY_DYNAMIC and b.invMass > 0 then
            b.pos.x = b.pos.x + b.velocity.x * dt
            b.pos.y = b.pos.y + b.velocity.y * dt
            b.angle = b.angle + b.angularVelocity * dt

            
            if b.shapeData and b.shapeData.type == "obb" then
                b.shapeData.angle = b.angle
            end
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
            local hit = Narrowphase2D.test(a, b, manifold)
            if not hit then
                self.manifoldPool:release(manifold)
            end
        end
    end

    
    local activeManifolds = self.manifoldPool:getActive()
    for iter = 1, Solver.VEL_ITERATIONS do
        for i = 1, #activeManifolds do
            Solver.solveContact(activeManifolds[i], dt)
        end
    end

    
    for i = 1, Solver.POS_ITERATIONS do
        for j = 1, #activeManifolds do
            Solver.positionalCorrection(activeManifolds[j])
        end
    end

    
    for i = 1, n do
        local b = bodies[i]
        Shapes.computeAABB2D(b)
        self.broadphase:updateBody(b)
        if b.linkedObject then
            b.linkedObject.x = b.pos.x
            b.linkedObject.y = b.pos.y
            b.linkedObject.vx = b.velocity.x
            b.linkedObject.vy = b.velocity.y
            b.linkedObject.angle = b.angle
            b.linkedObject.grounded = b.grounded
        end
    end

    
    if self.onCollide then
        for i = 1, #activeManifolds do
            local m = activeManifolds[i]
            if m.pointCount > 0 then
                self.onCollide(m.bodyA, m.bodyB, m.normalX, m.normalY)
            end
        end
    end
end




function World2D:queryPoint(x, y)
    return self.broadphase:queryPoint(x, y)
end

function World2D:queryAABB(minX, minY, maxX, maxY)
    return self.broadphase:queryAABB(minX, minY, maxX, maxY)
end

function World2D:clear()
    self.bodies = {}
    self.bodyMap = {}
    self.broadphase:clear()
    self.manifoldPool:releaseAll()
end




function World2D:drawDebug()
    local lg = love.graphics

    
    if self.debugDrawAABB then
        lg.setColor(0, 1, 0, 0.3)
        lg.setLineWidth(1)
        for _, b in ipairs(self.bodies) do
            lg.rectangle("line",
                b.aabbMinX, b.aabbMinY,
                b.aabbMaxX - b.aabbMinX,
                b.aabbMaxY - b.aabbMinY
            )
        end
    end

    
    for _, b in ipairs(self.bodies) do
        local s = b.shapeData
        if s then
            if s.type == "circle" then
                lg.setColor(0.4, 0.6, 1, 0.7)
                lg.circle("line", b.pos.x, b.pos.y, s.radius)
            elseif s.type == "aabb" then
                lg.setColor(0.4, 0.6, 1, 0.7)
                lg.rectangle("line", b.pos.x - s.halfW, b.pos.y - s.halfH, s.halfW * 2, s.halfH * 2)
            elseif s.type == "obb" then
                lg.setColor(0.4, 0.6, 1, 0.7)
                local c, sn = math.cos(b.angle), math.sin(b.angle)
                local hw, hh = s.halfW, s.halfH
                local verts = {
                    b.pos.x + c * hw - sn * hh, b.pos.y + sn * hw + c * hh,
                    b.pos.x + c * hw + sn * hh, b.pos.y + sn * hw - c * hh,
                    b.pos.x - c * hw + sn * hh, b.pos.y - sn * hw - c * hh,
                    b.pos.x - c * hw - sn * hh, b.pos.y - sn * hw + c * hh,
                }
                lg.polygon("line", verts)
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

    
    if self.debugDrawForces then
        lg.setColor(1, 0, 0, 0.6)
        lg.setLineWidth(2)
        for _, b in ipairs(self.bodies) do
            if b.force.x ~= 0 or b.force.y ~= 0 then
                lg.line(b.pos.x, b.pos.y,
                    b.pos.x + b.force.x * 0.01,
                    b.pos.y + b.force.y * 0.01
                )
            end
        end
    end

    
    if self.debugDrawCOM then
        lg.setColor(0, 1, 1, 1)
        for _, b in ipairs(self.bodies) do
            lg.circle("fill", b.pos.x, b.pos.y, 3)
        end
    end
end




function World2D:addBodyLegacy(config)
    local body = self:addBody(config)
    body._legacyId = config.id or ("body_" .. #self.bodies)
    return body._legacyId, body
end

function World2D:removeBodyLegacy(id)
    for _, b in ipairs(self.bodies) do
        if b._legacyId == id then
            self:removeBody(b)
            return
        end
    end
end

function World2D:getBodyLegacy(id)
    for _, b in ipairs(self.bodies) do
        if b._legacyId == id then
            return b
        end
    end
end


return World2D
