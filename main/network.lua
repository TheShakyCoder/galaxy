-- Nakama realtime connection, singleton (shared_state = 1 in game.project
-- means this module is the same table everywhere it's required).
--
-- Ported from ~/Defold/SuperShips/main/network.lua (§0 - mechanics, not
-- creative expression, reuse is fine), cut down to exactly the
-- "Realtime presence only" slice picked via AskUserQuestion: guest device-id
-- auth, connect, join a per-system room, broadcast/receive transforms. The
-- source file's Steam/email account layer, username generation, and
-- session-activity logging (its M.login_steam/M.register_email/M.login_email/
-- M.start_session_log and friends) are deliberately NOT ported - no
-- wallet/economy/combat authority yet, and guest play is the only account
-- model Galaxy has at all right now (main/session.lua).
--
-- Responsibilities:
--   1. Authenticate against the self-hosted Nakama server
--      (nakama-server/docker-compose.yml, local dev) using a persisted
--      device id, and connect the realtime socket, reconnecting on its own
--      whenever that fails or drops. M.connect() is called
--      once from main/remote_ships.script's init() (that game object is
--      embedded directly in main/main.collection, so this runs at game
--      boot, before the player has even picked a faction or launched).
--   2. Join a realtime "room" per star system (main/data/star_systems.lua) -
--      a plain named channel every client in that system joins by the same
--      fixed string, so there's no match-creation race to resolve
--      server-side. Used purely as a broadcast bus for ship transforms.

local session = require "main.session"
local star_systems = require "main.data.star_systems"
local defold = require "nakama.engine.defold"
local nakama = require "nakama.nakama"
local nakama_socket = require "nakama.socket"
local json = require "nakama.util.json"

local M = {}

-- Read from game.project's [nakama] section, whose committed defaults point
-- at the local docker-compose dev server (nakama-server/docker-compose.yml).
-- The deployed web build overrides them at bundle time via bob's --settings
-- (see Dockerfile and docs/DEPLOY_COOLIFY.md), so the production host never
-- has to be hard-coded here.
local SERVER_CONFIG = {
	host = sys.get_config_string("nakama.host", "127.0.0.1"),
	port = sys.get_config_int("nakama.port", 7350),
	use_ssl = sys.get_config_int("nakama.use_ssl", 0) == 1,
	-- Nakama's server key, not a user login - ships inside every client
	-- build, so it's an identifier rather than a secret.
	username = sys.get_config_string("nakama.server_key", "defaultkey"),
	password = "",
	engine = defold,
	timeout = 10,
}

-- One realtime room per star system (main/data/star_systems.lua), not one
-- fixed room for the whole game - so players in different systems don't see
-- each other's transforms, matching SuperShips' own room_name_for()/
-- M.rejoin_room_for_system() design.
local SPACE_ROOM_PREFIX = "space_"

-- Which system's room join_space_room()/rejoin_room_for_system() target -
-- kept local to this module (not main/player_ship.script's own
-- self.current_system_id) so this file doesn't need to require that script,
-- and so join_space_room() still works correctly no matter whether
-- main/remote_ships.script's init() or the player's own start_flight()
-- happens to run first. Defaults to the player's own faction's home system
-- the first time it's needed, same starting point start_flight() itself
-- independently arrives at.
local current_system_id = nil

local function room_name_for(system_id)
	return SPACE_ROOM_PREFIX .. (system_id or "unknown")
end

-- Automatic reconnection: any failed connect attempt or dropped socket
-- schedules another M.connect() after `reconnect_delay` seconds, doubling
-- per consecutive failure up to RECONNECT_MAX_DELAY and resetting to
-- RECONNECT_MIN_DELAY once a connection succeeds. Keeps retrying forever -
-- a player left on the page through a server restart rejoins on their own.
local RECONNECT_MIN_DELAY = 1
local RECONNECT_MAX_DELAY = 30
local reconnect_delay = RECONNECT_MIN_DELAY
local reconnect_pending = false
local connecting = false

-- True once join_space_room() has been called - i.e. something wants to be
-- in a room - so every successful (re)connect rejoins it automatically.
local wants_room = false

