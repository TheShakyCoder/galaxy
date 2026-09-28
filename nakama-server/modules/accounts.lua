--[[
Email accounts: verification codes and "verified players only" enforcement.

Players register and log in with Nakama's built-in email authentication
(the client calls AuthenticateEmail). Nakama has no email verification of its
own, so this module adds it:

  * A player is verified once their account metadata has
    email_verified = true. Only the server can write account metadata.
  * send_verification_code emails a 6-digit code (via Resend), stored
    server-only as a SHA-256 hash with an expiry and an attempt limit.
  * verify_email checks the code and marks the account verified.
  * Before-hooks stop unverified players from joining realtime channels
    (space rooms) or using storage, and stop every client from writing the
    server-owned collections (saved progress lives in profile/state and is
    only changed by modules/economy.lua).

Email is sent through Resend's HTTP API. Configure with runtime env vars
(--runtime.env on the nakama command line):
  RESEND_API_KEY  Resend API key. If empty, the code is written to the
                  Nakama log instead (local development only).
  EMAIL_FROM      Sender, e.g. "Galaxy <noreply@stupidly.uk>", on a domain
                  verified in Resend.
]]

local nk = require("nakama")
local version = require("main.version") -- copied from the game by tools/sync_server_rules.py

local CODE_COLLECTION = "verification"
local CODE_KEY = "code"
local CODE_TTL_MS = 15 * 60 * 1000
local RESEND_INTERVAL_MS = 60 * 1000
local MAX_ATTEMPTS = 5

local function now_ms()
	return nk.time()
end

local function result(tbl)
	return nk.json_encode(tbl)
end

local function account(user_id)
	return nk.account_get_id(user_id)
end

local function is_verified(user_id)
	local ok, acc = pcall(account, user_id)
	return ok and acc and acc.user and acc.user.metadata and acc.user.metadata.email_verified == true
end

