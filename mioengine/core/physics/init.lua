














local Physics = {}


Physics.Vec2     = require("mioengine.core.physics.vector_math").Vec2
Physics.Vec3     = require("mioengine.core.physics.vector_math").Vec3
Physics.Quat     = require("mioengine.core.physics.vector_math").Quat
Physics.RigidBody = require("mioengine.core.physics.rigid_body").RigidBody
Physics.BodyPool = require("mioengine.core.physics.rigid_body").BodyPool
Physics.Shapes   = require("mioengine.core.physics.collision_shapes")


Physics.World2D  = require("mioengine.core.physics.world_2d")
Physics.World3D  = require("mioengine.core.physics.world_3d")


Physics.Narrowphase2D = require("mioengine.core.physics.narrowphase_2d")
Physics.Narrowphase3D = require("mioengine.core.physics.narrowphase_3d")
Physics.Solver        = require("mioengine.core.physics.solver")
Physics.Broadphase2D  = require("mioengine.core.physics.broadphase").SHG2D
Physics.Broadphase3D  = require("mioengine.core.physics.broadphase").SHG3D
Physics.Contact       = require("mioengine.core.physics.contact")




function Physics.new2D(config)
    config = config or {}
    local world = Physics.World2D.new(config)
    world._gravity = world  

    
    world.gravity = { x = world.gravityX, y = world.gravityY }

    
    local origUpdate = world.update
    function world:update(dt)
        self.gravityX = self.gravity.x
        self.gravityY = self.gravity.y
        origUpdate(self, dt)
    end

    
    local origAddBody = world.addBody
    function world:addBody(config)
        local body = origAddBody(self, config)
        body._legacyId = config.id or ("body_" .. #self.bodies)
        body.id = body._legacyId
        return body._legacyId, body
    end

    
    function world:addBodyPlain(config)
        config = config or {}
        local body = {
            id = config.id or ("body_" .. #self.bodies + 1),
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

        
        local physBody = origAddBody(self, {
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
        body._legacyId = physBody._legacyId

        return body
    end

    
    function world:removeBody(id)
        for _, b in ipairs(self.bodies) do
            if b._legacyId == id or b.id == id then
                Physics.World2D.removeBody(self, b)
                return
            end
        end
    end

    function world:getBody(id)
        for _, b in ipairs(self.bodies) do
            if b._legacyId == id or b.id == id then
                return b
            end
        end
    end

    function world:applyForce(id, fx, fy)
        local b = self:getBody(id)
        if b then Physics.World2D.applyForce(self, b, fx, fy) end
    end

    function world:applyImpulse(id, ix, iy)
        local b = self:getBody(id)
        if b then Physics.World2D.applyImpulse(self, b, ix, iy) end
    end

    function world:setVelocity(id, vx, vy)
        local b = self:getBody(id)
        if b then Physics.World2D.setVelocity(self, b, vx, vy) end
    end

    function world:getVelocity(id)
        local b = self:getBody(id)
        if b then return Physics.World2D.getVelocity(self, b) end
        return 0, 0
    end

    function world:setPosition(id, x, y)
        local b = self:getBody(id)
        if b then Physics.World2D.setPosition(self, b, x, y) end
    end

    function world:getPosition(id)
        local b = self:getBody(id)
        if b then return Physics.World2D.getPosition(self, b) end
        return 0, 0
    end

    function world:isGrounded(id)
        local b = self:getBody(id)
        if b then return Physics.World2D.isGrounded(self, b) end
        return false
    end

    function world:clear()
        Physics.World2D.clear(self)
    end

    return world
end




function Physics.new3D(config)
    config = config or {}
    local world = Physics.World3D.new(config)

    world.gravity = { x = world.gravityX, y = world.gravityY, z = world.gravityZ }

    local origUpdate = world.update
    function world:update(dt)
        self.gravityX = self.gravity.x
        self.gravityY = self.gravity.y
        self.gravityZ = self.gravity.z
        origUpdate(self, dt)
    end

    local origAddBody = world.addBody
    function world:addBody(config)
        local body = origAddBody(self, config)
        body._legacyId = config.id or ("body3d_" .. #self.bodies)
        return body._legacyId, body
    end

    function world:removeBody(id)
        for _, b in ipairs(self.bodies) do
            if b._legacyId == id or b.id == id then
                Physics.World3D.removeBody(self, b)
                return
            end
        end
    end

    function world:getBody(id)
        for _, b in ipairs(self.bodies) do
            if b._legacyId == id or b.id == id then
                return b
            end
        end
    end

    function world:applyForce(id, fx, fy, fz)
        local b = self:getBody(id)
        if b then Physics.World3D.applyForce(self, b, fx, fy, fz) end
    end

    function world:applyImpulse(id, ix, iy, iz)
        local b = self:getBody(id)
        if b then Physics.World3D.applyImpulse(self, b, ix, iy, iz) end
    end

    function world:setVelocity(id, vx, vy, vz)
        local b = self:getBody(id)
        if b then Physics.World3D.setVelocity(self, b, vx, vy, vz) end
    end

    function world:getVelocity(id)
        local b = self:getBody(id)
        if b then return Physics.World3D.getVelocity(self, b) end
        return 0, 0, 0
    end

    function world:setPosition(id, x, y, z)
        local b = self:getBody(id)
        if b then Physics.World3D.setPosition(self, b, x, y, z) end
    end

    function world:getPosition(id)
        local b = self:getBody(id)
        if b then return Physics.World3D.getPosition(self, b) end
        return 0, 0, 0
    end

    function world:isGrounded(id)
        local b = self:getBody(id)
        if b then return Physics.World3D.isGrounded(self, b) end
        return false
    end

    function world:clear()
        Physics.World3D.clear(self)
    end

    return world
end


return Physics
