#!/usr/bin/env python3
"""Portable, dependency-free cosmetic review gallery and fleet contact sheets."""
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'artifacts/themes'
ORDER={'patrol':0,'escort':1,'frigate':2}; ROLES={'interceptor':0,'support':1,'assault':2,'tactical':3}


def sheets(catalog):
    title=ImageFont.load_default(size=34); label=ImageFont.load_default(size=22); small=ImageFont.load_default(size=15)
    for key,collection in catalog['collections'].items():
        for faction in ('accord','swarm'):
            rows=sorted([r for r in catalog['entries'] if r['collection']==key and r['faction']==faction],key=lambda r:(ORDER[r['size']],ROLES[r['role']]))
            for view in (['perspective','side','top'] if collection['kind']=='model' else ['perspective']):
                sheet=Image.new('RGB',(1640,1180),(16,25,35)); d=ImageDraw.Draw(sheet)
                d.text((28,22),collection['name'].upper()+' / '+('ACCORD FISH' if faction=='accord' else 'SWARM BIRDS'),font=title,fill=(234,229,216))
                d.text((30,70),view.upper()+'   |   Original ship geometry retained   |   Studio views normalized for detail',font=small,fill=(159,178,183))
                for i,row in enumerate(rows):
                    x=24+i%4*402; y=110+i//4*351
                    with Image.open(OUT/'renders'/f'{row["ship"]}-{key}-{view}.jpg') as image:
                        image.thumbnail((390,279),Image.Resampling.LANCZOS); sheet.paste(image,(x+(390-image.width)//2,y))
                    d.text((x+8,y+282),row['name'],font=label,fill=(227,234,233))
                    d.text((x+8,y+312),row['size'].title()+' / '+row['role'].title()+f'  ·  {row["triangles"]:,} tris',font=small,fill=(150,177,181))
                sheet.save(OUT/f'{key}-{faction}-{view}.jpg',quality=93,optimize=True)


if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--sprint',type=int);args=p.parse_args()
    suffix=f'-sprint-{args.sprint}' if args.sprint else ''
    cat=json.loads((ROOT/'assets/skins/catalogs'/('themes'+suffix+'.json')).read_text())
    sheets(cat)
    print('Theme contact sheets complete.')
