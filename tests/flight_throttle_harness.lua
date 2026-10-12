-- Ad-hoc verification harness for main/flight_throttle.lua (plan.md §2.10):
-- the flight throttle as ten discrete speed segments, 0 (no speed) to 9 (the
-- ship's own top speed), which the mouse wheel and the throttle keys step one
-- notch at a time. Pure Lua - the module is engine-free - so run it with
-- luajit (or lua) from the Galaxy root:
--   luajit tests/flight_throttle_harness.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local throttle = require("main.flight_throttle")

local failures = 0
local function check(label, cond)
	if cond then
		print("PASS  " .. label)
	else
		failures = failures + 1
		print("FAIL  " .. label)
	end
end

-- ---- The segment range itself ----
check("ten segments, 0 to 9", throttle.SEGMENTS == 10 and throttle.MAX_SEGMENT == 9)

-- ---- Segment -> fraction of top speed ----
check("segment 0 is no speed", throttle.fraction(0) == 0)
check("segment 9 is full speed", throttle.fraction(9) == 1)
local even = true
for segment = 1, 9 do
	if math.abs(throttle.fraction(segment) - segment / 9) > 1e-12 then
		even = false
	end
end
check("the nine steps are an even split", even)

-- ---- Segment -> commanded speed, scaled by the ship's own top speed ----
local TOP = 52.5 -- Patrol Interceptor's speed_m_per_sec, main/data/ships.lua
check("segment 0 commands a stop", throttle.target_speed(0, TOP) == 0)
check("segment 9 commands the ship's top speed", math.abs(throttle.target_speed(9, TOP) - TOP) < 1e-9)
check("a middle segment commands its share of top speed",
	math.abs(throttle.target_speed(3, TOP) - 3 / 9 * TOP) < 1e-9)
local rising = true
local previous = -1
for segment = 0, 9 do
	local speed = throttle.target_speed(segment, TOP)
	if speed <= previous and segment > 0 then
		rising = false
	end
	previous = speed
end
check("every segment above 0 commands more speed than the one below it", rising)

-- ---- Clamping / rounding (the wheel and Q/E push past the ends) ----
check("Below 0 clamps to a stop", throttle.clamp(-7) == 0)
check("above 9 clamps to full speed", throttle.clamp(24) == 9)
check("a fractional segment rounds to the nearest notch", throttle.clamp(4.4) == 4 and throttle.clamp(4.6) == 5)
check("no segment at all reads as a stop", throttle.clamp(nil) == 0)
check("stepping down from 0 stays at 0", throttle.step(0, -1) == 0)
check("stepping up from 9 stays at 9", throttle.step(9, 1) == 9)
check("one notch up is one segment", throttle.step(4, 1) == 5)
check("the whole range is nine notches", throttle.step(0, 9) == 9)

-- ---- Speed -> segment (Match Speed, T) ----
check("a target at rest is segment 0", throttle.segment_for_speed(0, TOP) == 0)
check("a target at our top speed is segment 9", throttle.segment_for_speed(TOP, TOP) == 9)
check("half top speed lands on the nearest notch", throttle.segment_for_speed(TOP / 2, TOP) == 5)
check("a target faster than us clamps to 9", throttle.segment_for_speed(TOP * 4, TOP) == 9)
check("a target flying backwards clamps to 0", throttle.segment_for_speed(-TOP, TOP) == 0)
check("no top speed means no scaling, so a stop", throttle.segment_for_speed(30, 0) == 0)
local round_trip = true
for segment = 0, 9 do
	if throttle.segment_for_speed(throttle.target_speed(segment, TOP), TOP) ~= segment then
		round_trip = false
	end
end
check("every segment survives a speed -> segment round trip", round_trip)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("flight_throttle harness: all assertions passed.")
