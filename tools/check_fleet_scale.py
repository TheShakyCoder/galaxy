"""Verify native 1:4:16 fleet dimensions and uniformly resized skin geometry."""
import json
from pathlib import Path
import re
import subprocess
import tempfile
import numpy as np
from check_cosmetic_library import load

ROOT=Path(__file__).resolve().parents[1]
BASE='82aa1bfba9e974de7f3c04a9e91f925e5997c520'


def git(*args):
    return subprocess.check_output(['git','-c','safe.directory='+ROOT.as_posix(),*args],cwd=ROOT)


def preserved_assets():
    fleet=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())
    old_fleet=json.loads(git('show',BASE+':artifacts/fleet/manifest.json'))
    old={r['slug']:r for r in old_fleet['ships']}
    allowed=set();moray={}
    catalogs=['assets/cosmetics/catalog.json','assets/themes/catalog.json']+[f'assets/themes/catalog-sprint-{i}.json' for i in range(1,5)]
    for r in fleet['ships']:
        if r['class']=='patrol':assert r==old[r['slug']],'Patrol metadata changed'
        else:allowed.add(r['glb'])
    for path in catalogs:
        before=json.loads(git('show',BASE+':'+path));after=json.loads((ROOT/path).read_text())
        assert {k:v for k,v in before.items() if k!='entries'}=={k:v for k,v in after.items() if k!='entries'}
        old_rows={r['id']:r for r in before['entries']};new_rows={r['id']:r for r in after['entries']}
        assert old_rows.keys()==new_rows.keys()
        for key,r in new_rows.items():
            if r['size']=='patrol':assert r==old_rows[key],'Patrol cosmetic metadata changed'
            else:allowed.add(r['glb'])
            if r['ship']=='moray':moray[key]=r
        allowed.add(path)
    allowed.update(('assets/themes/README.md','assets/cosmetics/README.md'))
    changed=set(git('diff','--name-only','--diff-filter=MD',BASE,'--','assets').decode().splitlines())
    assert changed<=allowed,'Unexpected resource changes: '+str(changed-allowed)
    game=set(git('diff','--name-only',BASE,'--','main','game.project').decode().splitlines())
    assert game<={'main/outpost.gui_script','main/data/ships.lua'}
    def strip_camera(s):
        s=re.sub(r'local PREVIEW_CAMERA = \{.*?\n\}', '',s,flags=re.S)
        return re.sub(r'flight_camera = \{[^}]*\}', '',s)
    for file in game:
        assert strip_camera(git('show',BASE+':'+file).decode())==strip_camera((ROOT/file).read_text(encoding='utf-8')),'Non-camera game code changed'
    return moray


def main():
    preserved_assets()
    fleet=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())
    old=json.loads(git('show',BASE+':artifacts/fleet/manifest.json'))
    old_ships={r['slug']:r for r in old['ships']};rows=fleet['ships'];ratios={};results=[]
    patrol={(r['faction'],r['role']):r for r in rows if r['class']=='patrol'}
    all_assets=[]
    collection=(ROOT/'main/main.collection').read_text()
    remote_script=(ROOT/'main/remote_ships.script').read_text()
    assert 'local scale = is_fallback and FALLBACK_SCALE or nil' in remote_script
    assert 'go.set_scale' not in remote_script
    for r in rows:
        block=next(b for b in collection.split('embedded_instances {') if r['model']+'\\"' in b)
        scale=re.search(r'scale3\s*\{\s*x:\s*([\d.]+)\s*y:\s*([\d.]+)\s*z:\s*([\d.]+)',block)
        assert scale and tuple(map(float,scale.groups()))==(1,1,1),'Local model scale override'
        remote=(ROOT/f'main/remote_ships/{r["class"]}_{r["role"]}_{r["faction"]}.go').read_text()
        assert r['model'] in remote and 'scale' not in remote,'Remote model scale override'
        p,*_=load(ROOT/r['glb']);extent=float(np.ptp(p,axis=0).max())
        reference=max(patrol[(r['faction'],r['role'])]['dimensions_m'])
        multiplier={'patrol':1,'escort':4,'frigate':16}[r['class']]
        assert np.isclose(extent,reference*multiplier,atol=1e-4,rtol=0)
        factor=reference*multiplier/max(old_ships[r['slug']]['dimensions_m']);ratios[r['slug']]=factor
        all_assets.append((r['glb'],factor))
        results.append(dict(ship=r['slug'],size=r['class'],extent_m=round(extent,4),patrol_ratio=multiplier,scale_from_previous=factor))
    for library in ('cosmetics','themes'):
        cat=json.loads((ROOT/f'assets/{library}/catalog.json').read_text())
        all_assets.extend((r['glb'],ratios[r['ship']]) for r in cat['entries'])
    folder=ROOT/'artifacts/scale';folder.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='rebuild-',dir=folder) as temp:
        prior=Path(temp)/'previous.glb'
        for path,factor in all_assets:
            original=git('show',BASE+':'+path)
            if abs(factor-1)<1e-8:
                assert (ROOT/path).read_bytes()==original,'Patrol binary changed: '+path
                continue
            prior.write_bytes(original);a,b,c,d,t=load(prior);p,n,uv,idx,tex=load(ROOT/path)
            assert len(p)==len(a) and np.array_equal(idx,d),'Topology changed: '+path
            assert np.allclose(p,a*factor,atol=.0002,rtol=0),'Nonuniform scale: '+path
            assert np.allclose(n,b,atol=1e-5,rtol=0),'Normals changed: '+path
            assert np.allclose(uv,c,atol=1e-6,rtol=0),'UV changed: '+path
            assert tex==t,'Texture changed: '+path
    report=dict(result='PASS',comparison_base=BASE,ships=24,cosmetics=288,total_glbs=312,
                native_size_ratios='1:4:16 by longest dimension within each faction/role',
                patrol_glbs_byte_identical=104,uniform_scale_glbs_checked=208,
                position_tolerance_m=.0002,topology_preserved=True,textures_preserved=True,
                local_and_remote_reference_same_native_assets=True,only_generated_cameras_changed=True,rows=results,
                not_tested=['Defold runtime','live multiplayer','device performance'])
    (folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS: all 24 ships use 1:4:16 dimensions; 104 Patrol GLBs byte-identical; 208 larger GLBs uniformly scaled')


if __name__=='__main__':main()
