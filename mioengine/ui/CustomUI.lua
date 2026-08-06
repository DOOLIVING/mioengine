local UI = {}
UI.__index = UI

local defaultFont = nil
local activeInput = nil
local tooltipText = nil
local tooltipTimer = 0
local hoveredButton = nil

local fontCache = {}
local function getFont(size)
    size = size or 14
    if not fontCache[size] then
        fontCache[size] = love.graphics.newFont(size)
    end
    return fontCache[size]
end

function UI.drawText(text, x, y, size, r, g, b, a, align)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.setFont(getFont(size))
    if align == "center" then
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, x - w / 2, y)
    elseif align == "right" then
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, x - w, y)
    else
        love.graphics.print(text, x, y)
    end
end

function UI.drawTextShadow(text, x, y, size, r, g, b, a, offset, sr, sg, sb, sa)
    offset = offset or 2
    sr = sr or 0; sg = sg or 0; sb = sb or 0; sa = sa or 0.5
    UI.drawText(text, x + offset, y + offset, size, sr, sg, sb, sa)
    UI.drawText(text, x, y, size, r, g, b, a)
end

function UI.drawTexture(texture, x, y, sx, sy, r, ox, oy, kx, ky)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(texture, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0, kx or 0, ky or 0)
end

function UI.drawTextureScaled(texture, x, y, w, h, r, ox, oy)
    local tw, th = texture:getDimensions()
    local sx = w / tw
    local sy = h / th
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(texture, x, y, r or 0, sx, sy, ox or 0, oy or 0)
end

function UI.drawTextureBlended(texture, x, y, blendMode, sx, sy, r, ox, oy)
    local prev = love.graphics.getBlendMode()
    love.graphics.setBlendMode(blendMode or "alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(texture, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0)
    love.graphics.setBlendMode(prev)
end

function UI.drawRect(x, y, w, h, r, g, b, a, radius)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    if radius and radius > 0 then
        love.graphics.rectangle("fill", x, y, w, h, radius)
    else
        love.graphics.rectangle("fill", x, y, w, h)
    end
end

function UI.drawRectOutline(x, y, w, h, r, g, b, a, lineWidth, radius)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.setLineWidth(lineWidth or 1)
    if radius and radius > 0 then
        love.graphics.rectangle("line", x, y, w, h, radius)
    else
        love.graphics.rectangle("line", x, y, w, h)
    end
    love.graphics.setLineWidth(1)
end

function UI.drawRoundedRect(x, y, w, h, r, g, b, a, radius)
    UI.drawRect(x, y, w, h, r, g, b, a, radius)
end

function UI.drawPanel(x, y, w, h, bgColor, borderColor, radius)
    bgColor = bgColor or { 0.1, 0.12, 0.18, 0.92 }
    borderColor = borderColor or { 0.25, 0.3, 0.4 }
    radius = radius or 6
    UI.drawRect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4], radius)
    UI.drawRectOutline(x, y, w, h, borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1, 1, radius)
end

function UI.drawLine(x1, y1, x2, y2, r, g, b, a, width)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.setLineWidth(width or 1)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setLineWidth(1)
end

function UI.drawCrosshair(cx, cy, size, r, g, b, a)
    size = size or 8
    r = r or 1; g = g or 1; b = b or 1; a = a or 0.7
    UI.drawLine(cx - size, cy, cx + size, cy, r, g, b, a)
    UI.drawLine(cx, cy - size, cx, cy + size, r, g, b, a)
end

function UI.drawCircle(cx, cy, radius, r, g, b, a, segments)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.circle("fill", cx, cy, radius, segments or 24)
end

function UI.drawCircleOutline(cx, cy, radius, r, g, b, a, width, segments)
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    love.graphics.setLineWidth(width or 1)
    love.graphics.circle("line", cx, cy, radius, segments or 24)
    love.graphics.setLineWidth(1)
end

function UI.drawButton(x, y, w, h, label, state, opts)
    opts = opts or {}
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h

    local bg    = opts.bg or { 0.15, 0.2, 0.35 }
    local bgHov = opts.bgHover or { 0.22, 0.32, 0.52 }
    local bgAct = opts.bgActive or { 0.18, 0.45, 0.7 }
    local fg    = opts.fg or { 0.9, 0.9, 0.9 }
    local radius = opts.radius or 5
    local fontSize = opts.fontSize or 14

    local col = bg
    if state == "active" then
        col = bgAct
    elseif hovered then
        col = bgHov
    end

    UI.drawRect(x, y, w, h, col[1], col[2], col[3], col[4] or 1, radius)
    UI.drawText(label, x + w / 2, y + h / 2 - fontSize / 2, fontSize, fg[1], fg[2], fg[3], fg[4] or 1, "center")

    return hovered
end

