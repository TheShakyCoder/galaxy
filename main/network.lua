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
--      (reconnecting on its own whenever it drops). Each star system is an
--      authoritative match on the server (nakama-server/modules/
--      system_match.lua): M.enter_system() asks the directory
--      (enter_system RPC) for the system's match and a one-use transfer
--      ticket, then joins it. The server validates every position update and
--      tells us who's there (JOIN), where (SNAPSHOT) and who left (LEAVE).

local defold = require "nakama.engine.defold"
local nakama = require "nakama.nakama"
local json = require "nakama.util.json"
local nakama_session = require "nakama.session"
local session = require "main.session"

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

-- Star-system match protocol (see nakama-server/modules/system_match.lua).
local OP_STATE, OP_SNAPSHOT, OP_JOIN, OP_LEAVE, OP_OUTPOSTS, OP_FIRE = 1, 2, 3, 4, 5, 6

-- The system the player is in while flying (nil when docked or logged out).
-- Every (re)connect enters it again with a fresh ticket.
local current_system_id = nil

-- Bumped by every enter/leave, so a slow enter_system reply for a system
-- the player has already left is ignored.
local system_generation = 0

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

-- Other players in the current system: user_id -> { ship_id, faction,
-- skin_id } from their JOIN message. Their ships are removed (M.on_leave)
-- when we drop or change system, since no LEAVE arrives for those cases.
local members = {}

-- Outposts' hull/destruction as last heard from the server (the system's
-- match while flying, the outpost_status RPC at an outpost): system_id ->
-- faction -> { exists, hp, max_hp, available, destroyed_until, returns_at }.
-- `returns_at` is destroyed_until on the local socket.gettime() clock, so
-- countdowns don't depend on this computer's clock matching the server's.
local outpost_cache = {}

local function store_outposts(system_id, data)
	local now = socket.gettime()
	local by_faction = {}
	for _, faction in ipairs({ "accord", "swarm" }) do
		local st = data[faction]
		if type(st) == "table" then
			if st.destroyed_until and data.now then
				st.returns_at = now + (st.destroyed_until - data.now) / 1000
			end
			by_faction[faction] = st
		end
	end
	outpost_cache[system_id] = by_faction
end

-- The outpost's last known state, or nil if the server hasn't told us yet.
-- A destruction whose hour is up counts as returned (the server says so as
-- soon as it notices).
function M.outpost_state(system_id, faction)
	local st = outpost_cache[system_id] and outpost_cache[system_id][faction]
	if st and not st.available and st.returns_at and socket.gettime() >= st.returns_at then
		st.available, st.hp, st.destroyed_until, st.returns_at = true, st.max_hp, nil, nil
	end
	return st
end

-- Seconds until a destroyed outpost returns (0 if it isn't destroyed).
function M.outpost_returns_in(system_id, faction)
	local st = M.outpost_state(system_id, faction)
	if not (st and st.returns_at) then
		return 0
	end
	return math.max(0, st.returns_at - socket.gettime())
end

-- Docking, launching and respawning (main/session.lua docked_system) treat
-- a destroyed outpost as missing, the same rule the server applies. Until
-- the server has said otherwise an outpost is assumed to be there.
session.set_outpost_availability(function(system_id, faction)
	local st = M.outpost_state(system_id, faction)
	return st == nil or st.available
end)

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
M.match_id = nil
M.on_transform = nil
M.on_leave = nil

local function client()
	M.client = M.client or nakama.create_client(SERVER_CONFIG)
	return M.client
end

local function clear_members()
	local previous = members
	members = {}
	if M.on_leave then
		for user_id in pairs(previous) do
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
		M.match_id = nil
		clear_members()
		print("[network] disconnected")
		schedule_reconnect()
	end)
	socket.on_error(function(socket_err)
		print("[network] socket error: " .. tostring(socket_err and socket_err.message or socket_err))
	end)
	socket.on_match_data(function(message)
		local data = message.match_data
		if M.socket == socket and data and data.match_id == M.match_id then
			M.handle_match_data(tonumber(data.op_code), data.data)
		end
	end)

	connecting = false
	reconnect_delay = RECONNECT_MIN_DELAY
	M.connected = true
	print("[network] connected as " .. tostring(session_obj.user_id))
	if current_system_id then
		M.enter_system(current_system_id)
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
	system_generation = system_generation + 1
	local socket = M.socket
	M.socket = nil
	M.connected = false
	M.in_room = false
	M.match_id = nil
	clear_members()
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

-- Registers who hears about other ships: on_transform(user_id,
-- {x,y,z,qx,qy,qz,qw,speed,ship_id,faction,skin_id}) whenever another player
-- in the current system moves (their ship/faction/skin are the ones the
-- server read from their profile); on_leave(user_id) when they leave, and
-- for everyone when we drop or change system.
function M.set_space_callbacks(on_transform, on_leave)
	M.on_transform = on_transform
	M.on_leave = on_leave
end

