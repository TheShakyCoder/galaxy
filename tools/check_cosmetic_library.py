#!/usr/bin/env python3
"""Independently validate exported cosmetics and their unchanged source fleet.

No generator imports. --rebuild compares an isolated complete build bytewise.
"""
import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import sys
import tempfile
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
BASE='6a747c86c51ac3ff9d52c318bdafee2bd21e568a'


def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    raw=path.read_bytes(); magic,version,length=struct.unpack_from('<4sII',raw)
    assert (magic,version,length)==(b'glTF',2,len(raw))
    jl,jt=struct.unpack_from('<II',raw,12); assert jl%4==0 and jt==0x4E4F534A
    doc=json.loads(raw[20:20+jl]); bl,bt=struct.unpack_from('<II',raw,20+jl); binary=raw[28+jl:]
    assert bt==0x004E4942 and bl==len(binary)==doc['buffers'][0]['byteLength'] and bl%4==0
    for v in doc['bufferViews']:
        assert v.get('byteOffset',0)%4==0 and v.get('byteOffset',0)+v['byteLength']<=bl
    def acc(index):
        a=doc['accessors'][index]; v=doc['bufferViews'][a['bufferView']]
        width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]; dtype={5126:'<f4',5123:'<u2'}[a['componentType']]
        assert a.get('byteOffset',0)+a['count']*width*np.dtype(dtype).itemsize<=v['byteLength']
        x=np.frombuffer(binary,dtype,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0))
        return x.reshape(-1,width) if width>1 else x
    assert len(doc['nodes'])==len(doc['meshes'])==len(doc['materials'])==1
    assert not any(k in doc['nodes'][0] for k in ('scale','rotation','matrix','translation'))
    assert len(doc['meshes'][0]['primitives'])==1
    primitive=doc['meshes'][0]['primitives'][0]; assert primitive['mode']==4
    p=acc(primitive['attributes']['POSITION']); n=acc(primitive['attributes']['NORMAL'])
    uv=acc(primitive['attributes']['TEXCOORD_0']); idx=acc(primitive['indices'])
    assert len(p)==len(n)==len(uv)<65536
    assert idx.max()<len(p) and len(idx)%3==0 and len(idx)//3<=26000
    assert all(np.isfinite(a).all() for a in [p,n,uv])
    assert np.allclose(np.linalg.norm(n,axis=1),1,atol=1e-5)
    assert ((uv>=0)&(uv<=1)).all()
    a=doc['accessors'][primitive['attributes']['POSITION']]
    assert np.allclose(p.min(0),a['min']) and np.allclose(p.max(0),a['max'])
    tri=p[idx.reshape(-1,3)]; face=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])
    assert (np.linalg.norm(face,axis=1)>1e-8).all(),'Degenerate triangles'
    assert (np.sum(face*n[idx.reshape(-1,3)].mean(1),axis=1)>0).all(),'Winding versus normals'
    v=doc['bufferViews'][doc['images'][0]['bufferView']]
    texture=binary[v['byteOffset']:v['byteOffset']+v['byteLength']]
    image=Image.open(io.BytesIO(texture)); assert image.size==(1024,1024) and image.mode=='RGB'
    return p,n,uv,idx,texture


def framing(p,camera):
    eye=np.array(camera['eye_offset']); forward=-eye/np.linalg.norm(eye)
    right=np.cross(forward,[0,1,0]); right/=np.linalg.norm(right); up=np.cross(right,forward)
    worst=0
    for angle in range(0,360,3):
        a=math.radians(angle); c,s=math.cos(a),math.sin(a)
        rot=np.array([[c,0,s],[0,1,0],[-s,0,c]])
        v=p@rot.T-eye; depth=v@forward
        assert (depth>.1).all() and (depth<camera['far']).all()
        worst=max(worst,float(np.abs(v@right/(depth*math.tan(math.pi/8))).max()),float(np.abs(v@up/(depth*math.tan(math.pi/8))).max()))
    assert worst<.95
    return round(worst,4)


