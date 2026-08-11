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
        elseif word == "look_at" then return self:parseLookAt()
        elseif word == "get_canvas_size" then return self:parseGetCanvasSize()
        elseif word == "set_scale" then return self:parseParseScale()
        elseif word == "mute" then self:advance(); return { type = "mute" }
        elseif word == "volume" then return self:parseVolume()
        elseif word == "switch_scene" then return self:parseSwitchScene()
        elseif word == "setup_camera" then return self:parseSetupCamera()
        elseif word == "setup_renderer" then return self:parseSetupRenderer()
        elseif word == "load_texture" then return self:parseLoadTexture()
        elseif word == "set_texture" then return self:parseSetTexture()
        elseif word == "load_shader" then return self:parseLoadShader()
        elseif word == "set_shader" then return self:parseSetShader()
        elseif word == "set_shader_uniform" then return self:parseSetShaderUniform()
        elseif word == "reload_shader" then return self:parseReloadShader()
        elseif word == "set_mouse" then return self:parseSetMouse()
        elseif word == "camera_update" then self:advance(); return { type = "camera_update" }
        elseif word == "camera_collide" then self:advance(); return { type = "camera_collide" }
        elseif word == "set_fps_camera" then return self:parseSetFpsCamera()
        elseif word == "set_fly_camera" then self:advance(); return { type = "set_fly_camera" }
        elseif word == "set_static_camera" then self:advance(); return { type = "set_static_camera" }
        elseif word == "set_camera_pos" then return self:parseSetCameraPos()
        elseif word == "camera_speed" then return self:parseCameraSpeed()
        elseif word == "camera_sensitivity" then return self:parseCameraSensitivity()
        elseif word == "camera_jump" then return self:parseCameraJump()
        elseif word == "camera_gravity" then return self:parseCameraGravity()
        elseif word == "camera_ground" then return self:parseCameraGround()
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
    if self:at("TO") then self:advance() end
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    local z = nil
    if self:match("COMMA") then z = self:parseExpr() end
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
    if self:match("COMMA") then v3 = self:expect("ID").value end
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
    if self:match("COMMA") then z = self:parseExpr() end
    local opts = {}
    while self:at("ROTATEX") or self:at("ROTATEY") or self:at("SCALE") or self:at("SIZE") or self:at("DRAWORDER") do
        local tt = self:peek().type
        if tt == "ROTATEX" then
            self:advance(); opts.rotSpeedX = self:parseExpr()
        elseif tt == "ROTATEY" then
            self:advance(); opts.rotSpeedY = self:parseExpr()
        elseif tt == "SCALE" then
            self:advance(); opts.scale = self:parseExpr()
        elseif tt == "SIZE" then
            self:advance(); opts.size = self:parseExpr()
        elseif tt == "DRAWORDER" then
            self:advance(); opts.drawOrder = self:parseExpr()
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
    if self:at("LOOP") then self:advance(); loop = true end
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
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
    return { type = "drawrect", args = args }
end

function Parser:parseDrawText()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
    return { type = "drawtext", args = args }
end

function Parser:parseDrawCircle()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
    return { type = "drawcircle", args = args }
end

function Parser:parseDrawLine()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
    return { type = "drawline", args = args }
end

function Parser:parseDrawImage()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
    return { type = "drawimage", args = args }
end

