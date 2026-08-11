local M = {}
local gl = require("engine.core.platform.gl")

function M:exec(stmt)
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
        if self.ctx.stop_all_sounds then self.ctx.stop_all_sounds() end

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
        if self.ctx.audio then self.ctx.audio:stop_all() end

    elseif stmt.type == "volume" then
        if self.ctx.audio then
            local vol = tonumber(self:evalExpr(stmt.value)) or 1.0
            for _, src in ipairs(self.ctx.audio.sources) do
                self.ctx.audio.al.alSourcef(src.id, self.ctx.audio.AL_GAIN, vol)
            end
        end

    elseif stmt.type == "switchscene" then
        local name = self:evalExpr(stmt.name)
        if self.ctx.switch_scene then self.ctx.switch_scene(name) end

    elseif stmt.type == "setup_camera" then
        local x = tonumber(self:evalExpr(stmt.x)) or 0
        local y = tonumber(self:evalExpr(stmt.y)) or 2
        local z = tonumber(self:evalExpr(stmt.z)) or -3
        local speed = stmt.speed and tonumber(self:evalExpr(stmt.speed)) or 4
        local sens = stmt.sensitivity and tonumber(self:evalExpr(stmt.sensitivity)) or 0.0025
        if self.ctx.camera then
            self.ctx.camera.position = require("engine.core.math").vec3(x, y, z)
            self.ctx.camera.speed = speed
            self.ctx.camera.sensitivity = sens * 0.001
        end

    elseif stmt.type == "setup_renderer" then
        local w = tonumber(self:evalExpr(stmt.width)) or 320
        local h = tonumber(self:evalExpr(stmt.height)) or 240
        local fov = stmt.fov and tonumber(self:evalExpr(stmt.fov)) or 60
        if self.ctx.renderer then
            self.ctx.renderer:set_internal_resolution(w, h)
            self.ctx.renderer.fov = math.rad(fov)
        end

    elseif stmt.type == "load_texture" then
        local name = tostring(self:evalExpr(stmt.name))
        local path = tostring(self:evalExpr(stmt.path))
        if self.ctx.load_texture then
            self.ctx.load_texture(name, path)
        end

    elseif stmt.type == "set_texture" then
        local ent_val = self:evalExpr(stmt.ent_name)
        local ent_name
        if type(ent_val) == "table" and ent_val.name then
            ent_name = ent_val.name
        else
            ent_name = tostring(ent_val)
        end
        local tex_name = tostring(self:evalExpr(stmt.tex_name))
        if self.ctx.set_entity_texture then
            self.ctx.set_entity_texture(ent_name, tex_name)
        end

    elseif stmt.type == "load_shader" then
        local name = tostring(self:evalExpr(stmt.name))
        local vert = tostring(self:evalExpr(stmt.vert))
        local frag = tostring(self:evalExpr(stmt.frag))
        if self.ctx.load_shader then
            self.ctx.load_shader(name, vert, frag)
        end

    elseif stmt.type == "set_shader" then
        local obj_val = self:evalExpr(stmt.obj)
        local obj_name
        if type(obj_val) == "table" and obj_val.name then
            obj_name = obj_val.name
        else
            obj_name = tostring(obj_val)
        end
        local shader_name = tostring(self:evalExpr(stmt.shader_name))
        local obj = self.vars[obj_name] or obj_val
        if obj and type(obj) == "table" then
            local s = self.ctx.get_shader and self.ctx.get_shader(shader_name) or nil
            if s then
                obj.shader = s
                if obj.node then
                    obj.node.shader = s
                end
            end
        end

    elseif stmt.type == "look_at" then
        self:execLookAt(stmt)

    elseif stmt.type == "set_shader_uniform" then
        local obj_val = self:evalExpr(stmt.obj)
        local obj_name
        if type(obj_val) == "table" and obj_val.name then
            obj_name = obj_val.name
        else
            obj_name = tostring(obj_val)
        end
        local uname = tostring(self:evalExpr(stmt.uname))
        local obj = self.vars[obj_name] or obj_val
        if obj and type(obj) == "table" then
            if stmt.val3 then
                local v1 = tonumber(self:evalExpr(stmt.val)) or 0
                local v2 = tonumber(self:evalExpr(stmt.val2)) or 0
                local v3 = tonumber(self:evalExpr(stmt.val3)) or 0
                obj.shader_uniforms[uname] = {v1, v2, v3}
                if obj.node then
                    obj.node.shader_uniforms[uname] = {v1, v2, v3}
                end
            else
                local v = self:evalExpr(stmt.val)
                obj.shader_uniforms[uname] = v
                if obj.node then
                    obj.node.shader_uniforms[uname] = v
                end
            end
        end

    elseif stmt.type == "reload_shader" then
        local name = tostring(self:evalExpr(stmt.name))
        if self.ctx.reload_shader then
            self.ctx.reload_shader(name)
        end

    elseif stmt.type == "set_mouse" then
        if stmt.mode == "relative" then
            if self.ctx.set_mouse then self.ctx.set_mouse("relative") end
        elseif stmt.mode == "visible" then
            if self.ctx.set_mouse then self.ctx.set_mouse("visible") end
        end

    elseif stmt.type == "camera_update" then

    elseif stmt.type == "camera_collide" then

    elseif stmt.type == "set_fps_camera" then
        if self.ctx.camera then
            local cam = self.ctx.camera
            cam.fps_mode = true
            if stmt.x ~= nil then
                local x = tonumber(self:evalExpr(stmt.x)) or 0
                local y = tonumber(self:evalExpr(stmt.y)) or 1.7
                local z = tonumber(self:evalExpr(stmt.z)) or 0
                cam.position = require("engine.core.math").vec3(x, y, z)
            end
            if stmt.speed then cam.speed = tonumber(self:evalExpr(stmt.speed)) or 5 end
            if stmt.sensitivity then cam.sensitivity = (tonumber(self:evalExpr(stmt.sensitivity)) or 2) * 0.001 end
            if stmt.ground_y then cam.groundY = tonumber(self:evalExpr(stmt.ground_y)) or 1.7 end
            if stmt.jump_force then cam.jumpForce = tonumber(self:evalExpr(stmt.jump_force)) or 8 end
            if stmt.gravity then cam.gravity = tonumber(self:evalExpr(stmt.gravity)) or -20 end
        end

    elseif stmt.type == "set_fly_camera" then
        if self.ctx.camera then
            self.ctx.camera.fps_mode = false
        end

    elseif stmt.type == "set_static_camera" then
        if self.ctx.camera then
            self.ctx.camera.locked = true
        end

    elseif stmt.type == "set_camera_pos" then
        if self.ctx.camera then
            local x = tonumber(self:evalExpr(stmt.x)) or 0
            local y = tonumber(self:evalExpr(stmt.y)) or 2
            local z = tonumber(self:evalExpr(stmt.z)) or 0
            self.ctx.camera.position = require("engine.core.math").vec3(x, y, z)
        end

    elseif stmt.type == "camera_speed" then
        if self.ctx.camera then
            self.ctx.camera.speed = tonumber(self:evalExpr(stmt.value)) or 5
        end

    elseif stmt.type == "camera_sensitivity" then
        if self.ctx.camera then
            self.ctx.camera.sensitivity = (tonumber(self:evalExpr(stmt.value)) or 2) * 0.001
        end

    elseif stmt.type == "camera_jump" then
        if self.ctx.camera then
            self.ctx.camera.jumpForce = tonumber(self:evalExpr(stmt.value)) or 8
        end

    elseif stmt.type == "camera_gravity" then
        if self.ctx.camera then
            self.ctx.camera.gravity = tonumber(self:evalExpr(stmt.value)) or -20
        end

    elseif stmt.type == "camera_ground" then
        if self.ctx.camera then
            self.ctx.camera.groundY = tonumber(self:evalExpr(stmt.value)) or 1.7
        end

    elseif stmt.type == "exit_game" then
        if self.ctx.exit_game then self.ctx.exit_game() end

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

