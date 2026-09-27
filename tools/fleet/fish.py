"""Eleven original species-specific Accord hulls; Sardine is preserved separately."""
import math
from .geometry import Mesh,Hull,eye,gill,cockpit,role_details,add,mul


def standard(w=1.35,h=1.25,head=1):
    return Hull([(-5.6,.22,.25),(-4.4,w*.34,h*.36),(-2.4,w*.70,h*.72),(0,w,h),
                 (2,w*1.04,h*1.03),(3.5,w*.94,h*.94),(4.8,w*.70*head,h*.71*head),
                 (5.8,w*.34*head,h*.37*head),(6.3,.07,.11)])


def fin(m,outline,thick=.16,color='fin',horizontal=False,sign=1,y=0):
    start=len(m.p)
    m.fin(outline,thick,color,axis='y' if horizontal else 'x',sign=sign)
    if y: m.transform_part(start,lambda p:add(p,(0,y,0)))


def fork(m,root=-5.25,length=2.8,height=1.8,shark=False):
    for sign in (-1,1):
        h=height*(.70 if shark and sign<0 else 1)
        end=root-length*(.78 if shark and sign<0 else 1)
        fin(m,[(.06,root),(.56,root-.6),(h,end+.4),(h*.95,end),(h*.65,end+.45),(.06,root-1.2)],.17,sign=sign)


def pectorals(m,width=1.2,span=2.7,z=2.8,length=2.7):
    for sign in (-1,1):
        fin(m,[(width,z),(width+.65,z-.4),(span,z-length),(span*.89,z-length-.15),(width*.83,z-1.2)],.13,horizontal=True,sign=sign,y=-.12)


def dorsal(m,h,z=1.5,height=1.15,length=3):
    base=h.section(z)[1]+h.section(z)[2]
    fin(m,[(base*.85,z+.55),(base+height,z),(base+height*.95,z-.4),(base*.90,z-length)],.17)


