#!/usr/bin/env python3
"""Portable, dependency-free cosmetic review gallery and fleet contact sheets."""
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'artifacts/themes'
ORDER={'patrol':0,'escort':1,'frigate':2}; ROLES={'interceptor':0,'support':1,'assault':2,'tactical':3}


def gallery(catalog,filename="index.html",catalog_file="catalog.json"):
    first=next(iter(catalog["collections"]))
    base=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())['ships']
    base.sort(key=lambda r:(ORDER[r['class']],r['faction'],ROLES[r['role']]))
    options=''.join(f'<option value="{r["slug"]}">{html.escape(r["name"])}</option>' for r in base)
    collection_buttons=[]
    for key,c in catalog['collections'].items():
        colors=''.join(f'<i style="background:rgb{tuple(c[t])}" aria-hidden="true"></i>' for t in ('back','flank','trim'))
        collection_buttons.append(f'<button class="collection" type="button" data-key="{key}" aria-pressed="{str(key==first).lower()}"><span class="swatches">{colors}</span><strong>{c["name"]}</strong><span>{"24 sculpted variants" if c["kind"]=="model" else "24 paint variants"}</span></button>')
    cards=[]
    for r in base:
        slug=r['slug']; name=html.escape(r['name'])
        cards.append(f'''<article class="ship" data-ship="{slug}" data-faction="{r['faction']}" data-size="{r['class']}">
<a class="art" href="renders/{slug}-{first}-perspective.jpg" target="_blank" rel="noopener"><img loading="lazy" src="renders/{slug}-{first}-perspective.jpg" alt="{name}, {catalog["collections"][first]["name"]} finish"></a>
<div class="info"><p class="eyebrow">{r['faction']} / {r['class']} / {r['role']}</p><h2>{name}</h2><p class="finish">{catalog["collections"][first]["name"]}</p><p class="description"></p><div class="links"><a class="glb" href="../../assets/skins/{slug}/{first}/model.glb" download>Model GLB</a><a class="texture" href="../../assets/skins/{slug}/{first}/albedo.png" download>Texture PNG</a></div></div></article>''')
    template=(ROOT/'tools/themes/gallery.html').read_text(encoding='utf-8')
    for marker,value in [('COLLECTION_BUTTONS',''.join(collection_buttons)),('SHIP_OPTIONS',options),('CARDS',''.join(cards)),('CATALOG_JSON',json.dumps(catalog)),('BASE_JSON',json.dumps(base)),('FIRST_COLLECTION',first),('VARIANT_COUNT',str(len(catalog['entries']))),('COLLECTION_COUNT',str(len(catalog['collections']))),('CATALOG_FILE',catalog_file),('VALIDATION_FILE','validation'+catalog_file.removeprefix('themes'))]:
        template=template.replace('{{'+marker+'}}',value)
    (OUT/filename).write_text(template,encoding='utf-8',newline='\n')


def main():
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--sprint',type=int);args=p.parse_args()
    suffix=f'-sprint-{args.sprint}' if args.sprint else ''
    filename='themes'+suffix+'.json'
    catalog=json.loads((ROOT/'assets/skins/catalogs'/filename).read_text())
    gallery(catalog,'sprint-'+str(args.sprint)+'.html' if args.sprint else 'index.html',filename)
    print('Theme gallery ready:',len(catalog['entries']),'variants')

if __name__=='__main__':main()
