--[[
Server-only RPCs for the website (Laravel), called server-to-server with
this server's NAKAMA_HTTP_KEY. Players are identified by their website UUID
(their custom id here, see modules/auth.lua). Calls made with a player's
session are refused.

  player_summary { user_ids = [uuid, ...] }  (at most 100)
    -> { players = { [uuid] = summary } }  (players who never joined are
       missing). summary = { faction, faction_name, ship_id, ship_name,
       tope, hydrogen, water, iron, current_system, system_name, xp, level,
       rank }

  delete_player { user_id = uuid } -> { deleted = true|false }
    Deletes the account and everything it owns (the website's account
    deletion).
]]

local nk = require("nakama")
local ships = require("main.data.ships") -- copied from the game by tools/sync_server_rules.py
local star_systems = require("main.data.star_systems")
local ranks = require("main.data.ranks")

local MAX_USERS = 100
local FACTION_NAMES = { accord = "The Accord", swarm = "The Swarm" }

local function reply(tbl)
	return nk.json_encode(tbl)
end

local function server_only(context)
	if context.user_id and context.user_id ~= "" then
		error("server-to-server only")
	end
end

local function decode(payload)
	local ok, input = pcall(nk.json_decode, payload ~= "" and payload or "{}")
	if not ok or type(input) ~= "table" then
		error("bad request")
	end
	return input
end

-- This server's user id for a website UUID, or nil if they never joined.
local function user_id_for(uuid)
	if type(uuid) ~= "string" or #uuid < 6 or #uuid > 128 then
		return nil
	end
	local ok, user_id = pcall(nk.authenticate_custom, uuid, nil, false)
	return ok and user_id or nil
end

local function ship_name(ship_id, faction)
	local ship = ship_id and ships.SHIPS[ship_id]
	local skin = ship and ship.faction_skins and ship.faction_skins[faction]
	return (skin and skin.name ~= "<TBD>") and skin.name or ship_id
end

local function summary(profile)
	local system = profile.current_system and star_systems.SYSTEMS[profile.current_system]
	return {
		faction = profile.faction,
		faction_name = FACTION_NAMES[profile.faction],
		ship_id = profile.active_ship_id,
		ship_name = ship_name(profile.active_ship_id, profile.faction),
		tope = profile.tope,
		hydrogen = profile.hydrogen,
		water = profile.water,
		iron = profile.iron,
		current_system = profile.current_system,
		system_name = system and system.name or nil,
		xp = profile.xp or 0,
		level = ranks.level_for_xp(profile.xp),
		rank = ranks.rank_name(profile.faction, ranks.level_for_xp(profile.xp)),
	}
end

local function player_summary(context, payload)
	server_only(context)
	local uuids = decode(payload).user_ids
	if type(uuids) ~= "table" or #uuids > MAX_USERS then
		error("user_ids must be a list of at most " .. MAX_USERS)
	end
	local players = {}
	for _, uuid in ipairs(uuids) do
		local user_id = user_id_for(uuid)
		if user_id then
			local objects = nk.storage_read({ { collection = "profile", key = "state", user_id = user_id } })
			players[uuid] = summary(objects[1] and objects[1].value or {})
		end
	end
	return reply({ players = players })
end

local function delete_player(context, payload)
	server_only(context)
	local user_id = user_id_for(decode(payload).user_id)
	if not user_id then
		return reply({ deleted = false })
	end
	nk.account_delete_id(user_id, false)
	nk.logger_info("deleted player " .. user_id .. " at the website's request")
	return reply({ deleted = true })
end

nk.register_rpc(player_summary, "player_summary")
nk.register_rpc(delete_player, "delete_player")
