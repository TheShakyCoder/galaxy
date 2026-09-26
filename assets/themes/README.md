# Optional fleet themes

Each collection is delivered in its own pull request with 24 variants: 12 Accord
fish and 12 Swarm birds. Select any subset. Each catalog is named
`catalog-<theme>.json`; resources live in `<ship>/<theme>/`. The shared theme
tools are identical across collection PRs, allowing them to merge in any order.

Merge the Moray symmetry PR (#5), then the native fleet sizing PR (#6), before
these collections. Their source hull hashes target the straight Moray and the
1:4:16 Patrol/Escort/Frigate proportions. Theme PRs only add resources and tools;
they do not replace the default models or existing cosmetics. No gameplay stats,
shop, ownership, equip flow or networking changes are included.

Each entry includes its resource paths, source and output hashes, geometry
counts, dimensions, camera framing and preview image. The base hull positions,
normals and triangles are preserved exactly; decorative themes append geometry.
Body UVs remain unchanged. Panel swatches are remapped on the optional copy.
Textures are authored opaque base color; bright details are not real lights or
emissive shaders, and attachments are static.

Review `artifacts/themes/<theme>.html`, the per-theme Markdown notes, actual-model
renders and `validation-<theme>.json`. Studio images normalize size to show detail;
`artifacts/scale/index.html` compares native sizes.

```text
python tools/build_theme_library.py --theme porcelain_dynasty
python tools/check_theme_library.py --theme porcelain_dynasty --rebuild --renders
python tools/build_theme_gallery.py --theme porcelain_dynasty
python tools/build_theme_sheets.py --theme porcelain_dynasty
blender --background --python tools/render_theme_review.py -- --catalog assets/themes/catalog-porcelain_dynasty.json
```

Replace the key with an installed collection. Python requires NumPy and Pillow;
rendering requires Blender. The build command requires an explicit theme to avoid
generating unwanted collections. Each collection includes its own standalone
catalog and gallery rather than changing a shared catalog or preview page.

Defold runtime, mobile performance and shop/equip/multiplayer integration remain
untested. These are optional art resources for later game integration.
