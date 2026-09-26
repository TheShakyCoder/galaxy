"""Twelve original Swarm birds with species-specific wings, heads and tails."""
import math
from .geometry import Mesh,Hull,cockpit,role_details,add,sub,mul,cross,unit

# Each wing station is span, leading Z, trailing Z, dihedral Y.
WINGS={
 'hummingbird':[(.8,1.3,-1.3,.12),(2.6,1.65,-.65,.3),(5.5,.30,-.85,.1),(6.7,-.90,-1.15,-.12)],
 'oxpecker':[(.95,1.0,-2.0,.12),(2.4,.8,-2.7,.27),(3.9,-.05,-2.3,.12),(4.55,-1,-1.35,0)],
 'shrike':[(1,1.3,-1.8,.16),(2.9,.85,-2.8,.25),(4.75,-.15,-2.8,.12),(5.2,-1.25,-1.6,0)],
 'kingfisher':[(1,1.2,-1.6,.2),(2.5,.8,-2.4,.38),(4.4,-.2,-2.2,.15),(4.8,-1.0,-1.3,0)],
 'falcon':[(.95,1.8,-1.8,.15),(2.8,1.45,-2.5,.34),(5.5,-.65,-3.3,.2),(6.9,-2.8,-3.10,0)],
 'egret':[(.9,1.2,-2,.18),(3.0,1.2,-3,.48),(5.5,.4,-3.2,.3),(6.45,-1.1,-1.5,.15)],
 'goshawk':[(1.1,1.4,-2.5,.16),(3.1,1.4,-3.2,.4),(5.2,.65,-3.4,.3),(6.1,-.7,-1.3,.15)],
 'osprey':[(1.1,1.4,-1.9,.1),(3.1,2.3,-1.4,.55),(4.4,1.6,-2.1,.20),(6.6,-.6,-1.1,-.35)],
 'frigatebird':[(.85,1.3,-1.7,.12),(3.2,2.0,-1.2,.4),(6.2,.55,-1.45,.1),(9.1,-1.45,-1.72,-.15)],
 'pelican':[(1.4,1.5,-2.6,.1),(3.4,1.9,-3.5,.35),(6.3,.65,-3.8,.2),(7.4,-1.2,-1.7,-.1)],
 'golden_eagle':[(1.35,1.7,-2.5,.12),(3.5,1.9,-3.3,.42),(6.4,.8,-3.7,.32),(7.5,-.85,-1.35,.15)],
 'harpy_eagle':[(1.5,1.6,-2.9,.15),(3.5,1.6,-3.8,.40),(5.8,.85,-4,.24),(6.9,-.9,-1.4,.1)],
}


def wing_section(stations,x):
    i=next((j for j in range(len(stations)-1) if x<=stations[j+1][0]),len(stations)-2)
    a,b=stations[i:i+2]; t=max(0,min(1,(x-a[0])/(b[0]-a[0])))
    return tuple(a[k]+(b[k]-a[k])*t for k in range(1,4))


