--[[
Outposts per system and faction: Outpost Progress, control level, hull and
destruction, beacon and sentry platforms (plan.md §2.7 "Outpost progression").

The rules - what a progress value puts in a system, how it drains, what is
permanent, how hull scales - are main/outpost_rules.lua (copied from the game
by tools/sync_server_rules.py), so the game and the server agree. This module
stores the records and answers questions about them; the system's match
(modules/system_match.lua) is the one writer while players are there: it adds
progress for mining and presence, and applies weapon damage.

Storage: outposts/<system>.<faction>, owned by the system user - the record
shape documented in main/outpost_rules.lua ({ pct, pct_at, hp_frac,
destroyed_until, beacon, platforms }). No record = never touched: no
progress (or the permanent floor), full hull. A record from before
progression ({ hp }) still reads correctly: hp becomes a fraction of 50,000.

Galaxy-wide questions (how many outposts each faction holds - the underdog
hull scale and the +1 %/outpost XP and mining bonus - and the nearest outpost
for docking) read every record at once (storage list), cached for
GALAXY_CACHE_MS per server runtime.

RPCs:
  outpost_status { system_id } -> { accord = state, swarm = state, now }
    state = main/outpost_rules.lua state() (both factions' outposts there)
  outpost_galaxy {} -> { now, systems = { [system_id] = { accord = brief, swarm = brief } } }
    brief = { pct, level, present, available, permanent, destroyed_until } -
    for docking at the nearest outpost and the sector map
]]

local nk = require("nakama")
local star_systems = require("main.data.star_systems") -- copied from the game by tools/sync_server_rules.py
local outpost_data = require("main.data.outposts") -- likewise
local rules = require("main.outpost_rules") -- likewise

local M = {}

M.FACTIONS = outpost_data.FACTIONS

local COLLECTION = "outposts"
local SYSTEM_USER = "00000000-0000-0000-0000-000000000000"
local GALAXY_CACHE_MS = 2000
local LEGACY_HULL = 50000 -- records written before progression stored absolute hp

local function key(system_id, faction)
	return system_id .. "." .. faction
end

-- Every stored record, keyed "<system>.<faction>" - refreshed at most every
-- GALAXY_CACHE_MS, and updated in place by M.write on this runtime.
local galaxy_cache = { at = -math.huge, records = {} }

local function all_records(now)
	if now - galaxy_cache.at < GALAXY_CACHE_MS then
		return galaxy_cache.records
	end
	local records, cursor = {}, nil
	repeat
		local objects, next_cursor = nk.storage_list(SYSTEM_USER, COLLECTION, 100, cursor)
		for _, object in ipairs(objects or {}) do
			records[object.key] = object.value
		end
		cursor = next_cursor
	until not cursor or cursor == ""
	galaxy_cache = { at = now, records = records }
	return records
end

local function upgrade_legacy(record)
	if record and record.hp and not record.hp_frac then
		record.hp_frac = math.max(0, math.min(1, record.hp / LEGACY_HULL))
		record.hp = nil
	end
	return record
end

function M.read(system_id, faction)
	local objects = nk.storage_read({ { collection = COLLECTION, key = key(system_id, faction), user_id = SYSTEM_USER } })
	return upgrade_legacy(objects[1] and objects[1].value or nil)
end

function M.write(system_id, faction, record)
	nk.storage_write({ {
		collection = COLLECTION, key = key(system_id, faction), user_id = SYSTEM_USER, value = record,
		permission_read = 0, permission_write = 0,
	} })
	galaxy_cache.records[key(system_id, faction)] = record
end

-- Galaxy summary at `now` (ms): states[system][faction] (rule states at
-- scale 1 - enough for presence/availability) and counts[faction] = held
-- (available) outposts.
function M.galaxy(now)
	local records = all_records(now)
	local states, counts = {}, { accord = 0, swarm = 0 }
	for system_id in pairs(star_systems.SYSTEMS) do
		states[system_id] = {}
		for _, faction in ipairs(M.FACTIONS) do
			local st = rules.state(system_id, faction, upgrade_legacy(records[key(system_id, faction)]), now, 1)
			states[system_id][faction] = st
			if st.available then
				counts[faction] = counts[faction] + 1
			end
		end
	end
	return states, counts
end

-- How many outposts `faction` holds across the galaxy right now.
function M.held(faction)
	local _, counts = M.galaxy(nk.time())
	return counts[faction] or 0
end

-- The underdog hull scale for `faction` right now (main/outpost_rules.lua).
function M.hull_scale(faction)
	local _, counts = M.galaxy(nk.time())
	return rules.hull_scale(faction, counts)
end

-- The galaxy-wide reward multipliers for a pilot of `faction` (+1 % XP and
-- mining income per outpost the faction holds, BSGO Nova).
function M.xp_multiplier(faction)
	return 1 + outpost_data.REWARDS.xp_bonus_per_outpost * M.held(faction)
end

function M.mining_multiplier(faction)
	return 1 + outpost_data.REWARDS.mining_bonus_per_outpost * M.held(faction)
end

-- The outpost's full current state (rules.state), read fresh.
function M.state(system_id, faction, record, now)
	return rules.state(system_id, faction, record, now, M.hull_scale(faction))
end

function M.get(system_id, faction)
	return M.state(system_id, faction, M.read(system_id, faction), nk.time())
end

-- Is `faction`'s outpost in `system_id` available for docking/launching/
-- respawning? From the galaxy cache, so the nearest-outpost search in
-- main/session.lua docked_system() costs one storage list, not 58 reads.
function M.available(system_id, faction)
	local states = M.galaxy(nk.time())
	local st = states[system_id] and states[system_id][faction]
	return st ~= nil and st.available
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

local function outpost_galaxy(context, payload)
	local now = nk.time()
	local states = M.galaxy(now)
	local systems = {}
	for system_id, by_faction in pairs(states) do
		local entry = {}
		for faction, st in pairs(by_faction) do
			if st.exists then
				entry[faction] = {
					pct = math.floor(st.pct * 10 + 0.5) / 10, level = st.level, present = st.present,
					available = st.available, permanent = st.permanent, destroyed_until = st.destroyed_until,
				}
			end
		end
		systems[system_id] = entry
	end
	return nk.json_encode({ now = now, systems = systems })
end

-- XP gained anywhere on the server carries the faction's outpost bonus.
require("progress").set_xp_multiplier(M.xp_multiplier)

nk.register_rpc(outpost_status, "outpost_status")
nk.register_rpc(outpost_galaxy, "outpost_galaxy")

return M
