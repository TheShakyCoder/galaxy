-- Per-ship fittings (per direct instruction): a newly bought ship of ANY
-- class starts with nothing fitted - it never inherits another ship's
-- weapons or components; only the starting ship comes with its starter
-- kit. Modules only fit ships of their own class. Also checks the
-- conversion of saves from before per-ship loadouts, and a server-style
-- replay. Pure Lua, from the Galaxy root:
--   luajit tests/ship_loadout_harness.lua
package.path = "./?.lua;" .. package.path
local session = require("main.session")

local failures = 0
local function check(label, ok)
	print((ok and "PASS  " or "FAIL  ") .. label)
	if not ok then failures = failures + 1 end
end
local function count(list) local n = 0 for _ in pairs(list or {}) do n = n + 1 end return n end
local function rich()
	session.tope, session.valour, session.hydrogen = 10 ^ 9, 10 ^ 9, 10 ^ 9
	session.xp = 10 ^ 9 -- every class unlocked
end

-- 1. The starting ship comes with its starter kit.
session.reset()
session.choose_faction("accord")
check("starting ship is the patrol interceptor", session.get_ship_id() == "patrol_interceptor")
check("...fitted with its two starter guns", #session.get_loadout() == 2 and session.module_in_slot("W1") ~= nil)
local starter_w1 = select(2, session.module_in_slot("W1")).id

-- 2. Buying a Frigate: it starts EMPTY, and switching to it shows nothing fitted.
rich()
check("frigate bought", session.purchase_ship("frigate_assault") == true)
check("the starting ship still has its kit", #session.get_loadout() == 2)
check("frigate selected", session.select_ship("frigate_assault") == true)
check("the frigate has nothing fitted", #session.get_loadout() == 0 and session.module_in_slot("W1") == nil)

-- 3. A Patrol weapon can't be fitted to the Frigate.
check("patrol gun refused on the frigate", session.install("W1", starter_w1) == false)
check("...and stays on the patrol ship", session.is_installed(starter_w1))

-- 4. Back on the patrol ship, its kit is where it was.
session.select_ship("patrol_interceptor")
check("patrol ship's kit untouched", #session.get_loadout() == 2 and select(2, session.module_in_slot("W1")).id == starter_w1)

-- 5. Another Patrol ship also starts empty; moving a gun to it takes it OFF the first.
check("second patrol ship bought", session.purchase_ship("patrol_assault") == true)
session.select_ship("patrol_assault")
check("the new patrol ship starts empty too", #session.get_loadout() == 0)
check("a patrol gun fits a patrol ship", session.install("W1", starter_w1) == true)
session.select_ship("patrol_interceptor")
check("...and left the interceptor (one ship at a time)", session.module_in_slot("W1") == nil and #session.get_loadout() == 1)

-- 6. Round trip through the saved profile keeps each ship's fitting.
local saved = session.serialize()
session.reset()
session.restore(saved)
check("restored active ship's fitting", session.get_ship_id() == "patrol_interceptor" and #session.get_loadout() == 1)
session.select_ship("patrol_assault")
check("restored other ship's fitting", select(2, session.module_in_slot("W1")).id == starter_w1)
session.select_ship("frigate_assault")
check("restored frigate still empty", #session.get_loadout() == 0)
check("the save also carries the active ship's loadout (for the server)", #saved.loadout == 1)

-- 7. Selling a ship sends its modules back to the hold.
rich()
session.select_ship("patrol_interceptor")
check("sold the second patrol ship", session.sell_ship("patrol_assault") == true)
check("its gun is a spare again", session.get_instance(starter_w1) ~= nil and not session.is_installed(starter_w1))

-- 8. An old save (one loadout shared by every ship, frigate active - the bug
-- as reported) converts: the patrol guns go back on the patrol ship only.
session.reset()
session.restore({
	faction = "accord", owned_ships = { "patrol_interceptor", "frigate_assault" }, active_ship_id = "frigate_assault",
	owned = { { id = 1, item_key = "auto_cannon_basic", level = 0 }, { id = 2, item_key = "mining_cannon_basic", level = 0 } },
	loadout = { { slot = "W1", instance_id = 1 }, { slot = "W2", instance_id = 2 } },
	next_instance_id = 3,
})
check("old save: the frigate (active) has nothing fitted", session.get_ship_id() == "frigate_assault" and #session.get_loadout() == 0)
session.select_ship("patrol_interceptor")
check("old save: the patrol ship keeps both guns", #session.get_loadout() == 2)

if failures > 0 then
	print(failures .. " FAILURE(S)")
	os.exit(1)
end
print("All ship loadout assertions passed.")