def wings(m):
    s=m.ship.slug; stations=WINGS[s]; x0=stations[0][0]; x1=stations[-1][0]
    feathered=s not in ('hummingbird','falcon','frigatebird')
    for sign in (-1,1):
        # Solid aerodynamic wing skin, not zero-thickness triangles.
        def point(x,t,side):
            lead,trail,y=wing_section(stations,x)
            camber=.16*math.sin(math.pi*t)*(1-(x-x0)/(x1-x0)*.65)
            return (sign*x,y+side*(.025+camber),lead+(trail-lead)*t)
        for side in (-1,1):
            for i in range(28):
                a=x0+(x1-x0)*i/28; b=x0+(x1-x0)*(i+1)/28
                for j in range(5):
                    t=j/5; u=(j+1)/5
                    points=[point(a,t,side),point(b,t,side),point(b,u,side),point(a,u,side)]
                    color='blue' if j<2 else ('edge' if j==2 else 'fin')
                    if m.ship.slug in ('egret','pelican') and j<3: color='pearl'
                    m.face(points,color,(0,side,0))
            for edge_t in (0,1):
                for i in range(28):
                    a=x0+(x1-x0)*i/28; b=x0+(x1-x0)*(i+1)/28
                    if side==1:
                        m.face([point(a,edge_t,1),point(b,edge_t,1),point(b,edge_t,-1),point(a,edge_t,-1)],'navy',(0,0,1 if edge_t==0 else -1))
        for x,direction in ((x0,-sign),(x1,sign)):
            for j in range(5):
                t=j/5; u=(j+1)/5
                m.face([point(x,t,1),point(x,u,1),point(x,u,-1),point(x,t,-1)],'edge',(direction,0,0))
        # Individually beveled primary feather plates along the trailing edge.
        count=12 if feathered else 9
        for i in range(count):
            x=x0+.35+(x1-x0-.85)*i/(count-1)
            lead,trail,y=wing_section(stations,x)
            t=(x-x0)/(x1-x0)
            length=(1.05 if feathered else .6)*(.6+.6*t)
            half=(x1-x0)/count*.48
            # Spread the outer primaries into separated fingers for eagles.
            sweep=.30 if feathered else .48
            outline=[(x-half,trail+.65),(x+half,trail+.55),(x+half+sweep,trail-length+.22),(x+sweep,trail-length),(x-half+sweep,trail-length+.17)]
            start=len(m.p)
            color='fin_light' if i%3==0 else 'fin'
            if s=='golden_eagle' and i<4: color='brass'
            if s in ('egret','pelican'): color='pearl' if i%3 else 'edge'
            m.fin(outline,.13,color,axis='y',sign=sign)
            m.transform_part(start,lambda p,y=y:add(p,(0,y+.015,0)))
        # Shared precision trim, navigation lights and shoulder panel seams.
        for t in (.13,.48):
            points=[point(x0+(x1-x0)*i/20,t,1) for i in range(21)]
            m.tube([add(p,(0,.025,0)) for p in points],.022,'edge',6)
        tip=point(x1-.18,.40,1)
        m.ellipsoid(add(tip,(0,.08,0)),(.12,.045,.16),'cyan',6,12)


def tail(m):
    s=m.ship.slug
    if s=='frigatebird':
        for sign in (-1,1):
            m.fin([(.06,-3.5),(.75,-4.0),(2.3,-7.5),(2.25,-8.0),(.12,-5.4)],.17,'navy',axis='y',sign=sign)
    else:
        length=3.4 if s in ('shrike','goshawk') else 2.5
        width=1.1 if s in ('hummingbird','falcon') else 1.8
        for i in range(7):
            x=(i-3)*width/4
            end=-3.7-length+abs(i-3)*.15
            # Keep individual feather surfaces separated: overlapping coplanar
            # plates produce flicker in game and dark interference in renders.
            half=width/8*.87
            m.fin([(x-half,-3.25),(x+half,-3.25),(x+half,end+.20),(x,end),(x-half,end+.2)],.11,'fin_light' if i%3==0 else 'fin',axis='y')
        if s=='goshawk':
            for z in (-4.5,-5.1,-5.7): m.tube([(-.95,.08,z),(0,.08,z),(.95,.08,z)],.065,'navy',8)


