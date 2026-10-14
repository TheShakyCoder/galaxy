"""Read generated GLB bytes independently; validate bounds, UVs and reproducibility."""
import argparse,hashlib,json,math,struct,subprocess,sys
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/models/stations'
def load(path):
    raw=path.read_bytes();assert raw[:4]==b'glTF'
    length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
    prim=doc['meshes'][0]['primitives'][0]
    def values(idx):
        a=doc['accessors'][idx];v=doc['bufferViews'][a['bufferView']];width={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']];kind={5126:'f',5123:'H'}[a['componentType']]
        fmt='<'+kind*width;size=struct.calcsize(fmt);offset=v.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from(fmt,binary,offset+i*size) for i in range(a['count'])]
    p=values(prim['attributes']['POSITION']);n=values(prim['attributes']['NORMAL']);uv=values(prim['attributes']['TEXCOORD_0']);indices=[v[0] for v in values(prim['indices'])]
    assert len(p)==len(n)==len(uv) and len(indices)%3==0
    assert all(math.isfinite(v) for rows in (p,n,uv) for row in rows for v in row)
    assert all(abs(sum(x*x for x in normal)-1)<1e-4 for normal in n)
    assert all(0<=v<=1 for row in uv for v in row)
    for i in range(0,len(indices),3):
        ids=indices[i:i+3];assert max(ids)<len(p)
        a,b,c=[p[j] for j in ids];u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
        cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
        assert sum(x*x for x in cross)>1e-8,'degenerate triangle'
        assert sum(cross[k]*n[ids[0]][k] for k in range(3))>0,'normal/winding mismatch'
    return p,len(indices)//3
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--rebuild',action='store_true');args=ap.parse_args()
    paths=list(OUT.rglob('*'));before={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths if p.is_file()}
    if args.rebuild:
        subprocess.run([sys.executable,str(ROOT/'tools/build_stations.py')],check=True)
        for name,digest in before.items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name+' nondeterministic'
    rows=[]
    ad,adtri=load(OUT/'ad.glb');assert adtri==2
    assert max(p[0] for p in ad)-min(p[0] for p in ad)==100
    assert max(p[2] for p in ad)-min(p[2] for p in ad)==200
    for row in json.loads((OUT/'manifest.json').read_text())['stations']:
        f=row['faction'];fixed,ft=load(OUT/f/'fixed.glb');rotor,rt=load(OUT/f/'rotor.glb');pivot=row['pivot']
        assert len(row['slots'])==8
        if f=='swarm':
            # Turned frames cross both rim rings axially. Their back faces
            # are 10 m behind the ad plane and must clear the slimmed 274.5 m rims.
            assert all(r-10>274.5 for _,r,_ in row['slots']), 'Swarm rim obscures turned billboard'
        for a,r,z in row['slots']:
            # Transform all four billboard corners around the actual rotor axis.
            for x,y,zz in ad:rotor.append((-math.sin(a)*x+math.cos(a)*r,math.cos(a)*x+math.sin(a)*r,z+zz))
        radius=max(math.hypot(p[0],p[1]) for p in rotor)
        low=[min(p[k] for p in fixed) for k in range(3)];high=[max(p[k] for p in fixed) for k in range(3)]
        for k in (0,1):low[k]=min(low[k],pivot[k]-radius);high[k]=max(high[k],pivot[k]+radius)
        low[2]=min(low[2],pivot[2]+min(p[2] for p in rotor));high[2]=max(high[2],pivot[2]+max(p[2] for p in rotor))
        dims=[high[k]-low[k] for k in range(3)];assert max(dims)<=800,(f,dims)
        assert ft+rt+16<=40000
        # Rotating envelope's farthest possible point from preserved gameplay root.
        far=math.sqrt((radius+math.hypot(pivot[0],pivot[1]))**2+max(abs(low[2]),abs(high[2]))**2)
        assert far<1000,'visual structure outside unchanged docking sphere'
        assert Image.open(OUT/f/'hull.png').size==(2048,2048)
        rows.append(dict(faction=f,triangles=ft+rt+16,swept_radius=radius,swept_aabb_min=low,swept_aabb_max=high,dimensions=dims,conservative_root_distance=far,model_draws=10))
    for p in (OUT/'ads').glob('*.png'):assert Image.open(p).size==(1024,512)
    texels=sum(max(1,2048>>i)**2 for i in range(12))*2+sum(max(1,1024>>i)*max(1,512>>i) for i in range(11))*8
    result={'stations':rows,'byte_identical_rebuild':args.rebuild,'source_bytes':sum(p.stat().st_size for p in OUT.rglob('*') if p.is_file()),'texture_memory_rgb8_mips_bytes':texels*3,'texture_memory_rgba8_mips_upper_bytes':texels*4,'notes':['Bounds include every billboard and the full analytic rotational sweep.','Draw counts are component upper bounds, not measured GPU timing.','RGB8 with full mip chains; conservative RGBA8 allowance for drivers expanding RGB storage.']}
    dest=ROOT/'artifacts/stations';dest.mkdir(parents=True,exist_ok=True);(dest/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
if __name__=='__main__':main()
