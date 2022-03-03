local pixel = require("pixel")
local math = require("toolshed.util.math")

local M = {}

function M.clear(col)
	if not col then
		col = 0
	end
	for r = 1, pixel.rows() do
		for c = 1, pixel.cols() do
			pixel.set(r, c, col)
		end
	end
end

function M.line(x0, y0, x1, y1, col)
	if not col then
		col = 16777215
	end
	x0, y0, x1, y1 = math.round(x0), math.round(y0), math.round(x1), math.round(y1)

	local dx = math.abs(x1 - x0)
	local sx
	if x0 < x1 then
		sx = 1
	else
		sx = -1
	end
	local dy = -math.abs(y1 - y0)
	local sy
	if y0 < y1 then
		sy = 1
	else
		sy = -1
	end
	local err = dx + dy
	while true do
		pixel.set(y0, x0, col)
		if x0 == x1 and y0 == y1 then
			break
		end
		local e2 = 2 * err
		if e2 >= dy then
			if x0 == x1 then
				break
			end
			err = err + dy
			x0 = x0 + sx
		end
		if e2 <= dx then
			if y0 == y1 then
				break
			end
			err = err + dx
			y0 = y0 + sy
		end
	end
end

return M
