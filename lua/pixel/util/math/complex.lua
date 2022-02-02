local M = {}

local MT = {
    __tostring = function(tbl)
        local ret = tostring(tbl[1])
        if tbl[2] ~= 0 then
            ret = ret .. ' + ' .. tostring(tbl[2]) .. 'i'
        end
        return ret
    end,
    __index = function(tbl, key)
        if key == 'real' then
            return tbl[1]
        elseif key == 'imag' then
            return tbl[2]
        else
            return M[key]
        end
    end,
    __newindex = function(tbl, key, value)
        if key == 'real' then
            tbl[1] = type(value) == 'number' and value or 0
        elseif key == 'imag' then
            tbl[2] = type(value) == 'number' and value or 0
        end
    end,
    __add = function(a, b)
        return M.add(a, b)
    end,
    __sub = function(a, b)
        return M.sub(a, b)
    end,
    __mul = function(a, b)
        return M.mul(a, b)
    end,
    __div = function(a, b)
        return M.div(a, b)
    end,
    __unm = function(a)
        return M.unm(a)
    end,
    __eq = function(a, b)
        return M.eq(a, b)
    end,
}

function M.mag(x)
    return math.sqrt(x[1] * x[1] + x[2] * x[2])
end

function M.eq(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

function M.unm(a)
    return setmetatable({ a[1], -a[2] }, MT)
end

function M.mul(a, b)
    if type(a) == 'number' then
        return setmetatable({ b[1] * a, b[2] * a }, MT)
    elseif type(b) == 'number' then
        return setmetatable({ a[1] * b, a[2] * b }, MT)
    end
    return setmetatable({ a[1] * b[1] - a[2] * b[2], a[1] * b[2] + a[2] * b[1] }, MT)
end

function M.div(a, b)
    if type(a) == 'number' then
        return setmetatable({ b[1] / a, b[2] / a }, MT)
    elseif type(b) == 'number' then
        return setmetatable({ a[1] / b, a[2] / b }, MT)
    end
    return M.mul(a, M.unm(b))
end

function M.add(a, b)
    return setmetatable({ a[1] + b[1], a[2] + b[2] }, MT)
end

function M.sub(a, b)
    return setmetatable({ a[1] - b[1], a[2] - b[2] }, MT)
end

function M.normalize(a)
    return a / a:mag()
end

setmetatable(M, {
    __call = function(_, a, b)
        if a == nil then
            if b == nil then
                return setmetatable({ 0, 0 }, MT)
            end
        elseif type(a) == 'number' then
            if b == nil then
                return setmetatable({ a, 0 }, MT)
            elseif type(b) == 'number' then
                return setmetatable({ a, b }, MT)
            end
        end
    end,
})

return M
