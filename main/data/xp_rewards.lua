-- XP the game server awards for each activity (nakama-server/modules/
-- progress.lua is the only place XP is granted). BSGO gives XP for
-- defeating opponents, PvP and assignments, but the wiki gives no amounts,
-- so every number here is INVENTED - a starting point to tune, per the
-- plan's "don't invent unconfirmed numbers" rule (flagged, not hidden).

local M = {}

-- Attacking the other faction's outpost: XP per point of hull damage dealt
-- (1 XP per 10 hull; a regular outpost's 50,000 hull is worth 5,000 XP).
M.OUTPOST_DAMAGE_PER_XP = 10

-- Destroying an outpost: shared between everyone who damaged it in the last
-- OUTPOST_ATTACKER_WINDOW_S seconds, split by damage dealt.
M.OUTPOST_DESTROYED = 1000
M.OUTPOST_ATTACKER_WINDOW_S = 600

-- Arriving in a star system for the first time (58 systems).
M.SYSTEM_FIRST_ARRIVAL = 100

-- Analysing an asteroid for the first time (50 per system).
M.ASTEROID_FIRST_ANALYSIS = 10

return M
