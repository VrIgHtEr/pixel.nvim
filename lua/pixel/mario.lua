local mario = {}
math.randomseed(os.time())
local image, terminal = require 'pixel.render.image', require 'pixel.render.terminal'

local fps = 25
local started, stopping, active_characters = false, false, 0
local img, characters

local function exec_characters(key)
    for _, c in ipairs(characters) do
        c[key]()
    end
end

characters = {
    {
        anim = {
            x = 0,
            y = 0,
            w = 32,
            h = 32,
            frames = 3,
            stride_x = 32,
            stride_y = 32,
        },
    },
    {
        anim = {
            x = 0,
            y = 64,
            w = 32,
            h = 32,
            frames = 3,
            stride_x = 32,
            stride_y = 32,
        },
    },
    {
        anim = {
            x = 0,
            y = 128,
            w = 32,
            h = 32,
            frames = 2,
            stride_x = 32,
            stride_y = 32,
        },
    },
    {
        anim = {
            x = 0,
            y = 192,
            w = 32,
            h = 32,
            frames = 2,
            stride_x = 32,
            stride_y = 32,
        },
    },
    {
        anim = {
            x = 0,
            y = 256,
            w = 32,
            h = 32,
            frames = 3,
            stride_x = 32,
            stride_y = 32,
        },
    },
}

local function init_characters()
    img = image.new { src = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/mario.png' }
    img.size = { x = 96, y = 320 }
    img:transmit()
    for i, character in ipairs(characters) do
        local c = character
        c.anim = c.anim ~= nil and c.anim or { x = 0, y = 0, w = img.size.x, h = img.size.y, frames = 1, stride_x = 0, stride_y = 0 }
        c.z = -i
        c.p = i
        c.placement = img:create_placement()
        c.state = 'idle'
        c.anim_divisor = 3 + ((i == 3 or i == 4) and 2 or 0)
        function c.hide()
            c.placement.hide()
        end
        function c.display(opts)
            c.placement.display(opts)
        end
        function c.destroy()
            if c.placement then
                c.placement.destroy()
                c = nil
            end
        end
        function c.update(state)
            c.state = type(state) == 'string' and state or c.state
            if c.state == 'idle' then
                if stopping then
                    return c.update 'halted'
                end
                c.state = 'waiting'
                c.counter = math.random(25, 25 * 11)
                c.dir = c.dir == nil and (math.random(0, 1) == 0) or not c.dir
                c.xinc, c.xpos = c.dir and 1 or -1, c.dir and -c.anim.w or (image.win_w + c.anim.w)
                local maxspeed, minspeed = c.anim.frames - 1 + c.anim.frames, 1
                c.speed = math.max(minspeed, math.random() * (maxspeed - minspeed) + minspeed)
                c.frame_counter = 0
            elseif c.state == 'waiting' then
                if stopping then
                    c.hide()
                    return c.update 'halted'
                end
                c.counter = c.counter - 1
                if c.counter == 0 then
                    active_characters = active_characters + 1
                    return c.update 'animating'
                end
            elseif c.state == 'animating' then
                c.xpos = c.xpos + c.xinc * c.speed
                c.anim.cur_frame = math.floor((c.frame_counter / c.anim_divisor * c.speed) % (c.anim.frames > 1 and c.anim.frames - 2 + c.anim.frames or 1))
                if c.anim.cur_frame >= c.anim.frames then
                    c.anim.cur_frame = c.anim.frames - 1 + c.anim.frames - c.anim.cur_frame
                end
                c.frame_counter = c.frame_counter + 1
                c.display {
                    pos = {
                        x = math.floor(c.xpos),
                        y = math.floor(image.rows * image.cell_h - 1),
                    },
                    crop = {
                        x = c.anim.cur_frame * c.anim.w,
                        y = c.anim.y + (c.dir and 0 or c.anim.h),
                        w = c.anim.w,
                        h = c.anim.h,
                    },
                    z = c.z,
                    anchor = c.dir and 3 or 2,
                }
                if (not c.dir or c.xpos >= image.win_w) and (c.dir or c.xpos < 0) then
                    c.hide()
                    active_characters = active_characters - 1
                    return c.update 'idle'
                end
            end
        end
    end
end

local function draw()
    if started then
        terminal.begin_transaction()
        exec_characters 'update'
        if stopping and active_characters == 0 then
            started, stopping = false, false
            exec_characters 'destroy'
            img:destroy()
        else
            vim.defer_fn(draw, 1000 / fps)
        end
        terminal.end_transaction()
    end
end

function mario.lets_a_gooo()
    if not started and not stopping then
        local term = vim.fn.getenv 'TERM'
        if term == 'xterm-kitty' or term == 'wezterm' then
            started = true
            stopping = false
            image.discover_win_size(vim.schedule_wrap(function()
                init_characters()
                draw()
            end))
        end
    end
end

function mario.oh_nooo()
    if started and not stopping then
        stopping = true
    end
end

function mario.its_a_meee___MARIO()
    if started then
        if not stopping then
            mario.oh_nooo()
        end
    else
        mario.lets_a_gooo()
    end
end

return mario
