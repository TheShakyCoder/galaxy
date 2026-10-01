# Changelog

All notable changes to Galaxy. Versions follow [Semantic Versioning](https://semver.org);
while the game is in alpha they carry an `-alpha.N` label. The current version lives in
`main/version.lua` (see "Versioning" in the README).

## [0.3.0-alpha.1] - 2026-09-30

### XP, levels and ranks
- Earn XP on each game server, decided by the server (it can't be faked):
  - arriving in a star system for the first time: 100 XP;
  - analysing an asteroid for the first time: 10 XP each (the server now checks
    the analyser is fitted and which asteroids were in range);
  - damaging the other faction's outposts: 1 XP per 10 hull damage;
  - destroying one: 1,000 XP, shared by its attackers by damage dealt.
- XP gives a level (BSGO's curve: level n needs 1,000 x (n-1)^2 XP) and a
  faction rank for levels 1-20: naval ranks for the Accord (Cadet to Fleet
  Admiral), flock and bird-of-prey ranks for the Swarm (Hatchling to Apex).
- Ship classes need a level to buy: Escort 5, Frigate 10. Ships you own are
  never locked.
- Daily assignments (reset 00:00 UTC), each +1,000 XP and +250 Scrip: Asteroid
  Recon (analyse 20 new asteroids), Survey (arrive in 3 different systems),
  Outpost Raid (deal 2,000 outpost damage).
- The outpost's Overview shows your rank, XP and today's assignments; the HUD
  shows XP, promotions and completed assignments as they happen; the website
  dashboard shows each server's rank, level and XP.
- XP amounts, class levels and assignment rewards are first guesses (the BSGO
  wiki gives none) and will be tuned.

### Controls
- Weapons are switched on and off one at a time with Shift + their slot number
  (W1 is Shift+1, W2 Shift+2, ...). They all start on, and the ones that are on
  fire by themselves at your target; the old fire-everything key is gone.
- Active Computer, Engine and Hull modules are used with 1-9: slots are
  numbered C1, C2, then E1..., then H1... (on a Patrol ship C1 is 1 and H2 is
  8). The Asteroid Analyser still also works with P. Passive modules (armour
  plating and so on) are always on and have no key.
- The Fitting tab shows each slot's key under it, and the flight HUD lists your
  weapons (on/off) and module keys.
- After a reconnect, the game tells the server again what it's firing at.
- Targeting, with BSGO's keys: Tab cycles through everything in sensor range
  (other players' ships, both outposts and asteroids), nearest first; X targets
  the nearest enemy, F1 the nearest friendly, C clears the target, and a
  left-click targets whatever is under the cursor. G switches all weapons on or
  off at once.
- The target is marked: a bracket around it (red enemy, blue friendly, grey
  neutral), or an arrow at the screen edge when it's off screen, and a panel at
  the top with its name (an analysed asteroid shows its resource), hull for
  outposts, distance and [FIRING].
- Switched-on weapons visibly fire tracer shots at an enemy outpost or any
  asteroid within their range and firing arc. Asteroids take no damage yet
  (mining isn't built); outposts take damage as before.

### Fixes
- The server now tracks where a ship is between its position updates (games
  only send one when speed or heading changes), so analysing asteroids and
  firing at an outpost while flying straight use the ship's real position,
  not where it was when the run began.

### Asteroid Analyser
- The Asteroid Analyser (Computer module) works: press P to analyse every
  asteroid within 500 m. They pulse while the 2-second scan runs, then turn
  the colour of what they're made of: red inert rock, yellow hydrogen,
  purple iron or blue water. The HUD counts what was found.
- Asteroids are made of inert rock (55%), hydrogen (25%), iron (12%) or
  water (8%): BSGO's frequency order and colours, with SuperShips' split
  (Titanium becomes iron). Every player's game agrees what each asteroid is.
- Only you see what you've analysed; it's remembered per system until you
  reload the page. The analyser can't be used again until its scan finishes.

## [0.2.0-alpha.1] - 2026-09-29

### Accounts move to the website
- Registering, verifying your email, logging in, resetting your password and
  deleting your account all happen on the website (fig.limited), not in the
  game. The game's login and verification screens are gone.
- **Play** on the website opens the game. `play.fig.limited` only serves the
  game to players logged in (and verified) on the website; everyone else is
  sent to the login page.
- The game signs in to a game server with a short-lived token from the
  website, signed for that one server. Nakama accepts no other way of signing
  in (email, device, social and account linking are all refused).
- The website keeps a list of game servers and tells the game which one to
  connect to. With one server, Play goes straight in; a server list appears
  once there are more.
- You have the same identity on every game server, with separate progress on
  each, so you can pick a different faction per server.
- The website's dashboard shows your pilot on each server you've played:
  faction, ship, location, Scrip and Hydrogen.
- In the outpost, **Log out** is now **Account**, which saves and opens the
  website.
- When the game can't sign in, it says why: the game server didn't accept the
  game's key, didn't accept your login, or couldn't be reached.

### Breaking
- Existing game accounts and progress are wiped: everyone registers again on
  the website.
- Game servers need `PLAY_TOKEN_SECRET` and `SERVER_ID`; `RESEND_API_KEY`,
  `EMAIL_FROM` and the local Mailpit are gone (the website sends email).

### Development
- Debug builds sign in with a dev token (`php artisan galaxy:dev-token` on a
  local website): `#dev_token=` on the HTML5 page, or `GALAXY_PLAY_TOKEN` for
  desktop builds.

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
