




local sqrt, abs, max, min, huge =
    math.sqrt, math.abs, math.max, math.min, math.huge

local Narrowphase3D = {}

local EPSILON = 1e-6




function Narrowphase3D.sphereVsSphere(
    ax, ay, az, ar,
    bx, by, bz, br,
    manifold
)
    local dx = bx - ax
    local dy = by - ay
    local dz = bz - az
    local distSq = dx * dx + dy * dy + dz * dz
    local rSum = ar + br

    if distSq >= rSum * rSum then return false end

    local dist = sqrt(distSq)
    if dist < EPSILON then
        manifold:addContact(ax, ay, az, 1, 0, 0, rSum)
        manifold:setNormal(1, 0, 0)
    else
        local inv = 1 / dist
        local nx, ny, nz = dx * inv, dy * inv, dz * inv
        manifold:addContact(ax + nx * ar, ay + ny * ar, az + nz * ar, nx, ny, nz, rSum - dist)
        manifold:setNormal(nx, ny, nz)
    end
    return true
end




function Narrowphase3D.aabbVsAabb(
    ax, ay, az, ahw, ahh, ahd,
    bx, by, bz, bhw, bhh, bhd,
    manifold
)
    local dx = bx - ax
    local dy = by - ay
    local dz = bz - az
    local overlapX = (ahw + bhw) - abs(dx)
    local overlapY = (ahh + bhh) - abs(dy)
    local overlapZ = (ahd + bhd) - abs(dz)

    if overlapX <= 0 or overlapY <= 0 or overlapZ <= 0 then return false end

    local nx, ny, nz
    if overlapX < overlapY and overlapX < overlapZ then
        nx = dx > 0 and 1 or -1; ny = 0; nz = 0
        manifold:addContact(ax + nx * ahw, ay, az, nx, ny, nz, overlapX)
    elseif overlapY < overlapZ then
        nx = 0; ny = dy > 0 and 1 or -1; nz = 0
        manifold:addContact(ax, ay + ny * ahh, az, nx, ny, nz, overlapY)
    else
        nx = 0; ny = 0; nz = dz > 0 and 1 or -1
        manifold:addContact(ax, ay, az + nz * ahd, nx, ny, nz, overlapZ)
    end
    manifold:setNormal(nx, ny, nz)
    return true
end




function Narrowphase3D.sphereVsAABB(
    sx, sy, sz, sr,
    bx, by, bz, bhw, bhh, bhd,
    manifold
)
    local cx = max(-bhw, min(sx - bx, bhw)) + bx
    local cy = max(-bhh, min(sy - by, bhh)) + by
    local cz = max(-bhd, min(sz - bz, bhd)) + bz

    local dx = sx - cx
    local dy = sy - cy
    local dz = sz - cz
    local distSq = dx * dx + dy * dy + dz * dz

    if distSq >= sr * sr then return false end

    local dist = sqrt(distSq)
    if dist < EPSILON then
        local penX = bhw - abs(sx - bx) + sr
        local penY = bhh - abs(sy - by) + sr
        local penZ = bhd - abs(sz - bz) + sr
        local nx, ny, nz
        if penX < penY and penX < penZ then
            nx = sx > bx and 1 or -1; ny = 0; nz = 0
            manifold:addContact(cx, cy, cz, nx, ny, nz, penX)
        elseif penY < penZ then
            nx = 0; ny = sy > by and 1 or -1; nz = 0
            manifold:addContact(cx, cy, cz, nx, ny, nz, penY)
        else
            nx = 0; ny = 0; nz = sz > bz and 1 or -1
            manifold:addContact(cx, cy, cz, nx, ny, nz, penZ)
        end
        manifold:setNormal(nx, ny, nz)
    else
        local inv = 1 / dist
        local nx, ny, nz = dx * inv, dy * inv, dz * inv
        manifold:addContact(cx, cy, cz, nx, ny, nz, sr - dist)
        manifold:setNormal(nx, ny, nz)
    end
    return true
end




local function supportAABB(halfW, halfH, halfD, dx, dy, dz)
    local sx = dx > 0 and halfW or -halfW
    local sy = dy > 0 and halfH or -halfH
    local sz = dz > 0 and halfD or -halfD
    return sx, sy, sz
end

local function supportOBB(halfW, halfH, halfD, cosA, sinA, dx, dy, dz)
    
    local ldx = dx * cosA + dy * sinA
    local ldy = -dx * sinA + dy * cosA
    local localSupport = { supportAABB(halfW, halfH, halfD, ldx, ldy, dz) }
    
    local sx = localSupport[1] * cosA - localSupport[2] * sinA
    local sy = localSupport[1] * sinA + localSupport[2] * cosA
    return sx, sy, localSupport[3]
end




