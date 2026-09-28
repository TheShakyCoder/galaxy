-- Nakama realtime connection, singleton (shared_state = 1 in game.project
-- means this module is the same table everywhere it's required).
--
-- Ported from ~/Defold/SuperShips/main/network.lua (§0 - mechanics, not
-- creative expression, reuse is fine), including its email login, minus
-- Steam and username generation.
--
-- Responsibilities:
--   1. Accounts. Every player registers/logs in with email + password
--      (Nakama email auth) and must verify the email with a 6-digit code
--      before playing (nakama-server/modules/accounts.lua enforces that
--      server-side). The session is stored on the device so returning
--      players skip the login screen (M.resume()). Driven by
--      main/start_screen.gui_script.
--   2. Saved progress: M.load_profile() reads the player's profile storage
--      object; M.economy() asks the server to change it (both used by
--      main/profile.lua). Only the server writes it.
--   3. Realtime: once logged in and verified, M.connect() opens the socket
--      (reconnecting on its own whenever it drops) and joins a room per star
--      system (main/data/star_systems.lua) - a plain named channel every
--      client in that system joins by the same fixed string, used purely as
--      a broadcast bus for ship transforms.

local session = require "main.session"
local star_systems = require "main.data.star_systems"
local defold = require "nakama.engine.defold"
local nakama = require "nakama.nakama"
local nakama_socket = require "nakama.socket"
local json = require "nakama.util.json"
local nakama_session = require "nakama.session"

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

-- Where the logged-in session is kept between visits (a sys.save file -
-- IndexedDB on the web). Not nakama/session.lua's own store()/restore():
-- those call sys.get_config, which Defold 1.13 no longer has.
local function session_file()
	return sys.get_save_file("galaxy", "account_session")
end

local function store_session(session_obj)
	sys.save(session_file(), session_obj or {})
end

local function restore_session()
	local saved = sys.load(session_file())
	return saved and saved.token and saved or nil
end

-- False after M.logout(), so a pending reconnect doesn't bring a logged-out
-- player back online.
local online_wanted = false

M.client = nil
M.socket = nil
M.session = nil
M.connected = false
M.in_room = false
M.channel_id = nil
M.on_transform = nil
M.on_leave = nil

local function client()
	M.client = M.client or nakama.create_client(SERVER_CONFIG)
	return M.client
end

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
	if reconnect_pending or not online_wanted then
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

-- A readable message from a failed Nakama call.
local function error_message(result, fallback)
	local message = result and (result.message or (type(result.error) == "string" and result.error))
	return message and message ~= "" and message or fallback
end

local function use_session(session_obj)
	M.session = session_obj
	nakama.set_bearer_token(client(), session_obj.token)
	store_session(session_obj)
end

-- Refreshes the access token if it's about to expire (tokens last 2 h;
-- the refresh token much longer). Must run inside nakama.sync(). Returns
-- false if the session can't be used any more (player has to log in).
local function ensure_fresh_session()
	local s = M.session
	if not s then
		return false
	end
	if os.time() + 60 < s.expires then
		return true
	end
	if nakama_session.is_refresh_token_expired(s) then
		return false
	end
	local refreshed = nakama.session_refresh(client(), s.refresh_token, nil)
	if not refreshed or refreshed.error or not refreshed.token then
		return false
	end
	use_session(refreshed)
	return true
end

