-- Standalone harness for main/shot_hub.script. Confirms the "shot" message
-- actually spawns one tracer per requested tracer (the three-streak autocannon
-- burst), that they are staggered rather than simultaneous, and that a weapon's
-- plain-triple `shot_scale` is converted and applied. Run with:
--   luajit tests/shot_hub_harness.lua
hash = function(x) return x end

local vec = {}
vec.__index = vec
function vec.__add(a, b) return setmetatable({x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}, vec) end
function vec.__sub(a, b) return setmetatable({x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}, vec) end
function vec.__mul(a, b)
	if type(b) == "number" then return setmetatable({x = a.x * b, y = a.y * b, z = a.z * b}, vec) end
	return setmetatable({x = a.x * b.x, y = a.y * b.y, z = a.z * b.z}, vec)
end
local function v3(x, y, z) return setmetatable({x = x or 0, y = y or 0, z = z or 0}, vec) end
vmath = {
	vector3 = v3,
	vector4 = function(x, y, z, w) return {x = x, y = y, z = z, w = w} end,
	length = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end,
	normalize = function(v) local l = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z); return v3(v.x / l, v.y / l, v.z / l) end,
	quat = function() return {x = 0, y = 0, z = 0, w = 1} end,
	quat_from_to = function() return {x = 0, y = 0, z = 0, w = 1} end,
}

local created, timers = {}, {}
factory = { create = function(_, pos, rot, props, scale)
	local id = #created + 1
	created[id] = { pos = pos, scale = scale }
	return id
end }
go = { set = function() end, animate = function() end, delete = function() end }
msg = { url = function(_, id, c) return {id = id, component = c} end }
timer = { delay = function(delay, repeating, fn) timers[#timers + 1] = {delay = delay, fn = fn} end }
local sounds = {}
local audio_stub = { play = function(url, pos, opts) sounds[#sounds + 1] = {url = url, pos = pos} end }
package.loaded["main.audio"] = audio_stub

dofile("main/shot_hub.script")

local self = {}
local shot = {
	from = v3(0, 0, 0),
	to = v3(0, 0, 200),   -- 200 m away
	origin = v3(1, 0, 0),
	tracers = 3,
	scale = { 0.33, 0.33, 3.96 }, -- a weapon's plain numeric triple
	speed = 600,
}

on_message(self, "shot", shot)

assert(#timers == 3, "three tracers should be scheduled, got " .. #timers)
-- 200 m at 600 m/s = 0.3333 s of flight; a quarter of that apart.
local duration = 200 / 600
local stagger = 0.25 * duration
assert(math.abs(timers[1].delay - 0) < 1e-9, "first streak should launch immediately")
assert(math.abs(timers[2].delay - stagger) < 1e-9, "second streak should be staggered")
assert(math.abs(timers[3].delay - 2 * stagger) < 1e-9, "third streak should be staggered twice")
assert(#created == 0, "no streak should exist before its own delay elapses")

-- Fire the timers in order; each closure must create exactly one streak.
for _, t in ipairs(timers) do t.fn() end
assert(#created == 3, "three factory tracers should have been created, got " .. #created)
for i, c in ipairs(created) do
	assert(math.abs(c.scale.x - 0.33) < 1e-9 and math.abs(c.scale.y - 0.33) < 1e-9 and math.abs(c.scale.z - 3.96) < 1e-9,
		"streak " .. i .. " should carry the weapon's converted scale")
end
assert(#sounds == 1, "the firing sound should play once per shot, not per streak")

-- A single-tracer weapon (the default) must still draw exactly one.
timers, created, sounds = {}, {}, {}
on_message(self, "shot", { from = v3(0, 0, 0), to = v3(0, 0, 100), origin = v3() })
assert(#timers == 1 and #sounds == 1, "a default shot should be a single tracer")
timers[1].fn()
assert(#created == 1, "a default shot should create one tracer")

print("shot_hub harness: all assertions passed")
