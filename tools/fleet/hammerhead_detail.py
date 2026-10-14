"""Approved Hammerhead detail study, isolated from the other 23 fleet hulls.

Coordinates and atlas contract match fleet.geometry: +Z bow, +Y dorsal.
All surfaces use the original hull UV region or palette swatches, so existing
surface recolors remain valid. Sculpted cosmetics keep their own geometry.
"""
import math
import random
from PIL import ImageDraw
from .geometry import Mesh, Hull, cockpit, add, mul
from .fish import fork, pectorals, dorsal
from build_sardine_model import sub, cross, unit

TAU = math.tau


def atlas(ship):
    from .geometry import atlas as original_atlas
    image=original_atlas(ship);d=ImageDraw.Draw(image)
    # A manufactured panel finish replaces fish-scale engraving on this hull.
    for y in range(1024):
        t=max(0,min(1,(math.cos(TAU*(y+.5)/1024)-.1)/.85))
        rgb=tuple(round(b+(a-b)*t) for a,b in zip(ship.back,ship.flank))
        d.line((0,y,767,y),fill=rgb)
    rng=random.Random(272)
    for x in (45,112,181,250,321,393,465,537,609,681,740):
        d.line((x,0,x,1023),fill=(44,65,71),width=1)
        for y in range(24,1024,128):
            d.line((x+2,y,x+2,y+74),fill=(191,207,208),width=1)
    for y in (90,166,265,365,512,659,759,858,934):
        for x in range(20,735,74):
            d.line((x,y,x+64,y),fill=(48,70,76),width=1)
            d.line((x+2,y+2,x+62,y+2),fill=(174,195,198),width=1)
            for xx in (x+5,x+59):
                d.rectangle((xx,y+6,xx+1,y+7),fill=(37,51,57))
    # Subtle deterministic machining marks, rather than large dirt patches.
    for _ in range(4800):
        x=rng.randrange(4,758);y=rng.randrange(1024)
        rgb=image.getpixel((x,y));delta=rng.choice((-8,-4,4,7))
        d.line((x,y,x+rng.randrange(1,4),y),fill=tuple(max(0,min(255,c+delta)) for c in rgb))
    return image


def patch(m, point, normal, u0, u1, v0, v1, nu, nv, color=None, uv=None):
    rows=[]
    for i in range(nu+1):
        u=u0+(u1-u0)*i/nu; row=[]
        for j in range(nv+1):
            v=v0+(v1-v0)*j/nv
            row.append(m.vertex(point(u,v),normal(u,v),uv(u,v) if uv else m.swatch(color)))
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for j in range(nv):
            n=add(m.n[a[j]],m.n[b[j+1]])
            m.tri(a[j],b[j],b[j+1],n);m.tri(a[j],b[j+1],a[j+1],n)


def head_point(x,a,offset=0):
    t=abs(x)/3.04
    z=5.08+.28*math.sin(math.pi*t)-.04*t
    ry=.46+.07*math.sin(math.pi*t)-.10*t
    rz=.90-.50*t*t
    return (x,.07+(ry+offset)*math.cos(a),z+(rz+offset)*math.sin(a))


def head_normal(x,a):
    dx=sub(head_point(x+.0001,a),head_point(x-.0001,a))
    da=sub(head_point(x,a+.0001),head_point(x,a-.0001))
    return unit(cross(da,dx))


def head_uv(x,a):
    # Silver belly region of the same atlas used by existing recolors.
    return (.08+.61*(x+3.04)/6.08,.36+.28*(a%TAU)/TAU)


def hull_uv(h,z,a):
    return (.004+.738*(h.z1-z)/(h.z1-h.z0),(a%TAU)/TAU)


def surface_panel(m,h,z0,z1,a0,a1,color=None):
    # Conformal armor surfaces with edge trim over a dark seam.
    uv=None if color else lambda z,a:hull_uv(h,z,a)
    patch(m,lambda z,a:h.point(z,a,.044),h.normal,z0,z1,a0,a1,5,5,color,uv)
    for aa in (a0,a1):
        m.tube([h.point(z0+(z1-z0)*i/8,aa,.036) for i in range(9)],.012,'edge',6)
    for zz in (z0,z1):
        m.tube([h.point(zz,a0+(a1-a0)*i/8,.036) for i in range(9)],.012,'edge',6)


