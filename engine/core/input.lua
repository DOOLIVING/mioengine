local ffi = require("ffi")
local glfw = require("engine.core.platform.glfw")

local M = {}
M.__index = M

local KEY_MAP = {
    ["w"] = glfw.GLFW_KEY_W, ["a"] = glfw.GLFW_KEY_A, ["s"] = glfw.GLFW_KEY_S,
    ["d"] = glfw.GLFW_KEY_D, ["e"] = glfw.GLFW_KEY_E, ["q"] = glfw.GLFW_KEY_Q,
    ["r"] = glfw.GLFW_KEY_R, ["f"] = glfw.GLFW_KEY_F, ["g"] = glfw.GLFW_KEY_G,
    ["z"] = glfw.GLFW_KEY_Z, ["x"] = glfw.GLFW_KEY_X, ["c"] = glfw.GLFW_KEY_C,
    ["v"] = glfw.GLFW_KEY_V, ["b"] = glfw.GLFW_KEY_B, ["n"] = glfw.GLFW_KEY_N,
    ["m"] = glfw.GLFW_KEY_M, ["p"] = glfw.GLFW_KEY_P, ["l"] = glfw.GLFW_KEY_L,
    ["k"] = glfw.GLFW_KEY_K, ["j"] = glfw.GLFW_KEY_J, ["h"] = glfw.GLFW_KEY_H,
    ["i"] = glfw.GLFW_KEY_I, ["o"] = glfw.GLFW_KEY_O, ["u"] = glfw.GLFW_KEY_U,
    ["y"] = glfw.GLFW_KEY_Y, ["t"] = glfw.GLFW_KEY_T, ["space"] = glfw.GLFW_KEY_SPACE,
    ["escape"] = glfw.GLFW_KEY_ESCAPE, ["enter"] = glfw.GLFW_KEY_ENTER,
    ["tab"] = glfw.GLFW_KEY_TAB, ["backspace"] = glfw.GLFW_KEY_BACKSPACE,
    ["delete"] = glfw.GLFW_KEY_DELETE, ["left"] = glfw.GLFW_KEY_LEFT,
    ["right"] = glfw.GLFW_KEY_RIGHT, ["up"] = glfw.GLFW_KEY_UP, ["down"] = glfw.GLFW_KEY_DOWN,
    ["left_shift"] = glfw.GLFW_KEY_LEFT_SHIFT, ["right_shift"] = glfw.GLFW_KEY_RIGHT_SHIFT,
    ["left_control"] = glfw.GLFW_KEY_LEFT_CONTROL, ["right_control"] = glfw.GLFW_KEY_RIGHT_CONTROL,
    ["left_alt"] = glfw.GLFW_KEY_LEFT_ALT, ["right_alt"] = glfw.GLFW_KEY_RIGHT_ALT,
    ["1"] = glfw.GLFW_KEY_1, ["2"] = glfw.GLFW_KEY_2, ["3"] = glfw.GLFW_KEY_3,
    ["4"] = glfw.GLFW_KEY_4, ["5"] = glfw.GLFW_KEY_5, ["6"] = glfw.GLFW_KEY_6,
    ["7"] = glfw.GLFW_KEY_7, ["8"] = glfw.GLFW_KEY_8, ["9"] = glfw.GLFW_KEY_9,
    ["0"] = glfw.GLFW_KEY_0,
    ["f1"] = glfw.GLFW_KEY_F1, ["f2"] = glfw.GLFW_KEY_F2, ["f3"] = glfw.GLFW_KEY_F3,
    ["f4"] = glfw.GLFW_KEY_F4, ["f5"] = glfw.GLFW_KEY_F5, ["f6"] = glfw.GLFW_KEY_F6,
    ["f7"] = glfw.GLFW_KEY_F7, ["f8"] = glfw.GLFW_KEY_F8, ["f9"] = glfw.GLFW_KEY_F9,
    ["f10"] = glfw.GLFW_KEY_F10, ["f11"] = glfw.GLFW_KEY_F11, ["f12"] = glfw.GLFW_KEY_F12,
    ["minus"] = 45, ["equal"] = 61,
    ["left_bracket"] = 91, ["right_bracket"] = 93, ["backslash"] = 92,
    ["semicolon"] = 59, ["apostrophe"] = 39, ["grave"] = 96,
    ["comma"] = 44, ["period"] = 46, ["slash"] = 47,
}

