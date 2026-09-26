# Optional fleet themes

Eight collections for all 24 ships: 192 additional variants. Existing models,
textures, scripts and the earlier cosmetic library remain unchanged.

| Collection | Treatment | Sprint |
|---|---|---|
| Porcelain Dynasty | Ivory ceramic, cobalt florals, gold seams | 1 |
| Starlight | Midnight constellations and silver detail | 1 |
| Grand Prix | Numbered racing panels and checkerboards | 1 |
| Abyssal | Pearl lenses, photophore chains, sensory tendrils | 2 |
| Crystalborn | Amethyst panels and raised mint-quartz crystals | 2 |
| Corsair | Timber, canvas, rope, portholes and cannon housings | 3 |
| Overgrown | Coral/barnacles on fish; leaves/blossoms on birds | 3 |
| Toybox | Painted tin, fasteners, decorative axles, wind-up key | 4 |

The Corsair Accord fish have **triangle** insignias; Swarm birds have **circle**
insignias. The catalog records `insignia`, and both textures and meshes carry it.

## Resource contract

`catalog.json` is the combined manifest. `catalog-sprint-N.json` files provide
bounded checkpoints. Entries use stable IDs such as `sardine.starlight` and
record source hashes, metadata, resource paths, bounds and review camera offsets.
Each variant has a self-contained GLB (one mesh, one opaque material, embedded
1024 x 1024 PNG), matching external `albedo.png`, and a Defold `ship.model`.
The descriptor references that variant's own mesh and texture.

Surface variants preserve original vertex positions, normals and indices. Only
copy UVs on decorative fin/feather panels are remapped to the themed atlas.
Sculpted variants retain all original geometry and append decorative components.
Patrol/Escort/Frigate scale, axes, origin, faction and role metadata are retained.
No authored attachment is a functional weapon, engine, collider or hardpoint.

These resources are opt-in. Integration should resolve the selected catalog ID
to its `model` or `glb` and `texture` as appropriate for the game's loader. Supply
a default-fleet fallback for unavailable cosmetic IDs. Pricing, purchase flow,
ownership checks, equip persistence and multiplayer synchronization are not
implemented here; no gameplay scripts or factories are changed by this library.

## Review and limitations

Open `artifacts/themes/index.html` through a local repository-root HTTP server.
Each ship has downloads, original comparison, and three views for sculpted
collections. Studio views are normalized for detail; source game dimensions
remain intact. The preview uses the actual GLBs and their embedded textures.

All details are static. Bright nodes and crystals use opaque base-color paint;
there is no emission, transparency, refraction or mechanical animation. Defold
compilation/runtime, device performance and integration remain untested.
See `artifacts/themes/SPRINTS.md` and validation JSON files for actual checks.

Build: `python tools/build_theme_library.py` (Pillow required).
Verify: `python tools/check_theme_library.py --rebuild --renders` (NumPy/Pillow).
Review renders: Blender 4.3.2 with `tools/render_theme_review.py`.
Then run `tools/build_theme_sheets.py` and `tools/build_theme_gallery.py`.
Use `--sprint N` on build/check/sheet/gallery commands for a bounded checkpoint.
