



local Vec2 = require("mioengine.core.physics.vector_math").Vec2
local Vec3 = require("mioengine.core.physics.vector_math").Vec3
local Quat = require("mioengine.core.physics.vector_math").Quat

local insert, remove = table.insert, table.remove




local SHAPE_CIRCLE   = 1
local SHAPE_AABB     = 2
local SHAPE_OBB      = 3   
local SHAPE_SPHERE   = 4
local SHAPE_AABB3D   = 5
local SHAPE_OBB3D    = 6
local SHAPE_HULL     = 7   




local BODY_STATIC    = 0
local BODY_KINEMATIC = 1
local BODY_DYNAMIC   = 2




local RigidBody = {}
RigidBody.__index = RigidBody

local _nextId = 0

function RigidBody.new()
    _nextId = _nextId + 1
    local self = setmetatable({}, RigidBody)
    self.id = _nextId

    
    self.pos    = Vec2.new(0, 0)     
    self.pos3   = Vec3.new(0, 0, 0)  
    self.angle  = 0                  
    self.quat   = Quat.new(1,0,0,0)  

    
    self.velocity      = Vec2.new(0, 0)
    self.velocity3     = Vec3.new(0, 0, 0)
    self.force         = Vec2.new(0, 0)
    self.force3        = Vec3.new(0, 0, 0)
    self.linearDamping = 0
    self.invMass       = 1

    
    self.angularVelocity  = 0       
    self.angularVelocity3 = Vec3.new(0, 0, 0)
    self.torque           = 0       
    self.torque3          = Vec3.new(0, 0, 0)
    self.angularDamping   = 0
    self.invInertia       = 1       
    self.invInertia3      = Vec3.new(1, 1, 1)  

    
    self.restitution = 0.3
    self.friction    = 0.5
    self.mass        = 1

    
    self.shapeType = SHAPE_AABB
    self.shapeData = nil

    
    self.bodyType      = BODY_DYNAMIC
    self.isSleeping    = false
    self.sleepTime     = 0
    self.grounded      = false
    self.grounded3     = false
    self.collisions    = {}
    self.tags          = {}
    self.userData      = nil

    
    self.aabbMinX = 0; self.aabbMinY = 0
    self.aabbMaxX = 0; self.aabbMaxY = 0
    self.aabbMinX3 = 0; self.aabbMinY3 = 0; self.aabbMinZ3 = 0
    self.aabbMaxX3 = 0; self.aabbMaxY3 = 0; self.aabbMaxZ3 = 0

    
    self.linkedObject = nil

    
    self.active = false

    return self
end

function RigidBody:reset()
    self.pos:set(0, 0)
    self.pos3:set(0, 0, 0)
    self.angle = 0
    self.quat:identity()
    self.velocity:set(0, 0)
    self.velocity3:set(0, 0, 0)
    self.force:set(0, 0)
    self.force3:set(0, 0, 0)
    self.angularVelocity = 0
    self.angularVelocity3:set(0, 0, 0)
    self.torque = 0
    self.torque3:set(0, 0, 0)
    self.linearDamping = 0
    self.angularDamping = 0
    self.mass = 1
    self.invMass = 1
    self.invInertia = 1
    self.invInertia3:set(1, 1, 1)
    self.restitution = 0.3
    self.friction = 0.5
    self.shapeType = SHAPE_AABB
    self.shapeData = nil
    self.bodyType = BODY_DYNAMIC
    self.isSleeping = false
    self.sleepTime = 0
    self.grounded = false
    self.grounded3 = false
    self.collisions = {}
    self.tags = {}
    self.userData = nil
    self.linkedObject = nil
    self.active = false
    return self
end

function RigidBody:setMass(m)
    self.mass = m
    self.invMass = m > 0 and (1 / m) or 0
end

function RigidBody:setStatic(v)
    if v then
        self.bodyType = BODY_STATIC
        self.invMass = 0
        self.invInertia = 0
    else
        self.bodyType = BODY_DYNAMIC
        self.invMass = 1 / self.mass
    end
end

function RigidBody:applyForce(fx, fy)
    self.force.x = self.force.x + fx
    self.force.y = self.force.y + fy
end

