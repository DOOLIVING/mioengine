local ffi = require("ffi")
local gl = require("engine.core.platform.gl")
local math3d = require("engine.core.math")

local M = {}
M.__index = M

local QUAD_VERT_SRC = [[
#version 330 core
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUV;
layout(location = 2) in vec3 aColor;

uniform mat4 uProjection;

out vec2 vUV;
out vec3 vColor;

void main() {
    gl_Position = uProjection * vec4(aPos, 0.0, 1.0);
    vUV = aUV;
    vColor = aColor;
}
]]

local QUAD_FRAG_SRC = [[
#version 330 core
in vec2 vUV;
in vec3 vColor;
out vec4 FragColor;

void main() {
    FragColor = vec4(vColor, 1.0);
}
]]

function M.new()
    local ui = setmetatable({}, M)
    ui.shader = require("engine.core.render.shader").new(QUAD_VERT_SRC, QUAD_FRAG_SRC)
    ui.vao = nil
    ui.vbo = nil
    ui.max_quads = 4096
    ui.quad_data = ffi.new("float[?]", ui.max_quads * 6 * 7)
    ui.quad_count = 0
    ui.window_w = 800
    ui.window_h = 600

    ui.font = nil
    ui.font_small = nil

    ui.mouse_x = 0
    ui.mouse_y = 0
    ui.mouse_down = false
    ui.mouse_pressed = false
    ui.mouse_released = false
    ui.widgets = {}
    ui._next_id = 1

    local vao = ffi.new("GLuint[1]")
    local vbo = ffi.new("GLuint[1]")
    gl.glGenVertexArrays(1, vao)
    gl.glGenBuffers(1, vbo)
    ui.vao = vao[0]
    ui.vbo = vbo[0]

    gl.glBindVertexArray(ui.vao)
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, ui.vbo)
    gl.glBufferData(gl.GL_ARRAY_BUFFER, ffi.sizeof(ui.quad_data), nil, gl.GL_DYNAMIC_DRAW)

    local stride = 7 * 4
    gl.glEnableVertexAttribArray(0)
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", 0))
    gl.glEnableVertexAttribArray(1)
    gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", 8))
    gl.glEnableVertexAttribArray(2)
    gl.glVertexAttribPointer(2, 3, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", 16))
    gl.glBindVertexArray(0)

    return ui
end

function M:set_font(font, font_small)
    self.font = font
    self.font_small = font_small or font
end

function M:set_mouse_state(x, y, down, pressed, released)
    self.mouse_x = x or 0
    self.mouse_y = y or 0
    self.mouse_down = down or false
    self.mouse_pressed = pressed or false
    self.mouse_released = released or false
end

function M:begin(window_w, window_h)
    self.window_w = window_w or self.window_w
    self.window_h = window_h or self.window_h
    self.quad_count = 0
    self.widgets = {}

    gl.glEnable(gl.GL_BLEND)
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
    gl.glDisable(gl.GL_DEPTH_TEST)

    require("engine.core.render.shader").use(self.shader)
    local proj = math3d.mat4_ortho(0, self.window_w, self.window_h, 0, -1, 1)
    local gl_proj = ffi.new("float[16]")
    ffi.copy(gl_proj, proj, 16 * ffi.sizeof("float"))
    local loc = gl.glGetUniformLocation(self.shader.program, "uProjection")
    gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, gl_proj)

    self._proj = gl_proj

    if self.font then
        self.font:set_projection(gl_proj)
    end
    if self.font_small and self.font_small ~= self.font then
        self.font_small:set_projection(gl_proj)
    end
end

function M:draw_rect(x, y, w, h, r, g, b)
    local i = self.quad_count * 6 * 7
    if self.quad_count >= self.max_quads then return end

    local x1, y1, x2, y2 = x, y, x + w, y + h
    local verts = {
        x1, y1, 0, 0, r, g, b,
        x2, y1, 1, 0, r, g, b,
        x2, y2, 1, 1, r, g, b,
        x1, y1, 0, 0, r, g, b,
        x2, y2, 1, 1, r, g, b,
        x1, y2, 0, 1, r, g, b,
    }

    for _, v in ipairs(verts) do
        self.quad_data[i] = v
        i = i + 1
    end
    self.quad_count = self.quad_count + 1
