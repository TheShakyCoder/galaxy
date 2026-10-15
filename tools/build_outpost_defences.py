#!/usr/bin/env python3
"""Placeholder models for outpost defences, and their scene objects.

plan.md §2.7 "Outpost progression": each faction's outpost gets a jump beacon
and up to 4 sentry platforms (light / medium / heavy). Until real art exists
these are simple box shapes, textured with the faction's station hull atlas
(assets/models/stations/<faction>/hull.png) so they read as station hardware
in the faction's colours.

Writes:
  assets/models/outpost_defences/<faction>/{light,medium,heavy,beacon}.glb/.model
  main/main.collection - the block between "# OUTPOST DEFENCES BEGIN/END":
    <faction>_beacon (component "model") and <faction>_platform1..4 (components
    "light", "medium", "heavy" - main/player_ship.script shows the one the
    server's state names). Rerunning replaces the block.

The .model paths must match main/data/outposts.lua BEACON.faction_skins and
main/data/sentry_platforms.lua faction_skins (tests/outposts_data_harness.lua
checks). Sizes follow each class's radius_m there. Geometry is metres, Y up.

Run from anywhere:  python3 tools/build_outpost_defences.py
"""
import json, re
from pathlib import Path
from build_stations import Mesh, ROOT, write

OUT = ROOT / 'assets/models/outpost_defences'
FACTIONS = ['accord', 'swarm']
# radius_m per class (main/data/sentry_platforms.lua) - the shape is scaled to it.
PLATFORMS = {'light': 20, 'medium': 28, 'heavy': 38}
BEACON_RADIUS = 40  # main/data/outposts.lua BEACON.data.radius_m
MATERIAL = '/builtins/materials/model.material'
BEGIN, END = '# OUTPOST DEFENCES BEGIN', '# OUTPOST DEFENCES END'


def platform(r, heavy_guns):
    """A squat armoured hub with four arms, a turret on each, and a mast."""
    m = Mesh()
    m.box((0, 0, 0), (r * 1.1, r * 0.45, r * 1.1), 'armor')
    m.box((0, r * 0.3, 0), (r * 0.6, r * 0.2, r * 0.6), 'navy')
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        arm = (dx * r * 0.75, 0, dz * r * 0.75)
        m.box(arm, (r * 0.5 if dx else r * 0.22, r * 0.18, r * 0.22 if dx else r * 0.5), 'dark')
        tip = (dx * r * 0.95, r * 0.12, dz * r * 0.95)
        m.box(tip, (r * 0.22, r * 0.2, r * 0.22), 'metal')
        barrel = (tip[0] + dx * r * 0.12, tip[1] + r * 0.06, tip[2] + dz * r * 0.12)
        m.box(barrel, (r * (0.3 if dx else 0.06) * heavy_guns, r * 0.06, r * (0.06 if dx else 0.3) * heavy_guns), 'machine')
    m.box((0, r * 0.55, 0), (r * 0.06, r * 0.5, r * 0.06), 'metal')
    m.box((0, r * 0.82, 0), (r * 0.14, r * 0.08, r * 0.14), 'cyan')
    return m


def beacon(r):
    """A tall lattice mast on a base, with a lamp on top."""
    m = Mesh()
    h = r * 2
    m.box((0, -h * 0.45, 0), (r * 0.7, r * 0.2, r * 0.7), 'navy')
    m.box((0, 0, 0), (r * 0.12, h * 0.9, r * 0.12), 'metal')
    for y in (-0.25, 0.05, 0.3):
        m.box((0, h * y, 0), (r * 0.6, r * 0.05, r * 0.05), 'dark')
        m.box((0, h * y, 0), (r * 0.05, r * 0.05, r * 0.6), 'dark')
    m.box((0, h * 0.47, 0), (r * 0.22, r * 0.18, r * 0.22), 'red')
    return m


def model_text(mesh_path, texture):
    return f'mesh: "{mesh_path}"\nmaterial: "{MATERIAL}"\ntextures: "{texture}"\nname: "outpost_defence"\n'


def component(cid, path):
    return f'components {{ id: "{cid}" component: "{path}" }}'


def instance(iid, data):
    return ('embedded_instances { id: ' + json.dumps(iid) + ' data: ' + json.dumps(data) + '\n'
            'position { x: 0.0 y: 0.0 z: 0.0 } rotation { x: 0.0 y: 0.0 z: 0.0 w: 1.0 } '
            'scale3 { x: 1.0 y: 1.0 z: 1.0 } }\n')


def main():
    block = ''
    for faction in FACTIONS:
        folder = OUT / faction
        folder.mkdir(parents=True, exist_ok=True)
        texture = f'/assets/models/stations/{faction}/hull.png'
        paths = {}
        shapes = {name: platform(r, 1.6 if name == 'heavy' else 1.0) for name, r in PLATFORMS.items()}
        shapes['beacon'] = beacon(BEACON_RADIUS)
        for name, mesh in shapes.items():
            mesh.save(folder / f'{name}.glb')
            write(folder / f'{name}.model', model_text(f'/assets/models/outpost_defences/{faction}/{name}.glb', texture))
            paths[name] = f'/assets/models/outpost_defences/{faction}/{name}.model'
        block += instance(f'{faction}_beacon', component('model', paths['beacon']))
        for slot in range(1, 5):
            data = '\n'.join(component(c, paths[c]) for c in PLATFORMS)
            block += instance(f'{faction}_platform{slot}', data)
    path = ROOT / 'main/main.collection'
    text = path.read_text()
    text = re.sub(r'\n' + re.escape(BEGIN) + r'.*?' + re.escape(END) + r'\n', '\n', text, flags=re.S)
    text = text.rstrip() + '\n\n' + BEGIN + '\n' + block + END + '\n'
    write(path, text)
    print('wrote', OUT.relative_to(ROOT), 'and', path.relative_to(ROOT))


if __name__ == '__main__':
    main()
