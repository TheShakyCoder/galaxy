-- Rules for a player's ship taking hits (plan.md §2.19). Decided per direct
-- instruction, 2026-10-15. NOT USED YET: there is no damage to player ships
-- (plan.md §4); this file holds the decided numbers ready for that work.
-- Pure Lua, no engine calls, so the server can use it once combat is built
-- (add it to tools/sync_server_rules.py then).
--
-- Hit / damage maths (hit chance, criticals, armour) are BSGO Nova's
-- published formulas, recorded in plan.md §2.13 A - not repeated here until
-- they are implemented.

local M = {}

-- Threat ("in combat") state: lasts this long after the ship was last shot
-- at OR last fired at an enemy (a player of the other faction, their outpost,
-- beacon or platform) or a drone - refreshed by every such shot. Firing at an
-- ASTEROID does not start it. While it lasts: hull regeneration
-- is paused, the HUD shows the threat indicator, docking takes the longer
-- in-combat time (main/data/outposts.lua dock_countdown_in_combat_sec) and
-- an FTL jump charges x4. Power regeneration is NEVER paused.
M.THREAT_SEC = 15

-- Hull regeneration pauses during threat; power regeneration never does.
M.HULL_REGEN_IN_THREAT = false
M.POWER_REGEN_IN_THREAT = true

-- Low durability (BSGO Closed Beta 1.3 patch notes): at or below this hull
-- durability the ship's maximum hull is cut by LOW_DURABILITY_HULL_FACTOR,
-- one weapon slot stops working, and one other slot stops working by role
-- (engine for interceptors, hull for assaults, computer for the rest). A
-- module at 0 % durability stops working until repaired. Repairing restores
-- full durability; upgrading a module also restores it.
M.LOW_DURABILITY_PCT = 20
M.LOW_DURABILITY_HULL_FACTOR = 0.5
M.LOW_DURABILITY_DISABLED_SLOTS = { weapon = 1, by_role = { Interceptor = "E", Assault = "H", default = "C" } }

-- Durability (ARBITRARY - may change): every hit the ship takes removes this
-- percentage of durability from the ship AND from every module fitted to it
-- - one shared wear percentage for the whole ship. Dying adds no extra loss.
M.DURABILITY_LOSS_PER_HIT_PCT = 1

-- Repair (MAY CHANGE): instant, part or all of the ship and its modules, at
-- an outpost; any repair delays the next launch by
-- main/data/launch_delays.lua REPAIR_SEC (20 s). Hull damage is NOT healed by
-- docking - only by regeneration or a repair. (BSGO's own rate was 1 Titanium
-- per 10 durability points in Closed Beta 1.3, raised later; ours is 1:1.)
-- The ship (ships.lua repair_cost_iron) and each fitted
-- module (its durability) have a durability value. At W % wear, the
-- durability lost is W % of each of those values, and repairing costs that
-- many durability points in Iron:
--   iron = W / 100 * (ship durability + sum of fitted modules' durability)
M.IRON_PER_DURABILITY_POINT = 1

-- Player kills (TEMPORARY - to be designed properly later): a player kill is
-- rewarded exactly like a drone kill (plan.md §2.18) until PvP rewards get
-- their own design.
M.PVP_KILL_REWARD = "same_as_drone"

-- Death: no extra durability loss; the player chooses between the 2 nearest
-- outposts of their faction (this system's if it has one), with this long to
-- choose before the nearest is picked automatically (BSGO: ~30 s).
M.RESPAWN_CHOICES = 2
M.RESPAWN_CHOICE_SEC = 30

-- Damage feedback: a subtle halo around the screen edge while being shot at.
M.HIT_HALO_FADE_SEC = 0.6   -- ours: how long the halo takes to fade after a shot
M.HIT_HALO_MAX_ALPHA = 0.35 -- ours: subtle, never a full red-out

return M
