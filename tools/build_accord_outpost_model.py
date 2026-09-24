#!/usr/bin/env python3
"""
Accord outpost - a basic ORIGINAL shape, per direct instruction: a cuboid
that "vaguely represents a fish tank" (fits the Accord's own fish naming
theme, §2.1.2), about 1000 units long overall. Same low-poly/vertex-color
GLB-writing technique as the ship hull builders (e.g.
tools/build_sardine_model.py) - flat-shaded geometry, a small palette
texture, embedded in a real binary .glb. Deliberately basic (per direct
instruction: "let's begin by building two basic shapes") - just two
stacked boxes, a dark stand under a lighter glass-tinted main volume, not a
detailed structure.

Units: meters (1 Defold unit = 1 meter, same convention every ship hull
uses). Orientation: long axis along Z, resting on Y=0 (matches
main/data/star_systems.lua's own outpost-position convention - Y is up,
X/Z are the horizontal plane a station would actually sit on).

Run from the project root: `python3 tools/build_accord_outpost_model.py`
(needs Pillow). Writes:
  assets/models/outposts/accord_outpost.glb
  assets/models/outposts/accord_outpost_palette.png
"""
import io
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_PATH = os.path.join(ROOT, "assets", "models", "outposts", "accord_outpost.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "outposts", "accord_outpost_palette.png")


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


# ---- Dimensions (meters) - overall length ~1000 (per direct instruction),
# a plain rectangular footprint (no taper/hull shaping - a "basic shape",
# not a ship). ----
LENGTH = 1000.0        # Z extent (the stand's own length - the widest part)
STAND_WIDTH = 300.0     # X extent of the stand
STAND_HEIGHT = 60.0     # Y extent of the stand (0 to STAND_HEIGHT)
BODY_LENGTH = 960.0     # Z extent of the glass-tinted main volume, slightly inset from the stand's own ends
BODY_WIDTH = 260.0      # X extent of the main volume, slightly inset from the stand's own sides
BODY_HEIGHT = 300.0     # Y extent of the main volume, sits on top of the stand

HALF_L = LENGTH / 2.0
HALF_SW = STAND_WIDTH / 2.0
HALF_BL = BODY_LENGTH / 2.0
HALF_BW = BODY_WIDTH / 2.0

STAND_OUTLINE = [(-HALF_SW, -HALF_L), (HALF_SW, -HALF_L), (HALF_SW, HALF_L), (-HALF_SW, HALF_L)]
BODY_OUTLINE = [(-HALF_BW, -HALF_BL), (HALF_BW, -HALF_BL), (HALF_BW, HALF_BL), (-HALF_BW, HALF_BL)]

# Accord's own established faction blue (main/faction_select.gui's
# "accord_button" color) for the stand; a lighter cyan/teal "glass/water"
# tint - distinct from the faction blue - for the main volume, since a
# flat single-color box wouldn't read as "vaguely a fish tank" at all.
STAND_COLOR = (0.16, 0.32, 0.55, 1.0)
BODY_COLOR = (0.30, 0.62, 0.64, 1.0)

PALETTE_W = 2
PALETTE_H = 1
COLOR_UV = {
	STAND_COLOR: (0.5 / PALETTE_W, 0.5),
	BODY_COLOR: (1.5 / PALETTE_W, 0.5),
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


add_prism(STAND_OUTLINE, 0.0, STAND_HEIGHT, STAND_COLOR)
add_prism(BODY_OUTLINE, STAND_HEIGHT, STAND_HEIGHT + BODY_HEIGHT, BODY_COLOR)

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
for i, color in enumerate((STAND_COLOR, BODY_COLOR)):
	palette_img.putpixel((i, 0), to_8bit(color))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - Accord outpost, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "accord_outpost"}],
	"meshes": [{
		"name": "accord_outpost",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "accord_outpost_flat",
		"pbrMetallicRoughness": {
			"baseColorFactor": [1, 1, 1, 1],
			"baseColorTexture": {"index": 0},
			"metallicFactor": 0.0,
			"roughnessFactor": 0.75,
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
