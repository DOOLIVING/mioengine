





local sqrt, abs, min, max = math.sqrt, math.abs, math.min, math.max

local Solver = {}

Solver.BAUMGARTE       = 0.2   
Solver.SLOP            = 0.005 
Solver.VEL_ITERATIONS  = 8
Solver.POS_ITERATIONS  = 3
Solver.FRICTION_SCALE  = 0.6   




function Solver.solveContact(manifold, dt)
    local a = manifold.bodyA
    local b = manifold.bodyB
    if not a or not b then return end
    if a.invMass == 0 and b.invMass == 0 then return end

    local nx, ny, nz = manifold.normalX, manifold.normalY, manifold.normalZ
    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    local e = min(a.restitution, b.restitution)
    local mu = sqrt(a.friction * b.friction) 
    local baumgarte = Solver.BAUMGARTE / dt
    local slop = Solver.SLOP

    for i = 1, manifold.pointCount do
        local pt = manifold.points[i]
        local px, py, pz = pt.px, pt.py, pt.pz
        local depth = pt.depth

        
        
        
        
        
        
        local rvx, rvy, rvz

        
        rvx = b.velocity.x - a.velocity.x
        rvy = b.velocity.y - a.velocity.y
        rvz = (b.velocity3 and b.velocity3.z or 0) - (a.velocity3 and a.velocity3.z or 0)

        
        if a.invInertia > 0 then
            local rx, ry = px - a.pos.x, py - a.pos.y
            rvx = rvx - a.angularVelocity * (-ry)
            rvy = rvy - a.angularVelocity * rx
        end
        if b.invInertia > 0 then
            local rx, ry = px - b.pos.x, py - b.pos.y
            rvx = rvx + b.angularVelocity * (-ry)
            rvy = rvy + b.angularVelocity * rx
        end

        
        
        
        local vn = rvx * nx + rvy * ny + rvz * nz
        if vn > 0 then
            
        else
            local j = -(1 + e) * vn / totalInvMass

            
            a.velocity.x = a.velocity.x - j * nx * a.invMass
            a.velocity.y = a.velocity.y - j * ny * a.invMass
            b.velocity.x = b.velocity.x + j * nx * b.invMass
            b.velocity.y = b.velocity.y + j * ny * b.invMass

            
            if a.invInertia > 0 then
                local rx, ry = px - a.pos.x, py - a.pos.y
                a.angularVelocity = a.angularVelocity -
                    j * a.invInertia * (rx * ny - ry * nx)
            end
            if b.invInertia > 0 then
                local rx, ry = px - b.pos.x, py - b.pos.y
                b.angularVelocity = b.angularVelocity +
                    j * b.invInertia * (rx * ny - ry * nx)
            end

            
            
            
            
            rvx = b.velocity.x - a.velocity.x
            rvy = b.velocity.y - a.velocity.y

            if a.invInertia > 0 then
                local rx, ry = px - a.pos.x, py - a.pos.y
                rvx = rvx - a.angularVelocity * (-ry)
                rvy = rvy + a.angularVelocity * rx
            end
            if b.invInertia > 0 then
                local rx, ry = px - b.pos.x, py - b.pos.y
                rvx = rvx + b.angularVelocity * (-ry)
                rvy = rvy + b.angularVelocity * rx
            end

            
            local tx, ty = -ny, nx
            local vt = rvx * tx + rvy * ty

            
            local jt
            if abs(vt) < e * abs(vn) then
                
                jt = -vt / totalInvMass
            else
                
                jt = -mu * abs(vn) / totalInvMass
                if vt > 0 then jt = -jt end
            end

            
            a.velocity.x = a.velocity.x - jt * tx * a.invMass
            a.velocity.y = a.velocity.y - jt * ty * a.invMass
            b.velocity.x = b.velocity.x + jt * tx * b.invMass
            b.velocity.y = b.velocity.y + jt * ty * b.invMass

            if a.invInertia > 0 then
                local rx, ry = px - a.pos.x, py - a.pos.y
                a.angularVelocity = a.angularVelocity -
                    jt * a.invInertia * (rx * ty - ry * tx)
            end
            if b.invInertia > 0 then
                local rx, ry = px - b.pos.x, py - b.pos.y
                b.angularVelocity = b.angularVelocity +
                    jt * b.invInertia * (rx * ty - ry * tx)
            end
        end
    end
end




function Solver.positionalCorrection(manifold)
    local a = manifold.bodyA
    local b = manifold.bodyB
    if not a or not b then return end

    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    local nx, ny, nz = manifold.normalX, manifold.normalY, manifold.normalZ
    local slop = Solver.SLOP
    local baumgarte = Solver.BAUMGARTE

    
    local totalDepth = 0
    for i = 1, manifold.pointCount do
        totalDepth = totalDepth + manifold.points[i].depth
    end
    if manifold.pointCount == 0 then return end
    local avgDepth = totalDepth / manifold.pointCount

    local correction = max(avgDepth - slop, 0) * baumgarte / totalInvMass

    a.pos.x = a.pos.x - nx * correction * a.invMass
    a.pos.y = a.pos.y - ny * correction * a.invMass
    b.pos.x = b.pos.x + nx * correction * b.invMass
    b.pos.y = b.pos.y + ny * correction * b.invMass
