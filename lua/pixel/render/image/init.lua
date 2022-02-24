local image = {}
local util = require 'pixel.util'
local kitty = require 'pixel.render.engine.kitty'
local stdin = vim.loop.new_tty(0, true)
local win_w, win_h

local img_id = 0

local MT = {
    __index = image,
    __metatable = function() end,
}

local format = { rgb = 24, argb = 32, png = 100 }

local defaults = {
    format = format.png,
}

local sprite_offset_x, sprite_offset_y = 8, 4
local sprite_w, sprite_h = 40, 40

local data_path = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data'
local img

local sprite_x, sprite_y = 0, 0
local anim_delay = 25

local terminal = require 'pixel.render.terminal'

local cols, rows = terminal.size()
local xpos, xinc = 0, 1

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
    ret.src = opts.src
    return ret
end

function image:transmit()
    local data = util.read_file(self.src)
    kitty.send_cmd({
        a = 't',
        t = 'd',
        f = 100,
        i = self.id,
        q = 2,
    }, data)
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

local animating = false
local frame_change_max, frame_change_counter, direction = 4, 0, 1
local function display_next()
    local cell_width = math.floor(win_w / cols)
    local xcell = math.floor(xpos / cell_width)
    local xoff = xpos - xcell * cell_width
    xpos = xpos + xinc
    terminal.execute_at(rows - 2, xcell + 1, function()
        img:display {
            x = sprite_offset_x + sprite_x * sprite_w,
            y = sprite_offset_y + sprite_y * sprite_h,
            w = sprite_w,
            h = sprite_h,
            q = 2,
            p = 1,
            C = 1,
            z = -1,
            X = xoff,
        }
    end)
    frame_change_counter = frame_change_counter + 1
    if frame_change_counter == frame_change_max then
        frame_change_counter = 0
        if sprite_x == 0 then
            direction = 1
        elseif sprite_x == 2 then
            direction = -1
        end
        sprite_x = sprite_x + direction
    end
    if xpos < win_w then
        vim.defer_fn(display_next, anim_delay)
    else
        image:destroy()
        animating = false
    end
end

local function discover_win_size(cb)
    if stdin then
        stdin:read_start(function(_, data)
            if data then
                local len = data:len()
                if len >= 8 and data:sub(len, len) == 't' and data:sub(1, 4) == '\x1b[4;' then
                    data = data:sub(5, len - 1)
                    len = len - 5
                    local idx = data:find ';'
                    if idx then
                        win_h, win_w = tonumber(data:sub(1, idx - 1)), tonumber(data:sub(idx + 1))
                    end
                end
            end
        end)
        terminal.write '\x1b[14t'
        vim.defer_fn(function()
            if stdin then
                stdin:read_stop()
            end
            if not win_w or not win_h then
                discover_win_size(cb)
            else
                cb()
            end
        end, 100)
    end
end

function image.its_a_meee()
    if not animating then
        animating = true
        discover_win_size(function()
            vim.schedule(function()
                img:transmit()
                xpos = 0
                display_next()
            end)
        end)
    end
end

img = image.new { src = data_path .. '/mario.png' }
return image
