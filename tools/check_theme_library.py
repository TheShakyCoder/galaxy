#!/usr/bin/env python3
"""Binary-reader gates for theme sprints, preservation, framing and rebuilds.

Reuses the existing independent GLB validator, not the theme generator.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import numpy as np
from PIL import Image
from check_cosmetic_library import load,framing

ROOT=Path(__file__).resolve().parents[1]; BASE='b63ffcc'
EXPECTED={1:{'porcelain_dynasty','starlight','grand_prix'},2:{'abyssal','crystalborn'},3:{'corsair','overgrown'},4:{'toybox'}}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def preserved_files():
    from check_moray_revision import preserved_assets
    preserved_assets()
    checked=0
    for path in (ROOT/'assets/themes').glob('catalog-sprint-[1-4].json'):
        for r in json.loads(path.read_text())['entries']:
            assert sha(ROOT/r['glb'])==r['sha256'],'Previous sprint GLB changed: '+r['id']
            assert sha(ROOT/r['texture'].lstrip('/'))==r['texture_sha256'],'Previous sprint texture changed: '+r['id']
            checked+=1
    return checked


def main():
    p=argparse.ArgumentParser(); p.add_argument('--sprint',type=int,choices=range(1,5));p.add_argument('--rebuild',action='store_true');p.add_argument('--renders',action='store_true');args=p.parse_args()
    suffix=f'-sprint-{args.sprint}' if args.sprint else ''
    catalog_path=Path('assets/themes')/('catalog'+suffix+'.json');cat=json.loads((ROOT/catalog_path).read_text());rows=cat['entries']
    expected=EXPECTED[args.sprint] if args.sprint else set.union(*EXPECTED.values())
    base=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text());fleet={r['slug']:r for r in base['ships']}
    assert set(cat['collections'])==expected and len(rows)==24*len(expected)
    assert {(r['ship'],r['collection']) for r in rows}=={(s,k) for s in fleet for k in expected}
    assert len({r['id'] for r in rows})==len(rows)
    originals={s:load(ROOT/r['glb']) for s,r in fleet.items()};hashes=set();results=[];render_count=0
    for r in rows:
        try:
            s,k=r['ship'],r['collection'];b=fleet[s]
            assert r['id']==s+'.'+k and r['base_glb']==b['glb'] and r['base_model']==b['model']
            assert r['faction']==b['faction'] and r['size']==b['class'] and r['role']==b['role']
            if k=='corsair':
                shape='triangle' if b['faction']=='accord' else 'circle'
                assert r['insignia']==shape
                assert any(shape+' faction insignias' in f.lower() for f in r['features'])
            assert r['base_sha256']==b['sha256']==sha(ROOT/b['glb'])
            assert r['sha256']==sha(ROOT/r['glb'])
            pts,n,uv,idx,tex=load(ROOT/r['glb']);bp,bn,bu,bi,_=originals[s]
            assert np.array_equal(pts[:len(bp)],bp) and np.array_equal(n[:len(bn)],bn)
            assert np.array_equal(idx[:len(bi)],bi)
            # Only copy-only panel swatches may acquire new UVs; body UVs stay.
            body=bu[:,0]<.75
            assert np.array_equal(uv[:len(bu)][body],bu[body])
            assert len(pts)==r['vertices'] and len(idx)//3==r['triangles']
            assert len(pts)-len(bp)==r['added_vertices'] and (len(idx)-len(bi))//3==r['added_triangles']
            assert (r['kind']=='surface')==(k in EXPECTED[1])
            if r['kind']=='surface':assert len(pts)==len(bp) and len(idx)==len(bi)
            else:assert len(pts)>len(bp) and r['added_triangles']>100 and len(r['features'])>=3
            assert np.ptp(pts,axis=0).max()<=np.ptp(bp,axis=0).max()*1.12
            assert np.allclose([pts.min(0),pts.max(0)],r['bounds_m'])
            assert np.allclose(np.ptp(pts,axis=0),r['dimensions_m'],atol=1e-4)
            assert tex==(ROOT/r['texture'].lstrip('/')).read_bytes()
            th=hashlib.sha256(tex).hexdigest();assert th==r['texture_sha256'] and th not in hashes;hashes.add(th)
            model=(ROOT/r['model'].lstrip('/')).read_text()
            assert f'mesh: "/{r["glb"]}"' in model and f'textures: "{r["texture"]}"' in model
            assert '/builtins/materials/model.material' in model
            framing_value=framing(pts,r['preview'])
            fc=base['flight_camera'][b['class']+'_'+b['role']]; depth=pts[:,2]+fc['distance']
            assert (depth>.5).all()
            flight=max(float(np.abs(pts[:,0]/(depth*np.tan(.35)*1.7778)).max()),float(np.abs((pts[:,1]-fc['height'])/(depth*np.tan(.35))).max()))
            assert flight<.95,'Flight framing clips'
            if args.renders:
                for view in (['perspective','side','top'] if r['kind']=='model' else ['perspective']):
                    path=ROOT/'artifacts/themes/renders'/f'{s}-{k}-{view}.jpg'
                    with Image.open(path) as im:assert im.size==(840,600);im.verify()
                    render_count+=1
            results.append(dict(id=r['id'],triangles=r['triangles'],added_triangles=r['added_triangles'],preview_max_ndc=framing_value,flight_max_ndc=round(flight,4),result='PASS'))
        except AssertionError as e:raise AssertionError(r['id']+': '+str(e)) from e
    previous=preserved_files()
    if args.rebuild:
        with tempfile.TemporaryDirectory(prefix='rebuild-',dir=ROOT/'artifacts/themes') as temp:
            command=[sys.executable,str(ROOT/'tools/build_theme_library.py'),'--output-root',temp]
            if args.sprint:command+=['--sprint',str(args.sprint)]
            subprocess.run(command,check=True,capture_output=True)
            files=[catalog_path]
            for r in rows:files.extend(Path(r[k].lstrip('/')) for k in ('glb','texture','model'))
            for f in files:assert (ROOT/f).read_bytes()==(Path(temp)/f).read_bytes(),'Rebuild mismatch: '+str(f)
    report=dict(result='PASS',sprint=args.sprint,variants=len(rows),collections=sorted(expected),source_hulls_preserved=True,source_fleet_revision='Symmetrical Moray and requested native 1:4:16 class sizing; Patrol unchanged',previous_sprint_assets_checked=previous,
                body_uvs_preserved=True,panel_uvs_remapped_on_copies=True,unique_textures=len(hashes),preview_poses=len(rows)*120,
                render_files_verified=render_count,rebuild_verified=args.rebuild,rows=results,
                not_tested=['Defold compilation/runtime','mobile/game performance','shop/equip/multiplayer integration'])
    (ROOT/'artifacts/themes'/('validation'+suffix+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: {len(rows)} variants; {len(rows)*120} preview poses; {render_count} renders; authorized source revision checked; previous sprint entries {previous}; rebuild={args.rebuild}')


if __name__=='__main__':main()
