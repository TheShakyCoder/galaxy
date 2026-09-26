#!/usr/bin/env python3
"""Build Galaxy's original sardine-shaped Accord interceptor (Python + Pillow + NumPy).

Run from any directory: python tools/build_sardine_model.py
Optional --output-root DIR stages all three outputs without changing game assets.

Meters; nose +Z, dorsal +Y. Single mesh/material, explicit smooth normals,
16-bit indices, embedded base-color atlas plus matching Defold external texture.
The historical sardine_palette.png filename now holds a 1024px detail atlas.
No downloaded art, external textures, PBR-only effects, or Blender dependency.
"""
import argparse
import io
import json
import math
import struct
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

TAU = math.tau
ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
ATLAS_END = 0.75
COLORS = {
    'navy': (20, 42, 55), 'blue': (36, 77, 92),
    'teal': (58, 113, 124), 'silver': (173, 194, 200),
    'pearl': (215, 225, 224), 'edge': (110, 146, 157),
    'dark': (13, 25, 34), 'glass': (25, 72, 94),
    'cyan': (108, 220, 225), 'white': (215, 247, 243),
    'brass': (186, 160, 102), 'fin': (81, 124, 138),
    'fin_light': (135, 172, 177), 'nozzle': (46, 58, 65),
    'panel': (127, 161, 174), 'spot': (30, 66, 81),
}
# (Z, half width, half height): a rounded head and long, gently tapering body.
# Rounded cross section is intentionally unlike a shark's wedge-shaped snout.
PROFILE = [
    (-6.45, .24, .25), (-5.8, .31, .34), (-4.8, .48, .51),
    (-3.5, .76, .78), (-2, 1.05, 1.02), (0, 1.31, 1.24),
    (1.8, 1.42, 1.35), (3.3, 1.36, 1.30), (4.5, 1.20, 1.14),
    (5.4, .94, .90), (6.15, .64, .65), (6.65, .34, .38),
    (6.90, .15, .20), (7.0, .045, .07),
]


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def unit(a): return mul(a, 1 / math.sqrt(dot(a, a)))


def profile(z):
    """Monotone cubic Hermite interpolation avoids bumps between hull stations."""
    z = max(PROFILE[0][0], min(PROFILE[-1][0], z))
    k = next((i for i in range(len(PROFILE)-1) if z <= PROFILE[i+1][0]), len(PROFILE)-2)
    def channel(c):
        def slope(i):
            if i == 0: return (PROFILE[1][c]-PROFILE[0][c])/(PROFILE[1][0]-PROFILE[0][0])
            if i == len(PROFILE)-1: return (PROFILE[-1][c]-PROFILE[-2][c])/(PROFILE[-1][0]-PROFILE[-2][0])
            a = (PROFILE[i][c]-PROFILE[i-1][c])/(PROFILE[i][0]-PROFILE[i-1][0])
            b = (PROFILE[i+1][c]-PROFILE[i][c])/(PROFILE[i+1][0]-PROFILE[i][0])
            return 0 if a*b <= 0 else 2*a*b/(a+b)
        h = PROFILE[k+1][0]-PROFILE[k][0]
        t = (z-PROFILE[k][0])/h
        return ((2*t**3-3*t*t+1)*PROFILE[k][c] + (t**3-2*t*t+t)*h*slope(k)
                + (-2*t**3+3*t*t)*PROFILE[k+1][c] + (t**3-t*t)*h*slope(k+1))
    return channel(1), channel(2)


def surface(z, angle, offset=0):
    w, h = profile(z)
    return ((w+offset)*math.sin(angle), (h+offset)*math.cos(angle), z)


def surface_normal(z, angle):
    a = sub(surface(min(7, z+.002), angle), surface(max(-6.45, z-.002), angle))
    b = sub(surface(z, angle+.002), surface(z, angle-.002))
    return unit(cross(a, b))


