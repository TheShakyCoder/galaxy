# Changelog

All notable changes to Galaxy. Versions follow [Semantic Versioning](https://semver.org);
while the game is in alpha they carry an `-alpha.N` label. The current version lives in
`main/version.lua` (see "Versioning" in the README).

## [0.1.0-alpha.3] - 2026-09-29

### Combat
- Outposts can be attacked. Target the other faction's outpost with Tab or X (from up to
  2,000 m) and press 1 to fire all your weapons at it; press 1 again to stop. The HUD shows
  its distance, hull and whether you're firing.
- The server does the damage: every weapon in a W slot hits for its damage per second while
  the outpost is inside its range and 75° firing arc. Your own faction's outpost can't be hit.
- Outposts have 50,000 hull, the BSGO wiki's figure for a regular outpost. At zero they are
  destroyed: they leave the system for an hour, then come back at full hull.
- While an outpost is destroyed its faction can't dock, launch or respawn there; they go to
  their home system instead.
- Weapon stats from the BSGO wiki, one class of weapon per ship class: Gnat (light
  autocannon) 11–22 DPS by upgrade level, 750 m; Digger (light mining cannon) 5 DPS, 600 m;
  Miner (medium mining battery) 5 DPS, 900 m; Speculator (heavy mining battery) 5.3 DPS,
  1,350 m. The Prospector has no stats yet.

### Outposts
- Every system has an outpost for each faction that can go there, not only the home systems.
  Dock at your faction's outpost in any system and launch again from there.
- Launching or arriving from a jump puts you 1,200 m from your faction's outpost in that
  system (or from the system's centre if you have none there), facing the centre.
- Docking range is 1,000 m.
- If you quit, or are destroyed, in a system without your faction's outpost, you return to
  your home system's outpost.
- Launching refunds an unfinished jump.

### Temporary
- FTL jumps cost no Hydrogen for now.

### Deployment
- Hosted at play.fig.limited (game), api1.fig.limited (Nakama) and admin.fig.limited.
- Nakama is built from Docker Hub's copy of the official image, and the server checks its
  required settings when it starts.

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
