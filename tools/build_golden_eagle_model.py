#!/usr/bin/env python3
"""
Replaces Golden Eagle's (Swarm, Frigate class, Assault role) hull with an
ORIGINAL design, not sourced from anywhere - same rationale as
tools/build_lionfish_model.py and tools/build_pelican_model.py: the
previous golden_eagle.glb was a SuperShips-sourced, BSG-derived asset
(ships.lua's own header comment flagged it as a "Cylon"-faction "Jormung"
mesh), replaced here per direct instruction with a hand-authored hull
built to actually resemble the ship's own real-world namesake instead.

Leans into an actual golden eagle's own most recognizable features:
- a small downward-hooked BEAK at the very nose - a raptor's beak curves
  down and back, unlike a straight fighter-craft point
- long, broad wings held at a dihedral (tips angled UP, a soaring raptor's
  own silhouette, not a flat fighter wing)
- a FANNED tail (three overlapping panels, spread at slightly different
  angles) rather than a single fin
- two small talons tucked under the belly, folded back
- warm golden-brown plumage with a darker brown wing/tail band and a
  lighter golden highlight on the head/nape, echoing the real bird's own
  two-tone coloring (dark body, lighter golden nape) - visible in the live
  preview now that render/custom.render_script's leftover diagnostic red
  tint override has been removed.

Same technique as the other hand-authored hulls: flat-shaded low-poly
geometry, vertex colors via a small palette texture, embedded in a real
binary .glb. Units: meters, 1 Defold unit = 1 meter.

Run from the project root: `python3 tools/build_golden_eagle_model.py`
(needs Pillow). Writes:
  assets/models/frigate_assault/golden_eagle.glb
  assets/models/frigate_assault/golden_eagle_palette.png
  main/images/frigate_assault_golden_eagle_topdown.png
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
GLB_PATH = os.path.join(ROOT, "assets", "models", "frigate_assault", "golden_eagle.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "frigate_assault", "golden_eagle_palette.png")
PNG_PATH = os.path.join(ROOT, "main", "images", "frigate_assault_golden_eagle_topdown.png")


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


# ---- Hull dimensions (meters) - Frigate class, same tier as Pelican, but
# a leaner body and much wider wingspan (BEAM), fitting a soaring raptor
# rather than a bulky support hull. ----
LENGTH = 40.0
BEAM = 18.0
DECK_Y = 1.4
KEEL_Y = -1.4
HALF_L = LENGTH / 2.0
HALF_BEAM = BEAM / 2.0

# Lean, tapered body - a raptor's compact torso, not a fighter's flat taper.
OUTLINE = [
	(0.0, HALF_L),                       # nose (the hooked beak sits ahead of this, see below)
	(HALF_BEAM * 0.17, HALF_L - 6.0),    # head/neck
	(HALF_BEAM * 0.33, HALF_L - 11.5),   # neck widening into shoulders
	(HALF_BEAM * 0.5, HALF_L - 18.0),    # shoulder, body widest starts
	(HALF_BEAM * 0.5, HALF_L - 27.0),    # body widest continues
	(HALF_BEAM * 0.32, HALF_L - 33.0),   # tapering toward the tail
	(HALF_BEAM * 0.13, -HALF_L),         # tail root corner
	(-HALF_BEAM * 0.13, -HALF_L),
	(-HALF_BEAM * 0.32, HALF_L - 33.0),
	(-HALF_BEAM * 0.5, HALF_L - 27.0),
	(-HALF_BEAM * 0.5, HALF_L - 18.0),
	(-HALF_BEAM * 0.33, HALF_L - 11.5),
	(-HALF_BEAM * 0.17, HALF_L - 6.0),
]

HULL_COLOR = (0.58, 0.39, 0.17, 1.0)    # golden-brown body
WING_COLOR = (0.30, 0.19, 0.10, 1.0)    # darker brown wing/tail band
NAPE_COLOR = (0.78, 0.61, 0.30, 1.0)    # lighter golden head/nape highlight
TALON_COLOR = (0.14, 0.14, 0.15, 1.0)   # beak hook + talons

PALETTE_W = 4
PALETTE_H = 1
COLOR_UV = {
	HULL_COLOR: (0.5 / PALETTE_W, 0.5),
	WING_COLOR: (1.5 / PALETTE_W, 0.5),
	NAPE_COLOR: (2.5 / PALETTE_W, 0.5),
	TALON_COLOR: (3.5 / PALETTE_W, 0.5),
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


# ---- Body, with a lighter golden nape patch on top just behind the head ----
add_prism(OUTLINE, KEEL_Y, DECK_Y, HULL_COLOR)
add_box(-1.6, 1.6, DECK_Y - 0.05, DECK_Y + 0.35, HALF_L - 11.5, HALF_L - 4.0, NAPE_COLOR, "nape")

# ---- Hooked beak: a small spike jutting forward from the nose then
# hooking DOWN - unlike Lionfish's forward-only spines, this one's tip
# is offset both forward (+Z) and below centerline (-Y), the same
# down-and-back curve a real raptor's beak has. ----
add_spike(0.0, DECK_Y * 0.2, HALF_L, 0.55, 0.0, -1.8, HALF_L + 1.6, TALON_COLOR, "beak")

# ---- Wings: broad and swept, held at a DIHEDRAL (wingtip Y rises above
# the root) - a soaring raptor's own silhouette, not a flat fighter wing.
# A small extra spike at each tip stands in for spread primary feathers. ----
WING_ROOT_Z = HALF_L - 22.0
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	root_fwd = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z + 7.0)
	root_aft = (sign * HALF_BEAM * 0.5, 0.0, WING_ROOT_Z - 7.5)
	tip = (sign * (HALF_BEAM + 11.5), 2.6, WING_ROOT_Z - 2.5)
	add_double_tri(root_fwd, tip, root_aft, WING_COLOR, "wing_%s" % side)
	feather_base = (sign * (HALF_BEAM + 8.0), 2.0, WING_ROOT_Z - 4.5)
	add_spike(feather_base[0], feather_base[1], feather_base[2], 0.4,
		sign * (HALF_BEAM + 14.0), 2.9, WING_ROOT_Z - 7.5, WING_COLOR, "feather_%s" % side)

# ---- Fanned tail: three overlapping panels spread at different angles,
# not a single fin - a raptor's tail fans out in flight. The center blade
# (spread_x=0) needs its own nonzero `width` for the side_offset point -
# root/tip/side_offset would otherwise all sit exactly on the z-axis (x=0,
# y=0), a zero-area degenerate triangle that fails glTF's normal-must-be-
# unit-length validation (caught at build time, not by this script itself
# - math.sqrt(0) silently produced a (0,0,0) "normal" instead of erroring).
TAIL_ROOT_Z = -HALF_L + 3.5
for i, spread_x in enumerate((0.0, 2.6, -2.6)):
	root = (0.0, 0.0, TAIL_ROOT_Z)
	tip = (spread_x, 0.0, -HALF_L - 4.5)
	width = spread_x * 0.35 if spread_x != 0.0 else 0.4
	side_offset = (width, 0.0, TAIL_ROOT_Z - 1.0)
	add_double_tri(root, tip, side_offset, WING_COLOR, "tail_%d" % i)

# ---- Talons: two small spikes tucked under the belly, folded back (tip
# points down and toward the stern, like a raptor's talons drawn up
# beneath it in flight) ----
for side, sign in (("stbd", 1.0), ("port", -1.0)):
	add_spike(sign * 1.8, KEEL_Y, HALF_L - 20.0, 0.35,
		sign * 2.4, KEEL_Y - 2.2, HALF_L - 24.0, TALON_COLOR, "talon_%s" % side)

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
for i, color in enumerate((HULL_COLOR, WING_COLOR, NAPE_COLOR, TALON_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - golden eagle hull, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "golden_eagle_hull"}],
	"meshes": [{
		"name": "golden_eagle_hull",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "golden_eagle_flat",
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

CANVAS_W, CANVAS_H = 320, 640
PAD_Y = 60
SCALE = (CANVAS_H - PAD_Y) / (LENGTH + 10)


def to_px(x, z):
	px = CANVAS_W / 2.0 + x * SCALE
	py = CANVAS_H / 2.0 - z * SCALE
	return px, py


img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

deck_poly = [to_px(x, z) for x, z in OUTLINE]
draw.polygon(deck_poly, fill=(148, 100, 43, 255), outline=(15, 20, 26, 255), width=3)

nape_poly = [to_px(-1.6, HALF_L - 4.0), to_px(1.6, HALF_L - 4.0), to_px(1.6, HALF_L - 11.5), to_px(-1.6, HALF_L - 11.5)]
draw.polygon(nape_poly, fill=(199, 156, 77, 255), outline=(15, 20, 26, 255), width=1)

beak_poly = [to_px(-0.55, HALF_L), to_px(0.55, HALF_L), to_px(0.0, HALF_L + 1.6)]
draw.polygon(beak_poly, fill=(36, 36, 38, 255), outline=(15, 20, 26, 255), width=2)

for sign in (1.0, -1.0):
	root_fwd = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z + 7.0)
	root_aft = to_px(sign * HALF_BEAM * 0.5, WING_ROOT_Z - 7.5)
	tip = to_px(sign * (HALF_BEAM + 11.5), WING_ROOT_Z - 2.5)
	draw.polygon([root_fwd, tip, root_aft], fill=(77, 49, 26, 255), outline=(15, 20, 26, 255), width=2)
	feather_tip = to_px(sign * (HALF_BEAM + 14.0), WING_ROOT_Z - 7.5)
	feather_base = to_px(sign * (HALF_BEAM + 8.0), WING_ROOT_Z - 4.5)
	draw.line([feather_base, feather_tip], fill=(77, 49, 26, 255), width=3)

for spread_x in (0.0, 2.6, -2.6):
	root = to_px(0.0, TAIL_ROOT_Z)
	tip = to_px(spread_x, -HALF_L - 4.5)
	draw.line([root, tip], fill=(77, 49, 26, 255), width=4)

bx, by = to_px(0, HALF_L)
draw.line([(bx, by), (bx, by - 14)], fill=(230, 235, 240, 255), width=3)

img.save(PNG_PATH)
print("Wrote %s (%dx%d px, %.2f px/m)" % (PNG_PATH, CANVAS_W, CANVAS_H, SCALE))

scale = (radius / 6.34) * 1.5
eye = (0.0, 3.0 * scale, 8.0 * scale)
far = math.sqrt(eye[0] ** 2 + eye[1] ** 2 + eye[2] ** 2) + radius + 50.0
print()
print("PREVIEW_CAMERA entry (PREVIEW_WORLD_POS unchanged - same model path):")
print('\t["/assets/models/frigate_assault/golden_eagle.model"] = { eye_offset = vmath.vector3(%.2f, %.2f, %.2f), far = %.2f },' % (eye[0], eye[1], eye[2], far))
