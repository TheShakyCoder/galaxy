# Eight-theme expansion: sprint plan and evidence

Baseline: merged cosmetic-library PR #3, upstream `b63ffcc`.
Scope: eight additional collections for all 24 existing species, 192 variants.
All original fleet resources and all four prior cosmetic collections stay intact.
Toybox uses the proposed painted-tin/wind-up interpretation; plush is not a ninth
collection. New paint treatments may remap copy-only fin UVs for actual decorative
surface detail. No base geometry or source UV files are overwritten.

| Sprint | Deliverable | Gate before advancing |
|---|---|---|
| 1 | Porcelain Dynasty, Starlight, Grand Prix: 72 surface variants | Geometry equality, texture/detail review, complete fleet renders, isolated rebuild |
| 2 | Abyssal and Crystalborn: 48 geometry variants | Retained species hulls, geometry/normals/bounds, three-angle review, rebuild and sprint-1 preservation |
| 3 | Corsair and Overgrown: 48 geometry variants | Attachment placement, distinct fish/bird treatment, three-angle review, rebuild and previous-sprint preservation |
| 4 | Toybox: 24 geometry variants; complete library/gallery | Wind-up silhouette review, all 192 variants, cross-sprint manifest/resources/gallery checks, original-file preservation |

Each gate is a builder verification, not a separate agent's independent review.
Defold runtime and shop/equip integration remain outside this art-library pass.
The existing base-color material is retained: bright accents are opaque painted
or pearl-like surfaces, not shader emission, transparency or refraction.

## Sprint results

### Sprint 1 — complete

72 surface variants built and rendered. All six faction contact sheets reviewed;
individual Sardine/Harpy Eagle/Manta Ray samples inspected before the full render.
Porcelain scrollwork and seams, Starlight constellations, and Grand Prix checker
panels/numbers are visible on actual hull/fin geometry. No mesh positions,
normals or triangles changed. Copy-only panel UV remapping is intentional.

Binary/resource checks and isolated rebuild passed. 8,640 preview rotations fit.
See `validation-sprint-1.json` for the gate results. No deviations.

### Sprint 2 — complete

48 Abyssal and Crystalborn variants built, with 144 renders. All twelve faction
and angle contact sheets reviewed. Enlarged the crystal clusters after the first
visual pass, refined their facet normals, then rerendered and revalidated all 48.
Binary/resource checks, 5,760 preview rotations, flight framing, isolated rebuild,
and preservation of Sprint 1 passed. See `validation-sprint-2.json`.
The Sprint 1 and Sprint 2 galleries provide separate review checkpoints.
No scope deviations.

### Sprint 4 — complete

24 Toybox variants built, with 72 renders and all six contact sheets reviewed.
The double-loop keys, slotted fasteners and decorative axles remain static and
clear of the animal heads. The isolated sprint rebuild and 2,880 preview poses
passed. See `validation-sprint-4.json`.

### Combined library gate — complete

All 192 variants rebuilt byte-for-byte in an isolated output directory. The
combined catalog exactly matches the four sprint catalogs. Binary geometry,
normals/winding, texture/resource references, original-hull equality, source and
previous-sprint hashes, 23,040 preview poses, original flight framing and all
432 render files passed. Meshes range from 9,076 to 22,580 triangles.
All 36 faction/angle contact sheets were visually reviewed across the sprints.
See `validation.json` for the combined binary gate.

Browser checks passed for all eight collection selectors, faction/size/species
filters, empty state, side/top views, original comparison and surface-view reset.
The combined gallery had no browser error/warning logs. All five galleries and
their linked resources were checked on disk (1,019 unique linked files), along
with every original-comparison render. Browser layout was inspected at the
normal desktop viewport; mobile/device testing was not performed.

This branch only adds files relative to its upstream merge base `b63ffcc`.
Upstream advanced to `63d8a53` during work with an unrelated Nakama configuration
fix; this art PR does not change that configuration. No originals or prior
cosmetics are replaced. No scope deviations. Defold runtime, device performance
and shop/equip integration remain untested and outside this art-library pass.

### Sprint 3 — complete

User specified **triangle insignias for Corsair fish** and **circle insignias for
Corsair birds**. Include matching texture markings and raised faction badges;
checked metadata plus rendered visibility before completing this sprint.

48 Corsair/Overgrown variants built, with 144 renders and twelve contact sheets
reviewed. Corrected repeated rope anchor samples after the winding check caught
a folded segment; rebuilt and rerendered. Broadened bird leaves and blossoms
after sample review. Fish coral gardens, bird vines, nautical hardware and the
requested faction marks retain the original species profiles.
Isolated rebuild, 5,760 preview poses, flight framing, binary/resource checks,
and previous-sprint preservation passed. See `validation-sprint-3.json`.
No scope deviations.
