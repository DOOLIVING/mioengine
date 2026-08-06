local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

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
        vx = randomRange(emitter.minVx, emitter.maxVx),
        vy = randomRange(emitter.minVy, emitter.maxVy),
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

function ParticleSystem.new(config)
    local self = setmetatable({}, ParticleSystem)
    config = config or {}
    self.x = config.x or 0
    self.y = config.y or 0
    self.active = true
    self.maxParticles = config.maxParticles or 100
    self.particles = {}

    self.gravity = config.gravity or 0
    self.spreadX = config.spreadX or 0
    self.spreadY = config.spreadY or 0

    self.minVx = config.minVx or -50
    self.maxVx = config.maxVx or 50
    self.minVy = config.minVy or -100
    self.maxVy = config.maxVy or -50

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

    self.shape = config.shape or "circle"
    self.image = config.image

    return self
end

function ParticleSystem:setPosition(x, y)
    self.x = x
    self.y = y
end

function ParticleSystem:emit(count)
    count = count or 1
    for i = 1, count do
        if #self.particles < self.maxParticles then
            self.particles[#self.particles + 1] = newParticle(self)
        end
    end
end

function ParticleSystem:burst(count)
    self:emit(count or self.maxParticles)
end

function ParticleSystem:stop()
    self.active = false
end

function ParticleSystem:start()
    self.active = true
end

function ParticleSystem:clear()
    self.particles = {}
end

function ParticleSystem:isDone()
    return not self.active and #self.particles == 0
end

function ParticleSystem:update(dt)
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
            p.vy = p.vy + self.gravity * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.rotation = p.rotation + p.rotSpeed * dt
            local t = 1 - (p.life / p.maxLife)
            p.size = lerp(p.sizeStart, p.endSize, t)
            p.color = lerpColor(self.startColor, self.endColor, t)
        end
    end
end

function ParticleSystem:draw()
    if #self.particles == 0 then return end
    if self.image then
        for _, p in ipairs(self.particles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4])
            love.graphics.draw(self.image, p.x, p.y, p.rotation, p.size / (self.image:getWidth() or 1), p.size / (self.image:getHeight() or 1))
        end
    else
        for _, p in ipairs(self.particles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4])
            if self.shape == "circle" then
                love.graphics.circle("fill", p.x, p.y, math.max(0.5, p.size))
            else
                love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function ParticleSystem:getCount()
    return #self.particles
end

function ParticleSystem:configure(config)
    for k, v in pairs(config) do
        self[k] = v
    end
end

return ParticleSystem
