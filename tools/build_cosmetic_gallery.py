#!/usr/bin/env python3
"""Portable, dependency-free cosmetic review gallery and fleet contact sheets."""
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'artifacts/cosmetics'
ORDER={'patrol':0,'escort':1,'frigate':2}; ROLES={'interceptor':0,'support':1,'assault':2,'tactical':3}


def sheets(catalog):
    title=ImageFont.load_default(size=34); label=ImageFont.load_default(size=22); small=ImageFont.load_default(size=15)
    for key,collection in catalog['collections'].items():
        for faction in ('accord','swarm'):
            rows=sorted([r for r in catalog['entries'] if r['collection']==key and r['faction']==faction],key=lambda r:(ORDER[r['size']],ROLES[r['role']]))
            for view in (['perspective','side','top'] if key=='clockwork' else ['perspective']):
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


def gallery(catalog):
    base=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())['ships']
    base.sort(key=lambda r:(ORDER[r['class']],r['faction'],ROLES[r['role']]))
    options=''.join(f'<option value="{r["slug"]}">{html.escape(r["name"])}</option>' for r in base)
    collection_buttons=[]
    for key,c in catalog['collections'].items():
        colors=''.join(f'<i style="background:rgb{tuple(c[t])}" aria-hidden="true"></i>' for t in ('back','flank','trim'))
        collection_buttons.append(f'<button class="collection" type="button" data-key="{key}" aria-pressed="{str(key=="aurora").lower()}"><span class="swatches">{colors}</span><strong>{c["name"]}</strong><span>{"24 sculpted variants" if key=="clockwork" else "24 paint variants"}</span></button>')
    cards=[]
    for r in base:
        slug=r['slug']; name=html.escape(r['name'])
        cards.append(f'''<article class="ship" data-ship="{slug}" data-faction="{r['faction']}" data-size="{r['class']}">
<a class="art" href="renders/{slug}-aurora-perspective.jpg" target="_blank" rel="noopener"><img loading="lazy" src="renders/{slug}-aurora-perspective.jpg" alt="{name}, Aurora paint"></a>
<div class="info"><p class="eyebrow">{r['faction']} / {r['class']} / {r['role']}</p><h2>{name}</h2><p class="finish">Aurora</p><p class="description"></p><div class="links"><a class="glb" href="../../assets/cosmetics/{slug}/aurora/model.glb" download>Model GLB</a><a class="texture" href="../../assets/cosmetics/{slug}/aurora/albedo.png" download>Texture PNG</a></div></div></article>''')
    template=(ROOT/'tools/cosmetics/gallery.html').read_text(encoding='utf-8')
    for marker,value in [('COLLECTION_BUTTONS',''.join(collection_buttons)),('SHIP_OPTIONS',options),('CARDS',''.join(cards)),('CATALOG_JSON',json.dumps(catalog)),('BASE_JSON',json.dumps(base))]:
        template=template.replace('{{'+marker+'}}',value)
    (OUT/'index.html').write_text(template,encoding='utf-8',newline='\n')


def main():
    catalog=json.loads((ROOT/'assets/cosmetics/catalog.json').read_text())
    sheets(catalog); gallery(catalog)
    print('Built 12 contact sheets and the 96-variant cosmetic gallery.')


if __name__=='__main__': main()
