# Temporary dev state — revert before release

Two deliberate temporary overrides are in place, per direct instruction
("*as a temporary measure, remove the restriction on which ships I can purchase.
And put 1 million of each resource into my player account. Keep a note of the
original amounts for when I revert*"). Neither is a balance decision and neither
belongs in a release. This file is the record of both; delete it once both are
reverted.

Two follow-up instructions widened the second one: its 1,000,000 was raised to
5,000,000 ("*change the temporary initial amount of resources to 5,000,000*"), and
the balances were then set for **every** player, not just mine ("*set all players
currencies and resources to 5,000,000*"). See §2.

## 1. Ship purchase level gate disabled — code, in this repo

`main/data/ship_class_levels.lua`: every class is `1`, so any ship can be bought
at any rank. The file itself also carries the original numbers in comments.

| Class   | Original level | Now |
|---------|----------------|-----|
| Patrol  | 1              | 1   |
| Escort  | 5              | 1   |
| Frigate | 10             | 1   |
| Carrier | 15             | 1   |

Revert:

```sh
# main/data/ship_class_levels.lua: Escort 1 -> 5, Frigate 1 -> 10, Carrier 1 -> 15
python tools/sync_server_rules.py    # re-copies the shared rules into nakama-server/modules
docker restart ddev-galaxy-nakama    # Nakama loads those Lua modules at startup, so this is required
```

The restart is not optional: the server enforces the same rules from its synced
copy (`nakama-server/modules/main/`), and it only reads them at startup. During
verification, a purchase that should have succeeded was refused until the
container was restarted after the sync — that is what that trap looks like.

The **client** reads the same file from its own HTML5 bundle, so the served
`play.ddev.site` bundle has to be rebuilt too, or the shop keeps showing "Level 5
required" and refusing the purchase before it ever reaches the server. The DDEV
post-start hook does that on the next `ddev restart`; `./tools/build_game.sh`
does it on its own (that is what was run here, and the rebuilt bundle is what
`play.ddev.site` now serves). Reload the page to pick it up.

Docs that still describe the pre-change levels (they are correct again once this
is reverted): `README.md` ("Escorts need level 5 and Frigates level 10"),
`CHANGELOG.md`'s older entry, and `plan.md` §2.2.

## 2. 5,000,000 of each currency and resource — every player — data, in the local Nakama DB

Every player who has a saved profile on the local DDEV server, not just one
account (per direct instruction: "*set all players currencies and resources to
5,000,000*"). Five players have a profile today:

| Account (Nakama username) | Nakama user id | Website UUID (custom id) |
|---------------------------|----------------|--------------------------|
| IzKTUlrymZ — Shaky Coder (`sharif.khan@mac.com`) | `dcf3b276-339c-43a2-9edf-e189b7ab159a` | `01a0f74d-2462-72fa-9d0b-be586b96793a` |
| BKoAUfViEE | `bda70671-e431-4df4-b372-7d22d79bbedd` | `01a0f729-799e-72f9-a48e-9e6ce9e467c8` |
| IKGtNzdsXP | `5351b816-6073-4352-8997-184847f9b1e6` | `01a0f6e9-e5ba-7051-82b2-754deff3ce85` |
| SatuyjeKlg | `af81762f-76a2-41b7-8563-ec2548903074` | `01a105ed-f920-70e6-bbec-01ab88ca465d` |
| zEHOPTBFDa | `8334dd58-37a2-4891-a92b-d78de8169b2d` | `01a0f6f4-ffff-71c0-8c73-979264b5aae6` |

Five of the eight Nakama users have a profile; the other three (`oeKUHSfQeU`,
`uyfmCirFhT`, and the empty system user) have never chosen a faction, so they
have no saved profile to set. A profile is created only at that choice
(`nakama-server/modules/economy.lua` refuses any op but `choose_faction` until
one exists) and the client writes it, so they are left alone — they will get the
new-character starting values if they ever play.

The five **live** balances are `tope` and `valour` (the two currencies) and
`water`, `iron`, `hydrogen` (the three resources) — exactly the keys
`main/session.lua`'s `serialize`/`restore` read and write. Each player's saved
profile is the Nakama storage object `collection = profile`, `key = state` in the
`nakama` database of the `ddev-galaxy-nakama-postgres` container. The game reads
it at login; only the server writes it.

### The original amounts

Shaky Coder was set first (to 1,000,000, then raised to 5,000,000 in the same
pass), and every other player was set to 5,000,000 afterwards.

| Account | Tope | Valour | Water | Iron | Hydrogen |
|---------|------|--------|-------|------|----------|
| Shaky Coder | 700 | 0 | 666 | 1452 | 6806 |
| BKoAUfViEE | *(absent)* | *(absent)* | 500 | 500 | 5000 |
| IKGtNzdsXP | *(absent)* | *(absent)* | 500 | 500 | 5000 |
| SatuyjeKlg | 1150 | *(absent)* | 935 | 832 | 5262 |
| zEHOPTBFDa | 1000 | 0 | 500 | 500 | 5000 |

"*(absent)*" means the profile carried no such key; the game falls back to the
new-character default when it reads one (`tope` 1000, `valour` 0). The two older
profiles also carry a dead `scrip: 1000` field that no code reads (a rename to
`tope` left it behind); it was left as it was.

Everything else in every profile (XP, owned modules, loadout, owned ships,
visited systems, assignments) is untouched. Each whole original object is kept
verbatim in the appendices, so a revert restores every account exactly — not
just the five balances — even if other fields move before then.

### Revert

Run this once per player, matching `<user_id>` to that player's own original JSON
from the appendices (Appendix A is Shaky Coder's; Appendix B has the other four):

```sh
docker exec -i ddev-galaxy-nakama-postgres psql -U postgres -d nakama -c "
UPDATE storage
   SET value = '<that player''s appendix JSON, one line>'::jsonb,
       version = md5(random()::text),
       update_time = now()
 WHERE collection = 'profile' AND key = 'state'
   AND user_id = '<user_id>';"
```

The `version` bump matters: Nakama writes are conditional on the object's
version, so leaving the old one lets a request that read the profile before this
edit overwrite it. A fresh version makes such a write conflict and retry instead
of silently winning.

The values were set on the row directly (SQL) rather than through any RPC on
purpose: no server operation grants currency — the only way a player gains
anything is by playing (`nakama-server/modules/resources.lua` credits mined
resources from the space match). There is deliberately no "give me money" API to
call.

### Affordability

With the class gate off, price is the only thing left limiting which ships can be
bought. At the first value (1,000,000 Hydrogen) two hulls were still refused for
funds — `frigate_assault` and `frigate_support`, both 2,000,000 Hydrogen
(`main/data/ships.lua`) — which is why the amount was raised to 5,000,000. At
5,000,000 every for-sale ship is affordable, so the only ship that cannot be
bought is the starter, `patrol_interceptor`, which has `price = nil` by design
(every new pilot already owns it). There are no Carrier-class ships defined yet,
though `ship_class_levels` still lists the class.

## What was verified when this was set up

- Every profile row was read back with `psql` and a field-by-field diff against
the values captured before the edit showed only the five balance keys changed
(`tope`/`valour`/`water`/`iron`/`hydrogen`) — no other field was touched on any
row.
- The live server agreed: the website's own server-to-server `player_summary` RPC
(`app/Services/NakamaClient.php`, which `nk.storage_read`s `profile/state`) was
asked for all five website UUIDs and returned `tope`/`hydrogen`/`water`/`iron`
5,000,000 for each. `valour` is verified only via the SQL read (that RPC doesn't
report it).
- `luajit tests/*_harness.lua` — all 10 harnesses pass with the gate open
  (`tests/ship_price_harness.lua` covers `purchase_ship`'s payment rules).
- Every ship enumerated through the game's own `session.purchase_ship` (the same
  code the server runs) at level 2: every `ship_level_required` reads 1, and every
  for-sale ship is buyable at the 5,000,000 balances. Re-run at the original
  1,000,000 too, where the two 2,000,000-Hydrogen Frigates were the only
  exception — that measurement is what prompted the raise.
- Through the **running server**, with a real play token (`php artisan
  galaxy:dev-token` → `AuthenticateCustom` → the `economy` RPC): buying
  `escort_interceptor` — an Escort, level 5 before this change — succeeded, and
  the saved profile showed the ship owned and exactly 600,000 Hydrogen spent.
  That test purchase was then undone.
- The final state was read back through the player's own storage read (what the
  game does at login) and matches "original + 5,000,000 each" exactly, with
  `owned_ships` back to just the starter.

## Appendix A — Shaky Coder's original profile object, verbatim

Exactly as it was read out of the `storage` row before any of this (one line, as
`psql -At` returned it, ready to paste into the revert SQL above):

```
{"xp": 1580, "iron": 1452, "tope": 700, "owned": [{"id": 1, "level": 0, "item_key": "auto_cannon_basic"}, {"id": 2, "level": 0, "item_key": "mining_cannon_basic"}, {"id": 3, "level": 0, "item_key": "asteroid_analyser"}, {"id": 4, "level": 0, "item_key": "armor_plating_patrol"}, {"id": 5, "level": 0, "item_key": "slide_thrusters_patrol"}, {"id": 6, "level": 0, "item_key": "emergency_hull_repair_patrol"}], "water": 666, "flying": true, "valour": 0, "faction": "accord", "loadout": [{"slot": "C1", "instance_id": 3}, {"slot": "W1", "instance_id": 2}, {"slot": "W2", "instance_id": 1}, {"slot": "E1", "instance_id": 5}, {"slot": "H1", "instance_id": 6}], "version": 1, "visited": {"sol": true}, "hydrogen": 6806, "assignments": {"date": "2026-10-06", "list": [{"id": "asteroid_recon", "done": false, "progress": 11}, {"id": "survey", "done": false, "progress": 0}, {"id": "outpost_raid", "done": false, "progress": 0}], "systems": {}}, "owned_ships": ["patrol_interceptor"], "owned_skins": {}, "active_ship_id": "patrol_interceptor", "advanced_ships": {}, "current_system": "sol", "equipped_skins": {}, "next_instance_id": 7, "launch_blocked_until": 1791294201.512}
```

## Appendix B — every other player's original profile object, verbatim

The four profiles that had never been overridden, one line each as `psql -At`
returned them just before this change (so each is both their pre-change state
and their true original),
ready to paste into the revert SQL above:

**BKoAUfViEE** — `bda70671-e431-4df4-b372-7d22d79bbedd`

```
{"xp": 0, "iron": 500, "owned": [{"id": 1, "level": 0, "item_key": "auto_cannon_basic"}, {"id": 2, "level": 0, "item_key": "mining_cannon_basic"}], "scrip": 1000, "water": 500, "faction": "accord", "loadout": [{"slot": "W1", "instance_id": 1}, {"slot": "W2", "instance_id": 2}], "version": 1, "visited": {"sol": true}, "hydrogen": 5000, "owned_ships": ["patrol_interceptor"], "owned_skins": {}, "active_ship_id": "patrol_interceptor", "advanced_ships": {}, "current_system": "sol", "equipped_skins": {}, "next_instance_id": 3}
```

**IKGtNzdsXP** — `5351b816-6073-4352-8997-184847f9b1e6`

```
{"xp": 0, "iron": 500, "owned": [{"id": 1, "level": 0, "item_key": "auto_cannon_basic"}, {"id": 2, "level": 0, "item_key": "mining_cannon_basic"}], "scrip": 1000, "water": 500, "faction": "accord", "loadout": [{"slot": "W1", "instance_id": 1}, {"slot": "W2", "instance_id": 2}], "version": 1, "visited": {"sol": true}, "hydrogen": 5000, "owned_ships": ["patrol_interceptor"], "owned_skins": {}, "active_ship_id": "patrol_interceptor", "advanced_ships": {}, "current_system": "sol", "equipped_skins": {}, "next_instance_id": 3}
```

**SatuyjeKlg** — `af81762f-76a2-41b7-8563-ec2548903074`

```
{"xp": 1450, "iron": 832, "tope": 1150, "owned": [{"id": 1, "level": 0, "item_key": "auto_cannon_basic"}, {"id": 2, "level": 0, "item_key": "mining_cannon_basic"}, {"id": 3, "level": 0, "item_key": "asteroid_analyser"}], "water": 935, "faction": "swarm", "loadout": [{"slot": "W1", "instance_id": 1}, {"slot": "W2", "instance_id": 2}, {"slot": "C2", "instance_id": 3}], "version": 1, "visited": {"polaris": true}, "hydrogen": 5262, "assignments": {"date": "2026-10-05", "list": [{"id": "asteroid_recon", "done": true, "progress": 20}, {"id": "survey", "done": false, "progress": 0}, {"id": "outpost_raid", "done": false, "progress": 0}], "systems": {}}, "owned_ships": ["patrol_interceptor"], "owned_skins": {}, "active_ship_id": "patrol_interceptor", "advanced_ships": {}, "current_system": "polaris", "equipped_skins": {}, "next_instance_id": 4}
```

**zEHOPTBFDa** — `8334dd58-37a2-4891-a92b-d78de8169b2d`

```
{"xp": 0, "iron": 500, "tope": 1000, "owned": [{"id": 1, "level": 0, "item_key": "auto_cannon_basic"}, {"id": 2, "level": 0, "item_key": "mining_cannon_basic"}], "water": 500, "flying": true, "valour": 0, "faction": "accord", "loadout": [{"slot": "W1", "instance_id": 1}, {"slot": "W2", "instance_id": 2}], "version": 1, "visited": {"sol": true}, "hydrogen": 5000, "owned_ships": ["patrol_interceptor"], "owned_skins": {}, "active_ship_id": "patrol_interceptor", "advanced_ships": {}, "current_system": "sol", "equipped_skins": {}, "next_instance_id": 3}
```