function UI.isButtonClicked(x, y, w, h, button)
    if button ~= 1 then return false end
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI.drawLabel(x, y, text, opts)
    opts = opts or {}
    local size = opts.fontSize or 14
    local r = opts.r or 0.85
    local g = opts.g or 0.85
    local b = opts.b or 0.85
    local a = opts.a or 1
    local align = opts.align or "left"
    local shadow = opts.shadow

    if shadow then
        UI.drawTextShadow(text, x, y, size, r, g, b, a)
    else
        UI.drawText(text, x, y, size, r, g, b, a, align)
    end
end

function UI.drawSlider(x, y, w, h, value, min, max, opts)
    opts = opts or {}
    local trackColor  = opts.track or { 0.18, 0.2, 0.28 }
    local fillColor   = opts.fill or { 0.25, 0.55, 0.85 }
    local knobColor   = opts.knob or { 0.9, 0.9, 0.9 }
    local radius      = opts.radius or 4
    local vertical    = opts.vertical

    UI.drawRect(x, y, w, h, trackColor[1], trackColor[2], trackColor[3], trackColor[4] or 1, radius)

    local t = math.max(0, math.min(1, (value - min) / (max - min)))
    if vertical then
        local fillH = h * t
        UI.drawRect(x, y + h - fillH, w, fillH, fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1, radius)
    else
        local fillW = w * t
        UI.drawRect(x, y, fillW, h, fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1, radius)
    end

    local knobR = h * 0.7
    local kx, ky
    if vertical then
        kx = x + w / 2
        ky = y + h - h * t
    else
        kx = x + w * t
        ky = y + h / 2
    end
    UI.drawCircle(kx, ky, knobR / 2, knobColor[1], knobColor[2], knobColor[3], knobColor[4] or 1)

    return t
end

function UI.sliderInteraction(x, y, w, h, value, min, max, opts)
    opts = opts or {}
    local vertical = opts.vertical
    local dragging = opts.dragging
    local mx, my = love.mouse.getPosition()

    if dragging then
        local t
        if vertical then
            t = 1 - (my - y) / h
        else
            t = (mx - x) / w
        end
        t = math.max(0, math.min(1, t))
        return min + t * (max - min), true
    end

    return value, false
end

function UI.drawProgressBar(x, y, w, h, value, max, opts)
    opts = opts or {}
    local bgColor   = opts.bg or { 0.12, 0.14, 0.2 }
    local fillColor = opts.fill or { 0.2, 0.65, 0.35 }
    local borderColor = opts.border or { 0.25, 0.3, 0.38 }
    local radius    = opts.radius or 4
    local showText  = opts.showText

    UI.drawRect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1, radius)

    local t = math.max(0, math.min(1, value / math.max(max, 1)))
    if t > 0 then
        UI.drawRect(x, y, w * t, h, fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1, radius)
    end

    UI.drawRectOutline(x, y, w, h, borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1, 1, radius)

    if showText then
        UI.drawText(string.format("%d / %d", value, max), x + w / 2, y + h / 2 - 6, 12, 1, 1, 1, 1, "center")
    end
end

function UI.drawCheckbox(x, y, size, checked, opts)
    opts = opts or {}
    local boxColor  = opts.box or { 0.15, 0.18, 0.25 }
    local checkColor = opts.check or { 0.25, 0.7, 0.4 }
    local border    = opts.border or { 0.3, 0.35, 0.45 }
    local radius    = opts.radius or 3

    UI.drawRect(x, y, size, size, boxColor[1], boxColor[2], boxColor[3], boxColor[4] or 1, radius)
    UI.drawRectOutline(x, y, size, size, border[1], border[2], border[3], border[4] or 1, 1, radius)

    if checked then
        local pad = size * 0.2
        UI.drawRect(x + pad, y + pad, size - pad * 2, size - pad * 2,
            checkColor[1], checkColor[2], checkColor[3], checkColor[4] or 1, radius - 1)
    end
end

function UI.isCheckboxClicked(x, y, size, button)
    if button ~= 1 then return false end
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + size and my >= y and my <= y + size
end

function UI.drawTextInput(x, y, w, h, text, isActive, opts)
    opts = opts or {}
    local bgColor  = opts.bg or { 0.08, 0.1, 0.16 }
    local borderColor = opts.border or { 0.25, 0.35, 0.55 }
    local textColor = opts.text or { 0.85, 0.88, 0.95 }
    local radius   = opts.radius or 4
    local fontSize = opts.fontSize or 14
    local placeholder = opts.placeholder or ""

    UI.drawRect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1, radius)

    local bc = borderColor
    if isActive then
        bc = opts.borderActive or { 0.3, 0.55, 0.85 }
    end
    UI.drawRectOutline(x, y, w, h, bc[1], bc[2], bc[3], bc[4] or 1, isActive and 2 or 1, radius)

    local displayText = #text > 0 and text or placeholder
    local tc = textColor
    if #text == 0 then
        tc = { 0.4, 0.42, 0.48 }
    end
    UI.drawText(displayText, x + 8, y + h / 2 - fontSize / 2, fontSize, tc[1], tc[2], tc[3], tc[4] or 1)

    if isActive then
        local ct = love.timer.getTime()
        if math.floor(ct * 2) % 2 == 0 then
            local tw = getFont(fontSize):getWidth(text)
            UI.drawLine(x + 8 + tw + 2, y + 4, x + 8 + tw + 2, y + h - 4,
                textColor[1], textColor[2], textColor[3], 0.8, 1)
        end
    end
