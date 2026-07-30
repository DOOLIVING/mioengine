local Camera = require("camera")
local Objects = require("objects")
local Renderer = require("renderer")

local camera
local renderer
local cube
local triangle
local floor
local staticCube
local testik
local cubes
local test
local forModel
local for2Model

function love.load()
    camera = Camera.new({ x = 0, y = 1.5, z = 0, moveSpeed = 4, mouseSensitivity = 0.0025 })
    renderer = Renderer.new({ width = 320, height = 240, fov = 200 })
    renderer:load("texture.png")

    cube = Objects.create({ model = "cube.txt", x = 0, y = 0.5, z = 5, rotSpeedX = 0.3, rotSpeedY = 0.5 })
    triangle = Objects.create({ model = "triangle.txt", x = -3, y = 0.5, z = 7, rotSpeedY = 0.4 })
    floor = Objects.create({ model = "floor.txt", x = 0, y = 0, z = 0, drawOrder = 0 })
    staticCube = Objects.create({ model = "static_cube.txt", x = 3, y = 1, z = 8, size = 1 })
    testik = Objects.create({ model = "testik.txt", x = -4, y = 0.5, z = 5, rotSpeedY = 0.3 })
    cubes = Objects.create({ model = "cubes.txt", x = 2, y = 0.5, z = 4, rotSpeedX = 0.2, rotSpeedY = 0.4 })
    test = Objects.create({ model = "test.txt", x = 4, y = 0.5, z = 6, rotSpeedY = 0.5 })
    forModel = Objects.create({ model = "for.txt", x = -2, y = 1, z = 10, size = 1.5 })
    for2Model = Objects.create({ model = "for2.txt", x = 5, y = 1, z = 10, size = 1.5 })

    love.mouse.setRelativeMode(true)
end

function love.mousemoved(x, y, dx, dy)
    camera:handleMouseMoved(dx, dy)
end

function love.update(dt)
    cube:update(dt)
    triangle:update(dt)
    testik:update(dt)
    cubes:update(dt)
    test:update(dt)
    camera:update(dt)
    camera:resolveCollisions({
        { x = staticCube.x, y = staticCube.y, z = staticCube.z, halfSize = staticCube.size },
        { x = forModel.x, y = forModel.y, z = forModel.z, halfSize = forModel.size }
    })
end

function love.mousepressed(x, y, button)
    camera:handleMousePressed(button)
end

function love.draw()
    local cubeVerts = cube:getTransformedVertices()
    local triVerts = triangle:getTransformedVertices()
    local floorVerts = floor:getTransformedVertices()
    local staticVerts = staticCube:getTransformedVertices()
    local testikVerts = testik:getTransformedVertices()
    local cubesVerts = cubes:getTransformedVertices()
    local testVerts = test:getTransformedVertices()
    local forVerts = forModel:getTransformedVertices()
    local for2Verts = for2Model:getTransformedVertices()

    local allVerts = {}
    local offsets = {}
    local offset = 0

    for _, v in ipairs(cubeVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #cubeVerts

    for _, v in ipairs(triVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #triVerts

    for _, v in ipairs(floorVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #floorVerts

    for _, v in ipairs(staticVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #staticVerts

    for _, v in ipairs(testikVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #testikVerts

    for _, v in ipairs(cubesVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #cubesVerts

    for _, v in ipairs(testVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #testVerts

    for _, v in ipairs(forVerts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset
    offset = offset + #forVerts

    for _, v in ipairs(for2Verts) do allVerts[#allVerts + 1] = v end
    offsets[#offsets + 1] = offset

    local allFaces = {}
    local allObjFaces = { cube.faces, triangle.faces, floor.faces, staticCube.faces, testik.faces, cubes.faces, test.faces, forModel.faces, for2Model.faces }

    for objIdx, objFaces in ipairs(allObjFaces) do
        for _, f in ipairs(objFaces) do
            local newIndices = {}
            for _, idx in ipairs(f.indices) do
                newIndices[#newIndices + 1] = idx + offsets[objIdx]
            end
            allFaces[#allFaces + 1] = { indices = newIndices, color = f.color, is_textured = f.is_textured, texture_file = f.texture_file, drawOrder = f.drawOrder }
        end
    end

    local projected, renderList = renderer:projectAndSort(camera, allVerts, allFaces)
    renderer:drawScene(projected, renderList, camera)
end

