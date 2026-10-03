"""Add accessible review controls to the compiled standalone HTML5 demo.

Usage: python tools/prepare_asteroid_preview.py /path/to/bundle
The supplied directory contains 'Asteroid Review/index.html'.
"""
import sys
from pathlib import Path

path = Path(sys.argv[1]) / 'Asteroid Review' / 'index.html'
html = path.read_text(encoding='utf-8')
if 'id="asteroid-review-controls"' not in html:
    controls = '''
<style>
#asteroid-review-controls { position:fixed; z-index:20; top:0; left:0; right:0;
  padding:18px 24px; background:#0b1423; color:#e4edf6; font:14px system-ui; }
#asteroid-review-controls h1 { font-size:23px; margin:0 0 5px; }
#asteroid-review-controls p { margin:0 0 12px; color:#a8b8cb; }
#asteroid-review-controls button { border:1px solid #536880; border-radius:5px;
  padding:8px 12px; margin:3px 4px 3px 0; background:#17283c; color:#e4edf6; cursor:pointer; }
#asteroid-review-controls button:hover { background:#28445f; }
</style>
<section id="asteroid-review-controls">
<h1>Galaxy / Procedural asteroids</h1>
<p>Six unique rock meshes. Actual Defold runtime. Breakup completes in two seconds.</p>
<button data-action="intact">Intact</button>
<button data-action="fractured">Fractured · 0.65 s</button>
<button data-action="dissolving">Dissolving · 1.5 s</button>
<button data-action="explode">Play breakup</button>
<button data-action="reseed">New rocks</button>
<button data-action="auto">Toggle auto cycle</button>
<p id="review-status">Ready</p>
</section>
<script>
document.querySelectorAll('#asteroid-review-controls button').forEach(button => {
  button.addEventListener('click', () => {
    window.asteroidReviewCommand=button.dataset.action;
    document.getElementById('review-status').textContent=button.textContent;
  });
});
</script>
'''
    html = html.replace('</body>', controls + '\n</body>')
    path.write_text(html, encoding='utf-8')
print(path)
