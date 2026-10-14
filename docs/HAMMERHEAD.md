# Hammerhead detail upgrade

Approved concept: `artifacts/hammerhead/approved-concept.png` (2026-10-14).
Future ship updates follow the user's one-ship-at-a-time workflow: concept,
approval, that ship's assets, then native game review. Do not regenerate the
whole fleet to make an individual ship adjustment.

The Hammerhead now has a tapered wing-shaped head, segmented cheek armor,
recessed optical eyes, cheek vents, a lower intake, five gill heat exchangers
per side, conformal body plates, fin mounting saddles and detailed twin engines.
The 2K atlas uses machined panel detail instead of the old fish-scale pattern.

The user's subsequent real-shark reference supersedes the concept's head shape:
a broad, thick root blends into the body and tapers to thin outer wings. Compact
upper-tip sensor eyes replace the large cylindrical end caps. The exported
outer head section is checked to be less than 40% of the root thickness.
The default menu thumbnail and fitting underlay are rendered from this GLB.

Only the Hammerhead HD mesh, atlas and menu images change. All other ship
outputs and the historical original Hammerhead sources are preserved. The
existing Aurora, Royal Amethyst and Solar Regatta recolors share the updated
mesh with their existing textures; separately sculpted cosmetics retain their
own authored models. Shader, lighting, ship statistics, module slots, collision
data, camera behavior and stations are unchanged.

## Reproduce

```
python tools/build_hammerhead_detail.py
python tools/check_hammerhead_detail.py
python tools/check_hd_fleet.py
blender --background --python tools/render_hammerhead_detail.py
```

The dedicated builder updates only Hammerhead's entry in the HD manifest. The
general HD builder dispatches Hammerhead to the same isolated geometry module.
The renderer updates only its two menu images and its fitting dimensions entry.

## Validation

- Independent exported-GLB validation: finite positions/normals/UVs, unit normals,
  outward winding, nondegenerate triangles, valid uint16 indices, embedded atlas
  equal to external texture, unchanged 272 m maximum dimension.
- Deterministic regeneration; other HD assets byte-identical. Existing fleet
  validator passes all 24 hulls, 72 recolor descriptors and preserved originals.
- Defold 1.13.1 full game and offline station preview WASM release builds pass.
- Native browser review: Hammerhead rotating overview from below, fitting
  underlay, fleet card; unchanged Swarm Harpy Eagle counterpart. No browser
  warnings/errors observed. Live accounts, multiplayer and fleet-scale
  performance have not been tested.

Cost: 43,203 vertices / 63,308 triangles versus 21,155 / 34,816 before. One
mesh/material draw remains; the 2K atlas size is unchanged. GLB grows from
1,196,484 to about 2.1 MB. This is an individual ship upgrade, not a fleet-wide
performance change.

Review renders use Blender studio lighting; native screenshots show the actual
game renderer. The approved concept is an art target, not an in-game capture.
