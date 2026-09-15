#!/usr/bin/env python3
"""
Builds a rudimentary, original low-poly hull for the Escort-class ship
(plan.md S2.1.2's Escort 1 - fish/bird-named per faction, currently
Barracuda/Falcon) - the "first real, combat-capable" tier, one size class
up from Patrol - then RENDERS A TOP-DOWN PLAN DIRECTLY FROM THAT SAME
GEOMETRY, same convention as tools/build_patrol1_model.py.

Deliberately simple/original, same "no BSG-style fighter-craft silhouette"
rule as Patrol 1 (plan.md S0/S4): a 9-point hull outline (boxier/more
parallel-sided than Patrol 1's 7-point boat curve, to read as a slightly
more purposeful combat hull at a glance) plus a single bridge/cabin box -
no textures, flat material colors, same style as every other placeholder
ship asset in this project.

Hull dimensions (22m/5m) are a PLACEHOLDER scale, not a considered design -
same caveat plan.md already carries for Patrol 1's own 12m/3m figures
(plan.md S4): "one size class up from Patrol" is the only actual design
intent confirmed so far.

Units: meters, 1 Defold unit = 1 meter (this project's own convention).

Run from the project root: `python3 tools/build_escort1_model.py`
(needs Pillow). Writes directly over the checked-in outputs:
  main/models/escort_1/escort_1.gltf
  main/images/escort_1_topdown.png
Re-run this after editing the dimensions/outline below rather than
hand-editing the generated .gltf/.png directly.
"""
import base64
import json
import math
import os
import struct

OUT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # project root
GLTF_PATH = os.path.join(OUT_DIR, "main", "models", "escort_1", "escort_1.gltf")
PNG_PATH = os.path.join(OUT_DIR, "main", "images", "escort_1_topdown.png")

# ---- Hull dimensions (meters) - "one size class up from Patrol 1" ----
LENGTH = 22.0          # bow to stern, along +Z
BEAM = 5.0             # max width, along X
DECK_Y = 1.0
KEEL_Y = -1.0
CABIN_LENGTH = 6.0
CABIN_WIDTH = 3.0
CABIN_HEIGHT = 2.4
CABIN_Z_CENTER = -1.5  # slightly aft of amidships, same convention as Patrol 1

HALF_BEAM = BEAM / 2.0
HALF_L = LENGTH / 2.0

# 9-point deck/keel outline (x, z), bow at +Z, going around once - more
# parallel-sided amidships than Patrol 1's 7-point curve (a boxier,
# "first real combat hull" silhouette per plan.md S2.1's Escort-tier role).
OUTLINE = [
	(0.0, HALF_L),                     # bow tip
	(HALF_BEAM * 0.9, HALF_L - 3.5),   # stbd bow shoulder
	(HALF_BEAM, HALF_L * 0.15),        # stbd forward hull (near full beam already)
	(HALF_BEAM, -HALF_L * 0.5),        # stbd aft hull (parallel mid-body)
	(HALF_BEAM * 0.85, -HALF_L),       # stbd stern corner
	(-HALF_BEAM * 0.85, -HALF_L),      # port stern corner
	(-HALF_BEAM, -HALF_L * 0.5),       # port aft hull
	(-HALF_BEAM, HALF_L * 0.15),       # port forward hull
	(-HALF_BEAM * 0.9, HALF_L - 3.5),  # port bow shoulder
]

HULL_COLOR = (0.18, 0.20, 0.24, 1.0)   # flat baseColorFactor, no texture - a shade
CABIN_COLOR = (0.24, 0.26, 0.31, 1.0)  # cooler/more neutral grey than Patrol 1's
                                        # blue-leaning hull, just enough to read as
                                        # a distinct, slightly more armored hull

# ---- Build the mesh: (position, color) per unique vertex, plus a list
# of faces (each a list of vertex indices, in order, for a convex
# polygon - triangulated at export/render time). Identical approach to
# tools/build_patrol1_model.py - see that file's own comment for why. ----
verts = []  # list of (x, y, z, r, g, b, a)
faces = []  # list of (name, [vertex indices], color)


