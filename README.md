# Galaxy

A multiplayer space-flight game for the browser, built with [Defold](https://defold.com/)
and a self-hosted [Nakama](https://heroiclabs.com/nakama/) server.

**Play the current build:** <https://galaxy.stupidly.uk>

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

You pick Accord or Swarm when you start. Galaxy is mechanically inspired by
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
- **Multiplayer**: each star system is a shared room where you see other players'
  ships in real time. The client reconnects automatically and uses dead
  reckoning to keep network traffic low.
- **Ship skins**: twelve optional paint and model collections for every ship,
  288 skins in all (see [`assets/skins/`](assets/skins/README.md)). They aren't
  selectable in-game yet.

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
   **Project → Build**. The editor fetches the dependencies (Nakama, WebSocket,
   Poki SDK) on first build.

To test multiplayer, run two builds from the editor. Debug builds get a new
player identity each launch, so they won't collide.

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
- Registered accounts, since only guest play exists today
