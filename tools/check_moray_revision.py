"""Regression gates for the explicitly requested symmetrical Moray revision."""
import hashlib
import json
from pathlib import Path
import subprocess
import numpy as np
from check_cosmetic_library import load

ROOT=Path(__file__).resolve().parents[1]
BASE='63d8a53'
MORAY='assets/models/escort_assault/moray.glb'


def git(*args):
    return subprocess.check_output(['git','-c','safe.directory='+ROOT.as_posix(),*args],cwd=ROOT)


def preserved_assets():
    """Only the default Moray GLB, its 12 GLBs and catalog metadata may change."""
    catalogs=['assets/cosmetics/catalog.json']
    allowed={MORAY,*catalogs}; variants=[]
    for path in catalogs:
        before=json.loads(git('show',BASE+':'+path));after=json.loads((ROOT/path).read_text())
        assert {k:v for k,v in before.items() if k!='entries'}=={k:v for k,v in after.items() if k!='entries'}
        old={r['id']:r for r in before['entries']};new={r['id']:r for r in after['entries']}
        assert set(old)==set(new)
        for key,r in new.items():
            if r['ship']=='moray':
                allowed.add(r['glb']);variants.append(r)
            else:assert r==old[key],'Unrelated catalog entry changed: '+key
    changed=set(git('diff','--name-only',BASE,'--','assets').decode().splitlines())
    assert changed<=allowed,'Unrelated assets changed: '+str(changed-allowed)
    fleet=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())
    old_fleet=json.loads(git('show',BASE+':artifacts/fleet/manifest.json'))
    assert [r for r in fleet['ships'] if r['slug']!='moray']==[r for r in old_fleet['ships'] if r['slug']!='moray']
    # Limit game-code changes to the generated Moray camera, escort-assault
    # camera (shared chassis), and Moray descriptive comment.
    game_changes=set(git('diff','--name-only',BASE,'--','main','game.project').decode().splitlines())
    assert game_changes<={'main/outpost.gui_script','main/data/ships.lua'}
    for file in ('main/outpost.gui_script','main/data/ships.lua'):
        before=git('show',BASE+':'+file).decode().splitlines();after=(ROOT/file).read_text(encoding='utf-8').splitlines()
        assert len(before)==len(after)
        for a,b in zip(before,after):
            if a==b:continue
            assert (('moray.model' in a and 'moray.model' in b and 'eye_offset' in a and 'eye_offset' in b)
                    or (a.strip().startswith('-- Moray:') and b.strip().startswith('-- Moray:'))
                    or ('flight_camera = { distance = 54.506, height = 8.301 }' in a
                        and 'flight_camera = { distance = 54.444, height = 8.283 }' in b)),file
    return {r['id']:r for r in variants}


def main():
    rows=preserved_assets();assert len(rows)==4
    p,n,uv,idx,_=load(ROOT/MORAY)
    points={tuple(v) for v in np.round(p,4)}
    assert all((-x,y,z) in points for x,y,z in points),'Default Moray is not bilaterally symmetric'
    body=p[uv[:,0]<.75]
    for z in np.unique(body[:,2]):
        ring=body[body[:,2]==z];assert abs(float(ring[:,0].min()+ring[:,0].max()))<1e-5
    assert abs(float(np.ptp(p,axis=0).max())-42)<1e-4
    sha=hashlib.sha256((ROOT/MORAY).read_bytes()).hexdigest()
    for r in rows.values():
        a,b,c,d,_=load(ROOT/r['glb'])
        assert r['base_sha256']==sha
        assert np.array_equal(a[:len(p)],p) and np.array_equal(b[:len(n)],n)
        assert np.array_equal(d[:len(idx)],idx)
        assert np.array_equal(c[:len(uv)][uv[:,0]<.75],uv[uv[:,0]<.75])
    report=dict(result='PASS',revision_base=BASE,default_bilateral_symmetry_tolerance_m=.0001,
                straight_hull_rings=True,extent_m=42,cosmetics_checked=4,
                all_cosmetics_retain_revised_hull=True,other_ship_resources_unchanged=True,
                other_catalog_entries_unchanged=True,gameplay_unchanged=True,
                note='Cosmetic ornament such as the Toybox key remains intentionally asymmetric; every hull is symmetrical.')
    folder=ROOT/'artifacts/moray';folder.mkdir(exist_ok=True)
    (folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: symmetrical straight 42m Moray; all 4 existing skins use revised hull; all other ship assets unchanged')


if __name__=='__main__':main()