local function minkowskiSupport(
    ax, ay, az, ahw, ahh, ahd, aCos, aSin,
    bx, by, bz, bhw, bhh, bhd, bCos, bSin,
    dx, dy, dz
)
    local sx, sy, sz
    if aCos then
        sx, sy, sz = supportOBB(ahw, ahh, ahd, aCos, aSin, dx, dy, dz)
        sx, sy, sz = ax + sx, ay + sy, az + sz
    else
        sx, sy, sz = supportAABB(ahw, ahh, ahd, dx, dy, dz)
        sx, sy, sz = ax + sx, ay + sy, az + sz
    end

    local bx2, by2, bz2
    if bCos then
        bx2, by2, bz2 = supportOBB(bhw, bhh, bhd, bCos, bSin, -dx, -dy, -dz)
        bx2, by2, bz2 = bx + bx2, by + by2, bz + bz2
    else
        bx2, by2, bz2 = supportAABB(bhw, bhh, bhd, -dx, -dy, -dz)
        bx2, by2, bz2 = bx + bx2, by + by2, bz + bz2
    end

    return sx - bx2, sy - by2, sz - bz2
end




local function gjk3D(
    ax, ay, az, ahw, ahh, ahd, aCos, aSin,
    bx, by, bz, bhw, bhh, bhd, bCos, bSin
)
    local sx, sy, sz = {}, {}, {}
    local n = 0
    local dirX, dirY, dirZ = 1, 0, 0

    
    local wx, wy, wz = {}, {}, {}
    local sn = 0

    local function doSimplex()
        if sn == 2 then
            
            local ax0, ay0, az0 = wx[1] - wx[2], wy[1] - wy[2], wz[1] - wz[2]
            local t = -(wx[2] * ax0 + wy[2] * ay0 + wz[2] * az0) /
                      (ax0 * ax0 + ay0 * ay0 + az0 * az0 + EPSILON)
            if t < 0 then t = 0 elseif t > 1 then t = 1 end
            dirX = -(wx[2] + ax0 * t)
            dirY = -(wy[2] + ay0 * t)
            dirZ = -(wz[2] + az0 * t)
        elseif sn == 3 then
            
            local abx, aby, abz = wx[1] - wx[2], wy[1] - wy[2], wz[1] - wz[2]
            local acx, acy, acz = wx[3] - wx[2], wy[3] - wy[2], wz[3] - wz[2]
            local d1 = abx * (-wx[2]) + aby * (-wy[2]) + abz * (-wz[2])
            local d2 = acx * (-wx[2]) + acy * (-wy[2]) + acz * (-wz[2])

            if d1 <= 0 and d2 <= 0 then
                sn = 1; wx[1] = wx[2]; wy[1] = wy[2]; wz[1] = wz[2]
                dirX = -wx[1]; dirY = -wy[1]; dirZ = -wz[1]
            else
                local crossX = aby * acz - abz * acy
                local crossY = abz * acx - abx * acz
                local crossZ = abx * acy - aby * acx
                if crossX * (-wx[2]) + crossY * (-wy[2]) + crossZ * (-wz[2]) <= 0 then
                    
                    wx[1], wx[3] = wx[3], wx[1]
                    wy[1], wy[3] = wy[3], wy[1]
                    wz[1], wz[3] = wz[3], wz[1]
                    dirX, dirY, dirZ = -dirX, -dirY, -dirZ
                end
                if d1 > 0 then
                    sn = 3
                    wx[2] = wx[1]; wy[2] = wy[1]; wz[2] = wz[1]
                    wx[1] = abx; wy[1] = aby; wz[1] = abz
                end
            end
        elseif sn == 4 then
            
            local ax0 = wx[1] - wx[4]; local ay0 = wy[1] - wy[4]; local az0 = wz[1] - wz[4]
            local bx0 = wx[2] - wx[4]; local by0 = wy[2] - wy[4]; local bz0 = wz[2] - wz[4]
            local cx0 = wx[3] - wx[4]; local cy0 = wy[3] - wy[4]; local cz0 = wz[3] - wz[4]

            local det = ax0 * (by0 * cz0 - bz0 * cy0) -
                        ay0 * (bx0 * cz0 - bz0 * cx0) +
                        az0 * (bx0 * cy0 - by0 * cx0)

            if abs(det) < EPSILON then
                
                sn = 3
                return true
            end

            local invDet = 1 / det
            local ox = -wx[4] * invDet
            local oy = -wy[4] * invDet
            local oz = -wz[4] * invDet

            local u = (ax0 * (oy * cz0 - oz * cy0) - ay0 * (ox * cz0 - oz * cx0) + az0 * (ox * cy0 - oy * cx0))
            local v = (bx0 * (oy * cz0 - oz * cy0) - by0 * (ox * cz0 - oz * cx0) + bz0 * (ox * cy0 - oy * cx0))

            if u > 0 and v > 0 and (u + v) < 1 then
                return true 
            end

            
            sn = 3
            return true
        end
        return false
    end

    
    local px, py, pz = minkowskiSupport(
        ax, ay, az, ahw, ahh, ahd, aCos, aSin,
        bx, by, bz, bhw, bhh, bhd, bCos, bSin,
        dirX, dirY, dirZ
    )

    for iter = 1, 32 do
        sn = sn + 1
        wx[sn] = px; wy[sn] = py; wz[sn] = pz

        if px * px + py * py + pz * pz < EPSILON then
            return true
        end

        
        dirX, dirY, dirZ = -px, -py, -pz

        local nx, ny, nz = minkowskiSupport(
            ax, ay, az, ahw, ahh, ahd, aCos, aSin,
            bx, by, bz, bhw, bhh, bhd, bCos, bSin,
            dirX, dirY, dirZ
        )

        if (nx * dirX + ny * dirY + nz * dirZ) < EPSILON then
            return false
        end

        px, py, pz = nx, ny, nz
        if sn >= 4 then
            if doSimplex() then return true end
            sn = 3
        end
    end
    return false
