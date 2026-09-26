# Review an optional collection

Open `<theme>.html` for the collection installed by its PR. The page compares all
24 ships with their originals and filters by faction, class and species. Surface
collections include perspective renders; sculpted collections include perspective,
side and top renders. Each image was rendered from the actual GLB and texture.
Normalized studio views show detail; see `../scale/index.html` for native sizes.

Each collection has `<theme>.md` notes and `validation-<theme>.json` results.
See `../../assets/themes/README.md` for rebuild commands and integration limits.
Merge Moray symmetry (#5), then fleet resizing (#6), before selecting theme PRs.
The collection PRs are independent of one another and preserve default resources.

Geometry, resource, source-hash, camera and deterministic rebuild checks cover
each collection. Render validation checks image integrity and dimensions; visual
review is a separate manual step. Defold runtime and gameplay are not tested.
