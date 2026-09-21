-- Minimal shared in-memory session state (plan.md §3.2's decided guest-state
-- design: a plain Lua table client-side, riding on the `shared_state = 1`
-- setting already on in game.project). Nothing here is written to any
-- persistent storage — it's gone the moment the page/tab reloads, which is
-- what makes §1.1's "guests re-pick every load" rule true automatically.
-- Registered-account session state (auth token, permanent faction, etc.,
-- §3.2/§3.3) is separate, not-yet-built work.

local M = {}

M.faction = nil -- "accord" | "swarm" | nil (not chosen yet)
M.owned_ships = nil -- list of ship ids owned (main/data/ships.lua's M.SHIPS)
M.active_ship_id = nil -- which owned ship is currently selected/fitted
-- `owned`: list of OWNED INSTANCES, NOT catalog type-keys — decided (§4) that
-- module upgrades are per PHYSICAL COPY, not a shared per-type "blueprint"
-- upgrade, so two owned Gnats need to be distinguishable and independently
-- upgradeable. Each entry: { id = <unique instance id>, item_key = <catalog
-- key, main/data/modules/catalog.lua>, level = <int, starts at 0> }.
M.owned = nil
-- `loadout`: list of { slot = "W1"/"W2"/..., instance_id = <owned instance's
-- id> } — currently installed. Keyed by INSTANCE id (not item type key) for
-- the same reason: installing/uninstalling must track which specific
-- upgraded copy is in a slot, not just which type.
M.loadout = nil
-- NOTE: `owned`/`loadout` are a single global pool, not yet scoped per
-- ship — only one ship exists in the roster so far (§2.1.2), so there's
-- nothing to test per-ship segregation against yet. Flagged as an open
-- question in plan.md §4 once more ships exist.

-- `scrip`: the player's balance of Scrip (§2.6's general currency, as
-- opposed to PvP-only Valor). Per direct instruction, the outpost screen
-- always shows this and it updates as items/ships are bought and sold -
-- which needs a REAL balance and REAL transaction amounts to do
-- honestly, not just a static display. STARTING_SCRIP and every price/
-- refund below are FLAT PLACEHOLDER values, not real per-item economy
-- design (§2.6's actual pricing is still open work, §4) - introduced
-- now purely so the currency display has something genuine to show and
-- update, rather than a number that never changes.
M.scrip = nil
local STARTING_SCRIP = 500
local MODULE_PRICE = 100
local MODULE_SELL_REFUND = 50
local SHIP_PRICE = 500
local SHIP_SELL_REFUND = 250

-- `water`/`iron`/`hydrogen`: the player's balances of the three RESOURCES
-- (§2.6) - distinct from Scrip/Valor, which are the two CURRENCIES. Per
-- direct instruction, the outpost screen always shows all four of these
-- balances together. Unlike `scrip` above, none of these three has a real
-- transaction wired up anywhere yet - no mining, repair, or FTL/boost
-- mechanic exists in code to actually earn or spend them (`repair_cost_iron`
-- and `boost_cost_hydrogen_per_sec`/`ftl_cost_hydrogen_per_ly` in
-- ships.lua are stat FIELDS a future mechanic will read, not something
-- anything currently deducts against). So these three are honestly STATIC
-- for now - set once here and never touched again - rather than faking
-- transactions just to make the display look alive. STARTING_WATER/IRON/
-- HYDROGEN are flat placeholder values with no economy-balancing behind
-- them yet (same caveat as STARTING_SCRIP above); note they're not even
-- scaled against the existing repair_cost_iron = 10000 placeholder stat,
-- since nothing spends against either number yet - reconciling that scale
-- is open work, plan.md §4.
M.water = nil
M.iron = nil
M.hydrogen = nil
local STARTING_WATER = 500
local STARTING_IRON = 500
local STARTING_HYDROGEN = 500

-- Monotonically-increasing instance id counter, reset on every
-- choose_faction (a fresh guest session) — plain incrementing integers are
-- fine since this is in-memory/per-tab state, never persisted or compared
-- across sessions (§3.2).
local next_instance_id = 1
local function alloc_instance_id()
	local id = next_instance_id
	next_instance_id = next_instance_id + 1
	return id
end

-- Starting gift for every new character, regardless of faction (direct
-- instruction): the Patrol Interceptor ship (§2.1.2) fitted with one basic
-- Auto Cannon ("Gnat") and one Mining Cannon ("Digger", §2.8) — one in each
-- weapon slot. The Asteroid Analyser (§2.8, a Computer-slot module) is NOT
-- part of the starting gift — it's available to purchase instead (see the
-- outpost screen's Shop tab), demonstrating the owned-vs-purchasable
-- distinction below.
local STARTING_SHIP_ID = "patrol_interceptor"
local STARTING_GIFT_SLOTS = {
	{ slot = "W1", item_key = "auto_cannon_basic" },
	{ slot = "W2", item_key = "mining_cannon_basic" },
}

-- Sets the chosen faction AND assigns the starting gift in one call, so
-- there's a single place that defines "what does a new character start
-- with" rather than that logic being duplicated at each call site. Each
-- starting item is granted as its own fresh instance (id 1, 2, ... after
-- the counter reset below), same as any other purchase — no special-cased
-- data shape for starting-gift items.
function M.choose_faction(faction)
	M.faction = faction
	M.owned_ships = { STARTING_SHIP_ID }
	M.active_ship_id = STARTING_SHIP_ID
	next_instance_id = 1
	M.owned = {}
	M.loadout = {}
	M.scrip = STARTING_SCRIP
	M.water = STARTING_WATER
	M.iron = STARTING_IRON
	M.hydrogen = STARTING_HYDROGEN
	for _, gift in ipairs(STARTING_GIFT_SLOTS) do
		local id = alloc_instance_id()
		table.insert(M.owned, { id = id, item_key = gift.item_key, level = 0 })
		table.insert(M.loadout, { slot = gift.slot, instance_id = id })
	end
end

function M.get_faction()
	return M.faction
end

function M.get_scrip()
	return M.scrip
end

function M.get_water()
	return M.water
end

function M.get_iron()
	return M.iron
end

function M.get_hydrogen()
	return M.hydrogen
end

-- The flat placeholder price/refund a caller (e.g. the outpost screen's
-- confirmation dialogs and Shop/For Sale card labels) should show and
-- charge for a given kind of transaction — see the STARTING_SCRIP
-- comment above on why these are placeholders, not real prices.
function M.get_module_price()
	return MODULE_PRICE
end

function M.get_module_sell_refund()
	return MODULE_SELL_REFUND
end

function M.get_ship_price()
	return SHIP_PRICE
end

function M.get_ship_sell_refund()
	return SHIP_SELL_REFUND
end

-- Spends `amount` Scrip if (and only if) the player can afford it —
-- returns false and changes nothing otherwise. The balance never goes
-- negative.
local function spend_scrip(amount)
	if M.scrip < amount then
		return false
	end
	M.scrip = M.scrip - amount
	return true
end

local function add_scrip(amount)
	M.scrip = M.scrip + amount
end

-- Kept as the existing accessor name (used throughout the outpost
-- screen already) - now returns the currently SELECTED owned ship,
-- rather than there only ever being one possible ship.
function M.get_ship_id()
	return M.active_ship_id
end

function M.get_owned_ships()
	return M.owned_ships
end

-- Does the player own `ship_id` at all?
function M.is_ship_owned(ship_id)
	for _, id in ipairs(M.owned_ships or {}) do
		if id == ship_id then
			return true
		end
	end
	return false
end

-- Switches the active ship to `ship_id`, if owned. No-op otherwise.
function M.select_ship(ship_id)
	if M.is_ship_owned(ship_id) then
		M.active_ship_id = ship_id
		return true
	end
	return false
end

-- Adds `ship_id` to owned ships if not already owned, spending
-- get_ship_price() Scrip (a flat placeholder, see STARTING_SCRIP's
-- comment - not real per-ship pricing). Returns false, spending nothing,
-- if the player can't afford it or already owns the ship.
function M.purchase_ship(ship_id)
	if M.is_ship_owned(ship_id) then
		return false
	end
	if not spend_scrip(SHIP_PRICE) then
		return false
	end
	table.insert(M.owned_ships, ship_id)
	return true
end

-- Returns the list of owned INSTANCES (see M.owned's own comment above) —
-- NOT catalog keys. Callers that need "do I own any copy of this type at
-- all" should use M.is_owned(item_key) instead of scanning this
-- themselves.
function M.get_owned()
	return M.owned
end

function M.get_loadout()
	return M.loadout
end

-- Looks up one owned instance by its id, or nil if no such instance
-- exists (e.g. already sold/removed — not a currently reachable case, but
-- callers should still handle it rather than assume).
function M.get_instance(instance_id)
	for _, inst in ipairs(M.owned or {}) do
		if inst.id == instance_id then
			return inst
		end
	end
	return nil
end

-- Is this SPECIFIC owned instance currently installed in any slot? Takes
-- an instance id, NOT a catalog item key — two owned copies of the same
-- module type can have different install states (and different upgrade
-- levels, M.upgrade below). Use M.is_type_installed for the "is ANY copy
-- of this type installed anywhere" query instead.
function M.is_installed(instance_id)
	for _, entry in ipairs(M.loadout or {}) do
		if entry.instance_id == instance_id then
			return true
		end
	end
	return false
end

-- Does the player own at least one instance of `item_key` (installed or
-- spare)? A "by type" convenience query — doesn't distinguish which
-- specific copy, or how many.
function M.is_owned(item_key)
	for _, inst in ipairs(M.owned or {}) do
		if inst.item_key == item_key then
			return true
		end
	end
	return false
end

-- Is any owned instance of `item_key` currently installed in any slot?
-- Same "by type, not by specific copy" convenience as M.is_owned.
function M.is_type_installed(item_key)
	for _, entry in ipairs(M.loadout or {}) do
		local inst = M.get_instance(entry.instance_id)
		if inst and inst.item_key == item_key then
			return true
		end
	end
	return false
end

-- Grants a brand-new OWNED INSTANCE of `item_key` — decided (§4): every
-- purchase creates its own separately-upgradeable physical copy, never
-- tops up a shared per-type count. Spends get_module_price() Scrip (a
-- flat placeholder, see STARTING_SCRIP's comment - not real per-item
-- pricing). Returns the new instance's id on success, so a caller (e.g.
-- the outpost screen's "drag a Shop card onto a slot" flow) can install
-- it immediately without a second lookup - or nil if the player can't
-- afford it, spending nothing.
function M.purchase(item_key)
	if not spend_scrip(MODULE_PRICE) then
		return nil
	end
	local id = alloc_instance_id()
	table.insert(M.owned, { id = id, item_key = item_key, level = 0 })
	return id
end

-- Upgrades one owned instance by a level. No cost/effect wired up yet —
-- real upgrade cost (Scrip? materials?) and what a level actually changes
-- (stats, per §2.8) are both still undesigned (plan.md §4); this just
-- moves the counter so the "does an upgrade survive uninstall/reinstall"
-- mechanic (the reason this per-instance model exists at all) is real and
-- testable. No-op (returns false) if the instance doesn't exist.
function M.upgrade(instance_id)
	local inst = M.get_instance(instance_id)
	if not inst then
		return false
	end
	inst.level = inst.level + 1
	return true
end

-- Installs `instance_id` into `slot`, used by the outpost screen's
-- drag-and-drop fitting UI (§2.8/§2.9). Whatever was previously in
-- `slot` simply becomes an uninstalled spare again (still owned, just no
-- longer in a slot) — this is NOT a true two-way swap with the dragged
-- item's own origin slot, just the simplest data-consistent behavior; see
-- plan.md §4. No-op if the instance isn't owned. Since `owned` entries are
-- never mutated by install/uninstall (only `loadout` membership changes),
-- an instance's `level` is untouched by any of this — moving a Gnat
-- between slots, or back out to being a spare, always preserves its
-- upgrade level, which is the whole point of tracking instances instead
-- of just type keys.
function M.install(slot, instance_id)
	if not M.get_instance(instance_id) then
		return false
	end
	-- pull this instance out of whatever slot it's currently in, if any
	for i, entry in ipairs(M.loadout) do
		if entry.instance_id == instance_id then
			table.remove(M.loadout, i)
			break
		end
	end
	-- whatever currently occupies `slot` is displaced back to being a spare
	for i, entry in ipairs(M.loadout) do
		if entry.slot == slot then
			table.remove(M.loadout, i)
			break
		end
	end
	table.insert(M.loadout, { slot = slot, instance_id = instance_id })
	return true
end

-- Removes whatever's installed in `slot`, if anything — the instance
-- stays owned (at its current upgrade level, untouched), just no longer
-- installed.
function M.uninstall(slot)
	for i, entry in ipairs(M.loadout) do
		if entry.slot == slot then
			table.remove(M.loadout, i)
			return true
		end
	end
	return false
end

-- Sells one owned module INSTANCE, per direct instruction ("there needs
-- to be an option to sell a component"). Uninstalls it first if it's
-- currently fitted somewhere (selling an equipped item unequips it,
-- rather than leaving a dangling loadout entry pointing at a
-- now-nonexistent instance), then removes it from `owned` entirely -
-- unlike M.uninstall, the instance itself stops existing, not just its
-- slot membership. Credits get_module_sell_refund() Scrip (a flat
-- placeholder, see STARTING_SCRIP's comment). Returns false if the
-- instance doesn't exist.
function M.sell(instance_id)
	if not M.get_instance(instance_id) then
		return false
	end
	for i, entry in ipairs(M.loadout) do
		if entry.instance_id == instance_id then
			table.remove(M.loadout, i)
			break
		end
	end
	for i, inst in ipairs(M.owned) do
		if inst.id == instance_id then
			table.remove(M.owned, i)
			break
		end
	end
	add_scrip(MODULE_SELL_REFUND)
	return true
end

-- Sells an owned SHIP, per direct instruction - with the explicit
-- constraint that direct instruction also gave: "you cannot sell all
-- ships." Refuses (returns false, no-op) if `ship_id` isn't owned, or if
-- it's the player's ONLY owned ship - a player must always have at least
-- one ship. Selling the currently ACTIVE ship (while others remain) is
-- allowed - the active ship just becomes whichever other owned ship
-- happens to be first in the list afterward, so there's always a valid
-- active ship. Credits get_ship_sell_refund() Scrip (a flat placeholder,
-- see STARTING_SCRIP's comment).
function M.sell_ship(ship_id)
	if not M.is_ship_owned(ship_id) then
		return false
	end
	if #M.owned_ships <= 1 then
		return false
	end
	for i, id in ipairs(M.owned_ships) do
		if id == ship_id then
			table.remove(M.owned_ships, i)
			break
		end
	end
	if M.active_ship_id == ship_id then
		M.active_ship_id = M.owned_ships[1]
	end
	add_scrip(SHIP_SELL_REFUND)
	return true
end

return M
