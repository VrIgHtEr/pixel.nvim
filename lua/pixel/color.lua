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

return M