def add_vert(x, y, z, color):
	verts.append((x, y, z) + color)
	return len(verts) - 1


deck_idx = [add_vert(x, DECK_Y, z, HULL_COLOR) for x, z in OUTLINE]
keel_idx = [add_vert(x, KEEL_Y, z, HULL_COLOR) for x, z in OUTLINE]

n = len(OUTLINE)
for i in range(n):
	j = (i + 1) % n
	# hull side quad, wound outward
	faces.append(("hull_side_%d" % i, [deck_idx[i], deck_idx[j], keel_idx[j], keel_idx[i]], HULL_COLOR))

faces.append(("deck", list(deck_idx), HULL_COLOR))
faces.append(("keel", list(reversed(keel_idx)), HULL_COLOR))

# Cabin/bridge: simple box sitting on the deck, same convention as Patrol 1.
cx0, cx1 = -CABIN_WIDTH / 2.0, CABIN_WIDTH / 2.0
cz0, cz1 = CABIN_Z_CENTER - CABIN_LENGTH / 2.0, CABIN_Z_CENTER + CABIN_LENGTH / 2.0
cy0, cy1 = DECK_Y, DECK_Y + CABIN_HEIGHT
c = {}
for (xi, x) in ((0, cx0), (1, cx1)):
	for (yi, y) in ((0, cy0), (1, cy1)):
		for (zi, z) in ((0, cz0), (1, cz1)):
			c[(xi, yi, zi)] = add_vert(x, y, z, CABIN_COLOR)

# 6 faces of the box, each wound outward (CCW viewed from outside).
faces.append(("cabin_top", [c[(0, 1, 0)], c[(0, 1, 1)], c[(1, 1, 1)], c[(1, 1, 0)]], CABIN_COLOR))
faces.append(("cabin_bottom", [c[(0, 0, 0)], c[(1, 0, 0)], c[(1, 0, 1)], c[(0, 0, 1)]], CABIN_COLOR))
faces.append(("cabin_front", [c[(0, 0, 1)], c[(1, 0, 1)], c[(1, 1, 1)], c[(0, 1, 1)]], CABIN_COLOR))
faces.append(("cabin_back", [c[(1, 0, 0)], c[(0, 0, 0)], c[(0, 1, 0)], c[(1, 1, 0)]], CABIN_COLOR))
faces.append(("cabin_stbd", [c[(1, 0, 1)], c[(1, 0, 0)], c[(1, 1, 0)], c[(1, 1, 1)]], CABIN_COLOR))
faces.append(("cabin_port", [c[(0, 0, 0)], c[(0, 0, 1)], c[(0, 1, 1)], c[(0, 1, 0)]], CABIN_COLOR))

print("Unique vertices: %d, faces (polygons): %d" % (len(verts), len(faces)))

xs = [v[0] for v in verts]
ys = [v[1] for v in verts]
zs = [v[2] for v in verts]
print("Bounding box (m): X %.2f..%.2f (beam %.2fm)  Y %.2f..%.2f (height %.2fm)  Z %.2f..%.2f (length %.2fm)" % (
	min(xs), max(xs), max(xs) - min(xs),
	min(ys), max(ys), max(ys) - min(ys),
	min(zs), max(zs), max(zs) - min(zs)))


# ---- glTF export (flat-shaded: each face's vertices duplicated with a
# computed face normal, so lighting reads as a faceted low-poly hull) ----
def face_normal(poly_verts):
	a = poly_verts[0]
	b = poly_verts[1]
	cpt = poly_verts[2]
	ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
	vx, vy, vz = cpt[0] - a[0], cpt[1] - a[1], cpt[2] - a[2]
	nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
	length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
	return nx / length, ny / length, nz / length


positions = []
normals = []
colors = []
indices = []

for name, poly, color in faces:
	poly_pts = [verts[i][:3] for i in poly]
	nx, ny, nz = face_normal(poly_pts)
	base = len(positions)
	for i in poly:
		positions.append(verts[i][:3])
		normals.append((nx, ny, nz))
		colors.append(verts[i][3:])
	# fan-triangulate the polygon (all faces here are convex: quads or the two 9-gon caps)
	for k in range(1, len(poly) - 1):
		indices.extend([base, base + k, base + k + 1])

