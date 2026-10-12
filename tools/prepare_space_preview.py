"""Add controls and visible acknowledgements to Bob's offline review bundle."""
from pathlib import Path
import hashlib,re,sys
p=Path(sys.argv[1]);root=Path(__file__).resolve().parents[1]
html=p.read_text(encoding='utf8')
# Safe to rerun against the same bundle as well as Bob's fresh generated HTML.
html=re.sub(r'<script>CUSTOM_PARAMETERS\.archive_location_filter=.*?</script>','',html,flags=re.S)
html=re.sub(r'<style>\s*body\{background:#05070b.*?</script>','',html,flags=re.S)
fingerprint=hashlib.sha256((p.parent/'archive/game0.arci').read_bytes()).hexdigest()[:16]
html=html.replace("<script id='engine-start'",f"<script>CUSTOM_PARAMETERS.archive_location_filter=path=>'archive'+path+'?build={fingerprint}';</script><script id='engine-start'")
systems=re.findall(r'\["([^"]+)"\]\s*=\s*\{ name = "([^"]+)"',(root/'main/data/star_systems.lua').read_text(encoding='utf8'))
def display_name(name):
    return re.sub(r'(?:\\\d{1,3})+',lambda m:bytes(map(int,re.findall(r'\d+',m.group()))).decode('utf8'),name)
options=''.join(f'<option value="{id}">{display_name(name)}</option>' for id,name in sorted(systems,key=lambda s:s[1]))
controls='''<style>
body{background:#05070b!important}#review{position:fixed;top:12px;left:50%;transform:translateX(-50%);z-index:30;background:#09101aeb;color:#bdd0de;border:1px solid #304555;border-radius:9px;padding:9px 14px;font:12px system-ui;max-width:95vw;text-align:center}#review button,#review select{font:inherit;color:#d5e4ee;background:#182732;border:1px solid #385064;border-radius:4px;padding:5px 8px;margin:4px 2px}#space-status{display:block;color:#8facbd;margin-top:4px}summary{cursor:pointer}
</style><details id="review" open><summary>Galaxy / Space review / offline native Defold</summary><div>
<label>System <select id="system">OPTIONS</select></label>
<button data-command="sol">Sol</button><button data-command="polaris">Polaris</button><button data-command="wolf_359">Wolf 359</button><button data-command="antares">Antares</button><button data-command="deneb">Deneb</button><br>
<button data-command="old">Old / new</button><button data-command="turn">Auto turn</button><button data-command="move">Travel / stop</button><button data-command="reset">Reset camera</button><button data-command="overlay">Ship overlay</button><button data-command="close_overlay">Close overlay</button><button id="fullscreen">Full screen</button>
<br><button data-command="front">Forward</button><button data-command="right">Right</button><button data-command="back">Back</button><button data-command="left">Left</button><button data-command="up">Zenith</button><button data-command="down">Nadir</button>
<span id="space-status">Loading native preview...</span></div></details>
<script>
document.querySelectorAll('[data-command]').forEach(b=>b.onclick=()=>{window.spaceCommand=b.dataset.command;});
document.getElementById('system').onchange=e=>window.spaceCommand=e.target.value;
document.getElementById('fullscreen').onclick=()=>document.documentElement.requestFullscreen();
window.spaceErrors=[];window.addEventListener('error',e=>window.spaceErrors.push(e.message));
</script>'''.replace('OPTIONS',options)
html=html.replace('</body>',controls+'</body>');p.write_text(html,encoding='utf8');print(p)
