-- The flight throttle: commanded speed as ten discrete segments, 0 to 9
-- (plan.md §2.10/§2.10.1). Segment 0 is a dead stop and segment 9 is the
-- ship's own top speed (`speed_m_per_sec`, main/data/ships.lua §2.1.1); the
-- eight segments between them are even steps of that span, so segment `n`
-- commands `n / 9 * top speed`.
--
-- The lever is DISCRETE on purpose (per direct instruction): the mouse wheel
-- and the throttle keys move the selected segment one notch at a time rather
-- than ramping a continuous 0..1 lever, and the ship's actual speed then
-- eases toward whatever the segment commands at its own
-- `acceleration_m_per_sec2` (main/player_ship.script's update()). Boost still
-- overrides the segment while held (§2.1.1's boost speed), and Follow Friend
-- still matches a target's broadcast speed directly - neither is a throttle
-- segment.
--
-- Engine-free (no go./vmath./gui. dependency), so
-- tests/flight_throttle_harness.lua runs it under plain luajit, same footing
-- as main/session.lua.

local M = {}

-- Ten segments: 0 (no speed) through MAX_SEGMENT (top speed).
M.SEGMENTS = 10
M.MAX_SEGMENT = M.SEGMENTS - 1 -- 9 - the top-speed notch

-- A segment as a whole number 0..9, whatever it's handed. Fractional input
-- (Match Speed's own target-speed fraction) rounds to the nearest notch, and
-- anything off either end clamps to the end it ran off - so callers never
-- need to clamp before stepping past 0 or 9.
function M.clamp(segment)
	local n = math.floor((segment or 0) + 0.5)
	if n < 0 then
		return 0
	end
	if n > M.MAX_SEGMENT then
		return M.MAX_SEGMENT
	end
	return n
end

-- The commanded fraction of top speed for a segment: 0 -> 0.0, 9 -> 1.0.
function M.fraction(segment)
	return M.clamp(segment) / M.MAX_SEGMENT
end

-- The segment `delta` notches up (+) or down (-) from `segment`, clamped.
function M.step(segment, delta)
	return M.clamp((segment or 0) + (delta or 0))
end

-- The speed a segment commands, in m/sec - scaled by the ship's own top
-- speed so the same ten segments mean the same fraction on any hull.
function M.target_speed(segment, top_speed)
	return M.fraction(segment) * (top_speed or 0)
end

-- The segment closest to `speed`, for Match Speed (T) and anything else that
-- has a target speed in m/sec rather than a notch. A ship with no (or a
-- zero) top speed can't scale anything, so it reports the stop.
function M.segment_for_speed(speed, top_speed)
	if not top_speed or top_speed <= 0 then
		return 0
	end
	return M.clamp(((speed or 0) / top_speed) * M.MAX_SEGMENT)
end

return M
