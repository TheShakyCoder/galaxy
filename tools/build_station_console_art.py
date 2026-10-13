"""Deterministic, code-authored nine-slice console surfaces and service icons."""
from pathlib import Path
import math, random, sys
from PIL import Image, ImageDraw
ROOT=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
OUT=ROOT/'main/ui/station_console'
OUT.mkdir(parents=True,exist_ok=True)

def bevel(name,active=False,gold=False,row=False):
    w,h=(256,96) if row else (256,256)
    im=Image.new('RGBA',(w,h)); d=ImageDraw.Draw(im)
    cut=12 if row else 20
    def poly(inset):
        a=inset; b=w-1-inset; c=h-1-inset; k=max(3,cut-inset//2)
        return [(a+k,a),(b-k,a),(b,a+k),(b,c-k),(b-k,c),(a+k,c),(a,c-k),(a,a+k)]
    d.polygon(poly(0),fill=(3,8,12,255))
    d.line(poly(1)+[poly(1)[0]],fill=(80,105,114,255),width=2)
    d.line(poly(5)+[poly(5)[0]],fill=(26,48,59,255),width=2)
    d.polygon(poly(9),fill=(13,23,30,250))
    accent=(206,160,80,255) if gold else ((87,216,239,255) if active else (82,115,128,255))
    d.line(poly(9)+[poly(9)[0]],fill=accent,width=2)
    rnd=random.Random(724)
    for y in range(24,h-24):
        shade=int(24+9*(1-y/h))
        if active: color=(shade//2,shade+19,shade+28,255)
        else: color=(shade-7,shade,shade+5,255)
        d.line((20,y,w-21,y),fill=color)
        if y%3==0:
            a=rnd.randrange(24,80); d.line((a,y,w-a,y),fill=(*color[:3],245))
    d.line((27,18,w-28,18),fill=(102,118,120,255))
    d.line((28,h-18,w-28,h-18),fill=(5,10,15,255))
    for x in [17,w-18]:
        for y in [29,h-30]:
            d.ellipse((x-2,y-2,x+2,y+2),fill=(4,8,11,255),outline=(96,111,116,255))
    d.line((24,12,55,12),fill=(186,153,89,255),width=2)
    d.line((w-55,h-13,w-24,h-13),fill=(186,153,89,255),width=2)
    if active:
        d.line((12,35,12,h-35),fill=(117,234,250,255),width=3)
        d.line((25,h-9,w-25,h-9),fill=(70,187,211,255),width=2)
    im.save(OUT/(name+'.png'))

def icon(name):
    S=3; im=Image.new('RGBA',(128*S,128*S)); d=ImageDraw.Draw(im); c=(226,231,224,255)
    def line(points,width=5): d.line([(x*S,y*S) for x,y in points],fill=c,width=width*S,joint='curve')
    def ellipse(rect,width=4): d.ellipse(tuple(x*S for x in rect),outline=c,width=width*S)
    def poly(points): d.polygon([(x*S,y*S) for x,y in points],fill=c)
    if name=='command':
        ellipse((24,24,104,104)); ellipse((41,41,87,87),3)
        for a in [(64,8,64,44),(64,84,64,120),(8,64,44,64),(84,64,120,64)]: line([a[:2],a[2:]])
    elif name=='fitting':
        line([(31,99),(83,47)],15); poly([(75,22),(100,15),(88,33),(95,42),(113,30),(106,54),(91,60),(72,41)])
        ellipse((20,88,40,108),4)
    elif name=='hangar':
        line([(14,108),(14,47),(64,15),(114,47),(114,108)],6)
        line([(29,104),(29,57),(64,34),(99,57),(99,104)],3)
        poly([(64,52),(82,93),(64,84),(46,93)])
    elif name=='map':
        ellipse((16,16,112,112)); ellipse((42,16,86,112),3); line([(16,64),(112,64)],3)
        line([(25,37),(103,37)],3); line([(25,91),(103,91)],3)
    elif name=='livery':
        poly([(42,68),(82,28),(100,46),(62,86)]); line([(84,25),(99,10)],9)
        poly([(37,73),(58,94),(33,113),(15,111),(23,87)])
    elif name=='weapon':
        for x in [28,55,82]: poly([(x,108),(x,38),(x+8,15),(x+16,38),(x+16,108)])
    elif name=='computer':
        line([(34,34),(94,34),(94,94),(34,94),(34,34)],5)
        for x in [44,64,84]:
            line([(x,16),(x,31)],3); line([(x,96),(x,112)],3)
            line([(16,x),(31,x)],3); line([(96,x),(112,x)],3)
    elif name=='engine':
        ellipse((19,19,109,109),4)
        for i in range(6):
            a=i*math.pi/3
            poly([(64+math.cos(a)*14,64+math.sin(a)*14),(64+math.cos(a+.2)*40,64+math.sin(a+.2)*40),(64+math.cos(a+.75)*40,64+math.sin(a+.75)*40)])
        ellipse((49,49,79,79),4)
    elif name=='hull':
        line([(64,13),(105,27),(101,74),(87,94),(64,116),(41,94),(27,74),(23,27),(64,13)],5)
        line([(64,17),(64,110)],3)
    elif name=='orbital':
        ellipse((10,10,118,118),2); ellipse((19,19,109,109),1)
        ellipse((15,45,113,83),1); ellipse((44,12,84,116),1)
        line([(64,0),(64,128)],1); line([(0,64),(128,64)],1)
        poly([(64,31),(72,56),(96,64),(72,72),(64,97),(56,72),(32,64),(56,56)])
    im.resize((128,128),Image.Resampling.LANCZOS).save(OUT/(name+'.png'))

for name,kw in [('panel',{}),('button',{}),('button_active',{'active':True}),('button_gold',{'gold':True}),('row',{'row':True})]: bevel(name,**kw)
for name in ['command','fitting','hangar','map','livery','weapon','computer','engine','hull','orbital']: icon(name)
files=sorted(OUT.glob('*.png'))
(OUT/'console.atlas').write_text('\n'.join('images { image: "/main/ui/station_console/'+p.name+'" }' for p in files)+'\nextrude_borders: 2\n',encoding='utf8')
print('Built',len(files),'console textures')
