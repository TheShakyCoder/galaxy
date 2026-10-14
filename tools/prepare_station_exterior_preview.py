"""Add offline browser review controls to a Bob-generated HTML bundle."""
import hashlib,re,sys
from pathlib import Path
p=Path(sys.argv[1]);s=p.read_text(encoding='utf8')
s=re.sub(r'<!-- STATION REVIEW BEGIN -->.*?<!-- STATION REVIEW END -->','',s,flags=re.S)
arci=p.parent/'archive/game.arci'
if not arci.exists():arci=p.parent/'archive/game0.arci'
version=hashlib.sha256(arci.read_bytes()).hexdigest()[:12] if arci.exists() else '1'
s=re.sub(r'/\* STATION ARCHIVE \*/.*?/\* END STATION ARCHIVE \*/','',s,flags=re.S)
s=s.replace('// From here you can configure',f'/* STATION ARCHIVE */ CUSTOM_PARAMETERS.archive_location_filter = function(path) {{ return "archive" + path + "?station={version}"; }}; /* END STATION ARCHIVE */\n// From here you can configure')
controls='''<!-- STATION REVIEW BEGIN -->
<style>html,body{margin:0;background:#05080e;color:#dee6ec;font:14px system-ui}#station-review{position:fixed;left:12px;top:12px;z-index:100;padding:12px;max-width:540px;background:#08101be8;border:1px solid #526273;border-radius:10px}button,select{background:#17283a;color:#e4edf8;border:1px solid #536578;border-radius:5px;margin:3px;padding:7px;cursor:pointer}summary{cursor:pointer;color:#c2d5e4}#rendered{display:block;margin-top:8px;color:#91d8d5}label{margin:4px}input{vertical-align:middle}</style>
<details id="station-review" open><summary>Galaxy / Station exteriors / Native Defold</summary>
<div><button onclick="send('accord')">Accord</button><button onclick="send('swarm')">Swarm</button><button onclick="send('both')">Same scale</button><button onclick="send('old')">Old / new</button></div>
<div><button onclick="send('orbit')">Orbit</button><button onclick="send('reset')">Reset camera</button><button onclick="send('side')">Side</button><button onclick="send('end')">End</button><button onclick="send('bounds')">800 m box</button></div>
<div><label>Spin <input aria-label="Spin speed" type="range" min="0" max="10" value="1" step="0.5" oninput="send('spin:'+this.value)"></label><button onclick="send('distance:10000')">10 km</button><button onclick="send('distance:5000')">5 km</button><button onclick="send('distance:1000')">1 km</button></div>
<div><button onclick="send('screen')">Screen close-up</button><label>Slot <select aria-label="Ad slot" onchange="send('slot:'+this.value)">OPTIONS</select></label><button onclick="send('ad')">Next ad</button></div>
<span id="rendered">Loading native preview...</span><small>Actual game assets. Mouse drag to orbit. Prototype rotation is cosmetic.</small></details>
<script>function send(value){window.stationCommand=value;}</script><!-- STATION REVIEW END -->'''.replace('OPTIONS',''.join(f'<option>{i}</option>' for i in range(1,9)))
s=s.replace('</body>',controls+'\n</body>');p.write_text(s,encoding='utf8')
print('Prepared',p)
