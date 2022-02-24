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

local offset_x, offset_y = 8, 4
local width_x, width_y = 40, 40

local data_path = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data'
local img

local counter = 30
local sprite_x, sprite_y = 0, 0
local anim_delay = 100

local terminal = require 'pixel.render.terminal'

local rows = vim.api.nvim_get_option 'lines'
local cols = vim.api.nvim_get_option 'columns'

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

function image:display(opts)
    local cmd = { a = 'p', i = self.id, z = 1, C = 1 }
    opts = opts or {}
    cmd = vim.tbl_deep_extend('keep', cmd, opts)
    kitty.send_cmd(cmd)
end

function image:destroy()
    kitty.send_cmd { a = 'd', i = self.id }
end

local function display_next()
    terminal.execute_at(rows - 2, 0, function()
        img:display {
            x = sprite_x * width_x + offset_x,
            y = sprite_y * width_y + offset_y,
            w = width_x,
            h = width_y,
            q = 2,
            p = 1,
        }
    end)
    sprite_x = sprite_x + 1
    sprite_x = sprite_x == 3 and 0 or sprite_x
    counter = counter - 1
    if counter > 0 then
        vim.defer_fn(display_next, anim_delay)
    else
        image:destroy()
    end
end
vim.schedule(function()
    img = image.new { src = data_path .. '/mario.png' }
    display_next()
end)
return image
