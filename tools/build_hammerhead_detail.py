"""Rebuild only the approved Hammerhead; preserve all other fleet outputs."""
import json
from build_hd_fleet import ROOT, build
from fleet.roster import BY_SLUG

def main():
    row=build(BY_SLUG['hammerhead'])
    row['features']=['Approved 2026-10-14 Hammerhead concept: sculpted head and recessed optical eyes',
        'Segmented cheek armor and under-head intake','Five gill heat exchangers per side',
        'Conformal body plates, fin joints, protected sensors and engine collars','2K machined panel finish']
    path=ROOT/'artifacts/ship-detail/manifest.json'
    manifest=json.loads(path.read_text(encoding='utf8'))
    assert sum(r['slug']=='hammerhead' for r in manifest['ships'])==1
    manifest['ships']=[row if r['slug']=='hammerhead' else r for r in manifest['ships']]
    path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    print(json.dumps(row,indent=2))

if __name__=='__main__':main()
