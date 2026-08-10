local ffi = require("ffi")

ffi.cdef[[
typedef uint32_t  GLenum;
typedef uint8_t   GLboolean;
typedef uint32_t  GLbitfield;
typedef void      GLvoid;
typedef int32_t   GLint;
typedef uint32_t  GLuint;
typedef int32_t   GLsizei;
typedef float     GLfloat;
typedef double    GLdouble;
typedef uint8_t   GLubyte;
typedef int8_t    GLchar;
typedef intptr_t  GLintptr;
typedef size_t    GLsizei64;

typedef void  (*PFNGLCLEARPROC)(GLbitfield mask);
typedef void  (*PFNGLCLEARCOLORPROC)(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
typedef void  (*PFNGLVIEWPORTPROC)(GLint x, GLint y, GLsizei w, GLsizei h);
typedef void  (*PFNGLENABLEPROC)(GLenum cap);
typedef void  (*PFNGLDISABLEPROC)(GLenum cap);
typedef void  (*PFNGLDEPTHFUNCPROC)(GLenum func);
typedef void  (*PFNGLBLENDFUNCPROC)(GLenum sfactor, GLenum dfactor);
typedef void  (*PFNGLCULLFACEPROC)(GLenum mode);
typedef void  (*PFNGLFRONTFACEPROC)(GLenum mode);
typedef void  (*PFNGLPOLYGONMODEPROC)(GLenum face, GLenum mode);
typedef const GLubyte* (*PFNGLGETSTRINGPROC)(GLenum name);
typedef GLenum (*PFNGLGETERRORPROC)(void);
typedef void (*PFNGLGENBUFFERSPROC)(GLsizei n, GLuint* buffers);
typedef void (*PFNGLBINDBUFFERPROC)(GLenum target, GLuint buffer);
typedef void (*PFNGLBUFFERDATAPROC)(GLenum target, GLsizei size, const void* data, GLenum usage);
typedef void (*PFNGLDELETEBUFFERSPROC)(GLsizei n, const GLuint* buffers);
typedef void (*PFNGLGENVERTEXARRAYSPROC)(GLsizei n, GLuint* arrays);
typedef void (*PFNGLBINDVERTEXARRAYPROC)(GLuint array);
typedef void (*PFNGLDELETEVERTEXARRAYSPROC)(GLsizei n, const GLuint* arrays);
typedef void (*PFNGLENABLEVERTEXATTRIBARRAYPROC)(GLuint index);
typedef void (*PFNGLDISABLEVERTEXATTRIBARRAYPROC)(GLuint index);
typedef void (*PFNGLVERTEXATTRIBPOINTERPROC)(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void* pointer);
typedef GLuint (*PFNGLCREATESHADERPROC)(GLenum type);
typedef void   (*PFNGLSHADERSOURCEPROC)(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);
typedef void   (*PFNGLCOMPILESHADERPROC)(GLuint shader);
typedef void   (*PFNGLGETSHADERIVPROC)(GLuint shader, GLenum pname, GLint* params);
typedef void   (*PFNGLGETSHADERINFOLOGPROC)(GLuint shader, GLsizei bufSize, GLsizei* length, GLchar* infoLog);
typedef void   (*PFNGLDELETESHADERPROC)(GLuint shader);
typedef GLuint (*PFNGLCREATEPROGRAMPROC)(void);
typedef void   (*PFNGLATTACHSHADERPROC)(GLuint program, GLuint shader);
typedef void   (*PFNGLLINKPROGRAMPROC)(GLuint program);
typedef void   (*PFNGLGETPROGRAMIVPROC)(GLuint program, GLenum pname, GLint* params);
typedef void   (*PFNGLGETPROGRAMINFOLOGPROC)(GLuint program, GLsizei bufSize, GLsizei* length, GLchar* infoLog);
typedef void   (*PFNGLUSEPROGRAMPROC)(GLuint program);
typedef void   (*PFNGLDELETEPROGRAMPROC)(GLuint program);
typedef GLint  (*PFNGLGETUNIFORMLOCATIONPROC)(GLuint program, const GLchar* name);
typedef void   (*PFNGLUNIFORM1IPROC)(GLint location, GLint v0);
typedef void   (*PFNGLUNIFORM1FPROC)(GLint location, GLfloat v0);
typedef void   (*PFNGLUNIFORM3FPROC)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
typedef void   (*PFNGLUNIFORMMATRIX4FVPROC)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
typedef void   (*PFNGLDRAWARRAYSPROC)(GLenum mode, GLint first, GLsizei count);
typedef void (*PFNGLDRAWELEMENTSPROC)(GLenum mode, GLsizei count, GLenum type, const void* indices);
typedef void (*PFNGLBUFFERSUBDATAPROC)(GLenum target, GLintptr offset, GLsizei size, const void* data);
typedef void   (*PFNGLGENTEXTURESPROC)(GLsizei n, GLuint* textures);
typedef void   (*PFNGLBINDTEXTUREPROC)(GLenum target, GLuint texture);
typedef void   (*PFNGLTEXIMAGE2DPROC)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void* pixels);
typedef void   (*PFNGLTEXSUBIMAGE2DPROC)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void* pixels);
typedef void   (*PFNGLTEXPARAMETERIPROC)(GLenum target, GLenum pname, GLint param);
typedef void   (*PFNGLACTIVETEXTUREPROC)(GLenum texture);
typedef void   (*PFNGLDELETETEXTURESPROC)(GLsizei n, const GLuint* textures);
typedef void   (*PFNGLGENFRAMEBUFFERSPROC)(GLsizei n, GLuint* framebuffers);
typedef void   (*PFNGLBINDFRAMEBUFFERPROC)(GLenum target, GLuint framebuffer);
typedef void   (*PFNGLDELETEFRAMEBUFFERSPROC)(GLsizei n, const GLuint* framebuffers);
typedef void   (*PFNGLFRAMEBUFFERTEXTURE2DPROC)(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void   (*PFNGLFRAMEBUFFERRENDERBUFFERPROC)(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
typedef GLenum (*PFNGLCHECKFRAMEBUFFERSTATUSPROC)(GLenum target);
typedef void   (*PFNGLGENRENDERBUFFERSPROC)(GLsizei n, GLuint* renderbuffers);
typedef void   (*PFNGLBINDRENDERBUFFERPROC)(GLenum target, GLuint renderbuffer);
typedef void   (*PFNGLRENDERBUFFERSTORAGEPROC)(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
typedef void   (*PFNGLDELETERENDERBUFFERSPROC)(GLsizei n, const GLuint* renderbuffers);
typedef void   (*PFNGLREADPIXELSPROC)(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void* pixels);
typedef void   (*PFNGLPIXELSTOREIPROC)(GLenum pname, GLint param);
]]

local M = {}

M.GL_FALSE                = 0
M.GL_TRUE                 = 1
M.GL_TRIANGLES            = 0x0004
M.GL_TRIANGLE_STRIP       = 0x0005
M.GL_LINES                = 0x0001
M.GL_POINTS               = 0x0000
M.GL_DEPTH_TEST           = 0x0B71
M.GL_BLEND                = 0x0BE2
M.GL_CULL_FACE            = 0x0B44
M.GL_SCISSOR_TEST         = 0x0C11
M.GL_FRONT_AND_BACK       = 0x0408
M.GL_FRONT                = 0x0404
M.GL_BACK                 = 0x0405
M.GL_CW                   = 0x0900
M.GL_CCW                  = 0x0901
M.GL_DEPTH_BUFFER_BIT     = 0x00000100
M.GL_COLOR_BUFFER_BIT     = 0x00004000
M.GL_STENCIL_BUFFER_BIT   = 0x00000400
M.GL_LEQUAL               = 0x0203
M.GL_LESS                 = 0x0201
M.GL_ALWAYS               = 0x0207
M.GL_SRC_ALPHA            = 0x0302
M.GL_ONE_MINUS_SRC_ALPHA  = 0x0303
M.GL_ONE                  = 1
M.GL_ZERO                 = 0
M.GL_ARRAY_BUFFER         = 0x8892
M.GL_ELEMENT_ARRAY_BUFFER = 0x8893
M.GL_STATIC_DRAW          = 0x88E4
M.GL_DYNAMIC_DRAW         = 0x88E8
M.GL_VERTEX_SHADER        = 0x8B31
M.GL_FRAGMENT_SHADER      = 0x8B30
M.GL_COMPILE_STATUS       = 0x8B81
M.GL_LINK_STATUS          = 0x8B82
M.GL_INFO_LOG_LENGTH      = 0x8B84
M.GL_FLOAT                = 0x1406
M.GL_UNSIGNED_INT         = 0x1405
M.GL_UNSIGNED_BYTE        = 0x1401
M.GL_TEXTURE_2D           = 0x0DE1
M.GL_TEXTURE0             = 0x84C0
M.GL_LINEAR               = 0x2601
M.GL_NEAREST              = 0x2600
M.GL_REPEAT               = 0x2901
M.GL_CLAMP_TO_EDGE        = 0x812F
M.GL_TEXTURE_WRAP_S       = 0x2802
M.GL_TEXTURE_WRAP_T       = 0x2803
M.GL_TEXTURE_MIN_FILTER   = 0x2801
M.GL_TEXTURE_MAG_FILTER   = 0x2800
M.GL_RGBA                 = 0x1908
M.GL_RGB                  = 0x1907
M.GL_RED                  = 0x1903
M.GL_R8                   = 0x8229
M.GL_FRAMEBUFFER          = 0x8D40
M.GL_FRAMEBUFFER_COMPLETE = 0x8CD5
M.GL_COLOR_ATTACHMENT0    = 0x8CE0
M.GL_RENDERBUFFER         = 0x8D41
M.GL_DEPTH_ATTACHMENT     = 0x8D00
M.GL_DEPTH_COMPONENT16    = 0x81A5
M.GL_COLOR_COMPONENT      = 0x8D57
M.GL_FILL                 = 0x1B02
M.GL_LINE                 = 0x1B01
M.GL_VENDOR               = 0x1F00
M.GL_RENDERER             = 0x1F01
M.GL_VERSION              = 0x1F02

local gl_funcs = {}

local CAST_MAP = {
    glClear                = "PFNGLCLEARPROC",
    glClearColor           = "PFNGLCLEARCOLORPROC",
    glViewport             = "PFNGLVIEWPORTPROC",
    glEnable               = "PFNGLENABLEPROC",
    glDisable              = "PFNGLDISABLEPROC",
    glDepthFunc            = "PFNGLDEPTHFUNCPROC",
    glBlendFunc            = "PFNGLBLENDFUNCPROC",
    glCullFace             = "PFNGLCULLFACEPROC",
    glFrontFace            = "PFNGLFRONTFACEPROC",
    glPolygonMode          = "PFNGLPOLYGONMODEPROC",
    glGetString            = "PFNGLGETSTRINGPROC",
    glGetError             = "PFNGLGETERRORPROC",
    glGenBuffers           = "PFNGLGENBUFFERSPROC",
    glBindBuffer           = "PFNGLBINDBUFFERPROC",
    glBufferData           = "PFNGLBUFFERDATAPROC",
    glDeleteBuffers        = "PFNGLDELETEBUFFERSPROC",
    glGenVertexArrays      = "PFNGLGENVERTEXARRAYSPROC",
    glBindVertexArray      = "PFNGLBINDVERTEXARRAYPROC",
    glDeleteVertexArrays   = "PFNGLDELETEVERTEXARRAYSPROC",
    glEnableVertexAttribArray  = "PFNGLENABLEVERTEXATTRIBARRAYPROC",
    glDisableVertexAttribArray = "PFNGLDISABLEVERTEXATTRIBARRAYPROC",
    glVertexAttribPointer  = "PFNGLVERTEXATTRIBPOINTERPROC",
    glCreateShader         = "PFNGLCREATESHADERPROC",
    glShaderSource         = "PFNGLSHADERSOURCEPROC",
    glCompileShader        = "PFNGLCOMPILESHADERPROC",
    glGetShaderiv          = "PFNGLGETSHADERIVPROC",
    glGetShaderInfoLog     = "PFNGLGETSHADERINFOLOGPROC",
    glDeleteShader         = "PFNGLDELETESHADERPROC",
    glCreateProgram        = "PFNGLCREATEPROGRAMPROC",
    glAttachShader         = "PFNGLATTACHSHADERPROC",
    glLinkProgram          = "PFNGLLINKPROGRAMPROC",
    glGetProgramiv         = "PFNGLGETPROGRAMIVPROC",
    glGetProgramInfoLog    = "PFNGLGETPROGRAMINFOLOGPROC",
    glUseProgram           = "PFNGLUSEPROGRAMPROC",
    glDeleteProgram        = "PFNGLDELETEPROGRAMPROC",
    glGetUniformLocation  = "PFNGLGETUNIFORMLOCATIONPROC",
    glUniform1i            = "PFNGLUNIFORM1IPROC",
    glUniform1f            = "PFNGLUNIFORM1FPROC",
    glUniform3f            = "PFNGLUNIFORM3FPROC",
    glUniformMatrix4fv     = "PFNGLUNIFORMMATRIX4FVPROC",
    glDrawArrays           = "PFNGLDRAWARRAYSPROC",
    glDrawElements         = "PFNGLDRAWELEMENTSPROC",
    glBufferSubData        = "PFNGLBUFFERSUBDATAPROC",
    glGenTextures          = "PFNGLGENTEXTURESPROC",
    glBindTexture          = "PFNGLBINDTEXTUREPROC",
    glTexImage2D           = "PFNGLTEXIMAGE2DPROC",
    glTexSubImage2D        = "PFNGLTEXSUBIMAGE2DPROC",
    glTexParameteri        = "PFNGLTEXPARAMETERIPROC",
    glActiveTexture        = "PFNGLACTIVETEXTUREPROC",
    glDeleteTextures       = "PFNGLDELETETEXTURESPROC",
    glGenFramebuffers      = "PFNGLGENFRAMEBUFFERSPROC",
    glBindFramebuffer      = "PFNGLBINDFRAMEBUFFERPROC",
    glDeleteFramebuffers   = "PFNGLDELETEFRAMEBUFFERSPROC",
    glFramebufferTexture2D = "PFNGLFRAMEBUFFERTEXTURE2DPROC",
    glFramebufferRenderbuffer = "PFNGLFRAMEBUFFERRENDERBUFFERPROC",
    glCheckFramebufferStatus  = "PFNGLCHECKFRAMEBUFFERSTATUSPROC",
    glGenRenderbuffers     = "PFNGLGENRENDERBUFFERSPROC",
    glBindRenderbuffer     = "PFNGLBINDRENDERBUFFERPROC",
    glRenderbufferStorage  = "PFNGLRENDERBUFFERSTORAGEPROC",
    glDeleteRenderbuffers  = "PFNGLDELETERENDERBUFFERSPROC",
    glReadPixels           = "PFNGLREADPIXELSPROC",
    glPixelStorei          = "PFNGLPIXELSTOREIPROC",
}

local function load_proc(name)
    local glfw = require("engine.core.platform.glfw")
    local ptr = glfw.glfwGetProcAddress(name)
    if ptr == nil then
        return nil
    end
    local cast_type = CAST_MAP[name]
    if cast_type then
        return ffi.cast(cast_type, ptr)
    end
    return ptr
end

function M.init()
    local glfw = require("engine.core.platform.glfw")
    
    if glfw.glfwGetCurrentContext() == nil then
        error("No OpenGL context! Make sure GLFW window is created and current.")
    end
    
    print("[GL] Loading OpenGL functions...")
    
    local func_names = {
        "glClear", "glClearColor", "glViewport", "glEnable", "glDisable",
        "glDepthFunc", "glBlendFunc", "glCullFace", "glFrontFace", "glPolygonMode",
        "glGetString", "glGetError", "glGenBuffers", "glBindBuffer", "glBufferData",
        "glDeleteBuffers", "glGenVertexArrays", "glBindVertexArray", "glDeleteVertexArrays",
        "glEnableVertexAttribArray", "glDisableVertexAttribArray", "glVertexAttribPointer",
        "glCreateShader", "glShaderSource", "glCompileShader", "glGetShaderiv",
        "glGetShaderInfoLog", "glDeleteShader", "glCreateProgram", "glAttachShader",
        "glLinkProgram", "glGetProgramiv", "glGetProgramInfoLog", "glUseProgram",
        "glDeleteProgram", "glGetUniformLocation", "glUniform1i", "glUniform1f",
        "glUniform3f", "glUniformMatrix4fv", "glDrawArrays", "glDrawElements",
        "glBufferSubData", "glGenTextures", "glBindTexture", "glTexImage2D",
        "glTexSubImage2D", "glTexParameteri", "glActiveTexture", "glDeleteTextures",
        "glGenFramebuffers", "glBindFramebuffer", "glDeleteFramebuffers",
        "glFramebufferTexture2D", "glFramebufferRenderbuffer", "glCheckFramebufferStatus",
        "glGenRenderbuffers", "glBindRenderbuffer", "glRenderbufferStorage",
        "glDeleteRenderbuffers", "glReadPixels", "glPixelStorei",
    }
    
    local loaded_count = 0
    for _, name in ipairs(func_names) do
        local func = load_proc(name)
        if func then
            gl_funcs[name] = func
            loaded_count = loaded_count + 1
        end
    end
    
    print("[GL] Loaded " .. loaded_count .. " OpenGL functions")
    
    if not gl_funcs.glEnable then
        error("Failed to load OpenGL functions. Make sure you have a valid OpenGL context.")
    end
    
    M.glEnable(M.GL_DEPTH_TEST)
    
    if gl_funcs.glGetString then
        local vendor = gl_funcs.glGetString(0x1F00)
        local renderer = gl_funcs.glGetString(0x1F01)
        local version = gl_funcs.glGetString(0x1F02)
        if vendor then print("[GL] Vendor:", ffi.string(vendor)) end
        if renderer then print("[GL] Renderer:", ffi.string(renderer)) end
        if version then print("[GL] Version:", ffi.string(version)) end
    end
    
    print("[GL] OpenGL initialized successfully")
end

setmetatable(M, {
    __index = function(_, key)
        if key:match("^gl") then
            local func = gl_funcs[key]
            if func then
                return func
            end
            local new_func = load_proc(key)
            if new_func then
                gl_funcs[key] = new_func
                return new_func
            end
            return nil
        end
        return rawget(M, key)
    end,
})

function M.create_shader_program(vert_src, frag_src)
    local gl = M
    
    if not gl.glCreateShader then
        error("OpenGL functions not loaded")
    end
    
    local vs = gl.glCreateShader(gl.GL_VERTEX_SHADER)
    if vs == 0 then
        error("Failed to create vertex shader")
    end
    
    local vs_ptr = ffi.new("const GLchar*[1]", {vert_src})
    local vs_len = ffi.new("GLint[1]", {#vert_src})
    gl.glShaderSource(vs, 1, vs_ptr, vs_len)
    gl.glCompileShader(vs)
    
    local ok_status = ffi.new("GLint[1]")
    gl.glGetShaderiv(vs, gl.GL_COMPILE_STATUS, ok_status)
    if ok_status[0] == 0 then
        local log = ffi.new("GLchar[1024]")
        local len = ffi.new("GLsizei[1]")
        gl.glGetShaderInfoLog(vs, 1024, len, log)
        error("Vertex shader error:\n" .. ffi.string(log, len[0]))
    end
    
    local fs = gl.glCreateShader(gl.GL_FRAGMENT_SHADER)
    if fs == 0 then
        error("Failed to create fragment shader")
    end
    
    local fs_ptr = ffi.new("const GLchar*[1]", {frag_src})
    local fs_len = ffi.new("GLint[1]", {#frag_src})
    gl.glShaderSource(fs, 1, fs_ptr, fs_len)
    gl.glCompileShader(fs)
    
    gl.glGetShaderiv(fs, gl.GL_COMPILE_STATUS, ok_status)
    if ok_status[0] == 0 then
        local log = ffi.new("GLchar[1024]")
        local len = ffi.new("GLsizei[1]")
        gl.glGetShaderInfoLog(fs, 1024, len, log)
        error("Fragment shader error:\n" .. ffi.string(log, len[0]))
    end
    
    local prog = gl.glCreateProgram()
    if prog == 0 then
        error("Failed to create program")
    end
    
    gl.glAttachShader(prog, vs)
    gl.glAttachShader(prog, fs)
    gl.glLinkProgram(prog)
    
    gl.glGetProgramiv(prog, gl.GL_LINK_STATUS, ok_status)
    if ok_status[0] == 0 then
        local log = ffi.new("GLchar[1024]")
        local len = ffi.new("GLsizei[1]")
        gl.glGetProgramInfoLog(prog, 1024, len, log)
        error("Program link error:\n" .. ffi.string(log, len[0]))
    end
    
    gl.glDeleteShader(vs)
    gl.glDeleteShader(fs)
    
    return prog
end

return M