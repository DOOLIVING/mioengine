local UI = {}

local state

function UI.init(s)
    state = s
end

function UI.pointInPolygon(px, py, verts2d)
    local inside = false
    local n = #verts2d
    for i = 1, n do
        local j = i % n + 1
        local xi, yi = verts2d[i][1], verts2d[i][2]
        local xj, yj = verts2d[j][1], verts2d[j][2]
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
    end
    return inside
end

function UI.findFaceAt(mx, my)
    local s = state
    local cam = s.cam
    local W, H = s.W, s.H
    local candidates = {}

    for i, f in ipairs(s.faces) do
        local pts = {}
        local allFront = true
        local avgZ = 0
        for _, v in ipairs(f.vertices) do
            local sx, sy, rz = Camera.projectPoint(cam, v[1], v[2], v[3], W, H)
            if rz < 0.1 then allFront = false end
            pts[#pts + 1] = {sx, sy}
            avgZ = avgZ + rz
        end
        if allFront and #pts >= 3 then
            avgZ = avgZ / #pts
            if UI.pointInPolygon(mx, my, pts) then
                candidates[#candidates + 1] = { index = i, depth = avgZ }
            end
        end
    end

    if #candidates > 0 then
        table.sort(candidates, function(a, b) return a.depth > b.depth end)
        return candidates[1].index
    end
    return -1
end

function UI.drawGrid()
    if not state.gridVisible then return end
    local s = state
    local cam = s.cam
    local W, H = s.W, s.H
    local size = 10
    local step = 1

    love.graphics.setColor(0.1, 0.15, 0.25, 0.5)
    for i = -size, size, step do
        local x1, y1, z1 = Camera.transformPoint(cam, i, 0, -size)
        local x2, y2, z2 = Camera.transformPoint(cam, i, 0, size)
        local sx1 = (x1 * cam.fov) / math.max(z1, 0.1) + W / 2
        local sy1 = (-y1 * cam.fov) / math.max(z1, 0.1) + H / 2
        local sx2 = (x2 * cam.fov) / math.max(z2, 0.1) + W / 2
        local sy2 = (-y2 * cam.fov) / math.max(z2, 0.1) + H / 2
        love.graphics.line(sx1, sy1, sx2, sy2)
    end
    for i = -size, size, step do
        local x1, y1, z1 = Camera.transformPoint(cam, -size, 0, i)
        local x2, y2, z2 = Camera.transformPoint(cam, size, 0, i)
        local sx1 = (x1 * cam.fov) / math.max(z1, 0.1) + W / 2
        local sy1 = (-y1 * cam.fov) / math.max(z1, 0.1) + H / 2
        local sx2 = (x2 * cam.fov) / math.max(z2, 0.1) + W / 2
        local sy2 = (-y2 * cam.fov) / math.max(z2, 0.1) + H / 2
        love.graphics.line(sx1, sy1, sx2, sy2)
    end
end

function UI.drawFaces()
    local s = state
    local cam = s.cam
    local W, H = s.W, s.H
    local renderList = {}

    for i, f in ipairs(s.faces) do
        local avgZ = 0
        local behind = false
        for _, v in ipairs(f.vertices) do
            local _, _, rz = Camera.transformPoint(cam, v[1], v[2], v[3])
            if rz < 0.1 then behind = true end
            avgZ = avgZ + rz
        end
        avgZ = avgZ / #f.vertices
        if not behind then
            renderList[#renderList + 1] = { face = f, index = i, depth = avgZ, drawOrder = f.drawOrder or 1 }
        end
    end

    table.sort(renderList, function(a, b)
        if a.drawOrder ~= b.drawOrder then return a.drawOrder < b.drawOrder end
        return a.depth > b.depth
    end)

    for _, item in ipairs(renderList) do
        local f = item.face
        local i = item.index
        local pts = {}
        for _, v in ipairs(f.vertices) do
            local sx, sy = Camera.projectPoint(cam, v[1], v[2], v[3], W, H)
            pts[#pts + 1] = sx
            pts[#pts + 1] = sy
        end

        if f.textured and f.textureFile then
            local img = Texture.get(f.textureFile)
            if img then
                love.graphics.setStencilTest()
                love.graphics.stencil(function()
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.polygon("fill", pts)
                end, "replace", 1)
                love.graphics.setStencilTest("equal", 1)

                local minX, minY = pts[1], pts[2]
                local maxX, maxY = pts[1], pts[2]
                for j = 1, #pts, 2 do
                    if pts[j] < minX then minX = pts[j] end
                    if pts[j] > maxX then maxX = pts[j] end
                    if pts[j + 1] < minY then minY = pts[j + 1] end
                    if pts[j + 1] > maxY then maxY = pts[j + 1] end
                end
                local polyW = maxX - minX
                local polyH = maxY - minY
                local scaleX = polyW / img:getWidth()
                local scaleY = polyH / img:getHeight()
                local scale = math.max(scaleX, scaleY)

                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img, minX, minY, 0, scale, scale)

                love.graphics.setStencilTest()
            end
        end

        if i == s.selectedFace then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.polygon("line", pts)
            love.graphics.setLineWidth(1)

            if s.selectedVertex >= 1 and s.selectedVertex <= #f.vertices then
                local sv = f.vertices[s.selectedVertex]
                local vsx, vsy = Camera.projectPoint(cam, sv[1], sv[2], sv[3], W, H)
                love.graphics.setColor(1, 1, 0)
                love.graphics.circle("fill", vsx, vsy, 5)
                love.graphics.setColor(0, 0, 0)
                love.graphics.circle("line", vsx, vsy, 5)
            end
        elseif i == s.hoveredFace then
            love.graphics.setColor(1, 1, 0.5, 0.4)
            love.graphics.polygon("fill", pts)
        else
            love.graphics.setColor(f.color[1], f.color[2], f.color[3])
            love.graphics.polygon("fill", pts)
        end

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.polygon("line", pts)
    end
end

function UI.drawCrosshair()
    local cx, cy = state.W / 2, state.H / 2
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(cx - 8, cy, cx + 8, cy)
    love.graphics.line(cx, cy - 8, cx, cy + 8)
end

function UI.drawUI()
    local s = state
    local W, H = s.W, s.H
    local barH = 36

    love.graphics.setColor(0.08, 0.12, 0.22)
    love.graphics.rectangle("fill", 0, 0, W, barH)

    local buttons = {
        { "Cube(C)", function() s.selectedFace = Model.addCube(s.faces, 0, 0.5, 0, s.colorIndex); s.setStatus("Cube added") end },
        { "Face(F)", function() s.selectedFace = Model.addFace(s.faces, 0, 0.5, 0, s.colorIndex); s.setStatus("Face added") end },
        { "Delete(Del)", function()
            if s.selectedFace >= 1 and s.selectedFace <= #s.faces then
                table.remove(s.faces, s.selectedFace)
                s.selectedFace = math.min(s.selectedFace, #s.faces)
                s.selectedVertex = -1
                s.setStatus("Face deleted")
            end
        end },
        { "Save(S)", function()
            s.openInput("Save as (filename.txt):", "", function(text)
                if text ~= "" then
                    local ok, msg = Model.save(s.faces, text)
                    s.setStatus(msg)
                end
            end)
        end },
        { "Load(R)", function()
            s.openInput("Load file:", "", function(text)
                if text ~= "" then
                    local file = io.open(text, "r")
                    if file then
                        local content = file:read("*a")
                        file:close()
                        local newFaces = Model.import(content)
                        if #newFaces > 0 then
                            s.faces = newFaces
                            s.selectedFace = 1
                            s.selectedVertex = -1
                            s.setStatus("Imported: " .. #newFaces .. " faces")
                        else
                            s.setStatus("Import error!")
                        end
                    else
                        s.setStatus("Not found: " .. text)
                    end
                end
            end)
        end },
        { "Texture(I)", function()
            s.openInput("Texture file (.png):", "", function(text)
                if text ~= "" and s.selectedFace >= 1 and s.selectedFace <= #s.faces then
                    local img = Texture.get(text)
                    if img then
                        s.faces[s.selectedFace].textureFile = text
                        s.faces[s.selectedFace].textured = true
                        s.setStatus("Texture: " .. text)
                    else
                        s.setStatus("Failed to load: " .. text)
                    end
                end
            end)
        end },
    }

    local bx = 8
    for _, btn in ipairs(buttons) do
        local tw = love.graphics.getFont():getWidth(btn[1]) + 16
        local hovered = love.mouse.getX() >= bx and love.mouse.getX() <= bx + tw
                      and love.mouse.getY() >= 4 and love.mouse.getY() <= barH - 4

        love.graphics.setColor(hovered and 0.25 or 0.12, hovered and 0.35 or 0.18, hovered and 0.55 or 0.3)
        love.graphics.rectangle("fill", bx, 4, tw, barH - 8, 4)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(btn[1], bx + 8, 10)
        bx = bx + tw + 4
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Faces:%d Color:%d/%d", #s.faces, s.colorIndex, #Model.COLORS), W - 250, 10)

    local panelW = 220
    local px = W - panelW
    love.graphics.setColor(0.08, 0.12, 0.22, 0.9)
    love.graphics.rectangle("fill", px, barH, panelW, H - barH)

    love.graphics.setColor(0.9, 0.3, 0.4)
    love.graphics.print("Properties", px + 8, barH + 8)

    local sf = s.selectedFace
    if sf >= 1 and sf <= #s.faces then
        local f = s.faces[sf]
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(string.format("Face %d (%d verts)", sf, #f.vertices), px + 8, barH + 28)

        love.graphics.print("Color:", px + 8, barH + 50)
        love.graphics.setColor(f.color[1], f.color[2], f.color[3])
        love.graphics.rectangle("fill", px + 50, barH + 46, 30, 16, 3)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Space", px + 86, barH + 50)

        love.graphics.setColor(0.8, 0.8, 0.8)
        local texStr = "off"
        if f.textured then
            texStr = f.textureFile and f.textureFile or "on"
        end
        love.graphics.print("Tex: " .. texStr, px + 8, barH + 72)

        love.graphics.print("+/- scale", px + 8, barH + 88)

        love.graphics.print("Vertices:", px + 8, barH + 106)
        for vi, v in ipairs(f.vertices) do
            local sy = barH + 122 + (vi - 1) * 18
            if vi == s.selectedVertex then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
            end
            love.graphics.print(string.format("v%d: %.1f %.1f %.1f", vi, v[1], v[2], v[3]), px + 8, sy)
        end

        love.graphics.setColor(0.5, 0.5, 0.5)
        local helpY = barH + 122 + #f.vertices * 18 + 4
        love.graphics.print("Tab - select vert", px + 8, helpY)
        love.graphics.print("LJK - move vert XZ", px + 8, helpY + 16)
        love.graphics.print("U/O - move vert Y", px + 8, helpY + 32)
        love.graphics.print("1-5 - rotate face", px + 8, helpY + 48)
        love.graphics.print("Esc - deselect vert", px + 8, helpY + 64)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Select a face", px + 8, barH + 28)
    end

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("RMB - rotate cam", px + 8, H - 96)
    love.graphics.print("MMB - pan cam", px + 8, H - 80)
    love.graphics.print("Wheel - zoom", px + 8, H - 64)
    love.graphics.print("Arrows - move face", px + 8, H - 48)
    love.graphics.print("PgUp/Dn - move Y", px + 8, H - 32)
    love.graphics.print("G - grid", px + 8, H - 16)

    if s.statusTimer > 0 then
        love.graphics.setColor(1, 1, 0.3, math.min(1, s.statusTimer))
        love.graphics.print(s.statusMsg, 8, H - 24)
    end

    if s.inputMode then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, W, H)
        local mw, mh = 500, 120
        local mx, my = W / 2 - mw / 2, H / 2 - mh / 2
        love.graphics.setColor(0.1, 0.15, 0.25)
        love.graphics.rectangle("fill", mx, my, mw, mh, 6)
        love.graphics.setColor(0.9, 0.3, 0.4)
        love.graphics.print(s.inputTitle, mx + 10, my + 10)

        love.graphics.setColor(0.15, 0.2, 0.35)
        love.graphics.rectangle("fill", mx + 10, my + 34, mw - 20, 28, 4)
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.print(s.inputText, mx + 16, my + 40)

        love.graphics.setColor(1, 1, 1, 0.5 + math.sin(love.timer.getTime() * 4) * 0.5)
        local tw = love.graphics.getFont():getWidth(s.inputText)
        love.graphics.line(mx + 16 + tw, my + 38, mx + 16 + tw, my + 60)

        if s.inputTitle:find("Texture") then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("Example: texture.png", mx + 10, my + 72)
        end
    end
end

return UI
