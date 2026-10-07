--[[
One authoritative match per star system: who is flying there, where, and in
what ship. Created on demand by modules/directory.lua (enter_system RPC).

Movement is predicted by each client and VALIDATED here: a position update
that's faster than the ship can fly, or jumps further than it could have
moved, is ignored (and repeat offenders are kicked). Accepted updates are
relayed to everyone else in the system, batched per tick. Players' ship,
faction and skin come from their server-owned profile, not from the client.

Joining needs a transfer ticket from enter_system (a short-lived JWT naming
this system and the player), so only players who are really in this system
can join. Each ticket works once.

The match keeps its entry in the system registry (storage
system_matches/<system>) up to date with a heartbeat, so the directory can
find it - on this node now, and on whichever node hosts it once there are
several (see directory.lua).

The match also owns the system's outposts (modules/outposts.lua): players
of the other faction can fire at one, and the match applies each of their
installed weapons' damage per second (BSGO values in main/data/modules/
weapons_autocannons.lua) while the outpost is within that weapon's range
and firing arc of the ship's last validated position and heading. At zero
hull the outpost is destroyed for an hour, then returns at full hull.

Wire protocol (JSON match data):
  1 STATE     client -> server  {x,y,z,qx,qy,qz,qw,speed}
  2 SNAPSHOT  server -> client  [{u,x,y,z,qx,qy,qz,qw,speed}, ...]
  3 JOIN      server -> client  {u, ship_id, faction, skin_id}
  4 LEAVE     server -> client  {u}
  5 OUTPOSTS  server -> client  {accord = state, swarm = state, now}
              state = {exists, hp, max_hp, available, destroyed_until}
              (ms; `now` is the server's clock, for the countdown)
  6 FIRE      client -> server  {target = "outpost:<faction>", slots = ["W1", ...]}
              to fire the weapons in those slots (all fitted weapons if slots
              is missing), {} to stop
  7 ANALYSE   client -> server  {} - Asteroid Analyser (P): analyse every
              asteroid within the fitted analyser's range of the player's last
              validated position; after its scan time, XP for each one this
              player hasn't analysed before (modules/progress.lua)
  8 PROGRESS  server -> client  {reason, xp_gained, tope_gained, xp, level,
              level_before, rank, completed = [{id, name, xp, tope}]} - XP
              this player just earned here (only sent to them)
  9 ASTEROIDS server -> client  {now, rocks = [{i, hp, max_hp, destroyed_until}]}
              the hull of every asteroid of this system that isn't at full
              hull (or is destroyed, destroyed_until = ms); absent = full.
              Sent on joining and whenever a hull changes.
 10 RESOURCE  server -> client  {resource, amount, total} - an asteroid the
              player's final shot depleted, credited to their saved
              inventory (only sent to them)
]]

local nk = require("nakama")
local ships = require("main.data.ships") -- copied from the game by tools/sync_server_rules.py
local star_systems = require("main.data.star_systems")
local catalog = require("main.data.modules.catalog")
local weapons = require("main.data.modules.weapons_autocannons")
local tickets = require("tickets")
local registry = require("registry")
local outposts = require("outposts")
local asteroids = require("main.data.asteroids")
local rewards = require("main.data.xp_rewards")
local progress = require("progress")
local resources = require("resources")

local OP_STATE, OP_SNAPSHOT, OP_JOIN, OP_LEAVE, OP_OUTPOSTS, OP_FIRE, OP_ANALYSE, OP_PROGRESS, OP_ASTEROIDS, OP_RESOURCE = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

local TICK_RATE = 10
local HEARTBEAT_TICKS = 5 * TICK_RATE
local IDLE_TICKS = 5 * 60 * TICK_RATE -- empty for 5 minutes -> shut down
local MAX_STRIKES = 20 -- invalid updates before a player is kicked
local OUTPOST_BROADCAST_TICKS = 5 -- hull updates at most twice a second
local OUTPOST_PERSIST_TICKS = 5 * TICK_RATE -- save changed hull every 5 seconds
local ASTEROID_BROADCAST_TICKS = 5 -- asteroid hull updates, same twice-a-second cap
local ASTEROID_RESPAWN_MS = 5 * 60 * 1000 -- a depleted asteroid is gone for 5 minutes
local XP_FLUSH_TICKS = 5 * TICK_RATE -- award outpost damage XP every 5 seconds
local ANALYSED_COLLECTION = "analysed" -- per player, key = system id (server-only, modules/auth.lua)

