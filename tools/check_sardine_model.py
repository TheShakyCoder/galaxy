"""Validate the shipped GLB independently of its generator; Python + NumPy/Pillow.

Checks binary layout, geometry, UV/texture agreement, deterministic regeneration,
Defold references, and actual hangar projection over a full rotation.
Run: python tools/check_sardine_model.py
"""
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
FILES=['assets/models/patrol_interceptor/sardine.glb',
       'assets/models/patrol_interceptor/sardine_palette.png',
       'main/images/patrol_interceptor_sardine_topdown.png']


def check():
    raw=(ROOT/FILES[0]).read_bytes()
    magic,version,length=struct.unpack_from('<4sII',raw)
    assert (magic,version,length)==(b'glTF',2,len(raw))
    jlen,jkind=struct.unpack_from('<II',raw,12)
    assert jkind==0x4E4F534A and jlen%4==0
    doc=json.loads(raw[20:20+jlen])
    blen,bkind=struct.unpack_from('<II',raw,20+jlen)
    binary=raw[28+jlen:]
    assert bkind==0x004E4942 and blen==len(binary) and blen%4==0
    assert doc['buffers'][0]['byteLength']==blen
    for view in doc['bufferViews']:
        assert view['byteOffset']%4==0
        assert view['byteOffset']+view['byteLength']<=blen
    def accessor(index):
        a=doc['accessors'][index]; v=doc['bufferViews'][a['bufferView']]
        dtype={5126:'<f4',5123:'<u2'}[a['componentType']]
        width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
        assert a.get('byteOffset',0)+a['count']*width*np.dtype(dtype).itemsize<=v['byteLength']
        data=np.frombuffer(binary,dtype,count=a['count']*width,offset=v['byteOffset']+a.get('byteOffset',0))
        return data.reshape(-1,width) if width>1 else data
    assert len(doc['meshes'])==len(doc['materials'])==1
    assert len(doc['meshes'][0]['primitives'])==1
    prim=doc['meshes'][0]['primitives'][0]
    assert prim['mode']==4
    p=accessor(prim['attributes']['POSITION']); n=accessor(prim['attributes']['NORMAL'])
    uv=accessor(prim['attributes']['TEXCOORD_0']); indices=accessor(prim['indices'])
    assert np.isfinite(p).all() and np.isfinite(n).all() and np.isfinite(uv).all()
    assert len(p)==len(n)==len(uv) and len(p)<65536
    assert indices.max()<len(p) and len(indices)%3==0
    assert len(indices)//3<=20000, 'Asset triangle budget exceeded'
    assert np.allclose(np.linalg.norm(n,axis=1),1,atol=1e-5)
    assert ((uv>=0)&(uv<=1)).all()
    bounds=doc['accessors'][prim['attributes']['POSITION']]
    assert np.allclose(p.min(axis=0),bounds['min']) and np.allclose(p.max(axis=0),bounds['max'])
    assert np.allclose(p[:,2].min(),-9.2) and np.allclose(p[:,2].max(),7)
    triangles=p[indices.reshape(-1,3)]
    face_normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    assert (np.linalg.norm(face_normals,axis=1)>1e-8).all(), 'Zero-area triangles'
    average_normals=n[indices.reshape(-1,3)].mean(axis=1)
    assert (np.sum(face_normals*average_normals,axis=1)>0).all(), 'Winding disagrees with normals'
    image=doc['images'][0]; view=doc['bufferViews'][image['bufferView']]
    embedded=binary[view['byteOffset']:view['byteOffset']+view['byteLength']]
    assert embedded==(ROOT/FILES[1]).read_bytes(), 'GLB and Defold textures differ'
    atlas=Image.open(io.BytesIO(embedded)); assert atlas.size==(1024,1024)
    icon=Image.open(ROOT/FILES[2]); assert icon.mode=='RGBA'
    box=icon.getbbox(); assert box and box[0]>0 and box[1]>0 and box[2]<icon.width and box[3]<icon.height
    model_path='/assets/models/patrol_interceptor/patrol_interceptor.model'
    definition=(ROOT/model_path.lstrip('/')).read_text()
    assert 'mesh: "/'+FILES[0]+'"' in definition
    assert 'textures: "/'+FILES[1]+'"' in definition
    for file in ('main/main.collection','main/remote_ships/patrol_interceptor_accord.go','main/data/ships.lua'):
        assert model_path in (ROOT/file).read_text()
    lua=(ROOT/'main/outpost.gui_script').read_text()
    pattern=r'\["'+re.escape(model_path)+r'"\] = \{ eye_offset = vmath.vector3\(([^)]+)\), far = ([\d.]+)'
    match=re.search(pattern,lua); assert match
    eye=np.array([float(x.strip()) for x in match[1].split(',')]); far=float(match[2])
    forward=-eye/np.linalg.norm(eye); right=np.cross(forward,[0,1,0]); right/=np.linalg.norm(right)
    up=np.cross(right,forward); worst=0
    for degrees in range(0,360,3):
        a=math.radians(degrees); co,si=math.cos(a),math.sin(a)
        rot=np.array([[co,0,si],[0,1,0],[-si,0,co]])
        view=p@rot.T-eye; depth=view@forward
        assert (depth>.1).all() and (depth<far).all()
        # Square modal is the narrowest preview; sale-grid cells are wider.
        x=view@right/(depth*math.tan(math.radians(22.5)))
        y=view@up/(depth*math.tan(math.radians(22.5)))
        worst=max(worst,float(np.abs(x).max()),float(np.abs(y).max()))
    assert worst<.95, f'Preview crops or leaves insufficient margin: {worst}'
    with tempfile.TemporaryDirectory(prefix='sardine-check-',dir=ROOT/'artifacts/sardine') as folder:
        subprocess.run([sys.executable,str(ROOT/'tools/build_sardine_model.py'),'--output-root',folder],check=True,capture_output=True)
        for file in FILES:
            assert (ROOT/file).read_bytes()==(Path(folder)/file).read_bytes(), f'Non-reproducible asset: {file}'
    result={'result':'PASS','triangles':len(indices)//3,'vertices':len(p),'glb_bytes':len(raw),
            'texture_px':list(atlas.size),'preview_max_ndc':round(worst,4),'preview_yaw_samples':120,
            'deterministic_outputs':len(FILES),'glb_sha256':hashlib.sha256(raw).hexdigest(),
            'checks':['binary layout and buffer bounds','finite geometry and unit normals','triangle area and winding','16-bit indices and 20k triangle budget','embedded/external texture equality','uncropped transparent top-down image','game asset references','full-rotation preview framing','byte-identical regeneration'],
            'not_tested':['Defold runtime rendering','HTML5 device performance','live multiplayer']}
    (ROOT/'artifacts/sardine/validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))


if __name__=='__main__': check()
