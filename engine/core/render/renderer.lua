local ffi = require("ffi")
local gl = require("engine.core.platform.gl")
local math3d = require("engine.core.math")

local M = {}
M.__index = M

local PS1_VERT_SRC = [[
#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUV;

uniform mat4 uMVP;
uniform mat4 uModel;
uniform vec3 uCamPos;
uniform float uSnapSize;

out vec3 vWorldPos;
out vec3 vNormal;
out vec2 vUV;

void main() {
    vec4 worldPos = uModel * vec4(aPos, 1.0);

    vec4 snapPos = uMVP * vec4(aPos, 1.0);
    if (uSnapSize > 0.0) {
        snapPos.xyz = floor(snapPos.xyz * uSnapSize + 0.5) / uSnapSize;
    }

    gl_Position = snapPos;
    vWorldPos = worldPos.xyz;
    vNormal = mat3(uModel) * aNormal;
    vUV = aUV;
}
]]

local PS1_FRAG_SRC = [[
#version 330 core
in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;

uniform vec3 uColor;
uniform vec3 uLightDir;
uniform vec3 uLightColor;
uniform vec3 uAmbient;
uniform float uFogDensity;
uniform vec3 uFogColor;
uniform float uUseTexture;
uniform sampler2D uTexture;
uniform float uTime;
uniform vec3 uCamPos;

out vec4 FragColor;

void main() {
    vec3 norm = normalize(vNormal);
    vec3 lightD = normalize(-uLightDir);
    float diff = max(dot(norm, lightD), 0.0);

    vec3 baseColor = uColor;
    if (uUseTexture > 0.5) {
        vec4 texColor = texture(uTexture, vUV);
        baseColor = texColor.rgb * uColor;
    }

    vec3 lighting = uAmbient + uLightColor * diff;
    vec3 result = baseColor * lighting;

    float dist = length(vWorldPos - uCamPos);
    float fogFactor = exp(-uFogDensity * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    result = mix(uFogColor, result, fogFactor);

    float d = fract(gl_FragCoord.x * 0.5 + gl_FragCoord.y * 0.5);
    if (d < 0.5) {
        result = floor(result * 31.0 + 0.5) / 31.0;
    } else {
        result = floor(result * 31.0 + 0.5) / 31.0;
        result = mix(result, floor(result * 31.0 + 1.0) / 31.0, 0.25);
    }

    FragColor = vec4(result, 1.0);
}
]]

local UI_VERT_SRC = [[
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

local UI_FRAG_SRC = [[
#version 330 core
in vec2 vUV;
in vec3 vColor;
out vec4 FragColor;

void main() {
    FragColor = vec4(vColor, 1.0);
}
]]

local SCREEN_VERT_SRC = [[
#version 330 core
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUV;

out vec2 vUV;

void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
    vUV = aUV;
}
]]

local SCREEN_FRAG_SRC = [[
#version 330 core
in vec2 vUV;
uniform sampler2D uTexture;
out vec4 FragColor;

void main() {
    FragColor = texture(uTexture, vUV);
}
]]

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
    local r = setmetatable({}, M)

    r.internal_width = params.width or 320
    r.internal_height = params.height or 240
    r.fov = math.rad(params.fov or 60)
    r.fog_density = params.fog_density or 0.015
    r.fog_color = params.fog_color or math3d.vec3(0.12, 0.12, 0.15)
    r.ambient_color = params.ambient or math3d.vec3(0.25, 0.25, 0.3)
    r.light_dir = params.light_dir or math3d.vec3(-0.4, -1.0, -0.3)
    r.light_color = params.light_color or math3d.vec3(1.0, 0.95, 0.9)
    r.snap_size = params.snap_size or 40.0

    r.ps1_shader = nil
    r.ui_shader = nil
    r.screen_shader = nil
    r.font_shader = nil

    r.fbo = nil
    r.fbo_texture = nil
    r.fbo_depth = nil

    r.screen_vao = nil
    r.screen_vbo = nil

    r.width = params.window_width or 800
    r.height = params.window_height or 600

    return r
end

function M:init()
    self.ps1_shader = require("engine.core.render.shader").new(PS1_VERT_SRC, PS1_FRAG_SRC)
    self.ui_shader = require("engine.core.render.shader").new(UI_VERT_SRC, UI_FRAG_SRC)
    self.screen_shader = require("engine.core.render.shader").new(SCREEN_VERT_SRC, SCREEN_FRAG_SRC)

    self:create_fbo()
    self:create_screen_quad()
end

function M:create_fbo()
    local fbo = ffi.new("GLuint[1]")
    gl.glGenFramebuffers(1, fbo)
    self.fbo = fbo[0]

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.fbo)

    local tex = ffi.new("GLuint[1]")
    gl.glGenTextures(1, tex)
    self.fbo_texture = tex[0]
    gl.glBindTexture(gl.GL_TEXTURE_2D, self.fbo_texture)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, self.internal_width, self.internal_height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, nil)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE)
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, self.fbo_texture, 0)

    local rbo = ffi.new("GLuint[1]")
    gl.glGenRenderbuffers(1, rbo)
    self.fbo_depth = rbo[0]
    gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, self.fbo_depth)
    gl.glRenderbufferStorage(gl.GL_RENDERBUFFER, gl.GL_DEPTH_COMPONENT16, self.internal_width, self.internal_height)
    gl.glFramebufferRenderbuffer(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_RENDERBUFFER, self.fbo_depth)

    local status = gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER)
    if status ~= gl.GL_FRAMEBUFFER_COMPLETE then
        error("Framebuffer is not complete!")
    end

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
end

