#!/usr/bin/env python3
"""
Replaces Osprey's (Swarm, Escort class, Tactical role) hull with an
ORIGINAL design, not sourced from anywhere - same rationale as
tools/build_lionfish_model.py/build_golden_eagle_model.py/build_pelican_model.py:
the previous osprey.glb was a SuperShips-sourced, BSG-derived asset
(ships.lua's own header comment flags it as a "Cylon"-faction "liche" mesh),
replaced here per direct instruction with a hand-authored hull built to
actually resemble the ship's own real-world namesake instead - and, per
direct instruction, sized to roughly match its own class/role sibling
Lionfish (escort_tactical's Accord skin, tools/build_lionfish_model.py,
~11.73-unit bounding radius) rather than the old asset's own ~123-unit
scale that made main/data/ships.lua's flight_camera entry for this chassis
need a >10x-larger radius than its sibling to avoid clipping.

Leans into an actual osprey's own most recognizable features - deliberately
DIFFERENT from tools/build_golden_eagle_model.py's eagle silhouette, not a
recolor of it:
- a white/pale HEAD with a dark eye-stripe band, unlike an eagle's uniform
  golden head - an osprey's most distinctive field mark
- long, narrow wings held with a visible CROOK/bend at the wrist (built as
  two swept segments per wing, root-to-elbow then elbow-to-tip at a
  shallower sweep) - an osprey's own signature silhouette in flight,
  distinct from a golden eagle's broad straight-tapered wing
- a moderate, single-notch tail fan (2 panels, not golden eagle's 3) -
  Escort-tier proportions, smaller than that Frigate-tier hull
- two small hooked talons tucked under the belly - fittingly prominent
  given a real osprey hunts fish almost exclusively with its talons
- slate-grey/brown upperside plumage, the pale head patch, and dark
  talons/beak

Same technique as the other hand-authored hulls: flat-shaded low-poly
geometry, vertex colors via a small palette texture, embedded in a real
binary .glb. Units: meters, 1 Defold unit = 1 meter.

Run from the project root: `python3 tools/build_osprey_model.py`
(needs Pillow). Writes:
  assets/models/escort_tactical/osprey.glb
  assets/models/escort_tactical/osprey_palette.png
  main/images/escort_tactical_osprey_topdown.png
Also prints the bounding-sphere radius and a ready-to-paste
PREVIEW_CAMERA entry for main/outpost.gui_script (PREVIEW_WORLD_POS stays
unchanged - same model path, same off-world rig position).
"""
import io
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_PATH = os.path.join(ROOT, "assets", "models", "escort_tactical", "osprey.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "escort_tactical", "osprey_palette.png")
PNG_PATH = os.path.join(ROOT, "main", "images", "escort_tactical_osprey_topdown.png")


def write_glb(path, gltf_dict, binary_data):
	json_bytes = json.dumps(gltf_dict).encode("utf-8")
	pad = (-len(json_bytes)) % 4
	json_bytes += b" " * pad
	bin_bytes = binary_data
	pad = (-len(bin_bytes)) % 4
	bin_bytes += b"\x00" * pad
	JSON_CHUNK_TYPE = 0x4E4F534A
	BIN_CHUNK_TYPE = 0x004E4942
	json_chunk = struct.pack("<II", len(json_bytes), JSON_CHUNK_TYPE) + json_bytes
	bin_chunk = struct.pack("<II", len(bin_bytes), BIN_CHUNK_TYPE) + bin_bytes
	total_length = 12 + len(json_chunk) + len(bin_chunk)
	with open(path, "wb") as f:
		f.write(struct.pack("<4sII", b"glTF", 2, total_length))
		f.write(json_chunk)
		f.write(bin_chunk)


# ---- Hull dimensions (meters) - LENGTH matches Lionfish's own 20m nose-to-
# tail exactly (per direct instruction: "roughly the same size as the
# lionfish"); BEAM/wing reach kept modest (an Escort/Tactical scout, not
# golden_eagle's Frigate-tier wingspan) so the overall bounding radius lands
# close to Lionfish's own ~11.73, not the old liche.glb's ~123. ----
LENGTH = 20.0
BEAM = 6.0
DECK_Y = 0.85
KEEL_Y = -0.85
HALF_L = LENGTH / 2.0
HALF_BEAM = BEAM / 2.0

# 13-point deck/keel outline (x, z), nose (beak root) at +Z: a slim raptor
# torso - narrower than Golden Eagle's own bulkier Frigate-tier body.
OUTLINE = [
	(0.0, HALF_L),                        # nose / beak root
	(HALF_BEAM * 0.22, HALF_L - 2.4),     # head
	(HALF_BEAM * 0.42, HALF_L - 4.6),     # neck widening into shoulders
	(HALF_BEAM * 0.55, HALF_L - 7.0),     # shoulder, body widest starts
	(HALF_BEAM * 0.55, HALF_L - 11.5),    # body widest continues
	(HALF_BEAM * 0.34, HALF_L - 15.5),    # tapering toward the tail
	(HALF_BEAM * 0.14, -HALF_L),          # stbd tail root corner
	(-HALF_BEAM * 0.14, -HALF_L),         # port tail root corner
	(-HALF_BEAM * 0.34, HALF_L - 15.5),
	(-HALF_BEAM * 0.55, HALF_L - 11.5),
	(-HALF_BEAM * 0.55, HALF_L - 7.0),
	(-HALF_BEAM * 0.42, HALF_L - 4.6),
	(-HALF_BEAM * 0.22, HALF_L - 2.4),
]

HULL_COLOR = (0.32, 0.31, 0.34, 1.0)    # slate-grey/brown upperside
HEAD_COLOR = (0.82, 0.82, 0.78, 1.0)    # pale head patch
STRIPE_COLOR = (0.16, 0.15, 0.17, 1.0)  # dark eye-stripe / beak / talons
WING_COLOR = (0.22, 0.21, 0.24, 1.0)    # darker wing/tail panels

PALETTE_W = 4
PALETTE_H = 1
COLOR_UV = {
	HULL_COLOR: (0.5 / PALETTE_W, 0.5),
	HEAD_COLOR: (1.5 / PALETTE_W, 0.5),
	STRIPE_COLOR: (2.5 / PALETTE_W, 0.5),
	WING_COLOR: (3.5 / PALETTE_W, 0.5),
}


def to_8bit(color):
	return tuple(round(c * 255) for c in color)


verts = []
faces = []


def add_vert(x, y, z, color):
	verts.append((x, y, z) + color)
	return len(verts) - 1


def add_prism(outline, y0, y1, color):
	top_idx = [add_vert(x, y1, z, color) for x, z in outline]
	bot_idx = [add_vert(x, y0, z, color) for x, z in outline]
	n = len(outline)
	for i in range(n):
		j = (i + 1) % n
		faces.append(("side_%d" % i, [top_idx[i], top_idx[j], bot_idx[j], bot_idx[i]], color))
	faces.append(("top", list(top_idx), color))
	faces.append(("bottom", list(reversed(bot_idx)), color))


def add_box(cx0, cx1, cy0, cy1, cz0, cz1, color, prefix):
	c = {}
	for (xi, x) in ((0, cx0), (1, cx1)):
		for (yi, y) in ((0, cy0), (1, cy1)):
			for (zi, z) in ((0, cz0), (1, cz1)):
				c[(xi, yi, zi)] = add_vert(x, y, z, color)
	faces.append((prefix + "_top", [c[(0, 1, 0)], c[(0, 1, 1)], c[(1, 1, 1)], c[(1, 1, 0)]], color))
	faces.append((prefix + "_bottom", [c[(0, 0, 0)], c[(1, 0, 0)], c[(1, 0, 1)], c[(0, 0, 1)]], color))
	faces.append((prefix + "_front", [c[(0, 0, 1)], c[(1, 0, 1)], c[(1, 1, 1)], c[(0, 1, 1)]], color))
	faces.append((prefix + "_back", [c[(1, 0, 0)], c[(0, 0, 0)], c[(0, 1, 0)], c[(1, 1, 0)]], color))
	faces.append((prefix + "_stbd", [c[(1, 0, 1)], c[(1, 0, 0)], c[(1, 1, 0)], c[(1, 1, 1)]], color))
	faces.append((prefix + "_port", [c[(0, 0, 0)], c[(0, 0, 1)], c[(0, 1, 1)], c[(0, 1, 0)]], color))


def add_spike(base_x, base_y, base_z, half_w, tip_x, tip_y, tip_z, color, prefix):
	b00 = add_vert(base_x - half_w, base_y, base_z - half_w, color)
	b10 = add_vert(base_x + half_w, base_y, base_z - half_w, color)
	b11 = add_vert(base_x + half_w, base_y, base_z + half_w, color)
	b01 = add_vert(base_x - half_w, base_y, base_z + half_w, color)
	tip = add_vert(tip_x, tip_y, tip_z, color)
	faces.append((prefix + "_base", [b00, b10, b11, b01], color))
	faces.append((prefix + "_s0", [b00, b01, tip], color))
	faces.append((prefix + "_s1", [b01, b11, tip], color))
	faces.append((prefix + "_s2", [b11, b10, tip], color))
	faces.append((prefix + "_s3", [b10, b00, tip], color))


def add_double_tri(p0, p1, p2, color, prefix):
	i0 = add_vert(*p0, color)
	i1 = add_vert(*p1, color)
	i2 = add_vert(*p2, color)
	j0 = add_vert(*p0, color)
	j1 = add_vert(*p1, color)
	j2 = add_vert(*p2, color)
	faces.append((prefix + "_a", [i0, i1, i2], color))
	faces.append((prefix + "_b", [j0, j2, j1], color))


# ---- Body ----
add_prism(OUTLINE, KEEL_Y, DECK_Y, HULL_COLOR)

# ---- Pale head patch with a dark eye-stripe band across it - an osprey's
# single most recognizable field mark, unlike Golden Eagle's uniform-toned
# head. ----
add_box(-1.1, 1.1, DECK_Y - 0.04, DECK_Y + 0.28, HALF_L - 4.4, HALF_L - 0.6, HEAD_COLOR, "head")
add_box(-1.15, 1.15, DECK_Y + 0.05, DECK_Y + 0.32, HALF_L - 2.8, HALF_L - 1.9, STRIPE_COLOR, "eyestripe")

# ---- Small hooked beak - shorter/shallower hook than Golden Eagle's, an
# osprey's beak curves down less dramatically. ----
add_spike(0.0, DECK_Y * 0.2, HALF_L, 0.4, 0.0, -1.0, HALF_L + 1.1, STRIPE_COLOR, "beak")

# ---- Wings: the osprey's own signature CROOKED silhouette - two swept
# segments per side (root-to-elbow at a shallow sweep, then elbow-to-tip
# swept back harder and drooped slightly), unlike Golden Eagle's single
# straight dihedral panel. ----
WING_ROOT_Z = HALF_L - 10.0
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_fwd = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z + 2.6)
	root_aft = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z - 2.6)
	elbow = (sign * (HALF_BEAM + 3.6), 1.1, WING_ROOT_Z - 1.0)
	tip = (sign * (HALF_BEAM + 8.2), 0.2, WING_ROOT_Z - 5.4)
	# root-to-elbow panel (the shallow inner sweep)
	add_double_tri(root_fwd, elbow, root_aft, WING_COLOR, "wing_%s_inner" % side)
	# elbow-to-tip panel (the harder-swept, drooped outer primary feathers) -
	# shares its two root points with the inner panel's own tip/aft corner
	# so the wing reads as one continuous crooked shape, not two disjoint
	# panels.
	add_double_tri(elbow, tip, root_aft, WING_COLOR, "wing_%s_outer" % side)

