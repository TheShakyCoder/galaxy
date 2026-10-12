#!/usr/bin/env python3
"""Independently validate exported surface themes, runtime references and preservation."""
import argparse,hashlib,io,json,struct,subprocess,sys,tempfile
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
KEYS={'porcelain_dynasty','starlight','grand_prix'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read_glb(path):
    raw=path.read_bytes();assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
    length,kind=struct.unpack_from('<II',raw,12);assert kind==0x4e4f534a
    doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
    assert len(doc['meshes'])==1 and len(doc['meshes'][0]['primitives'])==1
    primitive=doc['meshes'][0]['primitives'][0]
    def arr(index):
        a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']]
        width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
        return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2'}[a['componentType']],count=a['count']*width,offset=view.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,width)
    p,n,uv=[arr(primitive['attributes'][name]) for name in ('POSITION','NORMAL','TEXCOORD_0')]
    idx=arr(primitive['indices']).reshape(-1,3)
    assert all(np.isfinite(a).all() for a in (p,n,uv))
    assert len(p)<65536 and idx.max()<len(p)
    assert np.allclose(np.linalg.norm(n,axis=1),1,atol=1e-4)
    assert ((uv>=0)&(uv<=1)).all()
    t=p[idx];face=np.cross(t[:,1]-t[:,0],t[:,2]-t[:,0])
    assert (np.linalg.norm(face,axis=1)>1e-8).all()
    assert (np.sum(face*n[idx].mean(1),axis=1)>0).all()
    view=doc['bufferViews'][doc['images'][0]['bufferView']]
    texture=binary[view['byteOffset']:view['byteOffset']+view['byteLength']]
    return p,n,uv,idx,texture

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--rebuild',action='store_true');args=parser.parse_args()
    rows=json.loads((ROOT/'artifacts/theme-detail/manifest.json').read_text(encoding='utf8'))['variants']
    legacy=json.loads((ROOT/'assets/skins/catalogs/themes-sprint-1.json').read_text(encoding='utf8'))['entries']
    legacy={r['id']:r for r in legacy}
    assert len(rows)==72 and {r['id'] for r in rows}==set(legacy)
    sources=json.loads((ROOT/'tools/themes/detail_sources/manifest.json').read_text(encoding='utf8'))['ships']
    sources={r['ship']:r for r in sources};assert len(sources)==24
    skin_index=(ROOT/'main/data/skins.lua').read_text(encoding='utf8')
    hub=(ROOT/'main/skin_hub.go').read_text(encoding='utf8');result=[]
    for r in rows:
        slug,key=r['ship'],r['collection'];assert key in KEYS
        source=ROOT/f'tools/themes/detail_sources/{slug}.npz'
        assert sha(source)==sources[slug]['sha256']==r['source_sha256']
        path=ROOT/r['mesh'].lstrip('/');p,n,uv,idx,texture=read_glb(path)
        assert sha(path)==r['mesh_sha256']
        with np.load(source,allow_pickle=False) as data:
            assert np.array_equal(p,data['p']) and np.array_equal(n,data['n'])
            assert np.array_equal(idx.reshape(-1),data['idx'])
            body=data['uv'][:,0]<.75
            assert np.array_equal(uv[body],data['uv'][body])
        assert len(p)==r['vertices'] and len(idx)==r['triangles']
        assert len(idx)>legacy[r['id']]['triangles']
        assert abs(float(np.ptp(p,axis=0).max())-r['extent'])<.001
        assert texture==(ROOT/r['texture'].lstrip('/')).read_bytes()
        assert sha(ROOT/r['texture'].lstrip('/'))==r['texture_sha256']
        assert Image.open(io.BytesIO(texture)).size==(2048,2048)
        old=legacy[r['id']]
        assert sha(ROOT/r['original_mesh'].lstrip('/'))==old['sha256']==r['original_mesh_sha256']
        assert sha(ROOT/r['original_texture'].lstrip('/'))==old['texture_sha256']==r['original_texture_sha256']
        model=(ROOT/r['model'].lstrip('/')).read_text(encoding='utf8')
        assert all(r[field] in model for field in ('mesh','texture','material'))
        material=(ROOT/r['material'].lstrip('/')).read_text(encoding='utf8')
        assert 'tags: "model"' in material and 'name: "tex0"' in material and 'name: "tint"' in material and 'name: "light"' in material
        assert r['model'] in (ROOT/f'assets/skins/{slug}/{key}/ship.go').read_text(encoding='utf8')
        line=next(line for line in skin_index.splitlines() if f'["{r["id"]}"]' in line)
        assert 'flight_factory =' in line and f'skin_factory_{slug}_{key}' in hub
        if slug=='moray':
            pts={tuple(np.round(v,4)) for v in p}
            assert all(tuple(np.round((-v[0],v[1],v[2]),4)) in pts for v in p)
        result.append({'id':r['id'],'triangles':len(idx),'vertices':len(p),'result':'PASS'})
    # Every legacy skin mesh and texture, not just the selected three, remains intact.
    all_legacy=json.loads((ROOT/'assets/skins/catalog.json').read_text(encoding='utf8'))['entries']
    for r in all_legacy:
        assert sha(ROOT/r['glb'])==r['sha256'],r['id']+' legacy mesh changed'
        assert sha(ROOT/r['texture'].lstrip('/'))==r['texture_sha256'],r['id']+' legacy texture changed'
    if args.rebuild:
        with tempfile.TemporaryDirectory(prefix='theme-rebuild-',dir=ROOT/'artifacts/theme-detail') as temp:
            subprocess.run([sys.executable,str(ROOT/'tools/build_hd_surface_themes.py'),'--output-root',temp,'--integrate'],check=True,stdout=subprocess.DEVNULL)
            for r in rows:
                for field in ('mesh','texture','model'):
                    relative=r[field].lstrip('/')
                    assert sha(ROOT/relative)==sha(Path(temp)/relative),r['id']+' rebuild mismatch '+field
    report={'result':'PASS','variants':72,'legacy_skins_preserved':len(all_legacy),'rebuild_verified':args.rebuild,
        'checks':'binary geometry, normals, winding, UVs, detailed-source equality, 2K texture agreement, original hashes, material contracts, factory integration, Moray symmetry, exact extents','rows':result}
    (ROOT/'artifacts/theme-detail/validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(f'PASS: 72 detailed surface themes; {len(all_legacy)} original skins preserved; deterministic rebuild={args.rebuild}')
if __name__=='__main__':main()
