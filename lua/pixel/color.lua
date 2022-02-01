local M = {}
local util = require 'pixel.util'
function M.int_to_rgb(i)
    return bit.band(bit.rshift(i, 16), 255, bit.band(bit.rshift(i, 8), 255, bit.band(i, 255)))
end

function M.rgb_to_int(r, g, b)
    return bit.lshift(util.round(math.min(255, math.max(0, r))), 16)
        + bit.lshift(util.round(math.min(255, math.max(0, g))), 8)
        + util.round(math.min(255, math.max(0, b)))
end

local hexstr = '0123456789abcdef'
function M.int_to_hex(x)
    local ret = { '#' }
    for i = 7, 2, -1 do
        local n = bit.band(x, 15) + 1
        ret[i] = hexstr:sub(n, n)
        x = bit.rshift(x, 4)
    end
    return table.concat(ret)
end

local function decode_hex(hex)
    local ret = 0
    for i = 1, hex:len() do
        local c, byte = hex:sub(i, i)
        ret = ret * 16
        if c >= '0' and c <= '9' then
            byte = string.byte(c) - string.byte '0'
        elseif c >= 'a' and c <= 'f' then
            byte = string.byte(c) - string.byte 'a'
        elseif c >= 'A' and c <= 'F' then
            byte = string.byte(c) - string.byte 'A'
        else
            return
        end
        ret = ret + byte
    end
    return ret
end

function M.canonical(color)
    local col = nil
    if type(color) == 'number' then
        col = bit.band(color, 16777215)
    elseif type(color) == 'string' then
        local len = color:len()
        if len > 1 and color:sub(1, 1) == '#' then
            if len == 4 then
                local red, green, blue = decode_hex(color:sub(2, 2)), decode_hex(color:sub(3, 3)), decode_hex(color:sub(4, 4))
                col = M.rgb_to_int(bit.lshift(red, 4) + red, bit.lshift(green, 4) + green, bit.lshift(blue, 4) + blue)
            elseif len == 7 then
                col = M.rgb_to_int(decode_hex(color:sub(2, 3)), decode_hex(color:sub(4, 5)), decode_hex(color:sub(6, 7)))
            else
                return false
            end
        else
            return false
        end
    elseif type(color) == 'table' then
        if type(color[1]) ~= 'number' or type(color[2]) ~= 'number' or type(color[3]) ~= 'number' then
            if type(color.r) ~= 'number' or type(color.g) ~= 'number' or type(color.b) ~= 'number' then
                return false
            else
                col = M.rgb_to_int(color.r, color.g, color.b)
            end
        else
            col = M.rgb_to_int(col[1], col[2], col[3])
        end
    end
    return col
end

return M
