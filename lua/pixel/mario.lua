local mario = {}
math.randomseed(os.time())
local image, terminal = require 'pixel.render.image', require 'pixel.render.terminal'

local sprite_w, sprite_h = 32, 32
local fps = 25
local started, stopping = false, false
local img, characters

local function exec_characters(key)
    for _, c in ipairs(characters) do
        c[key]()
    end
end

local function init_characters()
    characters = {
        {
            anim = {
                x = 0,
                y = 0,
                w = sprite_w,
                h = sprite_h,
                frames = 3,
                stride_x = sprite_w,
                stride_y = sprite_h,
            },
        },
        {
            anim = {
                x = 0,
                y = 64,
                w = sprite_w,
                h = sprite_h,
                frames = 3,
                stride_x = sprite_w,
                stride_y = sprite_h,
            },
        },
        {
            anim = {
                x = 0,
                y = 128,
                w = sprite_w,
                h = sprite_h,
                frames = 2,
                stride_x = sprite_w,
                stride_y = sprite_h,
            },
        },
        {
            anim = {
                x = 0,
                y = 192,
                w = sprite_w,
                h = sprite_h,
                frames = 2,
                stride_x = sprite_w,
                stride_y = sprite_h,
            },
        },
        {
            anim = {
                x = 0,
                y = 256,
                w = sprite_w,
                h = sprite_h,
                frames = 3,
                stride_x = sprite_w,
                stride_y = sprite_h,
            },
        },
    }
    img = image.new { src = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/mario.png' }
    img.size = { x = 96, y = 320 }
    img:transmit()
    local num_frames = math.floor(img.size.x / sprite_w)
    for i = 1, math.floor(img.size.y / (sprite_h * 2)) do
        local c = characters[i]
        c.z = -i
        c.p = i
        c.placement = img:create_placement()
        c.state = 'idle'
        c.xpos = 0
        c.xinc = 0
        c.dir = math.random(0, 1) == 0
        c.sprite_sheet_strip_col_index = 0
        c.num_frames = num_frames - ((i == 3 or i == 4) and 1 or 0)
        c.sprite_sheet_strip_index = (i - 1) * 2 * sprite_h
        c.anim_divisor = 3 + ((i == 3 or i == 4) and 2 or 0)
        function c.hide()
            c.placement.hide()
        end
        function c.display(opts)
            c.placement.display(opts)
        end
        function c.update(state)
            if state then
                c.state = state
            end
            if c.state == 'animating' then
                c.xpos = c.xpos + c.xinc * c.speed
                c.sprite_sheet_strip_col_index = math.floor(
                    (c.frame_counter / c.anim_divisor * c.speed) % (c.num_frames > 1 and c.num_frames - 2 + c.num_frames or 1)
                )
                if c.sprite_sheet_strip_col_index >= c.num_frames then
                    c.sprite_sheet_strip_col_index = num_frames - 1 + num_frames - c.sprite_sheet_strip_col_index
                end
                c.frame_counter = c.frame_counter + 1
                c.display {
                    pos = {
                        x = math.floor(c.xpos),
                        y = math.floor(image.rows * image.cell_h - 1),
                    },
                    crop = {
                        x = c.sprite_sheet_strip_col_index * sprite_w,
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
                local maxspeed, minspeed = c.num_frames - 1 + c.num_frames, 1
                c.speed = math.random() * (maxspeed - minspeed) + minspeed
                if c.speed == 0 then
                    c.speed = 1
                end
                c.frame_counter = 0
            elseif c.state == 'waiting' then
                c.counter = c.counter - 1
                if c.counter == 0 then
                    c.state = 'animating'
                end
            end
        end
    end
end

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
        init_characters()
        image.discover_win_size(vim.schedule_wrap(draw))
    end
end

function mario.oh_nooo()
    if started and not stopping then
        stopping = true
    end
end

function mario.its_a_meee()
    if started then
        if not stopping then
            mario.oh_nooo()
        end
    else
        mario.lets_a_gooo()
    end
end

function mario.wahooo()
    local term = vim.fn.getenv 'TERM'
    if term == 'xterm-kitty' or term == 'wezterm' then
        mario.lets_a_gooo()
    end
end

return mario
