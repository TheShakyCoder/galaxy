"""Blender: render a top-down 2D underlay for every fleet ship.

The outpost Fitting screen draws the active ship under its slot markers in
the `ship_visual` box (main/outpost.gui, 440 x 640 design px). This renders
each ship in artifacts/fleet/manifest.json straight down from above, bow up,
starboard (glTF -X) to the right - the same frame slot_positions use - with
its own texture unlit and outlined on a transparent background, uniformly
scaled to fit the box. Writes main/images/topdown/<model name>.png and
topdown.json (pixels per metre and hull extents).

The PNGs are reduced to a 256-colour palette with ImageMagick (4.8 MB ->
~0.6 MB for all 24, no visible loss on these flat-shaded renders) and ship as
custom resources, not an atlas: main/outpost.gui_script loads only the
active ship's image at runtime, which keeps both the web download and GPU
memory small (an atlas would add ~4 MB and ~30 MB respectively).

Run: blender --background --python tools/render_topdown_silhouettes.py
"""
import bpy
import json
import math
import subprocess
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'main/images/topdown'
OUT.mkdir(parents=True, exist_ok=True)
WIDTH, HEIGHT, MARGIN = 440, 640, 10

rows = json.loads((ROOT / 'artifacts/fleet/manifest.json').read_text())['ships']
meta = {}
for row in rows:
    name = Path(row['model']).stem
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / row['glb']))

    # World-space bounds from the evaluated meshes, so nested node
    # transforms (e.g. sardine.glb's 100x/0.01x pair) are accounted for.
    depsgraph = bpy.context.evaluated_depsgraph_get()
    lo = Vector((math.inf,) * 3)
    hi = Vector((-math.inf,) * 3)
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH':
            continue
        ev = ob.evaluated_get(depsgraph)
        for v in ev.to_mesh().vertices:
            p = ev.matrix_world @ v.co
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
        ev.to_mesh_clear()

    # Blender space after glTF import: x = glTF x, -y = glTF +z (bow), z = up.
    width_m, length_m = hi.x - lo.x, hi.y - lo.y
    scale = min((WIDTH - 2 * MARGIN) / width_m, (HEIGHT - 2 * MARGIN) / length_m)

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'FLAT'
    scene.display.shading.color_type = 'TEXTURE'
    scene.display.shading.show_object_outline = True
    scene.display.shading.object_outline_color = (0.03, 0.04, 0.06)
    scene.render.film_transparent = True
    scene.render.resolution_x, scene.render.resolution_y = WIDTH, HEIGHT
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.view_settings.view_transform = 'Standard'

    cam = bpy.data.cameras.new('Top')
    cam.type = 'ORTHO'
    cam.ortho_scale = HEIGHT / scale  # the taller axis spans ortho_scale metres
    cam.clip_end = (hi.z - lo.z) + 1000
    ob = bpy.data.objects.new('Top', cam)
    scene.collection.objects.link(ob)
    ob.location = ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z + 500)
    ob.rotation_euler = (0, 0, math.pi)  # image up = -Y (bow), right = -X (starboard)
    scene.camera = ob

    scene.render.filepath = str(OUT / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    subprocess.run(['magick', scene.render.filepath, '-colors', '256',
                    'PNG8:' + scene.render.filepath], check=True)
    meta[name] = {
        'ship': row['name'],
        'class': row['class'],
        'role': row['role'],
        'faction': row['faction'],
        'px_per_m': round(scale, 4),
        'hull_px': [round(width_m * scale, 1), round(length_m * scale, 1)],
    }
    print('TOPDOWN_RENDERED ' + name, flush=True)

(OUT / 'topdown.json').write_text(json.dumps(meta, indent=1, sort_keys=True) + '\n')
