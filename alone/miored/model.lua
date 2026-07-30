local Model = {}

Model.COLORS = {
    {0.9, 0.2, 0.1},
    {0.1, 0.6, 0.1},
    {0.1, 0.1, 0.7},
    {0.7, 0.6, 0.1},
    {0.6, 0.1, 0.6},
    {0.1, 0.6, 0.6},
    {0.6, 0.3, 0.1},
    {0.3, 0.5, 0.2},
    {0.8, 0.5, 0.2},
    {0.5, 0.5, 0.5}
}

function Model.getCenter(f)
    local cx, cy, cz = 0, 0, 0
    for _, v in ipairs(f.vertices) do
        cx = cx + v[1]
        cy = cy + v[2]
        cz = cz + v[3]
    end
    local n = #f.vertices
    return cx / n, cy / n, cz / n
end

function Model.scale(f, factor)
    local cx, cy, cz = Model.getCenter(f)
    for _, v in ipairs(f.vertices) do
        v[1] = cx + (v[1] - cx) * factor
        v[2] = cy + (v[2] - cy) * factor
        v[3] = cz + (v[3] - cz) * factor
    end
end

function Model.move(f, dx, dy, dz)
    for _, v in ipairs(f.vertices) do
        v[1] = v[1] + dx
        v[2] = v[2] + dy
        v[3] = v[3] + dz
    end
end

function Model.rotate(f, axis, angle)
    local cx, cy, cz = Model.getCenter(f)
    local cosA, sinA = math.cos(angle), math.sin(angle)
    for _, v in ipairs(f.vertices) do
        local rx, ry, rz = v[1] - cx, v[2] - cy, v[3] - cz
        if axis == "x" then
            v[2] = cy + ry * cosA - rz * sinA
            v[3] = cz + ry * sinA + rz * cosA
        elseif axis == "y" then
            v[1] = cx + rx * cosA + rz * sinA
            v[3] = cz - rx * sinA + rz * cosA
        elseif axis == "z" then
            v[1] = cx + rx * cosA - ry * sinA
            v[2] = cy + rx * sinA + ry * cosA
        end
    end
end

function Model.addCube(faces, cx, cy, cz, colorIndex)
    local s = 0.5
    local verts = {
        {-s,-s,-s}, { s,-s,-s}, { s, s,-s}, {-s, s,-s},
        {-s,-s, s}, { s,-s, s}, { s, s, s}, {-s, s, s}
    }
    local faceDef = {
        { {1,2,3,4}, true },
        { {5,6,7,8}, false },
        { {1,5,8,4}, false },
        { {2,6,7,3}, false },
        { {4,3,7,8}, false },
        { {1,2,6,5}, false }
    }
    for fi, fd in ipairs(faceDef) do
        local v = {}
        for _, idx in ipairs(fd[1]) do
            v[#v + 1] = { verts[idx][1] + cx, verts[idx][2] + cy, verts[idx][3] + cz }
        end
        local ci = ((fi - 1) % #Model.COLORS) + 1
        faces[#faces + 1] = {
            vertices = v,
            color = { Model.COLORS[ci][1], Model.COLORS[ci][2], Model.COLORS[ci][3] },
            textured = fd[2],
            textureFile = nil,
            drawOrder = 1
        }
    end
    return #faces - 5
end

function Model.addFace(faces, cx, cy, cz, colorIndex)
    local s = 0.5
    local ci = colorIndex
    faces[#faces + 1] = {
        vertices = {
            { cx, cy + s, cz - s },
            { cx + s, cy + s, cz + s },
            { cx - s, cy + s, cz + s }
        },
        color = { Model.COLORS[ci][1], Model.COLORS[ci][2], Model.COLORS[ci][3] },
        textured = false,
        textureFile = nil,
        drawOrder = 1
    }
    return #faces
end

function Model.buildExportTxt(faces, filename)
    local allVerts = {}
    local vertMap = {}

    for _, f in ipairs(faces) do
        for _, v in ipairs(f.vertices) do
            local key = string.format("%.4f,%.4f,%.4f", v[1], v[2], v[3])
            if not vertMap[key] then
                vertMap[key] = #allVerts + 1
                allVerts[#allVerts + 1] = v
            end
        end
    end

    local lines = {}
    lines[#lines + 1] = "# " .. filename
    for _, v in ipairs(allVerts) do
        lines[#lines + 1] = string.format("v %.4f %.4f %.4f", v[1], v[2], v[3])
    end
    lines[#lines + 1] = ""

    for _, f in ipairs(faces) do
        local indices = {}
        for _, v in ipairs(f.vertices) do
            local key = string.format("%.4f,%.4f,%.4f", v[1], v[2], v[3])
            indices[#indices + 1] = vertMap[key]
        end
        local line = "f " .. table.concat(indices, " ")
        if f.color then
            line = line .. string.format(" color %.3f %.3f %.3f", f.color[1], f.color[2], f.color[3])
        end
        if f.textured then
            line = line .. " textured"
            if f.textureFile then
                line = line .. " " .. f.textureFile
            end
        end
        lines[#lines + 1] = line
    end

    return table.concat(lines, "\n")
end

function Model.save(faces, name)
    if name == "" then return false, "Filename is empty!" end
    if not name:match("%.txt$") then name = name .. ".txt" end
    local txt = Model.buildExportTxt(faces, name)
    local file = io.open(name, "w")
    if file then
        file:write(txt)
        file:close()
        return true, "Saved: " .. name
    else
        return false, "Save error!"
    end
end

function Model.import(txt)
    local newFaces = {}
    local verts = {}

    for line in txt:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
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

                local face = { vertices = {}, color = {1, 1, 1}, textured = false, textureFile = nil, drawOrder = 1 }
                for _, idx in ipairs(indices) do
                    if verts[idx] then
                        face.vertices[#face.vertices + 1] = { verts[idx][1], verts[idx][2], verts[idx][3] }
                    end
                end

                for j = i, #parts do
                    if parts[j] == "color" then
                        face.color = {
                            tonumber(parts[j + 1]) or 1,
                            tonumber(parts[j + 2]) or 1,
                            tonumber(parts[j + 3]) or 1
                        }
                        j = j + 3
                    elseif parts[j] == "textured" then
                        face.textured = true
                        if j + 1 <= #parts and not parts[j + 1]:match("^%d") then
                            face.textureFile = parts[j + 1]
                            j = j + 1
                        end
                    end
                end

                if #face.vertices >= 3 then
                    newFaces[#newFaces + 1] = face
                end
            end
        end
    end

    return newFaces
end

return Model
