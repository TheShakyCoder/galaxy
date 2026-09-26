# Sardine model upgrade

Review build, 2026-09-26. Starting repository: `TheShakyCoder/galaxy`,
`master` at `743c2ee`. This package is prepared for pull-request review;
no deployment or live-server changes are included.

## Result

The original fish silhouette is rebuilt as a smooth, detailed small spacecraft:
blue-green back, silver flanks, scale-like engraved armor, sardine spots, round
optical eyes, a single curved gill cover, a conformal cockpit, small rayed fins,
and compact twin tail thrusters. The tail now has equal **vertical** lobes, as a
fish does. The face has no shark-style brow or gill slits.

Anatomical/color reference: [NOAA Pacific sardine](https://www.fisheries.noaa.gov/species/pacific-sardine).
Reference was used for features, not copied artwork. All geometry and texture art
are generated locally by the project script.

| Asset | Before | After |
|---|---:|---:|
| Triangles | 106 | 14,252 |
| Exported vertices | 186 | 9,742 |
| Base-color image | 3 x 1 | 1024 x 1024 |
| GLB size | 11,288 bytes | 443,080 bytes |
| Total length | 16.2 m | 16.2 m |
| Mesh/material count | 1 / 1 | 1 / 1 |

The GLB remains self-contained. Its external Defold texture uses the existing
`sardine_palette.png` filename, now containing the detail atlas. The mesh has
explicit normals, 16-bit indices and a single texture/material. No custom shader
or additional runtime dependency was added. Cyan details are painted colors,
not an unimplemented emission effect.

## Integration and scope

- Existing model path is unchanged, so the player, remote ship, and hangar
  instances still reference the same asset. Nose remains +Z; origin is unchanged.
- The square hangar preview camera was moved back to keep the entire model in
  view throughout rotation. The sale-grid preview shares that camera.
- The generator rebuilds the separate Sardine top-down image at 520 x 1280 from
  the actual mesh with a depth buffer. The existing generic fitting schematic
  still uses `patrol_interceptor.atlas`; its layout and module slots were not
  changed by this model upgrade.
- `ships.lua` descriptive comments were updated to match the delivered asset.
- Baseline GLB and palette copies are included here for visual comparison.

## Verification

`python tools/check_sardine_model.py` **PASS**. See `validation.json`.

Checks include GLB layout/buffer boundaries, finite geometry, unit normals,
triangle areas and winding, UV bounds, 16-bit limits, a 20k-triangle ceiling,
embedded/external texture identity, image transparency and margins, game asset
references, and byte-identical regeneration of all three generated outputs.

The checker projects every vertex at 120 yaw angles through the actual 45-degree
square hangar camera: maximum absolute NDC coordinate 0.922 (inside the frame).
The grid preview is wider than the tested square. This is a mathematical framing
check, not a runtime screenshot.

Blender 4.3.2 imported the final GLB and rendered front three-quarter, true side,
top and rear three-quarter views. Reviewed all four images. Studio rendering uses
the shipped base-color material without added metallic or emission effects;
it is not a screenshot of the Defold game.

The first geometry check caught a tube-frame discontinuity in curved trim.
Continuous frame transport fixed it; the final winding check passes.

**Not tested:** Defold runtime rendering, browser/mobile performance, and live
multiplayer. Actual engine lighting may differ from the studio renders. The
larger mesh needs a multi-ship performance check before release.

## Rebuild

Requires Python, Pillow and NumPy. Rendering additionally requires Blender.

```text
python tools/build_sardine_model.py
python tools/check_sardine_model.py
blender --background --python tools/render_sardine_review.py
```

Use `--output-root PATH` with the generator to stage outputs elsewhere. The
checker uses this mode to regenerate assets and compare them byte for byte.

## Deviations

- The old horizontal tail was changed to a vertical fork for fish anatomy.
- The hangar camera was adjusted after checking the square rotating preview.
- No other deviations from the approved reshape/detail scope.
