local Sound = {}

Sound.sources = {}
Sound.masterVolume = 1
Sound.muted = false

function Sound.load(name, path, resources)
    if not love.audio then return end
    if resources then
        local source = resources:getSound(path)
        if source then
            Sound.sources[name] = source
        end
    else
        local ok, source = pcall(love.audio.newSource, path, "stream")
        if ok then
            Sound.sources[name] = source
        end
    end
end

function Sound.play(name, loop)
    local src = Sound.sources[name]
    if not src then return end
    src:setLooping(loop or false)
    src:setVolume(Sound.muted and 0 or Sound.masterVolume)
    src:play()
end

function Sound.stop(name)
    local src = Sound.sources[name]
    if src then src:stop() end
end

function Sound.stopAll()
    for _, src in pairs(Sound.sources) do
        src:stop()
    end
end

function Sound.setMasterVolume(vol)
    Sound.masterVolume = vol
    for _, src in pairs(Sound.sources) do
        src:setVolume(Sound.muted and 0 or vol)
    end
end

function Sound.toggleMute()
    Sound.muted = not Sound.muted
    for _, src in pairs(Sound.sources) do
        src:setVolume(Sound.muted and 0 or Sound.masterVolume)
    end
end

return Sound
