"""Read this project's single-mesh GLBs without altering their geometry."""
import json
import struct
from fleet.geometry import Mesh


def read_mesh(ship, path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + length])
    binary = raw[28 + length:]
    primitive = doc['meshes'][0]['primitives'][0]
    mesh = Mesh(ship)
    def values(index):
        a = doc['accessors'][index]
        v = doc['bufferViews'][a['bufferView']]
        width = {'VEC3': 3, 'VEC2': 2, 'SCALAR': 1}[a['type']]
        kind = {5126: 'f', 5123: 'H'}[a['componentType']]
        offset = v.get('byteOffset', 0) + a.get('byteOffset', 0)
        size = a['count'] * width * (4 if kind == 'f' else 2)
        rows = list(struct.iter_unpack('<' + kind * width, binary[offset:offset + size]))
        return [r[0] for r in rows] if width == 1 else rows
    for field, attribute in [('p', 'POSITION'), ('n', 'NORMAL'), ('uv', 'TEXCOORD_0')]:
        setattr(mesh, field, values(primitive['attributes'][attribute]))
    mesh.idx = values(primitive['indices'])
    return mesh
