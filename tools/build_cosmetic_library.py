#!/usr/bin/env python3
"""Build three recolors per existing ship and optional Clockwork model variants.

Defaults to both parts. --part recolors or --part clockwork can stage either.
Source geometry always comes from the approved, committed default fleet GLBs.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
from fleet.roster import SHIPS, BY_SLUG
from fleet.geometry import export
from cosmetics.glb import read_mesh
from cosmetics.paint import COLLECTIONS, paint

ROOT=Path(__file__).resolve().parents[1]


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def build(ship, key, root):
    mesh=read_mesh(ship,ROOT/ship.glb)
    source_vertices=len(mesh.p); source_indices=len(mesh.idx)
    features=[]
    if key=='clockwork':
        from cosmetics.clockwork import detail
        features=detail(mesh)
    image=paint(ship,key)
    folder=Path('assets/cosmetics')/ship.slug/key
    dest=root/folder; dest.mkdir(parents=True,exist_ok=True)
    glb=folder/'model.glb'; texture=folder/'albedo.png'; model=folder/'ship.model'
    export(mesh,image,root/glb); image.save(root/texture,optimize=True)
    # Defold recolors share the original geometry resource. The portable GLB also
    # embeds this colorway for Blender, review and downstream content tools.
    game_mesh=ship.glb if key!='clockwork' else glb.as_posix()
    (root/model).write_text(f'mesh: "/{game_mesh}"\nmaterial: "/builtins/materials/model.material"\ntextures: "/{texture.as_posix()}"\nname: "{ship.slug}_{key}"\n',encoding='utf-8',newline='\n')
    # Exported geometry starts with all original source vertices and triangles.
    lo=[min(p[k] for p in mesh.p) for k in range(3)]; hi=[max(p[k] for p in mesh.p) for k in range(3)]
    radius=max(math.sqrt(sum(v*v for v in p)) for p in mesh.p)
    dist=radius*3.12
    return dict(id=ship.slug+'.'+key,ship=ship.slug,name=ship.name,collection=key,
                kind=COLLECTIONS[key]['kind'],faction=ship.faction,size=ship.size,role=ship.role,
                model='/'+model.as_posix(),texture='/'+texture.as_posix(),glb=glb.as_posix(),
                game_mesh='/'+game_mesh,base_model=ship.model,base_glb=ship.glb,
                base_sha256=sha(ROOT/ship.glb),sha256=sha(root/glb),texture_sha256=sha(root/texture),
                bounds_m=[lo,hi],dimensions_m=[round(b-a,5) for a,b in zip(lo,hi)],
                vertices=len(mesh.p),triangles=len(mesh.idx)//3,
                added_vertices=len(mesh.p)-source_vertices,added_triangles=(len(mesh.idx)-source_indices)//3,
                preview=dict(eye_offset=[0,round(dist*.35,3),round(dist*math.sqrt(1-.35**2),3)],far=round(dist+radius+50,3)),
                features=features,
                thumbnail=f'artifacts/cosmetics/renders/{ship.slug}-{key}-perspective.jpg')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--part',choices=['all','recolors','clockwork'],default='all')
    parser.add_argument('--ship',choices=list(BY_SLUG))
    parser.add_argument('--output-root',type=Path,default=ROOT)
    args=parser.parse_args()
    keys=[k for k in COLLECTIONS if args.part=='all' or (k=='clockwork')==(args.part=='clockwork')]
    rows=[]
    for ship in ([BY_SLUG[args.ship]] if args.ship else SHIPS):
        for key in keys:
            row=build(ship,key,args.output_root); rows.append(row)
        print(ship.name+': '+', '.join(keys),flush=True)
    catalog=dict(schema_version=1,scope='Optional art library; no store, pricing, ownership or equip integration.',
                 source_commit='de7d7b4',collections={k:COLLECTIONS[k] for k in keys},entries=rows)
    path=args.output_root/'assets/cosmetics'; path.mkdir(parents=True,exist_ok=True)
    # Partial builds cannot silently overwrite the complete shop catalog.
    filename='catalog.json' if not args.ship and args.part=='all' else f'catalog-{args.ship or "all"}-{args.part}.json'
    (path/filename).write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Built {len(rows)} cosmetics; catalog: {path/filename}')


if __name__=='__main__': main()