# ---- Tail: a single-notch fan (2 panels), smaller/simpler than Golden
# Eagle's 3-panel fan - Escort-tier proportions. ----
TAIL_ROOT_Z = -HALF_L + 2.4
for i, spread_x in ((0, 1.6), (1, -1.6)):
	root = (0.0, 0.0, TAIL_ROOT_Z)
	tip = (spread_x, 0.0, -HALF_L - 2.6)
	side_offset = (spread_x * 0.3, 0.0, TAIL_ROOT_Z - 0.7)
	add_double_tri(root, tip, side_offset, WING_COLOR, "tail_%d" % i)

# ---- Talons: two small hooked spikes tucked under the belly, prominent -
# a real osprey catches fish almost exclusively with these. ----
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	add_spike(sign * 1.0, KEEL_Y, HALF_L - 8.5, 0.28,
		sign * 1.4, KEEL_Y - 1.4, HALF_L - 10.5, STRIPE_COLOR, "talon_%s" % side)

print("Unique vertices: %d, faces (polygons): %d" % (len(verts), len(faces)))

xs = [v[0] for v in verts]
ys = [v[1] for v in verts]
zs = [v[2] for v in verts]
cx, cy, cz = (min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0, (min(zs) + max(zs)) / 2.0
radius = max(math.sqrt((x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2) for x, y, z in zip(xs, ys, zs))
print("Bounding box (m): X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
	min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
print("Bounding-sphere radius (m): %.2f (Lionfish's own: 11.73)" % radius)


def face_normal(poly_verts):
	a, b, cpt = poly_verts[0], poly_verts[1], poly_verts[2]
	ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
	vx, vy, vz = cpt[0] - a[0], cpt[1] - a[1], cpt[2] - a[2]
	nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
	length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
	return nx / length, ny / length, nz / length


positions, normals, colors, uvs, indices = [], [], [], [], []

for name, poly, color in faces:
	poly_pts = [verts[i][:3] for i in poly]
	nx, ny, nz = face_normal(poly_pts)
	uv = COLOR_UV[color]
	base = len(positions)
	for i in poly:
		positions.append(verts[i][:3])
		normals.append((nx, ny, nz))
		colors.append(verts[i][3:])
		uvs.append(uv)
	for k in range(1, len(poly) - 1):
		indices.extend([base, base + k, base + k + 1])

pos_bytes = b"".join(struct.pack("<3f", *p) for p in positions)
norm_bytes = b"".join(struct.pack("<3f", *n) for n in normals)
color_bytes = b"".join(struct.pack("<4f", *c) for c in colors)
uv_bytes = b"".join(struct.pack("<2f", *uv) for uv in uvs)
idx_bytes = b"".join(struct.pack("<H", i) for i in indices)


def pad4(b):
	pad = (-len(b)) % 4
	return b + b"\x00" * pad


buf = b""
views = []


def add_view(data, target):
	global buf
	true_length = len(data)
	offset = len(buf)
	buf += pad4(data)
	views.append({"byteOffset": offset, "byteLength": true_length, "target": target})
	return len(views) - 1


ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963

pos_view = add_view(pos_bytes, ARRAY_BUFFER)
norm_view = add_view(norm_bytes, ARRAY_BUFFER)
color_view = add_view(color_bytes, ARRAY_BUFFER)
uv_view = add_view(uv_bytes, ARRAY_BUFFER)
idx_view = add_view(idx_bytes, ELEMENT_ARRAY_BUFFER)

xs_p = [p[0] for p in positions]
ys_p = [p[1] for p in positions]
zs_p = [p[2] for p in positions]

accessors = [
	{"bufferView": pos_view, "componentType": 5126, "count": len(positions), "type": "VEC3",
	 "min": [min(xs_p), min(ys_p), min(zs_p)], "max": [max(xs_p), max(ys_p), max(zs_p)]},
	{"bufferView": norm_view, "componentType": 5126, "count": len(normals), "type": "VEC3"},
	{"bufferView": color_view, "componentType": 5126, "count": len(colors), "type": "VEC4"},
	{"bufferView": uv_view, "componentType": 5126, "count": len(uvs), "type": "VEC2"},
	{"bufferView": idx_view, "componentType": 5123, "count": len(indices), "type": "SCALAR"},
]

from PIL import Image  # noqa: E402

palette_img = Image.new("RGBA", (PALETTE_W, PALETTE_H), (0, 0, 0, 0))
for i, color in enumerate((HULL_COLOR, HEAD_COLOR, STRIPE_COLOR, WING_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - osprey hull, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "osprey_hull"}],
	"meshes": [{
		"name": "osprey_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "osprey_flat",
		"pbrMetallicRoughness": {
			"baseColorFactor": [1, 1, 1, 1],
			"baseColorTexture": {"index": 0},
			"metallicFactor": 0.0,
			"roughnessFactor": 0.9,
		},
	}],
	"images": [{"bufferView": img_view, "mimeType": "image/png"}],
	"samplers": [{"magFilter": NEAREST, "minFilter": NEAREST, "wrapS": CLAMP_TO_EDGE, "wrapT": CLAMP_TO_EDGE}],
	"textures": [{"source": 0, "sampler": 0}],
	"buffers": [{"byteLength": len(buf)}],
	"bufferViews": [
		({"buffer": 0, "byteOffset": v["byteOffset"], "byteLength": v["byteLength"], "target": v["target"]}
		 if v["target"] is not None else
		 {"buffer": 0, "byteOffset": v["byteOffset"], "byteLength": v["byteLength"]})
		for v in views
	],
	"accessors": accessors,
}

write_glb(GLB_PATH, gltf, buf)
print("Wrote %s (%d bytes buffer, %d triangles)" % (GLB_PATH, len(buf), len(indices) // 3))

palette_img.save(PALETTE_PATH)
print("Wrote %s (%dx%d px)" % (PALETTE_PATH, PALETTE_W, PALETTE_H))

# ---- Top-down plan render ----
from PIL import ImageDraw  # noqa: E402

CANVAS_W, CANVAS_H = 300, 640
PAD_Y = 60
SCALE = (CANVAS_H - PAD_Y) / (LENGTH + 6)


def to_px(x, z):
	px = CANVAS_W / 2.0 + x * SCALE
	py = CANVAS_H / 2.0 - z * SCALE
	return px, py


img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

deck_poly = [to_px(x, z) for x, z in OUTLINE]
draw.polygon(deck_poly, fill=(82, 79, 87, 255), outline=(15, 20, 26, 255), width=3)

head_poly = [to_px(-1.1, HALF_L - 0.6), to_px(1.1, HALF_L - 0.6), to_px(1.1, HALF_L - 4.4), to_px(-1.1, HALF_L - 4.4)]
draw.polygon(head_poly, fill=(209, 209, 199, 255), outline=(15, 20, 26, 255), width=1)

stripe_poly = [to_px(-1.15, HALF_L - 1.9), to_px(1.15, HALF_L - 1.9), to_px(1.15, HALF_L - 2.8), to_px(-1.15, HALF_L - 2.8)]
draw.polygon(stripe_poly, fill=(41, 38, 43, 255))

beak_poly = [to_px(-0.4, HALF_L), to_px(0.4, HALF_L), to_px(0.0, HALF_L + 1.1)]
draw.polygon(beak_poly, fill=(41, 38, 43, 255), outline=(15, 20, 26, 255), width=1)

for sign in (1.0, -1.0):
	root_fwd = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z + 2.6)
	root_aft = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z - 2.6)
	elbow = to_px(sign * (HALF_BEAM + 3.6), WING_ROOT_Z - 1.0)
	tip = to_px(sign * (HALF_BEAM + 8.2), WING_ROOT_Z - 5.4)
	draw.polygon([root_fwd, elbow, root_aft], fill=(56, 54, 61, 255), outline=(15, 20, 26, 255), width=2)
	draw.polygon([elbow, tip, root_aft], fill=(56, 54, 61, 255), outline=(15, 20, 26, 255), width=2)

for spread_x in (1.6, -1.6):
	root = to_px(0.0, TAIL_ROOT_Z)
	tip = to_px(spread_x, -HALF_L - 2.6)
	draw.line([root, tip], fill=(56, 54, 61, 255), width=4)

bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote %s (%dx%d px, %.2f px/m)" % (PNG_PATH, CANVAS_W, CANVAS_H, SCALE))

scale = (radius / 6.34) * 1.5
eye = (0.0, 3.0 * scale, 8.0 * scale)
far = math.sqrt(eye[0] ** 2 + eye[1] ** 2 + eye[2] ** 2) + radius + 50.0
print()
print("PREVIEW_CAMERA entry (PREVIEW_WORLD_POS unchanged - same model path):")
print('\t["/assets/models/escort_tactical/osprey.model"] = { eye_offset = vmath.vector3(%.2f, %.2f, %.2f), far = %.2f },' % (eye[0], eye[1], eye[2], far))
