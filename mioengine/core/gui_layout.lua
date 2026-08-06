local GUILayout = {}
GUILayout.__index = GUILayout

function GUILayout.new(config)
    local self = setmetatable({}, GUILayout)
    config = config or {}
    self.x = config.x or 0
    self.y = config.y or 0
    self.w = config.w or 200
    self.h = config.h or 300
    self.padding = config.padding or 5
    self.spacing = config.spacing or 5
    self.bgColor = config.bgColor or {0.12, 0.12, 0.18, 0.9}
    self.borderColor = config.borderColor or {0.3, 0.5, 0.7, 0.8}
    self.children = {}
    self.direction = config.direction or "vertical"
    self.scrollY = 0
    self.scrollX = 0
    self.contentHeight = 0
    self.contentWidth = 0
    self.scrollable = config.scrollable ~= false
    self.visible = true
    self.draggable = config.draggable or false
    self.isDragging = false
    self.dragOffX = 0
    self.dragOffY = 0
    self.title = config.title or nil
    return self
end

function GUILayout:addPanel(config)
    local panel = GUILayout.new(config or {})
    panel.parent = self
    self.children[#self.children + 1] = panel
    self:reflow()
    return panel
end

function GUILayout:addButton(x, y, w, h, label, opts)
    local btn = {
        type = "button",
        x = x, y = y, w = w, h = h,
        label = label or "Button",
        hover = false,
        pressed = false,
        id = opts and opts.id,
        color = opts and opts.color or {0.25, 0.45, 0.7, 1},
        hoverColor = opts and opts.hoverColor or {0.35, 0.55, 0.8, 1},
    }
    self.children[#self.children + 1] = btn
    self:reflow()
    return btn
end

function GUILayout:addLabel(x, y, text, opts)
    local lbl = {
        type = "label",
        x = x, y = y,
        text = text or "",
        size = opts and opts.size or 14,
        color = opts and opts.color or {0.8, 0.8, 0.85, 1},
        align = opts and opts.align or "left",
    }
    self.children[#self.children + 1] = lbl
    return lbl
end

function GUILayout:addSeparator()
    local sep = { type = "separator" }
    self.children[#self.children + 1] = sep
    self:reflow()
    return sep
end

function GUILayout:addRow(config)
    local row = {
        type = "row",
        children = {},
        h = config and config.h or 30,
    }
    self.children[#self.children + 1] = row
    return row
end

function GUILayout:addColumn(config)
    local col = {
        type = "column",
        children = {},
        w = config and config.w or 100,
    }
    self.children[#self.children + 1] = col
    return col
end

function GUILayout:reflow()
    local y = self.padding
    local x = self.padding
    local maxW = 0
    for _, child in ipairs(self.children) do
        if child.type == "button" then
            child.x = x
            child.y = y
            y = y + child.h + self.spacing
            maxW = math.max(maxW, child.w)
        elseif child.type == "label" then
            child.x = x
            child.y = y
            y = y + (child.size or 14) + self.spacing
        elseif child.type == "separator" then
            y = y + 4 + self.spacing
        elseif child.type == "row" then
            local rx = x
            for _, rc in ipairs(child.children) do
                rc.x = rx
                rc.y = y
                rx = rx + (rc.w or 50) + self.spacing
            end
            y = y + child.h + self.spacing
        elseif child.type == "column" then
            local cy = y
            for _, cc in ipairs(child.children) do
                cc.x = x
                cc.y = cy
                cy = cy + (cc.h or 30) + self.spacing
            end
            x = x + child.w + self.spacing
        else
            if child.x and child.w then
                child.x = x
                child.y = y
                if child.h then y = y + child.h + self.spacing end
            end
        end
    end
    self.contentHeight = y
    self.contentWidth = math.max(maxW, x)
end

function GUILayout:update(dt)
    if not self.visible then return end
    local mx, my = love.mouse.getPosition()

    for _, child in ipairs(self.children) do
        if child.type == "button" then
            child.hover = mx >= self.x + child.x and mx <= self.x + child.x + child.w
                and my >= self.y + child.y - self.scrollY and my <= self.y + child.y - self.scrollY + child.h
        end
    end

    if self.draggable and not self.isDragging then
        self.isDragging = love.mouse.isDown(1)
    end
end

function GUILayout:handleClick(x, y)
    if not self.visible then return nil end
    local localX = x - self.x
    local localY = y - self.y + self.scrollY

    for _, child in ipairs(self.children) do
        if child.type == "button" then
            if localX >= child.x and localX <= child.x + child.w
                and localY >= child.y and localY <= child.y + child.h then
                return child.id or child.label
            end
        end
    end

    for _, child in ipairs(self.children) do
        if child.type == "panel" then
            local result = child:handleClick(x, y)
            if result then return result end
        end
    end

    return nil
end

function GUILayout:handleScroll(dx, dy)
    if not self.visible or not self.scrollable then return end
    self.scrollY = math.max(0, math.min(self.contentHeight - self.h, self.scrollY - dy * 20))
end

function GUILayout:draw()
    if not self.visible then return end

    love.graphics.setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4])
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4, 4)
    love.graphics.setColor(self.borderColor[1], self.borderColor[2], self.borderColor[3], self.borderColor[4])
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 4, 4)

    if self.title then
        local font = love.graphics.getFont()
        love.graphics.setColor(0.85, 0.85, 0.9, 1)
        love.graphics.print(self.title, self.x + self.padding, self.y + self.padding)
    end

    love.graphics.setScissor(self.x, self.y, self.w, self.h)

    for _, child in ipairs(self.children) do
        if child.type == "button" then
            local cx = self.x + child.x
            local cy = self.y + child.y - self.scrollY
            if cy >= self.y - child.h and cy <= self.y + self.h then
                local color = child.hover and child.hoverColor or child.color
                love.graphics.setColor(color[1], color[2], color[3], color[4])
                love.graphics.rectangle("fill", cx, cy, child.w, child.h, 3, 3)
                love.graphics.setColor(0.95, 0.95, 1, 1)
                local font = love.graphics.newFont(12)
                love.graphics.setFont(font)
                local tw = font:getWidth(child.label)
                love.graphics.print(child.label, cx + child.w / 2 - tw / 2, cy + child.h / 2 - 6)
            end
        elseif child.type == "label" then
            local cx = self.x + child.x
            local cy = self.y + child.y - self.scrollY
            if cy >= self.y - 20 and cy <= self.y + self.h then
                love.graphics.setColor(child.color[1], child.color[2], child.color[3], child.color[4])
                local font = love.graphics.newFont(child.size or 12)
                love.graphics.setFont(font)
                if child.align == "center" then
                    local tw = font:getWidth(child.text)
                    love.graphics.print(child.text, cx + self.w / 2 - tw / 2, cy)
                else
                    love.graphics.print(child.text, cx, cy)
                end
            end
        elseif child.type == "separator" then
            local cy = self.y + child.y - self.scrollY
            if cy >= self.y and cy <= self.y + self.h then
                love.graphics.setColor(0.3, 0.3, 0.4, 0.6)
                love.graphics.line(self.x + self.padding, cy, self.x + self.w - self.padding, cy)
            end
        elseif child.type == "panel" then
            child.x = self.x + child.x
            child.y = self.y + child.y - self.scrollY
            child:draw()
        end
    end

    love.graphics.setScissor()
    love.graphics.setColor(1, 1, 1, 1)
end

function GUILayout:setPosition(x, y)
    self.x = x
    self.y = y
end

function GUILayout:setSize(w, h)
    self.w = w
    self.h = h
end

function GUILayout:setVisible(v)
    self.visible = v
end

function GUILayout:isVisible()
    return self.visible
end

return GUILayout
