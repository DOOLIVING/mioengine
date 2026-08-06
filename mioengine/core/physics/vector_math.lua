




local sqrt, sin, cos, acos, abs, min, max =
    math.sqrt, math.sin, math.cos, math.acos, math.abs, math.min, math.max




local Vec2 = {}
Vec2.__index = Vec2

function Vec2.new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, Vec2)
end

function Vec2:clone()  return Vec2.new(self.x, self.y) end
function Vec2:copy(v)  self.x = v.x; self.y = v.y; return self end
function Vec2:set(x, y) self.x = x; self.y = y; return self end

function Vec2:add(v)  self.x = self.x + v.x; self.y = self.y + v.y; return self end
function Vec2:sub(v)  self.x = self.x - v.x; self.y = self.y - v.y; return self end
function Vec2:scale(s) self.x = self.x * s;   self.y = self.y * s;   return self end

function Vec2:addScaled(v, s)
    self.x = self.x + v.x * s; self.y = self.y + v.y * s; return self
end

function Vec2:subScaled(v, s)
    self.x = self.x - v.x * s; self.y = self.y - v.y * s; return self
end

function Vec2:dot(v)  return self.x * v.x + self.y * v.y end
function Vec2:cross(v) return self.x * v.y - self.y * v.x end

function Vec2:length()    return sqrt(self.x * self.x + self.y * self.y) end
function Vec2:lengthSq()  return self.x * self.x + self.y * self.y end

function Vec2:normalize()
    local l = self:length()
    if l > 1e-8 then self.x = self.x / l; self.y = self.y / l end
    return self
end

function Vec2:negate() self.x = -self.x; self.y = -self.y; return self end

function Vec2:perp() return Vec2.new(-self.y, self.x) end

function Vec2:rotate(cosA, sinA)
    local nx = self.x * cosA - self.y * sinA
    local ny = self.x * sinA + self.y * cosA
    self.x = nx; self.y = ny
    return self
end

function Vec2:min(v) return Vec2.new(min(self.x, v.x), min(self.y, v.y)) end
function Vec2:max(v) return Vec2.new(max(self.x, v.x), max(self.y, v.y)) end

function Vec2:dist(v)
    local dx, dy = v.x - self.x, v.y - self.y
    return sqrt(dx * dx + dy * dy)
end

function Vec2:distSq(v)
    local dx, dy = v.x - self.x, v.y - self.y
    return dx * dx + dy * dy
end

function Vec2:toString()
    return string.format("(%.4f, %.4f)", self.x, self.y)
end




local Vec3 = {}
Vec3.__index = Vec3

function Vec3.new(x, y, z)
    return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, Vec3)
end

function Vec3:clone()  return Vec3.new(self.x, self.y, self.z) end
function Vec3:copy(v)  self.x = v.x; self.y = v.y; self.z = v.z; return self end
function Vec3:set(x, y, z) self.x = x; self.y = y; self.z = z; return self end

function Vec3:add(v)
    self.x = self.x + v.x; self.y = self.y + v.y; self.z = self.z + v.z
    return self
end

function Vec3:sub(v)
    self.x = self.x - v.x; self.y = self.y - v.y; self.z = self.z - v.z
    return self
end

function Vec3:scale(s)
    self.x = self.x * s; self.y = self.y * s; self.z = self.z * s
    return self
end

function Vec3:addScaled(v, s)
    self.x = self.x + v.x * s
    self.y = self.y + v.y * s
    self.z = self.z + v.z * s
    return self
end

function Vec3:subScaled(v, s)
    self.x = self.x - v.x * s
    self.y = self.y - v.y * s
    self.z = self.z - v.z * s
    return self
end

function Vec3:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

function Vec3:cross(v)
    return Vec3.new(
        self.y * v.z - self.z * v.y,
        self.z * v.x - self.x * v.z,
        self.x * v.y - self.y * v.x
    )
end

function Vec3:crossInplace(v)
    local cx = self.y * v.z - self.z * v.y
    local cy = self.z * v.x - self.x * v.z
    local cz = self.x * v.y - self.y * v.x
    self.x = cx; self.y = cy; self.z = cz
    return self
end

function Vec3:length()   return sqrt(self.x * self.x + self.y * self.y + self.z * self.z) end
function Vec3:lengthSq() return self.x * self.x + self.y * self.y + self.z * self.z end

function Vec3:normalize()
    local l = self:length()
    if l > 1e-8 then
        self.x = self.x / l; self.y = self.y / l; self.z = self.z / l
    end
    return self
end

function Vec3:negate()
    self.x = -self.x; self.y = -self.y; self.z = -self.z
    return self
end

function Vec3:min(v)
    return Vec3.new(min(self.x, v.x), min(self.y, v.y), min(self.z, v.z))
end

function Vec3:max(v)
    return Vec3.new(max(self.x, v.x), max(self.y, v.y), max(self.z, v.z))
end

function Vec3:dist(v)
    local dx, dy, dz = v.x - self.x, v.y - self.y, v.z - self.z
    return sqrt(dx * dx + dy * dy + dz * dz)
end

function Vec3:distSq(v)
    local dx, dy, dz = v.x - self.x, v.y - self.y, v.z - self.z
    return dx * dx + dy * dy + dz * dz
end

function Vec3:toString()
    return string.format("(%.4f, %.4f, %.4f)", self.x, self.y, self.z)
end




local Quat = {}
Quat.__index = Quat

