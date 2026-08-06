local ConfigParser = {}

function ConfigParser.parse(filepath)
    local config = {
        window = {
            title = "mioengine",
            width = 1024,
            height = 768,
            resizable = true,
            minwidth = 640,
            minheight = 480,
        },
        default_scene = "",
        scenes = {},
    }

    local content = love.filesystem.read(filepath)
    if not content then
        print("[ConfigParser] Cannot load: " .. filepath)
        return config
    end

    local configDir = filepath:match("^(.-)[^/\\]*$")
    if configDir == "" then configDir = "" else configDir = configDir end

    local raw = {}
    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            local key, value = line:match("^(%S+)%s*=%s*(.+)$")
            if key and value then
                raw[#raw + 1] = { key = key, value = value }
            end
        end
    end

    for _, entry in ipairs(raw) do
        local k, v = entry.key, entry.value

        if k == "window_title" then
            config.window.title = v
        elseif k == "window_width" then
            config.window.width = tonumber(v) or 1024
        elseif k == "window_height" then
            config.window.height = tonumber(v) or 768
        elseif k == "window_resizable" then
            config.window.resizable = (v == "true")
        elseif k == "window_minwidth" then
            config.window.minwidth = tonumber(v) or 640
        elseif k == "window_minheight" then
            config.window.minheight = tonumber(v) or 480
        elseif k == "default_scene" then
            config.default_scene = v
        elseif k == "scene" then
            local name, script = v:match("^(%S+)%s+(.+)$")
            if name and script then
                if not script:match("^/") and not script:match("^%a+:") then
                    script = configDir .. script
                end
                config.scenes[#config.scenes + 1] = {
                    name = name,
                    script = script,
                }
            end
        end
    end

    print("[ConfigParser] Loaded: " .. #config.scenes .. " scenes")
    return config
end

return ConfigParser
