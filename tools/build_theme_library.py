#!/usr/bin/env python3
"""Build bounded sprints of optional themes without rewriting previous assets."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from fleet.roster import SHIPS,BY_SLUG
from fleet.geometry import export
from cosmetics.glb import read_mesh
from themes.collections import THEMES
from themes.surface import paint,remap_panels

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def build(ship,key,root):
    mesh=read_mesh(ship,ROOT/ship.glb); nv,nt=len(mesh.p),len(mesh.idx)//3
    remapped=remap_panels(mesh); features=[]
    if THEMES[key]['kind']=='model':
        from themes.geometry import detail
        features=detail(mesh,key)
    folder=Path('assets/themes')/ship.slug/key; (root/folder).mkdir(parents=True,exist_ok=True)
    glb=folder/'model.glb'; texture=folder/'albedo.png'; model=folder/'ship.model'
    image=paint(ship,key); export(mesh,image,root/glb); image.save(root/texture,optimize=True)
    (root/model).write_text(f'mesh: "/{glb.as_posix()}"\nmaterial: "/builtins/materials/model.material"\ntextures: "/{texture.as_posix()}"\nname: "{ship.slug}_{key}"\n',encoding='utf-8',newline='\n')
    lo=[min(p[k] for p in mesh.p) for k in range(3)]; hi=[max(p[k] for p in mesh.p) for k in range(3)]
    radius=max(math.sqrt(sum(v*v for v in p)) for p in mesh.p); dist=radius*3.12
    return dict(id=ship.slug+'.'+key,ship=ship.slug,name=ship.name,collection=key,sprint=THEMES[key]['sprint'],kind=THEMES[key]['kind'],
                faction=ship.faction,size=ship.size,role=ship.role,base_glb=ship.glb,base_model=ship.model,
                base_sha256=sha(ROOT/ship.glb),glb=glb.as_posix(),texture='/'+texture.as_posix(),model='/'+model.as_posix(),
                sha256=sha(root/glb),texture_sha256=sha(root/texture),vertices=len(mesh.p),triangles=len(mesh.idx)//3,
                added_vertices=len(mesh.p)-nv,added_triangles=len(mesh.idx)//3-nt,remapped_panel_vertices=remapped,
                bounds_m=[lo,hi],dimensions_m=[round(b-a,5) for a,b in zip(lo,hi)],features=features,
                preview=dict(eye_offset=[0,round(dist*.35,3),round(dist*math.sqrt(1-.35**2),3)],far=round(dist+radius+50,3)),
                thumbnail=f'artifacts/themes/renders/{ship.slug}-{key}-perspective.jpg',
                **({'insignia':'triangle' if ship.faction=='accord' else 'circle'} if key=='corsair' else {}))


def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('--sprint',type=int,choices=range(1,5)); p.add_argument('--theme',choices=list(THEMES))
    p.add_argument('--ship',choices=list(BY_SLUG)); p.add_argument('--output-root',type=Path,default=ROOT); args=p.parse_args()
    keys=[k for k,c in THEMES.items() if (not args.sprint or c['sprint']==args.sprint) and (not args.theme or args.theme==k)]
    if not keys:p.error('Theme does not belong to the selected sprint')
    rows=[]
    for ship in ([BY_SLUG[args.ship]] if args.ship else SHIPS):
        for key in keys:rows.append(build(ship,key,args.output_root))
        print(ship.name+': '+', '.join(keys),flush=True)
    folder=args.output_root/'assets/themes';folder.mkdir(parents=True,exist_ok=True)
    suffix=f'-{args.ship}' if args.ship else ''
    name='catalog'+(f'-sprint-{args.sprint}' if args.sprint else f'-{args.theme}' if args.theme else '')+suffix+'.json'
    doc=dict(schema_version=1,source_commit='b63ffcc',scope='Optional art resources. No shop/equip integration.',collections={k:THEMES[k] for k in keys},entries=rows)
    (folder/name).write_text(json.dumps(doc,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Built {len(rows)} variants: {name}')


if __name__=='__main__':main()
