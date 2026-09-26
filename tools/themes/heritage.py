"""Nautical Corsairs and species-specific living Overgrown hulls."""
import math
from .attachments import Rig,add,mul,unit


def rope(r,points):
    # Two interwoven strands, authored in body units, with a stable world frame.
    # Hull anchors snap to loft rings: remove repeats before braiding so a
    # strand cannot fold back on itself where two samples hit the same ring.
    points=[p for i,p in enumerate(points) if i==0 or sum((a-b)**2 for a,b in zip(p,points[i-1]))>1e-10]
    for phase in (0,math.pi):
        strand=[]
        for i,p in enumerate(points):
            strand.append(r.move(p,(math.cos(i*.90+phase)*.016,math.sin(i*.90+phase)*.016,0)))
        r.pipe(strand,.022,'fin_light',6)


def blossom(r,p,normal,size=.14):
    u,v=r.basis(normal)
    for j in range(5):
        radial=add(mul(u,math.cos(j*math.tau/5)),mul(v,math.sin(j*math.tau/5)))
        q=add(p,mul(radial,size*.65*r.scale));r.ball(q,size*.46,'cyan',4,8)
    r.ball(add(p,mul(normal,size*.2*r.scale)),size*.29,'brass',4,8)


def detail(m,key):
    r=Rig(m);bird=m.ship.faction=='swarm'
    if key=='corsair':
        shape='circle' if bird else 'triangle'
        for sign in (-1,1):
            for t in (.36,.49):
                p,n=r.anchor(t,sign*1.72,.035)
                axis=unit((sign*.95,.06,.28))
                r.cyl(p,axis,[(0,.19),(.17,.22),(.24,.16),(.67,.14),(.74,.19),(.79,.19)],['navy','brass','navy','edge','brass'],20)
                r.cyl(add(p,mul(axis,.795*r.scale)),axis,[(0,.12),(.009,.115)],['dark'],16)
            for t in (.40,.52,.64):
                p,n=r.anchor(t,sign*.94,.03)
                r.cyl(p,n,[(0,.145),(.055,.17),(.08,.115)],['brass','brass'],20)
                r.cyl(add(p,mul(n,.085*r.scale)),n,[(0,.105),(.008,.10)],['glass'],16)
            line=[r.anchor(.23+i*.016,sign*1.21,.065)[0] for i in range(34)]
            rope(r,line)
            if bird:
                # Rope lies on the wing above its authored canvas panel.
                line=[r.wing(sign,.12+i*.021,.18,.105) for i in range(37)];rope(r,line)
                r.badge(r.wing(sign,.51,.57,.20),(0,1,0),shape,.52)
            else:
                p,n=r.anchor(.67,sign*1.22,.035);r.badge(p,n,shape,.46)
        # Two restrained wooden spars/hoops around the aft hull.
        for t in (.27,.56):
            pts=[r.anchor(t,math.tau*i/40,.024)[0] for i in range(41)]
            r.pipe(pts,.035,'brass',6)
        return ['Timber-patterned plating and canvas decorative panels',
                'Four broadside cannon housings with recessed dark muzzle faces',
                'Braided rope rails and brass-rimmed portholes',
                shape.title()+' faction insignias in texture and raised geometry',
                'Circle marks on both wings' if bird else 'Triangle marks on both forward flanks']
    for sign in (-1,1):
        path=[r.anchor(.25+i*.023,sign*(.75+.12*math.sin(i*.55)),.055)[0] for i in range(24)]
        r.pipe(path,.037,'fin',8)
        if bird:
            for i in range(8):
                p,n=r.anchor(.29+i*.056,sign*.75,.08)
                r.leaf(p,unit((sign*(.65 if i%2 else -.2),.20,-.25)),.60,.23,'fin_light')
                if i in (1,4,6):blossom(r,add(p,mul(n,.08*r.scale)),n,.19)
            for i in range(7):
                p=r.wing(sign,.16+i*.105,.40,.12)
                r.leaf(p,unit((sign*.7,.12,-.2)),.72,.25,'fin_light')
                if i in (1,4):blossom(r,r.move(p,(0,.09,0)),(0,1,0),.23)
            r.pipe([r.wing(sign,.15+i*.026,.40,.10) for i in range(28)],.028,'fin',6)
        else:
            for i in range(4):
                p,n=r.anchor(.31+i*.085,sign*.73,.01)
                # Branching coral fans, not trees pasted onto fish.
                stem=[p,r.move(p,(sign*.07,.19,-.07)),r.move(p,(sign*.13,.39,-.12))]
                r.pipe(stem,.046,'pearl',8)
                for j in (-1,1):
                    end=r.move(stem[1],(sign*.10+j*.13,.29,-.11))
                    r.pipe([stem[1],end],.034,'cyan',8);r.ball(end,.045,'cyan',4,8)
                r.ball(stem[-1],.05,'pearl',4,8)
            for i in range(9):
                p,n=r.anchor(.29+i*.043,sign*1.52,.008)
                r.cyl(p,n,[(0,.10),(.075,.082),(.09,.05)],['edge','pearl'],10)
                r.cyl(add(p,mul(n,.092*r.scale)),n,[(0,.04),(.006,.035)],['dark'],8)
    return ['Original animal hull stays visible beneath living surface detail',
            'Swept climbing vines follow the body and wing panels' if bird else 'Paired branching coral gardens follow the fish shoulders',
            'Raised leaves and five-petal blossoms' if bird else 'Raised barnacle colonies with recessed openings',
            'Moss-patterned enamel and restrained warm organic accents']
