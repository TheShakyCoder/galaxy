--[[
Sign-in: players are accounts on the website (Laravel, fig.limited), not here.

The website owns who a player is: registration, email verification, password
reset. When a verified player presses Play, it gives the game a short-lived
play token for this server: an HS256 JWT signed with this server's
PLAY_TOKEN_SECRET, with claims

  sub   the player's permanent website UUID
  aud   this server's SERVER_ID
  name  display name
  exp   expiry (unix seconds; about 2 minutes)

The game signs in with AuthenticateCustom { id = sub, vars = { token } }. The
before-hook below checks the token; the custom id is the website UUID, so the
same person has the same identity on every game server (with separate game
data on each). Every other way of signing in or linking is refused.

Storage hooks: saved progress (profile/state) is written only by
modules/economy.lua, so clients can't write that collection.

Runtime env (--runtime.env):
  PLAY_TOKEN_SECRET  shared with this server's row on the website
                     (php artisan galaxy:server)
  SERVER_ID          this server's slug on the website
]]

local nk = require("nakama")
local hs256 = require("hs256")
local version = require("main.version") -- copied from the game by tools/sync_server_rules.py

local function env(context, name)
	local value = context.env and context.env[name] or ""
	if value == "" then
		error(name .. " is not set (runtime env)")
	end
	return value
end

-- The play token's claims if it's valid for this server and this custom id,
-- or nil and a reason.
local function check_play_token(context, token, custom_id)
	local claims, reason = hs256.verify(token, env(context, "PLAY_TOKEN_SECRET"), "play token")
	if not claims then
		return nil, reason
	end
	if claims.aud ~= env(context, "SERVER_ID") then
		return nil, "play token is for another server"
	end
	if type(claims.sub) ~= "string" or claims.sub ~= custom_id then
		return nil, "play token is for another player"
	end
	return claims
end

local function sign_in(context, payload)
	local account = payload and payload.account
	local token = account and account.vars and account.vars.token
	local claims, reason = check_play_token(context, token, account and account.id)
	if not claims then
		nk.logger_warn("refused sign-in: " .. tostring(reason))
		return nil
	end
	-- Nakama picks a random username; the display name comes from the site.
	-- Session vars end up inside the session token, so the (checked) play
	-- token is swapped for just the name after_sign_in needs.
	payload.username = nil
	account.vars = { name = type(claims.name) == "string" and claims.name or "" }
	return payload
end

-- After signing in: keep the display name in step with the website's. The
-- vars were set by sign_in above, after the token was checked.
local function after_sign_in(context, _, payload)
	local name = payload and payload.account and payload.account.vars and payload.account.vars.name
	if context.user_id and type(name) == "string" and name ~= "" then
		pcall(nk.account_update_id, context.user_id, nil, nil, name)
	end
end

-- The server's release, so the game can ask for a reload when it's running
-- an older (cached) copy whose rules don't match.
nk.register_rpc(function()
	return nk.json_encode({ version = version.VERSION })
end, "server_version")

nk.register_req_before(sign_in, "AuthenticateCustom")
nk.register_req_after(after_sign_in, "AuthenticateCustom")

local function refuse()
	return nil
end

for _, api in ipairs({
	"AuthenticateApple", "AuthenticateDevice", "AuthenticateEmail", "AuthenticateFacebook",
	"AuthenticateFacebookInstantGame", "AuthenticateGameCenter", "AuthenticateGoogle", "AuthenticateSteam",
	"LinkApple", "LinkCustom", "LinkDevice", "LinkEmail", "LinkFacebook", "LinkFacebookInstantGame",
	"LinkGameCenter", "LinkGoogle", "LinkSteam",
	"UnlinkApple", "UnlinkCustom", "UnlinkDevice", "UnlinkEmail", "UnlinkFacebook", "UnlinkFacebookInstantGame",
	"UnlinkGameCenter", "UnlinkGoogle", "UnlinkSteam",
	"UpdateAccount", "DeleteAccount",
}) do
	nk.register_req_before(refuse, api)
end

-- Saved progress (profile/state) is written only by modules/economy.lua.
-- Its permission_write = 0 already stops clients overwriting it, but a new
-- player could otherwise create their own before the server does.
local SERVER_ONLY_COLLECTIONS = { profile = true, analysed = true }

local function client_writable(_, payload)
	for _, object in ipairs((payload and (payload.objects or payload.object_ids)) or {}) do
		if SERVER_ONLY_COLLECTIONS[object.collection] then
			return nil
		end
	end
	return payload
end

nk.register_req_before(client_writable, "WriteStorageObjects")
nk.register_req_before(client_writable, "DeleteStorageObjects")

nk.logger_info("auth module loaded (Galaxy " .. version.VERSION .. ")")