-- Remote user_ids seen in the current room, so their ships can be removed
-- (via M.on_leave) when this client drops or changes room - no presence
-- "leave" events arrive for those cases, which would otherwise leave frozen
-- ghost ships behind.
local room_senders = {}

-- Resolved once per launch and reused on every reconnect: debug builds get a
-- fresh random id per call (see get_or_create_device_id()), which would
-- otherwise turn each reconnect into a brand-new Nakama user.
local device_id = nil

M.client = nil
M.socket = nil
M.session = nil
M.connected = false
M.in_room = false
M.channel_id = nil
M.on_transform = nil
M.on_leave = nil

local function clear_room_senders()
	local senders = room_senders
	room_senders = {}
	if M.on_leave then
		for user_id in pairs(senders) do
			M.on_leave(user_id)
		end
	end
end

local function schedule_reconnect()
	if reconnect_pending then
		return
	end
	reconnect_pending = true
	print(string.format("[network] reconnecting in %ds", reconnect_delay))
	timer.delay(reconnect_delay, false, function()
		reconnect_pending = false
		M.connect()
	end)
	reconnect_delay = math.min(reconnect_delay * 2, RECONNECT_MAX_DELAY)
end

local function device_id_file()
	return sys.get_save_file("galaxy", "device_id")
end

-- A stable per-install id, generated once and persisted to disk so the same
-- player is recognized across relaunches.
--
-- Debug (editor Build-and-Run) builds skip persistence and always get a
-- fresh random id instead: the save file path is the same for every debug
-- instance launched from this project on this machine, so persisting it
-- would make two editor-launched clients on the same Mac collide onto the
-- same Nakama user - exactly the case when locally testing multiplayer with
-- two editor windows (ported verbatim from SuperShips' own
-- get_or_create_device_id(), §0).
local function get_or_create_device_id()
	if sys.get_engine_info().is_debug then
		return defold.uuid()
	end

	local saved = sys.load(device_id_file())
	if saved and saved.device_id then
		return saved.device_id
	end
	local id = defold.uuid()
	sys.save(device_id_file(), { device_id = id })
	return id
end

local function open_socket(session_obj, callback)
	local socket = nakama.create_socket(M.client)
	local ok, err = socket.connect()
	if not ok then
		print("[network] socket connect failed: " .. tostring(err and err.message))
		connecting = false
		schedule_reconnect()
		if callback then callback(false) end
		return
	end
	M.socket = socket

	socket.on_disconnect(function()
		-- ignore late events from a socket already replaced by a reconnect
		if M.socket ~= socket then
			return
		end
		M.connected = false
		M.in_room = false
		M.channel_id = nil
		clear_room_senders()
		print("[network] disconnected")
		schedule_reconnect()
	end)
	socket.on_error(function(socket_err)
		print("[network] socket error: " .. tostring(socket_err and socket_err.message or socket_err))
	end)

	connecting = false
	reconnect_delay = RECONNECT_MIN_DELAY
	M.connected = true
	print("[network] connected as " .. tostring(session_obj.user_id))
	if wants_room then
		M.join_space_room()
	end
	if callback then callback(true) end
end

-- Authenticates and connects the realtime socket. callback(ok) is called
-- once this attempt's outcome is known. Safe to call more than once: a no-op
-- while already connected or mid-attempt. On failure, or if the socket later
-- drops, it retries by itself (see schedule_reconnect()), re-authenticating
-- each time so an expired session token can't block reconnecting.
function M.connect(callback)
	if M.connected or connecting then
		if callback then callback(M.connected) end
		return
	end
	connecting = true

	nakama.sync(function()
		M.client = M.client or nakama.create_client(SERVER_CONFIG)
		device_id = device_id or get_or_create_device_id()

		local session_obj = nakama.authenticate_device(M.client, device_id, nil, true, nil)
		if not session_obj or session_obj.error or not session_obj.token then
			print("[network] authentication failed: " .. tostring(session_obj and (session_obj.message or session_obj.error)))
			connecting = false
			schedule_reconnect()
			if callback then callback(false) end
			return
		end
		nakama.set_bearer_token(M.client, session_obj.token)
		M.session = session_obj

		open_socket(session_obj, callback)
	end)
