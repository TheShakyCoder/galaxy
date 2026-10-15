-- Standalone harness for the ten-segment flight throttle as main/player_ship.script
-- actually flies it (plan.md §2.10.2, main/flight_throttle.lua): the mouse wheel
-- and the throttle keys step the desired speed one segment at a time (0 = no
-- speed, 9 = the ship's own top speed), and the ship then accelerates or
-- decelerates to whatever the segment commands at its own acceleration.
--
-- The engine globals (go/msg/vmath/camera/sound/socket) are stubbed and the
-- modules this script only talks to over the network or GPU are replaced with
-- no-op tables, so the whole thing runs under plain luajit:
--   luajit tests/flight_speed_harness.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

hash = function(x) return x end

-- ---- vmath: real vector/quaternion maths, since heading and the actual speed
-- are read back out of the ship's position ----
local vec, quat = {}, {}
vec.__index, quat.__index = vec, quat
function vec.__add(a, b) return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }, vec) end
function vec.__sub(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vec) end
function vec.__mul(a, b)
	if type(b) == "number" then return setmetatable({ x = a.x * b, y = a.y * b, z = a.z * b }, vec) end
	return setmetatable({ x = a.x * b.x, y = a.y * b.y, z = a.z * b.z }, vec)
end
local function v3(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vec) end
local function vlen(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
local function qmul(a, b)
	return setmetatable({
		w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
		x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
		y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
		z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
	}, quat)
end
local function qnorm(q)
	local l = math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
	if l == 0 then return quat.identity() end
	return setmetatable({ x = q.x / l, y = q.y / l, z = q.z / l, w = q.w / l }, quat)
end
function quat.identity() return setmetatable({ x = 0, y = 0, z = 0, w = 1 }, quat) end
function quat.__mul(a, b) return qmul(a, b) end
local function qrotate(q, v)
	-- v' = v + 2 * qv x (qv x v + w * v)
	local qv = v3(q.x, q.y, q.z)
	local t = v3(
		qv.y * v.z - qv.z * v.y + q.w * v.x,
		qv.z * v.x - qv.x * v.z + q.w * v.y,
		qv.x * v.y - qv.y * v.x + q.w * v.z)
	return v3(
		v.x + 2 * (qv.y * t.z - qv.z * t.y),
		v.y + 2 * (qv.z * t.x - qv.x * t.z),
		v.z + 2 * (qv.x * t.y - qv.y * t.x))
end
-- A view/projection matrix is only ever multiplied by another one here, so
-- the stub only has to support that.
local matrix_mt = { __mul = function() return new_matrix() end }
function new_matrix() return setmetatable({}, matrix_mt) end

vmath = {
	vector3 = v3,
	vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
	quat = function() return quat.identity() end,
	quat_axis_angle = function(axis, angle)
		local half = angle / 2
		local s = math.sin(half)
		return setmetatable({ x = axis.x * s, y = axis.y * s, z = axis.z * s, w = math.cos(half) }, quat)
	end,
	quat_from_to = function() return quat.identity() end,
	conj = function(q) return setmetatable({ x = -q.x, y = -q.y, z = -q.z, w = q.w }, quat) end,
	slerp = function(_, a) return a end,
	length = vlen,
	dot = function(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end,
	cross = function(a, b)
		return v3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
	end,
	normalize = function(v)
		if getmetatable(v) == quat then return qnorm(v) end
		local l = vlen(v)
		return l == 0 and v3() or v3(v.x / l, v.y / l, v.z / l)
	end,
	rotate = function(q, v) return qrotate(q, v) end,
	matrix4_look_at = function() return new_matrix() end,
	matrix4_perspective = function() return new_matrix() end,
}

-- ---- go / msg / camera / sound / socket ----
local pos = v3()
local rot = quat.identity()
local posted = {}
go = {
	property = function() end,
	get_id = function() return "player_ship" end,
	get_position = function() return pos end,
	-- A component id means the chase camera (the script drives that object's
	-- transform too); without one it is the ship itself, which is what this
	-- harness measures.
	set_position = function(p, id) if id == nil then pos = p end end,
	get_rotation = function() return rot end,
	set_rotation = function(r, id) if id == nil then rot = r end end,
	get = function() return nil end,
	set = function() end,
	delete = function() end,
	animate = function() end,
}
msg = {
	post = function(url, message_id, message)
		posted[#posted + 1] = { url = url, id = message_id, message = message }
	end,
	url = function(_, id, c) return { id = id, component = c } end,
}
local function last_message(id)
	for i = #posted, 1, -1 do
		if posted[i].id == id then return posted[i] end
	end
end
camera = {
	get_view = function() return {} end,
	get_projection = function() return {} end,
	camera = {},
}
sound = { play = function() end, stop = function() end, set_speed = function() end }
socket = { gettime = function() return os.clock() end }
-- The target marker maps screen pixels through the window's own size
-- (update_gui_mapping).
local WINDOW = { x = 0, y = 0, width = 1920, height = 1080 }
window = {
	get_size = function() return WINDOW end,
	get_display_scale = function() return 1 end,
}

-- ---- Modules this script only drives through the engine/network ----
package.loaded["main.network"] = {
	send_transform = function() return false end,
	enter_system = function() end,
	set_outposts_callback = function() end,
	set_asteroids_callback = function() end,
	fire = function() end,
	report = function() end,
	-- Outpost state for the HUD's Outpost Progress readout and targeting
	-- (nothing known in these tests).
	outpost_state = function() return nil end,
	outpost_returns_in = function() return 0 end,
	asteroid_state = function() return nil end,
}
package.loaded["main.profile"] = { flush = function(fn) if fn then fn() end end, save = function() end }
package.loaded["main.audio"] = {
	play = function() end, play_loop = function() end, stop_loop = function() end, stop = function() end,
	set_speed = function() end, set_pan = function() end,
	set_listener = function() end, update_loop = function() end,
}
package.loaded["main.skin_flight"] = { apply = function() end, clear = function() end }
local remote_ships = {}
package.loaded["main.remote_registry"] = { ships = remote_ships, outposts = {} }
package.loaded["main.asteroid_registry"] = {
	asteroids = {}, -- what the radar's own rock blips iterate
	list = function() return {} end, get = function() return nil end,
}

dofile("main/player_ship.script")

local session = require("main.session")

local failures = 0
local function check(label, cond)
	if cond then
		print("PASS  " .. label)
	else
		failures = failures + 1
		print("FAIL  " .. label)
	end
end

session.choose_faction("accord")
session.select_ship("patrol_interceptor")
local TOP = session.ship_stat("patrol_interceptor", "speed_m_per_sec")
local ACCEL = session.ship_stat("patrol_interceptor", "acceleration_m_per_sec2")
check("the harness's ship has a real top speed and acceleration", TOP and TOP > 0 and ACCEL and ACCEL > 0)

local self = {}
init(self)
-- Fly it directly: start_flight() would go through session.launch(), the model
-- components and the server sync, none of which this harness is about.
self.flying = true
self.ship_id = "patrol_interceptor"
self.current_system_id = session.get_current_system()

local function wheel_up() on_input(self, "zoom_in", { value = 1, pressed = true, released = true }) end
local function wheel_down() on_input(self, "zoom_out", { value = 1, pressed = true, released = true }) end
local function key(action) on_input(self, action, { pressed = true }) end
local DT = 1 / 60
local function fly(seconds)
	local steps = math.floor(seconds / DT)
	for _ = 1, steps do update(self, DT) end
end
-- The actual speed the ship is travelling at, measured from where it moved in
-- one frame rather than read out of the script's own field. Advances the
-- simulation by exactly that one frame.
local function frame_speed()
	local before = go.get_position()
	local from = v3(before.x, before.y, before.z)
	update(self, DT)
	return vlen(go.get_position() - from) / DT
end

-- ---- The mouse wheel moves the desired speed one segment per notch ----
check("a launch starts on segment 0 (no speed)", self.speed_segment == 0)
wheel_up()
check("one wheel notch up is one segment", self.speed_segment == 1)
on_input(self, "zoom_in", { value = 0, pressed = false, released = true })
check("the wheel's own release does not move it again", self.speed_segment == 1)
for _ = 1, 20 do wheel_up() end
check("the wheel clamps at segment 9", self.speed_segment == 9)
wheel_down()
check("one wheel notch down is one segment", self.speed_segment == 8)
for _ = 1, 20 do wheel_down() end
check("the wheel clamps at segment 0", self.speed_segment == 0)

-- ---- The throttle keys move the same segment ----
key("throttle_up")
check("the throttle keys step the segment too", self.speed_segment == 1)
key("full_throttle")
check("E is full speed (segment 9)", self.speed_segment == 9)
key("stop_throttle")
check("Q is a stop (segment 0)", self.speed_segment == 0)
key("throttle_down")
check("stepping down from a stop stays at a stop", self.speed_segment == 0)

-- ---- The ship accelerates to the segment's speed, at its own acceleration ----
key("full_throttle")
local accel_seconds = TOP / ACCEL
local rising = true
local previous = 0
local reached_at = nil
local elapsed = 0
for _ = 1, math.floor((accel_seconds + 1) / DT) do
	elapsed = elapsed + DT
	local speed = frame_speed()
	if speed < previous - 1e-6 then rising = false end
	previous = speed
	if not reached_at and speed >= TOP - 1e-3 then reached_at = elapsed end
end
check("segment 9 commands exactly the ship's top speed", math.abs(self.speed - TOP) < 1e-6)
check("the ship accelerated smoothly, never slowing on the way up", rising)
check("it got there in about top-speed / acceleration seconds",
	reached_at and math.abs(reached_at - accel_seconds) < 0.1)
check("the speed on the HUD is the speed it is actually travelling at",
	math.abs(frame_speed() - TOP) < 1e-3)

-- ---- ...and decelerates to a lower segment, and to a stop ----
wheel_down()
wheel_down()
check("two notches down is segment 7", self.speed_segment == 7)
local segment_speed = 7 / 9 * TOP
fly(accel_seconds)
check("the ship settled at the segment's own commanded speed",
	math.abs(self.speed - segment_speed) < 1e-6)
key("stop_throttle")
local fall_at = nil
elapsed = 0
for _ = 1, math.floor((TOP / ACCEL + 1) / DT) do
	update(self, DT)
	elapsed = elapsed + DT
	if self.speed <= 1e-6 then fall_at = elapsed break end
end
check("closing the throttle stops the ship, over the same acceleration time",
	fall_at and math.abs(fall_at - segment_speed / ACCEL) < 0.1 and self.speed == 0)

-- ---- The desired speed is on the HUD, as segment + commanded m/sec ----
wheel_up(); wheel_up(); wheel_up(); wheel_up()
check("four notches up is segment 4", self.speed_segment == 4)
update(self, DT)
local throttle_message = last_message("set_throttle")
check("the HUD is told the segment and the speed it commands",
	throttle_message and throttle_message.message.segment == 4
		and throttle_message.message.max_segment == 9
		and math.abs(throttle_message.message.speed - 4 / 9 * TOP) < 1e-6)

-- ---- Match Speed (T) snaps to the nearest segment ----
remote_ships["friend"] = { pos = v3(0, 0, 100), speed = TOP / 2, faction = "accord" }
self.target_id = "friend"
key("match_speed")
check("Match Speed picks the segment nearest the target's speed", self.speed_segment == 5)
remote_ships["friend"].speed = TOP
key("match_speed")
check("matching a target at top speed is segment 9", self.speed_segment == 9)
remote_ships["friend"] = nil
self.target_id = nil

-- ---- Boost still overrides the segment while held (plan.md §2.1.1) ----
local BOOST = session.ship_stat("patrol_interceptor", "boost_speed_m_per_sec")
on_input(self, "boost", { pressed = true })
fly(BOOST / ACCEL + 0.5)
check("boost still pushes the ship past the selected segment's speed",
	math.abs(self.speed - BOOST) < 1e-6)
on_input(self, "boost", { released = true })
fly(BOOST / ACCEL + 0.5)
check("releasing boost drops back to the selected segment's speed",
	math.abs(self.speed - 9 / 9 * TOP) < 1e-6)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("flight_speed harness: all assertions passed.")
