local pixel = require 'pixel'
local drawing = require 'pixel.drawing'
local world = require 'pixel.util.geometry.world'
local level = world.load(vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/map2.txt')

local inc = 0.05
local val = 0

return function()
    drawing.clear(0)
    val = (val + inc) % (math.pi * 2)
    level.position.y = math.sin(val) * 2.5 + 6
    world.render(level, pixel.cols(), pixel.rows(), function(x, y, col)
        pixel.set(y, x, col)
    end)
end
