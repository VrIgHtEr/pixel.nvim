local image = {}
local util = require 'pixel.util'
local kitty = require 'pixel.render.engine.kitty'
local stdin = vim.loop.new_tty(0, true)

local img_id = 0

local MT = {
    __index = image,
    __metatable = function() end,
}

local format = { rgb = 24, argb = 32, png = 100 }

local defaults = {
    format = format.png,
}

local data_path = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data'
local img

local sprite_x, sprite_y = 0, 0
local anim_delay = 25

local terminal = require 'pixel.render.terminal'

local cols, rows, cell_w, cell_h, win_h, win_w
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

local function validate_opts(self, opts)
    opts = opts == nil and {} or opts

    if type(opts) ~= 'table' then
        return util.error('TYPE', type(opts))
    end

    for _, v in pairs(kitty.constants.control_keys) do
        if opts[v] ~= nil then
            return util.error('DISALLOWED', v)
        end
    end

    if opts.pos ~= nil and type(opts.pos) ~= 'table' then
        return util.error('pos', 'TYPE', type(opts.pos))
    end
    opts.pos = opts.pos and opts.pos or { x = 0, y = 0 }

    if type(opts.pos.x) ~= 'number' then
        return util.error('pos.x', 'TYPE', type(opts.pos.x))
    end

    if type(opts.pos.y) ~= 'number' then
        return util.error('pos.y', 'TYPE', type(opts.pos.y))
    end

    opts.crop = opts.crop == nil and {} or opts.crop
    if type(opts.crop) ~= 'table' then
        return util.error('crop', 'TYPE', type(opts.crop))
    end

    opts.crop.x = opts.crop.x == nil and 0 or opts.crop.x
    if type(opts.crop.x) ~= 'number' then
        return util.error('crop.x', 'TYPE', type(opts.crop.x))
    end

    opts.crop.y = opts.crop.y == nil and 0 or opts.crop.y
    if type(opts.crop.y) ~= 'number' then
        return util.error('crop.y', 'TYPE', type(opts.crop.y))
    end

    if opts.crop.w ~= nil and type(opts.crop.w) ~= 'number' then
        return util.error('crop.w', 'TYPE', type(opts.crop.w))
    end
    opts.crop.w = opts.crop.w == nil and self.size.x - opts.pos.x or opts.crop.w

    if opts.crop.h ~= nil and type(opts.crop.h) ~= 'number' then
        return util.error('crop.h', 'TYPE', type(opts.crop.h))
    end
    opts.crop.h = opts.crop.h == nil and self.size.y - opts.pos.y or opts.crop.h

    if opts.crop.x < 0 or opts.crop.x >= self.size.x then
        return util.error('crop.x', 'VALUE', opts.crop.x)
    end

    if opts.crop.y < 0 or opts.crop.y >= self.size.y then
        return util.error('crop.y', 'VALUE', opts.crop.y)
    end

    if opts.crop.w < 0 or self.size.x - opts.crop.x < opts.crop.w then
        return util.error('crop.w', 'VALUE', opts.crop.w)
    end

    if opts.crop.h < 0 or (self.size.y - opts.crop.y) < opts.crop.h then
        return util.error('crop.h', 'VALUE', opts.crop.h)
    end

    opts.anchor = opts.anchor == nil and 0 or opts.anchor
    if type(opts.anchor) ~= 'number' then
        return util.error('anchor', 'TYPE', type(opts.anchor))
    end
    if opts.anchor < 0 or opts.anchor >= 4 then
        return util.error('anchor', 'VALUE', opts.anchor)
    end
    opts.anchor = math.floor(opts.anchor)

    do
        local args, err = kitty.validate(opts.args)
        if not args then
            return util.error('args', err)
        end
        opts.args = args
    end

    return opts
end

function image:display(opts)
    local cmd = { a = 'p', i = self.id, z = -1, C = 1, q = 2 }
    do
        local e
        opts, e = validate_opts(self, opts)
        if not opts then
            return nil, e
        end
    end
    if opts.crop.w == 0 or opts.crop.h == 0 then
        return true
    end
    local xcell, ycell = math.floor(opts.pos.x / cell_w), math.floor(opts.pos.y / cell_h)
    if opts.anchor > 1 then
        local y = self.size.y
        while y > cell_h do
            ycell, y = ycell - 1, y - cell_h
        end
        cmd.Y = cell_h - y
    end
    if opts.anchor == 1 or opts.anchor == 2 then
        local x = self.size.x
        while x > cell_w do
            xcell, x = xcell - 1, x - cell_w
        end
        cmd.X = cell_w - x
    end
    cmd.x = opts.crop.x
    cmd.y = opts.crop.y
    cmd.w = opts.crop.w
    cmd.h = opts.crop.h
    if opts.args then
        vim.tbl_extend('keep', cmd, opts.args)
    end
    terminal.execute_at(ycell + 1, xcell + 1, function()
        kitty.send_cmd(cmd)
    end)
    return true
end

function image:destroy()
    kitty.send_cmd { a = 'd', i = self.id }
end

local animating = false
local frame_change_max, frame_change_counter, direction = 4, 0, 1
function image.lets_a_gooo()
    vim.defer_fn(image.its_a_meee, (math.random(120) - 1 + 60 * 4) * 1000)
end

local function display_next()
    local success, err = img:display {
        pos = {
            x = math.floor(xpos),
            y = (rows - 3) * cell_h,
        },
        crop = { x = sprite_x * 16, y = sprite_y * 16, w = 16, h = 16 },
        anchor = 3,
        args = { p = 1 },
    }
    if not success then
        print(err)
    end
    xpos = xpos + xinc
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
        image.lets_a_gooo()
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
                        win_h, win_w, cols, rows = tonumber(data:sub(1, idx - 1)), tonumber(data:sub(idx + 1)), terminal.size()
                        cell_w, cell_h = math.floor(win_w / cols), math.floor(win_h / rows)
                        win_h, win_w = cell_h * rows, cell_w * cols
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
img.size = { x = 48, y = 32 }
return image
