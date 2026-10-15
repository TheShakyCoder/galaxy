-- Runs main/system_map.gui_script (the M-key system map) against stubbed
-- gui/vmath/msg and the real shared registries, checking what it plots:
-- every asteroid (depleted ones hidden), standing outposts and their
-- defences, friendly ships anywhere, enemy ships only within sensor range,
-- and that a click on a blip targets it. From the Galaxy root:
--   luajit tests/system_map_harness.lua
package.path = "./?.lua;" .. package.path

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end

-- Stubs ----------------------------------------------------------------------
local V = {}
V.__index = V
V.__add = function(a, b) return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = (a.z or 0) + (b.z or 0) }, V) end
V.__mul = function(a, k) return setmetatable({ x = a.x * k, y = a.y * k, z = (a.z or 0) * k }, V) end
vmath = {
	vector3 = function(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V) end,
	vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
}
local nodes = {}
local function node(kind)
	local n = { kind = kind, enabled = true, pos = vmath.vector3(), size = vmath.vector3() }
	table.insert(nodes, n)
	return n
end
gui = {
	PIVOT_CENTER = 0, PIVOT_W = 1, PIVOT_E = 2, PIEBOUNDS_ELLIPSE = 0,
	new_box_node = function(p, s) local n = node("box"); n.pos, n.size = p, s; return n end,
	new_pie_node = function(p, s) local n = node("pie"); n.pos, n.size = p, s; return n end,
	new_text_node = function(p, t) local n = node("text"); n.pos, n.text = p, t; return n end,
	set_perimeter_vertices = function() end, set_outer_bounds = function() end, set_fill_angle = function() end,
	set_inner_radius = function() end, set_pivot = function() end, set_font = function() end, set_scale = function() end,
	set_color = function(n, c) n.color = c end, set_alpha = function() end,
	set_enabled = function(n, e) n.enabled = e end, is_enabled = function(n) return n.enabled end,
	set_position = function(n, p) n.pos = p end, get_position = function(n) return n.pos end,
	set_size = function(n, s) n.size = s end, set_rotation = function(n, r) n.rot = r end,
	set_text = function(n, t) n.text = t end,
}
local posted = {}
msg = { post = function(to, id, m) table.insert(posted, { to = to, id = id, m = m }) end }
hash = function(s) return s end

-- Shared registries (the real modules), filled with a scene.
local asteroid_registry = require("main.asteroid_registry")
local remote_registry = require("main.remote_registry")
local net = { asteroid_state = function(_, i) return i == 2 and { available = false } or nil end,
	outpost_state = function(_, f) return f == "accord" and { available = true, beacon = { available = true }, platforms = { { available = true }, { available = false } } } or { available = false, present = false } end }
package.loaded["main.network"] = net

asteroid_registry.set({
	{ index = 1, pos = vmath.vector3(100, 0, 100), radius = 20, resource = "iron", analysed = true },
	{ index = 2, pos = vmath.vector3(200, 0, 100), radius = 20, resource = "inert", analysed = false }, -- depleted
	{ index = 3, pos = vmath.vector3(-300, 0, 50), radius = 30, resource = "water", analysed = false },
})
remote_registry.ships = {
	friend_far = { pos = vmath.vector3(4000, 0, 4000), faction = "accord" },
	enemy_near = { pos = vmath.vector3(500, 0, 0), faction = "swarm" },
	enemy_far = { pos = vmath.vector3(-4500, 0, -4500), faction = "swarm" },
}

dofile("main/system_map.gui_script")
local self = {}
init(self)

local function enabled_ids(list)
	local ids = {}
	for _, slot in ipairs(list) do
		if slot.node.enabled and slot.id then ids[slot.id] = slot.node end
	end
	return ids
end

on_message(self, "toggle", { open = true })
on_message(self, "system_map", {
	system_id = "deneb", system_name = "Deneb", width = 40000, depth = 40000, faction = "accord",
	own = { x = 0, z = 0, hx = 0, hz = 1 }, sensor_range = 2000, target_id = "outpost:accord",
})
update(self, 0.016)

local a = enabled_ids(self.asteroids)
check("asteroids 1 and 3 shown, depleted 2 hidden", a["asteroid:1"] and a["asteroid:3"] and not a["asteroid:2"])
check("analysed iron rock in its resource colour", a["asteroid:1"].color.x > 0.5 and a["asteroid:1"].color.z > 0.7)
local o = enabled_ids(self.outposts)
check("accord outpost, beacon and platform 1 shown", o["outpost:accord"] and o["beacon:accord"] and o["platform:accord:1"])
check("destroyed platform 2 and absent swarm outpost hidden", not o["platform:accord:2"] and not o["outpost:swarm"])
local s = enabled_ids(self.ships)
check("friendly ship shown outside sensor range", s.friend_far ~= nil)
check("enemy inside sensor range shown", s.enemy_near ~= nil)
check("enemy outside sensor range hidden", s.enemy_far == nil)
check("target ring shown on the targeted outpost", self.target_ring.enabled)
-- The own ship shows which way it's flying: heading +Z (north) points the
-- line straight up the screen, with both arrow barbs at its tip.
check("own ship marker, heading line and arrow tip shown", self.own.enabled and self.own_line.enabled and self.own_tip[1].enabled and self.own_tip[2].enabled)
check("heading north: line points up the screen (90 degrees)", math.abs(self.own_line.rot.z - 90) < 1e-6)
check("arrow tip sits 34 px up the line", math.abs(self.own_tip[1].pos.x - self.own.pos.x) < 1e-6 and math.abs(self.own_tip[1].pos.y - self.own.pos.y - 34) < 1e-6)
check("barbs open 30 degrees either side", math.abs(self.own_tip[1].rot.z - 120) < 1e-6 and math.abs(self.own_tip[2].rot.z - 60) < 1e-6)
on_message(self, "system_map", {
	system_id = "deneb", system_name = "Deneb", width = 40000, depth = 40000, faction = "accord",
	own = { x = 0, z = 0, hx = 1, hz = 0 }, sensor_range = 2000, target_id = "outpost:accord",
})
self.redraw = 0
update(self, 0.016)
check("heading world +X: line points screen-left (180 degrees)", math.abs(self.own_line.rot.z - 180) < 1e-6)
on_message(self, "system_map", {
	system_id = "deneb", system_name = "Deneb", width = 40000, depth = 40000, faction = "accord",
	own = { x = 0, z = 0, hx = 0, hz = 1 }, sensor_range = 2000, target_id = "outpost:accord",
})
self.redraw = 0
update(self, 0.016)

-- North-up, screen right = world -X: the near enemy at world +500 X is left of centre.
check("world +X plots left of centre", s.enemy_near.pos.x < 960)

-- Clicking the enemy's blip targets it.
local p = s.enemy_near.pos
posted = {}
check("click on a blip is handled", on_input(self, "touch", { pressed = true, x = p.x + 3, y = p.y - 2 }) == true)
check("...and targets that ship", posted[1] and posted[1].id == "set_target" and posted[1].m.id == "enemy_near")
check("other keys pass through to flight", on_input(self, "up", { pressed = true }) == false)

on_message(self, "toggle", { open = false })
check("closing hides every blip", next(enabled_ids(self.asteroids)) == nil and next(enabled_ids(self.ships)) == nil)
check("closing hides the heading arrow", not self.own_line.enabled and not self.own_tip[1].enabled)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All system map assertions passed.")
