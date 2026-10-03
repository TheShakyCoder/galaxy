--[[
XP, levels and daily assignments: the only place a player gains XP.

Every grant is decided here on the server. The game never reports XP it
thinks it earned; it only learns about grants (the reply to an economy
operation, or an OP_PROGRESS message from its system's match).

Events (amounts in main/data/xp_rewards.lua, assignment targets and rewards
in main/data/assignments.lua):
  outpost_damage     units = hull damage dealt to an enemy outpost
  outpost_destroyed  units = XP (the attacker's share of the bonus)
  system_arrival     units = the system_id arrived in
  asteroid_analysed  units = asteroids analysed for the first time

Saved in the profile (profile/state, see main/session.lua):
  xp           total XP (the level comes from main/data/ranks.lua)
  visited      { [system_id] = true }, systems ever arrived in
  assignments  { date = "YYYY-MM-DD", list = { { id, progress, done } },
                 systems = { [system_id] = true } } - today's (00:00 UTC)

RPC assignments -> { date, list = { { id, name, description, target,
progress, done, xp, tope } } } for the player's current profile, as it
would be today (a new day shows fresh ones before any progress is saved).
]]

local nk = require("nakama")
local ranks = require("main.data.ranks")
local rewards = require("main.data.xp_rewards")
local assignment_data = require("main.data.assignments")

local M = {}

local COLLECTION, KEY = "profile", "state"
local MAX_WRITE_ATTEMPTS = 5

-- "YYYY-MM-DD" (UTC) for a time in milliseconds - Howard Hinnant's
-- days-to-civil conversion, so it doesn't depend on os.date.
local function utc_date(now_ms)
	local z = math.floor(now_ms / 86400000) + 719468
	local era = math.floor(z / 146097)
	local doe = z - era * 146097
	local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
	local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local day = doy - math.floor((153 * mp + 2) / 5) + 1
	local month = mp < 10 and mp + 3 or mp - 9
	local year = yoe + era * 400 + (month <= 2 and 1 or 0)
	return string.format("%04d-%02d-%02d", year, month, day)
end
M.utc_date = utc_date

-- Today's assignments for `profile`, starting a fresh set on a new day.
local function todays_assignments(profile, now_ms)
	local today = utc_date(now_ms)
	local current = profile.assignments
	if type(current) ~= "table" or current.date ~= today then
		current = { date = today, list = {}, systems = {} }
		for _, template in ipairs(assignment_data.DAILY) do
			table.insert(current.list, { id = template.id, progress = 0, done = false })
		end
		profile.assignments = current
	end
	current.systems = current.systems or {}
	return current
end

-- Assignment progress an event is worth (nil = none).
local function assignment_units(event, units, assignments)
	if event == "system_arrival" then
		if assignments.systems[units] then
			return nil -- only different systems count
		end
		assignments.systems[units] = true
		return 1
	elseif event == "outpost_destroyed" then
		return nil
	end
	return units
end

-- Applies `event` to the profile table: XP, first-arrival bookkeeping and
-- assignment progress (completing one pays its XP and Tope). Returns
-- { xp_gained, tope_gained, xp, level, level_before, rank, completed }.
function M.grant(profile, event, units, now_ms)
	profile.xp = profile.xp or 0
	profile.visited = profile.visited or {}
	local level_before = ranks.level_for_xp(profile.xp)
	local xp, tope = 0, 0

	if event == "outpost_damage" then
		xp = math.floor(units / rewards.OUTPOST_DAMAGE_PER_XP)
	elseif event == "outpost_destroyed" then
		xp = math.floor(units)
	elseif event == "asteroid_analysed" then
		xp = units * rewards.ASTEROID_FIRST_ANALYSIS
	elseif event == "system_arrival" then
		if not profile.visited[units] then
			profile.visited[units] = true
			xp = rewards.SYSTEM_FIRST_ARRIVAL
		end
	end

	local completed = {}
	local assignments = todays_assignments(profile, now_ms)
	local progress_units = assignment_units(event, units, assignments)
	if progress_units and progress_units > 0 then
		for _, entry in ipairs(assignments.list) do
			local template = assignment_data.BY_ID[entry.id]
			if template and template.event == event and not entry.done then
				entry.progress = math.min(template.target, (entry.progress or 0) + progress_units)
				if entry.progress >= template.target then
					entry.done = true
					xp = xp + template.xp
					tope = tope + template.tope
					table.insert(completed, { id = template.id, name = template.name, xp = template.xp, tope = template.tope })
				end
			end
		end
	end

	profile.xp = profile.xp + xp
	profile.tope = (profile.tope or 0) + tope
	local level = ranks.level_for_xp(profile.xp)
	return {
		xp_gained = xp, tope_gained = tope, xp = profile.xp, level = level, level_before = level_before,
		rank = ranks.rank_name(profile.faction, level), completed = completed,
	}
end

-- Grants `event` to a player's saved profile (read, grant, write with the
-- storage version so a concurrent economy operation isn't overwritten;
-- retried on conflict). For grants from outside an economy operation
-- (system matches). Returns grant()'s result, or nil if the player has no
-- profile or it kept changing underneath.
function M.apply(user_id, event, units)
	for _ = 1, MAX_WRITE_ATTEMPTS do
		local objects = nk.storage_read({ { collection = COLLECTION, key = KEY, user_id = user_id } })
		local object = objects[1]
		if not (object and object.value and object.value.faction) then
			return nil
		end
		local profile = object.value
		local result = M.grant(profile, event, units, nk.time())
		local ok = pcall(nk.storage_write, { {
			collection = COLLECTION, key = KEY, user_id = user_id, value = profile,
			version = object.version, permission_read = 1, permission_write = 0,
		} })
		if ok then
			return result
		end
	end
	nk.logger_warn(string.format("progress: couldn't save %s for %s after %d attempts", event, user_id, MAX_WRITE_ATTEMPTS))
	return nil
end

-- Today's assignments with their names and targets, for display.
function M.describe_assignments(profile, now_ms)
	local copy = { assignments = profile.assignments }
	local assignments = todays_assignments(copy, now_ms)
	local list = {}
	for _, entry in ipairs(assignments.list) do
		local template = assignment_data.BY_ID[entry.id]
		if template then
			table.insert(list, {
				id = template.id, name = template.name, description = template.description, target = template.target,
				progress = entry.progress or 0, done = entry.done == true, xp = template.xp, tope = template.tope,
			})
		end
	end
	return { date = assignments.date, list = list }
end

local function assignments_rpc(context)
	if not context.user_id or context.user_id == "" then
		error("sign in first")
	end
	local objects = nk.storage_read({ { collection = COLLECTION, key = KEY, user_id = context.user_id } })
	local profile = objects[1] and objects[1].value or {}
	return nk.json_encode(M.describe_assignments(profile, nk.time()))
end

nk.register_rpc(assignments_rpc, "assignments")

return M
