local ffi = require("ffi")

ffi.cdef[[
typedef struct GLFWwindow  GLFWwindow;
typedef struct GLFWmonitor GLFWmonitor;
typedef void (* GLFWerrorfun)(int error_code, const char* description);
typedef void (* GLFWkeyfun)(GLFWwindow* window, int key, int scancode, int action, int mods);
typedef void (* GLFWcharfun)(GLFWwindow* window, unsigned int codepoint);
typedef void (* GLFWframebuffersizefun)(GLFWwindow* window, int width, int height);
typedef void (* GLFWcursorposfun)(GLFWwindow* window, double xpos, double ypos);
typedef void (* GLFWmousebuttonfun)(GLFWwindow* window, int button, int action, int mods);
typedef void (* GLFWscrollfun)(GLFWwindow* window, double xoffset, double yoffset);

int         glfwInit(void);
void        glfwTerminate(void);
void        glfwGetVersion(int* major, int* minor, int* rev);
GLFWerrorfun glfwSetErrorCallback(GLFWerrorfun cbfun);
void        glfwWindowHint(int hint, int value);
GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
void        glfwDestroyWindow(GLFWwindow* window);
int         glfwWindowShouldClose(GLFWwindow* window);
void        glfwSetWindowShouldClose(GLFWwindow* window, int value);
void        glfwSetWindowTitle(GLFWwindow* window, const char* title);
void        glfwGetWindowSize(GLFWwindow* window, int* width, int* height);
void        glfwSetWindowSize(GLFWwindow* window, int width, int height);
void        glfwGetFramebufferSize(GLFWwindow* window, int* width, int* height);
void        glfwMakeContextCurrent(GLFWwindow* window);
GLFWwindow* glfwGetCurrentContext(void);
void        glfwSwapBuffers(GLFWwindow* window);
void        glfwSwapInterval(int interval);
void        glfwPollEvents(void);
void        glfwWaitEvents(void);
int         glfwGetKey(GLFWwindow* window, int key);
int         glfwGetMouseButton(GLFWwindow* window, int button);
void        glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);
void        glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);
void        glfwSetInputMode(GLFWwindow* window, int mode, int value);
GLFWkeyfun         glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun cbfun);
GLFWcharfun        glfwSetCharCallback(GLFWwindow* window, GLFWcharfun cbfun);
GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWframebuffersizefun cbfun);
GLFWcursorposfun   glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun cbfun);
GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun cbfun);
GLFWscrollfun      glfwSetScrollCallback(GLFWwindow* window, GLFWscrollfun cbfun);
double      glfwGetTime(void);
void        glfwSetTime(double time);
typedef void (*GLFWglproc)(void);
GLFWglproc glfwGetProcAddress(const char* procname);
const char* glfwGetClipboardString(GLFWwindow* window);
void glfwSetClipboardString(GLFWwindow* window, const char* string);
void glfwSetWindowSizeLimits(GLFWwindow* window, int minwidth, int minheight, int maxwidth, int maxheight);
]]

local Platform = require("engine.core.platform.platform")
local lib = Platform.try_load("glfw")
if not lib then error("Failed to load GLFW library") end

local M = {}
M.lib = lib

local glfw_names = {
    "glfwInit", "glfwTerminate", "glfwGetVersion",
    "glfwSetErrorCallback", "glfwWindowHint",
    "glfwCreateWindow", "glfwDestroyWindow",
    "glfwWindowShouldClose", "glfwSetWindowShouldClose",
    "glfwSetWindowTitle", "glfwGetWindowSize", "glfwSetWindowSize",
    "glfwGetFramebufferSize",
    "glfwMakeContextCurrent", "glfwGetCurrentContext",
    "glfwSwapBuffers", "glfwSwapInterval",
    "glfwPollEvents", "glfwWaitEvents",
    "glfwGetKey", "glfwGetMouseButton",
    "glfwGetCursorPos", "glfwSetCursorPos", "glfwSetInputMode",
    "glfwSetKeyCallback", "glfwSetCharCallback",
    "glfwSetFramebufferSizeCallback",
    "glfwSetCursorPosCallback", "glfwSetMouseButtonCallback",
    "glfwSetScrollCallback",
    "glfwGetTime", "glfwSetTime",
    "glfwGetProcAddress",
    "glfwGetClipboardString", "glfwSetClipboardString",
    "glfwSetWindowSizeLimits",
}

for _, name in ipairs(glfw_names) do
    M[name] = lib[name]
end

