local ffi = require("ffi")

ffi.cdef[[
typedef unsigned int aiReturn;
typedef unsigned int ai_uint32;

typedef struct aiString { unsigned int length; char data[1024]; } aiString;
typedef struct aiVector3D { float x, y, z; } aiVector3D;
typedef struct aiColor4D { float r, g, b, a; } aiColor4D;

typedef struct aiMatrix4x4 {
    float a1, a2, a3, a4;
    float b1, b2, b3, b4;
    float c1, c2, c3, c4;
    float d1, d2, d3, d4;
} aiMatrix4x4;

typedef struct aiFace {
    unsigned int mNumIndices;
    unsigned int* mIndices;
} aiFace;

typedef struct aiNode aiNode;

typedef struct aiMesh {
    unsigned int mPrimitiveTypes;
    unsigned int mNumVertices;
    unsigned int mNumFaces;
    aiVector3D* mVertices;
    aiVector3D* mNormals;
    aiVector3D* mTangents;
    aiVector3D* mBitangents;
    aiColor4D* mColors[8];
    aiVector3D* mTextureCoords[8];
    unsigned int mNumUVComponents[8];
    aiFace* mFaces;
    unsigned int mNumBones;
    void** mBones;
    unsigned int mMaterialIndex;
} aiMesh;

typedef struct aiNode {
    aiString mName;
    aiMatrix4x4 mTransformation;
    aiNode* mParent;
    unsigned int mNumChildren;
    aiNode** mChildren;
    unsigned int mNumMeshes;
    unsigned int* mMeshes;
    void* mMetaData;
} aiNode;

typedef struct aiScene {
    unsigned int mFlags;
    aiNode* mRootNode;
    unsigned int mNumMeshes;
    aiMesh** mMeshes;
    unsigned int mNumMaterials;
    void** mMaterials;
    unsigned int mNumAnimations;
    void* mAnimations;
    unsigned int mNumTextures;
    void* mTextures;
    unsigned int mNumLights;
    void* mLights;
    unsigned int mNumCameras;
    void* mCameras;
} aiScene;

typedef struct aiPropertyStore { char dummy[512]; } aiPropertyStore;

const aiScene* aiImportFile(const char* pFile, unsigned int pFlags);
const aiScene* aiImportFileExWithProperties(const char* pFile, unsigned int pFlags, void* pProv, const aiPropertyStore* pStore);
void aiReleaseImport(const aiScene* pScene);
const char* aiGetErrorString(void);

typedef struct aiMaterial {
    void** mProperties;
    unsigned int mNumProperties;
    unsigned int mNumAllocated;
} aiMaterial;

typedef struct aiMaterialProperty {
    aiString mKey;
    unsigned int mSemantic;
    unsigned int mIndex;
    unsigned int mType;
    unsigned int mDataLength;
    char* mData;
} aiMaterialProperty;

unsigned int aiGetMaterialProperty(const void* pMat, const char* pKey, unsigned int pType, unsigned int pIndex, void** pPropOut);
]]

local Platform = require("engine.core.platform.platform")
local lib = Platform.try_load("assimp")
if not lib then error("Failed to load Assimp library") end

local M = {}
M.lib = lib

M.AI_POSTPROCESS = {
    CALC_TANGENT_SPACE       = 0x1,
    JOIN_IDENTICAL_VERTICES  = 0x2,
    TRIANGULATE              = 0x8,
    GEN_NORMALS              = 0x20,
    GEN_SMOOTH_NORMALS       = 0x40,
    IMPROVE_CACHE_LOCALITY   = 0x800,
    SORT_BY_PTYPE            = 0x8000,
    FLIP_UV                  = 0x800000,
}

M.AI_TEXTURE_TYPE = {
    NONE         = 0,
    DIFFUSE      = 1,
    SPECULAR     = 2,
    AMBIENT      = 3,
    EMISSIVE     = 4,
    HEIGHT       = 5,
    NORMALS      = 6,
    SHININESS    = 7,
    OPACITY      = 8,
    DISPLACEMENT = 9,
    LIGHTMAP     = 10,
    REFLECTION   = 11,
    BASE_COLOR   = 12,
    NORMAL_CAMERA = 13,
    EMISSION_COLOR = 14,
    METALNESS    = 15,
    DIFFUSE_ROUGHNESS = 16,
    AMBIENT_OCCLUSION = 17,
}