-- on_outposts(system_id) is called whenever the current system's outpost
-- state arrives (on joining its match and whenever a hull changes).
function M.set_outposts_callback(on_outposts)
	M.on_outposts = on_outposts
end

-- Asks the server for `system_id`'s outposts (the outpost screen isn't in
-- any system's match); callback(ok) once the cache is updated.
function M.fetch_outposts(system_id, callback)
	rpc("outpost_status", { system_id = system_id }, function(result)
		if result and not result.error then
			store_outposts(system_id, result)
			if callback then callback(true) end
		elseif callback then
			callback(false)
		end
	end)
end

function M.handle_match_data(op, raw)
	local ok, data = pcall(json.decode, raw)
	if not ok or type(data) ~= "table" then
		return
	end
	if op == OP_OUTPOSTS then
		if current_system_id then
			store_outposts(current_system_id, data)
			if M.on_outposts then M.on_outposts(current_system_id) end
		end
	elseif op == OP_JOIN then
		members[data.u] = { ship_id = data.ship_id, faction = data.faction, skin_id = data.skin_id }
	elseif op == OP_LEAVE then
		if members[data.u] then
			members[data.u] = nil
			if M.on_leave then M.on_leave(data.u) end
		end
	elseif op == OP_SNAPSHOT and M.on_transform then
		for _, t in ipairs(data) do
			local who = members[t.u]
			if who and t.u ~= (M.session and M.session.user_id) then
				t.ship_id, t.faction, t.skin_id = who.ship_id, who.faction, who.skin_id
				M.on_transform(t.u, t)
			end
		end
	end
end

local function leave_current_match()
	local match_id = M.match_id
	M.match_id = nil
	M.in_room = false
	clear_members()
	if match_id and M.socket and M.connected then
		local socket = M.socket
		nakama.sync(function()
			socket.match_leave(match_id)
		end)
	end
end

-- Enters `system_id` (the player must be in it on the server - see
-- nakama-server/modules/directory.lua): leaves the current system's match,
-- gets the new one and a ticket from enter_system, joins. Called on launch
-- and on arriving from a jump (main/player_ship.script), and again after
-- every reconnect.
function M.enter_system(system_id)
	system_generation = system_generation + 1
	local generation = system_generation
	current_system_id = system_id
	leave_current_match()
	if not (M.connected and M.socket) then
		return -- open_socket() enters current_system_id once connected
	end
	local socket = M.socket
	rpc("enter_system", { system_id = system_id }, function(result, err)
		if generation ~= system_generation or M.socket ~= socket then
			return -- moved on (another system, docked, reconnected) meanwhile
		end
		if not (result and result.ok) then
			print("[network] can't enter " .. system_id .. ": " .. tostring(result and result.error or err))
			return
		end
		if result.endpoint and result.endpoint ~= "" then
			-- Multi-node deployments: the system lives on another node. Not
			-- used yet (single node); this is where the client would open a
			-- socket to result.endpoint with the same session token.
			print("[network] system " .. system_id .. " is hosted on " .. result.endpoint .. " (not supported yet)")
			return
		end
		local joined = socket.match_join(result.match_id, nil, { ticket = result.ticket })
		if generation ~= system_generation or M.socket ~= socket then
			return
		end
		if not joined or joined.error then
			print("[network] joining " .. system_id .. " failed: " .. tostring(joined and joined.error and joined.error.message))
			return
		end
		M.match_id = result.match_id
		M.in_room = true
		print("[network] entered system: " .. system_id)
	end)
end

-- Leaves the current system (docking).
function M.leave_system()
	system_generation = system_generation + 1
	current_system_id = nil
	leave_current_match()
end

-- Sends this ship's position to the system's match (the server validates it
-- and relays it). Cheap fire-and-forget - callers throttle (see
-- main/player_ship.script's NETWORK_SEND_INTERVAL). Returns false without
-- sending while not in a system (connecting, or mid system change).
-- `ship_id` is unused: the server knows the player's ship from their profile.
function M.send_transform(pos, rot, speed, ship_id)
	if not M.match_id then
		return false
	end
	local socket, match_id = M.socket, M.match_id
	local payload = json.encode({
		x = pos.x, y = pos.y, z = pos.z,
		qx = rot.x, qy = rot.y, qz = rot.z, qw = rot.w,
		speed = speed or 0,
	})
	nakama.sync(function()
		socket.match_data_send(match_id, OP_STATE, payload)
	end)
	return true
end

-- Fires this ship's weapons at `target` ("outpost:<faction>") until
-- M.stop_fire(). The server decides the damage: each installed weapon hits
-- while the target is inside its range and firing arc.
function M.fire(target)
	if not M.match_id then
		return false
	end
	local socket, match_id = M.socket, M.match_id
	local payload = json.encode(target and { target = target } or {})
	nakama.sync(function()
		socket.match_data_send(match_id, OP_FIRE, payload)
	end)
	return true
end

function M.stop_fire()
	return M.fire(nil)
end

return M
