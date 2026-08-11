local ffi = require("ffi")
local math3d = require("engine.core.math")
local glfw = require("engine.core.platform.glfw")

local M = {}
M.__index = M

function M.new(params)
    params = params or {}
    local cam = setmetatable({}, M)
    cam.position = math3d.vec3(params.x or 0, params.y or 1.5, params.z or 5)
    cam.pitch = params.pitch or 0
    cam.yaw = params.yaw or -90
    cam.fov = math.rad(params.fov or 60)
    cam.near = params.near or 0.1
    cam.far = params.far or 500
    cam.speed = params.speed or 5
    cam.sensitivity = params.sensitivity or 0.002
    cam.front = math3d.vec3(0, 0, -1)
    cam.up = math3d.vec3(0, 1, 0)
    cam.right = math3d.vec3(1, 0, 0)
    cam.first_mouse = true
    cam.last_x = 400
    cam.last_y = 300
    cam.locked = false
    cam.fps_mode = false
    cam.velY = 0
    cam.gravity = -20
    cam.groundY = 1.7
    cam.jumpForce = 8
    cam.onGround = true
    cam:update_vectors()
    return cam
end

function M:update_vectors()
    local rad_pitch = math.rad(self.pitch)
    local rad_yaw = math.rad(self.yaw)
    self.front = math3d.vec3(
        math.cos(rad_pitch) * math.cos(rad_yaw),
        math.sin(rad_pitch),
        math.cos(rad_pitch) * math.sin(rad_yaw)
    )
    self.front = math3d.vec3_normalize(self.front)
    self.right = math3d.vec3_normalize(math3d.vec3_cross(self.front, math3d.vec3(0, 1, 0)))
    self.up = math3d.vec3_normalize(math3d.vec3_cross(self.right, self.front))
end

function M:get_view_matrix()
    local target = math3d.vec3_add(self.position, self.front)
    return math3d.mat4_look_at(self.position, target, self.up)
end

function M:get_projection_matrix(aspect)
    return math3d.mat4_perspective(self.fov, aspect, self.near, self.far)
end

function M:process_keyboard(dt, input)
    if self.locked then return end

    if self.fps_mode then
        local flat_front = math3d.vec3(self.front[0], 0, self.front[2])
        flat_front = math3d.vec3_normalize(flat_front)
        local velocity = math3d.vec3_scale(flat_front, self.speed * dt)
        local strafe = math3d.vec3_scale(self.right, self.speed * dt)

        if input:is_down("w") then
            self.position = math3d.vec3_add(self.position, velocity)
        end
        if input:is_down("s") then
            self.position = math3d.vec3_sub(self.position, velocity)
        end
        if input:is_down("a") then
            self.position = math3d.vec3_sub(self.position, strafe)
        end
        if input:is_down("d") then
            self.position = math3d.vec3_add(self.position, strafe)
        end

        if input:is_down("space") and self.onGround then
            self.velY = self.jumpForce
            self.onGround = false
        end

        self.velY = self.velY + self.gravity * dt
        self.position[1] = self.position[1] + self.velY * dt

        if self.position[1] <= self.groundY then
            self.position[1] = self.groundY
            self.velY = 0
            self.onGround = true
        end
    else
        local velocity = math3d.vec3_scale(self.front, self.speed * dt)
        local strafe = math3d.vec3_scale(self.right, self.speed * dt)

        if input:is_down("w") then
            self.position = math3d.vec3_add(self.position, velocity)
        end
        if input:is_down("s") then
            self.position = math3d.vec3_sub(self.position, velocity)
        end
        if input:is_down("a") then
            self.position = math3d.vec3_sub(self.position, strafe)
        end
        if input:is_down("d") then
            self.position = math3d.vec3_add(self.position, strafe)
        end
        if input:is_down("space") then
            self.position[1] = self.position[1] + self.speed * dt
        end
        if input:is_down("left_shift") or input:is_down("right_shift") then
            self.position[1] = self.position[1] - self.speed * dt
        end
    end
end

function M:process_mouse(dx, dy)
    if self.locked then return end
    self.yaw = self.yaw + dx * self.sensitivity * 50
    self.pitch = self.pitch - dy * self.sensitivity * 50
    if self.pitch > 89 then self.pitch = 89 end
    if self.pitch < -89 then self.pitch = -89 end
    self:update_vectors()
end

return M
