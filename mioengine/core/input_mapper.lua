local InputMapper = {}
InputMapper.__index = InputMapper

function InputMapper.new()
    local self = setmetatable({}, InputMapper)
    self.bindings = {}
    self.actions = {}
    self.actionStates = {}
    self.prevStates = {}
    self.deadzone = 0.1
    return self
end

function InputMapper:bind(action, ...)
    local keys = { ... }
    self.bindings[action] = {}
    for _, key in ipairs(keys) do
        if type(key) == "string" then
            self.bindings[action][#self.bindings[action] + 1] = { type = "key", value = key }
        elseif type(key) == "number" then
            self.bindings[action][#self.bindings[action] + 1] = { type = "button", value = key }
        end
    end
    self.actionStates[action] = false
    self.prevStates[action] = false
end

function InputMapper:unbind(action)
    self.bindings[action] = nil
    self.actionStates[action] = nil
    self.prevStates[action] = nil
end

function InputMapper:isDown(action)
    return self.actionStates[action] or false
end

function InputMapper:wasPressed(action)
    return self.actionStates[action] and not self.prevStates[action]
end

function InputMapper:wasReleased(action)
    return not self.actionStates[action] and self.prevStates[action]
end

function InputMapper:getActions()
    local list = {}
    for action, _ in pairs(self.bindings) do
        list[#list + 1] = action
    end
    return list
end

function InputMapper:getBinding(action)
    local binds = self.bindings[action]
    if not binds then return {} end
    local result = {}
    for _, b in ipairs(binds) do
        result[#result + 1] = b.value
    end
    return result
end

function InputMapper:update()
    for action, binds in pairs(self.bindings) do
        self.prevStates[action] = self.actionStates[action]
        local down = false
        for _, b in ipairs(binds) do
            if b.type == "key" then
                if love.keyboard.isDown(b.value) then
                    down = true
                    break
                end
            elseif b.type == "button" then
                if love.mouse.isDown(b.value) then
                    down = true
                    break
                end
            end
        end
        self.actionStates[action] = down
    end
end

function InputMapper:keypressed(key)
    for action, binds in pairs(self.bindings) do
        for _, b in ipairs(binds) do
            if b.type == "key" and b.value == key then
                self.actionStates[action] = true
            end
        end
    end
end

function InputMapper:keyreleased(key)
    for action, binds in pairs(self.bindings) do
        for _, b in ipairs(binds) do
            if b.type == "key" and b.value == key then
                local stillDown = false
                for _, b2 in ipairs(binds) do
                    if b2.type == "key" and b2.value ~= key and love.keyboard.isDown(b2.value) then
                        stillDown = true
                        break
                    end
                end
                if not stillDown then
                    self.actionStates[action] = false
                end
            end
        end
    end
end

function InputMapper:loadDefaults()
    self:bind("move_left", "a", "left")
    self:bind("move_right", "d", "right")
    self:bind("move_up", "w", "up")
    self:bind("move_down", "s", "down")
    self:bind("jump", "space")
    self:bind("fire", "x")
    self:bind("interact", "e")
    self:bind("pause", "escape")
end

return InputMapper
