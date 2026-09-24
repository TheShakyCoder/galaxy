-- Aggregates every module-type data table (weapons_autocannons.lua,
-- computer_modules.lua, hull_modules.lua, engine_modules.lua, and future
-- launcher/ordinance tables, §2.8/§3.1) into one lookup, so callers — e.g.
-- the outpost screen's installed/owned/purchasable tabs — don't need to
-- know which specific table an item key lives in.

local autocannons = require("main.data.modules.weapons_autocannons")
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

return M
