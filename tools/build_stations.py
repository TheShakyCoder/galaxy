#!/usr/bin/env python3
"""Deterministic station geometry, original artwork and Defold resources.

Run from any directory. Requires Pillow. Geometry is meters, Y up, Z axial.
Only generated station resources are replaced. No game/session code is edited.
"""
import argparse, hashlib, json, math, random, struct
from pathlib import Path
from types import SimpleNamespace
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/stations'
TAU=math.tau
TILES=['armor','navy','metal','brass','dark','windows','cyan','red','green','vent','roof','glass','hazard','white','machine','registry']
ADS=[('verge','VERGE TRANSIT','TAKE THE LONG WAY HOME.',(18,35,54),(237,215,160)),('tope','TOPE EXCHANGE','SMALL CHANGE. BIG ORBITS.',(17,37,42),(160,232,219)),('molt','MOLT SYSTEMS','SHED YOUR LIMITS.',(31,21,58),(196,163,245)),('hydrogen','HYDROGEN WORKS','PURE FUEL. IMPURE THOUGHTS.',(10,37,54),(141,231,249)),('mutual','DOCKSIDE MUTUAL','YOUR OTHER SHIP IS INSURED.',(42,32,22),(244,202,124)),('current','CURRENT & CO.','FRESH WATER. OLD MONEY.',(19,46,51),(219,239,215)),('civic','ACCORD PORT AUTHORITY','LEAVE ROOM FOR SMALL FRY.',(218,221,209),(22,51,69)),('logistics','SWARM LOGISTICS','WE REMEMBER YOUR BAGGAGE.',(30,24,41),(206,183,229))]

def font(size):
    # Repository-owned font, no dependency on installed OS typefaces.
    return ImageFont.truetype(str(ROOT/'main/ui/flight/Barlow-Medium.ttf'),size)

