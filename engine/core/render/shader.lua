local gl = require("engine.core.platform.gl")
local M = {}

function M.new(vert_src, frag_src)
    local program = gl.create_shader_program(vert_src, frag_src)
    return {
        program = program,
        uniforms = {},
    }
end

function M.use(shader)
    gl.glUseProgram(shader.program)
end

function M.set_uniform(shader, name, ...)
    local loc
    if shader.uniforms[name] then
        loc = shader.uniforms[name]
    else
        loc = gl.glGetUniformLocation(shader.program, name)
        shader.uniforms[name] = loc
    end
    if loc < 0 then return end

    local args = {...}
    local argc = #args
    if argc == 1 then
        if type(args[1]) == "number" then
            gl.glUniform1f(loc, args[1])
        else
            gl.glUniform1i(loc, args[1])
        end
    elseif argc == 3 then
        gl.glUniform3f(loc, args[1], args[2], args[3])
    elseif argc == 4 then
        gl.glUniform3f(loc, args[1], args[2], args[3])
    elseif argc == 16 or (argc == 1 and type(args[1]) == "cdata") then
        local mat = type(args[1]) == "number" and args[1] or args[1]
        gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, mat)
    end
end

function M.delete(shader)
    gl.glDeleteProgram(shader.program)
end

return M
