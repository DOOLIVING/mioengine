local HotReload = {}
HotReload.__index = HotReload

function HotReload.new()
    local self = setmetatable({}, HotReload)
    self.watchedFiles = {}
    self.callbacks = {}
    self.pollInterval = 0.5
    self.timer = 0
    self.enabled = true
    return self
end

function HotReload:watch(path, callback)
    local info = love.filesystem.getInfo(path)
    if info then
        self.watchedFiles[path] = {
            lastModified = info.modtime or os.time(),
            callback = callback,
        }
    else
        print("[HotReload] Cannot watch (not found): " .. path)
    end
end

function HotReload:unwatch(path)
    self.watchedFiles[path] = nil
end

function HotReload:isWatching(path)
    return self.watchedFiles[path] ~= nil
end

function HotReload:update(dt)
    if not self.enabled then return end
    self.timer = self.timer + dt
    if self.timer < self.pollInterval then return end
    self.timer = 0

    for path, info in pairs(self.watchedFiles) do
        local fileInfo = love.filesystem.getInfo(path)
        if fileInfo then
            local newMod = fileInfo.modtime or 0
            if newMod > info.lastModified then
                info.lastModified = newMod
                print("[HotReload] Detected change: " .. path)
                if info.callback then
                    local ok, err = pcall(info.callback, path)
                    if not ok then
                        print("[HotReload] Callback error: " .. tostring(err))
                    end
                end
            end
        end
    end
end

function HotReload:setEnabled(v)
    self.enabled = v
end

function HotReload:clear()
    self.watchedFiles = {}
end

return HotReload
