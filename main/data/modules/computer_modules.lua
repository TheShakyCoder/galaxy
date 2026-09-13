-- Computer module entries (plan.md §2.8). One concrete entry so far: the
-- Asteroid Analyser, added per direct instruction. It's a normal,
-- separately fitted/removable component like any other module — never an
-- integral/hardcoded part of the ship. `behavior = "active"` (one-shot
-- trigger, not passive/always-on) matches the "activate_scanner" input
-- binding already reserved for a mineral-analysis-type module (§2.10,
-- ported from the reference project's own "Mineral Analysis Module" key)
-- — PROPOSED, flag if this should be passive instead. Stat fields
-- (power_draw/cooldown/wear_per_use, §2.8's shared schema) not yet
-- specified, omitted rather than guessed.

local M = {}

M.COMPUTER_MODULES = {
	["asteroid_analyser"] = {
		name = "Asteroid Analyser",
		type = "computer",
		behavior = "active", -- one-shot trigger (§2.8) — PROPOSED, see plan.md §4
		ship_classes = { "Patrol", "Escort", "Frigate", "Carrier" }, -- fits anywhere for now
		icon = "asteroid_analyser", -- main/images/icons.atlas region, see weapons_autocannons.lua's header comment
	},
}

return M
