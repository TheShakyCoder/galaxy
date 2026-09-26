"""Abyssal sensory organs and Crystalborn faceted growths."""
import math
from .attachments import Rig,add,mul,unit


def detail(m,key):
    r=Rig(m);bird=m.ship.faction=='swarm'
    if key=='abyssal':
        for sign in (-1,1):
            chain=[]
            for i in range(13):
                t=.24+i*.039;p,n=r.anchor(t,sign*1.45,.025)
                chain.append(p)
                r.ball(add(p,mul(n,.045*r.scale)),.055+.015*math.sin(i*.65),'cyan',4,8)
            r.pipe(chain,.018,'teal',6)
            for i in range(3):
                p,n=r.anchor(.30+i*.09,sign*.80,.03)
                tip=r.move(p,(sign*(.25+i*.06),.36+i*.07,-.42))
                r.pipe([p,r.move(p,(sign*.20,.21,-.12)),tip],.018,'edge',6)
                r.ball(tip,.064,'white',4,8)
            if bird:
                for i in range(9):
                    p=r.wing(sign,.16+i*.085,.64,.11)
                    r.ball(p,.055,'cyan',4,8)
                r.pipe([r.wing(sign,.14+i*.08,.64,.09) for i in range(10)],.014,'teal',6)
            else:
                # Short paired barbels sweep aft, keeping jaws, lure and bill clear.
                p,n=r.anchor(.76,sign*1.87,.02)
                r.pipe([p,r.move(p,(sign*.20,-.20,-.20)),r.move(p,(sign*.33,-.27,-.80))],.018,'teal',6)
        return ['Paired bright photophore chains fitted to the actual hull',
                'Pearl-tipped sensory tendrils sweep away from the species head',
                'Wing light chains' if bird else 'Short swept sensory barbels',
                'Opaque painted and pearl-like accents; no emission or transparency shader']
    for sign in (-1,1):
        for i in range(5):
            p,n=r.anchor(.25+i*.085,sign*.68,.005)
            direction=unit(add(n,(sign*.22,.36,-.27)))
            r.crystal(p,direction,.23+.055*math.sin(i),.90+.32*math.sin(i*.8),'cyan')
            q=r.move(p,(sign*.24,0,-.18));r.crystal(q,unit(add(n,(sign*.6,.1,-.4))),.13,.50,'teal',5)
        if bird:
            for i in range(5):
                p=r.wing(sign,.17+i*.13,.42,.03)
                r.crystal(p,unit((sign*.25,1,-.28)),.24,.74+.23*math.sin(i),'cyan')
        else:
            for i in range(4):
                p,n=r.anchor(.33+i*.09,sign*1.85,.015)
                r.crystal(p,unit(add(n,(0,.05,-.3))),.12,.36,'teal',5)
    return ['True flat-shaded hexagonal and pentagonal crystal prisms',
            'Paired mineral growths follow the body and preserve the original head',
            'Wing geodes' if bird else 'Small flank geodes',
            'Opaque faceted quartz treatment; no refractive/transparency shader']
