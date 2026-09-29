-- Weapon (Auto Cannon) module entries (plan.md §2.8). Two concrete entries
-- now exist: the basic Ordinance-type cannon and the Mining Cannon every
-- new character is gifted one of each of, along with the Patrol 1 ship
-- (§2.1.2), per direct instruction. Combat stats come from the BSGO wiki
-- (see "Combat stats" below); §2.8's wear_per_use isn't specified, so it's
-- omitted rather than guessed, per §0/§4's "don't invent unconfirmed
-- numbers" rule.
--
-- Naming convention (decided): combat (Ordinance-type) auto cannons are
-- named after INSECTS, sized to match the ship class they're built for —
-- same "real-world animal sized to the ship class" pattern as the ship
-- roster's fish (Accord)/bird (Swarm) names (§2.1.2), just a third animal
-- family reserved for this one weapon subtype. Scale, smallest ship class
-- to largest (only the Patrol-tier entry actually exists yet; the rest
-- are reserved for whenever an Escort/Frigate/Carrier-specific cannon is
-- added, §2.1):
--   Patrol  -> Gnat     (this file's "auto_cannon_basic")
--   Escort  -> Hornet
--   Frigate -> Locust
--   Carrier -> Beetle
--
-- Mining-type cannons are NOT part of the insect scheme - they get their
-- own class-sized naming scale instead, using mining/prospecting
-- terminology (decided). Unlike the combat scale above, all four tiers
-- are now implemented (item keys below):
--   Patrol  -> Digger      ("mining_cannon_basic")
--   Escort  -> Miner       ("mining_cannon_escort")
--   Frigate -> Speculator  ("mining_cannon_frigate")
--   Carrier -> Prospector  ("mining_cannon_carrier" - the name the
--                           Patrol-tier entry used before being renamed
--                           to Digger, reused here rather than retired)
--
-- `ship_class` (decided, singular - a plain string, not a list): each
-- cannon belongs to exactly ONE ship class, not "fits anywhere" -
-- matching the naming scale above (a Gnat is a Patrol-sized weapon, not
-- a generic one that happens to be named after a small insect). NOTE:
-- this field isn't actually enforced anywhere yet (no fitting-screen or
-- install-time check reads it) - it's data awaiting that logic, not a
-- currently-active restriction (plan.md §4). This now matters more than
-- it did with just Gnat/Digger (both Patrol, so the missing check was
-- moot in practice): Miner/Speculator/Prospector are Escort/Frigate/
-- Carrier-only, but with no ships in those classes yet AND no
-- enforcement, they're currently draggable onto the Patrol ship anyway.
--
-- `arc` (plan.md §2.8's firing-arc provision): total width, in degrees, of
-- this weapon's firing cone - centered on whichever slot's own `angle_deg`
-- (main/data/ships.lua's `slot_positions`) it ends up fitted into. Per direct
-- instruction, every auto cannon below defaults to `arc = 75` for now.
-- The server checks it when applying damage (nakama-server/modules/
-- system_match.lua), measured from the ship's nose - slot angles aren't
-- applied yet.
--
-- `icon`: the region name (image filename, no extension) within
-- main/images/icons.atlas, shown on the outpost screen's ship visual slot
-- markers instead of the item's name text (plan.md §4/§2.8's
-- fitting-screen notes). Per direct instruction, every auto cannon
-- (mining or combat) now uses one of the hand-provided "Octagon Cannon
-- *" icons instead of the old tools/build_module_icons.py-generated
-- ones - "Octagon Cannon Asteroid" for any mining-type cannon, "Octagon
-- Cannon Spaceship" for the normal (ordinance) combat cannon. Miner/
-- Speculator/Prospector all placeholder-share Digger's icon for now -
-- distinct per-tier mining-cannon art hasn't been designed (plan.md §4).

local M = {}

-- Combat stats, from the BSGO wiki's Weapons page (bsgo.fandom.com/wiki/
-- Weapons, read via its API). Colonial and Cylon versions of each weapon
-- share one stat block there.
--   dps             damage per second by upgrade level (index = level + 1;
--                   levels past the end use the last value) - what the
--                   server applies while firing (nakama-server/modules/
--                   system_match.lua), as an average: no per-shot damage
--                   rolls, accuracy, criticals or armour yet
--   max_range_m     out of range = no damage
--   optimal_range_m, damage_min/damage_max, reload_s, armor_piercing,
--   power_cost      recorded from the wiki, not used yet
-- The firing arc is each entry's own `arc` (same 75 degrees as the wiki).
--
-- Gnat = MEC-A6 "Fang" / Type A "Aggressor" Light Autocannon (the strike
-- craft default): DPS 11 at level 1 rising linearly to 22 at level 10.
local LIGHT_AUTOCANNON = {
	dps = { 11, 12.22, 13.44, 14.67, 15.89, 17.11, 18.33, 19.56, 20.78, 22 },
	max_range_m = 750,
	optimal_range_m = 300,
	damage_min = 1,
	damage_max = 10,
	reload_s = 0.5,
	armor_piercing = 5,
	power_cost = 1,
}
-- Mining cannons: one per ship class, like the ships themselves - each is
-- the matching class of BSGO mining weapon (Weapons and Mining pages; "much
-- less effective in combat"). The wiki gives no per-level values for these,
-- so every level uses the one DPS figure.
-- Digger (Patrol) = "Gopher" / "Gouger" Light Mining Cannon.
local LIGHT_MINING_CANNON = {
	dps = { 5 },
	max_range_m = 600,
	optimal_range_m = 250,
	damage_min = 1,
	damage_max = 4,
	reload_s = 0.5,
	armor_piercing = 5,
	power_cost = 2,
}
-- Miner (Escort) = "Mole" / "Dredger" Medium Mining Battery.
local MEDIUM_MINING_BATTERY = {
	dps = { 5 },
	max_range_m = 900,
	damage_min = 4,
	damage_max = 10,
}
-- Speculator (Frigate) = "Badger" / "Excavator" Heavy Mining Battery.
local HEAVY_MINING_BATTERY = {
	dps = { 5.3 },
	max_range_m = 1350,
	damage_min = 14,
	damage_max = 28,
}
-- Prospector (Carrier): BSGO had no carrier-class mining weapon, so it has
-- no combat stats (deals no damage) until one is decided.

M.AUTOCANNONS = {
	["auto_cannon_basic"] = {
		name = "Gnat", -- Patrol-tier combat auto cannon, see the naming-scale comment above
		type = "weapon",
		subtype = "auto_cannon",
		cannon_type = "ordinance", -- consumes ordinance, combat-capable (§2.8)
		behavior = "toggle", -- §2.8: weapons are always toggle-type
		ship_class = "Patrol", -- see the ship_class comment above
		icon = "Octagon Cannon Spaceship", -- normal (ordinance) combat cannon, see the icon comment above
		arc = 75, -- firing-arc width in degrees, see the arc comment above
	},
	["mining_cannon_basic"] = {
		name = "Digger", -- Patrol-tier mining cannon, see the mining naming-scale comment above
		type = "weapon",
		subtype = "auto_cannon",
		cannon_type = "mining", -- no ordinance needed, mining-focused, weak vs. ships (§2.8)
		behavior = "toggle", -- §2.8: weapons are always toggle-type
		ship_class = "Patrol", -- see the ship_class comment above
		icon = "Octagon Cannon Asteroid", -- mining cannon, see the icon comment above
		arc = 75, -- firing-arc width in degrees, see the arc comment above
	},
	["mining_cannon_escort"] = {
		name = "Miner", -- Escort-tier mining cannon, see the mining naming-scale comment above
		type = "weapon",
		subtype = "auto_cannon",
		cannon_type = "mining",
		behavior = "toggle", -- §2.8: weapons are always toggle-type
		ship_class = "Escort", -- see the ship_class comment above - NOT YET enforced (plan.md §4)
		icon = "Octagon Cannon Asteroid", -- placeholder - shares Digger's icon, see the icon comment above
		arc = 75, -- firing-arc width in degrees, see the arc comment above
	},
	["mining_cannon_frigate"] = {
		name = "Speculator", -- Frigate-tier mining cannon, see the mining naming-scale comment above
		type = "weapon",
		subtype = "auto_cannon",
		cannon_type = "mining",
		behavior = "toggle", -- §2.8: weapons are always toggle-type
		ship_class = "Frigate", -- see the ship_class comment above - NOT YET enforced (plan.md §4)
		icon = "Octagon Cannon Asteroid", -- placeholder - shares Digger's icon, see the icon comment above
		arc = 75, -- firing-arc width in degrees, see the arc comment above
	},
	["mining_cannon_carrier"] = {
		name = "Prospector", -- Carrier-tier mining cannon, see the mining naming-scale comment above
		type = "weapon",
		subtype = "auto_cannon",
		cannon_type = "mining",
		behavior = "toggle", -- §2.8: weapons are always toggle-type
		ship_class = "Carrier", -- see the ship_class comment above - NOT YET enforced (plan.md §4)
		icon = "Octagon Cannon Asteroid", -- placeholder - shares Digger's icon, see the icon comment above
		arc = 75, -- firing-arc width in degrees, see the arc comment above
	},
}

-- Attach the combat stats above to each weapon (by class).
local STATS = {
	auto_cannon_basic = LIGHT_AUTOCANNON,
	mining_cannon_basic = LIGHT_MINING_CANNON,
	mining_cannon_escort = MEDIUM_MINING_BATTERY,
	mining_cannon_frigate = HEAVY_MINING_BATTERY,
}
for key, stats in pairs(STATS) do
	for field, value in pairs(stats) do
		M.AUTOCANNONS[key][field] = value
	end
end

-- Damage per second of `weapon` (a catalog entry) at upgrade `level`
-- (0 = not upgraded), or 0 for a module without combat stats.
function M.dps_at_level(weapon, level)
	local by_level = weapon and weapon.dps
	if not by_level then
		return 0
	end
	return by_level[math.min((level or 0) + 1, #by_level)]
end

return M
