-- The ship roster - individual named ships within each class (plan.md §2.1).
-- Distinct from ship_classes.lua (the class-level baseline stats every
-- ship inherits, §2.1.1).
--
-- Per-faction differences are deliberately narrow: only `name`, `model`,
-- and `weapon_gui` vary between The Accord's and The Swarm's version of a
-- given ship - every stat/characteristic is shared. That's stored as one
-- entry with a small `faction_skins` override table, NOT two separate
-- per-faction listings - duplicating a full ship entry per faction is
-- exactly the pattern that caused real stat-drift bugs in the other local
-- reference project (`~/Defold/SuperShips/main/config.lua`'s header
-- comments on the old Viper Mk II/Raider and Raven/Malefactor "mirror
-- mismatches"), which is why that project unified onto one shared roster
-- too. Robots (§1, computer-managed only, never player-selectable) don't
-- need a `faction_skins` entry on player-facing ships like this one.
--
-- A future ship that needs to actually deviate from its class's baseline
-- stats (ship_classes.lua) would add override fields directly on its own
-- entry here, rather than duplicating the whole stat block.

local M = {}

M.SHIPS = {
	["patrol_interceptor"] = {
		class = "Patrol",
		-- Not for sale: every new pilot starts with it (BSGO: Viper Mark II /
		-- Cylon Raider, starter ships).
		price = nil,
		-- Full stat block (plan.md §2.1.1's Hull/Engine/FTL/Computer Systems
		-- baseline), populated directly on this ship rather than left as pure
		-- inheritance. Three deliberate overrides vs. the class baseline: `hull_points`
		-- (600 vs. 650), `ftl_range_ly` (4.5 vs. 5.5 LY), and
		-- `ftl_cost_hydrogen_per_ly` (20 vs. 30 Hydrogen/LY) - every other field
		-- below currently matches the baseline as-is, pending real per-ship tuning.
		data = {
			-- Hull Systems
			hull_points = 600,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 4.5, -- override vs. class baseline's 5.5 LY, per direct instruction
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 20, -- override vs. class baseline's 30, per direct instruction - Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- Component slot counts (decided): started from the reference
		-- project's own Viper Mk II STANDARD tier -
		-- ~/Defold/SuperShips/main/config.lua's M.SHIPS["Viper Mk II"]
		-- `components = { W = 3, C = 2, E = 3, H = 1 }` - plain integers,
		-- a balancing fact not creative expression, same footing as the
		-- Hull/Engine/FTL/Computer stat block above (§0/§2.1.1). Per
		-- direct instruction, `H` bumped from 1 to 2 - Patrol Interceptor now
		-- deviates from that reference baseline rather than matching it
		-- exactly (H is the one field no longer identical to Viper Mk II
		-- standard tier). Applied to Patrol Interceptor as a whole (a ship-level
		-- stat, shared by both faction skins) rather than Accord-only,
		-- consistent with "only name/model/weapon_gui differ per
		-- faction" (§2.1.2) - flag if Sardine specifically (Accord-only)
		-- was actually intended instead, which would need a small
		-- architecture change (slot counts currently live at the ship
		-- level, not per faction_skins entry).
		components = { W = 3, C = 2, E = 4, H = 2 },
		advanced   = { W = 4, C = 2, E = 5, H = 2 },
		-- Slot positions for the outpost screen's top-down ship visual
		-- (plan.md §2.8/§2.9) - {x, y} offsets in screen-pixel units from
		-- the ship visual panel's own center, same idea as the reference
		-- project's own M.CHASSIS[x].slot_positions
		-- (~/Defold/SuperShips/main/config.lua). One entry per slot in
		-- `components` above (3 Weapon + 2 Computer + 3 Engine + 2 Hull =
		-- 10 total). STILL PLACEHOLDER (not real ship-layout design) -
		-- spread across bow/midships/cabin/stern so they at least sit on
		-- the actual hull rather than floating at random; waiting on real
		-- coordinates (plan.md §4). Derived from the hull's own real
		-- geometry: the outpost screen renders the ship visual at
		-- ~49.17 px/meter (see assets/models/patrol_interceptor/ -
		-- "build_patrol_interceptor_model.py" if this ever needs regenerating), so a
		-- point at ship-space (x, z) meters maps to a screen offset of
		-- roughly (x * 49.17, z * 49.17).
		--
		-- `angle_deg` (weapon slots only, plan.md §2.8's new firing-arc
		-- provision): the bearing this mount's firing arc is centered on,
		-- in degrees from the ship's own bow/forward axis - 0 = dead ahead,
		-- positive rotates clockwise toward starboard (+x), matching this
		-- table's own "+y = forward" sense (E1/E3's stern sit at negative
		-- y). Same "STILL PLACEHOLDER, structure not real design" caveat as
		-- the {x, y} coordinates themselves - no targeting/firing code reads
		-- this yet (plan.md §4).
		slot_positions = {
			W1 = { x = 0, y = 250, angle_deg = 0 },     -- bow-mounted gun, fires dead ahead
			W2 = { x = -90, y = 100, angle_deg = -15 }, -- port midships gun, forward of the cabin, angled slightly to port
			W3 = { x = 90, y = 100, angle_deg = 15 },   -- starboard midships gun, forward of the cabin, angled slightly to starboard
			W4 = { x = 0, y = 150, angle_deg = 0 },     -- centerline, forward-facing
			-- C1/C2 (repositioned per direct instruction - manually adjusted
			-- in the editor, not by a script): side-by-side across the cabin
			-- at the same y, rather than stacked fore/aft at the same x.
			C1 = { x = -50, y = -90 },   -- computer, por	t side of the cabin
			C2 = { x = 50, y = -90 },     -- computer, centerline of the cabin
			-- H1/H2 (repositioned per direct instruction, same manual
			-- adjustment as C1/C2 above): H1 stays amidships but moved to
			-- the port side; H2 moved from stacked-below-H1 to its own
			-- centerline spot just aft of amidships.
			H1 = { x = -50, y = 0 },    -- hull/armor, port side amidships
			H2 = { x = 50, y = 0 },     -- hull/armor, centerline, just aft of amidships
			-- Per direct instruction: all three engines moved down (further
			-- stern-ward, more negative y) by ~50px; E2 specifically (the
			-- bottom-middle slot - centerline, lowest y of all 9 slots) then
			-- moved back up by 100px on top of that, netting +50 vs. its
			-- original position. E1/E3 now sit at y=-310, just past the
			-- hull's own ~-295 stern extent (see the geometry note above) -
			-- flag if that reads as hanging off the back of the hull once
			-- seen against the real ship_visual image; still well within the
			-- ship_visual panel's own bounds (+-320) either way.
			E1 = { x = -70, y = -340 },  
			E2 = { x = -70, y = -250 },   
			E3 = { x = 70, y = -340 },  
			E4 = { x = 70, y = -250 },   
			E5 = { x = 0, y = -180 },
		},
		flight_camera = { distance = 28.151, height = 3.292 },
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Sardine: Preserved approved model: silver flanks, round eyes, equal forked tail.
			accord = { name = "Sardine", model = "/assets/models/patrol_interceptor/patrol_interceptor.model", weapon_gui = "<TBD>" },
			-- Hummingbird: Needle bill, swept narrow wings and ruby throat.
			swarm = { name = "Hummingbird", model = "/assets/models/patrol_interceptor/hummingbird.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_support"] = {
		class = "Patrol",
		-- Purchase price from bsgo.fandom.com (Raptor / Cylon Heavy Raider), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 75000, currency = "hydrogen" },
		flight_camera = { distance = 27.504, height = 3.212 },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Support.
		role = "Support",
		-- Full stat block: the unmodified universal baseline (§2.1.1) - NOT
		-- Patrol Interceptor's own hull_points=600 override (ship-specific, not
		-- Patrol-tier-wide, per §2.1.1's shared-baseline note elsewhere in this
		-- file).
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- No confirmed slot-count number exists yet for this ship, so left
		-- empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Pilotfish: Five dark body bands, streamlined body and service cradles.
			accord = { name = "Pilotfish", model = "/assets/models/patrol_support/pilotfish.model", weapon_gui = "<TBD>" },
			-- Oxpecker: Compact rounded wings, ochre body and red bill.
			swarm = { name = "Oxpecker", model = "/assets/models/patrol_support/oxpecker.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_assault"] = {
		class = "Patrol",
		-- Purchase price from bsgo.fandom.com (Rhino / Marauder), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 36000, currency = "tope" },
		flight_camera = { distance = 26.725, height = 3.211 },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Assault.
		role = "Assault",
		-- Full stat block: the unmodified universal baseline (§2.1.1) - NOT
		-- Patrol Interceptor's own hull_points=600 override, since that override
		-- was specific to that one ship, not a Patrol-tier-wide change (§2.1.1
		-- establishes 650 as the shared starting point for all four classes).
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- No confirmed slot-count number exists yet for this ship, so left
		-- empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Piranha: Deep compressed body, blunt jaw, copper belly and armored bite.
			accord = { name = "Piranha", model = "/assets/models/patrol_assault/piranha.model", weapon_gui = "<TBD>" },
			-- Shrike: Black eye mask, hooked beak and long narrow tail.
			swarm = { name = "Shrike", model = "/assets/models/patrol_assault/shrike.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_tactical"] = {
		class = "Patrol",
		-- Purchase price from bsgo.fandom.com (Viper Mark VII / Cylon War Raider), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 45000, currency = "tope" },
		flight_camera = { distance = 26.534, height = 3.137 },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Tactical.
		role = "Tactical",
		-- Full stat block: the unmodified universal baseline (§2.1.1) - NOT
		-- Patrol Interceptor's own hull_points=600 override (ship-specific, not
		-- Patrol-tier-wide).
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- No confirmed slot-count number exists yet for this ship, so left
		-- empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Anglerfish: Round head, broad mouth and a luminous-tipped forward sensor lure.
			accord = { name = "Anglerfish", model = "/assets/models/patrol_tactical/anglerfish.model", weapon_gui = "<TBD>" },
			-- Kingfisher: Long spear bill, compact wings and swept blue crest.
			swarm = { name = "Kingfisher", model = "/assets/models/patrol_tactical/kingfisher.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_interceptor"] = {
		class = "Escort",
		-- Purchase price from bsgo.fandom.com (Scythe / Banshee), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 600000, currency = "hydrogen" },
		-- Full stat block (plan.md §2.1.1's Hull/Engine/FTL/Computer Systems
		-- baseline) - the UNMODIFIED universal baseline, no overrides (unlike
		-- Patrol Interceptor's hull_points), since none have been specified for this
		-- ship yet. §2.1.1 already establishes that all four classes share
		-- this same starting point, so this is a legitimate, non-invented
		-- value set, not a placeholder guess - just pending real per-ship
		-- tuning like Patrol Interceptor's was before its hull_points override.
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- Component slot counts and their screen positions are NOT set yet -
		-- unlike Patrol Interceptor, no source number (Viper Mk II tier or otherwise)
		-- has been given for Escort, and plan.md's own rule is "don't invent
		-- unconfirmed numbers" (§0/§4). Deliberately left empty rather than
		-- guessed: the outpost screen already handles a ship with zero
		-- slot_positions correctly (0 markers shown, not a crash - proven by
		-- outpost_harness2.lua's injected "escort_test" ship). Flagged in
		-- plan.md §4 pending real Escort-tier fitting design.
		components = {},
		slot_positions = {},
		flight_camera = { distance = 102.074, height = 13.338 },
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Barracuda: Long narrow body, projecting lower jaw and two separate dorsal fins.
			accord = { name = "Barracuda", model = "/assets/models/escort_interceptor/barracuda.model", weapon_gui = "<TBD>" },
			-- Falcon: Pointed swept wings, short hooked beak and cheek mask.
			swarm = { name = "Falcon", model = "/assets/models/escort_interceptor/falcon.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_support"] = {
		class = "Escort",
		-- Purchase price from bsgo.fandom.com (Glaive / Spectre), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 60000, currency = "tope" },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Support.
		role = "Support",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- Escort Interceptor - no Escort-specific tuning has been decided for
		-- this ship yet.
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- Same as the other Escort/Frigate-tier ships: no confirmed slot-count
		-- number exists yet, so left empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		flight_camera = { distance = 95.681, height = 12.650 },
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Remora: Flattened head and long ribbed dorsal docking disc.
			accord = { name = "Remora", model = "/assets/models/escort_support/remora.model", weapon_gui = "<TBD>" },
			-- Egret: White feather armor, slender S-neck and long straight bill.
			swarm = { name = "Egret", model = "/assets/models/escort_support/egret.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_tactical"] = {
		class = "Escort",
		-- Purchase price from bsgo.fandom.com (Halberd / Liche), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 75000, currency = "tope" },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Tactical.
		role = "Tactical",
		-- Full stat block sourced from https://bsgo.fandom.com/wiki/Liche (per
		-- direct instruction: "apply the stats from the liche to the Osprey") -
		-- Liche is the wiki's own Cylon-faction Escort-class counterpart this
		-- chassis' Swarm skin (Osprey) already visually reinterprets (this
		-- ship's model was tools/build_osprey_model.py's own original design,
		-- not sourced - only these NUMBERS come from the wiki page). Stats are
		-- per-CHASSIS, not per-faction-skin (§2.1.2's own "only name/model/
		-- weapon_gui differ per faction, every stat is identical" data model -
		-- there is no separate Lionfish stat block to leave at the baseline),
		-- so this replaces the shared universal-baseline block below for BOTH
		-- Lionfish and Osprey, not Osprey alone. `repair_cost_iron` is left at
		-- its existing baseline value - the wiki page's own stats don't include
		-- a repair cost, only a 75,000-cubit PURCHASE price (not a Tope
		-- conversion this project has decided yet, so not applied either -
		-- §0/§4, don't invent unconfirmed numbers). Equipment Slots (Liche:
		-- Weapon 6/Hull 3/Engine 3/Computer 3) also NOT applied here - that's
		-- component/slot-position data, not this stat block, and this chassis
		-- has no slot_positions layout to pair real counts with yet (still
		-- empty below); flag if that should be filled in too.
		data = {
			-- Hull Systems
			hull_points = 1950,
			hull_recovery_per_sec = 15,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6) - NOT from the Liche page, see this entry's own header comment
			armor = 25,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 260,
			turning_speed_deg_per_sec = 25,
			turning_acceleration_deg_per_sec2 = 25,
			inertial_compensation_m_per_sec = 50,
			acceleration_m_per_sec2 = 5,
			speed_m_per_sec = 40,
			boost_speed_m_per_sec = 60,
			boost_cost_hydrogen_per_sec = 2.7, -- renamed from the wiki's own Tylium unit (§2.6)

			-- FTL Systems
			ftl_range_ly = 7.5,
			ftl_charge_sec = 20,
			ftl_cost_hydrogen_per_ly = 80, -- renamed from the wiki's own Tylium unit (§2.6)

			-- Computer Systems
			power = 300,
			power_recharge_per_sec = 10,
			firewall_rating = 150,
			emitter_rating = 150,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0) - unchanged, the wiki's own value matches the baseline exactly
			visual_range_m = 300,
		},
		-- No confirmed slot-count number exists yet for this ship, so left
		-- empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		flight_camera = { distance = 108.507, height = 13.124 },
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Lionfish: Striped body, radiating sensor spines and large fan-shaped pectorals.
			accord = { name = "Lionfish", model = "/assets/models/escort_tactical/lionfish.model", weapon_gui = "<TBD>" },
			-- Osprey: Bent M-shaped wings, pale head and dark eye stripe.
			swarm = { name = "Osprey", model = "/assets/models/escort_tactical/osprey.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_assault"] = {
		class = "Escort",
		-- Purchase price from bsgo.fandom.com (Maul / Wraith), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 600000, currency = "hydrogen" },
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Assault.
		role = "Assault",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- every other Escort/Frigate-tier ship so far - no Escort-specific
		-- tuning has been decided for this ship yet.
		data = {
			-- Hull Systems
			hull_points = 650,
			hull_recovery_per_sec = 5,
			repair_cost_iron = 10000, -- full-repair cost, paid in Iron (§2.6)
			armor = 5,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 500,
			turning_speed_deg_per_sec = 47.5,
			turning_acceleration_deg_per_sec2 = 47.5,
			inertial_compensation_m_per_sec = 100,
			acceleration_m_per_sec2 = 10,
			speed_m_per_sec = 52.5,
			boost_speed_m_per_sec = 77.5,
			boost_cost_hydrogen_per_sec = 0.6, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 5.5,
			ftl_charge_sec = 15,
			ftl_cost_hydrogen_per_ly = 30, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 175,
			power_recharge_per_sec = 6,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 500,
		},
		-- Same as the other Escort/Frigate-tier ships: no confirmed slot-count
		-- number exists yet, so left empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		flight_camera = { distance = 82.545, height = 12.938 },
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Moray: Straight symmetrical eel body, centered dorsal ribbon and heavy jaw.
			accord = { name = "Moray", model = "/assets/models/escort_assault/moray.model", weapon_gui = "<TBD>" },
			-- Goshawk: Broad rounded wings, long barred tail and pale eyebrow.
			swarm = { name = "Goshawk", model = "/assets/models/escort_assault/goshawk.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_support"] = {
		class = "Frigate",
		-- Purchase price from bsgo.fandom.com (Vanir / Hel), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 2000000, currency = "hydrogen" },
		flight_camera = { distance = 353.428, height = 55.768 },
		-- `role` (new field, plan.md §2.1.2's Interceptor/Support/Assault/Tactical
		-- naming-matrix rows): Support. Deliberately separate from `class` above,
		-- which stays the size tier (Patrol/Escort/Frigate/Carrier) - outpost.gui_script
		-- already reads `ship.class` for display and module-compatibility filtering,
		-- so that field couldn't be repurposed to hold the role instead. Purely
		-- descriptive for now, same as `components`/`slot_positions` being left
		-- empty below - not yet wired into any gameplay logic. Patrol Interceptor/Escort Interceptor
		-- predate this dimension and are Interceptor-row per the naming matrix, but
		-- don't have a `role` field set retroactively (out of scope here).
		role = "Support",
		-- Full stat block and slot counts: the reference game's Vanir (a
		-- Command-role line ship, bsgo.fandom.com/wiki/Vanir), per direct
		-- instruction - plain numbers, a balancing fact not creative
		-- expression (§0), same footing as Patrol Interceptor's Viper Mk II
		-- slot counts. Source units renamed as elsewhere: Titanium repair
		-- cost -> Iron, Tylium fuel -> Hydrogen, Dradis -> sensor range.
		-- Not carried over: its level-20 requirement and 2,000,000 purchase
		-- price (no rank gating yet; prices come from session.lua), and its
		-- Command role bonus (no FTL-transponder module exists).
		data = {
			-- Hull Systems
			hull_points = 3500,
			hull_recovery_per_sec = 19,
			repair_cost_iron = 35000, -- full-repair cost, paid in Iron (§2.6)
			armor = 40,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 50,
			turning_speed_deg_per_sec = 9,
			turning_acceleration_deg_per_sec2 = 9,
			inertial_compensation_m_per_sec = 50,
			acceleration_m_per_sec2 = 2,
			speed_m_per_sec = 27.5,
			boost_speed_m_per_sec = 42.5,
			boost_cost_hydrogen_per_sec = 5.4, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 11,
			ftl_charge_sec = 25,
			ftl_cost_hydrogen_per_ly = 250, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 650,
			power_recharge_per_sec = 28,
			firewall_rating = 200,
			emitter_rating = 200,
			sensor_range_m = 4000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 1000,
		},
		-- Vanir slot counts (see the stat block's comment above);
		-- Fitting screen positions below.
		components = { W = 6, C = 4, E = 2, H = 2 },
		-- Laid out over both faction silhouettes (main/images/topdown/,
		-- 440 x 640 px, centre origin, +y = bow, +x = starboard): rows of
		-- up to 4 from bow to stern - Weapons, Hull, Computers, Engines -
		-- symmetric, with an odd count's extra slot on the centreline.
		-- Weapon arcs angle outward with distance from the centreline.
		slot_positions = {
			W1 = { x = -135, y = 200, angle_deg = -30 },
			W2 = { x = -45, y = 200, angle_deg = -10 },
			W3 = { x = 45, y = 200, angle_deg = 10 },
			W4 = { x = 135, y = 200, angle_deg = 30 },
			W5 = { x = -45, y = 100, angle_deg = -10 },
			W6 = { x = 45, y = 100, angle_deg = 10 },
			H1 = { x = -45, y = 0 },
			H2 = { x = 45, y = 0 },
			C1 = { x = -135, y = -100 },
			C2 = { x = -45, y = -100 },
			C3 = { x = 45, y = -100 },
			C4 = { x = 135, y = -100 },
			E1 = { x = -45, y = -200 },
			E2 = { x = 45, y = -200 },
		},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Manta Ray: Broad swept ray disc, paired cephalic lobes and slender trailing tail.
			accord = { name = "Manta Ray", model = "/assets/models/frigate_support/manta_ray.model", weapon_gui = "<TBD>" },
			-- Pelican: Broad wings, long bill and large armored throat pouch.
			swarm = { name = "Pelican", model = "/assets/models/frigate_support/pelican.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_interceptor"] = {
		class = "Frigate",
		-- Purchase price from bsgo.fandom.com (Fenrir / Aesir), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 135000, currency = "tope" },
		flight_camera = { distance = 403.553, height = 49.803 },
		-- `role` (see `frigate_support` above for the field's own rationale): Interceptor.
		role = "Interceptor",
		-- Full stat block and slot counts: the reference game's Fenrir (an
		-- Interceptor-role line ship, bsgo.fandom.com/wiki/Fenrir), per direct
		-- instruction - same sourcing and unit renames as `frigate_support`'s
		-- Vanir numbers above (§0). Not carried over, for the same reasons:
		-- its level-20 requirement and 135,000-cubit purchase price.
		data = {
			-- Hull Systems
			hull_points = 4290,
			hull_recovery_per_sec = 33,
			repair_cost_iron = 66000, -- full-repair cost, paid in Iron (§2.6)
			armor = 40,
			critical_defense = 80,

			-- Engine Systems
			avoidance = 70,
			turning_speed_deg_per_sec = 10,
			turning_acceleration_deg_per_sec2 = 10,
			inertial_compensation_m_per_sec = 50,
			acceleration_m_per_sec2 = 2.5,
			speed_m_per_sec = 30,
			boost_speed_m_per_sec = 45,
			boost_cost_hydrogen_per_sec = 4.5, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 9,
			ftl_charge_sec = 25,
			ftl_cost_hydrogen_per_ly = 250, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 750,
			power_recharge_per_sec = 25,
			firewall_rating = 100,
			emitter_rating = 100,
			sensor_range_m = 3000, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 300,
		},
		-- Fenrir slot counts (see the stat block's comment above);
		-- Fitting screen positions below.
		components = { W = 8, C = 2, E = 5, H = 2 },
		-- Laid out over both faction silhouettes (main/images/topdown/,
		-- 440 x 640 px, centre origin, +y = bow, +x = starboard): rows of
		-- up to 4 from bow to stern - Weapons, Hull, Computers, Engines -
		-- symmetric, with an odd count's extra slot on the centreline.
		-- Weapon arcs angle outward with distance from the centreline.
		slot_positions = {
			W1 = { x = -135, y = 250, angle_deg = -30 },
			W2 = { x = -45, y = 250, angle_deg = -10 },
			W3 = { x = 45, y = 250, angle_deg = 10 },
			W4 = { x = 135, y = 250, angle_deg = 30 },
			W5 = { x = -135, y = 150, angle_deg = -30 },
			W6 = { x = -45, y = 150, angle_deg = -10 },
			W7 = { x = 45, y = 150, angle_deg = 10 },
			W8 = { x = 135, y = 150, angle_deg = 30 },
			H1 = { x = -45, y = 50 },
			H2 = { x = 45, y = 50 },
			C1 = { x = -45, y = -50 },
			C2 = { x = 45, y = -50 },
			E1 = { x = -135, y = -150 },
			E2 = { x = -45, y = -150 },
			E3 = { x = 45, y = -150 },
			E4 = { x = 135, y = -150 },
			E5 = { x = 0, y = -250 },
		},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Marlin: Long spear bill, slender fast hull and crescent caudal fin.
			accord = { name = "Marlin", model = "/assets/models/frigate_interceptor/marlin.model", weapon_gui = "<TBD>" },
			-- Frigatebird: Very long angular wings, forked tail and red throat module.
			swarm = { name = "Frigatebird", model = "/assets/models/frigate_interceptor/frigatebird.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_tactical"] = {
		class = "Frigate",
		-- Purchase price from bsgo.fandom.com (Gungnir / Nidhogg), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 250000, currency = "tope" },
		flight_camera = { distance = 416.144, height = 54.873 },
		-- `role` (see `frigate_support` above for the field's own rationale): Tactical.
		role = "Tactical",
		-- Full stat block and slot counts: the reference game's Gungnir (a
		-- Multi-Role line ship, bsgo.fandom.com/wiki/Gungnir), per direct
		-- instruction - same sourcing and unit renames as `frigate_support`'s
		-- Vanir numbers above (§0). Not carried over, for the same reasons:
		-- its level-20 requirement and 250,000-cubit purchase price.
		data = {
			-- Hull Systems
			hull_points = 4550,
			hull_recovery_per_sec = 35,
			repair_cost_iron = 70000, -- full-repair cost, paid in Iron (§2.6)
			armor = 40,
			critical_defense = 100,

			-- Engine Systems
			avoidance = 50,
			turning_speed_deg_per_sec = 10,
			turning_acceleration_deg_per_sec2 = 10,
			inertial_compensation_m_per_sec = 50,
			acceleration_m_per_sec2 = 2,
			speed_m_per_sec = 30,
			boost_speed_m_per_sec = 45,
			boost_cost_hydrogen_per_sec = 8.1, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 10,
			ftl_charge_sec = 25,
			ftl_cost_hydrogen_per_ly = 250, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 750,
			power_recharge_per_sec = 25,
			firewall_rating = 150,
			emitter_rating = 150,
			sensor_range_m = 3500, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 350,
		},
		-- Gungnir slot counts (see the stat block's comment above);
		-- Fitting screen positions below.
		components = { W = 8, C = 3, E = 3, H = 3 },
		-- Laid out over both faction silhouettes (main/images/topdown/,
		-- 440 x 640 px, centre origin, +y = bow, +x = starboard): rows of
		-- up to 4 from bow to stern - Weapons, Hull, Computers, Engines -
		-- symmetric, with an odd count's extra slot on the centreline.
		-- Weapon arcs angle outward with distance from the centreline.
		slot_positions = {
			W1 = { x = -135, y = 200, angle_deg = -30 },
			W2 = { x = -45, y = 200, angle_deg = -10 },
			W3 = { x = 45, y = 200, angle_deg = 10 },
			W4 = { x = 135, y = 200, angle_deg = 30 },
			W5 = { x = -135, y = 100, angle_deg = -30 },
			W6 = { x = -45, y = 100, angle_deg = -10 },
			W7 = { x = 45, y = 100, angle_deg = 10 },
			W8 = { x = 135, y = 100, angle_deg = 30 },
			H1 = { x = -90, y = 0 },
			H2 = { x = 0, y = 0 },
			H3 = { x = 90, y = 0 },
			C1 = { x = -90, y = -100 },
			C2 = { x = 0, y = -100 },
			C3 = { x = 90, y = -100 },
			E1 = { x = -90, y = -200 },
			E2 = { x = 0, y = -200 },
			E3 = { x = 90, y = -200 },
		},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Hammerhead: Broad transverse hammer head with sensors at both ends.
			accord = { name = "Hammerhead", model = "/assets/models/frigate_tactical/hammerhead.model", weapon_gui = "<TBD>" },
			-- Harpy Eagle: Massive broad wings, slate chest and a split crown crest.
			swarm = { name = "Harpy Eagle", model = "/assets/models/frigate_tactical/harpy_eagle.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_assault"] = {
		class = "Frigate",
		-- Purchase price from bsgo.fandom.com (Jotunn / Jormung), as-is: cubits -> Tope,
		-- Tylium -> Hydrogen. Same for both factions (the two are counterparts there).
		price = { amount = 2000000, currency = "hydrogen" },
		flight_camera = { distance = 385.522, height = 50.957 },
		-- `role` (see `frigate_support` above for the field's own rationale): Assault.
		role = "Assault",
		-- Full stat block and slot counts: the reference game's Jotunn (an
		-- Assault-role line ship, bsgo.fandom.com/wiki/Jotunn), per direct
		-- instruction - same sourcing and unit renames as `frigate_support`'s
		-- Vanir numbers above (§0). Not carried over, for the same reasons:
		-- its level-20 requirement and 2,000,000 purchase price.
		data = {
			-- Hull Systems
			hull_points = 4500,
			hull_recovery_per_sec = 20.6,
			repair_cost_iron = 37000, -- full-repair cost, paid in Iron (§2.6)
			armor = 45,
			critical_defense = 120,

			-- Engine Systems
			avoidance = 30,
			turning_speed_deg_per_sec = 8,
			turning_acceleration_deg_per_sec2 = 8,
			inertial_compensation_m_per_sec = 50,
			acceleration_m_per_sec2 = 1.5,
			speed_m_per_sec = 25,
			boost_speed_m_per_sec = 40,
			boost_cost_hydrogen_per_sec = 6.3, -- Hydrogen fuel (§2.6)

			-- FTL Systems
			ftl_range_ly = 10,
			ftl_charge_sec = 25,
			ftl_cost_hydrogen_per_ly = 250, -- Hydrogen fuel (§2.6)

			-- Computer Systems
			power = 500,
			power_recharge_per_sec = 25,
			firewall_rating = 150,
			emitter_rating = 150,
			sensor_range_m = 3500, -- renamed from source's "Dradis Range" (§0)
			visual_range_m = 350,
		},
		-- Jotunn slot counts (see the stat block's comment above);
		-- Fitting screen positions below.
		components = { W = 6, C = 2, E = 2, H = 4 },
		-- Laid out over both faction silhouettes (main/images/topdown/,
		-- 440 x 640 px, centre origin, +y = bow, +x = starboard): rows of
		-- up to 4 from bow to stern - Weapons, Hull, Computers, Engines -
		-- symmetric, with an odd count's extra slot on the centreline.
		-- Weapon arcs angle outward with distance from the centreline.
		slot_positions = {
			W1 = { x = -135, y = 200, angle_deg = -30 },
			W2 = { x = -45, y = 200, angle_deg = -10 },
			W3 = { x = 45, y = 200, angle_deg = 10 },
			W4 = { x = 135, y = 200, angle_deg = 30 },
			W5 = { x = -45, y = 100, angle_deg = -10 },
			W6 = { x = 45, y = 100, angle_deg = 10 },
			H1 = { x = -135, y = 0 },
			H2 = { x = -45, y = 0 },
			H3 = { x = 45, y = 0 },
			H4 = { x = 135, y = 0 },
			C1 = { x = -45, y = -100 },
			C2 = { x = 45, y = -100 },
			E1 = { x = -45, y = -200 },
			E2 = { x = 45, y = -200 },
		},
		faction_skins = {
			-- Original species hulls; tools/build_fleet_models.py. Sardine retains its approved asset.
			-- One mesh/texture each; meters, +Z forward. Hardware conveys role, not slot counts.
			-- Tiger Shark: Heavy blunt shark head, dark flank bars and asymmetric caudal lobes.
			accord = { name = "Tiger Shark", model = "/assets/models/frigate_assault/tiger_shark.model", weapon_gui = "<TBD>" },
			-- Golden Eagle: Broad fingered wings and golden neck/shoulder armor.
			swarm = { name = "Golden Eagle", model = "/assets/models/frigate_assault/golden_eagle.model", weapon_gui = "<TBD>" },
		},
	},
}

return M
