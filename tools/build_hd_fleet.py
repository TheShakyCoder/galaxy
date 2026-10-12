#!/usr/bin/env python3
"""Add 24 detailed hulls without overwriting approved mesh/texture originals.

python tools/build_hd_fleet.py [--ship sardine] [--integrate]
The optional integration updates existing model descriptors, including recolors.
Sculpted skin meshes retain their separately authored geometry.
"""
import argparse,hashlib,json,math,re,struct
from pathlib import Path
from fleet.roster import SHIPS,BY_SLUG
from fleet import fish,birds
from fleet.geometry import atlas,export
from fleet.hd_detail import service_details,texture_2k
import build_sardine_model as sardine
from build_fleet_models import read_positions
ROOT=Path(__file__).resolve().parents[1]
MATERIAL='/assets/materials/ship_finish/ship.material'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def build(ship):
    original=ROOT/ship.glb; original_texture=ROOT/ship.texture
    if ship.slug=='sardine':
        mesh=sardine.build_mesh(detail_scale=2,engine_scale=1.65)
        class Surface:
            z0=-6.45; z1=7
            point=staticmethod(sardine.surface);normal=staticmethod(sardine.surface_normal)
        hull=Surface();source=sardine.make_atlas()
    else:
        mesh=(fish if ship.faction=='accord' else birds).build(ship,detail_scale=2)
        hull=mesh.hull;source=atlas(ship)
    assert hull.z0 < 0 < hull.z1, "Detail surface must be the main torso, not a bill loft"
    service_details(mesh,hull)
    extent=max(max(p[k] for p in mesh.p)-min(p[k] for p in mesh.p) for k in range(3))
    mesh.p=[tuple(v*ship.extent/extent for v in p) for p in mesh.p]
    mesh.ship=ship
    if len(mesh.p)>65535: raise ValueError(f'{ship.slug}: exceeds 16-bit vertex budget')
    path=ROOT/'assets/models/hd'/ship.slug;path.mkdir(parents=True,exist_ok=True)
    image=texture_2k(source,ship)
    image.save(path/'albedo.png',optimize=True);export(mesh,image,path/'ship.glb')
    positions,triangles=read_positions(path/'ship.glb')
    orig_positions,orig_triangles=read_positions(original)
    return dict(slug=ship.slug,name=ship.name,faction=ship.faction,size=ship.size,role=ship.role,
        model=ship.model,original_mesh='/'+ship.glb,original_texture='/'+ship.texture,
        original_sha256=sha(original),original_texture_sha256=sha(original_texture),
        mesh='/'+(path/'ship.glb').relative_to(ROOT).as_posix(),texture='/'+(path/'albedo.png').relative_to(ROOT).as_posix(),
        vertices=len(positions),triangles=triangles,original_triangles=orig_triangles,
        extent=ship.extent,texture_size=2048,mesh_sha256=sha(path/'ship.glb'),
        features=['Smoother curved hull','Paired vent panels and fasteners','2K hull engraving']+
        (['Engine radius 1.65x; housing length 1.2925x; cooling collars'] if ship.slug=='sardine' else []))

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--ship',choices=list(BY_SLUG));p.add_argument('--integrate',action='store_true');a=p.parse_args()
    rows=[]
    for ship in ([BY_SLUG[a.ship]] if a.ship else SHIPS):
        row=build(ship);rows.append(row);print(f'{ship.slug}: {row["triangles"]:,} triangles, {row["vertices"]:,} vertices')
        if a.integrate:
            # Only descriptors that share the approved base mesh use its detailed successor.
            for root in ('assets/models','assets/skins'):
                for model in (ROOT/root).rglob('*.model'):
                    s=model.read_text(encoding='utf8')
                    if f'"{row["original_mesh"]}"' not in s: continue
                    s=s.replace(row['original_mesh'],row['mesh']).replace('/builtins/materials/model.material',MATERIAL)
                    if model==ROOT/ship.model.lstrip('/'): s=s.replace(row['original_texture'],row['texture'])
                    model.write_text(s,encoding='utf8')
    dest=ROOT/'artifacts/ship-detail';dest.mkdir(parents=True,exist_ok=True)
    (dest/('manifest.json' if not a.ship else a.ship+'-manifest.json')).write_text(json.dumps({'ships':rows},indent=2)+'\n',encoding='utf8')
if __name__=='__main__':main()
