local mario = {}
local image = require 'pixel.render.image'
local img = image.new { src = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/mario.png' }
img.size = { x = 96, y = 128 }
img:transmit()
local anim_delay = 40
local started = false

local sprite_w, sprite_h = 32, 32

local characters = {}
local frame_change_max = 4

local function next_state(c)
    if c.state == 'animating' then
        c.xpos = c.xpos + c.xinc
        c.frame_change_counter = c.frame_change_counter + 1
        if c.frame_change_counter == frame_change_max then
            c.frame_change_counter = 0
            if c.sprite_x == 0 then
                c.sprite_x_dir = 1
            elseif c.sprite_x == 2 then
                c.sprite_x_dir = -1
            end
            c.sprite_x = c.sprite_x + c.sprite_x_dir
        end
        c.placement.display {
            pos = {
                x = math.floor(c.xpos),
                y = (image.rows - 2) * image.cell_h - 1,
            },
            z = c.z,
            crop = {
                x = c.sprite_x * sprite_w,
                y = ((c.p - 1) * 2 + (c.dir == 0 and 0 or 1)) * sprite_h,
                w = sprite_w,
                h = sprite_h,
            },
            anchor = c.dir == 0 and 3 or 2,
        }
        if (c.dir ~= 0 or c.xpos >= image.win_w) and (c.dir == 0 or c.xpos < 0) then
            c.placement.hide()
            c.state = 'idle'
            return next_state(c)
        end
    elseif c.state == 'idle' then
        c.state = 'waiting'
        c.counter = math.random(25, 25 * 156)
        c.dir = 1 - c.dir
        c.xinc = c.dir == 0 and 1 or -1
        c.xpos = c.dir == 0 and -sprite_w or (image.win_w + sprite_w)
    elseif c.state == 'waiting' then
        c.counter = c.counter - 1
        if c.counter == 0 then
            c.state = 'animating'
        end
    end
end

for i = 1, math.floor(img.size.y / (sprite_h * 2)) do
    characters[i] = {
        z = -i,
        p = i,
        placement = img:create_placement(),
        state = 'idle',
        xpos = 0,
        xinc = 0,
        dir = math.random(0, 1),
        sprite_x_dir = 1,
        sprite_x = 0,
        frame_change_counter = 0,
    }
end

function mario.its_a_meee()
    vim.schedule(mario.lets_a_gooo)
end

local terminal = require 'pixel.render.terminal'
local function display_next()
    if started then
        terminal.begin_transaction()
        for _, char in ipairs(characters) do
            next_state(char)
        end
        terminal.end_transaction()
        vim.defer_fn(display_next, anim_delay)
    end
end

function mario.lets_a_gooo()
    if not started then
        started = true
        image.discover_win_size(function()
            vim.schedule(function()
                display_next()
            end)
        end)
    end
end

return mario
