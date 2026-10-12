from pathlib import Path
import sys
p=Path(sys.argv[1]); html=p.read_text(encoding='utf8')
if 'galaxy-review-controls' not in html:
 controls='''<style>
 #galaxy-review-controls {position:fixed;z-index:20;left:50%;top:84px;transform:translateX(-50%);font:12px system-ui;color:#a2bcc9;background:#091725ed;padding:10px 15px;border:1px solid #284d60;border-radius:8px;max-width:90vw;text-align:center}
 #galaxy-review-controls button {font:inherit;background:#173448;color:#d3edf8;border:1px solid #30566c;padding:5px 9px;margin:5px 3px 0;cursor:pointer;border-radius:3px}
 #galaxy-review-controls summary{cursor:pointer}
 </style><details id="galaxy-review-controls"><summary>LOCAL DESIGN REVIEW / offline sample data</summary><div>
 <button data-command="accord">Accord fish</button><button data-command="swarm">Swarm birds</button></div></details>
 <script>document.querySelectorAll('[data-command]').forEach(b=>b.onclick=()=>window.galaxyStationCommand=b.dataset.command);</script>
 '''
 html=html.replace('</body>',controls+'</body>');p.write_text(html,encoding='utf8')
print(p)
