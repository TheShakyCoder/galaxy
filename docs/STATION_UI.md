# Station hangar console

Docking opens a faction hangar with the existing live base-hull preview, pilot
dossier, fitting readiness and assignments. The five station tabs retain their
existing actions. Generated hangar art supplies environmental detail; native
Defold nodes supply every label, gauge, icon, button and interactive panel.

## Presentation and integration

- `main/ui/station_console.lua` lays out the docked console and reads values
  supplied by the existing outpost controller. XP measures progress within the
  current level. Readiness uses actual installed modules and confirmed slot
  counts. Missing upstream slot tables remain empty.
- `main/ui/station_hangars/` contains two fixed-view painted backgrounds:
  warm ivory/brass Accord architecture and graphite/radiator-vane Swarm
  architecture. They are images, not traversable 3D interiors. The distant
  exterior scenery in each image is decorative, not live traffic.
- `main/ui/station_console/` contains deterministic nine-slice surfaces and
  service icons. Regenerate with `python tools/build_station_console_art.py`.
  Barlow Medium and its existing SIL OFL attribution remain in `main/ui/station`.
- `assets/materials/station_console/` adds warm key, cool fill, specular and rim
  lighting only for the overview ship draw. It reuses original geometry,
  normals, UVs and albedo. It adds no normal map, cast shadow, reflection probe
  or bloom. Flight rendering retains its existing material behavior.
- `main/ui/station_pose.lua` selects the off-world preview rig for a slow
  six-degree-per-second turn beginning at 65 degrees. The overview camera sits
  below the ship and looks upward from the hangar floor, retaining the fitted
  distance for each hull. Other previews retain
  their original rotation. The renderer clears this state and the custom
  viewport when the overview closes or a detail modal takes over.

The ship is still the base hull, explicitly identified under the preview;
the livery catalog retains its original thumbnails. Original fleet models,
textures, skins, gameplay sizes, prices, unlocks, hardpoint IDs, input handling,
account persistence and server contracts are unchanged. The console was
originally based independently on master `6d1f0a5`.
On 2026-10-14 it was reconciled with upstream `663bd2e`, which includes merged
PRs 22, 23 and 24. The shared renderer retains both the upstream space passes
and the docked ship override. `game.project` and its texture-profile selection
match upstream unchanged.

## Offline review

Build using Defold 1.13.1 Bob, with an external bundle directory:

```
java -jar bob.jar --platform wasm-web --variant debug --archive --settings tests/station_preview/preview.ini --bundle-output ../station-review resolve build bundle
python tools/prepare_station_preview.py "../station-review/Station UI Review/index.html"
python -m http.server 8494 --bind 127.0.0.1 --directory ../station-review
```

Open `/Station%20UI%20Review/index.html`. The collapsible offline review controls
select either faction and any of the 12 class/role hulls. Wait for the visible
`Viewing: faction / hull` acknowledgement before capturing a frame. The helper
fingerprints the archive index to avoid stale browser resources after builds.
It also matches the launcher to the emitted WASM engine name, because Bob may
reuse a launcher with the full-game title when alternating builds. It is safe
to run again after each bundle, which replaces the generated HTML.

The fixture disables assignments/outpost requests, account/logout navigation
and profile flush. Purchases use disposable sample funds. Non-starter hulls
begin with the starter modules as spares, avoiding fabricated hardpoints.
Undock exercises the countdown/cooldown and returns to the review station.
The fixture and its HTML controls are not production bootstrap content.

For full-game integration compilation, omit `--settings` and use another
external bundle directory. Run `tests/station_console_harness.lua` in Lua 5.1,
along with the launch-cooldown, ship-price, flight-HUD, throttle, flight-speed
and starfield harnesses. Execute from the repository root.

## Validation and cost, 2026-10-13

Full-game and isolated HTML5 builds passed with Defold 1.13.1. The seven Lua 5.1
harnesses pass, including repeated faction/tab changes, bounded node allocation,
readiness/XP values, long text, zero-capacity slots, selected-rig rotation and
render-message cleanup for detail/launch transitions.

Native browser review at 1280 x 720 covered both factions and all five tabs,
module drag/install with sample currency, ship-detail cancellation, livery
purchase detail/cancellation and launch countdown/return. Hero framing was
checked across Patrol, Escort and Frigate hulls, including Sardine, Moray,
Manta Ray, Falcon and Harpy Eagle. Screenshots in `artifacts/station-console/`
are native Defold output, not concept renders. Runtime logs reported no new
warnings or errors during these checks.

The 17 new source PNGs total 5,151,017 bytes (4.91 MiB). The two compiled
texture resources total 20,971,618 bytes (20 MiB plus headers) with this
desktop HTML5 build's default texture settings. This is compiled resource size,
not a measured download delta or GPU allocation. The overview reuses one ship
preview draw and adds no ship geometry. Both faction plates share one atlas;
they are loaded together. Low-end/mobile GPU memory and frame timing, touch
input, live multiplayer and account persistence remain untested.

## Artwork provenance

The user supplied BSGO station overlays and a Rogue Skies screenshot as mood
and readability references. An original Accord console concept was generated,
reviewed and approved before implementation. Two empty hangar plates were then
generated with ImageGen on 2026-10-13 using that approved concept as reference.
They contain no baked UI or hero ship. The Swarm variant uses the established
machine-crown/radiator-vane faction direction. The runtime plates are the
checked-in authoring deliverables; no proprietary game art or code was extracted.

The intended generation brief was a detailed fixed-camera industrial hangar,
clear central berth for a separately rendered ship, warm practical lighting
balanced by cool space light, with all controls, text and foreground ship
removed. Accord retains ivory/navy/brass structural character; Swarm replaces
that character with graphite ribs and layered radiator vanes. The exact source
image dimensions and SHA-256 hashes are recorded in `artifacts/station-console/assets.json`.
Panel surfaces and icons are code-authored in the deterministic Python tool.

## Approved faction insignias

The dossier uses the user-supplied fish insignia for Accord and bird insignia
for Swarm. Both transparent 1254 x 1254 originals are preserved byte-for-byte
under `artifacts/faction-logos/`, with source hashes in `manifest.json`.
`main/ui/faction_logos/` contains 256 x 256 runtime imports, retaining the
original square aspect, artwork, colors and transparency. The logo is drawn
without tint and switches with the faction. These replace the generic orbital
placeholder; the decorative orbital asset remains available but unused here.
The separate logo atlas adds 2,097,201 bytes (about 2 MiB) of compiled texture resource with the current HTML5 settings. The original high-resolution copies are documentation assets and are not referenced by the runtime.


## Upstream reconciliation, 2026-10-14

Upstream `663bd2e56aa6fb13a7b2d0c6c90664c7da79bd19` merged into the PR
branch without textual conflicts. Both full-game and isolated station HTML5
bundles passed with Defold 1.13.1. Thirteen Lua 5.1 harnesses passed:
station console, space, space wisps, station exteriors, launch cooldown,
ship prices, flight HUD, throttle, speed, camera, starfield, asteroid script
and asteroid hub. `git diff --check` passed.

Native 1280 x 720 browser smoke review confirmed both faction backgrounds,
approved insignias and lit ship previews, plus the Swarm launch countdown
and return to the station. No new warnings or errors appeared after correcting
the offline launcher filename. The full interaction matrix above was performed
on 2026-10-13; live gameplay and account testing were not repeated here.
