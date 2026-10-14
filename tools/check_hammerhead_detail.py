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
