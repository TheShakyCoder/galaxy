-- Per-system asteroid field: a default procedural scatter around each
-- system's centre, used unless a system specifically overrides it (per
-- direct instruction - "create a default algorithm... used unless a
-- system specifically overrides that"). Each asteroid has a position, a
-- size and what it's made of (M.RESOURCES below: inert rock, hydrogen, iron
-- or water), which the Asteroid Analyser reveals (main/asteroid_hub.script).
-- These are real mining targets, not decoration: each rock has hull and a
-- mineable resource amount (M.max_hull/M.resource_amount below), the server
-- owns the damage and the reward (nakama-server/modules/system_match.lua),
-- and main/asteroid_hub.script renders each one as its own seeded rock that
-- visibly breaks apart when mined out (plan.md §2.11).
--
-- Deterministic sin-hash PRNG (seed derived from system_id, NOT
-- math.random()/math.randomseed()) - technique ported (not code, per §0 -
-- mechanics, not creative expression) from the other local reference
-- project's own main/asteroid_fields.lua: a self-contained hash gives
-- every caller the exact same field for a given system_id regardless of
-- call order, with no dependency on math.randomseed() actually having
-- been called first (or any future network sync, if this project ever
-- adds multiplayer).
--
-- "Centre of the system" is the origin (0,0,0) - the same point
-- main/player_ship.script's start_flight() spawns the player at. There's
-- no per-system world position yet (§4 - flight mode is still one generic
-- scene, not tied to main/data/star_systems.lua's actual per-system
-- data), so that's the only sensible "centre" available right now.
--
-- Same "plain {x=,y=,z=} table, not vmath.vector3" convention
-- star_systems.lua's own M.outpost_position()/M.spawn_points() already
-- use for position data - keeps this a pure data module; the caller
-- (main/asteroid_hub.script) builds the actual vmath.vector3 at spawn time.

local M = {}

-- Default field parameters (per direct instruction: ~50 asteroids, 10-50m
-- diameter). radius_m is how far from centre they scatter, as a full 3D
-- ball rather than flattened to a disc - unlike the reference project's
-- own asteroid_fields.lua, this is a pitch/yaw free-flight game with no
-- fixed "up" to flatten toward. min_radius_m keeps a clear pocket right
-- at centre so the player doesn't spawn inside a rock. Both radii are
-- PLACEHOLDERS (plan.md §4), not sized off anything real yet - chosen so
-- the field is comfortably reachable at the Patrol Interceptor's own
-- cruise speed (main/data/ships.lua's speed_m_per_sec) rather than to
-- match any system's real scale.
M.DEFAULT = {
	count = 50,
	min_diameter_m = 10,
	max_diameter_m = 50,
	radius_m = 600,
	min_radius_m = 40,
}

-- Per-system overrides, keyed by system_id (main/data/star_systems.lua's
-- own SYSTEMS keys) - only the fields actually being overridden need to
-- be present, everything else still falls back to M.DEFAULT (see
-- params_for()'s merge below). Empty for now - no system has been asked
-- to deviate from the default yet.
M.OVERRIDES = {}

-- Hull: how much damage an asteroid can take before it's mined out, so the
-- target readout can show "HULL <hp> / <max_hp>" and the server knows when
-- one is depleted (nakama-server/modules/system_match.lua). Bigger rocks
-- have more hull. Both numbers are PLACEHOLDERS (plan.md §4) pending a real
-- mining balance pass - at the basic Gnat autocannon's 11 damage/second a
-- 10 m rock (100 hull) takes ~9 s and a 50 m one (500 hull) ~45 s.
M.HULL_PER_METER = 10
M.MIN_HULL = 100

-- The hull an asteroid of `diameter_m` metres starts with. Shared by the
-- game (the HUD readout) and the server (its damage resolution), so both
-- agree on what "full hull" means.
function M.max_hull(diameter_m)
	return math.max(M.MIN_HULL, math.floor((diameter_m or 0) * M.HULL_PER_METER))
end

-- What an asteroid is made of, rolled per asteroid with these weights (sum
-- 1.0). Frequency order and scan colours are BSGO's (bsgo.fandom.com/wiki/
-- Asteroid_Mining: red empty most common, then yellow Tylium, purple
-- Titanium, blue Water - "in order of frequency found"); the weights are
-- ~/Defold/SuperShips' main/asteroid_fields.lua split (0.55/0.25/0.12/
-- 0.08), with Galaxy's names: Tylium is Hydrogen and, per direct
-- instruction, Titanium is Iron. Inert rock has no use in the game.
-- `tint` is the colour an analysed asteroid turns (main/asteroid_hub.script
-- multiplies it by the flight lighting boost). `yield` is the fraction of
-- the rock's own hull it holds as mineable resource (see resource_amount()
-- below) - per direct instruction, hydrogen and iron hold 2/3 of their hull
-- and water 1/3; inert rock is worthless, so it holds nothing.
M.RESOURCES = {
	{ id = "inert", name = "Inert", weight = 0.55, yield = 0, tint = { 0.62, 0.26, 0.22 } },
	{ id = "hydrogen", name = "Hydrogen", weight = 0.25, yield = 2 / 3, tint = { 0.9, 0.78, 0.22 } },
	{ id = "iron", name = "Iron", weight = 0.12, yield = 2 / 3, tint = { 0.58, 0.36, 0.8 } },
	{ id = "water", name = "Water", weight = 0.08, yield = 1 / 3, tint = { 0.28, 0.56, 0.92 } },
}

