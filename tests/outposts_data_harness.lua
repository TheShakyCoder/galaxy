-- Checks main/data/outposts.lua (plan.md §2.9) against the scene: the
-- accord_outpost / swarm_outpost objects in main/main.collection must use
-- exactly the dock and rotor models each faction's skin lists, and carry as
-- many ad panels as the chassis says. Pure Lua, from the Galaxy root:
--   lua tests/outposts_data_harness.lua
package.path = "./?.lua;" .. package.path
local outposts = require("main.data.outposts")

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end

local function read(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local text = f:read("*a")
	f:close()
	return text
end

local collection = assert(read("main/main.collection"), "main/main.collection not found")

-- The text of one embedded instance's block, from its id up to the next one.
local function instance(id)
	local start = collection:find('id: "' .. id .. '"', 1, true)
	if not start then return nil end
	local finish = collection:find("embedded_instances", start, true) or #collection
	return collection:sub(start, finish)
end

-- The model component path inside an instance block, in either of the two
-- spellings the collection uses (escaped multi-line or one-line).
local function model_of(block)
	return block and (block:match('component: \\"([^\\"]+%.model)\\"') or block:match('component: "([^"]+%.model)"'))
end

local chassis = outposts.OUTPOSTS[outposts.DEFAULT]
check("default outpost exists", chassis ~= nil)
for _, key in ipairs({ "hull_points", "destroyed_for_sec", "radius_m", "dock_range_m", "dock_countdown_sec", "launch_distance_m", "ad_panels" }) do
	check("chassis has " .. key, type(outposts.stat(key)) == "number")
end
check("launch distance is beyond dock range", outposts.stat("launch_distance_m") > outposts.stat("dock_range_m"))

for _, faction in ipairs(outposts.FACTIONS) do
	local skin = outposts.skin(faction)
	check(faction .. ": skin exists", skin ~= nil)
	if skin then
		check(faction .. ": name set", type(skin.name) == "string" and skin.name ~= "")
		check(faction .. ": rotor period set", type(skin.rotor_period_sec) == "number" and skin.rotor_period_sec > 0)
		local dock = model_of(instance(faction .. "_outpost"))
		check(faction .. ": collection dock model = skin.model (" .. tostring(dock) .. ")", dock == skin.model)
		local rotor = model_of(instance(faction .. "_outpost_rotor"))
		check(faction .. ": collection rotor model = skin.rotor_model (" .. tostring(rotor) .. ")", rotor == skin.rotor_model)
		for _, path in ipairs({ skin.model, skin.rotor_model }) do
			check(faction .. ": " .. path .. " exists", read(path:sub(2)) ~= nil)
		end
		local panels = 0
		while instance(faction .. "_outpost_ad" .. (panels + 1)) do panels = panels + 1 end
		check(faction .. ": " .. panels .. " ad panels in the collection", panels == outposts.stat("ad_panels"))
	end
end

-- Upgraded / fortified tiers and the control-level ladder (reference data).
local platforms = require("main.data.sentry_platforms")
check("fortified hull 60000", outposts.stat("hull_points", "fortified_outpost") == 60000)
check("tiers fall back to the regular chassis", outposts.stat("dock_range_m", "upgraded_outpost") == outposts.stat("dock_range_m"))
check("tiers fall back to the regular skins", outposts.skin("swarm", "fortified_outpost") == outposts.skin("swarm"))
local last_pct = 0
for i, row in ipairs(outposts.CONTROL_LEVELS) do
	check("control level " .. i .. " numbered", row.level == i)
	if row.progress_pct then
		check("level " .. i .. " threshold rises", row.progress_pct > last_pct and row.progress_pct <= outposts.PROGRESS.max_pct)
		last_pct = row.progress_pct
	end
	check("level " .. i .. " outpost tier exists", row.outpost == nil or outposts.OUTPOSTS[row.outpost] ~= nil)
	local total = 0
	for class, count in pairs(row.platforms) do
		check("level " .. i .. " platform class " .. class .. " exists", platforms.PLATFORMS[class] ~= nil)
		total = total + count
	end
	check("level " .. i .. " has at most 4 platforms", total <= 4)
end
for class, platform in pairs(platforms.PLATFORMS) do
	check(class .. " platform has hull", type(platform.data.hull_points) == "number")
	check(class .. " platform has a radius", type(platform.data.radius_m) == "number")
	for _, faction in ipairs(platforms.FACTIONS) do
		local skin = platforms.skin(class, faction)
		check(class .. " platform has a " .. faction .. " skin", skin ~= nil)
		check(class .. " " .. faction .. " model exists", skin and skin.model and read(skin.model:sub(2)) ~= nil)
		-- Every platform slot object carries this class's model as component `class`.
		for slot = 1, 4 do
			local block = instance(faction .. "_platform" .. slot) or ""
			local path = block:match('id: \\"' .. class .. '\\" component: \\"([^\\"]+)\\"')
			check(faction .. "_platform" .. slot .. " #" .. class .. " = skin model", path == skin.model)
		end
	end
end
for _, faction in ipairs(outposts.FACTIONS) do
	local skin = outposts.BEACON.faction_skins[faction]
	check(faction .. " beacon skin + model", skin and read(skin.model:sub(2)) ~= nil)
	check(faction .. "_beacon in the collection uses it", model_of(instance(faction .. "_beacon")) == skin.model)
end

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All outpost data assertions passed.")
