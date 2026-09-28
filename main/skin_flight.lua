-- Shows a ship's equipped skin in flight, for main/player_ship.script (the
-- local ship) and main/remote_ships.script (other players). main/data/skins.lua
-- says how each skin can be shown:
--   flight_texture  recolors: swap the ship's own model texture. Textures are
--                   bundled via game.project's custom_resources
--                   (main/images/skin_textures/) and created on first use.
--   flight_factory  surface themes: spawn the skin's own model (a
--                   load_dynamically factory on main/skin_hub.go) as a child
--                   of the ship and hide the ship's own model component.
--   neither         sculpted themes/Clockwork: default model until Live Update.
--
-- Each ship keeps a `state` table from M.new_state(); M.show() replaces
-- whatever that ship was showing before, and M.clear() removes it.

local skins = require("main.data.skins")

local M = {}

local created = {} -- flight_texture path -> texture resource hash

local function texture_resource(path)
	if created[path] then
		return created[path]
	end
	local data = sys.load_resource(path)
	local img = data and image.load_buffer(data, { flip_vertically = true })
	if not img then
		print("[skin_flight] could not load " .. path)
		return nil
	end
	-- Texture constants live in the `graphics` module on current engines; the
	-- older `resource.*` names are the fallback.
	local g = graphics or resource
	local format = img.type == image.TYPE_RGBA and g.TEXTURE_FORMAT_RGBA or g.TEXTURE_FORMAT_RGB
	local name = path:match("([^/]+)%.png$")
	local texture = resource.create_texture("/skin_flight_" .. name .. ".texturec", {
		type = g.TEXTURE_TYPE_2D, width = img.width, height = img.height, format = format,
	}, img.buffer)
	created[path] = texture
	return texture
end

-- `parent`: the ship's game object id. `base`: url of its own (default) model
-- component. `setup(model_url)`: optional, called on a spawned skin model to
-- give it the same material constants (tint/light) the base model gets.
function M.new_state(parent, base, setup)
	return { parent = parent, base = base, setup = setup, default = go.get(base, "texture0"), generation = 0 }
end

-- Back to the ship's own model: removes a spawned skin model, restores the
-- base component and its texture.
function M.clear(state)
	state.generation = state.generation + 1 -- cancels any factory load still in flight
	if state.child then
		go.delete(state.child)
		state.child = nil
		msg.post(state.base, "enable")
	end
	go.set(state.base, "texture0", state.default)
end

-- Shows `skin_id` on the ship, or the default model when the skin is nil,
-- unknown, for a different ship/faction (other players' skins arrive over the
-- network and aren't trusted), or not showable in flight yet.
function M.show(state, skin_id, ship_id, faction)
	M.clear(state)
	local skin = skin_id and skins.SKINS[skin_id]
	if not (skin and skin.chassis == ship_id and skin.faction == faction) then
		return
	end
	if skin.flight_texture then
		local texture = texture_resource(skin.flight_texture)
		if texture then
			go.set(state.base, "texture0", texture)
		end
	elseif skin.flight_factory then
		-- The default model stays visible until the skin's resources load.
		local generation = state.generation
		factory.load(skin.flight_factory, function(_, _, ok)
			if not ok or generation ~= state.generation then
				return -- failed, or superseded by a later show()/clear()
			end
			local child = factory.create(skin.flight_factory, vmath.vector3(), vmath.quat())
			go.set_parent(child, state.parent, false)
			state.child = child
			msg.post(state.base, "disable")
			if state.setup then
				state.setup(msg.url(nil, child, "model"))
			end
		end)
	end
end

-- Whether `skin_id` shows up in flight at all (for the outpost's wording).
function M.shown_in_flight(skin_id)
	local skin = skin_id and skins.SKINS[skin_id]
	return skin ~= nil and (skin.flight_texture ~= nil or skin.flight_factory ~= nil)
end

return M
