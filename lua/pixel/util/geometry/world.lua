local world = {}
local string = require 'pixel.util.string'
local complex = require 'pixel.util.math.complex'
local sector = require 'pixel.util.geometry.sector'

local path = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/data/map.txt'

local level = nil

function world.load()
    level = { vertices = {}, sectors = {}, position = nil, angle = nil, currentsector = nil }
    local file = io.open(path, 'r')
    local data = file:read '*a'
    file:close()
    local lines = {}
    for line in string.lines(data) do
        line = string.trim(line:gsub('\t', ' '))
        while true do
            local nline = line:gsub('  ', ' ')
            if nline == line then
                break
            end
            line = nline
        end
        table.insert(lines, line)
    end

    for lineno, line in ipairs(lines) do
        local len = line:len()
        if len > 0 then
            local vals = vim.split(line, ' ', { plain = true, trimempty = true })
            local commentindex = nil
            for i, x in ipairs(vals) do
                if x:sub(1, 1) == '#' then
                    commentindex = i
                    break
                end
            end
            if commentindex then
                for i = commentindex, #vals do
                    vals[i] = nil
                end
            end
            local amt = #vals
            if amt > 0 then
                if vals[1] == 'vertex' then
                    local y = tonumber(vals[2])
                    if y then
                        for i = 3, amt do
                            local x = tonumber(vals[i])
                            if x then
                                table.insert(level.vertices, complex(x, y))
                            else
                                error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                            end
                        end
                    else
                        error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                    end
                elseif vals[1] == 'sector' then
                    local floor_height, ceiling_height = tonumber(vals[2]), tonumber(vals[3])
                    if not floor_height or not ceiling_height then
                        error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                    end
                    amt = amt - 3
                    if amt % 2 ~= 0 then
                        error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                    end
                    local verts = {}
                    local portals = {}
                    amt = amt / 2
                    for i = 1, amt do
                        table.insert(verts, vals[i + 3])
                        table.insert(portals, vals[i + amt + 3])
                    end
                    for i = 1, amt do
                        verts[i] = tonumber(verts[i])
                        if not verts[i] then
                            error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                        end
                        if portals[i] ~= 'x' then
                            portals[i] = tonumber(portals[i])
                            if not portals[i] then
                                error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                            end
                        end
                    end
                    local sect = sector(verts, portals)
                    if sect then
                        table.insert(level.sectors, sect)
                    else
                        error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                    end
                elseif vals[1] == 'player' then
                    local x, y, angle, sectornum = tonumber(vals[2]), tonumber(vals[3]), tonumber(vals[4]), tonumber(vals[5])
                    if not x or not y or not angle or not sectornum then
                        error('Invalid ' .. vals[1] .. ' line (' .. lineno .. '): ' .. line)
                    end
                    level.position, level.angle, level.currentsector = complex(x, y), angle, sectornum
                elseif vals[1] == 'light' then
                end
            end
        end
    end
    print(vim.inspect(level))
end

world.load()

return world
