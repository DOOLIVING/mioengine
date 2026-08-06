




local sqrt = math.sqrt

local Shapes = {}




function Shapes.circle(radius)
    return { type = "circle", radius = radius }
end




function Shapes.aabb(halfW, halfH)
    return { type = "aabb", halfW = halfW, halfH = halfH }
end




function Shapes.obb(halfW, halfH, angle)
    return { type = "obb", halfW = halfW, halfH = halfH, angle = angle or 0 }
end




function Shapes.sphere(radius)
    return { type = "sphere", radius = radius }
end




function Shapes.aabb3d(halfW, halfH, halfD)
    return { type = "aabb3d", halfW = halfW, halfH = halfH, halfD = halfD }
end




function Shapes.obb3d(halfW, halfH, halfD)
    return {
        type = "obb3d",
        halfW = halfW, halfH = halfH, halfD = halfD,
        orientation = nil, 
        axes = nil,        
    }
end




function Shapes.hull(vertices)
    return { type = "hull", vertices = vertices }
end




function Shapes.computeAABB2D(body)
    local s = body.shapeData
    if not s then
        body.aabbMinX = body.pos.x; body.aabbMinY = body.pos.y
        body.aabbMaxX = body.pos.x; body.aabbMaxY = body.pos.y
        return
    end
    local t = s.type
    if t == "circle" then
        local r = s.radius
        body.aabbMinX = body.pos.x - r
        body.aabbMinY = body.pos.y - r
        body.aabbMaxX = body.pos.x + r
        body.aabbMaxY = body.pos.y + r
    elseif t == "aabb" then
        body.aabbMinX = body.pos.x - s.halfW
        body.aabbMinY = body.pos.y - s.halfH
        body.aabbMaxX = body.pos.x + s.halfW
        body.aabbMaxY = body.pos.y + s.halfH
    elseif t == "obb" then
        local c, sn = math.cos(body.angle), math.sin(body.angle)
        local hw, hh = s.halfW, s.halfH
        local wx = math.abs(c * hw) + math.abs(sn * hh)
        local wy = math.abs(sn * hw) + math.abs(c * hh)
        body.aabbMinX = body.pos.x - wx
        body.aabbMinY = body.pos.y - wy
        body.aabbMaxX = body.pos.x + wx
        body.aabbMaxY = body.pos.y + wy
    else
        body.aabbMinX = body.pos.x; body.aabbMinY = body.pos.y
        body.aabbMaxX = body.pos.x; body.aabbMaxY = body.pos.y
    end
end

function Shapes.computeAABB3D(body)
    local s = body.shapeData
    if not s then
        local p = body.pos3
        body.aabbMinX3 = p.x; body.aabbMinY3 = p.y; body.aabbMinZ3 = p.z
        body.aabbMaxX3 = p.x; body.aabbMaxY3 = p.y; body.aabbMaxZ3 = p.z
        return
    end
    local t = s.type
    local p = body.pos3
    if t == "sphere" then
        local r = s.radius
        body.aabbMinX3 = p.x - r; body.aabbMinY3 = p.y - r; body.aabbMinZ3 = p.z - r
        body.aabbMaxX3 = p.x + r; body.aabbMaxY3 = p.y + r; body.aabbMaxZ3 = p.z + r
    elseif t == "aabb3d" then
        body.aabbMinX3 = p.x - s.halfW
        body.aabbMinY3 = p.y - s.halfH
        body.aabbMinZ3 = p.z - s.halfD
        body.aabbMaxX3 = p.x + s.halfW
        body.aabbMaxY3 = p.y + s.halfH
        body.aabbMaxZ3 = p.z + s.halfD
    elseif t == "obb3d" or t == "hull" then
        
        local hw, hh, hd = s.halfW or 1, s.halfH or 1, s.halfD or 1
        body.aabbMinX3 = p.x - hw; body.aabbMinY3 = p.y - hh; body.aabbMinZ3 = p.z - hd
        body.aabbMaxX3 = p.x + hw; body.aabbMaxY3 = p.y + hh; body.aabbMaxZ3 = p.z + hd
    else
        body.aabbMinX3 = p.x; body.aabbMinY3 = p.y; body.aabbMinZ3 = p.z
        body.aabbMaxX3 = p.x; body.aabbMaxY3 = p.y; body.aabbMaxZ3 = p.z
    end
end




function Shapes.getOBBVertices2D(body)
    local s = body.shapeData
    local hw, hh = s.halfW, s.halfH
    local c, sn = math.cos(body.angle), math.sin(body.angle)
    local px, py = body.pos.x, body.pos.y

    local v1x = px + (-c * hw + sn * hh)
    local v1y = py + (-sn * hw - c * hh)
    local v2x = px + ( c * hw + sn * hh)
    local v2y = py + ( sn * hw - c * hh)
    local v3x = px + ( c * hw - sn * hh)
    local v3y = py + ( sn * hw + c * hh)
    local v4x = px + (-c * hw - sn * hh)
    local v4y = py + (-sn * hw + c * hh)

    return v1x, v1y, v2x, v2y, v3x, v3y, v4x, v4y
end




function Shapes.getOBBAxes2D(body)
    local c, sn = math.cos(body.angle), math.sin(body.angle)
    return c, sn, -sn, c
end


return Shapes