end

-- Joins the shared space room and starts listening for other ships'
-- transforms. on_transform(user_id, {x,y,z,qx,qy,qz,qw,faction,speed,model})
-- fires whenever another player's ship moves; on_leave(user_id) fires when
-- they disconnect or leave the room, and for every known ship when this
-- client itself drops or changes room. If not connected yet, the join
-- happens automatically once M.connect() succeeds - and again after every
-- reconnect - so call order with M.connect() doesn't matter.
function M.join_space_room(on_transform, on_leave)
	M.on_transform = on_transform or M.on_transform
	M.on_leave = on_leave or M.on_leave
	wants_room = true

	if not M.connected or M.in_room then
		return
	end

	M.socket.on_channel_message(function(message)
		local chan = message.channel_message
		if not chan or chan.sender_id == M.session.user_id then
			return
		end
		local ok, payload = pcall(json.decode, chan.content)
		if ok and payload and payload.x and M.on_transform then
			room_senders[chan.sender_id] = true
			M.on_transform(chan.sender_id, payload)
		end
	end)

	M.socket.on_channel_presence_event(function(message)
		local pres = message.channel_presence_event
		if not pres or not pres.leaves then
			return
		end
		for _, p in ipairs(pres.leaves) do
			room_senders[p.user_id] = nil
			if M.on_leave then M.on_leave(p.user_id) end
		end
	end)

	if not current_system_id then
		current_system_id = star_systems.HOME_SYSTEM[session.get_faction()]
	end

	nakama.sync(function()
		local result, err = M.socket.channel_join(room_name_for(current_system_id), nakama_socket.CHANNELTYPE_ROOM, false, false)
		if not result then
			print("[network] failed to join space room: " .. tostring(err and err.message))
			-- try again shortly; if the socket itself has dropped, the
			-- reconnect path rejoins instead and this retry no-ops
			timer.delay(RECONNECT_MIN_DELAY, false, function()
				M.join_space_room()
			end)
			return
		end
		M.channel_id = result.channel and result.channel.id or result.id
		M.in_room = true
		print("[network] joined space room: " .. room_name_for(current_system_id))
	end)
end

-- Called by main/player_ship.script's start_flight()/arrive_at_system() on
-- every system change (including the very first, harmless call at initial
-- launch, since current_system_id already matches by then and this just
-- no-ops). Leaves the old system's room and joins the new one, so players
-- in different systems don't see each other's transforms.
function M.rejoin_room_for_system(system_id)
	if system_id == current_system_id then
		return
	end
	current_system_id = system_id
	if M.in_room and M.socket then
		-- must run inside nakama.sync(), same as channel_join() above -
		-- calling it bare fails an assertion in nakama/util/async.lua
		local channel_id = M.channel_id
		nakama.sync(function()
			M.socket.channel_leave(channel_id)
		end)
	end
	M.in_room = false
	M.channel_id = nil
	clear_room_senders()
	M.join_space_room(M.on_transform, M.on_leave)
end

-- Broadcasts this ship's transform (plus its current speed and ship/faction
-- id) to everyone else in the room. Cheap fire-and-forget - safe to call
-- every frame, but callers should throttle (see player_ship.script's
-- NETWORK_SEND_INTERVAL) to keep traffic reasonable.
function M.send_transform(pos, rot, speed, ship_id)
	if not M.in_room then
		return
	end
	local payload = json.encode({
		x = pos.x, y = pos.y, z = pos.z,
		qx = rot.x, qy = rot.y, qz = rot.z, qw = rot.w,
		faction = session.get_faction(),
		speed = speed or 0,
		-- main/data/ships.lua chassis id (e.g. "patrol_interceptor") - lets
		-- main/remote_ships.script size the spawned stand-in roughly right;
		-- nil/omitted (json.encode drops nil fields) falls back to a
		-- default-sized marker, same as a client too old to send this.
		ship_id = ship_id,
	})
	nakama.sync(function()
		M.socket.channel_message_send(M.channel_id, payload)
	end)
end

return M
