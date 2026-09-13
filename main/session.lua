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
-- instruction): the Patrol 1 ship (§2.1.2) fitted with one basic Auto
-- Cannon ("Gnat") and one Mining Cannon ("Digger", §2.8) — one in each
-- weapon slot. The Asteroid Analyser (§2.8, a Computer-slot module) is NOT
-- part of the starting gift — it's available to purchase instead (see the
-- outpost screen's Shop tab), demonstrating the owned-vs-purchasable
-- distinction below.
local STARTING_SHIP_ID = "patrol_1"
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
	for _, gift in ipairs(STARTING_GIFT_SLOTS) do
		local id = alloc_instance_id()
		table.insert(M.owned, { id = id, item_key = gift.item_key, level = 0 })
		table.insert(M.loadout, { slot = gift.slot, instance_id = id })
	end
end

function M.get_faction()
	return M.faction
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

-- Adds `ship_id` to owned ships if not already owned. Price is TBD
-- (same "free grant, not a real transaction yet" caveat as
-- M.purchase for modules, §2.8/§4).
function M.purchase_ship(ship_id)
	if not M.is_ship_owned(ship_id) then
		table.insert(M.owned_ships, ship_id)
	end
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
-- tops up a shared per-type count. Price is TBD (§2.8) — still a free
-- grant, not a real purchase transaction. Returns the new instance's id,
-- so a caller (e.g. the outpost screen's "drag a Shop card onto a slot"
-- flow) can install it immediately without a second lookup.
function M.purchase(item_key)
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
-- slot membership. Price/refund is TBD (§2.8/§4), same "not a real
-- transaction yet" caveat as M.purchase. Returns false if the instance
-- doesn't exist.
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
	return true
end

-- Sells an owned SHIP, per direct instruction - with the explicit
-- constraint that direct instruction also gave: "you cannot sell all
-- ships." Refuses (returns false, no-op) if `ship_id` isn't owned, or if
-- it's the player's ONLY owned ship - a player must always have at least
-- one ship. Selling the currently ACTIVE ship (while others remain) is
-- allowed - the active ship just becomes whichever other owned ship
-- happens to be first in the list afterward, so there's always a valid
-- active ship. Price/refund is TBD (§2.8/§4), same caveat as M.sell.
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
	return true
end

return M
