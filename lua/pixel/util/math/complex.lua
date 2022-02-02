local complex = {}

local MT = {
    __tostring = function(tbl)
        local ret = tostring(tbl[1])
        if tbl[2] ~= 0 then
            if tbl[2] < 0 then
                ret = ret .. ' - '
                if tbl[2] ~= -1 then
                    ret = ret .. -tbl[2]
                end
            else
                ret = ret .. ' + '
                if tbl[2] ~= 1 then
                    ret = ret .. tbl[2]
                end
            end
            ret = ret .. 'i'
        end
        return ret
    end,
    __index = function(tbl, key)
        if key == 'real' or key == 'x' then
            return tbl[1]
        elseif key == 'imag' or key == 'y' then
            return tbl[2]
        end
        return complex[key]
    end,
    __newindex = function(tbl, key, value)
        if key == 'real' or key == 'x' then
            rawset(tbl, 1, type(value) == 'number' and value or 0)
        elseif key == 'imag' or key == 'y' then
            rawset(tbl, 2, type(value) == 'number' and value or 0)
        elseif key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
    __add = function(a, b)
        return complex.add(a, b)
    end,
    __sub = function(a, b)
        return complex.sub(a, b)
    end,
    __mul = function(a, b)
        return complex.mul(a, b)
    end,
    __div = function(a, b)
        return complex.div(a, b)
    end,
    __unm = function(a)
        return complex.unm(a)
    end,
    __eq = function(a, b)
        return complex.eq(a, b)
    end,
}

function complex.mag(x)
    return math.sqrt(x[1] * x[1] + x[2] * x[2])
end

function complex.eq(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

function complex.unm(a)
    return setmetatable({ -a[1], -a[2] }, MT)
end

function complex.conj(a)
    return setmetatable({ a[1], -a[2] }, MT)
end

function complex.mul(a, b)
    if type(a) == 'number' then
        return setmetatable({ b[1] * a, b[2] * a }, MT)
    elseif type(b) == 'number' then
        return setmetatable({ a[1] * b, a[2] * b }, MT)
    end
    return setmetatable({ a[1] * b[1] - a[2] * b[2], a[1] * b[2] + a[2] * b[1] }, MT)
end

function complex.div(a, b)
    if type(a) == 'number' then
        return setmetatable({ b[1] / a, b[2] / a }, MT)
    elseif type(b) == 'number' then
        return setmetatable({ a[1] / b, a[2] / b }, MT)
    end
    return complex.mul(a, complex.conj(b))
end

function complex.add(a, b)
    return setmetatable({ a[1] + b[1], a[2] + b[2] }, MT)
end

function complex.sub(a, b)
    return setmetatable({ a[1] - b[1], a[2] - b[2] }, MT)
end

function complex.normalize(a)
    return a / a:mag()
end

setmetatable(complex, {
    __index = function(_, key)
        if key == '__type' then
            return 'complex'
        end
    end,
    __newindex = function(tbl, key, value)
        if key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
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
        elseif b == nil and type(a) == 'table' and a.__type == complex.__type then
            return a
        end
    end,
})

return complex
