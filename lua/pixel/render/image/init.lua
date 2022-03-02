local image = {}
local stdin = vim.loop.new_tty(0, true)
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

local terminal = require 'pixel.render.terminal'

function image.new(opts)
    opts = opts == nil and {} or opts
    opts = vim.tbl_deep_extend('force', defaults, opts)
    if not opts.src then
        error 'src not provided'
    end
    img_id = img_id + 1
    return setmetatable({
        id = img_id,
        placements = {},
        placement_ids = {},
        last_placement_id = 0,
        src = opts.src,
    }, MT)
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

    if opts.placement ~= nil then
        if type(opts.placement) ~= 'number' then
            return util.error('placement', 'TYPE', type(opts.placement))
        end
        if opts.placement < 1 then
            return util.error('placement', 'VALUE', opts.placement)
        end
        opts.placement = math.floor(opts.placement)
    end

    if opts.z ~= nil then
        if type(opts.z) ~= 'number' then
            return util.error('placement', 'TYPE', type(opts.z))
        end
        opts.z = math.floor(opts.z)
    end

    return opts
end

function image:display(opts)
    local cmd = { a = 'p', i = self.id, C = 1, q = 2 }
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

    local top = opts.anchor > 1 and (opts.pos.y - opts.crop.h + 1) or opts.pos.y
    local left = (opts.anchor == 1 or opts.anchor == 2) and (opts.pos.x - opts.crop.w + 1) or opts.pos.x
    local bottom, right = top + opts.crop.w, left + opts.crop.h

    if left < 0 then
        if -left >= opts.crop.w then
            return true
        end
        opts.crop.x, opts.crop.w, left = opts.crop.x - left, opts.crop.w + left, 0
    elseif left >= image.win_w or right <= 0 then
        return true
    end
    if top < 0 then
        if -top >= opts.crop.h then
            return true
        end
        opts.crop.y, opts.crop.h, top = opts.crop.y - top, opts.crop.h + top, 0
    elseif top >= image.win_h or bottom <= 0 then
        return true
    end

    if bottom > image.win_h then
        opts.crop.h = opts.crop.h - (bottom - image.win_h)
    end
    if right > image.win_w then
        opts.crop.w = opts.crop.w - (right - image.win_w)
    end

    local xcell, ycell = math.floor(left / image.cell_w), math.floor(top / image.cell_h)
    cmd.X, cmd.Y = left % image.cell_w, top % image.cell_h
    cmd.x, cmd.y, cmd.w, cmd.h = opts.crop.x, opts.crop.y, opts.crop.w, opts.crop.h
    cmd.p = opts.placement
    cmd.z = opts.z
    terminal.execute_at(ycell + 1, xcell + 1, function()
        kitty.send_cmd(cmd)
    end)
    return true
end

function image:hide(p)
    local cmd = { a = 'd', i = self.id }
    if type(p) == 'number' then
        cmd.p = p
    end
    kitty.send_cmd(cmd)
end

function image:create_placement()
    local placement_id
    local active = true
    local hidden = true
    if #self.placement_ids > 0 then
        placement_id = table.remove(self.placement_ids)
    else
        self.last_placement_id = self.last_placement_id + 1
        placement_id = self.last_placement_id
    end
    if not self.placements[placement_id] then
        self.placements[placement_id] = 1
    else
        self.placements[placement_id] = self.placements[placement_id] + 1
    end
    local placement = {}
    function placement.display(opts)
        if active then
            opts.placement = placement_id
            self:display(opts)
            hidden = false
        end
    end
    function placement.hide()
        if active then
            if not hidden then
                self:hide(placement_id)
                hidden = true
            end
        end
    end
    function placement.destroy()
        if active then
            placement.hide()
            self.placements[placement_id] = self.placements[placement_id] - 1
            if self.placements[placement_id] == 0 then
                self.placements[placement_id] = nil
                table.insert(self.placement_ids, placement_id)
            end
            active = false
        end
    end
    return placement
end

function image.discover_win_size(cb)
    if stdin then
        stdin:read_start(function(_, data)
            if data then
                local len = data:len()
                if len >= 8 and data:sub(len, len) == 't' and data:sub(1, 4) == '\x1b[4;' then
                    data = data:sub(5, len - 1)
                    len = len - 5
                    local idx = data:find ';'
                    if idx then
                        image.win_h, image.win_w, image.cols, image.rows = tonumber(data:sub(1, idx - 1)), tonumber(data:sub(idx + 1)), terminal.size()
                        image.cell_w, image.cell_h = math.floor(image.win_w / image.cols), math.floor(image.win_h / image.rows)
                        image.win_h, image.win_w = image.cell_h * image.rows, image.cell_w * image.cols
                    end
                end
            end
        end)
        terminal.write '\x1b[14t'
        vim.defer_fn(function()
            if stdin then
                stdin:read_stop()
            end
            if not image.win_w or not image.win_h then
                image.discover_win_size(cb)
            else
                cb()
            end
        end, 100)
    end
end

return image
