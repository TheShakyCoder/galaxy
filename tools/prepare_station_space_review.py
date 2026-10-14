"""Optional native combined review. Requires a separate Space PR checkout/export.

The ordinary station preview and game do not depend on that checkout. This tool
copies only the sky's resources into an ignored, preview-only generated folder.
"""
import argparse,json,shutil
from pathlib import Path
from build_stations import ROOT,write
from setup_station_exteriors import instance,component
ap=argparse.ArgumentParser();ap.add_argument('--space-root',type=Path,required=True);args=ap.parse_args()
base=ROOT/'tests/station_exterior_preview';dest=base/'combined';prefix='/tests/station_exterior_preview/combined'
names=['right.png','left.png','top.png','bottom.png','front.png','back.png','fields.cubemap','sky.buffer','sky.mesh','sky.material','sky.vp','sky.fp']
for name in names:
    src=args.space_root/'assets/space'/name;out=dest/'space'/name;out.parent.mkdir(parents=True,exist_ok=True)
    if name.endswith('.png'):shutil.copyfile(src,out)
    else:out.write_text(src.read_text().replace('/assets/space/',prefix+'/space/'),encoding='utf8')
write(dest/'profiles.lua',(args.space_root/'main/space_profiles.lua').read_text())
write(dest/'preview.collection',(base/'preview.collection').read_text()+instance('review_sky',component('mesh',prefix+'/space/sky.mesh')))
write(dest/'preview.render',f'script: "{prefix}/preview.render_script"\n')
render=(base/'preview.render_script').read_text()
render='local profiles=require "tests.station_exterior_preview.combined.profiles"\n'+render
render=render.replace('self.model=render.predicate({"model"})','self.sky=render.predicate({"space_sky"});self.constants=render.constant_buffer()\n self.model=render.predicate({"model"})')
render=render.replace('render.enable_state(graphics.STATE_DEPTH_TEST);', '''render.disable_state(graphics.STATE_DEPTH_TEST);render.disable_state(graphics.STATE_CULL_FACE);render.set_depth_mask(false)
 render.draw(self.sky,{constants=self.constants});render.set_depth_mask(true)
 render.enable_state(graphics.STATE_DEPTH_TEST);''',1)
render=render.replace('self.view=m.view;self.projection=m.projection','''self.view=m.view;self.projection=m.projection
  local p=profiles.get(m.system or "sol");local c=self.constants
  c.cloud_color=vmath.vector4(p.color[1],p.color[2],p.color[3],1)
  c.edge_color=vmath.vector4(p.edge[1],p.edge[2],p.edge[3],1)
  local q=vmath.quat_rotation_y(p.yaw)*vmath.quat_rotation_x(p.pitch)
  c.rotation=vmath.vector4(q.x,q.y,q.z,q.w)
  c.structure=vmath.vector4(p.threshold,p.mix,p.star_gain,p.exposure)
  c.sun_direction=vmath.vector4(p.light_direction[1],p.light_direction[2],p.light_direction[3],1)''')
write(dest/'preview.render_script',render)
profile=(ROOT/'assets/materials/stations/stations.texture_profiles').read_text()
write(dest/'preview.texture_profiles',f'path_settings {{ path: "{prefix}/space/fields.cubemap" profile: "Station" }}\n'+profile)
write(dest/'preview.ini',f'[bootstrap]\nmain_collection = {prefix}/preview.collectionc\nrender = {prefix}/preview.renderc\n[project]\ntitle = Station Exterior Review\n[graphics]\ntexture_profiles = {prefix}/preview.texture_profiles\n')
print('Use --settings tests/station_exterior_preview/combined/preview.ini for optional combined review')