function Parser:parseDrawModel()
    self:advance()
    local args = {}
    args[#args+1] = self:parseExpr()
    while self:match("COMMA") do args[#args+1] = self:parseExpr() end
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

function Parser:parseLookAt()
    self:advance()
    local obj = self:expect("ID").value
    local tx = self:parseExpr()
    local ty, tz
    if self:at("COMMA") then
        self:advance()
        ty = self:parseExpr()
    end
    if self:at("COMMA") then
        self:advance()
        tz = self:parseExpr()
    end
    return { type = "look_at", obj = obj, tx = tx, ty = ty, tz = tz }
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
    if self:at("TO") then self:advance() end
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
    if self:at("SPEED") then self:advance(); speed = self:parseExpr() end
    if self:at("SENSITIVITY") then self:advance(); sensitivity = self:parseExpr() end
    return { type = "setup_camera", x = x, y = y, z = z, speed = speed, sensitivity = sensitivity }
end

function Parser:parseSetupRenderer()
    self:advance()
    local w = self:parseExpr()
    self:match("COMMA")
    local h = self:parseExpr()
    local fov = nil
    if self:at("FOV") then self:advance(); fov = self:parseExpr() end
    return { type = "setup_renderer", width = w, height = h, fov = fov }
end

function Parser:parseLoadTexture()
    self:advance()
    local name = self:parseExpr()
    self:expect("COMMA")
    local path = self:parseExpr()
    return { type = "load_texture", name = name, path = path }
end

function Parser:parseSetTexture()
    self:advance()
    local ent_name = self:parseExpr()
    self:expect("COMMA")
    local tex_name = self:parseExpr()
    return { type = "set_texture", ent_name = ent_name, tex_name = tex_name }
end

function Parser:parseLoadShader()
    self:advance()
    local name = self:parseExpr()
    self:expect("COMMA")
    local vert = self:parseExpr()
    self:expect("COMMA")
    local frag = self:parseExpr()
    return { type = "load_shader", name = name, vert = vert, frag = frag }
end

function Parser:parseSetShader()
    self:advance()
    local obj = self:parseExpr()
    self:expect("COMMA")
    local shader_name = self:parseExpr()
    return { type = "set_shader", obj = obj, shader_name = shader_name }
end

function Parser:parseSetShaderUniform()
    self:advance()
    local obj = self:parseExpr()
    self:expect("COMMA")
    local uname = self:parseExpr()
    self:expect("COMMA")
    local val = self:parseExpr()
    local val2 = nil
    local val3 = nil
    if self:match("COMMA") then
        val2 = self:parseExpr()
        self:expect("COMMA")
        val3 = self:parseExpr()
    end
    return { type = "set_shader_uniform", obj = obj, uname = uname, val = val, val2 = val2, val3 = val3 }
end

function Parser:parseReloadShader()
    self:advance()
    local name = self:parseExpr()
    return { type = "reload_shader", name = name }
end

function Parser:parseSetupCamera2D()
    self:advance()
    local args = {}
    if not self:at("ID") or (self:peek().value ~= "speed" and self:peek().value ~= "smoothing") then
        if not self:at("EOL") and not self:at("EOF") then
            args.x = self:parseExpr()
            if self:match("COMMA") then args.y = self:parseExpr() end
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
    return { type = "obj_is_grounded", objName = objToken.value }
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
    local t = self:peek()
    local mode
    if t.type == "ID" then
        mode = self:advance().value
    else
        mode = self:advance().value
    end
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
            self:advance(); opts.rotSpeedX = self:parseExpr()
        elseif tt == "ROTATEY" then
            self:advance(); opts.rotSpeedY = self:parseExpr()
        elseif tt == "SCALE" then
            self:advance(); opts.scale = self:parseExpr()
        elseif tt == "SIZE" then
            self:advance(); opts.size = self:parseExpr()
        elseif tt == "DRAWORDER" then
            self:advance(); opts.drawOrder = self:parseExpr()
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
        self:advance(); self:expect("ASSIGN"); opts.id = self:parseExpr()
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
        self:advance(); self:expect("ASSIGN"); opts.id = self:parseExpr()
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
            while self:match("COMMA") do frames[#frames+1] = self:parseExpr() end
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
            while self:match("COMMA") do frames[#frames+1] = self:parseExpr() end
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
    local animName = nil
    if self:match("COMMA") then animName = self:parseExpr() end
    return { type = "anim_play", objName = objToken.value, animName = animName }
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
    if self:at("ID") then parseOpt(self:peek().value) end
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
    while self:match("COMMA") do keys[#keys+1] = self:parseExpr() end
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

function Parser:parseSetFpsCamera()
    self:advance()
    local x, y, z = nil, nil, nil
    if not self:at("EOF") and not self:at("SPEED") and not self:at("SENSITIVITY") and not self:at("GROUND") and not self:at("JUMP") and not self:at("GRAVITY") then
        x = self:parseExpr()
        self:expect("COMMA")
        y = self:parseExpr()
        self:expect("COMMA")
        z = self:parseExpr()
    end
    local speed = nil
    local sensitivity = nil
    local ground_y = nil
    local jump_force = nil
    local gravity = nil
    while not self:at("EOF") do
        if self:at("SPEED") then self:advance(); speed = self:parseExpr()
        elseif self:at("SENSITIVITY") then self:advance(); sensitivity = self:parseExpr()
        elseif self:at("GROUND") then self:advance(); ground_y = self:parseExpr()
        elseif self:at("JUMP") then self:advance(); jump_force = self:parseExpr()
        elseif self:at("GRAVITY") then self:advance(); gravity = self:parseExpr()
        else break end
    end
    return { type = "set_fps_camera", x = x, y = y, z = z, speed = speed, sensitivity = sensitivity, ground_y = ground_y, jump_force = jump_force, gravity = gravity }
end

function Parser:parseSetCameraPos()
    self:advance()
    local x = self:parseExpr()
    self:expect("COMMA")
    local y = self:parseExpr()
    self:expect("COMMA")
    local z = self:parseExpr()
    return { type = "set_camera_pos", x = x, y = y, z = z }
end

function Parser:parseCameraSpeed()
    self:advance()
    local val = self:parseExpr()
    return { type = "camera_speed", value = val }
end

function Parser:parseCameraSensitivity()
    self:advance()
    local val = self:parseExpr()
    return { type = "camera_sensitivity", value = val }
end

function Parser:parseCameraJump()
    self:advance()
    local val = self:parseExpr()
    return { type = "camera_jump", value = val }
end

function Parser:parseCameraGravity()
    self:advance()
    local val = self:parseExpr()
    return { type = "camera_gravity", value = val }
end

function Parser:parseCameraGround()
    self:advance()
    local val = self:parseExpr()
    return { type = "camera_ground", value = val }
end

return Parser
