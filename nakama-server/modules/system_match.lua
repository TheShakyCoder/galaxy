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

Wire protocol (JSON match data):
  1 STATE     client -> server  {x,y,z,qx,qy,qz,qw,speed}
  2 SNAPSHOT  server -> client  [{u,x,y,z,qx,qy,qz,qw,speed}, ...]
  3 JOIN      server -> client  {u, ship_id, faction, skin_id}
  4 LEAVE     server -> client  {u}
]]

local nk = require("nakama")
local ships = require("main.data.ships") -- copied from the game by tools/sync_server_rules.py
local tickets = require("tickets")
local registry = require("registry")

local OP_STATE, OP_SNAPSHOT, OP_JOIN, OP_LEAVE = 1, 2, 3, 4

local TICK_RATE = 10
local HEARTBEAT_TICKS = 5 * TICK_RATE
local IDLE_TICKS = 5 * 60 * TICK_RATE -- empty for 5 minutes -> shut down
local MAX_STRIKES = 20 -- invalid updates before a player is kicked

-- Validation slack: speed limit is the ship's boost speed + 10%; a move may
-- cover 1.5x what that speed allows in the time since the last update, plus
-- a few metres for timing jitter.
local SPEED_SLACK = 1.1
local DISTANCE_SLACK = 1.5
local DISTANCE_EXTRA_M = 5
local DEFAULT_BOOST_SPEED = 40 -- m/s, same fallback as main/player_ship.script

local M = {}

local function load_identity(user_id)
	local objects = nk.storage_read({ { collection = "profile", key = "state", user_id = user_id } })
	local profile = objects[1] and objects[1].value or {}
	local ship_id = profile.active_ship_id
	return {
		ship_id = ship_id,
		faction = profile.faction,
		skin_id = profile.equipped_skins and ship_id and profile.equipped_skins[ship_id] or nil,
	}
end

local function max_speed(ship_id)
	local ship = ships.SHIPS[ship_id]
	return (ship and ship.data and ship.data.boost_speed_m_per_sec) or DEFAULT_BOOST_SPEED
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
		players = {}, -- user_id -> { presence, ship_id, faction, skin_id, state, updated_at, strikes }
		used_tickets = {}, -- jti -> expiry (seconds)
		idle_ticks = 0,
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
		if player and message.op_code == OP_STATE and player.presence.session_id == message.sender.session_id then
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
			registry.release(context, state.system)
			return nil -- end the match; the directory makes a new one when needed
		end
	else
		state.idle_ticks = 0
	end
	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
	registry.release(context, state.system)
	return state
end

function M.match_signal(context, dispatcher, tick, state, data)
	return state, data
end

return M
