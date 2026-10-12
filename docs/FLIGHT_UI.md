# Flight command UI

Native Defold GUI with a clear central flight area, live hull/power tracks, compact
equipment rows and restrained cyan instruments. Slots retain their original IDs,
icons, modifier-key indicators, click actions and cooldowns. Basic hulls still show
locked advanced slots. Radar orientation, sensor range and selected-target logic
are unchanged.

## Tuning

Edit `main/flight_hud.gui` in Defold for panel positions, colors and text scale.
`main/ui/flight_layout.lua` owns equipment spacing and gauge dimensions. The font
uses Defold's bundled Vera Mono at 32 px with distance-field rendering; no external
font asset is required. Presentation does not change ship stats or network traffic.

Equipment is grouped Weapons / Computers / Engines / Hull, numerically within each
group, in balanced rows of at most 12. Empty and locked slots remain visible.
Hull/power fills clamp to [0,1]; zero or missing capacity gives an empty track.

## Verify

Run `luajit tests/flight_hud_harness.lua` (or Lua 5.1 with this project on package.path).
The harness covers ship-relative radar, selected-target restoration, telemetry,
all roster slot layouts, cooldown plumbing and click passthrough.

Compile the complete game using the project's normal Defold build. For the isolated
review, using Defold 1.13.1 Bob:

```
java -jar bob.jar --platform wasm-web --variant debug --archive --settings tests/flight_preview/preview.ini --bundle-output ../flight-review resolve build bundle
python tools/prepare_flight_preview.py "../flight-review/Flight UI Review/index.html"
python -m http.server 8490 --bind 127.0.0.1 --directory ../flight-review
```

Open `/Flight%20UI%20Review/index.html`. The collapsible review controls exercise
Patrol/Escort/Frigate slot layouts, low vitals, docking and clearing target state.
The Sardine is a fixed scene model; the class buttons test equipment layouts.
All telemetry is deliberately synthetic. The preview collection does not load
the login flow, network module or profile persistence and cannot spend live funds.
Its bootstrap override is supplied only to Bob; production game.project is unchanged.

This PR only changes the flight UI. Station UI and ship graphics are independent.
Live multiplayer and low-end GPU performance require a separate integration pass.
