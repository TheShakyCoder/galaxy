"""Independent geometry, preservation, integration and cosmetic checks for HD fleet."""
from pathlib import Path
import hashlib,io,json,math,re,struct
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):
 raw=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',raw)
 assert (magic,version,length)==(b'glTF',2,len(raw))
 jl,jt=struct.unpack_from('<II',raw,12);assert jt==0x4e4f534a
 doc=json.loads(raw[20:20+jl]);binary=raw[28+jl:]
 assert len(doc['meshes'])==1 and len(doc['meshes'][0]['primitives'])==1
 def arr(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
  width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
  dtype={5126:'<f4',5123:'<u2'}[a['componentType']]
  return np.frombuffer(binary,dtype=dtype,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,width)
 pr=doc['meshes'][0]['primitives'][0];p=arr(pr['attributes']['POSITION']);n=arr(pr['attributes']['NORMAL']);uv=arr(pr['attributes']['TEXCOORD_0']);idx=arr(pr['indices']).reshape(-1,3)
 assert all(np.isfinite(a).all() for a in (p,n,uv))
 assert len(p)<65536 and idx.max()<len(p) and idx.min()>=0
 assert np.allclose(np.linalg.norm(n,axis=1),1,atol=1e-4)
 assert (uv>=0).all() and (uv<=1).all()
 t=p[idx];face=np.cross(t[:,1]-t[:,0],t[:,2]-t[:,0]);area=np.linalg.norm(face,axis=1)
 assert (area>1e-8).all(),f'{(area<=1e-8).sum()} degenerate triangles'
 winding=np.sum(face*n[idx].mean(1),axis=1)
 assert (winding>0).all(),f'{(winding<=0).sum()} reversed triangles'
 v=doc['bufferViews'][doc['images'][0]['bufferView']];texture=binary[v['byteOffset']:v['byteOffset']+v['byteLength']]
 assert Image.open(io.BytesIO(texture)).size==(2048,2048)
 return p,uv,texture,len(idx)
def main():
 rows=json.loads((ROOT/'artifacts/ship-detail/manifest.json').read_text(encoding='utf8'))['ships']
 assert len(rows)==24 and sum(r['faction']=='accord' for r in rows)==12
 results=[];groups={}
 for r in rows:
  slug=r['slug'];path=ROOT/r['mesh'].lstrip('/');p,uv,texture,triangles=load(path)
  assert digest(path)==r['mesh_sha256']
  assert digest(ROOT/r['original_mesh'].lstrip('/'))==r['original_sha256']
  assert digest(ROOT/r['original_texture'].lstrip('/'))==r['original_texture_sha256']
  assert texture==(ROOT/r['texture'].lstrip('/')).read_bytes()
  extent=float(np.ptp(p,axis=0).max());assert abs(extent-r['extent'])<1e-3
  groups.setdefault((r['faction'],r['role']),{})[r['size']]=extent
  model=(ROOT/r['model'].lstrip('/')).read_text(encoding='utf8')
  assert r['mesh'] in model and r['texture'] in model and '/assets/materials/ship_finish/ship.material' in model
  for collection in ('aurora','royal_amethyst','solar_regatta'):
   m=ROOT/f'assets/skins/{slug}/{collection}/ship.model'
   assert r['mesh'] in m.read_text(encoding='utf8')
  if slug=='moray':
   points={tuple(np.round(v,4)) for v in p}
   assert all(tuple(np.round((-v[0],v[1],v[2]),4)) in points for v in p),'Moray lost bilateral symmetry'
  assert triangles>r['original_triangles']
  results.append({'ship':slug,'result':'PASS','vertices':len(p),'triangles':triangles,'extent':round(extent,3)})
  print('PASS '+slug,flush=True)
 for sizes in groups.values():
  assert abs(sizes['escort']/sizes['patrol']-4)<1e-4
  assert abs(sizes['frigate']/sizes['escort']-4)<1e-4
 (ROOT/'artifacts/ship-detail/validation.json').write_text(json.dumps({'checks':'finite geometry, normals, winding, UVs, uint16 budget, originals, textures, descriptors, recolors, Moray symmetry, size hierarchy','ships':results},indent=2)+'\n',encoding='utf8')
 print('PASS 24 hulls, 72 recolor descriptors, preserved originals and 1:4:16 sizing')
if __name__=='__main__':main()