-- Validation slack: speed limit is the ship's boost speed + 10%; a move may
-- cover 1.5x what that speed allows in the time since the last update, plus
-- a few metres for timing jitter.
local SPEED_SLACK = 1.1
local DISTANCE_SLACK = 1.5
local DISTANCE_EXTRA_M = 5
local DEFAULT_BOOST_SPEED = 40 -- m/s, same fallback as main/player_ship.script

local M = {}

-- The combat weapons fitted in the ship's weapon slots, from the profile's
-- loadout and module instances (upgrade level sets the DPS). Fitting only
-- changes at an outpost, so this is read once per join.
local function installed_weapons(profile)
	local instances = {}
	for _, inst in ipairs(profile.owned or {}) do
		instances[inst.id] = inst
	end
	local list = {}
	for _, entry in ipairs(profile.loadout or {}) do
		local inst = instances[entry.instance_id]
		local module = inst and catalog.get(inst.item_key)
		if module and tostring(entry.slot):sub(1, 1) == "W" and module.max_range_m then
			local dps = weapons.dps_at_level(module, inst.level)
			if dps > 0 then
				table.insert(list, { slot = entry.slot, dps = dps, range = module.max_range_m, cos_half_arc = math.cos(math.rad((module.arc or 0) / 2)) })
			end
		end
	end
	return list
end

-- The fitted Asteroid Analyser's { range, scan_time }, or nil.
local function installed_analyser(profile)
	local instances = {}
	for _, inst in ipairs(profile.owned or {}) do
		instances[inst.id] = inst
	end
	for _, entry in ipairs(profile.loadout or {}) do
		local inst = instances[entry.instance_id]
		local module = inst and catalog.get(inst.item_key)
		if module and module.range_m and module.scan_time_s then
			return { range = module.range_m, scan_time = module.scan_time_s }
		end
	end
	return nil
end

local function load_identity(user_id)
	local objects = nk.storage_read({ { collection = "profile", key = "state", user_id = user_id } })
	local profile = objects[1] and objects[1].value or {}
	local ship_id = profile.active_ship_id
	return {
		ship_id = ship_id,
		faction = profile.faction,
		skin_id = profile.equipped_skins and ship_id and profile.equipped_skins[ship_id] or nil,
		weapons = installed_weapons(profile),
		analyser = installed_analyser(profile),
		pending_damage = 0, -- outpost damage not yet turned into XP
	}
end

-- Progress --------------------------------------------------------------

