local pixel = require 'pixel'
local color = require 'pixel.color'

local rows, cols = nil, nil
local grid = nil

local palette = {}
local palette_size = 256
local r_divisor = 1 / 4.0625

for i = 1, palette_size do
    local v = (i - 1) / (palette_size - 1)
    palette[i] = color.rgb_to_int(color.hsv_to_rgb(v / 6, 1, v))
end

return function()
    if pixel.rows() ~= rows or pixel.cols() ~= cols then
        rows, cols = pixel.rows(), pixel.cols()
        grid = {}
        for r = 1, rows do
            local row = {}
            grid[r] = row
            for c = 1, cols do
                row[c] = 0
            end
        end
    end
    for r = 1, rows - 1 do
        local row = grid[r + 1]
        for c = 1, cols do
            local left, right = c - 1, c + 1
            if left == 0 then
                left = cols
            end
            if right > cols then
                right = 1
            end
            local sum = row[left] + row[c] + row[right]
            if r <= rows - 2 then
                sum = sum + grid[r + 2][c]
            end
            sum = sum * r_divisor
            grid[r][c] = math.floor(sum)
        end
    end
    for c = 1, cols do
        grid[rows][c] = math.random(palette_size) - 1
    end
    for r = 1, rows do
        for c, v in ipairs(grid[r]) do
            pixel.set(r, c, palette[v + 1])
        end
    end
end
