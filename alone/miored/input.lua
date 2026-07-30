local Input = {}

local state

function Input.init(s)
    state = s
end

function Input.keypressed(key)
    local s = state

    if s.inputMode then
        if key == "escape" then
            s.inputMode = false
        elseif key == "return" then
            local cb = s.inputCallback
            s.inputMode = false
            if cb then cb(s.inputText) end
        elseif key == "backspace" then
            s.inputText = s.inputText:sub(1, -2)
        end
        return
    end

    local step = love.keyboard.isDown("lshift") and 0.1 or 0.5
    local faces = s.faces
    local sf = s.selectedFace
    local sv = s.selectedVertex

    if key == "c" then
        s.selectedFace = Model.addCube(faces, 0, 0.5, 0, s.colorIndex)
        s.setStatus("Cube added")
    elseif key == "f" then
        s.selectedFace = Model.addFace(faces, 0, 0.5, 0, s.colorIndex)
        s.setStatus("Face added")
    elseif key == "delete" or key == "backspace" then
        if sf >= 1 and sf <= #faces then
            table.remove(faces, sf)
            s.selectedFace = math.min(sf, #faces)
            s.selectedVertex = -1
            s.setStatus("Face deleted")
        end
    elseif key == "s" then
        s.openInput("Save as (filename.txt):", "", function(text)
            if text ~= "" then
                local ok, msg = Model.save(faces, text)
                s.setStatus(msg)
            end
        end)
    elseif key == "r" then
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
    elseif key == "i" then
        s.openInput("Texture file (.png):", "", function(text)
            if text ~= "" and sf >= 1 and sf <= #faces then
                local img = Texture.get(text)
                if img then
                    faces[sf].textureFile = text
                    faces[sf].textured = true
                    s.setStatus("Texture: " .. text)
                else
                    s.setStatus("Failed to load: " .. text)
                end
            end
        end)
    elseif key == "g" then
        s.gridVisible = not s.gridVisible
    elseif key == "=" or key == "+" then
        if sf >= 1 and sf <= #faces then
            Model.scale(faces[sf], 1.2)
            s.setStatus("Scaled up")
        end
    elseif key == "-" then
        if sf >= 1 and sf <= #faces then
            Model.scale(faces[sf], 1 / 1.2)
            s.setStatus("Scaled down")
        end
    elseif key == "tab" then
        if sf >= 1 and sf <= #faces then
            local f = faces[sf]
            s.selectedVertex = sv + 1
            if s.selectedVertex > #f.vertices then
                s.selectedVertex = 1
            end
            s.setStatus(string.format("Vertex %d/%d", s.selectedVertex, #f.vertices))
        end
    elseif key == "space" then
        s.colorIndex = s.colorIndex + 1
        if s.colorIndex > #Model.COLORS then s.colorIndex = 1 end
        if sf >= 1 and sf <= #faces then
            local c = Model.COLORS[s.colorIndex]
            faces[sf].color = { c[1], c[2], c[3] }
            s.setStatus(string.format("Color: %d/%d", s.colorIndex, #Model.COLORS))
        end
    elseif key == "t" then
        if sf >= 1 and sf <= #faces then
            faces[sf].textured = not faces[sf].textured
            s.setStatus("Texture: " .. tostring(faces[sf].textured))
        end
    elseif key == "1" then
        if sf >= 1 and sf <= #faces then
            Model.rotate(faces[sf], "x", 0.2)
            s.setStatus("Rotated X+")
        end
    elseif key == "2" then
        if sf >= 1 and sf <= #faces then
            Model.rotate(faces[sf], "x", -0.2)
            s.setStatus("Rotated X-")
        end
    elseif key == "3" then
        if sf >= 1 and sf <= #faces then
            Model.rotate(faces[sf], "y", 0.2)
            s.setStatus("Rotated Y+")
        end
    elseif key == "4" then
        if sf >= 1 and sf <= #faces then
            Model.rotate(faces[sf], "y", -0.2)
            s.setStatus("Rotated Y-")
        end
    elseif key == "5" then
        if sf >= 1 and sf <= #faces then
            Model.rotate(faces[sf], "z", 0.2)
            s.setStatus("Rotated Z+")
        end
    elseif key == "left" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], -step, 0, 0)
            s.setStatus("Moved -X")
        end
    elseif key == "right" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], step, 0, 0)
            s.setStatus("Moved +X")
        end
    elseif key == "up" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], 0, 0, -step)
            s.setStatus("Moved -Z")
        end
    elseif key == "down" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], 0, 0, step)
            s.setStatus("Moved +Z")
        end
    elseif key == "pageup" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], 0, step, 0)
            s.setStatus("Moved +Y")
        end
    elseif key == "pagedown" then
        if sf >= 1 and sf <= #faces then
            Model.move(faces[sf], 0, -step, 0)
            s.setStatus("Moved -Y")
        end
    elseif key == "escape" then
        s.selectedVertex = -1
        s.setStatus("Deselected vertex")
    elseif key == "l" then
        if sv >= 1 and sf >= 1 and sf <= #faces then
            faces[sf].vertices[sv][1] = faces[sf].vertices[sv][1] + step
        end
    elseif key == "j" then
        if sv >= 1 and sf >= 1 and sf <= #faces then
            faces[sf].vertices[sv][1] = faces[sf].vertices[sv][1] - step
        end
    elseif key == "k" then
        if sv >= 1 and sf >= 1 and sf <= #faces then
            faces[sf].vertices[sv][3] = faces[sf].vertices[sv][3] + step
        end
    elseif key == "u" then
        if sv >= 1 and sf >= 1 and sf <= #faces then
            faces[sf].vertices[sv][2] = faces[sf].vertices[sv][2] + step
        end
    elseif key == "o" then
        if sv >= 1 and sf >= 1 and sf <= #faces then
            faces[sf].vertices[sv][2] = faces[sf].vertices[sv][2] - step
        end
    end
