local Objects = {}

function Objects.loadModel(path, resources)
    if resources then
        return resources:getModel(path)
    end

    local model = { vertices = {}, faces = {} }
    local content = love.filesystem.read(path)
    if not content then return model end

    for line in content:gmatch("[^\n]+") do
        line = line:gsub("%s+", " "):match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            local parts = {}
            for word in line:gmatch("%S+") do
                parts[#parts + 1] = word
            end

            if parts[1] == "v" then
                model.vertices[#model.vertices + 1] = {
                    tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
                }
            elseif parts[1] == "f" then
                local indices = {}
                local i = 2
                while i <= #parts do
                    local n = tonumber(parts[i])
                    if n then
                        indices[#indices + 1] = n
                        i = i + 1
                    else
                        break
                    end
                end

                local face = { indices = indices }

                for j = i, #parts do
                    if parts[j] == "color" then
                        face.color = {
                            tonumber(parts[j + 1]) or 1,
                            tonumber(parts[j + 2]) or 1,
                            tonumber(parts[j + 3]) or 1
                        }
                    elseif parts[j] == "textured" then
                        face.is_textured = true
                        if j + 1 <= #parts and not parts[j + 1]:match("^%d") then
                            face.texture_file = parts[j + 1]
                        end
                    end
                end

                model.faces[#model.faces + 1] = face
            end
        end
    end

    return model
end

function Objects.create(config)
    local obj = {}
    obj.x = config.x or 0
    obj.y = config.y or 0
    obj.z = config.z or 0
    obj.angleX = 0
    obj.angleY = 0
    obj.rotSpeedX = config.rotSpeedX or 0
    obj.rotSpeedY = config.rotSpeedY or 0
    obj.scale = config.scale or 1
    obj.drawOrder = config.drawOrder
    obj.size = config.size
    obj.static = config.static or false

    obj.modelPath = config.model
    local model = Objects.loadModel(config.model, config.resources)
    obj.vertices = model.vertices
    obj.faces = model.faces

    if obj.drawOrder then
        for _, f in ipairs(obj.faces) do
            f.drawOrder = obj.drawOrder
        end
    end

    if obj.size then
        local s = obj.size
        for i, v in ipairs(obj.vertices) do
            obj.vertices[i] = { v[1] * s, v[2] * s, v[3] * s }
        end
    end

    obj._vertsCache = nil
    obj._cacheDirty = true

    function obj:markDirty()
        self._cacheDirty = true
        self._vertsCache = nil
    end

    function obj:update(dt)
        local oldX = self.angleX
        local oldY = self.angleY
        self.angleX = self.angleX + self.rotSpeedX * dt
        self.angleY = self.angleY + self.rotSpeedY * dt
        if self.angleX ~= oldX or self.angleY ~= oldY then
            self:markDirty()
        end
    end

    function obj:getTransformedVertices()
        if self._vertsCache and not self._cacheDirty then
            return self._vertsCache
        end

        local result = {}
        local cosY, sinY = math.cos(self.angleY), math.sin(self.angleY)
        local cosX, sinX = math.cos(self.angleX), math.sin(self.angleX)
        local sc = self.scale or 1

        for i, v in ipairs(self.vertices) do
            local x, y, z = v[1] * sc, v[2] * sc, v[3] * sc

            local rx1 = x * cosY - z * sinY
            local rz1 = x * sinY + z * cosY

            local ry2 = y * cosX - rz1 * sinX
            local rz2 = y * sinX + rz1 * cosX

            result[i] = { rx1 + self.x, ry2 + self.y, rz2 + self.z }
        end

        if self.rotSpeedX == 0 and self.rotSpeedY == 0 then
            self._vertsCache = result
            self._cacheDirty = false
        end

        return result
    end

    return obj
end

return Objects
