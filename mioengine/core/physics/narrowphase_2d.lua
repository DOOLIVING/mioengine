




local sqrt, abs, cos, sin, max, huge =
    math.sqrt, math.abs, math.cos, math.sin, math.max, math.huge

local Narrowphase2D = {}




function Narrowphase2D.circleVsCircle(ax, ay, ar, bx, by, br, manifold)
    local dx = bx - ax
    local dy = by - ay
    local distSq = dx * dx + dy * dy
    local rSum = ar + br
    if distSq >= rSum * rSum then return false end

    local dist = sqrt(distSq)
    if dist < 1e-8 then
        manifold:addContact(ax, ay, 0, 1, 0, 0, rSum)
        manifold:setNormal(1, 0, 0)
    else
        local nx = dx / dist
        local ny = dy / dist
        manifold:addContact(ax + nx * ar, ay + ny * ar, 0, nx, ny, 0, rSum - dist)
        manifold:setNormal(nx, ny, 0)
    end
    return true
end




function Narrowphase2D.aabbVsAabb(ax, ay, ahw, ahh, bx, by, bhw, bhh, manifold)
    local dx = bx - ax
    local dy = by - ay
    local overlapX = (ahw + bhw) - abs(dx)
    local overlapY = (ahh + bhh) - abs(dy)

    if overlapX <= 0 or overlapY <= 0 then return false end

    local nx, ny
    if overlapX < overlapY then
        nx = dx > 0 and 1 or -1
        ny = 0
        manifold:addContact(ax + nx * ahw, ay, 0, nx, ny, 0, overlapX)
    else
        nx = 0
        ny = dy > 0 and 1 or -1
        manifold:addContact(ax, ay + ny * ahh, 0, nx, ny, 0, overlapY)
    end
    manifold:setNormal(nx, ny, 0)
    return true
end




function Narrowphase2D.circleVsAABB(cx, cy, cr, bx, by, bhw, bhh, manifold)
    local closestX = max(-bhw, min(cx - bx, bhw)) + bx
    local closestY = max(-bhh, min(cy - by, bhh)) + by

    local dx = cx - closestX
    local dy = cy - closestY
    local distSq = dx * dx + dy * dy

    if distSq >= cr * cr then return false end

    local dist = sqrt(distSq)
    if dist < 1e-8 then
        
        local penX = bhw - abs(cx - bx) + cr
        local penY = bhh - abs(cy - by) + cr
        if penX < penY then
            local nx = cx > bx and 1 or -1
            manifold:addContact(closestX, closestY, 0, nx, 0, 0, penX)
            manifold:setNormal(nx, 0, 0)
        else
            local ny = cy > by and 1 or -1
            manifold:addContact(closestX, closestY, 0, 0, ny, 0, penY)
            manifold:setNormal(0, ny, 0)
        end
    else
        local nx = dx / dist
        local ny = dy / dist
        manifold:addContact(closestX, closestY, 0, nx, ny, 0, cr - dist)
        manifold:setNormal(nx, ny, 0)
    end
    return true
end




function Narrowphase2D.obbVsOBB(
    ax, ay, acosA, asinA, ahw, ahh,
    bx, by, acosB, asinB, bhw, bhh,
    manifold
)
    
    local axes = {
        acosA, asinA,
        -asinA, acosA,
    }

    
    local function project(ox, oy, cosO, sinO, hw, hh, ax, ay)
        local rx = cosO * hw
        local ry = sinO * hh
        local cx = ox * ax + oy * ay
        local ex = abs(rx * ax) + abs(ry * ay)
        return cx - ex, cx + ex
    end

    
    local dbx, dby = bx - ax, by - ay
    local dbLocalX = dbx * acosA + dby * asinA
    local dbLocalY = dbx * (-asinA) + dby * acosA

    
    local function bAxis(ax, ay)
        local cB = bx + bhw * acosB
        local sB = by + bhh * asinB
    end

    local minOverlap = huge
    local minAxisX, minAxisY = 0, 0
    local minAxisWorldX, minAxisWorldY = 0, 0

    local function testAxis(nx, ny)
        
        local aEx = abs(ahw * nx) + abs(ahh * ny)
        local bEx = abs(bhw * nx) + abs(bhh * ny)
        local d = abs((bx - ax) * nx + (by - ay) * ny)
        local overlap = aEx + bEx - d
        if overlap <= 0 then return false end
        if overlap < minOverlap then
            minOverlap = overlap
            minAxisX = nx
            minAxisY = ny
        end
        return true
    end

    
    if not testAxis(acosA, asinA) then return false end
    if not testAxis(-asinA, acosA) then return false end

    
    if not testAxis(acosB, asinB) then return false end
    if not testAxis(-asinB, acosB) then return false end

    
    local dnx = bx - ax
    local dny = by - ay
    if dnx * minAxisX + dny * minAxisY < 0 then
        minAxisX = -minAxisX
        minAxisY = -minAxisY
    end

    manifold:addContact(
        ax + dnx * 0.5, ay + dny * 0.5, 0,
        minAxisX, minAxisY, 0,
        minOverlap
    )
    manifold:setNormal(minAxisX, minAxisY, 0)
    return true
