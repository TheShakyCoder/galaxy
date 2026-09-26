#!/usr/bin/env python3
"""Independent binary, geometry, integration and framing checks for all 24 ships.

Python + NumPy/Pillow. Does not import generator implementations.
--rebuild verifies all 23 new assets byte for byte in an isolated temporary folder.
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
BASE='dc6775434e9e6103462fb3da55daa55a4f5e8761'


def git_file(file):
    return subprocess.run(['git','-c','safe.directory='+ROOT.as_posix(),'show',BASE+':'+file],capture_output=True,check=True).stdout


def load(path):
    raw=path.read_bytes(); magic,version,length=struct.unpack_from('<4sII',raw)
    assert (magic,version,length)==(b'glTF',2,len(raw))
    jl,jt=struct.unpack_from('<II',raw,12); assert jl%4==0 and jt==0x4E4F534A
    doc=json.loads(raw[20:20+jl]); bl,bt=struct.unpack_from('<II',raw,20+jl); binary=raw[28+jl:]
    assert bt==0x004E4942 and bl==len(binary)==doc['buffers'][0]['byteLength'] and bl%4==0
    for v in doc['bufferViews']:
        assert v.get('byteOffset',0)%4==0 and v.get('byteOffset',0)+v['byteLength']<=bl
    def accessor(index):
        a=doc['accessors'][index]; v=doc['bufferViews'][a['bufferView']]
        width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]; dtype={5126:'<f4',5123:'<u2'}[a['componentType']]
        assert a.get('byteOffset',0)+a['count']*width*np.dtype(dtype).itemsize<=v['byteLength']
        x=np.frombuffer(binary,dtype,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0))
        return x.reshape(-1,width) if width>1 else x
    assert len(doc['nodes'])==len(doc['meshes'])==len(doc['materials'])==1
    assert not any(k in doc['nodes'][0] for k in ('scale','rotation','matrix','translation'))
    assert len(doc['meshes'][0]['primitives'])==1
    prim=doc['meshes'][0]['primitives'][0]; assert prim['mode']==4
    p=accessor(prim['attributes']['POSITION']); n=accessor(prim['attributes']['NORMAL']); uv=accessor(prim['attributes']['TEXCOORD_0']); idx=accessor(prim['indices'])
    assert np.isfinite(p).all() and np.isfinite(n).all() and np.isfinite(uv).all()
    assert len(p)==len(n)==len(uv) and len(p)<65536
    assert idx.max()<len(p) and len(idx)%3==0 and len(idx)//3<=22000
    assert np.allclose(np.linalg.norm(n,axis=1),1,atol=1e-5)
    assert ((uv>=0)&(uv<=1)).all()
    a=doc['accessors'][prim['attributes']['POSITION']]
    assert np.allclose(p.min(0),a['min']) and np.allclose(p.max(0),a['max'])
    tri=p[idx.reshape(-1,3)]; normals=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])
    assert (np.linalg.norm(normals,axis=1)>1e-8).all(),'Zero-area triangles'
    dots=np.sum(normals*n[idx.reshape(-1,3)].mean(1),axis=1)
    assert (dots>0).all(),f'{int((dots<=0).sum())} triangle windings disagree with normals'
    v=doc['bufferViews'][doc['images'][0]['bufferView']]
    texture=binary[v['byteOffset']:v['byteOffset']+v['byteLength']]
    assert Image.open(io.BytesIO(texture)).size==(1024,1024)
    return p,texture,hashlib.sha256(raw).hexdigest()


def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--rebuild',action='store_true'); args=parser.parse_args()
    manifest=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text()); rows=manifest['ships']
    assert len(rows)==24 and sum(r['faction']=='accord' for r in rows)==12
    assert len(set(r['slug'] for r in rows))==24
    ships=(ROOT/'main/data/ships.lua').read_text(); preview=(ROOT/'main/outpost.gui_script').read_text(); collection=(ROOT/'main/main.collection').read_text()
    originals=git_file('main/data/ships.lua').decode()
    def gameplay(text):
        text=re.sub(r'--[^\n]*','',text)
        text=re.sub(r'flight_camera\s*=\s*\{[^}]+\},','',text)
        return re.sub(r'\s+','',text)
    assert gameplay(originals)==gameplay(ships),'Gameplay or roster fields changed beyond camera settings'
    for file in ['assets/models/patrol_interceptor/sardine.glb','assets/models/patrol_interceptor/sardine_palette.png','tools/build_sardine_model.py']:
        actual,expected=(ROOT/file).read_bytes(),git_file(file)
        if file.endswith('.py'): actual,expected=actual.replace(b'\r\n',b'\n'),expected.replace(b'\r\n',b'\n')
        assert actual==expected,'Approved Sardine changed: '+file
    results=[]; grouped={}; hashes=set(); sizes={k:[] for k in ('patrol','escort','frigate')}
    for row in rows:
        slug=row['slug']
        try:
            p,texture,sha=load(ROOT/row['glb'])
            assert sha==row['sha256']; assert sha not in hashes; hashes.add(sha)
            assert texture==(ROOT/row['texture']).read_bytes()
            model=(ROOT/row['model'].lstrip('/')).read_text()
            assert f'mesh: "/{row["glb"]}"' in model and f'textures: "/{row["texture"]}"' in model
            assert '/builtins/materials/model.material' in model
            assert row['model'] in ships and row['model'] in collection
            remote=ROOT/f'main/remote_ships/{row["class"]}_{row["role"]}_{row["faction"]}.go'
            assert row['model'] in remote.read_text()
            pat=r'\["'+re.escape(row['model'])+r'"\] = \{ eye_offset = vmath.vector3\(([^)]+)\), far = ([\d.]+)'
            match=re.search(pat,preview); assert match
            eye=np.array([float(v) for v in match[1].split(',')]); far=float(match[2])
            assert np.allclose(eye,row['preview']['eye_offset'])
            forward=-eye/np.linalg.norm(eye); right=np.cross(forward,[0,1,0]); right/=np.linalg.norm(right); up=np.cross(right,forward)
            worst=0
            for degrees in range(0,360,3):
                a=math.radians(degrees); c,s=math.cos(a),math.sin(a)
                rot=np.array([[c,0,s],[0,1,0],[-s,0,c]])
                v=p@rot.T-eye; depth=v@forward
                assert (depth>.1).all() and (depth<far).all()
                worst=max(worst,float(np.abs(v@right/(depth*math.tan(math.pi/8))).max()),float(np.abs(v@up/(depth*math.tan(math.pi/8))).max()))
            assert worst<.95,f'Preview clips: {worst}'
            chassis=row['class']+'_'+row['role']; grouped.setdefault(chassis,[]).append(p)
            extent=float(np.ptp(p,axis=0).max()); sizes[row['class']].append(extent)
            results.append({'ship':row['name'],'result':'PASS','triangles':row['triangles'],'extent_m':round(extent,3),'preview_max_ndc':round(worst,4),'sha256':sha})
            print('PASS '+row['name'],flush=True)
        except AssertionError as error: raise AssertionError(slug+': '+str(error)) from error
    assert max(sizes['patrol'])<min(sizes['escort']) and max(sizes['escort'])<min(sizes['frigate'])
    flight_results={}
    for chassis,arrays in grouped.items():
        block=ships[ships.index('["'+chassis+'"]'):]; block=block[:block.index('\n\t\tfaction_skins =')]
        match=re.search(r'flight_camera = \{ distance = ([\d.]+), height = ([\d.]+)',block); assert match
        distance,height=map(float,match.groups()); p=np.concatenate(arrays); depth=p[:,2]+distance
        # Actual player_ship.script camera faces horizontally +Z, not at the origin.
        assert (depth>.5).all() and (depth<20000).all()
        x=p[:,0]/(depth*math.tan(.35)*1.7778); y=(p[:,1]-height)/(depth*math.tan(.35))
        worst=max(float(np.abs(x).max()),float(np.abs(y).max())); assert worst<.85
        flight_results[chassis]=round(worst,4)
    if args.rebuild:
        with tempfile.TemporaryDirectory(prefix='rebuild-',dir=ROOT/'artifacts/fleet') as folder:
            subprocess.run([sys.executable,str(ROOT/'tools/build_fleet_models.py'),'--output-root',folder],check=True,capture_output=True)
            for row in rows:
                if row['retained']: continue
                for file in (row['glb'],row['texture'],row['model'].lstrip('/')):
                    assert (ROOT/file).read_bytes()==(Path(folder)/file).read_bytes(),'Regeneration mismatch: '+file
    result={'result':'PASS','ships_checked':24,'new_models':23,'approved_sardine_preserved':True,
            'gameplay_tables_unchanged':True,'all_geometry_hashes_unique':True,'class_size_bands_separated':True,
            'preview_yaws_per_ship':120,'flight_aspect':1.7778,'rebuild_verified':args.rebuild,
            'ships':results,'flight_max_ndc':flight_results,
            'not_tested':['Defold runtime','mobile/browser performance','live multiplayer']}
    (ROOT/'artifacts/fleet/validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print('FLEET VALIDATION PASS: 24 ships; gameplay preserved; cameras fit; rebuild='+str(args.rebuild))


if __name__=='__main__': main()
