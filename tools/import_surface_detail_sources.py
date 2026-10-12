#!/usr/bin/env python3
"""Explicit authoring operation: refresh surface-theme geometry snapshots from an HD fleet checkout.

Normal theme builds use the checked-in snapshots and do not require another PR.
Run this only when intentionally adopting a revised detailed hull generation.
"""
import argparse,hashlib,json,subprocess
from pathlib import Path
import numpy as np
from cosmetics.glb import read_mesh
from fleet.roster import SHIPS
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--fleet-root',type=Path,required=True);a=p.parse_args()
    source=a.fleet_root.resolve();meshes=[]
    # Validate every input before changing the current authoring sources.
    for ship in SHIPS:
        path=source/'assets/models/hd'/ship.slug/'ship.glb';mesh=read_mesh(ship,path)
        points=np.array(mesh.p,dtype='<f4');normals=np.array(mesh.n,dtype='<f4')
        assert np.isfinite(points).all() and np.isfinite(normals).all()
        assert len(points)<65536 and abs(float(np.ptp(points,axis=0).max())-ship.extent)<.001
        meshes.append((ship,path,points,normals,np.array(mesh.uv,dtype='<f4'),np.array(mesh.idx,dtype='<u2')))
    revision=subprocess.check_output(['git','-c',f'safe.directory={source.as_posix()}','-C',str(source),'rev-parse','HEAD'],text=True).strip()
    dest=ROOT/'tools/themes/detail_sources';dest.mkdir(parents=True,exist_ok=True);rows=[]
    for ship,path,points,normals,uv,idx in meshes:
        target=dest/(ship.slug+'.npz');np.savez_compressed(target,p=points,n=normals,uv=uv,idx=idx)
        rows.append(dict(ship=ship.slug,source_glb_sha256=sha(path),sha256=sha(target),vertices=len(points),triangles=len(idx)//3))
    (dest/'manifest.json').write_text(json.dumps({'source_commit':revision,'format':'Lossless float32 position/normal/UV and uint16 indices. Offline authoring sources, not runtime dependencies.','ships':rows},indent=2)+'\n',encoding='utf8')
    print('Imported 24 sources. Rebuild and validate the complete surface-theme library before committing.')
if __name__=='__main__':main()
