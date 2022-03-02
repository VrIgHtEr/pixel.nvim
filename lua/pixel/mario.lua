local mario = {}
math.randomseed(os.time())
local image, terminal = require 'pixel.render.image', require 'pixel.render.terminal'

local sprite_w, sprite_h = 32, 32
local fps = 25

local characters = {}

local function exec_characters(key)
    for _, c in ipairs(characters) do
        c[key]()
    end
end

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
            sprite_x = 0,
            num_frames = num_frames,
            sprite_sheet_strip_index = (i - 1) * 2 * sprite_h,
            anim_divisor = 3,
            hide = function()
                c.placement.hide()
            end,
            display = function(opts)
                c.placement.display(opts)
            end,
            update = function(state)
                if state then
                    c.state = state
                end
                if c.state == 'animating' then
                    c.xpos = c.xpos + c.xinc * c.speed
                    c.sprite_x = math.floor((c.frame_counter / c.anim_divisor * c.speed) % (c.num_frames > 1 and c.num_frames - 2 + c.num_frames or 1))
                    if c.sprite_x >= c.num_frames then
                        c.sprite_x = num_frames - 1 + num_frames - c.sprite_x
                    end
                    c.frame_counter = c.frame_counter + 1
                    c.display {
                        pos = {
                            x = math.floor(c.xpos),
                            y = math.floor((image.rows - 2) * image.cell_h - 1),
                        },
                        crop = {
                            x = c.sprite_x * sprite_w,
                            y = c.sprite_sheet_strip_index + (c.dir and 0 or sprite_h),
                            w = sprite_w,
                            h = sprite_h,
                        },
                        z = c.z,
                        anchor = c.dir and 3 or 2,
                    }
                    if (not c.dir or c.xpos >= image.win_w) and (c.dir or c.xpos < 0) then
                        return c.update 'idle'
                    end
                elseif c.state == 'idle' then
                    c.hide()
                    c.state = 'waiting'
                    c.counter = math.random(25, 25 * 11)
                    c.dir = not c.dir
                    c.xinc = c.dir and 1 or -1
                    c.xpos = c.dir and -sprite_w or (image.win_w + sprite_w)
                    c.speed = math.random() * 7 + 1
                    c.frame_counter = 0
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
        terminal.begin_transaction()
        if stopping then
            exec_characters 'hide'
            started, stopping = false, false
        else
            exec_characters 'update'
            vim.defer_fn(draw, 1000 / fps)
        end
        terminal.end_transaction()
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
