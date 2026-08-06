local SpriteBatch2D = {}
SpriteBatch2D.__index = SpriteBatch2D

function SpriteBatch2D.new(resources)
    local self = setmetatable({}, SpriteBatch2D)
    self.batches = {}
    self.resources = resources
    return self
end

function SpriteBatch2D:draw(imagePath, x, y, r, g, b, a, sx, sy, ox, oy, quad)
    if not self.batches[imagePath] then
        self.batches[imagePath] = {}
    end
    self.batches[imagePath][#self.batches[imagePath] + 1] = {
        x = x or 0, y = y or 0,
        r = r or 1, g = g or 1, b = b or 1, a = a or 1,
        sx = sx or 1, sy = sy or sx or 1,
        ox = ox or 0, oy = oy or 0,
        quad = quad,
    }
end

function SpriteBatch2D:flush()
    for imagePath, sprites in pairs(self.batches) do
        local img
        if self.resources then
            img = self.resources:getImage(imagePath)
        else
            local ok, image = pcall(love.graphics.newImage, imagePath)
            if ok then img = image end
        end
        if img then
            for _, s in ipairs(sprites) do
                love.graphics.setColor(s.r, s.g, s.b, s.a)
                if s.quad then
                    love.graphics.draw(img, s.quad, s.x, s.y, 0, s.sx, s.sy, s.ox, s.oy)
                else
                    love.graphics.draw(img, s.x, s.y, 0, s.sx, s.sy, s.ox, s.oy)
                end
            end
            love.graphics.setColor(1, 1, 1, 1)
        else
            print("[SpriteBatch2D] Cannot load: " .. imagePath)
        end
    end
    self.batches = {}
end

function SpriteBatch2D:clear()
    self.batches = {}
end

return SpriteBatch2D