function M:execBlock(stmts)
    for _, s in ipairs(stmts) do
        self:exec(s)
        if self._break then break end
    end
end

function M:execCreateModel(stmt)
    local MioObject = require("engine.core.scene.mio_object")
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

    local name = stmt.name
    local node = self.ctx.create_entity(name)
    self.ctx.load_model(name, modelPath)
    self.ctx.attach_model(name, name)
    node:set_position(x, y, z)

    local obj = MioObject.new(node, name)
    obj.x = x
    obj.y = y
    obj.z = z
    obj.rotSpeedX = opts.rotSpeedX or 0
    obj.rotSpeedY = opts.rotSpeedY or 0
    obj.scale = opts.scale or 1
    obj:markDirty()

    self.ctx.objects = self.ctx.objects or {}
    self.ctx.objects[#self.ctx.objects+1] = obj
    self.vars[stmt.name] = obj
end

function M:execAddObject(stmt)
    local MioObject = require("engine.core.scene.mio_object")
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

    local name = stmt.name
    local node = self.ctx.create_entity(name)
    self.ctx.load_model(name, modelPath)
    self.ctx.attach_model(name, name)
    node:set_position(x, y, z)

    local obj = MioObject.new(node, name)
    obj.x = x
    obj.y = y
    obj.z = z
    obj.rotSpeedX = opts.rotSpeedX or 0
    obj.rotSpeedY = opts.rotSpeedY or 0
    obj.scale = opts.scale or 1
    obj:markDirty()

    self.ctx.objects = self.ctx.objects or {}
    self.ctx.objects[#self.ctx.objects+1] = obj
    self.vars[stmt.name] = obj
end

function M:execAddCollider(stmt)
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

function M:execCheckHit(stmt)
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

function M:execAddBody(stmt)
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

function M:execAddBody3D(stmt)
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

function M:execSetPhysics(stmt)
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

function M:execMove(stmt)
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

function M:execMoveTowards(stmt)
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

function M:execSetPos(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    if stmt.x then obj.x = tonumber(self:evalExpr(stmt.x)) or obj.x end
    if stmt.y then obj.y = tonumber(self:evalExpr(stmt.y)) or obj.y end
    if stmt.z then obj.z = tonumber(self:evalExpr(stmt.z)) or obj.z end
    if obj.markDirty then obj:markDirty() end
end

function M:execGetPos(stmt)
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

function M:execSetRot(stmt)
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

function M:execLookAt(stmt)
    local obj = self.vars[stmt.obj]
    if not obj then return end
    local tx = tonumber(self:evalExpr(stmt.tx)) or 0
    local ty = tonumber(self:evalExpr(stmt.ty)) or 0
    local tz = tonumber(self:evalExpr(stmt.tz)) or 0
    local dx = tx - (obj.x or 0)
    local dy = ty - (obj.y or 0)
    local dz = tz - (obj.z or 0)
    if dx == 0 and dz == 0 then return end
    local yaw = math.deg(math.atan2(dz, dx))
    local pitch = math.deg(math.atan2(dy, math.sqrt(dx * dx + dz * dz)))
    obj.angleY = yaw
    obj.angleX = -pitch
    if obj.markDirty then obj:markDirty() end
end

function M:execDestroy(stmt)
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

function M:execPlaySound(stmt)
    if self.ctx.play_sound then
        local path = self:evalExpr(stmt.path)
        if self.ctx.audio then
            self.ctx.audio:load_wav(stmt.name, path)
        end
        self.ctx.play_sound(stmt.name, { path = path, loop = stmt.loop })
    end
end

function M:execDrawRect(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    if self.ctx.ui then
        self.ctx.ui:draw_rect(args[1] or 0, args[2] or 0, args[3] or 0, args[4] or 0,
            args[5] or 1, args[6] or 1, args[7] or 1)
    end
end

function M:execDrawText(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    if self.ctx.ui then
        if self.ctx.ui.quad_count and self.ctx.ui.quad_count > 0 then
            self.ctx.ui:flush()
            self.ctx.ui.quad_count = 0
            gl.glEnable(gl.GL_BLEND)
            gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
            gl.glDisable(gl.GL_DEPTH_TEST)
        end
        local font = self.ctx.ui.font or self.ctx.ui.font_small
        if not font then self:log("draw_text: NO FONT!") return end
        if not font.atlas_tex then self:log("draw_text: NO ATLAS!") return end
        local size = tonumber(args[4]) or 12
        if font then
            local scale = size / font.pixel_height
            local text = tostring(args[1] or "")
            local x = tonumber(args[2]) or 0
            local y = tonumber(args[3]) or 0
            local r = tonumber(args[5]) or 1
            local g = tonumber(args[6]) or 1
            local b = tonumber(args[7]) or 1
            local a = tonumber(args[8]) or 1
            local align = args[9] or "left"
            font:draw_text(text, x, y, scale, r, g, b, a, align)
        else
            self.ctx.ui:draw_text(tostring(args[1] or ""), tonumber(args[2]) or 0, tonumber(args[3]) or 0,
                size, tonumber(args[5]) or 1, tonumber(args[6]) or 1,
                tonumber(args[7]) or 1, tonumber(args[8]) or 1, args[9] or "left")
        end
    end
end

function M:execDrawCircle(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    if self.ctx.ui then
        self.ctx.ui:draw_circle(args[1] or 0, args[2] or 0, args[3] or 10,
            args[4] or 1, args[5] or 1, args[6] or 1)
    end
end

function M:execDrawLine(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = tonumber(self:evalExpr(a)) or 0 end
    if self.ctx.ui then
        self.ctx.ui:draw_line(args[1] or 0, args[2] or 0, args[3] or 0, args[4] or 0,
            args[5] or 1, args[6] or 1, args[7] or 1, args[8] or 1, args[9] or 1)
    end
end

function M:execDrawImage(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    local path = tostring(args[1] or "")
    local x = tonumber(args[2]) or 0
    local y = tonumber(args[3]) or 0

    local res = self.ctx.resources
    local img
    if res then
        img = res:getImage(path)
    end

    if not img then return end
    self:log("draw_image: rendering not available in this engine")
end

function M:execDrawSprite(stmt)
    local path = tostring(self:evalExpr(stmt.path) or "")
    self:log("draw_sprite: not available in this engine (use add_object for 3D)")
end

function M:execDrawModel(stmt)
    local args = {}
    for i, a in ipairs(stmt.args) do args[i] = self:evalExpr(a) end
    self:log("draw_model: not available in this engine (use add_object)")
end

function M:execGetCanvasSize(stmt)
    local w, h
    if self.ctx.renderer then
        w = self.ctx.renderer.width or 800
        h = self.ctx.renderer.height or 600
    else
        w = 800
        h = 600
    end
    self.vars[stmt.vars[1]] = w
    self.vars[stmt.vars[2]] = h
end

function M:execSetScale(stmt)
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


function M:execCreateAnim(stmt)
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

function M:execCreateAnimatedSprite(stmt)
    self:log("create_animated_sprite: not available in this engine")
end

function M:execAnimAdd(stmt)
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

function M:execAnimPlay(stmt)
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

function M:execAnimStop(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.stop then sprite:stop()
    elseif sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim then anim:stop() end
    end
end

function M:execAnimPause(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.pause then sprite:pause() end
end

function M:execAnimResume(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.resume then sprite:resume() end
end

function M:execAnimSetSpeed(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    local fps = tonumber(self:evalExpr(stmt.fps)) or 8
    if sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim and anim.setSpeed then anim:setSpeed(fps) end
    end
end

function M:execAnimSetFrame(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    local frame = tonumber(self:evalExpr(stmt.frame)) or 1
    if sprite.animations and sprite.currentAnim then
        local anim = sprite.animations[sprite.currentAnim]
        if anim and anim.setFrame then anim:setFrame(frame) end
    end
end

function M:execDrawAnimatedSprite(stmt)
    local sprite = self.vars[stmt.objName]
    if not sprite then return end
    if sprite.update then sprite:update(self.ctx.dt or 0) end
    if sprite.draw then sprite:draw() end
end


function M:execCreateParticles(stmt)
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

function M:execParticlesSetPos(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.setPosition then return end
    ps:setPosition(tonumber(self:evalExpr(stmt.x)) or 0, tonumber(self:evalExpr(stmt.y)) or 0)
end

function M:execParticlesEmit(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.emit then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 1
    ps:emit(count)
end

function M:execParticlesBurst(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.burst then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 10
    ps:burst(count)
end

function M:execParticlesStart(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.start then ps:start() end
end

function M:execParticlesStop(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.stop then ps:stop() end
end

function M:execParticlesClear(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.clear then ps:clear() end
end

function M:execParticlesConfigure(stmt)
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

function M:execDrawParticles(stmt)
    local ps = self.vars[stmt.objName]
    if not ps then return end
    if ps.update then ps:update(self.ctx.dt or 0) end
    if ps.draw then ps:draw() end
end


function M:execSetPhysics3DGravity(stmt)
    local FP3D = require("mioengine.core.flag_physics3d")
    if not self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d = FP3D.new({})
    end
    local gx = tonumber(self:evalExpr(stmt.gx)) or 0
    local gy = stmt.gy and tonumber(self:evalExpr(stmt.gy)) or 980
    local gz = stmt.gz and tonumber(self:evalExpr(stmt.gz)) or 0
    self.ctx.flagPhysics3d.gravity = { x = gx, y = gy, z = gz }
end

function M:execSetPhysics3DFloor(stmt)
    local FP3D = require("mioengine.core.flag_physics3d")
    if not self.ctx.flagPhysics3d then
        self.ctx.flagPhysics3d = FP3D.new({})
    end
    self.ctx.flagPhysics3d.groundY = tonumber(self:evalExpr(stmt.floorY))
end

function M:execSetPhysics3D(stmt)
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

function M:execObj3DImpulse(stmt)
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

function M:execObj3DSetVel(stmt)
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

function M:execObj3DGetVel(stmt)
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

function M:execObj3DSetPos(stmt)
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


function M:execCreateParticles3D(stmt)
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

function M:execParticles3DSetPos(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.setPosition then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local z = stmt.z and tonumber(self:evalExpr(stmt.z)) or 0
    ps:setPosition(x, y, z)
end

function M:execParticles3DEmit(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.emit then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 1
    ps:emit(count)
end

function M:execParticles3DBurst(stmt)
    local ps = self.vars[stmt.objName]
    if not ps or not ps.burst then return end
    local count = stmt.count and tonumber(self:evalExpr(stmt.count)) or 10
    ps:burst(count)
end

function M:execParticles3DStart(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.start then ps:start() end
end

function M:execParticles3DStop(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.stop then ps:stop() end
end

function M:execParticles3DClear(stmt)
    local ps = self.vars[stmt.objName]
    if ps and ps.clear then ps:clear() end
end

function M:execParticles3DConfigure(stmt)
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

function M:execDrawParticles3D(stmt)
    local ps = self.vars[stmt.objName]
    if not ps then return end
    local list = self.ctx.particles3dList
    if list then
        list[#list + 1] = ps
    end
end


function M:execWatchFile(stmt)
    local path = tostring(self:evalExpr(stmt.path))
    if self.ctx.hotReload then
        self.ctx.hotReload:watch(path, function(changedPath)
            self:log("File changed: " .. changedPath)
        end)
    end
end

function M:execUnwatchFile(stmt)
    local path = tostring(self:evalExpr(stmt.path))
    if self.ctx.hotReload then
        self.ctx.hotReload:unwatch(path)
    end
end


function M:execBindKey(stmt)
    local action = tostring(self:evalExpr(stmt.action))
    local keys = {}
    for _, k in ipairs(stmt.keys) do
        keys[#keys+1] = self:evalExpr(k)
    end
    if self.ctx.inputMapper then
        self.ctx.inputMapper:bind(action, unpack(keys))
    end
end

function M:execUnbindKey(stmt)
    local action = tostring(self:evalExpr(stmt.action))
    if self.ctx.inputMapper then
        self.ctx.inputMapper:unbind(action)
    end
end


function M:execCreatePanel(stmt)
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

function M:execPanelAddButton(stmt)
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

function M:execPanelAddLabel(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.addLabel then return end
    local text = tostring(self:evalExpr(stmt.text))
    local size = 14
    if stmt.opts and stmt.opts.size then size = tonumber(self:evalExpr(stmt.opts.size)) end
    panel:addLabel(5, 0, text, { size = size })
    panel:reflow()
end

function M:execPanelAddSeparator(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.addSeparator then return end
    panel:addSeparator()
end

function M:execDrawPanel(stmt)
    local panel = self.vars[stmt.objName]
    if not panel then return end
    if panel.update then panel:update(self.ctx.dt or 0) end
    if panel.draw then panel:draw() end
end

function M:execPanelSetVisible(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.setVisible then return end
    panel:setVisible(self:evalExpr(stmt.visible))
end

function M:execPanelSetPosition(stmt)
    local panel = self.vars[stmt.objName]
    if not panel or not panel.setPosition then return end
    panel:setPosition(tonumber(self:evalExpr(stmt.x)) or 0, tonumber(self:evalExpr(stmt.y)) or 0)
end

function M:execUIButton(stmt)
    if not self.ctx.ui then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local w = tonumber(self:evalExpr(stmt.w)) or 100
    local h = tonumber(self:evalExpr(stmt.h)) or 30
    local label = tostring(self:evalExpr(stmt.label) or "")
    local opts = {}
    if stmt.opts then
        if stmt.opts.id then opts.id = tostring(self:evalExpr(stmt.opts.id)) end
        if stmt.opts.fontsize then opts.font_size = tonumber(self:evalExpr(stmt.opts.fontsize)) end
        if stmt.opts.bg then
            local bg = self:evalExpr(stmt.opts.bg)
            if type(bg) == "table" then opts.bg_color = bg end
        end
    end

    local id = opts.id or ("btn_" .. tostring(self._next_btn_id or 1))
    self._next_btn_id = (self._next_btn_id or 1) + 1

    local clicked = self.ctx.ui:ui_button(id, x, y, w, h, label, opts)
    self.vars["_btn_" .. id] = self.vars["_btn_" .. id] or {}
    self.vars["_btn_" .. id].justClicked = clicked
    self.vars["_btn_" .. id].id = id
end

function M:execUICheckbox(stmt)
    if not self.ctx.ui then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local size = tonumber(self:evalExpr(stmt.size)) or 18
    local checked = self:evalExpr(stmt.checked)
    if checked == nil then checked = false end
    local opts = {}
    if stmt.opts then
        if stmt.opts.id then opts.id = tostring(self:evalExpr(stmt.opts.id)) end
    end

    local id = opts.id or ("chk_" .. tostring(self._next_chk_id or 1))
    self._next_chk_id = (self._next_chk_id or 1) + 1

    local prev = self.vars["_chk_" .. id]
    local prev_checked = prev and prev.checked or checked
    opts.size = size
    local new_checked = self.ctx.ui:ui_checkbox(id, x, y, prev_checked, opts)
    self.vars["_chk_" .. id] = self.vars["_chk_" .. id] or {}
    self.vars["_chk_" .. id].checked = new_checked
    self.vars["_chk_" .. id].id = id
end

function M:execUISlider(stmt)
    if not self.ctx.ui then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local w = tonumber(self:evalExpr(stmt.w)) or 150
    local h = tonumber(self:evalExpr(stmt.h)) or 20
    local value = tonumber(self:evalExpr(stmt.value)) or 0
    local minVal = tonumber(self:evalExpr(stmt.minVal)) or 0
    local maxVal = tonumber(self:evalExpr(stmt.maxVal)) or 1
    local opts = {}
    if stmt.opts then
        if stmt.opts.id then opts.id = tostring(self:evalExpr(stmt.opts.id)) end
    end

    local id = opts.id or ("sld_" .. tostring(self._next_sld_id or 1))
    self._next_sld_id = (self._next_sld_id or 1) + 1

    local prev = self.vars["_sld_" .. id]
    local prev_value = prev and prev.value or value
    local new_value = self.ctx.ui:ui_slider(id, x, y, w, h, prev_value, minVal, maxVal, opts)
    self.vars["_sld_" .. id] = self.vars["_sld_" .. id] or {}
    self.vars["_sld_" .. id].value = new_value
    self.vars["_sld_" .. id].id = id
end

function M:execUILabel(stmt)
    if not self.ctx.ui then return end
    local x = tonumber(self:evalExpr(stmt.x)) or 0
    local y = tonumber(self:evalExpr(stmt.y)) or 0
    local text = tostring(self:evalExpr(stmt.text) or "")
    local opts = {}
    if stmt.opts then
        if stmt.opts.id then opts.id = tostring(self:evalExpr(stmt.opts.id)) end
        if stmt.opts.fontsize then opts.font_size = tonumber(self:evalExpr(stmt.opts.fontsize)) end
        if stmt.opts.align then opts.align = tostring(self:evalExpr(stmt.opts.align)) end
    end
    self.ctx.ui:ui_label(opts.id or "lbl", x, y, text, opts)
end

return M
