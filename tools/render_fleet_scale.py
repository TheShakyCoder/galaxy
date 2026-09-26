"""Blender: show each faction/role trio at its actual common world scale."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/scale';OUT.mkdir(exist_ok=True)
rows=json.loads((ROOT/'artifacts/fleet/manifest.json').read_text())['ships']
for faction in ('accord','swarm'):
    for role in ('interceptor','support','assault','tactical'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        for size,x in [('patrol',-220),('escort',0),('frigate',220)]:
            row=next(r for r in rows if r['faction']==faction and r['role']==role and r['class']==size)
            existing=set(bpy.context.scene.objects)
            bpy.ops.import_scene.gltf(filepath=str(ROOT/row['glb']))
            center=Vector([(a+b)/2 for a,b in zip(*row['bounds_m'])])
            center=Vector((center.x,-center.z,center.y))
            for ob in set(bpy.context.scene.objects)-existing:
                if ob.type=='MESH':
                    ob.location=Vector((x,0,0))-center
                    # Deliberately no per-model normalization or scaling.
        scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
        scene.render.resolution_x=1480;scene.render.resolution_y=720;scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG'
        scene.world=bpy.data.worlds.new('Scale review');scene.world.use_nodes=True
        scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.085,.12,1)
        scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
        scene.view_settings.view_transform='AgX'
        for name,pos,power in [('Key',(200,-200,550),4500000),('Fill',(-400,0,500),4000000),('Rim',(0,400,500),4000000)]:
            light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=500
            ob=bpy.data.objects.new(name,light);scene.collection.objects.link(ob);ob.location=pos
            ob.rotation_euler=(-ob.location).to_track_quat('-Z','Y').to_euler()
        cam=bpy.data.cameras.new('Common orthographic camera');ob=bpy.data.objects.new('Common orthographic camera',cam)
        scene.collection.objects.link(ob);ob.location=(0,0,800);cam.type='ORTHO';cam.ortho_scale=740;cam.clip_end=2000;scene.camera=ob
        scene.render.filepath=str(OUT/f'{faction}-{role}.png');bpy.ops.render.render(write_still=True)
        print('SCALE_RENDERED '+faction+' '+role,flush=True)
