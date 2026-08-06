local UIElements = {}
UIElements.__index = UIElements

local fontCache = {}
local function getFont(size, resources)
    size = size or 14
    if resources then
        return resources:getFont(size)
    end
    if not fontCache[size] then
        fontCache[size] = love.graphics.newFont(size)
    end
    return fontCache[size]
end

function UIElements.new(resources)
    local self = setmetatable({}, UIElements)
    self.buttons = {}
    self.checkboxes = {}
    self.sliders = {}
    self.labels = {}
    self._nextId = 1
    self.resources = resources
    return self
end

function UIElements:_genId(prefix)
    local id = prefix .. "_" .. self._nextId
    self._nextId = self._nextId + 1
    return id
end

function UIElements:button(x, y, w, h, label, opts)
    opts = opts or {}
    local id = opts.id or self:_genId("btn")

    if not self.buttons[id] then
        self.buttons[id] = {
            x = x, y = y, w = w, h = h,
            label = label,
            hovered = false,
            clicked = false,
            justClicked = false,
            bg = opts.bg or { 0.15, 0.2, 0.35 },
            bgHover = opts.bgHover or { 0.22, 0.32, 0.52 },
            bgActive = opts.bgActive or { 0.18, 0.45, 0.7 },
            fg = opts.fg or { 0.9, 0.9, 0.9 },
            radius = opts.radius or 5,
            fontSize = opts.fontSize or 14,
            visible = true,
        }
    end

    local b = self.buttons[id]
    b.x = x
    b.y = y
    b.w = w
    b.h = h
    b.label = label

    local mx, my = love.mouse.getPosition()
    b.hovered = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h

    local wasClicked = b.clicked
    b.clicked = false
    b.justClicked = false

    if b.hovered and love.mouse.isDown(1) and not wasClicked then
        b.clicked = true
        b.justClicked = true
    elseif not love.mouse.isDown(1) then
        b.clicked = false
    end

    return b
end

function UIElements:buttonClicked(x, y, w, h, label, opts)
    local b = self:button(x, y, w, h, label, opts)
    return b.justClicked
end

function UIElements:checkbox(x, y, size, checked, opts)
    opts = opts or {}
    local id = opts.id or self:_genId("chk")

    if not self.checkboxes[id] then
        self.checkboxes[id] = {
            x = x, y = y, size = size,
            checked = checked,
            justToggled = false,
            bg = opts.bg or { 0.15, 0.18, 0.25 },
            check = opts.check or { 0.25, 0.7, 0.4 },
            border = opts.border or { 0.3, 0.35, 0.45 },
            radius = opts.radius or 3,
            visible = true,
        }
    end

    local c = self.checkboxes[id]
    c.x = x
    c.y = y
    c.size = size
    c.checked = checked
    c.justToggled = false

    local mx, my = love.mouse.getPosition()
    local hovered = mx >= c.x and mx <= c.x + c.size and my >= c.y and my <= c.y + c.size

    if hovered and love.mouse.isDown(1) and not c._wasDown then
        c.checked = not c.checked
        c.justToggled = true
    end
    c._wasDown = love.mouse.isDown(1)

    return c
end

function UIElements:slider(x, y, w, h, value, minVal, maxVal, opts)
    opts = opts or {}
    local id = opts.id or self:_genId("sld")

    if not self.sliders[id] then
        self.sliders[id] = {
            x = x, y = y, w = w, h = h,
            value = value, minVal = minVal, maxVal = maxVal,
            dragging = false,
            track = opts.track or { 0.18, 0.2, 0.28 },
            fill = opts.fill or { 0.25, 0.55, 0.85 },
            knob = opts.knob or { 0.9, 0.9, 0.9 },
            radius = opts.radius or 4,
            vertical = opts.vertical or false,
            visible = true,
        }
    end

    local s = self.sliders[id]
    s.x = x
    s.y = y
    s.w = w
    s.h = h
    s.minVal = minVal
    s.maxVal = maxVal

    local mx, my = love.mouse.getPosition()
    local hovered = mx >= s.x and mx <= s.x + s.w and my >= s.y and my <= s.y + s.h

    if hovered and love.mouse.isDown(1) and not s.dragging then
        s.dragging = true
    elseif not love.mouse.isDown(1) then
        s.dragging = false
    end

    if s.dragging then
        local t = (mx - s.x) / s.w
        t = math.max(0, math.min(1, t))
        s.value = s.minVal + t * (s.maxVal - s.minVal)
    end

    return s
