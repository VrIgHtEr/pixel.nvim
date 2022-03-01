local mario = {}
local image, terminal = require 'pixel.render.image', require 'pixel.render.terminal'

local sprite_w, sprite_h = 32, 32
local fps = 25

local characters = {}
do
    local img = image.new { src = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/mario.png' }
    img.size = { x = 96, y = 128 }
    img:transmit()
    local num_frames = math.floor(img.size.x / sprite_w)
    for i = 1, math.floor(img.size.y / (sprite_h * 2)) do
        local c
        c = {
            z = -i,
            p = i,
            placement = img:create_placement(),
            state = 'idle',
            xpos = 0,
            xinc = 0,
            dir = math.random(0, 1) == 0,
            sprite_x_dir = 1,
            sprite_x = 0,
            frame_change_counter = 0,
            frame_change_max = 4,
            num_frames = num_frames,
            update = function()
                if c.state == 'animating' then
                    c.xpos = c.xpos + c.xinc
                    c.frame_change_counter = c.frame_change_counter + 1
                    if c.frame_change_counter == c.frame_change_max then
                        c.frame_change_counter = 0
                        if c.sprite_x == 0 then
                            c.sprite_x_dir = 1
                        elseif c.sprite_x == (c.num_frames - 1) then
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
                            y = ((c.p - 1) * 2 + (c.dir and 0 or 1)) * sprite_h,
                            w = sprite_w,
                            h = sprite_h,
                        },
                        anchor = c.dir and 3 or 2,
                    }
                    if (not c.dir or c.xpos >= image.win_w) and (c.dir or c.xpos < 0) then
                        c.placement.hide()
                        c.state = 'idle'
                        return c.update()
                    end
                elseif c.state == 'idle' then
                    c.state = 'waiting'
                    c.counter = math.random(25, 25 * 156)
                    c.dir = not c.dir
                    c.xinc = c.dir and 1 or -1
                    c.xpos = c.dir and -sprite_w or (image.win_w + sprite_w)
                elseif c.state == 'waiting' then
                    c.counter = c.counter - 1
                    if c.counter == 0 then
                        c.state = 'animating'
                    end
                end
            end,
        }
        characters[i] = c
    end
end

local started = false
local stopping = false

local function draw()
    if started then
        if stopping then
            terminal.begin_transaction()
            for _, c in ipairs(characters) do
                c.placement.hide()
            end
            terminal.end_transaction()
            started, stopping = false, false
        else
            terminal.begin_transaction()
            for _, c in ipairs(characters) do
                c.update()
            end
            terminal.end_transaction()
            vim.defer_fn(draw, 1000 / fps)
        end
    end
end

function mario.lets_a_gooo()
    if not started and not stopping then
        started = true
        stopping = false
        image.discover_win_size(vim.schedule_wrap(draw))
    end
end

function mario.oh_nooo()
    if started and not stopping then
        stopping = true
    end
end

return mario
