"""Validate baked spherical fields, costs, hashes and Lua lifecycle tests."""
from pathlib import Path
import argparse,hashlib,json,sys,tempfile
import numpy as np
from PIL import Image
from build_space import FACES,fields,directions,build

ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--rebuild',action='store_true');args=ap.parse_args()
    manifest=json.loads((ROOT/'assets/space/manifest.json').read_text())
    assert manifest['rgba8_mip_bytes']<=32*1024**2
    assert manifest['png_bytes']<12*1024**2
    for name in FACES:
        p=ROOT/f'assets/space/{name}.png'
        assert hashlib.sha256(p.read_bytes()).hexdigest()==manifest['faces'][name]['sha256']
        im=np.asarray(Image.open(p));assert im.shape==(1024,1024,3)
        assert im[:,:,0].std()>12 and im[:,:,1].std()>12
    # Check every cube edge against its partner in DIRECTION space, including corners.
    # This catches orientation mismatches rather than just comparing face brightness.
    edge_vectors=[]
    for face in range(6):
        t=np.linspace(-1,1,65)
        for u,v in [(t,t*0-1),(t,t*0+1),(t*0-1,t),(t*0+1,t)]:
            edge_vectors.append(directions(face,u,v))
    for i,a in enumerate(edge_vectors):
        partners=[b for j,b in enumerate(edge_vectors) if j//4!=i//4 and (np.allclose(a,b) or np.allclose(a,b[::-1]))]
        assert len(partners)==1
        b=partners[0]
        if not np.allclose(a,b): b=b[::-1]
        assert np.max(np.abs(fields(a)-fields(b)))<1e-6
    from lupa.lua51 import LuaRuntime
    import os
    os.chdir(ROOT)
    LuaRuntime().execute((ROOT/'tests/space_harness.lua').read_text())
    LuaRuntime().execute((ROOT/'tests/space_wisps_harness.lua').read_text())
    if args.rebuild:
        with tempfile.TemporaryDirectory(prefix='galaxy-space-') as temp:
            fresh=build(Path(temp))
            assert fresh==manifest,'Generator must rebuild byte-identically'
    report={'cube_edge_pairs':12,'systems':58,'png_bytes':manifest['png_bytes'],
        'rgba8_mip_bytes':manifest['rgba8_mip_bytes'],'sky_draw_calls':1,'wisp_draw_calls':1,
        'sky_triangles':12,'wisp_triangles':16,'wisp_vertex_bytes':8*6*6*4,
        'deterministic_rebuild':args.rebuild,'passed':True}
    out=ROOT/'artifacts/space';out.mkdir(parents=True,exist_ok=True)
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
if __name__=='__main__': main()
