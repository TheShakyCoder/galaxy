-- Galaxy's release version: the single source of truth, shared by the game
-- (shown on the login screen) and the Nakama server (tools/sync_server_rules.py
-- copies this file there; accounts.lua reports it so the game can tell when
-- it's out of date).
--
-- Semantic Versioning (https://semver.org) with a pre-release label while
-- the game is in alpha: MAJOR.MINOR.PATCH-alpha.N. To release, bump this,
-- add a CHANGELOG.md entry, run tools/sync_server_rules.py, commit, and tag
-- the commit vX.Y.Z (or vX.Y.Z-alpha.N while pre-release). See README.md
-- "Versioning".

local M = {}

M.VERSION = "0.4.0-alpha.3"

return M
