local M = {}
function M.reverse(tbl)
    local amt = #tbl
    for i = 1, amt / 2 do
        tbl[i], tbl[amt - i + 1] = tbl[amt - i + 1], tbl[i]
    end
    return tbl
end
return M
