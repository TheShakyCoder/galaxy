-- Standalone harness for main/flight_hud.gui_script's two newest pieces of
-- flight HUD (plan.md §2.17), both per direct instruction:
--   * the Power / Hull readouts ("while in flight show the ship power and hull
--     points") - the "ship_status" message, including the "only rewrite the
--     text when it changes" caching;
--   * the circular radar scope (a warship-style screen): its static nodes
--     (disc, outer ring, two range rings, cross-hairs) and the sweep wedge +
--     leading-edge line update() rotates every frame, plus the contact and
--     asteroid blips landing inside the scope and plotting the right way round -
--     SHIP-RELATIVE, so the bow is always up and starboard to the right.
-- gui/vmath/msg/timer are stubbed, so this needs no engine. Run with:
--   luajit tests/flight_hud_harness.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

hash = function(x) return x end

-- ---- vmath ----
local vec = {}
vec.__index = vec
function vec.__add(a, b) return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }, vec) end
function vec.__sub(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vec) end
function vec.__mul(a, b)
	if type(b) == "number" then return setmetatable({ x = a.x * b, y = a.y * b, z = a.z * b }, vec) end
	return setmetatable({ x = a.x * b.x, y = a.y * b.y, z = a.z * b.z }, vec)
end
local function v3(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vec) end
vmath = {
	vector3 = v3,
	vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
	length = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end,
	normalize = function(v) local l = vmath.length(v); return v3(v.x / l, v.y / l, v.z / l) end,
	quat = function() return { x = 0, y = 0, z = 0, w = 1 } end,
}

