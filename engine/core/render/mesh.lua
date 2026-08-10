local ffi = require("ffi")
local gl = require("engine.core.platform.gl")
local assimp = require("engine.core.render.assimp")
local math3d = require("engine.core.math")
local M = {}

function M.new()
    return {
        vao = 0, vbo = 0, ebo = 0,
        vertex_count = 0,
        has_normals = false,
        has_uvs = false,
        name = "",
        material_index = 0,
    }
end

local function compute_normals(vertices, indices)
    local normals = {}
    for i = 1, #vertices do
        normals[i] = { 0, 0, 0 }
    end
    for i = 1, #indices, 3 do
        local i0 = indices[i] + 1
        local i1 = indices[i + 1] + 1
        local i2 = indices[i + 2] + 1
        local v0, v1, v2 = vertices[i0], vertices[i1], vertices[i2]
        local e1 = { v1[1] - v0[1], v1[2] - v0[2], v1[3] - v0[3] }
        local e2 = { v2[1] - v0[1], v2[2] - v0[2], v2[3] - v0[3] }
        local nx = e1[2] * e2[3] - e1[3] * e2[2]
        local ny = e1[3] * e2[1] - e1[1] * e2[3]
        local nz = e1[1] * e2[2] - e1[2] * e2[1]
        for _, idx in ipairs({ i0, i1, i2 }) do
            normals[idx][1] = normals[idx][1] + nx
            normals[idx][2] = normals[idx][2] + ny
            normals[idx][3] = normals[idx][3] + nz
        end
    end
    for i = 1, #normals do
        local n = normals[i]
        local len = math.sqrt(n[1] * n[1] + n[2] * n[2] + n[3] * n[3])
        if len > 1e-8 then
            n[1] = n[1] / len
            n[2] = n[2] / len
            n[3] = n[3] / len
        else
            n[1], n[2], n[3] = 0, 1, 0
        end
    end
    return normals
end

function M.create_from_data(vertices, normals, uvs, indices)
    local mesh = M.new()
    mesh.vertex_count = #indices

    if not normals or #normals == 0 then
        normals = compute_normals(vertices, indices)
    end

    local vao = ffi.new("GLuint[1]")
    local vbo = ffi.new("GLuint[1]")
    local ebo = ffi.new("GLuint[1]")
    gl.glGenVertexArrays(1, vao)
    gl.glGenBuffers(1, vbo)
    gl.glGenBuffers(1, ebo)

    mesh.vao = vao[0]
    mesh.vbo = vbo[0]
    mesh.ebo = ebo[0]

    local has_n = true
    local has_uv = uvs and #uvs > 0
    local floats_per_vert = 3 + 3 + (has_uv and 2 or 0)

    local vert_data = ffi.new("float[?]", #indices * floats_per_vert)
    local idx = 0
    for _, fi in ipairs(indices) do
        local v = vertices[fi + 1]
        vert_data[idx] = v[1]; idx = idx + 1
        vert_data[idx] = v[2]; idx = idx + 1
        vert_data[idx] = v[3]; idx = idx + 1
        local n = normals[fi + 1]
        vert_data[idx] = n[1]; idx = idx + 1
        vert_data[idx] = n[2]; idx = idx + 1
        vert_data[idx] = n[3]; idx = idx + 1
        if has_uv then
            local uv = uvs[fi + 1] or { 0, 0 }
            vert_data[idx] = uv[1]; idx = idx + 1
            vert_data[idx] = uv[2]; idx = idx + 1
        end
    end

    local gl_indices = ffi.new("uint32_t[?]", #indices)
    for i = 1, #indices do
        gl_indices[i - 1] = i - 1
    end

    gl.glBindVertexArray(mesh.vao)

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, mesh.vbo)
    gl.glBufferData(gl.GL_ARRAY_BUFFER, ffi.sizeof(vert_data), vert_data, gl.GL_STATIC_DRAW)

    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, ffi.sizeof(gl_indices), gl_indices, gl.GL_STATIC_DRAW)

    local stride = floats_per_vert * 4
    local offset = 0

    gl.glEnableVertexAttribArray(0)
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", offset))
    offset = offset + 12

    mesh.has_normals = has_n
    gl.glEnableVertexAttribArray(1)
    gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", offset))
    offset = offset + 12

    if has_uv then
        mesh.has_uvs = true
        gl.glEnableVertexAttribArray(2)
        gl.glVertexAttribPointer(2, 2, gl.GL_FLOAT, gl.GL_FALSE, stride, ffi.cast("void*", offset))
    end

    gl.glBindVertexArray(0)

    return mesh
end

