local SceneParser = {}

function SceneParser.parse(filepath)
    local scene = {
        camera = nil,
        renderer = nil,
        texture = nil,
        objects = {},
        colliders = {},
    }

    local content = love.filesystem.read(filepath)
    if not content then
        print("[SceneParser] Cannot load: " .. filepath)
        return scene
    end

    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            local parts = {}
            for token in line:gmatch("%S+") do
                parts[#parts + 1] = token
            end

            local cmd = parts[1]

            if cmd == "camera" then
                scene.camera = {
                    x = tonumber(parts[2]) or 0,
                    y = tonumber(parts[3]) or 2.5,
                    z = tonumber(parts[4]) or -3,
                    speed = 7,
                    sensitivity = 0.0025,
                }
                for i = 5, #parts do
                    if parts[i] == "speed" and parts[i + 1] then
                        scene.camera.speed = tonumber(parts[i + 1]) or 7
                    elseif parts[i] == "sensitivity" and parts[i + 1] then
                        scene.camera.sensitivity = tonumber(parts[i + 1]) or 0.0025
                    end
                end

            elseif cmd == "renderer" then
                scene.renderer = {
                    width = tonumber(parts[2]) or 320,
                    height = tonumber(parts[3]) or 240,
                    fov = 200,
                }
                for i = 4, #parts do
                    if parts[i] == "fov" and parts[i + 1] then
                        scene.renderer.fov = tonumber(parts[i + 1]) or 200
                    end
                end

            elseif cmd == "texture" then
                scene.texture = parts[2]

            elseif cmd == "object" then
                local obj = {
                    name = parts[2],
                    model = parts[3],
                    x = tonumber(parts[4]) or 0,
                    y = tonumber(parts[5]) or 0,
                    z = tonumber(parts[6]) or 0,
                    opts = {},
                }
                local i = 7
                while i <= #parts do
                    local opt = parts[i]
                    if opt == "draworder" and parts[i + 1] then
                        obj.opts.draworder = tonumber(parts[i + 1])
                        i = i + 2
                    elseif opt == "scale" and parts[i + 1] then
                        obj.opts.scale = tonumber(parts[i + 1])
                        i = i + 2
                    elseif opt == "rotatex" and parts[i + 1] then
                        obj.opts.rotatex = tonumber(parts[i + 1])
                        i = i + 2
                    elseif opt == "rotatey" and parts[i + 1] then
                        obj.opts.rotatey = tonumber(parts[i + 1])
                        i = i + 2
                    elseif opt == "size" and parts[i + 1] then
                        obj.opts.size = tonumber(parts[i + 1])
                        i = i + 2
                    else
                        i = i + 1
                    end
                end
                scene.objects[#scene.objects + 1] = obj

            elseif cmd == "collider" then
                local col = {
                    x = tonumber(parts[2]) or 0,
                    y = tonumber(parts[3]) or 0,
                    z = tonumber(parts[4]) or 0,
                    halfW = 0.5,
                    halfH = 0.5,
                    halfD = 0.5,
                }
                for i = 5, #parts do
                    if parts[i] == "size" and parts[i + 1] then
                        col.halfW = tonumber(parts[i + 1]) or 0.5
                        if parts[i + 2] and not tonumber(parts[i + 2]) == nil then
                            col.halfH = tonumber(parts[i + 2]) or col.halfW
                            if parts[i + 3] then
                                col.halfD = tonumber(parts[i + 3]) or col.halfW
                            end
                        end
                    end
                end
                scene.colliders[#scene.colliders + 1] = col
            end
        end
    end

    print("[SceneParser] Parsed: " .. filepath .. " (" .. #scene.objects .. " objects)")
    return scene
end

return SceneParser
