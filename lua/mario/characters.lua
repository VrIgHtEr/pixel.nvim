local M
local image = require 'pixel.image'
local img

M = {
    data = {
        {
            anim = {
                x = 0,
                y = 0,
                w = 32,
                h = 32,
                frames = 3,
                stride_x = 32,
                stride_y = 32,
                speed = 3,
            },
        },
        {
            anim = {
                x = 0,
                y = 64,
                w = 32,
                h = 32,
                frames = 3,
                stride_x = 32,
                stride_y = 32,
                speed = 3,
            },
        },
        {
            anim = {
                x = 0,
                y = 128,
                w = 32,
                h = 32,
                frames = 2,
                stride_x = 32,
                stride_y = 32,
                speed = 5,
            },
        },
        {
            anim = {
                x = 0,
                y = 192,
                w = 32,
                h = 32,
                frames = 2,
                stride_x = 32,
                stride_y = 32,
                speed = 5,
            },
        },
        {
            anim = {
                x = 0,
                y = 256,
                w = 32,
                h = 32,
                frames = 3,
                stride_x = 32,
                stride_y = 32,
                speed = 3,
            },
        },
    },
    exec = function(key)
        for _, c in ipairs(M.data) do
            c[key]()
        end
    end,
    destroy = function()
        if img then
            M.exec 'destroy'
            img.destroy()
            img = nil
        end
    end,
    init = function()
        img = image.new { src = vim.fn.stdpath 'data' .. '/site/pack/vrighter/opt/pixel.nvim/lua/mario/sprites.png', auto_reclaim = true }
        img.size = { x = 96, y = 320 }
        img.transmit()
        for i, character in ipairs(M.data) do
            local c = character
            c.placement = img.create_placement()
            c.state = 'halted'
            c.anim = c.anim ~= nil and c.anim or { x = 0, y = 0, w = img.size.x, h = img.size.y, frames = 1, stride_x = 0, stride_y = 0 }
            c.anim.z = -i
            if c.dir == nil then
                c.dir = math.random(0, 1) == 0
            end
            c.hide = function()
                c.placement.hide()
            end
            function c.display(opts)
                c.placement.display(opts)
            end
            function c.destroy()
                if c.placement then
                    c.placement.destroy()
                    c = nil
                end
            end
        end
        for i = #M.data, 2, -1 do
            local j = math.random(1, i)
            M.data[i].anim.z, M.data[j].anim.z = M.data[j].anim.z, M.data[i].anim.z
        end
    end,
}
return M
