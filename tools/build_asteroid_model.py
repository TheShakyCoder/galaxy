#!/usr/bin/env python3
"""
Asteroid - a basic ORIGINAL shape, per direct instruction: "represent the
asteroids as spheres for now". Same low-poly/flat-shaded/vertex-color
GLB-writing technique as the ship hull and outpost builders (e.g.
tools/build_swarm_outpost_model.py) - a plain UV sphere (8 latitude bands x
12 longitude segments), one flat rock color, no greebling/craters/detail.

Built at UNIT DIAMETER (1m, i.e. radius 0.5) centered on the origin, NOT at
any particular asteroid's real size - main/data/asteroids.lua's generator
picks each instance's actual diameter (5-50m, per direct instruction) and
that becomes this prototype's `scale3` at spawn time (factory.create's own
`scale` argument, applied uniformly), so one shared mesh covers every size
rather than baking N separate GLBs.

Units: meters. Orientation: sphere, so no meaningful "forward"/"up" - Y is
still this project's up axis for consistency, not that it matters for a
sphere.

Run from the project root: `python3 tools/build_asteroid_model.py` (needs
Pillow). Writes:
  assets/models/asteroids/asteroid.glb
  assets/models/asteroids/asteroid_palette.png
"""
import io
import json
import math
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB_PATH = os.path.join(ROOT, "assets", "models", "asteroids", "asteroid.glb")
PALETTE_PATH = os.path.join(ROOT, "assets", "models", "asteroids", "asteroid_palette.png")


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


# ---- Dimensions (meters) - unit diameter, see header comment. ----
RADIUS = 0.5
LAT_SEGMENTS = 8   # latitude bands, pole to pole
LON_SEGMENTS = 12  # longitude segments around

ROCK_COLOR = (0.40, 0.36, 0.33, 1.0)  # flat muted gray-brown, no palette variation needed for a single-color shape

PALETTE_W = 1
PALETTE_H = 1
COLOR_UV = {
	ROCK_COLOR: (0.5 / PALETTE_W, 0.5),
}


def to_8bit(color):
	return tuple(round(c * 255) for c in color)


def sphere_point(theta, phi):
	# theta = polar angle from +Y (0 at the top pole, pi at the bottom),
	# phi = azimuth around Y. Standard Y-up spherical-to-Cartesian.
	return (
		RADIUS * math.sin(theta) * math.cos(phi),
		RADIUS * math.cos(theta),
		RADIUS * math.sin(theta) * math.sin(phi),
	)


TOP_POLE = (0.0, RADIUS, 0.0)
BOTTOM_POLE = (0.0, -RADIUS, 0.0)
# Intermediate latitude rings only (poles are single points, handled as fans
# below) - LAT_SEGMENTS-1 rings, each LON_SEGMENTS points around.
RINGS = [
	[sphere_point(math.pi * ring / LAT_SEGMENTS, 2 * math.pi * col / LON_SEGMENTS) for col in range(LON_SEGMENTS)]
	for ring in range(1, LAT_SEGMENTS)
]

verts = []
faces = []


def add_vert(p, color):
	verts.append(p + color)
	return len(verts) - 1


# Top/bottom pole fans and the quad bands between rings all need to wind so
# their cross-product normal points radially outward (away from the
# origin, same direction as the vertex position itself, since this is a
# sphere centered on the origin) - hand-derived and numerically verified
# (not just copied from the cylinder builders, whose winding doesn't
# transfer directly to a sphere's pole singularities):
#  - top pole fan: [pole, ring0[next], ring0[i]]      (note the swap)
#  - bottom pole fan: [pole, ring_last[i], ring_last[next]]  (no swap)
#  - quad band: [ring_a[i], ring_a[next], ring_b[next], ring_b[i]]
top_ring = RINGS[0]
for i in range(LON_SEGMENTS):
	nxt = (i + 1) % LON_SEGMENTS
	a = add_vert(TOP_POLE, ROCK_COLOR)
	b = add_vert(top_ring[nxt], ROCK_COLOR)
	c = add_vert(top_ring[i], ROCK_COLOR)
	faces.append(("top_%d" % i, [a, b, c], ROCK_COLOR))

for ring_idx in range(len(RINGS) - 1):
	ring_a = RINGS[ring_idx]
	ring_b = RINGS[ring_idx + 1]
	for i in range(LON_SEGMENTS):
		nxt = (i + 1) % LON_SEGMENTS
		a = add_vert(ring_a[i], ROCK_COLOR)
		b = add_vert(ring_a[nxt], ROCK_COLOR)
		c = add_vert(ring_b[nxt], ROCK_COLOR)
		d = add_vert(ring_b[i], ROCK_COLOR)
		faces.append(("band_%d_%d" % (ring_idx, i), [a, b, c, d], ROCK_COLOR))

bottom_ring = RINGS[-1]
for i in range(LON_SEGMENTS):
	nxt = (i + 1) % LON_SEGMENTS
	a = add_vert(BOTTOM_POLE, ROCK_COLOR)
	b = add_vert(bottom_ring[i], ROCK_COLOR)
	c = add_vert(bottom_ring[nxt], ROCK_COLOR)
	faces.append(("bottom_%d" % i, [a, b, c], ROCK_COLOR))

print("Unique vertices: %d, faces (polygons): %d" % (len(verts), len(faces)))

xs = [v[0] for v in verts]
ys = [v[1] for v in verts]
zs = [v[2] for v in verts]
print("Bounding box (m): X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
	min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))


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
palette_img.putpixel((0, 0), to_8bit(ROCK_COLOR))
_buf_io = io.BytesIO()
palette_img.save(_buf_io, format="PNG")
img_view = add_view(_buf_io.getvalue(), None)

NEAREST = 9728
CLAMP_TO_EDGE = 33071

gltf = {
	"asset": {"version": "2.0", "generator": "Galaxy - Asteroid, hand-authored, original design"},
	"scene": 0,
	"scenes": [{"nodes": [0]}],
	"nodes": [{"mesh": 0, "name": "asteroid"}],
	"meshes": [{
		"name": "asteroid",
		"primitives": [{
			"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2, "TEXCOORD_0": 3},
			"indices": 4,
			"material": 0,
			"mode": 4,
		}],
	}],
	"materials": [{
		"name": "asteroid_flat",
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

os.makedirs(os.path.dirname(GLB_PATH), exist_ok=True)
write_glb(GLB_PATH, gltf, buf)
print("Wrote %s (%d bytes buffer, %d triangles)" % (GLB_PATH, len(buf), len(indices) // 3))

palette_img.save(PALETTE_PATH)
print("Wrote %s (%dx%d px)" % (PALETTE_PATH, PALETTE_W, PALETTE_H))
