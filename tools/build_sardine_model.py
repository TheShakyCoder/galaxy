#!/usr/bin/env python3
"""
Replaces Sardine's (Accord, Patrol class, Interceptor role) hull with an
ORIGINAL design, not sourced from anywhere - same rationale as
tools/build_lionfish_model.py, build_pelican_model.py, and
build_golden_eagle_model.py: the previous sardine.glb was a SuperShips-
sourced, BSG-derived asset - ships.lua's own header comment calls it out as
the single most-flagged asset in the whole file ("HIGHEST-SEVERITY §0
EXCEPTION... the EXACT named pair this comment block has always cited as
the paradigm example of what §0 excludes - 'Viper Mk II/Cylon Raider'").
Replaced here per direct instruction with a hand-authored hull built to
actually resemble the ship's own real-world namesake instead.

Leans into an actual sardine's own most recognizable features:
- a slender, tapered FUSIFORM (torpedo-shaped) body - a small schooling
  fish's own classic silhouette, not a fighter-craft wedge
- a FORKED tail (two swept lobes with a V-notch between them, not a single
  fin) - the defining herring-family tail shape
- a single small dorsal fin and a pair of small pectoral fins near the head
- a two-tone body: a darker blue-green back over a lighter silver belly,
  the actual counter-shading real sardines have (dark from above, bright
  from below) - split at the hull's own centerline, visible now that
  render/custom.render_script's leftover diagnostic red tint override has
  been removed (§2.8.9, resolved alongside build_pelican_model.py)
- deliberately the SMALLEST hull built so far, matching Patrol's own place
  as the smallest class in the roster and Interceptor's fast/agile role

Same technique as the other hand-authored hulls: flat-shaded low-poly
geometry, vertex colors via a small palette texture, embedded in a real
binary .glb. Units: meters, 1 Defold unit = 1 meter.

Run from the project root: `python3 tools/build_sardine_model.py`
(needs Pillow). Writes:
  assets/models/patrol_interceptor/sardine.glb
  assets/models/patrol_interceptor/sardine_palette.png
  main/images/patrol_interceptor_sardine_topdown.png
Also prints the bounding-sphere radius and a ready-to-paste PREVIEW_CAMERA
entry for main/outpost.gui_script (PREVIEW_WORLD_POS stays unchanged -
same model path, same off-world rig position).
"""
import io
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_PATH = os.path.join(ROOT, "assets", "models", "patrol_interceptor", "sardine.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "patrol_interceptor", "sardine_palette.png")
PNG_PATH = os.path.join(ROOT, "main", "images", "patrol_interceptor_sardine_topdown.png")


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


# ---- Hull dimensions (meters) - Patrol class, the SMALLEST hull tier in
# the roster, noticeably smaller than Lionfish's 20m Escort hull. ----
LENGTH = 14.0
BEAM = 3.2
DECK_Y = 0.85
KEEL_Y = -0.85
HALF_L = LENGTH / 2.0
HALF_BEAM = BEAM / 2.0

# 11-point deck/keel outline (x, z), nose at +Z: a classic small-fish
# fusiform taper - narrow head, widest just aft of the gills, tapering to a
# slender tail stock (peduncle) that the forked tail attaches to.
OUTLINE = [
	(0.0, HALF_L),                        # nose tip
	(HALF_BEAM * 0.55, HALF_L - 1.7),     # head widening
	(HALF_BEAM * 0.92, HALF_L - 3.3),     # gill line, nearly full beam
	(HALF_BEAM, HALF_L - 4.8),            # body widest point
	(HALF_BEAM * 0.85, HALF_L - 7.5),     # body still broad
	(HALF_BEAM * 0.5, HALF_L - 10.0),     # narrowing toward the tail stock
	(HALF_BEAM * 0.22, -HALF_L + 1.2),    # slender tail stock (peduncle)
	(-HALF_BEAM * 0.22, -HALF_L + 1.2),
	(-HALF_BEAM * 0.5, HALF_L - 10.0),
	(-HALF_BEAM * 0.85, HALF_L - 7.5),
	(-HALF_BEAM, HALF_L - 4.8),
	(-HALF_BEAM * 0.92, HALF_L - 3.3),
	(-HALF_BEAM * 0.55, HALF_L - 1.7),
]

BACK_COLOR = (0.16, 0.30, 0.40, 1.0)    # darker blue-green back
BELLY_COLOR = (0.66, 0.72, 0.76, 1.0)   # lighter silver belly (real countershading)
FIN_COLOR = (0.13, 0.22, 0.28, 1.0)     # dorsal/pectoral/tail fins

PALETTE_W = 3
PALETTE_H = 1
COLOR_UV = {
	BACK_COLOR: (0.5 / PALETTE_W, 0.5),
	BELLY_COLOR: (1.5 / PALETTE_W, 0.5),
	FIN_COLOR: (2.5 / PALETTE_W, 0.5),
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


# ---- Body: split at the vertical centerline into a darker back (top half)
# and lighter belly (bottom half) - real countershading, not a flat color. ----
BODY_MID_OUTLINE = [(x * 0.97, z) for x, z in OUTLINE]  # a hair narrower at the midline seam, avoids a visible seam gap
add_prism(OUTLINE, 0.0, DECK_Y, BACK_COLOR)
add_prism(BODY_MID_OUTLINE, KEEL_Y, 0.0, BELLY_COLOR)

# ---- Dorsal fin: one small triangular fin, mid-back ----
dorsal_root_fwd = (0.0, DECK_Y * 0.3, HALF_L - 4.5)
dorsal_root_aft = (0.0, DECK_Y * 0.3, HALF_L - 7.0)
dorsal_tip = (0.0, DECK_Y + 1.6, HALF_L - 5.7)
add_double_tri(dorsal_root_fwd, dorsal_tip, dorsal_root_aft, FIN_COLOR, "dorsal")

# ---- Pectoral fins: small fins near the head, swept back ----
PECT_Z = HALF_L - 3.6
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_fwd = (sign * HALF_BEAM * 0.7, -0.1, PECT_Z + 0.6)
	root_aft = (sign * HALF_BEAM * 0.6, -0.1, PECT_Z - 0.9)
	tip = (sign * (HALF_BEAM + 1.7), -0.3, PECT_Z - 0.4)
	add_double_tri(root_fwd, tip, root_aft, FIN_COLOR, "pect_%s" % side)

# ---- Forked tail: two swept lobes from the tail stock, a V-notch left
# open between them - the defining herring-family tail shape, not a
# single fin. ----
TAIL_ROOT_Z = -HALF_L + 1.2
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_inner = (sign * 0.12, 0.0, TAIL_ROOT_Z)
	root_outer = (sign * HALF_BEAM * 0.22, 0.0, TAIL_ROOT_Z + 0.3)
	tip = (sign * 1.7, 0.0, -HALF_L - 2.2)
	add_double_tri(root_outer, tip, root_inner, FIN_COLOR, "tail_%s" % side)

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
	length = math.sqrt(nx * nx + ny * ny + nz * nz)
	if length < 1e-9:
		raise ValueError("degenerate face (zero-area triangle): %r" % (poly_verts,))
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
for i, color in enumerate((BACK_COLOR, BELLY_COLOR, FIN_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - sardine hull, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "sardine_hull"}],
	"meshes": [{
		"name": "sardine_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "sardine_flat",
		"pbrMetallicRoughness": {
			"baseColorFactor": [1, 1, 1, 1],
			"baseColorTexture": {"index": 0},
			"metallicFactor": 0.0,
			"roughnessFactor": 0.85,
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

CANVAS_W, CANVAS_H = 260, 640
PAD_Y = 60
SCALE = (CANVAS_H - PAD_Y) / (LENGTH + 5)


def to_px(x, z):
	px = CANVAS_W / 2.0 + x * SCALE
	py = CANVAS_H / 2.0 - z * SCALE
	return px, py


img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

deck_poly = [to_px(x, z) for x, z in OUTLINE]
draw.polygon(deck_poly, fill=(41, 77, 102, 255), outline=(15, 20, 26, 255), width=3)

dorsal_poly = [to_px(0.0, HALF_L - 4.5), to_px(0.35, HALF_L - 5.7), to_px(0.0, HALF_L - 7.0)]
draw.polygon(dorsal_poly, fill=(33, 56, 71, 255), outline=(15, 20, 26, 255), width=1)

for sign in (1.0, -1.0):
	root_fwd = to_px(sign * HALF_BEAM * 0.7, PECT_Z + 0.6)
	root_aft = to_px(sign * HALF_BEAM * 0.6, PECT_Z - 0.9)
	tip = to_px(sign * (HALF_BEAM + 1.7), PECT_Z - 0.4)
	draw.polygon([root_fwd, tip, root_aft], fill=(33, 56, 71, 255), outline=(15, 20, 26, 255), width=1)
	root_inner = to_px(sign * 0.12, TAIL_ROOT_Z)
	root_outer = to_px(sign * HALF_BEAM * 0.22, TAIL_ROOT_Z + 0.3)
	tail_tip = to_px(sign * 1.7, -HALF_L - 2.2)
	draw.polygon([root_outer, tail_tip, root_inner], fill=(33, 56, 71, 255), outline=(15, 20, 26, 255), width=1)

bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote %s (%dx%d px, %.2f px/m)" % (PNG_PATH, CANVAS_W, CANVAS_H, SCALE))

scale = (radius / 6.34) * 1.5
eye = (0.0, 3.0 * scale, 8.0 * scale)
far = math.sqrt(eye[0] ** 2 + eye[1] ** 2 + eye[2] ** 2) + radius + 50.0
print()
print("PREVIEW_CAMERA entry (PREVIEW_WORLD_POS unchanged - same model path):")
print('\t["/assets/models/patrol_interceptor/patrol_interceptor.model"] = { eye_offset = vmath.vector3(%.2f, %.2f, %.2f), far = %.2f },' % (eye[0], eye[1], eye[2], far))
