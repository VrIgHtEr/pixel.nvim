return {
    config = function()
        vim.o.termguicolors = true
        nnoremap('<leader>sp', ':lua require"pixel".toggle()<cr>', 'silent', 'Pixel: switch on and off pixel display')
        local mul = 4
        require('pixel').setup { rows = 9 * mul, cols = 16 * mul, framerate = 10 }
        require('pixel').set_animation(require 'pixel.animations.portrend')
    end,
}
