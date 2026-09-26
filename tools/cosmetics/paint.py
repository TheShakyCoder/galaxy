"""Original procedural paint collections using the fleet's existing atlas UVs.

Regenerates scale/feather engraving and species markings, then authors paint
panels and hardware swatches. No downloaded textures or repainted screenshots.
"""
from dataclasses import replace
from PIL import ImageDraw
from fleet.geometry import atlas
from build_sardine_model import COLORS

COLLECTIONS = {
    'aurora': dict(name='Aurora', kind='recolor', back=(12,82,78), flank=(168,231,204),
                   accent=(138,247,230), trim=(98,174,181), fin=(16,105,102),
                   light=(203,246,222), description='Deep teal enamel, mint armor and glacial blue trim.'),
    'solar_regatta': dict(name='Solar Regatta', kind='recolor', back=(139,30,32), flank=(240,216,169),
                         accent=(255,143,59), trim=(216,149,62), fin=(166,42,33),
                         light=(247,229,194), description='Crimson racing panels, warm ivory armor and amber details.'),
    'royal_amethyst': dict(name='Royal Amethyst', kind='recolor', back=(64,28,104), flank=(182,145,220),
                          accent=(247,182,232), trim=(224,183,91), fin=(92,44,131),
                          light=(224,196,244), description='Plum enamel, lavender armor and champagne-gold trim.'),
    'clockwork': dict(name='Clockwork', kind='model', back=(53,69,59), flank=(176,130,67),
                      accent=(243,185,76), trim=(186,108,57), fin=(90,65,41),
                      light=(213,188,132), description='Brass and copper machinery, verdigris enamel and canvas-colored fins.'),
}


def paint(ship, collection):
    c = COLLECTIONS[collection]
    back, flank = c['back'], c['flank']
    if collection == 'clockwork' and ship.faction == 'swarm':
        back, flank = (48,49,53), (149,104,65)
    decorated = replace(ship, back=back, flank=flank, accent=c['accent'])
    image = atlas(decorated)
    d = ImageDraw.Draw(image)
    # Existing species masks/bands come from atlas(). Sardine adds its own spots.
    if ship.slug == 'sardine':
        for y in (181,843):
            for x in range(215,630,52):
                d.ellipse((x-5,y-5,x+5,y+5), fill=back)
    # Parallel thin paint lines remain legible without erasing anatomical marks.
    for y in (225,799):
        d.line((196,y,690,y), fill=c['trim'], width=4)
        d.line((196,y+7,690,y+7), fill=c['light'], width=2)
    for y in (390,620):
        if collection == 'solar_regatta':
            for x in (295,319,343):
                d.polygon([(x,y),(x+10,y),(x+31,y+68),(x+21,y+68)],fill=back)
        elif collection == 'royal_amethyst':
            d.line([(355,y),(380,y+20),(355,y+40),(330,y+20),(355,y)],fill=c['trim'],width=3)
        elif collection == 'aurora':
            for j in range(3):
                d.line([(303+j*21,y+36),(327+j*21,y+18),(303+j*21,y)],fill=c['trim'],width=3)
    if collection == 'clockwork':
        # Plate seams and alternating rivet heads on the body atlas.
        for x in (185,282,396,516,629,714):
            for y in range(28,1005,35):
                d.ellipse((x-2,y-2,x+3,y+3),fill=(55,39,26))
                d.ellipse((x-1,y-2,x+2,y+1),fill=(236,201,120))
    colors = dict(COLORS)
    colors.update(navy=tuple(round(v*.48) for v in back), blue=back,
                  teal=tuple((a+b)//2 for a,b in zip(back,flank)), silver=flank,
                  pearl=c['light'], edge=c['trim'], brass=c['trim'], fin=c['fin'],
                  fin_light=c['light'], panel=flank, cyan=c['accent'],
                  glass=tuple(round(v*.24) for v in back), dark=(14,18,22),
                  nozzle=(38,42,45), white=c['light'], spot=back)
    if collection == 'clockwork':
        colors.update(brass=(209,166,78), edge=(178,104,54), panel=(77,101,82),
                      fin=(135,111,73), fin_light=(223,201,152), pearl=(237,218,169),
                      silver=(166,124,66), blue=back, glass=(17,48,45), cyan=(251,184,58))
    for i, (name, rgb) in enumerate(colors.items()):
        x,y=800+(i%4)*56,24+(i//4)*56
        d.rectangle((x,y,x+47,y+47),fill=rgb)
    return image
