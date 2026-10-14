"""Add native inspection controls to an external Defold HTML5 bundle."""
import hashlib,re,sys
from pathlib import Path
path=Path(sys.argv[1])/'Asteroid Review/index.html';html=path.read_text(encoding='utf8')
html=re.sub(r'<!-- ASTEROID REVIEW BEGIN -->.*?<!-- ASTEROID REVIEW END -->','',html,flags=re.S)
html=re.sub(r'/\* ASTEROID ARCHIVE \*/.*?/\* END ASTEROID ARCHIVE \*/','',html,flags=re.S)
index=path.parent/'archive/game0.arci';stamp=hashlib.sha256(index.read_bytes()).hexdigest()[:12]
html=html.replace('// From here you can configure',f'/* ASTEROID ARCHIVE */ CUSTOM_PARAMETERS.archive_location_filter=function(path){{return "archive"+path+"?rock={stamp}";}}; /* END ASTEROID ARCHIVE */\n// From here you can configure')
controls='''<!-- ASTEROID REVIEW BEGIN -->
<style>body{background:#030810}#asteroid-review-controls{position:fixed;z-index:20;top:10px;left:10px;padding:12px;color:#deebf2;background:#091321e8;border:1px solid #526477;border-radius:10px;font:14px system-ui;max-width:470px}button,select{background:#16283b;color:#e1edf6;border:1px solid #526477;border-radius:5px;padding:7px;margin:3px;cursor:pointer}summary{cursor:pointer}#review-status{font-size:12px;color:#9fd9d8;margin-top:6px}</style>
<details id="asteroid-review-controls" open><summary>Galaxy / Asteroid detail / Native Defold</summary>
<div><button data-action="population">Ten rocks</button><button data-action="close">Close-up</button><button data-action="compare">Before / after</button><button data-action="old">Old / new</button></div>
<div><select aria-label="Archetype" onchange="send('kind:'+this.value)"><option value="1">Weathered</option><option value="2">Shard</option><option value="3">Contact binary</option><option value="4">Fractured</option><option value="5">Rubble</option></select><button data-action="reseed">New seeds</button><button data-action="spin">Pause / rotate</button></div>
<div><button data-action="analysed">Toggle analysed</button><select aria-label="Resource" onchange="send('resource:'+this.value)"><option value="iron">Iron / violet</option><option value="inert">Inert / red</option><option value="hydrogen">Hydrogen / yellow</option><option value="water">Water / blue</option></select></div>
<div><button data-action="intact">Intact</button><button data-action="fractured">Fractured · 0.65 s</button><button data-action="dissolving">Dissolving · 1.5 s</button><button data-action="explode">Play breakup</button></div>
<div><button data-action="field:50">50 rocks</button><button data-action="field:100">100 rocks</button><button data-action="auto">Auto cycle</button></div>
<div id="review-status">Loading native assets...</div><small>Drag to turn. Comparison: original left, upgrade right.</small></details>
<script>window.asteroidReviewCommands=[];function send(value){window.asteroidReviewCommands.push(value)}document.querySelectorAll('[data-action]').forEach(b=>b.addEventListener('click',()=>send(b.dataset.action)));</script>
<!-- ASTEROID REVIEW END -->'''
html=html.replace('</body>',controls+'\n</body>');path.write_text(html,encoding='utf8');print(path)
