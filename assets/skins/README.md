# Ship skins

Optional paint and model variants for the 24 ships in Galaxy: twelve collections
per ship, 288 skins in all. A player buys one skin for one ship, so each skin has
a stable ID `<ship>.<collection>` (for example `sardine.starlight`) that maps to
`assets/skins/<ship>/<collection>/`.

Escorts and Frigates, including all skins, follow native 1:4:16 sizing and Moray
is straight and symmetrical. See `artifacts/scale/README.md` and
`artifacts/moray/README.md`.

## Layout

```text
assets/skins/
  catalog.json          merged manifest of every skin (generated)
  catalogs/             per-library build outputs
    cosmetics.json      tools/build_cosmetic_library.py
    themes.json         tools/build_theme_library.py
    themes-sprint-N.json
  <ship>/<collection>/
    ship.model          Defold model resource
    albedo.png          1024 x 1024 base-color atlas
    model.glb           portable GLB with the atlas embedded
    ship.go             game object wrapping ship.model (generated)
```

Defold only bundles resources that the game references. Review-only files in
these folders, such as the recolor `model.glb`s, don't add to the build.

Don't edit `catalog.json`, `ship.go`, `main/skin_hub.go`,
`main/data/skins.lua`, `main/data/skin_collections.lua` or the images in
`main/images/skins/` and `main/images/skin_textures/` by hand. Regenerate them after any library build:

```text
python tools/build_skin_index.py
```

## Collections

| ID | Collection | Library | Treatment | Kind |
|---|---|---|---|---|
| `aurora` | Aurora | cosmetics | Teal, mint, glacial blue | Recolor |
| `solar_regatta` | Solar Regatta | cosmetics | Crimson, ivory, amber | Recolor |
| `royal_amethyst` | Royal Amethyst | cosmetics | Plum, lavender, champagne gold | Recolor |
| `clockwork` | Clockwork | cosmetics | Brass, copper, verdigris/iron, canvas | New geometry |
| `porcelain_dynasty` | Porcelain Dynasty | themes | Ivory ceramic, cobalt florals, gold seams | Surface |
| `starlight` | Starlight | themes | Midnight constellations and silver detail | Surface |
| `grand_prix` | Grand Prix | themes | Numbered racing panels and checkerboards | Surface |
| `abyssal` | Abyssal | themes | Pearl lenses, photophore chains, sensory tendrils | Sculpted |
| `crystalborn` | Crystalborn | themes | Amethyst panels and raised mint-quartz crystals | Sculpted |
| `corsair` | Corsair | themes | Timber, canvas, rope, portholes, cannon housings | Sculpted |
| `overgrown` | Overgrown | themes | Coral/barnacles on fish; leaves/blossoms on birds | Sculpted |
| `toybox` | Toybox | themes | Painted tin, fasteners, decorative axles, wind-up key | Sculpted |

Corsair Accord fish carry **triangle** insignias and Swarm birds carry **circle**
insignias. The catalog records this as `insignia`.

## Geometry rules

- **Recolors** reference the original fleet GLB from `ship.model` and only swap
  the texture. Their local `model.glb` is a review/export copy with identical
  vertex, normal, UV and index data.
- **Clockwork** and all **themes** reference their own `model.glb`.
  - Surface themes keep original vertex positions, normals and indices. Only the
    UVs on decorative fin/feather panels are remapped.
  - Sculpted themes and Clockwork keep all original geometry and add static
    decorative parts.
- Every variant keeps the original origin, scale and +Z nose direction. No added
  part is a functional weapon, engine, collider or hardpoint, and nothing is
  animated. Bright details are opaque paint, with no emission or transparency.

## Integration

Every catalog entry records its ship, faction, size and role, plus its resource
paths, source hashes, bounds and a suggested preview camera (`preview`). Look up
a skin by its ID and fall back to the ship's default `faction_skins` model when a
skin is missing or not owned.

`catalog.json` is an asset manifest, not a commerce contract. Prices live in
`main/data/skin_prices.lua`; ownership and equip state in `main/session.lua`;
the outpost's Skins tab is in `main/outpost.gui_script`.

In flight (`main/skin_flight.lua`), for your ship and other players' ships:

| Kind | How it's shown | Bundled data |
|---|---|---|
| Recolor | Texture swap on the ship's own model | `main/images/skin_textures/` (~3 MB) |
| Surface | Skin's own model, spawned from `main/skin_hub.go` | Meshes + textures (~9 MB compressed in the web archive) |
| Sculpted, Clockwork | Default model | Not bundled; waits for Live Update |

Each player sends their equipped skin ID with their position (`main/network.lua`).
Receivers only show it if it matches that player's ship and faction.

Do an in-engine material, framing and crowded-scene performance review before
enabling skins. The studio previews don't guarantee how Defold will render them.

## Rebuild and review

Requires Python, Pillow and NumPy. From the repository root:

```text
python tools/build_cosmetic_library.py
python tools/check_cosmetic_library.py --rebuild
python tools/build_theme_library.py
python tools/check_theme_library.py --rebuild --renders
python tools/build_skin_index.py
```

- Cosmetics: use `--part recolors|clockwork` or `--ship <slug>` for a partial
  build. Partial builds write a separately named catalog.
- Themes: use `--sprint N` on the build, check, sheet and gallery commands for a
  bounded checkpoint.
- Review renders need Blender 4.3.2 (`tools/render_cosmetic_review.py` and
  `tools/render_theme_review.py`). Galleries are in `artifacts/cosmetics/` and
  `artifacts/themes/`. Serve them from the repository root over HTTP.
