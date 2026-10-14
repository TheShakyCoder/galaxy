"""Wire generated station resources; --integrate preserves outpost root IDs/positions."""
import argparse,json,math,re,shutil
from pathlib import Path
from build_stations import ROOT,OUT,Mesh,write,model,ADS

def component(id,path):return f'components {{ id: "{id}" component: "{path}" }}'
def instance(id,data,pos=(0,0,0),children=(),rot=(0,0,0,1)):
    return 'embedded_instances { id: '+json.dumps(id)+' data: '+json.dumps(data)+'\n'+''.join('children: '+json.dumps(c)+'\n' for c in children)+f'position {{ x: {pos[0]} y: {pos[1]} z: {pos[2]} }} rotation {{ x: {rot[0]} y: {rot[1]} z: {rot[2]} w: {rot[3]} }} scale3 {{ x: 1 y: 1 z: 1 }} }}\n'
def assembly(row,root=True):
    f=row['faction'];p=f+'_outpost';r=p+'_rotor'
    result=''
    if root:result+=instance(p,component('model',f'/assets/models/stations/{f}/fixed.model'),children=[r])
    result+=instance(r,component('model',f'/assets/models/stations/{f}/rotor.model'),row['pivot'],[p+'_ad'+str(i) for i in range(1,9)])
    for i,(a,radius,z) in enumerate(row['slots'],1):
        angle=a+math.pi/2
        result+=instance(p+'_ad'+str(i),component('model',f'/assets/models/stations/ads/{ADS[i-1][0]}.model'),(radius*math.cos(a),radius*math.sin(a),z),rot=(0,0,math.sin(angle/2),math.cos(angle/2)))
    return result
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--integrate',action='store_true');args=ap.parse_args()
    rows=json.loads((OUT/'manifest.json').read_text())['stations']
    old=(ROOT/'assets/materials/ship_finish/ship.material').read_text()
    for kind in ('hull','ad'):
        text=old.replace('name: "ship_finish"',f'name: "station_{kind}"').replace('/assets/materials/ship_finish/ship.fp',f'/assets/materials/stations/{kind}.fp')
        text=text.replace('FILTER_MODE_MIN_LINEAR','FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR').replace('max_anisotropy: 1.0','max_anisotropy: 4.0')
        if kind=='ad':text=re.sub(r'fragment_constants \{.*?\n\}', '',text,flags=re.S)
        else:text+='\nfragment_constants { name: "beacon_clock" type: CONSTANT_TYPE_USER value { x: 0 y: 0 z: 0 w: 0 } }\n'
        write(ROOT/f'assets/materials/stations/{kind}.material',text)
    preview=ROOT/'tests/station_exterior_preview'
    text='name: "station_exterior_review"\n'
    for row in rows:text+=assembly(row)
    text+=instance('controller',component('script','/tests/station_exterior_preview/preview.script'))
    text+=instance('sardine',component('model','/assets/models/patrol_interceptor/patrol_interceptor.model'),(0,0,460))
    for f in ('accord','swarm'):
        write(preview/f'{f}_old.model',f'mesh: "/assets/models/outposts/{f}_outpost.glb"\nmaterial: "/builtins/materials/model.material"\ntextures: "/assets/models/outposts/{f}_outpost_palette.png"\n')
        text+=instance(f+'_old',component('model',f'/tests/station_exterior_preview/{f}_old.model'))
    box=Mesh()
    for axis in range(3):
        for a in (-400,400):
            for b in (-400,400):
                c=[0,0,0];others=[k for k in range(3) if k!=axis];c[others[0]]=a;c[others[1]]=b;s=[1.3]*3;s[axis]=800;box.box(c,s,'cyan')
    box.save(preview/'bounds.glb');write(preview/'bounds.model',model('/tests/station_exterior_preview/bounds.glb','/assets/models/stations/accord/hull.png'))
    text+=instance('bounds',component('model','/tests/station_exterior_preview/bounds.model'))
    write(preview/'preview.collection',text)
    write(preview/'preview.ini','[bootstrap]\nmain_collection = /tests/station_exterior_preview/preview.collectionc\nrender = /tests/station_exterior_preview/preview.renderc\n[project]\ntitle = Station Exterior Review\n')
    write(preview/'preview.render','script: "/tests/station_exterior_preview/preview.render_script"\n')
    if args.integrate:
        path=ROOT/'main/main.collection';text=path.read_text()
        # Generated children/controller have explicit begin/end delimiters for reruns.
        text=re.sub(r'\n# STATION EXTERIORS BEGIN.*?# STATION EXTERIORS END\n','\n',text,flags=re.S)
        for row in rows:
            f=row['faction'];anchor=f'  id: "{f}_outpost"'
            child=f'  children: "{f}_outpost_rotor"'
            if child not in text:text=text.replace(anchor,anchor+'\n'+child)
            shutil.copyfile(OUT/f/'fixed.model',ROOT/f'assets/models/outposts/{f}_outpost.model')
        block='\n# STATION EXTERIORS BEGIN\n'+''.join(assembly(row,False) for row in rows)+instance('station_visuals',component('script','/main/stations.script'))+'# STATION EXTERIORS END\n'
        first=text.index('embedded_instances {');text=text[:first]+block+text[first:]
        write(path,text.rstrip()+'\n')
        project=ROOT/'game.project';config=project.read_text()
        setting='texture_profiles = /assets/materials/stations/stations.texture_profiles'
        if re.search(r'^texture_profiles\s*=',config,re.M):config=re.sub(r'^texture_profiles\s*=.*$',setting,config,flags=re.M)
        elif '[graphics]' in config:config=config.replace('[graphics]','[graphics]\n'+setting)
        else:config+='\n[graphics]\n'+setting+'\n'
        write(project,config)
if __name__=='__main__':main()
