-- Shared view of the current system's spawned asteroids, written by
-- main/asteroid_hub.script and read by main/player_ship.script for
-- targeting (Tab / click) and weapon fire. Singleton (shared_state = 1 in
-- game.project), same pattern as main/remote_registry.lua.
--
-- M.asteroids = list of { index, pos = vmath.vector3, radius, resource,
-- analysed }, where index is the asteroid's place in
-- main/data/asteroids.lua field_for(system) (target id "asteroid:<index>")
-- and analysed says whether this player has analysed it (so its resource
-- may be shown).

local M = {}

M.asteroids = {}
M.by_index = {}

function M.set(list)
	M.asteroids = list
	M.by_index = {}
	for _, a in ipairs(list) do
		M.by_index[a.index] = a
	end
end

return M