pos_bytes = b"".join(struct.pack("<3f", *p) for p in positions)
norm_bytes = b"".join(struct.pack("<3f", *nrm) for nrm in normals)
color_bytes = b"".join(struct.pack("<4f", *col) for col in colors)
idx_bytes = b"".join(struct.pack("<H", i) for i in indices)


def pad4(b):
	pad = (-len(b)) % 4
	return b + b"\x00" * pad


buf = b""
views = []


def add_view(data, target):
	global buf
	data = pad4(data)
	offset = len(buf)
	buf += data
	views.append({"byteOffset": offset, "byteLength": len(data), "target": target})
	return len(views) - 1


ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963

pos_view = add_view(pos_bytes, ARRAY_BUFFER)
norm_view = add_view(norm_bytes, ARRAY_BUFFER)
color_view = add_view(color_bytes, ARRAY_BUFFER)
idx_view = add_view(idx_bytes, ELEMENT_ARRAY_BUFFER)

xs_p = [p[0] for p in positions]
ys_p = [p[1] for p in positions]
zs_p = [p[2] for p in positions]

accessors = [
	{"bufferView": pos_view, "componentType": 5126, "count": len(positions), "type": "VEC3",
	 "min": [min(xs_p), min(ys_p), min(zs_p)], "max": [max(xs_p), max(ys_p), max(zs_p)]},
	{"bufferView": norm_view, "componentType": 5126, "count": len(normals), "type": "VEC3"},
	{"bufferView": color_view, "componentType": 5126, "count": len(colors), "type": "VEC4"},
	{"bufferView": idx_view, "componentType": 5123, "count": len(indices), "type": "SCALAR"},
]

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy plan.md S2.1.2 - escort_1 rudimentary hull, hand-authored"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "escort_1_hull"}],
	"meshes": [{
		"name": "escort_1_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2},
			"indices": 3,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "escort_1_flat",
		"pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0.0, "roughnessFactor": 0.9},
	}],
	"buffers": [{"byteLength": len(buf), "uri": "data:application/octet-stream;base64," + base64.b64encode(buf).decode("ascii")}],
	"bufferViews": [
		{"buffer": 0, "byteOffset": v["byteOffset"], "byteLength": v["byteLength"], "target": v["target"]}
		for v in views
	],
	"accessors": accessors,
}

with open(GLTF_PATH, "w") as f:
	json.dump(gltf, f, indent=1)
print("Wrote escort_1.gltf (%d bytes buffer, %d triangles)" % (len(buf), len(indices) // 3))

# ---- Top-down plan render, extracted from the SAME face/vertex data ----
from PIL import Image, ImageDraw  # noqa: E402

CANVAS_W, CANVAS_H = 300, 640
PAD_Y = 50
SCALE = (CANVAS_H - PAD_Y) / LENGTH  # px per meter, fit length with padding


def to_px(x, z):
	# +Z (bow) -> up on screen (smaller Y in image space); centered horizontally
	px = CANVAS_W / 2.0 + x * SCALE
	py = CANVAS_H / 2.0 - z * SCALE
	return px, py


img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw the hull deck outline (top-down silhouette) first...
deck_poly = [to_px(x, z) for x, z in OUTLINE]
draw.polygon(deck_poly, fill=(46, 51, 61, 255), outline=(15, 20, 26, 255), width=3)

# ...then the cabin/bridge footprint on top of it.
cabin_poly = [to_px(cx0, cz1), to_px(cx1, cz1), to_px(cx1, cz0), to_px(cx0, cz0)]
draw.polygon(cabin_poly, fill=(61, 66, 79, 255), outline=(15, 20, 26, 255), width=2)

# A small bow-direction tick, purely a readability aid for a top-down plan.
bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote escort_1_topdown.png (%dx%d px, %.2f px/m)" % (CANVAS_W, CANVAS_H, SCALE))
