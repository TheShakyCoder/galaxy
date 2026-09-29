--[[
Server-authoritative economy: the only way a player's saved progress
(currencies, resources, ships, modules, skins, flight state) changes.

The client applies each change locally for responsiveness, then calls the
`economy` RPC with the same operation:  { op = "purchase_ship", args = { "escort_assault" } }.
This module loads the player's profile, replays the operation with the
client's own rules (main/session.lua, copied here by
tools/sync_server_rules.py) and saves the result. Anything the rules reject
(can't afford it, doesn't own it, jump out of range, ...) is refused, and the
reply carries the authoritative profile so the client can resync.

The profile is storage object profile/state, readable by its owner but
writable only by the server (permission_write = 0); modules/accounts.lua also
refuses any client write to that collection.

Reply: { ok = true, result, profile } or { ok = false, error, profile }.
]]

local nk = require("nakama")
local session = require("main.session")
local outposts = require("outposts")

-- Destroyed outposts count as absent for docking/launch/respawn rules.
session.set_outpost_availability(function(system_id, faction)
	return outposts.get(system_id, faction).available
end)

local COLLECTION = "profile"
local KEY = "state"
local FACTIONS = { accord = true, swarm = true }
local MAX_WRITE_ATTEMPTS = 3

local ALLOWED = {}
for _, name in ipairs(session.OPS) do
	ALLOWED[name] = true
end

local function reply(tbl)
	return nk.json_encode(tbl)
end

local function read_profile(user_id)
	local objects = nk.storage_read({ { collection = COLLECTION, key = KEY, user_id = user_id } })
	local object = objects[1]
	if object then
		return object.value, object.version
	end
	return nil, nil
end

-- Arguments must be plain values (ids, slot names, numbers); nothing else is
-- ever needed by a rule.
local function valid_args(args)
	if type(args) ~= "table" then
		return false
	end
	for _, value in pairs(args) do
		local t = type(value)
		if t ~= "string" and t ~= "number" and t ~= "boolean" then
			return false
		end
	end
	return true
end

-- One attempt: returns (response table, retry?).
local function apply(user_id, op, args)
	local saved, version = read_profile(user_id)

	if op == "choose_faction" then
		if saved and saved.faction then
			return { ok = false, error = "Faction already chosen.", profile = saved }, false
		end
		if not FACTIONS[args[1]] then
			return { ok = false, error = "Unknown faction." }, false
		end
		session.reset()
	else
		if not (saved and saved.faction) then
			return { ok = false, error = "No profile yet - choose a faction first." }, false
		end
		session.restore(saved)
	end

	local result = session[op](unpack(args))
	if result == nil and op ~= "choose_faction" or result == false then
		return { ok = false, error = "Not allowed: " .. op, profile = saved }, false
	end

	local profile = session.serialize()
	local ok, err = pcall(nk.storage_write, { {
		collection = COLLECTION, key = KEY, user_id = user_id, value = profile,
		version = version or "*", -- "*": only create if it doesn't exist yet
		permission_read = 1, permission_write = 0,
	} })
	if not ok then
		-- Another request for this player changed the profile since it was
		-- read (version mismatch): start again from the new version.
		nk.logger_warn(string.format("economy write conflict for %s (%s): %s", user_id, op, tostring(err)))
		return nil, true
	end
	return { ok = true, result = type(result) ~= "table" and result or nil, profile = profile }, false
end

local function economy(context, payload)
	local ok_decode, input = pcall(nk.json_decode, payload ~= "" and payload or "{}")
	if not ok_decode or type(input) ~= "table" then
		return reply({ ok = false, error = "Bad request." })
	end
	local op, args = input.op, input.args or {}
	if type(op) ~= "string" or not ALLOWED[op] or not valid_args(args) then
		return reply({ ok = false, error = "Unknown operation." })
	end

	for _ = 1, MAX_WRITE_ATTEMPTS do
		local response, retry = apply(context.user_id, op, args)
		if not retry then
			return reply(response)
		end
	end
	local saved = read_profile(context.user_id)
	return reply({ ok = false, error = "Busy, please retry.", profile = saved })
end

nk.register_rpc(economy, "economy")
nk.logger_info("economy module loaded")
