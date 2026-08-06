local MioLang = {}
MioLang.__index = MioLang

local Lexer = {}
Lexer.__index = Lexer

local KEYWORDS = {
    ["let"] = true, ["if"] = true, ["then"] = true, ["else"] = true, ["end"] = true,
    ["loop"] = true, ["forever"] = true, ["for"] = true, ["to"] = true, ["do"] = true,
    ["break"] = true, ["true"] = true, ["false"] = true, ["step"] = true,
    ["from"] = true, ["at"] = true, ["by"] = true, ["to"] = true, ["speed"] = true,
    ["towards"] = true, ["rotatey"] = true, ["rotatex"] = true, ["scale"] = true,
    ["size"] = true, ["draworder"] = true, ["fov"] = true, ["sensitivity"] = true,
    ["not"] = true, ["and"] = true, ["or"] = true,
    ["button"] = true, ["checkbox"] = true, ["slider"] = true, ["label"] = true,
    ["checked"] = true, ["visible"] = true, ["hidden"] = true,
    ["action"] = true,
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
    local start = self.pos
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

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    return setmetatable({ tokens = tokens, pos = 1 }, Parser)
end

function Parser:peek()
    return self.tokens[self.pos]
end

function Parser:advance()
    local t = self.tokens[self.pos]
    self.pos = self.pos + 1
    return t
end

function Parser:expect(type)
    local t = self:peek()
    if t.type ~= type then
        error("Expected " .. type .. " got " .. t.type .. " at line " .. t.line .. ":" .. t.col)
    end
    return self:advance()
end

function Parser:at(type)
    return self:peek().type == type
end

function Parser:match(type)
    if self:at(type) then return self:advance() end
    return nil
end

function Parser:parse()
    local stmts = {}
    while not self:at("EOF") do
        local s = self:parseStatement()
        if s then stmts[#stmts+1] = s end
    end
    return stmts
end

function Parser:parseStatement()
    local t = self:peek()
    if t.type == "EOF" then return nil end
    if t.type == "END" then return nil end

    if t.type == "LET" then return self:parseLet()
    elseif t.type == "IF" then return self:parseIf()
    elseif t.type == "LOOP" then return self:parseLoop()
    elseif t.type == "FOR" then return self:parseFor()
    elseif t.type == "BREAK" then self:advance(); return { type = "break" }
    elseif t.type == "ADD_COLLIDER" then return self:parseAddCollider()
    end

    local kwStatements = {
        MOVE = "move", SET_POS = "setpos", GET_POS = "getpos", DESTROY = "destroy",
        SAY = "say", CREATE_MODEL = "createmodel", PLAY_SOUND = "playsound",
        STOP_SOUND = "stopsound", DRAW_RECT = "drawrect", DRAW_TEXT = "drawtext",
        DRAW_CIRCLE = "drawcircle", DRAW_LINE = "drawline", IMPORT = "import",
        SET_ROT = "setrot", GET_CANVAS_SIZE = "getcanvassize", SET_SCALE = "setscale",
        MUTE = "mute", VOLUME = "volume", CAMERA_SET_POS = "camerasepos",
        CAMERA_GET_POS = "cameragetpos", CAMERA_SET_LOOK = "camerasetlook",
        CAMERA_GET_LOOK = "cameragetlook", SWITCH_SCENE = "switchscene",
    }

    if t.type == "ID" then
        local word = t.value

        local next = self.tokens[self.pos + 1]
        if next and (next.type == "PLUSEQ" or next.type == "MINUSEQ" or next.type == "MULTEQ" or next.type == "DIVEQ") then
            return self:parseCompoundAssign()
        end
        if next and next.type == "ASSIGN" then
            return self:parseAssign()
        end

        if word == "on_update" then return self:parseOnUpdate()
        elseif word == "on_draw" then return self:parseOnDraw()
        elseif word == "on_key" then return self:parseOnKey()
        elseif word == "on_click" then return self:parseOnClick()
        elseif word == "on_collision" then return self:parseOnCollision()
        elseif word == "on_mouse" then return self:parseOnMouse()
        elseif word == "move" then return self:parseMove()
        elseif word == "set_pos" then return self:parseSetPos()
        elseif word == "get_pos" then return self:parseGetPos()
        elseif word == "destroy" then return self:parseDestroy()
        elseif word == "say" then return self:parseSay()
        elseif word == "create_model" then return self:parseCreateModel()
        elseif word == "play_sound" then return self:parsePlaySound()
        elseif word == "stop_sound" then return self:parseStopSound()
        elseif word == "draw_rect" then return self:parseDrawRect()
        elseif word == "draw_text" then return self:parseDrawText()
        elseif word == "draw_circle" then return self:parseDrawCircle()
        elseif word == "draw_line" then return self:parseDrawLine()
        elseif word == "draw_image" then return self:parseDrawImage()
        elseif word == "draw_model" then return self:parseDrawModel()
        elseif word == "import" then return self:parseImport()
        elseif word == "set_rot" then return self:parseSetRot()
        elseif word == "get_canvas_size" then return self:parseGetCanvasSize()
        elseif word == "set_scale" then return self:parseParseScale()
        elseif word == "mute" then self:advance(); return { type = "mute" }
        elseif word == "volume" then return self:parseVolume()
        elseif word == "switch_scene" then return self:parseSwitchScene()
        elseif word == "setup_camera" then return self:parseSetupCamera()
        elseif word == "setup_renderer" then return self:parseSetupRenderer()
        elseif word == "load_texture" then return self:parseLoadTexture()
        elseif word == "set_mouse" then return self:parseSetMouse()
        elseif word == "camera_update" then self:advance(); return { type = "camera_update" }
        elseif word == "camera_collide" then self:advance(); return { type = "camera_collide" }
        elseif word == "exit_game" then self:advance(); return { type = "exit_game" }
        elseif word == "add_object" then return self:parseAddObject()
        elseif word == "add_collider" then return self:parseAddCollider()
        elseif word == "check_hit" then return self:parseCheckHit()
        elseif word == "setup_camera2d" then return self:parseSetupCamera2D()
        elseif word == "draw_sprite" then return self:parseDrawSprite()
        elseif word == "move_camera2d" then return self:parseMoveCamera2D()
        elseif word == "set_camera2d_pos" then return self:parseSetCamera2DPos()
        elseif word == "zoom_camera2d" then return self:parseZoomCamera2D()
        elseif word == "set_gravity" then return self:parseSetGravity()
        elseif word == "add_body" then return self:parseAddBody()
        elseif word == "add_body3d" then return self:parseAddBody3D()
        elseif word == "set_body_vel" then return self:parseSetBodyVel()
        elseif word == "set_body3d_vel" then return self:parseSetBody3DVel()
        elseif word == "get_body_vel" then return self:parseGetBodyVel()
        elseif word == "get_body3d_vel" then return self:parseGetBody3DVel()
        elseif word == "body_apply_force" then return self:parseBodyApplyForce()
        elseif word == "body3d_apply_force" then return self:parseBody3DApplyForce()
        elseif word == "body_apply_impulse" then return self:parseBodyApplyImpulse()
        elseif word == "body3d_apply_impulse" then return self:parseBody3DApplyImpulse()
        elseif word == "set_body_pos" then return self:parseSetBodyPos()
        elseif word == "set_body3d_pos" then return self:parseSetBody3DPos()
        elseif word == "get_body_pos" then return self:parseGetBodyPos()
        elseif word == "get_body3d_pos" then return self:parseGetBody3DPos()
        elseif word == "is_grounded" then return self:parseIsGrounded()
        elseif word == "body_colliding" then return self:parseBodyColliding()
        elseif word == "set_physics" then return self:parseSetPhysics()
        elseif word == "set_physics3d" then return self:parseSetPhysics3D()
        elseif word == "obj_impulse" then return self:parseObjImpulse()
        elseif word == "obj3d_impulse" then return self:parseObj3DImpulse()
        elseif word == "obj_set_vel" then return self:parseObjSetVel()
        elseif word == "obj3d_set_vel" then return self:parseObj3DSetVel()
        elseif word == "obj_get_vel" then return self:parseObjGetVel()
        elseif word == "obj3d_get_vel" then return self:parseObj3DGetVel()
        elseif word == "obj_set_pos" then return self:parseObjSetPos()
        elseif word == "obj3d_set_pos" then return self:parseObj3DSetPos()
        elseif word == "obj_is_grounded" then return self:parseObjIsGrounded()
        elseif word == "obj3d_is_grounded" then return self:parseObj3DIsGrounded()
        elseif word == "obj_colliding" then return self:parseObjColliding()
        elseif word == "obj3d_colliding" then return self:parseObj3DColliding()
        elseif word == "set_physics_gravity" then return self:parseSetPhysicsGravity()
        elseif word == "set_physics3d_gravity" then return self:parseSetPhysics3DGravity()
        elseif word == "set_physics_ground" then return self:parseSetPhysicsGround()
        elseif word == "set_physics3d_floor" then return self:parseSetPhysics3DFloor()
        elseif word == "create_particles3d" then return self:parseCreateParticles3D()
        elseif word == "particles3d_set_pos" then return self:parseParticles3DSetPos()
        elseif word == "particles3d_emit" then return self:parseParticles3DEmit()
        elseif word == "particles3d_burst" then return self:parseParticles3DBurst()
        elseif word == "particles3d_start" then return self:parseParticles3DStart()
        elseif word == "particles3d_stop" then return self:parseParticles3DStop()
        elseif word == "particles3d_clear" then return self:parseParticles3DClear()
        elseif word == "particles3d_configure" then return self:parseParticles3DConfigure()
        elseif word == "draw_particles3d" then return self:parseDrawParticles3D()
        elseif word == "physics_update" then self:advance(); return { type = "physics_update" }
        elseif word == "physics3d_update" then self:advance(); return { type = "physics3d_update" }
        elseif word == "remove_body" then return self:parseRemoveBody()
        elseif word == "remove_body3d" then return self:parseRemoveBody3D()
        elseif word == "create_anim" then return self:parseCreateAnim()
        elseif word == "create_animated_sprite" then return self:parseCreateAnimatedSprite()
        elseif word == "anim_add" then return self:parseAnimAdd()
        elseif word == "anim_play" then return self:parseAnimPlay()
        elseif word == "anim_stop" then return self:parseAnimStop()
        elseif word == "anim_pause" then return self:parseAnimPause()
        elseif word == "anim_resume" then return self:parseAnimResume()
        elseif word == "anim_set_speed" then return self:parseAnimSetSpeed()
        elseif word == "anim_set_frame" then return self:parseAnimSetFrame()
        elseif word == "draw_animated_sprite" then return self:parseDrawAnimatedSprite()
        elseif word == "create_particles" then return self:parseCreateParticles()
        elseif word == "particles_set_pos" then return self:parseParticlesSetPos()
        elseif word == "particles_emit" then return self:parseParticlesEmit()
        elseif word == "particles_burst" then return self:parseParticlesBurst()
        elseif word == "particles_start" then return self:parseParticlesStart()
        elseif word == "particles_stop" then return self:parseParticlesStop()
        elseif word == "particles_clear" then return self:parseParticlesClear()
        elseif word == "particles_configure" then return self:parseParticlesConfigure()
        elseif word == "draw_particles" then return self:parseDrawParticles()
        elseif word == "watch_file" then return self:parseWatchFile()
        elseif word == "unwatch_file" then return self:parseUnwatchFile()
        elseif word == "bind_key" then return self:parseBindKey()
        elseif word == "unbind_key" then return self:parseUnbindKey()
        elseif word == "load_default_bindings" then self:advance(); return { type = "load_default_bindings" }
        elseif word == "toggle_console" then self:advance(); return { type = "toggle_console" }
        elseif word == "console_log" then return self:parseConsoleLog()
        elseif word == "profiler_start" then return self:parseProfilerStart()
        elseif word == "profiler_end" then return self:parseProfilerEnd()
        elseif word == "profiler_reset" then self:advance(); return { type = "profiler_reset" }
        elseif word == "create_panel" then return self:parseCreatePanel()
        elseif word == "panel_add_button" then return self:parsePanelAddButton()
        elseif word == "panel_add_label" then return self:parsePanelAddLabel()
        elseif word == "panel_add_separator" then return self:parsePanelAddSeparator()
        elseif word == "draw_panel" then return self:parseDrawPanel()
        elseif word == "panel_set_visible" then return self:parsePanelSetVisible()
        elseif word == "panel_set_position" then return self:parsePanelSetPosition()
        elseif word == "ui_button" then return self:parseUIButton()
        elseif word == "ui_checkbox" then return self:parseUICheckbox()
        elseif word == "ui_slider" then return self:parseUISlider()
        elseif word == "ui_label" then return self:parseUILabel()
        elseif word == "ui_visible" then return self:parseUIVisible()
        elseif word == "ui_hidden" then return self:parseUIHidden()
        elseif word == "ui_clear" then self:advance(); return { type = "ui_clear" }
        else

            return self:parseExprStatement()
        end
    end

    error("Unexpected token " .. t.type .. " '" .. tostring(t.value) .. "' at line " .. t.line .. ":" .. t.col)
end

function Parser:parseExpr()
    return self:parseOr()
end

function Parser:parseOr()
    local left = self:parseAnd()
    while self:at("OR") do
        self:advance()
        local right = self:parseAnd()
        left = { type = "binop", op = "or", left = left, right = right }
    end
    return left
end

function Parser:parseAnd()
    local left = self:parseComparison()
    while self:at("AND") do
        self:advance()
        local right = self:parseComparison()
        left = { type = "binop", op = "and", left = left, right = right }
    end
    return left
end

function Parser:parseComparison()
    local left = self:parseAddSub()
    while self:at("EQ") or self:at("NE") or self:at("LT") or self:at("GT") or self:at("LE") or self:at("GE") do
        local op = self:advance().value
        local right = self:parseAddSub()
        left = { type = "binop", op = op, left = left, right = right }
    end
    return left
end

function Parser:parseAddSub()
    local left = self:parseMulDiv()
    while self:at("PLUS") or self:at("MINUS") do
        local op = self:advance().value
        local right = self:parseMulDiv()
        left = { type = "binop", op = op, left = left, right = right }
    end
    return left
end

function Parser:parseMulDiv()
    local left = self:parseUnary()
    while self:at("STAR") or self:at("SLASH") or self:at("PERCENT") do
        local op = self:advance().value
        local right = self:parseUnary()
        left = { type = "binop", op = op, left = left, right = right }
    end
    return left
end

function Parser:parseUnary()
    if self:at("MINUS") then
        self:advance()
        local expr = self:parseUnary()
        return { type = "unop", op = "-", expr = expr }
    end
    if self:at("NOT") then
        self:advance()
        local expr = self:parseUnary()
        return { type = "unop", op = "not", expr = expr }
    end
    return self:parsePrimary()
end

function Parser:parsePrimary()
    local t = self:peek()

    if t.type == "NUMBER" then
        self:advance()
        return { type = "number", value = t.value }
    end

    if t.type == "STRING" then
        self:advance()
        return { type = "string", value = t.value }
    end

    if t.type == "TRUE" then
        self:advance()
        return { type = "boolean", value = true }
    end

    if t.type == "FALSE" then
        self:advance()
        return { type = "boolean", value = false }
    end

    if t.type == "LPAREN" then
        self:advance()
        local expr = self:parseExpr()
        self:expect("RPAREN")
        return expr
    end

    if t.type == "LBRACKET" then
        self:advance()
        local elements = {}
        if not self:at("RBRACKET") then
            elements[#elements+1] = self:parseExpr()
            while self:match("COMMA") do
                elements[#elements+1] = self:parseExpr()
            end
        end
        self:expect("RBRACKET")
        return { type = "array", elements = elements }
    end

    if t.type == "ID" then
        self:advance()
        local name = t.value

        if name == "ui_clicked" then
            local id = self:parseExpr()
            return { type = "ui_clicked", id = id }
        elseif name == "ui_checked" then
            local id = self:parseExpr()
            return { type = "ui_checked", id = id }
        elseif name == "ui_slider_value" then
            local id = self:parseExpr()
            return { type = "ui_slider_value", id = id }
        elseif name == "is_grounded" then
            local id = self:parseExpr()
            return { type = "is_grounded", id = id }
        elseif name == "body_colliding" then
            local id = self:parseExpr()
            self:expect("COMMA")
            local tag = self:parseExpr()
            return { type = "body_colliding", id = id, tag = tag }
        elseif name == "obj_is_grounded" then
            local objToken = self:advance()
            return { type = "obj_is_grounded", objName = objToken.value }
        elseif name == "obj_colliding" then
            local objToken = self:advance()
            self:expect("COMMA")
            local tag = self:parseExpr()
            return { type = "obj_colliding", objName = objToken.value, tag = tag }
        elseif name == "key_down" then
            local key = self:parseExpr()
            return { type = "key_down", key = key }
        elseif name == "mouse_down" then
            local btn = self:parseExpr()
            return { type = "mouse_down", button = btn }
        elseif name == "action_down" then
            local action = self:parseExpr()
            return { type = "action_down", action = action }
        elseif name == "action_pressed" then
            local action = self:parseExpr()
            return { type = "action_pressed", action = action }
        elseif name == "action_released" then
            local action = self:parseExpr()
            return { type = "action_released", action = action }
        elseif name == "anim_is_done" then
            local objToken = self:advance()
            return { type = "anim_is_done", objName = objToken.value }
        elseif name == "particles_get_count" then
            local objToken = self:advance()
            return { type = "particles_get_count", objName = objToken.value }
        elseif name == "obj3d_is_grounded" then
            local objToken = self:advance()
            return { type = "obj3d_is_grounded", objName = objToken.value }
        elseif name == "obj3d_colliding" then
            local objToken = self:advance()
            self:expect("COMMA")
            local tag = self:parseExpr()
            return { type = "obj3d_colliding", objName = objToken.value, tag = tag }
        elseif name == "particles3d_get_count" then
            local objToken = self:advance()
            return { type = "particles3d_get_count", objName = objToken.value }
        end

        if self:at("LPAREN") then
            self:advance()
            local args = {}
            if not self:at("RPAREN") then
                args[#args+1] = self:parseExpr()
                while self:match("COMMA") do
                    args[#args+1] = self:parseExpr()
                end
            end
            self:expect("RPAREN")
            return { type = "call", name = name, args = args }
        end

        if self:match("DOT") then
            local prop = self:expect("ID").value

            if self:at("LPAREN") then
                self:advance()
                local args = {}
                if not self:at("RPAREN") then
                    args[#args+1] = self:parseExpr()
                    while self:match("COMMA") do
                        args[#args+1] = self:parseExpr()
                    end
                end
                self:expect("RPAREN")
                return { type = "methodcall", object = name, method = prop, args = args }
            end
            return { type = "property", object = name, prop = prop }
        end

        if self:at("LBRACKET") then
            self:advance()
            local index = self:parseExpr()
            self:expect("RBRACKET")
            return { type = "index", array = name, index = index }
        end

        return { type = "var", name = name }
    end

    error("Unexpected token " .. t.type .. " '" .. tostring(t.value) .. "' at line " .. t.line .. ":" .. t.col)
end

function Parser:parseLet()
    self:expect("LET")
    local name = self:expect("ID").value
    local t = self:peek()

    if t.type == "ASSIGN" and self.tokens[self.pos + 1] and self.tokens[self.pos + 1].type == "ID" and self.tokens[self.pos + 1].value == "create_model" then
        self:advance()
        self:advance()
        return self:parseCreateModelAssign(name)
    end

    if t.type == "ASSIGN" and self.tokens[self.pos + 1] and self.tokens[self.pos + 1].type == "ID" and self.tokens[self.pos + 1].value == "create_scene" then
        self:advance()
        self:advance()
        return self:parseCreateSceneAssign(name)
    end

    if t.type == "ASSIGN" then
        self:advance()
        local expr = self:parseExpr()
        return { type = "assign", name = name, op = "=", expr = expr }
    elseif t.type == "PLUSEQ" then
        self:advance()
        local expr = self:parseExpr()
        return { type = "assign", name = name, op = "+", expr = expr }
    elseif t.type == "MINUSEQ" then
        self:advance()
        local expr = self:parseExpr()
        return { type = "assign", name = name, op = "-", expr = expr }
    elseif t.type == "MULTEQ" then
        self:advance()
        local expr = self:parseExpr()
        return { type = "assign", name = name, op = "*", expr = expr }
    elseif t.type == "DIVEQ" then
        self:advance()
        local expr = self:parseExpr()
        return { type = "assign", name = name, op = "/", expr = expr }
    elseif t.type == "LBRACKET" then
        self:advance()
        local index = self:parseExpr()
        self:expect("RBRACKET")
        local op = self:advance().value
        local expr = self:parseExpr()
        return { type = "arrayassign", name = name, index = index, op = op, expr = expr }
    else
        error("Expected = += -= *= /= [ after " .. name .. " at line " .. t.line)
    end
end

function Parser:parseCreateModelAssign(name)

    if self:at("FROM") then self:advance() end
    local modelPath = self:parseExpr()
    self:expect("AT")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then
        z = self:parseExpr()
    end
    local opts = {}
    while self:at("ROTATEX") or self:at("ROTATEY") or self:at("SCALE") or self:at("SIZE") or self:at("DRAWORDER") do
        local tt = self:peek().type
        if tt == "ROTATEX" then
            self:advance()
            opts.rotSpeedX = self:parseExpr()
        elseif tt == "ROTATEY" then
            self:advance()
            opts.rotSpeedY = self:parseExpr()
        elseif tt == "SCALE" then
            self:advance()
            opts.scale = self:parseExpr()
        elseif tt == "SIZE" then
            self:advance()
            opts.size = self:parseExpr()
        elseif tt == "DRAWORDER" then
            self:advance()
            opts.drawOrder = self:parseExpr()
        end
    end
    return { type = "createmodel", name = name, model = modelPath, x = x, y = y, z = z, opts = opts }
end

function Parser:parseCreateSceneAssign(name)

    self:parseExpr()
    return { type = "assign", name = name, op = "=", expr = { type = "number", value = 0 } }
end

function Parser:parseCompoundAssign()
    local name = self:expect("ID").value
    local t = self:advance()
    local op = t.value:sub(1, 1)
    local expr = self:parseExpr()
    return { type = "assign", name = name, op = op, expr = expr }
end

function Parser:parseAssign()
    local name = self:expect("ID").value
    self:expect("ASSIGN")
    local expr = self:parseExpr()
    return { type = "assign", name = name, op = "=", expr = expr }
end

function Parser:parseIf()
    self:expect("IF")
    local cond = self:parseExpr()
    self:expect("THEN")
    local body = self:parseBlock()
    local elseBody = nil
    if self:at("ELSE") then
        self:advance()
        if self:at("IF") then
            elseBody = { self:parseIf() }
        else
            elseBody = self:parseBlock()
        end
    end
    self:expect("END")
    return { type = "if", cond = cond, body = body, elseBody = elseBody }
end

function Parser:parseBlock()
    local stmts = {}
    while not self:at("EOF") and not self:at("END") do

        if self:at("ELSE") then break end
        local s = self:parseStatement()
        if s then stmts[#stmts+1] = s end
    end
    return stmts
end

function Parser:parseLoop()
    self:expect("LOOP")
    if self:at("FOREVER") then
        self:advance()
        local body = self:parseBlock()
        self:expect("END")
        return { type = "loop", mode = "forever", body = body }
    elseif self:at("FOR") then
        return self:parseForLoop()
    else
        error("Expected 'forever' or 'for' after loop at line " .. self:peek().line)
    end
end

function Parser:parseFor()
    return self:parseForLoop()
end

function Parser:parseForLoop()
    if self:at("FOR") then self:advance() end
    local var = self:expect("ID").value
    self:expect("ASSIGN")
    local from = self:parseExpr()
    self:expect("TO")
    local to = self:parseExpr()
    local step = nil
    if self:at("STEP") then
        self:advance()
        step = self:parseExpr()
    end
    local body = self:parseBlock()
    self:expect("END")
    return { type = "for", var = var, from = from, to = to, step = step, body = body }
end

function Parser:parseOnUpdate()
    self:advance()
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_update", body = body }
end

function Parser:parseOnDraw()
    self:advance()
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_draw", body = body }
end

function Parser:parseOnKey()
    self:advance()
    local key = self:expect("STRING").value
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_key", key = key, body = body }
end

function Parser:parseOnClick()
    self:advance()
    local obj = self:expect("ID").value
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_click", obj = obj, body = body }
end

function Parser:parseOnCollision()
    self:advance()
    local obj1 = self:expect("ID").value
    self:expect("COMMA")
    local obj2 = self:expect("ID").value
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_collision", obj1 = obj1, obj2 = obj2, body = body }
end

function Parser:parseOnMouse()
    self:advance()
    local body = self:parseBlock()
    self:expect("END")
    return { type = "on_mouse", body = body }
end

function Parser:parseMove()
    self:advance()
    local obj = self:expect("ID").value
    if self:at("BY") then
        self:advance()
        local dx = self:parseExpr()
        self:expect("COMMA")
        local dy = self:parseExpr()
        local dz = nil
        if self:match("COMMA") then
            dz = self:parseExpr()
        end
        return { type = "move", obj = obj, dx = dx, dy = dy, dz = dz }
    elseif self:at("TOWARDS") then
        self:advance()
        local target = self:expect("ID").value
        self:expect("SPEED")
        local speed = self:parseExpr()
        return { type = "move_towards", obj = obj, target = target, speed = speed }
    end
    error("Expected 'by' or 'towards' after move " .. obj)
end

function Parser:parseSetPos()
    self:advance()
    local obj = self:expect("ID").value
    if self:at("TO") then
        self:advance()
    end
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then
        z = self:parseExpr()
    end
    return { type = "setpos", obj = obj, x = x, y = y, z = z }
end

function Parser:parseGetPos()
    self:advance()
    local obj = self:expect("ID").value
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    local v3 = nil
    if self:match("COMMA") then
        v3 = self:expect("ID").value
    end
    return { type = "getpos", obj = obj, vars = { v1, v2, v3 } }
end

function Parser:parseDestroy()
    self:advance()
    local obj = self:expect("ID").value
    return { type = "destroy", obj = obj }
end

function Parser:parseSay()
    self:advance()
    local expr = self:parseExpr()
    return { type = "say", expr = expr }
end

function Parser:parseCreateModel()
    self:advance()
    local name = self:expect("ID").value
    self:expect("FROM")
    local modelPath = self:parseExpr()
    self:expect("AT")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then
        z = self:parseExpr()
    end
    local opts = {}
    while self:at("ROTATEX") or self:at("ROTATEY") or self:at("SCALE") or self:at("SIZE") or self:at("DRAWORDER") do
        local tt = self:peek().type
        if tt == "ROTATEX" then
            self:advance()
            opts.rotSpeedX = self:parseExpr()
        elseif tt == "ROTATEY" then
            self:advance()
            opts.rotSpeedY = self:parseExpr()
        elseif tt == "SCALE" then
            self:advance()
            opts.scale = self:parseExpr()
        elseif tt == "SIZE" then
            self:advance()
            opts.size = self:parseExpr()
        elseif tt == "DRAWORDER" then
            self:advance()
            opts.drawOrder = self:parseExpr()
        end
    end
    return { type = "createmodel", name = name, model = modelPath, x = x, y = y, z = z, opts = opts }
end

function Parser:parsePlaySound()
    self:advance()
    local name = self:expect("ID").value
    self:expect("FROM")
    local path = self:parseExpr()
    local loop = false
    if self:at("LOOP") then
        self:advance()
        loop = true
    end
    return { type = "playsound", name = name, path = path, loop = loop }
end

function Parser:parseStopSound()
    self:advance()
    local name = self:expect("ID").value
    return { type = "stopsound", name = name }
end

function Parser:parseDrawRect()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawrect", args = args }
end

function Parser:parseDrawText()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawtext", args = args }
end

function Parser:parseDrawCircle()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawcircle", args = args }
end

function Parser:parseDrawLine()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawline", args = args }
end

function Parser:parseDrawImage()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawimage", args = args }
end

function Parser:parseDrawModel()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do
        args[#args+1] = self:parseExpr()
    end
    return { type = "drawmodel", args = args }
end

function Parser:parseImport()
    self:advance()
    self:expect("LPAREN")
    local path = self:parseExpr()
    self:expect("RPAREN")
    return { type = "import", path = path }
end

function Parser:parseSetRot()
    self:advance()
    local obj = self:expect("ID").value
    local axis = self:expect("ID").value
    local val = self:parseExpr()
    return { type = "setrot", obj = obj, axis = axis, value = val }
end

function Parser:parseGetCanvasSize()
    self:advance()
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    return { type = "getcanvassize", vars = { v1, v2 } }
end

function Parser:parseParseScale()
    self:advance()
    local obj = self:expect("ID").value
    if self:at("TO") then
        self:advance()
    end
    local val = self:parseExpr()
    return { type = "setscale", obj = obj, value = val }
end

function Parser:parseVolume()
    self:advance()
    local val = self:parseExpr()
    return { type = "volume", value = val }
end

function Parser:parseSwitchScene()
    self:advance()
    local name = self:parseExpr()
    return { type = "switchscene", name = name }
end

function Parser:parseSetupCamera()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    local speed = nil
    local sensitivity = nil
    if self:at("SPEED") then
        self:advance()
        speed = self:parseExpr()
    end
    if self:at("SENSITIVITY") then
        self:advance()
        sensitivity = self:parseExpr()
    end
    return { type = "setup_camera", x = x, y = y, z = z, speed = speed, sensitivity = sensitivity }
end

function Parser:parseSetupRenderer()
    self:advance()
    local w = self:parseExpr()
    self:match("COMMA")
    local h = self:parseExpr()
    local fov = nil
    if self:at("FOV") then
        self:advance()
        fov = self:parseExpr()
    end
    return { type = "setup_renderer", width = w, height = h, fov = fov }
end

function Parser:parseLoadTexture()
    self:advance()
    local path = self:parseExpr()
    return { type = "load_texture", path = path }
end

function Parser:parseSetupCamera2D()
    self:advance()
    local args = {}
    if not self:at("ID") or (self:peek().value ~= "speed" and self:peek().value ~= "smoothing") then
        if not self:at("EOL") and not self:at("EOF") then
            args.x = self:parseExpr()
            if self:match("COMMA") then
                args.y = self:parseExpr()
            end
        end
    end
    while self:at("ID") and (self:peek().value == "zoom" or self:peek().value == "smoothing") do
        local key = self:advance().value
        self:expect("ASSIGN")
        args[key] = self:parseExpr()
    end
    return { type = "setup_camera2d", args = args }
end

function Parser:parseDrawSprite()
    self:advance()
    local path = self:parseExpr()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local r, g, b, a, sx, sy, ox, oy
    if self:match("COMMA") then r = self:parseExpr() end
    if self:match("COMMA") then g = self:parseExpr() end
    if self:match("COMMA") then b = self:parseExpr() end
    if self:match("COMMA") then a = self:parseExpr() end
    if self:match("COMMA") then sx = self:parseExpr() end
    if self:match("COMMA") then sy = self:parseExpr() end
    if self:match("COMMA") then ox = self:parseExpr() end
    if self:match("COMMA") then oy = self:parseExpr() end
    return { type = "draw_sprite", path = path, x = x, y = y, r = r, g = g, b = b, a = a, sx = sx, sy = sy, ox = ox, oy = oy }
end

function Parser:parseMoveCamera2D()
    self:advance()
    local dx = self:parseExpr()
    self:expect("COMMA")
    local dy = self:parseExpr()
    return { type = "move_camera2d", dx = dx, dy = dy }
end

function Parser:parseSetCamera2DPos()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    return { type = "set_camera2d_pos", x = x, y = y }
end

function Parser:parseZoomCamera2D()
    self:advance()
    local amount = self:parseExpr()
    return { type = "zoom_camera2d", amount = amount }
end

function Parser:parseSetGravity()
    self:advance()
    local gx = self:parseExpr()
    self:expect("COMMA")
    local gy = self:parseExpr()
    local gz = nil
    if self:match("COMMA") then gz = self:parseExpr() end
    return { type = "set_gravity", gx = gx, gy = gy, gz = gz }
end

function Parser:parseAddBody()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local opts = {}
    while not self:at("EOL") and not self:at("EOF") do
        self:match("COMMA")
        if self:at("ID") and self:peek().value == "w" then
            self:advance(); self:expect("ASSIGN"); opts.w = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "h" then
            self:advance(); self:expect("ASSIGN"); opts.h = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "radius" then
            self:advance(); self:expect("ASSIGN"); opts.radius = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "shape" then
            self:advance(); self:expect("ASSIGN"); opts.shape = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "mass" then
            self:advance(); self:expect("ASSIGN"); opts.mass = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "bounce" then
            self:advance(); self:expect("ASSIGN"); opts.bounce = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "friction" then
            self:advance(); self:expect("ASSIGN"); opts.friction = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "static" then
            self:advance()
            if self:match("ASSIGN") then
                local val = self:parseExpr()
                opts.static = (val == true or val == 1 or val == "true")
            else
                opts.static = true
            end
        elseif self:at("ID") and self:peek().value == "tag" then
            self:advance(); self:expect("ASSIGN"); opts.tag = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "vx" then
            self:advance(); self:expect("ASSIGN"); opts.vx = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "vy" then
            self:advance(); self:expect("ASSIGN"); opts.vy = self:parseExpr()
        else
            break
        end
    end
    return { type = "add_body", id = id, x = x, y = y, opts = opts }
end

function Parser:parseAddBody3D()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    local opts = {}
    while not self:at("EOL") and not self:at("EOF") do
        self:match("COMMA")
        if self:at("ID") and self:peek().value == "radius" then
            self:advance(); self:expect("ASSIGN"); opts.radius = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "shape" then
            self:advance(); self:expect("ASSIGN"); opts.shape = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "mass" then
            self:advance(); self:expect("ASSIGN"); opts.mass = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "bounce" then
            self:advance(); self:expect("ASSIGN"); opts.bounce = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "friction" then
            self:advance(); self:expect("ASSIGN"); opts.friction = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "static" then
            self:advance()
            if self:match("ASSIGN") then
                local val = self:parseExpr()
                opts.static = (val == true or val == 1 or val == "true")
            else
                opts.static = true
            end
        elseif self:at("ID") and self:peek().value == "tag" then
            self:advance(); self:expect("ASSIGN"); opts.tag = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "w" then
            self:advance(); self:expect("ASSIGN"); opts.w = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "h" then
            self:advance(); self:expect("ASSIGN"); opts.h = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "d" then
            self:advance(); self:expect("ASSIGN"); opts.d = self:parseExpr()
        else
            break
        end
    end
    return { type = "add_body3d", id = id, x = x, y = y, z = z, opts = opts }
end

function Parser:parseSetBodyVel()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local vx = self:parseExpr()
    self:expect("COMMA")
    local vy = self:parseExpr()
    return { type = "set_body_vel", id = id, vx = vx, vy = vy }
end

function Parser:parseSetBody3DVel()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local vx = self:parseExpr()
    self:expect("COMMA")
    local vy = self:parseExpr()
    self:expect("COMMA")
    local vz = self:parseExpr()
    return { type = "set_body3d_vel", id = id, vx = vx, vy = vy, vz = vz }
end

function Parser:parseGetBodyVel()
    self:advance()
    local id = self:parseExpr()
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    return { type = "get_body_vel", id = id, vars = { v1, v2 } }
end

function Parser:parseGetBody3DVel()
    self:advance()
    local id = self:parseExpr()
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    self:expect("COMMA")
    local v3 = self:expect("ID").value
    return { type = "get_body3d_vel", id = id, vars = { v1, v2, v3 } }
end

function Parser:parseBodyApplyForce()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local fx = self:parseExpr()
    self:expect("COMMA")
    local fy = self:parseExpr()
    return { type = "body_apply_force", id = id, fx = fx, fy = fy }
end

function Parser:parseBody3DApplyForce()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local fx = self:parseExpr()
    self:expect("COMMA")
    local fy = self:parseExpr()
    self:expect("COMMA")
    local fz = self:parseExpr()
    return { type = "body3d_apply_force", id = id, fx = fx, fy = fy, fz = fz }
end

function Parser:parseBodyApplyImpulse()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local ix = self:parseExpr()
    self:expect("COMMA")
    local iy = self:parseExpr()
    return { type = "body_apply_impulse", id = id, ix = ix, iy = iy }
end

function Parser:parseBody3DApplyImpulse()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local ix = self:parseExpr()
    self:expect("COMMA")
    local iy = self:parseExpr()
    self:expect("COMMA")
    local iz = self:parseExpr()
    return { type = "body3d_apply_impulse", id = id, ix = ix, iy = iy, iz = iz }
end

function Parser:parseSetBodyPos()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    return { type = "set_body_pos", id = id, x = x, y = y }
end

function Parser:parseSetBody3DPos()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    return { type = "set_body3d_pos", id = id, x = x, y = y, z = z }
end

function Parser:parseGetBodyPos()
    self:advance()
    local id = self:parseExpr()
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    return { type = "get_body_pos", id = id, vars = { v1, v2 } }
end

function Parser:parseGetBody3DPos()
    self:advance()
    local id = self:parseExpr()
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    self:expect("COMMA")
    local v3 = self:expect("ID").value
    return { type = "get_body3d_pos", id = id, vars = { v1, v2, v3 } }
end

function Parser:parseIsGrounded()
    self:advance()
    local id = self:parseExpr()
    return { type = "is_grounded", id = id }
end

function Parser:parseBodyColliding()
    self:advance()
    local id = self:parseExpr()
    self:expect("COMMA")
    local tag = self:parseExpr()
    return { type = "body_colliding", id = id, tag = tag }
end

function Parser:parseRemoveBody()
    self:advance()
    local id = self:parseExpr()
    return { type = "remove_body", id = id }
end

function Parser:parseRemoveBody3D()
    self:advance()
    local id = self:parseExpr()
    return { type = "remove_body3d", id = id }
end

function Parser:parseSetPhysics()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local mode = self:parseExpr()
    local opts = {}
    while self:match("COMMA") do
        if self:at("ID") and self:peek().value == "w" then
            self:advance(); self:expect("ASSIGN"); opts.w = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "h" then
            self:advance(); self:expect("ASSIGN"); opts.h = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "radius" then
            self:advance(); self:expect("ASSIGN"); opts.radius = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "bounce" then
            self:advance(); self:expect("ASSIGN"); opts.bounce = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "mass" then
            self:advance(); self:expect("ASSIGN"); opts.mass = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "friction" then
            self:advance(); self:expect("ASSIGN"); opts.friction = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "tag" then
            self:advance(); self:expect("ASSIGN"); opts.tag = self:parseExpr()
        elseif self:at("ID") and self:peek().value == "shape" then
            self:advance(); self:expect("ASSIGN"); opts.shape = self:parseExpr()
        else
            break
        end
    end
    return { type = "set_physics", objName = objName, mode = mode, opts = opts }
end

function Parser:parseObjImpulse()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local ix = self:parseExpr()
    self:expect("COMMA")
    local iy = self:parseExpr()
    return { type = "obj_impulse", objName = objName, ix = ix, iy = iy }
end

function Parser:parseObjSetVel()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local vx = self:parseExpr()
    self:expect("COMMA")
    local vy = self:parseExpr()
    return { type = "obj_set_vel", objName = objName, vx = vx, vy = vy }
end

function Parser:parseObjGetVel()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    return { type = "obj_get_vel", objName = objName, vars = { v1, v2 } }
end

function Parser:parseObjSetPos()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    return { type = "obj_set_pos", objName = objName, x = x, y = y }
end

function Parser:parseObjIsGrounded()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    return { type = "obj_is_grounded", objName = objName }
end

function Parser:parseObjColliding()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local tag = self:parseExpr()
    return { type = "obj_colliding", objName = objName, tag = tag }
end

function Parser:parseSetPhysicsGravity()
    self:advance()
    local g = self:parseExpr()
    return { type = "set_physics_gravity", gravity = g }
end

function Parser:parseSetPhysicsGround()
    self:advance()
    local y = self:parseExpr()
    return { type = "set_physics_ground", groundY = y }
end

function Parser:parseSetPhysics3DGravity()
    self:advance()
    local gx = self:parseExpr()
    local gy = nil
    local gz = nil
    if self:match("COMMA") then gy = self:parseExpr() end
    if self:match("COMMA") then gz = self:parseExpr() end
    return { type = "set_physics3d_gravity", gx = gx, gy = gy, gz = gz }
end

function Parser:parseSetPhysics3DFloor()
    self:advance()
    local y = self:parseExpr()
    return { type = "set_physics3d_floor", floorY = y }
end

function Parser:parseSetPhysics3D()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local mode = self:parseExpr()
    local opts = {}
    while self:match("COMMA") and self:at("ID") do
        local key = self:peek().value
        if key == "w" then self:advance(); self:expect("ASSIGN"); opts.w = self:parseExpr()
        elseif key == "h" then self:advance(); self:expect("ASSIGN"); opts.h = self:parseExpr()
        elseif key == "d" then self:advance(); self:expect("ASSIGN"); opts.d = self:parseExpr()
        elseif key == "radius" then self:advance(); self:expect("ASSIGN"); opts.radius = self:parseExpr()
        elseif key == "mass" then self:advance(); self:expect("ASSIGN"); opts.mass = self:parseExpr()
        elseif key == "bounce" then self:advance(); self:expect("ASSIGN"); opts.bounce = self:parseExpr()
        elseif key == "friction" then self:advance(); self:expect("ASSIGN"); opts.friction = self:parseExpr()
        elseif key == "tag" then self:advance(); self:expect("ASSIGN"); opts.tag = self:parseExpr()
        elseif key == "shape" then self:advance(); self:expect("ASSIGN"); opts.shape = self:parseExpr()
        else break end
    end
    return { type = "set_physics3d", objName = objName, mode = mode, opts = opts }
end

function Parser:parseObj3DImpulse()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local ix = self:parseExpr()
    self:expect("COMMA")
    local iy = self:parseExpr()
    local iz = nil
    if self:match("COMMA") then iz = self:parseExpr() end
    return { type = "obj3d_impulse", objName = objName, ix = ix, iy = iy, iz = iz }
end

function Parser:parseObj3DSetVel()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local vx = self:parseExpr()
    self:expect("COMMA")
    local vy = self:parseExpr()
    local vz = nil
    if self:match("COMMA") then vz = self:parseExpr() end
    return { type = "obj3d_set_vel", objName = objName, vx = vx, vy = vy, vz = vz }
end

function Parser:parseObj3DGetVel()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("ARROW")
    local v1 = self:expect("ID").value
    self:expect("COMMA")
    local v2 = self:expect("ID").value
    local v3 = nil
    if self:match("COMMA") then v3 = self:expect("ID").value end
    return { type = "obj3d_get_vel", objName = objName, vars = { v1, v2, v3 } }
end

function Parser:parseObj3DSetPos()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then z = self:parseExpr() end
    return { type = "obj3d_set_pos", objName = objName, x = x, y = y, z = z }
end

function Parser:parseObj3DIsGrounded()
    self:advance()
    local objToken = self:advance()
    return { type = "obj3d_is_grounded", objName = objToken.value }
end

function Parser:parseObj3DColliding()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local tag = self:parseExpr()
    return { type = "obj3d_colliding", objName = objToken.value, tag = tag }
end

function Parser:parseSetMouse()
    self:advance()
    local mode = self:expect("ID").value
    return { type = "set_mouse", mode = mode }
end

function Parser:parseAddObject()
    self:advance()
    local name = self:expect("ID").value
    self:expect("FROM")
    local model = self:parseExpr()
    self:expect("AT")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    local opts = {}
    while self:at("ROTATEX") or self:at("ROTATEY") or self:at("SCALE") or self:at("SIZE") or self:at("DRAWORDER") do
        local tt = self:peek().type
        if tt == "ROTATEX" then
            self:advance()
            opts.rotSpeedX = self:parseExpr()
        elseif tt == "ROTATEY" then
            self:advance()
            opts.rotSpeedY = self:parseExpr()
        elseif tt == "SCALE" then
            self:advance()
            opts.scale = self:parseExpr()
        elseif tt == "SIZE" then
            self:advance()
            opts.size = self:parseExpr()
        elseif tt == "DRAWORDER" then
            self:advance()
            opts.drawOrder = self:parseExpr()
        end
    end
    return { type = "add_object", name = name, model = model, x = x, y = y, z = z, opts = opts }
end

function Parser:parseAddCollider()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    local halfW, halfH, halfD = nil, nil, nil
    if self:at("SIZE") then
        self:advance()
        halfW = self:parseExpr()
        if self:at("COMMA") then
            self:advance()
            halfH = self:parseExpr()
            self:expect("COMMA")
            halfD = self:parseExpr()
        end
    end
    return { type = "add_collider", x = x, y = y, z = z, halfW = halfW, halfH = halfH, halfD = halfD }
end

function Parser:parseCheckHit()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    return { type = "check_hit", x = x, y = y, z = z }
end

function Parser:parseUIButton()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local w = self:parseExpr()
    self:expect("COMMA")
    local h = self:parseExpr()
    self:expect("COMMA")
    local label = self:parseExpr()
    local opts = {}
    while self:at("ID") and (self:peek().value == "id" or self:peek().value == "fontsize" or self:peek().value == "bg") do
        local key = self:advance().value
        self:expect("ASSIGN")
        opts[key] = self:parseExpr()
    end
    return { type = "ui_button", x = x, y = y, w = w, h = h, label = label, opts = opts }
end

function Parser:parseUICheckbox()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local size = self:parseExpr()
    self:expect("COMMA")
    local checked = self:parseExpr()
    local opts = {}
    if self:at("ID") and self:peek().value == "id" then
        self:advance()
        self:expect("ASSIGN")
        opts.id = self:parseExpr()
    end
    return { type = "ui_checkbox", x = x, y = y, size = size, checked = checked, opts = opts }
end

function Parser:parseUISlider()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local w = self:parseExpr()
    self:expect("COMMA")
    local h = self:parseExpr()
    self:expect("COMMA")
    local value = self:parseExpr()
    self:expect("COMMA")
    local minVal = self:parseExpr()
    self:expect("COMMA")
    local maxVal = self:parseExpr()
    local opts = {}
    if self:at("ID") and self:peek().value == "id" then
        self:advance()
        self:expect("ASSIGN")
        opts.id = self:parseExpr()
    end
    return { type = "ui_slider", x = x, y = y, w = w, h = h, value = value, minVal = minVal, maxVal = maxVal, opts = opts }
end

function Parser:parseUILabel()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local text = self:parseExpr()
    local opts = {}
    while self:at("ID") and (self:peek().value == "id" or self:peek().value == "fontsize" or self:peek().value == "align") do
        local key = self:advance().value
        self:expect("ASSIGN")
        opts[key] = self:parseExpr()
    end
    return { type = "ui_label", x = x, y = y, text = text, opts = opts }
end

function Parser:parseUIClicked()
    self:advance()
    local id = self:parseExpr()
    return { type = "ui_clicked", id = id }
end

function Parser:parseUIChecked()
    self:advance()
    local id = self:parseExpr()
    return { type = "ui_checked", id = id }
end

function Parser:parseUISliderValue()
    self:advance()
    local id = self:parseExpr()
    return { type = "ui_slider_value", id = id }
end

function Parser:parseUIVisible()
    self:advance()
    local id = self:parseExpr()
    return { type = "ui_visible", id = id }
end

function Parser:parseUIHidden()
    self:advance()
    local id = self:parseExpr()
    return { type = "ui_hidden", id = id }
end


function Parser:parseCreateAnim()
    self:advance()
    local nameToken = self:advance()
    local name = nameToken.value
    local frames = {}
    if self:match("LBRACKET") then
        if not self:at("RBRACKET") then
            frames[#frames+1] = self:parseExpr()
            while self:match("COMMA") do
                frames[#frames+1] = self:parseExpr()
            end
        end
        self:expect("RBRACKET")
    end
    local opts = {}
    while self:at("ID") do
        local key = self:peek().value
        if key == "frame_width" then self:advance(); self:expect("ASSIGN"); opts.frameWidth = self:parseExpr()
        elseif key == "frame_height" then self:advance(); self:expect("ASSIGN"); opts.frameHeight = self:parseExpr()
        elseif key == "fps" then self:advance(); self:expect("ASSIGN"); opts.fps = self:parseExpr()
        elseif key == "loop" then self:advance(); self:expect("ASSIGN"); opts.loop = self:parseExpr()
        else break end
    end
    return { type = "create_anim", name = name, frames = frames, opts = opts }
end

function Parser:parseCreateAnimatedSprite()
    self:advance()
    local nameToken = self:advance()
    local name = nameToken.value
    self:expect("COMMA")
    local imagePath = self:parseExpr()
    local opts = {}
    if self:match("COMMA") then
        while self:at("ID") do
            local key = self:peek().value
            if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
            elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
            elseif key == "scale_x" then self:advance(); self:expect("ASSIGN"); opts.scaleX = self:parseExpr()
            elseif key == "scale_y" then self:advance(); self:expect("ASSIGN"); opts.scaleY = self:parseExpr()
            else break end
        end
    end
    return { type = "create_animated_sprite", name = name, imagePath = imagePath, opts = opts }
end

function Parser:parseAnimAdd()
    self:advance()
    local spriteName = self:advance().value
    self:expect("COMMA")
    local animName = self:parseExpr()
    self:expect("COMMA")
    local frames = {}
    if self:match("LBRACKET") then
        if not self:at("RBRACKET") then
            frames[#frames+1] = self:parseExpr()
            while self:match("COMMA") do
                frames[#frames+1] = self:parseExpr()
            end
        end
        self:expect("RBRACKET")
    end
    local opts = {}
    while self:at("ID") do
        local key = self:peek().value
        if key == "fps" then self:advance(); self:expect("ASSIGN"); opts.fps = self:parseExpr()
        elseif key == "loop" then self:advance(); self:expect("ASSIGN"); opts.loop = self:parseExpr()
        elseif key == "frame_width" then self:advance(); self:expect("ASSIGN"); opts.frameWidth = self:parseExpr()
        elseif key == "frame_height" then self:advance(); self:expect("ASSIGN"); opts.frameHeight = self:parseExpr()
        else break end
    end
    return { type = "anim_add", spriteName = spriteName, animName = animName, frames = frames, opts = opts }
end

function Parser:parseAnimPlay()
    self:advance()
    local objToken = self:advance()
    local objName = objToken.value
    local animName = nil
    if self:match("COMMA") then animName = self:parseExpr() end
    return { type = "anim_play", objName = objName, animName = animName }
end

function Parser:parseAnimStop()
    self:advance()
    local objToken = self:advance()
    return { type = "anim_stop", objName = objToken.value }
end

function Parser:parseAnimPause()
    self:advance()
    local objToken = self:advance()
    return { type = "anim_pause", objName = objToken.value }
end

function Parser:parseAnimResume()
    self:advance()
    local objToken = self:advance()
    return { type = "anim_resume", objName = objToken.value }
end

function Parser:parseAnimSetSpeed()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local fps = self:parseExpr()
    return { type = "anim_set_speed", objName = objToken.value, fps = fps }
end

function Parser:parseAnimSetFrame()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local frame = self:parseExpr()
    return { type = "anim_set_frame", objName = objToken.value, frame = frame }
end

function Parser:parseDrawAnimatedSprite()
    self:advance()
    local objToken = self:advance()
    return { type = "draw_animated_sprite", objName = objToken.value }
end


function Parser:parseCreateParticles()
    self:advance()
    local nameToken = self:advance()
    local name = nameToken.value
    local opts = {}
    local function parseOpt(key)
        if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
        elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
        elseif key == "gravity" then self:advance(); self:expect("ASSIGN"); opts.gravity = self:parseExpr()
        elseif key == "max" then self:advance(); self:expect("ASSIGN"); opts.maxParticles = self:parseExpr()
        elseif key == "min_vx" then self:advance(); self:expect("ASSIGN"); opts.minVx = self:parseExpr()
        elseif key == "max_vx" then self:advance(); self:expect("ASSIGN"); opts.maxVx = self:parseExpr()
        elseif key == "min_vy" then self:advance(); self:expect("ASSIGN"); opts.minVy = self:parseExpr()
        elseif key == "max_vy" then self:advance(); self:expect("ASSIGN"); opts.maxVy = self:parseExpr()
        elseif key == "min_life" then self:advance(); self:expect("ASSIGN"); opts.minLife = self:parseExpr()
        elseif key == "max_life" then self:advance(); self:expect("ASSIGN"); opts.maxLife = self:parseExpr()
        elseif key == "min_size" then self:advance(); self:expect("ASSIGN"); opts.minSize = self:parseExpr()
        elseif key == "max_size" then self:advance(); self:expect("ASSIGN"); opts.maxSize = self:parseExpr()
        elseif key == "end_size" then self:advance(); self:expect("ASSIGN"); opts.endSize = self:parseExpr()
        elseif key == "spread_x" then self:advance(); self:expect("ASSIGN"); opts.spreadX = self:parseExpr()
        elseif key == "spread_y" then self:advance(); self:expect("ASSIGN"); opts.spreadY = self:parseExpr()
        elseif key == "rate" then self:advance(); self:expect("ASSIGN"); opts.emitRate = self:parseExpr()
        elseif key == "burst" then self:advance(); self:expect("ASSIGN"); opts.burstMode = self:parseExpr()
        elseif key == "shape" then self:advance(); self:expect("ASSIGN"); opts.shape = self:parseExpr()
        elseif key == "r" then self:advance(); self:expect("ASSIGN"); opts.r = self:parseExpr()
        elseif key == "g" then self:advance(); self:expect("ASSIGN"); opts.g = self:parseExpr()
        elseif key == "b" then self:advance(); self:expect("ASSIGN"); opts.b = self:parseExpr()
        elseif key == "a" then self:advance(); self:expect("ASSIGN"); opts.a = self:parseExpr()
        elseif key == "er" then self:advance(); self:expect("ASSIGN"); opts.er = self:parseExpr()
        elseif key == "eg" then self:advance(); self:expect("ASSIGN"); opts.eg = self:parseExpr()
        elseif key == "eb" then self:advance(); self:expect("ASSIGN"); opts.eb = self:parseExpr()
        elseif key == "ea" then self:advance(); self:expect("ASSIGN"); opts.ea = self:parseExpr()
        else return false end
        return true
    end
    if self:at("ID") then
        parseOpt(self:peek().value)
    end
    while self:match("COMMA") and self:at("ID") do
        if not parseOpt(self:peek().value) then break end
    end
    return { type = "create_particles", name = name, opts = opts }
end

function Parser:parseParticlesSetPos()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    return { type = "particles_set_pos", objName = objToken.value, x = x, y = y }
end

function Parser:parseParticlesEmit()
    self:advance()
    local objToken = self:advance()
    local count = nil
    if self:match("COMMA") then count = self:parseExpr() end
    return { type = "particles_emit", objName = objToken.value, count = count }
end

function Parser:parseParticlesBurst()
    self:advance()
    local objToken = self:advance()
    local count = nil
    if self:match("COMMA") then count = self:parseExpr() end
    return { type = "particles_burst", objName = objToken.value, count = count }
end

function Parser:parseParticlesStart()
    self:advance()
    local objToken = self:advance()
    return { type = "particles_start", objName = objToken.value }
end

function Parser:parseParticlesStop()
    self:advance()
    local objToken = self:advance()
    return { type = "particles_stop", objName = objToken.value }
end

function Parser:parseParticlesClear()
    self:advance()
    local objToken = self:advance()
    return { type = "particles_clear", objName = objToken.value }
end

function Parser:parseParticlesConfigure()
    self:advance()
    local objToken = self:advance()
    local opts = {}
    while self:match("COMMA") and self:at("ID") do
        local key = self:peek().value
        if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
        elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
        elseif key == "gravity" then self:advance(); self:expect("ASSIGN"); opts.gravity = self:parseExpr()
        elseif key == "rate" then self:advance(); self:expect("ASSIGN"); opts.emitRate = self:parseExpr()
        else break end
    end
    return { type = "particles_configure", objName = objToken.value, opts = opts }
end

function Parser:parseDrawParticles()
    self:advance()
    local objToken = self:advance()
    return { type = "draw_particles", objName = objToken.value }
end


function Parser:parseCreateParticles3D()
    self:advance()
    local nameToken = self:advance()
    local name = nameToken.value
    local opts = {}
    local function parseOpt(key)
        if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
        elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
        elseif key == "z" then self:advance(); self:expect("ASSIGN"); opts.z = self:parseExpr()
        elseif key == "gravity" then self:advance(); self:expect("ASSIGN"); opts.gravity = self:parseExpr()
        elseif key == "max" then self:advance(); self:expect("ASSIGN"); opts.maxParticles = self:parseExpr()
        elseif key == "min_vx" then self:advance(); self:expect("ASSIGN"); opts.minVx = self:parseExpr()
        elseif key == "max_vx" then self:advance(); self:expect("ASSIGN"); opts.maxVx = self:parseExpr()
        elseif key == "min_vy" then self:advance(); self:expect("ASSIGN"); opts.minVy = self:parseExpr()
        elseif key == "max_vy" then self:advance(); self:expect("ASSIGN"); opts.maxVy = self:parseExpr()
        elseif key == "min_vz" then self:advance(); self:expect("ASSIGN"); opts.minVz = self:parseExpr()
        elseif key == "max_vz" then self:advance(); self:expect("ASSIGN"); opts.maxVz = self:parseExpr()
        elseif key == "min_life" then self:advance(); self:expect("ASSIGN"); opts.minLife = self:parseExpr()
        elseif key == "max_life" then self:advance(); self:expect("ASSIGN"); opts.maxLife = self:parseExpr()
        elseif key == "min_size" then self:advance(); self:expect("ASSIGN"); opts.minSize = self:parseExpr()
        elseif key == "max_size" then self:advance(); self:expect("ASSIGN"); opts.maxSize = self:parseExpr()
        elseif key == "end_size" then self:advance(); self:expect("ASSIGN"); opts.endSize = self:parseExpr()
        elseif key == "spread_x" then self:advance(); self:expect("ASSIGN"); opts.spreadX = self:parseExpr()
        elseif key == "spread_y" then self:advance(); self:expect("ASSIGN"); opts.spreadY = self:parseExpr()
        elseif key == "spread_z" then self:advance(); self:expect("ASSIGN"); opts.spreadZ = self:parseExpr()
        elseif key == "rate" then self:advance(); self:expect("ASSIGN"); opts.emitRate = self:parseExpr()
        elseif key == "burst" then self:advance(); self:expect("ASSIGN"); opts.burstMode = self:parseExpr()
        elseif key == "r" then self:advance(); self:expect("ASSIGN"); opts.r = self:parseExpr()
        elseif key == "g" then self:advance(); self:expect("ASSIGN"); opts.g = self:parseExpr()
        elseif key == "b" then self:advance(); self:expect("ASSIGN"); opts.b = self:parseExpr()
        elseif key == "a" then self:advance(); self:expect("ASSIGN"); opts.a = self:parseExpr()
        elseif key == "er" then self:advance(); self:expect("ASSIGN"); opts.er = self:parseExpr()
        elseif key == "eg" then self:advance(); self:expect("ASSIGN"); opts.eg = self:parseExpr()
        elseif key == "eb" then self:advance(); self:expect("ASSIGN"); opts.eb = self:parseExpr()
        elseif key == "ea" then self:advance(); self:expect("ASSIGN"); opts.ea = self:parseExpr()
        else return false end
        return true
    end
    if self:at("ID") then parseOpt(self:peek().value) end
    while self:match("COMMA") and self:at("ID") do
        if not parseOpt(self:peek().value) then break end
    end
    return { type = "create_particles3d", name = name, opts = opts }
end

function Parser:parseParticles3DSetPos()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then z = self:parseExpr() end
    return { type = "particles3d_set_pos", objName = objToken.value, x = x, y = y, z = z }
end

function Parser:parseParticles3DEmit()
    self:advance()
    local objToken = self:advance()
    local count = nil
    if self:match("COMMA") then count = self:parseExpr() end
    return { type = "particles3d_emit", objName = objToken.value, count = count }
end

function Parser:parseParticles3DBurst()
    self:advance()
    local objToken = self:advance()
    local count = nil
    if self:match("COMMA") then count = self:parseExpr() end
    return { type = "particles3d_burst", objName = objToken.value, count = count }
end

function Parser:parseParticles3DStart()
    self:advance()
    local objToken = self:advance()
    return { type = "particles3d_start", objName = objToken.value }
end

function Parser:parseParticles3DStop()
    self:advance()
    local objToken = self:advance()
    return { type = "particles3d_stop", objName = objToken.value }
end

function Parser:parseParticles3DClear()
    self:advance()
    local objToken = self:advance()
    return { type = "particles3d_clear", objName = objToken.value }
end

function Parser:parseParticles3DConfigure()
    self:advance()
    local objToken = self:advance()
    local opts = {}
    while self:match("COMMA") and self:at("ID") do
        local key = self:peek().value
        if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
        elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
        elseif key == "z" then self:advance(); self:expect("ASSIGN"); opts.z = self:parseExpr()
        elseif key == "gravity" then self:advance(); self:expect("ASSIGN"); opts.gravity = self:parseExpr()
        elseif key == "rate" then self:advance(); self:expect("ASSIGN"); opts.emitRate = self:parseExpr()
        else break end
    end
    return { type = "particles3d_configure", objName = objToken.value, opts = opts }
end

function Parser:parseDrawParticles3D()
    self:advance()
    local objToken = self:advance()
    return { type = "draw_particles3d", objName = objToken.value }
end


function Parser:parseWatchFile()
    self:advance()
    local path = self:parseExpr()
    return { type = "watch_file", path = path }
end

function Parser:parseUnwatchFile()
    self:advance()
    local path = self:parseExpr()
    return { type = "unwatch_file", path = path }
end


function Parser:parseBindKey()
    self:advance()
    local action = self:parseExpr()
    local keys = {}
    while self:match("COMMA") do
        keys[#keys+1] = self:parseExpr()
    end
    return { type = "bind_key", action = action, keys = keys }
end

function Parser:parseUnbindKey()
    self:advance()
    local action = self:parseExpr()
    return { type = "unbind_key", action = action }
end


function Parser:parseConsoleLog()
    self:advance()
    local msg = self:parseExpr()
    return { type = "console_log", msg = msg }
end

function Parser:parseProfilerStart()
    self:advance()
    local name = self:parseExpr()
    return { type = "profiler_start", name = name }
end

function Parser:parseProfilerEnd()
    self:advance()
    local name = self:parseExpr()
    return { type = "profiler_end", name = name }
end


function Parser:parseCreatePanel()
    self:advance()
    local nameToken = self:advance()
    local name = nameToken.value
    local opts = {}
    if self:match("COMMA") then
        while self:at("ID") do
            local key = self:peek().value
            if key == "x" then self:advance(); self:expect("ASSIGN"); opts.x = self:parseExpr()
            elseif key == "y" then self:advance(); self:expect("ASSIGN"); opts.y = self:parseExpr()
            elseif key == "w" then self:advance(); self:expect("ASSIGN"); opts.w = self:parseExpr()
            elseif key == "h" then self:advance(); self:expect("ASSIGN"); opts.h = self:parseExpr()
            elseif key == "title" then self:advance(); self:expect("ASSIGN"); opts.title = self:parseExpr()
            elseif key == "scrollable" then self:advance(); self:expect("ASSIGN"); opts.scrollable = self:parseExpr()
            else break end
        end
    end
    return { type = "create_panel", name = name, opts = opts }
end

function Parser:parsePanelAddButton()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local label = self:parseExpr()
    local opts = {}
    if self:match("COMMA") then
        opts.w = self:parseExpr()
        if self:match("COMMA") then opts.h = self:parseExpr() end
    end
    if self:match("COMMA") and self:at("ID") and self:peek().value == "id" then
        self:advance(); self:expect("ASSIGN"); opts.id = self:parseExpr()
    end
    return { type = "panel_add_button", objName = objToken.value, label = label, opts = opts }
end

function Parser:parsePanelAddLabel()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local text = self:parseExpr()
    local opts = {}
    if self:match("COMMA") and self:at("ID") then
        local key = self:peek().value
        if key == "size" then self:advance(); self:expect("ASSIGN"); opts.size = self:parseExpr() end
    end
    return { type = "panel_add_label", objName = objToken.value, text = text, opts = opts }
end

function Parser:parsePanelAddSeparator()
    self:advance()
    local objToken = self:advance()
    return { type = "panel_add_separator", objName = objToken.value }
end

function Parser:parseDrawPanel()
    self:advance()
    local objToken = self:advance()
    return { type = "draw_panel", objName = objToken.value }
end

function Parser:parsePanelSetVisible()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local visible = self:parseExpr()
    return { type = "panel_set_visible", objName = objToken.value, visible = visible }
end

function Parser:parsePanelSetPosition()
    self:advance()
    local objToken = self:advance()
    self:expect("COMMA")
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    return { type = "panel_set_position", objName = objToken.value, x = x, y = y }
end

function Parser:parseExprStatement()

    local expr = self:parsePrimary()

    if self:at("ASSIGN") then
        self:advance()
        local val = self:parseExpr()
        return { type = "expr_assign", target = expr, expr = val }
    end

    return { type = "expr", expr = expr }
end

function MioLang.new(ctx)
    local self = setmetatable({}, MioLang)
    self.ctx = ctx or {}
    self.vars = {}
    self.imported = {}
    self.onUpdateBodies = {}
    self.onDrawBodies = {}
    self.onKeyHandlers = {}
    self.onClickHandlers = {}
    self.onCollisionPairs = {}
    self.onMouseBodies = {}
    self.timers = {}
    self.name = ""
    self.initialized = false
    self._break = false
    self.imageCache = {}
    if not self.ctx.ui then
        local UIElements = require("mioengine.core.ui_elements")
        self.ctx.ui = UIElements.new(self.ctx.resources)
    end
    return self
end

function MioLang:log(msg)
    print("[.mio:" .. self.name .. "] " .. tostring(msg))
end

function MioLang:load(source, name)
    self.name = name or "anon"

    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    local parser = Parser.new(tokens)
    local ast = parser:parse()

    self.ast = ast
    self.initialized = true

    self:runTopLevel(ast)
end

function MioLang:runTopLevel(stmts)
    for _, stmt in ipairs(stmts) do
        if stmt.type == "on_update" then
            self.onUpdateBodies[#self.onUpdateBodies+1] = stmt.body
        elseif stmt.type == "on_draw" then
            self.onDrawBodies[#self.onDrawBodies+1] = stmt.body
        elseif stmt.type == "on_key" then
            self.onKeyHandlers[stmt.key] = self.onKeyHandlers[stmt.key] or {}
            self.onKeyHandlers[stmt.key][#self.onKeyHandlers[stmt.key]+1] = stmt.body
        elseif stmt.type == "on_click" then
            self.onClickHandlers[stmt.obj] = self.onClickHandlers[stmt.obj] or {}
            self.onClickHandlers[stmt.obj][#self.onClickHandlers[stmt.obj]+1] = stmt.body
        elseif stmt.type == "on_collision" then
            self.onCollisionPairs[#self.onCollisionPairs+1] = {
                obj1 = stmt.obj1, obj2 = stmt.obj2, body = stmt.body,
            }
        elseif stmt.type == "on_mouse" then
            self.onMouseBodies[#self.onMouseBodies+1] = stmt.body
        elseif stmt.type == "import" then
            self:doImport(stmt)
        else

            pcall(function() self:exec(stmt) end)
        end
    end
end

function MioLang:doImport(stmt)
    local path = self:evalExpr(stmt.path)
    if type(path) ~= "string" then
        self:log("import: path must be a string")
        return
    end
    if self.imported[path] then return end
    self.imported[path] = true

    local content = love.filesystem.read(path)
    if not content then
        self:log("import: cannot load " .. path)
        return
    end

    local sub = MioLang.new(self.ctx)
    sub.vars = self.vars
    sub.imported = self.imported
    sub.name = path
    local ok, err = pcall(function() sub:load(content, path) end)
    if not ok then
        self:log("import error in " .. path .. ": " .. tostring(err))
        return
    end

    for _, body in ipairs(sub.onUpdateBodies) do
        self.onUpdateBodies[#self.onUpdateBodies+1] = body
    end
    for _, body in ipairs(sub.onDrawBodies) do
        self.onDrawBodies[#self.onDrawBodies+1] = body
    end
    for key, handlers in pairs(sub.onKeyHandlers) do
        self.onKeyHandlers[key] = self.onKeyHandlers[key] or {}
        for _, body in ipairs(handlers) do
            self.onKeyHandlers[key][#self.onKeyHandlers[key]+1] = body
        end
    end
    for obj, handlers in pairs(sub.onClickHandlers) do
        self.onClickHandlers[obj] = self.onClickHandlers[obj] or {}
        for _, body in ipairs(handlers) do
            self.onClickHandlers[obj][#self.onClickHandlers[obj]+1] = body
        end
    end
    for _, pair in ipairs(sub.onCollisionPairs) do
        self.onCollisionPairs[#self.onCollisionPairs+1] = pair
    end
    for _, body in ipairs(sub.onMouseBodies) do
        self.onMouseBodies[#self.onMouseBodies+1] = body
    end

    self:log("imported: " .. path)
end

function MioLang:evalExpr(node)
    if not node then return nil end

    if node.type == "number" then return node.value end
    if node.type == "string" then return node.value end
    if node.type == "boolean" then return node.value end

    if node.type == "array" then
        local arr = {}
        for i, el in ipairs(node.elements) do
            arr[i] = self:evalExpr(el)
        end
        return arr
    end

    if node.type == "var" then
        return self.vars[node.name]
    end

    if node.type == "index" then
        local arr = self.vars[node.array]
        local idx = self:evalExpr(node.index)
        if type(idx) == "number" then idx = math.floor(idx) end
        if type(arr) == "table" then return arr[idx] end
        return nil
    end

    if node.type == "property" then
        local obj = self.vars[node.object]
        if type(obj) == "table" then return obj[node.prop] end
        return nil
    end

    if node.type == "binop" then
        local l = self:evalExpr(node.left)
        local r = self:evalExpr(node.right)
        local op = node.op
        if op == "+" then return (tonumber(l) or 0) + (tonumber(r) or 0)
        elseif op == "-" then return (tonumber(l) or 0) - (tonumber(r) or 0)
        elseif op == "*" then return (tonumber(l) or 0) * (tonumber(r) or 0)
        elseif op == "/" then return (tonumber(l) or 0) / (tonumber(r) or 1)
        elseif op == "%" then return (tonumber(l) or 0) % (tonumber(r) or 1)
        elseif op == "==" then return l == r
        elseif op == "~=" then return l ~= r
        elseif op == "<" then return (tonumber(l) or 0) < (tonumber(r) or 0)
        elseif op == ">" then return (tonumber(l) or 0) > (tonumber(r) or 0)
        elseif op == "<=" then return (tonumber(l) or 0) <= (tonumber(r) or 0)
        elseif op == ">=" then return (tonumber(l) or 0) >= (tonumber(r) or 0)
        elseif op == "and" then return l and r
        elseif op == "or" then return l or r
        end
        return nil
    end

    if node.type == "unop" then
        local v = self:evalExpr(node.expr)
        if node.op == "-" then return -(tonumber(v) or 0) end
        if node.op == "not" then return not v end
        return nil
    end

    if node.type == "ui_clicked" then
        local id = self:evalExpr(node.id)
        local var = self.vars["_btn_" .. id]
        if var then return var.justClicked end
        return false
    end

    if node.type == "ui_checked" then
        local id = self:evalExpr(node.id)
        local var = self.vars["_chk_" .. id]
        if var then return var.checked end
        return false
    end

    if node.type == "ui_slider_value" then
        local id = self:evalExpr(node.id)
        local var = self.vars["_sld_" .. id]
        if var then return var.value end
        return 0
    end

    if node.type == "is_grounded" then
        local id = tostring(self:evalExpr(node.id))
        if self.ctx.physics then
            return self.ctx.physics:isGrounded(id)
        elseif self.ctx.physics3d then
            return self.ctx.physics3d:isGrounded(id)
        end
        return false
    end

    if node.type == "body_colliding" then
        local id = tostring(self:evalExpr(node.id))
        local tag = tostring(self:evalExpr(node.tag))
        if self.ctx.physics then
            local body = self.ctx.physics:getBody(id)
            if body then
                for _, col in ipairs(body.collisions) do
                    if col.other.tag == tag then return true end
                end
            end
        elseif self.ctx.physics3d then
            local body = self.ctx.physics3d:getBody(id)
            if body then
                for _, col in ipairs(body.collisions) do
                    if col.other.tag == tag then return true end
                end
            end
        end
        return false
    end

    if node.type == "obj_is_grounded" then
        local objName = node.objName
        local obj = self.vars[objName]
        if obj and obj._physicsId and self.ctx.flagPhysics then
            return self.ctx.flagPhysics:isGrounded(obj._physicsId)
        end
        return false
    end

    if node.type == "obj_colliding" then
        local objName = node.objName
        local tag = tostring(self:evalExpr(node.tag))
        local obj = self.vars[objName]
        if obj and obj._physicsId and self.ctx.flagPhysics then
            local body = self.ctx.flagPhysics:getBody(obj._physicsId)
            if body then
                for _, col in ipairs(body.collisions) do
                    if col.other.tag == tag then return true end
                end
            end
        end
        return false
    end

    if node.type == "key_down" then
        local key = tostring(self:evalExpr(node.key))
        return love.keyboard.isDown(key)
    end

    if node.type == "mouse_down" then
        local btn = tonumber(self:evalExpr(node.button)) or 1
        return love.mouse.isDown(btn)
    end

    if node.type == "action_down" then
        local action = tostring(self:evalExpr(node.action))
        if self.ctx.inputMapper then return self.ctx.inputMapper:isDown(action) end
        return false
    end

    if node.type == "action_pressed" then
        local action = tostring(self:evalExpr(node.action))
        if self.ctx.inputMapper then return self.ctx.inputMapper:wasPressed(action) end
        return false
    end

    if node.type == "action_released" then
        local action = tostring(self:evalExpr(node.action))
        if self.ctx.inputMapper then return self.ctx.inputMapper:wasReleased(action) end
        return false
    end

    if node.type == "anim_is_done" then
        local sprite = self.vars[node.objName]
        if sprite and sprite.isDone then return sprite:isDone() end
        return true
    end

    if node.type == "particles_get_count" then
        local ps = self.vars[node.objName]
        if ps and ps.getCount then return ps:getCount() end
        return 0
    end

    if node.type == "obj3d_is_grounded" then
        local obj = self.vars[node.objName]
        if obj and obj._physics3dId and self.ctx.flagPhysics3d then
            return self.ctx.flagPhysics3d:isGrounded(obj._physics3dId)
        end
        return false
    end

    if node.type == "obj3d_colliding" then
        local tag = tostring(self:evalExpr(node.tag))
        local obj = self.vars[node.objName]
        if obj and obj._physics3dId and self.ctx.flagPhysics3d then
            return self.ctx.flagPhysics3d:collidingWithTag(obj._physics3dId, tag)
        end
        return false
    end

    if node.type == "particles3d_get_count" then
        local ps = self.vars[node.objName]
        if ps and ps.getCount then return ps:getCount() end
        return 0
    end

    if node.type == "ui_visible" then
        local id = self:evalExpr(node.id)
        local var = self.vars["_btn_" .. id] or self.vars["_chk_" .. id] or self.vars["_sld_" .. id] or self.vars["_lbl_" .. id]
        if var then var.visible = true end
        return nil
    end

    if node.type == "ui_hidden" then
        local id = self:evalExpr(node.id)
        local var = self.vars["_btn_" .. id] or self.vars["_chk_" .. id] or self.vars["_sld_" .. id] or self.vars["_lbl_" .. id]
        if var then var.visible = false end
        return nil
    end

    if node.type == "call" then
        return self:callFunc(node.name, node.args)
    end

    if node.type == "methodcall" then
        return self:callMethod(node.object, node.method, node.args)
    end

    return nil
end

function MioLang:callFunc(name, argNodes)
    local args = {}
    for i, a in ipairs(argNodes) do
        args[i] = self:evalExpr(a)
    end

    if name == "sin" then return math.sin(args[1] or 0)
    elseif name == "cos" then return math.cos(args[1] or 0)
    elseif name == "atan2" then return math.atan2(args[1] or 0, args[2] or 0)
    elseif name == "sqrt" then return math.sqrt(args[1] or 0)
    elseif name == "abs" then return math.abs(args[1] or 0)
    elseif name == "floor" then return math.floor(args[1] or 0)
    elseif name == "ceil" then return math.ceil(args[1] or 0)
    elseif name == "min" then return math.min(args[1] or 0, args[2] or 0)
    elseif name == "max" then return math.max(args[1] or 0, args[2] or 0)
    elseif name == "random" then
        if args[1] and args[2] then return math.random(args[1], args[2])
        elseif args[1] then return math.random(args[1])
        else return math.random() end
    elseif name == "dist" then
        local dx = (args[4] or 0) - (args[1] or 0)
        local dy = (args[5] or 0) - (args[2] or 0)
        local dz = (args[6] or 0) - (args[3] or 0)
        return math.sqrt(dx*dx + dy*dy + dz*dz)
    elseif name == "pi" then return math.pi
    elseif name == "type" then return type(args[1])
    elseif name == "tostring" then return tostring(args[1])
    elseif name == "tonumber" then return tonumber(args[1])
    elseif name == "str" then
        local parts = {}
        for i, a in ipairs(args) do parts[i] = tostring(a) end
        return table.concat(parts)
    elseif name == "print" then
        self:log(tostring(args[1] or ""))
        return nil
    end

    if self.vars[name] and type(self.vars[name]) == "function" then
        return self.vars[name](unpack(args))
    end

    self:log("Unknown function: " .. name)
    return nil
end

function MioLang:callMethod(objName, method, argNodes)
    local obj = self.vars[objName]
    if not obj then return nil end

    local args = {}
    for i, a in ipairs(argNodes) do
        args[i] = self:evalExpr(a)
    end

    if type(obj) == "table" and obj[method] then
        return obj[method](obj, unpack(args))
    end

    return nil
end

function MioLang:exec(stmt)
    if self._break then return end
    if not stmt then return end

    if stmt.type == "assign" then
        local val = self:evalExpr(stmt.expr)
        local cur = self.vars[stmt.name]
        if stmt.op == "=" then
            self.vars[stmt.name] = val
        elseif stmt.op == "+" then
            self.vars[stmt.name] = (tonumber(cur) or 0) + (tonumber(val) or 0)
        elseif stmt.op == "-" then
            self.vars[stmt.name] = (tonumber(cur) or 0) - (tonumber(val) or 0)
        elseif stmt.op == "*" then
            self.vars[stmt.name] = (tonumber(cur) or 0) * (tonumber(val) or 0)
        elseif stmt.op == "/" then
            self.vars[stmt.name] = (tonumber(cur) or 0) / (tonumber(val) or 1)
        end

    elseif stmt.type == "arrayassign" then
        local arr = self.vars[stmt.name]
        if type(arr) ~= "table" then arr = {}; self.vars[stmt.name] = arr end
        local idx = self:evalExpr(stmt.index)
        if type(idx) == "number" then idx = math.floor(idx) end
        local val = self:evalExpr(stmt.expr)
        if stmt.op == "=" then
            arr[idx] = val
        else
            local cur = arr[idx] or 0
            if stmt.op == "+" then arr[idx] = cur + val
            elseif stmt.op == "-" then arr[idx] = cur - val
            elseif stmt.op == "*" then arr[idx] = cur * val
            elseif stmt.op == "/" then arr[idx] = cur / (val or 1)
            end
        end

    elseif stmt.type == "if" then
        local cond = self:evalExpr(stmt.cond)
        if cond and cond ~= 0 and cond ~= false and cond ~= "" then
            self:execBlock(stmt.body)
        elseif stmt.elseBody then
            self:execBlock(stmt.elseBody)
        end

    elseif stmt.type == "for" then
        local from = tonumber(self:evalExpr(stmt.from)) or 0
        local to = tonumber(self:evalExpr(stmt.to)) or 0
        local step = stmt.step and (tonumber(self:evalExpr(stmt.step)) or 1) or 1
        if from <= to and step > 0 then
            for i = from, to, step do
                self.vars[stmt.var] = i
                self:execBlock(stmt.body)
                if self._break then self._break = false; break end
            end
        elseif from >= to and step < 0 then
            for i = from, to, step do
                self.vars[stmt.var] = i
                self:execBlock(stmt.body)
                if self._break then self._break = false; break end
            end
        end

    elseif stmt.type == "loop" then
        if stmt.mode == "forever" then

        end

    elseif stmt.type == "break" then
        self._break = true

    elseif stmt.type == "say" then
        local val = self:evalExpr(stmt.expr)
        self:log(tostring(val))

    elseif stmt.type == "createmodel" then
        self:execCreateModel(stmt)

    elseif stmt.type == "move" then
        self:execMove(stmt)

    elseif stmt.type == "move_towards" then
        self:execMoveTowards(stmt)

    elseif stmt.type == "setpos" then
        self:execSetPos(stmt)

    elseif stmt.type == "getpos" then
        self:execGetPos(stmt)

    elseif stmt.type == "setrot" then
        self:execSetRot(stmt)

    elseif stmt.type == "destroy" then
        self:execDestroy(stmt)

    elseif stmt.type == "playsound" then
        self:execPlaySound(stmt)

    elseif stmt.type == "stopsound" then
        local Sound = require("mioengine.core.sound")
        Sound.stop(stmt.name)

    elseif stmt.type == "drawrect" then
        self:execDrawRect(stmt)

    elseif stmt.type == "drawtext" then
        self:execDrawText(stmt)

    elseif stmt.type == "drawcircle" then
        self:execDrawCircle(stmt)

    elseif stmt.type == "drawline" then
        self:execDrawLine(stmt)

    elseif stmt.type == "drawimage" then
        self:execDrawImage(stmt)

    elseif stmt.type == "drawmodel" then
        self:execDrawModel(stmt)

    elseif stmt.type == "getcanvassize" then
        self:execGetCanvasSize(stmt)

    elseif stmt.type == "setscale" then
        self:execSetScale(stmt)

    elseif stmt.type == "mute" then
        local Sound = require("mioengine.core.sound")
        Sound.toggleMute()

    elseif stmt.type == "volume" then
        local Sound = require("mioengine.core.sound")
        Sound.setMasterVolume(self:evalExpr(stmt.value))

    elseif stmt.type == "switchscene" then
        local name = self:evalExpr(stmt.name)
        if self.ctx.switchScene then self.ctx.switchScene(name) end

    elseif stmt.type == "setup_camera" then
        local Camera = require("mioengine.core.camera")
        local x = tonumber(self:evalExpr(stmt.x)) or 0
        local y = tonumber(self:evalExpr(stmt.y)) or 2
        local z = tonumber(self:evalExpr(stmt.z)) or -3
        local speed = stmt.speed and tonumber(self:evalExpr(stmt.speed)) or 4
        local sens = stmt.sensitivity and tonumber(self:evalExpr(stmt.sensitivity)) or 0.0025
        local cam = Camera.new({ x = x, y = y, z = z, moveSpeed = speed, mouseSensitivity = sens })
        self.ctx.camera = cam
        self.vars["camera"] = cam

    elseif stmt.type == "setup_renderer" then
        local Renderer = require("mioengine.core.renderer")
        local w = tonumber(self:evalExpr(stmt.width)) or 320
        local h = tonumber(self:evalExpr(stmt.height)) or 240
        local fov = stmt.fov and tonumber(self:evalExpr(stmt.fov)) or 200
        local ren = Renderer.new({ width = w, height = h, fov = fov, resources = self.ctx.resources })
        self.ctx.renderer = ren
        self.vars["renderer"] = ren

    elseif stmt.type == "load_texture" then
        local path = self:evalExpr(stmt.path)
        if self.ctx.renderer then
            self.ctx.renderer:load(path)
        end

    elseif stmt.type == "set_mouse" then
        if stmt.mode == "relative" then
            love.mouse.setRelativeMode(true)
        elseif stmt.mode == "visible" then
            love.mouse.setRelativeMode(false)
        end

    elseif stmt.type == "camera_update" then
        local dt = self.ctx.dt or 0
        if self.ctx.camera then
            local allColliders = {}
            for _, c in ipairs(self.ctx.colliders or {}) do
                allColliders[#allColliders + 1] = c
            end
            if self.ctx.flagPhysics3d then
                for _, b in pairs(self.ctx.flagPhysics3d.bodies) do
                    if b.static then
                        allColliders[#allColliders + 1] = {
                            x = b.x, y = b.y, z = b.z,
                            halfSizeX = b.w / 2, halfSizeY = b.h / 2, halfSizeZ = b.d / 2,
                        }
                    end
                end
            end
            self.ctx.camera:update(dt, allColliders)
        end

    elseif stmt.type == "camera_collide" then
        local dt = self.ctx.dt or 0
        if self.ctx.camera then
            local allColliders = {}
            for _, c in ipairs(self.ctx.colliders or {}) do
                allColliders[#allColliders + 1] = c
            end
            if self.ctx.flagPhysics3d then
                for _, b in pairs(self.ctx.flagPhysics3d.bodies) do
                    if b.static then
                        allColliders[#allColliders + 1] = {
                            x = b.x, y = b.y, z = b.z,
                            halfSizeX = b.w / 2, halfSizeY = b.h / 2, halfSizeZ = b.d / 2,
                        }
                    end
                end
            end
            self.ctx.camera:update(dt, allColliders)
        end

    elseif stmt.type == "exit_game" then
        if self.ctx.switchScene then self.ctx.switchScene("menu") end

    elseif stmt.type == "add_object" then
        self:execAddObject(stmt)

    elseif stmt.type == "add_collider" then
        self:execAddCollider(stmt)

    elseif stmt.type == "check_hit" then
        self:execCheckHit(stmt)

    elseif stmt.type == "setup_camera2d" then
        local Camera2D = require("mioengine.core.camera2d")
        local args = stmt.args or {}
        local cam = Camera2D.new({
            x = args.x and tonumber(self:evalExpr(args.x)) or 0,
            y = args.y and tonumber(self:evalExpr(args.y)) or 0,
            zoom = args.zoom and tonumber(self:evalExpr(args.zoom)) or 1,
            smoothing = args.smoothing and tonumber(self:evalExpr(args.smoothing)) or 0,
        })
        self.ctx.camera2d = cam
        self.ctx.is2D = true
        self.vars["camera2d"] = cam

    elseif stmt.type == "draw_sprite" then
        self:execDrawSprite(stmt)

    elseif stmt.type == "move_camera2d" then
        if self.ctx.camera2d then
            local dx = tonumber(self:evalExpr(stmt.dx)) or 0
            local dy = tonumber(self:evalExpr(stmt.dy)) or 0
            self.ctx.camera2d:move(dx, dy)
        end

    elseif stmt.type == "set_camera2d_pos" then
        if self.ctx.camera2d then
            local x = tonumber(self:evalExpr(stmt.x))
            local y = tonumber(self:evalExpr(stmt.y))
            self.ctx.camera2d:setPosition(x, y)
        end

    elseif stmt.type == "zoom_camera2d" then
        if self.ctx.camera2d then
            local amount = tonumber(self:evalExpr(stmt.amount)) or 0.1
            if amount > 0 then
                self.ctx.camera2d:zoomIn(amount)
            else
                self.ctx.camera2d:zoomOut(-amount)
            end
        end

    elseif stmt.type == "ui_button" then
        self:execUIButton(stmt)
    elseif stmt.type == "ui_checkbox" then
        self:execUICheckbox(stmt)
    elseif stmt.type == "ui_slider" then
        self:execUISlider(stmt)
    elseif stmt.type == "ui_label" then
        self:execUILabel(stmt)
    elseif stmt.type == "ui_clear" then
        if self.ctx.ui then self.ctx.ui:clear() end

    elseif stmt.type == "physics_update" then
        if self.ctx.physics then self.ctx.physics:update(self.ctx.dt or 0) end

    elseif stmt.type == "physics3d_update" then
        if self.ctx.physics3d then self.ctx.physics3d:update(self.ctx.dt or 0) end

    elseif stmt.type == "set_gravity" then
        local gx = tonumber(self:evalExpr(stmt.gx)) or 0
        local gy = tonumber(self:evalExpr(stmt.gy)) or 0
        local gz = stmt.gz and tonumber(self:evalExpr(stmt.gz))
        if gz and self.ctx.physics3d then
            self.ctx.physics3d.gravity.x = gx
            self.ctx.physics3d.gravity.y = gy
            self.ctx.physics3d.gravity.z = gz
        elseif self.ctx.physics then
            self.ctx.physics.gravity.x = gx
            self.ctx.physics.gravity.y = gy
        end

    elseif stmt.type == "add_body" then
        self:execAddBody(stmt)
    elseif stmt.type == "add_body3d" then
        self:execAddBody3D(stmt)

    elseif stmt.type == "set_body_vel" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local vx = tonumber(self:evalExpr(stmt.vx)) or 0
            local vy = tonumber(self:evalExpr(stmt.vy)) or 0
            self.ctx.physics:setVelocity(id, vx, vy)
        end
    elseif stmt.type == "set_body3d_vel" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local vx = tonumber(self:evalExpr(stmt.vx)) or 0
            local vy = tonumber(self:evalExpr(stmt.vy)) or 0
            local vz = tonumber(self:evalExpr(stmt.vz)) or 0
            self.ctx.physics3d:setVelocity(id, vx, vy, vz)
        end

    elseif stmt.type == "get_body_vel" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local vx, vy = self.ctx.physics:getVelocity(id)
            self.vars[stmt.vars[1]] = vx
            self.vars[stmt.vars[2]] = vy
        end
    elseif stmt.type == "get_body3d_vel" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local vx, vy, vz = self.ctx.physics3d:getVelocity(id)
            self.vars[stmt.vars[1]] = vx
            self.vars[stmt.vars[2]] = vy
            self.vars[stmt.vars[3]] = vz
        end

    elseif stmt.type == "body_apply_force" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local fx = tonumber(self:evalExpr(stmt.fx)) or 0
            local fy = tonumber(self:evalExpr(stmt.fy)) or 0
            self.ctx.physics:applyForce(id, fx, fy)
        end
    elseif stmt.type == "body3d_apply_force" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local fx = tonumber(self:evalExpr(stmt.fx)) or 0
            local fy = tonumber(self:evalExpr(stmt.fy)) or 0
            local fz = tonumber(self:evalExpr(stmt.fz)) or 0
            self.ctx.physics3d:applyForce(id, fx, fy, fz)
        end

    elseif stmt.type == "body_apply_impulse" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local ix = tonumber(self:evalExpr(stmt.ix)) or 0
            local iy = tonumber(self:evalExpr(stmt.iy)) or 0
            self.ctx.physics:applyImpulse(id, ix, iy)
        end
    elseif stmt.type == "body3d_apply_impulse" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local ix = tonumber(self:evalExpr(stmt.ix)) or 0
            local iy = tonumber(self:evalExpr(stmt.iy)) or 0
            local iz = tonumber(self:evalExpr(stmt.iz)) or 0
            self.ctx.physics3d:applyImpulse(id, ix, iy, iz)
        end

    elseif stmt.type == "set_body_pos" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local x = tonumber(self:evalExpr(stmt.x))
            local y = tonumber(self:evalExpr(stmt.y))
            self.ctx.physics:setPosition(id, x, y)
        end
    elseif stmt.type == "set_body3d_pos" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local x = tonumber(self:evalExpr(stmt.x))
            local y = tonumber(self:evalExpr(stmt.y))
            local z = tonumber(self:evalExpr(stmt.z))
            self.ctx.physics3d:setPosition(id, x, y, z)
        end

    elseif stmt.type == "get_body_pos" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            local x, y = self.ctx.physics:getPosition(id)
            self.vars[stmt.vars[1]] = x
            self.vars[stmt.vars[2]] = y
        end
    elseif stmt.type == "get_body3d_pos" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            local x, y, z = self.ctx.physics3d:getPosition(id)
            self.vars[stmt.vars[1]] = x
            self.vars[stmt.vars[2]] = y
            self.vars[stmt.vars[3]] = z
        end

    elseif stmt.type == "remove_body" then
        if self.ctx.physics then
            local id = tostring(self:evalExpr(stmt.id))
            self.ctx.physics:removeBody(id)
        end
    elseif stmt.type == "remove_body3d" then
        if self.ctx.physics3d then
            local id = tostring(self:evalExpr(stmt.id))
            self.ctx.physics3d:removeBody(id)
        end

    elseif stmt.type == "set_physics_gravity" then
        local FlagPhysics = require("mioengine.core.flag_physics")
        if not self.ctx.flagPhysics then
            self.ctx.flagPhysics = FlagPhysics.new({})
        end
        self.ctx.flagPhysics.gravity = tonumber(self:evalExpr(stmt.gravity)) or 980

    elseif stmt.type == "set_physics_ground" then
        local FlagPhysics = require("mioengine.core.flag_physics")
        if not self.ctx.flagPhysics then
            self.ctx.flagPhysics = FlagPhysics.new({})
        end
        self.ctx.flagPhysics.groundY = tonumber(self:evalExpr(stmt.groundY))

    elseif stmt.type == "set_physics" then
        self:execSetPhysics(stmt)

    elseif stmt.type == "obj_impulse" then
        if self.ctx.flagPhysics then
            local objName = stmt.objName
            local obj = self.vars[objName]
            if obj and obj._physicsId then
                local ix = tonumber(self:evalExpr(stmt.ix)) or 0
                local iy = tonumber(self:evalExpr(stmt.iy)) or 0
                self.ctx.flagPhysics:applyImpulse(obj._physicsId, ix, iy)
            end
        end

    elseif stmt.type == "obj_set_vel" then
        if self.ctx.flagPhysics then
            local objName = stmt.objName
            local obj = self.vars[objName]
            if obj and obj._physicsId then
                local vx = tonumber(self:evalExpr(stmt.vx)) or 0
                local vy = tonumber(self:evalExpr(stmt.vy)) or 0
                self.ctx.flagPhysics:setVelocity(obj._physicsId, vx, vy)
            end
        end

    elseif stmt.type == "obj_set_pos" then
        if self.ctx.flagPhysics then
            local objName = stmt.objName
            local obj = self.vars[objName]
            if obj and obj._physicsId then
                local x = tonumber(self:evalExpr(stmt.x))
                local y = tonumber(self:evalExpr(stmt.y))
                self.ctx.flagPhysics:setPosition(obj._physicsId, x, y)
            end
        end

    elseif stmt.type == "create_anim" then
        self:execCreateAnim(stmt)
    elseif stmt.type == "create_animated_sprite" then
        self:execCreateAnimatedSprite(stmt)
    elseif stmt.type == "anim_add" then
        self:execAnimAdd(stmt)
    elseif stmt.type == "anim_play" then
        self:execAnimPlay(stmt)
    elseif stmt.type == "anim_stop" then
        self:execAnimStop(stmt)
    elseif stmt.type == "anim_pause" then
        self:execAnimPause(stmt)
    elseif stmt.type == "anim_resume" then
        self:execAnimResume(stmt)
    elseif stmt.type == "anim_set_speed" then
        self:execAnimSetSpeed(stmt)
    elseif stmt.type == "anim_set_frame" then
        self:execAnimSetFrame(stmt)
    elseif stmt.type == "draw_animated_sprite" then
        self:execDrawAnimatedSprite(stmt)

    elseif stmt.type == "create_particles" then
        self:execCreateParticles(stmt)
    elseif stmt.type == "particles_set_pos" then
        self:execParticlesSetPos(stmt)
    elseif stmt.type == "particles_emit" then
        self:execParticlesEmit(stmt)
    elseif stmt.type == "particles_burst" then
        self:execParticlesBurst(stmt)
    elseif stmt.type == "particles_start" then
        self:execParticlesStart(stmt)
    elseif stmt.type == "particles_stop" then
        self:execParticlesStop(stmt)
    elseif stmt.type == "particles_clear" then
        self:execParticlesClear(stmt)
    elseif stmt.type == "particles_configure" then
        self:execParticlesConfigure(stmt)
    elseif stmt.type == "draw_particles" then
        self:execDrawParticles(stmt)

    elseif stmt.type == "set_physics3d_gravity" then
        self:execSetPhysics3DGravity(stmt)
    elseif stmt.type == "set_physics3d_floor" then
        self:execSetPhysics3DFloor(stmt)
    elseif stmt.type == "set_physics3d" then
        self:execSetPhysics3D(stmt)
    elseif stmt.type == "obj3d_impulse" then
        self:execObj3DImpulse(stmt)
    elseif stmt.type == "obj3d_set_vel" then
        self:execObj3DSetVel(stmt)
    elseif stmt.type == "obj3d_get_vel" then
        self:execObj3DGetVel(stmt)
    elseif stmt.type == "obj3d_set_pos" then
        self:execObj3DSetPos(stmt)

    elseif stmt.type == "create_particles3d" then
        self:execCreateParticles3D(stmt)
    elseif stmt.type == "particles3d_set_pos" then
        self:execParticles3DSetPos(stmt)
    elseif stmt.type == "particles3d_emit" then
        self:execParticles3DEmit(stmt)
    elseif stmt.type == "particles3d_burst" then
        self:execParticles3DBurst(stmt)
    elseif stmt.type == "particles3d_start" then
        self:execParticles3DStart(stmt)
    elseif stmt.type == "particles3d_stop" then
        self:execParticles3DStop(stmt)
    elseif stmt.type == "particles3d_clear" then
        self:execParticles3DClear(stmt)
    elseif stmt.type == "particles3d_configure" then
        self:execParticles3DConfigure(stmt)
    elseif stmt.type == "draw_particles3d" then
        self:execDrawParticles3D(stmt)

    elseif stmt.type == "watch_file" then
        self:execWatchFile(stmt)
    elseif stmt.type == "unwatch_file" then
        self:execUnwatchFile(stmt)

    elseif stmt.type == "bind_key" then
        self:execBindKey(stmt)
    elseif stmt.type == "unbind_key" then
        self:execUnbindKey(stmt)
    elseif stmt.type == "load_default_bindings" then
        if self.ctx.inputMapper then self.ctx.inputMapper:loadDefaults() end

    elseif stmt.type == "toggle_console" then
        if self.ctx.debugConsole then self.ctx.debugConsole:toggle() end
    elseif stmt.type == "console_log" then
        local msg = self:evalExpr(stmt.msg)
        if self.ctx.debugConsole then self.ctx.debugConsole:log(tostring(msg)) end
    elseif stmt.type == "profiler_start" then
        local name = tostring(self:evalExpr(stmt.name))
        if self.ctx.debugConsole then self.ctx.debugConsole:profilerStart(name) end
    elseif stmt.type == "profiler_end" then
        local name = tostring(self:evalExpr(stmt.name))
        if self.ctx.debugConsole then self.ctx.debugConsole:profilerEnd(name) end
    elseif stmt.type == "profiler_reset" then
        if self.ctx.debugConsole then self.ctx.debugConsole:profilerReset() end

    elseif stmt.type == "create_panel" then
        self:execCreatePanel(stmt)
    elseif stmt.type == "panel_add_button" then
        self:execPanelAddButton(stmt)
    elseif stmt.type == "panel_add_label" then
        self:execPanelAddLabel(stmt)
    elseif stmt.type == "panel_add_separator" then
        self:execPanelAddSeparator(stmt)
    elseif stmt.type == "draw_panel" then
        self:execDrawPanel(stmt)
    elseif stmt.type == "panel_set_visible" then
        self:execPanelSetVisible(stmt)
    elseif stmt.type == "panel_set_position" then
        self:execPanelSetPosition(stmt)

    elseif stmt.type == "import" then
        self:doImport(stmt)

    elseif stmt.type == "expr" then
        self:evalExpr(stmt.expr)

    elseif stmt.type == "expr_assign" then
        local target = stmt.target
        local val = self:evalExpr(stmt.expr)
        if target.type == "property" then
            local obj = self.vars[target.object]
            if type(obj) == "table" then obj[target.prop] = val end
        elseif target.type == "index" then
            local arr = self.vars[target.array]
            local idx = self:evalExpr(target.index)
            if type(idx) == "number" then idx = math.floor(idx) end
            if type(arr) == "table" then arr[idx] = val end
        end
    end
end

function MioLang:execBlock(stmts)
    for _, s in ipairs(stmts) do
        self:exec(s)
        if self._break then break end
    end
end

function MioLang:execCreateModel(stmt)
    local Objects = require("mioengine.core.objects")
    local modelPath = self:evalExpr(stmt.model)
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = stmt.z and (tonumber(self:evalExpr(stmt.z)) or 0) or 0
    local opts = {}
    if stmt.opts then
        if stmt.opts.rotSpeedX then opts.rotSpeedX = tonumber(self:evalExpr(stmt.opts.rotSpeedX)) end
        if stmt.opts.rotSpeedY then opts.rotSpeedY = tonumber(self:evalExpr(stmt.opts.rotSpeedY)) end
        if stmt.opts.scale then opts.scale = tonumber(self:evalExpr(stmt.opts.scale)) end
        if stmt.opts.size then opts.size = tonumber(self:evalExpr(stmt.opts.size)) end
    end
    local obj = Objects.create({
        model = modelPath,
        x = x, y = y, z = z,
        rotSpeedX = opts.rotSpeedX or 0,
        rotSpeedY = opts.rotSpeedY or 0,
        scale = opts.scale or 1,
        size = opts.size,
    })
    self.ctx.objects = self.ctx.objects or {}
    self.ctx.objects[#self.ctx.objects+1] = obj
    self.vars[stmt.name] = obj
end

function MioLang:execAddObject(stmt)
    local Objects = require("mioengine.core.objects")
    local modelPath = self:evalExpr(stmt.model)
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = stmt.z and (tonumber(self:evalExpr(stmt.z)) or 0) or 0
    local opts = {}
    if stmt.opts then
        if stmt.opts.rotSpeedX then opts.rotSpeedX = tonumber(self:evalExpr(stmt.opts.rotSpeedX)) end
        if stmt.opts.rotSpeedY then opts.rotSpeedY = tonumber(self:evalExpr(stmt.opts.rotSpeedY)) end
        if stmt.opts.scale then opts.scale = tonumber(self:evalExpr(stmt.opts.scale)) end
        if stmt.opts.size then opts.size = tonumber(self:evalExpr(stmt.opts.size)) end
        if stmt.opts.drawOrder then opts.drawOrder = tonumber(self:evalExpr(stmt.opts.drawOrder)) end
    end
    local obj = Objects.create({
        model = modelPath,
        x = x, y = y, z = z,
        scale = opts.scale or 1,
        size = opts.size,
        drawOrder = opts.drawOrder,
    })
    if opts.rotSpeedX then obj.angleX = opts.rotSpeedX end
    if opts.rotSpeedY then obj.angleY = opts.rotSpeedY end
    self.ctx.objects = self.ctx.objects or {}
    self.ctx.objects[#self.ctx.objects+1] = obj
    self.vars[stmt.name] = obj
end

function MioLang:execAddCollider(stmt)
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = tonumber(self:evalExpr(stmt.z)) or 0
    local halfW = stmt.halfW and tonumber(self:evalExpr(stmt.halfW)) or 0.5
    local halfH = stmt.halfH and tonumber(self:evalExpr(stmt.halfH)) or halfW
    local halfD = stmt.halfD and tonumber(self:evalExpr(stmt.halfD)) or halfW
    self.ctx.colliders = self.ctx.colliders or {}
    self.ctx.colliders[#self.ctx.colliders+1] = {
        x = x, y = y, z = z,
        halfSizeX = halfW,
        halfSizeY = halfH,
        halfSizeZ = halfD,
    }
end

function MioLang:execCheckHit(stmt)
    local wx = tonumber(self:evalExpr(stmt.x)) or 0
    local wy = tonumber(self:evalExpr(stmt.y)) or 0
    local wz = tonumber(self:evalExpr(stmt.z)) or 0
    local camera = self.ctx.camera
    local renderer = self.ctx.renderer
    if camera and renderer then
        local rx, ry, rz = camera:transformPoint(wx, wy, wz)
        print("[check_hit] world=" .. wx .. "," .. wy .. "," .. wz .. " cam=" .. string.format("%.2f,%.2f,%.2f", rx, ry, rz))
        if rz > 0.1 then
            local sx = (rx * renderer.fov) / rz + renderer.width / 2
            local sy = (-ry * renderer.fov) / rz + renderer.height / 2
            local dx = sx - renderer.width / 2
            local dy = sy - renderer.height / 2
            local d = math.sqrt(dx * dx + dy * dy)
            print("[check_hit] screen=" .. string.format("%.1f,%.1f", sx, sy) .. " dist=" .. string.format("%.1f", d))
            self.vars["_hitResult"] = d < 30 and 1 or 0
        else
            self.vars["_hitResult"] = 0
        end
    else
        self.vars["_hitResult"] = 0
    end
end

function MioLang:execAddBody(stmt)
    local Physics2D = require("mioengine.core.physics2d")
    if not self.ctx.physics then
        self.ctx.physics = Physics2D.new({ groundY = 600 })
    end
    local id = tostring(self:evalExpr(stmt.id))
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local opts = stmt.opts or {}
    local config = {
        id = id,
        x = x, y = y,
        shape = opts.shape and tostring(self:evalExpr(opts.shape)) or "rect",
        w = opts.w and tonumber(self:evalExpr(opts.w)) or 32,
        h = opts.h and tonumber(self:evalExpr(opts.h)) or 32,
        radius = opts.radius and tonumber(self:evalExpr(opts.radius)) or 16,
        mass = opts.mass and tonumber(self:evalExpr(opts.mass)) or 1,
        bounce = opts.bounce and tonumber(self:evalExpr(opts.bounce)) or 0.3,
        friction = opts.friction and tonumber(self:evalExpr(opts.friction)) or 0.5,
        static = opts.static or false,
        tag = opts.tag and tostring(self:evalExpr(opts.tag)) or "",
        vx = opts.vx and tonumber(self:evalExpr(opts.vx)) or 0,
        vy = opts.vy and tonumber(self:evalExpr(opts.vy)) or 0,
    }
    self.ctx.physics:addBody(config)
end

function MioLang:execAddBody3D(stmt)
    local Physics3D = require("mioengine.core.physics3d")
    if not self.ctx.physics3d then
        self.ctx.physics3d = Physics3D.new({ groundY = 0 })
    end
    local id = tostring(self:evalExpr(stmt.id))
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = tonumber(self:evalExpr(stmt.z)) or 0
    local opts = stmt.opts or {}
    local config = {
        id = id,
        x = x, y = y, z = z,
        shape = opts.shape and tostring(self:evalExpr(opts.shape)) or "sphere",
        radius = opts.radius and tonumber(self:evalExpr(opts.radius)) or 0.5,
        w = opts.w and tonumber(self:evalExpr(opts.w)) or 1,
        h = opts.h and tonumber(self:evalExpr(opts.h)) or 1,
        d = opts.d and tonumber(self:evalExpr(opts.d)) or 1,
        mass = opts.mass and tonumber(self:evalExpr(opts.mass)) or 1,
        bounce = opts.bounce and tonumber(self:evalExpr(opts.bounce)) or 0.3,
        friction = opts.friction and tonumber(self:evalExpr(opts.friction)) or 0.5,
        static = opts.static or false,
        tag = opts.tag and tostring(self:evalExpr(opts.tag)) or "",
    }
    self.ctx.physics3d:addBody(config)
end

function MioLang:execSetPhysics(stmt)
    local FlagPhysics = require("mioengine.core.flag_physics")
    if not self.ctx.flagPhysics then
        self.ctx.flagPhysics = FlagPhysics.new({ groundY = 600 })
    end
    local objName = stmt.objName
    local obj = self.vars[objName]
    if not obj then
        self:log("set_physics: object '" .. objName .. "' not found")
        return
    end
    local mode = tostring(self:evalExpr(stmt.mode))
    local opts = stmt.opts or {}
    local config = {
        w = opts.w and tonumber(self:evalExpr(opts.w)) or 32,
        h = opts.h and tonumber(self:evalExpr(opts.h)) or 32,
        radius = opts.radius and tonumber(self:evalExpr(opts.radius)) or 16,
        shape = opts.shape and tostring(self:evalExpr(opts.shape)) or "rect",
        mass = opts.mass and tonumber(self:evalExpr(opts.mass)) or 1,
        bounce = opts.bounce and tonumber(self:evalExpr(opts.bounce)) or 0.3,
        friction = opts.friction and tonumber(self:evalExpr(opts.friction)) or 0.5,
        tag = opts.tag and tostring(self:evalExpr(opts.tag)) or "",
        static = (mode == "static"),
        dynamic = (mode == "dynamic"),
        trigger = (mode == "trigger"),
    }
    local body = self.ctx.flagPhysics:addBody(objName, obj, config)
    obj._physicsId = objName
end

function MioLang:execMove(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    local dx = tonumber(self:evalExpr(stmt.dx)) or 0
    local dy = tonumber(self:evalExpr(stmt.dy)) or 0
    local dz = stmt.dz and (tonumber(self:evalExpr(stmt.dz)) or 0) or 0
    obj.x = obj.x + dx
    obj.y = obj.y + dy
    obj.z = obj.z + dz
    if obj.markDirty then obj:markDirty() end
end

function MioLang:execMoveTowards(stmt)
    local obj = self.vars[stmt.obj]
    local target = self.vars[stmt.target]
    if not obj or not target then return end
    local speed = tonumber(self:evalExpr(stmt.speed)) or 1
    local dt = self.ctx.dt or 0.016
    local dx = target.x - obj.x
    local dy = target.y - obj.y
    local dz = target.z - obj.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist < 0.01 then return end
    local nx = dx / dist
    local ny = dy / dist
    local nz = dz / dist
    obj.x = obj.x + nx * speed * dt
    obj.y = obj.y + ny * speed * dt
    obj.z = obj.z + nz * speed * dt
    if obj.markDirty then obj:markDirty() end
end

function MioLang:execSetPos(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    if stmt.x then obj.x = tonumber(self:evalExpr(stmt.x)) or obj.x end
    if stmt.y then obj.y = tonumber(self:evalExpr(stmt.y)) or obj.y end
    if stmt.z then obj.z = tonumber(self:evalExpr(stmt.z)) or obj.z end
    if obj.markDirty then obj:markDirty() end
end

function MioLang:execGetPos(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then
        self.vars[stmt.vars[1]] = 0
        self.vars[stmt.vars[2]] = 0
        if stmt.vars[3] then self.vars[stmt.vars[3]] = 0 end
        return
    end
    self.vars[stmt.vars[1]] = obj.x or 0
    self.vars[stmt.vars[2]] = obj.y or 0
    if stmt.vars[3] then self.vars[stmt.vars[3]] = obj.z or 0 end
end

function MioLang:execSetRot(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    local val = tonumber(self:evalExpr(stmt.value)) or 0
    if stmt.axis == "x" then obj.rotSpeedX = val
    elseif stmt.axis == "y" then obj.rotSpeedY = val
    elseif stmt.axis == "angle_x" then obj.angleX = val
    elseif stmt.axis == "angle_y" then obj.angleY = val
    end
    if obj.markDirty then obj:markDirty() end
end

function MioLang:execDestroy(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    local objs = self.ctx.objects or {}
    for i = #objs, 1, -1 do
        if objs[i] == obj then
            table.remove(objs, i)
            break
        end
    end
    self.vars[stmt.obj] = nil
end

function MioLang:execPlaySound(stmt)
    local Sound = require("mioengine.core.sound")
    local path = self:evalExpr(stmt.path)
    Sound.load(stmt.name, path, self.ctx.resources)
    Sound.play(stmt.name, stmt.loop)
end

function MioLang:execDrawRect(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    love.graphics.setColor(args[5] or 1, args[6] or 1, args[7] or 1, args[8] or 1)
    love.graphics.rectangle("fill", args[1] or 0, args[2] or 0, args[3] or 0, args[4] or 0)
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawText(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    local text = tostring(args[1] or "")
    local x = tonumber(args[2]) or 0
    local y = tonumber(args[3]) or 0
    local size = tonumber(args[4]) or 12
    local res = self.ctx.resources
    local font = res and res:getFont(size) or love.graphics.newFont(size)
    love.graphics.setFont(font)
    love.graphics.setColor(tonumber(args[5]) or 1, tonumber(args[6]) or 1, tonumber(args[7]) or 1, tonumber(args[8]) or 1)
    local align = args[9] or "left"
    if align == "center" then
        local w = font:getWidth(text)
        love.graphics.print(text, x - w / 2, y)
    elseif align == "right" then
        local w = font:getWidth(text)
        love.graphics.print(text, x - w, y)
    else
        love.graphics.print(text, x, y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawCircle(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    love.graphics.setColor(args[4] or 1, args[5] or 1, args[6] or 1, args[7] or 1)
    love.graphics.circle("fill", args[1] or 0, args[2] or 0, args[3] or 10)
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawLine(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    love.graphics.setColor(args[5] or 1, args[6] or 1, args[7] or 1, args[8] or 1)
    love.graphics.setLineWidth(args[9] or 1)
    love.graphics.line(args[1] or 0, args[2] or 0, args[3] or 0, args[4] or 0)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawImage(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    local path = tostring(args[1] or "")
    local x = tonumber(args[2]) or 0
    local y = tonumber(args[3]) or 0
    local r = tonumber(args[4]) or 0
    local g = tonumber(args[5]) or 1
    local b = tonumber(args[6]) or 1
    local a = tonumber(args[7]) or 1
    local sx = tonumber(args[8]) or 1
    local sy = tonumber(args[9]) or sx

    local res = self.ctx.resources
    local img
    if res then
        img = res:getImage(path)
    else
        if not self.imageCache[path] then
            local ok, image = pcall(function() return love.graphics.newImage(path) end)
            if ok and image then
                self.imageCache[path] = image
            else
                self:log("draw_image: cannot load " .. path)
                return
            end
        end
        img = self.imageCache[path]
    end

    if not img then return end
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(img, x, y, 0, sx, sy)
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawSprite(stmt)
    local path = tostring(self:evalExpr(stmt.path) or "")
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local r = stmt.r and tonumber(self:evalExpr(stmt.r)) or 1
    local g = stmt.g and tonumber(self:evalExpr(stmt.g)) or 1
    local b = stmt.b and tonumber(self:evalExpr(stmt.b)) or 1
    local a = stmt.a and tonumber(self:evalExpr(stmt.a)) or 1
    local sx = stmt.sx and tonumber(self:evalExpr(stmt.sx)) or 1
    local sy = stmt.sy and tonumber(self:evalExpr(stmt.sy)) or sx
    local ox = stmt.ox and tonumber(self:evalExpr(stmt.ox)) or 0
    local oy = stmt.oy and tonumber(self:evalExpr(stmt.oy)) or 0

    local res = self.ctx.resources
    local img
    if res then
        img = res:getImage(path)
    else
        if not self.imageCache[path] then
            local ok, image = pcall(function() return love.graphics.newImage(path) end)
            if ok and image then
                self.imageCache[path] = image
            else
                self:log("draw_sprite: cannot load " .. path)
                return
            end
        end
        img = self.imageCache[path]
    end

    if not img then return end
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(img, x, y, 0, sx, sy, ox, oy)
    love.graphics.setColor(1, 1, 1, 1)
end

function MioLang:execDrawModel(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    local path = tostring(args[1] or "")
    local x = tonumber(args[2]) or 0
    local y = tonumber(args[3]) or 0
    local scale = tonumber(args[4]) or 1
    local rotX = tonumber(args[5]) or 0
    local rotY = tonumber(args[6]) or 0

    if self.ctx.renderer then
        self.ctx.renderer:drawModelHUD(path, x, y, scale, rotX, rotY)
    end
end

function MioLang:execGetCanvasSize(stmt)
    local w, h
    if self.ctx.renderer then
        w = self.ctx.renderer:getCanvasW()
        h = self.ctx.renderer:getCanvasH()
    else
        w = love.graphics.getWidth()
        h = love.graphics.getHeight()
    end
    self.vars[stmt.vars[1]] = w
    self.vars[stmt.vars[2]] = h
end

function MioLang:execSetScale(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    local s = tonumber(self:evalExpr(stmt.value)) or 1
    local factor = s / (obj.scale or 1)
    obj.scale = s
    if obj.vertices then
        for _, v in ipairs(obj.vertices) do
            v[1] = v[1] * factor
            v[2] = v[2] * factor
            v[3] = v[3] * factor
        end
    end
end


function MioLang:execCreateAnim(stmt)
    local animMod = require("mioengine.core.animation")
    local frames = {}
    for i, f in ipairs(stmt.frames) do
        frames[i] = tonumber(self:evalExpr(f)) or i - 1
    end
    local opts = {}
    if stmt.opts then
        if stmt.opts.frameWidth then opts.frameWidth = tonumber(self:evalExpr(stmt.opts.frameWidth)) end
        if stmt.opts.frameHeight then opts.frameHeight = tonumber(self:evalExpr(stmt.opts.frameHeight)) end
        if stmt.opts.fps then opts.fps = tonumber(self:evalExpr(stmt.opts.fps)) end
        if stmt.opts.loop then opts.loop = self:evalExpr(stmt.opts.loop) end
    end
    opts.frames = frames
    local anim = animMod.Animation.new(opts)
    self.vars[stmt.name] = anim
end

function MioLang:execCreateAnimatedSprite(stmt)
    local animMod = require("mioengine.core.animation")
    local imagePath = tostring(self:evalExpr(stmt.imagePath))
    local res = self.ctx.resources
    local img
    if res then
        img = res:getImage(imagePath)
    else
        local ok, image = pcall(love.graphics.newImage, imagePath)
        if ok then img = image end
    end
    local opts = {}
    if stmt.opts then
        if stmt.opts.x then opts.x = tonumber(self:evalExpr(stmt.opts.x)) end
        if stmt.opts.y then opts.y = tonumber(self:evalExpr(stmt.opts.y)) end
        if stmt.opts.scaleX then opts.scaleX = tonumber(self:evalExpr(stmt.opts.scaleX)) end
        if stmt.opts.scaleY then opts.scaleY = tonumber(self:evalExpr(stmt.opts.scaleY)) end
    end
    local sprite = animMod.AnimatedSprite.new(img, opts)
    self.vars[stmt.name] = sprite
end

function MioLang:execAnimAdd(stmt)
    local sprite = self.vars[stmt.spriteName]
    if not sprite or not sprite.addAnimation then self:log("anim_add: sprite '" .. stmt.spriteName .. "' not found"); return end
    local frames = {}
    for i, f in ipairs(stmt.frames) do
        frames[i] = tonumber(self:evalExpr(f)) or i - 1
    end
    local animName = tostring(self:evalExpr(stmt.animName))
    local opts = { frames = frames }
    if stmt.opts then
        if stmt.opts.fps then opts.fps = tonumber(self:evalExpr(stmt.opts.fps)) end
        if stmt.opts.loop then opts.loop = self:evalExpr(stmt.opts.loop) end
        if stmt.opts.frameWidth then opts.frameWidth = tonumber(self:evalExpr(stmt.opts.frameWidth)) end
        if stmt.opts.frameHeight then opts.frameHeight = tonumber(self:evalExpr(stmt.opts.frameHeight)) end
    end
    sprite:addAnimation(animName, opts)
end

function MioLang:execAnimPlay(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then self:log("anim_play: '" .. stmt.objName .. "' not found"); return end
    local animName = stmt.animName and tostring(self:evalExpr(stmt.animName)) or nil
    if sprite.play then sprite:play(animName)
    elseif sprite.animations and animName then
        sprite.currentAnim = animName
        local anim = sprite.animations[animName]
        if anim then anim:play() end
    end
end

function MioLang:execAnimStop(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.stop then sprite:stop()
    elseif sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim then anim:stop() end
    end
end

function MioLang:execAnimPause(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.pause then sprite:pause() end
end

function MioLang:execAnimResume(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.resume then sprite:resume() end
end

function MioLang:execAnimSetSpeed(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    local fps = tonumber(self:evalExpr(stmt.fps)) or 8
    if sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim and anim.setSpeed then anim:setSpeed(fps) end
    end
end

function MioLang:execAnimSetFrame(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    local frame = tonumber(self:evalExpr(stmt.frame)) or 1
    if sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim and anim.setFrame then anim:setFrame(frame) end
    end
end

function MioLang:execDrawAnimatedSprite(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.update then sprite:update(self.ctx.dt or 0) end
    if sprite.draw then sprite:draw() end
end


function MioLang:execCreateParticles(stmt)
    local Particles = require("mioengine.core.particles")
    local opts = {}
    if stmt.opts then
        local o = stmt.opts
        if o.x then opts.x = tonumber(self:evalExpr(o.x)) end
        if o.y then opts.y = tonumber(self:evalExpr(o.y)) end
        if o.gravity then opts.gravity = tonumber(self:evalExpr(o.gravity)) end
        if o.maxParticles then opts.maxParticles = tonumber(self:evalExpr(o.maxParticles)) end
        if o.minVx then opts.minVx = tonumber(self:evalExpr(o.minVx)) end
        if o.maxVx then opts.maxVx = tonumber(self:evalExpr(o.maxVx)) end
        if o.minVy then opts.minVy = tonumber(self:evalExpr(o.minVy)) end
        if o.maxVy then opts.maxVy = tonumber(self:evalExpr(o.maxVy)) end
        if o.minLife then opts.minLife = tonumber(self:evalExpr(o.minLife)) end
        if o.maxLife then opts.maxLife = tonumber(self:evalExpr(o.maxLife)) end
        if o.minSize then opts.minSize = tonumber(self:evalExpr(o.minSize)) end
        if o.maxSize then opts.maxSize = tonumber(self:evalExpr(o.maxSize)) end
        if o.endSize then opts.endSize = tonumber(self:evalExpr(o.endSize)) end
        if o.spreadX then opts.spreadX = tonumber(self:evalExpr(o.spreadX)) end
        if o.spreadY then opts.spreadY = tonumber(self:evalExpr(o.spreadY)) end
        if o.emitRate then opts.emitRate = tonumber(self:evalExpr(o.emitRate)) end
        if o.burstMode then opts.burstMode = self:evalExpr(o.burstMode) end
        if o.shape then opts.shape = tostring(self:evalExpr(o.shape)) end
        if o.r or o.g or o.b or o.a then
            opts.startColor = {
                tonumber(self:evalExpr(o.r)) or 1,
                tonumber(self:evalExpr(o.g)) or 1,
                tonumber(self:evalExpr(o.b)) or 1,
                tonumber(self:evalExpr(o.a)) or 1,
            }
        end
        if o.er or o.eg or o.eb or o.ea then
            opts.endColor = {
                tonumber(self:evalExpr(o.er)) or 1,
                tonumber(self:evalExpr(o.eg)) or 1,
                tonumber(self:evalExpr(o.eb)) or 1,
                tonumber(self:evalExpr(o.ea)) or 0,
            }
        end
    end
    local ps = Particles.new(opts)
    self.vars[stmt.name] = ps
end

function MioLang:execParticlesSetPos(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.setPosition then return end
    ps:setPosition(tonumber(self:evalExpr(stmt.x)) or 0, tonumber(self:evalExpr(stmt.y)) or 0)
end

function MioLang:execParticlesEmit(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.emit then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 1
    ps:emit(count)
end

function MioLang:execParticlesBurst(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.burst then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 10
    ps:burst(count)
end

function MioLang:execParticlesStart(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.start then ps:start() end
end

function MioLang:execParticlesStop(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.stop then ps:stop() end
end

function MioLang:execParticlesClear(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.clear then ps:clear() end
end

function MioLang:execParticlesConfigure(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.configure then return end
    local cfg = {}
    local o = stmt.opts
    if o.x then cfg.x = tonumber(self:evalExpr(o.x)) end
    if o.y then cfg.y = tonumber(self:evalExpr(o.y)) end
    if o.gravity then cfg.gravity = tonumber(self:evalExpr(o.gravity)) end
    if o.emitRate then cfg.emitRate = tonumber(self:evalExpr(o.emitRate)) end
    ps:configure(cfg)
end

function MioLang:execDrawParticles(stmt)
    local ps = self.vars[stmt.objName]
    if not ps then return end
    if ps.update then ps:update(self.ctx.dt or 0) end
    if ps.draw then ps:draw() end
end


function MioLang:execSetPhysics3DGravity(stmt)
    local FP3D = require("mioengine.core.flag_physics3d")
    if not self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d = FP3D.new({})
    end
    local gx = tonumber(self:evalExpr(stmt.gx)) or 0
    local gy = stmt.gy and tonumber(self:evalExpr(stmt.gy)) or 980
    local gz = stmt.gz and tonumber(self:evalExpr(stmt.gz)) or 0
    self.ctx.flagPhysics3d.gravity = { x = gx, y = gy, z = gz }
end

function MioLang:execSetPhysics3DFloor(stmt)
    local FP3D = require("mioengine.core.flag_physics3d")
    if not self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d = FP3D.new({})
    end
    self.ctx.flagPhysics3d.groundY = tonumber(self:evalExpr(stmt.floorY))
end

function MioLang:execSetPhysics3D(stmt)
    local FP3D = require("mioengine.core.flag_physics3d")
    if not self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d = FP3D.new({ groundY = 600 })
    end
    local objName = stmt.objName
    local obj = self.vars[objName]
    if not obj then
        self:log("set_physics3d: object '" .. objName .. "' not found")
        return
    end
    local mode = tostring(self:evalExpr(stmt.mode))
    local opts = stmt.opts or {}
    local config = {
        w = opts.w and tonumber(self:evalExpr(opts.w)) or 1,
        h = opts.h and tonumber(self:evalExpr(opts.h)) or 1,
        d = opts.d and tonumber(self:evalExpr(opts.d)) or 1,
        radius = opts.radius and tonumber(self:evalExpr(opts.radius)) or 0.5,
        shape = opts.shape and tostring(self:evalExpr(opts.shape)) or "box",
        mass = opts.mass and tonumber(self:evalExpr(opts.mass)) or 1,
        bounce = opts.bounce and tonumber(self:evalExpr(opts.bounce)) or 0.3,
        friction = opts.friction and tonumber(self:evalExpr(opts.friction)) or 0.5,
        tag = opts.tag and tostring(self:evalExpr(opts.tag)) or "",
        static = (mode == "static"),
        dynamic = (mode == "dynamic"),
        trigger = (mode == "trigger"),
    }
    self.ctx.flagPhysics3d:addBody(objName, obj, config)
    obj._physics3dId = objName
end

function MioLang:execObj3DImpulse(stmt)
    if self.ctx.flagPhysics3d then
        local obj = self.vars[stmt.objName]
        if obj and obj._physics3dId then
            local ix = tonumber(self:evalExpr(stmt.ix)) or 0
            local iy = tonumber(self:evalExpr(stmt.iy)) or 0
            local iz = stmt.iz and tonumber(self:evalExpr(stmt.iz)) or 0
            self.ctx.flagPhysics3d:applyImpulse(obj._physics3dId, ix, iy, iz)
        end
    end
end

function MioLang:execObj3DSetVel(stmt)
    if self.ctx.flagPhysics3d then
        local obj = self.vars[stmt.objName]
        if obj and obj._physics3dId then
            local vx = tonumber(self:evalExpr(stmt.vx)) or 0
            local vy = tonumber(self:evalExpr(stmt.vy)) or 0
            local vz = stmt.vz and tonumber(self:evalExpr(stmt.vz)) or 0
            self.ctx.flagPhysics3d:setVelocity(obj._physics3dId, vx, vy, vz)
        end
    end
end

function MioLang:execObj3DGetVel(stmt)
    if self.ctx.flagPhysics3d then
        local obj = self.vars[stmt.objName]
        if obj and obj._physics3dId then
            local vx, vy, vz = self.ctx.flagPhysics3d:getVelocity(obj._physics3dId)
            self.vars[stmt.vars[1]] = vx
            self.vars[stmt.vars[2]] = vy
            if stmt.vars[3] then self.vars[stmt.vars[3]] = vz end
        end
    end
end

function MioLang:execObj3DSetPos(stmt)
    if self.ctx.flagPhysics3d then
        local obj = self.vars[stmt.objName]
        if obj and obj._physics3dId then
            local x = tonumber(self:evalExpr(stmt.x))
            local y = tonumber(self:evalExpr(stmt.y))
            local z = stmt.z and tonumber(self:evalExpr(stmt.z))
            self.ctx.flagPhysics3d:setPosition(obj._physics3dId, x, y, z)
        end
    end
end


function MioLang:execCreateParticles3D(stmt)
    local Particles3D = require("mioengine.core.particles3d")
    local opts = {}
    if stmt.opts then
        local o = stmt.opts
        if o.x then opts.x = tonumber(self:evalExpr(o.x)) end
        if o.y then opts.y = tonumber(self:evalExpr(o.y)) end
        if o.z then opts.z = tonumber(self:evalExpr(o.z)) end
        if o.gravity then opts.gravity = tonumber(self:evalExpr(o.gravity)) end
        if o.maxParticles then opts.maxParticles = tonumber(self:evalExpr(o.maxParticles)) end
        if o.minVx then opts.minVx = tonumber(self:evalExpr(o.minVx)) end
        if o.maxVx then opts.maxVx = tonumber(self:evalExpr(o.maxVx)) end
        if o.minVy then opts.minVy = tonumber(self:evalExpr(o.minVy)) end
        if o.maxVy then opts.maxVy = tonumber(self:evalExpr(o.maxVy)) end
        if o.minVz then opts.minVz = tonumber(self:evalExpr(o.minVz)) end
        if o.maxVz then opts.maxVz = tonumber(self:evalExpr(o.maxVz)) end
        if o.minLife then opts.minLife = tonumber(self:evalExpr(o.minLife)) end
        if o.maxLife then opts.maxLife = tonumber(self:evalExpr(o.maxLife)) end
        if o.minSize then opts.minSize = tonumber(self:evalExpr(o.minSize)) end
        if o.maxSize then opts.maxSize = tonumber(self:evalExpr(o.maxSize)) end
        if o.endSize then opts.endSize = tonumber(self:evalExpr(o.endSize)) end
        if o.spreadX then opts.spreadX = tonumber(self:evalExpr(o.spreadX)) end
        if o.spreadY then opts.spreadY = tonumber(self:evalExpr(o.spreadY)) end
        if o.spreadZ then opts.spreadZ = tonumber(self:evalExpr(o.spreadZ)) end
        if o.emitRate then opts.emitRate = tonumber(self:evalExpr(o.emitRate)) end
        if o.burstMode then opts.burstMode = self:evalExpr(o.burstMode) end
        if o.r or o.g or o.b or o.a then
            opts.startColor = {
                tonumber(self:evalExpr(o.r)) or 1,
                tonumber(self:evalExpr(o.g)) or 1,
                tonumber(self:evalExpr(o.b)) or 1,
                tonumber(self:evalExpr(o.a)) or 1,
            }
        end
        if o.er or o.eg or o.eb or o.ea then
            opts.endColor = {
                tonumber(self:evalExpr(o.er)) or 1,
                tonumber(self:evalExpr(o.eg)) or 1,
                tonumber(self:evalExpr(o.eb)) or 1,
                tonumber(self:evalExpr(o.ea)) or 0,
            }
        end
    end
    local ps = Particles3D.new(opts)
    self.vars[stmt.name] = ps
end

function MioLang:execParticles3DSetPos(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.setPosition then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = stmt.z and tonumber(self:evalExpr(stmt.z)) or 0
    ps:setPosition(x, y, z)
end

function MioLang:execParticles3DEmit(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.emit then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 1
    ps:emit(count)
end

function MioLang:execParticles3DBurst(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.burst then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 10
    ps:burst(count)
end

function MioLang:execParticles3DStart(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.start then ps:start() end
end

function MioLang:execParticles3DStop(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.stop then ps:stop() end
end

function MioLang:execParticles3DClear(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.clear then ps:clear() end
end

function MioLang:execParticles3DConfigure(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.configure then return end
    local cfg = {}
    local o = stmt.opts
    if o.x then cfg.x = tonumber(self:evalExpr(o.x)) end
    if o.y then cfg.y = tonumber(self:evalExpr(o.y)) end
    if o.z then cfg.z = tonumber(self:evalExpr(o.z)) end
    if o.gravity then cfg.gravity = tonumber(self:evalExpr(o.gravity)) end
    if o.emitRate then cfg.emitRate = tonumber(self:evalExpr(o.emitRate)) end
    ps:configure(cfg)
end

function MioLang:execDrawParticles3D(stmt)
    local ps = self.vars[stmt.objName]
    if not ps then return end
    local list = self.ctx.particles3dList
    if list then
        list[#list + 1] = ps
    end
end


function MioLang:execWatchFile(stmt)
    local path = tostring(self:evalExpr(stmt.path))
    if self.ctx.hotReload then
        self.ctx.hotReload:watch(path, function(changedPath)
            self:log("File changed: " .. changedPath)
        end)
    end
end

function MioLang:execUnwatchFile(stmt)
    local path = tostring(self:evalExpr(stmt.path))
    if self.ctx.hotReload then
        self.ctx.hotReload:unwatch(path)
    end
end


function MioLang:execBindKey(stmt)
    local action = tostring(self:evalExpr(stmt.action))
    local keys = {}
    for _, k in ipairs(stmt.keys) do
        keys[#keys+1] = self:evalExpr(k)
    end
    if self.ctx.inputMapper then
        self.ctx.inputMapper:bind(action, unpack(keys))
    end
end

function MioLang:execUnbindKey(stmt)
    local action = tostring(self:evalExpr(stmt.action))
    if self.ctx.inputMapper then
        self.ctx.inputMapper:unbind(action)
    end
end


function MioLang:execCreatePanel(stmt)
    local GUILayout = require("mioengine.core.gui_layout")
    local opts = {}
    if stmt.opts then
        local o = stmt.opts
        if o.x then opts.x = tonumber(self:evalExpr(o.x)) end
        if o.y then opts.y = tonumber(self:evalExpr(o.y)) end
        if o.w then opts.w = tonumber(self:evalExpr(o.w)) end
        if o.h then opts.h = tonumber(self:evalExpr(o.h)) end
        if o.title then opts.title = tostring(self:evalExpr(o.title)) end
        if o.scrollable then opts.scrollable = self:evalExpr(o.scrollable) end
    end
    local panel = GUILayout.new(opts)
    self.vars[stmt.name] = panel
end

function MioLang:execPanelAddButton(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.addButton then return end
    local label = tostring(self:evalExpr(stmt.label))
    local w = 150
    local h = 30
    local id = nil
    if stmt.opts then
        if stmt.opts.w then w = tonumber(self:evalExpr(stmt.opts.w)) end
        if stmt.opts.h then h = tonumber(self:evalExpr(stmt.opts.h)) end
        if stmt.opts.id then id = tostring(self:evalExpr(stmt.opts.id)) end
    end
    panel:addButton(5, 0, w, h, label, { id = id })
    panel:reflow()
end

function MioLang:execPanelAddLabel(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.addLabel then return end
    local text = tostring(self:evalExpr(stmt.text))
    local size = 14
    if stmt.opts and stmt.opts.size then size = tonumber(self:evalExpr(stmt.opts.size)) end
    panel:addLabel(5, 0, text, { size = size })
    panel:reflow()
end

function MioLang:execPanelAddSeparator(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.addSeparator then return end
    panel:addSeparator()
end

function MioLang:execDrawPanel(stmt)
    local panel = self.vars[stmt.objName]
    if not panel then return end
    if panel.update then panel:update(self.ctx.dt or 0) end
    if panel.draw then panel:draw() end
end

function MioLang:execPanelSetVisible(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.setVisible then return end
    panel:setVisible(self:evalExpr(stmt.visible))
end

function MioLang:execPanelSetPosition(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.setPosition then return end
    panel:setPosition(tonumber(self:evalExpr(stmt.x)) or 0, tonumber(self:evalExpr(stmt.y)) or 0)
end

function MioLang:update(dt)
    if self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d:update(dt)
    end
    if self.ctx.flagPhysics then
        self.ctx.flagPhysics:update(dt)
    end

    for i = #self.timers, 1, -1 do
        local t = self.timers[i]
        t.elapsed = t.elapsed + dt
        if t.elapsed >= t.time then
            t.elapsed = t.elapsed - t.time
            if t.fn then pcall(t.fn) end
            if t.once then table.remove(self.timers, i) end
        end
    end

    for _, body in ipairs(self.onUpdateBodies) do
        self:execBlock(body)
    end
end

function MioLang:draw()
    for _, body in ipairs(self.onDrawBodies) do
        self:execBlock(body)
    end
    if self.ctx.ui then
        self.ctx.ui:draw()
    end
end

function MioLang:onKey(key)
    local handlers = self.onKeyHandlers[key]
    if handlers then
        for _, body in ipairs(handlers) do
            self:execBlock(body)
        end
    end
end

function MioLang:onMouse(x, y, button, action)
    for _, body in ipairs(self.onMouseBodies) do
        self.vars["_mousex"] = x
        self.vars["_mousey"] = y
        self.vars["_mousebutton"] = button
        self.vars["_mouseaction"] = action
        self:execBlock(body)
    end
end

function MioLang:checkCollisions()
    local objs = self.ctx.objects or {}
    for _, pair in ipairs(self.onCollisionPairs) do
        local a = self.vars[pair.obj1]
        local b = self.vars[pair.obj2]
        if a and b then
            local dx = (a.x or 0) - (b.x or 0)
            local dy = (a.y or 0) - (b.y or 0)
            local dz = (a.z or 0) - (b.z or 0)
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            local threshold = 1.0
            if dist < threshold then
                self:execBlock(pair.body)
            end
        end
    end
end

function MioLang:execUIButton(stmt)
    local UIElements = require("mioengine.core.ui_elements")
    if not self.ctx.ui then
        self.ctx.ui = UIElements.new(self.ctx.resources)
    end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local w = tonumber(self:evalExpr(stmt.w)) or 100
    local h = tonumber(self:evalExpr(stmt.h)) or 30
    local label = tostring(self:evalExpr(stmt.label)) or "Button"
    local opts = {}
    if stmt.opts then
        for k, v in pairs(stmt.opts) do
            opts[k] = self:evalExpr(v)
        end
    end
    local b = self.ctx.ui:button(x, y, w, h, label, opts)
    if opts.id then
        self.vars["_btn_" .. opts.id] = b
    end
end

function MioLang:execUICheckbox(stmt)
    local UIElements = require("mioengine.core.ui_elements")
    if not self.ctx.ui then
        self.ctx.ui = UIElements.new(self.ctx.resources)
    end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local size = tonumber(self:evalExpr(stmt.size)) or 20
    local checked = self:evalExpr(stmt.checked)
    local opts = {}
    if stmt.opts then
        for k, v in pairs(stmt.opts) do
            opts[k] = self:evalExpr(v)
        end
    end
    local c = self.ctx.ui:checkbox(x, y, size, checked, opts)
    if opts.id then
        self.vars["_chk_" .. opts.id] = c
        self.vars[opts.id] = c.checked
    end
end

function MioLang:execUISlider(stmt)
    local UIElements = require("mioengine.core.ui_elements")
    if not self.ctx.ui then
        self.ctx.ui = UIElements.new(self.ctx.resources)
    end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local w = tonumber(self:evalExpr(stmt.w)) or 150
    local h = tonumber(self:evalExpr(stmt.h)) or 20
    local value = tonumber(self:evalExpr(stmt.value)) or 0
    local minVal = tonumber(self:evalExpr(stmt.minVal)) or 0
    local maxVal = tonumber(self:evalExpr(stmt.maxVal)) or 100
    local opts = {}
    if stmt.opts then
        for k, v in pairs(stmt.opts) do
            opts[k] = self:evalExpr(v)
        end
    end
    local s = self.ctx.ui:slider(x, y, w, h, value, minVal, maxVal, opts)
    if opts.id then
        self.vars["_sld_" .. opts.id] = s
        self.vars[opts.id] = s.value
    end
end

function MioLang:execUILabel(stmt)
    local UIElements = require("mioengine.core.ui_elements")
    if not self.ctx.ui then
        self.ctx.ui = UIElements.new(self.ctx.resources)
    end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local text = tostring(self:evalExpr(stmt.text)) or ""
    local opts = {}
    if stmt.opts then
        for k, v in pairs(stmt.opts) do
            opts[k] = self:evalExpr(v)
        end
    end
    local l = self.ctx.ui:label(x, y, text, opts)
    if opts.id then
        self.vars["_lbl_" .. opts.id] = l
    end
end

function MioLang:isRunning()
    return self.initialized
end

return MioLang
