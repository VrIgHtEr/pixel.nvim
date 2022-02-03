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
    __call = function(_, indices, portals)
        if #indices >= 3 and #indices == #portals then
            local ret = setmetatable({ portals = {} }, MT)
            for i, index in ipairs(indices) do
                if type(index) ~= 'number' or index < 0 then
                    return
                end
                ret[i] = index + 1
            end
            for i, portal in ipairs(portals) do
                if portal ~= 'x' and (type(portal) ~= 'number' or portal < 0) then
                    return
                end
                ret.portals[i] = portal == 'x' and portal or portal + 1
            end
            return ret
        end
    end,
})

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

return sector