def atlas(faction):
    img=Image.new('RGBA',(2048,2048)); rng=random.Random(871)
    colors=[(207,210,199),(22,40,58),(78,89,97),(169,142,87),(10,16,22),(21,33,40),(98,215,237),(238,58,39),(52,222,126),(34,44,53),(177,187,184),(18,39,52),(202,169,71),(226,232,227),(36,42,50),(202,213,212)]
    if faction=='swarm':
        colors[0]=(59,65,77);colors[1]=(27,25,39);colors[3]=(99,89,122);colors[10]=(73,81,91)
    for k,name in enumerate(TILES):
        col=colors[k];tile=Image.new('RGBA',(512,512),col+(0,));d=ImageDraw.Draw(tile)
        if name in ('cyan','red','green','white'):
            d.rectangle((0,0,511,511),fill=col+(255,))
        elif name=='windows':
            for y in range(16,500,48):
                for x in range(10,500,28):
                    c=(237,184,100) if rng.random()>.22 else (42,53,60)
                    d.rectangle((x,y,x+17,y+30),fill=c+((225 if c[0]>100 else 0),))
                    d.line((x+2,y+2,x+15,y+2),fill=(255,225,164,230))
            for y in range(0,512,96):d.rectangle((0,y,511,y+5),fill=(17,29,37,0))
        elif name=='vent':
            for y in range(8,508,15):
                d.rectangle((6,y,505,y+7),fill=(12,18,25,0));d.line((6,y,505,y),fill=(115,132,141,0),width=2)
        elif name=='hazard':
            for x in range(-512,1024,72):d.polygon([(x,0),(x+34,0),(x-478,512),(x-512,512)],fill=(22,27,30,0))
        else:
            for row,y in enumerate(range(8,504,126)):
                for x in range(8-(row%2)*62,512,126):
                    tint=tuple(max(0,min(255,c+rng.randrange(-5,6))) for c in col)
                    d.rectangle((x+2,y+2,x+122,y+122),fill=tint+(0,))
                    d.line((x,y+123,x+123,y+123,x+123,y),fill=tuple(int(c*.53) for c in col)+(0,),width=3)
                    d.line((x+2,y+2,x+121,y+2),fill=tuple(min(255,int(c*1.16)+8) for c in col)+(0,),width=2)
                    for xx in (x+10,x+115):
                        for yy in (y+10,y+115):d.ellipse((xx-2,yy-2,xx+2,yy+2),fill=(29,37,43,0))
                    if (row+x//126)%3==0:d.rectangle((x+16,y+70,x+63,y+86),outline=tuple(int(c*.6) for c in col)+(0,),width=2)
            if name in ('machine','registry'):
                for y in (28,282):
                    d.text((24,y),f'{faction.upper()} / 07',font=font(24),fill=(172,193,201,0))
                    d.text((24,y+36),'SERVICE ACCESS',font=font(13),fill=(125,151,167,0))
        img.paste(tile,((k%4)*512,(k//4)*512))
    return img.convert('RGB')

def advertisements():
    dest=OUT/'ads';dest.mkdir(parents=True,exist_ok=True)
    for i,(slug,title,copy,bg,fg) in enumerate(ADS):
        im=Image.new('RGB',(1024,512),bg);d=ImageDraw.Draw(im)
        d.rectangle((24,24,999,487),outline=fg,width=2)
        # Original simple geometric brand marks, authored rather than raster AI art.
        if i%3==0:
            d.arc((90,100,355,365),200,515,fill=fg,width=10)
            d.ellipse((234,100,280,146),fill=fg)
            d.line([(91,290),(226,218),(349,254)],fill=fg,width=12)
        elif i%3==1:
            for r in (102,82):d.ellipse((225-r,237-r,225+r,237+r),outline=fg,width=6)
            d.line((109,329,338,144),fill=fg,width=15)
        else:
            for j in range(4):d.polygon([(115+j*36,340-j*20),(254+j*20,133+j*10),(205+j*27,315-j*14)],fill=fg)
        words=title.split();line1=' '.join(words[:-1]);line2=words[-1]
        d.text((398,134),line1,font=font(45),fill=fg);d.text((398,190),line2,font=font(55),fill=fg)
        d.text((64,399),copy,font=font(29),fill=fg)
        d.text((401,291),'GALAXY  /  PORT NETWORK',font=font(18),fill=fg)
        im.save(dest/(slug+'.png'),optimize=True)
    im=Image.new('RGB',(1024,512),(24,31,45));d=ImageDraw.Draw(im)
    d.rectangle((64,32,959,479),outline=(74,230,185),width=3)
    d.text((88,75),'1024 x 512  /  2:1',font=font(42),fill='white')
    d.text((88,164),'KEEP LOGOS AND COPY INSIDE THIS BOX',font=font(28),fill='white')
    d.text((88,215),'64 px horizontal / 32 px vertical safe margins',font=font(24),fill='white')
    d.text((88,351),'GUIDES ONLY - REMOVE BEFORE SUBMITTING',font=font(24),fill=(250,196,95))
    (ROOT/'docs').mkdir(exist_ok=True);im.save(ROOT/'docs/station-ad-template.png')

def add(a,b):return tuple(x+y for x,y in zip(a,b))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def mul(a,s):return tuple(x*s for x in a)
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a):return mul(a,1/math.sqrt(sum(x*x for x in a)))

class Mesh:
    def __init__(self):self.p=[];self.n=[];self.uv=[];self.idx=[]
    def face(self,pts,tile='armor',normal=None,full=False,uv_fn=None):
        n=unit(cross(sub(pts[1],pts[0]),sub(pts[2],pts[0])))
        if normal and sum(a*b for a,b in zip(n,normal))<0:pts=list(reversed(pts));n=mul(n,-1)
        k=TILES.index(tile);x=(k%4)*512;y=(k//4)*512
        coords=[(0,1),(1,1),(1,0),(0,0)] if len(pts)==4 else [(0.5+.48*math.cos(TAU*i/len(pts)),.5+.48*math.sin(TAU*i/len(pts))) for i in range(len(pts))]
        if uv_fn:coords=[uv_fn(p) for p in pts]
        base=len(self.p)
        for p,(u,v) in zip(pts,coords):
            self.p.append(p);self.n.append(n);self.uv.append((u,v) if full else ((x+8+u*496)/2048,(y+8+v*496)/2048))
        for i in range(1,len(pts)-1):self.idx.extend((base,base+i,base+i+1))
    def box(self,c,size,tile='armor',basis=((1,0,0),(0,1,0),(0,0,1))):
        pts=[add(c,tuple(sum(basis[j][k]*size[j]*s[j]/2 for j in range(3)) for k in range(3))) for s in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        for idx,face in enumerate(((0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5))):
            q=[pts[i] for i in face];centre=tuple(sum(p[k] for p in q)/4 for k in range(3))
            axes=(0,1) if idx<2 else (0,2) if idx<4 else (1,2)
            def uv(p):
                d=sub(p,c);u=.5+sum(d[k]*basis[axes[0]][k] for k in range(3))/size[axes[0]]
                v=.5-sum(d[k]*basis[axes[1]][k] for k in range(3))/size[axes[1]]
                return u,v
            self.face(q,tile,sub(centre,c),uv_fn=uv)
    def lathe(self,profile,tile='armor',sides=64,phase=0,c=(0,0,0)):
        for (z0,r0),(z1,r1) in zip(profile,profile[1:]):
            for i in range(sides):
                a=phase+TAU*i/sides;b=phase+TAU*(i+1)/sides
                self.face([add(c,(r0*math.cos(a),r0*math.sin(a),z0)),add(c,(r0*math.cos(b),r0*math.sin(b),z0)),add(c,(r1*math.cos(b),r1*math.sin(b),z1)),add(c,(r1*math.cos(a),r1*math.sin(a),z1))],tile)
    def radial_box(self,a,r,z,size,tile):
        u=(-math.sin(a),math.cos(a),0);n=(math.cos(a),math.sin(a),0)
        self.box((r*n[0],r*n[1],z),size,tile,(u,n,(0,0,1)))
    def beam(self,a,b,width,height,tile='metal',side=(0,0,1)):
        direction=unit(sub(b,a));u=unit(side);v=unit(cross(u,direction))
        self.box(mul(add(a,b),.5),(width,math.sqrt(sum(x*x for x in sub(b,a))),height),tile,(u,direction,v))
    def shift(self,offset):self.p=[add(p,offset) for p in self.p]
    def save(self,path):
        assert len(self.p)<65536
        data=bytearray();views=[];acc=[]
        for values,width,kind,ctype in ((self.p,3,'VEC3',5126),(self.n,3,'VEC3',5126),(self.uv,2,'VEC2',5126),(self.idx,1,'SCALAR',5123)):
            flat=[v for row in values for v in row] if width>1 else values
            raw=struct.pack('<'+('f' if ctype==5126 else 'H')*len(flat),*flat)
            views.append(dict(buffer=0,byteOffset=len(data),byteLength=len(raw),target=34962 if width>1 else 34963));data.extend(raw);data.extend(b'\0'*(-len(data)%4))
            a=dict(bufferView=len(views)-1,componentType=ctype,count=len(values),type=kind)
            if not acc:a.update(min=[min(p[k] for p in values) for k in range(3)],max=[max(p[k] for p in values) for k in range(3)])
            acc.append(a)
        doc=dict(asset={'version':'2.0','generator':'Galaxy / tools/build_stations.py'},scene=0,scenes=[{'nodes':[0]}],nodes=[{'mesh':0}],meshes=[{'primitives':[{'attributes':{'POSITION':0,'NORMAL':1,'TEXCOORD_0':2},'indices':3,'material':0}]}],materials=[{'name':'station','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1]}}],accessors=acc,bufferViews=views,buffers=[{'byteLength':len(data)}])
        raw=json.dumps(doc,separators=(',',':')).encode();raw+=b' '*(-len(raw)%4)
        path.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(raw)+len(data))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(data),0x004e4942)+data)

def ring(m,z,r,width,tile='metal',sides=64):
    bevel=min(width*.24,2)
    m.lathe([(z-width/2,r-3),(z-width/2+bevel,r),(z+width/2-bevel,r),(z+width/2,r-3)],tile,sides)

def dock(m,z,sign,r=72):
    # Open black throat is recessed behind modeled annular armor and lit collars.
    profile=[(z-sign*32,r*.68),(z-sign*25,r),(z-sign*6,r),(z,r*.86),(z,r*.64),(z-sign*25,r*.64)]
    m.lathe(profile if sign>0 else list(reversed(profile)),'armor',64)
    ring(m,z-sign*2,r*.68,3,'brass')
    profile=[(z-sign*26,r*.63),(z-sign*27,1)]
    m.lathe(profile if sign>0 else list(reversed(profile)),'dark',64)
    for i in range(12):
        a=TAU*i/12;m.radial_box(a,r*.6,z-sign*13,(3,3,18),'cyan' if i%3==0 else 'white')
        m.radial_box(a,r+2,z-sign*18,(4,5,18),'metal')

def frame(m,a,r,z,w=200,h=100):
    m.radial_box(a,r-2,z,(w+14,8,h+14),'navy')
    for x in (-1,1):
        # Four sides, deliberately separate from the logo sampler.
        u=(-math.sin(a),math.cos(a),0);n=(math.cos(a),math.sin(a),0)
        c=add(mul(n,r+3),add(mul(u,x*(w/2+4)),(0,0,z)))
        m.box(c,(5,5,h+10),'metal',(u,n,(0,0,1)))
        m.radial_box(a,r+2,z+x*(h/2+4),(w,5,4),'brass')

def station(faction):
    fixed=Mesh();rotor=Mesh();slots=[]
    if faction=='accord':
        pivot=(0,135,0);phase=math.pi/8
        fixed.lathe([(-350,56),(350,56)],'navy')
        for sign in (-1,1):
            profile=[(sign*175,75),(sign*210,66),(sign*315,66),(sign*334,78)]
            fixed.lathe(profile if sign>0 else list(reversed(profile)),'armor')
            for z in range(215,320,16):ring(fixed,sign*z,69,5,'brass' if z%3==0 else 'metal')
            for i in range(8):
                a=TAU*i/8;fixed.radial_box(a,68,sign*262,(16,7,86),'vent')
                fixed.radial_box(a,86,sign*205,(12,35,35),'metal')
            dock(fixed,sign*378,sign,78)
            for a in (0,math.pi):
                fixed.radial_box(a,109,sign*338,(5,64,5),'metal')
                fixed.radial_box(a,142,sign*338,(6,5,6),'red' if a==0 else 'green')
        # Closed faceted drum, stepped/sloping shoulders, through-spindle aperture.
        rotor.lathe([(-176,83),(-174,186),(-148,258),(-112,306),(112,306),(148,258),(174,186),(176,83)],'armor',8,phase)
        for z,r in ((-169,198),(-146,263),(-112,311),(112,311),(146,263),(169,198)):ring(rotor,z,r,8,'metal',8)
        for i in range(8):
            a=phase+(i+.5)*TAU/8;apothem=306*math.cos(math.pi/8)
            frame(rotor,a,apothem+6,0)
            slots.append((a,apothem+10,0))
            for z in (-84,84):
                rotor.radial_box(a,apothem+2,z,(207,3,32),'windows')
                for x in range(-90,100,30):
                    u=(-math.sin(a),math.cos(a),0);n=(math.cos(a),math.sin(a),0)
                    rotor.box(add(mul(n,apothem+5),add(mul(u,x),(0,0,z))),(2,6,35),'metal',(u,n,(0,0,1)))
            for z in (-137,137):rotor.radial_box(a,253,z,(125,9,14),'vent')
        # Eight slim axial seam ribs, inside the 320m rotor radius.
        for i in range(8):rotor.radial_box(phase+TAU*i/8,310,0,(7,8,227),'brass')
    else:
        pivot=(0,142.5,0);phase=math.pi/8
        fixed.lathe([(30,43),(84,66),(135,57),(185,39),(447,39),(498,60),(518,60)],'machine',32)
        for z in range(170,481,24):ring(fixed,z,44,7,'metal',32)
        for i in range(8):
            a=TAU*i/8;fixed.radial_box(a,47,315,(12,12,245),'navy')
            fixed.radial_box(a,55,315,(2,2,190),'cyan')
            fixed.radial_box(a,86,100,(25,93,42),'metal')
            fixed.radial_box(a,133,100,(47,18,59),'armor')
            fixed.radial_box(a,144,100,(30,5,35),'vent')
            fixed.radial_box(a,182,100,(3,81,4),'metal')
            fixed.radial_box(a,225,100,(5,6,5),'red' if i%2 else 'green')
        dock(fixed,8,-1,48)
        rotor.lathe([(506,62),(531,150),(548,275),(558,362),(678,362),(690,315),(706,76),(708,62)],'armor',8,phase)
        ring(rotor,559,366,9,'metal',8);ring(rotor,677,366,9,'metal',8)
        ring(rotor,512,74,9,'brass',64)
        for i in range(8):
            a=phase+(i+.5)*TAU/8;r=362*math.cos(math.pi/8)
            frame(rotor,a,r+5,618);slots.append((a,r+9,618))
            for offset in (-65,0,65):
                u=(-math.sin(a),math.cos(a),0);n=(math.cos(a),math.sin(a),0)
                rotor.box(add(mul(n,r+2),add(mul(u,offset),(0,0,552))),(14,4,2),'cyan',(u,n,(0,0,1)))
        # Radial under-cap gills are genuinely modeled thin vanes, not a noisy texture.
        for i in range(112):
            a=TAU*i/112
            # Cut each rib into gently rising segments; no geometry escapes cap radius.
            pts=[]
            for j in range(9):
                r=82+j*34;z=484+67*(j/8)**.48
                pts.append((r*math.cos(a),r*math.sin(a),z))
            for p,q in zip(pts,pts[1:]):rotor.beam(p,q,2.2,12,'metal',(-math.sin(a),math.cos(a),0))
        for i in range(8):
            a=phase+TAU*i/8
            rotor.radial_box(a,352,618,(7,12,116),'metal')
            rotor.radial_box(a,210,698,(15,88,5),'vent')
        ring(rotor,712,50,8,'metal',32)
        for i in range(4):
            a=TAU*i/4;rotor.radial_box(a,36,709,(2,2,18),'metal');rotor.radial_box(a,36,719,(3,3,2),'red' if i%2 else 'green')
    fixed.shift(pivot)
    return fixed,rotor,pivot,slots

def write(path,text):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf8')
def model(mesh,texture,material='hull'):
    return f'mesh: "{mesh}"\nmaterial: "/assets/materials/stations/{material}.material"\ntextures: "{texture}"\nname: "station"\n'

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--faction',choices=['accord','swarm']);args=ap.parse_args()
    OUT.mkdir(parents=True,exist_ok=True);advertisements();rows=[]
    for faction in ([args.faction] if args.faction else ['accord','swarm']):
        folder=OUT/faction;folder.mkdir(exist_ok=True);im=atlas(faction);im.save(folder/'hull.png',optimize=True)
        fixed,rotor,pivot,slots=station(faction)
        for name,m in [('fixed',fixed),('rotor',rotor)]:
            m.save(folder/(name+'.glb'));write(folder/(name+'.model'),model(f'/assets/models/stations/{faction}/{name}.glb',f'/assets/models/stations/{faction}/hull.png'))
        ad=Mesh();ad.face([(-100,0,-50),(100,0,-50),(100,0,50),(-100,0,50)],normal=(0,-1,0),full=True);ad.save(OUT/'ad.glb')
        for slug,*_ in ADS:write(OUT/'ads'/(slug+'.model'),model('/assets/models/stations/ad.glb',f'/assets/models/stations/ads/{slug}.png','ad'))
        rows.append(dict(faction=faction,pivot=pivot,slots=slots,period=110 if faction=='accord' else 120,triangles=(len(fixed.idx)+len(rotor.idx))//3+16,vertices=len(fixed.p)+len(rotor.p)+32))
        print(faction,rows[-1]['triangles'],'triangles')
    if args.faction and (OUT/'manifest.json').exists():
        rows+= [r for r in json.loads((OUT/'manifest.json').read_text())['stations'] if r['faction']!=args.faction]
    rows.sort(key=lambda r:r['faction'])
    write(OUT/'manifest.json',json.dumps({'stations':rows,'builder':'tools/build_stations.py'},indent=2)+'\n')

if __name__=='__main__':main()