function Quat.new(w, x, y, z)
    return setmetatable({ w = w or 1, x = x or 0, y = y or 0, z = z or 0 }, Quat)
end

function Quat:clone()
    return Quat.new(self.w, self.x, self.y, self.z)
end

function Quat:copy(q)
    self.w = q.w; self.x = q.x; self.y = q.y; self.z = q.z
    return self
end

function Quat:identity()
    self.w = 1; self.x = 0; self.y = 0; self.z = 0
    return self
end

function Quat:fromAxisAngle(axis, angle)
    local half = angle * 0.5
    local s = sin(half)
    local len = axis:length()
    if len < 1e-8 then return self:identity() end
    self.w = cos(half)
    self.x = (axis.x / len) * s
    self.y = (axis.y / len) * s
    self.z = (axis.z / len) * s
    return self
end

function Quat:fromEuler(pitch, yaw, roll)
    local hp, hy, hr = pitch * 0.5, yaw * 0.5, roll * 0.5
    local cp, sp = cos(hp), sin(hp)
    local cy, sy = cos(hy), sin(hy)
    local cr, sr = cos(hr), sin(hr)
    self.w = cr * cp * cy + sr * sp * sy
    self.x = sr * cp * cy - cr * sp * sy
    self.y = cr * sp * cy + sr * cp * sy
    self.z = cr * cp * sy - sr * sp * cy
    return self
end

function Quat:set(w, x, y, z)
    self.w = w; self.x = x; self.y = y; self.z = z
    return self
end

function Quat:lengthSq()
    return self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z
end

function Quat:length()
    return sqrt(self:lengthSq())
end

function Quat:normalize()
    local l = self:length()
    if l > 1e-8 then
        local inv = 1 / l
        self.w = self.w * inv; self.x = self.x * inv
        self.y = self.y * inv; self.z = self.z * inv
    end
    return self
end

function Quat:conjugate()
    self.x = -self.x; self.y = -self.y; self.z = -self.z
    return self
end

function Quat:inverse()
    local l2 = self:lengthSq()
    if l2 < 1e-12 then return self:identity() end
    local inv = 1 / l2
    self.w =  self.w * inv
    self.x = -self.x * inv
    self.y = -self.y * inv
    self.z = -self.z * inv
    return self
end

function Quat:mul(q)
    local aw, ax, ay, az = self.w, self.x, self.y, self.z
    local bw, bx, by, bz = q.w, q.x, q.y, q.z
    self.w = aw * bw - ax * bx - ay * by - az * bz
    self.x = aw * bx + ax * bw + ay * bz - az * by
    self.y = aw * by - ax * bz + ay * bw + az * bx
    self.z = aw * bz + ax * by - ay * bx + az * bw
    return self
end

function Quat:rotateVec3(v)
    local qw, qx, qy, qz = self.w, self.x, self.y, self.z
    local vx, vy, vz = v.x, v.y, v.z

    local tx = 2 * (qy * vz - qz * vy)
    local ty = 2 * (qz * vx - qx * vz)
    local tz = 2 * (qx * vy - qy * vx)

    v.x = vx + qw * tx + (qy * tz - qz * ty)
    v.y = vy + qw * ty + (qz * tx - qx * tz)
    v.z = vz + qw * tz + (qx * ty - qy * tx)
    return v
end

function Quat:toMatrix3x3()
    local w, x, y, z = self.w, self.x, self.y, self.z
    local xx, yy, zz = x * x, y * y, z * z
    local xy, xz, yz = x * y, x * z, y * z
    local wx, wy, wz = w * x, w * y, w * z
    return {
        1 - 2 * (yy + zz), 2 * (xy + wz),     2 * (xz - wy),
        2 * (xy - wz),     1 - 2 * (xx + zz), 2 * (yz + wx),
        2 * (xz + wy),     2 * (yz - wx),     1 - 2 * (xx + yy),
    }
end

function Quat:dot(q)
    return self.w * q.w + self.x * q.x + self.y * q.y + self.z * q.z
end

function Quat:slerp(q, t)
    local d = self:dot(q)
    if d < 0 then q = q:clone(); q:negate(); d = -d end
    if d > 0.9995 then
        self.x = self.x + t * (q.x - self.x)
        self.y = self.y + t * (q.y - self.y)
        self.z = self.z + t * (q.z - self.z)
        self.w = self.w + t * (q.w - self.w)
        return self:normalize()
    end
    local theta = acos(min(max(d, -1), 1))
    local st = sin(theta)
    local a = sin((1 - t) * theta) / st
    local b = sin(t * theta) / st
    self.w = a * self.w + b * q.w
    self.x = a * self.x + b * q.x
    self.y = a * self.y + b * q.y
    self.z = a * self.z + b * q.z
    return self
end

function Quat:toString()
    return string.format("(%.4f, %.4f, %.4f, %.4f)", self.w, self.x, self.y, self.z)
end




local _v2a = Vec2.new(0, 0)
local _v2b = Vec2.new(0, 0)
local _v3a = Vec3.new(0, 0, 0)
local _v3b = Vec3.new(0, 0, 0)
local _v3c = Vec3.new(0, 0, 0)
local _q1  = Quat.new(1, 0, 0, 0)


return {
    Vec2   = Vec2,
    Vec3   = Vec3,
    Quat   = Quat,
    
    tmpV2a = _v2a,
    tmpV2b = _v2b,
    tmpV3a = _v3a,
    tmpV3b = _v3b,
    tmpV3c = _v3c,
    tmpQ1  = _q1,
}
