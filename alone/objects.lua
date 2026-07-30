local Objects = {}

function Objects.loadModel(path)
    local model = { vertices = {}, faces = {} }
    local file = io.open(path, "r")
    if not file then return model end

    for line in file:lines() do
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

    file:close()
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

    local model = Objects.loadModel(config.model)
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

    function obj:update(dt)
        self.angleX = self.angleX + self.rotSpeedX * dt
        self.angleY = self.angleY + self.rotSpeedY * dt
    end

    function obj:getTransformedVertices()
        local result = {}
        local cosY, sinY = math.cos(self.angleY), math.sin(self.angleY)
        local cosX, sinX = math.cos(self.angleX), math.sin(self.angleX)

        for i, v in ipairs(self.vertices) do
            local x, y, z = v[1], v[2], v[3]

            local rx1 = x * cosY - z * sinY
            local rz1 = x * sinY + z * cosY

            local ry2 = y * cosX - rz1 * sinX
            local rz2 = y * sinX + rz1 * cosX

            result[i] = { rx1 + self.x, ry2 + self.y, rz2 + self.z }
        end

        return result
    end

    return obj
end

return Objects