def build(ship):
    m=Mesh(ship); s=ship.slug
    w=1.35 if s in ('pelican','golden_eagle','harpy_eagle','goshawk') else 1.05
    height=1.05 if s not in ('hummingbird','frigatebird') else .78
    if s=='egret':
        h=Hull([(-4.6,.2,.2),(-3.2,.60,.55),(-1,1.05,.90),(1,1.0,1.0),
                (2.5,.53,.60,.48),(3.5,.35,.38,1.13),(4.4,.59,.61,1.40),(5.1,.40,.34,1.40),(5.5,.16,.16,1.22)])
    elif s=='pelican':
        h=Hull([(-4.8,.3,.28),(-3,.85,.7),(-1,1.50,1.16),(1,1.45,1.2),
                (2.5,.80,.84,.30),(3.5,.68,.83,.72),(4.8,.72,.75,.85),(5.5,.27,.27,.6)])
    else:
        h=Hull([(-4.6,.22,.2),(-3,.55,height*.5),(-1,w,height),(1,w*1.06,height*1.05),
                (2.4,w*.67,height*.77,.12),(3.25,w*.60,.69,.38),(4.0,w*.65,.71,.48),(4.65,.38,.35,.35),(4.9,.13,.14,.25)])
    h.build(m,52,40); wings(m); tail(m)
    m.features.append(ship.identity)
    # Bird eyes are inset oval optical housings with an outer armored brow.
    z=4.47 if s in ('egret','pelican') else 3.91
    for sign in (-1,1):
        a=sign*1.18; p=h.point(z,a,.02); n=h.normal(z,a)
        m.lathe(p,n,[(0,.27),(.055,.29),(.105,.22)],['navy','edge'],28)
        m.lathe(add(p,mul(n,.11)),n,[(0,.20),(.03,.13)],['cyan'],28)
        if s in ('shrike','falcon','osprey','goshawk'):
            m.tube([h.point(z+.40,sign*1.06,.055),h.point(z,sign*1.02,.09),h.point(z-.60,sign*1.06,.045)],.09,'navy',8)
        if s=='goshawk':
            m.tube([h.point(z+.28,sign*.88,.05),h.point(z-.12,sign*.85,.08),h.point(z-.52,sign*.90,.05)],.045,'pearl',8)

    # Distinct bills: fine needles, kingfisher spear, pelican pouch, raptor hook.
    start=h.z1-.15; y=h.section(start)[2]
    if s in ('hummingbird','kingfisher','egret'):
        length={'hummingbird':2.65,'kingfisher':2.15,'egret':2.15}[s]
        radius=.12 if s=='hummingbird' else .25
        m.lathe((0,y,start),(0,0,1),[(0,radius),(.40,radius*.8),(length,.012)],['edge','brass' if s=='egret' else 'navy'],20)
    elif s=='pelican':
        bill=Hull([(start,.30,.18,y),(start+.4,.47,.19,y),(start+2.7,.24,.13,y-.06),(start+3.1,.05,.05,y-.12)])
        bill.build(m,22,20,'brass')
        m.ellipsoid((0,y-.43,start+1.04),(.43,.59,1.5),'panel',14,28)
        m.tube([(-.38,y-.12,start+.1),(0,y-.93,start+1.15),(.38,y-.12,start+.1)],.05,'edge',8)
    else:
        color='cyan' if s=='oxpecker' else 'brass'
        # A solid curved beak built as a small asymmetric loft.
        bill=Hull([(start,.22,.22,y),(start+.4,.27,.25,y-.02),(start+.72,.17,.29,y-.19),(start+.92,.04,.09,y-.42)])
        bill.build(m,16,20,color)
        m.tube([(-.20,y-.12,start+.1),(0,y-.2,start+.72),(.20,y-.12,start+.1)],.022,'dark',6)

    if s in ('hummingbird','frigatebird'):
        m.ellipsoid((0,-.55,2.65),(.60,.29,.86),'cyan',12,28)
    if s=='kingfisher':
        for i in range(5):
            x=(i-2)*.14
            start_v=len(m.p)
            m.fin([(1.02,3.9),(1.68,3.22),(1.36,2.52),(.68,3.1)],.10,'blue',axis='x')
            m.transform_part(start_v,lambda p,x=x:add(p,(x,0,0)))
    if s=='harpy_eagle':
        for sign in (-1,1):
            for i in range(3):
                p=(sign*(.25+i*.18),1.00,3.6)
                m.tube([p,(sign*(.65+i*.21),1.9-i*.08,3.05-i*.14)],.095,'pearl',8)
    if s=='golden_eagle':
        for i in range(5):
            z=2.65+i*.23
            m.tube([h.point(z,-.6,.04),h.point(z,0,.06),h.point(z,.6,.04)],.055,'brass',8)
    if s=='egret':
        # Slender trailing landing booms echo an egret's long legs.
        for sign in (-1,1):
            m.tube([(sign*.43,-.6,-2.1),(sign*.5,-.75,-4.7),(sign*.56,-.65,-6.8)],.055,'navy',8)
    cockpit(m,h,.9,2.15,.34)
    role_details(m,h,ship.role)
    return m
