local pixel = require 'pixel'
local drawing = require 'pixel.drawing'
local world = require 'pixel.util.geometry.world'
local level = world.load(vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/map2.txt')

local inc1, inc2 = 0.05, 0.07
local val1, val2 = 0, 0

return function()
    drawing.clear(0)
    val1 = (val1 + inc1) % (math.pi * 2)
    val2 = (val2 + inc2) % (math.pi * 2)
    level.position.y = math.sin(val1) * 4 + 10
    level.playerheight = math.sin(val2) * 5 + 10
    world.render(level, pixel.cols(), pixel.rows(), function(x, y, col)
        pixel.set(y, x, col)
    end)
end
