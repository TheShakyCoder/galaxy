-- Aggregates every fittable module-type data table (weapons_autocannons.lua,
-- weapons_launchers.lua, computer_modules.lua, hull_modules.lua,
-- engine_modules.lua, §2.8/§3.1) into one lookup, so callers — e.g. the
-- outpost screen's installed/owned/purchasable tabs — don't need to know
-- which specific table an item key lives in.
--
-- ordinance.lua is deliberately NOT aggregated here: ordinance (cannon
-- rounds, missiles, torpedoes) is not a fittable module — it's ammunition
-- consumed by a fitted weapon, reached via its own table (§2.8).

local autocannons = require("main.data.modules.weapons_autocannons")
local launchers = require("main.data.modules.weapons_launchers")
local computer_modules = require("main.data.modules.computer_modules")
local hull_modules = require("main.data.modules.hull_modules")
local engine_modules = require("main.data.modules.engine_modules")

local M = {}

-- Every module currently defined, keyed by item id, regardless of which
-- source table it came from.
M.ALL = {}
for key, entry in pairs(autocannons.AUTOCANNONS) do
	M.ALL[key] = entry
end
for key, entry in pairs(launchers.LAUNCHERS) do
	M.ALL[key] = entry
end
for key, entry in pairs(computer_modules.COMPUTER_MODULES) do
	M.ALL[key] = entry
end
for key, entry in pairs(hull_modules.HULL_MODULES) do
	M.ALL[key] = entry
end
for key, entry in pairs(engine_modules.ENGINE_MODULES) do
	M.ALL[key] = entry
end

function M.get(item_key)
	return M.ALL[item_key]
end

-- The name to show for `entry` (a catalog entry) to a player in `faction`
-- ("accord"/"swarm") - `entry.faction_names[faction]` when the entry
-- carries a two-faction name, else the plain `entry.name`, else nil. The
-- combat weapons split their name per faction (Accord "MEC-A6 'Fang'" vs
-- Swarm "Type A 'Aggressor'", weapons_autocannons.lua's header); entries the
-- reference lists with a single shared name, plus hull/engine/computer
-- modules, have only a plain `name` and fall through unchanged. Ships resolve the same way via their own `faction_skins`
-- (§2.1.2), so every module-name call site should go through this instead
-- of reading `entry.name` directly.
function M.name_for(entry, faction)
	if not entry then
		return nil
	end
	local names = entry.faction_names
	if names and faction and names[faction] then
		return names[faction]
	end
	return entry.name
end

return M
