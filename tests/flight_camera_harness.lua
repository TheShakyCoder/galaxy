-- Standalone harness for flight mode's manual camera orbit (main/player_ship.script,
-- plan.md §2.10.3): holding LMB and moving the mouse swings the chase camera around
-- the ship; a plain click still targets whatever is under the cursor; and once the
-- player has stopped moving the camera for two seconds it eases back on its own - to
-- the plain rear chase view with nothing targeted, or to the ship-BETWEEN-camera-and-
-- target view when something is.
--
-- The engine globals (go/msg/vmath/camera/sound/socket) are stubbed and the modules
-- this script only talks to over the network or GPU are replaced with no-op tables, so
-- the whole thing runs under plain luajit:
--   luajit tests/flight_camera_harness.lua
--
-- Unlike tests/flight_speed_harness.lua this stub set needs REAL quaternion AND 4x4
-- matrix maths: everything here is asserted on the camera transform the script
-- publishes (go.set_rotation's "flight_camera" argument), and the click-versus-drag
-- cases need the script's own view-projection to put a target under the cursor.
package.path = "./?.lua;./?/init.lua;" .. package.path

hash = function(x) return x end

-- ---- vmath: real vector/quaternion/matrix maths ----
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
local function vdot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function vcross(a, b)
	return v3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end
local function vnorm(v)
	local l = vlen(v)
	return l == 0 and v3() or v3(v.x / l, v.y / l, v.z / l)
end
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
-- vmath.slerp takes the SHORTEST path (dlib flips the second quaternion when the dot
-- product is negative) - the path the script's camera easing relies on to come round
-- the near side of the ship rather than the long way.
local function qslerp(t, a, b)
	local d = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
	local bb = b
	if d < 0 then
		bb = setmetatable({ x = -b.x, y = -b.y, z = -b.z, w = -b.w }, quat)
		d = -d
	end
	if d > 0.9995 then
		return qnorm(setmetatable({
			x = a.x + (bb.x - a.x) * t, y = a.y + (bb.y - a.y) * t,
			z = a.z + (bb.z - a.z) * t, w = a.w + (bb.w - a.w) * t,
		}, quat))
	end
	local theta0 = math.acos(d)
	local theta = theta0 * t
	local s0 = math.sin(theta0 - theta) / math.sin(theta0)
	local s1 = math.sin(theta) / math.sin(theta0)
	return setmetatable({
		x = a.x * s0 + bb.x * s1, y = a.y * s0 + bb.y * s1,
		z = a.z * s0 + bb.z * s1, w = a.w * s0 + bb.w * s1,
	}, quat)
end
-- The shortest-arc quaternion rotating `from` onto `to`: normalize(cross(from, to),
-- 1 + dot). Degenerate for exactly opposite vectors, which is why the script's own
-- camera_aim_at() resolves that case itself before ever calling this.
local function qfrom_to(from, to)
	local f, t = vnorm(from), vnorm(to)
	local d = vdot(f, t)
	if d > 0.9999 then return quat.identity() end
	local axis = vcross(f, t)
	return qnorm(setmetatable({ x = axis.x, y = axis.y, z = axis.z, w = 1 + d }, quat))
end

-- ---- 4x4 matrices, row-major: row i, column j is `m[i * 4 + j + 1]` (the flat
-- table is 1-based, like every Lua table) ----
-- Only what the script's own view-projection needs: matrix * matrix and matrix *
-- vector4, in the same right-handed convention (a point in front of the camera has
-- w = -z_view > 0 - exactly what project() divides by).
local mat = {}
mat.__index = mat
local function new_matrix(m) return setmetatable({ m = m }, mat) end
mat.__mul = function(a, b)
	if getmetatable(b) == mat then
		local r = {}
		for i = 0, 3 do
			for j = 0, 3 do
				local s = 0
				for k = 0, 3 do s = s + a.m[i * 4 + k + 1] * b.m[k * 4 + j + 1] end
				r[i * 4 + j + 1] = s
			end
		end
		return new_matrix(r)
	end
	local r = {}
	for i = 0, 3 do
		r[i] = a.m[i * 4 + 1] * b.x + a.m[i * 4 + 2] * b.y + a.m[i * 4 + 3] * b.z + a.m[i * 4 + 4] * b.w
	end
	return { x = r[0], y = r[1], z = r[2], w = r[3] }
end

-- General 4x4 inverse (Gauss-Jordan), for pick_target's unprojected click ray.
local function mat_inv(a)
	local n, inv = {}, {}
	for i = 1, 16 do n[i] = a.m[i]; inv[i] = (i - 1) % 5 == 0 and 1 or 0 end
	for c = 0, 3 do
		local p = c
		for r = c + 1, 3 do
			if math.abs(n[r * 4 + c + 1]) > math.abs(n[p * 4 + c + 1]) then p = r end
		end
		for k = 0, 3 do
			n[c * 4 + k + 1], n[p * 4 + k + 1] = n[p * 4 + k + 1], n[c * 4 + k + 1]
			inv[c * 4 + k + 1], inv[p * 4 + k + 1] = inv[p * 4 + k + 1], inv[c * 4 + k + 1]
		end
		local d = n[c * 4 + c + 1]
		for k = 0, 3 do
			n[c * 4 + k + 1] = n[c * 4 + k + 1] / d
			inv[c * 4 + k + 1] = inv[c * 4 + k + 1] / d
		end
		for r = 0, 3 do
			if r ~= c then
				local f = n[r * 4 + c + 1]
				for k = 0, 3 do
					n[r * 4 + k + 1] = n[r * 4 + k + 1] - f * n[c * 4 + k + 1]
					inv[r * 4 + k + 1] = inv[r * 4 + k + 1] - f * inv[c * 4 + k + 1]
				end
			end
		end
	end
	return new_matrix(inv)
end

vmath = {
	inv = mat_inv,
	vector3 = v3,
	vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
	quat = function(x, y, z, w)
		if x then return setmetatable({ x = x, y = y, z = z, w = w }, quat) end
		return quat.identity()
	end,
	quat_axis_angle = function(axis, angle)
		local half = angle / 2
		local s = math.sin(half)
		return setmetatable({ x = axis.x * s, y = axis.y * s, z = axis.z * s, w = math.cos(half) }, quat)
	end,
	quat_from_to = qfrom_to,
	conj = function(q) return setmetatable({ x = -q.x, y = -q.y, z = -q.z, w = q.w }, quat) end,
	slerp = qslerp,
	length = vlen,
	dot = vdot,
	cross = vcross,
	normalize = function(v)
		if getmetatable(v) == quat then return qnorm(v) end
		return vnorm(v)
	end,
	rotate = function(q, v) return qrotate(q, v) end,
	matrix4_look_at = function(eye, target, up)
		local z = vnorm(eye - target)
		local x = vnorm(vcross(up, z))
		local y = vcross(z, x)
		return new_matrix({
			x.x, x.y, x.z, -vdot(x, eye),
			y.x, y.y, y.z, -vdot(y, eye),
			z.x, z.y, z.z, -vdot(z, eye),
			0, 0, 0, 1,
		})
	end,
	matrix4_perspective = function(fov, aspect, near, far)
		local f = 1 / math.tan(fov / 2)
		return new_matrix({
			f / aspect, 0, 0, 0,
			0, f, 0, 0,
			0, 0, (far + near) / (near - far), (2 * far * near) / (near - far),
			0, 0, -1, 0,
		})
	end,
}

-- ---- go / msg / camera / sound / socket ----
local pos = v3()
local rot = quat.identity()
-- The camera object the script drives through component ids (go.set_position /
-- go.set_rotation with "flight_camera") - this harness's whole subject.
local cam_pos, cam_rot = nil, nil
local posted = {}
go = {
	property = function() end,
	get_id = function() return "player_ship" end,
	get_position = function() return pos end,
	set_position = function(p, id)
		if id == nil then pos = p else cam_pos = p end
	end,
	get_rotation = function() return rot end,
	set_rotation = function(r, id)
		if id == nil then rot = r else cam_rot = r end
	end,
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
camera = {
	get_view = function() return new_matrix({}) end,
	get_projection = function() return new_matrix({}) end,
	camera = {},
}
sound = { play = function() end, stop = function() end, set_speed = function() end }
socket = { gettime = function() return os.clock() end }
-- The script maps screen pixels through the window's own size (both the target marker
-- and pick_target do), so the window has to be a real one: 16:9 at the project's own
-- display resolution, which makes the GUI/design mapping exactly 1:1 (SCREEN_W/H).
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
	asteroids = {},
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

-- ---- The stub's own maths first, so a later failure is the script's ----
local CAMERA_FORWARD = v3(0, 0, -1)
local UP = v3(0, 1, 0)
local SHIP_FORWARD = v3(0, 0, 1)
local YAW_180 = vmath.quat_axis_angle(UP, math.pi)
check("harness self-check: quat_from_to rotates its `from` onto its `to`",
	vlen(vmath.rotate(qfrom_to(v3(0, 0, 1), v3(0, 1, 0)), v3(0, 0, 1)) - v3(0, 1, 0)) < 1e-6)
check("harness self-check: quat_axis_angle actually rotates",
	vlen(vmath.rotate(vmath.quat_axis_angle(UP, math.pi / 2), SHIP_FORWARD) - v3(1, 0, 0)) < 1e-6)

session.choose_faction("accord")
session.select_ship("patrol_interceptor")

local DT = 1 / 60
local function fly(ship, seconds)
	for _ = 1, math.max(1, math.floor(seconds / DT + 0.5)) do update(ship, DT) end
end
local function camera_forward()
	return vnorm(vmath.rotate(cam_rot, CAMERA_FORWARD))
end
local function chase_forward()
	return vnorm(vmath.rotate(rot * YAW_180, CAMERA_FORWARD))
end
local function angle_between(a, b)
	return math.acos(math.max(-1, math.min(1, vdot(a, b))))
end
-- Where the script's own project() puts a world point, so a click can be aimed at one
-- (view_proj/gui_half_w are the script's own published fields).
local function screen_of(ship, p)
	local v = ship.view_proj * vmath.vector4(p.x, p.y, p.z, 1)
	local inv = 1 / v.w
	return 1920 * 0.5 + v.x * inv * ship.gui_half_w, 1080 * 0.5 + v.y * inv * ship.gui_half_h
end
-- Fly it directly: start_flight() would go through session.launch(), the 24 model
-- components and the server sync, none of which this harness is about.
local function launch(ship)
	init(ship)
	ship.flying = true
	ship.ship_id = "patrol_interceptor"
	ship.current_system_id = session.get_current_system()
	fly(ship, 0.1)
	return ship
end

-- The chase camera's own distance/height come from the ship chassis (main/data/ships.lua's
-- `flight_camera`), not from the script's fallback constants - read them from there.
local ships = require("main.data.ships")
local FLIGHT_CAMERA = ships.SHIPS["patrol_interceptor"].flight_camera

local ship_state = launch({})
-- Input helpers: LMB press/release are action "touch", and the movement in between is
-- the engine's own unbound mouse-move action (action_id == nil).
local function press(x, y) return on_input(ship_state, "touch", { x = x, y = y, pressed = true }) end
local function release(x, y) return on_input(ship_state, "touch", { x = x, y = y, released = true }) end
local function move(x, y) return on_input(ship_state, nil, { x = x, y = y }) end

-- ---- A flight that has never been orbited behaves exactly as it did before ----
check("a fresh flight has no manual orbit yet",
	ship_state.camera_orbit_active == false and ship_state.camera_orbit_yaw == 0
		and ship_state.camera_orbit_pitch == 0 and ship_state.camera_press == nil)
check("the camera starts behind the ship's tail, looking along its nose",
	vlen(camera_forward() - v3(0, 0, 1)) < 1e-6)
check("...from the chassis' own flight_camera distance behind and height above the ship",
	vlen(cam_pos - v3(0, FLIGHT_CAMERA.height, -FLIGHT_CAMERA.distance)) < 1e-6)
check("mouse motion is not swallowed from the rest of the game", move(700, 400) == false)

-- ---- A locked target alone does NOT move the camera (only a manual orbit does) ----
remote_ships["foe"] = { pos = v3(0, 0, 100), speed = 0, faction = "swarm" }
ship_state.target_id = "foe"
fly(ship_state, 5)
check("targeting something does not by itself touch the camera",
	vlen(camera_forward() - chase_forward()) < 1e-6 and ship_state.camera_orbit_active == false)

-- ---- A plain click still targets whatever is under the cursor ----
local tx, ty = screen_of(ship_state, remote_ships["foe"].pos)
check("harness self-check: the target projects near the middle of a 16:9 window",
	math.abs(tx - 960) < 1 and ty > 500 and ty < 580)
ship_state.target_id = nil
press(tx, ty)
check("the press alone does not target yet", ship_state.target_id == nil)
release(tx, ty)
check("releasing on the same pixel is a click: it targets what is under the cursor",
	ship_state.target_id == "foe")
check("...and a click never starts a manual orbit", ship_state.camera_orbit_active == false)
check("...leaving the camera exactly where it was", vlen(camera_forward() - chase_forward()) < 1e-6)
ship_state.target_id = nil

-- ---- Mouse movement inside the click threshold is not yet a drag ----
press(960, 540)
move(958, 540)
check("a couple of pixels of jitter is not yet a drag",
	ship_state.camera_press and ship_state.camera_press.dragged == false)
-- ---- ...past it, it is: the camera starts swinging around the ship ----
move(940, 540)
check("moving past CAMERA_ORBIT_DRAG_THRESHOLD starts the drag",
	ship_state.camera_press.dragged == true and ship_state.camera_orbit_active == true)
check("the drag restarts the two-second countdown", ship_state.camera_orbit_idle == 0)
check("the offset follows the cursor's own pixels (only past the threshold)",
	math.abs(ship_state.camera_orbit_yaw - 18 * 0.008) < 1e-6)
fly(ship_state, 0.3)
check("the camera is swung off the chase axis while the drag is held",
	angle_between(camera_forward(), chase_forward()) > 0.05)
release(940, 540)
check("releasing ends the drag", ship_state.camera_press == nil)
fly(ship_state, 5)
check("an orbit and its return leave the camera back on the chase axis",
	vlen(camera_forward() - chase_forward()) < 1e-3)

-- ---- A drag that comes back to where it started is still a drag, not a click ----
-- Aimed at a pixel the click test above DID target at, so if pick_target ran on this
-- release the target would be set - it must not be, and the drag must still orbit.
ship_state.camera_orbit_active = false
local kx, ky = screen_of(ship_state, remote_ships["foe"].pos)
press(kx, ky)
move(kx - 10, ky)
move(kx, ky)
release(kx, ky)
check("a drag back to the press pixel is not a click: nothing gets targeted",
	ship_state.target_id == nil)
check("...but the drag did engage the manual orbit", ship_state.camera_orbit_active == true)
fly(ship_state, 5)

-- ---- Holding the button still keeps the view: the countdown waits for the release ----
press(960, 540)
move(900, 540)
fly(ship_state, 5) -- button still down, mouse not moving
check("while the button is held the countdown doesn't run",
	ship_state.camera_orbit_idle == 0 and ship_state.camera_orbit_yaw ~= 0)
check("...and the camera stays where the player put it",
	angle_between(camera_forward(), chase_forward()) > 0.3)
release(900, 540)
fly(ship_state, 1.9)
check("after the release the camera still waits out the two seconds",
	angle_between(camera_forward(), chase_forward()) > 0.3)
fly(ship_state, 5)
check("...then returns behind the ship", vlen(camera_forward() - chase_forward()) < 1e-3)

-- ---- Two seconds after the last manual movement, with no target: rear chase ----
press(960, 540)
move(900, 540) -- 60 px = 0.48 rad of yaw
release(900, 540)
fly(ship_state, 1.9)
check("before the countdown elapses the camera stays where the player left it",
	angle_between(camera_forward(), chase_forward()) > 0.3)
check("...with the countdown still running", ship_state.camera_orbit_idle >= 1.8)
fly(ship_state, 0.25)
check("once it idles past CAMERA_ORBIT_RETURN_DELAY the manual offset is dropped",
	ship_state.camera_orbit_yaw == 0 and ship_state.camera_orbit_pitch == 0)
fly(ship_state, 4)
check("with no target selected the camera eases back to the rear of the ship",
	vlen(camera_forward() - chase_forward()) < 1e-3)

-- ---- ...and with a target: the ship ends up BETWEEN camera and target ----
-- Target directly behind the ship, which is also the degenerate case for the aim
-- itself (the shortest arc between two exactly opposite vectors has no unique axis).
remote_ships["foe"].pos = v3(0, 0, -200)
ship_state.target_id = "foe"
fly(ship_state, 0.5)
press(960, 540)
move(900, 540)
release(900, 540)
fly(ship_state, 6) -- the two-second countdown, then the ease round to the target
local to_target = vnorm(remote_ships["foe"].pos - go.get_position())
check("with a target selected the camera turns to aim along the ship->target direction",
	vdot(camera_forward(), to_target) > 0.999)
check("the target is in front of the ship and the camera behind it - the ship is between them",
	vdot(cam_pos - go.get_position(), to_target) < -1)
check("...at the camera's own chase distance and height from the ship",
	math.abs(vlen(cam_pos - go.get_position())
		- math.sqrt(FLIGHT_CAMERA.distance ^ 2 + FLIGHT_CAMERA.height ^ 2)) < 0.01)
check("...without rolling: its up vector stays world-up",
	vdot(vnorm(vmath.rotate(cam_rot, UP)), UP) > 0.999)
-- ---- Clearing the target eases it back to the rear of the ship ----
ship_state.target_id = nil
fly(ship_state, 5)
check("clearing the target eases the camera back to the rear of the ship",
	vlen(camera_forward() - chase_forward()) < 1e-3)

-- ---- Grabbing the mouse again continues from where the camera already is ----
-- (a fresh drag seeds its offsets from the current view, so it never snaps back to an
-- angle measured from the plain chase view first - here the target-facing view is a
-- half turn away from it, so a snap would be unmissable)
ship_state.target_id = "foe"
fly(ship_state, 5)
local before = camera_forward()
press(960, 540)
move(950, 540) -- just past the threshold: its own 0.08 rad of yaw, nothing more
fly(ship_state, 0.3)
check("starting a drag continues from the current view instead of snapping to the chase view",
	angle_between(camera_forward(), before) < 0.1)
release(950, 540)
ship_state.target_id = nil
fly(ship_state, 5)

-- ---- The orbit's pitch is clamped short of straight up/down ----
press(960, 540)
move(960, 520)
for i = 1, 50 do move(960, 520 + i * 100) end -- 5000 px of drag downwards
-- Dragging down looks up (the vertical axis is inverted, per direct
-- instruction), so the clamp is reached at +MAX_PITCH here.
check("pitch is clamped at CAMERA_ORBIT_MAX_PITCH", math.abs(math.abs(ship_state.camera_orbit_pitch) - 1.4) < 1e-9)
fly(ship_state, 1)
check("...so the camera is never left looking straight down its own up vector",
	math.abs(camera_forward().y) < 0.99)
release(960, 1120)
fly(ship_state, 5)

-- ---- A flight that never orbits keeps the plain chase view even with a target ----
local fresh = launch({})
fresh.target_id = "foe"
fly(fresh, 5)
check("a flight that never orbits the camera is unaffected by having a target locked",
	fresh.camera_orbit_active == false and vlen(camera_forward() - chase_forward()) < 1e-6)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("flight_camera harness: all assertions passed.")
