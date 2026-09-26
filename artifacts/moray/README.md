# Moray symmetry revision

Requested follow-up to the theme library: replace the Moray's bent centerline
with a straight, bilaterally symmetrical eel hull. The centered dorsal ribbon
is continuous and closed; the jaw trim is explicitly mirrored. All four existing
Moray cosmetic variants were regenerated from the revised default GLB, retaining
their texture designs and refitting the existing decorative attachments.

The symmetry checkpoint retained the 42m hull. The subsequent fleet-size revision
scales it uniformly to 60m, preserving its symmetry. `validation.json` checks every default
vertex has a reflected partner to 0.0001m, each body ring is centered, all four existing
variants retain the new hull, and other ships' resources/catalog entries match
the preceding commit. Fleet, cosmetics and theme rebuild checks also passed.

The refreshed model renders are in `../fleet/renders` and `../cosmetics/renders`.
Defold runtime and multiplayer remain untested.
