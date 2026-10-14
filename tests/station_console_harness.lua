-- Presentation checks against real authored node IDs, plus scoped rig lifecycle.
package.path='./?.lua;./?/init.lua;'..package.path
local function v(x,y,z,w) return {x=x or 0,y=y or 0,z=z or 0,w=w} end
vmath={vector3=v,vector4=v,quat_rotation_y=function(a) return a end}
hash=function(s) return s end
local nodes,created={},{}
local f=assert(io.open('main/outpost.gui'));local source=f:read('*a');f:close()
for id in source:gmatch('id:%s*"([^"]+)"') do nodes[id]={id=id,enabled=true} end
local function new(pos,size) local n={pos=pos,size=size,enabled=true};created[#created+1]=n;return n end
gui={PIVOT_CENTER='center',PIVOT_W='west',SIZE_MODE_MANUAL='manual',
 get_node=function(id) return assert(nodes[id],'Unknown authored node '..id) end,
 new_box_node=new,new_text_node=function(pos,value) local n=new(pos);n.text=value;return n end,
 get_font=function() return 'font' end,get_font_resource=function() return 'font' end,
 move_above=function(n,target) n.above=target end,move_below=function(n,target) n.below=target end}
for _,entry in ipairs({'position:pos','size:size','pivot:pivot','color:color','scale:scale','enabled:enabled','texture:texture','text:text','font:font','slice9:slice9','size_mode:size_mode','line_break:line_break'}) do
 local method,key=entry:match('(.+):(.+)');gui['set_'..method]=function(n,value) assert(n);n[key]=value end
end
gui.get_text=function(n) return n.text or "" end
gui.play_flipbook=function(n,name) n.image=name end
resource={get_text_metrics=function(_,value,options)
 local lines=0;for line in (value..'\n'):gmatch('(.-)\n') do lines=lines+math.max(1,math.ceil(#line*13/options.width)) end
 return {height=lines*28}
end}
local console=require('main.ui.station_console')
local self={tab_nodes={}}
for _,page in ipairs({'overview','fitting','ships','map','skins'}) do self.tab_nodes[page]=nodes['tab_'..page] end
console.init(self)
assert(#created<80,'Unbounded decorative node allocation')
assert(nodes.overview_heading.above==nodes.overview_panel,'Dossier heading covered by its panel')
assert(nodes.overview_vessel.pivot=='center','Legacy top pivot leaked into new caption')
local count=#created
for cycle=1,20 do
 for _,faction in ipairs({'accord','swarm'}) do
  for _,page in ipairs({'overview','fitting','ships','map','skins'}) do
   console.page(self,page,faction)
   assert(nodes.background.image==faction)
   assert(self.console_scrim.enabled==(page~='overview'))
   for _,n in ipairs(self.console_overview) do assert(n.enabled==(page=='overview')) end
   assert(self.tab_nodes[page].image=='button_active')
  end
 end
end
assert(#created==count,'Switching tabs leaks nodes')
console.refresh(self,{faction='The Accord',rank='Coxswain',level=4,xp='12,000',next_xp='16,000',xp_fraction=3/7,home='Sol',docked='Polaris',filled={W=2,H=1},components={W=3,C=2,E=4,H=2},summary='1 hull / 0 spares',assignments=string.rep('Long assignment description ',30)})
assert(self.console_rows[1].value.text=='2 / 3')
assert(self.console_rows[4].value.text=='1 / 2')
assert(math.abs(self.console_xp.size.x-108)<.001,'XP fraction must use this level interval')
assert(nodes.overview_assignments.scale.x<.78,'Long server text must fit its bounds')
console.refresh(self,{faction='The Swarm',rank='Hatchling',level=1,xp='0',next_xp='1,000',xp_fraction=-1,home='Polaris',docked='Polaris',filled={},components={},summary='',assignments='No assignments available.'})
assert(self.console_xp.size.x==0)
assert(self.console_rows[1].progress.size.x==0,'Zero-capacity slots must not divide by zero')

local pose=require('main.ui.station_pose')
local position=v(100000,2000,0); local rotation
go={get_position=function() return position end,set_rotation=function(r) rotation=r end,set=function() end}
dofile('main/ship_preview.script')
local rig={};pose.set(nil);update(rig,1)
assert(math.abs(rotation-math.rad(30))<.001,'Normal grid rotation changed')
pose.set(position);update(rig,1)
assert(math.abs(rotation-math.rad(71))<.001,'Docked hero orientation missing')
pose.set(v(100000,3000,0));update(rig,1)
assert(math.abs(rotation-math.rad(90))<.001,'Unselected rig was affected')
pose.set(position);update(rig,1)
assert(math.abs(rotation-math.rad(71))<.001,'Re-entering the berth must reset framing')
pose.set(nil);update(rig,1)
assert(not rig.dock_time,'Dock state leaked after exit')
print('PASS station console: real IDs, all tabs/factions, bounded nodes, data gauges, text bounds, scoped preview lifecycle')

-- Render messages must clear dock mode, custom viewport and pose on every exit.
dofile('render/custom.render_script')
local renderer={state={main_camera={}},preview={}}
local rect={x=354,y=275,w=1212,h=650}
on_message(renderer,'set_ship_preview',{visible=true,target_pos=position,rect=rect,dock=true})
assert(renderer.preview.rect==rect and renderer.preview.dock and pose.is_target(position))
on_message(renderer,'set_ship_preview',{visible=true,target_pos=position})
assert(renderer.preview.rect==nil and not renderer.preview.dock and not pose.is_target(position),'Detail preview inherited dock state')
on_message(renderer,'set_ship_preview',{visible=true,target_pos=position,rect=rect,dock=true})
on_message(renderer,'set_ship_preview',{visible=false})
assert(renderer.preview.rect==nil and not renderer.preview.dock and pose.target==nil,'Hidden preview retained dock state')
print('PASS station render messages: detail and launch reset viewport, material mode and pose')