end

function UI.isTextInputClicked(x, y, w, h, button)
    if button ~= 1 then return false end
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI.setTooltip(text, delay)
    tooltipText = text
    tooltipTimer = delay or 0.5
end

function UI.drawTooltip(dt)
    if not tooltipText or tooltipTimer > 0 then
        if tooltipTimer > 0 then tooltipTimer = tooltipTimer - dt end
        return
    end

    local mx, my = love.mouse.getPosition()
    local fontSize = 12
    local tw = getFont(fontSize):getWidth(tooltipText)
    local th = fontSize + 8
    local pad = 6

    local tx = mx + 12
    local ty = my + 12
    local sw, sh = love.graphics.getDimensions()
    if tx + tw + pad * 2 > sw then tx = mx - tw - pad * 2 - 12 end
    if ty + th + pad * 2 > sh then ty = my - th - pad * 2 - 12 end

    UI.drawPanel(tx, ty, tw + pad * 2, th + pad * 2, { 0.08, 0.1, 0.16, 0.95 }, { 0.3, 0.35, 0.5 }, 4)
    UI.drawText(tooltipText, tx + pad, ty + pad, fontSize, 0.9, 0.9, 0.9, 1)
end

function UI.clearTooltip()
    tooltipText = nil
    tooltipTimer = 0
end

function UI.drawSection(x, y, w, h, title, opts)
    opts = opts or {}
    local bgColor = opts.bg or { 0.1, 0.12, 0.18, 0.88 }
    local titleColor = opts.titleColor or { 0.3, 0.65, 0.9 }
    local radius = opts.radius or 6
    local fontSize = opts.fontSize or 14

    UI.drawRect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1, radius)

    if title then
        UI.drawRect(x, y, w, fontSize + 12, bgColor[1] + 0.03, bgColor[2] + 0.03, bgColor[3] + 0.05, bgColor[4] or 1, radius)
        UI.drawText(title, x + 10, y + 6, fontSize, titleColor[1], titleColor[2], titleColor[3], titleColor[4] or 1)
    end
end

function UI.drawSeparator(x, y, w, opts)
    opts = opts or {}
    local color = opts.color or { 0.25, 0.3, 0.4 }
    local thickness = opts.thickness or 1
    local margin = opts.margin or 0

    UI.drawLine(x + margin, y, x + w - margin, y, color[1], color[2], color[3], color[4] or 0.6, thickness)
end

function UI.drawScrollList(x, y, w, h, items, scrollY, opts)
    opts = opts or {}
    local itemHeight = opts.itemHeight or 28
    local bgColor = opts.bg or { 0.08, 0.1, 0.16 }
    local hoverColor = opts.hover or { 0.18, 0.25, 0.4 }
    local selectedColor = opts.selected or { 0.15, 0.35, 0.6 }
    local fontSize = opts.fontSize or 13
    local radius = opts.radius or 4

    UI.drawRect(x, y, w, h, bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1, radius)

    love.graphics.setScissor(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    local clicked = -1

    for i, item in ipairs(items) do
        local iy = y + (i - 1) * itemHeight + scrollY
        if iy + itemHeight > y and iy < y + h then
            local isHover = mx >= x and mx <= x + w and my >= iy and my <= iy + itemHeight
            local isSel = opts.selectedIdx == i

            if isSel then
                UI.drawRect(x + 2, iy + 1, w - 4, itemHeight - 2, selectedColor[1], selectedColor[2], selectedColor[3], selectedColor[4] or 1, 3)
            elseif isHover then
                UI.drawRect(x + 2, iy + 1, w - 4, itemHeight - 2, hoverColor[1], hoverColor[2], hoverColor[3], hoverColor[4] or 1, 3)
            end

            UI.drawText(tostring(item), x + 10, iy + itemHeight / 2 - fontSize / 2, fontSize, 0.85, 0.85, 0.85, 1)

            if isHover and love.mouse.isDown(1) then
                clicked = i
            end
        end
    end

    love.graphics.setScissor()

    local totalH = #items * itemHeight
    if totalH > h then
        local sbW = 6
        local sbH = math.max(20, h * h / totalH)
        local sbY = y + (-scrollY / totalH) * (h - sbH)
        UI.drawRect(x + w - sbW - 2, sbY, sbW, sbH, 0.3, 0.35, 0.45, 0.6, 3)
    end

    return clicked
end

function UI.measureText(text, size)
    return getFont(size):getWidth(text)
end

function UI.getScreenSize()
    return love.graphics.getDimensions()
end

function UI.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function UI.lerp(a, b, t)
    return a + (b - a) * t
end

function UI.color(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

return UI