-- Tells the player what they just earned (if they're still here).
local function send_progress(dispatcher, state, user_id, reason, result)
	local player = state.players[user_id]
	if not (player and result) or (result.xp_gained == 0 and #result.completed == 0) then
		return
	end
	result.reason = reason
	dispatcher.broadcast_message(OP_PROGRESS, nk.json_encode(result), { player.presence })
end

-- Turns the player's outpost damage so far into XP (whole multiples of the
-- damage worth 1 XP; the remainder carries over).
local function flush_damage(dispatcher, state, user_id, player)
	local per_xp = rewards.OUTPOST_DAMAGE_PER_XP
	local damage = math.floor(player.pending_damage / per_xp) * per_xp
	if damage <= 0 then
		return
	end
	player.pending_damage = player.pending_damage - damage
	send_progress(dispatcher, state, user_id, "outpost_damage", progress.apply(user_id, "outpost_damage", damage))
end

-- The destruction bonus, split by damage between everyone who hit the
-- outpost recently (whether or not they're still in the system).
local function award_destruction(dispatcher, state, outpost, now)
	local total, recent = 0, {}
	for user_id, a in pairs(outpost.attackers or {}) do
		if now - a.last <= rewards.OUTPOST_ATTACKER_WINDOW_S * 1000 then
			recent[user_id] = a.damage
			total = total + a.damage
		end
	end
	outpost.attackers = {}
	if total <= 0 then
		return
	end
	for user_id, damage in pairs(recent) do
		local player = state.players[user_id]
		if player then
			flush_damage(dispatcher, state, user_id, player)
		end
		local share = math.floor(rewards.OUTPOST_DESTROYED * damage / total)
		if share > 0 then
			send_progress(dispatcher, state, user_id, "outpost_destroyed", progress.apply(user_id, "outpost_destroyed", share))
		end
	end
end

-- Asteroid Analyser -------------------------------------------------------

-- The asteroids (indices into state.field) within `range` of position `s`.
local function asteroids_in_range(state, s, range)
	local found = {}
	for index, a in ipairs(state.field) do
		local dx, dy, dz = a.x - s.x, a.y - s.y, a.z - s.z
		if math.sqrt(dx * dx + dy * dy + dz * dz) - a.diameter_m / 2 <= range then
			table.insert(found, index)
		end
	end
	return found
end

-- Records a finished scan and grants XP for the asteroids this player hadn't
-- analysed before (kept as a "0"/"1" string, one character per asteroid of
-- the system's field).
local function finish_scan(dispatcher, state, user_id, indices)
	local objects = nk.storage_read({ { collection = ANALYSED_COLLECTION, key = state.system, user_id = user_id } })
	local mask = objects[1] and objects[1].value and objects[1].value.mask or ""
	mask = mask .. string.rep("0", #state.field - #mask)
	local new = 0
	for _, index in ipairs(indices) do
		if mask:sub(index, index) ~= "1" then
			mask = mask:sub(1, index - 1) .. "1" .. mask:sub(index + 1)
			new = new + 1
		end
	end
	if new == 0 then
		return
	end
	nk.storage_write({ {
		collection = ANALYSED_COLLECTION, key = state.system, user_id = user_id, value = { mask = mask },
		permission_read = 1, permission_write = 0,
	} })
	send_progress(dispatcher, state, user_id, "asteroid_analysed", progress.apply(user_id, "asteroid_analysed", new))
end

-- Outposts ----------------------------------------------------------------

local function load_outposts(system)
	local list = {}
	local now = nk.time()
	for _, faction in ipairs(outposts.FACTIONS) do
		local st = outposts.state(system, faction, outposts.read(system, faction), now)
		if st.exists then
			st.pos = star_systems.outpost_position(system, faction)
			list[faction] = st
		end
	end
	return list
end

local function outposts_message(state)
	local out = { now = nk.time() }
	for faction, o in pairs(state.outposts) do
		out[faction] = { exists = true, hp = math.floor(o.hp + 0.5), max_hp = o.max_hp, available = o.available, destroyed_until = o.destroyed_until }
	end
	return nk.json_encode(out)
end

local function save_outpost(state, faction)
	local o = state.outposts[faction]
	outposts.write(state.system, faction, { hp = o.hp, destroyed_until = o.destroyed_until })
	o.dirty = false
end

local function save_dirty_outposts(state)
	for faction, o in pairs(state.outposts) do
		if o.dirty then
			save_outpost(state, faction)
		end
	end
end

-- Direction the ship faces (+Z rotated by its quaternion), as in the game.
local function forward(t)
	local x, y, z, w = t.qx, t.qy, t.qz, t.qw
	return 2 * (x * z + w * y), 2 * (y * z - w * x), 1 - 2 * (x * x + y * y)
end

-- Longest the server will carry a position forward. Games send their state
-- whenever speed or heading changes, so a longer silence means a stalled
-- connection rather than a long straight run.
local MAX_PREDICT_S = 30

-- Where the player's ship is now, as every other player's game shows it:
-- games only send their state when it stops matching dead reckoning
-- (main/player_ship.script network_state_changed), so a ship flying straight
-- at a steady speed sends nothing - its last reported position, carried
-- forward along its heading at its reported speed. Used for anything that
-- needs where the ship actually is (outpost range and arc, the analyser's
-- snapshot), not for checking the next update (plausible uses the last
-- reported one). Returns a copy of the state with x, y, z moved, or nil.
local function predicted_state(player, now)
	local s = player.state
	if not s then
		return nil
	end
	local elapsed = math.min(math.max(0, now - (player.updated_at or now)) / 1000, MAX_PREDICT_S)
	local fx, fy, fz = forward(s)
	local distance = (s.speed or 0) * elapsed
	return {
		x = s.x + fx * distance, y = s.y + fy * distance, z = s.z + fz * distance,
		qx = s.qx, qy = s.qy, qz = s.qz, qw = s.qw, speed = s.speed,
	}
end

-- Damage this player's weapons deal to `outpost` over `dt` seconds: each
-- weapon counts if the outpost is within its range and firing arc of where
-- the ship is now (predicted_state).
local function outpost_damage(player, outpost, dt, now)
	local s = predicted_state(player, now)
	if not s then
		return 0
	end
	local dx, dy, dz = outpost.pos.x - s.x, outpost.pos.y - s.y, outpost.pos.z - s.z
	local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
	local cos_angle = 1
	if dist > 0 then
		local fx, fy, fz = forward(s)
		cos_angle = (fx * dx + fy * dy + fz * dz) / dist
	end
	local damage = 0
	for _, weapon in ipairs(player.weapons or {}) do
		local switched_on = not player.firing_slots or player.firing_slots[weapon.slot]
		if switched_on and dist <= weapon.range and cos_angle >= weapon.cos_half_arc then
			damage = damage + weapon.dps * dt
		end
	end
	return damage
end

-- Applies this tick's fire to the outposts, destroys any at zero hull and
-- brings back any whose hour is up. Returns true if their state changed.
local function update_outposts(dispatcher, state, now)
	local changed = false
	for faction, o in pairs(state.outposts) do
		if not o.available and o.destroyed_until and now >= o.destroyed_until then
			o.hp, o.available, o.destroyed_until = o.max_hp, true, nil
			save_outpost(state, faction)
			nk.logger_info(string.format("%s outpost in %s is back", faction, state.system))
			changed = true
		elseif o.available then
			local damage = 0
			o.attackers = o.attackers or {}
			for user_id, player in pairs(state.players) do
				if player.firing == faction and player.faction ~= faction then
					local dealt = outpost_damage(player, o, 1 / TICK_RATE, now)
					if dealt > 0 then
						damage = damage + dealt
						player.pending_damage = player.pending_damage + dealt
						local a = o.attackers[user_id] or { damage = 0 }
						a.damage, a.last = a.damage + dealt, now
						o.attackers[user_id] = a
					end
				end
			end
			if damage > 0 then
				o.hp = o.hp - damage
				o.dirty = true
				changed = true
				if o.hp <= 0 then
					o.hp, o.available, o.destroyed_until = 0, false, now + outposts.DESTROYED_FOR_MS
					save_outpost(state, faction)
					nk.logger_info(string.format("%s outpost in %s destroyed until %d", faction, state.system, o.destroyed_until))
					for _, player in pairs(state.players) do
						if player.firing == faction then
							player.firing = nil
						end
					end
					award_destruction(dispatcher, state, o, now)
				end
			end
		end
	end
	return changed
end

-- Asteroids ---------------------------------------------------------------

-- Damage this player's weapons deal to asteroid `a` (an entry of
-- state.field) over `dt` seconds: the same range/arc test the game uses for
-- its visible fire (main/player_ship.script update_weapon_fire), measured to
-- the rock's surface rather than its centre.
local function asteroid_damage(player, a, dt, now)
	local s = predicted_state(player, now)
	if not s then
		return 0
	end
	local dx, dy, dz = a.x - s.x, a.y - s.y, a.z - s.z
	local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
	local cos_angle = 1
	if dist > 0 then
		local fx, fy, fz = forward(s)
		cos_angle = (fx * dx + fy * dy + fz * dz) / dist
	end
	local reach = math.max(0, dist - a.diameter_m / 2) -- surface distance
	local damage = 0
	for _, weapon in ipairs(player.weapons or {}) do
		local switched_on = not player.firing_slots or player.firing_slots[weapon.slot]
		if switched_on and reach <= weapon.range and cos_angle >= weapon.cos_half_arc then
			damage = damage + weapon.dps * dt
		end
	end
	return damage
end

-- A depleted asteroid's resource goes to the player whose damage brought
-- its hull to zero (direct instruction) - the FINAL BLOW, not merely the
-- largest or most recent attacker. The amount is the asteroid's own
-- resource content (main/data/asteroids.lua resource_amount) saved to that
-- player's inventory (modules/resources.lua); inert rock holds nothing and
-- awards nothing. The player is told their new balance (OP_RESOURCE) if
-- they're still in the system - the credit itself doesn't need them there.
local function deplete_asteroid(dispatcher, state, index, a, user_id)
	local amount = asteroids.resource_amount(a.resource, a.diameter_m)
	nk.logger_info(string.format("asteroid %d (%s) in %s depleted by %s", index, a.resource, state.system, user_id))
	if amount <= 0 then
		return
	end
	local total = resources.apply(user_id, a.resource, amount)
	if not total then
		return
	end
	local player = state.players[user_id]
	if player then
		dispatcher.broadcast_message(OP_RESOURCE,
			nk.json_encode({ resource = a.resource, amount = amount, total = total }), { player.presence })
	end
end

-- Applies this tick's fire to the system's asteroids: each rock loses hull
-- while a firing player has it in range and arc; at zero it's depleted for
-- ASTEROID_RESPAWN_MS, then comes back at full hull. Returns true if any
-- hull changed. state.rocks holds only the rocks that aren't at full hull:
-- index -> { hp, destroyed_until? }. A depleted asteroid is in that table
-- only while its timer runs; once it elapses the entry is dropped and the
-- rock counts as full again (the same shape outposts.lua uses).
local function update_asteroids(dispatcher, state, now)
	state.rocks = state.rocks or {}
	local changed = false
	for index, r in pairs(state.rocks) do
		if r.destroyed_until and now >= r.destroyed_until then
			state.rocks[index] = nil
			changed = true
		end
	end
	-- This tick's damage, kept PER PLAYER so a depleted rock can be credited
	-- to whoever brought it to zero: by_rock[index] = { {user_id, damage}, ... }.
	local by_rock = {}
	for user_id, player in pairs(state.players) do
		local index = player.firing_asteroid
		local a = index and state.field[index]
		local r = index and state.rocks[index]
		if a and not (r and r.destroyed_until) then
			local damage = asteroid_damage(player, a, 1 / TICK_RATE, now)
			if damage > 0 then
				by_rock[index] = by_rock[index] or {}
				table.insert(by_rock[index], { user_id = user_id, damage = damage })
			end
		end
	end
	for index, hits in pairs(by_rock) do
		local a = state.field[index]
		local r = state.rocks[index] or { hp = asteroids.max_hull(a.diameter_m) }
		local killer = nil
		for _, hit in ipairs(hits) do
			if r.hp <= 0 then
				break -- already depleted earlier this tick; later shots hit nothing
			end
			r.hp = r.hp - hit.damage
			if r.hp <= 0 then
				r.hp, killer = 0, hit.user_id
			end
		end
		if killer then
			r.destroyed_until = now + ASTEROID_RESPAWN_MS
			for _, player in pairs(state.players) do
				if player.firing_asteroid == index then
					player.firing_asteroid = nil
				end
			end
			deplete_asteroid(dispatcher, state, index, a, killer)
		end
		state.rocks[index] = r
		changed = true
	end
	return changed
end

-- { now, rocks = [{i, hp, max_hp, destroyed_until}] }: every asteroid of
-- this system that isn't at full hull (or is depleted). The game
-- (main/network.lua) turns this into the HULL <hp> / <max_hp> line and hides
-- depleted rocks.
local function asteroids_message(state)
	local rocks = {}
	for index, r in pairs(state.rocks or {}) do
		local max_hp = asteroids.max_hull(state.field[index].diameter_m)
		table.insert(rocks, { i = index, hp = math.floor(r.hp + 0.5), max_hp = max_hp, destroyed_until = r.destroyed_until })
	end
	return nk.json_encode({ now = nk.time(), rocks = rocks })
end

-- Validates against the ship's BASIC-tier boost speed (main/data/ships.lua's
-- `basic.data`, §2.1.3). An advanced tier's overrides live under
-- `advanced.data`, but this validator has no access to a player's per-ship
-- advanced state and no advanced tier changes boost speed today - revisit if
-- one ever does.
local function max_speed(ship_id)
	local ship = ships.SHIPS[ship_id]
	return (ship and ship.basic and ship.basic.data and ship.basic.data.boost_speed_m_per_sec) or DEFAULT_BOOST_SPEED
end

local function number_fields_ok(t)
	for _, k in ipairs({ "x", "y", "z", "qx", "qy", "qz", "qw", "speed" }) do
		if type(t[k]) ~= "number" or t[k] ~= t[k] then -- missing or NaN
			return false
		end
	end
	return true
end

-- Is this update physically possible for the player's ship?
local function plausible(player, t, now)
	local limit = max_speed(player.ship_id)
	if math.abs(t.speed) > limit * SPEED_SLACK then
		return false
	end
	local last = player.state
	if not last then
		return true -- first update after joining (spawn point / jump arrival)
	end
	local dx, dy, dz = t.x - last.x, t.y - last.y, t.z - last.z
	local elapsed = math.max(0, now - player.updated_at) / 1000
	local allowed = limit * elapsed * DISTANCE_SLACK + DISTANCE_EXTRA_M
	return dx * dx + dy * dy + dz * dz <= allowed * allowed
end

local function join_message(user_id, player)
	return nk.json_encode({ u = user_id, ship_id = player.ship_id, faction = player.faction, skin_id = player.skin_id })
end

local function snapshot_entry(user_id, s)
	return { u = user_id, x = s.x, y = s.y, z = s.z, qx = s.qx, qy = s.qy, qz = s.qz, qw = s.qw, speed = s.speed }
end

function M.match_init(context, params)
	local system = params.system
	local state = {
		system = system,
		players = {}, -- user_id -> { presence, ship_id, faction, skin_id, weapons, firing, state, updated_at, strikes }
		used_tickets = {}, -- jti -> expiry (seconds)
		idle_ticks = 0,
		outposts = load_outposts(system), -- faction -> { hp, max_hp, available, destroyed_until, pos, dirty, attackers }
		field = asteroids.field_for(system), -- the system's asteroids (the same list every game has)
		rocks = {}, -- index -> { hp, destroyed_until? } for asteroids not at full hull
		outposts_changed = false,
		last_outposts_broadcast = 0,
		asteroids_changed = false,
		last_asteroids_broadcast = 0,
	}
	local label = nk.json_encode({ system = system, node = registry.node_id(context) })
	return state, TICK_RATE, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	local claims, err = tickets.verify(context, metadata and metadata.ticket)
	if not claims then
		return state, false, err
	end
	if claims.sys ~= state.system or claims.uid ~= presence.user_id or claims.match ~= context.match_id then
		return state, false, "ticket is for a different system or player"
	end
	if state.used_tickets[claims.jti] then
		return state, false, "ticket already used"
	end
	state.used_tickets[claims.jti] = claims.exp
	return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		local user_id = presence.user_id
		local old = state.players[user_id]
		local player = load_identity(user_id)
		player.presence = presence
		player.strikes = 0
		state.players[user_id] = player

		-- Tell the newcomer who's already here and where they are...
		local others = {}
		for other_id, other in pairs(state.players) do
			if other_id ~= user_id then
				dispatcher.broadcast_message(OP_JOIN, join_message(other_id, other), { presence })
				if other.state then
					table.insert(others, snapshot_entry(other_id, other.state))
				end
			end
		end
		if #others > 0 then
			dispatcher.broadcast_message(OP_SNAPSHOT, nk.json_encode(others), { presence })
		end
		dispatcher.broadcast_message(OP_OUTPOSTS, outposts_message(state), { presence })
		dispatcher.broadcast_message(OP_ASTEROIDS, asteroids_message(state), { presence })
		-- ...and everyone else about the newcomer (a reconnect replaces the
		-- previous session silently).
		if not old then
			local rest = {}
			for other_id, other in pairs(state.players) do
				if other_id ~= user_id then
					table.insert(rest, other.presence)
				end
			end
			if #rest > 0 then
				dispatcher.broadcast_message(OP_JOIN, join_message(user_id, player), rest)
			end
		end
	end
	state.idle_ticks = 0
	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		local player = state.players[presence.user_id]
		-- Ignore the old session of a player who has already rejoined.
		if player and player.presence.session_id == presence.session_id then
			flush_damage(dispatcher, state, presence.user_id, player)
			state.players[presence.user_id] = nil
			dispatcher.broadcast_message(OP_LEAVE, nk.json_encode({ u = presence.user_id }))
		end
	end
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	local now = nk.time()
	local updates = {}
	for _, message in ipairs(messages) do
		local player = state.players[message.sender.user_id]
		if player and message.op_code == OP_FIRE and player.presence.session_id == message.sender.session_id then
			local ok, t = pcall(nk.json_decode, message.data)
			local target = ok and type(t) == "table" and type(t.target) == "string" and t.target or nil
			local faction = target and target:match("^outpost:(%a+)$")
			local asteroid_index = target and tonumber(target:match("^asteroid:(%d+)$"))
			-- Only the other faction's outpost in this system, or one of this
			-- system's standing asteroids, can be a target.
			if faction and state.outposts[faction] and faction ~= player.faction then
				player.firing, player.firing_asteroid = faction, nil
			elseif asteroid_index and state.field[asteroid_index]
				and not (state.rocks[asteroid_index] and state.rocks[asteroid_index].destroyed_until) then
				player.firing, player.firing_asteroid = nil, asteroid_index
			else
				player.firing, player.firing_asteroid = nil, nil
			end
			if player.firing or player.firing_asteroid then
				-- Which weapons are switched on (Shift+1-9 in the game).
				player.firing_slots = nil
				if ok and type(t) == "table" and type(t.slots) == "table" then
					player.firing_slots = {}
					for _, slot in pairs(t.slots) do
						if type(slot) == "string" then
							player.firing_slots[slot] = true
						end
					end
				end
			end
		elseif player and message.op_code == OP_ANALYSE and player.presence.session_id == message.sender.session_id then
			-- Needs a fitted analyser, a known position and no scan running.
			-- The asteroids are those in range of where the ship is at this
			-- moment (predicted_state): the same snapshot the game takes when
			-- P is pressed, revealed after the scan time.
			local position = predicted_state(player, now)
			if player.analyser and position and not player.scan then
				player.scan = {
					done_tick = tick + math.ceil(player.analyser.scan_time * TICK_RATE),
					indices = asteroids_in_range(state, position, player.analyser.range),
				}
			end
		elseif player and message.op_code == OP_STATE and player.presence.session_id == message.sender.session_id then
			local ok, t = pcall(nk.json_decode, message.data)
			if ok and type(t) == "table" and number_fields_ok(t) and plausible(player, t, now) then
				player.state = t
				player.updated_at = now
				updates[message.sender.user_id] = t
			else
				player.strikes = player.strikes + 1
				if player.strikes >= MAX_STRIKES then
					nk.logger_warn(string.format("kicking %s from %s: %d invalid updates", message.sender.user_id, state.system, player.strikes))
					dispatcher.match_kick({ player.presence })
				end
			end
		end
	end

	local batch = {}
	for user_id, t in pairs(updates) do
		table.insert(batch, snapshot_entry(user_id, t))
	end
	if #batch > 0 then
		dispatcher.broadcast_message(OP_SNAPSHOT, nk.json_encode(batch))
	end

	if update_outposts(dispatcher, state, now) then
		state.outposts_changed = true
	end
	if update_asteroids(dispatcher, state, now) then
		state.asteroids_changed = true
	end
	for user_id, player in pairs(state.players) do
		if player.scan and tick >= player.scan.done_tick then
			local indices = player.scan.indices
			player.scan = nil
			finish_scan(dispatcher, state, user_id, indices)
		end
		if tick % XP_FLUSH_TICKS == 0 then
			flush_damage(dispatcher, state, user_id, player)
		end
	end
	if state.outposts_changed and tick - state.last_outposts_broadcast >= OUTPOST_BROADCAST_TICKS then
		dispatcher.broadcast_message(OP_OUTPOSTS, outposts_message(state))
		state.outposts_changed = false
		state.last_outposts_broadcast = tick
	end
	if state.asteroids_changed and tick - state.last_asteroids_broadcast >= ASTEROID_BROADCAST_TICKS then
		dispatcher.broadcast_message(OP_ASTEROIDS, asteroids_message(state))
		state.asteroids_changed = false
		state.last_asteroids_broadcast = tick
	end
	if tick % OUTPOST_PERSIST_TICKS == 0 then
		save_dirty_outposts(state)
	end

	local count = 0
	for _ in pairs(state.players) do
		count = count + 1
	end
	if tick % HEARTBEAT_TICKS == 0 then
		registry.heartbeat(context, state.system, count)
		-- Forget tickets that have expired anyway.
		local now_s = now / 1000
		for jti, exp in pairs(state.used_tickets) do
			if exp < now_s then
				state.used_tickets[jti] = nil
			end
		end
	end
	if count == 0 then
		state.idle_ticks = state.idle_ticks + 1
		if state.idle_ticks >= IDLE_TICKS then
			save_dirty_outposts(state)
			registry.release(context, state.system)
			return nil -- end the match; the directory makes a new one when needed
		end
	else
		state.idle_ticks = 0
	end
	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
	save_dirty_outposts(state)
	for user_id, player in pairs(state.players) do
		flush_damage(dispatcher, state, user_id, player)
	end
	registry.release(context, state.system)
	return state
end

function M.match_signal(context, dispatcher, tick, state, data)
	return state, data
end

return M
