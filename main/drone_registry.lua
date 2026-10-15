-- Shared view of the current system's NPC drones (plan.md §2.18), as last
-- heard from the server's system match (OP_DRONES, main/network.lua). Written
-- by main/network.lua, smoothed and drawn by main/drones.script (which also
-- fills `pos` with the position actually shown), and read by
-- main/player_ship.script (targeting, radar) and main/system_map.gui_script.
-- Singleton (shared_state = 1), same pattern as main/remote_registry.lua.
--
-- M.drones[index] = { index, type, tier, level, hp, max_hp, down,
--   target = vmath.vector3 (server position), heading = {x, z},
--   pos = vmath.vector3 (shown position, set by drones.script) }

local M = {}

M.drones = {}
M.system_id = nil

-- Replaces the list from a DRONES message for `system_id`.
function M.store(system_id, data)
	if system_id ~= M.system_id then
		M.drones = {}
		M.system_id = system_id
	end
	local seen = {}
	for _, d in ipairs(data.d or {}) do
		local entry = M.drones[d.i] or { index = d.i }
		entry.type, entry.tier, entry.level = d.t, d.r, d.l
		entry.hp, entry.max_hp, entry.down = d.hp, d.m, d.down == true
		entry.target = vmath.vector3(d.x, d.y, d.z)
		entry.heading = { x = d.hx or 0, z = d.hz or 1 }
		entry.pos = entry.pos or entry.target
		M.drones[d.i] = entry
		seen[d.i] = true
	end
	for i in pairs(M.drones) do
		if not seen[i] then
			M.drones[i] = nil
		end
	end
end

function M.clear()
	M.drones = {}
	M.system_id = nil
end

return M
