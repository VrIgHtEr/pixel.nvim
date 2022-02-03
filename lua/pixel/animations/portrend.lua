local pixel = require 'pixel'
local world = require 'pixel.util.geometry.world'
local level = world.load(vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/map2.txt')
return function()
    world.render(level, pixel.cols(), pixel.rows(), function(x, y, col)
        pixel.set(y, x, col)
    end)
end
