local complex = require 'pixel.util.math.complex'
local line = {}

local MT = {
    __index = function(tbl, key)
        if key == 'a' then
            return tbl[1]
        elseif key == 'b' then
            return tbl[2]
        end
        return line[key]
    end,
    __newindex = function(tbl, key, value)
        if key == 'a' then
            rawset(tbl, 1, complex(value) or complex(0))
        elseif key == 'b' then
            rawset(tbl, 2, complex(value) or complex(0))
        elseif key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
    __tostring = function(tbl)
        return 'line:(' .. tostring(tbl.a) .. '):(' .. tostring(tbl.b) .. ')'
    end,
}

setmetatable(line, {
    __index = function(_, key)
        if key == '__type' then
            return 'line'
        end
    end,
    __newindex = function(tbl, key, value)
        if key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
    __call = function(_, a, b)
        if b == nil and type(a) == 'table' and a.__type == line.__type then
            return a
        else
            a, b = complex(a), complex(b)
            if a and b then
                return setmetatable({ a, b }, MT)
            end
        end
    end,
})

function line.intersect(a, b)
    a, b = line(a), line(b)
    if a and b then
        local a1, a2, b1, b2 = a[1], a[2], b[1], b[2]
        a2, b1, b2 = a2 - a1, b1 - a1, b2 - a1
        a1 = a2:normalize():conj()
        a2, b1, b2 = a2 * a1, b1 * a1, b2 * a1
        local x = line.x_intercept(line(b1, b2))
        if x then
            return x / a2.x
        end
    end
end

function line.intersect_segment(a, b)
    a, b = line(a), line(b)
    if a and b then
        local a1, a2, b1, b2 = a[1], a[2], b[1], b[2]
        a2, b1, b2 = a2 - a1, b1 - a1, b2 - a1
        a1 = a2:normalize():conj()
        a2, b1, b2 = a2 * a1, b1 * a1, b2 * a1
        local x = line.x_intercept(line(b1, b2))
        if x and x >= math.max(0, math.min(b1.x, b2.x)) and x <= math.min(a2.x, math.max(b1.x, b2.x)) then
            return a:lerp(x / a2.x)
        end
    end
end

function line.x_intercept(l)
    if l.a.y ~= l.b.y then
        if l.a.x == l.b.x then
            return l.a.x
        end
        local m = (l.b.y - l.a.y) / (l.b.x - l.a.x)
        return (m * l.a.x - l.a.y) / m
    end
end

function line.lerp(x, t)
    return x.a + ((x.b - x.a) * t)
end

return line
