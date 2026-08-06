local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(config)
    local self = setmetatable({}, Renderer)
    self.width = config.width or 320
    self.height = config.height or 240
    self.fov = config.fov or 200
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter("nearest", "nearest")
    self.texture = nil
    self.textureQuads = {}
    self.textureCache = {}
    self.modelCache = {}
    self.fogEnabled = config.fogEnabled or false
    self.fogColor = config.fogColor or {0.6, 0.6, 0.65}
    self.fogStart = config.fogStart or 8
    self.fogEnd = config.fogEnd or 20
    self.resources = config.resources
    return self
end

function Renderer:load(texturePath)
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter("nearest", "nearest")

    if self.resources then
        self.texture = self.resources:getImage(texturePath)
    else
        self.texture = love.graphics.newImage(texturePath)
    end
    self.texture:setFilter("nearest", "nearest")

    local texW, texH = self.texture:getDimensions()
    for i = 0, texH - 1 do
        table.insert(self.textureQuads, love.graphics.newQuad(0, i, texW, 1, texW, texH))
    end
end

function Renderer:getTexture(path)
    if not path then return self.texture end
    if self.resources then
        return self.resources:getImage(path) or self.texture
    end
    if self.textureCache[path] then return self.textureCache[path] end
    local ok, img = pcall(love.graphics.newImage, path)
    if ok then
        img:setFilter("nearest", "nearest")
        self.textureCache[path] = img
        return img
    end
    return self.texture
end

function Renderer:drawTexturedFace(p1, p2, p3, p4, texture)
    local tex = texture or self.texture
    local texW, texH = tex:getDimensions()
    love.graphics.setColor(1, 1, 1)

    for y = 0, texH - 1 do
        local t = y / (texH - 1)

        local lx = p1[1] + (p4[1] - p1[1]) * t
        local ly = p1[2] + (p4[2] - p1[2]) * t
        local rx = p2[1] + (p3[1] - p2[1]) * t
        local ry = p2[2] + (p3[2] - p2[2]) * t

        local dx = rx - lx
        local dy = ry - ly
        local dist = math.sqrt(dx * dx + dy * dy)
        local angle = math.atan2(dy, dx)

        local scaleX = dist / texW

        if dist > 0 then
            local quad = love.graphics.newQuad(0, y, texW, 1, texW, texH)
            love.graphics.draw(tex, quad, lx, ly, angle, scaleX, 1)
        end
    end
end

