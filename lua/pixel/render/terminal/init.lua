local terminal = {}

local string = require 'toolshed.util.string'
local stdout = vim.loop.new_pipe(false)
stdout:open(1)

local queue = require('toolshed.util.generic.queue').new()
local writing = false
local faulted, fault = false, nil
local transaction_count = 0

local function write_next(data)
    local ret = vim.loop.write(stdout, data, function(err)
        if err then
            faulted, writing, fault = true, false, err
        elseif queue:size() > 0 then
            if queue:size() == 1 then
                write_next(queue:dequeue())
            else
                local group = {}
                for i = 1, queue:size() do
                    group[i] = queue:dequeue()
                end
                write_next(group)
            end
        else
            writing = false
        end
    end)
    if not ret then
        faulted, writing, fault = true, false, ret
    else
        writing = true
    end
end

local function write(data)
    if not faulted then
        if transaction_count > 0 or writing then
            queue:enqueue(data)
        else
            write_next(data)
        end
    end
end

function terminal.last_error()
    return faulted, fault
end
function terminal.begin_transaction()
    transaction_count = transaction_count + 1
end

function terminal.end_transaction()
    if transaction_count > 0 then
        transaction_count = transaction_count - 1
        if transaction_count == 0 then
            if queue:size() > 0 then
                local group = {}
                for i = 1, queue:size() do
                    group[i] = queue:dequeue()
                end
                write_next(group)
            end
        end
    end
end

function terminal.write(...)
    for _, data in ipairs { ... } do
        local t = type(data)
        if t == 'string' then
            write(data)
        elseif t == 'table' then
            local amt = #data
            if amt > 0 then
                for _, x in ipairs(data) do
                    if type(x) ~= 'string' then
                        goto continue
                    end
                end
                write(table.concat(data))
            end
        elseif t == 'number' then
            write(tostring(data))
        end
        ::continue::
    end
end

function terminal.execute_at(row, col, func, ...)
    terminal.begin_transaction()
    write '\x1b[s'
    write('\x1b[' .. math.floor(math.abs(row)) .. ';' .. math.floor(math.abs(col)) .. 'H')
    local ret = { pcall(func, row, col, ...) }
    write '\x1b[u'
    terminal.end_transaction()
    if not ret[1] then
        return nil, ret[2]
    end
    return unpack(ret, 1)
end

return terminal
