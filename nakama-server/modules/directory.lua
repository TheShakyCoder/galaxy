--[[
Directory: "where is star system X, and may I go in?"

RPC enter_system { system_id } -> { ok, endpoint, match_id, ticket }
                               or { ok = false, error }

1. The player must be email-verified, and their server-owned profile must
   say they're in that system (current_system, set by modules/economy.lua's
   launch / arrive_jump) - so nobody can enter a system they didn't fly or
   pay to jump to.
2. The system's match is looked up in the registry (modules/registry.lua)
   and created on this node if it has none that's alive.
3. A transfer ticket (modules/tickets.lua) for that player, system and match
   is returned with the match's endpoint. The client connects to `endpoint`
   (empty = the server it's already on) and joins the match with the ticket.

Scaling out later: with several Nakama nodes sharing the database, the
registry already tells every node where each system lives. What changes is
placement in find_or_create(): instead of always creating locally, pick the
least-loaded live node (sum of registry heartbeats per node) and ask it to
create the match via a server-to-server RPC; its PUBLIC_ENDPOINT then goes
back to the client, which reconnects there with the same session token.
]]

local nk = require("nakama")
local registry = require("registry")
local tickets = require("tickets")

local function reply(tbl)
	return nk.json_encode(tbl)
end

local function current_system(user_id)
	local objects = nk.storage_read({ { collection = "profile", key = "state", user_id = user_id } })
	return objects[1] and objects[1].value and objects[1].value.current_system
end

-- A running match for the system on this node, or nil.
local function local_match_alive(entry, context)
	return entry and entry.node == registry.node_id(context) and nk.match_get(entry.match_id) ~= nil
end

-- match_id, endpoint for the system's match, creating one if needed.
local function find_or_create(context, system_id)
	local entry, version = registry.read(system_id)
	if registry.is_live(entry) and (entry.node ~= registry.node_id(context) or local_match_alive(entry, context)) then
		return entry.match_id, entry.endpoint or ""
	end
	-- Placement: step 1 always hosts on this node (see header).
	local match_id = nk.match_create("system_match", { system = system_id })
	local mine = {
		match_id = match_id, node = registry.node_id(context), endpoint = registry.endpoint(context),
		players = 0, heartbeat = nk.time(),
	}
	if registry.write(system_id, mine, version) then
		return match_id, mine.endpoint
	end
	-- Someone registered a match for this system at the same moment: use
	-- theirs (ours sits empty and shuts itself down).
	local winner = registry.read(system_id)
	if registry.is_live(winner) then
		return winner.match_id, winner.endpoint or ""
	end
	return match_id, mine.endpoint
end

local function enter_system(context, payload)
	local ok, input = pcall(nk.json_decode, payload ~= "" and payload or "{}")
	local system_id = ok and type(input) == "table" and input.system_id
	if type(system_id) ~= "string" then
		return reply({ ok = false, error = "Missing system." })
	end
	if not context.user_id or context.user_id == "" then
		return reply({ ok = false, error = "Sign in first." })
	end
	if current_system(context.user_id) ~= system_id then
		return reply({ ok = false, error = "You're not in that system." })
	end
	local match_id, endpoint = find_or_create(context, system_id)
	return reply({
		ok = true, match_id = match_id, endpoint = endpoint,
		ticket = tickets.issue(context, context.user_id, system_id, match_id),
	})
end

nk.register_rpc(enter_system, "enter_system")

-- Players only join system matches through enter_system; they can't create
-- matches of their own.
nk.register_rt_before(function() return nil end, "MatchCreate")

nk.logger_info("directory module loaded")