-- Email login/registration. `create`: true registers a new account (Nakama
-- rejects an email that's already taken with a different password).
-- callback(ok, error_message)
local function authenticate(email, password, create, callback)
	nakama.sync(function()
		local result = nakama.authenticate_email(client(), email, password, nil, create, nil)
		if not result or result.error or not result.token then
			-- authenticate_email clears the client's bearer token even on
			-- failure (nakama-defold quirk, see SuperShips) - restore it.
			if M.session then
				nakama.set_bearer_token(client(), M.session.token)
			end
			local fallback = create and "Couldn't create the account." or "Wrong email or password."
			local message = error_message(result, fallback)
			if message == "Invalid credentials." then
				message = create and "That email is already registered." or "Wrong email or password."
			end
			print("[network] " .. (create and "register" or "login") .. " failed: " .. tostring(message))
			if callback then callback(false, message) end
			return
		end
		use_session(result)
		print("[network] " .. (create and "registered" or "logged in") .. " as " .. tostring(result.user_id))
		if callback then callback(true) end
	end)
end

function M.register(email, password, callback)
	authenticate(email, password, true, callback)
end

function M.login(email, password, callback)
	authenticate(email, password, false, callback)
end

-- Picks up the session stored by an earlier visit. callback(ok)
function M.resume(callback)
	local stored = restore_session()
	if not stored then
		callback(false)
		return
	end
	M.session = stored
	nakama.set_bearer_token(client(), stored.token)
	nakama.sync(function()
		local ok = ensure_fresh_session()
		if not ok then
			M.session = nil
		end
		callback(ok)
	end)
end

-- Calls a server RPC (nakama-server/modules/*.lua) with a JSON payload.
-- callback(decoded_result_or_nil, error_message)
local function rpc(id, payload, callback)
	nakama.sync(function()
		if not ensure_fresh_session() then
			callback(nil, "Your session has expired. Please log in again.")
			return
		end
		local result = nakama.rpc_func(client(), id, json.encode(payload or {}), nil)
		if not result or result.error or not result.payload then
			callback(nil, error_message(result, "Couldn't reach the server."))
			return
		end
		local ok, decoded = pcall(json.decode, result.payload)
		if ok then
			callback(decoded, nil)
		else
			callback(nil, "Unexpected server reply.")
		end
	end)
end

-- callback({ email, verified } or nil, error)
function M.account_status(callback)
	rpc("account_status", {}, callback)
end

-- callback({ ok, error?, retry_in_s? } or nil, error)
function M.send_code(callback)
	rpc("send_verification_code", {}, callback)
end

-- callback({ ok, error? } or nil, error)
function M.verify(code, callback)
	rpc("verify_email", { code = code }, callback)
end

-- Saved progress: one storage object per player, readable by its owner,
-- written only by the server.
local PROFILE_COLLECTION = "profile"
local PROFILE_KEY = "state"

-- callback(data_or_nil, error) - data is nil (no error) for a new player.
function M.load_profile(callback)
	nakama.sync(function()
		if not ensure_fresh_session() then
			callback(nil, "Your session has expired. Please log in again.")
			return
		end
		local result = nakama.read_storage_objects(client(), {
			{ collection = PROFILE_COLLECTION, key = PROFILE_KEY, user_id = M.session.user_id },
		})
		if not result or result.error then
			callback(nil, error_message(result, "Couldn't load your progress."))
			return
		end
		local object = result.objects and result.objects[1]
		if not object then
			callback(nil, nil)
			return
		end
		local ok, data = pcall(json.decode, object.value)
		if ok then
			callback(data, nil)
		else
			callback(nil, "Your saved progress couldn't be read.")
		end
	end)
end

-- Asks the server to apply one change to the player's progress
-- (nakama-server/modules/economy.lua; see main/profile.lua).
-- callback({ ok, result?, error?, profile? } or nil, network_error)
function M.economy(op, args, callback)
	rpc("economy", { op = op, args = args }, callback)
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

-- Opens the realtime socket for the logged-in, verified player. callback(ok)
-- is called once this attempt's outcome is known. Safe to call more than
-- once: a no-op while already connected or mid-attempt. On failure, or if
-- the socket later drops, it retries by itself (see schedule_reconnect()),
-- refreshing the session token when needed.
function M.connect(callback)
	online_wanted = true
	if M.connected or connecting then
		if callback then callback(M.connected) end
		return
	end
	if not M.session then
		if callback then callback(false) end
		return
	end
	connecting = true

	nakama.sync(function()
		if not ensure_fresh_session() then
			print("[network] session expired - log in again")
			connecting = false
			if callback then callback(false) end
			return
		end
		open_socket(M.session, callback)
	end)
end

-- Logs out: closes the realtime connection, forgets the stored session.
function M.logout()
	online_wanted = false
	wants_room = false
	local socket = M.socket
	M.socket = nil
	M.connected = false
	M.in_room = false
	M.channel_id = nil
	clear_room_senders()
	if socket then
		socket.disconnect()
	end
	M.session = nil
	current_system_id = nil -- the next account may be in a different faction's home system
	if M.client then
		nakama.set_bearer_token(M.client, nil)
	end
	store_session(nil) -- overwrite with an empty (token-less) session
	print("[network] logged out")
end

-- Joins the shared space room and starts listening for other ships'
-- transforms. on_transform(user_id, {x,y,z,qx,qy,qz,qw,faction,speed,ship_id,skin_id})
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
-- NETWORK_SEND_INTERVAL) to keep traffic reasonable. Returns false without
-- sending while not in a room (still connecting or mid system change).
function M.send_transform(pos, rot, speed, ship_id)
	if not M.in_room then
		return false
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
		-- Equipped skin (main/data/skins.lua id), omitted for the default
		-- model. Receivers only show it if it's valid for this ship_id and
		-- faction - see main/skin_flight.lua's show().
		skin_id = ship_id and session.get_equipped_skin(ship_id),
	})
	nakama.sync(function()
		M.socket.channel_message_send(M.channel_id, payload)
	end)
	return true
end

return M
