"""Blender: actual Hammerhead GLB review and its two game menu images only."""
import bpy, json, math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/hammerhead';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/hd/hammerhead/ship.glb'))
models=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[o.matrix_world @ v.co for o in models for v in o.data.vertices]
lo=Vector([min(p[k] for p in points) for k in range(3)])
hi=Vector([max(p[k] for p in points) for k in range(3)])
center=(lo+hi)/2
scale=14/max(hi-lo)
for o in models:o.scale*=scale;o.location-=center*scale
scene=bpy.context.scene;scene.render.engine='CYCLES'
scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Review');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.085,.12,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
scene.view_settings.view_transform='AgX'
target=Vector((0,0,0))
def aim(o):o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
for name,pos,power,size in [('Key',(5,-7,14),2200,9),('Fill',(-9,-1,6),1800,8),('Rim',(3,10,10),2600,7)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=size
    o=bpy.data.objects.new(name,light);scene.collection.objects.link(o);o.location=pos;aim(o)
cam=bpy.data.cameras.new('Review');ob=bpy.data.objects.new('Review',cam)
scene.collection.objects.link(ob);scene.camera=ob;cam.type='ORTHO'
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGB'
for view,pos in [('perspective',(15,-18,14)),('underside',(12,-18,-7)),('side',(24,0,0)),('head',(9,-21,6))]:
    target=Vector((0,-5.0,0)) if view=='head' else Vector((0,0,0))
    ob.location=pos;aim(ob);cam.ortho_scale=8 if view=='head' else 20.3
    scene.render.resolution_x=1280;scene.render.resolution_y=880
    scene.render.filepath=str(OUT/(view+'.png'));bpy.ops.render.render(write_still=True)
target=Vector((0,0,0));ob.location=(15,-18,14);aim(ob);cam.ortho_scale=20.3
scene.render.resolution_x=336;scene.render.resolution_y=240
scene.render.image_settings.file_format='JPEG';scene.render.image_settings.quality=94
scene.render.filepath=str(ROOT/'main/images/skins/hammerhead-default.jpg');bpy.ops.render.render(write_still=True)
# Transparent fitting underlay with the same orientation and margin as the fleet.
scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='FLAT'
scene.display.shading.color_type='TEXTURE';scene.display.shading.show_object_outline=True
scene.display.shading.object_outline_color=(.03,.04,.06)
scene.render.film_transparent=True;scene.view_settings.view_transform='Standard'
scene.render.resolution_x=440;scene.render.resolution_y=640
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
width,length=hi.x-lo.x,hi.y-lo.y
px_per_m=min(420/width,620/length)
cam.ortho_scale=640/px_per_m*scale
ob.location=(0,0,25);ob.rotation_euler=(0,0,math.pi)
scene.render.filepath=str(ROOT/'main/images/topdown/hammerhead.png');bpy.ops.render.render(write_still=True)
path=ROOT/'main/images/topdown/topdown.json';meta=json.loads(path.read_text())
meta['hammerhead']['px_per_m']=round(px_per_m,4)
meta['hammerhead']['hull_px']=[round(width*px_per_m,1),round(length*px_per_m,1)]
path.write_text(json.dumps(meta,indent=1,sort_keys=True)+'\n')
print('HAMMERHEAD_RENDERS_COMPLETE')
