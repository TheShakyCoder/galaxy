--[[
Mineable resource balances: the one place a player GAINS Water, Iron or
Hydrogen.

The three balances live in the player's saved profile (profile/state, see
main/session.lua's own M.water/M.iron/M.hydrogen), separate from the two
currencies Tope and Valour. They were static placeholders until mining
existed; now a player whose final shot depletes an asteroid is credited
that asteroid's own resource amount (main/data/asteroids.lua
resource_amount), decided by the system's match (system_match.lua) - never
an amount the client reports.

Read-modify-write with the storage version, retried on conflict, exactly
like modules/progress.lua's own XP grant: both can happen between a
player's economy operations, so neither may overwrite the other.

There is no RPC here: the only caller is the system match (the economy RPC
in modules/economy.lua still owns everything the player spends).
]]

local nk = require("nakama")

local M = {}

local COLLECTION, KEY = "profile", "state"
local MAX_WRITE_ATTEMPTS = 5

-- resource id (main/data/asteroids.lua M.RESOURCES) -> profile field. Inert
-- rock is deliberately absent: it holds nothing, so there's nothing to add.
local FIELD = { water = "water", iron = "iron", hydrogen = "hydrogen" }

-- Adds `amount` of `resource_id` to `user_id`'s saved inventory and returns
-- the new balance, or nil (unknown/worthless resource, non-positive amount,
-- no profile yet, or the profile kept changing underneath).
function M.apply(user_id, resource_id, amount)
	local field = FIELD[resource_id]
	if not field or type(amount) ~= "number" or amount <= 0 then
		return nil
	end
	for _ = 1, MAX_WRITE_ATTEMPTS do
		local objects = nk.storage_read({ { collection = COLLECTION, key = KEY, user_id = user_id } })
		local object = objects[1]
		if not (object and object.value and object.value.faction) then
			return nil
		end
		local profile = object.value
		profile[field] = (profile[field] or 0) + amount
		local ok = pcall(nk.storage_write, { {
			collection = COLLECTION, key = KEY, user_id = user_id, value = profile,
			version = object.version,
			permission_read = 1, permission_write = 0,
		} })
		if ok then
			return profile[field]
		end
	end
	nk.logger_warn(string.format("resources: couldn't save %s +%d for %s after %d attempts", resource_id, amount, user_id, MAX_WRITE_ATTEMPTS))
	return nil
end

return M
