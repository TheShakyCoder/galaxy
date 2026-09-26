#!/usr/bin/env python3
"""Build the 23 remaining ships in Galaxy's named fish/bird roster.

Python + Pillow; NumPy is needed by the validator, not this builder.
Run: python tools/build_fleet_models.py [--ship NAME] [--output-root DIR]
Sardine is never regenerated or altered here. Game integration is a separate,
explicit step: python tools/integrate_fleet_models.py
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
from fleet.roster import SHIPS,BY_SLUG
from fleet.geometry import atlas,export
from fleet import fish,birds

ROOT=Path(__file__).resolve().parents[1]


def read_positions(path):
    raw=path.read_bytes(); length=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+length]); binary=raw[28+length:]
    prim=doc['meshes'][0]['primitives'][0]; a=doc['accessors'][prim['attributes']['POSITION']]
    view=doc['bufferViews'][a['bufferView']]; off=view.get('byteOffset',0)+a.get('byteOffset',0)
    positions=list(struct.iter_unpack('<3f',binary[off:off+a['count']*12]))
    count=doc['accessors'][prim['indices']]['count']//3
    return positions,count


def measure(ship,positions,triangles,path,features):
    lo=[min(p[k] for p in positions) for k in range(3)]; hi=[max(p[k] for p in positions) for k in range(3)]
    radius=max(math.sqrt(sum(v*v for v in p)) for p in positions)
    dist=radius*3.12
    # Square rotating hangar preview; all other grid cells are wider.
    camera=[0,round(dist*.35,3),round(dist*math.sqrt(1-.35**2),3)]
    far=round(dist+radius+50,3)
    if ship.slug=='sardine': camera=[0,9.2,24.6]; far=90
    return {'name':ship.name,'slug':ship.slug,'faction':ship.faction,'class':ship.size,'role':ship.role,
            'model':ship.model,'glb':ship.glb,'texture':ship.texture,
            'bounds_m':[lo,hi],'dimensions_m':[round(b-a,3) for a,b in zip(lo,hi)],
            'origin_radius_m':round(radius,5),'vertices':len(positions),'triangles':triangles,
            'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'preview':{'eye_offset':camera,'far':far},'identity':ship.identity,'features':features,
            'retained':ship.slug=='sardine'}


def build_one(ship,root):
    mesh=(fish if ship.faction=='accord' else birds).build(ship)
    lo=[min(p[k] for p in mesh.p) for k in range(3)]; hi=[max(p[k] for p in mesh.p) for k in range(3)]
    scale=ship.extent/max(b-a for a,b in zip(lo,hi))
    mesh.p=[tuple(v*scale for v in p) for p in mesh.p]
    if len(mesh.p)>65535: raise ValueError(ship.slug+': 16-bit vertex limit')
    image=atlas(ship); path=root/ship.glb; path.parent.mkdir(parents=True,exist_ok=True)
    export(mesh,image,path); image.save(root/ship.texture,optimize=True)
    model=root/ship.model.lstrip('/')
    model.write_text(f'mesh: "/{ship.glb}"\nmaterial: "/builtins/materials/model.material"\ntextures: "/{ship.texture}"\nname: "{ship.slug}"\n')
    # Read exported float32 values for reproducible bounds/camera checks.
    positions,triangles=read_positions(path)
    row=measure(ship,positions,triangles,path,mesh.features)
    print(f'{ship.name:14} {ship.size:7} {row["triangles"]:6,} triangles  {max(row["dimensions_m"]):5.1f}m')
    return row,positions


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ship',choices=list(BY_SLUG)); parser.add_argument('--output-root',type=Path,default=ROOT)
    args=parser.parse_args(); rows=[]; points={}
    ships=[BY_SLUG[args.ship]] if args.ship else SHIPS
    for ship in ships:
        if ship.slug=='sardine':
            path=ROOT/ship.glb; p,t=read_positions(path)
            row=measure(ship,p,t,path,['Approved Sardine asset retained byte for byte'])
        else: row,p=build_one(ship,args.output_root)
        rows.append(row); points.setdefault(ship.chassis,[]).extend(p)
    out=args.output_root/'artifacts/fleet'; out.mkdir(parents=True,exist_ok=True)
    flight={}
    for chassis,p in points.items():
        radius=max(math.sqrt(sum(x*x for x in v)) for v in p); height=round(radius*.35,3)
        tan=math.tan(.7/2)
        distance=max(max(abs(x)/(tan*1.7778*.80)-z,abs(y-height)/(tan*.80)-z) for x,y,z in p)
        flight[chassis]={'distance':round(max(radius*2,distance)+1,3),'height':height}
    manifest={'roster_count':len(rows),'built':sum(not r['retained'] for r in rows),'retained_sardine':True,
              'size_basis':'maximum model dimension in meters; Patrol 15-17, Escort 38-42, Frigate 78-88',
              'module_slots':'unchanged; hardware is visual role language, not a gameplay slot assignment',
              'ships':rows,'flight_camera':flight}
    filename='manifest.json' if not args.ship else args.ship+'-manifest.json'
    (out/filename).write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__': main()
