--[[
System registry: which match (on which node) hosts each star system.

One storage object per system, system_matches/<system_id>, owned by the
system user so every node sees the same registry through the shared
database:
  { match_id, node, endpoint, players, heartbeat (ms) }

A running system match refreshes its heartbeat every few seconds
(modules/system_match.lua); an entry whose heartbeat is older than
STALE_MS is treated as gone and replaced by modules/directory.lua.

Node identity comes from the runtime env (--runtime.env):
  NODE_ID          name of this Nakama node (default "node1")
  PUBLIC_ENDPOINT  host clients should connect to for matches on this node.
                   Empty means "the server you're already talking to" - the
                   only case until there are several nodes.
]]

local nk = require("nakama")

local M = {}

local COLLECTION = "system_matches"
local SYSTEM_USER = "00000000-0000-0000-0000-000000000000"
M.STALE_MS = 15000

function M.node_id(context)
	local env = context.env or {}
	return (env.NODE_ID and env.NODE_ID ~= "") and env.NODE_ID or "node1"
end

function M.endpoint(context)
	local env = context.env or {}
	return env.PUBLIC_ENDPOINT or ""
end

-- entry (table or nil), version (string or nil)
function M.read(system_id)
	local objects = nk.storage_read({ { collection = COLLECTION, key = system_id, user_id = SYSTEM_USER } })
	local object = objects[1]
	if object then
		return object.value, object.version
	end
	return nil, nil
end

-- Writes `entry` only if the stored version is still `version` (nil: only if
-- there's no entry yet). Returns true on success, false if someone else
-- changed it first.
function M.write(system_id, entry, version)
	local ok = pcall(nk.storage_write, { {
		collection = COLLECTION, key = system_id, user_id = SYSTEM_USER, value = entry,
		version = version or "*", permission_read = 0, permission_write = 0,
	} })
	return ok
end

function M.is_live(entry)
	return entry ~= nil and entry.match_id ~= nil and nk.time() - (entry.heartbeat or 0) < M.STALE_MS
end

-- Called by a running match: refresh its entry (unless another match has
-- taken the system over meanwhile).
function M.heartbeat(context, system_id, players)
	local entry, version = M.read(system_id)
	if entry and entry.match_id ~= context.match_id then
		return
	end
	M.write(system_id, {
		match_id = context.match_id, node = M.node_id(context), endpoint = M.endpoint(context),
		players = players, heartbeat = nk.time(),
	}, version)
end

-- Called by a match that's shutting down: drop its entry if it's still the
-- registered one.
function M.release(context, system_id)
	local entry, version = M.read(system_id)
	if entry and entry.match_id == context.match_id then
		pcall(nk.storage_delete, { { collection = COLLECTION, key = system_id, user_id = SYSTEM_USER, version = version } })
	end
end

return M
