local mario = {}
local image, terminal, chars = require 'pixel.render.image', require 'pixel.render.terminal', require 'mario.characters'

local fps = 25
local started, stopping, active_characters = false, false, 0

local function init_characters()
    chars.init()
    for _, c in ipairs(chars.data) do
        function c.update(state)
            c.state = type(state) == 'string' and state or c.state
            if c.state == 'idle' then
                if stopping then
                    return c.update 'halted'
                end
                c.state = 'waiting'
                c.counter = math.random(25, 25 * 11)
                if c.dir == nil then
                    c.dir = math.random(0, 1) == 0
                else
                    c.dir = not c.dir
                end
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
                c.anim.cur_frame = math.floor((c.frame_counter / c.anim.speed * c.speed) % (c.anim.frames > 1 and c.anim.frames - 2 + c.anim.frames or 1))
                if c.anim.cur_frame >= c.anim.frames then
                    c.anim.cur_frame = c.anim.frames - 1 + c.anim.frames - c.anim.cur_frame
                end
                c.frame_counter = c.frame_counter + 1
                c.display {
                    pos = { x = math.floor(c.xpos), y = math.floor(image.rows * image.cell_h - 1) },
                    crop = { x = c.anim.cur_frame * c.anim.w, y = c.anim.y + (c.dir and 0 or c.anim.h), w = c.anim.w, h = c.anim.h },
                    z = c.anim.z,
                    anchor = c.dir and 3 or 2,
                }
                if (not c.dir or c.xpos >= image.win_w) and (c.dir or c.xpos < 0) then
                    c.hide()
                    active_characters = active_characters - 1
                    return c.update 'idle'
                end
            elseif c.state == 'halted' then
                if not stopping then
                    return c.update 'idle'
                end
            end
        end
    end
end

local function draw()
    if started then
        terminal.begin_transaction()
        chars.exec 'update'
        if stopping and active_characters == 0 then
            started, stopping = false, false
            chars.destroy()
        else
            vim.defer_fn(draw, 1000 / fps)
        end
        terminal.end_transaction()
    end
end

function mario.lets_a_gooo()
    if stopping then
        stopping = false
    elseif not started then
        local term = vim.fn.getenv 'TERM'
        if term == 'xterm-kitty' or term == 'wezterm' then
            started = true
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

function mario.its_a_meee()
    ((not started or stopping) and mario.lets_a_gooo or mario.oh_nooo)()
end

return mario
