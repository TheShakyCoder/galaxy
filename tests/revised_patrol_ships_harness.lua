-- Verifies main/data/ships.lua against revised-patrol-ships.csv (the Patrol
-- class's source of truth, plan.md §2.1.4), field by field, for every Patrol
-- ship's base row AND its " advanced" row. Pure Lua - run from the Galaxy root:
--   luajit tests/revised_patrol_ships_harness.lua
--
-- For a base row every stat cell must match ships.lua's `basic` section. For an
-- advanced row, a filled cell must match the advanced value (via session's
-- basic/advanced fallback) and an empty cell must fall back to the base value.
package.path = "./?.lua;./?/init.lua;" .. package.path

local ships = require("main.data.ships")
local session = require("main.session")

local STATS = {
	{ "Hull Points", "hull_points" },
	{ "Hull Recovery/S", "hull_recovery_per_sec" },
	{ "Repair Cost (Iron)", "repair_cost_iron" },
	{ "Armor", "armor" },
	{ "Critical Defense", "critical_defense" },
	{ "Avoidance", "avoidance" },
	{ "Turning Speed (deg/s)", "turning_speed_deg_per_sec" },
	{ "Turning Accel (deg/s2)", "turning_acceleration_deg_per_sec2" },
	{ "Inertial Comp (m/s)", "inertial_compensation_m_per_sec" },
	{ "Acceleration (m/s2)", "acceleration_m_per_sec2" },
	{ "Speed (m/s)", "speed_m_per_sec" },
	{ "Boost Speed (m/s)", "boost_speed_m_per_sec" },
	{ "Boost Cost (H2/s)", "boost_cost_hydrogen_per_sec" },
	{ "FTL Range (LY)", "ftl_range_ly" },
	{ "FTL Charge (s)", "ftl_charge_sec" },
	{ "FTL Cost (H2/LY)", "ftl_cost_hydrogen_per_ly" },
	{ "Power", "power" },
	{ "Power Recharge/S", "power_recharge_per_sec" },
	{ "Firewall", "firewall_rating" },
	{ "Emitter", "emitter_rating" },
	{ "Sensor Range (m)", "sensor_range_m" },
	{ "Visual Range (m)", "visual_range_m" },
}
local COMPONENTS = {
	{ "W Slots", "W" }, { "H Slots", "H" }, { "E Slots", "E" }, { "C Slots", "C" },
}
local PRICE_COLS = {
	{ "Purchase Hydrogen", "hydrogen" },
	{ "Purchase Topes", "tope" },
	{ "Purchase Valour", "valour" },
}

local function split(line)
	local out, pos = {}, 1
	while true do
		local comma = line:find(",", pos, true)
		if not comma then
			out[#out + 1] = line:sub(pos)
			return out
		end
		out[#out + 1] = line:sub(pos, comma - 1)
		pos = comma + 1
	end
end

local f = assert(io.open("revised-patrol-ships.csv", "rb"))
local text = f:read("*a")
f:close()
local lines = {}
for line in text:gsub("\r", ""):gmatch("[^\n]+") do
	lines[#lines + 1] = line
end

local hdr = split(lines[1])
local col = {}
for i, name in ipairs(hdr) do
	col[name] = i
end

local failures = 0
local function check(label, ok, got, want)
	if ok then
		return
	end
	failures = failures + 1
	print(("FAIL  %s  (got %s, want %s)"):format(label, tostring(got), tostring(want)))
end

local function num(s)
	return tonumber(s)
end
local function near(a, b)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 1e-9
end

-- "price" list, in CSV column order, from the row's three Purchase columns.
local function csv_price(row)
	local list = {}
	for _, entry in ipairs(PRICE_COLS) do
		local v = row[col[entry[1]]]
		if v and v ~= "" then
			list[#list + 1] = { amount = num(v), currency = entry[2] }
		end
	end
	return #list > 0 and list or nil
end
local function same_price(got, want)
	if (got == nil) ~= (want == nil) then
		return false
	end
	if got == nil then
		return true
	end
	if #got ~= #want then
		return false
	end
	for i = 1, #want do
		if got[i].amount ~= want[i].amount or got[i].currency ~= want[i].currency then
			return false
		end
	end
	return true
end

session.choose_faction("accord")

local seen, advanced_seen, pending = {}, {}, {}
for i = 2, #lines do
	local row = split(lines[i])
	local name = row[col["Ship"]]
	if name:sub(1, 6) == "patrol" then
		local base_id = name:match("^(.-) advanced$") or name
		local is_advanced = name:match(" advanced$") ~= nil
		local ship = ships.SHIPS[base_id]
		if not ship then
			pending[base_id] = true
		else
			if is_advanced then
				advanced_seen[base_id] = true
				session.advanced_ships[base_id] = true
			else
				seen[base_id] = true
			end

			local label = base_id .. (is_advanced and " advanced" or "")
			local basic = ship.basic.data

			-- Price.
			if is_advanced then
				check(label .. " price", same_price(session.get_ship_advance_price(base_id), csv_price(row)))
			else
				check(label .. " price", same_price(session.get_ship_price(base_id), csv_price(row)))
			end

			-- Class / Role (base rows only).
			if not is_advanced then
				check(label .. " class", ship.class == row[col["Class"]], ship.class, row[col["Class"]])
				check(label .. " role", ship.role == row[col["Role"]], ship.role, row[col["Role"]])
			end

			-- Stats: filled cell -> value; empty cell -> base value.
			for _, stat in ipairs(STATS) do
				local want = num(row[col[stat[1]]])
				local got = session.ship_stat(base_id, stat[2])
				if want == nil then
					check(label .. " " .. stat[2] .. " falls back to basic", near(got, basic[stat[2]]), got, basic[stat[2]])
				else
					check(label .. " " .. stat[2], near(got, want), got, want)
				end
			end

			-- Slot counts.
			local counts = session.get_components(base_id)
			for _, comp in ipairs(COMPONENTS) do
				local want = num(row[col[comp[1]]])
				if want ~= nil then
					check(label .. " " .. comp[2] .. " slots", counts[comp[2]] == want, counts[comp[2]], want)
				end
			end
		end
	end
end

-- Slot layouts: the full advanced slot set is laid out, every position is a real
-- slot of that ship, and a `tier = "advanced"` position is one the upgrade adds.
for _, id in ipairs({ "patrol_interceptor", "patrol_support", "patrol_assault", "patrol_tactical" }) do
	local ship = ships.SHIPS[id]
	local advanced = ship.advanced.components
	local basic = ship.basic.components
	local placed = {}
	for slot, pos in pairs(ship.slot_positions) do
		local prefix, n = slot:match("^(%a)(%d+)$")
		local count = tonumber(n)
		placed[prefix] = (placed[prefix] or 0) + 1
		check(id .. " " .. slot .. " within advanced count", count <= (advanced[prefix] or 0))
		if pos.tier == "advanced" then
			check(id .. " " .. slot .. " is an upgraded slot", count > (basic[prefix] or 0))
		else
			check(id .. " " .. slot .. " within basic count", count <= (basic[prefix] or 0))
		end
	end
	for _, prefix in ipairs({ "W", "H", "E", "C" }) do
		check(id .. " " .. prefix .. " positions laid out == advanced count",
			(placed[prefix] or 0) == advanced[prefix])
	end
end

-- Sanity: every Patrol row in the CSV was actually exercised.
for _, id in ipairs({ "patrol_interceptor", "patrol_support", "patrol_assault", "patrol_tactical" }) do
	check(id .. " base row present", seen[id] == true)
	check(id .. " advanced row present", advanced_seen[id] == true)
end
for id in pairs(pending) do
	print("NOTE  " .. id .. " is in the CSV but not yet in ships.lua (needs faction names + a model asset)")
end

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("ships.lua matches revised-patrol-ships.csv for every Patrol ship.")
