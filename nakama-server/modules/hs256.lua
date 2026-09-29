--[[
HS256 JSON Web Token checks. Nakama can sign JWTs (nk.jwt_generate) but has no
way to verify one, so this does it: signature (HMAC-SHA256 over
"header.payload" with a shared secret), then decoding and expiry. Callers
check their own claims.

Used for play tokens from the website (modules/auth.lua) and for system
transfer tickets (modules/tickets.lua).
]]

local nk = require("nakama")

local M = {}

local function unpadded(s)
	return (s:gsub("=+$", ""))
end

local function base64url_decode(s)
	return nk.base64url_decode(s .. string.rep("=", (4 - #s % 4) % 4))
end

-- Returns the token's claims, or nil and a reason. `what` names the token
-- in those reasons ("ticket", "play token").
function M.verify(token, secret, what)
	what = what or "token"
	if type(token) ~= "string" then
		return nil, "missing " .. what
	end
	local header, payload, signature = token:match("^([%w_%-]+)%.([%w_%-]+)%.([%w_%-]+)$")
	if not header then
		return nil, "malformed " .. what
	end
	local ok_header, decoded_header = pcall(function()
		return nk.json_decode(base64url_decode(header))
	end)
	if not ok_header or type(decoded_header) ~= "table" or decoded_header.alg ~= "HS256" then
		return nil, "unsupported " .. what
	end
	local expected = unpadded(nk.base64url_encode(nk.hmac_sha256_hash(header .. "." .. payload, secret)))
	if expected ~= unpadded(signature) then
		return nil, "bad " .. what .. " signature"
	end
	local ok, claims = pcall(function()
		return nk.json_decode(base64url_decode(payload))
	end)
	if not ok or type(claims) ~= "table" then
		return nil, "unreadable " .. what
	end
	if type(claims.exp) ~= "number" or claims.exp < nk.time() / 1000 then
		return nil, what .. " expired"
	end
	return claims
end

return M
