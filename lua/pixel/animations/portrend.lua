local pixel = require 'pixel'
local drawing = require 'pixel.drawing'
local world = require 'pixel.p3d.world'
local level = world.load(vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/lua/pixel/animations/portrend.txt')

local inc1, inc2, inc3 = 0.05, 0.07, 0.06
local val1, val2, val3 = 0, 0, 0

return function()
    drawing.clear(0)
    val1 = (val1 + inc1) % (math.pi * 2)
    val2 = (val2 + inc2) % (math.pi * 2)
    val3 = (val3 + inc3) % (math.pi * 2)
    level.position.y = math.sin(val1) * 4 + 10
    level.playerheight = math.sin(val2) * 5 + 10
    --    level.angle = val3
    world.render(level, pixel.cols(), pixel.rows(), function(x, y, col)
        pixel.set(y, x, col)
    end)
end
