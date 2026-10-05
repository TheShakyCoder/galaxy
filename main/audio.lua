-- 3D-ish spatialisation for the built-in sound components.
--
-- Defold's built-in sound system has NO listener and NO 3D position: a
-- component's only spatial controls are `pan` (-1..1) and `gain`. Real 3D
-- positional audio would need a native extension (OpenAL/FMOD). This module
-- instead derives pan and gain from the game's own camera every frame, which
-- is the technique Defold's own engine team recommends for positional audio.
--
-- Everything is derived from the listener's own axes, which is the point:
-- the listener is the chase camera, so when a future camera mode moves or
-- re-orients the camera (e.g. looking up from BELOW the ship, which flips
-- left/right), the pan follows automatically with no change here. Nothing
-- assumes the camera is behind the ship or even upright - `right` is the
-- camera's own local +X, whatever direction that happens to point in the
-- world.
--
-- This is a shared module (game.project sets [script] shared_state = 1), so
-- main/player_ship.script sets the listener and the world hubs
-- (main/asteroid_hub.script, main/shot_hub.script) read it - they play
-- sounds in the world but never own a camera.
--
-- What this deliberately does NOT do: elevation. A rock directly above and
-- one directly below pan identically, because pan is a single left/right
-- number. Distance and bearing are real; height is only reflected through
-- distance. Flagged as a known limit (plan.md §2.12).

local M = {}

-- Beyond REFERENCE_DISTANCE a source is at full gain; it fades linearly to
-- silence at MAX_DISTANCE. Both are PLACEHOLDERS (plan.md §4), chosen so the
-- things that actually make noise sit comfortably in range: a ship is ~16 m
-- from its own chase camera and asteroid fields scatter out to ~600 m
-- (main/data/asteroids.lua's M.DEFAULT.radius_m), so a whole field stays
-- audible while something across a 10,000 m system is not.
local REFERENCE_DISTANCE = 20
local MAX_DISTANCE = 2000

-- The listener, or nil before main/player_ship.script has set it (or while
-- the camera is disabled.
local listener_pos = nil
local listener_rot = nil

local RIGHT = vmath.vector3(1, 0, 0)

-- The chase camera, in world space. Call every frame while flying.
function M.set_listener(pos, rot)
	listener_pos = pos
	listener_rot = rot
end

function M.clear_listener()
	listener_pos = nil
	listener_rot = nil
end

-- Pan (-1..1, -1 = full left / "left" being the listener's own right axis
-- negated) and gain (0..1) for a sound at `world_pos`. With no listener set
-- yet, a sound is simply centred and at full gain rather than silent, so
-- nothing is ever lost to ordering.
function M.mix(world_pos)
	if not listener_pos or not world_pos then
		return 0, 1
	end
	local to_source = world_pos - listener_pos
	local distance = vmath.length(to_source)
	local gain = 1
	if distance > REFERENCE_DISTANCE then
		gain = math.max(0, (MAX_DISTANCE - distance) / (MAX_DISTANCE - REFERENCE_DISTANCE))
	end
	if distance < 0.0001 then
		return 0, gain
	end
	-- Dot the UNIT direction to the source with the listener's own right
	-- axis: a source dead ahead or dead astern pans centre, one directly to
	-- the side pans fully, and the camera's orientation decides which is
	-- which. Normalising first (rather than using the raw offset) is what
	-- makes pan depend on BEARING not raw screen position.
	local direction = to_source / distance
	local pan = vmath.dot(direction, vmath.rotate(listener_rot, RIGHT))
	return math.max(-1, math.min(1, pan)), gain
end

-- Plays `url` once, positioned at `world_pos`. `opts.attenuate = false` keeps
-- full gain regardless of distance (for sounds that belong to the player's
-- own ship, which should stay audible however the camera moves) while still
-- panning. `opts.gain` scales the result.
--
-- Pan is passed per-play here rather than set on the component, because
-- several one-shots can share one component in the same frame (two weapons
-- firing at once) and each needs its own pan - `sound.play`'s own pan is
-- added to the component's, so the component must stay at 0 for these.
function M.play(url, world_pos, opts)
	local pan, gain = M.mix(world_pos)
	if opts and opts.attenuate == false then
		gain = 1
	end
	if opts and opts.gain then
		gain = gain * opts.gain
	end
	sound.play(url, { pan = pan, gain = gain })
end

-- A looping sound that lives at a world position, e.g. a ship's engines.
-- Unlike the one-shots, a loop is alone on its component, so pan/gain are
-- driven through the component (sound.set_pan/set_gain) - that's what lets an
-- already-playing loop follow a moving camera.
function M.play_loop(url, world_pos, opts)
	local pan, gain = M.mix(world_pos)
	if opts and opts.attenuate == false then
		gain = 1
	end
	sound.set_pan(url, pan)
	sound.set_gain(url, gain)
	sound.play(url)
end

-- Re-positions an already-playing loop. Cheap (two property writes).
function M.update_loop(url, world_pos, opts)
	local pan, gain = M.mix(world_pos)
	if opts and opts.attenuate == false then
		gain = 1
	end
	sound.set_pan(url, pan)
	sound.set_gain(url, gain)
end

-- Playback speed (pitch) of a component's voices. There is no
-- sound.set_speed() - unlike pan/gain, `speed` is only a component property
-- (sound.play's own `speed` is a one-shot multiplier and is not exposed for a
-- live voice), so this goes through go.set. Applied before sound.play() for a
-- fresh voice; re-applying it while a loop is playing retunes it live. 1 = the
-- recorded pitch; 1.2 = 20% higher (see main/player_ship.script's engine loop).
function M.set_speed(url, speed)
	go.set(url, "speed", speed)
end

function M.stop_loop(url)
	sound.stop(url)
end

return M