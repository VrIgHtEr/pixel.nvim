local M = {}

local freelist = {}
local hlcache = {}
local hlgroups = {}
local hlindex = 0
local dirty = {}

local color = require 'pixel.color'

local transaction = false

local function purge_highlight(key, cached)
    hlgroups[cached.group] = nil
    table.insert(freelist, cached.id)
    hlcache[key.a][key.b] = nil
    hlcache[key.a].count = hlcache[key.a].count - 1
    if hlcache[key.a].count == 0 then
        hlcache[key.a] = nil
    end
end

function M.begin_transaction()
    if transaction then
        return false
    end
    transaction = true
    return true
end

function M.end_transaction()
    if not transaction then
        return false
    end
    local cmds = {}
    local cmdindex = 0

    for cached, needs_update in pairs(dirty) do
        local key = hlgroups[cached.group]
        if cached.refcount == 0 then
            purge_highlight(key, cached)
        elseif needs_update then
            cmdindex = cmdindex + 1
            cmds[cmdindex] = { 'hi ', cached.group, ' guifg=', color.int_to_hex(key.a), ' guibg=', color.int_to_hex(key.b) }
        end
    end
    dirty = {}
    for i, cmd in ipairs(cmds) do
        cmds[i] = table.concat(cmd)
    end
    cmds = table.concat(cmds, '\n')
    vim.api.nvim_exec(cmds, true)
    transaction = false
    return true
end

local function group_name(id)
    return 'px' .. tostring(id)
end

function M.use_color_pair(a, b)
    local cached = hlcache[a]
    if not cached then
        cached = { count = 0 }
        hlcache[a] = cached
    end
    cached = cached[b]

    if not cached then
        local id
        if #freelist > 0 then
            id = table.remove(freelist)
        else
            id = hlindex
            hlindex = hlindex + 1
        end
        cached = { refcount = 0, id = id, group = group_name(id) }
        hlgroups[cached.group] = { a = a, b = b }

        hlcache[a][b] = cached
        if transaction then
            dirty[cached] = true
        else
            local cmd = 'highlight ' .. cached.group .. ' guifg=' .. color.int_to_hex(a) .. ' guibg=' .. color.int_to_hex(b)
            vim.api.nvim_exec(cmd, true)
        end
    end
    cached.refcount = cached.refcount + 1
    return cached.group
end

function M.unuse_highlight(hl)
    local key = hlgroups[hl]
    if key then
        local cached = hlcache[key.a][key.b]
        cached.refcount = cached.refcount - 1
        if cached.refcount == 0 then
            if transaction then
                dirty[cached] = dirty[cached] or false
            else
                purge_highlight(key, cached)
            end
        end
    end
end

function M.refresh_highlights()
    for group, pair in pairs(hlgroups) do
        vim.api.nvim_exec('highlight ' .. group .. ' guifg=' .. color.int_to_hex(pair.a) .. ' guibg=' .. color.int_to_hex(pair.b), true)
    end
end

return M