M.GLFW_TRUE              = 1
M.GLFW_FALSE             = 0
M.GLFW_RELEASE           = 0
M.GLFW_PRESS             = 1
M.GLFW_REPEAT            = 2
M.GLFW_KEY_UNKNOWN       = -1
M.GLFW_KEY_SPACE         = 32
M.GLFW_KEY_ESCAPE        = 256
M.GLFW_KEY_ENTER         = 257
M.GLFW_KEY_TAB           = 258
M.GLFW_KEY_BACKSPACE     = 259
M.GLFW_KEY_DELETE        = 261
M.GLFW_KEY_RIGHT         = 262
M.GLFW_KEY_LEFT          = 263
M.GLFW_KEY_DOWN          = 264
M.GLFW_KEY_UP            = 265
M.GLFW_KEY_LEFT_SHIFT    = 340
M.GLFW_KEY_LEFT_CONTROL  = 341
M.GLFW_KEY_LEFT_ALT      = 342
M.GLFW_KEY_RIGHT_SHIFT   = 344
M.GLFW_KEY_RIGHT_CONTROL = 345
M.GLFW_KEY_RIGHT_ALT     = 346
M.GLFW_KEY_A = 65
M.GLFW_KEY_B = 66
M.GLFW_KEY_C = 67
M.GLFW_KEY_D = 68
M.GLFW_KEY_E = 69
M.GLFW_KEY_F = 70
M.GLFW_KEY_G = 71
M.GLFW_KEY_H = 72
M.GLFW_KEY_I = 73
M.GLFW_KEY_J = 74
M.GLFW_KEY_K = 75
M.GLFW_KEY_L = 76
M.GLFW_KEY_M = 77
M.GLFW_KEY_N = 78
M.GLFW_KEY_O = 79
M.GLFW_KEY_P = 80
M.GLFW_KEY_Q = 81
M.GLFW_KEY_R = 82
M.GLFW_KEY_S = 83
M.GLFW_KEY_T = 84
M.GLFW_KEY_U = 85
M.GLFW_KEY_V = 86
M.GLFW_KEY_W = 87
M.GLFW_KEY_X = 88
M.GLFW_KEY_Y = 89
M.GLFW_KEY_Z = 90
M.GLFW_KEY_0 = 48
M.GLFW_KEY_1 = 49
M.GLFW_KEY_2 = 50
M.GLFW_KEY_3 = 51
M.GLFW_KEY_4 = 52
M.GLFW_KEY_5 = 53
M.GLFW_KEY_6 = 54
M.GLFW_KEY_7 = 55
M.GLFW_KEY_8 = 56
M.GLFW_KEY_9 = 57
M.GLFW_KEY_F1  = 290
M.GLFW_KEY_F2  = 291
M.GLFW_KEY_F3  = 292
M.GLFW_KEY_F4  = 293
M.GLFW_KEY_F5  = 294
M.GLFW_KEY_F6  = 295
M.GLFW_KEY_F7  = 296
M.GLFW_KEY_F8  = 297
M.GLFW_KEY_F9  = 298
M.GLFW_KEY_F10 = 299
M.GLFW_KEY_F11 = 300
M.GLFW_KEY_F12 = 301
M.GLFW_KEY_KP_0 = 320
M.GLFW_KEY_KP_1 = 321
M.GLFW_KEY_KP_2 = 322
M.GLFW_KEY_KP_3 = 323
M.GLFW_KEY_KP_4 = 324
M.GLFW_KEY_KP_5 = 325
M.GLFW_KEY_KP_6 = 326
M.GLFW_KEY_KP_7 = 327
M.GLFW_KEY_KP_8 = 328
M.GLFW_KEY_KP_9 = 329
M.GLFW_MOUSE_BUTTON_LEFT   = 0
M.GLFW_MOUSE_BUTTON_RIGHT  = 1
M.GLFW_MOUSE_BUTTON_MIDDLE = 2
M.GLFW_MOD_SHIFT   = 0x0001
M.GLFW_MOD_CONTROL = 0x0002
M.GLFW_MOD_ALT     = 0x0004
M.GLFW_MOD_SUPER   = 0x0008
M.GLFW_CLIENT_API             = 0x00022001
M.GLFW_CONTEXT_VERSION_MAJOR  = 0x00022002
M.GLFW_CONTEXT_VERSION_MINOR  = 0x00022003
M.GLFW_OPENGL_FORWARD_COMPAT  = 0x00022006
M.GLFW_OPENGL_PROFILE         = 0x00022008
M.GLFW_RESIZABLE              = 0x00022007
M.GLFW_VISIBLE                = 0x00022004
M.GLFW_DECORATED              = 0x00022005
M.GLFW_OPENGL_API             = 0x00030001
M.GLFW_OPENGL_CORE_PROFILE    = 0x00032001
M.GLFW_CURSOR                 = 0x00033001
M.GLFW_CURSOR_NORMAL          = 0x00034001
M.GLFW_CURSOR_HIDDEN          = 0x00034002
M.GLFW_CURSOR_DISABLED        = 0x00034003
M.GLFW_STICKY_KEYS            = 0x00033002
M.GLFW_STICKY_MOUSE_BUTTONS   = 0x00033003

function M.init(width, height, title)
    M.glfwInit()
    M.glfwSetErrorCallback(function(code, desc)
        io.stderr:write(string.format("[GLFW ERROR %d] %s\n", code, ffi.string(desc)))
    end)
    M.glfwWindowHint(M.GLFW_CONTEXT_VERSION_MAJOR, 3)
    M.glfwWindowHint(M.GLFW_CONTEXT_VERSION_MINOR, 3)
    M.glfwWindowHint(M.GLFW_OPENGL_PROFILE, M.GLFW_OPENGL_CORE_PROFILE)
    M.glfwWindowHint(M.GLFW_OPENGL_FORWARD_COMPAT, 1)
    M.glfwWindowHint(M.GLFW_RESIZABLE, 1)
    local win = M.glfwCreateWindow(width, height, title or "MioEngine", nil, nil)
    if win == nil then
        M.glfwTerminate()
        error("Failed to create GLFW window")
    end
    M.glfwMakeContextCurrent(win)
    M.glfwSwapInterval(1)
    return win
end

function M.shouldClose(win)
    return M.glfwWindowShouldClose(win) ~= 0
end

function M.destroy(win)
    M.glfwDestroyWindow(win)
    M.glfwTerminate()
end

return M
