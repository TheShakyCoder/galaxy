-- Nakama realtime connection, singleton (shared_state = 1 in game.project
-- means this module is the same table everywhere it's required).
--
-- Ported from ~/Defold/SuperShips/main/network.lua (§0 - mechanics, not
-- creative expression, reuse is fine), minus its login.
--
-- Responsibilities:
--   1. Signing in. Accounts live on the website (Laravel, fig.limited), not
--      in the game: players register, verify and log in there, then press
--      Play. The game (served from play.fig.limited behind the website's
--      login) asks the website for a play token and which game server to
--      use (M.start()), and signs in to that server's Nakama with it
--      (nakama-server/modules/auth.lua checks the token). Driven by
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
local b64 = require "nakama.util.b64"
local session = require "main.session"

local M = {}

-- The game server to connect to. The website says which one when it hands
-- out the play token (M.start()); game.project's [nakama] section is only
-- used by debug builds signing in with a dev token (see M.start()), and
-- points at the local docker-compose server (nakama-server/docker-compose.yml).
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
local OP_STATE, OP_SNAPSHOT, OP_JOIN, OP_LEAVE, OP_OUTPOSTS, OP_FIRE, OP_ANALYSE, OP_PROGRESS = 1, 2, 3, 4, 5, 6, 7, 8

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
end

-- Refreshes the access token if it's about to expire (tokens last 2 h;
-- the refresh token much longer). Must run inside nakama.sync(). Returns
-- false if the session can't be used any more (the page has to be reloaded
-- for a new play token).
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

-- Where to send players for anything account-related (the website's
-- dashboard). Set by M.start() from the website's reply.
M.account_url = sys.get_config_string("galaxy.account_url", "https://fig.limited/dashboard")

local function is_html5()
	return html5 ~= nil and sys.get_sys_info().system_name == "HTML5"
end

-- Debug builds only: a dev play token (php artisan galaxy:dev-token on the
-- website) from the page's #dev_token= fragment or the GALAXY_PLAY_TOKEN
-- environment variable, for builds that aren't served behind the website.
local function dev_token()
	if not sys.get_engine_info().is_debug then
		return nil
	end
	local token
	if is_html5() then
		token = html5.run("new URLSearchParams(location.hash.slice(1)).get('dev_token') || ''")
	else
		token = os.getenv("GALAXY_PLAY_TOKEN")
	end
	return token ~= nil and token ~= "" and token or nil
end