def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--rebuild',action='store_true'); args=parser.parse_args()
    catalog=json.loads((ROOT/'assets/cosmetics/catalog.json').read_text()); rows=catalog['entries']
    originals=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())
    expected={r['slug']:r for r in originals['ships']}
    keys={'aurora','solar_regatta','royal_amethyst','clockwork'}
    assert set(catalog['collections'])==keys and len(rows)==96 and len(expected)==24
    assert len({r['id'] for r in rows})==96
    assert {(r['ship'],r['collection']) for r in rows}=={(s,k) for s in expected for k in keys}
    # The user explicitly revised Moray after the original library delivery.
    # A focused guard permits that hull/camera revision and no other ship edits.
    from check_moray_revision import preserved_assets
    preserved_assets()
    cache={s:load(ROOT/r['glb']) for s,r in expected.items()}
    results=[]; texture_hashes=set(); base_geometry_hashes=set()
    for row in rows:
        try:
            slug=row['ship']; key=row['collection']; base=expected[slug]
            assert row['id']==slug+'.'+key and row['name']==base['name']
            assert row['faction']==base['faction'] and row['size']==base['class'] and row['role']==base['role']
            assert row['base_model']==base['model'] and row['base_glb']==base['glb']
            assert row['kind']==('model' if key=='clockwork' else 'recolor')
            assert row['base_sha256']==digest(ROOT/base['glb'])==base['sha256']
            assert row['sha256']==digest(ROOT/row['glb'])
            p,n,uv,idx,texture=load(ROOT/row['glb']); bp,bn,bu,bi,_=cache[slug]
            assert np.array_equal(p[:len(bp)],bp) and np.array_equal(n[:len(bn)],bn)
            assert np.array_equal(uv[:len(bu)],bu) and np.array_equal(idx[:len(bi)],bi)
            assert row['vertices']==len(p) and row['triangles']==len(idx)//3
            assert row['added_vertices']==len(p)-len(bp) and row['added_triangles']==(len(idx)-len(bi))//3
            if key!='clockwork':
                assert len(p)==len(bp) and len(idx)==len(bi) and not row['features']
                assert row['game_mesh']=='/'+base['glb']
            else:
                assert row['added_triangles']>1000 and len(row['features'])>=5
                assert row['game_mesh']=='/'+row['glb']
                # Added machinery must remain subordinate to the animal silhouette.
                assert np.ptp(p,axis=0).max()<=np.ptp(bp,axis=0).max()*1.08
                base_geometry_hashes.add(hashlib.sha256(p.tobytes()).hexdigest())
            assert np.allclose([p.min(0),p.max(0)],row['bounds_m'])
            assert np.allclose(np.ptp(p,axis=0),row['dimensions_m'],atol=1e-4)
            assert texture==(ROOT/row['texture'].lstrip('/')).read_bytes()
            th=hashlib.sha256(texture).hexdigest(); assert th==row['texture_sha256']
            assert th not in texture_hashes; texture_hashes.add(th)
            model=(ROOT/row['model'].lstrip('/')).read_text()
            assert f'mesh: "{row["game_mesh"]}"' in model and f'textures: "{row["texture"]}"' in model
            assert '/builtins/materials/model.material' in model
            for path in (row['game_mesh'],row['model'],row['texture']): assert (ROOT/path.lstrip('/')).is_file()
            preview=framing(p,row['preview'])
            camera=originals['flight_camera'][base['class']+'_'+base['role']]
            depth=p[:,2]+camera['distance']; assert (depth>.5).all()
            flight=max(float(np.abs(p[:,0]/(depth*math.tan(.35)*1.7778)).max()),float(np.abs((p[:,1]-camera['height'])/(depth*math.tan(.35))).max()))
            assert flight<.95,'Existing flight framing clips cosmetic'
            results.append(dict(id=row['id'],triangles=len(idx)//3,added_triangles=row['added_triangles'],preview_max_ndc=preview,existing_flight_max_ndc=round(flight,4),result='PASS'))
        except AssertionError as error: raise AssertionError(row['id']+': '+str(error)) from error
    assert len(base_geometry_hashes)==24
    if args.rebuild:
        with tempfile.TemporaryDirectory(prefix='rebuild-',dir=ROOT/'artifacts/cosmetics') as folder:
            subprocess.run([sys.executable,str(ROOT/'tools/build_cosmetic_library.py'),'--output-root',folder],check=True,capture_output=True)
            files=[ROOT/'assets/cosmetics/catalog.json']
            for row in rows:
                files.extend(ROOT/p.lstrip('/') for p in (row['glb'],row['texture'],row['model']))
            for file in files:
                assert file.read_bytes()==(Path(folder)/file.relative_to(ROOT)).read_bytes(),'Rebuild mismatch: '+str(file)
    report=dict(result='PASS',validation_base_commit=BASE,cosmetics=96,recolors=72,clockwork_models=24,source_fleet_revision='Symmetrical Moray and requested native 1:4:16 class sizing; Patrol unchanged',
                recolor_geometry_exact=True,clockwork_base_geometry_exact=True,unique_textures=96,
                preview_yaws_per_variant=120,rebuild_verified=args.rebuild,rows=results,
                not_tested=['Defold runtime rendering/performance','shop/ownership/equip integration','live multiplayer'])
    (ROOT/'artifacts/cosmetics/validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: 96 cosmetics; 72 exact-geometry recolors; 24 additive Clockwork models; 96 unique textures; revised Moray preserved; rebuild='+str(args.rebuild))


if __name__=='__main__': main()
