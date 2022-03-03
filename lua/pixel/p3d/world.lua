local string = require("toolshed.util.string")
local complex = require("toolshed.util.math.complex")
local sector = require("pixel.p3d.sector")

---@class level
---@field vertices complex[]
---@field sectors sector[]
---@field position complex
---@field angle number
---@field currentsector number
---@field playerheight number

local world = {}

---@param path string
---@return level
function world.load(path)
	local level = { vertices = {}, sectors = {}, position = nil, angle = nil, currentsector = nil }
	local file = io.open(path, "r")
	local data = file:read("*a")
	file:close()
	local lines = {}
	for line in string.lines(data) do
		line = string.trim(line:gsub("\t", " "))
		while true do
			local nline = line:gsub("  ", " ")
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
			local vals = vim.split(line, " ", { plain = true, trimempty = true })
			local commentindex = nil
			for i, x in ipairs(vals) do
				if x:sub(1, 1) == "#" then
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
				if vals[1] == "vertex" then
					local y = tonumber(vals[2])
					if y then
						for i = 3, amt do
							local x = tonumber(vals[i])
							if x then
								table.insert(level.vertices, complex(x, y))
							else
								error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
							end
						end
					else
						error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
					end
				elseif vals[1] == "sector" then
					local floor_height, ceiling_height = tonumber(vals[2]), tonumber(vals[3])
					if not floor_height or not ceiling_height then
						error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
					end
					amt = amt - 3
					if amt % 2 ~= 0 then
						error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
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
							error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
						end
						if portals[i] ~= "x" then
							portals[i] = tonumber(portals[i])
							if not portals[i] then
								error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
							end
						end
					end
					local sect = sector(floor_height, ceiling_height, verts, portals)
					if sect then
						table.insert(level.sectors, sect)
					else
						error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
					end
				elseif vals[1] == "player" then
					local x, y, angle, sectornum =
						tonumber(vals[2]), tonumber(vals[3]), tonumber(vals[4]), tonumber(vals[5])
					if not x or not y or not angle or not sectornum then
						error("Invalid " .. vals[1] .. " line (" .. lineno .. "): " .. line)
					end
					level.position, level.angle, level.currentsector = complex(x, y), angle, sectornum + 1
				elseif vals[1] == "light" then
				end
			end
		end
	end
	for i, x in ipairs(level.sectors) do
		if not x:validate(level.vertices, level.sectors) then
			error("Invalid sector " .. i)
		end
	end
	if not level.position or not level.angle or not level.currentsector then
		error("player line was not found")
	end
	if level.currentsector < 1 or level.currentsector > #level.sectors then
		error("Invalid player sector number: " .. level.currentsector)
	end

	--TODO: validate player inside sector

	level.playerheight = 1

	level.angle = level.angle - math.pi / 2
	return level
end

---@param level level
---@param width number
---@param height number
---@param set_pixel function
function world.render(level, width, height, set_pixel)
	local set_pix = function(x, y, col)
		y = height - y + 1
		set_pixel(x, y, col)
	end
	local sect = level.sectors[level.currentsector]
	local player_height = sect.floor + level.playerheight
	local stack = { { sector = sect, left = 0, right = width } }
	local top, bottom = {}, {}
	for i = 1, width do
		top[i], bottom[i] = height + 1, 1
	end
	local rot = complex(math.cos(level.angle), -math.sin(level.angle))
	local halfwidth, halfheight = width / 2, height / 2 / 2
	while #stack > 0 do
		local next = table.remove(stack)
		next.sector:render(
			halfwidth,
			halfheight,
			level.position,
			rot,
			player_height,
			stack,
			level.vertices,
			level.sectors,
			top,
			bottom,
			next.left,
			next.right,
			set_pix
		)
	end
end

return world
