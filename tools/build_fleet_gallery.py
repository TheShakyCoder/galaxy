#!/usr/bin/env python3
"""Build review contact sheets and a portable HTML gallery from actual GLB renders."""
import html
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'artifacts/fleet'
ORDER={'patrol':0,'escort':1,'frigate':2}; ROLES={'interceptor':0,'support':1,'assault':2,'tactical':3}


def main():
    rows=json.loads((OUT/'manifest.json').read_text())['ships']
    font=ImageFont.load_default(size=22); small=ImageFont.load_default(size=16); titlefont=ImageFont.load_default(size=36)
    for faction in ('accord','swarm'):
        fleet=sorted([r for r in rows if r['faction']==faction],key=lambda r:(ORDER[r['class']],ROLES[r['role']]))
        for view in ('perspective','side','top'):
            sheet=Image.new('RGB',(1640,1330),(18,27,40)); d=ImageDraw.Draw(sheet)
            d.text((30,22),('ACCORD / FISH' if faction=='accord' else 'SWARM / BIRDS')+'     '+view.upper(),font=titlefont,fill=(226,235,238))
            d.text((30,73),'Patrol: small  |  Escort: medium  |  Frigate: largest    -    Images normalized for detail; dimensions shown below.',font=small,fill=(158,179,194))
            for i,row in enumerate(fleet):
                x=25+(i%4)*402; y=114+(i//4)*400
                img=Image.open(OUT/'renders'/f'{row["slug"]}-{view}.png').convert('RGB'); img.thumbnail((390,278),Image.Resampling.LANCZOS)
                sheet.paste(img,(x+(390-img.width)//2,y))
                d.text((x+9,y+279),row['name'],font=font,fill=(222,237,239))
                d.text((x+9,y+309),row['class'].title()+' / '+row['role'].title(),font=small,fill=(153,186,195))
                d.text((x+9,y+332),f'{max(row["dimensions_m"]):g}m max dimension  /  {row["triangles"]:,} triangles',font=small,fill=(139,159,179))
                width=round(max(row['dimensions_m'])/88*350)
                d.rounded_rectangle((x+9,y+365,x+9+width,y+371),radius=3,fill=(91,194,199) if faction=='accord' else (213,147,100))
            sheet.save(OUT/f'{faction}-{view}.png',optimize=True)
    cards=[]
    for row in sorted(rows,key=lambda r:(ORDER[r['class']],r['faction'],ROLES[r['role']])):
        size=max(row['dimensions_m']); slug=row['slug']; name=html.escape(row['name'])
        cards.append(f'''<article class="ship" data-faction="{row['faction']}" data-class="{row['class']}" data-slug="{slug}">
<a class="render" href="renders/{slug}-perspective.png"><img loading="lazy" src="renders/{slug}-perspective.png" alt="{name} spacecraft, three-quarter view"></a>
<div class="info"><div class="eyebrow">{row['faction']} · {row['class']} · {row['role']}</div><h2>{name}</h2><p>{html.escape(row['identity'])}.</p>
<div class="size"><span style="width:{size/88*100:.2f}%"></span></div><div class="spec">{size:g} m maximum dimension · {row['triangles']:,} triangles</div>
<a class="download" href="../../{row['glb']}" download>Download model ↗</a>{'<span class="retained">Approved Sardine retained</span>' if row['retained'] else ''}</div></article>''')
    doc='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Galaxy · Species fleet</title><style>
:root{color-scheme:dark;font:16px/1.5 system-ui,sans-serif;background:#101923;color:#e4edf0}*{box-sizing:border-box}body{margin:0}header,main,footer{max-width:1600px;margin:auto;padding:30px 36px}header{padding-top:58px;border-bottom:1px solid #304151}.kicker{color:#89cbd0;letter-spacing:.2em;font-size:12px;text-transform:uppercase}h1{font-size:clamp(32px,5vw,60px);font-weight:550;letter-spacing:-.04em;margin:12px 0}header p{max-width:820px;color:#aabac7}nav{display:flex;gap:15px;flex-wrap:wrap;margin-top:27px}label{font-size:12px;color:#a1b7c6;text-transform:uppercase;letter-spacing:.08em}select{display:block;min-width:170px;margin-top:6px;background:#1d2a39;border:1px solid #435467;border-radius:6px;padding:10px 14px;color:#eef7fa;font:inherit;text-transform:none;letter-spacing:0}.count{align-self:end;color:#96acbc;padding:10px}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:22px}.ship{background:#192532;border:1px solid #324454;border-radius:12px;overflow:hidden}.ship[hidden]{display:none}.render{display:block;background:#354355}.render img{display:block;width:100%;aspect-ratio:960/680;object-fit:contain}.info{padding:21px}.eyebrow{font-size:10px;letter-spacing:.1em;color:#9bbbc8;text-transform:uppercase}h2{margin:7px 0;font-size:24px;font-weight:550}.info p{font-size:13px;color:#afbfcc;min-height:60px}.spec{font-size:11px;color:#9bb0bf}.size{margin:19px 0 7px;height:4px;background:#314354;border-radius:3px}.size span{display:block;height:4px;background:#83cad0;border-radius:3px}[data-faction=swarm] .size span{background:#d69e79}.download{display:inline-block;margin-top:18px;font-size:12px;color:#b1e0e4;text-decoration:none}.retained{display:block;color:#a2c5a5;font-size:11px;margin-top:10px}footer{color:#92a8b9;font-size:13px;border-top:1px solid #304151}a{color:#9bd6da}select:focus-visible,a:focus-visible{outline:3px solid #93dbe1;outline-offset:3px}.section-note{color:#95acbb;margin:0 0 25px;font-size:13px}@media(max-width:1150px){.grid{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:850px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}header,main,footer{padding:25px 20px}}@media(max-width:530px){.grid{grid-template-columns:1fr}select{min-width:140px}.info p{min-height:0}}
</style><header><div class="kicker">Galaxy / Fleet review</div><h1>Two factions. Twenty-four species.</h1><p>12 Accord fish and 12 Swarm birds, built around the approved Sardine's machined armor and species-inspired silhouettes. Patrol ships are small, Escorts are medium, and Frigates are largest.</p>
<nav aria-label="Gallery filters"><label>Faction<select id="faction"><option value="all">Both factions</option><option value="accord">Accord · Fish</option><option value="swarm">Swarm · Birds</option></select></label><label>Size class<select id="size"><option value="all">All sizes</option><option value="patrol">Patrol · Small</option><option value="escort">Escort · Medium</option><option value="frigate">Frigate · Largest</option></select></label><label>View<select id="view"><option value="perspective">Three-quarter</option><option value="side">Side profile</option><option value="top">Top-down</option></select></label><span class="count" id="count" aria-live="polite">24 ships</span></nav></header>
<main><p class="section-note">Studio renders of the actual models, scaled to show detail. Compare the dimension bars for relative size. Click an image to inspect the full render.</p><section class="grid" aria-label="Ship models">'''+''.join(cards)+'''</section></main><footer><p>23 new models; the approved Sardine is retained. Geometry, deterministic builds, game references, and camera framing pass automated checks. In-game rendering, multiplayer, and browser/mobile performance remain untested.</p><a href="README.md">Read the full report</a> · <a href="validation.json">Validation results</a></footer>
<script>
const faction=document.querySelector('#faction'),size=document.querySelector('#size'),view=document.querySelector('#view'),cards=[...document.querySelectorAll('.ship')];
function update(){let count=0;for(const card of cards){card.hidden=!(faction.value==='all'||card.dataset.faction===faction.value)||!(size.value==='all'||card.dataset.class===size.value);if(!card.hidden)count++;const path=`renders/${card.dataset.slug}-${view.value}.png`;card.querySelector('img').src=path;card.querySelector('img').alt=`${card.querySelector('h2').textContent} spacecraft, ${view.options[view.selectedIndex].text} view`;card.querySelector('.render').href=path;}document.querySelector('#count').textContent=count+' ships';}
for(const input of [faction,size,view])input.addEventListener('change',update);
</script></html>'''
    (OUT/'index.html').write_text(doc,encoding='utf-8')
    print('Wrote six contact sheets and portable 24-ship gallery.')


if __name__=='__main__': main()
