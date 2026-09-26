"""Blender studio renders of the actual exported theme meshes/materials."""
import argparse
import bpy
import json
import math
from pathlib import Path
import sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/themes/renders'; OUT.mkdir(parents=True,exist_ok=True)
p=argparse.ArgumentParser(); p.add_argument('--catalog',default='assets/themes/catalog.json')
p.add_argument('--ships',default='all'); p.add_argument('--collections',default='all')
p.add_argument('--views',default='auto'); p.add_argument('--missing-only',action='store_true')
args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
rows=json.loads((ROOT/args.catalog).read_text())['entries']
for row in rows:
    slug,key=row['ship'],row['collection']
    if args.ships!='all' and slug not in args.ships.split(','): continue
    if args.collections!='all' and key not in args.collections.split(','): continue
    views=('perspective,side,top' if row['kind']=='model' else 'perspective') if args.views=='auto' else args.views
    views=[v for v in views.split(',') if not args.missing_only or not (OUT/f'{slug}-{key}-{v}.jpg').exists()]
    if not views: continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/row['glb']))
    center=Vector([(a+b)/2 for a,b in zip(*row['bounds_m'])]); scale=14/max(row['dimensions_m'])
    center=Vector((center.x,-center.z,center.y))
    for o in bpy.context.scene.objects:
        if o.type=='MESH': o.scale*=scale; o.location-=center*scale
    scene=bpy.context.scene; scene.render.engine='CYCLES'
    scene.cycles.samples=20; scene.cycles.use_denoising=True
    scene.render.resolution_x=840; scene.render.resolution_y=600; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='JPEG'; scene.render.image_settings.quality=91
    scene.world=bpy.data.worlds.new('Cosmetic review studio'); scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.085,.12,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
    scene.view_settings.view_transform='AgX'
    def aim(o): o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
    for name,pos,power,size in [('Key',(5,-7,14),2200,9),('Fill',(-9,-1,6),1800,8),('Rim',(3,10,10),2600,7)]:
        light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.shape='DISK'; light.size=size
        ob=bpy.data.objects.new(name,light); scene.collection.objects.link(ob); ob.location=pos; aim(ob)
    cam=bpy.data.cameras.new('Review camera'); ob=bpy.data.objects.new('Review camera',cam)
    scene.collection.objects.link(ob); scene.camera=ob; cam.type='ORTHO'
    for view in views:
        ob.location={'perspective':(15,-18,14),'side':(24,0,0),'top':(0,0,24)}[view]; aim(ob)
        if view=='top': ob.rotation_euler.z+=math.pi
        cam.ortho_scale=21.8 if view=='top' else 20.3
        scene.render.filepath=str(OUT/f'{slug}-{key}-{view}.jpg')
        bpy.ops.render.render(write_still=True)
    print('THEME_RENDERED '+row['id'],flush=True)
print('THEME_RENDER_COMPLETE',flush=True)
