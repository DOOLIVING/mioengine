local Animation = {}
Animation.__index = Animation

function Animation.new(config)
    local self = setmetatable({}, Animation)
    self.frames = config.frames or {}
    self.frameWidth = config.frameWidth or 32
    self.frameHeight = config.frameHeight or 32
    self.fps = config.fps or 8
    self.loop = config.loop ~= false
    self.playing = true
    self.currentTime = 0
    self.currentFrame = 1
    self.direction = config.direction or 1
    self.onComplete = config.onComplete
    self.tag = config.tag or ""
    return self
end

function Animation:update(dt)
    if not self.playing or #self.frames == 0 then return end
    self.currentTime = self.currentTime + dt
    local frameDuration = 1 / self.fps
    if self.currentTime >= frameDuration then
        self.currentTime = self.currentTime - frameDuration
        self.currentFrame = self.currentFrame + self.direction
        if self.currentFrame > #self.frames then
            if self.loop then
                self.currentFrame = 1
            else
                self.currentFrame = #self.frames
                self.playing = false
                if self.onComplete then self.onComplete() end
            end
        elseif self.currentFrame < 1 then
            if self.loop then
                self.currentFrame = #self.frames
            else
                self.currentFrame = 1
                self.playing = false
                if self.onComplete then self.onComplete() end
            end
        end
    end
end

function Animation:play(loop)
    self.playing = true
    self.currentFrame = 1
    self.currentTime = 0
    if loop ~= nil then self.loop = loop end
end

function Animation:stop()
    self.playing = false
end

function Animation:pause()
    self.playing = false
end

function Animation:resume()
    self.playing = true
end

function Animation:setFrame(frame)
    self.currentFrame = math.max(1, math.min(#self.frames, frame))
end

function Animation:getQuad()
    if #self.frames == 0 then return nil end
    local frameIndex = self.frames[self.currentFrame]
    if not frameIndex then return nil end
    local cols = 0
    local frameW = self.frameWidth
    local frameH = self.frameHeight
    return {
        x = (frameIndex - 1) * frameW,
        y = 0,
        w = frameW,
        h = frameH,
    }
end

function Animation:isDone()
    return not self.playing and not self.loop
end

function Animation:setSpeed(fps)
    self.fps = math.max(1, fps)
end

function Animation:reverse()
    self.direction = self.direction * -1
end


local AnimatedSprite = {}
AnimatedSprite.__index = AnimatedSprite

function AnimatedSprite.new(image, config)
    local self = setmetatable({}, AnimatedSprite)
    self.image = image
    self.x = config.x or 0
    self.y = config.y or 0
    self.scaleX = config.scaleX or 1
    self.scaleY = config.scaleY or 1
    self.rotation = config.rotation or 0
    self.r = config.r or 1
    self.g = config.g or 1
    self.b = config.b or 1
    self.a = config.a or 1
    self.flipX = false
    self.flipY = false
    self.animations = {}
    self.currentAnim = nil
    return self
end

function AnimatedSprite:addAnimation(name, config)
    local anim = Animation.new(config)
    self.animations[name] = anim
    if not self.currentAnim then
        self.currentAnim = name
    end
    return anim
end

function AnimatedSprite:play(name, loop)
    if name then
        self.currentAnim = name
        local anim = self.animations[name]
        if anim then anim:play(loop) end
    else
        local anim = self.animations[self.currentAnim]
        if anim then anim:play(loop) end
    end
end

function AnimatedSprite:stop()
    local anim = self.animations[self.currentAnim]
    if anim then anim:stop() end
end

function AnimatedSprite:pause()
    local anim = self.animations[self.currentAnim]
    if anim then anim:pause() end
end

function AnimatedSprite:resume()
    local anim = self.animations[self.currentAnim]
    if anim then anim:resume() end
end

function AnimatedSprite:setAnimation(name)
    self.currentAnim = name
end

function AnimatedSprite:update(dt)
    local anim = self.animations[self.currentAnim]
    if anim then anim:update(dt) end
end

function AnimatedSprite:draw()
    if not self.image then return end
    local anim = self.animations[self.currentAnim]
    if not anim then return end
    local quad = anim:getQuad()
    if not quad then return end
    local fw = quad.w * self.scaleX
    local fh = quad.h * self.scaleY
    local sx = self.scaleX
    local sy = self.scaleY
    if self.flipX then sx = -sx end
    if self.flipY then sy = -sy end
    love.graphics.setColor(self.r, self.g, self.b, self.a)
    love.graphics.draw(
        self.image, quad,
        self.x, self.y, self.rotation,
        sx, sy,
        quad.w / 2, quad.h / 2
    )
    love.graphics.setColor(1, 1, 1, 1)
end

function AnimatedSprite:isDone()
    local anim = self.animations[self.currentAnim]
    if anim then return anim:isDone() end
    return true
end

return { Animation = Animation, AnimatedSprite = AnimatedSprite }
