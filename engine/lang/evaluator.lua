local M = {}

function M:evalExpr(node)
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
        if self.ctx.key_down then return self.ctx.key_down(key) end
        return false
    end

    if node.type == "mouse_down" then
        local btn = tonumber(self:evalExpr(node.button)) or 1
        if self.ctx.mouse_down then return self.ctx.mouse_down(btn) end
        return false
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

function M:callFunc(name, argNodes)
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
    elseif name == "time" then return self.ctx.time and self.ctx.time() or 0
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

function M:callMethod(objName, method, argNodes)
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

return M