local function mesh_from_ai(ai_mesh, label, scene, material_cache)
    local verts = assimp.get_mesh_vertices(ai_mesh)
    local norms = assimp.get_mesh_normals(ai_mesh)
    local ai_faces = assimp.get_mesh_faces(ai_mesh)
    local uvs = assimp.get_mesh_texture_coords(ai_mesh)

    local indices = {}
    for _, face in ipairs(ai_faces) do
        for _, face_idx in ipairs(face) do
            indices[#indices + 1] = face_idx
        end
    end

    if #indices == 0 then
        return nil
    end

    local m = M.create_from_data(verts, norms, uvs, indices)
    m.name = label or "mesh"
    m.material_index = assimp.get_mesh_material_index(ai_mesh)

    if scene and m.material_index and m.material_index >= 0 then
        local cache_key = tostring(m.material_index)
        if material_cache and material_cache[cache_key] then
            m.texture = material_cache[cache_key]
        else
            local tex_path = assimp.get_material_diffuse_texture(scene, m.material_index)
            if tex_path and tex_path ~= "" then
                local ok, tex = pcall(require("engine.core.render.texture").load, tex_path)
                if ok and tex then
                    m.texture = tex
                    if material_cache then material_cache[cache_key] = tex end
                end
            end
        end
    end

    return m
end

function M.load_scene_with_node(path, SceneNode)
    local scene = assimp.load_file(path)
    local root_ai = assimp.get_root_node(scene)
    local material_cache = {}
    
    local function build_node(ai_node, name_prefix)
        local node_name = assimp.ai_string_to_lua(ai_node.mName)
        if node_name == "" then
            node_name = name_prefix .. "_node"
        end

        local node = SceneNode.new(node_name)
        node.local_matrix = assimp.matrix_to_mat4(ai_node.mTransformation)

        local raw_verts = {}
        for i = 0, ai_node.mNumMeshes - 1 do
            local mesh_index = ai_node.mMeshes[i]
            local ai_mesh = assimp.get_mesh(scene, mesh_index)
            local m = mesh_from_ai(ai_mesh, node_name .. "#" .. mesh_index, scene, material_cache)
            if m then
                node.meshes[#node.meshes + 1] = m
                if m.texture and not node.texture then
                    node.texture = m.texture
                end
            end
            local nverts = ai_mesh.mNumVertices
            local ptr = ai_mesh.mVertices
            for j = 0, nverts - 1 do
                raw_verts[#raw_verts + 1] = { ptr[j].x, ptr[j].y, ptr[j].z }
            end
        end
        if #raw_verts > 0 then
            node._raw_vertices = raw_verts
        end

        for i = 0, ai_node.mNumChildren - 1 do
            local child = build_node(ai_node.mChildren[i], name_prefix .. "_c" .. i)
            node:add_child(child)
        end

        return node
    end
    
    local root = build_node(root_ai, path:match("([^/]+)$") or "model")

    local function mul4(a, b)
        return math3d.mat4_multiply(a, b)
    end

    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge

    local function walk_bounds(node, parent_mat)
        local lm = node.local_matrix
        local world_mat = lm and mul4(parent_mat, lm) or parent_mat
        local raw = node._raw_vertices
        if raw then
            for i = 1, #raw do
                local v = raw[i]
                local wx = world_mat[0]*v[1]+world_mat[4]*v[2]+world_mat[8]*v[3]+world_mat[12]
                local wy = world_mat[1]*v[1]+world_mat[5]*v[2]+world_mat[9]*v[3]+world_mat[13]
                local wz = world_mat[2]*v[1]+world_mat[6]*v[2]+world_mat[10]*v[3]+world_mat[14]
                if wx < min_x then min_x = wx end
                if wy < min_y then min_y = wy end
                if wz < min_z then min_z = wz end
                if wx > max_x then max_x = wx end
                if wy > max_y then max_y = wy end
                if wz > max_z then max_z = wz end
            end
        end
        for _, child in ipairs(node.children) do
            walk_bounds(child, world_mat)
        end
    end

    local id4 = math3d.mat4_identity()
    walk_bounds(root, id4)

    if min_x < math.huge then
        local cx = (min_x + max_x) / 2
        local cy = (min_y + max_y) / 2
        local cz = (min_z + max_z) / 2
        local max_dim = math.max(max_x - min_x, max_y - min_y, max_z - min_z)
        if max_dim < 0.001 then max_dim = 1 end
        local ns = 10.0 / max_dim

        local norm = math3d.mat4()
        norm[0]  = ns
        norm[5]  = ns
        norm[10] = ns
        norm[12] = -cx * ns
        norm[13] = -cy * ns
        norm[14] = -cz * ns
        norm[15] = 1

        if root.local_matrix then
            root.local_matrix = math3d.mat4_multiply(norm, root.local_matrix)
        else
            root.local_matrix = norm
        end
    end

    local function cleanup_raw(node)
        node._raw_vertices = nil
        for _, child in ipairs(node.children) do
            cleanup_raw(child)
        end
    end
    cleanup_raw(root)

    assimp.release(scene)
    return root
end

function M.load_scene(path)
    local SceneNode = require("engine.core.scene.scene_graph")
    return M.load_scene_with_node(path, SceneNode)
end

function M.load(path)
    local root = M.load_scene(path)
    local meshes = {}
    local function collect(n)
        for _, m in ipairs(n.meshes) do
            meshes[#meshes + 1] = m
        end
        for _, c in ipairs(n.children) do
            collect(c)
        end
    end
    collect(root)
    return meshes, root
end

function M.draw(mesh)
    gl.glBindVertexArray(mesh.vao)
    if mesh.ebo and mesh.ebo ~= 0 then
        gl.glDrawElements(gl.GL_TRIANGLES, mesh.vertex_count, gl.GL_UNSIGNED_INT, ffi.cast("void*", 0))
    else
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, mesh.vertex_count)
    end
    gl.glBindVertexArray(0)
end

function M.delete(mesh)
    if mesh.vao and mesh.vao ~= 0 then
        gl.glDeleteVertexArrays(1, ffi.new("GLuint[1]", mesh.vao))
    end
    if mesh.vbo and mesh.vbo ~= 0 then
        gl.glDeleteBuffers(1, ffi.new("GLuint[1]", mesh.vbo))
    end
    if mesh.ebo and mesh.ebo ~= 0 then
        gl.glDeleteBuffers(1, ffi.new("GLuint[1]", mesh.ebo))
    end
end

return M