function M:create_screen_quad()
    local quad = ffi.new("float[24]", {
        -1, -1, 0, 0,
         1, -1, 1, 0,
         1,  1, 1, 1,
        -1, -1, 0, 0,
         1,  1, 1, 1,
        -1,  1, 0, 1,
    })

    local vao = ffi.new("GLuint[1]")
    local vbo = ffi.new("GLuint[1]")
    gl.glGenVertexArrays(1, vao)
    gl.glGenBuffers(1, vbo)
    self.screen_vao = vao[0]
    self.screen_vbo = vbo[0]

    gl.glBindVertexArray(self.screen_vao)
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.screen_vbo)
    gl.glBufferData(gl.GL_ARRAY_BUFFER, ffi.sizeof(quad), quad, gl.GL_STATIC_DRAW)
    gl.glEnableVertexAttribArray(0)
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, 16, ffi.cast("void*", 0))
    gl.glEnableVertexAttribArray(1)
    gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, 16, ffi.cast("void*", 8))
    gl.glBindVertexArray(0)
end

function M:begin_scene(camera, window_w, window_h)
    self.width = window_w or self.width
    self.height = window_h or self.height

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.fbo)
    gl.glViewport(0, 0, self.internal_width, self.internal_height)
    gl.glClearColor(self.fog_color[0], self.fog_color[1], self.fog_color[2], 1.0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT + gl.GL_DEPTH_BUFFER_BIT)
    gl.glEnable(gl.GL_DEPTH_TEST)
    gl.glDisable(gl.GL_CULL_FACE)

    require("engine.core.render.shader").use(self.ps1_shader)

    local aspect = self.internal_width / self.internal_height
    local proj = camera:get_projection_matrix(aspect)
    local view = camera:get_view_matrix()
    local cam_pos = camera.position

    local gl_proj = ffi.new("float[16]")
    local gl_view = ffi.new("float[16]")
    ffi.copy(gl_proj, proj, 16 * ffi.sizeof("float"))
    ffi.copy(gl_view, view, 16 * ffi.sizeof("float"))

    local function uloc(name)
        local loc = self.ps1_shader.uniforms[name]
        if loc == nil then
            loc = gl.glGetUniformLocation(self.ps1_shader.program, name)
            self.ps1_shader.uniforms[name] = loc
        end
        return loc
    end

    local loc

    loc = uloc("uLightDir"); if loc >= 0 then gl.glUniform3f(loc, self.light_dir[0], self.light_dir[1], self.light_dir[2]) end
    loc = uloc("uAmbient"); if loc >= 0 then gl.glUniform3f(loc, self.ambient_color[0], self.ambient_color[1], self.ambient_color[2]) end
    loc = uloc("uLightColor"); if loc >= 0 then gl.glUniform3f(loc, self.light_color[0], self.light_color[1], self.light_color[2]) end
    loc = uloc("uFogColor"); if loc >= 0 then gl.glUniform3f(loc, self.fog_color[0], self.fog_color[1], self.fog_color[2]) end
    loc = uloc("uFogDensity"); if loc >= 0 then gl.glUniform1f(loc, self.fog_density) end
    loc = uloc("uSnapSize"); if loc >= 0 then gl.glUniform1f(loc, self.snap_size) end
    loc = uloc("uCamPos"); if loc >= 0 then gl.glUniform3f(loc, cam_pos[0], cam_pos[1], cam_pos[2]) end
    loc = uloc("uTime"); if loc >= 0 then gl.glUniform1f(loc, 0.0) end

    self._proj = gl_proj
    self._view = gl_view
    self._cam_pos = cam_pos
    self._time = self._time or 0
end