end

function Input.textinput(text)
    if state.inputMode then
        state.inputText = state.inputText .. text
    end
end

function Input.mousepressed(x, y, button)
    if state.inputMode then return end

    if button == 1 then
        local hit = state.findFaceAt(x, y)
        if hit > 0 then
            state.selectedFace = hit
            state.selectedVertex = -1
            state.setStatus(string.format("Face %d/%d", state.selectedFace, #state.faces))
        else
            state.selectedFace = -1
            state.selectedVertex = -1
        end
    elseif button == 2 or button == 3 then
        state.isDragging = true
        state.dragButton = button
    end
end

function Input.mousereleased(x, y, button)
    if button == 2 or button == 3 then
        state.isDragging = false
    end
end

function Input.mousemoved(x, y, dx, dy)
    local s = state
    local cam = s.cam

    if s.isDragging and s.dragButton == 2 then
        cam.yaw = cam.yaw - dx * 0.005
        cam.pitch = cam.pitch + dy * 0.005
        cam.pitch = math.max(-math.pi / 2 + 0.01, math.min(math.pi / 2 - 0.01, cam.pitch))
    elseif s.isDragging and s.dragButton == 3 then
        local rightX = math.cos(cam.yaw)
        local rightZ = -math.sin(cam.yaw)
        local fwdX = -math.sin(cam.yaw)
        local fwdZ = -math.cos(cam.yaw)
        local panSpeed = cam.dist * 0.001
        cam.targetX = cam.targetX + (-rightX * dx + fwdX * dy) * panSpeed
        cam.targetY = cam.targetY + dy * panSpeed * 0.5
        cam.targetZ = cam.targetZ + (-rightZ * dx + fwdZ * dy) * panSpeed
    end
end

function Input.wheelmoved(x, y)
    state.cam.dist = state.cam.dist - y * state.cam.dist * 0.1
    state.cam.dist = math.max(1, math.min(100, state.cam.dist))
end

return Input
