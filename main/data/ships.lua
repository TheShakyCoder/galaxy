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
	["patrol_1"] = {
		class = "Patrol",
		-- Full stat block (plan.md §2.1.1's Hull/Engine/FTL/Computer Systems
		-- baseline), populated directly on this ship rather than left as pure
		-- inheritance. `hull_points` is a deliberate override (600 vs. the
		-- class baseline's 650) - every other field below currently matches
		-- the baseline as-is, pending real per-ship tuning.
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
		-- Component slot counts (decided): started from the reference
		-- project's own Viper Mk II STANDARD tier -
		-- ~/Defold/SuperShips/main/config.lua's M.SHIPS["Viper Mk II"]
		-- `components = { W = 3, C = 2, E = 3, H = 1 }` - plain integers,
		-- a balancing fact not creative expression, same footing as the
		-- Hull/Engine/FTL/Computer stat block above (§0/§2.1.1). Per
		-- direct instruction, `H` bumped from 1 to 2 - Patrol 1 now
		-- deviates from that reference baseline rather than matching it
		-- exactly (H is the one field no longer identical to Viper Mk II
		-- standard tier). Applied to Patrol 1 as a whole (a ship-level
		-- stat, shared by both faction skins) rather than Accord-only,
		-- consistent with "only name/model/weapon_gui differ per
		-- faction" (§2.1.2) - flag if Sardine specifically (Accord-only)
		-- was actually intended instead, which would need a small
		-- architecture change (slot counts currently live at the ship
		-- level, not per faction_skins entry).
		components = { W = 3, C = 2, E = 3, H = 2 },
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
		-- ~49.17 px/meter (see main/models/patrol_1/ -
		-- "build_patrol1_model.py" if this ever needs regenerating), so a
		-- point at ship-space (x, z) meters maps to a screen offset of
		-- roughly (x * 49.17, z * 49.17).
		slot_positions = {
			W1 = { x = 0, y = 250 },     -- bow-mounted gun
			W2 = { x = -70, y = 100 },   -- port midships gun, forward of the cabin
			W3 = { x = 70, y = 100 },    -- starboard midships gun, forward of the cabin
			-- C1/C2 (repositioned per direct instruction - manually adjusted
			-- in the editor, not by a script): side-by-side across the cabin
			-- at the same y, rather than stacked fore/aft at the same x.
			C1 = { x = -70, y = -70 },   -- computer, port side of the cabin
			C2 = { x = 70, y = -70 },     -- computer, centerline of the cabin
			-- H1/H2 (repositioned per direct instruction, same manual
			-- adjustment as C1/C2 above): H1 stays amidships but moved to
			-- the port side; H2 moved from stacked-below-H1 to its own
			-- centerline spot just aft of amidships.
			H1 = { x = -70, y = 20 },    -- hull/armor, port side amidships
			H2 = { x = 70, y = 20 },     -- hull/armor, centerline, just aft of amidships
			-- Per direct instruction: all three engines moved down (further
			-- stern-ward, more negative y) by ~50px; E2 specifically (the
			-- bottom-middle slot - centerline, lowest y of all 9 slots) then
			-- moved back up by 100px on top of that, netting +50 vs. its
			-- original position. E1/E3 now sit at y=-310, just past the
			-- hull's own ~-295 stern extent (see the geometry note above) -
			-- flag if that reads as hanging off the back of the hull once
			-- seen against the real ship_visual image; still well within the
			-- ship_visual panel's own bounds (+-320) either way.
			E1 = { x = -50, y = -310 },  -- port engine, stern
			E2 = { x = 0, y = -230 },    -- centerline engine, stern
			E3 = { x = 50, y = -310 },   -- starboard engine, stern
		},
		faction_skins = {
			-- Naming convention (plan.md §2.1.2): real-world animal species
			-- sized to roughly match the ship's class - fish for The Accord,
			-- birds for The Swarm. Patrol is the smallest class, so both
			-- names below are small/fast species - PROPOSED, pending
			-- confirmation, same as Scrip/Valor were.
			--
			-- `model` (decided, replacing the old `nil`-placeholder-cube
			-- state): a rudimentary ORIGINAL 3D hull, small-patrol-boat scale
			-- (12m long, 3m beam, 2.8m tall including a small cabin),
			-- hand-authored as a low-poly glTF
			-- (main/models/patrol_1/patrol_1.gltf, 22 unique vertices / 36
			-- triangles) - deliberately NOT the reference project's actual
			-- Viper Mk II/Cylon Raider meshes, which are BSG-derived vehicle
			-- designs off-limits per §0 regardless of the CC-BY license on
			-- those specific mesh files (that license covers only the
			-- modeler's own copyright in the file, not the underlying
			-- BSG-owned design). Both factions share this same placeholder
			-- hull for now - distinct faction art is still open (§4).
			accord = { name = "Sardine", model = "/main/models/patrol_1/patrol_1.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Hummingbird", model = "/main/models/patrol_1/patrol_1.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_1"] = {
		class = "Escort",
		-- Full stat block (plan.md §2.1.1's Hull/Engine/FTL/Computer Systems
		-- baseline) - the UNMODIFIED universal baseline, no overrides (unlike
		-- Patrol 1's hull_points), since none have been specified for this
		-- ship yet. §2.1.1 already establishes that all four classes share
		-- this same starting point, so this is a legitimate, non-invented
		-- value set, not a placeholder guess - just pending real per-ship
		-- tuning like Patrol 1's was before its hull_points override.
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
		-- unlike Patrol 1, no source number (Viper Mk II tier or otherwise)
		-- has been given for Escort, and plan.md's own rule is "don't invent
		-- unconfirmed numbers" (§0/§4). Deliberately left empty rather than
		-- guessed: the outpost screen already handles a ship with zero
		-- slot_positions correctly (0 markers shown, not a crash - proven by
		-- outpost_harness2.lua's injected "escort_test" ship). Flagged in
		-- plan.md §4 pending real Escort-tier fitting design.
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Naming convention (plan.md §2.1.2): real-world animal species
			-- sized to roughly match the ship's class - fish for The Accord,
			-- birds for The Swarm, one size class up from Patrol's Sardine/
			-- Hummingbird. Both PROPOSED, same confirm-or-correct pattern as
			-- those two: predatory/combat-flavored species (vs. Patrol's
			-- small/schooling-or-darting flavor) to match Escort's "first
			-- real," combat-capable role (§2.1).
			--
			-- `model`/`weapon_gui` still `<TBD>` - no 3D hull has been built
			-- for this ship yet (unlike Patrol 1's hand-authored glTF), and
			-- the outpost screen's ship visual is hardcoded to Patrol 1's own
			-- top-down image regardless of active ship (plan.md §4), so
			-- nothing reads this field yet either way.
			accord = { name = "Barracuda", model = "<TBD>", weapon_gui = "<TBD>" },
			swarm  = { name = "Falcon", model = "<TBD>", weapon_gui = "<TBD>" },
		},
	},
}

return M
