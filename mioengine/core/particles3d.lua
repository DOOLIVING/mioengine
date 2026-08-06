local ParticleSystem3D = {}
ParticleSystem3D.__index = ParticleSystem3D

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return {
        lerp(c1[1], c2[1], t),
        lerp(c1[2], c2[2], t),
        lerp(c1[3], c2[3], t),
        lerp(c1[4] or 1, c2[4] or 1, t),
    }
end

local function randomRange(min, max)
    if min == max then return min end
    return min + math.random() * (max - min)
end

local function newParticle(emitter)
    local p = {
        x = randomRange(emitter.x - emitter.spreadX / 2, emitter.x + emitter.spreadX / 2),
        y = randomRange(emitter.y - emitter.spreadY / 2, emitter.y + emitter.spreadY / 2),
        z = randomRange(emitter.z - emitter.spreadZ / 2, emitter.z + emitter.spreadZ / 2),
        vx = randomRange(emitter.minVx, emitter.maxVx),
        vy = randomRange(emitter.minVy, emitter.maxVy),
        vz = randomRange(emitter.minVz, emitter.maxVz),
        life = randomRange(emitter.minLife, emitter.maxLife),
        maxLife = 0,
        size = randomRange(emitter.minSize, emitter.maxSize),
        endSize = emitter.endSize,
        rotation = randomRange(emitter.minRotation, emitter.maxRotation),
        rotSpeed = randomRange(emitter.minRotSpeed, emitter.maxRotSpeed),
        color = { emitter.startColor[1], emitter.startColor[2], emitter.startColor[3], emitter.startColor[4] or 1 },
    }
    p.maxLife = p.life
    p.sizeStart = p.size
    return p
end

function ParticleSystem3D.new(config)
    local self = setmetatable({}, ParticleSystem3D)
    config = config or {}
    self.x = config.x or 0
    self.y = config.y or 0
    self.z = config.z or 0
    self.active = true
    self.maxParticles = config.maxParticles or 100
    self.particles = {}

    self.gravity = config.gravity or { x = 0, y = 0, z = 0 }
    if type(self.gravity) == "number" then
        self.gravity = { x = 0, y = self.gravity, z = 0 }
    end
    self.spreadX = config.spreadX or 0
    self.spreadY = config.spreadY or 0
    self.spreadZ = config.spreadZ or 0

    self.minVx = config.minVx or -50
    self.maxVx = config.maxVx or 50
    self.minVy = config.minVy or -100
    self.maxVy = config.maxVy or -50
    self.minVz = config.minVz or -50
    self.maxVz = config.maxVz or 50

    self.minLife = config.minLife or 0.5
    self.maxLife = config.maxLife or 1.5

    self.minSize = config.minSize or 2
    self.maxSize = config.maxSize or 8
    self.endSize = config.endSize or 0

    self.minRotation = config.minRotation or 0
    self.maxRotation = config.maxRotation or 0
    self.minRotSpeed = config.minRotSpeed or 0
    self.maxRotSpeed = config.maxRotSpeed or 0

    self.startColor = config.startColor or {1, 0.8, 0.2, 1}
    self.endColor = config.endColor or {1, 0.2, 0.1, 0}

    self.emitRate = config.emitRate or 20
    self.emitAccum = 0
    self.burstMode = config.burstMode or false

    self.shape = config.shape or "sphere"
    self.image = config.image
    return self
end

function ParticleSystem3D:setPosition(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
end

function ParticleSystem3D:emit(count)
    count = count or 1
    for i = 1, count do
        if #self.particles < self.maxParticles then
            self.particles[#self.particles + 1] = newParticle(self)
        end
    end
end

function ParticleSystem3D:burst(count)
    self:emit(count or self.maxParticles)
end

function ParticleSystem3D:stop()
    self.active = false
end

function ParticleSystem3D:start()
    self.active = true
end

function ParticleSystem3D:clear()
    self.particles = {}
end

function ParticleSystem3D:isDone()
    return not self.active and #self.particles == 0
end

function ParticleSystem3D:configure(config)
    for k, v in pairs(config) do
        self[k] = v
    end
end

function ParticleSystem3D:update(dt)
    if self.active and not self.burstMode then
        self.emitAccum = self.emitAccum + self.emitRate * dt
        while self.emitAccum >= 1 and #self.particles < self.maxParticles do
            self.particles[#self.particles + 1] = newParticle(self)
            self.emitAccum = self.emitAccum - 1
        end
    end

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        else
            p.vx = p.vx + (self.gravity.x or 0) * dt
            p.vy = p.vy - (self.gravity.y or 0) * dt
            p.vz = p.vz + (self.gravity.z or 0) * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.z = p.z + p.vz * dt
            p.rotation = p.rotation + p.rotSpeed * dt
            local t = 1 - (p.life / p.maxLife)
            p.size = lerp(p.sizeStart, p.endSize, t)
            p.color = lerpColor(self.startColor, self.endColor, t)
        end
    end
end

function ParticleSystem3D:getSortedList()
    local list = {}
    for _, p in ipairs(self.particles) do
        list[#list + 1] = {
            x = p.x, y = p.y, z = p.z,
            size = p.size, color = p.color,
            rotation = p.rotation,
        }
    end
    return list
end

function ParticleSystem3D:getCount()
    return #self.particles
end

return ParticleSystem3D
