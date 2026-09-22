#!/usr/bin/env python3
"""
Builds an original low-poly hull for Lionfish (Accord, Escort class,
Tactical role) - the roster's last remaining hand-authored placeholder;
every other named ship in main/data/ships.lua's roster now has a model,
Lionfish was still `model = "<TBD>"`.

Deliberately an ORIGINAL design, not sourced from anywhere - same rule
tools/build_patrol_interceptor_model.py and
tools/build_escort_interceptor_model.py's own header comments already
state (plan.md S0/S4). The silhouette leans into the ship's own namesake
rather than any existing craft: a slender tapered body, a raised head
crest, a fan of dorsal spines along the back (progressively taller
toward midships, tilted aft), two swept pectoral fin panels near the
bow, and a small tail fin - a lionfish's own recognizable features
(fanned venomous spines, broad pectoral fins), reinterpreted as hull
detailing rather than a copy of any other ship's shape. The dorsal
spines and pectoral fins also read as a sensor/antenna array, fitting
the Tactical row this ship occupies in the class/role naming matrix.

Same technique as the two prior hand-authored hulls: flat-shaded
low-poly geometry, vertex colors driven by a tiny per-color palette
texture (model.material's shader only samples a bound texture, never a
mesh's own COLOR_0 attribute - see build_escort_interceptor_model.py's
own comment on this), embedded directly into a real binary .glb (JSON
chunk + BIN chunk, not a data-URI buffer - the same format fix already
proven necessary for this engine's model importer).

Units: meters, 1 Defold unit = 1 meter (this project's convention).

Run from the project root: `python3 tools/build_lionfish_model.py`
(needs Pillow). Writes:
  assets/models/escort_tactical/lionfish.glb
  assets/models/escort_tactical/lionfish_palette.png
  main/images/escort_tactical_lionfish_topdown.png
Also prints the bounding-sphere radius and a ready-to-paste
PREVIEW_CAMERA entry for main/outpost.gui_script, using the exact same
"(0, 3, 8) scaled by radius/6.34, then 1.5x zoom-out" formula already
used for every other PREVIEW_CAMERA entry in that file.
"""
import io
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_PATH = os.path.join(ROOT, "assets", "models", "escort_tactical", "lionfish.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "escort_tactical", "lionfish_palette.png")
PNG_PATH = os.path.join(ROOT, "main", "images", "escort_tactical_lionfish_topdown.png")


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


# ---- Hull dimensions (meters) ----
LENGTH = 20.0
BEAM = 4.4
DECK_Y = 0.9
KEEL_Y = -0.9
HALF_L = LENGTH / 2.0
HALF_BEAM = BEAM / 2.0

# 11-point deck/keel outline (x, z), bow at +Z: a blunt, widening head
# tapering back to a slender tail-root - a fish profile, not the boxier
# parallel-sided escort_interceptor hull.
OUTLINE = [
	(0.0, HALF_L),                       # nose
	(HALF_BEAM * 0.55, HALF_L - 2.6),    # stbd head shoulder
	(HALF_BEAM, HALF_L - 4.8),           # stbd widest point (gill line)
	(HALF_BEAM * 0.62, 0.0),             # stbd mid-body taper
	(HALF_BEAM * 0.28, -HALF_L * 0.55),  # stbd tail-body
	(HALF_BEAM * 0.14, -HALF_L),         # stbd tail root
	(-HALF_BEAM * 0.14, -HALF_L),        # port tail root
	(-HALF_BEAM * 0.28, -HALF_L * 0.55), # port tail-body
	(-HALF_BEAM * 0.62, 0.0),            # port mid-body taper
	(-HALF_BEAM, HALF_L - 4.8),          # port widest point
	(-HALF_BEAM * 0.55, HALF_L - 2.6),   # port head shoulder
]

HULL_COLOR = (0.50, 0.15, 0.13, 1.0)    # deep red-brown body
CREST_COLOR = (0.60, 0.23, 0.15, 1.0)   # warmer head crest
SPINE_COLOR = (0.90, 0.77, 0.46, 1.0)   # pale cream/gold spine tips
FIN_COLOR = (0.66, 0.21, 0.18, 1.0)     # pectoral/tail fin panels

PALETTE_W = 4
PALETTE_H = 1
COLOR_UV = {
	HULL_COLOR: (0.5 / PALETTE_W, 0.5),
	CREST_COLOR: (1.5 / PALETTE_W, 0.5),
	SPINE_COLOR: (2.5 / PALETTE_W, 0.5),
	FIN_COLOR: (3.5 / PALETTE_W, 0.5),
}


def to_8bit(color):
	return tuple(round(c * 255) for c in color)


verts = []
faces = []  # (name, [vertex indices], color) - convex polygons, fan-triangulated at export


def add_vert(x, y, z, color):
	verts.append((x, y, z) + color)
	return len(verts) - 1


def add_prism(outline, y0, y1, color):
	"""Closed prism (side quads + top/bottom caps) from a 2D (x, z) outline."""
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
	"""A 4-sided pyramid: a small square base on the hull, tapering to a
	single point - one dorsal spine. Wound so all 4 side faces point
	outward regardless of which way the tip leans."""
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
	"""A flat triangular fin panel, given faces on both sides (front-wound
	+ back-wound) so it stays visible from every camera angle despite
	having zero thickness - the live preview rotates a full 360 degrees."""
	i0 = add_vert(*p0, color)
	i1 = add_vert(*p1, color)
	i2 = add_vert(*p2, color)
	j0 = add_vert(*p0, color)
	j1 = add_vert(*p1, color)
	j2 = add_vert(*p2, color)
	faces.append((prefix + "_a", [i0, i1, i2], color))
	faces.append((prefix + "_b", [j0, j2, j1], color))


# ---- Hull body ----
add_prism(OUTLINE, KEEL_Y, DECK_Y, HULL_COLOR)

# ---- Head crest: a small raised fin/housing just behind the nose ----
add_box(-0.55, 0.55, DECK_Y, DECK_Y + 1.1, HALF_L - 6.5, HALF_L - 3.2, CREST_COLOR, "crest")

# ---- Dorsal spine fan: 7 spikes along the centerline, from just behind
# the crest back toward the tail - progressively taller toward midships
# then shorter again, each tilted aft for a swept "fanned spine" look. ----
SPINE_COUNT = 7
SPINE_Z_START = HALF_L - 3.6
SPINE_Z_END = -HALF_L * 0.75
SPINE_BASE_W = 0.22
for i in range(SPINE_COUNT):
	t = i / (SPINE_COUNT - 1)  # 0..1 nose-to-tail
	z = SPINE_Z_START + (SPINE_Z_END - SPINE_Z_START) * t
	# height peaks at t ~= 0.35 (just aft of the crest), tapering off both ways
	height = 1.4 + 3.2 * math.sin(min(1.0, t / 0.35 if t < 0.35 else 1.0) * math.pi * 0.5) * (1.0 - max(0.0, t - 0.35) / 0.65)
	sweep = 0.9 + 1.6 * t  # tip drifts further aft (more -Z) toward the back of the fan
	add_spike(0.0, DECK_Y, z, SPINE_BASE_W, 0.0, DECK_Y + height, z - sweep, SPINE_COLOR, "spine_%d" % i)

# ---- Pectoral fins: two swept wing panels near the head, port + stbd ----
PECT_Z = HALF_L - 5.2
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_fwd = (sign * HALF_BEAM * 0.85, 0.1, PECT_Z + 1.6)
	root_aft = (sign * HALF_BEAM * 0.75, -0.1, PECT_Z - 1.8)
	tip = (sign * (HALF_BEAM + 3.4), -0.3, PECT_Z - 0.6)
	add_double_tri(root_fwd, tip, root_aft, FIN_COLOR, "pect_%s" % side)

# ---- Tail fin: a small vertical fan at the stern ----
tail_root_top = (0.0, DECK_Y + 0.1, -HALF_L + 1.0)
tail_root_bot = (0.0, KEEL_Y - 0.1, -HALF_L + 1.0)
tail_tip = (0.0, 0.0, -HALF_L - 2.6)
add_double_tri(tail_root_top, tail_tip, tail_root_bot, FIN_COLOR, "tailfin")

print("Unique vertices: %d, faces (polygons): %d" % (len(verts), len(faces)))

xs = [v[0] for v in verts]
ys = [v[1] for v in verts]
zs = [v[2] for v in verts]
cx, cy, cz = (min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0, (min(zs) + max(zs)) / 2.0
radius = max(math.sqrt((x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2) for x, y, z in zip(xs, ys, zs))
print("Bounding box (m): X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
	min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
print("Bounding-sphere radius (m): %.2f" % radius)


# ---- glTF export (flat-shaded: each face's vertices duplicated with a
# computed face normal) ----
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
for i, color in enumerate((HULL_COLOR, CREST_COLOR, SPINE_COLOR, FIN_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - lionfish hull, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "lionfish_hull"}],
	"meshes": [{
		"name": "lionfish_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "lionfish_flat",
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
SCALE = (CANVAS_H - PAD_Y) / (LENGTH + 6)  # leave room for the tail fin/spine overhang


def to_px(x, z):
	px = CANVAS_W / 2.0 + x * SCALE
	py = CANVAS_H / 2.0 - z * SCALE
	return px, py


img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

deck_poly = [to_px(x, z) for x, z in OUTLINE]
draw.polygon(deck_poly, fill=(46, 25, 22, 255), outline=(15, 20, 26, 255), width=3)

crest_poly = [to_px(-0.55, HALF_L - 3.2), to_px(0.55, HALF_L - 3.2), to_px(0.55, HALF_L - 6.5), to_px(-0.55, HALF_L - 6.5)]
draw.polygon(crest_poly, fill=(56, 34, 24, 255), outline=(15, 20, 26, 255), width=2)

for i in range(SPINE_COUNT):
	t = i / (SPINE_COUNT - 1)
	z = SPINE_Z_START + (SPINE_Z_END - SPINE_Z_START) * t
	draw.line([to_px(0, z + 0.3), to_px(0, z - 0.3)], fill=(212, 178, 110, 255), width=3)

for sign in (1.0, -1.0):
	root_fwd = to_px(sign * HALF_BEAM * 0.85, PECT_Z + 1.6)
	root_aft = to_px(sign * HALF_BEAM * 0.75, PECT_Z - 1.8)
	tip = to_px(sign * (HALF_BEAM + 3.4), PECT_Z - 0.6)
	draw.polygon([root_fwd, tip, root_aft], fill=(56, 24, 20, 255), outline=(15, 20, 26, 255), width=2)

tail_poly = [to_px(0, -HALF_L + 1.0), to_px(0.9, -HALF_L - 2.6), to_px(-0.9, -HALF_L - 2.6)]
draw.polygon(tail_poly, fill=(56, 24, 20, 255), outline=(15, 20, 26, 255), width=2)

bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote %s (%dx%d px, %.2f px/m)" % (PNG_PATH, CANVAS_W, CANVAS_H, SCALE))

# ---- PREVIEW_CAMERA entry, same formula as every other entry in
# main/outpost.gui_script: a (0, 3, 8) reference eye offset scaled by
# radius/6.34 (the hand-authored escort_interceptor hull's own bounding
# radius, the fixed distance the render script's default was tuned
# against), then a further flat 1.5x zoom-out on top. ----
scale = (radius / 6.34) * 1.5
eye = (0.0, 3.0 * scale, 8.0 * scale)
far = math.sqrt(eye[0] ** 2 + eye[1] ** 2 + eye[2] ** 2) + radius + 50.0
print()
print("PREVIEW_WORLD_POS entry:")
print('\t["/assets/models/escort_tactical/lionfish.model"] = vmath.vector3(100000, 24000, 0),')
print("PREVIEW_CAMERA entry:")
print('\t["/assets/models/escort_tactical/lionfish.model"] = { eye_offset = vmath.vector3(%.2f, %.2f, %.2f), far = %.2f },' % (eye[0], eye[1], eye[2], far))
