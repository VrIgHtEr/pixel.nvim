local p = require 'pixel'
return function()
    for r = 1, p.rows() do
        for c = 1, p.cols() do
            p.set(r, c, math.random(16777216) - 1)
        end
    end
end
