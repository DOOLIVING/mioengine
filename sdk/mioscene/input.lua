local Input = {}

local state

function Input.init(s)
    state = s
end

function Input.keypressed(key)
    local s = state
    local sc = s.scene
    local step = love.keyboard.isDown("lshift") and 0.1 or 0.5
    local rotStep = love.keyboard.isDown("lshift") and 0.05 or 0.2

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

    local si = sc.selected
    local obj = nil
    if si >= 1 and si <= #sc.objects then
        obj = sc.objects[si]
    end

    if key == "a" then
        s.openInput("Model file (.txt):", "", function(text)
            if text ~= "" then
                local idx = Scene.addObject(sc, text, 0, 0.5, 0)
                sc.selected = idx
                s.setStatus("Added: " .. text)
            end
        end)
    elseif key == "delete" or key == "backspace" then
        Scene.deleteObject(sc)
        s.setStatus("Deleted")
    elseif key == "d" then
        Scene.duplicateObject(sc)
        s.setStatus("Duplicated")
    elseif key == "s" then
        s.openInput("Save scene (.scene):", sc.name, function(text)
            if text ~= "" then
                local ok, msg = Scene.save(sc, text)
                s.setStatus(msg)
            end
        end)
    elseif key == "l" then
        s.openInput("Load scene (.scene):", "", function(text)
            if text ~= "" then
                local ok, msg = Scene.load(sc, text)
                s.setStatus(msg)
            end
        end)
    elseif key == "g" then
        sc.gridVisible = not sc.gridVisible
    elseif key == "tab" then
        if #sc.objects > 0 then
            if si < 1 then
                sc.selected = 1
            else
                sc.selected = si + 1
                if sc.selected > #sc.objects then sc.selected = 1 end
            end
            s.setStatus(string.format("Object %d/%d", sc.selected, #sc.objects))
        end
    elseif key == "left" then
        if obj then
            obj.x = obj.x - step
            s.setStatus(string.format("X: %.1f", obj.x))
        end
    elseif key == "right" then
        if obj then
            obj.x = obj.x + step
            s.setStatus(string.format("X: %.1f", obj.x))
        end
    elseif key == "up" then
        if obj then
            obj.y = obj.y + step
            s.setStatus(string.format("Y: %.1f", obj.y))
        end
    elseif key == "down" then
        if obj then
            obj.y = obj.y - step
            s.setStatus(string.format("Y: %.1f", obj.y))
        end
    elseif key == "q" then
        if obj then
            obj.z = obj.z - step
            s.setStatus(string.format("Z: %.1f", obj.z))
        end
    elseif key == "e" then
        if obj then
            obj.z = obj.z + step
            s.setStatus(string.format("Z: %.1f", obj.z))
        end
    elseif key == "1" then
        if obj then
            obj.angleX = obj.angleX + rotStep
            s.setStatus(string.format("RotX: %.2f", obj.angleX))
        end
    elseif key == "2" then
        if obj then
            obj.angleX = obj.angleX - rotStep
            s.setStatus(string.format("RotX: %.2f", obj.angleX))
        end
    elseif key == "3" then
        if obj then
            obj.angleY = obj.angleY + rotStep
            s.setStatus(string.format("RotY: %.2f", obj.angleY))
        end
    elseif key == "4" then
        if obj then
            obj.angleY = obj.angleY - rotStep
            s.setStatus(string.format("RotY: %.2f", obj.angleY))
        end
    elseif key == "5" then
        if obj then
            obj.angleZ = obj.angleZ + rotStep
            s.setStatus(string.format("RotZ: %.2f", obj.angleZ))
        end
    elseif key == "6" then
        if obj then
            obj.angleZ = obj.angleZ - rotStep
            s.setStatus(string.format("RotZ: %.2f", obj.angleZ))
        end
    elseif key == "=" or key == "+" then
        if obj then
            obj.scaleX = obj.scaleX * 1.2
            obj.scaleY = obj.scaleY * 1.2
            obj.scaleZ = obj.scaleZ * 1.2
            s.setStatus("Scale up")
        end
    elseif key == "-" then
        if obj then
            obj.scaleX = obj.scaleX / 1.2
            obj.scaleY = obj.scaleY / 1.2
            obj.scaleZ = obj.scaleZ / 1.2
            s.setStatus("Scale down")
        end
    elseif key == "escape" then
        sc.selected = -1
        s.setStatus("Deselected")
    end
end

function Input.textinput(text)
    if state.inputMode then
        state.inputText = state.inputText .. text
    end
end

function Input.mousepressed(x, y, button)
    if state.inputMode then return end
    if button == 2 or button == 3 then
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
