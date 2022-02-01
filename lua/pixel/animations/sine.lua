local pixel = require 'pixel'
local color = require 'pixel.color'
local offset = 0
local increment = 0.01

return function()
    offset = offset + increment
    offset = offset - math.floor(offset)
    for r = 1, pixel.rows() do
        local y = (r - 1) / (pixel.rows() - 1) * 2 - 1
        local yy = y * y
        for c = 1, pixel.cols() do
            local x = (c - 1) / (pixel.cols() - 1) * 2 - 1
            local hue = (math.sqrt(x * x + yy))
            hue = hue + offset
            hue = hue - math.floor(hue)
            local red, green, blue = color.hsv_to_rgb(hue, 1, 1)
            pixel.set(r, c, color.rgb_to_int(red, green, blue))
        end
    end
end
