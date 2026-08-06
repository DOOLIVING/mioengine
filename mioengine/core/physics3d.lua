


local Physics = require("mioengine.core.physics.init")

local Physics3D = {}
Physics3D.__index = Physics3D

function Physics3D.new(config)
    config = config or {}
    local self = setmetatable({}, Physics3D)

    self._world = Physics.World3D.new({
        gravityX    = config.gravityX or 0,
        gravityY    = config.gravityY or 0,
        gravityZ    = config.gravityZ or 9.8,
        cellSize    = config.cellSize or 64,
        fixedDt     = config.fixedDt or (1 / 60),
        baumgarte   = config.baumgarte or 0.2,
        slop        = config.slop or 0.005,
        velIterations = config.velIterations or 8,
        posIterations = config.posIterations or 3,
        onCollide   = config.onCollide,
    })

    self.gravity = self._world.gravity
    self.groundY = config.groundY or nil
    self.onCollide = config.onCollide
    self.bodies = {}

    return self
end

function Physics3D:addBody(config)
    config = config or {}
    local body = {
        id = config.id or ("body3d_" .. #self.bodies + 1),
        x = config.x or 0,
        y = config.y or 0,
        z = config.z or 0,
        vx = config.vx or 0,
        vy = config.vy or 0,
        vz = config.vz or 0,
        ax = config.ax or 0,
        ay = config.ay or 0,
        az = config.az or 0,
        mass = config.mass or 1,
        invMass = 1 / (config.mass or 1),
        restitution = config.bounce or 0.3,
        friction = config.friction or 0.5,
        static = config.static or false,
        shape = config.shape or "sphere",
        size = config.size or 1,
        halfW = (config.w or 1) / 2,
        halfH = (config.h or 1) / 2,
        halfD = (config.d or 1) / 2,
        radius = config.radius or 0.5,
        tag = config.tag or "",
        userData = config.userData or nil,
        grounded = false,
        collisions = {},
        linkedObject = config.linkedObject or nil,
    }
    if body.static then body.invMass = 0 end

    local physBody = self._world:addBody({
        x = body.x,
        y = body.y,
        z = body.z,
        vx = body.vx,
        vy = body.vy,
        vz = body.vz,
        mass = body.mass,
        static = body.static,
        bounce = body.restitution,
        friction = body.friction,
        shape = body.shape,
        w = config.w,
        h = config.h,
        d = config.d,
        radius = body.radius,
        tag = body.tag,
        userData = body.userData,
        linkedObject = body.linkedObject,
    })
    body._physBody = physBody
    self.bodies[body.id] = body

    return body
end

function Physics3D:removeBody(id)
    local body = self.bodies[id]
    if body and body._physBody then
        self._world:removeBody(body._physBody)
    end
    self.bodies[id] = nil
end

function Physics3D:getBody(id)
    return self.bodies[id]
end

function Physics3D:applyForce(id, fx, fy, fz)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:applyForce(b._physBody, fx, fy, fz)
end

function Physics3D:applyImpulse(id, ix, iy, iz)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:applyImpulse(b._physBody, ix, iy, iz)
end

function Physics3D:setVelocity(id, vx, vy, vz)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:setVelocity(b._physBody, vx, vy, vz)
end

function Physics3D:getVelocity(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return 0, 0, 0 end
    return self._world:getVelocity(b._physBody)
end

function Physics3D:setPosition(id, x, y, z)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:setPosition(b._physBody, x, y, z)
end

function Physics3D:getPosition(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return 0, 0, 0 end
    return self._world:getPosition(b._physBody)
end

function Physics3D:isGrounded(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return false end
    return self._world:isGrounded(b._physBody)
end

function Physics3D:update(dt)
    self._world.gravityX = self.gravity.x
    self._world.gravityY = self.gravity.y
    self._world.gravityZ = self.gravity.z

    self._world:update(dt)

    for id, b in pairs(self.bodies) do
        if b._physBody then
            local p = b._physBody
            b.x = p.pos3.x
            b.y = p.pos3.y
            b.z = p.pos3.z
            b.vx = p.velocity3.x
            b.vy = p.velocity3.y
            b.vz = p.velocity3.z
            b.grounded = p.grounded3
            b.collisions = p.collisions or {}
            if p.linkedObject then
                p.linkedObject.x = b.x
                p.linkedObject.y = b.y
                p.linkedObject.z = b.z
                p.linkedObject.vx = b.vx
                p.linkedObject.vy = b.vy
                p.linkedObject.vz = b.vz
                p.linkedObject.grounded = b.grounded
            end
        end
    end

    
    if self.groundY ~= nil then
        for _, b in pairs(self.bodies) do
            if b._physBody and not b.static then
                local halfH = b.h / 2
                local bottom = b.y - halfH
                if bottom < self.groundY then
                    b.y = self.groundY + halfH
                    b.vy = -b.vy * b.restitution
                    if math.abs(b.vy) < 0.5 then
                        b.vy = 0
                        b.grounded = true
                        b._physBody.grounded3 = true
                        b._physBody.velocity3.y = 0
                    end
                end
            end
        end
    end
end

function Physics3D:queryPoint(x, y, z)
    return self._world:queryPoint(x, y, z)
end

function Physics3D:clear()
    self.bodies = {}
    self._world:clear()
end

return Physics3D