end

function UIElements:label(x, y, text, opts)
    opts = opts or {}
    local id = opts.id or self:_genId("lbl")

    if not self.labels[id] then
        self.labels[id] = {
            x = x, y = y, text = text,
            fontSize = opts.fontSize or 14,
            r = opts.r or 0.85,
            g = opts.g or 0.85,
            b = opts.b or 0.85,
            a = opts.a or 1,
            align = opts.align or "left",
            visible = true,
        }
    end

    local l = self.labels[id]
    l.x = x
    l.y = y
    l.text = text

    return l
end

function UIElements:draw()
    for _, b in pairs(self.buttons) do
        if b.visible then
            local col = b.bg
            if b.clicked then
                col = b.bgActive
            elseif b.hovered then
                col = b.bgHover
            end
            love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
            love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, b.radius)
            love.graphics.setFont(getFont(b.fontSize, self.resources))
            love.graphics.setColor(b.fg[1], b.fg[2], b.fg[3], b.fg[4] or 1)
            local tw = getFont(b.fontSize, self.resources):getWidth(b.label)
            love.graphics.print(b.label, b.x + b.w / 2 - tw / 2, b.y + b.h / 2 - b.fontSize / 2)
        end
    end

    for _, c in pairs(self.checkboxes) do
        if c.visible then
            love.graphics.setColor(c.bg[1], c.bg[2], c.bg[3], c.bg[4] or 1)
            love.graphics.rectangle("fill", c.x, c.y, c.size, c.size, c.radius)
            love.graphics.setColor(c.border[1], c.border[2], c.border[3], c.border[4] or 1)
            love.graphics.rectangle("line", c.x, c.y, c.size, c.size, c.radius)
            if c.checked then
                local pad = c.size * 0.2
                love.graphics.setColor(c.check[1], c.check[2], c.check[3], c.check[4] or 1)
                love.graphics.rectangle("fill", c.x + pad, c.y + pad, c.size - pad * 2, c.size - pad * 2, c.radius - 1)
            end
        end
    end

    for _, s in pairs(self.sliders) do
        if s.visible then
            love.graphics.setColor(s.track[1], s.track[2], s.track[3], s.track[4] or 1)
            love.graphics.rectangle("fill", s.x, s.y, s.w, s.h, s.radius)

            local t = math.max(0, math.min(1, (s.value - s.minVal) / math.max(s.maxVal - s.minVal, 0.001)))
            local fillW = s.w * t
            love.graphics.setColor(s.fill[1], s.fill[2], s.fill[3], s.fill[4] or 1)
            love.graphics.rectangle("fill", s.x, s.y, fillW, s.h, s.radius)

            local knobR = s.h * 0.7
            local kx = s.x + s.w * t
            local ky = s.y + s.h / 2
            love.graphics.setColor(s.knob[1], s.knob[2], s.knob[3], s.knob[4] or 1)
            love.graphics.circle("fill", kx, ky, knobR / 2)
        end
    end

    for _, l in pairs(self.labels) do
        if l.visible then
            love.graphics.setFont(getFont(l.fontSize, self.resources))
            love.graphics.setColor(l.r, l.g, l.b, l.a)
            if l.align == "center" then
                local tw = getFont(l.fontSize, self.resources):getWidth(l.text)
                love.graphics.print(l.text, l.x - tw / 2, l.y)
            elseif l.align == "right" then
                local tw = getFont(l.fontSize, self.resources):getWidth(l.text)
                love.graphics.print(l.text, l.x - tw, l.y)
            else
                love.graphics.print(l.text, l.x, l.y)
            end
        end
    end
end

function UIElements:clear()
    self.buttons = {}
    self.checkboxes = {}
    self.sliders = {}
    self.labels = {}
    self._nextId = 1
end

return UIElements
