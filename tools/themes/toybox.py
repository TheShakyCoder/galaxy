"""Painted tin wind-up animals, with static mechanical toy details."""
import math
from .attachments import Rig,add,mul


def detail(m,key):
    r=Rig(m);bird=m.ship.faction=='swarm'
    # A side-mounted key keeps the dorsal fin and bird head silhouettes clear.
    p,n=r.anchor(.42,1.02,.025)
    r.cyl(p,n,[(0,.24),(.12,.24),(.17,.15),(.70,.15)],['edge','pearl','brass'],20)
    center=add(p,mul(n,.75*r.scale));u,v=r.basis(n)
    for sign in (-1,1):
        c=add(center,mul(u,sign*.28*r.scale))
        points=[add(c,mul(add(mul(u,.32*math.cos(i*math.tau/28)),mul(v,.25*math.sin(i*math.tau/28))),r.scale)) for i in range(29)]
        r.pipe(points,.075,'brass',10)
    r.pipe([add(center,mul(u,-.28*r.scale)),add(center,mul(u,.28*r.scale))],.085,'brass',10)
    for sign in (-1,1):
        for t in (.29,.48,.64):
            p,n=r.anchor(t,sign*1.40,.025);u,v=r.basis(n)
            r.cyl(p,n,[(0,.155),(.065,.17),(.105,.14)],['pearl','edge'],16)
            c=add(p,mul(n,.109*r.scale))
            # Visible dark screwdriver slots on raised chunky fasteners.
            points=[add(add(c,mul(u,a*r.scale)),mul(v,b*r.scale)) for a,b in [(-.105,-.022),(.105,-.022),(.105,.022),(-.105,.022)]]
            m.face(points,'dark',n)
        p,n=r.anchor(.37,sign*1.83,.02)
        r.cyl(p,n,[(0,.15),(.30,.15),(.32,.30),(.47,.30),(.50,.22)],['brass','edge','cyan','pearl'],20)
        r.cyl(add(p,mul(n,.51*r.scale)),n,[(0,.075),(.04,.075)],['dark'],12)
        if bird:
            for t in (.22,.51,.77):
                p=r.wing(sign,t,.54,.12)
                r.cyl(p,(0,1,0),[(0,.10),(.055,.11),(.07,.085)],['edge','pearl'],12)
    for t in (.29,.59):
        r.pipe([r.anchor(t,math.tau*i/40,.023)[0] for i in range(41)],.035,'edge',6)
    return ['Painted tin panels with warm stripes and cream star motifs',
            'Raised double-loop wind-up key on a short shoulder spindle',
            'Chunky slotted fasteners and red rolled seams',
            'Paired decorative toy axles; all parts are static',
            'Wing-panel studs preserve the bird outline' if bird else 'Original fish fins and forked tails stay visible']