def head(m):
    # Continuous foil-shaped core replaces the old flattened ellipsoid.
    patch(m,head_point,head_normal,-3.04,3.04,0,TAU,48,32,'navy')
    for sign in (-1,1):
        x=sign*3.04
        m.face([head_point(x,TAU*i/48) for i in range(48)],'edge',(sign,0,0))
    # Segmented upper and lower cheeks: visible seams follow the head contour.
    xs=(-3.02,-2.35,-1.55,-.65,.65,1.55,2.35,3.02)
    angles=(0,.8,1.65,2.45,math.pi,3.95,4.85,5.5,TAU)
    for x0,x1 in zip(xs,xs[1:]):
        for a0,a1 in zip(angles,angles[1:]):
            patch(m,lambda x,a:head_point(x,a,.028),head_normal,
                  x0+.013,x1-.013,a0+.014,a1-.014,5,5,uv=head_uv)
    # Recessed optical eyes: layered housings, black cavity, inset glass,
    # a small cyan lens and separate concentric metal rings.
    for sign in (-1,1):
        p=(sign*3.02,.07,5.08);axis=(sign*.98,0,.20)
        m.lathe(p,axis,[(0,.35),(.12,.385),(.23,.35),(.25,.285)],['edge','silver','dark'],40)
        n=unit(axis)
        m.lathe(add(p,mul(n,.252)),axis,[(0,.28),(.009,.266)],['dark'],40)
        m.lathe(add(p,mul(n,.263)),axis,[(0,.205),(.035,.184),(.05,.13)],['navy','glass'],32)
        m.lathe(add(p,mul(n,.315)),axis,[(0,.066),(.008,.052)],['cyan'],24)
        for a in (.3,1.9,3.45,5.05):
            # Tiny fasteners in the front annulus, not floating beyond the rim.
            side=unit(cross(n,(0,1,0)));up=cross(side,n)
            q=add(add(p,mul(n,.248)),add(mul(side,.317*math.cos(a)),mul(up,.317*math.sin(a))))
            m.lathe(q,n,[(0,.019),(.012,.015)],['dark'],8)
        # Flush cheek intake and paired slit lights on the forward/lower foil.
        for xa in (1.10,2.10):
            x=sign*xa
            patch(m,lambda xx,a:head_point(xx,a,.033),head_normal,x-.18,x+.18,1.43,1.69,2,3,'dark')
            for a in (1.49,1.58,1.67):
                m.tube([head_point(x-.15,a,.041),head_point(x+.15,a,.041)],.011,'edge',6)
        m.tube([head_point(sign*x,2.15,.045) for x in (1.35,1.6,1.85)],.021,'navy',8)
        m.tube([head_point(sign*x,2.15,.058) for x in (1.39,1.6,1.81)],.009,'cyan',6)
        # Raised shoulder plates flow into the bridge instead of a smooth bar.
        for x0,x1 in ((.70,1.50),(1.59,2.29),(2.38,2.87)):
            patch(m,lambda x,a:head_point(sign*x,a,.055),lambda x,a:head_normal(sign*x,a),
                  x0,x1,.14,.69,4,4,uv=lambda x,a:head_uv(sign*x,a))
            for x in (x0+.07,x1-.07):
                a=.48;p=head_point(sign*x,a,.063);n=head_normal(sign*x,a)
                m.lathe(p,n,[(0,.024),(.012,.017)],['edge','dark'],8)
    # Central lower intake suggests a shark mouth without an organic face.
    outline=[(-.65,-.12,5.98),(-.40,-.31,5.98),(.40,-.31,5.98),(.65,-.12,5.98),(.44,-.04,5.98),(-.44,-.04,5.98)]
    m.face(outline,'dark',(0,0,1))
    m.tube(outline+[outline[0]],.042,'edge',8)
    for x in (-.42,-.21,0,.21,.42):
        m.tube([(x,-.27,6.005),(x,-.10,6.005)],.013,'navy',6)
    m.tube([(-.42,-.20,6.012),(0,-.22,6.012),(.42,-.20,6.012)],.012,'edge',6)


def gills(m,h):
    # Five broad dark heat-exchanger slots with raised lips and inset vanes.
    for sign in (-1,1):
        for row in range(5):
            z=4.02-row*.29
            point=lambda u,a:h.point(u-.17*math.sin(a),sign*a,.032)
            normal=lambda u,a:h.normal(u-.17*math.sin(a),sign*a)
            patch(m,point,normal,z-.115,z+.075,.60,2.49,2,18,'dark')
            for zz in (z-.116,z+.08):
                m.tube([h.point(zz-.17*math.sin(a),sign*a,.054) for a in [.6+1.89*j/18 for j in range(19)]],.027,'edge',8)
            for a in (.86,1.12,1.38,1.64,1.90,2.16):
                m.tube([point(z-.09,a),point(z+.045,a)],.010,'navy',6)


