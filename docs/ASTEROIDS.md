# Procedural asteroids

Each asteroid now owns a seeded rock mesh generated at spawn time, with an
irregular silhouette, nine overlapping crater depressions, rough surface detail,
smooth surface normals and subtle stone colour variation. The same system ID and
field index produce the same rock after a jump or respawn. No global random state
or server field data is changed.

When the existing server state marks a rock unavailable, the hub immediately
removes it from the targeting registry and sends `disintegrate` to its script.
Twenty closed fragments of that exact mesh separate over the first 0.32 seconds,
drift outward and tumble. They shrink and dissolve from 1.1 seconds, and the object
is deleted at 2 seconds. Repeated messages cannot restart the effect. Jumping
systems removes remaining debris immediately. Cached depleted rocks are skipped
on entry, avoiding a spurious explosion when revisiting a field.

Resource scans still animate `#model.tint`; `model` is now a mesh component on
asteroids only. The old sphere model and its generator remain in place because
`main/shot.go` uses them for tracers. Targeting radii, positions, mining rewards,
damage, respawn rules, network protocol and server modules are unchanged.

## Implementation and cost

- `main/asteroid_geometry.lua`: engine-independent generator, local integer PRNG,
  shared subdivision topology. Each rock stays within radius 0.5 before applying
  the existing `diameter_m` scale.
- `main/asteroid.script`: owns one unique buffer resource; detaches and releases
  it on deletion. Buffer bounds expand during breakup to prevent fragment culling.
- `assets/models/asteroids/rock.*`: local-space mesh and shaders using the existing
  `model` render predicate. Camera-relative lighting keeps the surface readable.
  Opaque screen-door dissolution needs no new transparent render pass.
- 1,280 exterior triangles plus 480 fracture-wall triangles per rock; 5,280
  non-indexed vertices, 18 floats each (~371 KiB per mesh; ~18.1 MiB for 50).
  Generation and upload happen once per spawn. Breakup moves fragments in the
  vertex shader; each active effect updates just one uniform per frame. There are
  no extra fragment game objects or physics bodies.
- `[mesh] max_count = 256` provides room for the default 50-rock field, pending
  deletion during jumps and concurrent debris. Larger custom fields need a
  corresponding capacity/performance review.

The mesh/resource implementation follows the [Defold mesh manual](https://defold.com/manuals/mesh/)
and [resource API](https://defold.com/ref/resource/). Defold 1.13.1 is the version
pinned by this repository's Dockerfile.

## Reproduce validation

Install `lupa` into a disposable Python environment, then from the repo root:

```sh
python tests/test_asteroids.py -v
java -jar /path/to/bob.jar --platform wasm-web --architectures wasm-web resolve build
```

The tests execute the generator and scripts in Lua 5.1. They check 50 unique and
repeatable rocks, finite data, unit normals, bounds, non-degenerate triangles,
outward exterior winding, watertight correctly oriented fragments, independent
random state, depletion/scan/respawn/jump integration, duplicate events, exact
two-second lifetime and buffer release. Engine APIs in lifecycle tests are mocks;
these complement the actual compiled demo below.

## Standalone visual review (no login or live game server)

```sh
java -jar /path/to/bob.jar --platform wasm-web --architectures wasm-web --variant debug --settings tests/asteroid_preview/preview.ini --output build/asteroid-preview --bundle-output /path/outside/build/asteroid-preview --archive resolve build bundle
python tools/prepare_asteroid_preview.py /path/outside/build/asteroid-preview
python -m http.server 8037 --directory /path/outside/build/asteroid-preview
```

Open `http://localhost:8037/Asteroid%20Review/index.html`. Use the labelled buttons,
or click the canvas to use the keyboard controls.
This runs the actual game component, Lua generator, and shaders with six rocks.

| Key | Action |
| --- | --- |
| Space | Break all six rocks with the real two-second lifecycle |
| R | Generate six new seeds |
| A | Toggle an eight-second automatic spawn/breakup cycle |
| 1 | Inspect intact rocks |
| 2 | Inspect shader breakup at 0.65 seconds |
| 3 | Inspect shader dissolution at 1.5 seconds |

The numbered inspection modes hold the shader time for visual review; Space uses
the real timed effect. The preview overrides bootstrap/render settings only for
that build. It never connects to Nakama or sends weapon/mining requests.

## Validation scope

Automated geometry and mocked lifecycle checks and the complete Galaxy HTML5
client build passed. In the actual standalone Defold HTML5 runtime, intact,
fractured and dissolving stages were visually inspected; the timed effect cleared
the scene and repeated spawn/destruction cycles ran without reported engine
errors. Review screenshots are in `artifacts/asteroids/`. Live multiplayer mining and mobile-device frame
time/memory testing remain separate acceptance checks before deployment.