end




function Narrowphase3D.obbVsOBB(
    ax, ay, az, aCos, aSin, ahw, ahh, ahd,
    bx, by, bz, bCos, bSin, bhw, bhh, bhd,
    manifold
)
    if not gjk3D(
        ax, ay, az, ahw, ahh, ahd, aCos, aSin,
        bx, by, bz, bhw, bhh, bhd, bCos, bSin
    ) then
        return false
    end

    
    local dx, dy, dz = bx - ax, by - ay, bz - az
    local overlapX = (ahw + bhw) - abs(dx)
    local overlapY = (ahh + bhh) - abs(dy)
    local overlapZ = (ahd + bhd) - abs(dz)

    if overlapX <= 0 or overlapY <= 0 or overlapZ <= 0 then return false end

    local nx, ny, nz, depth
    if overlapX < overlapY and overlapX < overlapZ then
        nx = dx > 0 and 1 or -1; ny = 0; nz = 0; depth = overlapX
    elseif overlapY < overlapZ then
        nx = 0; ny = dy > 0 and 1 or -1; nz = 0; depth = overlapY
    else
        nx = 0; ny = 0; nz = dz > 0 and 1 or -1; depth = overlapZ
    end

    manifold:addContact(
        ax + nx * ahw, ay, az + nz * ahd,
        nx, ny, nz, depth
    )
    manifold:setNormal(nx, ny, nz)
    return true
end




function Narrowphase3D.test(bodyA, bodyB, manifold)
    local sA = bodyA.shapeData
    local sB = bodyB.shapeData
    if not sA or not sB then return false end

    local tA, tB = sA.type, sB.type
    local pA = bodyA.pos3
    local pB = bodyB.pos3

    if tA == "sphere" and tB == "sphere" then
        return Narrowphase3D.sphereVsSphere(
            pA.x, pA.y, pA.z, sA.radius,
            pB.x, pB.y, pB.z, sB.radius,
            manifold
        )
    elseif tA == "aabb3d" and tB == "aabb3d" then
        return Narrowphase3D.aabbVsAabb(
            pA.x, pA.y, pA.z, sA.halfW, sA.halfH, sA.halfD,
            pB.x, pB.y, pB.z, sB.halfW, sB.halfH, sB.halfD,
            manifold
        )
    elseif tA == "sphere" and tB == "aabb3d" then
        return Narrowphase3D.sphereVsAABB(
            pA.x, pA.y, pA.z, sA.radius,
            pB.x, pB.y, pB.z, sB.halfW, sB.halfH, sB.halfD,
            manifold
        )
    elseif tA == "aabb3d" and tB == "sphere" then
        local hit = Narrowphase3D.sphereVsAABB(
            pB.x, pB.y, pB.z, sB.radius,
            pA.x, pA.y, pA.z, sA.halfW, sA.halfH, sA.halfD,
            manifold
        )
        if hit then
            manifold:setNormal(-manifold.normalX, -manifold.normalY, -manifold.normalZ)
        end
        return hit
    elseif tA == "obb3d" and tB == "obb3d" then
        return Narrowphase3D.obbVsOBB(
            pA.x, pA.y, pA.z, sA.cosAngle or 1, sA.sinAngle or 0, sA.halfW, sA.halfH, sA.halfD,
            pB.x, pB.y, pB.z, sB.cosAngle or 1, sB.sinAngle or 0, sB.halfW, sB.halfH, sB.halfD,
            manifold
        )
    end

    
    if tA == "sphere" and tB == "sphere" then
        return Narrowphase3D.sphereVsSphere(
            pA.x, pA.y, pA.z, sA.radius,
            pB.x, pB.y, pB.z, sB.radius,
            manifold
        )
    end

    return false
end


return Narrowphase3D