-- 6 random digits from a v4 UUID (Nakama's CSPRNG), zero-padded.
local function new_code()
	local hex = nk.uuid_v4():gsub("-", "")
	return string.format("%06d", tonumber(hex:sub(1, 8), 16) % 1000000)
end

local function read_code(user_id)
	local objects = nk.storage_read({ { collection = CODE_COLLECTION, key = CODE_KEY, user_id = user_id } })
	return objects[1] and objects[1].value or nil
end

local function write_code(user_id, value)
	nk.storage_write({ {
		collection = CODE_COLLECTION, key = CODE_KEY, user_id = user_id, value = value,
		permission_read = 0, permission_write = 0,
	} })
end

local function send_email(context, to, code)
	local api_key = context.env and context.env.RESEND_API_KEY or ""
	if api_key == "" then
		nk.logger_warn(string.format("RESEND_API_KEY not set - verification code for %s is %s", to, code))
		return true
	end
	local body = nk.json_encode({
		from = context.env.EMAIL_FROM,
		to = { to },
		subject = "Your Galaxy verification code: " .. code,
		text = "Your Galaxy verification code is " .. code .. "\n\nIt expires in 15 minutes. "
			.. "If you didn't create a Galaxy account, you can ignore this email.",
		html = "<p>Your Galaxy verification code is</p><p style=\"font-size:28px;font-weight:bold;letter-spacing:4px\">"
			.. code .. "</p><p>It expires in 15 minutes. If you didn't create a Galaxy account, you can ignore this email.</p>",
	})
	local ok, status, _, response = pcall(nk.http_request, "https://api.resend.com/emails", "POST", {
		["Authorization"] = "Bearer " .. api_key,
		["Content-Type"] = "application/json",
	}, body, 10000)
	if not ok or status < 200 or status >= 300 then
		nk.logger_error(string.format("Resend failed for %s: %s %s", to, tostring(status), tostring(response)))
		return false
	end
	return true
end

-- { email, verified, server_version } - the game compares server_version with
-- its own to tell players when they need to reload.
local function account_status(context, _)
	local acc = account(context.user_id)
	return result({ email = acc.email, verified = is_verified(context.user_id), server_version = version.VERSION })
end

-- Emails a fresh code. { ok } or { ok = false, error, retry_in_s }
local function send_verification_code(context, _)
	local user_id = context.user_id
	local acc = account(user_id)
	if not acc.email or acc.email == "" then
		return result({ ok = false, error = "This account has no email address." })
	end
	if is_verified(user_id) then
		return result({ ok = true, already_verified = true })
	end
	local existing = read_code(user_id)
	local now = now_ms()
	if existing and existing.sent_at and now - existing.sent_at < RESEND_INTERVAL_MS then
		return result({ ok = false, error = "Please wait before requesting another code.",
			retry_in_s = math.ceil((RESEND_INTERVAL_MS - (now - existing.sent_at)) / 1000) })
	end
	local code = new_code()
	write_code(user_id, { hash = nk.sha256_hash(user_id .. ":" .. code), expires_at = now + CODE_TTL_MS, attempts = 0, sent_at = now })
	if not send_email(context, acc.email, code) then
		return result({ ok = false, error = "Couldn't send the email. Try again shortly." })
	end
	return result({ ok = true })
end

-- { code } -> { ok } or { ok = false, error }
local function verify_email(context, payload)
	local user_id = context.user_id
	if is_verified(user_id) then
		return result({ ok = true })
	end
	local input = payload and payload ~= "" and nk.json_decode(payload) or {}
	local code = tostring(input.code or ""):gsub("%s", "")
	local stored = read_code(user_id)
	if not stored then
		return result({ ok = false, error = "No code found. Request a new one." })
	end
	if now_ms() > stored.expires_at then
		return result({ ok = false, error = "That code has expired. Request a new one." })
	end
	if stored.attempts >= MAX_ATTEMPTS then
		return result({ ok = false, error = "Too many attempts. Request a new code." })
	end
	if nk.sha256_hash(user_id .. ":" .. code) ~= stored.hash then
		stored.attempts = stored.attempts + 1
		write_code(user_id, stored)
		return result({ ok = false, error = "That code isn't right." })
	end

	local acc = account(user_id)
	local metadata = acc.user.metadata or {}
	metadata.email_verified = true
	nk.account_update_id(user_id, metadata)
	nk.storage_delete({ { collection = CODE_COLLECTION, key = CODE_KEY, user_id = user_id } })
	nk.logger_info("email verified for user " .. user_id)
	return result({ ok = true })
end

nk.register_rpc(account_status, "account_status")
nk.register_rpc(send_verification_code, "send_verification_code")
nk.register_rpc(verify_email, "verify_email")

-- Unverified players can't reach the game: no realtime rooms, no saved
-- progress. Returning nil from a before-hook rejects the request.
local function verified_only(context, payload)
	if context.user_id and context.user_id ~= "" and is_verified(context.user_id) then
		return payload
	end
	return nil
end

-- Saved progress (profile/state) is written only by modules/economy.lua.
-- Its permission_write = 0 already stops clients overwriting it, but a new
-- player could otherwise create their own before the server does.
local SERVER_ONLY_COLLECTIONS = { profile = true, verification = true }

local function client_writable(context, payload)
	if not verified_only(context, payload) then
		return nil
	end
	for _, object in ipairs((payload and (payload.objects or payload.object_ids)) or {}) do
		if SERVER_ONLY_COLLECTIONS[object.collection] then
			return nil
		end
	end
	return payload
end

nk.register_rt_before(verified_only, "ChannelJoin")
nk.register_req_before(verified_only, "ReadStorageObjects")
nk.register_req_before(client_writable, "WriteStorageObjects")
nk.register_req_before(verified_only, "ListStorageObjects")
nk.register_req_before(client_writable, "DeleteStorageObjects")

nk.logger_info("accounts module loaded (Galaxy " .. version.VERSION .. ")")
