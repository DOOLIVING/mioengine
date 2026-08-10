local ffi = require("ffi")
local gl = require("engine.core.platform.gl")

local Platform = require("engine.core.platform.platform")
local stb = Platform.try_load("stb_image")

ffi.cdef[[
unsigned char* stbi_load(const char* filename, int* x, int* y, int* channels_in_file, int desired_channels);
void stbi_image_free(void* retval_from_stbi_load);
unsigned char* stbi_load_from_memory(const unsigned char* buffer, int len, int* x, int* y, int* channels_in_file, int desired_channels);
]]

local M = {}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function M.load(path, params)
    params = params or {}
    local w = ffi.new("int[1]")
    local h = ffi.new("int[1]")
    local ch = ffi.new("int[1]")
    local desired = params.channels or 4

    local data = stb.stbi_load(path, w, h, ch, desired)
    if data == nil then
        error("Failed to load texture: " .. path)
    end

    local tex_id = ffi.new("GLuint[1]")
    gl.glGenTextures(1, tex_id)
    gl.glBindTexture(gl.GL_TEXTURE_2D, tex_id[0])

    local format = gl.GL_RGBA
    if desired == 3 then format = gl.GL_RGB end

    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, format, w[0], h[0], 0, format, gl.GL_UNSIGNED_BYTE, data)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_REPEAT)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_REPEAT)

    local filter = params.filter or "nearest"
    if filter == "linear" then
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    else
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)
    end

    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
    stb.stbi_image_free(data)

    return {
        id = tex_id[0],
        width = w[0],
        height = h[0],
        path = path,
    }
end

function M.bind(tex, unit)
    unit = unit or 0
    gl.glActiveTexture(gl.GL_TEXTURE0 + unit)
    gl.glBindTexture(gl.GL_TEXTURE_2D, tex.id)
end

function M.unbind()
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
end

function M.delete(tex)
    local id = ffi.new("GLuint[1]", tex.id)
    gl.glDeleteTextures(1, id)
end

return M
