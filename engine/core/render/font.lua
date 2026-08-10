local ffi = require("ffi")
local gl = require("engine.core.platform.gl")

local M = {}

ffi.cdef[[
typedef struct {
    unsigned short x0,y0,x1,y1;
    float xoff,yoff,xadvance;
} stbtt_bakedchar;

typedef struct {
    float x0,y0,s0,t0;
    float x1,y1,s1,t1;
} stbtt_aligned_quad;

int stbtt_BakeFontBitmap(const unsigned char *data, int offset,
                         float pixel_height,
                         unsigned char *pixels, int pw, int ph,
                         int first_char, int num_chars,
                         stbtt_bakedchar *chardata);

void stbtt_GetBakedQuad(const stbtt_bakedchar *chardata, int pw, int ph,
                        int char_index, float *xpos, float *ypos,
                        stbtt_aligned_quad *q, int opengl_fillrule);
]]

local Platform = require("engine.core.platform.platform")
local stbtt = Platform.try_load("stb_truetype")
if not stbtt then
    error("[Font] Failed to load stb_truetype library")
end

local ATLAS_W = 512
local ATLAS_H = 512
local FIRST_CHAR = 32
local NUM_CHARS = 96

local FONT_VERT_SRC = [[
#version 330 core
layout(location = 0) in vec4 aVertex;
uniform mat4 uProjection;
out vec2 vTexCoord;
void main() {
    gl_Position = uProjection * vec4(aVertex.xy, 0.0, 1.0);
    vTexCoord = aVertex.zw;
}
]]

local FONT_FRAG_SRC = [[
#version 330 core
in vec2 vTexCoord;
uniform sampler2D uTexture;
uniform vec3 uColor;
out vec4 FragColor;
void main() {
    float a = texture(uTexture, vTexCoord).r;
    FragColor = vec4(uColor, a);
}
]]

function M.new(params)
    params = params or {}
    local font = setmetatable({}, { __index = M })

    font.pixel_height = params.pixel_height or 32.0
    font.color = params.color or {1.0, 1.0, 1.0}
    font.atlas_w = ATLAS_W
    font.atlas_h = ATLAS_H
    font.first_char = FIRST_CHAR
    font.num_chars = NUM_CHARS

    font.cdata = ffi.new("stbtt_bakedchar[?]", NUM_CHARS)
    font.atlas_data = ffi.new("unsigned char[?]", ATLAS_W * ATLAS_H)
    font.atlas_tex = nil
    font.shader = nil
    font.vao = nil
    font.vbo = nil
    font.max_vertices = 4096

    return font
end

