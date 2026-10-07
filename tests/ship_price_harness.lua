-- Ad-hoc verification harness for the multi-currency ship price shape:
-- main/data/ships.lua's ordered `price` list, and session.can_afford /
-- session.spend_price (all-or-nothing payment). Pure Lua - both required
-- modules are engine-free - so run it with luajit (or lua) from the Galaxy
-- root:
--   luajit tests/ship_price_harness.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local ships = require("main.data.ships")
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

-- 1. Every live price is a non-empty list of { amount, currency } entries.
local priced = 0
for id, ship in pairs(ships.SHIPS) do
	local price = ship.basic and ship.basic.price
	if price ~= nil then
		priced = priced + 1
		check(id .. " basic.price is a non-empty list", type(price) == "table" and #price >= 1)
		for i, part in ipairs(price) do
			check(id .. " basic.price[" .. i .. "] shape",
				type(part.amount) == "number" and type(part.currency) == "string")
		end
	end
	local adv = ship.advanced and ship.advanced.price
	if adv ~= nil then
		check(id .. " advanced.price is a non-empty list", type(adv) == "table" and #adv >= 1)
	end
end
check("all 11 for-sale basic prices present", priced == 11) -- the starter ship has none

-- A ship with no `advanced` section at all still gets the flat fallback,
-- wrapped in the same one-entry list shape.
check("advance fallback is a one-entry list", #session.get_ship_advance_price("frigate_support") == 1)

-- 2. Multi-currency purchase is all-or-nothing.
session.choose_faction("accord")
local M = session
local SHIP = "patrol_assault"
ships.SHIPS[SHIP].basic.price = {
	{ amount = 36000, currency = "tope" },
	{ amount = 500, currency = "hydrogen" },
}
local price = session.get_ship_price(SHIP)
check("two-entry price is returned", price ~= nil and #price == 2)

M.tope = 100000
M.hydrogen = 100
check("can_afford false when one currency is short", session.can_afford(price) == false)
check("purchase refused", session.purchase_ship(SHIP) == false)
check("tope untouched after refusal", M.tope == 100000)
check("hydrogen untouched after refusal", M.hydrogen == 100)

M.hydrogen = 500
check("can_afford true when both are met", session.can_afford(price) == true)
check("purchase succeeds", session.purchase_ship(SHIP) == true)
check("tope spent exactly", M.tope == 64000)
check("hydrogen spent exactly", M.hydrogen == 0)

-- 3. Multi-currency ADVANCE is all-or-nothing too.
session.choose_faction("accord")
ships.SHIPS["patrol_interceptor"].advanced.price = {
	{ amount = 500, currency = "tope" },
	{ amount = 250, currency = "hydrogen" },
}
M.tope = 1000
M.hydrogen = 100
check("advance price is two entries", #session.get_ship_advance_price("patrol_interceptor") == 2)
check("advance refused while short", session.advance_ship("patrol_interceptor") == false)
check("still basic after refusal", session.is_ship_advanced("patrol_interceptor") == false)
check("tope untouched after refusal", M.tope == 1000)

M.hydrogen = 250
check("advance succeeds", session.advance_ship("patrol_interceptor") == true)
check("advanced flag set", session.is_ship_advanced("patrol_interceptor") == true)
check("tope spent exactly", M.tope == 500)
check("hydrogen spent exactly", M.hydrogen == 0)
check("double advance refused", session.advance_ship("patrol_interceptor") == false)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All ship-price assertions passed.")
