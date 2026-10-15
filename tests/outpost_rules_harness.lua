-- Checks main/outpost_rules.lua (plan.md §2.7 "Outpost progression"): the
-- progress meter, control levels, permanent outposts, destruction and
-- repair, defences, hull scaling and the nearest-outpost rule. Pure Lua,
-- from the Galaxy root:
--   luajit tests/outpost_rules_harness.lua
package.path = "./?.lua;" .. package.path
local rules = require("main.outpost_rules")
local outposts = require("main.data.outposts")
local star_systems = require("main.data.star_systems")

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

local MIN = 60 * 1000
local OPEN = "deneb" -- not in either faction's home region
check("deneb is open to both", not rules.permanent(OPEN, "accord") and not rules.permanent(OPEN, "swarm")
	and star_systems.has_outpost(OPEN, "accord") and star_systems.has_outpost(OPEN, "swarm"))

-- Permanent outposts: home + 6 nearest, only for the owner.
check("sol permanent for accord", rules.permanent("sol", "accord"))
check("sol not for swarm", not rules.permanent("sol", "swarm"))
check("alnair permanent for swarm", rules.permanent("alnair", "swarm"))
check("tau_ceti permanent for accord", rules.permanent("tau_ceti", "accord"))
local count = 0
for id in pairs(star_systems.SYSTEMS) do
	if rules.permanent(id, "accord") then count = count + 1 end
end
check("accord has 7 permanent outposts", count == 7)

-- The meter: untouched = 0 % (permanent: 90 %), drains 1 %/min, clamps.
check("untouched open system at 0%", rules.progress_at(nil, OPEN, "accord", 0) == 0)
check("untouched permanent at 90%", rules.progress_at(nil, "sol", "accord", 0) == 90)
local r = {}
rules.add_progress(r, OPEN, "accord", 100, 0)
check("added 100%", r.pct == 100 and r.pct_at == 0)
check("10 minutes later: 90%", near(rules.progress_at(r, OPEN, "accord", 10 * MIN), 90))
check("never below 0", rules.progress_at(r, OPEN, "accord", 1000 * MIN) == 0)
rules.add_progress(r, OPEN, "accord", 1000, 0)
check("capped at 300%", r.pct == 300)
local p = { pct = 95, pct_at = 0 }
check("permanent never drains below 90", rules.progress_at(p, "sol", "accord", 100 * MIN) == 90)