-- ---- gui stub: records every node creation and the properties written to it ----
local created = {}      -- every new_*_node, in creation order
local gui_nodes = {}    -- authored (.gui) nodes, by id
local function new_node(kind, pos, size)
	local node = { kind = kind, pos = pos, size = size, text_writes = 0 }
	created[#created + 1] = node
	return node
end
gui = { -- global: the script reads gui/vmath/hash as globals (same as the other harnesses)
	PIVOT_CENTER = "center", PIVOT_W = "west", PIVOT_E = "east",
	SIZE_MODE_MANUAL = "manual", PIEBOUNDS_ELLIPSE = "ellipse",
	get_node = function(id) return gui_nodes[id] end,
	new_box_node = function(pos, size) return new_node("box", pos, size) end,
	new_text_node = function(pos, text)
		local node = new_node("text", pos)
		node.text = text
		return node
	end,
	new_pie_node = function(pos, size) return new_node("pie", pos, size) end,
	set_text = function(node, text) node.text = text; node.text_writes = node.text_writes + 1 end,
	set_position = function(node, pos) node.pos = pos end,
	set_size = function(node, size) node.size = size end,
	set_rotation = function(node, rot) node.rotation = rot end,
	set_color = function(node, color) node.color = color end,
	set_enabled = function(node, enabled) node.enabled = enabled end,
	set_fill_angle = function(node, angle) node.fill_angle = angle end,
	set_inner_radius = function(node, radius) node.inner_radius = radius end,
	set_perimeter_vertices = function(node, count) node.perimeter_vertices = count end,
	move_above = function() end,
}
setmetatable(gui, { __index = function() return function() end end }) -- set_font/set_scale/play_flipbook/pick_node/... are no-ops

-- The authored nodes the script looks up by id (main/flight_hud.gui).
for _, id in ipairs({
	"speed_value", "dock_prompt", "target_text", "jump_preset", "system_name",
	"scan_status", "hotkeys", "progress_toast", "tope_value", "water_value",
	"iron_value", "hydrogen_value", "radar_range",
	"power_value", "hull_value", "position_value", "build_version",
}) do
	gui_nodes[id] = new_node("authored", v3(), v3())
end

msg = { post = function() end }
timer = { delay = function() end }

dofile("main/flight_hud.gui_script")

local failures = 0
local function check(label, cond)
	if cond then
		print("PASS  " .. label)
	else
		failures = failures + 1
		print("FAIL  " .. label)
	end
end

local self = {}
init(self)

-- ---- The circular scope (RADAR_* constants in the script) ----
local RADAR_CENTER = { x = 1760, y = 150 }
local RADAR_RADIUS = 110
local pies, boxes = {}, {}
for _, node in ipairs(created) do
	if node.kind == "pie" then
		table.insert(pies, node)
	elseif node.kind == "box" then
		table.insert(boxes, node)
	end
end

local discs, rings, wedges = {}, {}, {}
local heading_marker = nil
for _, node in ipairs(pies) do
	if node.perimeter_vertices == 3 then
		heading_marker = node -- the ship's own marker, a triangle (not part of the scope furniture)
	elseif node.fill_angle == 360 and node.inner_radius == 0 then
		table.insert(discs, node)
	elseif node.fill_angle == 360 then
		table.insert(rings, node)
	else
		table.insert(wedges, node)
	end
end

check("scope face is a full disc", #discs == 1 and discs[1].size.x == 208)
check("outer ring sits on the panel edge", #rings == 3 and (function()
	for _, r in ipairs(rings) do
		if r.size.x == RADAR_RADIUS * 2 then
			return r.inner_radius == RADAR_RADIUS - 6
		end
	end
	return false
end)())
check("two inner range rings", (function()
	local count = 0
	for _, r in ipairs(rings) do
		if r.size.x < RADAR_RADIUS * 2 then count = count + 1 end
	end
	return count == 2
end)())
check("exactly one sweep wedge", #wedges == 1)
check("sweep wedge is translucent so the scope shows through", wedges[1].color.w < 0.3)
check("scope nodes are all centred on the radar", (function()
	for _, node in ipairs(pies) do
		if node.pos.x ~= RADAR_CENTER.x or node.pos.y ~= RADAR_CENTER.y then return false end
	end
	return true
end)())
-- ---- Heading marker (per direct instruction: "add heading marker") ----
check("a heading marker exists", heading_marker ~= nil)
check("heading marker is at the scope centre", heading_marker ~= nil
	and heading_marker.pos.x == RADAR_CENTER.x and heading_marker.pos.y == RADAR_CENTER.y)
check("heading marker's apex points up (own heading)", heading_marker ~= nil
	and math.abs(heading_marker.rotation.z - 90) < 1e-9)
check("heading marker is small and bright", heading_marker ~= nil
	and heading_marker.size.x < RADAR_RADIUS / 4 and heading_marker.color.w > 0.9)
-- z-order: the ship's own marker must be created after every blip pool, so it
-- always draws on top of them. (The three pools are told apart by their own
-- square sizes - see the RADAR_*/ASTEROID_*/OUTPOST_* constants.)
local function created_index(node)
	for i, candidate in ipairs(created) do
		if candidate == node then return i end
	end
	return -1
end
local function last_index_of_size(size)
	local last = -1
	for i, node in ipairs(created) do
		if node.size and node.size.x == size and node.size.y == size then last = i end
	end
	return last
end
check("heading marker draws over every blip pool", heading_marker ~= nil
	and created_index(heading_marker) > last_index_of_size(6) -- ship contacts
	and created_index(heading_marker) > last_index_of_size(5) -- asteroid blips
	and created_index(heading_marker) > last_index_of_size(7)) -- outposts

check("cross-hairs span the scope", (function()
	local horizontal, vertical = false, false
	for _, b in ipairs(boxes) do
		if b.size.x > 190 and b.size.y == 2 then horizontal = true end
		if b.size.y > 190 and b.size.x == 2 then vertical = true end
	end
	return horizontal and vertical
end)())

-- ---- The sweep: one revolution every 3 s, line always on the wedge's leading edge ----
local SWEEP_ARC = 60
local function sweep_gap()
	return self.radar_sweep_line.rotation.z - self.radar_sweep_node.rotation.z
end
check("sweep line is the wedge's leading edge", math.abs(sweep_gap() - SWEEP_ARC) < 1e-9)
check("sweep line starts radial from the centre (west pivot)", self.radar_sweep_line.size.x < RADAR_RADIUS)
update(self, 1)
check("one second of sweep = 120 degrees", math.abs(self.radar_sweep_line.rotation.z - 120) < 1e-6)
check("wedge still trails the line by the arc width", math.abs(sweep_gap() - SWEEP_ARC) < 1e-6)
update(self, 0.5)
check("half a second more = 180 degrees", math.abs(self.radar_sweep_line.rotation.z - 180) < 1e-6)
update(self, 1.5) -- 3 s total: one full revolution, so back to 0
check("a full revolution wraps to 0", math.abs(self.radar_sweep_line.rotation.z) < 1e-6)

-- ---- Power / Hull readouts ----
self.hull_writes = gui_nodes.hull_value.text_writes
self.power_writes = gui_nodes.power_value.text_writes
on_message(self, "ship_status", { power = 100, power_max = 100, hull = 450, hull_max = 450 })
check("power readout shows current / max", gui_nodes.power_value.text == "100 / 100")
check("hull readout shows current / max", gui_nodes.hull_value.text == "450 / 450")
local hull_writes, power_writes = gui_nodes.hull_value.text_writes, gui_nodes.power_value.text_writes
check("both readouts were written", hull_writes > self.hull_writes and power_writes > self.power_writes)

-- The same values every frame (player_ship posts them every frame) must not
-- keep rewriting the text.
for _ = 1, 10 do
	on_message(self, "ship_status", { power = 100, power_max = 100, hull = 450, hull_max = 450 })
end
check("unchanged values are not rewritten", gui_nodes.hull_value.text_writes == hull_writes
	and gui_nodes.power_value.text_writes == power_writes)

on_message(self, "ship_status", { power = 80, power_max = 100, hull = 300, hull_max = 450 })
check("a changed value does update", gui_nodes.power_value.text == "80 / 100" and gui_nodes.hull_value.text == "300 / 450")

-- ---- Contacts still land inside the circular scope ----
local dots, rocks, outposts = {}, {}, {}
for _, node in ipairs(boxes) do
	if node.size.x == 6 and node.size.y == 6 then
		table.insert(dots, node)
	elseif node.size.x == 7 and node.size.y == 7 then
		table.insert(outposts, node)
	elseif node.size.x == 5 and node.size.y == 5 then -- the 1x1 marker-bracket boxes are smaller still
		table.insert(rocks, node)
	end
end
check("a pool of outpost markers exists", #outposts > 0)
check("outpost markers are bigger than contacts", outposts[1].size.x > dots[1].size.x)
check("outpost markers start hidden", (function()
	for _, o in ipairs(outposts) do
		if o.enabled then return false end
	end
	return true
end)())
check("a pool of contact dots exists", #dots > 0)
check("a pool of asteroid blips exists", #rocks > 0)
check("asteroid blips are semi-transparent", (function()
	for _, r in ipairs(rocks) do
		if r.color.w >= 0.5 then return false end
	end
	return true
end)())
check("asteroid blips are smaller than contacts", rocks[1].size.x < dots[1].size.x)
-- Bow pointing along world +Z, so "up" on the scope is +Z and starboard is +X.
on_message(self, "contacts", {
	own_pos = { x = 0, y = 0, z = 0 },
	heading = { x = 0, y = 0, z = 1 },
	range = 1000,
	contacts = { { pos = { x = 500, y = 0, z = 0 } }, { pos = { x = 9000, y = 0, z = 0 } } },
	asteroids = { { pos = { x = 0, y = 0, z = 500 } }, { pos = { x = -9000, y = 0, z = 0 } } },
	outposts = {
		{ pos = { x = 0, y = 0, z = -500 }, relation = "friendly" }, -- directly astern
		{ pos = { x = -9000, y = 0, z = 0 }, relation = "enemy" },
	},
})
local first, second = dots[1], dots[2]
check("near contact plots at half range", math.abs(first.pos.x - (RADAR_CENTER.x + RADAR_RADIUS * 0.5)) < 1e-6)
-- Ship-relative orientation (per direct instruction: blips are shown relative to
-- the direction of the ship, not to the world grid): with the bow along +Z,
-- +X is off the starboard side, so it draws to the RIGHT.
check("world +X plots to starboard", first.pos.x > RADAR_CENTER.x)
check("far contact is clamped to the outer ring",
	math.abs(math.abs(second.pos.x - RADAR_CENTER.x) - RADAR_RADIUS) < 1e-6)
check("every dot stays inside the scope", (function()
	for _, d in ipairs(dots) do
		if d.enabled then
			local dx, dy = d.pos.x - RADAR_CENTER.x, d.pos.y - RADAR_CENTER.y
			if math.sqrt(dx * dx + dy * dy) > RADAR_RADIUS + 1e-6 then return false end
		end
	end
	return true
end)())

-- Asteroids: same projection, dim points, and only as many as are in range.
local rock1, rock2 = rocks[1], rocks[2]
check("an asteroid at half range plots half way out", math.abs(rock1.pos.y - (RADAR_CENTER.y + RADAR_RADIUS * 0.5)) < 1e-6)
check("world +Z plots above centre", rock1.pos.y > RADAR_CENTER.y)
check("an out-of-range asteroid is clamped to the outer ring",
	math.abs(math.abs(rock2.pos.x - RADAR_CENTER.x) - RADAR_RADIUS) < 1e-6)
check("asteroids stay inside the scope", (function()
	for _, r in ipairs(rocks) do
		if r.enabled then
			local dx, dy = r.pos.x - RADAR_CENTER.x, r.pos.y - RADAR_CENTER.y
			if math.sqrt(dx * dx + dy * dy) > RADAR_RADIUS + 1e-6 then return false end
		end
	end
	return true
end)())
check("unused asteroid blips are hidden", rocks[3] ~= nil and rocks[3].enabled == false)

-- A contacts message with no asteroids at all hides the whole rock pool.
on_message(self, "contacts", { own_pos = { x = 0, y = 0, z = 0 }, range = 1000, contacts = {} })
check("no asteroids in range hides every blip", (function()
	for _, r in ipairs(rocks) do
		if r.enabled then return false end
	end
	return true
end)())

-- The same two positions with the ship now pointing along world +X: the scope
-- turns with the hull, so what was off the starboard side is now dead AHEAD
-- (top of the scope) and what was ahead is now off the PORT side (left).
on_message(self, "contacts", {
	own_pos = { x = 0, y = 0, z = 0 },
	heading = { x = 1, y = 0, z = 0 },
	range = 1000,
	contacts = { { pos = { x = 500, y = 0, z = 0 } } },
	asteroids = { { pos = { x = 0, y = 0, z = 500 } } },
})
check("turning the ship turns the scope: +X is now dead ahead",
	math.abs(dots[1].pos.x - RADAR_CENTER.x) < 1e-6
	and math.abs(dots[1].pos.y - (RADAR_CENTER.y + RADAR_RADIUS * 0.5)) < 1e-6)
check("and what was ahead is now to port",
	math.abs(rocks[1].pos.x - (RADAR_CENTER.x - RADAR_RADIUS * 0.5)) < 1e-6
	and math.abs(rocks[1].pos.y - RADAR_CENTER.y) < 1e-6)

-- A message with no heading at all (an older sender, or a hull pointing straight
-- up) still plots sensibly: world +Z counts as up.
on_message(self, "contacts", {
	own_pos = { x = 0, y = 0, z = 0 }, range = 1000,
	contacts = { { pos = { x = 0, y = 0, z = 500 } } }, asteroids = {},
})
check("no heading falls back to world +Z", dots[1].pos.x == RADAR_CENTER.x
	and math.abs(dots[1].pos.y - (RADAR_CENTER.y + RADAR_RADIUS * 0.5)) < 1e-6)

-- ---- Outposts on the scope (per direct instruction: "add outposts") ----
-- (Plotted by the first contacts message above, with the bow along +Z: an
-- outpost directly astern is below centre, one far off to port clamps to the
-- rim.)
check("an outpost astern plots below centre", math.abs(outposts[1].pos.x - RADAR_CENTER.x) < 1e-6
	and math.abs(outposts[1].pos.y - (RADAR_CENTER.y - RADAR_RADIUS * 0.5)) < 1e-6)
check("a far outpost is clamped to the outer ring",
	math.abs(math.abs(outposts[2].pos.x - RADAR_CENTER.x) - RADAR_RADIUS) < 1e-6)
check("a friendly outpost is coloured friendly (blue)", outposts[1].color.z > 0.9)
check("an enemy outpost is coloured enemy (red)", outposts[2].color.x > 0.9)
check("unused outpost markers are hidden", outposts[3] ~= nil and outposts[3].enabled == false)
on_message(self, "contacts", { own_pos = { x = 0, y = 0, z = 0 }, heading = { x = 0, y = 0, z = 1 }, range = 1000, contacts = {} })
check("no outposts in range hides every marker", (function()
	for _, o in ipairs(outposts) do
		if o.enabled then return false end
	end
	return true
end)())

-- ---- Own X/Y/Z coordinates under the scope (per direct instruction) ----
on_message(self, "ship_status", {
	power = 100, power_max = 100, hull = 450, hull_max = 450,
	x = 1234.6, y = -56.2, z = 789.4,
})
-- with_commas floors (the shared helper the reward readouts use, which is
-- why -56.2 reads as -57), so this checks the formatting and the grouping.
check("coordinates are shown as whole metres with grouping",
	gui_nodes.position_value.text == "X 1,234   Y -57   Z 789")

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("flight_hud harness: all assertions passed.")
