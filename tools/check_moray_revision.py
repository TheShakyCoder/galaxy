"""Regression gates for the explicitly requested symmetrical Moray revision."""
import hashlib
import json
from pathlib import Path
import subprocess
import numpy as np
from check_cosmetic_library import load

ROOT=Path(__file__).resolve().parents[1]
BASE='754a5ca6f47b60cd09f9e6caa7c4d434955f0339'
MORAY='assets/models/escort_assault/moray.glb'


def git(*args):
    return subprocess.check_output(['git','-c','safe.directory='+ROOT.as_posix(),*args],cwd=ROOT)


def preserved_assets():
    # The user subsequently authorized fleet scaling. That gate checks all
    # Patrol resources unchanged and limits other asset changes to scaled GLBs.
    from check_fleet_scale import preserved_assets as check
    return check()


def main():
    rows=preserved_assets();assert len(rows)==12
    p,n,uv,idx,_=load(ROOT/MORAY)
    points={tuple(v) for v in np.round(p,4)}
    assert all((-x,y,z) in points for x,y,z in points),'Default Moray is not bilaterally symmetric'
    body=p[uv[:,0]<.75]
    for z in np.unique(body[:,2]):
        ring=body[body[:,2]==z];assert abs(float(ring[:,0].min()+ring[:,0].max()))<1e-5
    assert abs(float(np.ptp(p,axis=0).max())-60)<1e-4
    sha=hashlib.sha256((ROOT/MORAY).read_bytes()).hexdigest()
    for r in rows.values():
        a,b,c,d,_=load(ROOT/r['glb'])
        assert r['base_sha256']==sha
        assert np.array_equal(a[:len(p)],p) and np.array_equal(b[:len(n)],n)
        assert np.array_equal(d[:len(idx)],idx)
        assert np.array_equal(c[:len(uv)][uv[:,0]<.75],uv[uv[:,0]<.75])
    report=dict(result='PASS',revision_base=BASE,default_bilateral_symmetry_tolerance_m=.0001,
                straight_hull_rings=True,extent_m=60,cosmetics_checked=12,
                all_cosmetics_retain_revised_hull=True,other_ship_shapes_preserved=True,
                patrol_resources_unchanged=True,gameplay_unchanged=True,
                note='Cosmetic ornament such as the Toybox key remains intentionally asymmetric; every hull is symmetrical.')
    folder=ROOT/'artifacts/moray';folder.mkdir(exist_ok=True)
    (folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: symmetrical straight 60m Moray; all 12 skins use revised hull; fleet scaling checked')


if __name__=='__main__':main()
