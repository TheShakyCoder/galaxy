-- Standalone harness for main/starfield.script (same approach as the other
-- tests/ harnesses: stub just enough of Defold's API to drive the real script
-- functions directly, then assert on the numbers). Verifies the behaviour this
-- effect actually claims: the field is built at launch and is LEFT IN PLACE
-- while the ship is idle; dust streams astern at DUST_SPEED_FACTOR x the ship's
-- speed, along the ship's own front-to-back axis; turning the ship changes the
-- direction of travel but must NOT drag the motes sideways; and launches/jumps
-- (teleports) are ignored.
-- Run with: luajit tests/starfield_harness.lua
hash = function(x) return x end

-- Minimal vector/quaternion math, enough for the script's own arithmetic.
local vec = {}
vec.__index = vec
function vec.__add(a, b) return setmetatable({x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}, vec) end
function vec.__sub(a, b) return setmetatable({x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}, vec) end
function vec.__mul(a, b)
	if type(b) == "number" then return setmetatable({x = a.x * b, y = a.y * b, z = a.z * b}, vec) end
	return setmetatable({x = a.x * b.x, y = a.y * b.y, z = a.z * b.z}, vec)
end
local function v3(x, y, z) return setmetatable({x = x or 0, y = y or 0, z = z or 0}, vec) end
local function cross(a, b) return v3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x) end
local function rotate(q, v)
	local u = v3(q.x, q.y, q.z)
	local t = cross(u, v) * 2
	return v + t * q.w + cross(u, t)
end
vmath = {
	vector3 = v3,
	vector4 = function(x, y, z, w) return {x = x, y = y, z = z, w = w} end,
	quat = function() return {x = 0, y = 0, z = 0, w = 1} end,
	quat_axis_angle = function(axis, a) return {x = axis.x * math.sin(a / 2), y = axis.y * math.sin(a / 2), z = axis.z * math.sin(a / 2), w = math.cos(a / 2)} end,
	rotate = rotate,
	length = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end,
}

-- The one ship instance the script reads, and the motes it creates.
local ship = { pos = v3(0, 0, 0), rot = vmath.quat() }
local live, created, posted = {}, {}, {}
go = {
	get_position = function() return ship.pos end,
	get_rotation = function() return ship.rot end,
	set_position = function(pos, id) assert(live[id], "setting a deleted mote"); live[id].pos = pos end,
	set = function(url) assert(live[url.id], "setting a deleted mote") end,
}
factory = { create = function(_, pos, rot, props, scale)
	local id = #created + 1
	created[id] = { pos = pos, scale = scale }
	live[id] = { pos = pos }
	return id
end }
msg = {
	url = function(_, id, component) return {id = id, component = component} end,
	post = function(url, event) posted[#posted + 1] = {id = url, event = event} end,
}

dofile("main/starfield.script")

local dt = 0.1
local function count_events(name)
	local n = 0
	for _, p in ipairs(posted) do if p.event == name then n = n + 1 end end
	return n
end
local function same_pos(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local self = {}
init(self)

-- --- 1. not flying yet: nothing ---------------------------------------------
update(self, dt)
assert(#self.motes == 0 and #created == 0, "no motes before flight")

-- --- 2. launch builds and shows the field; IDLE leaves it in place ----------
on_message(self, "start", {})
assert(#self.motes == 60 and #created == 60, "the pool should be built at launch")
assert(self.visible == true, "the field should be visible from launch")
local idle_before = self.motes[1].pos
posted = {}
update(self, dt) -- the ship has not moved: speed 0
assert(same_pos(self.motes[1].pos, idle_before), "idle motes must stay exactly in place")
assert(#posted == 0, "idle must not enable or disable anything")
assert(self.visible == true, "idle must keep the field visible")

-- --- 3. moving: the field stays up ------------------------------------------
ship.pos = v3(0, 0, 1.0) -- 10 m/s * 0.1 s, forward +Z
update(self, dt)
assert(#self.motes == 60 and self.visible == true, "the field survives moving")

-- --- 4. perceived speed = DUST_SPEED_FACTOR x the ship's speed ---------------
-- Park a mote dead ahead so the result is not at the mercy of the recycle
-- edges, then advance the ship one more metre.
local forward = vmath.rotate(ship.rot, v3(0, 0, 1))
local function lz_of(mote) local rel = mote.pos - ship.pos; return rel.x * forward.x + rel.y * forward.y + rel.z * forward.z end
self.motes[1].pos = ship.pos + forward * 10
local before = lz_of(self.motes[1])
ship.pos = v3(0, 0, 2.0)
update(self, dt)
local after = lz_of(self.motes[1])
assert(math.abs((before - after) - 1.0) < 1e-9,
	"perceived speed should be DUST_SPEED_FACTOR*10 m/s (1.0 per 0.1 s), got " .. (before - after))

-- --- 5. turning must NOT drag the dust sideways -----------------------------
-- THE regression this world-space rewrite is about: a left turn used to rotate
-- the whole field with the ship, sliding every mote left. Place a mote near the
-- ship's axis, yaw the ship 90 degrees (still moving, so the field updates),
-- and assert the mote's WORLD position is untouched.
self.motes[2].pos = ship.pos + forward * 5
local p = self.motes[2].pos
local px, py, pz = p.x, p.y, p.z
ship.rot = vmath.quat_axis_angle(v3(0, 1, 0), math.pi / 2)
ship.pos = v3(ship.pos.x + 1.0, ship.pos.y, ship.pos.z) -- keep moving (10 m/s)
update(self, dt)
local w = self.motes[2].pos
assert(w.x == px and w.y == py and w.z == pz,
	"a turn must not move the dust sideways (mote moved to " .. w.x .. "," .. w.y .. "," .. w.z .. ")")

-- --- 6. a teleport must not fling or hide the field -------------------------
local teleport_before = self.motes[1].pos
ship.pos = v3(1000, 0, 0) -- one frame of impossible movement reads as idle
update(self, dt)
assert(same_pos(self.motes[1].pos, teleport_before), "a teleport frame must not move the dust")
assert(self.visible == true, "a teleport frame must not hide the dust")

-- --- 7. moving again recycles the field back around the ship ----------------
ship.pos = v3(1001, 0, 0) -- 10 m/s again
update(self, dt)
local fwd = vmath.rotate(ship.rot, v3(0, 0, 1))
for _, mote in ipairs(self.motes) do
	local rel = mote.pos - ship.pos
	local lz = rel.x * fwd.x + rel.y * fwd.y + rel.z * fwd.z
	local lat = vmath.length(rel - fwd * lz)
	assert(lz > -120 - 1e-6 and lz < 80 + 1e-6 and lat <= 30 + 1e-6,
		"every mote should be back inside the slab around the ship after a teleport")
end

-- --- 8. stopping the flight disables everything -----------------------------
posted = {}
on_message(self, "stop", {})
assert(self.visible == false and count_events("disable") == 60, "stop should disable every mote")
local frozen = self.motes[1].pos
ship.pos = v3(1002, 0, 0)
update(self, dt) -- must do nothing while docked
assert(same_pos(self.motes[1].pos, frozen), "an inactive starfield must not move")

print("starfield harness: all assertions passed")
