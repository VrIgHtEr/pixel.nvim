return {
	needs = { "vrighter/toolshed.nvim" },
	after = { "vrighter/toolshed.nvim" },
	config = function()
		local pixel = require("pixel")
		vim.o.termguicolors = true
		nnoremap("<leader>sp", ':lua require"pixel".toggle()<cr>', "silent", "Pixel: switch on and off pixel display")
		nnoremap("<leader>sP", ':lua require"pixel".toggle_colors()<cr>', "silent", "Pixel: toggle colors")
		local mul = 6
		pixel.setup({ rows = 9 * mul + bit.band(mul, 1), cols = 16 * mul, framerate = 25 })
		pixel.set_animation(require("pixel.animations.cycle"))
	end,
}
