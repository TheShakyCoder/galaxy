-- Flight presentation only: no gameplay state or input bindings.
local M = { columns = 12, spacing = 68, center_x = 960, bottom_y = 104, row_height = 88,
    gauge_width = 240, gauge_height = 5 }
local order = {W=1, C=2, E=3, H=4}
function M.slots(positions)
    local ids = {}
    for id in pairs(positions or {}) do ids[#ids+1] = id end
    table.sort(ids, function(a,b)
        local ap,an = a:match("^(%a)(%d+)$")
        local bp,bn = b:match("^(%a)(%d+)$")
        local ar,br = order[ap] or 9,order[bp] or 9
        if ar ~= br then return ar < br end
        if ap == bp and tonumber(an) ~= tonumber(bn) then return tonumber(an) < tonumber(bn) end
        return a < b
    end)
    return ids
end
function M.position(index, count)
    local columns = math.ceil(count/math.ceil(count/M.columns))
    local row = math.floor((index-1)/columns)
    local in_row = math.min(columns, count-row*columns)
    return M.center_x + ((index-1)%columns-(in_row-1)*0.5)*M.spacing,
        M.bottom_y + row*M.row_height
end
function M.fraction(value, maximum)
    if not maximum or maximum <= 0 then return 0 end
    return math.max(0,math.min(1,(value or 0)/maximum))
end
return M
