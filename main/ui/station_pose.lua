-- Shared presentation state for off-world ship rigs only (script.shared_state=1).
local M={target=nil}
function M.set(target) M.target=target end
function M.is_target(position)
    local t=M.target
    return t and math.abs(position.x-t.x)<.01 and math.abs(position.y-t.y)<.01 and math.abs(position.z-t.z)<.01
end
return M
