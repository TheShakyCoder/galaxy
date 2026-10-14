"""Seeded periodic rock height/cavity/vein field. No resource-dependent pixels."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def build():
    size=256;rng=np.random.default_rng(130917)
    y,x=np.mgrid[:size,:size]/size
    height=np.zeros((size,size))
    for cells,weight in ((4,.42),(8,.25),(16,.17),(32,.10),(64,.06)):
        grid=rng.random((cells,cells));xx=x*cells;yy=y*cells
        ix=xx.astype(int);iy=yy.astype(int);u=xx-ix;v=yy-iy
        u=u*u*(3-2*u);v=v*v*(3-2*v)
        height+=weight*((grid[iy%cells,ix%cells]*(1-u)+grid[iy%cells,(ix+1)%cells]*u)*(1-v)+(grid[(iy+1)%cells,ix%cells]*(1-u)+grid[(iy+1)%cells,(ix+1)%cells]*u)*v)
    nearest=np.full((size,size),10.);second=nearest.copy()
    for cx,cy in rng.random((28,2)):
        dx=np.minimum(abs(x-cx),1-abs(x-cx));dy=np.minimum(abs(y-cy),1-abs(y-cy));d=np.sqrt(dx*dx+dy*dy)
        second=np.minimum(second,np.maximum(nearest,d));nearest=np.minimum(nearest,d)
    gap=second-nearest
    vein=np.clip(1-gap/.012,0,1)**2
    cavity=np.clip((height-.3)*1.5,0,1)
    height=np.clip(height-vein*.12,0,1)
    rgb=np.stack((height,vein,cavity),axis=-1)
    path=ROOT/'assets/models/asteroids/surface.png';Image.fromarray(np.rint(rgb*255).astype('uint8')).save(path)
    print(path)
if __name__=='__main__':build()
