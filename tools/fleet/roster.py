"""The 24 named faction skins already present in main/data/ships.lua.

Sizes are maximum dimensions in meters, not gameplay or module-slot values.
Patrol sizes are retained. Within each faction and role, Escort is 4x Patrol
and Frigate is 4x Escort (16x Patrol), with uniform scaling on all axes.
Advanced upgrade tiers share these models in the current game.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Ship:
    name: str
    slug: str
    faction: str
    size: str
    role: str
    extent: float
    back: tuple
    flank: tuple
    accent: tuple
    identity: str

    @property
    def chassis(self): return self.size+'_'+self.role
    @property
    def directory(self): return 'assets/models/'+self.chassis
    @property
    def model(self): return '/'+self.directory+'/'+('patrol_interceptor' if self.slug=='sardine' else self.slug)+'.model'
    @property
    def glb(self): return self.directory+'/'+self.slug+'.glb'
    @property
    def texture(self): return self.directory+'/'+self.slug+'_palette.png'


def fish(name,size,role,extent,back,flank,identity):
    return Ship(name,name.lower().replace(' ','_'),'accord',size,role,extent,back,flank,(106,218,222),identity)
def bird(name,size,role,extent,back,flank,accent,identity):
    return Ship(name,name.lower().replace(' ','_'),'swarm',size,role,extent,back,flank,accent,identity)


SHIPS=[
    fish('Sardine','patrol','interceptor',16.2,(25,69,89),(174,204,206),'Preserved approved model: silver flanks, round eyes, equal forked tail'),
    fish('Pilotfish','patrol','support',16,(29,68,85),(181,209,208),'Five dark body bands, streamlined body and service cradles'),
    fish('Piranha','patrol','assault',15,(61,89,99),(192,177,157),'Deep compressed body, blunt jaw, copper belly and armored bite'),
    fish('Anglerfish','patrol','tactical',17,(31,50,67),(116,150,160),'Round head, broad mouth and a luminous-tipped forward sensor lure'),
    fish('Barracuda','escort','interceptor',64.8,(27,69,88),(189,210,207),'Long narrow body, projecting lower jaw and two separate dorsal fins'),
    fish('Remora','escort','support',64,(40,66,76),(158,184,183),'Flattened head and long ribbed dorsal docking disc'),
    fish('Moray','escort','assault',60,(55,83,72),(180,194,149),'Straight symmetrical eel body, centered dorsal ribbon and heavy jaw'),
    fish('Lionfish','escort','tactical',68,(90,59,56),(213,191,161),'Striped body, radiating sensor spines and large fan-shaped pectorals'),
    fish('Marlin','frigate','interceptor',259.2,(24,64,96),(177,205,214),'Long spear bill, slender fast hull and crescent caudal fin'),
    fish('Manta Ray','frigate','support',256,(29,64,80),(186,209,207),'Broad swept ray disc, paired cephalic lobes and slender trailing tail'),
    fish('Tiger Shark','frigate','assault',240,(57,82,87),(188,204,195),'Heavy blunt shark head, dark flank bars and asymmetric caudal lobes'),
    fish('Hammerhead','frigate','tactical',272,(45,86,97),(177,206,207),'Broad transverse hammer head with sensors at both ends'),
    bird('Hummingbird','patrol','interceptor',17,(25,76,68),(115,162,150),(229,86,112),'Needle bill, swept narrow wings and ruby throat'),
    bird('Oxpecker','patrol','support',16,(87,69,53),(176,155,119),(234,104,66),'Compact rounded wings, ochre body and red bill'),
    bird('Shrike','patrol','assault',16.5,(48,61,72),(191,203,200),(230,96,75),'Black eye mask, hooked beak and long narrow tail'),
    bird('Kingfisher','patrol','tactical',17,(25,78,111),(185,142,86),(91,210,232),'Long spear bill, compact wings and swept blue crest'),
    bird('Falcon','escort','interceptor',68,(48,64,83),(167,184,198),(218,135,80),'Pointed swept wings, short hooked beak and cheek mask'),
    bird('Egret','escort','support',64,(108,134,140),(221,231,226),(237,189,84),'White feather armor, slender S-neck and long straight bill'),
    bird('Goshawk','escort','assault',66,(54,71,81),(175,185,182),(236,105,76),'Broad rounded wings, long barred tail and pale eyebrow'),
    bird('Osprey','escort','tactical',68,(64,71,66),(199,211,208),(106,205,214),'Bent M-shaped wings, pale head and dark eye stripe'),
    bird('Frigatebird','frigate','interceptor',272,(32,42,55),(111,130,143),(221,66,87),'Very long angular wings, forked tail and red throat module'),
    bird('Pelican','frigate','support',256,(90,119,136),(219,221,199),(224,180,81),'Broad wings, long bill and large armored throat pouch'),
    bird('Golden Eagle','frigate','assault',264,(76,58,46),(179,143,82),(240,167,83),'Broad fingered wings and golden neck/shoulder armor'),
    bird('Harpy Eagle','frigate','tactical',272,(47,57,68),(174,185,194),(186,140,232),'Massive broad wings, slate chest and a split crown crest'),
]
BY_SLUG={s.slug:s for s in SHIPS}