end




function Narrowphase2D.circleVsOBB(cx, cy, cr, ox, oy, ocos, osin, ohw, ohh, manifold)
    
    local lx = (cx - ox) * ocos + (cy - oy) * osin
    local ly = (cx - ox) * (-osin) + (cy - oy) * ocos

    local closestX = max(-ohw, min(lx, ohw))
    local closestY = max(-ohh, min(ly, ohh))

    local dx = lx - closestX
    local dy = ly - closestY
    local distSq = dx * dx + dy * dy

    if distSq >= cr * cr then return false end

    local dist = sqrt(distSq)
    local nx, ny
    if dist < 1e-8 then
        local penX = ohw - abs(lx) + cr
        local penY = ohh - abs(ly) + cr
        if penX < penY then
            local wnx = lx > 0 and 1 or -1
            nx = wnx * ocos
            ny = wnx * (-osin)
            manifold:addContact(cx - nx * cr, cy - ny * cr, 0, nx, ny, 0, penX)
        else
            local wny = ly > 0 and 1 or -1
            nx = wny * (-osin)
            ny = wny * ocos
            manifold:addContact(cx - nx * cr, cy - ny * cr, 0, nx, ny, 0, penY)
        end
    else
        local lnx = dx / dist
        local lny = dy / dist
        
        nx = lnx * ocos - lny * osin
        ny = lnx * osin + lny * ocos
        local worldCloseX = ox + closestX * ocos - closestY * osin
        local worldCloseY = oy + closestX * osin + closestY * ocos
        manifold:addContact(worldCloseX, worldCloseY, 0, nx, ny, 0, cr - dist)
    end
    manifold:setNormal(nx, ny, 0)
    return true
end




function Narrowphase2D.test(bodyA, bodyB, manifold)
    local sA = bodyA.shapeData
    local sB = bodyB.shapeData
    if not sA or not sB then return false end

    local tA, tB = sA.type, sB.type

    if tA == "circle" and tB == "circle" then
        return Narrowphase2D.circleVsCircle(
            bodyA.pos.x, bodyA.pos.y, sA.radius,
            bodyB.pos.x, bodyB.pos.y, sB.radius,
            manifold
        )
    elseif tA == "aabb" and tB == "aabb" then
        return Narrowphase2D.aabbVsAabb(
            bodyA.pos.x, bodyA.pos.y, sA.halfW, sA.halfH,
            bodyB.pos.x, bodyB.pos.y, sB.halfW, sB.halfH,
            manifold
        )
    elseif tA == "circle" and tB == "aabb" then
        return Narrowphase2D.circleVsAABB(
            bodyA.pos.x, bodyA.pos.y, sA.radius,
            bodyB.pos.x, bodyB.pos.y, sB.halfW, sB.halfH,
            manifold
        )
    elseif tA == "aabb" and tB == "circle" then
        local hit = Narrowphase2D.circleVsAABB(
            bodyB.pos.x, bodyB.pos.y, sB.radius,
            bodyA.pos.x, bodyA.pos.y, sA.halfW, sA.halfH,
            manifold
        )
        if hit then
            manifold:setNormal(-manifold.normalX, -manifold.normalY, 0)
        end
        return hit
    elseif tA == "obb" and tB == "obb" then
        return Narrowphase2D.obbVsOBB(
            bodyA.pos.x, bodyA.pos.y, cos(bodyA.angle), sin(bodyA.angle), sA.halfW, sA.halfH,
            bodyB.pos.x, bodyB.pos.y, cos(bodyB.angle), sin(bodyB.angle), sB.halfW, sB.halfH,
            manifold
        )
    elseif tA == "circle" and tB == "obb" then
        return Narrowphase2D.circleVsOBB(
            bodyA.pos.x, bodyA.pos.y, sA.radius,
            bodyB.pos.x, bodyB.pos.y, cos(bodyB.angle), sin(bodyB.angle), sB.halfW, sB.halfH,
            manifold
        )
    elseif tA == "obb" and tB == "circle" then
        local hit = Narrowphase2D.circleVsOBB(
            bodyB.pos.x, bodyB.pos.y, sB.radius,
            bodyA.pos.x, bodyA.pos.y, cos(bodyA.angle), sin(bodyA.angle), sA.halfW, sA.halfH,
            manifold
        )
        if hit then
            manifold:setNormal(-manifold.normalX, -manifold.normalY, 0)
        end
        return hit
    end

    return false
end


return Narrowphase2D
