# Custom Nakama runtime modules

Empty for now — no server-authoritative game logic has been written yet
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
