local ffi = require("ffi")
local M = {}

function M.vec3(x, y, z)
    return ffi.new("float[3]", x or 0, y or 0, z or 0)
end

function M.vec3_add(a, b)
    return M.vec3(a[0]+b[0], a[1]+b[1], a[2]+b[2])
end

function M.vec3_sub(a, b)
    return M.vec3(a[0]-b[0], a[1]-b[1], a[2]-b[2])
end

function M.vec3_scale(v, s)
    return M.vec3(v[0]*s, v[1]*s, v[2]*s)
end

function M.vec3_dot(a, b)
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
end

function M.vec3_cross(a, b)
    return M.vec3(
        a[1]*b[2] - a[2]*b[1],
        a[2]*b[0] - a[0]*b[2],
        a[0]*b[1] - a[1]*b[0]
    )
end

function M.vec3_length(v)
    return math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
end

function M.vec3_normalize(v)
    local l = M.vec3_length(v)
    if l < 1e-8 then return M.vec3(0, 0, 0) end
    return M.vec3(v[0]/l, v[1]/l, v[2]/l)
end

function M.vec3_lerp(a, b, t)
    return M.vec3(
        a[0] + (b[0]-a[0])*t,
        a[1] + (b[1]-a[1])*t,
        a[2] + (b[2]-a[2])*t
    )
end

function M.vec3_copy(v)
    return M.vec3(v[0], v[1], v[2])
end

function M.mat4()
    return ffi.new("float[16]")
end

function M.mat4_identity()
    local m = M.mat4()
    m[0]=1; m[5]=1; m[10]=1; m[15]=1
    return m
end

function M.mat4_perspective(fov_rad, aspect, near, far)
    local f = 1.0 / math.tan(fov_rad / 2.0)
    local nf = 1.0 / (near - far)
    local m = M.mat4()
    m[0] = f / aspect
    m[5] = f
    m[10] = (far + near) * nf
    m[11] = -1
    m[14] = 2 * far * near * nf
    return m
end

function M.mat4_ortho(left, right, bottom, top, near, far)
    local m = M.mat4()
    m[0]  = 2 / (right - left)
    m[5]  = 2 / (top - bottom)
    m[10] = -2 / (far - near)
    m[12] = -(right + left) / (right - left)
    m[13] = -(top + bottom) / (top - bottom)
    m[14] = -(far + near) / (far - near)
    m[15] = 1
    return m
end

function M.mat4_look_at(eye, center, up)
    local fx, fy, fz = center[0]-eye[0], center[1]-eye[1], center[2]-eye[2]
    local fl = math.sqrt(fx*fx + fy*fy + fz*fz)
    fx, fy, fz = fx/fl, fy/fl, fz/fl

    local sx = fy*up[2] - fz*up[1]
    local sy = fz*up[0] - fx*up[2]
    local sz = fx*up[1] - fy*up[0]
    local sl = math.sqrt(sx*sx + sy*sy + sz*sz)
    sx, sy, sz = sx/sl, sy/sl, sz/sl

    local ux = sy*fz - sz*fy
    local uy = sz*fx - sx*fz
    local uz = sx*fy - sy*fx

    local m = M.mat4()
    m[0] = sx;  m[4] = sy;  m[8]  = sz;  m[12] = -(sx*eye[0]+sy*eye[1]+sz*eye[2])
    m[1] = ux;  m[5] = uy;  m[9]  = uz;  m[13] = -(ux*eye[0]+uy*eye[1]+uz*eye[2])
    m[2] = -fx; m[6] = -fy; m[10] = -fz; m[14] = (fx*eye[0]+fy*eye[1]+fz*eye[2])
    m[3] = 0;   m[7] = 0;   m[11] = 0;   m[15] = 1
    return m
end

function M.mat4_multiply(a, b)
    local m = M.mat4()
    for col=0,3 do
        for row=0,3 do
            m[col*4+row] = a[0*4+row]*b[col*4+0] + a[1*4+row]*b[col*4+1] +
                           a[2*4+row]*b[col*4+2] + a[3*4+row]*b[col*4+3]
        end
    end
    return m
end

function M.mat4_translate(x, y, z)
    local m = M.mat4_identity()
    m[12] = x; m[13] = y; m[14] = z
    return m
end

function M.mat4_scale(sx, sy, sz)
    local m = M.mat4_identity()
    m[0] = sx; m[5] = sy; m[10] = sz
    return m
end

