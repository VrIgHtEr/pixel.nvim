---@class sector_t
---@field __type string
local sector_t = {}

---@class sector : sector_t
---@field floor number
---@field ceil number
---@field portals number[]

---@class render_stack_item
---@field sector sector
---@field left number
---@field right number
--

local color = require 'pixel.color'
local line = require 'pixel.util.geometry.line'
local complex = require 'pixel.util.math.complex'
local math = require 'pixel.util.math'

local colors = {
    ceil = 255 * 65536,
    ceil_step = 255 * 256,
    wall = 255,
    floor_step = 255 * 256 + 255,
    floor = 255 * 65536 + 255,
}

local MT = {
    __index = function(_, key)
        return sector_t[key]
    end,
    __newindex = function(tbl, key, value)
        if key ~= '__type' then
            rawset(tbl, key, value)
        end
    end,
}

setmetatable(sector_t, {
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
})

---@param floor_height number
---@param ceiling_height number
---@param indices number[]
---@param portals number[]
---@return sector
local function new(floor_height, ceiling_height, indices, portals)
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
end

---@param s sector
---@param vertices complex[]
---@param sectors sector[]
---@return boolean
function sector_t.validate(s, vertices, sectors)
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

---@param self sector
---@param halfwidth number
---@param halfheight number
---@param position complex
---@param rot complex
---@param player_height number
---@param stack render_stack_item[]
---@param vertices complex[]
---@param sectors sector[]
---@param top number[]
---@param bottom number[]
---@param left number
---@param right number
---@param set_pixel function
function sector_t.render(self, halfwidth, halfheight, position, rot, player_height, stack, vertices, sectors, top, bottom, left, right, set_pixel)
    local fl, ce = self.floor - player_height, self.ceil - player_height
    for wallid = 1, #self do
        local previd = wallid - 1
        if previd == 0 then
            previd = #self
        end

        --get transformed wall coordinates
        local a, b = (vertices[self[previd]] - position) * rot, (vertices[self[wallid]] - position) * rot

        --get wall normal
        local wallvect = b - a
        local normal = wallvect * I

        local dot = normal.x * a.x + normal.y * a.y

        --cull: wall is not facing us
        if dot >= 0 then
            goto continue
        end

        --cull: wall is completely behind the near plane
        if a.y < near and b.y < near then
            goto continue
        end

        --if wall is not completely in front of the near plane, then we need to clip it to the near plane
        if not (a.y >= near and b.y >= near) then
            local l = line(a - cnear, b - cnear)
            local intersectionpoint = l:lerp(l:intersect(x_axis)) + cnear
            if a.y > b.y then
                b = intersectionpoint
            else
                a = intersectionpoint
            end
        end

        local f_left, f_right = a.x / a.y, b.x / b.y
        local p_left, p_right = math.round(f_left * halfwidth) + 1 + halfwidth, math.round(f_right * halfwidth) + 1 + halfwidth

        --make sure a and b are the left and right edges of the wall, respectively
        if p_left > p_right then
            p_left, p_right = p_right, p_left
            f_left, f_right = f_right, f_left
            a, b = b, a
        end

        --cull: wall is offscreen, even though it is facing us and not behind us
        if p_right <= left then
            goto continue
        end
        if p_left > right then
            goto continue
        end
        if p_right == p_left then
            goto continue
        end

        local left_edge, right_edge = math.max(left, p_left), math.min(right, p_right)

        local flb, frb, clt, crt = fl / a.y, fl / b.y, ce / a.y, ce / b.y
        local flt, frt, clb, crb

        local portal = self.portals[wallid] ~= 'x' and sectors[self.portals[wallid]] or nil
        if portal then
            table.insert(stack, { sector = portal, left = left_edge, right = right_edge })
            if portal.floor > self.floor then
                local pfloor = portal.floor - player_height
                flt, frt = pfloor / a.y, pfloor / b.y
            else
                flt, frt = flb, frb
            end
            if portal.ceil < self.ceil then
                local pceil = portal.ceil - player_height
                clb, crb = pceil / a.y, pceil / b.y
            else
                clb, crb = clt, crt
            end
        else
            flt, frt, clb, crb = flb, frb, clt, crt
        end

        flb, frb, clt, crt =
            flb * halfheight + halfheight + 1, frb * halfheight + halfheight + 1, clt * halfheight + halfheight + 1, crt * halfheight + halfheight + 1
        flt, frt, clb, crb =
            flt * halfheight + halfheight + 1, frt * halfheight + halfheight + 1, clb * halfheight + halfheight + 1, crb * halfheight + halfheight + 1

        local steps = p_right - p_left

        local fbd, ftd, ctd, cbd, yd = frb - flb, frt - flt, crt - clt, crb - clb, b.y - a.y
        local fbs, fts, cts, cbs, ys = fbd / steps, ftd / steps, ctd / steps, cbd / steps, yd / steps

        for c = left_edge + 1, right_edge do
            if top[c] > bottom[c] then
                local step = c - p_left
                local fb, ft, ct, cb, y =
                    math.floor(fbs * step + flb), math.floor(fts * step + flt), math.floor(cts * step + clt), math.floor(cbs * step + clb), ys * step + a.y

                local function vline(from, to, col)
                    y = 1 - math.min(1, math.max(0, y / 20))
                    local red, green, blue = color.int_to_rgb(col)
                    red, green, blue = red * y, green * y, blue * y
                    col = color.rgb_to_int(red, green, blue)
                    for i = from, to do
                        set_pixel(c, i, (i == fb or i == ft or i == cb or i == ct) and 0 or col)
                    end
                end

                --draw ceiling
                if ct <= bottom[c] then
                    vline(bottom[c], top[c] - 1, colors.ceil)
                    top[c] = cb
                elseif cb <= bottom[c] then
                    if ct < top[c] then
                        vline(ct, top[c] - 1, colors.ceil_step)
                        if cb < ct then
                            vline(bottom[c], ct - 1, colors.ceil_step)
                        end
                    else
                        vline(bottom[c], top[c] - 1, colors.ceil_step)
                    end
                    top[c] = cb
                elseif cb < top[c] then
                    if ct < top[c] then
                        vline(ct, top[c] - 1, colors.ceil)
                        if cb < ct then
                            vline(cb, ct - 1, colors.ceil_step)
                        end
                    else
                        vline(cb, top[c] - 1, colors.ceil_step)
                    end
                    top[c] = cb
                end

                --draw floor

                if fb >= top[c] then
                    vline(bottom[c], top[c] - 1, colors.floor)
                    bottom[c] = top[c]
                elseif ft >= top[c] then
                    if fb < bottom[c] then
                        vline(bottom[c], top[c] - 1, colors.floor_step)
                    else
                        vline(bottom[c], fb - 1, colors.floor)
                        if ft > fb then
                            vline(fb, top[c] - 1, colors.floor_step)
                        end
                    end
                    bottom[c] = ft
                elseif fb > bottom[c] then
                    vline(bottom[c], fb - 1, colors.floor_step)
                    if ft > fb then
                        vline(fb, ft - 1, colors.floor_step)
                    end
                    bottom[c] = ft
                elseif ft > bottom[c] then
                    vline(bottom[c], ft - 1, colors.floor_step)
                    bottom[c] = ft
                end

                --draw wall
                if not portal then
                    vline(bottom[c], top[c] - 1, c == p_right and 0 or colors.wall)
                    top[c] = bottom[c]
                end
            end
        end

        ::continue::
    end
end

return new
