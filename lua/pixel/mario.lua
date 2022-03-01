local mario = {}
local data_path = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data'
local image = require 'pixel.render.image'
local img = image.new { src = data_path .. '/mario.png' }
img.size = { x = 96, y = 128 }
img:transmit()
local anim_delay = 25

local sprite_w, sprite_h = 32, 32

local character_rows = math.floor(img.size.y / (sprite_h * 2))
local xpos, xinc = 0, 1
local character_dir = {}
local character = nil
local frame_change_max, frame_change_counter, sprite_x_dir = 4, 0, 1
local animating = false

function mario.its_a_meee()
    vim.defer_fn(mario.lets_a_gooo, math.random(10) * 1000)
end

local sprite_x = 0

local function display_next()
    local success, err = img:display {
        pos = {
            x = math.floor(xpos),
            y = (image.rows - 2) * image.cell_h - 1,
        },
        placement = 1,
        z = -1,
        crop = {
            x = sprite_x * sprite_w,
            y = ((character - 1) * 2 + (character_dir[character] == 0 and 0 or 1)) * sprite_h,
            w = sprite_w,
            h = sprite_h,
        },
        anchor = character_dir[character] == 0 and 3 or 2,
    }
    if not success then
        print(err)
        return
    end
    xpos = xpos + xinc
    frame_change_counter = frame_change_counter + 1
    if frame_change_counter == frame_change_max then
        frame_change_counter = 0
        if sprite_x == 0 then
            sprite_x_dir = 1
        elseif sprite_x == 2 then
            sprite_x_dir = -1
        end
        sprite_x = sprite_x + sprite_x_dir
    end
    if character_dir[character] == 0 and xpos < image.win_w or character_dir[character] ~= 0 and xpos >= 0 then
        vim.defer_fn(display_next, anim_delay)
    else
        image:destroy()
        character_dir[character] = 1 - character_dir[character]
        animating = false
        mario.its_a_meee()
    end
end

function mario.lets_a_gooo()
    if not animating then
        animating = true
        image.discover_win_size(function()
            vim.schedule(function()
                if character_rows > 0 then
                    character = math.random(1, character_rows)
                    if not character_dir[character] then
                        character_dir[character] = math.random(0, 1)
                    end
                    xinc = character_dir[character] == 0 and 1 or -1
                    xpos = character_dir[character] == 0 and (-sprite_w + 1) or (image.win_w + sprite_w - 1)
                    display_next()
                end
            end)
        end)
    end
end

return mario
