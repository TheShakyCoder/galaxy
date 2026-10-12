"""Native 2K ornament for the three surface collections; normalized atlas UVs stay fixed."""
import hashlib
import math
import random
from PIL import Image, ImageDraw, ImageFont
from themes.collections import THEMES
from themes.surface import paint
from fleet.roster import SHIPS

def ornament(image, ship, key, region):
    x0,y0,x1,y1=region; w,h=x1-x0,y1-y0
    layer=Image.new('RGBA',(w,h));d=ImageDraw.Draw(layer)
    c=THEMES[key];ink=c['ink'];gold=c['trim']
    rng=random.Random(int.from_bytes(hashlib.sha256((ship.slug+key+str(region)).encode()).digest()[:8],'little'))
    if key=='porcelain_dynasty':
        # Broad botanical silhouettes remain legible in flight; fine veins reward close inspection.
        for x in range(65,w,175):
            for y in range(250+(x//175%2)*95,h+120,410):
                stem=[(x+18*math.sin(t*.15),y-t*4) for t in range(48)]
                d.line(stem,fill=ink+(235,),width=4)
                for t in (8,17,27,37):
                    px,py=stem[t];sgn=1 if t%2 else -1
                    leaf=[(px,py),(px+sgn*30,py-35),(px+sgn*47,py-17),(px+sgn*24,py+2)]
                    d.polygon(leaf,fill=ink+(195,))
                    d.line([(px,py),(px+sgn*34,py-21)],fill=(173,192,221,220),width=2)
                px,py=stem[-1]
                for a in range(0,360,60):
                    dx,dy=math.cos(math.radians(a))*15,math.sin(math.radians(a))*15
                    d.ellipse((px+dx-12,py+dy-12,px+dx+12,py+dy+12),outline=ink+(245,),width=3)
                d.ellipse((px-6,py-6,px+6,py+6),fill=gold+(255,))
        for y in (22,h-29):
            d.line((0,y,w,y),fill=gold+(245,),width=5)
            d.line((0,y+10,w,y+10),fill=ink+(230,),width=3)
            for x in range(12,w,28): d.ellipse((x,y-9,x+3,y-6),fill=gold+(225,))
        for start in (w*.27,w*.78):
            path=[(start,0),(start-20,h*.24),(start+44,h*.40),(start+16,h*.67),(start+68,h)]
            d.line(path,fill=(116,85,33,230),width=6)
            d.line(path,fill=gold+(255,),width=4)
            d.line([path[2],(path[2][0]+70,path[2][1]-50)],fill=gold+(245,),width=3)
    elif key=='starlight':
        for _ in range(max(45,w*h//2800)):
            x,y=rng.randrange(w),rng.randrange(h);r=rng.choice([1,1,2,2,3])
            d.ellipse((x-r,y-r,x+r,y+r),fill=ink+(rng.randrange(130,245),))
        for y in range(160,h,400):
            pts=[(w*.18,y+40),(w*.35,y-40),(w*.57,y+68),(w*.79,y-12),(w*.86,y+116)]
            d.line(pts,fill=(108,177,233,175),width=3)
            for i,(x,py) in enumerate(pts):
                d.ellipse((x-13,py-13,x+13,py+13),outline=(126,182,230,90),width=2)
                d.line((x-9,py,x+9,py),fill=(230,248,255,255),width=3)
                d.line((x,py-9,x,py+9),fill=(230,248,255,255),width=3)
                d.ellipse((x-3,py-3,x+3,py+3),fill=(255,255,255,255))
        for y in (24,h-26):
            d.line((0,y,w,y),fill=(151,180,215,170),width=2)
            for x in range(0,w,26):d.line((x,y-5,x,y+5),fill=(168,197,228,130),width=1)
    else:
        d.polygon([(w*.30,0),(w*.47,0),(w*.70,h),(w*.53,h)],fill=(246,233,198,248))
        d.polygon([(w*.48,0),(w*.54,0),(w*.77,h),(w*.71,h)],fill=(241,103,29,255))
        d.line([(w*.285,0),(w*.515,h)],fill=(247,180,82,235),width=3)
        for y in (60,h-120):
            for j in range(3):
                for i in range(max(1,w//28)):
                    if (i+j)%2==0:d.rectangle((i*28,y+j*20,i*28+27,y+j*20+19),fill=ink+(235,))
        number=next(i+1 for i,s in enumerate(SHIPS) if s.slug==ship.slug)
        font=ImageFont.load_default(size=92 if w>600 else 74)
        for y in ([440,1100] if h>1400 else [h*.42]):
            left=w*.12;size=font.size
            d.rounded_rectangle((left,y-18,left+size*1.85,y+size+30),radius=14,fill=(244,235,215,255),outline=ink+(255,),width=5)
            d.text((left+16,y),f'{number:02d}',font=font,fill=ink+(255,))
            d.text((left+8,y+size+42),'GALAXY RACING',font=ImageFont.load_default(size=18),fill=ink+(255,))
        for y in range(260,h,520):
            for j in range(6):d.line((w*.83,y+j*9,w*.94,y+j*9),fill=(8,25,43,155),width=4)
    image.paste(Image.alpha_composite(image.crop(region).convert('RGBA'),layer).convert('RGB'),(x0,y0))

def paint_hd(ship,key):
    # Keep legacy palette swatches (eyes, trims, glass, engines) exactly compatible.
    image=paint(ship,key).resize((2048,2048),Image.Resampling.NEAREST)
    c=THEMES[key];d=ImageDraw.Draw(image)
    # Replace the body/fin paint with native-resolution artwork, not an upscaled skin.
    for y in range(2048):
        t=math.cos(math.tau*(y+.5)/2048);blend=max(0,min(1,(t-.1)/.85))
        rgb=tuple(round(b+(a-b)*blend) for a,b in zip(c['back'],c['flank']))
        d.line((0,y,1535,y),fill=rgb)
    d.rectangle((1548,570,2047,2047),fill=c['fin'])
    # Subtle structural seams; the decoration stays visually dominant.
    for x in (348,784,1250,1422):
        d.line((x,0,x,2047),fill=tuple(round(v*.84) for v in c['flank']),width=2)
    ornament(image,ship,key,(350,0,1490,2048))
    ornament(image,ship,key,(1556,584,2036,2036))
    return image
