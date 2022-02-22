local image = {}
local util = require 'pixel.util'
local kitty = require 'pixel.render.engine.kitty'

local img_id = 0

local MT = {
    __index = image,
    __metatable = function() end,
}

local format = { rgb = 24, argb = 32, png = 100 }

local defaults = {
    format = format.png,
}

function image.new(opts)
    opts = opts == nil and {} or opts
    opts = vim.tbl_deep_extend('force', defaults, opts)
    if not opts.src then
        error 'src not provided'
    end
    img_id = img_id + 1
    local ret = setmetatable({
        id = img_id,
        placements = {},
    }, MT)
    local data = util.read_file(opts.src)
    kitty.send_cmd({
        a = 't',
        t = 'd',
        f = 100,
        i = ret.id,
        q = 2,
    }, data)
    return ret
end

function image:display()
    kitty.send_cmd { a = 'p', i = self.id, z = 1, C = 1 }
end

function image:destroy()
    kitty.send_cmd { a = 'd', i = self.id }
end

local img = image.new { src = '/home/cedric/dice.png' }
vim.defer_fn(function()
    img:display()
end, 1000)
vim.defer_fn(function()
    img:destroy()
end, 2000)
return image
