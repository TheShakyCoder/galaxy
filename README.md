# Galaxy

A multiplayer space-flight game for the browser, built with [Defold](https://defold.com/)
and a self-hosted [Nakama](https://heroiclabs.com/nakama/) server.

**Play the current build:** <https://play.fig.limited> (alpha, see [`CHANGELOG.md`](CHANGELOG.md))

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
- **Asteroid Analyser**: a Computer module. Press P to analyse every asteroid
  within 500 m: they pulse for two seconds, then turn the colour of what
  they're made of (red inert rock, yellow hydrogen, purple iron, blue
  water). Only you see what you've analysed.
- **Accounts**: everything account-related happens on the website
  ([fig.limited](https://fig.limited), a separate Laravel project): register,
  verify your email, log in, reset your password, and see your pilot on each
  game server. **Play** there opens the game, which signs you in to a game
  server with a short-lived token from the site; `play.fig.limited` only
  serves the game to logged-in players. Each game server keeps its own
  progress for you (faction, Scrip, ships, fittings, skins), so you can be
  Accord on one server and Swarm on another. The server owns that progress:
  every purchase, sale, fitting change and FTL jump is checked and applied by
  Nakama, so balances and items can't be edited in the browser.
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
| 1 | Fire / stop firing all weapons at the target (enemy outposts only, so far) |
| P | Asteroid Analyser (if fitted): reveal what every asteroid within 500 m is made of |
| Mouse wheel | Zoom |

Other keys (weapons 2–9, G, F, slide thrusters and so on) are reserved
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

Players sign in with a play token from the website. For local builds, run the
website locally (DDEV, see its README), register the local server there once
and make a verified user:

```sh
php artisan galaxy:server local --host=127.0.0.1 --port=7350 --insecure \
  --internal-url=http://host.docker.internal:7350 \
  --http-key=local-dev-http-key --secret=local-dev-play-token-secret
php artisan galaxy:dev-token you@example.test local   # prints a 30-day token
```

Then give the token to a debug build: set `GALAXY_PLAY_TOKEN` for a desktop
build, or open an HTML5 build as `index.html#dev_token=<token>`. Release
builds get their token from `play.fig.limited` instead and need the website.

The server enforces the same rules as the game by running copies of
`main/session.lua` and its data files. After changing any of them, run
`python tools/sync_server_rules.py` and restart Nakama
(`docker compose restart nakama`).

To test multiplayer, make two users and give each build its own token.

Debug builds read the game server address from the `[nakama]` section of
`game.project`, which points at the local server by default; release builds
get it from the website.

## Deployment

The live site runs on [Coolify](https://coolify.io/) as two services built from
this repo:

- **galaxy-web**: the HTML5 build, compiled by the root [`Dockerfile`](Dockerfile)
  and served by nginx to players logged in on the website.
- **galaxy-server**: Nakama and Postgres, from
  [`nakama-server/docker-compose.coolify.yml`](nakama-server/docker-compose.coolify.yml).

Accounts and the Play button are on the website (**galaxy-site**, its own
repo). For the full setup, required secrets and troubleshooting, see
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
- Stripe purchases (premium currency for real-money skins)
