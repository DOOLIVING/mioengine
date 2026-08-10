package.path = "./?.lua;./?/init.lua;" .. package.path
local ffi = require("ffi")
if ffi.os == "Windows" then
    package.cpath = "./?.dll;" .. package.cpath
else
    package.cpath = "./?.so;./?.dylib;" .. package.cpath
end

local engine = {}

engine.glfw = require("engine.core.platform.glfw")
engine.gl = require("engine.core.platform.gl")
engine.math3d = require("engine.core.math")
engine.assimp = require("engine.core.render.assimp")
engine.Camera = require("engine.core.camera")
engine.SceneNode = require("engine.core.scene.scene_graph")
engine.Renderer = require("engine.core.render.renderer")
engine.Input = require("engine.core.input")
engine.ResourceManager = require("engine.core.resource_manager")
engine.SceneManager = require("engine.core.scene.scene_manager")
engine.Shader = require("engine.core.render.shader")
engine.Texture = require("engine.core.render.texture")
engine.Mesh = require("engine.core.render.mesh")
engine.Audio = require("engine.core.platform.audio")
engine.UI = require("engine.core.ui")
engine.Font = require("engine.core.render.font")
engine.ConfParser = require("engine.core.conf_parser")
engine.MioLang = require("engine.lang.mio_lang")

