# Starlight

Midnight enamel, authored constellations, silver edging and scattered starlight.

This optional collection contains 24 paint variants: one for each of the 12 fish and
12 birds. It has its own catalog, gallery, render set and validation report.

Merge Moray symmetry (#5), then fleet sizing (#6), first. No other theme is
required. All source hull geometry is retained exactly, including the symmetrical
Moray, and all variants use the revised class proportions. Other assets and
gameplay code are unchanged in this PR.

Verification: binary geometry/resource checks, original hull and body UV
preservation, 120 preview poses per ship, flight framing, distinct texture
hashes, image integrity and a byte-for-byte rebuild. See
`validation-starlight.json`. Studio renders were visually reviewed in the original
sprint; Moray renders were refreshed after its shape revision. Uniform resizing
preserves the normalized appearance, verified across the combined library.

Preview: `starlight.html`. Catalog: `../../assets/themes/catalog-starlight.json`.
Defold runtime, device performance and shop/equip/multiplayer integration remain
untested. Bright colors are opaque base-color paint; decorations are static.
