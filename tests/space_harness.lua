package.path='./?.lua;'..package.path
local profiles=require 'main.space_profiles'
local systems=require 'main.data.star_systems'
local count=0;local seeds={};local variants={}
local real_random=math.random
math.random=function() error('Cosmetic profiles must not consume gameplay PRNG') end
for id in pairs(systems.SYSTEMS) do
    local a,b=profiles.get(id),profiles.get(id)
    assert(a.seed==b.seed and a.yaw==b.yaw and a.mix==b.mix)
    assert(not seeds[a.seed]);seeds[a.seed]=true
    assert(a.threshold>=.15 and a.threshold<.55)
    local d=a.light_direction
    assert(math.abs(d[1]^2+d[2]^2+d[3]^2-1)<1e-10)
    assert(a.star_gain>0 and a.exposure==1)
    variants[a.name]=true;count=count+1
end
assert(count==58)
assert(profiles.get('sol').name~=profiles.get('polaris').name)
math.random=real_random

-- Exercise the production observer through dock/launch/jump/logout.
local session={flying=false,current='sol'}
session.get_current_system=function() return session.current end
package.loaded['main.session']=session
local messages={}
msg={post=function(url,id,data) messages[#messages+1]={url=url,id=id,data=data} end}
dofile('main/space.script')
local observer={};init(observer);update(observer)
assert(messages[#messages].data.visible==false)
session.flying=true;update(observer)
assert(messages[#messages].data.visible==true and messages[#messages].data.system_id=='sol')
local before=#messages;update(observer);assert(#messages==before,'No per-frame messages')
session.current='polaris';update(observer);assert(messages[#messages].data.system_id=='polaris')
session.flying=false;update(observer);assert(not messages[#messages].data.visible)
session.current=nil;update(observer);assert(not messages[#messages].data.visible)
final(observer);assert(not messages[#messages].data.visible)

-- Check pass isolation and depth state. A disabled camera must never show a sky.
hash=function(x) return x end
vmath={vector4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end,
    quat_rotation_y=function() return setmetatable({x=0,y=0,z=0,w=1},{__mul=function(a,b) return b end}) end,
    quat_rotation_x=function() return {x=0,y=0,z=0,w=1} end}
graphics={STATE_DEPTH_TEST='depth',STATE_CULL_FACE='cull',STATE_BLEND='blend'}
local calls={};local cameras={1,2};local enabled={[1]=true,[2]=true}
camera={get_cameras=function() return cameras end,get_enabled=function(id) return enabled[id] end,
get_view=function(id) return 'view'..id end,get_projection=function(id) return 'proj'..id end}
render={predicate=function(tags) return tags[1] end,constant_buffer=function() return {} end,
get_window_width=function() return 1920 end,get_window_height=function() return 1080 end}
for _,name in ipairs({'set_camera','set_viewport','set_view','set_projection','disable_state','set_depth_mask','draw'}) do
    local key=name;render[key]=function(...) calls[#calls+1]={key,...} end
end
local renderer=require 'render.space'
local state=renderer.create();renderer.draw(state);assert(#calls==0)
renderer.configure(state,{visible=true,system_id='sol'});renderer.draw(state)
assert(calls[1][1]=='set_camera')
assert(calls[3][2]=='view2','Last enabled camera must match world pass')
assert(calls[#calls][1]=='set_depth_mask' and calls[#calls][2]==true)
local draw=calls[#calls-1];assert(draw[1]=='draw' and draw[2]=='space_sky' and draw[3].frustum==nil)
enabled[2]=false;calls={};renderer.draw(state);assert(calls[3][2]=='view1')
enabled[1]=false;calls={};renderer.draw(state);assert(#calls==0)
renderer.configure(state,{visible=false});renderer.draw_wisps(state,{});assert(#calls==0)
print('PASS: 58 deterministic profiles; observer lifecycle; sky render isolation/state')
