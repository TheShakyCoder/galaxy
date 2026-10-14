package.path='./?.lua;'..package.path
local calls,rotations={},{}
local textures={}
for _,n in ipairs({'verge','tope','molt','hydrogen','mutual','current','civic','logistics'}) do textures[n]=newproxy() end
go={set=function(url,prop,value) calls[#calls+1]={url,prop,value} end,set_rotation=function(q,url) rotations[url]=q end}
msg={post=function(url,message) calls[#calls+1]={url,message} end}
vmath={vector4=function(...) return {...} end,quat_rotation_z=function(a) return a end}
local ads=require 'main.station_ads'
local visual=require 'main.station_visual'
local a=visual.create('accord',textures)
local b=visual.create('swarm',textures)
assert(#a.components==10 and #b.components==10)
assert(not ads.set_ad('absent',1,'verge'))
for _,slot in ipairs({0,9,1.5}) do assert(not ads.set_ad(a.prefix,slot,'verge')) end
assert(not ads.set_ad(a.prefix,1,'missing'))
assert(not ads.set_ad(a.prefix,1,{}))
assert(ads.set_ad(a.prefix,8,'verge'))
assert(calls[#calls][1]=='accord_outpost_ad8#model' and calls[#calls][3]==textures.verge)
local dynamic=newproxy();assert(ads.set_ad(a.prefix,3,dynamic))
assert(calls[#calls][3]==dynamic)
local function check_visibility(s,visible)
 calls={};visual.update(s,0,visible)
 local seen={};for _,c in ipairs(calls) do if c[2]=='enable' or c[2]=='disable' then seen[c[1]]=c[2] end end
 for _,url in ipairs(s.components) do assert(seen[url]==(visible and 'enable' or 'disable'),url) end
end
check_visibility(a,false);check_visibility(b,false)
check_visibility(a,true);check_visibility(b,true)
visual.update(a,110,true);assert(math.abs(a.phase)<1e-10 or math.abs(a.phase-2*math.pi)<1e-10)
visual.update(b,120,true);assert(math.abs(b.phase)<1e-10 or math.abs(b.phase-2*math.pi)<1e-10)
local old=a.phase;check_visibility(a,false);visual.update(a,100,false);assert(a.phase==old)
check_visibility(a,true);a.speed=0;visual.update(a,20,true);assert(a.phase==old)
check_visibility(a,false);check_visibility(b,false)
-- Re-enabling a destroyed/unavailable station restores every billboard and rotor.
check_visibility(b,true)
assert(rotations['swarm_outpost_rotor']~=nil and rotations['swarm_outpost']==nil,'fixed dock rotated')
visual.final(a);assert(not ads.set_ad(a.prefix,1,'verge'))
visual.final(b)
print('Station exterior lifecycle, rotation and ad API checks passed')

-- Execute the actual production observer through launch, faction denial,
-- destruction, jump, respawn and docking without modifying session state.
local flying=false;local system='sol';local availability={accord=true,swarm=false}
local observed={}
package.loaded['main.session']={get_current_system=function()return system end,outpost_available=function(id,f)return availability[f] end}
local session=package.loaded['main.session']
package.loaded['main.station_visual']={create=function(f) return {faction=f} end,update=function(s,dt,on)observed[s.faction]=on end,final=function()end,light=function()end}
go.property=function()end;resource={texture=function(path)return path end};hash=function(v)return v end
dofile('main/stations.script')
local self={};for k,v in pairs(textures)do self[k]=v end
init(self);session.flying=false;update(self,.016);assert(not observed.accord and not observed.swarm)
session.flying=true;update(self,.016);assert(observed.accord and not observed.swarm)
availability.accord=false;update(self,.016);assert(not observed.accord)
system='polaris';availability.swarm=true;update(self,.016);assert(observed.swarm)
availability.accord=true;update(self,.016);assert(observed.accord)
system=nil;update(self,.016);assert(not observed.accord and not observed.swarm)
system='sol';session.flying=false;update(self,.016);assert(not observed.accord and not observed.swarm)
final(self)
print('Production station observer launch/jump/destruction/respawn/dock checks passed')
