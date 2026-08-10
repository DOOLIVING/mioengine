local ffi = require("ffi")

local M = {}

M.os = ffi.os       -- "Windows", "Linux", "OSX"
M.arch = ffi.arch   -- "x86", "x86_64", "arm"

function M.lib_ext()
    if M.os == "Windows" then return "dll"
    elseif M.os == "OSX" then return "dylib"
    else return "so" end
end

function M.lib_prefix()
    if M.os == "Windows" then return ""
    else return "lib" end
end

function M.lib_path(name)
    return M.lib_prefix() .. name .. "." .. M.lib_ext()
end

function M.try_load(name, fallback_name)
    local paths = {}

    local ext = M.lib_ext()
    local prefix = M.lib_prefix()

    if M.os == "Windows" then
        paths[#paths+1] = "deps/" .. name .. ".dll"
        paths[#paths+1] = "./deps/" .. name .. ".dll"
        paths[#paths+1] = name
        paths[#paths+1] = prefix .. name .. "." .. ext
    elseif M.os == "OSX" then
        paths[#paths+1] = "deps/" .. prefix .. name .. ".dylib"
        paths[#paths+1] = "./deps/" .. prefix .. name .. ".dylib"
        if name == "glfw" then
            paths[#paths+1] = "/opt/homebrew/lib/" .. prefix .. name .. ".dylib"
            paths[#paths+1] = "/usr/local/lib/" .. prefix .. name .. ".dylib"
        elseif name == "assimp" then
            paths[#paths+1] = "/opt/homebrew/lib/" .. prefix .. name .. ".dylib"
            paths[#paths+1] = "/usr/local/lib/" .. prefix .. name .. ".dylib"
        end
        paths[#paths+1] = name
    else
        paths[#paths+1] = "deps/" .. prefix .. name .. ".so"
        paths[#paths+1] = "./deps/" .. prefix .. name .. ".so"
        paths[#paths+1] = name
    end

    for _, p in ipairs(paths) do
        local ok, lib = pcall(ffi.load, p)
        if ok then return lib end
    end

    if fallback_name then
        local ok, lib = pcall(ffi.load, fallback_name)
        if ok then return lib end
    end

    return nil
end

function M.find_font()
    local ffi = require("ffi")
    local io = io

    local candidates = {}

    if M.os == "Windows" then
        local windir = os.getenv("WINDIR") or "C:\\Windows"
        local sysdir = windir .. "\\Fonts"
        candidates[#candidates+1] = sysdir .. "\\arial.ttf"
        candidates[#candidates+1] = sysdir .. "\\Arial.ttf"
        candidates[#candidates+1] = sysdir .. "\\segoeui.ttf"
        candidates[#candidates+1] = sysdir .. "\\tahoma.ttf"
        candidates[#candidates+1] = sysdir .. "\\verdana.ttf"
        candidates[#candidates+1] = sysdir .. "\\times.ttf"
        candidates[#candidates+1] = sysdir .. "\\cour.ttf"
        local localapp = os.getenv("LOCALAPPDATA") or ""
        if localapp ~= "" then
            candidates[#candidates+1] = localapp .. "\\Microsoft\\Windows\\Fonts\\arial.ttf"
        end
    elseif M.os == "OSX" then
        candidates[#candidates+1] = "/System/Library/Fonts/Supplemental/Arial.ttf"
        candidates[#candidates+1] = "/System/Library/Fonts/Helvetica.ttc"
        candidates[#candidates+1] = "/System/Library/Fonts/SFNSMono.ttf"
        candidates[#candidates+1] = "/Library/Fonts/Arial.ttf"
        candidates[#candidates+1] = "/System/Library/Fonts/Supplemental/Courier New.ttf"
    else
        candidates[#candidates+1] = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
        candidates[#candidates+1] = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
        candidates[#candidates+1] = "/usr/share/fonts/TTF/DejaVuSans.ttf"
        candidates[#candidates+1] = "/usr/share/fonts/truetype/freefont/FreeSans.ttf"
    end

    for _, path in ipairs(candidates) do
        local f = io.open(path, "rb")
        if f then
            f:close()
            return path
        end
    end

    return nil
end

return M
