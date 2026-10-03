local alive, released, attached = true, false, nil
hash = function(x) return x end
go = {
 property=function() end, get=function() return "placeholder" end,
 set=function(_,name,value) if name == "vertices" then attached=value end end,
 delete=function() alive=false end,
}
buffer = {VALUE_TYPE_FLOAT32=1, create=function() return {} end,
 get_stream=function(b,name) b[name]={}; return b[name] end,
 set_metadata=function(b,_,data) b.bounds=data end}
local owned
resource = {
 create_buffer=function(_,params) owned=params.buffer; return "unique" end,
 get_buffer=function() return owned end, set_buffer=function() end,
 release=function(path) assert(attached=="placeholder"); assert(path=="unique"); released=true end,
}
vmath = {vector4=function(...) return {...} end}
dofile("main/asteroid.script")
local self={seed=123}
init(self)
assert(attached=="unique" and #owned.position==15840)
assert(owned.bounds[1]==-0.5)
on_message(self,"disintegrate")
assert(owned.bounds[1]==-2)
update(self,1)
on_message(self,"disintegrate") -- duplicates must not restart the effect
assert(self.age==1 and alive)
update(self,0.999)
assert(alive)
update(self,0.0011)
assert(not alive and self.age==2)
final(self)
assert(released)
-- A field change can delete an intact rock; still release its unique buffer.
released=false
self={seed=123}; init(self); final(self); assert(released)
