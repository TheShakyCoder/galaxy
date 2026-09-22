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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2): real-world animal species
			-- sized to roughly match the ship's class - fish for The Accord,
			-- birds for The Swarm. Patrol is the smallest class, so both
			-- names below are small/fast species - PROPOSED, pending
			-- confirmation, same as Scrip/Valor were.
			--
			-- Sardine's `model` (`patrol_interceptor.model`): REPLACED per direct
			-- instruction with an ORIGINAL hand-authored hull
			-- (tools/build_sardine_model.py, writes over
			-- assets/models/patrol_interceptor/sardine.glb, the same file path
			-- `patrol_interceptor.model` already pointed at) - the old
			-- SuperShips-sourced viper_mk2.glb (this file's own former
			-- HIGHEST-SEVERITY §0 exception, see git history) is gone. The new
			-- hull leans into the ship's own real-world namesake: a slender
			-- fusiform (torpedo-shaped) body - a small schooling fish's own
			-- classic silhouette, not a fighter-craft wedge - a forked tail
			-- (two swept lobes with a V-notch, the defining herring-family
			-- shape), a small dorsal fin, and a pair of pectoral fins near the
			-- head. Two-tone countershaded coloring (darker blue-green back over
			-- a lighter silver belly, split at the hull's own centerline) - a
			-- real sardine's actual coloring, visible now that
			-- render/custom.render_script's leftover diagnostic red tint
			-- override has been removed. Deliberately the smallest hull built so
			-- far, matching Patrol's own place as the smallest class in the
			-- roster. ~8.3-unit bounding radius.
			--
			-- The OTHER hand-authored hull this file's comments used to mention
			-- here (assets/models/patrol_interceptor/patrol_interceptor.glb,
			-- tools/build_patrol_interceptor_model.py's own output) is unrelated
			-- to Sardine's model and still sits unused on disk - a leftover from
			-- before any faction skin had its own dedicated model.
			--
			-- Hummingbird's `model` was ORIGINALLY a separate user-supplied,
			-- CC-BY-4.0-licensed Sketchfab asset (attribution: JazOone,
			-- "SpaceShip") - since REPLACED per direct instruction with
			-- ~/Defold/SuperShips's `bsgo_ships_improved/hd/raider/raider.glb`
			-- (copied over the old `assets/models/patrol_interceptor/
			-- hummingbird.glb` file path, BSGO-identifying metadata stripped on
			-- copy same as every other SuperShips-sourced model in this file).
			-- HIGHEST-SEVERITY §0 EXCEPTION IN THIS FILE: `raider` is not just
			-- "BSG-derived" like the other exceptions below - it IS, by name,
			-- the exact "Cylon Raider" this very comment block (and this
			-- project's plan.md) has repeatedly cited as the paradigm example
			-- of what §0 excludes. Its own SuperShips manifest also carries a
			-- note the other sourced models don't: `"note": "reference only;
			-- friend already has a Raider"` - a signal from the asset pack's
			-- own author that this particular file wasn't intended for general
			-- reuse, separate from the BSG-IP question. Flagged with this
			-- specific severity and used anyway per direct instruction after
			-- being shown the render and both of these points explicitly - not
			-- a silent contradiction of this comment's own stated rule.
			accord = { name = "Sardine", model = "/assets/models/patrol_interceptor/patrol_interceptor.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Hummingbird", model = "/assets/models/patrol_interceptor/hummingbird.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_support"] = {
		class = "Patrol",
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
			-- Naming convention (plan.md §2.1.2's Support row): Accord =
			-- Pilotfish, Swarm = Oxpecker - both proposed, same confirm-or-correct
			-- pattern as every other name in this file.
			--
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/heavy_raider/heavy_raider.glb`
			-- (copied to `assets/models/patrol_support/oxpecker.glb`, real binary
			-- GLB, baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Heavy Raider" ->
			-- "oxpecker_hull", "cylon_*" materials -> "oxpecker_*", extras
			-- removed).
			-- FLAGGED, same "Cylon" pattern as the others, and part of the same
			-- Raider design family as Hummingbird's own model (see
			-- `patrol_interceptor` above for that entry's own heightened-severity
			-- note) - a transport variant with forward tusks and twin shoulder
			-- drives, `"cls": "Strike"`, 10m scale. Used anyway per direct
			-- instruction after being shown the render - not a §0-compliant
			-- asset, kept here as an explicit, acknowledged exception rather
			-- than a silent one.
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/raptor/raptor.glb` (copied to
			-- `assets/models/patrol_support/pilotfish.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Raptor" ->
			-- "pilotfish_hull", "colonial_*"/"glass"/"engine_glow" materials ->
			-- "pilotfish_*", extras removed).
			-- FLAGGED, same "Colonial" pattern as the others: source asset's own
			-- manifest tags it `"faction": "Colonial"`, `"cls": "Strike"` (8.6m
			-- scale) - the well-known Colonial transport/scout ship from the
			-- source material, a fitting "support role" ship even if that's not
			-- why it was picked. Used anyway per direct instruction after being
			-- shown the render - not a §0-compliant asset, kept here as an
			-- explicit, acknowledged exception rather than a silent one.
			accord = { name = "Pilotfish", model = "/assets/models/patrol_support/pilotfish.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Oxpecker", model = "/assets/models/patrol_support/oxpecker.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_assault"] = {
		class = "Patrol",
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
			-- Naming convention (plan.md §2.1.2's Assault row): Accord = Piranha,
			-- Swarm = Shrike - both proposed, same confirm-or-correct pattern as
			-- every other name in this file.
			--
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/rhino/rhino.glb` (copied to
			-- `assets/models/patrol_assault/piranha.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Rhino" ->
			-- "piranha_hull", "colonial_olive"/"glass"/"colonial_dark"/
			-- "engine_glow" materials -> "piranha_*", extras removed).
			-- FLAGGED, same pattern as the exceptions before it: source asset's
			-- own manifest tags it `"faction": "Colonial"`, `"cls": "Strike"`
			-- (an 11m small strike-fighter, unlike the capital/escort-scale
			-- sources used so far), referenced from playbsgo.com/fleet.html,
			-- "reference-guided interpretation" of a canon Colonial strike craft
			-- (armored cockpit wedge, broad stub wings, raised rear engine
			-- cluster) - i.e. BSG-derived vehicle design, §0's excluded
			-- category. Used anyway per direct instruction after being shown the
			-- render - not a §0-compliant asset, kept here as an explicit,
			-- acknowledged exception rather than a silent one.
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/marauder/marauder.glb`
			-- (copied to `assets/models/patrol_assault/shrike.glb`, real binary
			-- GLB, baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Marauder" ->
			-- "shrike_hull", "cylon_*" materials -> "shrike_*", extras removed).
			-- FLAGGED, same "Cylon" pattern as the others, and a close visual
			-- cousin of the Cylon Raider silhouette (single curved wing/body,
			-- red light bar) even though it's a distinct named ship in the
			-- source (`"cls": "Strike"`, 12m fighter scale). Used anyway per
			-- direct instruction after being shown the render - not a
			-- §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			accord = { name = "Piranha", model = "/assets/models/patrol_assault/piranha.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Shrike", model = "/assets/models/patrol_assault/shrike.model", weapon_gui = "<TBD>" },
		},
	},
	["patrol_tactical"] = {
		class = "Patrol",
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
			-- Naming convention (plan.md §2.1.2's Tactical row): Accord =
			-- Anglerfish, Swarm = Kingfisher - both proposed, same
			-- confirm-or-correct pattern as every other name in this file.
			--
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/war_raider/war_raider.glb`
			-- (copied to `assets/models/patrol_tactical/kingfisher.glb`, real
			-- binary GLB, baseColorFactor materials only, no textures).
			-- BSGO-identifying internal metadata stripped on copy (node/mesh
			-- "War Raider" -> "kingfisher_hull", "cylon_*" materials ->
			-- "kingfisher_*", extras removed).
			-- FLAGGED, same "Cylon" pattern as the others, part of the same
			-- Raider design family as Hummingbird's model (see
			-- `patrol_interceptor` above) but a broader flying-wing shape, less
			-- identical to the classic Raider silhouette - a broad solid swept
			-- wing with a compact armored center, `"cls": "Strike"`, 9m scale.
			-- Used anyway per direct instruction after being shown the render -
			-- not a §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/viper_mk7/viper_mk7.glb`
			-- (copied to `assets/models/patrol_tactical/anglerfish.glb`, real
			-- binary GLB, baseColorFactor materials only, no textures).
			-- BSGO-identifying internal metadata stripped on copy (node/mesh
			-- "Viper Mk VII" -> "anglerfish_hull", "colonial_*"/"glass"/
			-- "engine_glow" materials -> "anglerfish_*", extras removed).
			-- FLAGGED, same "Colonial" pattern as the others, and a close
			-- relative of Sardine's own viper_mk2.glb (see `patrol_interceptor`
			-- above for that entry's own heightened-severity note) - a later,
			-- distinct numbered Viper variant (`"cls": "Strike"`, 9.2m scale),
			-- still individually recognizable to anyone familiar with the source
			-- material even if less singularly iconic than Mk II. Used anyway
			-- per direct instruction after being shown the render - not a
			-- §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			accord = { name = "Anglerfish", model = "/assets/models/patrol_tactical/anglerfish.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Kingfisher", model = "/assets/models/patrol_tactical/kingfisher.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_interceptor"] = {
		class = "Escort",
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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2): real-world animal species
			-- sized to roughly match the ship's class - fish for The Accord,
			-- birds for The Swarm, one size class up from Patrol's Sardine/
			-- Hummingbird. Both PROPOSED, same confirm-or-correct pattern as
			-- those two: predatory/combat-flavored species (vs. Patrol's
			-- small/schooling-or-darting flavor) to match Escort's "first
			-- real," combat-capable role (§2.1).
			--
			-- `model` (decided, replacing the old `<TBD>` state): originally a
			-- rudimentary ORIGINAL low-poly hull, hand-authored as a glTF
			-- (assets/models/escort_interceptor/escort_interceptor.gltf, tools/build_escort_interceptor_model.py,
			-- still referenced by the base "escort_interceptor" ship_id above) - same
			-- "no BSG-derived design" rule as Patrol Interceptor (§0).
			--
			-- Falcon's `model` (REPLACED per direct instruction - originally a
			-- distinct per-faction, user-supplied asset (S2.8.9), stripped of
			-- identifying third-party metadata before being added, not
			-- SuperShips-sourced, no §0 flag needed): now sourced from
			-- ~/Defold/SuperShips's `assets/models/bsgo_ships_improved/hd/
			-- banshee/banshee.glb` (copied over the old `assets/models/
			-- escort_interceptor/falcon.glb`, same filename/path). BSGO-
			-- identifying internal metadata stripped on copy (node/mesh
			-- "Banshee" -> "falcon_hull", "cylon_*" materials -> "falcon_*",
			-- extras removed).
			-- FLAGGED: source asset's own manifest tags it `"faction": "Cylon"`,
			-- referenced from playbsgo.com/fleet.html, "reference-guided
			-- interpretation" of a canon Cylon Escort-class ship (compact rear
			-- body, four long separated forward lances). Used anyway per direct
			-- instruction after being shown the render - not a §0-compliant
			-- asset, kept here as an explicit, acknowledged exception rather
			-- than a silent one. `outpost.gui_script`'s PREVIEW_CAMERA entry for
			-- this model was recomputed against the new file's own ~128-unit
			-- bounding radius (was tuned to the old asset's different scale).
			--
			-- Barracuda's `model` (REPLACED per direct instruction - the file
			-- originally here was the same kind of clean user-supplied asset as
			-- Falcon's, now swapped out): sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/scythe/scythe.glb` (copied
			-- over the old `assets/models/escort_interceptor/barracuda.glb`,
			-- same filename/path, real binary GLB, baseColorFactor materials
			-- only, no textures). BSGO-identifying internal metadata stripped on
			-- copy, same as every other SuperShips-sourced model in this file
			-- (node/mesh "Scythe" -> "barracuda_hull", "colonial_*"/"glass"/
			-- "engine_glow" materials -> "barracuda_*", extras removed).
			-- FLAGGED, same pattern as the five exceptions before it: source
			-- asset's own manifest tags it `"faction": "Colonial"`, referenced
			-- from playbsgo.com/fleet.html, "reference-guided interpretation" of
			-- a canon Colonial Escort-class ship (tall axe-shaped hull, cruciform
			-- stern fins) - i.e. BSG-derived vehicle design, §0's excluded
			-- category. Used anyway per direct instruction after being shown the
			-- render and this same resemblance risk a sixth time - not a
			-- §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one. `outpost.gui_script`'s
			-- PREVIEW_CAMERA entry for this model was recomputed against the
			-- new file's own ~114-unit bounding radius (was tuned to the old
			-- asset's different scale before).
			accord = { name = "Barracuda", model = "/assets/models/escort_interceptor/barracuda.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Falcon", model = "/assets/models/escort_interceptor/falcon.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_support"] = {
		class = "Escort",
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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Support row): Accord = Remora,
			-- Swarm = Egret - both proposed, same confirm-or-correct pattern as
			-- every other name in this file.
			--
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/glaive/glaive.glb` (copied to
			-- `assets/models/escort_support/remora.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures - same format Defold's
			-- importer already renders correctly for this project's other
			-- third-party models).
			-- FLAGGED, same as Frigatebird's aesir.glb (`frigate_interceptor`
			-- above): that source asset's own manifest/README describe it as a
			-- "reference-guided interpretation" of an actual BSGO "Colonial"-faction
			-- Escort-class ship, explicitly built so its silhouette is recognizable
			-- - i.e. it's BSG-derived vehicle design, the same category of asset §0
			-- already ruled out for the Viper Mk II/Cylon Raider meshes. Used here
			-- anyway per direct instruction after being shown the render and this
			-- same resemblance risk a second time - not a §0-compliant asset, kept
			-- here as an explicit, acknowledged exception rather than a silent one.
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/spectre/spectre.glb` (copied
			-- to `assets/models/escort_support/egret.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Spectre" ->
			-- "egret_hull", "cylon_*" materials -> "egret_*", extras removed).
			-- FLAGGED, same "Cylon" pattern as the others: source asset's own
			-- manifest tags it `"faction": "Cylon"`, referenced from
			-- playbsgo.com/fleet.html, "reference-guided interpretation" of a
			-- canon Cylon Escort-class ship - three pronounced radial fins around
			-- a long forward spear. Used anyway per direct instruction after
			-- being shown the render - not a §0-compliant asset, kept here as an
			-- explicit, acknowledged exception rather than a silent one.
			accord = { name = "Remora", model = "/assets/models/escort_support/remora.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Egret", model = "/assets/models/escort_support/egret.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_tactical"] = {
		class = "Escort",
		-- `role` (see `frigate_support`'s own entry for the field's rationale): Tactical.
		role = "Tactical",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- every other Escort/Frigate-tier ship so far.
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
			-- Naming convention (plan.md §2.1.2's Tactical row): Accord =
			-- Lionfish, Swarm = Osprey - both proposed, same confirm-or-correct
			-- pattern as every other name in this file.
			--
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/liche/liche.glb` (copied to
			-- `assets/models/escort_tactical/osprey.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Liche" ->
			-- "osprey_hull", "cylon_*" materials -> "osprey_*", extras removed).
			-- FLAGGED, same "Cylon" pattern as Pelican's hel.glb: source asset's
			-- own manifest tags it `"faction": "Cylon"` - the explicitly-named
			-- banned term in §0 - referenced from playbsgo.com/fleet.html,
			-- "reference-guided interpretation" of a canon Cylon ship (vertically
			-- separated upper/lower forward blades, bone-white/metallic look,
			-- same bio-mechanical Cylon design language as Pelican's source).
			-- Used anyway per direct instruction after being shown the render -
			-- not a §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			-- Accord's `model`: an ORIGINAL hand-authored hull (tools/build_lionfish_model.py),
			-- not sourced from anywhere - the roster's last remaining `<TBD>` model, filled in
			-- without the BSG-derived-asset tradeoff every other exception in this file carries.
			-- Leans into the ship's own namesake rather than copying any existing craft: a
			-- tapered body, a raised head crest, a fan of dorsal spines (tallest just aft of the
			-- crest, tapering toward the tail), two swept pectoral fin panels near the bow, and a
			-- small tail fin - the spines/fins double as a sensor-array silhouette, fitting the
			-- Tactical row this ship occupies. ~11.7-unit bounding radius.
			accord = { name = "Lionfish", model = "/assets/models/escort_tactical/lionfish.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Osprey", model = "/assets/models/escort_tactical/osprey.model", weapon_gui = "<TBD>" },
		},
	},
	["escort_assault"] = {
		class = "Escort",
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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Assault row): Accord = Moray,
			-- Swarm = Goshawk - both proposed, same confirm-or-correct pattern as
			-- every other name in this file.
			--
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/maul/maul.glb` (copied to
			-- `assets/models/escort_assault/moray.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped before adding, same as every other
			-- SuperShips-sourced model in this file (node/mesh "Maul" ->
			-- "moray_hull", "colonial_*"/"engine_glow" materials -> "moray_*",
			-- the extras block with ship_id/faction/ship_class removed entirely).
			-- FLAGGED, same pattern as the four exceptions before it: that source
			-- asset's own manifest describes it as a "reference-guided
			-- interpretation" of an actual BSGO "Colonial"-faction Escort-class
			-- assault ship, explicitly built so its silhouette is recognizable -
			-- i.e. it's BSG-derived vehicle design, the same category of asset §0
			-- already ruled out for the Viper Mk II/Cylon Raider meshes. Used here
			-- anyway per direct instruction after being shown the render and this
			-- same resemblance risk a fifth time - not a §0-compliant asset, kept
			-- here as an explicit, acknowledged exception rather than a silent one.
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/wraith/wraith.glb` (copied to
			-- `assets/models/escort_assault/goshawk.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Wraith" ->
			-- "goshawk_hull", "cylon_*" materials -> "goshawk_*", extras
			-- removed).
			-- FLAGGED, same "Cylon" pattern as the others: source asset's own
			-- manifest tags it `"faction": "Cylon"`, referenced from
			-- playbsgo.com/fleet.html, "reference-guided interpretation" of a
			-- canon Cylon Escort-class ship - angular split armored jaws with a
			-- central opening and large red inner vents, an aggressive shape
			-- fitting the Assault row. Used anyway per direct instruction after
			-- being shown the render - not a §0-compliant asset, kept here as an
			-- explicit, acknowledged exception rather than a silent one.
			accord = { name = "Moray", model = "/assets/models/escort_assault/moray.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Goshawk", model = "/assets/models/escort_assault/goshawk.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_support"] = {
		class = "Frigate",
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
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- Escort Interceptor - no Frigate-specific tuning has been decided yet, so this is
		-- the shared starting point, not an invented number.
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
		-- Same as Escort Interceptor: no confirmed Frigate-tier slot-count number exists yet,
		-- so left empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Support row): Accord = Manta Ray,
			-- Swarm = Pelican - both proposed, same confirm-or-correct pattern as
			-- every other name in this file. (The aesir-derived glb was briefly
			-- and incorrectly wired to Pelican here; it actually belongs to
			-- Frigatebird, Interceptor row, `frigate_interceptor` above - moved
			-- there per direct correction.)
			--
			-- Swarm's `model`: REPLACED per direct instruction with an ORIGINAL
			-- hand-authored hull (tools/build_pelican_model.py) - the old
			-- SuperShips-sourced hel.glb (Cylon-flagged, see git history) is
			-- gone. The new hull leans into the ship's own real-world namesake:
			-- a long flattened bill making up nearly half the length, a
			-- distended throat pouch hanging underneath it (doubles as a
			-- cargo/supply pod - a fitting read for this Support-row ship),
			-- a bulky barrel body, and broad, only gently swept wings (a
			-- soaring bird's flat wing, not a fighter's delta). Pale grey-white
			-- plumage with a black wingtip band and a warm orange-tan pouch -
			-- real material colors, visible now that render/custom.render_script's
			-- leftover diagnostic red tint override has been removed.
			-- ~22.2-unit bounding radius.
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/vanir/vanir.glb` (copied to
			-- `assets/models/frigate_support/manta_ray.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Vanir" ->
			-- "manta_ray_hull", "colonial_*"/"engine_glow" materials ->
			-- "manta_ray_*", extras removed).
			-- FLAGGED, same "Colonial" pattern as the others: source asset's own
			-- manifest tags it `"faction": "Colonial"`, referenced from
			-- playbsgo.com/fleet.html, "reference-guided interpretation" of a
			-- canon Colonial capital ("Line" class) ship - two full-length
			-- parallel hulls with an open central channel and connecting
			-- bridges, a twin-hull silhouette that reads as a fitting coincidence
			-- for a Manta Ray, though that's not why it was picked. Used anyway
			-- per direct instruction after being shown the render - not a
			-- §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			accord = { name = "Manta Ray", model = "/assets/models/frigate_support/manta_ray.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Pelican", model = "/assets/models/frigate_support/pelican.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_interceptor"] = {
		class = "Frigate",
		-- `role` (see `frigate_support` above for the field's own rationale): Interceptor.
		role = "Interceptor",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- every other Frigate-tier ship so far - no Frigate-specific tuning has
		-- been decided yet.
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
		-- Same as the other Frigate-tier ships: no confirmed slot-count number
		-- exists yet, so left empty rather than guessed (§0/§4).
		components = {},
		slot_positions = {},
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Interceptor row): Accord = Marlin,
			-- Swarm = Frigatebird - both proposed, same confirm-or-correct pattern as
			-- every other name in this file.
			--
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/aesir/aesir.glb` (copied to
			-- `assets/models/frigate_interceptor/frigatebird.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures - same format Defold's
			-- importer already renders correctly for this project's other
			-- third-party models). Originally (mis)assigned to Pelican on
			-- `frigate_support` - moved here per direct correction.
			-- FLAGGED: that source asset's own manifest/README describe it as a
			-- "reference-guided interpretation" of an actual BSGO "Colonial"-faction
			-- capital ship, explicitly built so its silhouette is recognizable -
			-- i.e. it's BSG-derived vehicle design, the same category of asset §0
			-- and this file's own Patrol Interceptor/Escort Interceptor header comments
			-- already ruled out for the Viper Mk II/Cylon Raider meshes. Used here
			-- anyway per direct instruction after being shown the live render and
			-- the specific resemblance risk - not a §0-compliant asset, kept here
			-- as an explicit, acknowledged exception rather than a silent one.
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/fenrir/fenrir.glb` (copied to
			-- `assets/models/frigate_interceptor/marlin.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Fenrir" ->
			-- "marlin_hull", "cylon_*" materials -> "marlin_*", extras removed).
			-- FLAGGED, and NOTE the cross-faction mismatch: this source asset's
			-- own manifest tags it `"faction": "Cylon"` - the other explicitly-
			-- named banned term in §0 - despite being used here for an Accord
			-- (fish-named) ship, not a Swarm one. "Reference-guided
			-- interpretation" of a canon Cylon ship (forked long forward hull,
			-- paired lower lances, tall swept rear fins - a sleek, fast-reading
			-- shape that fits Marlin's Interceptor-row speed flavor regardless of
			-- source faction). Used anyway per direct instruction after being
			-- shown the render and this specific cross-faction resemblance risk -
			-- not a §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			accord = { name = "Marlin", model = "/assets/models/frigate_interceptor/marlin.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Frigatebird", model = "/assets/models/frigate_interceptor/frigatebird.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_tactical"] = {
		class = "Frigate",
		-- `role` (see `frigate_support` above for the field's own rationale): Tactical.
		role = "Tactical",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- every other Frigate-tier ship so far - no Frigate-specific tuning has
		-- been decided yet.
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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Tactical row): Accord = Hammerhead,
			-- Swarm = Harpy Eagle - both proposed, same confirm-or-correct pattern
			-- as every other name in this file.
			--
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/gungnir/gungnir.glb` (copied to
			-- `assets/models/frigate_tactical/hammerhead.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures - same format Defold's
			-- importer already renders correctly for this project's other
			-- third-party models).
			-- FLAGGED, same as Frigatebird's aesir.glb and Remora's glaive.glb: that
			-- source asset's own manifest/README describe it as a "reference-guided
			-- interpretation" of an actual BSGO "Colonial"-faction capital ("Line"
			-- class) ship, explicitly built so its silhouette is recognizable -
			-- i.e. it's BSG-derived vehicle design, the same category of asset §0
			-- already ruled out for the Viper Mk II/Cylon Raider meshes. Used here
			-- anyway per direct instruction after being shown the render and this
			-- same resemblance risk a third time - not a §0-compliant asset, kept
			-- here as an explicit, acknowledged exception rather than a silent one.
			-- Swarm's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/nidhogg/nidhogg.glb` (copied
			-- to `assets/models/frigate_tactical/harpy_eagle.glb`, real binary
			-- GLB, baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Nidhogg" ->
			-- "harpy_eagle_hull", "cylon_*" materials -> "harpy_eagle_*", extras
			-- removed).
			-- FLAGGED, same "Cylon" pattern as Pelican's hel.glb and Osprey's
			-- liche.glb: source asset's own manifest tags it `"faction": "Cylon"`,
			-- referenced from playbsgo.com/fleet.html, "reference-guided
			-- interpretation" of a canon Cylon ship (organic central spear
			-- wrapped by four outward-curving skeletal claws - the claw shape
			-- actually reads as a fitting coincidence for an eagle-named ship,
			-- though that's not why it was picked). Used anyway per direct
			-- instruction after being shown the render - not a §0-compliant
			-- asset, kept here as an explicit, acknowledged exception rather
			-- than a silent one.
			accord = { name = "Hammerhead", model = "/assets/models/frigate_tactical/hammerhead.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Harpy Eagle", model = "/assets/models/frigate_tactical/harpy_eagle.model", weapon_gui = "<TBD>" },
		},
	},
	["frigate_assault"] = {
		class = "Frigate",
		-- `role` (see `frigate_support` above for the field's own rationale): Assault.
		role = "Assault",
		-- Full stat block: the unmodified universal baseline (§2.1.1), same as
		-- every other Frigate-tier ship so far - no Frigate-specific tuning has
		-- been decided yet.
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
		faction_skins = {
			-- Naming convention (plan.md §2.1.2's Assault row): Accord = Tiger
			-- Shark, Swarm = Golden Eagle - both proposed, same confirm-or-correct
			-- pattern as every other name in this file.
			--
			-- Swarm's `model`: REPLACED per direct instruction with an ORIGINAL
			-- hand-authored hull (tools/build_golden_eagle_model.py) - the old
			-- SuperShips-sourced jormung.glb (Cylon-flagged, see git history) is
			-- gone. The new hull leans into the ship's own real-world namesake:
			-- a small beak hooking down-and-back at the nose (unlike every other
			-- hull's plain forward point), broad wings held at a dihedral (tips
			-- raised above the root, a soaring raptor's own silhouette) with a
			-- small spread-feather spike at each tip, a fanned three-panel tail
			-- instead of a single fin, and two talons folded under the belly.
			-- Golden-brown plumage with a darker brown wing/tail band and a
			-- lighter golden nape patch - the real bird's own two-tone coloring,
			-- visible now that render/custom.render_script's leftover diagnostic
			-- red tint override has been removed. ~24.6-unit bounding radius.
			-- Accord's `model`: sourced from ~/Defold/SuperShips's
			-- `assets/models/bsgo_ships_improved/hd/jotunn/jotunn.glb` (copied to
			-- `assets/models/frigate_assault/tiger_shark.glb`, real binary GLB,
			-- baseColorFactor materials only, no textures). BSGO-identifying
			-- internal metadata stripped on copy (node/mesh "Jotunn" ->
			-- "tiger_shark_hull", "colonial_*"/"engine_glow" materials ->
			-- "tiger_shark_*", extras removed).
			-- FLAGGED, same "Colonial" pattern as the others: source asset's own
			-- manifest tags it `"faction": "Colonial"`, referenced from
			-- playbsgo.com/fleet.html, "reference-guided interpretation" of a
			-- canon Colonial capital ("Line" class) ship - deep armored assault
			-- hull, sloping prow, stepped dorsal deck, rear outriggers, an
			-- appropriately heavy-hitter shape for the Assault row. Used anyway
			-- per direct instruction after being shown the render - not a
			-- §0-compliant asset, kept here as an explicit, acknowledged
			-- exception rather than a silent one.
			accord = { name = "Tiger Shark", model = "/assets/models/frigate_assault/tiger_shark.model", weapon_gui = "<TBD>" },
			swarm  = { name = "Golden Eagle", model = "/assets/models/frigate_assault/golden_eagle.model", weapon_gui = "<TBD>" },
		},
	},
}

return M