def engines(m,h):
    for sign in (-1,1):
        p=(sign*.70,-.22,-3.50)
        # Keep the original twin engine placement, adding collars and vanes.
        m.lathe(p,(0,0,-1),[(0,.20),(.15,.29),(.35,.30),(.68,.30),(.83,.27),(.93,.23)],['navy','silver','silver','edge','dark'],32)
        for z in (.24,.64,.80):
            m.lathe(add(p,(0,0,-z)),(0,0,-1),[(0,.31),(.035,.31)],['edge'],32)
        m.lathe(add(p,(0,0,-.935)),(0,0,-1),[(0,.205),(.009,.19)],['dark'],32)
        m.lathe(add(p,(0,0,-.947)),(0,0,-1),[(0,.11),(.01,.09)],['cyan'],24)
        for i in range(12):
            a=TAU*i/12
            q=add(p,(.24*math.cos(a),.24*math.sin(a),-.84))
            r=add(p,(.18*math.cos(a),.18*math.sin(a),-.96))
            m.tube([q,r],.012,'edge',6)
        # Compact protected sensor domes replace the exposed flat dish faces.
        a=sign*1.05;p=h.point(-.5,a,.04);n=h.normal(-.5,a)
        m.lathe(p,n,[(0,.25),(.11,.29),(.17,.27),(.20,.215)],['navy','edge','dark'],32)
        m.lathe(add(p,mul(n,.205)),n,[(0,.18),(.045,.155),(.06,.09)],['glass','cyan'],28)


def build(ship):
    assert ship.slug=='hammerhead'
    m=Mesh(ship,detail_scale=1)
    h=Hull([(-5.6,.22,.25),(-4.4,.354,.324),(-2.4,.728,.648),(0,1.04,.9),
            (2,1.082,.927),(3.5,.978,.846),(4.8,.80,.703),(5.55,.51,.43),(5.85,.20,.27)])
    m.hull=h
    h.build(m,steps=100,sides=72)
    fork(m,height=2.0,shark=True); pectorals(m,.95,2.75,z=2.3,length=3.4)
    dorsal(m,h,z=.8,height=1.6,length=2.8)
    head(m);gills(m,h);cockpit(m,h,3.95,4.95,.29)
    # Hull plates sit outside the original torso, keeping the shark taper.
    for sign in (-1,1):
        for z0,z1 in ((-4.15,-3.25),(-3.20,-2.30),(-2.25,-1.2),(-1.15,-.1),(-.05,.95),(1.,2.15)):
            for a0,a1 in ((.26,.88),(.93,1.57),(1.64,2.30),(2.35,2.90)):
                surface_panel(m,h,z0,z1,sign*a0,sign*a1)
        # Long recessed lateral service channel, broken by transverse bulkheads.
        for z0,z1 in ((-3.1,-1.7),(-1.6,-.1),(.0,1.7)):
            patch(m,lambda z,a:h.point(z,a,.056),h.normal,z0,z1,sign*1.10,sign*1.24,6,2,'dark')
            m.tube([h.point(z,sign*1.10,.067) for z in (z0,(z0+z1)/2,z1)],.014,'edge',6)
        # Pectoral mounting saddles, with visible recessed hinge pins.
        p=h.point(1.85,sign*1.65,.04);n=h.normal(1.85,sign*1.65)
        m.lathe(p,n,[(0,.24),(.09,.27),(.13,.22),(.15,.12)],['navy','edge','dark'],24)
        # Fin armor inlays and inset service markings, on both sides.
        for y in (-.20,-.04):
            pts=[(sign*1.12,y,1.95),(sign*1.48,y,1.61),(sign*2.47,y,-.84),(sign*2.33,y,-.82),(sign*1.02,y,.76)]
            m.face(pts,'blue',(0,1 if y>-.12 else -1,0))
            m.tube([pts[0],pts[1],pts[2]],.016,'silver',6)
            for t in (.3,.57,.79):
                x=1.20+1.13*t;z=1.7-2.4*t
                m.tube([(sign*x,y,z),(sign*(x-.17),y,z-.13)],.012,'edge',6)
    engines(m,h)
    m.features=['Sculpted foil-shaped hammer head with segmented upper and lower armor',
                'Recessed optical eyes, cheek vents and under-head intake',
                'Five gill heat exchangers per flank', 'Conformal hull armor and service channels',
                'Fin mounting saddles, twin cooling collars and recessed nozzles']
    return m
