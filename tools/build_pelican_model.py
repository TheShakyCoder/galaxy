#!/usr/bin/env python3
"""
Replaces Pelican's (Swarm, Frigate class, Support role) hull with an
ORIGINAL design, not sourced from anywhere - same rationale as
tools/build_lionfish_model.py: the previous pelican.glb was a SuperShips-
sourced, BSG-derived asset (ships.lua's own header comment on this entry
flagged it as a "Cylon"-faction "Hel" mesh), replaced here per direct
instruction with a hand-authored hull built to actually resemble the
ship's own real-world namesake instead.

Leans hard into an actual pelican's own most recognizable features:
- a long, flattened, gently tapering BILL making up most of the bow
- a distended throat POUCH hanging underneath the bill/neck junction -
  doubles as a cargo/supply pod, a fitting read for this ship's Support
  role even though that's not why the shape was picked
- a bulky, rounded body aft of the bill (a pelican's own barrel chest)
  tapering to a short tail
- broad, only gently swept wings (a pelican soars on broad, flattish
  wings, not swept fighter wings)
- pale grey-white plumage with a black wingtip band and a warm
  orange-tan pouch/bill, the two-tone coloring real pelicans actually
  have - this is also the first ship in the roster whose material colors
  will actually be visible in the live preview (render/custom.render_script's
  leftover diagnostic red tint override was removed alongside this).

Same technique as the other hand-authored hulls: flat-shaded low-poly
geometry, vertex colors via a small palette texture, embedded in a real
binary .glb. Units: meters, 1 Defold unit = 1 meter.

Run from the project root: `python3 tools/build_pelican_model.py`
(needs Pillow). Writes:
  assets/models/frigate_support/pelican.glb
  assets/models/frigate_support/pelican_palette.png
  main/images/frigate_support_pelican_topdown.png
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
GLB_PATH = os.path.join(ROOT, "assets", "models", "frigate_support", "pelican.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "frigate_support", "pelican_palette.png")
PNG_PATH = os.path.join(ROOT, "main", "images", "frigate_support_pelican_topdown.png")


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


# ---- Hull dimensions (meters) - Frigate class, the largest hull tier in
# the roster so far, noticeably bigger than Lionfish's 20m Escort hull. ----
LENGTH = 42.0
BEAM = 16.0
DECK_Y = 1.6
KEEL_Y = -1.6
HALF_L = LENGTH / 2.0
HALF_BEAM = BEAM / 2.0

# 13-point deck/keel outline (x, z), bill tip at +Z: a long, narrow bill
# taking up nearly half the length, widening abruptly into a bulky rounded
# body, then tapering to a short tail - the real bird's own silhouette
# (long flat bill + fat body), not a fighter-jet taper.
OUTLINE = [
	(0.0, HALF_L),                        # bill tip
	(HALF_BEAM * 0.06, HALF_L - 7.0),     # bill, long and nearly parallel-sided
	(HALF_BEAM * 0.13, HALF_L - 13.0),    # bill root, just starting to flare
	(HALF_BEAM * 0.38, HALF_L - 19.0),    # neck/shoulder, body widening fast
	(HALF_BEAM * 0.5, HALF_L - 26.0),     # body widest point (barrel chest)
	(HALF_BEAM * 0.5, HALF_L - 33.0),     # body still near full width
	(HALF_BEAM * 0.4, HALF_L - 38.0),     # tapering toward the tail
	(HALF_BEAM * 0.16, -HALF_L),          # tail corner
	(-HALF_BEAM * 0.16, -HALF_L),         # tail corner (port)
	(-HALF_BEAM * 0.4, HALF_L - 38.0),
	(-HALF_BEAM * 0.5, HALF_L - 33.0),
	(-HALF_BEAM * 0.5, HALF_L - 26.0),
	(-HALF_BEAM * 0.38, HALF_L - 19.0),
	(-HALF_BEAM * 0.13, HALF_L - 13.0),
	(-HALF_BEAM * 0.06, HALF_L - 7.0),
]

HULL_COLOR = (0.70, 0.68, 0.62, 1.0)    # pale grey-white plumage
WING_COLOR = (0.16, 0.17, 0.19, 1.0)    # black wingtip band
POUCH_COLOR = (0.76, 0.44, 0.17, 1.0)   # warm orange-tan pouch/bill

PALETTE_W = 3
PALETTE_H = 1
COLOR_UV = {
	HULL_COLOR: (0.5 / PALETTE_W, 0.5),
	WING_COLOR: (1.5 / PALETTE_W, 0.5),
	POUCH_COLOR: (2.5 / PALETTE_W, 0.5),
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

# ---- Pouch: a distended pod hanging under the bill/neck junction, tapered
# fore and aft like a real gular pouch (not a plain box) - built as a
# 6-point outline extruded a short distance below the keel. ----
POUCH_Z0, POUCH_Z1 = HALF_L - 21.5, HALF_L - 8.0
POUCH_OUTLINE = [
	(0.0, POUCH_Z1),
	(1.6, POUCH_Z1 - 3.5),
	(2.1, (POUCH_Z0 + POUCH_Z1) / 2.0),
	(1.3, POUCH_Z0 + 2.0),
	(0.0, POUCH_Z0),
	(-1.3, POUCH_Z0 + 2.0),
	(-2.1, (POUCH_Z0 + POUCH_Z1) / 2.0),
	(-1.6, POUCH_Z1 - 3.5),
]
add_prism(POUCH_OUTLINE, KEEL_Y - 3.2, KEEL_Y + 0.4, POUCH_COLOR)

# ---- Wings: broad, only gently swept panels (a soaring bird's flattish
# wing, not a fighter's swept delta) ----
WING_ROOT_Z = HALF_L - 24.0
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_fwd = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z + 5.5)
	root_aft = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z - 6.5)
	tip_fwd = (sign * (HALF_BEAM + 9.5), -0.4, WING_ROOT_Z + 1.5)
	tip_aft = (sign * (HALF_BEAM + 9.0), -0.4, WING_ROOT_Z - 6.0)
	add_double_tri(root_fwd, tip_fwd, root_aft, HULL_COLOR, "wing_%s_fwd" % side)
	add_double_tri(root_aft, tip_fwd, tip_aft, WING_COLOR, "wing_%s_tip" % side)

# ---- Tail: a short, broad fin fanning out at the stern ----
tail_root_top = (0.0, DECK_Y + 0.2, -HALF_L + 4.0)
tail_root_bot = (0.0, KEEL_Y - 0.2, -HALF_L + 4.0)
tail_tip = (0.0, 0.0, -HALF_L - 2.0)
add_double_tri(tail_root_top, tail_tip, tail_root_bot, WING_COLOR, "tailfin")

print("Unique vertices: %d, faces (polygons): %d" % (len(verts), len(faces)))

xs = [v[0] for v in verts]
ys = [v[1] for v in verts]
zs = [v[2] for v in verts]
cx, cy, cz = (min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0, (min(zs) + max(zs)) / 2.0
radius = max(math.sqrt((x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2) for x, y, z in zip(xs, ys, zs))
print("Bounding box (m): X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
	min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
print("Bounding-sphere radius (m): %.2f" % radius)


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
for i, color in enumerate((HULL_COLOR, WING_COLOR, POUCH_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - pelican hull, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "pelican_hull"}],
	"meshes": [{
		"name": "pelican_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "pelican_flat",
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
draw.polygon(deck_poly, fill=(178, 173, 158, 255), outline=(15, 20, 26, 255), width=3)

pouch_poly = [to_px(x, z) for x, z in POUCH_OUTLINE]
draw.polygon(pouch_poly, fill=(194, 112, 43, 255), outline=(15, 20, 26, 255), width=2)

for sign in (1.0, -1.0):
	root_fwd = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z + 5.5)
	root_aft = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z - 6.5)
	tip_fwd = to_px(sign * (HALF_BEAM + 9.5), WING_ROOT_Z + 1.5)
	tip_aft = to_px(sign * (HALF_BEAM + 9.0), WING_ROOT_Z - 6.0)
	draw.polygon([root_fwd, tip_fwd, tip_aft, root_aft], fill=(41, 44, 49, 255), outline=(15, 20, 26, 255), width=2)

tail_poly = [to_px(0, -HALF_L + 4.0), to_px(1.4, -HALF_L - 2.0), to_px(-1.4, -HALF_L - 2.0)]
draw.polygon(tail_poly, fill=(41, 44, 49, 255), outline=(15, 20, 26, 255), width=2)

bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote %s (%dx%d px, %.2f px/m)" % (PNG_PATH, CANVAS_W, CANVAS_H, SCALE))

scale = (radius / 6.34) * 1.5
eye = (0.0, 3.0 * scale, 8.0 * scale)
far = math.sqrt(eye[0] ** 2 + eye[1] ** 2 + eye[2] ** 2) + radius + 50.0
print()
print("PREVIEW_CAMERA entry (PREVIEW_WORLD_POS unchanged - same model path):")
print('\t["/assets/models/frigate_support/pelican.model"] = { eye_offset = vmath.vector3(%.2f, %.2f, %.2f), far = %.2f },' % (eye[0], eye[1], eye[2], far))
