# Custom Nakama runtime modules

- `accounts.lua`: email verification codes (sent through Resend) and the
  hooks that keep unverified players out of realtime rooms and storage. See
  its header for the `RESEND_API_KEY` / `EMAIL_FROM` settings; with no key
  (local dev) codes are written to the nakama container's log.

- `economy.lua`: the only way a player's saved progress changes. The `economy`
  RPC replays each change (purchases, fitting, skins, FTL jump Hydrogen) with
  the game's own rules and saves the result; the profile is server-write-only,
  so currencies and items can't be tampered with.
- `directory.lua`, `system_match.lua`, `tickets.lua`, `registry.lua`: one
  authoritative match per star system. `enter_system` (directory) checks the
  player is really in that system, finds or creates its match via the registry
  and returns a one-use signed ticket; the match validates movement and relays
  it. Designed so systems can later be spread over several Nakama nodes (see
  the header of `directory.lua`).
- `main/`: **generated** copies of `main/session.lua` and the data it needs,
  made by `python tools/sync_server_rules.py`. Don't edit them here. Rerun the
  tool (and restart Nakama) after changing any of those files;
  `--check` fails if they're stale.

No combat or other server-authoritative gameplay has been written yet
(see plan.md §4's open TODO on designing the actual match modules for
combat resolution, module power/cooldown/wear enforcement, siege/economy
state, and the opposing-ship population cap, §2.7/§3.3).

The reference project (`~/Defold/SuperShips/nakama-server/modules/`) has
an example of the shape this tends to take: a background match (never
joined by any player) created once at server boot, that owns an NPC
population and tops it up on a timer — directly analogous to what our own
**Robots** faction (plan.md §1/§2.3, computer-managed PvE-only) or the
**opposing-ship population cap** (plan.md §2.7) would need here. Not
ported directly — that project's actual logic is specific to its own
roster/factions — but worth using as a structural reference when this
gets built out.
