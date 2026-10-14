from pathlib import Path
import sys, hashlib, re
p=Path(sys.argv[1]); html=p.read_text(encoding='utf8')
# Bob can reuse an HTML launcher generated with the full game's title.
# Match the launcher to the engine actually emitted for this preview bundle.
engines=list(p.parent.glob('*_wasm.js'))
engines=[engine for engine in engines if not engine.name.endswith('_pthread_wasm.js')]
if len(engines)!=1:
 raise SystemExit('Expected exactly one non-threaded WASM engine in the preview bundle')
engine_name=engines[0].name.removesuffix('_wasm.js')
html=re.sub(r'EngineLoader\.load\("canvas",\s*"[^"]+"\)', lambda _: 'EngineLoader.load("canvas", "'+engine_name+'")', html)
html=re.sub(r'<title>.*?</title>', '<title>Station UI Review</title>', html)
fingerprint=hashlib.sha256((p.parent/'archive/game0.arci').read_bytes()).hexdigest()[:16]
html=re.sub(r"<script id='galaxy-review-archive'>.*?</script>\s*",'',html,flags=re.S)
html=html.replace("<script id='engine-start'",f"<script id='galaxy-review-archive'>CUSTOM_PARAMETERS.archive_location_filter = path => 'archive' + path + '?build={fingerprint}';</script>\n<script id='engine-start'")
if 'galaxy-review-controls' not in html:
 controls='''<style>
 body,.canvas-app-container {background:#040a10!important}
 #galaxy-review-controls {position:fixed;z-index:20;left:50%;top:58px;transform:translateX(-50%);font:11px system-ui;color:#a2bcc9;background:#091725ed;padding:5px 10px;border:1px solid #284d60;border-radius:5px;max-width:94vw;text-align:center}
 #galaxy-review-controls button,#galaxy-review-controls select {font:inherit;background:#173448;color:#d3edf8;border:1px solid #30566c;padding:4px 7px;margin:4px 2px;cursor:pointer;border-radius:3px}
 #galaxy-review-controls summary {cursor:pointer}
 </style><details id="galaxy-review-controls"><summary>LOCAL DESIGN REVIEW / offline sample data</summary><div>
 <label>Faction <select id="review-faction"><option value="accord">Accord</option><option value="swarm">Swarm</option></select></label>
 <label>Hull <select id="review-hull">
 <option value="patrol_interceptor">Patrol / Interceptor</option><option value="patrol_support">Patrol / Support</option><option value="patrol_assault">Patrol / Assault</option><option value="patrol_tactical">Patrol / Tactical</option>
 <option value="escort_interceptor">Escort / Interceptor</option><option value="escort_support">Escort / Support</option><option value="escort_assault">Escort / Assault</option><option value="escort_tactical">Escort / Tactical</option>
 <option value="frigate_interceptor">Frigate / Interceptor</option><option value="frigate_support">Frigate / Support</option><option value="frigate_assault">Frigate / Assault</option><option value="frigate_tactical">Frigate / Tactical</option>
 </select></label><button id="review-load">Load fixture</button><button id="review-fullscreen">Full screen</button>
 <span id="review-status">Loading native preview...</span></div></details>
 <script>document.getElementById('review-fullscreen').onclick=()=>document.documentElement.requestFullscreen();document.getElementById('review-load').onclick=()=>{window.galaxyStationCommand=document.getElementById('review-faction').value+':'+document.getElementById('review-hull').value;};</script>
 '''
 html=html.replace('</body>',controls+'</body>')
p.write_text(html,encoding='utf8')
print(p, fingerprint)
