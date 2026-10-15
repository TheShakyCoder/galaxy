-- Checks main/drone_rules.lua, the procedural drone population (plan.md
-- §2.18): deterministic per system and salt, counts and tiers from threat,
-- types gated by threat, groups of 2-5, anchors clear of outposts, the
-- out-of-range threat clamped. From the Galaxy root:
--   luajit tests/drone_rules_harness.lua
package.path = "./?.lua;" .. package.path
local rules = require("main.drone_rules")
local drones = require("main.data.drones")
local star_systems = require("main.data.star_systems")

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end

check("threat 0 (canopus): no drones", #rules.population("canopus", "s") == 0)
check("epsilon_indi's 255 clamps to 50 -> 34 drones", rules.threat("epsilon_indi") == 50 and #rules.population("epsilon_indi", "s") == 34)
check("threat 1: scouts only", #rules.types_for_threat(1) == 1)
check("threat 30: all four types", #rules.types_for_threat(30) == 4)

local a, b, c = rules.population("deneb", "s"), rules.population("deneb", "s"), rules.population("deneb", "other server")
local same = #a == #b
for i = 1, #a do same = same and a[i].type == b[i].type and a[i].anchor.x == b[i].anchor.x end
check("same system and salt: identical population", same)
local differs = false
for i = 1, math.min(#a, #c) do differs = differs or a[i].type ~= c[i].type or a[i].anchor.x ~= c[i].anchor.x end
check("another server's salt: a different population", differs)

for id, sys in pairs(star_systems.SYSTEMS) do
	local threat = rules.threat(id)
	local list = rules.population(id, "s")
	local ok = #list == rules.count_for_threat(threat)
	local tier = threat > 0 and drones.tier_for_threat(threat).id
	local groups = {}
	for _, d in ipairs(list) do
		ok = ok and d.tier == tier and threat >= drones.TYPES[d.type].min_threat
			and d.hull_points == drones.TYPES[d.type].by_tier[tier].hull_points
		groups[d.group] = (groups[d.group] or 0) + 1
		for _, f in ipairs({ "accord", "swarm" }) do
			local p = star_systems.outpost_position(id, f)
			if p and not (d.anchor.x == 0 and d.anchor.z == 0) then
				ok = ok and (p.x - d.anchor.x) ^ 2 + (p.z - d.anchor.z) ^ 2 >= drones.POPULATION.outpost_clearance_m ^ 2
			end
		end
	end
	for _, n in pairs(groups) do ok = ok and n >= 1 and n <= drones.POPULATION.group_max end
	if not ok then check(id .. " population follows the rules", false) end
end
check("every system's population follows the rules", failures == 0)

check("display name", drones.display_name("hunter", "weathered") == "Weathered Hunter drone")
check("tier bands: 12 decayed, 13 weathered, 50 alert",
	drones.tier_for_threat(12).id == "decayed" and drones.tier_for_threat(13).id == "weathered" and drones.tier_for_threat(50).id == "alert")

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All drone rule assertions passed.")
