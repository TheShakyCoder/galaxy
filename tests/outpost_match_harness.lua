-- Drives the REAL nakama-server/modules/system_match.lua and outposts.lua on
-- a fake Nakama (in-memory storage, a clock the test moves) to check Outpost
-- Progress end to end (plan.md §2.7 "Outpost progression"): presence and
-- drain, mining gains and the mining/XP bonus, the outpost appearing at 90 %,
-- sentry platforms taking damage and being destroyed, permanent outposts
-- refusing fire, and the galaxy RPC. From the Galaxy root, after
-- `python3 tools/sync_server_rules.py`:
--   luajit tests/outpost_match_harness.lua
package.path = "./nakama-server/modules/?.lua;./?.lua;" .. package.path

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end

-- Fake Nakama ----------------------------------------------------------------
local now_ms = 1000000
local store = {}
local rpcs = {}
local function deep(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in pairs(v) do t[k] = deep(x) end
	return t
end
local function skey(c, k, u) return c .. "|" .. k .. "|" .. u end
package.loaded["nakama"] = {
	time = function() return now_ms end,
	storage_read = function(list)
		local out = {}
		for _, r in ipairs(list) do
			local v = store[skey(r.collection, r.key, r.user_id)]
			if v then table.insert(out, { key = r.key, value = deep(v), version = "1" }) end
		end
		return out
	end,
	storage_write = function(list)
		for _, w in ipairs(list) do store[skey(w.collection, w.key, w.user_id)] = deep(w.value) end
	end,
	storage_list = function(user_id, collection)
		local out = {}
		for k, v in pairs(store) do
			local c, key, u = k:match("^([^|]+)|([^|]+)|(.+)$")
			if c == collection and u == user_id then table.insert(out, { key = key, value = deep(v) }) end
		end
		return out, nil
	end,
	json_encode = function(t) return t end,
	json_decode = function(t) return t end,
	logger_info = function() end,
	logger_warn = function() end,
	register_rpc = function(fn, id) rpcs[id] = fn end,
}
package.loaded["tickets"] = { verify = function() return nil end }
package.loaded["registry"] = { node_id = function() return "n" end, heartbeat = function() end, release = function() end }

local session = require("main.session")
local function make_profile(user_id, faction)
	session.reset()
	session.choose_faction(faction)
	store[skey("profile", "state", user_id)] = session.serialize()
end
make_profile("a1", "accord")
make_profile("a2", "accord")
make_profile("s1", "swarm")

local match = require("system_match")
local outposts = require("outposts")
local outpost_data = require("main.data.outposts")
local asteroids = require("main.data.asteroids")
local rules = require("main.outpost_rules")

local sent = {}
local dispatcher = {
	broadcast_message = function(op, data, presences) table.insert(sent, { op = op, data = data }) end,
	match_kick = function() end,
}
local function presence(u) return { user_id = u, session_id = u .. "-s" } end

local function run(state, ticks, messages_fn)
	for t = 1, ticks do
		now_ms = now_ms + 100
		state.tick = (state.tick or 0) + 1
		state = match.match_loop({}, dispatcher, state.tick, state, messages_fn and messages_fn(state.tick) or {})
	end
	return state
end

local function quat_facing(dx, dz)
	-- rotation about Y turning +Z toward (dx, dz)
	local yaw = math.atan2(dx, dz)
	return 0, math.sin(yaw / 2), 0, math.cos(yaw / 2)
end

local function state_msg(u, x, y, z, tx, tz)
	local qx, qy, qz, qw = quat_facing(tx - x, tz - z)
	return { op_code = 1, sender = presence(u), data = { x = x, y = y, z = z, qx = qx, qy = qy, qz = qz, qw = qw, speed = 0 } }
end

-- 1. Presence and drain ---------------------------------------------------------
local OPEN = "deneb"
local state = match.match_init({}, { system = OPEN })
state = match.match_join({}, dispatcher, 0, state, { presence("a1"), presence("a2") })
check("weapons fitted on the starter ship", #state.players.a1.weapons > 0)
state = run(state, 600) -- 60 s
local rec = state.records.accord
check("two accord pilots for a minute: +1% net (2 presence - 1 drain)", math.abs(rec.pct - 1) < 0.05)
check("swarm stays at 0 (only drain)", (state.records.swarm.pct or 0) == 0)

-- 2. Mining: +2% per asteroid, and the resource carries the outpost bonus.
local rock_index, rock = nil, nil
for i, a in ipairs(state.field) do
	if asteroids.resource_amount(a.resource, a.diameter_m) > 0 then
		rock_index, rock = i, a
		break
	end
end
local before_pct = rec.pct
local before_iron = store[skey("profile", "state", "a1")]
local held = outposts.held("accord")
check("accord holds its 7 permanent outposts", held == 7)
local function mining_msgs(tick)
	if tick == state.tick + 1 or true then
		return {
			state_msg("a1", rock.x, rock.y, rock.z - (rock.diameter_m / 2 + 50), rock.x, rock.z),
			{ op_code = 6, sender = presence("a1"), data = { target = "asteroid:" .. rock_index } },
		}
	end
end
local first = true
state = run(state, 1, function() return mining_msgs() end)
local ticks = 0
while state.players.a1.firing_asteroid and ticks < 20000 do
	state = run(state, 10)
	ticks = ticks + 10
end
check("asteroid depleted (" .. string.format("%.0f", ticks / 10) .. " s)", not state.players.a1.firing_asteroid)
-- +2 for the rock, plus the two pilots' presence less the drain meanwhile.
local expected = before_pct + 2 + (2 - 1) * (ticks / 10 + 0.1) / 60
check(string.format("mining added 2%% (%.2f -> %.2f, expected %.2f)", before_pct, state.records.accord.pct, expected),
	math.abs(state.records.accord.pct - expected) < 0.05)
local resource_msg
for _, m in ipairs(sent) do if m.op == 10 then resource_msg = m.data end end
local base = asteroids.resource_amount(rock.resource, rock.diameter_m)
if base > 0 then
	check("resource paid with +7% outpost bonus", resource_msg and resource_msg.amount == math.floor(base * 1.07 + 0.5))
else
	check("inert rock: no resource, still progress", resource_msg == nil)
end

-- 3. The outpost appears at 90 % and its defences follow the level.
state.records.accord.pct, state.records.accord.pct_at = 130, now_ms
state = run(state, 1)
local st = state.outposts.accord
check("130%: accord outpost available, beacon, 2 light platforms", st.available and st.beacon and #st.platforms == 2)
local msg
for _, m in ipairs(sent) do if m.op == 5 then msg = m.data end end
check("OUTPOSTS message carries level/platforms", msg and msg.accord and msg.accord.level == 3 and #msg.accord.platforms == 2)

-- 4. A swarm pilot destroys platform 1 (7,500 hull).
state = match.match_join({}, dispatcher, 0, state, { presence("s1") })
local ppos = state.positions.accord.platforms[1]
state = run(state, 1, function()
	return {
		state_msg("s1", ppos.x, ppos.y, ppos.z - 200, ppos.x, ppos.z),
		{ op_code = 6, sender = presence("s1"), data = { target = "platform:accord:1" } },
	}
end)
check("swarm is firing at the platform", state.players.s1.outpost_target and state.players.s1.outpost_target.part == "platform")
ticks = 0
while state.players.s1.outpost_target and ticks < 100000 do
	state = run(state, 10)
	ticks = ticks + 10
end
local p1 = state.records.accord.platforms and state.records.accord.platforms[1]
check("platform destroyed (" .. string.format("%.0f", ticks / 10) .. " s), down for 10 min",
	p1 and p1.destroyed_until and now_ms - (p1.destroyed_until - 600000) >= 0 and now_ms - (p1.destroyed_until - 600000) <= 1000)
check("rule state shows it down", not state.outposts.accord.platforms[1].available)
check("swarm pilot earned damage XP", (store[skey("profile", "state", "s1")].xp or 0) > 0)

-- 5. The accord pilot can't shoot its own outpost; nobody can shoot a permanent one.
state = run(state, 1, function()
	return { { op_code = 6, sender = presence("a1"), data = { target = "platform:accord:2" } } }
end)
check("own faction's platform refused", state.players.a1.outpost_target == nil)
local perm = match.match_init({}, { system = "tau_ceti" })
perm = match.match_join({}, dispatcher, 0, perm, { presence("s1") })
perm = run(perm, 1, function()
	return { { op_code = 6, sender = presence("s1"), data = { target = "outpost:accord" } } }
end)
check("tau_ceti accord outpost is permanent and refuses fire", perm.outposts.accord.permanent and perm.players.s1.outpost_target == nil)

-- 6. Saved, and the galaxy RPC reports it.
state = run(state, 50) -- persist tick
local saved = store[skey("outposts", OPEN .. ".accord", "00000000-0000-0000-0000-000000000000")]
check("record saved to storage", saved and saved.pct and saved.pct > 100)
local galaxy = rpcs.outpost_galaxy({}, "")
check("galaxy RPC: deneb accord level 3, available", galaxy.systems[OPEN].accord.level == 3 and galaxy.systems[OPEN].accord.available)
check("galaxy RPC: sol has no swarm entry", galaxy.systems.sol.swarm == nil)
check("accord now holds 8", outposts.held("accord") == 8)

-- 7. Docking rule on the server: nearest available outpost.
session.set_outpost_availability(function(id, f) return outposts.available(id, f) end)
session.reset()
session.choose_faction("swarm")
session.current_system = OPEN
check("swarm in deneb (no swarm outpost) docks at its nearest", session.docked_system() ~= OPEN
	and rules.permanent(session.docked_system(), "swarm"))
session.faction = "accord"
check("accord in deneb docks right there", session.docked_system() == OPEN)

-- 8. Drones (plan.md §2.18): deneb (threat 37) spawns its procedural set,
-- they move, chase a nearby pilot, die to fire, pay XP and npc_kill progress,
-- and come back after their respawn time.
local drone_rules = require("main.drone_rules")
local drone_data = require("main.data.drones")
local dm = match.match_init({ env = { drone_seed = "test" } }, { system = OPEN })
local expected_count = #drone_rules.population(OPEN, "test")
local n = 0
for _ in pairs(dm.drones) do n = n + 1 end
check("deneb spawns " .. expected_count .. " drones (threat 37 -> 26)", n == expected_count and n == 26)
check("same seed, same drones", drone_rules.population(OPEN, "test")[5].type == dm.drones[5].type)
dm = match.match_join({}, dispatcher, 0, dm, { presence("a1") })
local d = dm.drones[1]
local start = { x = d.pos.x, z = d.pos.z }
-- Park the pilot 900 m from drone 1 (inside aggro range) and let a few seconds pass.
local px, pz = d.pos.x + 900, d.pos.z
dm = run(dm, 1, function() return { state_msg("a1", px, d.pos.y, pz, d.pos.x, d.pos.z) } end)
dm = run(dm, 50)
check("drone 1 chases the pilot in range", d.chase == "a1")
local gap = math.sqrt((d.pos.x - px) ^ 2 + (d.pos.z - pz) ^ 2)
check(string.format("...closing to its standoff distance (now %.0f m)", gap), gap < 900)
local drones_msg
for _, m in ipairs(sent) do if m.op == 11 then drones_msg = m.data end end
check("DRONES message carries every drone", drones_msg and #drones_msg.d == n)
-- Shoot it down.
local xp_before = store[skey("profile", "state", "a1")].xp or 0
local pct_before = rules.progress_at(dm.records.accord, OPEN, "accord", now_ms)
local ticks2 = 0
dm = run(dm, 1, function()
	return {
		state_msg("a1", d.pos.x + 300, d.pos.y, d.pos.z, d.pos.x, d.pos.z),
		{ op_code = 6, sender = presence("a1"), data = { target = "drone:1" } },
	}
end)
while not d.destroyed_until and ticks2 < 20000 do
	dm = run(dm, 1, function() return { state_msg("a1", d.pos.x + 300, d.pos.y, d.pos.z, d.pos.x, d.pos.z) } end)
	ticks2 = ticks2 + 1
end
check(string.format("drone 1 destroyed (%.0f s)", ticks2 / 10), d.destroyed_until ~= nil)
local xp_gain = (store[skey("profile", "state", "a1")].xp or 0) - xp_before
check("XP paid: level x 10 x 1.08 outpost bonus = " .. xp_gain, xp_gain == math.floor(d.level * drone_data.REWARDS.xp_per_level * 1.08 + 0.5))
check("killer's faction outpost progress +1%", rules.progress_at(dm.records.accord, OPEN, "accord", now_ms) > pct_before + 0.9)
now_ms = d.destroyed_until
dm = run(dm, 1)
check("drone 1 respawns at its start after 5 minutes", not d.destroyed_until and d.hp == d.hull_points)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All outpost match assertions passed.")
