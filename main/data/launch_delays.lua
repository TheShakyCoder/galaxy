-- How long the player must wait before launching from an outpost (plan.md
-- §2.16, per direct instruction 2026-10-15). Kept in their own file so they
-- are easy to find and change. Applied by main/session.lua (dock, resume,
-- repair_delay) and re-checked by the server through the same rules.
--
-- Only two things delay a launch:
--   * reloading the browser (or closing/quitting) while IN FLIGHT, and
--   * doing any repair at the outpost.
-- Loading the game from the website while docked, docking, and respawning
-- after being destroyed launch straight away.

local M = {}

-- After a session that ended in flight (reload, tab closed, quit mid-flight).
M.RELOAD_IN_FLIGHT_SEC = 60

-- After any repair at the outpost (part or all of the ship and its modules).
-- ARBITRARY - may change.
M.REPAIR_SEC = 20

-- After docking or respawning: no wait.
M.DOCK_SEC = 0

return M
