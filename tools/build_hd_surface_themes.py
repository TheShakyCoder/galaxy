#!/usr/bin/env python3
"""Build the 72 detailed surface themes from checked-in, independent geometry sources."""
import argparse,hashlib,json,re
from pathlib import Path
import numpy as np
from fleet.roster import SHIPS,BY_SLUG
from fleet.geometry import Mesh,export
from themes.surface import remap_panels
from themes.hd_finish import paint_hd

ROOT=Path(__file__).resolve().parents[1]
KEYS=('porcelain_dynasty','starlight','grand_prix')
SOURCE=ROOT/'tools/themes/detail_sources'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def build(ship,key,output):
    source=SOURCE/(ship.slug+'.npz')
    mesh=Mesh(ship)
    with np.load(source,allow_pickle=False) as data:
        for field in ('p','n','uv'):setattr(mesh,field,[tuple(row) for row in data[field].tolist()])
        mesh.idx=data['idx'].tolist()
    changed=remap_panels(mesh)
    folder=Path('assets/skins/hd')/ship.slug/key;dest=output/folder;dest.mkdir(parents=True,exist_ok=True)
    texture=paint_hd(ship,key)
    texture.save(dest/'albedo.png',optimize=True);export(mesh,texture,dest/'model.glb')
    model=f'/assets/skins/{ship.slug}/{key}/ship.model'
    material=f'/assets/materials/theme_finish/{key}.material'
    return dict(id=ship.slug+'.'+key,ship=ship.slug,collection=key,model=model,
        mesh='/'+(folder/'model.glb').as_posix(),texture='/'+(folder/'albedo.png').as_posix(),material=material,
        source_sha256=sha(source),mesh_sha256=sha(dest/'model.glb'),texture_sha256=sha(dest/'albedo.png'),
        vertices=len(mesh.p),triangles=len(mesh.idx)//3,extent=ship.extent,remapped_panel_vertices=changed,
        original_mesh=f'/assets/skins/{ship.slug}/{key}/model.glb',
        original_texture=f'/assets/skins/{ship.slug}/{key}/albedo.png',
        original_mesh_sha256=sha(ROOT/f'assets/skins/{ship.slug}/{key}/model.glb'),
        original_texture_sha256=sha(ROOT/f'assets/skins/{ship.slug}/{key}/albedo.png'))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--ship',choices=list(BY_SLUG));p.add_argument('--theme',choices=KEYS)
    p.add_argument('--output-root',type=Path,default=ROOT);p.add_argument('--integrate',action='store_true');a=p.parse_args()
    rows=[]
    for ship in ([BY_SLUG[a.ship]] if a.ship else SHIPS):
        for key in ([a.theme] if a.theme else KEYS):
            row=build(ship,key,a.output_root);rows.append(row)
            if a.integrate:
                path=a.output_root/row['model'].lstrip('/');path.parent.mkdir(parents=True,exist_ok=True)
                path.write_text(f'mesh: "{row["mesh"]}"\nmaterial: "{row["material"]}"\ntextures: "{row["texture"]}"\nname: "{ship.slug}_{key}"\n',encoding='utf8',newline='\n')
        print(ship.slug,flush=True)
    dest=a.output_root/'artifacts/theme-detail';dest.mkdir(parents=True,exist_ok=True)
    name='manifest.json' if not a.ship and not a.theme else 'pilot-manifest.json'
    (dest/name).write_text(json.dumps({'schema_version':1,'variants':rows},indent=2)+'\n',encoding='utf8',newline='\n')
    print(f'Built {len(rows)} detailed surface themes',flush=True)
if __name__=='__main__':main()
