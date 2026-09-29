# Changelog

All notable changes to Galaxy. Versions follow [Semantic Versioning](https://semver.org);
while the game is in alpha they carry an `-alpha.N` label. The current version lives in
`main/version.lua` (see "Versioning" in the README).

## [0.1.0-alpha.2] - 2026-09-29

### Multiplayer
- Each star system is now an authoritative Nakama match instead of a chat channel. The
  server checks every position update against the ship's speed, drops impossible ones
  (teleports, over-speed) and kicks repeat offenders.
- You can only enter the system your server-saved progress says you're in: a directory RPC
  hands out a one-use, 60-second signed ticket for that system's match.
- Other players' ships, factions and skins come from their server-saved profiles, not from
  what their game claims.
- Docked ships leave the system instead of lingering until they time out.
- Built to spread systems across several server endpoints later (system registry, node
  endpoints, tickets that work on any node).

### Login
- Log in and Create account are separate tabs; bigger labels and typed text.

### Outpost
- Ships grid: larger ship names with the price on its own line.

### Fixes
- Jumping no longer runs out of model slots when the new system's asteroids spawn.

### Development
- Local verification emails go to a Mailpit inbox (http://localhost:8035).

## [0.1.0-alpha.1] - 2026-09-28

First versioned alpha release. Everything below is what the game contains at this point.

### Gameplay
- Two factions, the Accord and the Swarm, chosen once per account.
- 24 ships: Patrol, Escort and Frigate classes with Interceptor, Support, Assault and
  Tactical roles, one species model per faction.
- Outposts: buy, sell and advance ships; buy, sell, upgrade and fit modules by drag and drop.
- Flight with chase camera, throttle, boost, targeting and a star map of 58 systems.
- FTL jumps at the original game's scale (20 map units per light-year), costing light-years
  × the ship's Hydrogen per light-year.
- Ship prices from the original game (Scrip or Hydrogen); the starter ship isn't for sale.
- New players start with 1,000 Scrip and 5,000 Hydrogen.

### Skins
- 288 skins (12 collections for every ship), bought and equipped in the outpost's Skins tab.
- Recolor and surface-theme skins show in flight, for your ship and to other players;
  sculpted themes and Clockwork show the default model in flight for now.

### Accounts and server
- Email and password accounts, verified with a 6-digit code sent through Resend.
- Progress is saved to the account and owned by the server: every purchase, sale, fitting
  change and FTL jump is checked and applied by Nakama, so balances and items can't be edited
  in the browser.
- Multiplayer rooms per star system with dead reckoning.

### Known gaps
- No password reset yet.
- No way to earn Scrip yet, so no ship beyond the starter is affordable.
- The login screen doesn't support mobile on-screen keyboards or pasting.
