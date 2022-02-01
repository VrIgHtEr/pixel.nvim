local pixel = require 'pixel'
local drawing = require 'pixel.drawing'
local colors = require 'pixel.color'

local function velocityvector()
    local scaling = 0.025
    return { x = (math.random() * -0.5) * 2 * scaling, y = (math.random() * -0.5) * 2 * scaling }
end

local vertices = {
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(255, 0, 0) },
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(0, 255, 0) },
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(0, 0, 255) },
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(255, 255, 0) },
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(0, 255, 255) },
    { pos = { x = math.random(), y = math.random() }, vel = velocityvector(), color = colors.rgb_to_int(255, 0, 255) },
}

local function update_vertex(v)
    v.pos.x = v.pos.x + v.vel.x
    if v.pos.x < 0 then
        v.pos.x = -v.pos.x
        v.vel.x = -v.vel.x
    end
    if v.pos.x > 1 then
        v.pos.x = 2 - v.pos.x
        v.vel.x = -v.vel.x
    end
    v.pos.y = v.pos.y + v.vel.y
    if v.pos.y < 0 then
        v.pos.y = -v.pos.y
        v.vel.y = -v.vel.y
    end
    if v.pos.y > 1 then
        v.pos.y = 2 - v.pos.y
        v.vel.y = -v.vel.y
    end
end

return function()
    drawing.clear()
    for _, x in ipairs(vertices) do
        update_vertex(x)
    end
    for i, x in ipairs(vertices) do
        local j
        if i == 1 then
            j = #vertices
        else
            j = i - 1
        end
        local a, b = vertices[j], x
        drawing.line(
            a.pos.x * (pixel.cols() - 1) + 1,
            a.pos.y * (pixel.rows() - 1) + 1,
            b.pos.x * (pixel.cols() - 1) + 1,
            b.pos.y * (pixel.rows() - 1) + 1,
            a.color
        )
    end
end
