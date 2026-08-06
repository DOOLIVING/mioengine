local UI = {}

local state

function UI.init(s)
    state = s
end

function UI.drawGrid()
    if not state.scene.gridVisible then return end
    local s = state
    local cam = s.cam
    local W, H = s.W, s.H
    local size = 20
    local step = 1

    love.graphics.setColor(0.1, 0.15, 0.25, 0.5)
    for i = -size, size, step do
        local sx1, sy1 = Camera.projectPoint(cam, i, 0, -size, W, H)
        local sx2, sy2 = Camera.projectPoint(cam, i, 0, size, W, H)
        love.graphics.line(sx1, sy1, sx2, sy2)
    end
    for i = -size, size, step do
        local sx1, sy1 = Camera.projectPoint(cam, -size, 0, i, W, H)
        local sx2, sy2 = Camera.projectPoint(cam, size, 0, i, W, H)
        love.graphics.line(sx1, sy1, sx2, sy2)
    end

    local ax, ay = Camera.projectPoint(cam, 3, 0, 0, W, H)
    local bx, by = Camera.projectPoint(cam, 0, 0, 0, W, H)
    love.graphics.setColor(1, 0.2, 0.2, 0.7)
    love.graphics.line(bx, by, ax, ay)
    local ax2, ay2 = Camera.projectPoint(cam, 0, 3, 0, W, H)
    love.graphics.setColor(0.2, 1, 0.2, 0.7)
    love.graphics.line(bx, by, ax2, ay2)
    local az, az2 = Camera.projectPoint(cam, 0, 0, 3, W, H)
    love.graphics.setColor(0.2, 0.2, 1, 0.7)
    love.graphics.line(bx, by, az, az2)
end

