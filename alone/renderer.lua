local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(config)
    local self = setmetatable({}, Renderer)
    self.width = config.width or 320
    self.height = config.height or 240
    self.fov = config.fov or 200
    self.canvas = nil
    self.texture = nil
    self.textureQuads = {}
    self.textureCache = {}
    return self
end

function Renderer:load(texturePath)
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter("nearest", "nearest")

    self.texture = love.graphics.newImage(texturePath)
    self.texture:setFilter("nearest", "nearest")

    local texW, texH = self.texture:getDimensions()
    for i = 0, texH - 1 do
        table.insert(self.textureQuads, love.graphics.newQuad(0, i, texW, 1, texW, texH))
    end
end

function Renderer:getTexture(path)
    if not path then return self.texture end
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
            if verts[face.indices[j]].tz >= 0.1 then
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
            for j = 1, #clipped do
                avgZ = avgZ + verts[clipped[j]].tz
            end
            avgZ = avgZ / #clipped
            local newFace = { indices = clipped, color = face.color, is_textured = face.is_textured, texture_file = face.texture_file, drawOrder = face.drawOrder }
            table.insert(renderList, { face = newFace, depth = avgZ, drawOrder = face.drawOrder or 1 })
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
    end
    return result
end

function Renderer:drawScene(verts, renderList, camera)
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.15, 0.15, 0.15)

    for i = 1, #renderList do
        local face = renderList[i].face
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
            love.graphics.setColor(face.color[1], face.color[2], face.color[3])
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

    love.graphics.setCanvas()
    local scaleX = love.graphics.getWidth() / self.width
    local scaleY = love.graphics.getHeight() / self.height
    love.graphics.draw(self.canvas, 0, 0, 0, scaleX, scaleY)
end

return Renderer