function M:draw_entity(entity, inherited_texture)
    if not entity.visible then return end
    local active_shader = entity.shader or self.ps1_shader
    local model = entity:get_model_matrix()
    local gl_model = ffi.new("float[16]")

    local gl_model = ffi.new("float[16]")
    ffi.copy(gl_model, model, 16 * ffi.sizeof("float"))

    local mvp = math3d.mat4_multiply(self._proj, math3d.mat4_multiply(self._view, model))
    local gl_mvp = ffi.new("float[16]")
    ffi.copy(gl_mvp, mvp, 16 * ffi.sizeof("float"))

    gl.glUseProgram(active_shader.program)

    local loc = gl.glGetUniformLocation(active_shader.program, "uMVP")
    if loc >= 0 then gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, gl_mvp) end
    loc = gl.glGetUniformLocation(active_shader.program, "uModel")
    if loc >= 0 then gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, gl_model) end

    loc = gl.glGetUniformLocation(active_shader.program, "uColor")
    if loc >= 0 then gl.glUniform3f(loc, entity.color[0], entity.color[1], entity.color[2]) end

    loc = gl.glGetUniformLocation(active_shader.program, "uCamPos")
    if loc >= 0 and self._cam_pos then
        gl.glUniform3f(loc, self._cam_pos[0], self._cam_pos[1], self._cam_pos[2])
    end

    loc = gl.glGetUniformLocation(active_shader.program, "uTime")
    if loc >= 0 and self._time then gl.glUniform1f(loc, self._time) end

    loc = gl.glGetUniformLocation(active_shader.program, "uLightDir")
    if loc >= 0 then gl.glUniform3f(loc, self.light_dir[0], self.light_dir[1], self.light_dir[2]) end
    loc = gl.glGetUniformLocation(active_shader.program, "uAmbient")
    if loc >= 0 then gl.glUniform3f(loc, self.ambient_color[0], self.ambient_color[1], self.ambient_color[2]) end
    loc = gl.glGetUniformLocation(active_shader.program, "uLightColor")
    if loc >= 0 then gl.glUniform3f(loc, self.light_color[0], self.light_color[1], self.light_color[2]) end
    loc = gl.glGetUniformLocation(active_shader.program, "uFogDensity")
    if loc >= 0 then gl.glUniform1f(loc, self.fog_density) end
    loc = gl.glGetUniformLocation(active_shader.program, "uFogColor")
    if loc >= 0 then gl.glUniform3f(loc, self.fog_color[0], self.fog_color[1], self.fog_color[2]) end
    loc = gl.glGetUniformLocation(active_shader.program, "uSnapSize")
    if loc >= 0 then gl.glUniform1f(loc, self.snap_size) end

    for uname, uval in pairs(entity.shader_uniforms or {}) do
        loc = gl.glGetUniformLocation(active_shader.program, uname)
        if loc >= 0 then
            if type(uval) == "table" and #uval == 3 then
                gl.glUniform3f(loc, uval[1], uval[2], uval[3])
            elseif type(uval) == "number" then
                gl.glUniform1f(loc, uval)
            end
        end
    end

    local active_tex = entity.texture or inherited_texture
    if active_tex then
        loc = gl.glGetUniformLocation(active_shader.program, "uUseTexture")
        if loc >= 0 then gl.glUniform1f(loc, 1.0) end
        gl.glActiveTexture(gl.GL_TEXTURE0)
        gl.glBindTexture(gl.GL_TEXTURE_2D, active_tex.id)
        loc = gl.glGetUniformLocation(active_shader.program, "uTexture")
        if loc >= 0 then gl.glUniform1i(loc, 0) end
    else
        loc = gl.glGetUniformLocation(active_shader.program, "uUseTexture")
        if loc >= 0 then gl.glUniform1f(loc, 0.0) end
    end

    for _, m in ipairs(entity.meshes) do
        require("engine.core.render.mesh").draw(m)
    end

    if active_tex then
        gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
    end

    for _, child in ipairs(entity.children) do
        self:draw_entity(child, active_tex)
    end
end

function M:end_scene()
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
    gl.glViewport(0, 0, self.width, self.height)
    gl.glDisable(gl.GL_DEPTH_TEST)
    gl.glDisable(gl.GL_CULL_FACE)
    gl.glClearColor(0, 0, 0, 1)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)

    gl.glActiveTexture(gl.GL_TEXTURE0)
    gl.glBindTexture(gl.GL_TEXTURE_2D, self.fbo_texture)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)

    gl.glUseProgram(self.screen_shader.program)

    local loc = gl.glGetUniformLocation(self.screen_shader.program, "uTexture")
    gl.glUniform1i(loc, 0)

    gl.glBindVertexArray(self.screen_vao)
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6)
    gl.glBindVertexArray(0)

    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
end

function M:set_internal_resolution(w, h)
    self.internal_width = w
    self.internal_height = h
    if self.fbo then
        self:delete_fbo()
        self:create_fbo()
    end
end

function M:delete_fbo()
    if self.fbo then
        gl.glDeleteFramebuffers(1, ffi.new("GLuint[1]", self.fbo))
        gl.glDeleteTextures(1, ffi.new("GLuint[1]", self.fbo_texture))
        gl.glDeleteRenderbuffers(1, ffi.new("GLuint[1]", self.fbo_depth))
        self.fbo = nil
        self.fbo_texture = nil
        self.fbo_depth = nil
    end
end

function M:delete()
    self:delete_fbo()
    if self.screen_vao then gl.glDeleteVertexArrays(1, ffi.new("GLuint[1]", self.screen_vao)) end
    if self.screen_vbo then gl.glDeleteBuffers(1, ffi.new("GLuint[1]", self.screen_vbo)) end
end

return M
