-- World-space persistence, travel recycling, dock/launch and resource ownership.
package.path='./?.lua;'..package.path
hash=function(x) return x end
local vec={};vec.__index=vec
vec.__add=function(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},vec) end
vec.__sub=function(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},vec) end
vmath={vector3=function(x,y,z) return setmetatable({x=x or 0,y=y or x or 0,z=z or x or 0},vec) end,
vector4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end,
length=function(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end,
rotate=function(q,v) return v end}
local session={flying=false};package.loaded['main.session']=session
local pos=vmath.vector3();local calls={};local updates=0;local released=0
go={get=function() return 'original' end,set=function(url,key,value) calls[#calls+1]={url,key,value} end,
get_position=function() return pos end,get_rotation=function() return {} end}
msg={post=function(url,id) calls[#calls+1]={url,id} end}
buffer={VALUE_TYPE_FLOAT32=1,create=function() return {position={},normal={}} end,
get_stream=function(b,n) return b[n] end,set_metadata=function(b,k,v) b[k]=v end}
resource={create_buffer=function(path,args) assert(not args.transfer_ownership);return path end,
set_buffer=function(path,b) updates=updates+1 end,release=function() released=released+1 end}
local real_random=math.random;math.random=function() error('No gameplay PRNG use') end
dofile('main/space_wisps.script')
local s={};init(s);update(s);assert(updates==0)
session.flying=true;update(s);assert(updates==1 and #s.points==8)
local original=s.points[1];update(s);assert(updates==1 and s.points[1]==original,'Idle must not drift/recycle')
pos=vmath.vector3(0,0,1);update(s);assert(s.points[1]==original,'Near movement must preserve WORLD positions')
pos=vmath.vector3(8000,0,8000);update(s);assert(updates==2)
for _,p in ipairs(s.points) do assert(vmath.length(p-pos)<145) end
session.flying=false;update(s);assert(calls[#calls][2]=='disable')
session.flying=true;update(s);assert(updates==3 and calls[#calls][2]=='enable')
final(s);assert(released==1 and calls[#calls][3]=='original')
math.random=real_random
print('PASS: wisps stay in world space, recycle on travel/teleport, hide docked, release buffer')
