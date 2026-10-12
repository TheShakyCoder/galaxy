from pathlib import Path
import sys, hashlib
p=Path(sys.argv[1]); html=p.read_text(encoding='utf8')
# Local review archives keep stable filenames; fingerprint their index so a
# browser revisiting after a rebuild fetches the new game data.
fingerprint=hashlib.sha256((p.parent/'archive/game0.arci').read_bytes()).hexdigest()[:16]
if 'galaxy-review-archive' not in html:
 html=html.replace("<script id='engine-start'", f"<script id='galaxy-review-archive'>CUSTOM_PARAMETERS.archive_location_filter = path => 'archive' + path + '?build={fingerprint}';</script>\n<script id='engine-start'")
if 'galaxy-review-controls' not in html:
 controls='''<style>
 body {background:#040a10!important} .canvas-app-container {background:#040a10!important}
 #galaxy-review-controls {position:fixed;z-index:20;left:50%;top:105px;transform:translateX(-50%);font:12px system-ui;color:#a2bcc9;background:#091725ed;padding:10px 15px;border:1px solid #284d60;border-radius:8px;max-width:90vw;text-align:center}
 #galaxy-review-controls button {font:inherit;background:#173448;color:#d3edf8;border:1px solid #30566c;padding:5px 9px;margin:5px 3px 0;cursor:pointer;border-radius:3px}
 #galaxy-review-controls summary{cursor:pointer}
 </style><details id="galaxy-review-controls"><summary>LOCAL DESIGN REVIEW / offline sample data</summary><div>
 <button id="review-fullscreen">Full screen</button><button data-command="patrol_interceptor">Patrol</button><button data-command="escort_assault">Escort</button><button data-command="frigate_tactical">Frigate</button><button data-command="damage">Toggle low vitals</button><button data-command="dock">Dock prompt</button><button data-command="clear">Clear target</button></div></details>
 <script>document.getElementById('review-fullscreen').onclick=()=>document.documentElement.requestFullscreen();document.querySelectorAll('[data-command]').forEach(b=>b.onclick=()=>window.galaxyReviewCommand=b.dataset.command);</script>
 '''
 html=html.replace('</body>',controls+'</body>')
p.write_text(html,encoding='utf8')
print(p)
