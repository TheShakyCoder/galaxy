"""Shared geometry and texture finish derived from the approved Sardine.

Models use one mesh/material and base-color textures for Defold's existing shader.
"""
import io
import json
import math
import struct
from PIL import Image, ImageDraw, ImageFont
from build_sardine_model import Mesh as SardineMesh, COLORS, add, sub, mul, dot, cross, unit

TAU=math.tau


class Mesh(SardineMesh):
    def __init__(self, ship):
        super().__init__(); self.ship=ship; self.features=[]

    def plate(self, outline, thickness=.12, color='fin', axis='y', ribs=False):
        """Beveled convex plate. Outlines use (span, fore/aft) in the given plane."""
        before=len(self.p)
        self.fin(outline,thickness,color,axis=axis)
        # The inherited implementation also supplies restrained structural ribs.
        return before

    def ellipsoid(self, center, radii, color, rings=12, sides=24):
        start=len(self.p)
        # Avoid zero-area pole triangles by using small closed end rings.
        for i in range(rings+1):
            a=.025+(math.pi-.05)*i/rings
            for j in range(sides+1):
                b=TAU*j/sides
                q=(math.sin(a)*math.cos(b),math.cos(a),math.sin(a)*math.sin(b))
                p=add(center,tuple(q[k]*radii[k] for k in range(3)))
                self.vertex(p,unit(tuple(q[k]/radii[k] for k in range(3))),self.swatch(color))
        for i in range(rings):
            for j in range(sides):
                a=start+i*(sides+1)+j; b=a+sides+1
                self.tri(a,b,b+1,self.n[a]); self.tri(a,b+1,a+1,self.n[a])
        for i,n in ((0,(0,1,0)),(rings,(0,-1,0))):
            self.face([self.p[start+i*(sides+1)+j] for j in range(sides)],color,n)

    def transform_part(self,start,fn):
        """Rigid positional translation only. Non-rigid body lofts supply normals."""
        for i in range(start,len(self.p)): self.p[i]=fn(self.p[i])


class Hull:
    def __init__(self, stations):
        # Ascending Z; each row is z, half-width, half-height, center-y, center-x.
        self.stations=[tuple(p)+(0,)*(5-len(p)) for p in stations]
        self.z0=self.stations[0][0]; self.z1=self.stations[-1][0]

    def section(self,z):
        s=self.stations; z=max(self.z0,min(self.z1,z))
        i=next((k for k in range(len(s)-1) if z<=s[k+1][0]),len(s)-2)
        out=[]
        for c in range(1,5):
            def slope(k):
                if k==0: return (s[1][c]-s[0][c])/(s[1][0]-s[0][0])
                if k==len(s)-1: return (s[-1][c]-s[-2][c])/(s[-1][0]-s[-2][0])
                a=(s[k][c]-s[k-1][c])/(s[k][0]-s[k-1][0]); b=(s[k+1][c]-s[k][c])/(s[k+1][0]-s[k][0])
                return 0 if a*b<=0 else 2*a*b/(a+b)
            h=s[i+1][0]-s[i][0]; t=(z-s[i][0])/h
            out.append((2*t**3-3*t*t+1)*s[i][c]+(t**3-2*t*t+t)*h*slope(i)+(-2*t**3+3*t*t)*s[i+1][c]+(t**3-t*t)*h*slope(i+1))
        return out

    def point(self,z,a,offset=0):
        w,h,y,x=self.section(z)
        return (x+(w+offset)*math.sin(a),y+(h+offset)*math.cos(a),z)

    def normal(self,z,a):
        dz=sub(self.point(min(self.z1,z+.001),a),self.point(max(self.z0,z-.001),a))
        da=sub(self.point(z,a+.001),self.point(z,a-.001))
        return unit(cross(dz,da))

    def build(self,m,steps=56,sides=40,color=None):
        start=len(m.p)
        for i in range(steps+1):
            z=self.z1-(self.z1-self.z0)*i/steps
            for j in range(sides+1):
                a=TAU*j/sides
                uv=m.swatch(color) if color else (.004+.738*i/steps,j/sides)
                m.vertex(self.point(z,a),self.normal(z,a),uv)
        for i in range(steps):
            for j in range(sides):
                a=start+i*(sides+1)+j; b=a+sides+1
                n=add(m.n[a],m.n[a+1])
                m.tri(a,b,b+1,n); m.tri(a,b+1,a+1,n)
        for i,n in ((0,(0,0,1)),(steps,(0,0,-1))):
            m.face([m.p[start+i*(sides+1)+j] for j in range(sides)],color or 'silver',n)


