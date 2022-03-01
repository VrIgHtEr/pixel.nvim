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

local function next_state(char)
    if char.state == 'animating' then
        img:display {
            pos = {
                x = math.floor(char.xpos),
                y = (image.rows - 2) * image.cell_h - 1,
            },
            placement = char.p,
            z = char.z,
            crop = {
                x = char.sprite_x * sprite_w,
                y = ((char.p - 1) * 2 + (char.dir == 0 and 0 or 1)) * sprite_h,
                w = sprite_w,
                h = sprite_h,
            },
            anchor = char.dir == 0 and 3 or 2,
        }
        char.xpos = char.xpos + char.xinc
        char.frame_change_counter = char.frame_change_counter + 1
        if char.frame_change_counter == frame_change_max then
            char.frame_change_counter = 0
            if char.sprite_x == 0 then
                char.sprite_x_dir = 1
            elseif char.sprite_x == 2 then
                char.sprite_x_dir = -1
            end
            char.sprite_x = char.sprite_x + char.sprite_x_dir
        end
        if (char.dir ~= 0 or char.xpos >= image.win_w) and (char.dir == 0 or char.xpos < 0) then
            img:destroy(char.p)
            char.state = 'idle'
            return next_state(char)
        end
    elseif char.state == 'idle' then
        char.state = 'waiting'
        char.counter = math.random(25, 25 * 10)
        char.dir = 1 - char.dir
        char.xinc = char.dir == 0 and 1 or -1
        char.xpos = char.dir == 0 and (-sprite_w + 1) or (image.win_w + sprite_w - 1)
    elseif char.state == 'waiting' then
        char.counter = char.counter - 1
        if char.counter == 0 then
            char.state = 'animating'
        end
    end
end

math.randomseed(os.time())

for i = 1, math.floor(img.size.y / (sprite_h * 2)) do
    characters[i] = {
        z = -i,
        p = i,
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
