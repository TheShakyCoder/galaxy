-- Shared registry of other players' ships currently rendered in this
-- system, published by main/remote_ships.script every frame and read by
-- main/player_ship.script to populate main/flight_hud.gui's radar
-- "contacts" list. Singleton (shared_state = 1 in game.project) - ported
-- from ~/Defold/SuperShips/main/remote_registry.lua (§0), which the same
-- source file uses for its own ship-targeting/autopilot; Galaxy has neither
-- of those yet, so this is currently radar-only.
--
-- M.ships[user_id] = { pos = vmath.vector3, faction = string, speed = number }
local M = {}

M.ships = {}

return M
