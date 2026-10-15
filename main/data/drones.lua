-- NPC drones - the ships of the computer-run Robots faction (plan.md §1,
-- §2.18). Hostile to both the Accord and the Swarm. Own data file (§3.1);
-- one faction only, so no faction_skins - each type has a single look.
--
-- SOURCE: the BSGO wiki's "Drones" page (bsgo.fandom.com, read via its
-- MediaWiki API 2026-10-15). BSGO had four drone types (Seeker, Sentry,
-- Hunter, Guard) in four quality tiers (Failing, Worn, Rugged, Vigilant),
-- each a fixed level with published hull and power. Their numbers are used
-- as-is below; the NAMES are ours (plan.md §0 - no BSG names):
--   types  Seeker -> scout, Sentry -> sentry, Hunter -> hunter, Guard -> guard
--   tiers  Failing -> decayed, Worn -> weathered, Rugged -> hardened,
--          Vigilant -> alert
-- Scouts and sentries are the lighter pair (the lower level of each tier,
-- power 100), hunters and guards the heavier (power 200; hunters carry a
-- missile launcher as well as cannons in BSGO). Everything marked OURS is not
-- published and is a starting point to tune. The unique "Revenant" (level 90,
-- hull 2,950, speed 55) and the "Command Nexus" carrier are recorded in
-- plan.md §2.18 but not built yet.
--
-- Not used for combat yet: drones patrol, chase and can be shot down, but
-- don't fire back until player ships can take damage (plan.md §2.19).

local M = {}

-- Quality tiers, weakest first. A system's threat picks its tier
-- (main/drone_rules.lua): threat up to `max_threat`.
M.TIERS = {
	{ id = "decayed",   name = "Decayed",   max_threat = 12 },
	{ id = "weathered", name = "Weathered", max_threat = 25 },
	{ id = "hardened",  name = "Hardened",  max_threat = 38 },
	{ id = "alert",     name = "Alert",     max_threat = 50 },
}

-- Drone types. `min_threat`: the lowest system threat they appear at
-- (OURS, plan.md §2.18). `by_tier`: BSGO's level / hull / power per tier.
-- `speed_m_per_sec`, `radius_m` (click/marker/surface size) and the model
-- are OURS.
M.TYPES = {
	["scout"] = {
		name = "Scout drone",
		min_threat = 1,
		speed_m_per_sec = 45,
		radius_m = 10,
		by_tier = {
			decayed   = { level = 5,  hull_points = 250, power = 100 },
			weathered = { level = 10, hull_points = 375, power = 100 },
			hardened  = { level = 15, hull_points = 500, power = 100 },
			alert     = { level = 25, hull_points = 800, power = 100 },
		},
	},
	["sentry"] = {
		name = "Sentry drone",
		min_threat = 10,
		speed_m_per_sec = 25,
		radius_m = 12,
		by_tier = {
			decayed   = { level = 5,  hull_points = 300, power = 100 },
			weathered = { level = 10, hull_points = 425, power = 100 },
			hardened  = { level = 15, hull_points = 550, power = 100 },
			alert     = { level = 25, hull_points = 800, power = 100 },
		},
	},
	["guard"] = {
		name = "Guard drone",
		min_threat = 20,
		speed_m_per_sec = 30,
		radius_m = 16,
		by_tier = {
			decayed   = { level = 9,  hull_points = 600,  power = 200 },
			weathered = { level = 14, hull_points = 900,  power = 200 },
			hardened  = { level = 19, hull_points = 1200, power = 200 },
			alert     = { level = 29, hull_points = 1800, power = 200 },
		},
	},
	["hunter"] = {
		name = "Hunter drone",
		min_threat = 30,
		speed_m_per_sec = 50,
		radius_m = 14,
		by_tier = {
			-- The wiki gives 550 in one place and 500 in its table for the
			-- lowest tier; the table's 500 is used.
			decayed   = { level = 9,  hull_points = 500,  power = 200 },
			weathered = { level = 14, hull_points = 750,  power = 200 },
			hardened  = { level = 19, hull_points = 1000, power = 200 },
			alert     = { level = 29, hull_points = 1500, power = 200 },
		},
	},
}

-- Type ids in a fixed order (pairs() has none), weakest first.
M.TYPE_ORDER = { "scout", "sentry", "guard", "hunter" }

-- Population and behaviour (all OURS, plan.md §2.18).
M.POPULATION = {
	-- drones in a system = base + per_threat x threat (threat 0: none)
	base = 4,
	per_threat = 0.6,
	group_min = 2,
	group_max = 5,
	-- system threat is clamped to this (one system's data says 255 - plan §4)
	max_threat = 50,
	-- share of groups anchored at an asteroid (the rest at random points)
	asteroid_anchor_share = 0.6,
	-- anchors keep at least this far from either outpost
	outpost_clearance_m = 2500,
}

M.BEHAVIOUR = {
	patrol_radius_m = 500,   -- wander this far around the group's anchor
	aggro_range_m = 1200,    -- notice a player this close (BSGO platforms' figure)
	leash_m = 3000,          -- give up a chase this far from the anchor
	standoff_m = 400,        -- close to this distance from the player chased
	respawn_sec = 5 * 60,    -- a destroyed drone returns at its anchor
}

-- Rewards (OURS): XP per drone level for each pilot who damaged it in the
-- last `attacker_window_sec`, paid in full to each (like outpost kills).
-- Killing one also raises the killer's faction's Outpost Progress there by
-- main/data/outposts.lua PROGRESS.gain_pct.npc_kill.
M.REWARDS = {
	xp_per_level = 10,
	attacker_window_sec = 120,
}

-- Placeholder models, one per type (tools/build_drone_models.py).
M.MODELS = {
	scout = "/assets/models/drones/scout.model",
	sentry = "/assets/models/drones/sentry.model",
	guard = "/assets/models/drones/guard.model",
	hunter = "/assets/models/drones/hunter.model",
}

function M.tier_for_threat(threat)
	threat = math.min(threat or 0, M.POPULATION.max_threat)
	for _, tier in ipairs(M.TIERS) do
		if threat <= tier.max_threat then
			return tier
		end
	end
	return M.TIERS[#M.TIERS]
end

function M.tier_name(tier_id)
	for _, tier in ipairs(M.TIERS) do
		if tier.id == tier_id then
			return tier.name
		end
	end
	return "?"
end

-- "Weathered Hunter drone"
function M.display_name(type_id, tier_id)
	local t = M.TYPES[type_id]
	return M.tier_name(tier_id) .. " " .. (t and t.name or "drone")
end

return M
