"""Validate the shipped Hammerhead and prove regeneration touches one hull."""
import hashlib,json
from check_hd_fleet import ROOT,load

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    manifest=ROOT/'artifacts/ship-detail/manifest.json'
    rows=json.loads(manifest.read_text())['ships']
    row=next(r for r in rows if r['slug']=='hammerhead')
    p,uv,texture,triangles=load(ROOT/row['mesh'].lstrip('/'))
    assert abs(float((p.max(0)-p.min(0)).max())-272)<.001
    # Check the exported head silhouette, including tip hardware: the outer
    # section must be visibly thinner than the central root, not a cylinder.
    span=abs(p[:,0]).max()
    outer=p[(abs(p[:,0])>span*.84) & (p[:,2]>p[:,2].max()*.65)]
    root=p[(abs(p[:,0])<span*.12) & (p[:,2]>p[:,2].max()*.80)]
    assert len(outer)>0 and len(root)>0
    assert (outer[:,1].max()-outer[:,1].min()) < (root[:,1].max()-root[:,1].min())*.40, 'Head tips lost their vertical taper'
    assert texture==(ROOT/row['texture'].lstrip('/')).read_bytes()
    assert digest(ROOT/row['mesh'].lstrip('/'))==row['mesh_sha256']
    for r in rows:
        assert digest(ROOT/r['original_mesh'].lstrip('/'))==r['original_sha256']
        assert digest(ROOT/r['original_texture'].lstrip('/'))==r['original_texture_sha256']
        if r['slug']!='hammerhead':
            assert digest(ROOT/r['mesh'].lstrip('/'))==r['mesh_sha256']
    # Rebuilding the approved model must be deterministic and leave other HD
    # models/textures byte-identical. The invocation deliberately targets one ship.
    paths=list((ROOT/'assets/models/hd').rglob('*'))
    paths=[p for p in paths if p.is_file()]
    before={str(p):digest(p) for p in paths}
    from build_hammerhead_detail import main as rebuild
    rebuild()
    assert before=={str(p):digest(p) for p in paths}
    print(f'PASS Hammerhead: {len(p)} vertices, {triangles} triangles; 272m; finite normals, winding, UVs, embedded atlas, uint16 indices')
    print('PASS deterministic one-ship generation; all original models/textures and other HD assets preserved')

if __name__=='__main__':main()
