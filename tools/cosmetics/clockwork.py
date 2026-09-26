"""Add real, static clockwork machinery without replacing the species hull.

All original vertices/triangles are retained at their exact world coordinates.
Mounts are sampled from the body UV surface, so machinery follows narrow eels,
deep fish, rays and birds instead of floating at a universal attachment point.
"""
import math
from fleet.geometry import add, sub, mul, unit, cross


def detail(m):
    hull=[(p,n,uv) for p,n,uv in zip(m.p,m.n,m.uv) if uv[0]<.75]
    z0=min(p[2] for p,_,_ in hull); z1=max(p[2] for p,_,_ in hull)
    scale=(z1-z0)/12
    def anchor(t,a,lift=0):
        z=z0+(z1-z0)*t
        near=min(abs(p[2]-z) for p,_,_ in hull)
        ring=[(p,n,uv) for p,n,uv in hull if abs(p[2]-z)<=near+1e-5]
        v=(a/math.tau)%1
        p,n,_=min(ring,key=lambda r:min(abs(r[2][1]-v),1-abs(r[2][1]-v)))
        return add(p,mul(n,lift*scale)),n
    def cyl(p,axis,rings,colors,sides=20):
        m.lathe(p,axis,[(d*scale,r*scale) for d,r in rings],colors,sides)
    def pipe(points,r=.055,color='edge',sides=8):
        m.tube(points,r*scale,color,sides)
    def ball(p,r,color='brass'):
        m.ellipsoid(p,(r*scale,)*3,color,6,10)
    def basis(n):
        u=unit(cross(n,(0,1,0) if abs(n[1])<.9 else (1,0,0)))
        return u,cross(n,u)
    def gear(p,n,r=.42,teeth=12):
        # A visible ring with actual raised teeth and an inset hub.
        u,v=basis(n)
        cyl(p,n,[(0,r*.76),(.09,r*.76),(.12,r*.58)],['brass','edge'],24)
        cyl(add(p,mul(n,.13*scale)),n,[(0,r*.31),(.09,r*.23)],['dark'],16)
        for i in range(teeth):
            a=math.tau*i/teeth
            points=[]
            for rad,da in [(r*.69,-.075),(r,-.075),(r,.075),(r*.69,.075)]:
                points.append(add(p,mul(add(mul(u,math.cos(a+da)),mul(v,math.sin(a+da))),rad*scale)))
            top=[add(q,mul(n,.12*scale)) for q in points]
            m.face(top,'brass',n)
            for j in range(4):
                k=(j+1)%4
                # Inner tooth wall faces the hub; other walls use edge normal.
                out=cross(sub(points[k],points[j]),n)
                m.face([points[j],points[k],top[k],top[j]],'edge',out)
        # Three radial spokes read as a wheel instead of a solid brass medallion.
        face=add(p,mul(n,.135*scale))
        for a in (0,math.tau/3,2*math.tau/3):
            radial=add(mul(u,math.cos(a)),mul(v,math.sin(a)))
            pipe([add(face,mul(radial,r*.29*scale)),add(face,mul(radial,r*.60*scale))],.026,'brass',6)
    def gauge(p,n):
        cyl(p,n,[(0,.24),(.08,.28),(.12,.22)],['edge','brass'],24)
        q=add(p,mul(n,.126*scale))
        cyl(q,n,[(0,.215),(.012,.205)],['pearl'],24)
        u,v=basis(n); face=add(q,mul(n,.017*scale))
        for i in range(9):
            a=math.radians(-125+250*i/8)
            radial=add(mul(u,math.sin(a)),mul(v,math.cos(a)))
            pipe([add(face,mul(radial,.16*scale)),add(face,mul(radial,.19*scale))],.007,'dark',5)
        pipe([face,add(face,mul(add(mul(u,-.6),mul(v,.8)),.15*scale))],.012,'navy',6)
        ball(add(face,mul(n,.01*scale)),.028,'edge')

    features=['Original species hull, fins, beak, tail and optical hardware retained',
              'Paired copper pressure vessels with brass straps and riveted end caps',
              'Raised pipework, toothed drive wheels and analog pressure gauges']
    bird=m.ship.faction=='swarm'
    # Side vessels avoid crests/lures/dorsal fins and preserve the head profile.
    for sign in (-1,1):
        a=sign*(.98 if bird else 1.27)
        mount,n=anchor(.46,a,.15)
        center=add(mount,mul(n,.12*scale))
        # Vessel is embedded slightly in the surface for a grounded saddle mount.
        start=add(center,(0,0,-.77*scale))
        cyl(start,(0,0,1),[(0,.20),(.13,.33),(1.4,.33),(1.54,.20)],['brass','edge','brass'],24)
        for dz in (-.55,.55):
            cyl(add(center,(0,0,dz*scale)),(0,0,1),[(0,.355),(.09,.355)],['brass'],24)
        for dz in (-.81,.81):
            face=add(center,(0,0,dz*scale))
            for i in range(8):
                a2=math.tau*i/8
                ball(add(face,(math.cos(a2)*.19*scale,math.sin(a2)*.19*scale,0)),.031)
        p1,_=anchor(.29,a,.20); p2,_=anchor(.38,a,.29)
        p3,_=anchor(.58,a,.29); p4,_=anchor(.69,a,.11)
        pipe([p1,p2,add(center,mul(n,.36*scale)),p3,p4],.06)
        # Raised gauge and gear on the exposed side of the vessel.
        gauge(add(center,add(mul(n,.33*scale),(0,0,.37*scale))),n)
        wheel=add(center,add(mul(n,.35*scale),(0,0,-.37*scale)))
        gear(wheel,n,.30,10)
        # Bracket plates and rivets remain visibly connected to the body.
        for t in (.32,.63):
            p,normal=anchor(t,a,.015)
            cyl(p,normal,[(0,.22),(.06,.25),(.095,.18)],['navy','brass'],16)

    # A compact pressure chimney ahead of the tail, never over the animal's face.
    p,n=anchor(.25,0,.01)
    cyl(p,(0,1,0),[(0,.22),(.10,.26),(.17,.17),(.63,.17),(.70,.23),(.76,.23)],['brass','edge','edge','brass','brass'],20)
    cyl(add(p,(0,.765*scale,0)),(0,1,0),[(0,.17),(.01,.15)],['dark'],20)
    # Upper pressure-release handwheel, separate from the chimney.
    valve,n=anchor(.36,.45,.08)
    pipe([valve,add(valve,(0,.38*scale,0))],.045,'brass')
    gear(add(valve,(0,.38*scale,0)),(0,1,0),.23,8)

    if bird:
        from fleet.birds import WINGS, wing_section
        stations=WINGS[m.ship.slug]
        # Recover the source generator's uniform scale from body length.
        # Egret/pelican have different station ranges; the known loft endpoints
        # are read directly here rather than estimating from overall wingspan.
        original_length={'egret':10.1,'pelican':10.3}.get(m.ship.slug,9.5)
        wing_scale=(z1-z0)/original_length
        x=stations[1][0]
        lead,trail,y=wing_section(stations,x)
        for sign in (-1,1):
            joint=(sign*x*wing_scale,(y+.19)*wing_scale,(lead*.6+trail*.4)*wing_scale)
            gear(joint,(0,1,0),.42,12)
            p,_=anchor(.51,sign*.6,.09)
            # Double rods and a sleeved piston connect the real wing root joint.
            end=add(joint,(0,.16*scale,0)); direction=unit(sub(end,p)); distance=math.dist(p,end)
            pipe([p,end],.047,'brass')
            m.lathe(add(p,mul(direction,distance*.22)),direction,
                    [(0,.09*scale),(distance*.45,.09*scale)],['edge'],16)
            lead2,trail2,y2=wing_section(stations,x*.70+stations[-1][0]*.30)
            rib_end=(sign*(x*.70+stations[-1][0]*.30)*wing_scale,(y2+.10)*wing_scale,(lead2*.6+trail2*.4)*wing_scale)
            pipe([end,rib_end],.035,'brass')
        features.append('Articulated-looking wing-root gears and exposed brass piston linkages (static)')
    else:
        # A belt of small ribbed heat exchangers on both flanks, following the
        # actual body rather than a generic wing rig applied to every animal.
        for sign in (-1,1):
            for i in range(5):
                t=.39+i*.037
                p0,_=anchor(t,sign*1.90,.035); p1,_=anchor(t,sign*2.25,.065)
                pipe([p0,p1],.042,'brass')
        features.append('Contoured flank heat-exchanger ribs preserve the fish silhouette')
    features.append('Riveted texture plating, warm enamel optics and dark exhaust mouths')
    if len(m.p)>=65536: raise ValueError(m.ship.slug+': 16-bit vertex limit')
    return features
