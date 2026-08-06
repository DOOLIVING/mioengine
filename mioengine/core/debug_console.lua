local DebugConsole = {}
DebugConsole.__index = DebugConsole

function DebugConsole.new()
    local self = setmetatable({}, DebugConsole)
    self.visible = false
    self.logBuffer = {}
    self.maxLogLines = 200
    self.inputBuffer = ""
    self.cursorPos = 0
    self.history = {}
    self.historyIndex = 0
    self.font = nil
    self.profiler = {
        enabled = false,
        sections = {},
        timings = {},
    }
    return self
end

function DebugConsole:toggle()
    self.visible = not self.visible
end

function DebugConsole:show()
    self.visible = true
end

function DebugConsole:hide()
    self.visible = false
end

function DebugConsole:log(msg)
    local line = tostring(msg)
    self.logBuffer[#self.logBuffer + 1] = line
    if #self.logBuffer > self.maxLogLines then
        table.remove(self.logBuffer, 1)
    end
end

function DebugConsole:clearLog()
    self.logBuffer = {}
end

function DebugConsole:execCommand(cmd)
    self:log("> " .. cmd)
    self.history[#self.history + 1] = cmd
    self.historyIndex = #self.history

    local ok, result = pcall(loadstring, "return " .. cmd)
    if ok and result then
        local val = result()
        self:log(tostring(val))
    else
        local ok2, err2 = pcall(loadstring, cmd)
        if ok2 then
            local r, e = pcall(ok2)
            if not r then
                self:log("[error] " .. tostring(e))
            end
        else
            self:log("[error] " .. tostring(err2))
        end
    end
end

function DebugConsole:textinput(text)
    if not self.visible then return end
    self.inputBuffer = self.inputBuffer:sub(1, self.cursorPos) .. text .. self.inputBuffer:sub(self.cursorPos + 1)
    self.cursorPos = self.cursorPos + #text
end

function DebugConsole:keypressed(key)
    if not self.visible then return false end
    if key == "return" then
        if #self.inputBuffer > 0 then
            self:execCommand(self.inputBuffer)
            self.inputBuffer = ""
            self.cursorPos = 0
        end
        return true
    elseif key == "backspace" then
        if self.cursorPos > 0 then
            self.inputBuffer = self.inputBuffer:sub(1, self.cursorPos - 1) .. self.inputBuffer:sub(self.cursorPos + 1)
            self.cursorPos = self.cursorPos - 1
        end
        return true
    elseif key == "left" then
        self.cursorPos = math.max(0, self.cursorPos - 1)
        return true
    elseif key == "right" then
        self.cursorPos = math.min(#self.inputBuffer, self.cursorPos + 1)
        return true
    elseif key == "up" then
        if self.historyIndex > 1 then
            self.historyIndex = self.historyIndex - 1
            self.inputBuffer = self.history[self.historyIndex]
            self.cursorPos = #self.inputBuffer
        end
        return true
    elseif key == "down" then
        if self.historyIndex < #self.history then
            self.historyIndex = self.historyIndex + 1
            self.inputBuffer = self.history[self.historyIndex]
            self.cursorPos = #self.inputBuffer
        else
            self.historyIndex = #self.history + 1
            self.inputBuffer = ""
            self.cursorPos = 0
        end
        return true
    elseif key == "escape" then
        self.visible = false
        return true
    end
    return true
end

function DebugConsole:draw()
    if not self.visible then return end
    if not self.font then
        self.font = love.graphics.newFont(12)
    end
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    local panelH = H * 0.4

    love.graphics.setColor(0.05, 0.05, 0.1, 0.92)
    love.graphics.rectangle("fill", 0, 0, W, panelH)
    love.graphics.setColor(0.3, 0.6, 0.9, 1)
    love.graphics.rectangle("line", 0, 0, W, panelH)

    love.graphics.setFont(self.font)
    love.graphics.setColor(0.7, 0.7, 0.8, 1)
    local maxLines = math.floor((panelH - 30) / 14)
    local startIdx = math.max(1, #self.logBuffer - maxLines + 1)
    local y = 5
    for i = startIdx, #self.logBuffer do
        local line = self.logBuffer[i]
        if line:sub(1, 1) == ">" then
            love.graphics.setColor(0.3, 0.8, 0.3, 1)
        elseif line:sub(1, 7) == "[error]" then
            love.graphics.setColor(0.9, 0.3, 0.3, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.8, 1)
        end
        love.graphics.print(line, 5, y)
        y = y + 14
    end

    love.graphics.setColor(0.15, 0.15, 0.25, 1)
    love.graphics.rectangle("fill", 0, panelH - 25, W, 25)
    love.graphics.setColor(0.3, 0.9, 0.3, 1)
    love.graphics.print("> " .. self.inputBuffer, 5, panelH - 22)

    local cursorX = self.font:getWidth("> " .. self.inputBuffer:sub(1, self.cursorPos)) + 5
    love.graphics.setColor(0.3, 0.9, 0.3, (love.timer.getTime() % 1) > 0.5 and 1 or 0)
    love.graphics.rectangle("fill", cursorX, panelH - 24, 2, 20)

    love.graphics.setColor(1, 1, 1, 1)
end


function DebugConsole:profilerStart(name)
    self.profiler.sections[name] = love.timer.getTime()
end

function DebugConsole:profilerEnd(name)
    local start = self.profiler.sections[name]
    if start then
        local elapsed = love.timer.getTime() - start
        local timings = self.profiler.timings[name] or { avg = 0, max = 0, count = 0, total = 0 }
        timings.total = timings.total + elapsed
        timings.count = timings.count + 1
        timings.avg = timings.total / timings.count
        if elapsed > timings.max then timings.max = elapsed end
        self.profiler.timings[name] = timings
        self.profiler.sections[name] = nil
    end
end

function DebugConsole:profilerReset()
    self.profiler.timings = {}
    self.profiler.sections = {}
end

function DebugConsole:profilerDraw()
    if not self.visible then return end
    if not self.font then
        self.font = love.graphics.newFont(12)
    end
    local W = love.graphics.getWidth()
    local y = love.graphics.getHeight() * 0.4 + 10

    love.graphics.setFont(self.font)
    love.graphics.setColor(0.9, 0.8, 0.2, 1)
    love.graphics.print("--- Profiler ---", W - 220, y)
    y = y + 16

    for name, timing in pairs(self.profiler.timings) do
        love.graphics.setColor(0.7, 0.7, 0.8, 1)
        local line = string.format("%s: %.2fms avg, %.2fms max", name, timing.avg * 1000, timing.max * 1000)
        love.graphics.print(line, W - 220, y)
        y = y + 14
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DebugConsole:getLogBuffer()
    return self.logBuffer
end

return DebugConsole
