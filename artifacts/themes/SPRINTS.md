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

### Sprint 3 steering

User specified **triangle insignias for Corsair fish** and **circle insignias for
Corsair birds**. Include matching texture markings and raised faction badges;
check metadata plus rendered visibility before completing that sprint.