function engine.run(config_path)
    print("[MioEngine] Starting...")
    print("[MioEngine] Config path:", config_path)
    
    config_path = config_path or "game/main.mioconf"
    local config = engine.ConfParser.parse(config_path)
    print("[MioEngine] Config loaded successfully")

    local win_w = config.window.width or 800
    local win_h = config.window.height or 600

    print("[MioEngine] Creating window: " .. win_w .. "x" .. win_h)
    local win = engine.glfw.init(win_w, win_h, config.window.title or "MioEngine")
    print("[MioEngine] Window created")
    
    print("[MioEngine] Initializing OpenGL...")
    engine.gl.init()
    
    print("[MioEngine] OpenGL Vendor:", ffi.string(engine.gl.glGetString(engine.gl.GL_VENDOR)))
    print("[MioEngine] OpenGL Renderer:", ffi.string(engine.gl.glGetString(engine.gl.GL_RENDERER)))
    print("[MioEngine] OpenGL Version:", ffi.string(engine.gl.glGetString(engine.gl.GL_VERSION)))

    local input = engine.Input.new()
    input:init(win)
    print("[MioEngine] Input initialized")

    local resources = engine.ResourceManager.new()
    local audio = engine.Audio.new()
    print("[MioEngine] Resources and Audio initialized")

    local renderer = engine.Renderer.new({
        width = config.renderer.width or 320,
        height = config.renderer.height or 240,
        fov = config.renderer.fov or 60,
        snap_size = config.renderer.snap_size or 40,
        fog_density = config.renderer.fog_density or 0.015,
        window_width = win_w,
        window_height = win_h,
    })
    renderer:init()
    print("[MioEngine] Renderer initialized")

    local camera = engine.Camera.new({
        x = config.camera.x or 0,
        y = config.camera.y or 1.5,
        z = config.camera.z or 5,
        speed = config.camera.speed or 5,
        sensitivity = (config.camera.sensitivity or 2) * 0.001,
        fov = config.camera.fov or 60,
    })
    print("[MioEngine] Camera initialized")

    local scene_manager = engine.SceneManager.new(resources)

    local ui = engine.UI.new()

    local font = engine.Font.new({ pixel_height = 32.0 })
    local font_small = engine.Font.new({ pixel_height = 16.0 })

    local Platform = require("engine.core.platform.platform")
    local font_path = config.font and config.font.path or nil
    if not font_path then
        font_path = Platform.find_font()
    end

    if font_path then
        print("[MioEngine] Loading font:", font_path)
        local ok1, err1 = pcall(function() font:load_from_file(font_path) end)
        if not ok1 then
            print("[MioEngine] WARNING: Failed to load font:", err1)
        else
            print("[MioEngine] Font loaded successfully")
        end
        local ok2, err2 = pcall(function() font_small:load_from_file(font_path) end)
        if not ok2 then
            print("[MioEngine] WARNING: Failed to load small font:", err2)
        end
    else
        print("[MioEngine] WARNING: No font file found, text rendering disabled")
    end

    ui:set_font(font, font_small)

    local shader_manager = require("engine.core.render.shader_manager").new()
    local show_debug = false
    local mouse_captured = false
    local fps_timer = 0
    local fps_count = 0
    local fps_display = 0
    local frame_count = 0
    local total_time = 0

    local ctx = {
        engine = engine,
        win = win,
        input = input,
        resources = resources,
        audio = audio,
        renderer = renderer,
        camera = camera,
        scene_manager = scene_manager,
        ui = ui,
        font = font,
        font_small = font_small,
        show_debug = function() return show_debug end,
        mouse_captured = function() return mouse_captured end,
    }

    local scenes = {}
    print("[MioEngine] Loading scenes...")
    for _, scene_def in ipairs(config.scenes) do
        print("[MioEngine]  - Scene:", scene_def.name, "script:", scene_def.script)
        local script_src = nil
        if scene_def.script and scene_def.script ~= "" then
            local f = io.open(scene_def.script, "r")
            if f then
                script_src = f:read("*a")
                f:close()
                print("[MioEngine]    Script loaded successfully")
            else
                print("[MioEngine]    WARNING: Script file not found:", scene_def.script)
            end
        end
        scenes[scene_def.name] = {
            script = script_src,
            def = scene_def,
            entities = {},
            root = engine.SceneNode.new(scene_def.name),
        }
    end

    local current_scene_name = config.default_scene or ""
    if current_scene_name == "" then
        for name, _ in pairs(scenes) do
            current_scene_name = name
            break
        end
    end
    print("[MioEngine] Default scene:", current_scene_name)

    local active_ctx = nil
    local scene_miolangs = {}

    local function cleanup_scene(scene_name)
        local old_miolang = scene_miolangs[scene_name]
        if old_miolang then
            old_miolang.initialized = false
            scene_miolangs[scene_name] = nil
        end
        local scene = scenes[scene_name]
        if scene then
            scene.entities = {}
            scene.root = engine.SceneNode.new(scene_name)
        end
    end

    local function create_scene_context(scene_name)
        local scene = scenes[scene_name]
        if not scene then return nil end

        local sc = {
            name = scene_name,
            entities = {},
            root = scene.root,
            camera = camera,
            renderer = renderer,
            input = input,
            resources = resources,
            audio = audio,
            engine = engine,
            win = win,
            ui = ui,
            font = font,
            font_small = font_small,
            time = function() return total_time end,
            delta_time = function() return 1/60 end,

            create_entity = function(name)
                local ent = engine.SceneNode.new(name)
                scene.entities[name] = ent
                scene.root:add_child(ent)
                return ent
            end,

            load_model = function(name, path)
                return resources:load_model(name, path)
            end,

            attach_model = function(ent_name, model_name)
                local ent = scene.entities[ent_name]
                if not ent then return end
                local root = resources:get_model_root(model_name)
                if root then
                    ent:add_child(root)
                    return root
                end
                local meshes = resources:get_model(model_name)
                if meshes then ent:set_meshes(meshes) end
            end,

            get_model = function(name)
                return resources:get_model(name)
            end,

            load_texture = function(name, path, params)
                return resources:load_texture(name, path, params)
            end,

            get_texture = function(name)
                return resources:get_texture(name)
            end,

            load_audio = function(name, path)
                return audio:load_wav(name, path)
            end,

            play_sound = function(name, params)
                return audio:play(name, params)
            end,

            stop_all_sounds = function()
                audio:stop_all()
            end,

            set_entity_mesh = function(ent_name, mesh_or_name)
                local ent = scene.entities[ent_name]
                if not ent then return end
                if type(mesh_or_name) == "string" then
                    local root = resources:get_model_root(mesh_or_name)
                    if root then
                        ent:add_child(root)
                        return
                    end
                    local meshes = resources:get_model(mesh_or_name)
                    if meshes then ent:set_meshes(meshes) end
                elseif type(mesh_or_name) == "table" then
                    if mesh_or_name.vao then
                        ent:set_meshes({ mesh_or_name })
                    elseif mesh_or_name.get_model_matrix and mesh_or_name.meshes then
                        ent:add_child(mesh_or_name)
                    elseif mesh_or_name[1] and mesh_or_name[1].vao then
                        ent:set_meshes(mesh_or_name)
                    end
                end
            end,

            set_entity_texture = function(ent_name, tex_name)
                local ent = scene.entities[ent_name]
                if ent then
                    local tex = resources:get_texture(tex_name)
                    if tex then ent.texture = tex end
                end
            end,

            set_entity_position = function(ent_name, x, y, z)
                local ent = scene.entities[ent_name]
                if ent then ent:set_position(x, y, z) end
            end,

            set_entity_rotation = function(ent_name, pitch, yaw, roll)
                local ent = scene.entities[ent_name]
                if ent then ent:set_rotation(pitch, yaw, roll) end
            end,

            set_entity_scale = function(ent_name, sx, sy, sz)
                local ent = scene.entities[ent_name]
                if ent then ent:set_scale(sx, sy, sz) end
            end,

            set_entity_color = function(ent_name, r, g, b)
                local ent = scene.entities[ent_name]
                if ent then ent.color = engine.math3d.vec3(r, g, b) end
            end,

            move_entity = function(ent_name, dx, dy, dz)
                local ent = scene.entities[ent_name]
                if ent then
                    ent.position = engine.math3d.vec3_add(ent.position, engine.math3d.vec3(dx, dy, dz))
                end
            end,

            destroy_entity = function(ent_name)
                local ent = scene.entities[ent_name]
                if ent then
                    scene.root:remove_child(ent_name)
                    scene.entities[ent_name] = nil
                end
            end,

            get_entity = function(name)
                return scene.entities[name]
            end,

            set_camera_position = function(x, y, z)
                camera.position = engine.math3d.vec3(x, y, z)
            end,

            get_camera_position = function()
                return camera.position[0], camera.position[1], camera.position[2]
            end,

            set_camera_fov = function(fov)
                camera.fov = math.rad(fov)
            end,

            set_fog = function(density, r, g, b)
                renderer.fog_density = density
                renderer.fog_color = engine.math3d.vec3(r, g, b)
            end,

            set_gravity = function(x, y, z)
            end,

            draw_rect = function(x, y, w, h, r, g, b)
                ui:draw_rect(x, y, w, h, r, g, b)
            end,

            draw_text = function(text, x, y, size, r, g, b, a, align)
                local f = ui.font or ui.font_small
                if f then
                    f:draw_text(tostring(text or ""), x or 0, y or 0,
                        (size or 12) / f.pixel_height, r or 1, g or 1, b or 1, a or 1, align or "left")
                end
            end,

            load_font = function(name, path, size)
                local new_font = engine.Font.new({ pixel_height = size or 32.0 })
                local ok, err = pcall(function() new_font:load_from_file(path) end)
                if ok then
                    ctx["font_" .. name] = new_font
                    return new_font
                else
                    print("[MioEngine] WARNING: Failed to load font '" .. name .. "': " .. tostring(err))
                    return nil
                end
            end,

            load_shader = function(name, vert_path, frag_path)
                return shader_manager:load(name, vert_path, frag_path)
            end,

            get_shader = function(name)
                return shader_manager:get(name)
            end,

            set_entity_shader = function(ent_name, shader_name)
                local ent = scene.entities[ent_name]
                if not ent then return end
                if shader_name == nil then
                    ent.shader = nil
                else
                    local s = shader_manager:get(shader_name)
                    if s then ent.shader = s end
                end
            end,

            set_shader_uniform = function(ent_name, uname, ...)
                local ent = scene.entities[ent_name]
                if not ent then return end
                local args = {...}
                if #args == 1 then
                    ent.shader_uniforms[uname] = args[1]
                elseif #args == 3 then
                    ent.shader_uniforms[uname] = {args[1], args[2], args[3]}
                end
            end,

            reload_shader = function(name)
                return shader_manager:reload(name)
            end,

            switch_scene = function(name)
                current_scene_name = name
            end,

            key_down = function(key)
                return input:is_down(key)
            end,

            key_pressed = function(key)
                return input:is_pressed(key)
            end,

            mouse_x = function() return input.mouse_x end,
            mouse_y = function() return input.mouse_y end,
            mouse_dx = function() return input.mouse_dx end,
            mouse_dy = function() return input.mouse_dy end,
            mouse_down = function(btn) return input:mouse_down(btn) end,
            mouse_pressed = function(btn) return input:mouse_pressed(btn) end,

            print = function(...)
                print(...)
            end,
        }

        return sc
    end

    local function compile_and_run(scene_name)
        print("[MioEngine] Compiling scene:", scene_name)
        local scene = scenes[scene_name]
        if not scene then
            print("[MioEngine] ERROR: Scene not found:", scene_name)
            return 
        end
        if not scene.script then
            print("[MioEngine] ERROR: No script for scene:", scene_name)
            return
        end

        cleanup_scene(scene_name)
        active_ctx = create_scene_context(scene_name)
        setmetatable(active_ctx, { __index = _G })

        active_ctx.set_mouse = function(mode)
            if mode == "relative" then
                engine.glfw.glfwSetInputMode(win, engine.glfw.GLFW_CURSOR, engine.glfw.GLFW_CURSOR_DISABLED)
            elseif mode == "visible" then
                engine.glfw.glfwSetInputMode(win, engine.glfw.GLFW_CURSOR, engine.glfw.GLFW_CURSOR_NORMAL)
            end
        end

        active_ctx.switch_scene = function(name)
            if name ~= current_scene_name then
                current_scene_name = name
            end
        end

        active_ctx.exit_game = function()
            current_scene_name = ""
        end

        local MioLang = require("engine.lang.mio_lang")
        local miolang = MioLang.new(active_ctx)
        scene_miolangs[scene_name] = miolang

        active_ctx.camera = camera
        active_ctx.camera.x = camera.position[0]
        active_ctx.camera.y = camera.position[1]
        active_ctx.camera.z = camera.position[2]

        local ok, err = pcall(function() miolang:load(scene.script, scene_name) end)
        if not ok then
            io.stderr:write("[Script Error] " .. scene_name .. ": " .. tostring(err) .. "\n")
        else
            print("[MioEngine] Script compiled successfully")
        end
    end

    local last_scene = ""
    local first_frame = true

    local function frame()
        local dt = 1/60
        local now = engine.glfw.glfwGetTime()

        input:update()

        if input:is_pressed("f1") then
            show_debug = not show_debug
        end

        if input:is_pressed("escape") then
            if mouse_captured then
                engine.glfw.glfwSetInputMode(win, engine.glfw.GLFW_CURSOR, engine.glfw.GLFW_CURSOR_NORMAL)
                mouse_captured = false
            end
        end

        if input:mouse_pressed(0) and not mouse_captured then
            engine.glfw.glfwSetInputMode(win, engine.glfw.GLFW_CURSOR, engine.glfw.GLFW_CURSOR_DISABLED)
            mouse_captured = true
        end

        if mouse_captured then
            camera:process_keyboard(dt, input)
            local mdx, mdy = input:get_mouse_delta()
            camera:process_mouse(mdx, mdy)
        end

        if active_ctx and active_ctx.camera then
            active_ctx.camera.x = camera.position[0]
            active_ctx.camera.y = camera.position[1]
            active_ctx.camera.z = camera.position[2]
        end

        if current_scene_name ~= "" and current_scene_name ~= last_scene then
            compile_and_run(current_scene_name)
            last_scene = current_scene_name
        end

        local fb_w = ffi.new("int[1]")
        local fb_h = ffi.new("int[1]")
        engine.glfw.glfwGetFramebufferSize(win, fb_w, fb_h)
        win_w = fb_w[0]
        win_h = fb_h[0]

        renderer:begin_scene(camera, win_w, win_h)
        renderer._time = total_time

        local scene = scenes[current_scene_name]
        if scene then
            renderer:draw_entity(scene.root)
        end

        local miolang = scene_miolangs[current_scene_name]
        if miolang then
            active_ctx.dt = dt
            active_ctx.objects = active_ctx.objects or {}
            local ok, err = pcall(function() miolang:update(dt) end)
            if not ok then io.stderr:write("[Update Error] " .. tostring(err) .. "\n") end

            local key_map = {
                ["escape"] = "escape", ["w"] = "w", ["a"] = "a", ["s"] = "s", ["d"] = "d",
                ["space"] = "space", ["e"] = "e", ["r"] = "r", ["f"] = "f",
                ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5",
                ["g"] = "g", ["h"] = "h", ["t"] = "t", ["m"] = "m", ["c"] = "c",
                ["left_shift"] = "left_shift", ["right_shift"] = "right_shift",
                ["f1"] = "f1", ["f3"] = "f3",
            }
            for glfw_key, mio_key in pairs(key_map) do
                if input:is_pressed(glfw_key) then
                    local ok2, err2 = pcall(function() miolang:onKey(mio_key) end)
                    if not ok2 then io.stderr:write("[Key Error] " .. tostring(err2) .. "\n") end
                end
            end

            if input:mouse_pressed(0) then
                local ok2, err2 = pcall(function() miolang:onMouse(input.mouse_x, input.mouse_y, 0, "pressed") end)
                if not ok2 then io.stderr:write("[Mouse Error] " .. tostring(err2) .. "\n") end
            end
        end

        renderer:end_scene()

        ui:set_mouse_state(input.mouse_x, input.mouse_y, input:mouse_down(0), input:mouse_pressed(0), false)
        ui:begin(win_w, win_h)

        if miolang then
            local ok, err = pcall(function() miolang:draw() end)
            if not ok then io.stderr:write("[Draw Error] " .. tostring(err) .. "\n") end
        end

        ui:flush()

        engine.glfw.glfwSwapBuffers(win)
        engine.glfw.glfwPollEvents()

        frame_count = frame_count + 1
        total_time = total_time + dt
    end

    if current_scene_name ~= "" then
        compile_and_run(current_scene_name)
        last_scene = current_scene_name
    end

    print("[MioEngine] Entering main loop...")
    while not engine.glfw.shouldClose(win) do
        frame()
    end

    print("[MioEngine] Cleaning up...")
    audio:delete()
    renderer:delete()
    if font then font:delete() end
    if font_small then font_small:delete() end
    ui:delete()
    engine.glfw.destroy(win)
    print("[MioEngine] Done")
end

return engine