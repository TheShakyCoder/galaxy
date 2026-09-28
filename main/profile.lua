-- Keeps the player's progress (main/session.lua) in step with the server,
-- which owns it (nakama-server/modules/economy.lua).
--
-- Every change the game makes through session.lua is applied locally at once
-- (so buying, fitting and jumping feel instant) and reported here as an
-- operation - e.g. { op = "purchase_ship", args = { "escort_assault" } }. Operations
-- go to the server one at a time, in order; the server replays each with the
-- same rules and saves the result. When the queue empties, the server's copy
-- replaces the local one. If the server refuses an operation (the local
-- state was tampered with, or client and server disagree), the queue is
-- dropped, the server's copy is adopted and the outpost is told to refresh.
--
-- Sending is driven by M.update(dt), called every frame from
-- main/remote_ships.script (always running), so network replies never
-- depend on whichever GUI made the change still being enabled.

local session = require("main.session")
local network = require("main.network")

local M = {}

local RETRY_DELAY = 3 -- seconds before resending after a network error

local queue = {} -- operations not yet confirmed: { op, args }
local sending = false
local retry_wait = 0
local flush_callbacks = {}
local generation = 0 -- bumped by unload(), so replies for a logged-out player are ignored

local function adopt(profile)
	session.set_on_change(nil) -- replacing state isn't a change to report
	session.restore(profile)
	session.set_on_change(M.record)
end

local function run_flush_callbacks()
	local callbacks = flush_callbacks
	flush_callbacks = {}
	for _, callback in ipairs(callbacks) do
		callback()
	end
end

local function send_next()
	if sending or retry_wait > 0 or #queue == 0 then
		return
	end
	sending = true
	local item = queue[1]
	local sent_generation = generation
	network.economy(item.op, item.args, function(response, err)
		if sent_generation ~= generation then
			return
		end
		sending = false
		if not response then
			-- Network trouble: keep the queue and try again shortly.
			print("[profile] couldn't reach the server (" .. tostring(err) .. "), retrying")
			retry_wait = RETRY_DELAY
			return
		end
		if response.ok then
			table.remove(queue, 1)
			if #queue == 0 then
				if response.profile then
					adopt(response.profile)
				end
				run_flush_callbacks()
			end
			return
		end
		-- Refused: the server's copy wins.
		print("[profile] server refused " .. item.op .. ": " .. tostring(response.error))
		queue = {}
		if response.profile then
			adopt(response.profile)
		end
		msg.post("outpost#gui", "profile_resynced", { error = response.error })
		run_flush_callbacks()
	end)
end

-- session.lua's change hook: queue the operation for the server.
function M.record(op, args)
	table.insert(queue, { op = op, args = args or {} })
end

function M.update(dt)
	if retry_wait > 0 then
		retry_wait = math.max(0, retry_wait - dt)
	end
	send_next()
end

-- Loads the logged-in player's progress into session.lua and starts
-- reporting changes. callback(ok, has_faction, error): has_faction is false
-- for a new player, who still needs to pick a faction (main/faction_select).
function M.load(callback)
	network.load_profile(function(data, err)
		if err then
			callback(false, false, err)
			return
		end
		queue = {}
		session.set_on_change(nil)
		if data and data.faction then
			session.restore(data)
		else
			session.reset()
		end
		session.set_on_change(M.record)
		callback(true, session.get_faction() ~= nil)
	end)
end

-- callback() once every queued change has been confirmed (or refused) by the
-- server - straight away if nothing is waiting. Used before logging out.
function M.flush(callback)
	if #queue == 0 and not sending then
		callback()
	else
		table.insert(flush_callbacks, callback)
	end
end

-- Stops reporting changes and clears the in-memory state (logging out). Call
-- M.flush() first so queued changes reach the server.
function M.unload()
	generation = generation + 1
	sending = false
	queue = {}
	flush_callbacks = {}
	retry_wait = 0
	session.set_on_change(nil)
	session.reset()
end

return M
