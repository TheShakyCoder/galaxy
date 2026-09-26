"""Blender 4.3+: blender --background --python tools/render_sardine_review.py

Review-only studio renders. Never modifies the game asset or its materials.
Uses the GLB's shipped base-color material; no added metallic/emission effects.
"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/sardine'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/patrol_interceptor/sardine.glb'))
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=48
scene.cycles.use_denoising=True
scene.render.resolution_x=1600
scene.render.resolution_y=1000
scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Review studio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.06,.08,.11,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
scene.view_settings.view_transform='AgX'
center=Vector((0,1.1,0))
def aim(o): o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
for name,pos,power,size in [('Key',(5,-7,14),2200,9),('Fill',(-9,-1,6),1800,8),('Rim',(3,10,10),2600,7)]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.shape='DISK'; light.size=size
    ob=bpy.data.objects.new(name,light); scene.collection.objects.link(ob); ob.location=pos; aim(ob)
cam=bpy.data.cameras.new('Review camera'); ob=bpy.data.objects.new('Review camera',cam)
scene.collection.objects.link(ob); scene.camera=ob
cam.type='ORTHO'; cam.ortho_scale=19.5
for name,pos in [('perspective',(16,-14,11)),('side',(22,1.1,0)),('top',(0,1.1,24)),('rear',(13,20,8))]:
    ob.location=pos; aim(ob)
    if name=='top': ob.rotation_euler.z += math.pi
    cam.ortho_scale=30 if name=='top' else 19.5
    scene.render.filepath=str(OUT/f'sardine-{name}.png')
    bpy.ops.render.render(write_still=True)
print('SARDINE_REVIEW_RENDER_COMPLETE')
