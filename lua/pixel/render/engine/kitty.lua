local kitty = {}
local string = require 'toolshed.util.string'
local terminal = require 'pixel.render.terminal'

local function read_file(path)
    local file, err, data = io.open(path, 'rb')
    if not file then
        return nil, err
    end
    data, err = file:read '*a'
    file:close()
    return data, err
end

local function write_file(path, data)
    local file, err = io.open(path, 'wb')
    if not file then
        return nil, err
    end
    data, err = file:write(data)
    file:close()
    return data, err
end

local function chunks(data, size)
    size = math.floor(math.abs(size or 4096))
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

local bfr = {}
local function write(...)
    terminal.write(...)
    for _, x in ipairs { ... } do
        table.insert(bfr, x)
    end
end

local function dump()
    write_file('/tmp/test.kitty', table.concat(bfr))
    bfr = {}
end

local function send_cmd(cmd, data)
    cmd, data = cmd or '', chunks(string.base64_encode(data or ''))
    local num_chunks = #data
    if cmd == '' or num_chunks <= 1 then
        local esc = { '\x1b_G', cmd, ';' }
        if num_chunks == 1 then
            table.insert(esc, data[1])
        end
        table.insert(esc, '\x1b\\')
        write(table.concat(esc))
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
            write(table.concat(esc))
        end
    end
    dump()
end
terminal.execute_at(10, 100, function()
    send_cmd('a=T,f=100,q=2,i=1,p=1', read_file '/home/cedric/dice.png')
end)
--vim.defer_fn(function() transmit(string.base64_encode(read_file '/home/cedric/dice.png')) end, 0)
local my_image = require('hologram.image'):new {
    source = '/home/cedric/dice.png',
    row = 11,
    col = 0,
}
--[[
my_image:transmit() -- send image data to terminal

-- Move image 5 rows down after 1 second
vim.defer_fn(function()
    my_image:move(15, 0)
    my_image:adjust() -- must adjust to update image
end, 1000)

-- Crop image to 100x100 pixels after 2 seconds
vim.defer_fn(function()
    my_image:adjust {
        crop = { 100, 100 },
    }
end, 2000)

-- Resize image to 75x50 pixels after 3 seconds
vim.defer_fn(function()
    my_image:adjust {
        area = { 75, 50 },
    }
end, 3000)

vim.defer_fn(function()
    my_image:delete()
end, 4000)
]]
return kitty