function UI.drawObjects()
    local s = state
    local cam = s.cam
    local W, H = s.W, s.H
    local renderList = {}

    for i, obj in ipairs(s.scene.objects) do
        local verts = Scene.getTransformedVertices(obj)
        local avgZ = 0
        local behind = false
        for _, v in ipairs(verts) do
            local _, _, rz = Camera.transformPoint(cam, v[1], v[2], v[3])
            if rz < 0.1 then behind = true end
            avgZ = avgZ + rz
        end
        avgZ = avgZ / math.max(#verts, 1)
        if not behind and #verts > 0 then
            renderList[#renderList + 1] = { obj = obj, verts = verts, index = i, depth = avgZ }
        end
    end

    table.sort(renderList, function(a, b) return a.depth > b.depth end)

    for _, item in ipairs(renderList) do
        local obj = item.obj
        local verts = item.verts
        local i = item.index

        for _, face in ipairs(obj.faces) do
            local pts = {}
            local valid = true
            for _, idx in ipairs(face.indices) do
                local v = verts[idx]
                if not v then valid = false; break end
                local sx, sy = Camera.projectPoint(cam, v[1], v[2], v[3], W, H)
                pts[#pts + 1] = sx
                pts[#pts + 1] = sy
            end

            if valid and #pts >= 6 then
                if i == s.scene.selected then
                    love.graphics.setColor(face.color[1] * 0.8 + 0.2, face.color[2] * 0.8 + 0.1, face.color[3] * 0.8 + 0.1)
                else
                    love.graphics.setColor(face.color[1], face.color[2], face.color[3])
                end
                love.graphics.polygon("fill", pts)
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.polygon("line", pts)
            end
        end

        if i == s.scene.selected then
            local cx, cy, cz = 0, 0, 0
            for _, v in ipairs(verts) do
                cx = cx + v[1]
                cy = cy + v[2]
                cz = cz + v[3]
            end
            cx = cx / #verts
            cy = cy / #verts
            cz = cz / #verts

            local gs = 0.5
            local gx1, gy1 = Camera.projectPoint(cam, cx - gs, cy, cz, W, H)
            local gx2, gy2 = Camera.projectPoint(cam, cx + gs, cy, cz, W, H)
            local gy3, gy4 = Camera.projectPoint(cam, cx, cy - gs, cz, W, H)
            local gy5, gy6 = Camera.projectPoint(cam, cx, cy + gs, cz, W, H)
            local gz1, gz2 = Camera.projectPoint(cam, cx, cy, cz - gs, W, H)
            local gz3, gz4 = Camera.projectPoint(cam, cx, cy, cz + gs, W, H)

            love.graphics.setLineWidth(2)
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.line(gx1, gy1, gx2, gy2)
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.line(gy3, gy4, gy5, gy6)
            love.graphics.setColor(0.3, 0.3, 1)
            love.graphics.line(gz1, gz2, gz3, gz4)
            love.graphics.setLineWidth(1)
        end
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
    local sc = s.scene
    local barH = 36

    love.graphics.setColor(0.08, 0.12, 0.22)
    love.graphics.rectangle("fill", 0, 0, W, barH)

    local buttons = {
        { "Add(A)", function()
            s.openInput("Model file (.txt):", "", function(text)
                if text ~= "" then
                    local idx = Scene.addObject(sc, text, 0, 0.5, 0)
                    sc.selected = idx
                    s.setStatus("Added: " .. text)
                end
            end)
        end },
        { "Duplicate(D)", function()
            Scene.duplicateObject(sc)
            s.setStatus("Duplicated")
        end },
        { "Delete(Del)", function()
            Scene.deleteObject(sc)
            s.setStatus("Deleted")
        end },
        { "Save(S)", function()
            s.openInput("Save scene (.scene):", sc.name, function(text)
                if text ~= "" then
                    local ok, msg = Scene.save(sc, text)
                    s.setStatus(msg)
                end
            end)
        end },
        { "Load(L)", function()
            s.openInput("Load scene (.scene):", "", function(text)
                if text ~= "" then
                    local ok, msg = Scene.load(sc, text)
                    s.setStatus(msg)
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
    love.graphics.print(string.format("Objects:%d", #sc.objects), W - 150, 10)

    local panelW = 260
    local px = W - panelW
    love.graphics.setColor(0.08, 0.12, 0.22, 0.9)
    love.graphics.rectangle("fill", px, barH, panelW, H - barH)

    love.graphics.setColor(0.2, 0.8, 0.4)
    love.graphics.print("Scene: " .. sc.name, px + 8, barH + 8)

    love.graphics.setColor(0.9, 0.3, 0.4)
    love.graphics.print("Objects", px + 8, barH + 28)

    for oi, obj in ipairs(sc.objects) do
        local oy = barH + 46 + (oi - 1) * 20
        if oi == sc.selected then
            love.graphics.setColor(1, 1, 0.3)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        local name = obj.model:match("([^/]+)$") or obj.model
        love.graphics.print(string.format("%d. %s", oi, name), px + 8, oy)
    end

    local si = sc.selected
    if si >= 1 and si <= #sc.objects then
        local obj = sc.objects[si]
        local py = barH + 46 + #sc.objects * 20 + 16

        love.graphics.setColor(0.9, 0.3, 0.4)
        love.graphics.print("Properties", px + 8, py)
        py = py + 20

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(string.format("Pos: %.1f %.1f %.1f", obj.x, obj.y, obj.z), px + 8, py)
        py = py + 18
        love.graphics.print(string.format("Rot: %.2f %.2f %.2f", obj.angleX, obj.angleY, obj.angleZ), px + 8, py)
        py = py + 18
        love.graphics.print(string.format("Scl: %.2f %.2f %.2f", obj.scaleX, obj.scaleY, obj.scaleZ), px + 8, py)
        py = py + 24

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Tab - select object", px + 8, py)
        py = py + 16
        love.graphics.print("Arrows/QE - move", px + 8, py)
        py = py + 16
        love.graphics.print("1-6 - rotate XYZ", px + 8, py)
        py = py + 16
        love.graphics.print("+/- - scale", px + 8, py)
        py = py + 16
        love.graphics.print("Del - delete", px + 8, py)
        py = py + 16
        love.graphics.print("D - duplicate", px + 8, py)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Tab to select", px + 8, barH + 46)
    end

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("RMB - rotate cam", px + 8, H - 80)
    love.graphics.print("MMB - pan cam", px + 8, H - 64)
    love.graphics.print("Wheel - zoom", px + 8, H - 48)
    love.graphics.print("G - grid toggle", px + 8, H - 32)
    love.graphics.print("Esc - back to menu", px + 8, H - 16)

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
    end
end

return UI
