hash=function(x) return x end
local vector = {}
vector.__sub=function(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},vector) end
vmath={vector3=function(x,y,z) return setmetatable({x=x,y=y,z=z},vector) end,
 vector4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end,
 length=function(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end}
local field={{x=1,y=2,z=3,diameter_m=10,resource="iron"},{x=2,y=3,z=4,diameter_m=20,resource="iron"}}
local states, live, messages, timers, created = {}, {}, {}, {}, {}
local registry=require("main.asteroid_registry")
package.loaded['main.data.asteroids']={field_for=function() return field end,
 RESOURCE_BY_ID={iron={tint={1,1,1}}},RESOURCES={{id="iron",name="Iron"}}}
package.loaded['main.network']={asteroid_state=function(_,index) return states[index] end}
msg={url=function(_,id,component) return {id=id,component=component} end,
 post=function(url,event,data) messages[#messages+1]={url=url,event=event,data=data} end}
go={set=function(url) assert(live[url.id],"setting deleted object") end,
 cancel_animations=function(url) assert(live[url.id],"animating deleted object") end,
 animate=function() end,delete=function(id) live[id]=nil end,exists=function(id) return live[id] end}
factory={create=function(_,pos,rot,props,scale)
 local id=#created+1; created[id]={props=props,scale=scale}; live[id]=true; return id
end}
timer={delay=function(_,_,fn) timers[#timers+1]=fn; return #timers end,cancel=function(i) timers[i]=false end}
dofile('main/asteroid_hub.script')
local self={}
on_message(self,'spawn_field',{system_id='sol'})
assert(#registry.asteroids==2 and created[1].props.seed~=created[2].props.seed)
local original_seed=created[1].props.seed
on_message(self,'analyse',{position=vmath.vector3(0,0,0),range=100,scan_time=1})
states[1]={available=false}
update(self,0.016)
assert(#registry.asteroids==1 and registry.by_index[1]==nil and live[1])
assert(timers[1]==false)
local explosions=0
for _,m in ipairs(messages) do if m.event=='disintegrate' then explosions=explosions+1 end end
assert(explosions==1)
local message_count=#messages
update(self,0.016); assert(#messages==message_count)
states[1]={available=true}; update(self,0.016)
assert(#registry.asteroids==2 and created[3].props.seed==original_seed)
-- Jump while debris is alive; cached depletion must not spawn/explode a ghost.
states[1]={available=false}
on_message(self,'spawn_field',{system_id='other'})
assert(not live[1] and not live[2] and not live[3])
assert(#registry.asteroids==1 and registry.by_index[1]==nil)
final(self)
assert(next(live)==nil and #registry.asteroids==0)
