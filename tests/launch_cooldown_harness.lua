-- Ad-hoc verification harness for the dock / launch cooldown (plan.md §2.16):
-- session.M.dock / M.resume / M.launch / M.launch_cooldown_left, and the
-- serialize/restore round trip of the two fields that carry it (`flying` and
-- `launch_blocked_until`). Pure Lua - main/session.lua is engine-free - so run
-- it with luajit (or lua) from the Galaxy root:
--   luajit tests/launch_cooldown_harness.lua
--
-- The clock is driven by hand (session.set_clock) so the two cooldowns are
-- tested by moving time, not by waiting for it.
package.path = "./?.lua;./?/init.lua;" .. package.path

local session = require("main.session")

local failures = 0
local function check(label, cond)
	if cond then
		print("PASS  " .. label)
	else
		failures = failures + 1
		print("FAIL  " .. label)
	end
end

-- A clock the test moves itself, in seconds (same unit as os.time/nk.time).
local now = 1000000
session.set_clock(function()
	return now
end)
local function advance(seconds)
	now = now + seconds
end

session.choose_faction("accord")

-- 1. A fresh character has nothing to cool down.
check("no cooldown on a fresh character", session.launch_cooldown_left() == 0)
check("not flying on a fresh character", session.is_flying() == false)
check("first launch allowed", session.launch() == true)
check("flying after launch", session.is_flying() == true)
check("launching arms no cooldown", session.launch_cooldown_left() == 0)

-- 2. Launching again without docking is refused - docking is the only way back
--    to the outpost, and docking is what arms the cooldown. Without this the
--    cooldown could simply be skipped by never reporting the dock.
check("second launch refused while flying", session.launch() == false)

-- 3. Docking starts the 10-second cooldown.
check("dock clears flying", session.dock() == true and session.is_flying() == false)
check("dock arms a 10s cooldown", session.launch_cooldown_left() == 10)

-- 4. ...during which launching is refused, and changes nothing.
local system_before = session.get_current_system()
advance(9)
check("9s in: still cooling down", math.abs(session.launch_cooldown_left() - 1) < 0.001)
check("9s in: launch refused", session.launch() == false)
check("refused launch stayed docked", session.is_flying() == false)
check("refused launch changed nothing", session.get_current_system() == system_before)

-- 5. ...and allowed again once it elapses.
advance(1)
check("10s in: cooldown over", session.launch_cooldown_left() == 0)
check("10s in: launch allowed", session.launch() == true)
check("flying again", session.is_flying() == true)

-- 6. A session that ENDS in space (reload / close / quit mid-flight) is not a
--    free relaunch: the next one starts with the 60-second cooldown instead.
local saved = session.serialize()
check("in-flight profile saves flying", saved.flying == true)

-- next page load: reset, load the profile back, and start the session.
session.reset()
session.restore(saved)
check("restored as flying", session.is_flying() == true)
check("resume at the outpost", session.resume() == true)
check("resume clears flying", session.is_flying() == false)
check("resume arms a 60s cooldown", session.launch_cooldown_left() == 60)
check("launch refused during it", session.launch() == false)
advance(59)
check("59s in: still refused", session.launch() == false)
advance(1)
check("60s in: allowed", session.launch() == true)

-- 7. A session that ends DOCKED arms nothing new: the dock cooldown carries on
--    in the profile, so a quick reload is not punished by the long one.
session.dock()
advance(2) -- 8 seconds of the dock cooldown left
local docked_save = session.serialize()
session.reset()
session.restore(docked_save)
session.resume()
check("docked session: no 60s cooldown", session.launch_cooldown_left() == 8)
check("docked session: launch still refused", session.launch() == false)
advance(8)
check("docked session: allowed after the 10s", session.launch() == true)

-- 8. A dock never SHORTENS a cooldown that is already running.
session.reset()
session.restore({ faction = "accord", flying = true, launch_blocked_until = now + 500 })
session.resume()
check("resume keeps the longer cooldown already running", session.launch_cooldown_left() == 500)
session.dock()
check("dock did not shorten it to 10s", session.launch_cooldown_left() > 10)

-- 9. The profiles' timestamps are on the SERVER's clock, so the game lines its
--    own clock up with the server's before reading them (session.sync_clock,
--    fed by economy.lua's `now`).
now = 2000000
local server_seconds = now + 300 -- this host's clock is 5 minutes behind the server
session.sync_clock(server_seconds * 1000)
session.reset()
session.restore({ faction = "accord", flying = true })
session.resume()
check("server-clock cooldown reads as 60s, not 360", math.abs(session.launch_cooldown_left() - 60) < 0.001)
advance(60)
check("server-clock cooldown elapses with the host clock", session.launch() == true)

-- 10. Both fields round-trip through the profile and are cleared by reset().
session.dock()
session.restore(session.serialize())
check("round trip keeps flying", session.is_flying() == false)
check("round trip keeps the cooldown", session.launch_cooldown_left() == 10)
session.reset()
check("reset clears the cooldown", session.launch_blocked_until == nil)
check("reset clears flying", session.flying == nil)
check("reset leaves no cooldown left", session.launch_cooldown_left() == 0)

-- 11. Both new rules are reachable operations the server will accept and replay
--     (nakama-server/modules/economy.lua checks op names against session.OPS).
local allowed = {}
for _, name in ipairs(session.OPS) do
	allowed[name] = true
end
check("dock is a server operation", allowed.dock == true)
check("resume is a server operation", allowed.resume == true)

-- 12. Server-side replay, the way nakama-server/modules/economy.lua runs it:
-- load the saved profile, apply the operation, save the result. Both timestamps
-- are checked against the SERVER's clock (session.set_clock, as economy.lua
-- sets it from nk.time()), which is what makes the cooldown survive a client
-- that never reports its docking at all.
local server_seconds = 3000000
session.set_clock(function()
	return server_seconds
end)
session.sync_clock(server_seconds * 1000) -- host clock == server clock here (offset 0)

-- Returns (result, saved profile) for one server-side operation.
local function server_apply(saved, op)
	session.reset()
	session.restore(saved)
	local result = session[op]()
	return result, session.serialize()
end

local applied, flying_save = server_apply({ faction = "accord" }, "launch")
check("server: launch from a docked profile allowed", applied == true and flying_save.flying == true)

local relaunch = server_apply(flying_save, "launch")
check("server: relaunch refused while the save says flying", relaunch == false)

local docked, docked_save = server_apply(flying_save, "dock")
check("server: dock allowed and stamped on the server clock", docked == true and docked_save.launch_blocked_until == server_seconds + 10)

server_seconds = server_seconds + 9
local early = server_apply(docked_save, "launch")
check("server: launch 9s after docking refused", early == false)
server_seconds = server_seconds + 1
local in_time = server_apply(docked_save, "launch")
check("server: launch 10s after docking allowed", in_time == true)

-- The player left the game mid-flight: the save still says flying, so the
-- session that follows starts with the long cooldown instead.
local resumed, resumed_save = server_apply(flying_save, "resume")
check("server: resume after an in-flight session arms 60s", resumed == true and resumed_save.launch_blocked_until == server_seconds + 60)
local after_resume = server_apply(resumed_save, "launch")
check("server: launch right after that refused", after_resume == false)
server_seconds = server_seconds + 60
local after_wait = server_apply(resumed_save, "launch")
check("server: launch 60s after that allowed", after_wait == true)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All launch-cooldown assertions passed.")