def eye(m,h,z,size=.32,angle=1.35):
    for sign in (-1,1):
        a=sign*angle; p=h.point(z,a,.018); normal=h.normal(z,a)
        m.lathe(p,normal,[(0,size),(.05,size*1.12),(.10,size),(.12,size*.76)],['edge','brass','dark'],32)
        m.lathe(add(p,mul(normal,.12)),normal,[(0,size*.74),(.055,size*.63)],['glass'],32)
        m.ellipsoid(add(add(p,mul(normal,.19)),(0,size*.18,size*.12)),(size*.15,)*3,'cyan',6,12)


def gill(m,h,z,shark=False):
    for sign in (-1,1):
        for row in range(4 if shark else 1):
            points=[]
            for j in range(19):
                t=j/18; a=sign*(.6+1.9*t)
                points.append(h.point(z-row*.25-.35*math.sin(math.pi*t),a,.035))
            m.tube(points,.035,'navy',6)


def cockpit(m,h,z0,z1,width=.4):
    rows=[]; rails=[[],[]]
    for i in range(17):
        z=z0+(z1-z0)*i/16; spread=.025+width*math.sin(math.pi*i/16)**.65
        row=[]
        for j in range(9):
            a=-spread+2*spread*j/8
            row.append(m.vertex(h.point(z,a,.06),h.normal(z,a),m.swatch('glass')))
        rows.append(row)
        for k,sign in enumerate((-1,1)): rails[k].append(h.point(z,sign*spread,.065))
    for a,b in zip(rows,rows[1:]):
        for j in range(8):
            m.tri(a[j],b[j],b[j+1],m.n[a[j]]); m.tri(a[j],b[j+1],a[j+1],m.n[a[j]])
    for rail in rails: m.tube(rail,.025,'edge',6)


def engine(m,p,r=.3,length=.9):
    m.lathe(p,(0,0,-1),[(0,r*.72),(.18*length,r),(length*.78,r),(length,r*.8),(length+.02,r*.59)],['navy','silver','edge','nozzle'],24)
    m.lathe(add(p,(0,0,-length-.025)),(0,0,-1),[(0,r*.55),(.02,r*.47)],['cyan'],24)


def role_details(m,h,role):
    """Visual machinery only; does not claim to model gameplay module-slot counts."""
    if role=='interceptor':
        for x in (-1.05,-.42,.42,1.05): engine(m,(x,-.2,-3.6),.24,.95)
        m.features.append('Four compact engine nacelles: interceptor role cue')
    else:
        for x in (-.7,.7): engine(m,(x,-.22,-3.5),.28,.95)
    if role=='assault':
        for sign in (-1,1):
            z=1.5; p=h.point(z,sign*1.8,.08)
            m.lathe(p,(0,0,1),[(0,.26),(.35,.26),(1.3,.11),(1.36,.085)],['navy','edge','dark'],20)
            m.lathe(add(p,(0,0,1.365)),(0,0,1),[(0,.06),(.02,.05)],['dark'],16)
        m.features.append('Armored shoulders and paired forward gun housings')
    if role=='support':
        for sign in (-1,1):
            for z in (-.7,.7):
                p=h.point(z,sign*1.7,.12)
                m.ellipsoid(p,(.22,.34,.58),'silver',8,16)
                m.lathe(add(p,(sign*.16,0,0)),(sign,0,0),[(0,.15),(.08,.13)],['brass'],20)
        m.features.append('Paired service cradles and gold docking sockets')
    if role=='tactical':
        for sign in (-1,1):
            p=h.point(-.5,sign*.6,.08)
            m.tube([p,add(p,(sign*.35,.55,-.35))],.045,'edge',8)
            m.lathe(add(p,(sign*.35,.55,-.35)),(sign*.2,.8,.3),[(0,.27),(.075,.31),(.1,.2)],['navy','cyan'],24)
        m.features.append('Raised receiver dishes and sensor equipment')


def palette(ship):
    bird=ship.faction=='swarm'
    c=dict(COLORS)
    c.update(navy=tuple(round(v*.42) for v in ship.back),blue=ship.back,teal=tuple(round((a+b)/2) for a,b in zip(ship.back,ship.flank)),silver=ship.flank,pearl=tuple(min(245,v+23) for v in ship.flank),edge=tuple(round(v*.78) for v in ship.flank),cyan=ship.accent,fin=ship.back,fin_light=ship.flank,brass=(164,132,79) if bird else (186,160,102),glass=(16,34,48),dark=(12,21,28),panel=ship.flank)
    return c