function RigidBody:applyForce3(fx, fy, fz)
    self.force3.x = self.force3.x + fx
    self.force3.y = self.force3.y + fy
    self.force3.z = self.force3.z + fz
end

function RigidBody:applyImpulse(ix, iy)
    self.velocity.x = self.velocity.x + ix * self.invMass
    self.velocity.y = self.velocity.y + iy * self.invMass
end

function RigidBody:applyImpulse3(ix, iy, iz)
    self.velocity3.x = self.velocity3.x + ix * self.invMass
    self.velocity3.y = self.velocity3.y + iy * self.invMass
    self.velocity3.z = self.velocity3.z + iz * self.invMass
end

function RigidBody:applyAngularImpulse(impulse)
    self.angularVelocity = self.angularVelocity + impulse * self.invInertia
end

function RigidBody:applyAngularImpulse3(ix, iy, iz)
    self.angularVelocity3.x = self.angularVelocity3.x + ix * self.invInertia3.x
    self.angularVelocity3.y = self.angularVelocity3.y + iy * self.invInertia3.y
    self.angularVelocity3.z = self.angularVelocity3.z + iz * self.invInertia3.z
end

function RigidBody:applyTorque(t)
    self.torque = self.torque + t
end

function RigidBody:applyTorque3(tx, ty, tz)
    self.torque3.x = self.torque3.x + tx
    self.torque3.y = self.torque3.y + ty
    self.torque3.z = self.torque3.z + tz
end

function RigidBody:setInertia(invI)
    self.invInertia = invI
end

function RigidBody:setInertiaBox3(halfW, halfH, halfD)
    local m = self.mass
    local ix = (m / 12) * (4 * halfH * halfH + 4 * halfD * halfD)
    local iy = (m / 12) * (4 * halfW * halfW + 4 * halfD * halfD)
    local iz = (m / 12) * (4 * halfW * halfW + 4 * halfH * halfH)
    self.invInertia3:set(1 / ix, 1 / iy, 1 / iz)
end

function RigidBody:setInertiaSphere3(radius)
    local m = self.mass
    local i = (2 / 5) * m * radius * radius
    self.invInertia3:set(1 / i, 1 / i, 1 / i)
end

function RigidBody:hasTag(t) return self.tags[t] == true end
function RigidBody:addTag(t)  self.tags[t] = true end
function RigidBody:removeTag(t) self.tags[t] = nil end




local BodyPool = {}
BodyPool.__index = BodyPool

function BodyPool.new(initialSize)
    local self = setmetatable({}, BodyPool)
    self.free = {}
    self.active = {}
    initialSize = initialSize or 64
    for _ = 1, initialSize do
        local b = RigidBody.new()
        b.active = false
        insert(self.free, b)
    end
    return self
end

function BodyPool:acquire()
    local b
    local n = #self.free
    if n > 0 then
        b = self.free[n]
        self.free[n] = nil
    else
        b = RigidBody.new()
    end
    b.active = true
    b:reset()
    insert(self.active, b)
    return b
end

function BodyPool:release(body)
    body.active = false
    body:reset()
    for i = #self.active, 1, -1 do
        if self.active[i] == body then
            remove(self.active, i)
            break
        end
    end
    insert(self.free, body)
end

function BodyPool:releaseAll()
    for i = #self.active, 1, -1 do
        local b = self.active[i]
        b.active = false
        b:reset()
        insert(self.free, b)
        self.active[i] = nil
    end
end

function BodyPool:getActive()
    return self.active
end

function BodyPool:count()
    return #self.active
end


return {
    RigidBody = RigidBody,
    BodyPool  = BodyPool,
    SHAPE_CIRCLE  = SHAPE_CIRCLE,
    SHAPE_AABB    = SHAPE_AABB,
    SHAPE_OBB     = SHAPE_OBB,
    SHAPE_SPHERE  = SHAPE_SPHERE,
    SHAPE_AABB3D  = SHAPE_AABB3D,
    SHAPE_OBB3D   = SHAPE_OBB3D,
    SHAPE_HULL    = SHAPE_HULL,
    BODY_STATIC   = BODY_STATIC,
    BODY_KINEMATIC= BODY_KINEMATIC,
    BODY_DYNAMIC  = BODY_DYNAMIC,
}