end

function M:draw_rect_alpha(x, y, w, h, r, g, b, a)
    if a and a < 1.0 then
        gl.glEnable(gl.GL_BLEND)
        gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
    end
    self:draw_rect(x, y, w, h, r, g, b)
end

function M:flush()
    if self.quad_count == 0 then return end

    require("engine.core.render.shader").use(self.shader)

    local loc = gl.glGetUniformLocation(self.shader.program, "uProjection")
    if self._proj then
        gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, self._proj)
    end

    gl.glBindVertexArray(self.vao)
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo)
    gl.glBufferSubData(gl.GL_ARRAY_BUFFER, 0, self.quad_count * 6 * 7 * 4, self.quad_data)
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, self.quad_count * 6)
    gl.glBindVertexArray(0)

    gl.glDisable(gl.GL_BLEND)
    gl.glEnable(gl.GL_DEPTH_TEST)
end

function M:draw_text(text, x, y, size, r, g, b, a, align)
    if not self.font or not text or text == "" then return end
    local scale = (size or 12) / self.font.pixel_height
    self.font:draw_text(text, x, y, scale, r or 1, g or 1, b or 1, a or 1, align)
end

function M:draw_circle(x, y, radius, r, g, b)
    local segments = 16
    for i = 0, segments - 1 do
        local a1 = (i / segments) * 6.28318
        local a2 = ((i + 1) / segments) * 6.28318
        local x1 = x + math.cos(a1) * radius
        local y1 = y + math.sin(a1) * radius
        local x2 = x + math.cos(a2) * radius
        local y2 = y + math.sin(a2) * radius
        self:draw_rect(x1, y1, math.max(math.abs(x2 - x1), 1), math.max(math.abs(y2 - y1), 1), r, g, b)
    end
end

function M:draw_line(x1, y1, x2, y2, r, g, b, a, width)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    local w = width or 1
    if math.abs(dx) > math.abs(dy) then
        self:draw_rect(x1, y1, len, w, r, g, b)
    else
        self:draw_rect(x1, y1, w, len, r, g, b)
    end
end

function M:delete()
    if self.vao then gl.glDeleteVertexArrays(1, ffi.new("GLuint[1]", self.vao)) end
    if self.vbo then gl.glDeleteBuffers(1, ffi.new("GLuint[1]", self.vbo)) end
end

function M:_point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function M:ui_button(id, x, y, w, h, label, opts)
    opts = opts or {}
    local font = self.font_small or self.font
    local scale = (opts.font_size or 14) / (font and font.pixel_height or 16)
    local text_color = opts.text_color or {1, 1, 1}
    local bg_color = opts.bg_color or {0.25, 0.25, 0.3}
    local hover_color = opts.hover_color or {0.35, 0.35, 0.4}
    local press_color = opts.press_color or {0.15, 0.15, 0.2}
    local label_align = opts.align or "center"

    local hover = self:_point_in_rect(self.mouse_x, self.mouse_y, x, y, w, h)
    local clicked = false

    local color = bg_color
    if hover and self.mouse_down then
        color = press_color
        if self.mouse_pressed then
            clicked = true
        end
    elseif hover then
        color = hover_color
    end

    self:draw_rect(x, y, w, h, color[1], color[2], color[3])
    self:draw_rect(x, y, w, 1, color[1] * 1.2, color[2] * 1.2, color[3] * 1.2)

    if font and label then
        local text_scale = (opts.font_size or 14) / font.pixel_height
        local text_w = font:get_text_width(label, text_scale)
        local tx = x + (w - text_w) / 2
        local ty = y + (h - font.pixel_height * text_scale) / 2
        font:draw_text(label, tx, ty, text_scale, text_color[1], text_color[2], text_color[3], 1.0)
    end

    return clicked
