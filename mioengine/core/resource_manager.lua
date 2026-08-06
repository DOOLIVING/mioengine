local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new()
    local self = setmetatable({}, ResourceManager)
    self.images = {}
    self.fonts = {}
    self.sounds = {}
    self.models = {}
    self.canvases = {}
    self.refCount = {}
    return self
end

function ResourceManager:getImage(path)
    if self.images[path] then
        self.refCount[path] = (self.refCount[path] or 0) + 1
        return self.images[path]
    end
    local ok, img = pcall(love.graphics.newImage, path)
    if ok then
        img:setFilter("nearest", "nearest")
        self.images[path] = img
        self.refCount[path] = 1
        return img
    end
    print("[Resources] Cannot load image: " .. path)
    return nil
end

function ResourceManager:getFont(size)
    size = size or 12
    local key = "font_" .. size
    if self.fonts[key] then
        return self.fonts[key]
    end
    local font = love.graphics.newFont(size)
    font:setFilter("nearest", "nearest")
    self.fonts[key] = font
    return font
end

function ResourceManager:getSound(path, soundType)
    soundType = soundType or "stream"
    if self.sounds[path] then
        self.refCount[path] = (self.refCount[path] or 0) + 1
        return self.sounds[path]
    end
    local ok, source = pcall(love.audio.newSource, path, soundType)
    if ok then
        self.sounds[path] = source
        self.refCount[path] = 1
        return source
    end
    print("[Resources] Cannot load sound: " .. path)
    return nil
end

function ResourceManager:getModel(path)
    if self.models[path] then
        self.refCount[path] = (self.refCount[path] or 0) + 1
        return self.models[path]
    end
    local content = love.filesystem.read(path)
    if not content then
        print("[Resources] Cannot load model: " .. path)
        return nil
    end

    local vertices = {}
    local faces = {}
    local vCount = 0

    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line:sub(1, 2) == "v " then
            local x, y, z = line:match("^v%s+([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)$")
            if x then
                vCount = vCount + 1
                vertices[vCount] = { tonumber(x), tonumber(y), tonumber(z) }
            end
        elseif line:sub(1, 2) == "f " then
            local parts = {}
            for token in line:gmatch("%S+") do
                parts[#parts + 1] = token
            end
            local indices = {}
            local color = nil
            local textured = false
            local texFile = nil
            local i = 2
            while i <= #parts do
                local p = parts[i]
                if p == "textured" then
                    textured = true
                    i = i + 1
                elseif p == "color" then
                    color = { tonumber(parts[i+1]) or 1, tonumber(parts[i+2]) or 1, tonumber(parts[i+3]) or 1 }
                    i = i + 4
                else
                    local n = tonumber(p)
                    if n then
                        indices[#indices + 1] = n
                    end
                    i = i + 1
                end
            end
            if #indices >= 3 then
                faces[#faces + 1] = {
                    indices = indices,
                    color = color or {1, 1, 1},
                    is_textured = textured,
                    texture_file = texFile,
                }
            end
        end
    end

    local model = { vertices = vertices, faces = faces }
    self.models[path] = model
    self.refCount[path] = 1
    return model
end

function ResourceManager:getCanvas(width, height, filter)
    local key = "canvas_" .. width .. "x" .. height
    if self.canvases[key] then
        return self.canvases[key]
    end
    local canvas = love.graphics.newCanvas(width, height)
    if filter then
        canvas:setFilter(filter, filter)
    end
    self.canvases[key] = canvas
    return canvas
end

function ResourceManager:release(path)
    if not self.refCount[path] then return end
    self.refCount[path] = self.refCount[path] - 1
    if self.refCount[path] <= 0 then
        self.images[path] = nil
        self.sounds[path] = nil
        self.models[path] = nil
        self.refCount[path] = nil
    end
end

function ResourceManager:clear()
    self.images = {}
    self.fonts = {}
    self.sounds = {}
    self.models = {}
    self.canvases = {}
    self.refCount = {}
end

function ResourceManager:stats()
    local imgCount = 0
    for _ in pairs(self.images) do imgCount = imgCount + 1 end
    local sndCount = 0
    for _ in pairs(self.sounds) do sndCount = sndCount + 1 end
    local mdlCount = 0
    for _ in pairs(self.models) do mdlCount = mdlCount + 1 end
    local fntCount = 0
    for _ in pairs(self.fonts) do fntCount = fntCount + 1 end
    return {
        images = imgCount,
        fonts = fntCount,
        sounds = sndCount,
        models = mdlCount,
    }
end

return ResourceManager
