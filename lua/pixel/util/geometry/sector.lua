local sector = {}
local line = require 'pixel.util.geometry.line'
local complex = require 'pixel.util.math.complex'
local math = require 'pixel.util.math'
local prt = print
local print = function(...)
    return prt(...)
end

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
    __call = function(_, floor_height, ceiling_height, indices, portals)
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
            ret.floor, ret.ceil = tonumber(floor_height), tonumber(ceiling_height)
            if not ret.floor or not ret.ceil or ret.ceil <= ret.floor then
                return
            end
            return ret
        end
    end,
})

function sector.validate(s, vertices, sectors)
    --validate that all portals point to valid sectors
    local amt = #sectors
    for _, x in ipairs(s.portals) do
        if x ~= 'x' and x > amt then
            return false
        end
    end

    --validate vertex indices are all within range
    amt = #vertices
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

local I = complex(0, 1)
local near = 0.001
local cnear = complex(0, near)
local x_axis = line(complex(0, 0), complex(1, 0))

function sector.render(self, halfwidth, halfheight, position, rot, player_height, stack, vertices, sectors, top, bottom, left, right, set_pixel)
    print '-------------------------------------------'
    print 'RENDERING SECTOR'
    print(position)
    print(rot)
    local fl, ce = self.floor - player_height, self.ceil - player_height
    for wallid = 1, #self do
        print('WALL: ' .. wallid)
        local previd = wallid - 1
        if previd == 0 then
            previd = #self
        end

        --get transformed wall coordinates
        local a, b = (vertices[self[previd]] - position) * rot, (vertices[self[wallid]] - position) * rot
        print('A: ' .. tostring(a))
        print('B: ' .. tostring(b))

        --get wall normal
        local wallvect = b - a
        local normal = wallvect * I
        print('NORM: ' .. tostring(normal))

        local dot = normal.x * a.x + normal.y * a.y

        --cull: wall is not facing us
        if dot > 0 then
            print 'CULL: backface'
            goto continue
        end

        --cull: wall is completely behind the near plane
        if a.y < near and b.y < near then
            print 'CULL: behind near plane'
            goto continue
        end

        --if wall is not completely in front of the near plane, then we need to clip it to the near plane
        if not (a.y >= near and b.y >= near) then
            print 'CLIP'
            local l = line(a - cnear, b - cnear)
            local intersectionpoint = l:lerp(l:intersect(x_axis)) + cnear
            if a.y > b.y then
                b = intersectionpoint
            else
                a = intersectionpoint
            end
        end

        --make sure a and b are the left and right edges of the wall, respectively
        if a.x > b.x then
            a, b = b, a
        end

        print('A:' .. tostring(a))
        print('B:' .. tostring(b))
        local f_left, f_right = a.x / a.y, b.x / b.y
        print('FL: ' .. tostring(f_left))
        print('FR: ' .. tostring(f_right))

        local p_left, p_right = math.round(f_left * halfwidth) + 1 + halfwidth, math.round(f_right * halfwidth) + 1 + halfwidth
        print('PL: ' .. tostring(p_left))
        print('PR: ' .. tostring(p_right))

        --cull: wall is offscreen, even though it is facing us and not behind us
        if p_right < left or p_left > right then
            print('CULL: right:' .. p_right .. ':' .. left .. '   left:' .. p_left .. ':' .. right)
            goto continue
        end

        local flt, frt = fl / a.y, fl / b.y
        local clt, crt = ce / a.y, ce / b.y
        local flb, frb, clb, crb

        local steps = p_right - p_left

        local portal = self.portals[wallid] ~= 'x' and sectors[self.portals[wallid]] or nil
        if portal then
            print 'PORTAL'
            table.insert(stack, { sector = portal, left = left, right = right })
            if portal.floor > self.floor then
                local pfloor = portal.floor - player_height
                flt, flb, frt, frb = pfloor / a.y, flt, pfloor / b.y, frt
            else
                flb, frb = flt, frt
            end
            if portal.ceil < self.ceil then
                local pceil = portal.ceil - player_height
                clb, crb = pceil / a.y, pceil / b.y
            else
                clb, crb = clt, crt
            end
        else
            flb, frb, clb, crb = flt, frt, clt, crt
        end
        ::continue::
        print '---'
    end
end

return sector