function M.default_flags()
    return M.AI_POSTPROCESS.TRIANGULATE +
           M.AI_POSTPROCESS.JOIN_IDENTICAL_VERTICES +
           M.AI_POSTPROCESS.GEN_SMOOTH_NORMALS +
           M.AI_POSTPROCESS.CALC_TANGENT_SPACE +
           M.AI_POSTPROCESS.IMPROVE_CACHE_LOCALITY +
           M.AI_POSTPROCESS.SORT_BY_PTYPE +
           M.AI_POSTPROCESS.FLIP_UV
end

function M.load_file(path, flags)
    local pp = flags or M.default_flags()
    local scene = lib.aiImportFile(path, pp)
    if scene == nil then
        local err = lib.aiGetErrorString()
        error("Failed to load model: " .. path .. "\n" .. ffi.string(err))
    end
    return scene
end

function M.release(scene)
    lib.aiReleaseImport(scene)
end

function M.ai_string_to_lua(s)
    local len = math.min(s.length, 1023)
    if len == 0 then return "" end
    return ffi.string(s.data, len)
end

function M.matrix_to_mat4(m)
    local math3d = require("engine.core.math")
    local out = math3d.mat4()
    out[0]  = m.a1; out[1]  = m.b1; out[2]  = m.c1; out[3]  = m.d1
    out[4]  = m.a2; out[5]  = m.b2; out[6]  = m.c2; out[7]  = m.d2
    out[8]  = m.a3; out[9]  = m.b3; out[10] = m.c3; out[11] = m.d3
    out[12] = m.a4; out[13] = m.b4; out[14] = m.c4; out[15] = m.d4
    return out
end

function M.get_root_node(scene)
    return scene.mRootNode
end

function M.get_mesh(scene, index)
    return scene.mMeshes[index]
end

function M.get_mesh_vertices(mesh)
    local verts = {}
    local n = mesh.mNumVertices
    local ptr = mesh.mVertices
    for i = 0, n - 1 do
        verts[i + 1] = { ptr[i].x, ptr[i].y, ptr[i].z }
    end
    return verts
end

function M.get_mesh_normals(mesh)
    local normals = {}
    local n = mesh.mNumVertices
    if mesh.mNormals ~= nil then
        local ptr = mesh.mNormals
        for i = 0, n - 1 do
            normals[i + 1] = { ptr[i].x, ptr[i].y, ptr[i].z }
        end
    end
    return normals
end

function M.get_mesh_faces(mesh)
    local faces = {}
    local n = mesh.mNumFaces
    local ptr = mesh.mFaces
    for i = 0, n - 1 do
        local f = {}
        for j = 0, ptr[i].mNumIndices - 1 do
            f[j + 1] = ptr[i].mIndices[j]
        end
        faces[i + 1] = f
    end
    return faces
end

function M.get_mesh_texture_coords(mesh)
    local uvs = {}
    local n = mesh.mNumVertices
    if mesh.mTextureCoords[0] ~= nil then
        local ptr = mesh.mTextureCoords[0]
        for i = 0, n - 1 do
            uvs[i + 1] = { ptr[i].x, ptr[i].y }
        end
    end
    return uvs
end

function M.get_mesh_material_index(mesh)
    return mesh.mMaterialIndex
end

function M.get_material_texture_path(scene, material_index, texture_type)
    if material_index < 0 then return nil end
    local mat = scene.mMaterials[material_index]
    if mat == nil then return nil end
    local prop = ffi.new("void*[1]")
    local key = "$tex.file"
    local ok = lib.aiGetMaterialProperty(mat, key, texture_type, 0, prop)
    if ok ~= 0 or prop[0] == nil then return nil end
    local prop_ptr = ffi.cast("aiMaterialProperty*", prop[0])
    if prop_ptr.mDataLength == 0 then return nil end
    local str_ptr = ffi.cast("aiString*", prop_ptr.mData)
    return M.ai_string_to_lua(str_ptr)
end

function M.get_material_diffuse_texture(scene, material_index)
    return M.get_material_texture_path(scene, material_index, M.AI_TEXTURE_TYPE.DIFFUSE)
end

return M
