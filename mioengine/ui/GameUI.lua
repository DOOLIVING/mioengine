local GameUI = {}
GameUI.__index = GameUI

local texCache = {}
local fontCache = {}

local function getTex(path)
    if texCache[path] then return texCache[path] end
    local ok, img = pcall(love.graphics.newImage, path)
    if ok then
        img:setFilter("nearest", "nearest")
        texCache[path] = img
        return img
    end
    return nil
end

local function getFont(size)
    size = size or 8
    if not fontCache[size] then
        fontCache[size] = love.graphics.newFont(size)
    end
    return fontCache[size]
end

function GameUI.texRect(renderer, quadX, quadY, quadW, quadH, x, y, w, h, r, g, b, a)
    local tex = renderer.texture
    if not tex then return end
    local tw, th = tex:getDimensions()
    if quadX + quadW > tw then quadW = tw - quadX end
    if quadY + quadH > th then quadH = th - quadY end
    local quad = love.graphics.newQuad(quadX, quadY, quadW, quadH, tw, th)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.draw(tex, quad, x, y, 0, w / quadW, h / quadH)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.texQuad(renderer, quadX, quadY, quadW, quadH, x, y, sx, sy, r, g, b, a)
    local tex = renderer.texture
    if not tex then return end
    local tw, th = tex:getDimensions()
    if quadX + quadW > tw then quadW = tw - quadX end
    if quadY + quadH > th then quadH = th - quadY end
    local quad = love.graphics.newQuad(quadX, quadY, quadW, quadH, tw, th)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.draw(tex, quad, x, y, 0, sx or 1, sy or 1)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.tex9Patch(renderer, quadX, quadY, quadW, quadH, x, y, w, h, border, r, g, b, a)
    local tex = renderer.texture
    if not tex then return end
    local tw, th = tex:getDimensions()
    if quadX + quadW > tw then quadW = tw - quadX end
    if quadY + quadH > th then quadH = th - quadY end
    local quad = love.graphics.newQuad(quadX, quadY, quadW, quadH, tw, th)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)

    local bL = border or 2
    local bR = border or 2
    local bT = border or 2
    local bB = border or 2
    local innerW = w - bL - bR
    local innerH = h - bT - bB
    local tileW = quadW - bL - bR
    local tileH = quadH - bT - bB

    if tileW > 0 and innerW > 0 then
        love.graphics.draw(tex, quad, x + bL, y + bT, 0, innerW / tileW, innerH / tileH)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.rect(x, y, w, h, r, g, b, a)
    love.graphics.setColor(r or 0, g or 0, b or 0, a or 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.rectOutline(x, y, w, h, r, g, b, a, lw)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.roundRect(x, y, w, h, r, g, b, a, rad)
    love.graphics.setColor(r or 0, g or 0, b or 0, a or 1)
    love.graphics.rectangle("fill", x, y, w, h, rad or 2)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.text(text, x, y, size, r, g, b, a, align)
    love.graphics.setFont(getFont(size or 8))
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    if align == "center" then
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, x - w / 2, y)
    elseif align == "right" then
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, x - w, y)
    else
        love.graphics.print(text, x, y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.textShadow(text, x, y, size, r, g, b, a, off)
    off = off or 1
    GameUI.text(text, x + off, y + off, size, 0, 0, 0, (a or 1) * 0.6)
    GameUI.text(text, x, y, size, r, g, b, a)
end

function GameUI.healthBar(renderer, x, y, current, max, w, h, opts)
    opts = opts or {}
    local segments = opts.segments or 10
    local gap = opts.gap or 1
    local bgColor = opts.bg or { 0.15, 0.05, 0.05, 0.8 }
    local fillColor = opts.fill or { 0.8, 0.1, 0.1, 1 }
    local emptyColor = opts.empty or { 0.3, 0.15, 0.15, 0.6 }
    local borderColor = opts.border or { 0.5, 0.2, 0.2, 1 }
    local radius = opts.radius or 1

    GameUI.rect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    local segW = (w - gap * (segments - 1)) / segments
    local filled = math.ceil((current / math.max(max, 1)) * segments)

    for i = 0, segments - 1 do
        local sx = x + i * (segW + gap)
        local col = i < filled and fillColor or emptyColor
        love.graphics.setColor(col[1], col[2], col[3], col[4])
        love.graphics.rectangle("fill", sx, y, segW, h, radius, radius)
    end

    GameUI.rectOutline(x - 1, y - 1, w + 2, h + 2, borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.healthBarTex(renderer, x, y, current, max, texX, texY, texW, texH, count, opts)
    opts = opts or {}
    local gap = opts.gap or 1
    local emptyTexX = opts.emptyTexX or texX
    local emptyTexY = opts.emptyTexY or texY + texH
    local r = opts.r or 1
    local g = opts.g or 1
    local b = opts.b or 1
    local a = opts.a or 1
    local scale = opts.scale or 1
    local full = math.ceil((current / math.max(max, 1)) * count)

    for i = 0, count - 1 do
        local sx = x + i * (texW * scale + gap)
        if i < full then
            GameUI.texQuad(renderer, texX, texY, texW, texH, sx, y, scale, scale, r, g, b, a)
        else
            GameUI.texQuad(renderer, emptyTexX, emptyTexY, texW, texH, sx, y, scale, scale, r, g, b, a * 0.5)
        end
    end
end

function GameUI.hearts(x, y, current, max, heartSize, gap, opts)
    opts = opts or {}
    local rF = opts.rFull or 0.9
    local gF = opts.gFull or 0.1
    local bF = opts.bFull or 0.15
    local rE = opts.rEmpty or 0.3
    local gE = opts.gEmpty or 0.12
    local bE = opts.bEmpty or 0.12
    local a = opts.a or 1
    local full = math.ceil((current / math.max(max, 1)) * max)

    for i = 0, max - 1 do
        local hx = x + i * (heartSize + gap)
        local isFull = i < full

        local r = isFull and rF or rE
        local g = isFull and gF or gE
        local b = isFull and bF or bE

        local cx = hx + heartSize / 2
        local cy = y + heartSize / 2
        local s = heartSize * 0.3

        love.graphics.setColor(r, g, b, a)
        love.graphics.polygon("fill",
            cx, cy + s * 0.3,
            cx - s, cy - s * 0.3,
            cx - s * 0.5, cy - s,
            cx, cy - s * 0.5,
            cx + s * 0.5, cy - s,
            cx + s, cy - s * 0.3
        )

        love.graphics.setColor(0, 0, 0, a * 0.4)
        love.graphics.polygon("line",
            cx, cy + s * 0.3,
            cx - s, cy - s * 0.3,
            cx - s * 0.5, cy - s,
            cx, cy - s * 0.5,
            cx + s * 0.5, cy - s,
            cx + s, cy - s * 0.3
        )
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.bar(x, y, w, h, value, max, fg, bg, border)
    bg = bg or { 0.1, 0.1, 0.1, 0.8 }
    fg = fg or { 0.2, 0.7, 0.3, 1 }
    border = border or { 0.4, 0.4, 0.4, 1 }
    local t = math.max(0, math.min(1, value / math.max(max, 1)))

    GameUI.rect(x, y, w, h, bg[1], bg[2], bg[3], bg[4])
    if t > 0 then
        GameUI.rect(x, y, w * t, h, fg[1], fg[2], fg[3], fg[4])
    end
    GameUI.rectOutline(x, y, w, h, border[1], border[2], border[3], border[4])
end

function GameUI.icon(renderer, quadX, quadY, quadW, quadH, x, y, scale, r, g, b, a)
    GameUI.texQuad(renderer, quadX, quadY, quadW, quadH, x, y, scale or 1, scale or 1, r, g, b, a)
end

function GameUI.iconList(renderer, quadX, quadY, quadW, quadH, x, y, count, scale, gap, r, g, b, a)
    for i = 0, count - 1 do
        local ix = x + i * (quadW * (scale or 1) + (gap or 1))
        GameUI.texQuad(renderer, quadX, quadY, quadW, quadH, ix, y, scale or 1, scale or 1, r, g, b, a)
    end
end

function GameUI.sprite(path, x, y, sx, sy, r, g, b, a)
    local tex = getTex(path)
    if not tex then return end
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.draw(tex, x, y, 0, sx or 1, sy or 1)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.spriteSheet(path, quadX, quadY, quadW, quadH, x, y, sx, sy, r, g, b, a)
    local tex = getTex(path)
    if not tex then return end
    local tw, th = tex:getDimensions()
    local quad = love.graphics.newQuad(quadX, quadY, quadW, quadH, tw, th)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.draw(tex, quad, x, y, 0, sx or 1, sy or 1)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.damageFlash(intensity, w, h)
    if intensity <= 0 then return end
    love.graphics.setColor(0.8, 0.05, 0.05, intensity * 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local edge = 4
    love.graphics.setColor(0.9, 0.1, 0.1, intensity * 0.7)
    love.graphics.rectangle("fill", 0, 0, w, edge)
    love.graphics.rectangle("fill", 0, h - edge, w, edge)
    love.graphics.rectangle("fill", 0, 0, edge, h)
    love.graphics.rectangle("fill", w - edge, 0, edge, h)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.vignette(w, h, intensity)
    intensity = intensity or 0.4
    local steps = 8
    for i = 0, steps - 1 do
        local t = i / steps
        local a = t * t * intensity
        local m = t * 30
        love.graphics.setColor(0, 0, 0, a)
        love.graphics.rectangle("fill", 0, 0, w, m)
        love.graphics.rectangle("fill", 0, h - m, w, m)
        love.graphics.rectangle("fill", 0, 0, m, h)
        love.graphics.rectangle("fill", w - m, 0, m, h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.scanlines(w, h, alpha, spacing)
    alpha = alpha or 0.08
    spacing = spacing or 2
    love.graphics.setColor(0, 0, 0, alpha)
    for y = 0, h, spacing do
        love.graphics.rectangle("fill", 0, y, w, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.screenBorder(w, h, thickness, r, g, b, a)
    thickness = thickness or 2
    r = r or 0; g = g or 0; b = b or 0; a = a or 0.6
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", 0, 0, w, thickness)
    love.graphics.rectangle("fill", 0, h - thickness, w, thickness)
    love.graphics.rectangle("fill", 0, 0, thickness, h)
    love.graphics.rectangle("fill", w - thickness, 0, thickness, h)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.crosshair(x, y, size, gap, thickness, r, g, b, a)
    size = size or 6
    gap = gap or 2
    thickness = thickness or 1
    r = r or 1; g = g or 1; b = b or 1; a = a or 0.8

    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(thickness)
    love.graphics.line(x - size, y, x - gap, y)
    love.graphics.line(x + gap, y, x + size, y)
    love.graphics.line(x, y - size, x, y - gap)
    love.graphics.line(x, y + gap, x, y + size)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameUI.crosshairTex(renderer, quadX, quadY, quadW, quadH, x, y, scale)
    GameUI.texQuad(renderer, quadX, quadY, quadW, quadH, x - quadW * (scale or 1) / 2, y - quadH * (scale or 1) / 2, scale, scale)
end

function GameUI.minimap(x, y, w, h, playerX, playerZ, mapScale, objects, opts)
    opts = opts or {}
    local bgColor = opts.bg or { 0.05, 0.08, 0.12, 0.85 }
    local playerColor = opts.player or { 0.2, 0.8, 0.3 }
    local objColor = opts.obj or { 0.5, 0.5, 0.6 }
    local borderColor = opts.border or { 0.3, 0.35, 0.45 }
    local radius = opts.radius or 3

    GameUI.rect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    love.graphics.setScissor(x + 1, y + 1, w - 2, h - 2)

    if objects then
        for _, obj in ipairs(objects) do
            local ox = x + w / 2 + (obj.x - playerX) * mapScale
            local oy = y + h / 2 + (obj.z - playerZ) * mapScale
            if ox > x and ox < x + w and oy > y and oy < y + h then
                love.graphics.setColor(objColor[1], objColor[2], objColor[3], objColor[4] or 1)
                love.graphics.rectangle("fill", ox - 1, oy - 1, 2, 2)
            end
        end
    end

    love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], 1)
    love.graphics.rectangle("fill", x + w / 2 - 2, y + h / 2 - 2, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setScissor()
    GameUI.rectOutline(x, y, w, h, borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

function GameUI.notify(x, y, text, timer, maxTimer, opts)
    opts = opts or {}
    local fontSize = opts.fontSize or 8
    local bgColor = opts.bg or { 0.1, 0.15, 0.25, 0.85 }
    local textColor = opts.text or { 0.9, 0.9, 0.9 }
    local fadeStart = maxTimer * 0.3

    local alpha = 1
    if timer < fadeStart then
        alpha = timer / fadeStart
    end

    local tw = getFont(fontSize):getWidth(text)
    local pad = 4
    local nw = tw + pad * 2
    local nh = fontSize + pad * 2

    GameUI.rect(x - nw / 2, y, nw, nh, bgColor[1], bgColor[2], bgColor[3], bgColor[4] * alpha)
    GameUI.text(text, x, y + pad, fontSize, textColor[1], textColor[2], textColor[3], alpha, "center")
end

function GameUI.panel(x, y, w, h, opts)
    opts = opts or {}
    local bg = opts.bg or { 0.08, 0.1, 0.16, 0.9 }
    local border = opts.border or { 0.2, 0.25, 0.35 }
    local radius = opts.radius or 4

    GameUI.rect(x, y, w, h, bg[1], bg[2], bg[3], bg[4])
    GameUI.rectOutline(x, y, w, h, border[1], border[2], border[3], border[4] or 1)
end

function GameUI.panelTex9(renderer, quadX, quadY, quadW, quadH, x, y, w, h, border, r, g, b, a)
    GameUI.tex9Patch(renderer, quadX, quadY, quadW, quadH, x, y, w, h, border, r, g, b, a)
end

function GameUI.ammo(x, y, current, max, opts)
    opts = opts or {}
    local fontSize = opts.fontSize or 16
    local r = opts.r or 0.9
    local g = opts.g or 0.85
    local b = opts.b or 0.3

    GameUI.textShadow(string.format("%d", current), x, y, fontSize, r, g, b, 1, 1)
    if max then
        GameUI.text(string.format("/ %d", max), x + fontSize * 2, y + 4, fontSize * 0.6, 0.5, 0.5, 0.5, 0.8)
    end
end

function GameUI.score(x, y, value, opts)
    opts = opts or {}
    local fontSize = opts.fontSize or 10
    local prefix = opts.prefix or "SCORE: "
    GameUI.textShadow(prefix .. tostring(value), x, y, fontSize, 0.9, 0.9, 0.9, 1, 1)
end

function GameUI.fps(x, y)
    GameUI.text(string.format("FPS: %d", love.timer.getFPS()), x, y, 7, 0.5, 0.8, 0.3, 0.7)
end

return GameUI