function M.mat4_rotate_x(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = M.mat4_identity()
    m[5] = c;  m[6] = s
    m[9] = -s; m[10] = c
    return m
end

function M.mat4_rotate_y(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = M.mat4_identity()
    m[0] = c;  m[2] = -s
    m[8] = s;  m[10] = c
    return m
end

function M.mat4_rotate_z(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = M.mat4_identity()
    m[0] = c;  m[1] = s
    m[4] = -s; m[5] = c
    return m
end

function M.mat4_from_euler(pitch, yaw, roll)
    local rx = M.mat4_rotate_x(pitch)
    local ry = M.mat4_rotate_y(yaw)
    local rz = M.mat4_rotate_z(roll)
    return M.mat4_multiply(rz, M.mat4_multiply(rx, ry))
end

function M.mat4_get_position(m)
    return M.vec3(m[12], m[13], m[14])
end

function M.mat4_set_position(m, x, y, z)
    m[12] = x; m[13] = y; m[14] = z
end

function M.mat4_inverse(m)
    local inv = M.mat4()
    inv[0]  =  m[5]*m[10]*m[15] - m[5]*m[11]*m[14] - m[9]*m[6]*m[15] + m[9]*m[7]*m[14] + m[13]*m[6]*m[11] - m[13]*m[7]*m[10]
    inv[4]  = -m[4]*m[10]*m[15] + m[4]*m[11]*m[14] + m[8]*m[6]*m[15] - m[8]*m[7]*m[14] - m[12]*m[6]*m[11] + m[12]*m[7]*m[10]
    inv[8]  =  m[4]*m[9]*m[15]  - m[4]*m[11]*m[13] - m[8]*m[5]*m[15] + m[8]*m[7]*m[13] + m[12]*m[5]*m[11] - m[12]*m[7]*m[9]
    inv[12] = -m[4]*m[9]*m[14]  + m[4]*m[10]*m[13] + m[8]*m[5]*m[14] - m[8]*m[6]*m[13] - m[12]*m[5]*m[10] + m[12]*m[6]*m[9]
    inv[1]  = -m[1]*m[10]*m[15] + m[1]*m[11]*m[14] + m[9]*m[2]*m[15] - m[9]*m[3]*m[14] - m[13]*m[2]*m[11] + m[13]*m[3]*m[10]
    inv[5]  =  m[0]*m[10]*m[15] - m[0]*m[11]*m[14] - m[8]*m[2]*m[15] + m[8]*m[3]*m[14] + m[12]*m[2]*m[11] - m[12]*m[3]*m[10]
    inv[9]  = -m[0]*m[9]*m[15]  + m[0]*m[11]*m[13] + m[8]*m[1]*m[15] - m[8]*m[3]*m[13] - m[12]*m[1]*m[11] + m[12]*m[3]*m[9]
    inv[13] =  m[0]*m[9]*m[14]  - m[0]*m[10]*m[13] - m[8]*m[1]*m[14] + m[8]*m[2]*m[13] + m[12]*m[1]*m[10] - m[12]*m[2]*m[9]
    inv[2]  =  m[1]*m[6]*m[15]  - m[1]*m[7]*m[14]  - m[5]*m[2]*m[15] + m[5]*m[3]*m[14] + m[13]*m[2]*m[7]  - m[13]*m[3]*m[6]
    inv[6]  = -m[0]*m[6]*m[15]  + m[0]*m[7]*m[14]  + m[4]*m[2]*m[15] - m[4]*m[3]*m[14] - m[12]*m[2]*m[7]  + m[12]*m[3]*m[6]
    inv[10] =  m[0]*m[5]*m[15]  - m[0]*m[7]*m[13]  - m[4]*m[1]*m[15] + m[4]*m[3]*m[13] + m[12]*m[1]*m[7]  - m[12]*m[3]*m[5]
    inv[14] = -m[0]*m[5]*m[14]  + m[0]*m[6]*m[13]  + m[4]*m[1]*m[14] - m[4]*m[2]*m[13] - m[12]*m[1]*m[6]  + m[12]*m[2]*m[5]
    inv[3]  = -m[1]*m[6]*m[11]  + m[1]*m[7]*m[10]  + m[5]*m[2]*m[11] - m[5]*m[3]*m[10] - m[9]*m[2]*m[7]   + m[9]*m[3]*m[6]
    inv[7]  =  m[0]*m[6]*m[11]  - m[0]*m[7]*m[10]  - m[4]*m[2]*m[11] + m[4]*m[3]*m[10] + m[8]*m[2]*m[7]   - m[8]*m[3]*m[6]
    inv[11] = -m[0]*m[5]*m[11]  + m[0]*m[7]*m[9]   + m[4]*m[1]*m[11] - m[4]*m[3]*m[9]  - m[8]*m[1]*m[7]   + m[8]*m[3]*m[5]
    inv[15] =  m[0]*m[5]*m[10]  - m[0]*m[6]*m[9]   - m[4]*m[1]*m[10] + m[4]*m[2]*m[9]  + m[8]*m[1]*m[6]   - m[8]*m[2]*m[5]
    local det = m[0]*inv[0] + m[1]*inv[4] + m[2]*inv[8] + m[3]*inv[12]
    if math.abs(det) < 1e-10 then return M.mat4_identity() end
    local idet = 1.0 / det
    for i=0,15 do inv[i] = inv[i] * idet end
    return inv
end

function M.quat(x, y, z, w)
    return ffi.new("float[4]", x or 0, y or 0, z or 0, w or 1)
end

function M.quat_from_euler(pitch, yaw, roll)
    local cp, sp = math.cos(pitch*0.5), math.sin(pitch*0.5)
    local cy, sy = math.cos(yaw*0.5), math.sin(yaw*0.5)
    local cr, sr = math.cos(roll*0.5), math.sin(roll*0.5)
    return M.quat(
        sr*cp*cy - cr*sp*sy,
        cr*sp*cy + sr*cp*sy,
        cr*cp*sy - sr*sp*cy,
        cr*cp*cy + sr*sp*sy
    )
end

function M.quat_to_mat4(q)
    local m = M.mat4_identity()
    local xx, yy, zz = q[0]*q[0], q[1]*q[1], q[2]*q[2]
    local xy, xz, yz = q[0]*q[1], q[0]*q[2], q[1]*q[2]
    local wx, wy, wz = q[3]*q[0], q[3]*q[1], q[3]*q[2]
    m[0]  = 1 - 2*(yy+zz)
    m[1]  = 2*(xy+wz)
    m[2]  = 2*(xz-wy)
    m[4]  = 2*(xy-wz)
    m[5]  = 1 - 2*(xx+zz)
    m[6]  = 2*(yz+wx)
    m[8]  = 2*(xz+wy)
    m[9]  = 2*(yz-wx)
    m[10] = 1 - 2*(xx+yy)
    return m
end

return M
