local M = {}

local cache = require("pixel.cache")
local math = require("toolshed.util.math")
local co = coroutine

local options = {
	setup_pending = true,
	rows = 20,
	cols = 20,
	animation_func = nil,
	framerate = 10,
	ns = nil,
}

local win = nil
local buf = nil
local grid = {}
local highlights = {}

local char, ichar = "▀", "▄"
local charlen = char:len()

local draw_coroutine = nil
local color_enabled = true

local redraw
redraw = function()
	if win then
		if options.animation_func then
			cache.begin_transaction()
			if not draw_coroutine then
				draw_coroutine = co.create(options.animation_func)
			end
			local success, err = co.resume(draw_coroutine)
			cache.end_transaction()
			M.show()
			if success then
				if co.status(draw_coroutine) == "dead" then
					draw_coroutine = nil
				end
				vim.defer_fn(redraw, math.round(1000 / options.framerate))
			else
				draw_coroutine = nil
				print("DRAWING ERROR: " .. err)
			end
		end
	end
end

function M.setup(opts)
	if not opts then
		opts = {}
	end
	if not opts.rows then
		opts.rows = options.rows
	end
	if not opts.cols then
		opts.cols = options.cols
	end
	if type(opts.rows) ~= "number" then
		return nil, "rows is not a number"
	end
	if type(opts.cols) ~= "number" then
		return nil, "cols is not a number"
	end
	opts.cols, opts.rows = math.floor(opts.cols), math.floor(opts.rows)
	if opts.rows < 1 then
		return nil, "rows < 1"
	end
	if opts.cols < 1 then
		return nil, "cols < 1"
	end
	if not opts.framerate then
		opts.framerate = options.framerate
	end
	if type(opts.framerate) ~= "number" then
		return nil, "framerate is not a number"
	elseif opts.framerate <= 0 then
		return nil, "framerate < 0"
	end
	options.rows, options.cols, options.framerate = opts.rows, opts.cols, opts.framerate
	options.ns = vim.api.nvim_create_namespace("vrighter_pixel_nvim")
	for i = 1, options.rows do
		local row = {}
		grid[i] = row
		for j = 1, options.cols do
			row[j] = 0
		end
	end
	local max = math.floor((options.rows + 1) / 2)
	for i = 1, max do
		local r2 = i * 2
		local r1 = r2 - 1
		local row = {}
		highlights[i] = row
		for j = 1, options.cols do
			local col1 = grid[r1][j]
			local col2
			if r2 <= options.rows then
				col2 = grid[r2][j]
			else
				col2 = 0
			end
			row[j] = cache.use_color_pair(col1, col2)
		end
	end
	options.setup_pending = false
end

function M.get(r, c)
	if r < 1 or c < 1 or r > options.rows or c > options.cols then
		return
	end
	return grid[r][c]
end

function M.set(r, c, color)
	if r < 1 or c < 1 or r > options.rows or c > options.cols then
		return false
	end
	if color then
		grid[r][c] = color
		return true
	end
	return false
end

function M.hide()
	if options.setup_pending then
		return
	end
	if win then
		vim.api.nvim_win_close(win, true)
		win = nil
	end
end

function M.toggle()
	if options.setup_pending then
		return
	end
	if win then
		M.hide()
	else
		M.show()
		cache.refresh_highlights()
		redraw()
	end
end

local function render()
	local hl, lines = {}, {}
	local max = math.floor((options.rows + 1) / 2)
	for r = 1, max do
		local line = {}
		local r2 = r * 2
		local r1 = r2 - 1
		local hl_col_index = 0
		local row = highlights[r]
		for c = 1, options.cols do
			local col1 = grid[r1][c]
			local col2
			if r2 <= options.rows then
				col2 = grid[r2][c]
			else
				col2 = 0
			end
			cache.unuse_highlight(row[c])
			local inverted
			row[c], inverted = cache.use_color_pair(col1, col2)
			line[c] = inverted and ichar or char
			local newhlindex = hl_col_index + charlen
			table.insert(hl, { row = r - 1, col = hl_col_index, col_end = newhlindex, hl = row[c] })
			hl_col_index = newhlindex
		end
		lines[r] = table.concat(line)
	end
	return hl, lines
end

function M.show()
	if options.setup_pending then
		return
	end
	local hl, lines = render()
	if not buf then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(buf, "filetype", "philips_hue_map")
		vim.api.nvim_buf_set_option(buf, "fileencoding", "utf-8")
		vim.api.nvim_buf_set_option(buf, "undolevels", -1)
	end

	if not win then
		local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
		local row, col = math.round(height / 2 - ((options.rows + 1) / 2) / 2), math.round(width / 2 - options.cols / 2)

		win = vim.api.nvim_open_win(buf, false, {
			width = options.cols,
			height = math.floor((options.rows + 1) / 2),
			relative = "editor",
			col = col,
			row = row,
			anchor = "NW",
			style = "minimal",
			focusable = false,
			border = "rounded",
		})
		vim.api.nvim_win_set_option(win, "wrap", false)
	else
		vim.api.nvim_win_set_buf(win, buf)
	end

	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_clear_namespace(buf, options.ns, 0, -1)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
	if color_enabled then
		for _, h in ipairs(hl) do
			vim.api.nvim_buf_add_highlight(buf, options.ns, h.hl, h.row, h.col, h.col_end)
		end
	end
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.rows()
	return options.rows
end

function M.cols()
	return options.cols
end

function M.toggle_colors()
	color_enabled = not color_enabled
end

function M.set_animation(func)
	if type(func) ~= "function" then
		return false
	else
		options.animation_func = func
		return true
	end
end

return M
