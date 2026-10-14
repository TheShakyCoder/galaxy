"""Bake original spherical nebula fields and stars. Python + numpy + Pillow.

All cube faces sample the same continuous 3D field: no longitude seam or pole.
R = turbulent gas, G = dark dust/detail, B = stars. No external image assets.
"""
from pathlib import Path
import argparse, hashlib, json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FACES = ('right','left','top','bottom','front','back')

def directions(face, u, v):
    one=np.ones_like(u)
    vectors=((one,-v,-u),(-one,-v,u),(u,one,v),(u,-one,-v),(u,-v,one),(-u,-v,-one))
    d=np.stack(vectors[face],axis=-1)
    return d/np.linalg.norm(d,axis=-1,keepdims=True)

def lattice(x,y,z,seed):
    with np.errstate(over='ignore'):
        h=x.astype(np.uint32)*np.uint32(374761393)+y.astype(np.uint32)*np.uint32(668265263)+z.astype(np.uint32)*np.uint32(2147483647)+np.uint32(seed)
        h=(h^(h>>13))*np.uint32(1274126177)
        h=h^(h>>16)
    return (h&0xffffff).astype(np.float32)/16777215

def noise(p,seed):
    q=np.floor(p).astype(np.int32);f=p-q;f=f*f*f*(f*(f*6-15)+10)
    out=np.zeros(p.shape[:-1],np.float32)
    for x in range(2):
        for y in range(2):
            for z in range(2):
                w=(f[...,0] if x else 1-f[...,0])*(f[...,1] if y else 1-f[...,1])*(f[...,2] if z else 1-f[...,2])
                out+=w*lattice(q[...,0]+x,q[...,1]+y,q[...,2]+z,seed)
    return out

def fbm(p,seed,octaves=7):
    out=np.zeros(p.shape[:-1],np.float32);weight=0.55;total=0
    for i in range(octaves):
        out+=weight*noise(p,seed+i*713);total+=weight
        p=p*2.07+np.array([7.3,11.1,3.7]);weight*=0.52
    return out/total

def fields(d):
    p=d*3.4+17
    warp=np.stack([fbm(p+i*9.7,613+i*311,4) for i in range(3)],axis=-1)
    gas=fbm(p+warp*2.7,9191)
    dust=fbm(p*1.8+warp*3.8,1729)
    # Broad clouds with finely branching shadows; both remain continuously spherical.
    return np.stack([np.clip((gas-.23)*1.8,0,1),np.clip((dust-.25)*1.9,0,1)],axis=-1)

def stars(face,n):
    rng=np.random.default_rng(20261012)
    d=rng.normal(size=(17000,3));d/=np.linalg.norm(d,axis=1)[:,None]
    amplitude=.025+.53*rng.power(.38,len(d))
    sigma=.40+rng.random(len(d))*.32
    amplitude[:36]=.88;sigma[:36]=1.0
    # Project a spherical catalogue onto every relevant face, including edge spill.
    x,y,z=d.T
    denom=(x,-x,y,-y,z,-z)[face]
    uu=(-z,z,x,x,x,-x)[face]/np.maximum(denom,1e-8)
    vv=(-y,-y,z,-z,-y,-y)[face]/np.maximum(denom,1e-8)
    px=(uu+1)*n/2-.5;py=(vv+1)*n/2-.5
    image=np.zeros((n,n),np.float32)
    for i in np.flatnonzero((denom>0)&(np.abs(uu)<1.025)&(np.abs(vv)<1.025)):
        # Approximate angular footprint accounts for gnomonic projection.
        sig=sigma[i]/denom[i];radius=int(np.ceil(sig*5))
        a,b=max(0,int(px[i])-radius),min(n,int(px[i])+radius+2)
        c,e=max(0,int(py[i])-radius),min(n,int(py[i])+radius+2)
        if a>=b or c>=e: continue
        yy,xx=np.mgrid[c:e,a:b];dist=((xx-px[i])**2+(yy-py[i])**2)/sig**2
        glow=np.exp(-dist*.5)*amplitude[i]
        if i<36: glow+=.075*np.exp(-dist*.06)
        image[c:e,a:b]+=glow
    return np.clip(image,0,1)

def build(out,size=1024):
    out.mkdir(parents=True,exist_ok=True);manifest={'size':size,'seed':20261012,'stars':17000,'faces':{}}
    for face,name in enumerate(FACES):
        texture=np.zeros((size,size,3),np.uint8)
        for start in range(0,size,64):
            yy,xx=np.mgrid[start:min(start+64,size),0:size]
            d=directions(face,(xx+.5)*2/size-1,(yy+.5)*2/size-1)
            values=fields(d)
            # 6-bit scalar fields compress well losslessly. Their low-intensity
            # colour grade, filtered interpolation and final shader dither keep
            # gradients smooth. Stars retain all eight bits independently.
            texture[start:start+len(yy),:,:2]=(np.rint(np.clip(values,0,1)*63)*4).astype(np.uint8)
        texture[:,:,2]=np.rint(stars(face,size)*255).astype(np.uint8)
        p=out/(name+'.png');Image.fromarray(texture).save(p,optimize=True)
        manifest['faces'][name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
        print(name,flush=True)
    (out/'fields.cubemap').write_text(''.join(f'{name}: "/assets/space/{name}.png"\n' for name in FACES),encoding='utf8')
    manifest['png_bytes']=sum(v['bytes'] for v in manifest['faces'].values())
    manifest['rgba8_mip_bytes']=6*sum(max(1,size>>i)**2*4 for i in range(size.bit_length()))
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    return manifest

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,default=ROOT/'assets/space');ap.add_argument('--size',type=int,default=1024)
    args=ap.parse_args();print(json.dumps(build(args.output,args.size),indent=2))
