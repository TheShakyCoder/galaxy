# Changelog

All notable changes to Galaxy. Versions follow [Semantic Versioning](https://semver.org);
alpha milestones carry an `-alpha.N` label. The current version lives in
`main/version.lua` (see "Versioning" in the README).

## [Unreleased]

### Flight
- A **space dust starfield** now streams past the ship while flying at speed: a pool
  of small bright motes that rush astern at the ship's own speed, always along the
  hull's own long axis rather than the camera's view, so speed reads as speed. The
  motes live in world space and recycle ahead of the bow once they fall behind the
  stern, so a turn only changes the direction they travel — it never drags them
  sideways with the hull. While the ship is idle the dust simply stays where it is;
  launches and jumps (teleports) are ignored; and the dust is hidden whenever you're
  docked.
- The in-flight HUD's bottom-left ship diagram is now **interactive**: hovering a
  fitted slot shows the module's name and the key that toggles it (with the Shift
  modifier drawn as an **icon**, not the text "Shift+"), and clicking a slot toggles
  it exactly as its own key would — weapons switch on/off, active modules run, and
  passive or empty slots report their state. The whole diagram is now drawn at
  **66%** of its authored size (markers, labels, tooltip and panel background alike),
  held into the bottom-left corner.

### Asteroids
- The two faction **home systems** — Sol (The Accord) and Polaris (The Swarm) — now
  carry a much larger asteroid field: **100 rocks** (up from the default 50), spread
  right across the whole system instead of clustered in a small ball around the
  centre. Every other system keeps the default field.

### Weapons
- Combat weapons now use the **reference game's own published names verbatim** —
  the Colonial name on The Accord's side, the Cylon name on The Swarm's (e.g.
  `MEC-A6 "Fang"` / `Type A "Aggressor"`). This is an acknowledged exception to
  the §0 IP boundary (recorded at the top of `plan.md`), a deliberate move to match
  `bsgo.fandom.com/wiki/Weapons`. Where the reference lists a single shared name
  (`Claw`/`Hurricane`/`Falcon`, `Nova`, `Thunderbolt`, `Mole`) the entry keeps one
  `name` and no `faction_names`. Names live in a `faction_names` table and are
  resolved for the player's faction by `catalog.name_for`, which the outpost screen
  and flight HUD now use for every module name. Where the reference has no name
  (its Line/Frigate page is empty) the earlier original names are kept.
- Every ship class now has a full auto cannon family: a general-purpose cannon
  plus rapid-fire and long-range variants for Patrol, Escort and Frigate, and the
  Patrol tier also gets the reference's three **−P precision** models
  (`Fang-P`/`Tornado-P`/`Hawk`), which climb in CriticalOffense with upgrade instead
  of staying flat. The Patrol variants carry real reference stats (including
  Accuracy 400, CriticalOffense 100, Durability 2500→5000); the Escort/Frigate ones
  are identity data only until real numbers exist.
- **Every cannon** — combat and mining alike — now renders its shots as a
  **three-streak burst** that flies **much smaller and slower**: `tracers = 3`, a
  `shot_scale` of `0.33, 0.33, 3.96` (first cut to 33%, then halved again) and a
  `shot_speed` of **300 m/s** (the hub's 1200 default halved twice). Purely visual —
  damage and rate of fire are untouched, and the server still resolves one shot; the
  gentler speed is what lets the three streaks read as separate rather than merging
  into one long tracer. The look is stamped onto every cannon entry by one shared loop,
  so the Mining Cannons (which have no combat-stat block) and the Escort/Frigate
  cannons get it too — previously they kept the full-size, full-speed single tracer.
- Mining cannons are renamed to the reference's names too: **Gopher** / **Gouger**
  (Patrol, now with the reference's full DPS 5→16 curve and Mining ×5) and **Mole**
  (Escort). Frigate/Carrier keep their original placeholder names.
- Missile launchers exist for the first time (`weapons_launchers.lua`): a general
  missile launcher and a nuclear launcher for each of the three classes, now under
  the reference names (`HD-70 "Lightning"` / `Type B "Bereaver"`, `HD-96 "Nova"`,
  `HD-M50 "Thunderbolt"`).
- A new shared ordinance table (`ordinance.lua`) holds the ammunition: the four
  cannon-round families (HE/HESC/AP/HERT) with their per-grade bonuses, four
  missiles (interceptor, heavy, siege, dumbfire rocket) and the Nuclear Torpedo,
  which only a nuclear launcher can load. Each round also carries a two-faction
  name, resolved by `ordinance.name_for` (not yet shown anywhere).

### Code organisation
- Split all cannon/projectile rendering out of `main/asteroid_hub.script` into a
dedicated `main/shot_hub.script` / `main/shot_hub.go` hub. It owns the visible
tracer and the firing sound, draws a generic tracer by default, and lets the firing
weapon's own projectile data override it (a weapon may supply `tracers`,
`shot_speed`, `shot_scale`, `shot_tint` and `shot_burst_stagger`). The asteroid hub
is now asteroids only.

### Fixes
- The Asteroid Analyser now scans every asteroid within 400 m of the ship,
  shortened from 500 m per direct instruction.

## [0.3.1] - 2026-10-02

### Fixes
- The in-flight target bracket stays on its target while you turn. The HUD is a
  GUI scene, laid out in the project's 1920x1080 design space (centred, one
  uniform fit scale, letterboxed), while the chase camera fills the whole
  window; the bracket and left-click targeting are now mapped through the same
  centre-fit transform, so they line up at any window shape, not only 16:9.

## [0.3.0-alpha.2] - 2026-10-01

### Asteroids
- Asteroids now have hull, decided by the server like outposts: each rock's
  maximum is scaled from its size (main/data/asteroids.lua `max_hull`, ~100 for
  a 10 m rock to ~500 for a 50 m one), and a switched-on weapon inside its
  range and firing arc mines it down over time. At zero hull the asteroid is
  depleted and disappears for five minutes, then comes back at full hull.
- Targeting an asteroid now shows `HULL <hp> / <max_hp>` next to its distance
  in the top panel, updating as it takes damage.
- Each asteroid also holds a mineable resource amount, shown as `RESOURCE <n>`
  once analysed: for now a fixed proportion of its hull (2/3 for hydrogen and
  iron, 1/3 for water, nothing for inert rock), until the real formula - size,
  system threat level and more - is designed.
- Depleting an asteroid credits its whole resource amount to the player's
  saved inventory (Water, Iron or Hydrogen, shown on the outpost screen), and
  tells them with a HUD toast. When several players are shooting, it goes to
  the one whose final shot brought its hull to zero. Inert rock holds nothing.
- Hull and resource values are placeholders pending a real mining balance pass.

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
- Daily assignments (reset 00:00 UTC), each +1,000 XP and +250 Tope: Asteroid
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
- The flight HUD's ship diagram is interactive: clicking a slot's icon switches
  that weapon on/off or runs that active module, exactly as its key does (empty
  and still-locked slots do nothing). Hovering an icon shows the module's name
  and its key, with the Shift modifier drawn as a small icon before the slot
  number rather than spelled out as "Shift+".
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
  faction, ship, location, Tope and Hydrogen.
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
- Ship prices from the original game (Tope or Hydrogen); the starter ship isn't for sale.
- New players start with 1,000 Tope and 5,000 Hydrogen.

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
- No way to earn Tope yet, so no ship beyond the starter is affordable.
- The login screen doesn't support mobile on-screen keyboards or pasting.
