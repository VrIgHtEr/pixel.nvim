local pixel = require 'pixel'
local color = require 'pixel.color'
local divisor = 50
local offset = 0
local increment = 0.01

return function()
    local center = { math.floor((pixel.rows() + 1) / 2), math.floor((pixel.cols() + 1) / 2) }
    offset = offset + increment
    offset = offset - math.floor(offset)
    for r = 1, pixel.rows() do
        for c = 1, pixel.cols() do
            local x, y = r - center[1], c - center[2]
            local hue = (math.sqrt(x * x + y * y) / divisor)
            hue = hue + offset
            hue = hue - math.floor(hue)
            local red, green, blue = color.hsv_to_rgb(hue, 1, 1)
            pixel.set(r, c, color.rgb_to_int(red, green, blue))
        end
    end
end