local REVERSE_MAP = {}
for k, v in pairs(KEY_MAP) do REVERSE_MAP[v] = k end

function M.new()
    return setmetatable({
        keys_pressed = {},
        keys_down = {},
        keys_released = {},
        mouse_x = 0, mouse_y = 0,
        mouse_dx = 0, mouse_dy = 0,
        mouse_btn_pressed = {}, mouse_btn_down = {}, mouse_btn_released = {},
        scroll_x = 0, scroll_y = 0,
        window = nil,
        raw_input = {},
    }, M)
end

function M:init(window)
    self.window = window
    self.raw_input = {}

    glfw.glfwSetKeyCallback(window, function(win, key, scancode, action, mods)
        local name = REVERSE_MAP[key] or ("key_" .. key)
        if action == glfw.GLFW_PRESS then
            self.raw_input[name] = "pressed"
        elseif action == glfw.GLFW_RELEASE then
            self.raw_input[name] = "released"
        elseif action == glfw.GLFW_REPEAT then
            self.raw_input[name] = "repeat"
        end
    end)

    glfw.glfwSetMouseButtonCallback(window, function(win, button, action, mods)
        local name = "mouse_" .. button
        if action == glfw.GLFW_PRESS then
            self.raw_input[name] = "pressed"
        elseif action == glfw.GLFW_RELEASE then
            self.raw_input[name] = "released"
        end
    end)

    glfw.glfwSetScrollCallback(window, function(win, xoffset, yoffset)
        self.scroll_x = xoffset
        self.scroll_y = yoffset
    end)
end

function M:update()
    self.keys_pressed = {}
    self.keys_released = {}
    self.mouse_btn_pressed = {}
    self.mouse_btn_released = {}
    self.scroll_x = 0
    self.scroll_y = 0

    for name, state in pairs(self.raw_input) do
        if state == "pressed" then
            self.keys_pressed[name] = true
            self.keys_down[name] = true
            self.raw_input[name] = "held"
        elseif state == "released" then
            self.keys_released[name] = true
            self.keys_down[name] = nil
            self.raw_input[name] = nil
        elseif state == "repeat" then
            self.keys_pressed[name] = true
        end
    end

    if self.window then
        local mx = ffi.new("double[1]")
        local my = ffi.new("double[1]")
        glfw.glfwGetCursorPos(self.window, mx, my)
        self.mouse_dx = mx[0] - self.mouse_x
        self.mouse_dy = my[0] - self.mouse_y
        self.mouse_x = mx[0]
        self.mouse_y = my[0]

        for btn = 0, 2 do
            local state = glfw.glfwGetMouseButton(self.window, btn)
            local name = "mouse_" .. btn
            if state == glfw.GLFW_PRESS then
                if not self.mouse_btn_down[name] then
                    self.mouse_btn_pressed[name] = true
                end
                self.mouse_btn_down[name] = true
            else
                if self.mouse_btn_down[name] then
                    self.mouse_btn_released[name] = true
                end
                self.mouse_btn_down[name] = nil
            end
        end
    end
end

function M:is_down(key)
    return self.keys_down[key] or false
end

function M:is_pressed(key)
    return self.keys_pressed[key] or false
end

function M:is_released(key)
    return self.keys_released[key] or false
end

function M:mouse_down(btn)
    return self.mouse_btn_down["mouse_" .. (btn or 0)] or false
end

function M:mouse_pressed(btn)
    return self.mouse_btn_pressed["mouse_" .. (btn or 0)] or false
end

function M:get_mouse_pos()
    return self.mouse_x, self.mouse_y
end

function M:get_mouse_delta()
    return self.mouse_dx, self.mouse_dy
end

function M:get_scroll()
    return self.scroll_x, self.scroll_y
end

return M
