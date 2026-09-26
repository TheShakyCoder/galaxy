# Native fleet-size revision

The user requested unchanged Patrols, Escorts four times their corresponding
Patrol, and Frigates four times their Escort. This implementation uses the
repository's established size measure: the longest model dimension (length or
wingspan). Every axis is uniformly scaled, preserving proportions. The factor
is a linear size ratio, not volume. Pairings use the same faction and role.

| Class | Ratio to Patrol | Maximum dimension |
|---|---|---|
| Patrol | 1 | 15–17m, unchanged |
| Escort | 4 | 60–68m |
| Frigate | 16 | 240–272m |

The Moray has the separately requested straight, symmetrical hull and is now
60m as the Escort paired with the 15m Piranha. All 288 cosmetic variants use
the corresponding source size, including the earlier recolors and Clockwork.
Cosmetic protrusions retain their original proportions relative to each hull;
the exact class ratio describes the base ships, not optional ornament bounds.

Local ships and remote-player factories reference the same native model files.
Local model instance scales are 1,1,1; known remote ship factories receive no
scale override. Resizing the native GLBs therefore applies to both paths.
Generated flight/hangar cameras and far planes have been refitted to actual
bounds. Gameplay stats, speed, module slots, weapons, IDs, network code and
textures are unchanged. The shared Escort Assault camera also frames Goshawk.

## Verification

`check_fleet_scale.py` checks all 24 class ratios from exported vertex positions.
All 104 Patrol GLBs (8 defaults plus 96 cosmetic models) are byte-identical to
the preceding Moray checkpoint. The 208 larger GLBs have the same triangle
indices and textures; their positions match uniform scale to 0.0002m, normals
to 0.00001 and UVs to 0.000001. This includes all decorative attachments.
The checker also guards Patrol catalog entries and limits game-code changes
to generated cameras. Existing fleet, cosmetics and theme validators cover
geometry, full-rotation camera framing, flight framing and bytewise rebuilds.
The separate Moray symmetry gate checks its base and all twelve skins.

`index.html` shows eight newly rendered faction/role trios using a shared
orthographic camera and native dimensions, with no per-model normalization.
All eight common-scale images were visually reviewed. The regular detail
galleries retain their normalized renders: the uniform-scaling gate establishes
that those appearances remain valid. Moray detail renders were regenerated
after its shape change. Fleet dimension labels and size bars are updated.

The requested 4x multiplier is the user's art direction. The BSGO Fandom
[Line Ships page](https://bsgo.fandom.com/wiki/Line_Ships) describes relative
classes but did not establish an exact universal 4x geometry ratio.

Defold compilation/runtime, live multiplayer and device performance were not
tested. No deployment or merge was performed. No scope deviations.

```text
python tools/build_fleet_models.py
python tools/integrate_fleet_models.py
python tools/build_cosmetic_library.py
python tools/build_theme_library.py
# Regenerate all four sprint catalogs with --sprint 1 through --sprint 4.
python tools/check_fleet_scale.py
python tools/check_moray_revision.py
python tools/check_fleet_models.py --rebuild
python tools/check_cosmetic_library.py --rebuild
python tools/check_theme_library.py --rebuild --renders
blender --background --python tools/render_fleet_scale.py
python tools/build_fleet_scale_gallery.py
```
