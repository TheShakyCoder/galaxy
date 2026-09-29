--[[
Transfer tickets: short-lived signed tokens (JWT, HS256) that let a player
join one system's match. Issued by modules/directory.lua's enter_system and
checked by modules/system_match.lua's match_join_attempt.

Claims: uid (player), sys (system id), match (match id), exp (unix seconds),
jti (unique id, single use).

Signed with TICKET_SECRET from the runtime env (--runtime.env). Every node
that hosts systems must share it, so a ticket issued by one node is accepted
by another. Nakama can generate JWTs but has no JWT check, so verify() does
the HS256 check itself.
]]

local nk = require("nakama")

local M = {}

local TTL_SECONDS = 60

local function secret(context)
	local value = context.env and context.env.TICKET_SECRET or ""
	if value == "" then
		error("TICKET_SECRET is not set (runtime env)")
	end
	return value
end

local function unpadded(s)
	return (s:gsub("=+$", ""))
end

function M.issue(context, user_id, system_id, match_id)
	local claims = {
		uid = user_id,
		sys = system_id,
		match = match_id,
		exp = math.floor(nk.time() / 1000) + TTL_SECONDS,
		jti = nk.uuid_v4(),
	}
	return nk.jwt_generate("HS256", secret(context), claims)
end

-- Returns the claims, or nil and a reason.
function M.verify(context, token)
	if type(token) ~= "string" then
		return nil, "missing ticket"
	end
	local header, payload, signature = token:match("^([%w_%-]+)%.([%w_%-]+)%.([%w_%-]+)$")
	if not header then
		return nil, "malformed ticket"
	end
	local expected = unpadded(nk.base64url_encode(nk.hmac_sha256_hash(header .. "." .. payload, secret(context))))
	if expected ~= unpadded(signature) then
		return nil, "bad ticket signature"
	end
	local ok, claims = pcall(function()
		return nk.json_decode(nk.base64url_decode(payload .. string.rep("=", (4 - #payload % 4) % 4)))
	end)
	if not ok or type(claims) ~= "table" then
		return nil, "unreadable ticket"
	end
	if type(claims.exp) ~= "number" or claims.exp < nk.time() / 1000 then
		return nil, "ticket expired"
	end
	if type(claims.uid) ~= "string" or type(claims.sys) ~= "string" or type(claims.jti) ~= "string" then
		return nil, "incomplete ticket"
	end
	return claims
end

return M
