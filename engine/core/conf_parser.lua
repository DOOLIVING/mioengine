local M = {}

function M.parse(path)
    local f = io.open(path, "r")
    if not f then error("Cannot open config: " .. path) end
    local content = f:read("*a")
    f:close()

    local config = {
        window = { title = "MioEngine", width = 800, height = 600, resizable = true, minwidth = 640, minheight = 480 },
        scenes = {},
        default_scene = "",
        renderer = { width = 320, height = 240, fov = 60, snap_size = 40, fog_density = 0.015 },
        physics = { gravity_x = 0, gravity_y = -9.81, gravity_z = 0 },
        camera = { x = 0, y = 1.5, z = 5, speed = 5, sensitivity = 2, fov = 60 },
    }

    local current_section = nil
    local current_scene = nil

    for line in content:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == "" or trimmed:sub(1, 2) == "//" then
        elseif trimmed:match("^%[(.+)%]$") then
            current_section = trimmed:match("^%[(.+)%]$")
            if current_section:match("^scene:(.+)$") then
                current_scene = {
                    name = current_section:match("^scene:(.+)$"),
                    script = "",
                }
                config.scenes[#config.scenes+1] = current_scene
                current_section = "scene"
            end
        elseif trimmed:match("^([^=]+)=(.+)$") then
            local key, val = trimmed:match("^([^=]+)=(.+)$")
            key = key:match("^%s*(.-)%s*$")
            val = val:match("^%s*(.-)%s*$")

            local num = tonumber(val)
            if val == "true" then val = true
            elseif val == "false" then val = false
            elseif num then val = num
            end

            if current_section == "window" then
                config.window[key] = val
            elseif current_section == "renderer" then
                config.renderer[key] = val
            elseif current_section == "physics" then
                config.physics[key] = val
            elseif current_section == "camera" then
                config.camera[key] = val
            elseif current_section == "scene" and current_scene then
                current_scene[key] = val
            elseif current_section == nil then
                if key == "default_scene" then
                    config.default_scene = val
                end
            end
        end
    end

    return config
end

return M
