-- Flight presentation only: no gameplay state or input bindings.
local M = { columns = 10, spacing = 68, center_x = 1120, bottom_y = 110, row_height = 88,
    gauge_width = 240, gauge_height = 5,
    diagram_x = 530, diagram_y = 260, diagram_scale = 0.72 }
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
    if count == 0 then return M.center_x, M.bottom_y end
    local columns = math.ceil(count/math.ceil(count/M.columns))
    local row = math.floor((index-1)/columns)
    local in_row = math.min(columns, count-row*columns)
    return M.center_x + ((index-1)%columns-(in_row-1)*0.5)*M.spacing,
        M.bottom_y + row*M.row_height
end
-- Weapon anchors use exactly the same coordinate transform as the ship image.
-- Other equipment keeps a compact, deterministic row layout.
function M.placements(positions)
    local result, services = {}, {}
    for _,id in ipairs(M.slots(positions)) do
        local offset = positions[id]
        if id:match("^W%d+$") then
            result[id] = {x=M.diagram_x+offset.x*M.diagram_scale,
                y=M.diagram_y+offset.y*M.diagram_scale}
        else services[#services+1] = id end
    end
    for i,id in ipairs(services) do
        local x,y=M.position(i,#services)
        result[id]={x=x,y=y}
    end
    return result
end
function M.fraction(value, maximum)
    if not maximum or maximum <= 0 then return 0 end
    return math.max(0,math.min(1,(value or 0)/maximum))
end
return M
