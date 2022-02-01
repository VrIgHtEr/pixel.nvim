return {
    config = function()
        nnoremap('<leader>sp', ':lua require"pixel".toggle()<cr>', 'silent', 'Pixel: switch on and off pixel display')
        require('pixel').setup { rows = 90, cols = 160, framerate = 10 }
        require('pixel').set_animation(require 'pixel.animations.cycle')
    end,
}
