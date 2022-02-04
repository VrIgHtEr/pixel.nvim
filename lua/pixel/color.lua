---@class Color
---@field r number
---@field g number
---@field b number
--
local M = {}
local math = require 'pixel.util.math'

---Splits an integer representation of a color into its r,g and b components
---@param i number
---@return number
function M.int_to_rgb(i)
    return bit.band(bit.rshift(i, 16), 255), bit.band(bit.rshift(i, 8), 255), bit.band(i, 255)
end

function M.rgb_to_int(r, g, b)
    r, g, b = math.round(r), math.round(g), math.round(b)
    return bit.lshift(math.round(math.min(255, math.max(0, r))), 16)
        + bit.lshift(math.round(math.min(255, math.max(0, g))), 8)
        + math.round(math.min(255, math.max(0, b)))
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

---Converts a color to a canonical internal representation
---@param color number|string|table|Color
---@return boolean
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

---Converts an RGB color value to HSL. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSL_color_space.
---Assumes r, g, and b are contained in the set [0, 255] and
---returns h, s, and l in the set [0, 1].
---@param r number
---@param g number
---@param b number
---@return number h
---@return number s
---@return number l
function M.rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255

    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l

    l = (max + min) / 2

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        if l > 0.5 then
            s = d / (2 - max - min)
        else
            s = d / (max + min)
        end
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

---Converts an HSL color value to RGB. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSL_color_space.
---Assumes h, s, and l are contained in the set [0, 1] and
---returns r, g, and b in the set [0, 255].
---@param h number
---@param s number
---@param l number
---@return number r
---@return number g
---@return number b
function M.hsl_to_rgb(h, s, l)
    local r, g, b
    if s == 0 then
        r, g, b = l, l, l -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0 then
                t = t + 1
            end
            if t > 1 then
                t = t - 1
            end
            if t < 1 / 6 then
                return p + (q - p) * 6 * t
            end
            if t < 1 / 2 then
                return q
            end
            if t < 2 / 3 then
                return p + (q - p) * (2 / 3 - t) * 6
            end
            return p
        end

        local q
        if l < 0.5 then
            q = l * (1 + s)
        else
            q = l + s - l * s
        end
        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return r * 255, g * 255, b * 255
end

---Converts an RGB color value to HSV. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSV_color_space.
---Assumes r, g, and b are contained in the set [0, 255] and
---returns h, s, and v in the set [0, 1].
---@param r number
---@param g number
---@param b number
---@return number h
---@return number s
---@return number v
function M.rgb_to_hsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end

    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

---Converts an HSV color value to RGB. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSV_color_space.
---Assumes h, s, and v are contained in the set [0, 1] and
---returns r, g, and b in the set [0, 255].
---@param h number
---@param s number
---@param v number
---@return number r
---@return number g
---@return number b
function M.hsv_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return r * 255, g * 255, b * 255
end

return M
