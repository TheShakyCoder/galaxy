# Station command UI

Native Defold station presentation: pilot dossier, rotating base-hull preview,
fitting readiness and assignment summary, with a consistent command bar for
Fitting, Hangar, Sector Map and Liveries. Rounded nine-slice panels and bundled
Barlow Medium replace the dense monospace presentation. The font's SIL OFL and
source attribution are included in main/ui/station.

Gameplay prices, unlock levels, hardpoint IDs, inventory operations, livery
ownership and network/profile contracts are unchanged. The overview preview
shows the base hull; its caption explicitly identifies that. Existing livery
thumbnails remain the shop's cosmetic previews. Model assets and flight HUD
are delivered independently.

## Tuning

Edit main/outpost.gui for authored panels and text. main/outpost.gui_script
owns generated cards, hardpoint placement and live text. The new overview
uses the existing off-world preview rigs and render messages; no new render
target or renderer dependency is introduced. Confirm dialogs are ordered above
dynamic hardpoint nodes. Overview previews are hidden during confirmation and
when changing tabs or launching.

## Offline review

Build with Defold 1.13.1 Bob:

```
java -jar bob.jar --platform wasm-web --variant debug --archive --settings tests/station_preview/preview.ini --bundle-output ../station-review resolve build bundle
python tools/prepare_station_preview.py "../station-review/Station UI Review/index.html"
python -m http.server 8490 --bind 127.0.0.1 --directory ../station-review
```

Open /Station%20UI%20Review/index.html. Expand the offline review controls to
switch between Accord and Swarm fixtures. Purchases and inventory changes use
temporary sample funds, never an account. The preview overrides assignments,
outpost fetch, account/logout and profile flush; production bootstrap and
configuration are unchanged. Undocking returns to the review station and
exercises the normal docking cooldown.

Check all five tabs, drag an Armor Plating card to a green hull slot, confirm
and cancel purchases, inspect a ship, equip a recolor, and launch. Build the
normal game without --settings for integration compilation. Live multiplayer,
account persistence, touch input and low-end GPU performance need separate QA.

## Verified on 2026-10-12

Full-game and isolated HTML5 builds passed with Defold 1.13.1. Native preview
interaction was checked in the browser at 1280 x 720.
Both factions, all five tabs, module drag/install with sample currency, ship
detail cancellation and the launch countdown/return path were checked. The
livery shop and purchase detail rendered correctly. Live account persistence
was deliberately excluded from the offline fixture.
