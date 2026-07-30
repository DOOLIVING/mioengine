local Texture = {}

local loaded = {}

function Texture.get(path)
    if loaded[path] then return loaded[path] end
    local ok, img = pcall(love.graphics.newImage, path)
    if ok then
        img:setFilter("nearest", "nearest")
        loaded[path] = img
        return img
    end
    return nil
end

return Texture