def atlas(ship):
    c=palette(ship); img=Image.new('RGB',(1024,1024),c['navy']); d=ImageDraw.Draw(img)
    for y in range(1024):
        t=math.cos(TAU*(y+.5)/1024); blend=max(0,min(1,(t-.1)/.85))
        rgb=tuple(round(b+(a-b)*blend) for a,b in zip(ship.back,ship.flank))
        d.line((0,y,767,y),fill=rgb)
    layer=Image.new('RGBA',img.size); q=ImageDraw.Draw(layer)
    if ship.faction=='accord':
        for row,y in enumerate(range(72,965,25)):
            for x in range(175+(row%2)*18,744,36):
                q.arc((x-16,y-10,x+20,y+12),270,450,fill=(12,43,56,60),width=1)
                q.arc((x-15,y-9,x+19,y+11),280,430,fill=(244,255,250,68),width=1)
    else:
        for y in range(70,960,64):
            for x in range(120+(y//64%2)*30,730,72):
                q.line([(x,y),(x+20,y+24),(x+5,y+54)],fill=(10,23,35,150),width=3)
                q.line([(x+4,y),(x+24,y+24)],fill=(214,232,224,90),width=1)
    for x in (174,276,392,512,625,711):
        q.line((x,0,x,1023),fill=(12,28,40,110),width=2)
        q.line((x+3,0,x+3,1023),fill=(233,255,249,70),width=1)
    if ship.slug=='pilotfish':
        for x in (240,335,430,525,620): q.rectangle((x,55,x+27,970),fill=(14,40,55,155))
    if ship.slug=='lionfish':
        for x in range(190,740,58): q.polygon([(x,0),(x+27,0),(x+62,512),(x+27,1023),(x,1023),(x+35,512)],fill=(100,46,30,170))
    if ship.slug=='tiger_shark':
        for x in range(180,710,58):
            for sign in (-1,1):
                y=110 if sign==1 else 914
                q.polygon([(x,y),(x+18,y),(x+32,y+sign*140),(x+16,y+sign*94)],fill=(25,43,48,175))
    if ship.slug=='moray':
        for x in range(180,750,47):
            for y in range(120+(x//47%2)*21,910,57): q.ellipse((x,y,x+10,y+8),fill=(35,65,37,135))
    for y in (139,885):
        q.line((185,y,695,y),fill=(13,35,47,180),width=5)
        q.line((190,y+2,690,y+2),fill=ship.accent+(155,),width=1)
    img=Image.alpha_composite(img.convert('RGBA'),layer).convert('RGB'); d=ImageDraw.Draw(img)
    for i,(name,rgb) in enumerate(c.items()):
        x,y=800+(i%4)*56,24+(i//4)*56; d.rectangle((x,y,x+47,y+47),fill=rgb)
    font=ImageFont.load_default(size=16)
    label=('ACCORD' if ship.faction=='accord' else 'SWARM')+' / '+ship.slug[:11].upper()
    for y in (302,697): d.text((292,y),label,font=font,fill=c['navy'])
    return img


def export(mesh,image,path):
    buf=bytearray(); views=[]; accessors=[]
    def view(data,target=None):
        off=len(buf); buf.extend(data); buf.extend(b'\0'*((-len(buf))%4))
        v={'buffer':0,'byteOffset':off,'byteLength':len(data)}
        if target: v['target']=target
        views.append(v); return len(views)-1
    for values,width,kind,ctype in [(mesh.p,3,'VEC3',5126),(mesh.n,3,'VEC3',5126),(mesh.uv,2,'VEC2',5126),(mesh.idx,1,'SCALAR',5123)]:
        flat=[v for row in values for v in row] if width>1 else values
        fmt='f' if ctype==5126 else 'H'
        v=view(struct.pack('<'+fmt*len(flat),*flat),34962 if width>1 else 34963)
        a={'bufferView':v,'componentType':ctype,'count':len(values),'type':kind}
        if len(accessors)==0:
            a.update(min=[min(p[k] for p in values) for k in range(3)],max=[max(p[k] for p in values) for k in range(3)])
        accessors.append(a)
    stream=io.BytesIO(); image.save(stream,format='PNG',optimize=True); im=view(stream.getvalue())
    name=mesh.ship.slug
    doc={'asset':{'version':'2.0','generator':'Galaxy original species fleet / tools/build_fleet_models.py'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'name':name+'_hull','mesh':0}],
         'meshes':[{'name':name+'_hull','primitives':[{'attributes':{'POSITION':0,'NORMAL':1,'TEXCOORD_0':2},'indices':3,'material':0,'mode':4}]}],
         'materials':[{'name':name+'_atlas','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':.6}}],
         'images':[{'bufferView':im,'mimeType':'image/png'}],'textures':[{'source':0,'sampler':0}],
         'samplers':[{'magFilter':9729,'minFilter':9729,'wrapS':33071,'wrapT':33071}],
         'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(buf)}]}
    raw=json.dumps(doc,separators=(',',':')).encode(); raw+=b' '*((-len(raw))%4)
    # Stage beside the destination so a failed/locked replacement never truncates
    # the last usable model. This also avoids Windows import-cache write races.
    temporary=path.with_suffix('.glb.tmp')
    temporary.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(raw)+len(buf))+struct.pack('<II',len(raw),0x4E4F534A)+raw+struct.pack('<II',len(buf),0x004E4942)+buf)
    temporary.replace(path)
    return doc
