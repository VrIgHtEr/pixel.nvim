return {
    config = function()
        vim.o.termguicolors = true
        nnoremap('<leader>sp', ':lua require"pixel".toggle()<cr>', 'silent', 'Pixel: switch on and off pixel display')
        local mul = 5
        require('pixel').setup { rows = 9 * mul + bit.band(mul, 1), cols = 16 * mul, framerate = 1 }
        require('pixel').set_animation(require 'pixel.animations.portrend')
    end,
}
