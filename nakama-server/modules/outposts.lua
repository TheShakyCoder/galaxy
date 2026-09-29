--[[
Outpost hull and destruction state, per system and faction.

An outpost (main/data/star_systems.lua outpost_position/has_outpost) has
OUTPOST_HULL hull points. Players of the other faction can shoot it (damage
is applied by modules/system_match.lua, the one writer for its system). At
zero hull it's destroyed: it leaves the system for DESTROYED_FOR_MS, then
returns at full hull. While destroyed it counts as "no outpost here" for
docking, launching and respawning (main/session.lua outpost_available, which
modules/economy.lua points at get() below).

Values from the BSGO wiki's Outposts page: a regular outpost has 50,000 hull
points, and a destroyed outpost's faction waits 60 minutes before it can
return. (Upgraded/fortified outposts and hull scaling aren't modelled yet.)

Storage: outposts/<system>.<faction>, owned by the system user:
  { hp, destroyed_until (ms, only while destroyed) }
No record = never damaged (full hull).

RPC outpost_status { system_id } -> { accord = state, swarm = state, now }
  state = { exists, hp, max_hp, available, destroyed_until } - for the
  outpost screen, which isn't in any system's match.
]]

local nk = require("nakama")
local star_systems = require("main.data.star_systems") -- copied from the game by tools/sync_server_rules.py

local M = {}

M.OUTPOST_HULL = 50000
M.DESTROYED_FOR_MS = 60 * 60 * 1000
M.FACTIONS = { "accord", "swarm" }

local COLLECTION = "outposts"
local SYSTEM_USER = "00000000-0000-0000-0000-000000000000"

local function key(system_id, faction)
	return system_id .. "." .. faction
end

function M.read(system_id, faction)
	local objects = nk.storage_read({ { collection = COLLECTION, key = key(system_id, faction), user_id = SYSTEM_USER } })
	return objects[1] and objects[1].value or nil
end

function M.write(system_id, faction, record)
	nk.storage_write({ {
		collection = COLLECTION, key = key(system_id, faction), user_id = SYSTEM_USER, value = record,
		permission_read = 0, permission_write = 0,
	} })
end

-- The outpost's current state from a stored record (or nil), at time `now`
-- (ms). An expired destruction means it has returned at full hull.
function M.state(system_id, faction, record, now)
	if not star_systems.has_outpost(system_id, faction) then
		return { exists = false, hp = 0, max_hp = 0, available = false }
	end
	record = record or {}
	if record.destroyed_until and now < record.destroyed_until then
		return { exists = true, hp = 0, max_hp = M.OUTPOST_HULL, available = false, destroyed_until = record.destroyed_until }
	end
	if record.destroyed_until then
		return { exists = true, hp = M.OUTPOST_HULL, max_hp = M.OUTPOST_HULL, available = true }
	end
	local hp = record.hp or M.OUTPOST_HULL
	return { exists = true, hp = hp, max_hp = M.OUTPOST_HULL, available = hp > 0 }
end

function M.get(system_id, faction)
	return M.state(system_id, faction, M.read(system_id, faction), nk.time())
end

local function outpost_status(context, payload)
	local ok, input = pcall(nk.json_decode, payload ~= "" and payload or "{}")
	local system_id = ok and type(input) == "table" and input.system_id
	if type(system_id) ~= "string" or not star_systems.SYSTEMS[system_id] then
		return nk.json_encode({ error = "Unknown system." })
	end
	local result = { now = nk.time() }
	for _, faction in ipairs(M.FACTIONS) do
		result[faction] = M.get(system_id, faction)
	end
	return nk.json_encode(result)
end

nk.register_rpc(outpost_status, "outpost_status")

return M
