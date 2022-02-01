local M = {}
function M.round(x)
    if x >= 0 then
        return math.floor(x + 0.5)
    else
        return -math.floor(-x + 0.5)
    end
end
return M
