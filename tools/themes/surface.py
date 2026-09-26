"""Original drawn ornament and fin-panel UVs for the eight fleet collections."""
from dataclasses import replace
import hashlib
import math
import random
from PIL import Image, ImageDraw, ImageFont
from build_sardine_model import COLORS
from fleet.geometry import atlas
from fleet.roster import SHIPS
from .collections import THEMES


def decorate(image,key,ship,region,detail_scale=1):
    """Draw locally then clip, keeping UV swatches isolated from ornament."""
    x0,y0,x1,y1=region; w,h=x1-x0,y1-y0
    patch=Image.new('RGBA',(w,h)); d=ImageDraw.Draw(patch)
    c=THEMES[key]; ink=c['ink']; gold=c['trim']
    seed=int.from_bytes(hashlib.sha256((ship.slug+key+str(region)).encode()).digest()[:8],'little')
    rng=random.Random(seed)
    def floral(x,y,s):
        stem=[(x+s*.7*math.sin(i*.28),y-i*s*.32) for i in range(25)]
        d.line(stem,fill=ink+(220,),width=max(1,round(s*.065)))
        for j in (4,9,14,19):
            px,py=stem[j]; sign=1 if j%2 else -1
            d.arc((px-s,py-s,px+s,py+s),20 if sign==1 else 160,190 if sign==1 else 335,fill=ink+(210,),width=2)
            d.ellipse((px+sign*s*.55-s*.2,py-s*.2,px+sign*s*.55+s*.2,py+s*.15),fill=ink+(170,))
        px,py=stem[-1]
        for a in range(0,360,60):
            dx,dy=math.cos(math.radians(a))*s*.43,math.sin(math.radians(a))*s*.43
            d.ellipse((px+dx-s*.26,py+dy-s*.26,px+dx+s*.26,py+dy+s*.26),outline=ink+(240,),width=2)
        d.ellipse((px-s*.1,py-s*.1,px+s*.1,py+s*.1),fill=gold+(255,))
    if key=='porcelain_dynasty':
        for x in range(30,w,75):
            for y in range(130+(x//75%2)*55,h+50,205): floral(x,y,16)
        for y in (12,h-15):
            d.line((0,y,w,y),fill=gold+(230,),width=3)
            d.line((0,y+5,w,y+5),fill=ink+(230,),width=2)
        # Deliberate gold-filled ceramic seams, distinct from the blue scrollwork.
        for start in (w*.27,w*.78):
            p=[(start,0),(start-10,h*.24),(start+22,h*.40),(start+8,h*.67),(start+34,h)]
            d.line(p,fill=gold+(225,),width=3)
            d.line([p[2],(p[2][0]+35,p[2][1]-25)],fill=gold+(220,),width=2)
    elif key=='starlight':
        for _ in range(max(25,w*h//1400)):
            x,y=rng.randrange(w),rng.randrange(h); r=rng.choice([1,1,1,2])
            d.ellipse((x-r,y-r,x+r,y+r),fill=ink+(rng.randrange(120,245),))
        for y in range(80,h,200):
            pts=[(w*.18,y+20),(w*.35,y-20),(w*.57,y+34),(w*.79,y-6),(w*.86,y+58)]
            d.line(pts,fill=(108,177,233,175),width=2)
            for x,py in pts:
                d.line((x-5,py,x+5,py),fill=(239,244,250,255),width=2)
                d.line((x,py-5,x,py+5),fill=(239,244,250,255),width=2)
    elif key=='grand_prix':
        d.polygon([(w*.30,0),(w*.47,0),(w*.70,h),(w*.53,h)],fill=(246,233,198,235))
        d.polygon([(w*.48,0),(w*.54,0),(w*.77,h),(w*.71,h)],fill=(241,103,29,255))
        for y in (30,h-60):
            for j in range(3):
                for i in range(max(1,w//14)):
                    if (i+j)%2==0:d.rectangle((i*14,y+j*10,i*14+13,y+j*10+9),fill=ink+(220,))
        number=next(i+1 for i,s in enumerate(SHIPS) if s.slug==ship.slug)
        text=f'{number:02d}'
        size=46 if w>300 else 37; font=ImageFont.load_default(size=size)
        for y in ([220,550] if h>700 else [h*.42]):
            d.rounded_rectangle((w*.15,y-9,w*.15+size*1.75,y+size+12),radius=7,fill=(241,231,205,250),outline=ink+(255,),width=3)
            d.text((w*.15+9,y),text,font=font,fill=ink+(255,))
    elif key=='abyssal':
        for y in range(50,h,120):
            pts=[(x,y+15*math.sin(x*.045)) for x in range(0,w,4)]
            d.line(pts,fill=(52,175,171,190),width=2)
            for x in range(25,w,45):d.ellipse((x-2,y-2,x+2,y+2),fill=(151,245,224,245))
    elif key=='crystalborn':
        for y in range(-10,h,100):
            for x in range(-10,w,75):
                d.polygon([(x,y+40),(x+28,y),(x+70,y+40),(x+38,y+92)],outline=ink+(180,),width=2)
                d.line([(x+28,y),(x+38,y+92),(x+70,y+40)],fill=(119,206,224,150),width=1)
    elif key=='corsair':
        for x in range(0,w,44):
            d.line((x,0,x,h),fill=(29,20,15,185),width=3)
            for offset in (9,21,33):
                pts=[(x+offset+2.5*math.sin(y*.04+x),y) for y in range(0,h,5)]
                d.line(pts,fill=(43,25,13,80),width=1)
            for y in range(35,h,145):
                d.ellipse((x+5,y-2,x+9,y+2),fill=gold+(245,))
                d.line((x,y+50,x+44,y+50),fill=(43,25,13,130),width=2)
        # Requested faction insignias, also repeated as raised model badges.
        for y in (h*.32,h*.70):
            x=w*.48;r=min(34,w*.16)
            if ship.faction=='accord':
                pts=[(x,y-r),(x-r*.88,y+r*.58),(x+r*.88,y+r*.58)]
                d.polygon(pts,fill=(235,217,171,255),outline=(61,37,23,255),width=3)
            else:
                d.ellipse((x-r,y-r,x+r,y+r),fill=(235,217,171,255),outline=(61,37,23,255),width=3)
                d.ellipse((x-r*.56,y-r*.56,x+r*.56,y+r*.56),fill=(71,46,29,255))
    elif key=='overgrown':
        for _ in range(w*h//420):
            x,y=rng.randrange(w),rng.randrange(h); r=rng.randrange(1,6)
            d.ellipse((x-r,y-r,x+r,y+r),fill=rng.choice([(39,80,48,65),(149,179,81,90),(28,61,41,90)]))
        for x in range(35,w,100):
            d.line([(x+15*math.sin(y*.025),y) for y in range(0,h,4)],fill=(37,74,43,165),width=3)
    elif key=='toybox':
        for y in range(0,h,110):
            color=(243,191,75,200) if y//110%2 else (28,145,180,180)
            d.rectangle((0,y,w,y+50),fill=color)
        for y in range(45,h,155):
            x=w*.5
            points=[(x+math.cos(-math.pi/2+i*math.pi/5)*(20 if i%2==0 else 9),y+math.sin(-math.pi/2+i*math.pi/5)*(20 if i%2==0 else 9)) for i in range(10)]
            d.polygon(points,fill=(243,230,169,255),outline=(190,62,49,245),width=2)
    image.paste(Image.alpha_composite(image.crop(region).convert('RGBA'),patch).convert('RGB'),(x0,y0))


def paint(ship,key):
    c=THEMES[key]
    im=atlas(replace(ship,back=c['back'],flank=c['flank'],accent=c['accent']))
    d=ImageDraw.Draw(im)
    if ship.slug=='sardine':
        for y in (181,843):
            for x in range(215,630,52):d.ellipse((x-5,y-5,x+5,y+5),fill=c['ink'])
    # Pattern atlas reserved below the sixteen legacy swatches.
    d.rectangle((774,285,1023,1023),fill=c['fin'])
    decorate(im,key,ship,(175,0,745,1024))
    decorate(im,key,ship,(778,292,1018,1018))
    colors=dict(COLORS)
    colors.update(navy=tuple(round(v*.45) for v in c['back']),blue=c['back'],teal=c['flank'],
                  silver=c['flank'],pearl=c['light'],edge=c['trim'],dark=(14,20,28),
                  glass=(16,38,57),cyan=c['accent'],white=(245,240,212),brass=c['trim'],
                  fin=c['fin'],fin_light=c['light'],nozzle=(30,39,45),panel=c['ink'],spot=c['ink'])
    if key=='porcelain_dynasty':colors.update(glass=(27,59,113),dark=(27,46,79))
    if key=='crystalborn':colors.update(teal=(97,186,188),cyan=(161,240,224),white=(222,240,242))
    if key=='overgrown':colors.update(pearl=(226,163,125),cyan=(245,133,129),brass=(172,134,69))
    d=ImageDraw.Draw(im)
    for i,(name,rgb) in enumerate(colors.items()):
        x,y=800+i%4*56,24+i//4*56; d.rectangle((x,y,x+47,y+47),fill=rgb)
    return im


def remap_panels(mesh):
    """Copy-only UV remap gives fins/feathers actual pattern rather than flat paint."""
    swatches=[mesh.swatch(c) for c in ('blue','fin','fin_light','pearl')]
    lo=[min(p[k] for p in mesh.p) for k in range(3)]; hi=[max(p[k] for p in mesh.p) for k in range(3)]
    changed=0
    for i,(p,n,uv) in enumerate(zip(mesh.p,mesh.n,mesh.uv)):
        if not any(abs(uv[0]-a)<1e-6 and abs(uv[1]-b)<1e-6 for a,b in swatches):continue
        if mesh.ship.faction=='swarm' or abs(n[1])>abs(n[0]):
            u=abs(p[0])/max(abs(lo[0]),abs(hi[0])); v=(p[2]-lo[2])/(hi[2]-lo[2])
        else:
            u=(p[2]-lo[2])/(hi[2]-lo[2]); v=(p[1]-lo[1])/(hi[1]-lo[1])
        mesh.uv[i]=((782+232*u)/1024,(298+710*v)/1024); changed+=1
    return changed