-- The claims of a JWT, unchecked (the server checks it); nil if unreadable.
local function token_claims(token)
	local payload = token:match("^[^.]+%.([^.]+)%.")
	if not payload then
		return nil
	end
	payload = payload:gsub("-", "+"):gsub("_", "/")
	payload = payload .. string.rep("=", (4 - #payload % 4) % 4)
	local ok, claims = pcall(json.decode, b64.decode(payload))
	return ok and claims or nil
end

-- Asks the website (through play.fig.limited, which forwards the login
-- cookie) for a play token. callback(play) with the website's reply
-- { token, user_id, server = { host, port, ssl, server_key }, account_url },
-- or callback(nil, failure) with failure = { kind, message, url }:
--   kind "login"   not logged in on the website (url: its login page)
--   kind "choose"  several servers and none chosen (url: the server list)
--   kind "error"   anything else (retry)
local function fetch_play(callback)
	local token = dev_token()
	if token then
		local claims = token_claims(token)
		if not claims or not claims.sub then
			callback(nil, { kind = "error", message = "That dev token can't be read." })
			return
		end
		callback({
			token = token, user_id = claims.sub,
			server = { host = SERVER_CONFIG.host, port = SERVER_CONFIG.port, ssl = SERVER_CONFIG.use_ssl, server_key = SERVER_CONFIG.username },
		})
		return
	end
	if not is_html5() then
		callback(nil, { kind = "error", message = "Set GALAXY_PLAY_TOKEN to a dev token\n(php artisan galaxy:dev-token on the website)." })
		return
	end
	local origin = html5.run("location.origin")
	http.request(origin .. "/play-token", "GET", function(_, _, response)
		local ok, reply = pcall(json.decode, response.response or "")
		reply = ok and type(reply) == "table" and reply or {}
		if response.status == 200 and reply.token and reply.server then
			callback(reply)
		elseif response.status == 401 then
			callback(nil, { kind = "login", message = "Please log in on the website.", url = reply.login_url })
		elseif response.status == 409 then
			callback(nil, { kind = "choose", message = "Choose a game server on the website.", url = reply.play_url })
		else
			callback(nil, { kind = "error", message = "Couldn't reach Galaxy (" .. tostring(response.status) .. ")." })
		end
	end, { ["Accept"] = "application/json" })
end

-- Why the game server refused to sign us in, as a failure for the start
-- screen (see fetch_play). nakama-defold passes on Nakama's gRPC status
-- code: 16 (unauthenticated) is a server key the server doesn't accept,
-- 5 (not found) is modules/auth.lua refusing the play token; no reply at
-- all means the server couldn't be reached.
local function sign_in_failure(result, server)
	local address = tostring(server.host) .. ":" .. tostring(server.port)
	local code = result and result.code
	if code == 16 then
		return { kind = "error", message = "The game server didn't accept the game's key.\n"
			.. "Its settings on the website need fixing (server key for " .. address .. ")." }
	elseif code == 5 then
		return { kind = "login", message = "The game server didn't accept your login.\nPlease press Play on the website again.", url = M.account_url }
	elseif not result or not code then
		return { kind = "error", message = "Couldn't reach the game server (" .. address .. ")." }
	end
	return { kind = "error", message = "Couldn't sign in: " .. error_message(result, "unknown error") .. " (code " .. tostring(code) .. ")." }
end

-- Signs in to the game server the website chose. callback(ok, failure) -
-- failure as in fetch_play above.
function M.start(callback)
	fetch_play(function(play, failure)
		if not play then
			callback(false, failure)
			return
		end
		M.account_url = play.account_url or M.account_url
		SERVER_CONFIG.host = play.server.host
		SERVER_CONFIG.port = play.server.port
		SERVER_CONFIG.use_ssl = play.server.ssl == true
		SERVER_CONFIG.username = play.server.server_key
		M.client = nil -- a new client for this server
		nakama.sync(function()
			local result = nakama.authenticate_custom(client(), play.user_id, { token = play.token }, true, nil)
			if not result or result.error or not result.token then
				print("[network] sign-in refused: " .. tostring(error_message(result, "?")) .. " (code " .. tostring(result and result.code) .. ")")
				callback(false, sign_in_failure(result, play.server))
				return
			end
			use_session(result)
			online_wanted = true
			print("[network] signed in as " .. tostring(result.user_id))
			callback(true)
		end)
	end)
end

-- Opens the website's account pages in place of the game (logging out and
-- everything account-related happens there).
function M.open_account(url)
	url = url or M.account_url
	if is_html5() then
		html5.run("location.href = " .. json.encode(url))
	else
		sys.open_url(url)
	end
end

-- Calls a server RPC (nakama-server/modules/*.lua) with a JSON payload.
-- callback(decoded_result_or_nil, error_message)
local function rpc(id, payload, callback)
	nakama.sync(function()
		if not ensure_fresh_session() then
			callback(nil, "Your session has expired - please reload the page.")
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

-- callback({ version } or nil, error): the server's release.
function M.server_version(callback)
	rpc("server_version", {}, callback)
end

-- callback({ date, list = { { id, name, description, target, progress,
-- done, xp, scrip } } } or nil, error): today's assignments.
function M.assignments(callback)
	rpc("assignments", {}, callback)
end

-- Saved progress: one storage object per player, readable by its owner,
-- written only by the server.
local PROFILE_COLLECTION = "profile"
local PROFILE_KEY = "state"

-- callback(data_or_nil, error) - data is nil (no error) for a new player.
function M.load_profile(callback)
	nakama.sync(function()
		if not ensure_fresh_session() then
			callback(nil, "Your session has expired - please reload the page.")
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
	current_system_id = nil
	if M.client then
		nakama.set_bearer_token(M.client, nil)
	end
	print("[network] signed out")
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

-- XP and assignment rewards the server just granted (nakama-server/modules/
-- progress.lua): from the system's match (OP_PROGRESS) or with an economy
-- reply (arriving somewhere, via main/profile.lua). The local copy of the
-- player's XP and Scrip catch up at once (the server's saved copy replaces
-- them at the next resync anyway), then the flight HUD shows what was
-- earned.
function M.report_progress(result, reason)
	if type(result) ~= "table" then
		return
	end
	result.reason = result.reason or reason
	if type(result.xp) == "number" then
		session.xp = result.xp
	end
	if type(result.scrip_gained) == "number" and result.scrip_gained > 0 and session.scrip then
		session.scrip = session.scrip + result.scrip_gained
	end
	msg.post("flight_hud#gui", "progress", result)
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
	if op == OP_PROGRESS then
		M.report_progress(data)
	elseif op == OP_OUTPOSTS then
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

-- Fires the weapons in `slots` (e.g. { "W1", "W3" }: the ones switched on)
-- at `target` ("outpost:<faction>") until M.stop_fire(). The server decides
-- the damage: each of those weapons hits while the target is inside its
-- range and firing arc.
function M.fire(target, slots)
	if not M.match_id then
		return false
	end
	local socket, match_id = M.socket, M.match_id
	local payload = json.encode(target and { target = target, slots = slots } or {})
	nakama.sync(function()
		socket.match_data_send(match_id, OP_FIRE, payload)
	end)
	return true
end

function M.stop_fire()
	return M.fire(nil)
end

-- Asks the server to analyse the asteroids around this ship (Asteroid
-- Analyser, P): it checks the analyser is fitted and awards XP for new
-- ones after the scan (OP_PROGRESS). The colours are shown locally
-- (main/asteroid_hub.script) either way.
function M.analyse()
	if not M.match_id then
		return false
	end
	local socket, match_id = M.socket, M.match_id
	nakama.sync(function()
		socket.match_data_send(match_id, OP_ANALYSE, "{}")
	end)
	return true
end

return M
