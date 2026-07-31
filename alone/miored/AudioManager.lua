-- приве я калвизкс сидел за компом 4 часа без перерывов чтобы сделать эту залупу да
local AudioManager = {}
AudioManager.__index = AudioManager

AudioManager.sources = {}
AudioManager.maxSources = 32

AudioManager.listener = {
    x = 0, y = 0,
    angle = 0
}

AudioManager.masterVolume = 1.0
AudioManager.maxDistance = 50.0
AudioManager.referenceDistance = 1.0

function AudioManager:createSource(params)
    local source = {
        id = params.id or "source_" .. #self.sources + 1,
        path = params.path,
        
        x = params.x or 0,
        y = params.y or 0,
        
        volume = params.volume or 1.0,
        pitch = params.pitch or 1.0,
        loop = params.loop or false,
        priority = params.priority or 0,
        
        maxDistance = params.maxDistance or 50.0,
        referenceDistance = params.referenceDistance or 1.0,
        
        is3D = params.is3D ~= false,
        isPlaying = false,
        isPaused = false,
        
        sound = nil,
        
        -- Fade
        fadeTimer = 0,
        fadeDuration = 0,
        fadeStartVol = 0,
        fadeEndVol = 0,
        fadeCallback = nil,
        
        userData = params.userData or {}
    }
    
    local soundType = source.loop and "stream" or "static"
    source.sound = love.audio.newSource(params.path, soundType)
    source.sound:setLooping(source.loop)
    
    table.insert(self.sources, source)
    return source
end

function AudioManager:play(source)
    if not source then return end
    
    if #self.sources > self.maxSources then
        self:stealLowestPriority()
    end
    
    source.isPlaying = true
    source.isPaused = false
    source.sound:play()
    
    return source
end

function AudioManager:playAt(path, x, y, volume)
    local source = self:createSource({
        path = path,
        x = x or 0,
        y = y or 0,
        volume = volume or 1.0,
        is3D = true,
        loop = false
    })
    return self:play(source)
end

function AudioManager:play2D(path, volume, loop)
    local source = self:createSource({
        path = path,
        volume = volume or 1.0,
        loop = loop or false,
        is3D = false
    })
    return self:play(source)
end

function AudioManager:stop(source, fadeTime)
    if not source then return end
    
    if fadeTime and fadeTime > 0 then
        self:fadeOut(source, fadeTime, function()
            source.sound:stop()
            source.isPlaying = false
        end)
    else
        source.sound:stop()
        source.isPlaying = false
    end
end

function AudioManager:pause(source)
    if source and source.isPlaying then
        source.sound:pause()
        source.isPaused = true
        source.isPlaying = false
    end
end

function AudioManager:resume(source)
    if source and source.isPaused then
        source.sound:play()
        source.isPaused = false
        source.isPlaying = true
    end
end

function AudioManager:getDistance(source)
    local dx = source.x - self.listener.x
    local dy = source.y - self.listener.y
    return math.sqrt(dx*dx + dy*dy)
end

function AudioManager:calculateAttenuation(source)
    if not source.is3D then 
        return 1.0 
    end
    
    local dist = self:getDistance(source)
    
    if dist <= source.referenceDistance then
        return 1.0
    end
    
    if dist >= source.maxDistance then
        return 0.0
    end
    
    local t = (dist - source.referenceDistance) / (source.maxDistance - source.referenceDistance)
    return 1.0 - t
end

function AudioManager:calculatePan(source)
    if not source.is3D then 
        return 0
    end
    
    local dx = source.x - self.listener.x
    local dy = source.y - self.listener.y
    
    local angle = math.atan2(dy, dx)
    
    local relativeAngle = angle - self.listener.angle
    
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    return math.sin(relativeAngle)
end

function AudioManager:fadeIn(source, duration, targetVolume, callback)
    source.fadeTimer = 0
    source.fadeDuration = duration
    source.fadeStartVol = 0
    source.fadeEndVol = targetVolume or source.volume
    source.volume = 0
    source.fadeCallback = callback
    
    if not source.isPlaying then
        self:play(source)
    end
end

function AudioManager:fadeOut(source, duration, callback)
    source.fadeTimer = 0
    source.fadeDuration = duration
    source.fadeStartVol = source.volume
    source.fadeEndVol = 0
    source.fadeCallback = callback
end

function AudioManager:stealLowestPriority()
    local lowest = nil
    local lowestPriority = 999
    
    for _, src in ipairs(self.sources) do
        if src.isPlaying and src.priority < lowestPriority then
            lowestPriority = src.priority
            lowest = src
        end
    end
    
    if lowest then
        self:stop(lowest)
    end
end

function AudioManager:update(dt)
    self.listener.x, self.listener.y = camera.x, camera.y
    
    for _, source in ipairs(self.sources) do
        if source.fadeDuration > 0 then
            source.fadeTimer = source.fadeTimer + dt
            local t = math.min(source.fadeTimer / source.fadeDuration, 1.0)
            
            local eased = t * t * (3 - 2 * t)
            source.volume = source.fadeStartVol + (source.fadeEndVol - source.fadeStartVol) * eased
            
            if t >= 1.0 then
                source.fadeDuration = 0
                if source.fadeCallback then
                    source.fadeCallback(source)
                    source.fadeCallback = nil
                end
            end
        end
        
        if source.isPlaying and source.is3D then
            local attenuation = self:calculateAttenuation(source)
            local pan = self:calculatePan(source)
            
            local finalVolume = source.volume * self.masterVolume * attenuation
            
            source.sound:setVolume(finalVolume)
            source.sound:setPan(pan)
            
        elseif source.isPlaying then
            source.sound:setVolume(source.volume * self.masterVolume)
        end
    end
end

function AudioManager:setListenerPosition(x, y, angle)
    self.listener.x = x or self.listener.x
    self.listener.y = y or self.listener.y
    self.listener.angle = angle or self.listener.angle
end

function AudioManager:stopAll()
    for _, source in ipairs(self.sources) do
        source.sound:stop()
        source.isPlaying = false
    end
end

function AudioManager:getSourcesInRadius(x, y, radius)
    local result = {}
    for _, source in ipairs(self.sources) do
        local dx = source.x - x
        local dy = source.y - y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < radius then
            table.insert(result, source)
        end
    end
    return result
end

return AudioManager