def make_atlas():
    img = Image.new('RGB', (SIZE, SIZE), COLORS['navy'])
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        c = math.cos(TAU*(y+.5)/SIZE)
        if c > .38:
            t = min(1, (c-.38)/.52)
            lo, hi = (133, 180, 179), (25, 69, 89)
        else:
            t = min(1, max(0, (.38-c)/1.2))
            lo, hi = (174, 204, 206), (221, 228, 222)
        rgb = tuple(round(a+(b-a)*t) for a,b in zip(lo,hi))
        draw.line((0,y,767,y), fill=rgb)
    # Small staggered scales are engraved armor, strongest on the silver flanks.
    overlay = Image.new('RGBA', img.size)
    d = ImageDraw.Draw(overlay)
    for row, y in enumerate(range(76, 960, 24)):
        for x in range(172 + (row % 2)*18, 735, 36):
            d.arc((x-16,y-10,x+20,y+12), 270, 450, fill=(25,60,74,65), width=1)
            d.arc((x-15,y-9,x+19,y+11), 280, 435, fill=(244,255,250,75), width=1)
    # Broad hull divisions give the small scales readable structure at distance.
    for x in (181, 278, 391, 514, 620, 705):
        d.line((x,0,x,1023), fill=(14,41,54,100), width=2)
        d.line((x+3,0,x+3,1023), fill=(229,255,249,65), width=1)
    for y in (116, 908):
        d.line((175,y,704,y), fill=(12,41,56,180), width=6)
        d.line((180,y+2,702,y+2), fill=(122,204,205,210), width=2)
    # Sardine-specific spots, on both sides. No tiger stripes or shark gill slits.
    for y in (181, 843):
        for n, x in enumerate(range(215, 630, 52)):
            r = 6 if n < 5 else 4
            d.ellipse((x-r,y-r,x+r,y+r), fill=COLORS['spot']+(215,))
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    draw = ImageDraw.Draw(img)
    # Discrete swatches for geometry; generous padding makes linear filtering safe.
    for i, (name, rgb) in enumerate(COLORS.items()):
        x, y = 800+(i%4)*56, 24+(i//4)*56
        draw.rectangle((x,y,x+47,y+47), fill=rgb)
    # Small original hull identification, baked into both sides of the atlas.
    font = ImageFont.load_default(size=19)
    for y in (282, 710):
        draw.text((289,y), 'ACCORD / S-01', font=font, fill=(40,80,92))
    return img


class Mesh:
    def __init__(self):
        self.p, self.n, self.uv, self.idx = [], [], [], []
        self.parts = {}

    def swatch(self, color):
        i = list(COLORS).index(color)
        return ((824+(i%4)*56)/SIZE, (48+(i//4)*56)/SIZE)

    def vertex(self, p, n, uv):
        self.p.append(p); self.n.append(unit(n)); self.uv.append(uv)
        return len(self.p)-1

    def tri(self, a, b, c, outward):
        normal = cross(sub(self.p[b],self.p[a]), sub(self.p[c],self.p[a]))
        if dot(normal,normal) < 1e-16:
            raise ValueError('Degenerate triangle')
        self.idx.extend((a,c,b) if dot(normal,outward)<0 else (a,b,c))

    def face(self, points, color, outward):
        n = unit(outward)
        ids = [self.vertex(p,n,self.swatch(color)) for p in points]
        for i in range(1,len(ids)-1): self.tri(ids[0],ids[i],ids[i+1],n)

    def tube(self, points, radius, color, sides=8):
        rings=[]; previous_u=None
        for i,p in enumerate(points):
            axis=unit(sub(points[min(i+1,len(points)-1)],points[max(i-1,0)]))
            if previous_u is None:
                ref=(0,1,0) if abs(axis[1])<.9 else (1,0,0)
                u=unit(cross(axis,ref))
            else:
                # Transport the ring frame continuously around curves. Switching
                # reference axes halfway through a gill seam twists its faces.
                u=unit(sub(previous_u,mul(axis,dot(previous_u,axis))))
            v=cross(axis,u); previous_u=u
            ring=[]
            for j in range(sides):
                n=add(mul(u,math.cos(TAU*j/sides)),mul(v,math.sin(TAU*j/sides)))
                ring.append(self.vertex(add(p,mul(n,radius)),n,self.swatch(color)))
            rings.append(ring)
        for a,b in zip(rings,rings[1:]):
            for j in range(sides):
                k=(j+1)%sides
                n=add(self.n[a[j]],self.n[a[k]])
                self.tri(a[j],b[j],b[k],n); self.tri(a[j],b[k],a[k],n)
        for ring,p,axis in [(rings[0],points[0],sub(points[0],points[1])),(rings[-1],points[-1],sub(points[-1],points[-2]))]:
            self.face([self.p[k] for k in ring],color,axis)

    def lathe(self, center, axis, rings, colors, sides=40):
        """Closed rotational hardware, with separate ring vertices for crisp bevels."""
        axis=unit(axis); ref=(0,1,0) if abs(axis[1])<.9 else (1,0,0)
        u=unit(cross(axis,ref)); v=cross(axis,u)
        for seg,((d0,r0),(d1,r1)) in enumerate(zip(rings,rings[1:])):
            rows=[]
            for depth,r in ((d0,r0),(d1,r1)):
                row=[]
                for j in range(sides+1):
                    radial=add(mul(u,math.cos(TAU*j/sides)),mul(v,math.sin(TAU*j/sides)))
                    n=unit(add(mul(radial,d1-d0),mul(axis,r0-r1)))
                    row.append(self.vertex(add(add(center,mul(axis,depth)),mul(radial,r)),n,self.swatch(colors[seg%len(colors)])))
                rows.append(row)
            for j in range(sides):
                a,b=rows
                n=self.n[a[j]]
                self.tri(a[j],b[j],b[j+1],n); self.tri(a[j],b[j+1],a[j+1],n)
        for (depth,r),direction,color in ((rings[0],-1,colors[0]),(rings[-1],1,colors[-1])):
            pts=[add(add(center,mul(axis,depth)),mul(add(mul(u,math.cos(TAU*j/sides)),mul(v,math.sin(TAU*j/sides))),r)) for j in range(sides)]
            self.face(pts,color,mul(axis,direction))

    def fin(self, yz, thickness, color='fin', axis='x', sign=1):
        # Convex outlines: a center fan, beveled rim, and a proper solid edge.
        def coord(a,b,t): return (t,a*sign,b) if axis=='x' else (a*sign,t,b)
        center=(sum(p[0] for p in yz)/len(yz),sum(p[1] for p in yz)/len(yz))
        for side in (-1,1):
            outer=[coord(a,b,side*thickness*.28) for a,b in yz]
            inner=[coord(center[0]+(a-center[0])*.86,center[1]+(b-center[1])*.92,side*thickness*.5) for a,b in yz]
            direction=(side,0,0) if axis=='x' else (0,side,0)
            self.face(inner,color,direction)
            for j in range(len(yz)):
                k=(j+1)%len(yz)
                p=[outer[j],outer[k],inner[k],inner[j]]
                self.face(p,'edge',direction)
        for j in range(len(yz)):
            k=(j+1)%len(yz)
            a,b=yz[j]; c,d=yz[k]
            p=[coord(a,b,-thickness*.28),coord(c,d,-thickness*.28),coord(c,d,thickness*.28),coord(a,b,thickness*.28)]
            mid=coord((a+c)/2,(b+d)/2,0)
            self.face(p,'navy',sub(mid,coord(*center,0)))
        # Fin rays resemble sardine fins and provide engineered rib detail.
        root=yz[0]
        for target in yz[2:-1]:
            for side in (-1,1):
                a=coord(root[0]*.85+center[0]*.15,root[1]*.85+center[1]*.15,side*thickness*.56)
                b=coord(target[0]*.86+center[0]*.14,target[1]*.86+center[1]*.14,side*thickness*.56)
                self.tube([a,b],.018,'fin_light',6)


def build_mesh():
    m=Mesh()
    # 72 longitudinal intervals x 48 sides: smooth hull with a continuous UV seam.
    for i in range(73):
        z=7-13.45*i/72
        for j in range(49):
            a=TAU*j/48
            m.vertex(surface(z,a),surface_normal(z,a),(.004+.738*i/72,j/48))
    for i in range(72):
        for j in range(48):
            a=i*49+j; b=a+49
            n=add(m.n[a],m.n[a+1])
            m.tri(a,b,b+1,n); m.tri(a,b+1,a+1,n)
    for i,n in ((0,(0,0,1)),(72,(0,0,-1))):
        m.face([m.p[i*49+j] for j in range(48)],'silver',n)
    m.parts['hull_triangles']=len(m.idx)//3

    # One modest, rayed dorsal fin, with a rounded shoulder instead of a shark spike.
    m.fin([(1.03,1.7),(2.07,1.17),(2.22,.65),(2.02,.10),(1.34,-1.35),(.95,-1.6)],.18)
    # Real fish caudal plane is vertical. Equal upper/lower lobes, clear V fork.
    for sign in (-1,1):
        m.fin([(.06,-5.9),(.60,-6.60),(2.03,-8.65),(1.95,-9.2),(1.32,-8.65),(.06,-7.20)],.17,sign=sign)
    # Pectoral fins tuck alongside the hull rather than forming broad fighter wings.
    for sign in (-1,1):
        m.fin([(1.14,3.25),(1.78,2.7),(2.4,.85),(2.17,.63),(1.07,1.80)],.13,axis='y',sign=sign)
        m.fin([(.60,-2.1),(1.05,-2.65),(1.22,-3.65),(.43,-3.16)],.10,axis='y',sign=sign)

    for sign in (-1,1):
        # Large, round optical ports read as sardine eyes; no aggressive brow.
        a=sign*1.39; z=5.35
        normal=surface_normal(z,a); center=surface(z,a,.008)
        m.lathe(center,normal,[(0,.39),(.045,.43),(.11,.40),(.12,.32),(.15,.285)],['edge','silver','brass','dark'],48)
        m.lathe(add(center,mul(normal,.15)),normal,[(0,.276),(.035,.25),(.06,.12)],['glass','glass'],48)
        m.lathe(add(add(center,mul(normal,.215)),(0,.075,.055)),normal,[(0,.060),(.012,.048)],['cyan'],20)
        # A single curved gill-cover seam, not a row of shark gill cuts.
        points=[]
        for j in range(25):
            angle=sign*(.52+2.1*j/24)
            z=3.55-.5*math.sin(math.pi*j/24)
            points.append(surface(z,angle,.025))
        m.tube(points,.042,'navy')
        m.tube([surface(3.68-.5*math.sin(math.pi*j/24),sign*(.55+2.04*j/24),.034) for j in range(25)],.022,'pearl')
        # Lateral sensor rail integrates machinery into the fish's side stripe.
        m.tube([surface(z,sign*1.22,.028) for z in (2.8,2,1,0,-1,-2,-3,-4,-5)],.034,'edge')
        m.tube([surface(z,sign*1.22,.062) for z in (2.65,2,1,0,-1,-2,-3,-4,-4.8)],.013,'cyan',6)
        # Compact paired thrusters flank the narrow tail stock.
        center=(sign*.40,0,-5.58)
        m.lathe(center,(0,0,-1),[(0,.21),(.30,.31),(.83,.32),(1.02,.28),(1.04,.205)],['navy','silver','edge','nozzle'],32)
        m.lathe((sign*.40,0,-6.635),(0,0,-1),[(0,.19),(.018,.155)],['cyan'],32)
        # Small amber positioning lights at the pectoral-fin roots.
        p=surface(2.8,sign*1.72,.032)
        m.lathe(p,surface_normal(2.8,sign*1.72),[(0,.075),(.04,.064)],['brass'],16)

    # Low conformal cockpit on the dorsal head. Geometry follows the hull.
    rows=[]; rim_left=[]; rim_right=[]
    for i in range(25):
        z=4.05+i*1.56/24
        width=.025+.32*math.sin(math.pi*i/24)**.65
        row=[]
        for j in range(9):
            a=-width+2*width*j/8
            row.append(m.vertex(surface(z,a,.052),surface_normal(z,a),m.swatch('glass')))
        rows.append(row)
        rim_left.append(surface(z,-width,.055)); rim_right.append(surface(z,width,.055))
    for a,b in zip(rows,rows[1:]):
        for j in range(8):
            m.tri(a[j],b[j],b[j+1],m.n[a[j]])
            m.tri(a[j],b[j+1],a[j+1],m.n[a[j]])
    m.tube(rim_left+list(reversed(rim_right))+[rim_left[0]],.027,'edge',8)
    m.tube([surface(4.12+i*.12,0,.070) for i in range(13)],.016,'silver',6)
    # Small rounded terminal mouth seam, mostly visible in the side silhouette.
    m.tube([surface(6.83,1.22+3.84*j/24,.018) for j in range(25)],.019,'dark',6)
    return m


def write_glb(mesh, texture, path):
    binary=bytearray(); views=[]; accessors=[]
    def view(data,target=None):
        start=len(binary); binary.extend(data); binary.extend(b'\0'*((-len(binary))%4))
        obj={'buffer':0,'byteOffset':start,'byteLength':len(data)}
        if target: obj['target']=target
        views.append(obj); return len(views)-1
    def accessor(values,width,ctype,kind,target):
        fmt='f' if ctype==5126 else 'H'
        flat=[x for row in values for x in row] if width>1 else values
        v=view(struct.pack('<'+fmt*len(flat),*flat),target)
        a={'bufferView':v,'componentType':ctype,'count':len(values),'type':kind}
        if kind=='VEC3':
            a['min']=[min(p[i] for p in values) for i in range(3)]
            a['max']=[max(p[i] for p in values) for i in range(3)]
        accessors.append(a); return len(accessors)-1
    if len(mesh.p)>65535: raise ValueError('16-bit vertex budget exceeded')
    p=accessor(mesh.p,3,5126,'VEC3',34962)
    n=accessor(mesh.n,3,5126,'VEC3',34962)
    uv=accessor(mesh.uv,2,5126,'VEC2',34962)
    idx=accessor(mesh.idx,1,5123,'SCALAR',34963)
    buf=io.BytesIO(); texture.save(buf,format='PNG',optimize=True)
    im=view(buf.getvalue())
    gltf={
        'asset':{'version':'2.0','generator':'Galaxy original Sardine detailed hull / build_sardine_model.py'},
        'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'name':'sardine_hull','mesh':0}],
        'meshes':[{'name':'sardine_hull','primitives':[{'attributes':{'POSITION':p,'NORMAL':n,'TEXCOORD_0':uv},'indices':idx,'material':0,'mode':4}]}],
        'materials':[{'name':'sardine_atlas','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':.6}}],
        'images':[{'bufferView':im,'mimeType':'image/png'}],
        'textures':[{'source':0,'sampler':0}],
        'samplers':[{'magFilter':9729,'minFilter':9729,'wrapS':33071,'wrapT':33071}],
        'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}],
    }
    raw=json.dumps(gltf,separators=(',',':')).encode(); raw+=b' '*((-len(raw))%4)
    data=struct.pack('<4sII',b'glTF',2,28+len(raw)+len(binary))+struct.pack('<II',len(raw),0x4E4F534A)+raw+struct.pack('<II',len(binary),0x004E4942)+binary
    path.write_bytes(data)
    return gltf


def topdown(mesh,texture,path):
    """Rasterize the actual textured mesh with a depth buffer (no approximate icon)."""
    import numpy as np
    w,h=520,1280
    rgba=np.zeros((h,w,4),dtype=np.uint8); depth=np.full((h,w),-np.inf)
    tex=np.asarray(texture); scale=69
    p=np.asarray(mesh.p); n=np.asarray(mesh.n); uv=np.asarray(mesh.uv)
    light=np.array([-.35,.88,.3]); light/=np.linalg.norm(light)
    for k in range(0,len(mesh.idx),3):
        ids=mesh.idx[k:k+3]; pts=p[ids]
        normal=np.cross(pts[1]-pts[0],pts[2]-pts[0])
        if normal[1]<=1e-10: continue
        xx=w/2+pts[:,0]*scale; yy=100+(7-pts[:,2])*scale
        xmin=max(0,int(np.floor(xx.min()))); xmax=min(w-1,int(np.ceil(xx.max())))
        ymin=max(0,int(np.floor(yy.min()))); ymax=min(h-1,int(np.ceil(yy.max())))
        if xmin>xmax or ymin>ymax: continue
        X,Y=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
        den=(yy[1]-yy[2])*(xx[0]-xx[2])+(xx[2]-xx[1])*(yy[0]-yy[2])
        if abs(den)<1e-9: continue
        a=((yy[1]-yy[2])*(X-xx[2])+(xx[2]-xx[1])*(Y-yy[2]))/den
        b=((yy[2]-yy[0])*(X-xx[2])+(xx[0]-xx[2])*(Y-yy[2]))/den
        c=1-a-b; weights=np.stack([a,b,c],axis=-1)
        z=weights@pts[:,1]
        patch=depth[ymin:ymax+1,xmin:xmax+1]
        mask=(a>=-1e-6)&(b>=-1e-6)&(c>=-1e-6)&(z>patch)
        if not mask.any(): continue
        coord=np.clip(weights@uv[ids],0,1)
        color=tex[np.minimum(1023,(coord[...,1]*1024).astype(int)),np.minimum(1023,(coord[...,0]*1024).astype(int))]
        norm=weights@n[ids]; norm/=np.maximum(np.linalg.norm(norm,axis=-1,keepdims=True),1e-9)
        shade=.48+.52*np.maximum(0,norm@light)
        result=np.concatenate([np.clip(color*shade[...,None],0,255).astype(np.uint8),np.full((*mask.shape,1),255,dtype=np.uint8)],axis=-1)
        rgba[ymin:ymax+1,xmin:xmax+1][mask]=result[mask]; patch[mask]=z[mask]
    Image.fromarray(rgba).save(path)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-root',type=Path,default=ROOT)
    args=parser.parse_args()
    modeldir=args.output_root/'assets/models/patrol_interceptor'; modeldir.mkdir(parents=True,exist_ok=True)
    imagedir=args.output_root/'main/images'; imagedir.mkdir(parents=True,exist_ok=True)
    tex=make_atlas(); mesh=build_mesh()
    doc=write_glb(mesh,tex,modeldir/'sardine.glb')
    tex.save(modeldir/'sardine_palette.png',optimize=True)
    topdown(mesh,tex,imagedir/'patrol_interceptor_sardine_topdown.png')
    bounds=doc['accessors'][0]
    center=tuple((a+b)/2 for a,b in zip(bounds['min'],bounds['max']))
    radius=max(math.sqrt(dot(sub(p,center),sub(p,center))) for p in mesh.p)
    origin_radius=max(math.sqrt(dot(p,p)) for p in mesh.p)
    print(json.dumps({'vertices':len(mesh.p),'triangles':len(mesh.idx)//3,'bounds_m':[bounds['min'],bounds['max']],'bounding_radius_m':round(radius,3),'origin_radius_m':round(origin_radius,3),'texture':[SIZE,SIZE],'parts':mesh.parts},indent=2))


if __name__=='__main__': main()
