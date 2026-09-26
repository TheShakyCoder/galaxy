# Fleet cosmetic assets

This is an optional art library for the 24 ships already in Galaxy. It contains
**72 paint variants** (three per ship) and **24 Clockwork model variants** (one
per ship). The default models and gameplay are unchanged.

Start with [`catalog.json`](catalog.json). Every entry has a stable ID such as
`sardine.aurora` or `harpy_eagle.clockwork`, a species/faction/class/role mapping,
paths to its `.model`, PNG and portable GLB, source and output hashes, bounds,
triangle counts, a thumbnail path and suggested hangar-camera values.

The full visual gallery is [`artifacts/cosmetics/index.html`](../../artifacts/cosmetics/index.html).
See the [delivery and verification report](../../artifacts/cosmetics/README.md)
for previews, design details and outstanding runtime checks.

## Collections

| ID | Collection | Treatment | Per ship |
|---|---|---|---|
| `aurora` | Aurora | Teal, mint, glacial blue | Recolor |
| `solar_regatta` | Solar Regatta | Crimson, ivory, amber | Recolor |
| `royal_amethyst` | Royal Amethyst | Plum, lavender, champagne gold | Recolor |
| `clockwork` | Clockwork | Brass, copper, verdigris/iron, canvas tones | New geometry + texture |

## Resource layout and integration boundary

Each `assets/cosmetics/<species>/<collection>/` directory contains:

- `albedo.png`: a 1024 x 1024 RGB base-color atlas using the original UV layout.
- `model.glb`: a portable single-mesh model with that atlas embedded.
- `ship.model`: a Defold model resource using the existing built-in material.

For **recolors**, `ship.model` deliberately references the original fleet GLB
and the variant PNG, so authored Defold resources share the original geometry.
The nearby recolored GLB is a portable review/export copy, with identical vertex,
normal, UV and index data. There is no reason to load those extra geometry copies
when using the provided Defold resource arrangement.

For **Clockwork**, `ship.model` references its own GLB because it contains added
geometry. It retains the original model origin, scale and +Z nose direction.
All original vertices and triangles remain intact. The boiler straps, gears,
gauges, pipes and wing linkages are static mesh detail, not an animation rig.

These resources are **not automatically equipped or registered in the game**.
There is no store UI, pricing, entitlement storage, purchase handling, loadout
selection, dynamic factory loading or network skin synchronization in this pass.
The JSON is an asset catalog, not a database migration or purchase contract.
The thumbnails are review JPEGs; they are not registered in a Defold GUI atlas.

A future shop can use the stable IDs as its asset lookup and add its own commerce
and ownership data. Keep those concerns separate from the build-generated file.
The existing 24 model IDs do not automatically accept these additional paths:
the game's preview/factory/equip paths need explicit integration when the shop
is built. Copy the catalog camera framing when adding preview entries; merely
merging this library does not change the ships players currently see.

Do an in-engine material, framing and crowded-scene performance review before
enabling cosmetics. The studio previews are not a Defold rendering guarantee.

## Rebuild

Requires Python, Pillow and NumPy for validation. From the repository root:

```text
python tools/build_cosmetic_library.py
python tools/check_cosmetic_library.py --rebuild
```

Use `--part recolors` or `--part clockwork` to build one part; `--ship sardine`
to restrict a build; and `--output-root <directory>` to stage elsewhere. Partial
builds write a separately named catalog and never overwrite the complete catalog.
Partial builds refresh only their selected assets; run the full build to refresh
the master catalog before shipping those edits.
