# Galaxy: eight-theme expansion

This library adds eight collections for the 24 existing ships. Original fleet
files and the four earlier cosmetic collections are preserved. Each completed
sprint has a separate catalog, preview and verification report.

| Sprint | Collections | Preview |
|---|---|---|
| 1 | Porcelain Dynasty, Starlight, Grand Prix | [72 variants](sprint-1.html) |
| 2 | Abyssal, Crystalborn | [48 variants](sprint-2.html) |
| 3 | Corsair, Overgrown | [48 variants](sprint-3.html) |
| 4 | Toybox | [24 variants](sprint-4.html) |

[Browse all 192 variants](index.html). Corsair fish use triangle insignias;
Corsair birds use circle insignias, both as painted markings and raised badges.

See [sprint records](SPRINTS.md) for completed gates and review decisions.
Model and texture downloads are available from the preview cards. All previews
are Blender renders of the actual exported assets using the embedded base-color
texture. No painted-over concepts or preview-only glow/transparency are used.

Surface variants retain original positions, normals and triangles, with UVs
remapped only on copies of decorative fin/feather panels. Model variants retain
the original hull and add theme geometry. Their own `.model` resources reference
their corresponding GLBs and 1024px atlases; no existing game resources are
replaced or automatically equipped. These are optional assets for a future shop,
not a purchase/ownership/equip implementation.

Added details are static. The existing opaque material is used: bright nodes,
stars and crystals are painted/pearl-like or faceted surfaces, not emission,
transparency, refraction, moving gears or physics. Runtime appearance, Defold
compilation, performance, multiplayer skin synchronization and mobile rendering
remain to be tested during integration.

```text
python tools/build_theme_library.py --sprint 1
blender --background --python tools/render_theme_review.py -- --catalog assets/themes/catalog-sprint-1.json
python tools/build_theme_sheets.py --sprint 1
python tools/check_theme_library.py --sprint 1 --rebuild --renders
python tools/build_theme_gallery.py --sprint 1
```

The build supports `--ship`, `--theme` and `--output-root`. Sprint catalogs are
separate; a partial build never overwrites the combined catalog. Python requires
Pillow and NumPy; Blender 4.3.2 was used for review renders.
