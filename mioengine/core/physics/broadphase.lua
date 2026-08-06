




local floor = math.floor
local huge  = math.huge




local SHG2D = {}
SHG2D.__index = SHG2D

function SHG2D.new(cellSize)
    local self = setmetatable({}, SHG2D)
    self.cellSize = cellSize or 64
    self.invCellSize = 1 / self.cellSize
    self.cells = {}       
    self.bodyCells = {}   
    return self
end

function SHG2D:clear()
    self.cells = {}
    self.bodyCells = {}
end

function SHG2D:_hash(cx, cy)
    return cx * 73856093 + cy * 19349669
end

function SHG2D:_cellCoords(aabbMinX, aabbMinY, aabbMaxX, aabbMaxY)
    local x0 = floor(aabbMinX * self.invCellSize)
    local y0 = floor(aabbMinY * self.invCellSize)
    local x1 = floor(aabbMaxX * self.invCellSize)
    local y1 = floor(aabbMaxY * self.invCellSize)
    return x0, y0, x1, y1
end

function SHG2D:insert(body)
    local x0, y0, x1, y1 = self:_cellCoords(
        body.aabbMinX, body.aabbMinY, body.aabbMaxX, body.aabbMaxY
    )
    local hashes = {}
    local idx = 0
    for cx = x0, x1 do
        for cy = y0, y1 do
            idx = idx + 1
            local h = self:_hash(cx, cy)
            hashes[idx] = h
            if not self.cells[h] then
                self.cells[h] = {}
            end
            local cell = self.cells[h]
            cell[#cell + 1] = body
        end
    end
    self.bodyCells[body.id] = hashes
end

function SHG2D:remove(body)
    local hashes = self.bodyCells[body.id]
    if not hashes then return end
    for i = 1, #hashes do
        local h = hashes[i]
        local cell = self.cells[h]
        if cell then
            for j = #cell, 1, -1 do
                if cell[j] == body then
                    cell[j] = cell[#cell]
                    cell[#cell] = nil
                    break
                end
            end
            if #cell == 0 then
                self.cells[h] = nil
            end
        end
    end
    self.bodyCells[body.id] = nil
end

function SHG2D:updateBody(body)
    self:remove(body)
    self:insert(body)
end

function SHG2D:queryAABB(minX, minY, maxX, maxY)
    local result = {}
    local seen = {}
    local x0, y0, x1, y1 = self:_cellCoords(minX, minY, maxX, maxY)
    for cx = x0, x1 do
        for cy = y0, y1 do
            local h = self:_hash(cx, cy)
            local cell = self.cells[h]
            if cell then
                for i = 1, #cell do
                    local b = cell[i]
                    if not seen[b.id] then
                        seen[b.id] = true
                        result[#result + 1] = b
                    end
                end
            end
        end
    end
    return result
end

function SHG2D:queryPoint(x, y)
    local cx = floor(x * self.invCellSize)
    local cy = floor(y * self.invCellSize)
    local h = self:_hash(cx, cy)
    local cell = self.cells[h]
    if not cell then return {} end
    local result = {}
    for i = 1, #cell do
        local b = cell[i]
        if x >= b.aabbMinX and x <= b.aabbMaxX and
           y >= b.aabbMinY and y <= b.aabbMaxY then
            result[#result + 1] = b
        end
    end
    return result
end

function SHG2D:broadphasePairs()
    local pairs = {}
    local pairSet = {}
    local cells = self.cells
    for _, cell in pairs(cells) do
        local n = #cell
        for i = 1, n do
            local a = cell[i]
            for j = i + 1, n do
                local b = cell[j]
                if a.id ~= b.id then
                    local minId, maxId
                    if a.id < b.id then
                        minId, maxId = a.id, b.id
                    else
                        minId, maxId = b.id, a.id
                    end
                    local key = tostring(minId) .. "#" .. tostring(maxId)
                    if not pairSet[key] then
                        pairSet[key] = true
                        
                        if a.aabbMinX <= b.aabbMaxX and a.aabbMaxX >= b.aabbMinX and
                           a.aabbMinY <= b.aabbMaxY and a.aabbMaxY >= b.aabbMinY then
                            pairs[#pairs + 1] = a
                            pairs[#pairs + 1] = b
                        end
                    end
                end
            end
        end
    end
    return pairs
end




local SHG3D = {}
SHG3D.__index = SHG3D

function SHG3D.new(cellSize)
    local self = setmetatable({}, SHG3D)
    self.cellSize = cellSize or 64
    self.invCellSize = 1 / self.cellSize
    self.cells = {}
    self.bodyCells = {}
    return self
end

function SHG3D:clear()
    self.cells = {}
    self.bodyCells = {}
end

function SHG3D:_hash(cx, cy, cz)
    return cx * 73856093 + cy * 19349669 + cz * 83492791
end

function SHG3D:_cellCoords(minX, minY, minZ, maxX, maxY, maxZ)
    return
        floor(minX * self.invCellSize),
        floor(minY * self.invCellSize),
        floor(minZ * self.invCellSize),
        floor(maxX * self.invCellSize),
        floor(maxY * self.invCellSize),
        floor(maxZ * self.invCellSize)
end

function SHG3D:insert(body)
    local x0, y0, z0, x1, y1, z1 = self:_cellCoords(
        body.aabbMinX3, body.aabbMinY3, body.aabbMinZ3,
        body.aabbMaxX3, body.aabbMaxY3, body.aabbMaxZ3
    )
    local hashes = {}
    local idx = 0
    for cx = x0, x1 do
        for cy = y0, y1 do
            for cz = z0, z1 do
                idx = idx + 1
                local h = self:_hash(cx, cy, cz)
                hashes[idx] = h
                if not self.cells[h] then
                    self.cells[h] = {}
                end
                local cell = self.cells[h]
                cell[#cell + 1] = body
            end
        end
    end
    self.bodyCells[body.id] = hashes
end

function SHG3D:remove(body)
    local hashes = self.bodyCells[body.id]
    if not hashes then return end
    for i = 1, #hashes do
        local h = hashes[i]
        local cell = self.cells[h]
        if cell then
            for j = #cell, 1, -1 do
                if cell[j] == body then
                    cell[j] = cell[#cell]
                    cell[#cell] = nil
                    break
                end
            end
            if #cell == 0 then
                self.cells[h] = nil
            end
        end
    end
    self.bodyCells[body.id] = nil
end

function SHG3D:updateBody(body)
    self:remove(body)
    self:insert(body)
end

function SHG3D:queryAABB(minX, minY, minZ, maxX, maxY, maxZ)
    local result = {}
    local seen = {}
    local x0, y0, z0, x1, y1, z1 = self:_cellCoords(minX, minY, minZ, maxX, maxY, maxZ)
    for cx = x0, x1 do
        for cy = y0, y1 do
            for cz = z0, z1 do
                local h = self:_hash(cx, cy, cz)
                local cell = self.cells[h]
                if cell then
                    for i = 1, #cell do
                        local b = cell[i]
                        if not seen[b.id] then
                            seen[b.id] = true
                            result[#result + 1] = b
                        end
                    end
                end
            end
        end
    end
    return result
end

function SHG3D:broadphasePairs()
    local pairs = {}
    local pairSet = {}
    local cells = self.cells
    for _, cell in pairs(cells) do
        local n = #cell
        for i = 1, n do
            local a = cell[i]
            for j = i + 1, n do
                local b = cell[j]
                if a.id ~= b.id then
                    local minId, maxId
                    if a.id < b.id then
                        minId, maxId = a.id, b.id
                    else
                        minId, maxId = b.id, a.id
                    end
                    local key = tostring(minId) .. "#" .. tostring(maxId)
                    if not pairSet[key] then
                        pairSet[key] = true
                        if a.aabbMinX3 <= b.aabbMaxX3 and a.aabbMaxX3 >= b.aabbMinX3 and
                           a.aabbMinY3 <= b.aabbMaxY3 and a.aabbMaxY3 >= b.aabbMinY3 and
                           a.aabbMinZ3 <= b.aabbMaxZ3 and a.aabbMaxZ3 >= b.aabbMinZ3 then
                            pairs[#pairs + 1] = a
                            pairs[#pairs + 1] = b
                        end
                    end
                end
            end
        end
    end
    return pairs
end


return {
    SHG2D = SHG2D,
    SHG3D = SHG3D,
}
