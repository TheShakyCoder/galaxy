"""Surface-fitted original geometry helpers; dimensions use body-relative units."""
import math
from fleet.geometry import add,sub,mul,unit,cross


class Rig:
    def __init__(self,m):
        self.m=m;self.ship=m.ship
        self.hull=[(p,n,uv) for p,n,uv in zip(m.p,m.n,m.uv) if uv[0]<.75]
        self.z0=min(p[2] for p,_,_ in self.hull);self.z1=max(p[2] for p,_,_ in self.hull)
        self.scale=(self.z1-self.z0)/12

    def anchor(self,t,a,lift=0):
        z=self.z0+(self.z1-self.z0)*t; near=min(abs(p[2]-z) for p,_,_ in self.hull)
        ring=[r for r in self.hull if abs(r[0][2]-z)<near+1e-5];v=a/math.tau%1
        p,n,_=min(ring,key=lambda r:min(abs(r[2][1]-v),1-abs(r[2][1]-v)))
        return add(p,mul(n,lift*self.scale)),n

    def move(self,p,delta):return add(p,mul(delta,self.scale))
    def cyl(self,p,n,rings,colors,sides=20):self.m.lathe(p,n,[(d*self.scale,r*self.scale) for d,r in rings],colors,sides)
    def pipe(self,points,r=.035,color='edge',sides=8):self.m.tube(points,r*self.scale,color,sides)
    def ball(self,p,r,color='cyan',rings=5,sides=10):self.m.ellipsoid(p,(r*self.scale,)*3,color,rings,sides)

    def wing(self,sign,fraction,chord=.4,lift=.10):
        from fleet.birds import WINGS,wing_section
        stations=WINGS[self.ship.slug];x=stations[0][0]+fraction*(stations[-1][0]-stations[0][0])
        lead,trail,y=wing_section(stations,x)
        source_length={'egret':10.1,'pelican':10.3}.get(self.ship.slug,9.5)
        scale=(self.z1-self.z0)/source_length
        return (sign*x*scale,(y+lift)*scale,(lead+(trail-lead)*chord)*scale)

    @staticmethod
    def basis(n):
        n=unit(n);u=unit(cross(n,(0,1,0) if abs(n[1])<.9 else (1,0,0)));return u,cross(n,u)

    def crystal(self,p,n,r=.18,length=.65,color='cyan',sides=6):
        n=unit(n);u,v=self.basis(n);rings=[]
        for distance,radius in [(0,r*.72),(length*.65,r)]:
            rings.append([add(add(p,mul(n,distance*self.scale)),mul(add(mul(u,math.cos(i*math.tau/sides)),mul(v,math.sin(i*math.tau/sides))),radius*self.scale)) for i in range(sides)])
        tip=add(p,mul(n,length*self.scale))
        self.m.face(rings[0],color,mul(n,-1))
        for i in range(sides):
            j=(i+1)%sides;radial=add(mul(u,math.cos((i+.5)*math.tau/sides)),mul(v,math.sin((i+.5)*math.tau/sides)))
            shade=[color,'fin_light','teal','white','silver','edge'][i%6]
            q=[rings[0][i],rings[0][j],rings[1][j],rings[1][i]]
            normal=cross(sub(q[1],q[0]),sub(q[2],q[0]))
            if sum(a*b for a,b in zip(normal,radial))<0:normal=mul(normal,-1)
            self.m.face(q,shade,normal)
            normal=cross(sub(rings[1][j],rings[1][i]),sub(tip,rings[1][i]))
            if sum(a*b for a,b in zip(normal,radial))<0:normal=mul(normal,-1)
            self.m.face([rings[1][i],rings[1][j],tip],shade,normal)

    def leaf(self,p,direction,length=.45,width=.13,color='fin_light'):
        direction=unit(direction);u,v=self.basis(direction)
        tip=add(p,mul(direction,length*self.scale));middle=add(p,mul(direction,length*.47*self.scale))
        left=add(middle,mul(u,width*self.scale));right=add(middle,mul(u,-width*self.scale))
        ridge=add(middle,mul(v,.05*self.scale))
        for q in ([p,left,ridge],[left,tip,ridge],[tip,right,ridge],[right,p,ridge]):
            normal=cross(sub(q[1],q[0]),sub(q[2],q[0]));self.m.face(q,color,normal)
        self.m.face([p,right,tip,left],color,mul(v,-1))

    def badge(self,p,n,shape,r=.38):
        # Dark mounting plate, cream insignia and a gold inset edge; triangle and
        # circle are geometrically distinct, not merely described in metadata.
        u,v=self.basis(n);center=add(p,mul(n,.052*self.scale))
        if shape=='triangle':
            outer=[add(p,mul(add(mul(u,math.sin(a)),mul(v,math.cos(a))),r*1.2*self.scale)) for a in (0,math.tau/3,2*math.tau/3)]
            self.m.face(outer,'navy',n)
            pts=[add(center,mul(add(mul(u,math.sin(a)),mul(v,math.cos(a))),r*self.scale)) for a in (0,math.tau/3,2*math.tau/3)]
            self.m.face(pts,'pearl',n)
            self.pipe(pts+[pts[0]],.024,'brass',6)
        else:
            self.cyl(p,n,[(0,r*1.17),(.045,r*1.17)],['navy'],24)
            self.cyl(center,n,[(0,r),(.018,r)],['pearl'],32)
            q=add(center,mul(n,.022*self.scale))
            self.cyl(q,n,[(0,r*.60),(.008,r*.60)],['navy'],28)
