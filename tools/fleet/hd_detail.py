"""Conformal service hardware and 2K micro-detail with the approved atlas UVs."""
import math
from PIL import Image, ImageDraw, ImageFont
from build_sardine_model import add, mul

def service_details(mesh,hull):
    # Bilateral panels stay close to the existing body, leaving eyes/gills/fins free.
    span=hull.z1-hull.z0
    for fraction in (.36,.48,.60):
        z=hull.z0+span*fraction
        for sign in (-1,1):
            angle=sign*1.78
            # Dark inset plus a raised bevel frame following hull curvature.
            zhalf=min(.38,span*.025); ahalf=.13
            for offset,shrink,color in ((.025,1,'navy'),(.043,.91,'edge'),(.055,.77,'dark')):
                ids=[]; steps=4
                for i in range(steps+1):
                    zz=z-zhalf*shrink+2*zhalf*shrink*i/steps
                    for j in range(steps+1):
                        a=angle-ahalf*shrink+2*ahalf*shrink*j/steps
                        ids.append(mesh.vertex(hull.point(zz,a,offset),hull.normal(zz,a),mesh.swatch(color)))
                for i in range(steps):
                    for j in range(steps):
                        a=ids[i*(steps+1)+j];b=ids[(i+1)*(steps+1)+j]
                        mesh.tri(a,b,b+1,mesh.n[a]);mesh.tri(a,b+1,a+1,mesh.n[a])
            for zz in (z-zhalf*.8,z+zhalf*.8):
                for aa in (angle-ahalf*.78,angle+ahalf*.78):
                    p=hull.point(zz,aa,.065);n=hull.normal(zz,aa)
                    mesh.lathe(p,n,[(0,.024),(.018,.026),(.025,.016)],['silver','dark'],8)
            for row in range(5):
                zz=z-zhalf*.52+row*zhalf*.26
                points=[hull.point(zz,angle-ahalf*.53+j*ahalf*1.06/6,.071) for j in range(7)]
                mesh.tube(points,.012,'edge',6)
    # Paired rear navigation strobes and protected service ports.
    for sign in (-1,1):
        z=hull.z0+span*.28;a=sign*.92;p=hull.point(z,a,.02);n=hull.normal(z,a)
        mesh.lathe(p,n,[(0,.10),(.04,.12),(.07,.08)],['navy','edge'],24)
        mesh.lathe(add(p,mul(n,.071)),n,[(0,.061),(.017,.057)],['cyan'],24)

def texture_2k(source,ship):
    # Preserve atlas regions and swatches so every existing recolor remains mapped.
    img=source.resize((2048,2048),Image.Resampling.LANCZOS).convert('RGB')
    overlay=Image.new('RGBA',img.size);d=ImageDraw.Draw(overlay)
    font=ImageFont.load_default(size=17)
    tiny=ImageFont.load_default(size=12)
    for y in (380,1380):
        for x in (320,520,760,1000,1260):
            d.rounded_rectangle((x,y,x+130,y+66),radius=8,outline=(6,16,23,130),width=2)
            d.line((x+8,y+3,x+121,y+3),fill=(226,239,243,92),width=1)
            for bx in (x+8,x+122):
                for by in (y+9,y+57):
                    d.ellipse((bx-2,by-2,bx+2,by+2),fill=(6,14,20,175))
            for j in range(6):
                d.line((x+22,y+14+j*6,x+106,y+14+j*6),fill=(9,19,26,130),width=2)
        d.text((400,y+97),ship.slug.replace('_',' ').upper()+'  //  '+ship.role.upper(),font=font,fill=(224,238,245,180))
        d.text((990,y+101),'SERVICE  /  KEEP CLEAR',font=tiny,fill=(223,234,238,135))
    # Fine staggered etching adds real 2K-frequency information to the hull only.
    for y in range(24,2040,36):
        for x in range(16+(y//36%2)*24,1510,48):
            d.line((x,y,x+19,y),fill=(228,241,246,18),width=1)
    return Image.alpha_composite(img.convert('RGBA'),overlay).convert('RGB')
