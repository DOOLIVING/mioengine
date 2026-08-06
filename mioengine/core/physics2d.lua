


local Physics = require("mioengine.core.physics.init")

local Physics2D = {}
Physics2D.__index = Physics2D

function Physics2D.new(config)
    config = config or {}
    local self = setmetatable({}, Physics2D)

    
    self._world = Physics.World2D.new({
        gravityX    = config.gravityX or 0,
        gravityY    = config.gravityY or 980,
        cellSize    = config.cellSize or 64,
        fixedDt     = config.fixedDt or (1 / 60),
        baumgarte   = config.baumgarte or 0.2,
        slop        = config.slop or 0.005,
        velIterations = config.velIterations or 8,
        posIterations = config.posIterations or 3,
        onCollide   = config.onCollide,
    })

    
    self.gravity = self._world.gravity
    self.ground  = config.ground or nil
    self.onCollide = config.onCollide

    
    self.bodies = {}

    return self
end

function Physics2D:addBody(config)
    config = config or {}
    local body = {
        id = config.id or ("body_" .. (config._bodyCount or 0) + 1),
        x = config.x or 0,
        y = config.y or 0,
        vx = config.vx or 0,
        vy = config.vy or 0,
        ax = config.ax or 0,
        ay = config.ay or 0,
        mass = config.mass or 1,
        invMass = 1 / (config.mass or 1),
        restitution = config.bounce or 0.3,
        friction = config.friction or 0.5,
        static = config.static or false,
        shape = config.shape or "rect",
        w = config.w or 32,
        h = config.h or 32,
        radius = config.radius or 16,
        tag = config.tag or "",
        userData = config.userData or nil,
        grounded = false,
        collisions = {},
    }
    if body.static then body.invMass = 0 end

    
    local physBody = self._world:addBody({
        x = body.x,
        y = body.y,
        vx = body.vx,
        vy = body.vy,
        mass = body.mass,
        static = body.static,
        bounce = body.restitution,
        friction = body.friction,
        shape = body.shape,
        w = body.w,
        h = body.h,
        radius = body.radius,
        tag = body.tag,
        userData = body.userData,
    })
    body._physBody = physBody
    self.bodies[body.id] = body

    return body
end

function Physics2D:removeBody(id)
    local body = self.bodies[id]
    if body and body._physBody then
        self._world:removeBody(body._physBody)
    end
    self.bodies[id] = nil
end

function Physics2D:getBody(id)
    return self.bodies[id]
end

function Physics2D:applyForce(id, fx, fy)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:applyForce(b._physBody, fx, fy)
end

function Physics2D:applyImpulse(id, ix, iy)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:applyImpulse(b._physBody, ix, iy)
end

function Physics2D:setVelocity(id, vx, vy)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:setVelocity(b._physBody, vx, vy)
end

function Physics2D:getVelocity(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return 0, 0 end
    return self._world:getVelocity(b._physBody)
end

function Physics2D:setPosition(id, x, y)
    local b = self.bodies[id]
    if not b or not b._physBody then return end
    self._world:setPosition(b._physBody, x, y)
end

function Physics2D:getPosition(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return 0, 0 end
    return self._world:getPosition(b._physBody)
end

function Physics2D:isGrounded(id)
    local b = self.bodies[id]
    if not b or not b._physBody then return false end
    return self._world:isGrounded(b._physBody)
end

function Physics2D:update(dt)
    
    self._world.gravityX = self.gravity.x
    self._world.gravityY = self.gravity.y

    
    self._world:update(dt)

    
    for id, b in pairs(self.bodies) do
        if b._physBody then
            local w = self._world
            local p = b._physBody
            b.x = p.pos.x
            b.y = p.pos.y
            b.vx = p.velocity.x
            b.vy = p.velocity.y
            b.grounded = p.grounded
            b.collisions = p.collisions or {}
        end
    end

    
    if self.ground then
        for _, b in pairs(self.bodies) do
            if b._physBody and not b.static then
                local bottom = b.y + b.h / 2
                if bottom > self.ground then
                    b.y = self.ground - b.h / 2
                    b.vy = -b.vy * b.restitution
                    if math.abs(b.vy) < 20 then
                        b.vy = 0
                        b.grounded = true
                        b._physBody.grounded = true
                        b._physBody.velocity.y = 0
                    end
                end
            end
        end
    end
end

function Physics2D:queryPoint(x, y)
    return self._world:queryPoint(x, y)
end

function Physics2D:clear()
    self.bodies = {}
    self._world:clear()
end

return Physics2D