def build(ship):
    s=ship.slug; m=Mesh(ship)
    if s=='pilotfish': h=standard(1.15,1.1)
    elif s=='piranha':
        h=Hull([(-4.4,.18,.35),(-3,.60,1.45),(-1.5,1.13,2.13),(0,1.35,2.40),
                (2,1.30,2.25),(3.8,1.0,1.85),(5.0,.75,1.1),(5.6,.25,.40)])
    elif s=='anglerfish':
        h=Hull([(-4.5,.22,.35),(-3.2,.6,.8),(-1.7,1.7,1.6),(0,2.1,2.0),
                (2.3,2.2,2.0),(4.4,1.95,1.6),(5.7,1.25,1.1),(6.1,.9,.9)])
    elif s=='barracuda':
        h=Hull([(-6,.18,.22),(-4.5,.48,.50),(-2.5,.75,.72),(0,.90,.85),
                (2.8,.93,.88),(4.7,.8,.65),(6.1,.42,.39),(7,.08,.11)])
    elif s=='remora':
        h=Hull([(-6,.20,.19),(-4.5,.42,.34),(-2,.66,.52),(0,.91,.65),
                (3,1.14,.65),(4.7,1.00,.55),(5.8,.65,.40),(6.2,.2,.23)])
    elif s=='moray':
        h=Hull([(-8,.10,.14),(-6,.29,.43),(-4,.44,.67),
                (-2,.64,.85),(0,.76,.96),(2,.95,1.04),
                (4,1.15,1.1),(5.5,.90,.70),(6.2,.20,.25)])
    elif s=='lionfish': h=standard(1.40,1.70)
    elif s=='marlin':
        h=Hull([(-5.6,.20,.26),(-4.1,.44,.57),(-1.7,.84,1.12),(1,1.11,1.39),
                (3,1.06,1.27),(4.5,.73,.87),(5.5,.30,.38),(6,.10,.13)])
    elif s=='manta_ray':
        h=Hull([(-4.8,.20,.13),(-3,.95,.25),(-1.5,2.55,.44),(0,3.50,.62),
                (1.4,2.4,.78),(2.8,1.85,.71),(4.2,1.60,.44),(4.8,1.05,.25)])
    elif s=='tiger_shark': h=standard(1.50,1.25,1.25)
    elif s=='hammerhead': h=standard(1.04,.9,1.1)
    else: raise ValueError(s)
    h.build(m,steps=64 if s=='moray' else 56)
    m.features.append(ship.identity)

    if s=='pilotfish':
        fork(m); pectorals(m,1.05,2.35); dorsal(m,h,height=.8,length=2.4)
        eye(m,h,4.95,.30); gill(m,h,3.4); cockpit(m,h,3.7,4.9,.35)
    elif s=='piranha':
        fork(m,root=-4,length=2.4,height=1.7); pectorals(m,1.20,2.6,z=2.5,length=2)
        dorsal(m,h,z=.8,height=.85,length=3.1)
        eye(m,h,4.2,.39)
        # A jaw plate and five restrained tooth-like steel hardpoints.
        m.ellipsoid((0,-.63,5.15),(.76,.35,.60),'edge',10,24)
        m.tube([(-.72,-.39,5.32),(0,-.47,5.68),(.72,-.39,5.32)],.055,'dark',8)
        for x in (-.48,-.24,0,.24,.48):
            m.lathe((x,-.43,5.48-abs(x)*.22),(0,1,.15),[(0,.09),(.20,.014)],['pearl'],8)
        gill(m,h,2.65); cockpit(m,h,2.3,3.75,.30)
    elif s=='anglerfish':
        fork(m,root=-4.2,length=2.0,height=1.4); pectorals(m,1.8,3.3,z=1.9,length=2.5)
        dorsal(m,h,z=-.3,height=.65,length=2.3); eye(m,h,4.45,.43,.92)
        # Large circular intake/mouth, tipped lure and projecting jaw details.
        m.lathe((0,-.22,5.68),(0,0,1),[(0,1.27),(.28,1.36),(.34,1.11)],['edge','navy'],48)
        m.lathe((0,-.22,6.025),(0,0,1),[(0,1.08),(.008,1.04)],['dark'],40)
        for x in (-.76,-.38,0,.38,.76):
            m.lathe((x,-1.10,6.08),(0,1,-.04),[(0,.08),(.40,.016)],['pearl'],8)
        stalk=[(0,1.90,2.0),(0,2.80,2.25),(0,3.42,3.0),(0,3.54,4.1),(0,3.1,5.0)]
        m.tube(stalk,.075,'edge',10); m.ellipsoid(stalk[-1],(.28,.34,.28),'cyan',12,24)
        cockpit(m,h,.7,1.8,.34)
    elif s=='barracuda':
        fork(m,root=-5.7,height=1.5); pectorals(m,.85,2.15,z=3.2,length=2.4)
        dorsal(m,h,z=2,height=.85,length=1.7); dorsal(m,h,z=-2.2,height=.55,length=1.8)
        eye(m,h,5.45,.24); gill(m,h,4.1); cockpit(m,h,3.9,5.1,.30)
        m.ellipsoid((0,-.26,6.32),(.42,.18,.83),'silver',10,24)
        m.tube([(-.38,-.13,6.3),(0,-.11,7.0),(.38,-.13,6.3)],.026,'dark',6)
    elif s=='remora':
        fork(m,root=-5.7,length=2.2,height=1.05); pectorals(m,1,2.0,z=2.7,length=2.1)
        eye(m,h,5.1,.24); gill(m,h,3.5)
        # A long oval dorsal suction/docking disc and transverse lamellae.
        m.ellipsoid((0,.70,2.5),(.68,.14,2.35),'navy',12,32)
        for i in range(13):
            z=.5+i*.31; w=.53*math.sqrt(max(.08,1-((z-2.5)/2.2)**2))
            m.tube([(-w,.84,z),(0,.91,z+.02),(w,.84,z)],.043,'silver',8)
        cockpit(m,h,4.8,5.55,.26)
    elif s=='moray':
        eye(m,h,4.85,.30); gill(m,h,3.25); cockpit(m,h,3.3,4.45,.28)
        # One centered ribbon, with shared stations and closed edges instead of
        # overlapping offset patches. Keep the long eel profile on a straight keel.
        stations=[]; crest=[]
        for i in range(57):
            t=i/56; p=h.point(-7.6+11.2*t,0)
            height=.12+.36*math.sin(math.pi*t)**.45
            stations.append([add(p,(-.0275,-.015,0)),add(p,(.0275,-.015,0)),
                             add(p,(.0275,height,0)),add(p,(-.0275,height,0))])
            crest.append(add(p,(0,height,0)))
        for a,b in zip(stations,stations[1:]):
            for j,n in enumerate(((0,-1,0),(1,0,0),(0,1,0),(-1,0,0))):
                k=(j+1)%4; m.face([a[j],a[k],b[k],b[j]],'fin',n)
        m.face(stations[0],'fin',(0,0,-1));m.face(stations[-1],'fin',(0,0,1))
        m.tube(crest,.032,'edge',8)
        # Mirror the mouth trim explicitly as well: transporting a tube around
        # the full jaw can give its end rings slightly different orientations.
        start,first_index=len(m.p),len(m.idx)
        m.tube([(0,-.38,6.14),(.72,-.27,5.35)],.055,'dark',8)
        end=len(m.p)
        for p,n,uv in zip(m.p[start:end],m.n[start:end],m.uv[start:end]):
            m.vertex((-p[0],p[1],p[2]),(-n[0],n[1],n[2]),uv)
        for j in range(first_index,len(m.idx),3):
            a,b,c=m.idx[j:j+3];m.idx.extend((a+end-start,c+end-start,b+end-start))
    elif s=='lionfish':
        fork(m,root=-5.3,length=2.1,height=1.6); eye(m,h,4.7,.34); gill(m,h,3.0)
        cockpit(m,h,3.3,4.6,.3)
        # Radiating fan armor made from distinct fin rays, not generic wings.
        for sign in (-1,1):
            for i in range(8):
                t=i/7; z=2.4-6.3*t; x=2.4+2.1*math.sin(math.pi*t)
                fin(m,[(1.1,2.5),(x,z+.23),(x+.10,z-.10),(.8,.35)],.09,'fin_light' if i%2 else 'fin',True,sign,y=-.10-i*.025)
                m.tube([(sign*1.15,-.02,2.4),(sign*x,-.08-i*.025,z)],.035,'brass',6)
        for i in range(8):
            z=2.3-i*.68; base=h.point(z,0)
            m.tube([base,add(base,(0,1.10+.38*math.sin(i),-.34))],.055,'fin_light',8)
    elif s=='marlin':
        fork(m,root=-5.3,length=2.3,height=2.3); pectorals(m,1.0,3.0,z=2.7,length=3.6)
        dorsal(m,h,z=1.9,height=1.6,length=4.5); eye(m,h,4.9,.22); gill(m,h,3.6)
        cockpit(m,h,3.2,4.45,.26)
        m.lathe((0,.04,5.7),(0,0,1),[(0,.15),(1.3,.10),(3.55,.012)],['edge','silver'],20)
    elif s=='manta_ray':
        for sign in (-1,1):
            # Long swept pectoral discs, layered bevels, curved leading edges.
            fin(m,[(1.0,3.9),(3.6,2.5),(7.2,-.75),(6.3,-2.2),(2.0,-3.55),(.8,-1.2)],.35,'fin',True,sign)
            m.tube([(sign*1.4,.18,3.5),(sign*3.65,.15,2.3),(sign*6.7,.04,-.85)],.045,'edge',8)
            # Cephalic lobes remain separate, framing the central mouth.
            m.tube([(sign*1.35,.12,4.1),(sign*1.25,.15,5.1),(sign*.85,.18,5.3)],.18,'silver',12)
            p=h.point(3.7,sign*1.1,.03)
            m.lathe(p,(sign*.8,.3,.3),[(0,.22),(.08,.25),(.10,.17)],['brass','glass'],28)
        tail=Hull([(-9.0,.025,.035),(-7,.08,.09),(-5.7,.14,.13),(-4.3,.27,.17)])
        tail.build(m,28,16,'edge'); cockpit(m,h,2.2,3.6,.31)
        m.tube([(-.7,-.05,4.75),(0,-.1,4.92),(.7,-.05,4.75)],.042,'dark',8)
    elif s=='tiger_shark':
        fork(m,height=2.25,shark=True); pectorals(m,1.35,3.15,z=2.4,length=3.4)
        dorsal(m,h,z=1.3,height=1.9,length=2.7); dorsal(m,h,z=-3.1,height=.55,length=1.5)
        eye(m,h,4.95,.25); gill(m,h,3.55,True); cockpit(m,h,3.45,4.7,.27)
        m.tube([(-.70,-.43,5.38),(0,-.64,6.04),(.70,-.43,5.38)],.040,'dark',8)
    elif s=='hammerhead':
        fork(m,height=2.0,shark=True); pectorals(m,.95,2.75,z=2.3,length=3.4)
        dorsal(m,h,z=.8,height=1.6,length=2.8); gill(m,h,3.45,True); cockpit(m,h,2.4,3.7,.26)
        m.ellipsoid((0,.12,5.15),(3.1,.47,.84),'silver',16,40)
        m.tube([(-2.9,.24,5.42),(-1.9,.43,5.62),(0,.48,5.51),(1.9,.43,5.62),(2.9,.24,5.42)],.042,'edge',8)
        for sign in (-1,1):
            m.lathe((sign*2.97,.16,5.18),(sign,0,.1),[(0,.30),(.12,.29),(.15,.21)],['edge','glass'],32)
            m.ellipsoid((sign*3.1,.18,5.23),(.035,.10,.10),'cyan',8,16)

    role_details(m,h,ship.role)
    # Restrained lateral machinery line ties the otherwise distinct species together.
    if s not in ('manta_ray','lionfish','anglerfish'):
        for sign in (-1,1):
            zs=[-3.8+i*.55 for i in range(12)]
            m.tube([h.point(z,sign*1.25,.045) for z in zs],.020,'edge',6)
    return m
