local Scene = {}

function Scene.new()
    local self = {}
    self.name = "untitled"
    self.objects = {}
    self.selected = -1
    self.gridVisible = true
    return self
end

function Scene.addObject(scene, modelPath, x, y, z)
    local obj = {
        model = modelPath,
        x = x or 0,
        y = y or 0,
        z = z or 0,
        angleX = 0,
        angleY = 0,
        angleZ = 0,
        scaleX = 1,
        scaleY = 1,
        scaleZ = 1,
        vertices = {},
        faces = {}
    }
    Scene.loadModel(obj, modelPath)
    scene.objects[#scene.objects + 1] = obj
    return #scene.objects
end

function Scene.loadModel(obj, path)
    obj.vertices = {}
    obj.faces = {}
    local content = love.filesystem.read(path)
    if not content then return end

    local verts = {}
    for line in content:gmatch("[^\n]+") do
        line = line:gsub("%s+", " "):match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            local parts = {}
            for word in line:gmatch("%S+") do
                parts[#parts + 1] = word
            end

            if parts[1] == "v" then
                verts[#verts + 1] = {
                    tonumber(parts[2]) or 0,
                    tonumber(parts[3]) or 0,
                    tonumber(parts[4]) or 0
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

                local face = { indices = indices, color = {1,1,1}, is_textured = false, texture_file = nil }
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

                obj.faces[#obj.faces + 1] = face
            end
        end
    end

    for _, v in ipairs(verts) do
        obj.vertices[#obj.vertices + 1] = { v[1], v[2], v[3] }
    end
end

function Scene.getTransformedVertices(obj)
    local result = {}
    local cosY, sinY = math.cos(obj.angleY), math.sin(obj.angleY)
    local cosX, sinX = math.cos(obj.angleX), math.sin(obj.angleX)
    local cosZ, sinZ = math.cos(obj.angleZ), math.sin(obj.angleZ)

    for i, v in ipairs(obj.vertices) do
        local x = v[1] * obj.scaleX
        local y = v[2] * obj.scaleY
        local z = v[3] * obj.scaleZ

        local rx1 = x * cosY - z * sinY
        local rz1 = x * sinY + z * cosY

        local ry2 = y * cosX - rz1 * sinX
        local rz2 = y * sinX + rz1 * cosX

        local rx3 = rx1 * cosZ - ry2 * sinZ
        local ry3 = rx1 * sinZ + ry2 * cosZ

        result[i] = { rx3 + obj.x, ry3 + obj.y, rz2 + obj.z }
    end
    return result
end

function Scene.buildSaveTxt(scene)
    local lines = {}
    lines[#lines + 1] = "# " .. scene.name .. ".scene"
    for _, obj in ipairs(scene.objects) do
        lines[#lines + 1] = string.format("object %s %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f",
            obj.model,
            obj.x, obj.y, obj.z,
            obj.angleX, obj.angleY, obj.angleZ,
            obj.scaleX, obj.scaleY, obj.scaleZ,
            0, 0)
    end
    return table.concat(lines, "\n")
end

function Scene.save(scene, filename)
    if filename == "" then return false, "Empty filename" end
    if not filename:match("%.scene$") then filename = filename .. ".scene" end
    local txt = Scene.buildSaveTxt(scene)
    local file = io.open(filename, "w")
    if file then
        file:write(txt)
        file:close()
        return true, "Saved: " .. filename
    end
    return false, "Save error"
end

function Scene.load(scene, filename)
    local content = love.filesystem.read(filename)
    if not content then return false, "File not found: " .. filename end

    scene.objects = {}
    scene.selected = -1

    for line in content:gmatch("[^\n]+") do
        line = line:gsub("%s+", " "):match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            local parts = {}
            for word in line:gmatch("%S+") do
                parts[#parts + 1] = word
            end
            if parts[1] == "object" and parts[2] then
                local obj = {
                    model = parts[2],
                    x = tonumber(parts[3]) or 0,
                    y = tonumber(parts[4]) or 0,
                    z = tonumber(parts[5]) or 0,
                    angleX = tonumber(parts[6]) or 0,
                    angleY = tonumber(parts[7]) or 0,
                    angleZ = tonumber(parts[8]) or 0,
                    scaleX = tonumber(parts[9]) or 1,
                    scaleY = tonumber(parts[10]) or 1,
                    scaleZ = tonumber(parts[11]) or 1,
                    vertices = {},
                    faces = {}
                }
                Scene.loadModel(obj, obj.model)
                scene.objects[#scene.objects + 1] = obj
            end
        end
    end
    if #scene.objects > 0 then scene.selected = 1 end
    return true, "Loaded " .. #scene.objects .. " objects"
end

function Scene.deleteObject(scene)
    if scene.selected >= 1 and scene.selected <= #scene.objects then
        table.remove(scene.objects, scene.selected)
        scene.selected = math.min(scene.selected, #scene.objects)
    end
end

function Scene.duplicateObject(scene)
    if scene.selected >= 1 and scene.selected <= #scene.objects then
        local src = scene.objects[scene.selected]
        local obj = {
            model = src.model,
            x = src.x + 1,
            y = src.y,
            z = src.z,
            angleX = src.angleX,
            angleY = src.angleY,
            angleZ = src.angleZ,
            scaleX = src.scaleX,
            scaleY = src.scaleY,
            scaleZ = src.scaleZ,
            vertices = {},
            faces = {}
        }
        Scene.loadModel(obj, obj.model)
        scene.objects[#scene.objects + 1] = obj
        scene.selected = #scene.objects
    end
end

return Scene
