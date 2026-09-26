# Moray symmetry revision

Requested follow-up to the theme library: replace the Moray's bent centerline
with a straight, bilaterally symmetrical eel hull. The centered dorsal ribbon
is continuous and closed; the jaw trim is explicitly mirrored. All twelve
Moray cosmetic variants were regenerated from the revised default GLB, retaining
their texture designs and refitting the existing decorative attachments.

The symmetry checkpoint retained the 42m hull. The subsequent fleet-size revision
scales it uniformly to 60m, preserving its symmetry. `validation.json` checks every default
vertex has a reflected partner to 0.0001m, each body ring is centered, all twelve
variants retain the new hull, and other ships' resources/catalog entries match
the preceding commit. Fleet, cosmetics and theme rebuild checks also passed.

The actual exported Moray models were rerendered and visually reviewed in three
angles for geometry collections and three-quarter views for paint collections.
`perspective.jpg` compares all thirteen finishes. The top/side contact sheets
reuse three-quarter images for paint-only collections, matching their galleries.
Defold runtime and live multiplayer remain untested.
