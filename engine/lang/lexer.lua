local Lexer = {}
Lexer.__index = Lexer

local KEYWORDS = {
    ["let"] = true, ["if"] = true, ["then"] = true, ["else"] = true, ["end"] = true,
    ["loop"] = true, ["forever"] = true, ["for"] = true, ["to"] = true, ["do"] = true,
    ["break"] = true, ["true"] = true, ["false"] = true, ["step"] = true,
    ["from"] = true, ["at"] = true, ["by"] = true, ["speed"] = true,
    ["towards"] = true, ["rotatey"] = true, ["rotatex"] = true, ["scale"] = true,
    ["size"] = true, ["draworder"] = true, ["fov"] = true, ["sensitivity"] = true,
    ["not"] = true, ["and"] = true, ["or"] = true,
    ["button"] = true, ["checkbox"] = true, ["slider"] = true, ["label"] = true,
    ["checked"] = true, ["visible"] = true, ["hidden"] = true,
    ["action"] = true,
    ["gravity"] = true, ["ground"] = true, ["jump"] = true,
}

local TWO_CHAR = {
    ["=="] = "EQ", ["~="] = "NE", ["<="] = "LE", [">="] = "GE",
    ["+="] = "PLUSEQ", ["-="] = "MINUSEQ", ["*="] = "MULTEQ", ["/="] = "DIVEQ",
    ["=>"] = "ARROW",
}

local ONE_CHAR = {
    ["="] = "ASSIGN", ["+"] = "PLUS", ["-"] = "MINUS", ["*"] = "STAR", ["/"] = "SLASH",
    ["%"] = "PERCENT", ["<"] = "LT", [">"] = "GT",
    ["("] = "LPAREN", [")"] = "RPAREN", ["["] = "LBRACKET", ["]"] = "RBRACKET",
    [","] = "COMMA", ["."] = "DOT", [":"] = "COLON",
}

function Lexer.new(src)
    return setmetatable({ src = src, pos = 1, line = 1, col = 1, tokens = {} }, Lexer)
end

function Lexer:peek()
    return self.pos <= #self.src and self.src:sub(self.pos, self.pos) or nil
end

function Lexer:advance()
    local c = self.src:sub(self.pos, self.pos)
    self.pos = self.pos + 1
    if c == "\n" then
        self.line = self.line + 1
        self.col = 1
    elseif c ~= "\r" then
        self.col = self.col + 1
    end
    return c
end

function Lexer:skipWhitespace()
    while self.pos <= #self.src do
        local c = self.src:sub(self.pos, self.pos)
        if c == " " or c == "\t" or c == "\r" or c == "\n" then
            self:advance()
        elseif c == "/" and self.src:sub(self.pos + 1, self.pos + 1) == "/" then
            while self.pos <= #self.src and self.src:sub(self.pos, self.pos) ~= "\n" do
                self:advance()
            end
        else
            break
        end
    end
end

function Lexer:readString(quote)
    local parts = {}
    while self.pos <= #self.src do
        local c = self:advance()
        if c == "\\" then
            local esc = self:advance()
            if esc == "n" then parts[#parts+1] = "\n"
            elseif esc == "t" then parts[#parts+1] = "\t"
            elseif esc == "\\" then parts[#parts+1] = "\\"
            elseif esc == quote then parts[#parts+1] = quote
            else parts[#parts+1] = "\\" .. esc end
        elseif c == quote then
            return table.concat(parts)
        else
            parts[#parts+1] = c
        end
    end
    error("Unterminated string at line " .. self.line)
end

function Lexer:readNumber()
    local start = self.pos - 1
    while self.pos <= #self.src and self.src:sub(self.pos, self.pos):match("[%d%.]") do
        self:advance()
    end
    return tonumber(self.src:sub(start, self.pos - 1))
end

function Lexer:readWord()
    local start = self.pos - 1
    while self.pos <= #self.src and self.src:sub(self.pos, self.pos):match("[%w_]") do
        self:advance()
    end
    return self.src:sub(start, self.pos - 1)
end

function Lexer:tokenize()
    self.tokens = {}
    while self.pos <= #self.src do
        self:skipWhitespace()
        if self.pos > #self.src then break end
        local c = self.src:sub(self.pos, self.pos)
        local ln, cl = self.line, self.col

        if c == '"' or c == "'" then
            self:advance()
            local s = self:readString(c)
            self.tokens[#self.tokens+1] = { type = "STRING", value = s, line = ln, col = cl }
        elseif c:match("%d") or (c == "." and self.src:sub(self.pos+1, self.pos+1):match("%d")) then
            self:advance()
            local n = self:readNumber()
            self.tokens[#self.tokens+1] = { type = "NUMBER", value = n, line = ln, col = cl }
        elseif c:match("[%a_]") then
            self:advance()
            local w = self:readWord()
            if KEYWORDS[w] then
                self.tokens[#self.tokens+1] = { type = w:upper(), value = w, line = ln, col = cl }
            else
                self.tokens[#self.tokens+1] = { type = "ID", value = w, line = ln, col = cl }
            end
        else
            local two = c .. (self.src:sub(self.pos+1, self.pos+1) or "")
            if TWO_CHAR[two] then
                self:advance()
                self:advance()
                self.tokens[#self.tokens+1] = { type = TWO_CHAR[two], value = two, line = ln, col = cl }
            elseif ONE_CHAR[c] then
                self:advance()
                self.tokens[#self.tokens+1] = { type = ONE_CHAR[c], value = c, line = ln, col = cl }
            else
                error("Unexpected character '" .. c .. "' at line " .. ln .. ":" .. cl)
            end
        end
    end
    self.tokens[#self.tokens+1] = { type = "EOF", value = nil, line = self.line, col = self.col }
    return self.tokens
end

return Lexer
