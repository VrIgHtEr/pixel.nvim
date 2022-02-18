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
        write('\x1b_G', cmd, ';')
        if num_chunks == 1 then
            write(data[1])
        end
        write '\x1b\\'
    else
        for i = 1, num_chunks do
            write '\x1b_G'
            if i == 1 then
                write(cmd)
                if cmd ~= '' then
                    write ','
                end
            end
            write('m=', i == num_chunks and '0' or '1')
            write(';', data[i], '\x1b\\')
        end
    end
    dump()
    print 'written!'
end

terminal.execute_at(10, 100, function()
    send_cmd('a=T,f=100,q=2,C=1', read_file '/home/cedric/Pictures/dice.png')
end)

return kitty
