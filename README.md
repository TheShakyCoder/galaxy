# Galaxy

A multiplayer space-flight game for the browser, built with [Defold](https://defold.com/)
and a self-hosted [Nakama](https://heroiclabs.com/nakama/) server.

**Play the current build:** <https://galaxy.stupidly.uk> (alpha, see [`CHANGELOG.md`](CHANGELOG.md))

> Early prototype. Flying, fitting, the star map, FTL jumps and seeing other
> players fly are in. Combat, missions and progression are still being designed.

## The setting

In a fractured star cluster called **the Verge**, two player factions fight over
the jump lanes of a dying home system:

- **The Accord**: a human coalition. Crewed ships, pilot skill, strong opening strikes.
- **The Swarm**: augmented machine fleets descended from Accord robots. Weaker
  one-on-one, stronger in numbers, self-repair and holding territory.
- **Robots**: the original robots the Accord abandoned. A computer-controlled
  enemy that both player factions fight. Players can't choose it.

You pick Accord or Swarm when you first start; it's permanent for your account. Galaxy is mechanically inspired by
browser space MMOs of the early 2010s, but its setting, names and art are its own.

## What's in the game

- **24 ships**: Patrol, Escort and Frigate classes, each with Assault, Interceptor,
  Support and Tactical roles, and a separate model for each faction. Carriers
  are planned.
- **Outposts**: buy and sell ships, weapons and modules, and fit them into your
  ship's weapon, computer, engine and hull slots by drag and drop.
- **Flight**: third-person chase camera, throttle and boost, self-levelling, and
  speeds in real metres per second.
- **Star map**: 58 systems named after real stars, with Sol as the Accord home and
  Polaris as the Swarm home. You FTL-jump between them within your ship's jump
  range, which costs Hydrogen.
- **Targeting**: cycle targets, target the nearest enemy, match its speed, or
  follow a friendly ship.
- **Resources**: Scrip, Water, Iron and Hydrogen.
- **Accounts**: sign up with email and password and verify the email with a
  6-digit code before playing. Your faction, Scrip, ships, fittings and skins
  are saved to your account, and the game logs you back in automatically.
  The server owns that progress: every purchase, sale, fitting change and FTL
  jump is checked and applied by Nakama, so balances and items can't be
  edited in the browser.
- **Multiplayer**: each star system is an authoritative server match where you see
  other players' ships in real time. The server validates every move, and you can
  only enter the system you actually flew or jumped to. The client reconnects
  automatically and uses dead reckoning to keep network traffic low.
- **Ship skins**: twelve paint and model collections for every ship, 288 skins
  in all, bought and equipped in the outpost's Skins tab (see
  [`assets/skins/`](assets/skins/README.md)).

## Controls

| Key | Action |
|---|---|
| W / S, ↑ / ↓ | Pitch |
| A / D, ← / → | Yaw |
| = / −, keypad + / − | Throttle up / down |
| E / Q | Full throttle / stop |
| Space (hold) | Boost (uses Hydrogen) |
| Tab / X / C | Cycle target / nearest enemy / clear target |
| T | Match target's speed |
| Y | Follow friendly target |
| N | Star map |
| J | Execute FTL jump |
| K | Dock at a nearby outpost, or cancel a jump |
| Mouse wheel | Zoom |

Other keys (weapons 1–9, G, F, scanner, slide thrusters and so on) are reserved
for features that aren't built yet.

## Running it locally

1. **Start the server.** You need Docker.
   ```sh
   cd nakama-server
   docker compose up
   ```
   Nakama listens on `127.0.0.1:7350`. Its admin console is at <http://127.0.0.1:7351>.
2. **Run the game.** Open `game.project` in the Defold editor (1.13.1) and choose
   **Project → Build**. The editor fetches the dependencies (Nakama and
   WebSocket) on first build.

Every player needs a verified account. Locally, verification emails never go
out: they land in the [Mailpit](https://mailpit.axllent.org) inbox that starts
with the server, at <http://localhost:8035>. Any address works, e.g.
`test1@example.com`.

The server enforces the same rules as the game by running copies of
`main/session.lua` and its data files. After changing any of them, run
`python tools/sync_server_rules.py` and restart Nakama
(`docker compose restart nakama`).

To test multiplayer, use two accounts. Separate browsers each keep their own
login; two builds run from the editor on the same Mac share the saved login,
so log out in one and log in there with a second account.

The client reads its server address from the `[nakama]` section of `game.project`,
which points at the local server by default.

## Deployment

The live site runs on [Coolify](https://coolify.io/) as two services built from
this repo:

- **galaxy-web**: the HTML5 build, compiled by the root [`Dockerfile`](Dockerfile)
  and served by nginx.
- **galaxy-server**: Nakama and Postgres, from
  [`nakama-server/docker-compose.coolify.yml`](nakama-server/docker-compose.coolify.yml).

For the full setup, required secrets and troubleshooting, see
[`docs/DEPLOY_COOLIFY.md`](docs/DEPLOY_COOLIFY.md).

## Versioning

Galaxy uses [Semantic Versioning](https://semver.org) with an alpha label while the game
is in alpha: `0.1.0-alpha.1`, `0.1.0-alpha.2`, ... A bigger step bumps the minor version
(`0.2.0-alpha.1`); beta and `1.0.0` come later. Changes are listed in
[`CHANGELOG.md`](CHANGELOG.md).

The version lives in one place, `main/version.lua`. The game shows it on the login screen,
and the server gets a copy through `tools/sync_server_rules.py`. If a player's game and the
server report different versions (mid-deploy, or a cached old copy of the game), the login
screen asks them to reload.

To release:

1. Set `M.VERSION` in `main/version.lua`.
2. Add a `CHANGELOG.md` entry for it.
3. Run `python tools/sync_server_rules.py`.
4. Commit, tag the commit `v<version>` (e.g. `git tag v0.1.0-alpha.2`), and push the
   commit and the tag (`git push origin master --tags`).

## Project layout

```
main/                 game scripts, GUI screens and the main collection
  data/               game data: ships, star systems, asteroids, modules (one table per file)
  network.lua         Nakama connection, rooms and reconnection
  player_ship.script  flight, camera, targeting, jumps and position updates
  remote_ships.script other players' ships
  outpost.gui_script  hangar, shop and fitting screens
assets/               models, textures and the cosmetics library
input/                key bindings
render/               custom render script
nakama-server/        Nakama + Postgres (local and Coolify compose files)
deploy/, Dockerfile   web build and nginx config
docs/                 deployment guide
plan.md               full design document and open questions
```

## Roadmap

The design lives in [`plan.md`](plan.md), including the open questions in §4.
Main next steps:

- Combat: weapons, firing arcs and damage
- Server-authoritative game logic in `nakama-server/modules/` (Robots PvE,
  combat, economy)
- Carriers, progression and ranks
- Password reset for accounts
- Stripe purchases (premium currency for real-money skins)
