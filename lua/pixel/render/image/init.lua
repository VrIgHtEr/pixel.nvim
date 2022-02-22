local image = {}
local MT = {
    __index = image,
    __metatable = function() end,
}

local format = { rgb = 24, argb = 32, png = 100 }

local defaults = {
    format = format.png,
}

function image.new(opts)
    opts = opts == nil and {} or opts
    opts = vim.tbl_deep_extend('force', defaults, opts)
    print(vim.inspect(opts))
    local ret = setmetatable({}, MT)
    if not opts.src then
        error 'source not provided'
    end
    return ret
end

image.new { src = '/home/cedric/dice.png' }

return image
