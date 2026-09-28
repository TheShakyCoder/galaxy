-- Scrip price of one skin, by collection (main/data/skin_collections.lua's
-- keys). Priced by how much work the collection adds: recolors only swap the
-- texture, surface themes repaint panels, sculpted themes and Clockwork add
-- new geometry. Flat PLACEHOLDER values, same footing as main/session.lua's
-- own ship/module prices - not real economy design yet (§2.6/§4).
--
-- Hand-authored, unlike the generated skins.lua/skin_collections.lua beside
-- it, so tools/build_skin_index.py never overwrites these.

local M = {}

-- TEMPORARY: every skin costs 1 Scrip for testing. Delete this line to go back
-- to the per-collection prices below.
local TEST_PRICE = 1

M.PRICES = {
	-- Recolor
	aurora = 150,
	solar_regatta = 150,
	royal_amethyst = 150,
	-- Surface
	porcelain_dynasty = 250,
	starlight = 250,
	grand_prix = 250,
	-- Sculpted / new geometry
	abyssal = 400,
	crystalborn = 400,
	corsair = 400,
	overgrown = 400,
	toybox = 400,
	clockwork = 400,
}

if TEST_PRICE then
	for collection in pairs(M.PRICES) do
		M.PRICES[collection] = TEST_PRICE
	end
end

return M