M.RESOURCE_BY_ID = {}
for _, resource in ipairs(M.RESOURCES) do
	M.RESOURCE_BY_ID[resource.id] = resource
end

-- How much resource an asteroid of `diameter_m` metres holds - revealed
-- (along with what it's made of) once the Asteroid Analyser has scanned it.
-- For now this is just a fixed proportion of the rock's own hull
-- (M.RESOURCES[].yield above), a PLACEHOLDER (plan.md §4) until the real
-- formula is designed: the requirement is that it will depend on several
-- factors, the asteroid's size and the threat level of the system it's in
-- among them. The server will own the amount LEFT once mining exists; this
-- is only the starting amount (main/player_ship.script shows it when the
-- asteroid is targeted).
function M.resource_amount(resource_id, diameter_m)
	local resource = M.RESOURCE_BY_ID[resource_id]
	return math.floor(M.max_hull(diameter_m) * (resource and resource.yield or 0))
end

local function roll_resource(r)
	local cumulative = 0
	for _, resource in ipairs(M.RESOURCES) do
		cumulative = cumulative + resource.weight
		if r < cumulative then
			return resource.id
		end
	end
	return M.RESOURCES[1].id
end

local function params_for(system_id)
	local override = M.OVERRIDES[system_id]
	if not override then
		return M.DEFAULT
	end
	local merged = {}
	for k, v in pairs(M.DEFAULT) do
		merged[k] = v
	end
	for k, v in pairs(override) do
		merged[k] = v
	end
	return merged
end

-- Deterministic string hash - same output on every platform/client, same
-- technique as the reference project's own seed_for_system().
local function seed_for_system(system_id)
	local h = 0
	for i = 1, #system_id do
		h = (h * 31 + string.byte(system_id, i)) % 2147483647
	end
	return h
end

-- Classic sin-hash noise, [0, 1) - deterministic, well-distributed enough
-- for this (non-cryptographic) purpose. `salt` decorrelates multiple
-- draws for the same (seed, index) pair (radius/theta/phi/diameter rolls
-- below all need independent-looking values).
local function prng(seed, index, salt)
	local x = math.sin(seed * 12.9898 + index * 78.233 + salt * 37.719) * 43758.5453
	return x - math.floor(x)
end

local field_cache = {} -- system_id -> field, memoized (a field never changes once generated)

-- Returns a list of { x, y, z, diameter_m, resource } for `system_id`, using
-- params_for(system_id) (M.DEFAULT, merged with any M.OVERRIDES entry).
-- Positions are scattered uniformly BY VOLUME within a ball of radius
-- params.radius_m around the origin, excluding a min_radius_m pocket at
-- centre - picking the radius uniformly on [0,1] would instead bunch
-- asteroids toward the centre (a thin shell near the edge covers far more
-- volume than one near the middle), and picking theta uniformly on
-- [0,pi] would bunch them toward the poles - both corrected below
-- (cube-root radius, acos(2u-1) polar angle) so the scatter actually
-- looks uniform rather than clumped.
function M.field_for(system_id)
	if not system_id then
		return {}
	end
	if field_cache[system_id] then
		return field_cache[system_id]
	end
	local p = params_for(system_id)
	local seed = seed_for_system(system_id)

	local field = {}
	for i = 1, p.count do
		local r = p.min_radius_m + (p.radius_m - p.min_radius_m) * (prng(seed, i, 1) ^ (1 / 3))
		local theta = math.acos(2 * prng(seed, i, 2) - 1)
		local phi = prng(seed, i, 3) * 2 * math.pi
		local x = r * math.sin(theta) * math.cos(phi)
		local y = r * math.cos(theta)
		local z = r * math.sin(theta) * math.sin(phi)
		local diameter = p.min_diameter_m + prng(seed, i, 4) * (p.max_diameter_m - p.min_diameter_m)
		local resource = roll_resource(prng(seed, i, 5))
		table.insert(field, { x = x, y = y, z = z, diameter_m = diameter, resource = resource })
	end

	field_cache[system_id] = field
	return field
end

return M
