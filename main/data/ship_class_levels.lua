-- The level a player needs to BUY a ship of each class (plan.md §2.2: rank
-- gates ship-tier access). Ships already owned are never locked.
-- PLACEHOLDER levels (per direct instruction, to be tuned): the BSGO wiki
-- gives no single figure per class. Shared by the game and the server
-- (tools/sync_server_rules.py), so the server refuses early purchases too.

local M = {}

M.LEVELS = {
	Patrol = 1,
	Escort = 5,
	Frigate = 10,
	Carrier = 15,
}

return M
