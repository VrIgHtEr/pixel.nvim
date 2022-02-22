local kitty = {}
local string = require 'toolshed.util.string'
local terminal = require 'pixel.render.terminal'

local function chunks(data, size)
    size = math.floor(math.abs(size or 512))
    assert(size > 0, 'size cannot be negative')
    local len = data:len()
    local blocks = math.floor((len + size - 1) / size)
    local ret = {}
    for i = 1, blocks do
        local start = size * (i - 1)
        ret[i] = data:sub(start + 1, math.min(len, start + size))
    end
    return ret
end

local function send_cmd(cmd, data)
    terminal.begin_transaction()
    cmd, data = cmd or '', chunks(string.base64_encode(data or ''))
    local num_chunks = #data
    if cmd == '' or num_chunks <= 1 then
        local esc = { '\x1b_G', cmd, ';' }
        if num_chunks == 1 then
            table.insert(esc, data[1])
        end
        table.insert(esc, '\x1b\\')
        terminal.write(table.concat(esc))
    else
        for i = 1, num_chunks do
            local esc = { '\x1b_G' }
            if i == 1 then
                table.insert(esc, cmd)
                if cmd ~= '' then
                    table.insert(esc, ',')
                end
            end
            table.insert(esc, 'm=')
            table.insert(esc, i == num_chunks and '0;' or '1;')
            table.insert(esc, data[i])
            table.insert(esc, '\x1b\\')
            terminal.write(table.concat(esc))
        end
    end
    terminal.end_transaction()
end

kitty.constants = {
    control_keys = {
        format = 'f',
        image_width = 's',
        image_height = 'v',
        compression = 'o',
        transmission_medium = 't',
        continuation = 'm',
        read_offset = 'O',
        read_length = 'S',
        id = 'i',
        placement_id = 'p',
        action = 'a',
        x_offset = 'X',
        y_offset = 'Y',
        clip_x = 'x',
        clip_y = 'y',
        clip_w = 'w',
        clip_h = 'h',
        display_rows = 'r',
        display_cols = 'c',
        z_index = 'z',
        quiet = 'q',
        cursor_mode = 'C',
        delete = 'd',
    },
    format = { rgb = 24, rgba = 32, png = 100 },
    compression = { zlib_deflate = 'z' },
    transmission_medium = { direct = 'd', file = 'f', temp_file = 't', shared_memory = 's' },
    continuation = { in_progress = '1', finished = '0' },
    action = { query = 'q', delete = 'd', transmit = 't', transmit_and_display = 'T' },
    quiet = { ok = '1', errors = '2' },
}

terminal.execute_at(10, 100, function()
    send_cmd('a=T,f=100,q=2,i=1,p=1', require('pixel.util').read_file '/home/cedric/dice.png')
end)
vim.defer_fn(function()
    send_cmd 'a=d'
end, 1000)
return kitty
