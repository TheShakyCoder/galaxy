"""Render shipped fleet GLBs in Blender, using their actual base-color materials.

blender --background --python tools/render_fleet_review.py -- --ships all
Optional --ships comma,separated,slugs; --views perspective,side,top.
"""
import argparse
import bpy
import json
import math
from pathlib import Path
import sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/fleet/renders'; OUT.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser(); parser.add_argument('--ships',default='all'); parser.add_argument('--views',default='perspective,side,top')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
rows=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())['ships']
for row in rows:
    slug=row['slug']
    if args.ships!='all' and slug not in args.ships.split(','): continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/row['glb']))
    models=[o for o in bpy.context.scene.objects if o.type=='MESH']
    # Normalize only the review scene, never the source GLB.
    extent=max(row['dimensions_m']); scale=14/extent
    center_src=Vector([(a+b)/2 for a,b in zip(*row['bounds_m'])])
    center_blender=Vector((center_src.x,-center_src.z,center_src.y))
    for o in models:
        o.scale*=scale; o.location-=center_blender*scale
    scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24; scene.cycles.use_denoising=True
    scene.render.resolution_x=960; scene.render.resolution_y=680; scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new('Fleet review studio'); scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.085,.12,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
    scene.view_settings.view_transform='AgX'
    center=Vector((0,0,0))
    def aim(o): o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
    for name,pos,power,size in [('Key',(5,-7,14),2200,9),('Fill',(-9,-1,6),1800,8),('Rim',(3,10,10),2600,7)]:
        light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.shape='DISK'; light.size=size
        o=bpy.data.objects.new(name,light); scene.collection.objects.link(o); o.location=pos; aim(o)
    camera=bpy.data.cameras.new('Review camera'); ob=bpy.data.objects.new('Review camera',camera)
    scene.collection.objects.link(ob); scene.camera=ob; camera.type='ORTHO'
    for view in args.views.split(','):
        ob.location={'perspective':(15,-18,14),'side':(24,0,0),'top':(0,0,24)}[view]; aim(ob)
        if view=='top': ob.rotation_euler.z+=math.pi
        # Large enough to cover a 14m maximum dimension even in the image height.
        camera.ortho_scale=21.8 if view=='top' else 20.3
        scene.render.filepath=str(OUT/f'{slug}-{view}.png'); bpy.ops.render.render(write_still=True)
    print('FLEET_RENDERED '+slug,flush=True)
print('FLEET_RENDER_COMPLETE',flush=True)
