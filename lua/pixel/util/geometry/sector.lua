local complex = require 'pixel.util.math.complex'

local sector = {}

local MT = {
    __index = function(_, key)
        return sector[key]
    end,
    __newindex = function(tbl, key, value)
        if key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
}

setmetatable(sector, {
    __index = function(_, key)
        if key == '__type' then
            return 'sector'
        end
    end,
    __newindex = function(tbl, key, value)
        if key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
    __call = function(_, ...)
        local indices = { ... }
        if #indices == 1 and type(indices[1]) == 'table' then
            indices = indices[1]
        end
        if #indices >= 3 then
            local ret = setmetatable({}, MT)
            for i, index in ipairs(indices) do
                if type(index) ~= 'number' or index < 1 then
                    return
                end
                ret[i] = index
            end
            return ret
        end
    end,
})

local function validate_convex(s, vertices)
    local pb, pd = vertices[s[#s]], vertices[s[#s]] - vertices[s[#s - 1]]
    for _, x in ipairs(s) do
        local v = vertices[x]
        local d = v - pb
        if (d / pd).y < 0 then
            return false
        end
        pb, pd = v, d
    end
    return true
end

function sector.validate(s, vertices)
    --validate vertex indices are all within range
    local amt = #vertices
    for _, x in ipairs(s) do
        if x > amt then
            return false
        end
    end

    --validate that all interior angles are <= 180 degrees
    local pb, pd = vertices[s[#s]], vertices[s[#s]] - vertices[s[#s - 1]]
    for _, x in ipairs(s) do
        local d = vertices[x] - pb
        if (d / pd).y < 0 then
            return false
        end
        pb, pd = vertices[x], d
    end

    -- TODO: validate that the shape is not self-intersecting

    --sector is now confirmed to be a simple, convex polygon, with valid vertex data
    return true
end

local verts = { complex(0, 0), complex(10, 0), complex(5, 5) }
local sect = sector(1, 2, 3)
print(vim.inspect(sect))
print(sect:validate(verts))

return sector
