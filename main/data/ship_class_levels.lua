-- The level a player needs to BUY a ship of each class (plan.md §2.2: rank
-- gates ship-tier access). Ships already owned are never locked.
-- PLACEHOLDER levels (per direct instruction, to be tuned): the BSGO wiki
-- gives no single figure per class. Shared by the game and the server
-- (tools/sync_server_rules.py), so the server refuses early purchases too.
--
-- TEMPORARY — every class is 1, so any ship can be bought at any rank. This is
-- a dev-convenience override, NOT a balance decision: the original placeholder
-- levels were Patrol 1 / Escort 5 / Frigate 10 / Carrier 15, kept in the
-- comments below so this reverts by putting those four numbers back (then run
-- `python tools/sync_server_rules.py` and restart Nakama). See
-- TEMPORARY-DEV-STATE.md in the repo root for the other temporary change made
-- in the same pass.

local M = {}

M.LEVELS = {
	Patrol = 1,
	Escort = 1, -- TEMPORARY: was 5
	Frigate = 1, -- TEMPORARY: was 10
	Carrier = 1, -- TEMPORARY: was 15
}

return M