-- Control levels and what stands.
local function lay(pct) return rules.layout(pct, false) end
check("49%: level 0, nothing", lay(49).level == 0 and lay(49).tier == nil)
check("50%: level 1, still no outpost", lay(50).level == 1 and lay(50).tier == nil)
check("90%: regular outpost", lay(90).level == 2 and lay(90).tier == "outpost" and not lay(90).beacon)
check("125%: beacon + 2 light", lay(125).beacon and #lay(125).platforms == 2 and lay(125).platforms[1] == "light")
check("175%: 4 light", #lay(175).platforms == 4)
local l5 = lay(200)
check("200%: upgraded, 2 medium then 2 light", l5.tier == "upgraded_outpost" and l5.platforms[1] == "medium" and l5.platforms[3] == "light")
check("225%: 4 medium", lay(225).platforms[4] == "medium")
local l7 = lay(250)
check("250%: 2 heavy + 2 medium", l7.platforms[1] == "heavy" and l7.platforms[2] == "heavy" and l7.platforms[3] == "medium")
check("275%: fortified, 4 heavy", lay(275).tier == "fortified_outpost" and lay(275).platforms[4] == "heavy")
check("300%: still level 8 (9/10 have no thresholds)", lay(300).level == 8)
check("permanent below 90 still has an outpost", rules.layout(0, true).tier == "outpost")

-- State: presence, availability, hull, defences.
local st = rules.state(OPEN, "accord", nil, 0, 1)
check("untouched open system: exists, no outpost", st.exists and not st.present and not st.available)
st = rules.state("sol", "swarm", nil, 0, 1)
check("swarm can never have one in sol", not st.exists and not st.available)
st = rules.state(OPEN, "accord", { pct = 130, pct_at = 0 }, 0, 1)
check("130%: available, full hull 50000", st.available and st.hp == 50000 and st.max_hp == 50000)
check("130%: beacon and 2 platforms standing", st.beacon and st.beacon.available and #st.platforms == 2 and st.platforms[1].max_hp == 7500)
st = rules.state(OPEN, "accord", { pct = 280, pct_at = 0, hp_frac = 0.5 }, 0, 1)
check("fortified at half hull = 30000/60000", st.max_hp == 60000 and st.hp == 30000)
st = rules.state(OPEN, "accord", { pct = 280, pct_at = 0, hp_frac = 0.5 }, 0, 1.36)
check("underdog +36% hull keeps the fraction", st.max_hp == 81600 and st.hp == 40800)

-- Destruction and repair: resume at the level reached.
local destroyed = { pct = 150, pct_at = 0, destroyed_until = 60 * MIN }
st = rules.state(OPEN, "accord", destroyed, 30 * MIN, 1)
check("destroyed: present but not available, no defences", st.present and not st.available and st.beacon == nil and #st.platforms == 0)
st = rules.state(OPEN, "accord", destroyed, 60 * MIN, 1)
check("after the hour: back (150% - 60 min drain = 90%)", st.available and st.hp == 50000 and st.level == 2)
st = rules.state(OPEN, "accord", { pct = 100, pct_at = 0, destroyed_until = 60 * MIN }, 60 * MIN, 1)
check("after the hour below 90%: not back", not st.present and not st.available)
st = rules.state("sol", "accord", { pct = 95, pct_at = 0, destroyed_until = 60 * MIN, hp_frac = 0.1 }, 0, 1)
check("permanent outpost ignores destruction and damage", st.available and st.hp == 50000)

-- Platforms: a destroyed one is down for its timer; a class change starts fresh.
local rec = { pct = 130, pct_at = 0, platforms = { { class = "light", destroyed_until = 10 * MIN }, { class = "light", hp_frac = 0.25 } } }
st = rules.state(OPEN, "accord", rec, 0, 1)
check("platform 1 destroyed, platform 2 at quarter hull", not st.platforms[1].available and st.platforms[2].hp == 1875)
rec.pct = 230
st = rules.state(OPEN, "accord", rec, 0, 1)
check("upgraded to medium: slot 2 starts fresh", st.platforms[2].class == "medium" and st.platforms[2].hp == 10000)

-- Hull scale: linear in share difference, +-36 % at the extremes.
check("even: 1", rules.hull_scale("accord", { accord = 10, swarm = 10 }) == 1)
check("all held by accord: accord 0.64", near(rules.hull_scale("accord", { accord = 10, swarm = 0 }), 0.64))
check("underdog swarm: 1.36", near(rules.hull_scale("swarm", { accord = 10, swarm = 0 }), 1.36))

-- Positions: 4 platforms around the outpost on the ring, beacon toward the centre.
local pos = { x = -4000, y = 0, z = -4000 }
local ring = outposts.stat("platform_ring_m")
for slot = 1, 4 do
	local q = rules.platform_position(pos, slot)
	check("platform " .. slot .. " on the ring", near(math.sqrt((q.x - pos.x) ^ 2 + (q.z - pos.z) ^ 2), ring))
end
local b = rules.beacon_position(pos)
check("beacon toward the centre", math.abs(b.x) < math.abs(pos.x) and near(math.sqrt((b.x - pos.x) ^ 2 + (b.z - pos.z) ^ 2), outposts.stat("beacon_offset_m")))

-- Spine cylinder: centred on the spine, not the object's origin.
local sp = rules.spine({ x = -4000, y = 0, z = -4000 }, "swarm")
check("swarm spine centre offset", sp.centre.x == -4000 and sp.centre.y == 142.5 and sp.centre.z == -4000 + 366.5)
check("a point beside the spine is 20 m from its surface", near(rules.spine_distance(sp, { x = sp.centre.x + 100, y = sp.centre.y, z = sp.centre.z }), 20))
check("a point inside is at 0", rules.spine_distance(sp, sp.centre) == 0)
local t = rules.spine_ray(sp, { x = sp.centre.x - 1000, y = sp.centre.y, z = sp.centre.z }, { x = 1, y = 0, z = 0 })
check("a ray at the side hits the wall at 920 m", t and near(t, 920))
t = rules.spine_ray(sp, { x = sp.centre.x, y = sp.centre.y, z = sp.centre.z - 2000 }, { x = 0, y = 0, z = 1 })
check("a ray down the axis hits the end cap at 1620 m", t and near(t, 1620))
check("a ray that passes above misses", rules.spine_ray(sp, { x = sp.centre.x - 1000, y = sp.centre.y + 200, z = sp.centre.z }, { x = 1, y = 0, z = 0 }) == nil)
check("a ray pointing away misses", rules.spine_ray(sp, { x = sp.centre.x - 1000, y = sp.centre.y, z = sp.centre.z }, { x = -1, y = 0, z = 0 }) == nil)

-- Nearest outpost.
local only = { sol = true, polaris = true }
check("here when available", rules.nearest_available("sol", "accord", function(id) return id == "sol" end) == "sol")
local n = rules.nearest_available("wolf_359", "accord", function(id) return only[id] end)
check("nearest of sol/polaris from wolf_359 is sol", n == "sol")
check("home as a last resort", rules.nearest_available("deneb", "swarm", function() return false end) == "polaris")

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All outpost rule assertions passed.")