end

function M:ui_checkbox(id, x, y, checked, opts)
    opts = opts or {}
    local box_size = opts.size or 18
    local label = opts.label or ""
    local font = self.font_small or self.font
    local text_color = opts.text_color or {1, 1, 1}
    local bg_color = opts.bg_color or {0.25, 0.25, 0.3}
    local check_color = opts.check_color or {0.3, 0.7, 0.3}

    local result = checked

    local hover = self:_point_in_rect(self.mouse_x, self.mouse_y, x, y, box_size, box_size)
    if hover and self.mouse_pressed then
        result = not checked
    end

    self:draw_rect(x, y, box_size, box_size, bg_color[1], bg_color[2], bg_color[3])

    if result then
        local m = 3
        self:draw_rect(x + m, y + m, box_size - m * 2, box_size - m * 2,
            check_color[1], check_color[2], check_color[3])
    end

    if font and label ~= "" then
        local text_scale = (opts.font_size or 14) / font.pixel_height
        font:draw_text(label, x + box_size + 6, y + (box_size - font.pixel_height * text_scale) / 2,
            text_scale, text_color[1], text_color[2], text_color[3], 1.0)
    end

    return result
end

function M:ui_slider(id, x, y, w, h, value, min_val, max_val, opts)
    opts = opts or {}
    local font = self.font_small or self.font
    local text_color = opts.text_color or {1, 1, 1}
    local bg_color = opts.bg_color or {0.2, 0.2, 0.25}
    local fill_color = opts.fill_color or {0.3, 0.5, 0.8}
    local handle_color = opts.handle_color or {0.9, 0.9, 0.9}

    min_val = min_val or 0
    max_val = max_val or 1
    local range = max_val - min_val
    if range == 0 then range = 1 end

    local result = value
    local bar_h = math.max(h * 0.4, 4)
    local bar_y = y + (h - bar_h) / 2
    local handle_w = math.max(h * 0.6, 10)
    local handle_h = h

    self:draw_rect(x, bar_y, w, bar_h, bg_color[1], bg_color[2], bg_color[3])

    local t = (value - min_val) / range
    t = math.max(0, math.min(1, t))
    local fill_w = w * t
    self:draw_rect(x, bar_y, fill_w, bar_h, fill_color[1], fill_color[2], fill_color[3])

    local handle_x = x + fill_w - handle_w / 2
    local handle_y = y + (h - handle_h) / 2
    self:draw_rect(handle_x, handle_y, handle_w, handle_h, handle_color[1], handle_color[2], handle_color[3])

    if font and opts.label then
        local text_scale = (opts.font_size or 12) / font.pixel_height
        local val_str = string.format("%.2f", value)
        font:draw_text(opts.label .. ": " .. val_str, x, y - h * 0.3, text_scale,
            text_color[1], text_color[2], text_color[3], 1.0)
    end

    local dragging = false
    local hover = self:_point_in_rect(self.mouse_x, self.mouse_y, x, y, w, h)
    if hover and self.mouse_down then
        dragging = true
    end

    if dragging or (self.mouse_down and self:_point_in_rect(self.mouse_x, self.mouse_y, handle_x, handle_y, handle_w, handle_h)) then
        local mx = math.max(x, math.min(x + w, self.mouse_x))
        local new_t = (mx - x) / w
        result = min_val + new_t * range
    end

    return result
end

function M:ui_label(id, x, y, text, opts)
    opts = opts or {}
    local font = self.font_small or self.font
    if not font then return end

    local text_scale = (opts.font_size or 14) / font.pixel_height
    local text_color = opts.color or opts.text_color or {1, 1, 1}
    local align = opts.align or "left"

    local text_w = font:get_text_width(text, text_scale)
    local tx = x
    if align == "center" then
        tx = x - text_w / 2
    elseif align == "right" then
        tx = x - text_w
    end

    font:draw_text(text, tx, y, text_scale, text_color[1], text_color[2], text_color[3], 1.0)
end

return M
