#!/usr/bin/env python3
"""Placeholder models for the NPC drones (plan.md §2.18).

One model per drone type (main/data/drones.lua MODELS), built from boxes
with the station mesh helper. Drones are deliberately built along the
VERTICAL axis rather than the horizontal one every player ship uses, so
they read as a different, machine-built faction at a glance. Textured with
the station hull atlas; main/drones.script tints them.

Writes assets/models/drones/<type>.glb + .model, and main/drone.go (the
factory prototype: one model component per type, main/drones.script shows
the right one). Sizes follow each type's radius_m. Geometry is metres, Y up,
+Z forward.

Run from anywhere:  python3 tools/build_drone_models.py
"""
from build_stations import Mesh, ROOT, write

OUT = ROOT / 'assets/models/drones'
TEXTURE = '/assets/models/stations/swarm/hull.png'
MATERIAL = '/builtins/materials/model.material'
RADIUS = {'scout': 10, 'sentry': 12, 'guard': 16, 'hunter': 14}  # main/data/drones.lua


def scout(r):
    """A slim vertical spindle with two swept fins and a sensor eye."""
    m = Mesh()
    m.box((0, 0, 0), (r * .25, r * 1.8, r * .25), 'metal')
    for s in (-1, 1):
        m.box((s * r * .45, r * .1, -r * .1), (r * .6, r * .9, r * .06), 'red')
    m.box((0, r * .2, r * .2), (r * .18, r * .18, r * .2), 'cyan')
    return m


def sentry(r):
    """A squat core ringed by four vertical pylons."""
    m = Mesh()
    m.box((0, 0, 0), (r * .8, r * .8, r * .8), 'dark')
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        m.box((dx * r * .7, 0, dz * r * .7), (r * .15, r * 1.6, r * .15), 'metal')
    m.box((0, r * .5, r * .42), (r * .25, r * .25, r * .1), 'cyan')
    return m


def guard(r):
    """A tall armoured slab with plates and a heavy gun pod."""
    m = Mesh()
    m.box((0, 0, 0), (r * .5, r * 2, r * .7), 'armor')
    for y in (-.6, 0, .6):
        m.box((0, y * r, 0), (r * .8, r * .3, r * .8), 'dark')
    m.box((0, -r * .2, r * .55), (r * .2, r * .2, r * .5), 'machine')
    m.box((0, r * .9, r * .3), (r * .15, r * .15, r * .1), 'red')
    return m


def hunter(r):
    """A vertical blade with two forward prongs."""
    m = Mesh()
    m.box((0, 0, 0), (r * .2, r * 1.9, r * .9), 'metal')
    for s in (-1, 1):
        m.box((s * r * .3, s * r * .5, r * .55), (r * .12, r * .12, r * .9), 'machine')
    m.box((0, 0, r * .5), (r * .3, r * .3, r * .2), 'red')
    return m


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    components = []
    for name, build in (('scout', scout), ('sentry', sentry), ('guard', guard), ('hunter', hunter)):
        build(RADIUS[name]).save(OUT / f'{name}.glb')
        write(OUT / f'{name}.model', f'mesh: "/assets/models/drones/{name}.glb"\nmaterial: "{MATERIAL}"\ntextures: "{TEXTURE}"\nname: "drone"\n')
        components.append(f'components {{\n  id: "{name}"\n  component: "/assets/models/drones/{name}.model"\n}}\n')
    write(ROOT / 'main/drone.go', ''.join(components))
    print('wrote', OUT.relative_to(ROOT), 'and main/drone.go')


if __name__ == '__main__':
    main()