function Renderer:projectAndSort(camera, worldVertices, faces)
    local verts = {}

    for i = 1, #worldVertices do
        local v = worldVertices[i]
        local rx, ry, rz = camera:transformPoint(v[1], v[2], v[3])
        local pz = rz
        if rz < 0.1 then rz = 0.1 end
        local sx = math.floor((rx * self.fov) / rz + self.width / 2)
        local sy = math.floor((-ry * self.fov) / rz + self.height / 2)
        verts[i] = { tx = rx, ty = ry, tz = pz, sx = sx, sy = sy }
    end

    local renderList = {}
    for i = 1, #faces do
        local face = faces[i]
        local nverts = #face.indices

        local allBehind = true
        for j = 1, nverts do
            local v = verts[face.indices[j]]
            if v and v.tz >= 0.1 then
                allBehind = false
                break
            end
        end
        if allBehind then goto continue end

        local newIndices = {}
        for j = 1, nverts do
            newIndices[#newIndices + 1] = face.indices[j]
        end

        local clipped = self:clipFaceNear(newIndices, verts)
        if clipped and #clipped >= 3 then
            local avgZ = 0
            local valid = true
            for j = 1, #clipped do
                local v = verts[clipped[j]]
                if not v then valid = false; break end
                avgZ = avgZ + v.tz
            end
            if valid then
                avgZ = avgZ / #clipped
                local newFace = { indices = clipped, color = face.color, is_textured = face.is_textured, texture_file = face.texture_file, drawOrder = face.drawOrder }
                table.insert(renderList, { face = newFace, depth = avgZ, drawOrder = face.drawOrder or 1 })
            end
        end

        ::continue::
    end
    table.sort(renderList, function(a, b)
        if a.drawOrder ~= b.drawOrder then return a.drawOrder < b.drawOrder end
        return a.depth > b.depth
    end)

    return verts, renderList
end

function Renderer:clipFaceNear(indices, verts)
    local near = 0.1
    local result = {}
    local n = #indices
    for i = 1, n do
        local cur = indices[i]
        local nxt = indices[i % n + 1]
        local vCur = verts[cur]
        local vNxt = verts[nxt]
        if not vCur or not vNxt then goto continue end
        local insideCur = vCur.tz >= near
        local insideNxt = vNxt.tz >= near

        if insideCur then
            result[#result + 1] = cur
        end

        if insideCur ~= insideNxt then
            local t = (near - vCur.tz) / (vNxt.tz - vCur.tz)
            local nx = vCur.tx + (vNxt.tx - vCur.tx) * t
            local ny = vCur.ty + (vNxt.ty - vCur.ty) * t
            local newIdx = #verts + 1
            local rz = near
            local sx = math.floor((nx * self.fov) / rz + self.width / 2)
            local sy = math.floor((-ny * self.fov) / rz + self.height / 2)
            verts[newIdx] = { tx = nx, ty = ny, tz = near, sx = sx, sy = sy }
            result[#result + 1] = newIdx
        end
        ::continue::
    end
    return result
end

function Renderer:drawScene(verts, renderList, camera)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.53, 0.72, 0.90)

    for i = 1, #renderList do
        local entry = renderList[i]
        local face = entry.face
        local depth = entry.depth
        local nverts = #face.indices
        local points = {}
        for j = 1, nverts do
            local v = verts[face.indices[j]]
            points[#points + 1] = v.sx
            points[#points + 1] = v.sy
        end

        if face.is_textured and nverts == 4 then
            local v1 = verts[face.indices[1]]
            local v2 = verts[face.indices[2]]
            local v3 = verts[face.indices[3]]
            local v4 = verts[face.indices[4]]
            local tex = self:getTexture(face.texture_file)
            self:drawTexturedFace({v1.sx, v1.sy}, {v2.sx, v2.sy}, {v3.sx, v3.sy}, {v4.sx, v4.sy}, tex)
        elseif face.color then
            local r, g, b = face.color[1], face.color[2], face.color[3]
            if self.fogEnabled then
                local fogFactor = 0
                if depth > self.fogStart then
                    fogFactor = (depth - self.fogStart) / (self.fogEnd - self.fogStart)
                    if fogFactor > 1 then fogFactor = 1 end
                end
                r = r + (self.fogColor[1] - r) * fogFactor
                g = g + (self.fogColor[2] - g) * fogFactor
                b = b + (self.fogColor[3] - b) * fogFactor
            end
            love.graphics.setColor(r, g, b)
            love.graphics.polygon("fill", points)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.polygon("fill", points)
        end

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.polygon("line", points)
    end

    local cx, cy = self.width / 2, self.height / 2
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.line(cx - 6, cy, cx + 6, cy)
    love.graphics.line(cx, cy - 6, cx, cy + 6)
end

function Renderer:beginUI()
    love.graphics.setCanvas(self.canvas)
end

function Renderer:endUI()
    love.graphics.setCanvas()
    local scaleX = love.graphics.getWidth() / self.width
    local scaleY = love.graphics.getHeight() / self.height
    love.graphics.draw(self.canvas, 0, 0, 0, scaleX, scaleY)
end

function Renderer:getCanvasW()
    return self.width
end

function Renderer:getCanvasH()
    return self.height
end

function Renderer:projectPoint(camera, wx, wy, wz)
    if not camera then return nil end
    local rx, ry, rz = camera:transformPoint(wx, wy, wz)
    if rz < 0.1 then return nil end
    local sx = math.floor((rx * self.fov) / rz + self.width / 2)
    local sy = math.floor((-ry * self.fov) / rz + self.height / 2)
    return sx, sy, rz
end

function Renderer:loadModel(path)
    if self.modelCache[path] then
        return self.modelCache[path]
    end

    if self.resources then
        local model = self.resources:getModel(path)
        if model then
            self.modelCache[path] = model
        end
        return model
    end

    local content = love.filesystem.read(path)
    if not content then return nil end

    local vertices = {}
    local faces = {}
    local vCount = 0

    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line:sub(1, 1) == "v" and line:sub(2, 2) == " " then
            local x, y, z = line:match("^v%s+([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)$")
            if x then
                vCount = vCount + 1
                vertices[vCount] = { tonumber(x), tonumber(y), tonumber(z) }
            end
        elseif line:sub(1, 1) == "f" and line:sub(2, 2) == " " then
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
    self.modelCache[path] = model
    return model
end

function Renderer:drawModelHUD(path, screenX, screenY, scale, rotX, rotY)
    local model = self:loadModel(path)
    if not model then
        print("[drawModelHUD] FAILED to load: " .. path)
        return
    end
    if #model.vertices == 0 then
        print("[drawModelHUD] EMPTY model: " .. path)
        return
    end

    local cosX, sinX = math.cos(rotX or 0), math.sin(rotX or 0)
    local cosY, sinY = math.cos(rotY or 0), math.sin(rotY or 0)
    local s = scale or 1

    local projected = {}
    for i, v in ipairs(model.vertices) do
        local x, y, z = v[1], v[2], v[3]

        local y1 = y * cosX - z * sinX
        local z1 = y * sinX + z * cosX
        y, z = y1, z1

        local x1 = x * cosY + z * sinY
        local z2 = -x * sinY + z * cosY
        x, z = x1, z2

        z = z + 3
        if z < 0.1 then z = 0.1 end

        local sx = screenX + (x * self.fov * s) / z
        local sy = screenY + (-y * self.fov * s) / z
        projected[i] = { sx = sx, sy = sy, depth = z }
    end

    local drawList = {}
    for _, face in ipairs(model.faces) do
        local avgZ = 0
        local valid = true
        local pts = {}
        for _, idx in ipairs(face.indices) do
            local p = projected[idx]
            if not p then valid = false; break end
            pts[#pts + 1] = p.sx
            pts[#pts + 1] = p.sy
            avgZ = avgZ + p.depth
        end
        if valid and #pts >= 6 then
            avgZ = avgZ / #face.indices
            drawList[#drawList + 1] = { pts = pts, color = face.color, depth = avgZ }
        end
    end

    table.sort(drawList, function(a, b) return a.depth > b.depth end)

    for _, entry in ipairs(drawList) do
        love.graphics.setColor(entry.color[1], entry.color[2], entry.color[3])
        love.graphics.polygon("fill", entry.pts)
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.polygon("line", entry.pts)
    end
    love.graphics.setColor(1, 1, 1, 1)
    print("[drawModelHUD] Drew " .. #drawList .. " faces from " .. path)
end

return Renderer