end




function Solver.solveContact3D(manifold, dt)
    local a = manifold.bodyA
    local b = manifold.bodyB
    if not a or not b then return end
    if a.invMass == 0 and b.invMass == 0 then return end

    local nx, ny, nz = manifold.normalX, manifold.normalY, manifold.normalZ
    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    local e = min(a.restitution, b.restitution)
    local mu = sqrt(a.friction * b.friction)

    for i = 1, manifold.pointCount do
        local pt = manifold.points[i]
        local px, py, pz = pt.px, pt.py, pt.pz

        
        local rvx = b.velocity3.x - a.velocity3.x
        local rvy = b.velocity3.y - a.velocity3.y
        local rvz = b.velocity3.z - a.velocity3.z

        
        if a.invInertia > 0 then
            local rx, ry, rz = px - a.pos3.x, py - a.pos3.y, pz - a.pos3.z
            rvx = rvx - a.angularVelocity3.y * rz + a.angularVelocity3.z * ry
            rvy = rvy - a.angularVelocity3.z * rx + a.angularVelocity3.x * rz
            rvz = rvz - a.angularVelocity3.x * ry + a.angularVelocity3.y * rx
        end
        if b.invInertia > 0 then
            local rx, ry, rz = px - b.pos3.x, py - b.pos3.y, pz - b.pos3.z
            rvx = rvx + b.angularVelocity3.y * rz - b.angularVelocity3.z * ry
            rvy = rvy + b.angularVelocity3.z * rx - b.angularVelocity3.x * rz
            rvz = rvz + b.angularVelocity3.x * ry - b.angularVelocity3.y * rx
        end

        
        local vn = rvx * nx + rvy * ny + rvz * nz
        if vn < 0 then
            local j = -(1 + e) * vn / totalInvMass

            a.velocity3.x = a.velocity3.x - j * nx * a.invMass
            a.velocity3.y = a.velocity3.y - j * ny * a.invMass
            a.velocity3.z = a.velocity3.z - j * nz * a.invMass
            b.velocity3.x = b.velocity3.x + j * nx * b.invMass
            b.velocity3.y = b.velocity3.y + j * ny * b.invMass
            b.velocity3.z = b.velocity3.z + j * nz * b.invMass

            
            local tx = rvx - vn * nx
            local ty = rvy - vn * ny
            local tz = rvz - vn * nz
            local tl = sqrt(tx * tx + ty * ty + tz * tz)
            if tl > EPSILON then
                tx, ty, tz = tx / tl, ty / tl, tz / tl
                local vt = rvx * tx + rvy * ty + rvz * tz
                local jt = -vt / totalInvMass
                jt = max(-mu * abs(vn), min(jt, mu * abs(vn)))

                a.velocity3.x = a.velocity3.x - jt * tx * a.invMass
                a.velocity3.y = a.velocity3.y - jt * ty * a.invMass
                a.velocity3.z = a.velocity3.z - jt * tz * a.invMass
                b.velocity3.x = b.velocity3.x + jt * tx * b.invMass
                b.velocity3.y = b.velocity3.y + jt * ty * b.invMass
                b.velocity3.z = b.velocity3.z + jt * tz * b.invMass
            end
        end
    end
end

local EPSILON = 1e-6




function Solver.positionalCorrection3D(manifold)
    local a = manifold.bodyA
    local b = manifold.bodyB
    if not a or not b then return end

    local totalInvMass = a.invMass + b.invMass
    if totalInvMass == 0 then return end

    local nx, ny, nz = manifold.normalX, manifold.normalY, manifold.normalZ
    local slop = Solver.SLOP
    local baumgarte = Solver.BAUMGARTE

    local totalDepth = 0
    for i = 1, manifold.pointCount do
        totalDepth = totalDepth + manifold.points[i].depth
    end
    if manifold.pointCount == 0 then return end
    local avgDepth = totalDepth / manifold.pointCount
    local correction = max(avgDepth - slop, 0) * baumgarte / totalInvMass

    a.pos3.x = a.pos3.x - nx * correction * a.invMass
    a.pos3.y = a.pos3.y - ny * correction * a.invMass
    a.pos3.z = a.pos3.z - nz * correction * a.invMass
    b.pos3.x = b.pos3.x + nx * correction * b.invMass
    b.pos3.y = b.pos3.y + ny * correction * b.invMass
    b.pos3.z = b.pos3.z + nz * correction * b.invMass
end


return Solver