function M:load_from_file(path)
    local f = io.open(path, "rb")
    if not f then error("[Font] Cannot open font file: " .. path) end
    local data = f:read("*a")
    f:close()

    local buf = ffi.new("unsigned char[?]", #data)
    ffi.copy(buf, data, #data)

    local result = stbtt.stbtt_BakeFontBitmap(
        buf, 0,
        self.pixel_height,
        self.atlas_data, ATLAS_W, ATLAS_H,
        FIRST_CHAR, NUM_CHARS,
        self.cdata
    )

    if result <= 0 then
        error("[Font] Failed to bake font bitmap, result=" .. tostring(result))
    end

    local tex_id = ffi.new("GLuint[1]")
    gl.glGenTextures(1, tex_id)
    self.atlas_tex = tex_id[0]

    gl.glBindTexture(gl.GL_TEXTURE_2D, self.atlas_tex)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_R8, ATLAS_W, ATLAS_H, 0, gl.GL_RED, gl.GL_UNSIGNED_BYTE, self.atlas_data)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)

    local shader_mod = require("engine.core.render.shader")
    self.shader = shader_mod.new(FONT_VERT_SRC, FONT_FRAG_SRC)

    local vao = ffi.new("GLuint[1]")
    local vbo = ffi.new("GLuint[1]")
    gl.glGenVertexArrays(1, vao)
    gl.glGenBuffers(1, vbo)
    self.vao = vao[0]
    self.vbo = vbo[0]

    gl.glBindVertexArray(self.vao)
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo)
    gl.glBufferData(gl.GL_ARRAY_BUFFER, self.max_vertices * 4 * ffi.sizeof("float"), nil, gl.GL_DYNAMIC_DRAW)

    local stride = 4 * ffi.sizeof("float")
    gl.glEnableVertexAttribArray(0)
    gl.glVertexAttribPointer(0, 4, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", 0))
    gl.glBindVertexArray(0)

    self.vertex_buffer = ffi.new("float[?]", self.max_vertices * 4)

    return true
end

function M:measure_text(text, scale)
    scale = scale or 1.0
    local base_x = ffi.new("float[1]", 0)
    local base_y = ffi.new("float[1]", 0)
    for i = 1, #text do
        local ch = string.byte(text, i)
        if ch >= FIRST_CHAR and ch < FIRST_CHAR + NUM_CHARS then
            local char_idx = ch - FIRST_CHAR
            local q = ffi.new("stbtt_aligned_quad")
            stbtt.stbtt_GetBakedQuad(self.cdata, ATLAS_W, ATLAS_H, char_idx, base_x, base_y, q, 1)
        else
            base_x[0] = base_x[0] + self.pixel_height * 0.5 * scale
        end
    end
    return base_x[0] * scale, self.pixel_height * scale
end

function M:get_text_width(text, scale)
    scale = scale or 1.0
    local x = 0
    for i = 1, #text do
        local ch = string.byte(text, i)
        if ch >= FIRST_CHAR and ch < FIRST_CHAR + NUM_CHARS then
            local char_idx = ch - FIRST_CHAR
            local bc = self.cdata[char_idx]
            x = x + bc.xadvance * scale
        else
            x = x + self.pixel_height * 0.5 * scale
        end
    end
    return x
end

function M:get_line_height(scale)
    scale = scale or 1.0
    return self.pixel_height * scale
end

function M:draw_text(text, x, y, scale, r, g, b, a, align)
    if not text or text == "" then return end
    if not self.shader or not self.atlas_tex then return end

    scale = scale or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    a = a or 1.0

    local text_w = self:get_text_width(text, scale)

    if align == "center" then
        x = x - text_w / 2
    elseif align == "right" then
        x = x - text_w
    end

    local vertex_count = 0
    local cur_x = ffi.new("float[1]", x)
    local cur_y = ffi.new("float[1]", y)
    local max_verts = self.max_vertices * 4
    local buf = self.vertex_buffer

    for i = 1, #text do
        local ch = string.byte(text, i)

        if ch == 10 then
            cur_x[0] = x
            cur_y[0] = cur_y[0] + self.pixel_height * scale
        elseif ch >= FIRST_CHAR and ch < FIRST_CHAR + NUM_CHARS then
            local char_idx = ch - FIRST_CHAR
            local q = ffi.new("stbtt_aligned_quad")
            stbtt.stbtt_GetBakedQuad(self.cdata, ATLAS_W, ATLAS_H, char_idx, cur_x, cur_y, q, 1)

            local base = vertex_count * 4
            if base + 24 <= max_verts then
                buf[base + 0]  = q.x0; buf[base + 1]  = q.y0; buf[base + 2]  = q.s0; buf[base + 3]  = q.t0
                buf[base + 4]  = q.x1; buf[base + 5]  = q.y0; buf[base + 6]  = q.s1; buf[base + 7]  = q.t0
                buf[base + 8]  = q.x1; buf[base + 9]  = q.y1; buf[base + 10] = q.s1; buf[base + 11] = q.t1
                buf[base + 12] = q.x0; buf[base + 13] = q.y0; buf[base + 14] = q.s0; buf[base + 15] = q.t0
                buf[base + 16] = q.x1; buf[base + 17] = q.y1; buf[base + 18] = q.s1; buf[base + 19] = q.t1
                buf[base + 20] = q.x0; buf[base + 21] = q.y1; buf[base + 22] = q.s0; buf[base + 23] = q.t1
                vertex_count = vertex_count + 6
            end
        else
            cur_x[0] = cur_x[0] + self.pixel_height * 0.5 * scale
        end
    end

    if vertex_count == 0 then return end

    if not self._projection then
        print("[Font] WARNING: no projection matrix set!")
        return
    end

    gl.glEnable(gl.GL_BLEND)
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)

    gl.glUseProgram(self.shader.program)

    local shader_mod = require("engine.core.render.shader")
    local loc = gl.glGetUniformLocation(self.shader.program, "uProjection")
    if self._projection then
        gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, self._projection)
    end

    loc = gl.glGetUniformLocation(self.shader.program, "uTexture")
    gl.glUniform1i(loc, 0)
    gl.glActiveTexture(gl.GL_TEXTURE0)
    gl.glBindTexture(gl.GL_TEXTURE_2D, self.atlas_tex)

    loc = gl.glGetUniformLocation(self.shader.program, "uColor")
    gl.glUniform3f(loc, r, g, b)

    gl.glBindVertexArray(self.vao)
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo)
    gl.glBufferSubData(gl.GL_ARRAY_BUFFER, 0, vertex_count * 4 * ffi.sizeof("float"), buf)
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, vertex_count)
    gl.glBindVertexArray(0)

    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
end

function M:set_projection(proj_matrix)
    local gl_proj = ffi.new("float[16]")
    ffi.copy(gl_proj, proj_matrix, 16 * ffi.sizeof("float"))
    self._projection = gl_proj
end

function M:delete()
    if self.atlas_tex then
        gl.glDeleteTextures(1, ffi.new("GLuint[1]", self.atlas_tex))
    end
    if self.vao then gl.glDeleteVertexArrays(1, ffi.new("GLuint[1]", self.vao)) end
    if self.vbo then gl.glDeleteBuffers(1, ffi.new("GLuint[1]", self.vbo)) end
end

return M
