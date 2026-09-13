# Galaxy — Game Design & Reference Plan

Working title: **Galaxy** (Defold/HTML5, Poki template project)

This document tracks the design intent, mechanical references, and technical plan for this
game. Read the IP section first — it governs everything else in this file.

---

## 0. IP & Legal Boundaries (read first)

This game is **mechanically inspired** by *Battlestar Galactica Online* (BSGO), a
browser-based MMO published by Bigpoint (2011–2016) under license from the *Battlestar
Galactica* franchise. BSGO itself is offline/defunct, but the underlying **Battlestar
Galactica intellectual property is still owned and actively protected** (currently by
Universal/NBCUniversal, via the Glen A. Larson estate rights and later franchise
holders). Defunct ≠ public domain.

**Game mechanics and systems are not copyrightable** (only their specific creative
expression is), so we are free to build a game with a similar *feel* and *systems*. We
must not, however, reuse anything that is BSG's specific creative expression.

### Not allowed (would infringe)
- Faction names **"Colonial(s)"**, **"Cylon(s)"**, or any BSG faction/political terms.
- Character names (Adama, Starbuck, Roslin, Baltar, Six, Boomer, etc.) or their likenesses.
- Ship/vehicle names: **Viper**, **Raptor**, **Battlestar**, **Basestar**, **Cylon Raider**,
  **Heavy Raider**, etc.
- Place/lore names: **Caprica**, **Cylon**, **Kobol**, **the Twelve Colonies**, **New
  Caprica**, **Tylium** (as the specific fuel-resource name), **Cubits** (as the
  specific in-universe currency name), the "And they have a plan" / "So say we all"
  taglines, the numbered-Cylon-model concept, the "this has all happened before and
  will all happen again" motif, etc.
- The BSG backstory (Cylon rebellion, genocide of the Twelve Colonies, search for Earth,
  the Opera House vision, etc.) in any recognizable form.
- BSG logos, insignia, ship silhouettes/hull designs, UI chrome, music, or any art traced
  or closely derived from the show/game.
- Marketing language implying official affiliation ("Battlestar Galactica the game",
  "based on the TV series", etc.).

### Allowed (genre mechanics, not BSG-exclusive)
These systems appear across many space-MMO/combat games (EVE Online, Star Trek Online,
Fractured Space, Homeworld, etc.) and are treated as generic genre conventions, not BSG
IP:
- Two-faction **asymmetric PvP** (one faction fields agile fighter-carrier fleets, the
  other fields autonomous/drone-swarm fleets).
- **Ship class tiers**: small fast strike craft → mid-size multirole ships → capital
  ships that can be boarded/escorted/repaired mid-battle.
- **Rank/skill progression** tied to account level and ship-class unlocks.
- **Fleet/squad "wings"** launched from and recalled to a capital ship.
- **Corporation/guild-style player organizations** for large-scale fleet battles.
- **Territory control / capital-ship siege** objectives (attack or defend a system node).
- **Module-based ship fitting** (weapons, armor, engines, utility slots).
- **Resource harvesting + crafting economy** feeding ship upgrades.
- Free-to-play structure with cosmetic/time-saver monetization (fits the Poki template).

**Rule of thumb before adding any noun to this game:** if it only makes sense because of
BSG, rename it. If it would still make sense in a generic space-combat game, it's fine.

### Research resources (reference for mechanics/history only — do not copy text, art, or audio)
- Wikipedia: "Battlestar Galactica Online" — high-level history, feature summary, shutdown date.
- Internet Archive Wayback Machine — archived snapshots of the official BSGO site/forums
  (useful for recalling *system names and UI flow*, not for lifting copy or art).
- MobyGames / archived press coverage & reviews — feature lists, patch notes summaries.
- Old YouTube "let's play" / patch-notes videos — good for recalling *mechanical* details
  (e.g., how sieges or fitting screens worked) without touching copyrighted assets.
- General MMO/space-combat design postmortems (EVE Online, Star Trek Online) for
  cross-checking that a given system is a genre convention, not BSG-specific.

When in doubt on any specific fact, pull it up and paraphrase the *mechanic*, never the
*flavor text*.

---

## 1. Original Setting (faction names finalized)

Faction names **The Accord** and **The Swarm** are locked in — passed a quick
online sanity check (not full legal clearance):
- **"The Accord"**: no faction-name collision found; only unrelated game titles
  ("Tribe of the Accord", "The Ord Accord") plus the generic dictionary/Honda-Accord
  usage turned up. Low risk.
- **"The Swarm"**: more crowded genre term — several small/unrelated games use "The
  Swarm" as a title, and Blizzard's *StarCraft* Zerg are widely nicknamed "the Swarm"
  (e.g. the expansion *Heart of the Swarm*). Trademark protects source-identifying
  branding, not an internal faction name used inside a different game, so direct
  legal risk is low — but the name itself isn't especially distinctive in the genre.
  Accepted as-is per direction to proceed.

- **Setting**: A fractured star cluster ("the Verge") where a human coalition and a
  rogue synthetic-fleet intelligence contest control of a dying home system's jump lanes.
- **Faction 1 — The Accord**: human coalition, crewed ships, pilot-skill-driven,
  strong in small/medium craft and boarding actions. **Player-selectable.**
- **Faction 2 — The Swarm**: machine-intelligence fleets, weaker individually,
  stronger in numbers/self-repair, strong in attrition and territory lockdown.
  **Player-selectable** — piloted by players, not purely autonomous (see §2.3; the
  "swarm" flavor is now a playstyle identity, not an NPC-only concept).
- **Faction 3 — Robots** (new, generic sci-fi term, not BSG-specific): a separate,
  **purely computer/AI-managed faction — never player-selectable**. Functions as the
  common hostile PvE faction that both Accord and Swarm players fight (missions,
  contested-zone raids, etc.); not part of the Accord-vs-Swarm PvP axis. Lore: the
  original, un-augmented robots the Accord abandoned once the Swarm's
  cyborg-augmentation line superseded them (see Backstory below).
- **Backstory (decided — creation order for all three factions)**:
  1. The Accord (humans) created **Robots** first, as automated labor/logistics.
  2. The Accord later grafted **synthetic human augmentations** onto a portion of
     those Robots, creating a hybrid line — this augmentation program is the origin
     of **The Swarm**. (Ties into §2.3's asymmetry: the human-derived augmentation is
     why Swarm ships are player-piloted rather than purely autonomous, unlike plain
     Robots.)
  3. The **un-augmented original Robots** were simply left behind/deactivated once
     the Cyborg-augmentation program superseded them — **abandoned** by the Accord,
     not destroyed. Drifting without oversight since, they're the origin of the
     present-day **Robots** faction: the computer-managed, non-player PvE opponent
     both Accord and Swarm players now fight.
  - No genocide narrative, no "final five", no religious prophecy — kept
    intentionally distinct from BSG's themes.
  - Open thread: why/how the augmented Swarm broke from Accord control into an
    independent, player-selectable faction is still TBD — the human-derived
    augmentation itself is a natural hook for that (e.g. augmentation-granted
    independent will leading to secession), but not yet written up.

### 1.1 Faction Selection & Persistence Rules
- **Registered account**: the faction-choice prompt (Accord vs. Swarm) is shown once,
  at account registration. The selection is written to the account and is
  **permanent** — there is no in-game faction-change or paid-respec feature.
- **Guest play** (no account): there's no persistent storage to hold the choice, so the
  faction-choice prompt is shown **every time the game loads**, each session.
- **Robots is never offered as a selectable option**, in either the account or guest
  flow — it exists only as computer-managed PvE opposition.
- **Returning registered users skip the faction prompt entirely** — their faction was
  already locked in at registration, and (per §3.2) a silent-login token takes them
  straight into the game without re-choosing anything.
- Full auth/session flow (guest vs. register vs. silent-login) is detailed in §3.2.

## 2. Core Gameplay Systems

### 2.1 Ship classes (decided — smallest to biggest)
| Tier | Role | Notes |
|---|---|---|
| Patrol | fast, cheap, disposable | early-game, squad filler |
| Escort | multirole, first "real" ship | tanking/DPS/support subtypes |
| Frigate | mid-capital, small-fleet flagship | fitting slots expand a lot here |
| Carrier | capital ship, launches Patrol-class ships, siege target | end-game progression goal |

#### 2.1.1 Ship stat schema + universal baseline (decided)

Every ship's inherent (unfitted) properties are organized into four stat groups.
**These values apply to all four classes** (Patrol/Escort/Frigate/Carrier) — this is
not a Patrol-only baseline that scales up per tier; it's the shared starting point
across the whole ship-class range. What differentiates classes is therefore fitting
capacity/slots (§2.8) and role, not these inherent stats.

**Hull Systems**
| Stat | Value |
|---|---|
| Hull Points | 650 |
| Hull Recovery | 5/sec |
| Durability (full-repair cost) | 10,000 **Iron** (renamed from the source's Titanium-icon repair-cost stat, matching our repair resource, §2.6) |
| Armor | 5 |
| Critical Defense | 100 |

**Engine Systems**
| Stat | Value |
|---|---|
| Avoidance | 500 |
| Turning Speed | 47.5°/sec |
| Turning Acceleration | 47.5°/sec² |
| Inertial Compensation | 100 m/sec |
| Acceleration | 10 m/sec² |
| Speed | 52.5 m/sec |
| Boost Speed | 77.5 m/sec |
| Boost Cost | 0.6 **Hydrogen**/sec (renamed from the source's Tylium unit, §2.6) |

**FTL Systems**
| Stat | Value |
|---|---|
| FTL Range | 5.5 LY |
| FTL Charge | 15 sec |
| FTL Cost | 30 **Hydrogen**/LY (renamed from Tylium) |

**Computer Systems**
| Stat | Value |
|---|---|
| Power | 175 |
| Power Recharge | 6/sec |
| Firewall Rating | 200 |
| Emitter Rating | 200 |
| Sensor Range | 3,000 m (renamed from the source's "Dradis Range" — DRADIS is BSG-specific terminology, §0) |
| Visual Range | 500 m |

- This four-group schema (Hull / Engine / FTL / Computer Systems) is the stat
  template in `ship_classes.lua` (§3.1) — but per the above, all four classes share
  this **same** filled-in set of values rather than each getting its own.
- FTL Systems formalizes Hydrogen's fuel role (§2.6) — FTL jumps cost Hydrogen per
  light-year, boosting costs Hydrogen per second. This resolves the open TODO on
  whether Hydrogen keeps the fuel mechanic: **yes**, confirmed by this data.

#### 2.1.2 Ship roster (decided — two entries implemented)

**Implemented**: `main/data/ships.lua` — individual named ships within a class,
separate from the class-level baseline above. First entry: **Patrol 1** (working
name), in the Patrol class. Second entry: **Escort 1** (working name), in the Escort
class, per direct instruction.

- **Shared-vs-per-faction data model (decided)**: only three things differ between
  The Accord's and The Swarm's version of a given ship — **name**, **3D model**, and
  **weapon GUI/icon set**. Every characteristic/stat is identical. So each ship is
  **one entry** with a small `faction_skins` override table for just those three
  fields — **not** two fully separate per-faction listings.
- **Why**: duplicating a full ship entry per faction for data that's supposed to be
  identical is exactly what caused real stat-drift bugs in the other local reference
  project (`~/Defold/SuperShips/main/config.lua` — its header comments describe "the
  old Viper Mk II/Raider and Raven/Malefactor mirror mismatches"), which is why that
  project deliberately unified onto one shared roster too.
- **Patrol 1**'s full stat block (§2.1.1's Hull/Engine/FTL/Computer Systems) is now
  populated directly on its own entry (`data`), rather than left as pure inheritance
  from `ship_classes.lua` — with one deliberate override: **Hull Points 600** (vs.
  the class baseline's 650). Every other field currently matches the baseline as-is,
  pending real per-ship tuning. This is the intended pattern going forward: a ship
  carries its own full stat data, and only fields that need to differ from its
  class's baseline are actually changed.
- Robots (§1, computer-managed only) don't need a `faction_skins` entry on
  player-facing ships like this one, since they're never player-selectable.
- Patrol 1's `model` now points at a real hand-authored glTF hull (this section
  originally said `nil`/placeholder-cube, before that model existed — see §2.8's
  model/icon work). **Deliberately not** using the SuperShips reference project's
  actual Viper Mk II/Cylon Raider meshes — those are BSG-derived vehicle designs,
  off-limits per §0 regardless of the CC-BY license on the mesh files themselves
  (that license covers only the modeler's own copyright in the file, not the
  underlying BSG-owned design). `weapon_gui` is still a `<TBD>` placeholder — see §4.
- **Escort 1** (`escort_1`), added per direct instruction: `class = "Escort"`, stat
  block is the **unmodified universal baseline** (§2.1.1) with no overrides — unlike
  Patrol 1's Hull Points override, no specific tuning has been given for this ship
  yet, so it uses the shared starting point as-is rather than an invented number.
  `components`/`slot_positions` are deliberately left **empty** (not guessed) —
  no source slot-count number has been given for Escort the way Patrol 1 had the
  Viper Mk II standard tier, and plan.md's own rule is "don't invent unconfirmed
  numbers" (§0/§4). The outpost screen already handles a ship with zero
  `slot_positions` correctly (0 fitting-slot markers, not a crash — this is exactly
  the scenario `outpost_harness2.lua`'s Ships tab test used to have to *fake* with an
  injected placeholder ship before Escort 1 existed for real). `model`/`weapon_gui`
  are `<TBD>` — no 3D hull has been built for this ship, and the outpost screen's
  ship visual is hardcoded to Patrol 1's own top-down image regardless of the active
  ship anyway (§4), so nothing reads this field yet either way.

**Ship naming convention (decided)**: real-world animal species, sized to roughly
match the ship's class — smaller species for smaller classes, bigger species for
bigger classes:
- **The Accord**: fish species.
- **The Swarm**: bird species.

| Class | Accord (fish) | Swarm (bird) | Notes |
|---|---|---|---|
| Patrol | **Sardine** (proposed) | **Hummingbird** (proposed) | Both real animals chosen for small/fast/schooling-or-darting flavor, matching Patrol's "fast, cheap, disposable" role (§2.1) |
| Escort | **Barracuda** (proposed) | **Falcon** (proposed) | Predatory/combat-flavored species (vs. Patrol's small/schooling-or-darting flavor), matching Escort's "first real," combat-capable role (§2.1) |
| Frigate | TBD, larger still | TBD, larger still — *Frigatebird* is an obvious real-species pun worth considering here | Not yet assigned |
| Carrier | TBD, largest — *Whale Shark* (the largest real fish species) is a natural fit | TBD, largest — e.g. *Albatross* (largest wingspan) | Not yet assigned |

- **Patrol 1's proposed names** — same confirm-or-correct pattern as Scrip/Valor:
  Accord = **Sardine**, Swarm = **Hummingbird**. Set in `main/data/ships.lua`'s
  `faction_skins`, replacing the old `<TBD>` name placeholders — flag if you want
  different species.
- **Escort 1's proposed names**, same pattern: Accord = **Barracuda**, Swarm =
  **Falcon**. Set in `main/data/ships.lua`'s `escort_1` entry.
- Only the size-relative-to-class rule is fully decided; the actual species for
  Frigate/Carrier are just illustrative ideas above, not commitments, since those
  ships don't exist in the roster yet.

**Component slot counts (decided)** — per direct instruction: Patrol 1 started from the
reference project's own **Viper Mk II standard tier** slot counts
(`~/Defold/SuperShips/main/config.lua`'s `M.SHIPS["Viper Mk II"].components`) —
W=3, C=2, E=3, H=1 (9 slots total), not its *advanced* tier (W=3, C=2, E=5, H=2) — then
**H was bumped from 1 to 2** per a later direct instruction, so Patrol 1 now reads
**W=3, C=2, E=3, H=2 (10 slots total)**, no longer an exact match to either reference
tier. Plain integers are a balancing fact, not creative expression, so reuse (and this
kind of deviation from it) is fine per §0 — same footing as the Hull/Engine/FTL/Computer
stat block already adopted this way (§2.1.1).
- Applied to **Patrol 1 as a whole** (a ship-level field, `main/data/ships.lua`'s
  `components`), shared by both faction skins — consistent with the existing "only
  name/model/weapon_gui differ per faction" rule (§2.1.2 above). The instruction
  said "for the Sardine," which I read as shorthand for Patrol 1 in general (Sardine
  being the name you're using for it) rather than an Accord-only stat — **flag if
  Accord-only was actually intended**, which would need a small architecture change
  (slot counts currently aren't a per-`faction_skins`-entry field).
- `slot_positions` (§2.9) expanded from 3 to all 9 entries to match — still
  placeholder coordinates, but now spread sensibly across the hull (bow/midships
  guns, cabin-mounted computers, stern engines, amidships hull slot) rather than
  just the original 3. Verified within the ship visual's image bounds, and both
  outpost-screen test harnesses re-run and passing (one harness's hardcoded
  "3 markers" assumption had to be updated to 9 to match).

### 2.2 Progression
- Account rank gates ship-tier access (mirrors BSGO's ensign→admiral-style curve, but
  with original rank names).
- Skill/spec trees per role (gunnery, engineering, command) rather than per-class-only.

### 2.3 Faction asymmetry
Three factions total (see §1), but only two sit on the PvP axis — Robots is a separate,
computer-managed PvE-only opponent, not part of this asymmetry:
- **The Accord** (player-selectable): crewed, pilot-skill-weighted, strong alpha strike,
  weaker sustain.
- **The Swarm** (player-selectable): swarm-weighted, self-repair/respawn-in-place,
  weaker per-unit but stronger attrition and area denial.
- **Robots** (computer-managed only, not player-selectable): AI-controlled hostile
  faction encountered by both Accord and Swarm players in PvE content; not part of the
  Accord-vs-Swarm PvP dynamic.

### 2.4 Fleet & social systems
- Player-formed "wings" (small squad) and "fleets" (guild-scale) for large PvP.
- Carriers can carry/launch player-piloted Patrol-class ships.

### 2.5 PvE / PvP loop
- PvE missions to earn currency/resources and unlock modules.
- PvP contested-node map: control points feed toward a capital-ship siege window.
- Sieges: attacking fleet must break a shield/defense phase before the node flips.

### 2.6 Economy (revised — mapped from researched BSGO economy structure)

Researched BSGO's actual economy (Currency, Titanium, Mining/Asteroid Mining, Merits,
and Rewards-from-Battle wiki pages, via search — the fandom wiki itself 402'd on
direct fetch both times it was tried) and mapped its *structure* onto our resources,
per §0 (mechanics/structure are fair game; BSG-specific names are not). Numbers below
are intentionally not carried over 1:1 from the source — only the roles/relationships
are; exact rates are a balancing pass for later (§4).

**Three harvestable resources — roles swapped per confirmed correction, and
Titanium renamed to Hydrogen:**

| Our name | Role | Reference-game role it replaces (internal only, never player-facing) |
|---|---|---|
| **Hydrogen** (renamed from Titanium) | Base/general resource — **does not convert into Scrip**. Instead, Hydrogen is spent **directly** as a basic-tier currency-resource: cheap/everyday shop purchases can be paid for with Hydrogen alone. More advanced purchases require an additional resource/currency **on top of** Hydrogen (Scrip being the main example) — mirrors the source game's pattern where its base resource paid for most things outright, but pricier items needed it combined with the premium currency. Also confirmed as **ship fuel** — FTL jumps and boost both cost Hydrogen (§2.1.1). | Replaces **"Trillium"** (per confirmed intent — same name-association as when this resource was still called Titanium, just carried over to the rename). |
| **Iron** | Dedicated **repair** resource — repairs ship wear/tear over time (hull + module wear, §2.8). Swapped from Hydrogen/Titanium's old role. | Replaces **"Deuterium"** (per confirmed intent). |
| **Water** | Sells toward **Scrip** (Marque abandoned — see below; Water's sale now
feeds Scrip directly instead) — an efficient farming resource. | Water (name unchanged) — in the source game Water was a minor/flavor resource whose main gameplay purpose was conversion into the premium currency |

**Two currencies** (Marque abandoned — folded into Scrip; down from the earlier
three-currency draft):

| Currency | Tier | Earned via | Spent on |
|---|---|---|---|
| **Scrip** | General | **For now, exactly two sources, decided**: (1) mining an asteroid that contains Water and selling that Water for Scrip; (2) buying Scrip directly with real money. No other earn source (combat rewards, daily assignments, Robot kills, etc.) is active yet — those were provisional ideas from the Marque-merge, not confirmed for Scrip. | Everything beyond basic Hydrogen-only purchases — advanced items, ships, ship upgrades, booster items, resources — typically **required alongside Hydrogen** rather than replacing it |
| **Valor** (new, replaces "Merits") | PvP-only | **PvP kills only** (never from PvE/Robots) — small amount per kill, a bonus for damaging/forcing the retreat of an enemy siege objective (ties directly into the contested-node siege mechanic, §2.5), and a bigger bonus for destroying an enemy Carrier | Nuclear ordinance specifically (Nuclear Torpedoes/Launchers, §2.8) and Carrier-class ships — gates the highest-end purchases behind PvP performance, not spending |

- Proposed name **Valor** is a placeholder pending confirmation, same as Scrip was —
  flag if you want a different name.
- Marque (the premium-tier currency) is **abandoned** — its spend role (ships,
  upgrades, boosters) has folded into Scrip, which is now the single non-PvP
  currency. Only two of Marque's former earn sources (selling Water, real-money
  purchase) carried over — see the confirmed two-source list above.
- Deliberately not carried over: the source game's specific named ships tied to its
  PvP currency (e.g. specific multirole/stealth ship names) — those are BSG-specific
  proper nouns, out of bounds regardless of context (§0).
- Resources convert to refined material for crafting/fitting.
- Module fitting: weapon / armor / engine / utility slots per ship tier.
- Poki/F2P monetization: cosmetics, convenience (queue skips, extra ship slots), and
  **direct real-money purchase of Scrip**, which buys most fitting/upgrades —
  pay-to-win is accepted as part of the monetization model (the earlier "no
  pay-to-win" stance is abandoned).

### 2.7 Star system map (decided — real data file now exists)

**Implemented**: `main/data/star_systems.lua` — 58 star systems. Topology (positions,
sizes, the two faction-locked home systems, the threat-rating concept) is
structurally reconstructed from BSGO's real "Veil Sector" map — a prior local
project (`~/Defold/SuperShips/main/sector_map.lua`) had already done this
reconstruction from the fandom wiki. That's structural/functional reuse (positions,
node count, access rules), allowed under §0 the same way "territory control /
capital-ship siege" already is.

- **Names**: every one of the 58 systems is named after a **real star or star
  system** (Sol, Sirius-family designations, Bayer designations like Epsilon
  Eridani/Tau Ceti, Flamsteed-numbered stars like 61 Cygni/55 Cancri, exoplanet-host
  catalog stars like HD 209458/Gliese 667, etc.) — not BSGO's own invented system
  names.
- **Home systems**: deliberately **not** reusing BSGO's own specific home-system
  choices (its Colonial home was "Alpha Ceti", Cylon home "242 Apollid") even where
  one of those happens to itself be a real star — picked an independent pair
  instead: **Sol** (The Accord) and **Polaris** (The Swarm).
- **Do not** reuse the *Twelve Colonies* names (Caprica, Picon, Aerilon, Tauron,
  Gemenon, Leonis, Libran, Sagittaron, Scorpia, Virgon, Canceron, Aquaria) — those are
  BSG-show IP. None appear anywhere in the new data.
- **Mechanics carried over** (see the file itself): straight-line map distance,
  faction-gated `can_enter`, FTL-range reachability, and a per-jump **Hydrogen** cost
  (renamed from the source's Tylium-cost function, §2.6) — all structural/functional,
  not creative expression.
- **Home buffer zone (decided)**: a faction can't enter the opposing faction's home
  system, **and also can't enter the 3 systems nearest to it** — not just the single
  home system. Computed once from the map's own distances and stored as
  `M.HOME_BUFFER`:
  - Accord home (**Sol**) buffer: Wolf 359, Tau Ceti, Beta Andromedae
  - Swarm home (**Polaris**) buffer: Merak, Ankaa, Gliese 667
  - `M.zone_owner(system_id)` returns which faction (if any) a system is
    restricted to — home system or buffer zone — and `M.can_enter` now checks
    that instead of just the home system alone.
- **Threat rating**: carried over as a design/balancing reference only, same caveat
  as everywhere else in this doc — not final tuning.

**Outposts (decided)** — resolves the outpost-scope question from §2.9:
- **General rule**: every one of the 58 systems has an outpost for **each** faction
  by default (not just the two home systems) — these are the in-system dock/spawn
  points §2.9's spawn rules refer to.
- **Default position**: "approximately opposite corners" of the system's in-flight
  world space, computed generically from `size_m` (80%-to-edge placeholder inset) —
  not hand-placed per system.
- **Exception**: a faction's home system, **plus the 6 systems nearest to it**, deny
  the *opposing* faction an outpost entirely. This is a wider zone than §2.7's
  entry-blocking `HOME_BUFFER` (nearest 3, "can't even enter") — the nearest-3 list
  is always a subset of the nearest-6 list, so the two zones nest cleanly:
  - Accord home (Sol) + nearest 6 → no Swarm outpost: Sol, Wolf 359, Tau Ceti, Beta
    Andromedae, Epsilon Indi, Avior, Barnard's Star
  - Swarm home (Polaris) + nearest 6 → no Accord outpost: Polaris, Merak, Ankaa,
    Gliese 667, 70 Virginis, Acrux, Spica
- **Implemented** in `main/data/star_systems.lua`: `M.OUTPOST_DENIED`,
  `M.has_outpost(system_id, faction)`, `M.outpost_position(system_id, faction)`.
  Verified working (denied systems correctly return no outpost/position; open
  systems get correct opposite-corner coordinates scaled to each system's own
  `size_m`, including the two 40,000m systems).
- **Future gameplay, explicitly deferred**: how outposts can be attacked and what
  defenses they have is not designed yet — flagged in §4, not invented here.

**Spawn points (decided)** — 2 per faction per system, not 1, specifically to avoid
spawn-camping:
- Reuses the same inset "corner" concept as outpost placement above (not the
  system's literal edge).
- For a faction's own corner: the midpoints toward each of its two *adjacent*
  corners (roughly the middle of the two nearest map edges — not the diagonal
  corner, which is the opposing faction's own outpost). An earlier draft also added
  a 3rd point at one of the two corners unused by either outpost — removed, just
  the two midpoints now.
- Only defined where the faction actually has an outpost in that system
  (`M.has_outpost`) — matching `outpost_position`'s own behavior. A faction that can
  *enter* a system without an outpost (the population-capped zone, one tier out)
  needs a different spawn concept entirely (e.g. an FTL jump-in point rather than a
  fixed respawn point) — not decided, see §4.
- **Implemented and verified** in `main/data/star_systems.lua`: `M.spawn_points(system_id, faction)`. Checked: correct scaling on both the
  10,000m and 40,000m systems, correctly returns `nil` where a faction has no
  outpost, and no coordinate collisions — between the two factions' point sets, or
  with either outpost's own position.

**Opposing-ship population cap (decided, value TBC)**: in the systems with no
outpost for the opposing faction but that are still enterable — the 4th/5th/6th
nearest to each home system, i.e. one tier out from `HOME_BUFFER`'s fully-blocked
innermost 3 — the number of the opposing faction's ships allowed present at once is
capped:
- Sol region (Swarm capped): Epsilon Indi, Avior, Barnard's Star
- Polaris region (Accord capped): 70 Virginis, Acrux, Spica
- Current cap: **50**, a global placeholder — explicitly flagged as not final, needs
  real balancing (§4).
- **Implemented** in `main/data/star_systems.lua`: `M.OPPOSING_SHIP_CAP`,
  `M.SHIP_CAP_ZONE`, `M.ship_cap(system_id, faction)`. Verified working. Actually
  *enforcing* this (counting live ships per system in real time) is a server-side/
  Nakama match concern, not a data-layer one — see §4/§3.3.

### 2.8 Module / fitting system (decided — taxonomy and rules)

**Four module types**, all **class-specific** (a given module only fits certain ship
classes/tiers from §2.1 — exact fitting-slot counts per class still TBD, see §4):
- **Weapon** — split into two subtypes: **Auto Cannons** and **Launchers**.
- **Hull**
- **Engine**
- **Computer**

**Auto Cannons further split into two types** (decided):
| Auto Cannon type | Needs ordinance? | Role |
|---|---|---|
| **Mining Cannon** | No | Best suited for mining asteroids (ties into resource harvesting, §2.6); largely ineffective against other ships |
| **Ordinance Cannon** | Yes | Consumes **ordinance** (ammo) — a variety of ordinance types exist with different specs, **TBD** (see §4) |

- **Ordinance** is therefore its own consumable data concept, separate from the cannon
  module itself — a player fits an Ordinance Cannon, then loads/consumes ordinance
  into it. Gets its own data file per the one-table-per-file rule: `ordinance.lua`.

**Launchers always require ordinance** — specifically **missiles** or **torpedoes**
(decided), with a compatibility rule that differs from cannon ordinance:
| Launcher ordinance | Compatibility |
|---|---|
| **Missiles** | Generally interchangeable across different launchers — broad compatibility |
| **Torpedoes — Nuclear** | Restricted: a Nuclear Torpedo can only be fired from a **Nuclear Launcher** specifically, not a general-purpose launcher |

- This implies Launchers themselves have at least two subtypes: a general-purpose
  launcher (fires missiles) and a **Nuclear Launcher** (fires nuclear torpedoes only).
  Whether non-nuclear torpedoes also exist, and whether the general launcher fires
  both missiles and non-nuclear torpedoes, is **TBD** (see §4).
- `ordinance.lua` needs a compatibility field per entry (e.g. `compatible_launcher_type`:
  general vs. nuclear-only) to encode this restriction, not just a flat "fits any
  launcher" assumption.

**Activation behavior** — three categories, not one-per-type:
| Behavior | Applies to | How it works |
|---|---|---|
| **Toggle** | Weapons only | Explicitly switched on/off by the player; stays active until toggled off again |
| **Passive** | Hull, Engine, Computer | No activation at all — just provides a permanent stat adjustment to the ship while fitted |
| **Active (one-shot)** | Hull, Engine, Computer | Triggered for a single one-time activation — not a toggle, not held on |

So Hull/Engine/Computer modules are each *either* passive *or* one-shot-active (never
a toggle); Weapons are always toggle-type.

**Universal module rules** (apply to every module, regardless of type/behavior):
- **Power**: every module draws on the ship's power pool — it can only be
  activated/toggled on if the ship currently has enough spare power.
- **Cooldown**: every module has a cooldown before it can be used/toggled again.
- **Wear**: every use causes a very slight wear/durability loss. **Repair mechanic
  decided** (§2.6): wear is repaired by spending **Iron**, the dedicated repair
  resource. Where repairing is allowed (station/home system
  only vs. mid-mission) is still TBD, see §4.
- **Class-specific fitting**: a module is only fittable on specific ship classes.

**Data tables** (§3.1) — modules split by type/subtype rather than one giant list,
consistent with the one-table-per-file rule:
- `weapons_autocannons.lua` (holds both Mining and Ordinance cannon entries, with a
  `cannon_type` field distinguishing them), `weapons_launchers.lua`, `hull_modules.lua`,
  `engine_modules.lua`, `computer_modules.lua`, `ordinance.lua` (ammo consumed by
  Ordinance Cannons and Launchers alike).
- Suggested shared fields per module: `id`, `name`, `type`, `behavior` (toggle /
  passive / active), `ship_classes` (which classes it can fit), `power_draw`,
  `cooldown`, `wear_per_use`, plus type-specific stat fields (e.g. damage/rate of
  fire for weapons, stat bonus for passive hull/engine/computer modules).

**`ordinance.lua` — one shared table for all ordinance** (decided): cannon ammo,
missiles, and torpedoes all live in the **same table**, not split across separate
files — each row is classified so the fitting/firing logic can restrict it to the
correct weapon(s):
- `id`, `name`
- `weapon_type` — which weapon category this ordinance belongs to: `cannon`,
  `missile`, or `torpedo`.
- `compatible_weapon` — the specific weapon/launcher-type restriction, e.g. a given
  Ordinance Cannon model for cannon ammo, `general` for interchangeable missiles, or
  `nuclear_launcher` for Nuclear Torpedoes (locked to Nuclear Launchers only, §2.8
  above).
- Per-type spec fields (damage, blast radius, etc.) — TBD once ordinance types are
  fully designed (see §4).
- The classification (`weapon_type` + `compatible_weapon`) is what prevents, e.g., a
  Mining Cannon from firing missiles, or a general launcher from firing a Nuclear
  Torpedo — enforced by data, not by separate tables per weapon.

**Starting gift (decided, revised)**: one **Auto Cannon** (Ordinance-type,
`auto_cannon_basic`, `cannon_type = "ordinance"`) and one **Mining Cannon**
(`mining_cannon_basic`) — not two of the same cannon. The Mining Cannon needed an
actual name; **decided: "Digger"** (renamed from the original "Prospector" — see the
mining naming scale below, which reuses "Prospector" for the Carrier tier instead).

**Combat auto cannon naming convention (decided)**: named after **insects**, sized to
roughly match the ship class they're built for — a third real-world-animal family
alongside the ship roster's fish (Accord)/bird (Swarm) names (§2.1.2), reserved
specifically for Ordinance-type (combat) auto cannons.

| Ship class | Combat auto cannon name | Notes |
|---|---|---|
| Patrol | **Gnat** (decided) | `auto_cannon_basic` — the starting-gift cannon |
| Escort | **Hornet** (reserved) | No Escort-tier cannon exists yet |
| Frigate | **Locust** (reserved) | No Frigate-tier cannon exists yet |
| Carrier | **Beetle** (reserved) | No Carrier-tier cannon exists yet |

Only Gnat is implemented so far (`main/data/modules/weapons_autocannons.lua`) — the
other three are reserved names for whenever an Escort/Frigate/Carrier-specific combat
cannon is actually added, not separate items yet.

**Mining cannon naming convention (decided)**: mining-type cannons get their own
class-sized naming scale instead of the insect one — mining/prospecting terminology.
Same "only Patrol-tier actually exists" caveat as the combat scale above:

| Ship class | Mining cannon name | Notes |
|---|---|---|
| Patrol | **Digger** (decided) | `mining_cannon_basic` — the starting-gift cannon, renamed from "Prospector" |
| Escort | **Miner** (reserved) | No Escort-tier cannon exists yet |
| Frigate | **Speculator** (reserved) | No Frigate-tier cannon exists yet |
| Carrier | **Prospector** (reserved) | No Carrier-tier cannon exists yet — reuses the original Patrol-tier name rather than retiring it |

Only Digger is implemented so far — same caveat as the combat scale: the other three
are reserved names, not separate items yet.

**Weapons belong to exactly one ship class each (decided)** — per direct
clarification: a cannon isn't a generic item that happens to carry a class-flavored
name, it's built *for* that class specifically. Gnat and Digger are both
**Patrol-only** (`ship_class = "Patrol"` in `weapons_autocannons.lua` — a **singular**
field holding a plain string, not the plural `ship_classes = { "Patrol" }` list it
briefly was, and no longer the earlier
`ship_classes = { "Patrol", "Escort", "Frigate", "Carrier" }` "fits anywhere for now"
placeholder before that). Hornet/Locust/Beetle and Miner/Speculator/Prospector will
each get their own entry (`ship_class = "Escort"`/`"Frigate"`/`"Carrier"`) once those
ships actually exist, rather than one shared cannon fitting every class. This
singular-string shape is
specific to auto cannons, where the "exactly one class" rule is decided — other
module types (e.g. the Asteroid Analyser, `computer_modules.lua`) still use the
plural `ship_classes` list from the general shared-fields schema (§3.1) above, since
they weren't part of this decision. **Now enforced in the Shop/Owned lists** — see
§2.8.5.

**New Computer module: Asteroid Analyser** (decided) — `main/data/modules/computer_modules.lua`, `behavior = "active"` (one-shot
trigger, matching the `activate_scanner` (P key) binding already reserved in §2.10 —
proposed, flag if it should be passive instead). It is a **normal, separately fitted
component like any other module — never integral/hardcoded to the ship**. It is
**not** part of the starting gift — available to purchase instead (demonstrates the
Shop tab below).

**Component fitting rule (decided)**: components can only be added to or removed
from a ship **while docked at an outpost** — never mid-flight. Currently trivially
true (the fitting UI only exists on the outpost screen; there's no flight-mode
screen yet to bypass it from), but this will need real **server-side enforcement**
once flight mode exists (§4) — a client can't be trusted to self-police this once
there's somewhere else to try it from.

**Ownership vs. installed (decided)** — `main/session.lua` tracks these separately:
- `M.owned` — every item key the player owns at all, installed or spare.
- `M.loadout` — the subset of owned items currently installed in a slot
  (`{ slot = "W1"/"W2"/"C1"/..., item = <owned item key> }`).
- New helper: `main/data/modules/catalog.lua` aggregates every module-type table
  (autocannons, computer modules, and future ones) into one `id → module` lookup, so
  callers don't need to know which specific table an item lives in.

**Outpost screen: top-down ship visual + drag-and-drop fitting (decided, revised
again and implemented)** — `main/outpost.gui` + `.gui_script`. Superseded the earlier
"abstract slot-box row" version with slot markers plotted directly on a top-down ship
silhouette, still modeled on the other local reference project's own in-flight
component panel (`~/Defold/SuperShips/main/hud.gui_script`'s `components_panel`: one
colored box per slot, green when filled, positioned via a stored per-slot local
coordinate — same idea, docked and interactive instead of a read-only flight-HUD
display):
- **Layout**: ship visual on the **left half** of the screen; **two always-visible
  lists on the right half** — **Shop** (purchasable, not yet owned) above **Owned**
  (spares not installed). No more tab-switching — both lists render simultaneously
  now, per direct instruction.
- **Ship visual**: a placeholder box standing in for a real top-down ship
  silhouette (no actual ship art exists yet, §2.1.2). One marker per fitting slot is
  plotted on it at that slot's own `{x, y}` **screen-pixel offset from the visual's
  center** — a new `slot_positions` field on the ship itself
  (`main/data/ships.lua`), directly modeled on the reference project's own
  `M.CHASSIS[x].slot_positions`.
- **Slot coordinates are random placeholders** (`W1 = {-120,180}`, `W2 = {140,-90}`,
  `C1 = {-60,-220}`) — explicitly temporary until real coordinates are given (§4).
  Verified they all land within the ship visual panel's own bounds so nothing draws
  off the silhouette.
- **Drag and drop** (unchanged mechanics from the previous version): drag a card from
  Shop/Owned onto a matching-type slot marker to install it (Shop items purchased
  first, still `(price TBD)`); drag an installed marker off to uninstall it back to
  Owned; mismatched-type or empty-space drops cancel with no change; dragging a
  slot's item onto another matching slot moves it there (displacing the target's
  occupant back to a spare, not a true two-way swap — see `main/session.lua`'s
  `M.install`).
- **`main/session.lua`**'s `M.purchase`/`M.install`/`M.uninstall` are unchanged by
  this revision — only the *visual* layer (where markers/cards render, and that both
  lists now show at once) changed, not the underlying fitting logic.
- Fitting slots (2 Weapon + 1 Computer) remain a **provisional placeholder** —
  real per-class slot counts are still an open TODO (§4).
- **Drag-over hover feedback (decided, implemented)**: while dragging, whichever
  slot marker the cursor is currently over is highlighted — a neon border around
  the slot, **cyan if the dragged item's type fits that slot, red (plus a big red
  "X" over the slot) if it doesn't**. The border is a same-shape box sized slightly
  larger than the marker and drawn behind it (dynamically created, like everything
  else on this screen), so only its edges peek out — a flat-color stand-in for a
  real glow effect, since there's no outline/nine-patch texture to draw a true one.
  Moving the cursor off a slot clears its highlight; ending the drag clears all of
  them regardless of outcome.
- **Verified — properly this time**: earlier revisions of this screen could only be
  checked with `bob.jar` (compiles) and a plain-data simulation of `session.lua`'s
  logic in isolation. For this feature a small test harness was built that stubs
  Defold's `gui`/`vmath`/`msg`/`hash` APIs with **real rectangle hit-testing** using
  the actual node positions/sizes from `main/outpost.gui`, then drives the real
  `init`/`on_message`/`on_input` functions from `main/outpost.gui_script` directly —
  the closest this project can get to an engine-level test without the engine
  itself. Confirmed against the exact colors used in the code (not just guessed
  labels): hovering a type-matching slot shows the cyan border with no X; hovering a
  mismatched slot shows the red border and the X; moving between slots clears the
  previous highlight; releasing on an invalid slot cancels with no purchase/install;
  releasing on a valid slot correctly purchases and installs. The one thing this
  still can't confirm is the actual on-screen visual *appearance* (whether the
  "glow" reads as intended, exact pixel layout) — that needs the real engine/editor.

**Outpost screen: Ships tab (decided, implemented)** — a second tab (**Fitting** |
**Ships**) added to the outpost screen, per direct instruction, for selecting a
different owned ship or purchasing a new one. The other local reference project has
its own version of this (`~/Defold/SuperShips/main/station.gui_script`'s ship-picker
— buttons grouped by class, colored locked/unlocked/selected, click-to-select) but it
wasn't ported directly, since our roster/economy differ enough that reusing it
wouldn't fit cleanly — built fresh here, same underlying idea (click a ship entry to
make it the active one):
- **Two always-visible lists**: **Ships For Sale** (not yet owned) and **Owned
  Ships** (click to select; the active one is tagged "(current)" and colored
  differently). Plain click-to-act, not drag-and-drop — there's no "slot" concept
  for ships to be dropped onto.
- Clicking a **For Sale** ship purchases it (still `(price TBD)`, free-grant for now,
  same caveat as module purchases) and immediately selects it as active.
- **`main/session.lua`** gained `owned_ships`/`active_ship_id` (replacing the old
  singular `ship_id` — same accessor name, `get_ship_id()`, so nothing else needed to
  change) plus `select_ship`/`purchase_ship`/`is_ship_owned`/`get_owned_ships`.
- Switching tabs clears and rebuilds whichever tab's dynamic content is showing
  (deletes the other tab's nodes rather than just hiding them) — switching back to
  Fitting after changing the active ship correctly rebuilds the slot markers for the
  *new* ship.
- Only **Patrol 1** exists in the roster so far (§2.1.2), so Ships For Sale is
  correctly empty and Owned Ships has exactly one entry — not a placeholder gap, the
  honest state of a one-ship roster.
- **Known simplification, flagged not solved**: `owned`/`loadout` (fitted modules)
  are a single global pool, not yet scoped per ship — irrelevant with one ship, but
  will need a real answer once a second one exists (§4).
- **Verified** with the same real-hit-testing harness approach as the hover feature
  above, extended to also drive tab-switching and ship selection/purchase: confirmed
  the Fitting tab's markers are cleared while on the Ships tab and rebuilt correctly
  on return; confirmed Owned Ships shows Patrol 1 tagged "(current)" and Ships For
  Sale correctly shows the empty-list placeholder; **injected a second ship directly
  into the loaded roster module** (proving the mechanism itself works, not just the
  empty-roster case) and confirmed clicking it purchases + selects it, and that
  returning to the Fitting tab afterward rebuilds against the newly active ship
  (correctly 0 markers, since the injected test ship has no `slot_positions`); then
  re-selected Patrol 1 and reconfirmed the original drag-to-uninstall behavior still
  works unchanged. One real bug was caught and fixed by this same test: `clear_card_list`
  crashed on the empty-list "(none)" placeholder card, which has no box node — only
  a label — and the cleanup function didn't guard against that.

**Patrol 1's first real 3D model, and a top-down plan extracted from it (decided,
implemented)** — per direct instruction: a rudimentary, wholly original 3D hull,
sized to "approximately a small patrol boat," plus a top-down plan derived directly
from that same geometry (not a separately hand-drawn image) to replace the outpost
screen's placeholder box.
- **The model**: `main/models/patrol_1/patrol_1.gltf` — 12m long, 3m beam, 2.8m tall
  including a small cabin superstructure (22 unique vertices, 36 triangles, flat
  shaded, no texture). Convention: **1 Defold unit = 1 meter** for this project's own
  models — a simpler, independent choice, *not* the reference project's own
  derived Viper-Mk-II-narration ratio (which is BSG-specific data, untouched, per
  §0). Generator script: `tools/build_patrol1_model.py` (needs Pillow) — re-run it
  after changing the dimensions rather than hand-editing the generated files.
- **Wired in**: `main/data/ships.lua`'s `faction_skins.accord/swarm.model` now point
  at `/main/models/patrol_1/patrol_1.model` (both factions share this one hull for
  now — distinct faction art is still open, §4) — replacing the old `nil`
  placeholder-cube state.
- **The top-down plan**: `main/images/patrol_1_topdown.png`, rendered by the same
  script from the identical vertex/face data (orthographic projection onto the
  hull's XZ plane) — genuinely an *extraction* from the model, not independent
  artwork. Wrapped in a new `main/images/patrol_1.atlas` and wired into
  `main/outpost.gui` as the `ship_visual` node's actual texture (was a flat placeholder
  color box; node resized 260×640 to match the image's real aspect ratio instead of
  stretching it).
- **Slot positions recalculated** (still placeholder pending real values, §4, but no
  longer floating off-model at random) to sit sensibly on the real hull: bow gun,
  stern gun, and the computer slot on the cabin footprint — derived from the same
  ~49.17 px/meter scale the render script used, so a ship-space `(x, z)` meter
  coordinate maps directly to a screen offset.
- **A preview instance** (`patrol_1_preview`, a fourth embedded object in
  `main/main.collection` with a bare `model` component) was added purely so
  `bob.jar` actually validates the mesh/model resource chain — nothing referenced
  the `.model` file otherwise, so it would have silently gone unbuilt. This is not a
  real flight-mode/3D scene (there's still no camera or render setup for one, §4) —
  just enough to prove the asset is genuinely valid.
- **Verified thoroughly**, more so than most earlier steps since this is the first
  actual binary/mesh asset in the project: (1) the top-down PNG was visually
  inspected and sent to the user before finalizing; (2) a full `bob.jar build`
  compiled the `.gltf` all the way through Defold's model pipeline
  (`.modelc`/`.meshsetc`/`.rigscenec`/`.skeletonc`/`.animationsetc` all generated —
  confirming the hand-authored glTF is a genuinely valid, importable asset, not just
  well-formed JSON); (3) the atlas/texture wiring in `outpost.gui` was confirmed to
  resolve (texture-pipeline processing was actually invoked, versus silently
  skipped when nothing referenced it the first time); (4) the recalculated slot
  positions were checked against the new 260×640 image bounds; (5) both existing
  outpost-screen test harnesses were re-run afterward with no regressions; (6) the
  generator script was re-run from its final `tools/` location to confirm it
  reproduces the checked-in files identically, so regenerating later (e.g. once real
  dimensions are given) is a one-command operation, not a manual one.

#### 2.8.1 Slot icons (decided — icon instead of item name text)

The outpost screen's ship-visual slot markers show an **icon** for the installed
module instead of its name as text — an installed module shows its own icon; an empty
slot shows a dim outline icon for that slot's type (weapon/computer/engine/hull), so
it's still clear what kind of module belongs there. The slot-id tag (e.g. "W1") is
still shown, small, at the top of the marker — that's a slot identifier, not an item
name, so it stays.

- **Assets**: `main/images/icons/*.png` + `main/images/icons.atlas`, generated by
  `tools/build_module_icons.py` — flat geometric shapes drawn with basic primitives
  (no BSG-derived iconography, §0), same "regenerate, don't hand-edit" convention as
  the ship model/top-down image (§2.1.2). Filled-module icons are bright/saturated per
  module; empty-slot icons are the same silhouette family rendered as a dim outline.
- **Weapon icons specifically show the weapon firing**, not just a static cannon
  shape, per direct instruction — the Auto Cannon (cannon-silhouette family) gets a
  bright radial spark/muzzle-flash burst.
- **Digger (mining cannon, named "Prospector" at the time this icon was designed —
  see the mining naming-scale table above for the later rename) redesigned again**,
  per a reference image the user
  liked (a hex-badge mining-cannon icon, style/composition only — recreated from
  scratch as flat vector shapes in this project's own palette, not traced from the
  source file, same §0 rule that applies to any borrowed art style): a hexagonal badge
  frame around a dark navy interior, with a golden sunburst of light rays converging
  on a bright core near the bottom, plus scattered sparkle glints — dropped the
  cannon-silhouette family entirely for this one icon, so it no longer visually
  matches the Auto Cannon's design language. Flagged, not yet resolved: whether the
  rest of the icon set (Auto Cannon, Asteroid Analyser, the four empty-slot outlines)
  should get the same hex-badge treatment for consistency, or whether this stays a
  one-off style just for Digger.
- **Data**: each `main/data/modules/*.lua` entry gets an `icon` field (the atlas
  region name). Ship-agnostic — the icon is a property of the *module*, not the ship
  or slot.
- **Verified**: both outpost-screen test harnesses re-run with no regressions (their
  stub `gui` table needed `set_texture`/`play_flipbook` no-ops added, matching the
  real API used to assign an atlas image to a runtime-created box node); a real
  `bob.jar build` confirmed the new atlas/textures block/`.gui_script` changes compile
  through Defold's actual texture pipeline, not just well-formed data.

#### 2.8.2 Module upgrades (decided — per-instance)

Direct question that surfaced this: if a player upgrades a weapon and then unloads it
at an outpost, does the upgrade survive for next time? **Decided: yes — upgrades are
per physical INSTANCE, not shared across every copy of a type.** Two owned Gnats can
be at different upgrade levels; uninstalling one never resets it.

This was a real data-model gap, not just a naming/cosmetic choice: `main/session.lua`
previously tracked `owned`/`loadout` as plain catalog item-TYPE keys (e.g.
`"auto_cannon_basic"`), so two owned copies of the same module were completely
indistinguishable — there was nowhere to attach a per-copy upgrade state at all.
Reworked to track unique **instances** instead:

- `M.owned` is now a list of `{ id, item_key, level }` — one entry per physical copy,
  `id` a simple incrementing integer (in-memory/per-guest-session only, never
  persisted or compared across sessions, same as the rest of §3.2's guest state).
- `M.loadout` is now a list of `{ slot, instance_id }` — installing/uninstalling only
  ever moves an instance's `loadout` membership; `owned` entries (and therefore
  `level`) are never touched by that, which is *why* the upgrade survives.
- `M.purchase(item_key)` now grants a brand-new instance and returns its id, instead
  of just adding a type key to a set — buying a second Gnat is now a real, separate,
  independently-upgradeable copy rather than a no-op (owning one used to make the Shop
  hide that type entirely, which no longer happens — the Shop now always lists every
  catalog item, since a second/third copy is a legitimate purchase now).
- `M.upgrade(instance_id)` increments that instance's `level` — no cost or stat effect
  wired up yet (see §4), just the mechanic itself.
- The outpost screen's ship-visual slot markers show a small upgrade-level badge
  (e.g. "+2") next to the module icon when an installed instance's level is above 0;
  Shop/Owned cards show the same suffix on an upgraded spare's name text.
- **Verified**: both outpost-screen test harnesses updated for the new instance-based
  API (`is_installed` now takes an instance id; a new `is_type_installed(item_key)`
  covers the old "is any copy of this type installed" query some assertions actually
  needed). Harness 1 extended with a new end-to-end case: purchase → upgrade twice →
  drag off (uninstall) → confirm `level` unchanged → drag the resulting Owned spare
  card back into the same slot → confirm it reinstalls at the same `level` — the exact
  scenario the original question asked about, passing. A real `bob.jar build` also
  confirmed the `.gui_script` changes still compile cleanly.

#### 2.8.3 Slot marker shape (decided — octagon, not rectangle)

Per direct instruction, the ship-visual slot markers (the `box`/`border` nodes,
§2.8.1/§2.8.2) are octagons, not plain rectangles — and, per a follow-up correction,
**regular** octagons (equal side lengths) specifically.

- Built from Defold's native `TYPE_PIE` node rather than a custom texture: an 8-vertex
  pie with a full 360° fill and no inner radius renders as a plain octagon inscribed in
  the node's bounding box — no new image asset needed, unlike the module icons
  (§2.8.1). `new_octagon_node(pos, size)` in `main/outpost.gui_script` wraps this
  (`gui.new_pie_node` + `set_perimeter_vertices(8)` + `set_outer_bounds(PIEBOUNDS_ELLIPSE)`
  + `set_fill_angle(360)` + `set_inner_radius(0)`).
- **Regular vs. irregular (fixed)**: the pie is inscribed in an *ellipse*, which only
  degenerates into a *circle* — and therefore into a genuinely regular octagon — when
  the bounding box is square. `MARKER_SIZE` was the old 110×60 landscape rectangle
  (left over from when the marker showed name text), which produced a stretched,
  irregular octagon. Changed to a square 74×74 (`BORDER_SIZE` derives from it, so it's
  square too) — large enough to comfortably fit the 48×48 module icon plus its corner
  labels.
- **Real bug, found and fixed after the user saw it rendering live**: the fill-angle
  setter is `gui.set_fill_angle`, confirmed against the official API docs
  (defold.com/ref/stable/gui) — NOT `gui.set_pie_fill_angle`, which is what got shipped
  initially. That earlier name came from cross-referencing bob.jar's own compiled
  `NodeDesc` protobuf class, where the underlying *design-time* .gui field genuinely is
  named `pie_fill_angle` — a reasonable-looking but wrong inference, since the
  scripting API drops the `pie_` prefix for this one setter (unlike
  `set_perimeter_vertices`/`set_outer_bounds`/`set_inner_radius`, which all do match
  their proto field names exactly). Calling a nonexistent `gui.set_pie_fill_angle`
  threw a Lua runtime error inside `new_octagon_node`, which aborted `build_markers()`
  partway through its very first iteration — only that one slot's `border` node had
  been created (positioned, given 8 perimeter vertices and ellipse bounds) before the
  crash, and its own `gui.set_enabled(border, false)` call — which runs in
  `build_markers`, *after* `new_octagon_node` returns, which it never did — never ran
  either. That left exactly one always-visible, default-white, oversized
  (`BORDER_SIZE`) octagon on screen, at whichever slot Lua's `pairs()` happened to
  visit first (empirically W1, the bow gun — plausibly why it read as "at the top"),
  and none of the other 9 slots' markers were ever built at all. This is a real limit
  of the test-harness approach used throughout this project (plan.md's verification
  notes elsewhere): the harness's stub `gui` table implements whatever function name a
  call site uses, so it can't catch a call to a Lua API function that doesn't actually
  exist in the real engine — only running the real thing caught this.
- Applied to both the marker's own background (`box`) and the drag-over hover
  highlight (`border`) — the two are the same visual unit, so both changed together;
  everything else on the screen (Shop/Owned/Ships cards, tabs, the Launch button) stays
  rectangular, since the instruction was specifically about the ship-visual markers.
- `gui.pick_node`'s hit test is bounding-box based regardless of node shape/type, so
  drag/drop hit-testing against a marker is unaffected by the corners now being
  visually cut off — clicking in a corner that's now "outside" the visible octagon
  still counts as a hit, same as before.
- **Verified**: both outpost-screen test harnesses' stubs corrected to
  `set_fill_angle` and re-run with no regressions; a real `bob.jar build` still
  compiles cleanly. The actual fix (both the crash and the regular-octagon shape)
  still needs confirming in a real engine, same as every other "does this render
  right" question in this project.

#### 2.8.4 Card lists scroll (decided — real bug found + fixed via testing)

Adding the three new mining cannons (§2.8) took the catalog to 6 entries — more than
the Shop panel's 220px height comfortably fits at the existing 58px row spacing (~4
rows). This wasn't just cosmetic: it caused a **real, confirmed interaction bug** —
the overflowing Shop rows positionally overlapped the Owned panel directly below it
(both panels share the same x), and since Shop cards are built before Owned cards in
the shared card list, a click in the overlap zone could hit the wrong (Shop) card
instead of the intended Owned one. `outpost_harness.lua`'s upgrade-persistence test
(drag a spare Owned card back into a slot) hit this exactly and failed, which is how
it was caught — not spotted visually.

**Decided fix: make the four card-list panels (Shop/Owned/Ships For Sale/Owned
Ships) scrollable**, rather than resizing panels or capping the list length.

- Each panel gets Defold's native stencil clipping
  (`gui.set_clipping_mode(panel, gui.CLIPPING_MODE_STENCIL)`, set once in `init()`
  since the panels are static/authored nodes) so rows scrolled past its edge are
  actually hidden, not just repositioned off-screen. Every card is reparented under
  its panel (`gui.set_parent(card, panel, true)`, `keep_scene_transform` so nothing
  visually jumps) purely so it inherits that clipping.
- Mouse wheel scrolls whichever panel is under the cursor — reuses the existing
  `zoom_in`/`zoom_out` input actions already bound to `MOUSE_WHEEL_UP`/`DOWN`
  (`input/game.input_binding`, originally meant for flight-mode camera zoom; the
  physical wheel is what matters here, not that binding's name). One row
  (`CARD_SPACING`, 58px) per wheel notch, clamped to `[0, max_scroll]` per list, where
  `max_scroll` is recomputed from that list's *current* row count every rebuild — the
  Owned/Ships lists shrink and grow as items get installed/purchased, so how far a
  list is even allowed to scroll changes right along with it.
- **`gui.pick_node` does NOT know about a panel's own clipping** — it's a plain
  bounding-box test — so clipping alone doesn't stop a scrolled-out-of-view card from
  still registering as a click at its own (invisible) raw position. Fixed with an
  extra gate, `panel_for_card(self, card)` (maps a card's `source` to its owning panel
  node) — every click handler now requires `hits(card.box, action) AND
  hits(panel_for_card(self, card), action)`, so a card only counts as clicked if the
  click also lands inside its own panel's visible bounds. This is also what actually
  fixed the original overlap bug (clipping alone wouldn't have).
- **Verified**: both test harnesses' stubs extended (`set_clipping_mode`,
  `set_clipping_visible`, `set_parent`, both `CLIPPING_MODE_*` constants) and pass
  with no regressions; `outpost_harness.lua` extended with a new scroll-specific
  case — scroll down repeatedly and confirm it clamps rather than growing forever,
  confirm the row scrolled out of the top is no longer hit-testable there even
  though its raw bounding box still contains that point, scroll back up and confirm
  it clamps at 0. A real `bob.jar build` still compiles cleanly. Not yet confirmed
  in a real engine (see §4 for the one known gap: no visual scroll-position
  indicator yet).

#### 2.8.5 Shop/Owned lists filtered by ship class (decided — enforced)

Per direct instruction: the outpost screen's Shop and Owned lists now only offer
weapons/components that actually fit the **active ship's class** — closing the gap
flagged since `ship_class`/`ship_classes` were first added as pure, unenforced data
(§2.8).

- `module_fits_class(module, ship_class)` (`main/outpost.gui_script`) handles both
  schemas currently in use: the singular `ship_class` string (auto cannons, "exactly
  one class") and the older plural `ship_classes` list (other module types, e.g. the
  Asteroid Analyser, "fits anywhere for now"). A module with neither field falls back
  to "fits anywhere" rather than being silently hidden for missing data.
- Applied to **both** `shop_keys()` (what's offered to buy) and
  `owned_spare_instances()` (what's offered to install from existing spares) — a
  player flying the Patrol-class Sardine/Hummingbird no longer sees Miner/
  Speculator/Prospector (Escort/Frigate/Carrier-only) in either list at all.
  Re-filters automatically on every rebuild, so switching to a different owned ship
  (once more than one exists) would immediately show that ship's own class of items
  instead.
- **Scope, and what this doesn't cover yet**: this filters what's *offered* to drag in
  the first place - it is not a drop-time block. There's no second ship class in the
  roster yet to actually test whether a mismatched item could still be forced onto a
  slot some other way (flagged in §4).
- **Verified**: a new `outpost_harness.lua` case confirms the Shop list for the
  Patrol-class starting ship includes Gnat/Digger/Asteroid Analyser and excludes
  Miner/Speculator/Prospector. This incidentally shrank the real Shop list back down
  to 3 items (below §2.8.4's scroll threshold), so that scroll test now injects a
  handful of fake Patrol-class catalog entries first (same "inject test data
  directly into the loaded module" pattern `outpost_harness2.lua` already used for a
  fake ship) purely to keep exercising scroll mechanics on a long-enough list - not
  testing anything about those fake entries themselves. Both harnesses pass; a real
  `bob.jar build` compiles cleanly.

#### 2.8.6 Confirmation dialog for purchases/swaps (decided)

Per direct instruction: **any kind of purchase or swap needs a confirmation
dialogue** — nothing spends anything or displaces something already in place
without the player explicitly confirming first.

- **New dialog nodes** in `main/outpost.gui`: `confirm_scrim` (full-screen darken),
  `confirm_panel`, `confirm_message`, `confirm_yes`/`confirm_yes_label`,
  `confirm_no`/`confirm_no_label` — authored once, all hidden by default
  (`gui.set_enabled(..., false)` in `init()`), shown/hidden together as a group by
  two new helpers in `main/outpost.gui_script`: `show_confirm(self, message,
  on_confirm)` and `hide_confirm(self)`. Sits above both tabs (not tied to either
  one), so it can interrupt either.
- **Modal**: `on_input`'s very first check (after `self.active`) is now `if
  self.confirm then` — while the dialog is open, *only* clicks on its own
  Confirm/Cancel buttons do anything; every other input (tabs, cards, slots,
  scrolling, drag) is swallowed until it resolves one way or the other.
- **What counts as "purchase or swap," scoped per direct instruction**:
  - Fitting tab: dragging a **Shop** card onto any slot (always at least a
    purchase) or dragging **anything** onto an **already-occupied** slot (a swap,
    regardless of source) opens the dialog. Dragging an **Owned** spare onto an
    **empty** slot, or dragging an installed item off to empty space (uninstall),
    do **not** — nothing is being bought or replaced, so those still apply
    immediately, same as before. Dropping an item back onto the exact slot it was
    just dragged off of doesn't count as a swap either (nothing would change).
  - Ships tab: buying a **For Sale** ship, or clicking a **different** owned ship
    to make it active (a "swap" of the active ship), both open the dialog. Clicking
    the *already*-active owned ship's own card is a no-op, not a swap - no dialog.
  - The message names the specific item/slot/ship involved (e.g. "Buy Gnat and
    install it in W2?" / "Swap Gnat into W2, replacing Digger?" / "Switch your
    active ship to Barracuda?"), built from whichever combination of
    purchase/swap actually applies.
- **Drag ends visually on release either way** (the ghost node disappears,
  `end_drag`) — the dialog is what decides whether the underlying
  purchase/install/swap/ship-switch actually happens; Cancel truly does nothing,
  Confirm runs the deferred action.
- **Verified**: both test harnesses updated - `outpost_harness.lua` gained cases for
  a Shop-into-empty-slot purchase (dialog opens, Cancel does nothing, Confirm buys
  and installs) and a purchase-into-an-occupied-slot swap (dialog opens, confirming
  displaces the old instance to a spare with its upgrade level intact and installs
  the new one at level 0); `outpost_harness2.lua` gained cases for a Ships-For-Sale
  purchase and for switching the active ship via its Owned Ships card (both through
  the dialog), plus confirming that re-clicking the already-active ship's card is a
  no-op. A real `bob.jar build` compiles cleanly.

#### 2.8.7 Selling ships and components (decided)

Per direct instruction: **"in the component section and the ship section there
needs to be an option to sell a ship or sell a component. You cannot sell all
ships."**

- **`session.lua`**: `M.sell(instance_id)` removes an owned module instance
  entirely — uninstalling it first if it happens to be fitted somewhere, rather than
  leaving a dangling loadout entry. `M.sell_ship(ship_id)` removes an owned ship,
  **refusing (no-op, returns false) if it would leave the player with zero ships** —
  the direct constraint. Selling the *active* ship (while others remain) is allowed;
  the active ship just falls back to whichever other owned ship is first in the
  list. Price/refund is TBD (§2.8/§4), same "not a real transaction yet" caveat as
  buying.
- **Scope (a deliberate narrowing)**: selling is offered from the **Owned** lists
  only — Owned (component spares) and Owned Ships — not from installed slot
  markers directly. To sell something currently fitted, uninstall it first (already
  a free, immediate drag), then sell it as a spare. This keeps the small octagon
  slot markers uncluttered rather than trying to fit a sell affordance onto them too.
- **UI**: sellable rows (`row.sellable`) get a small "Sell" button pinned to the
  right edge of their card, `main/outpost.gui_script`'s `build_card_list` — a
  separate node from the card's own box, so it doesn't collide with that card's
  existing click behavior (dragging a module card, clicking a ship card to select
  it); checked first in `on_input` so a click on the button doesn't also trigger a
  drag/select. The card's own label shifts left to make room for it.
- **"Cannot sell all ships" enforced twice**: the Owned Ships list only marks rows
  `sellable` at all once the player owns **more than one** ship (`#owned_ships > 1`)
  — a UI-level courtesy so the button doesn't even appear when it would just fail —
  on top of `session.sell_ship`'s own real refusal, which is what actually matters;
  the UI check is not a substitute for it.
- Selling goes through the same confirmation dialog as buying/swapping (§2.8.6) —
  "Sell Gnat?" / "Sell Barracuda?" — Cancel does nothing, Confirm actually removes it.
- **Verified**: `outpost_harness.lua` gained a case selling a component spare (via
  its Sell button + dialog) and confirming it's actually gone, not just uninstalled.
  `outpost_harness2.lua` gained cases confirming the Sell button is absent on the
  only owned ship, appears on both ships once a second is bought, actually removes
  a sold ship via the dialog, and confirming `session.sell_ship` itself refuses to
  sell the last remaining ship even if called directly (not just a UI-level guard).
  A real `bob.jar build` compiles cleanly.

### 2.9 Spawn / start location (decided — rule, with one open edge case)

- **Guest** (§1.1): always spawns at the **outpost of their chosen faction's home
  system** — Sol for Accord, Polaris for Swarm (§2.7). Consistent with guest state
  being ephemeral/re-chosen every load — there's no "last location" to return to.
- **Registered, authenticated player** (§3.2 silent-login flow): spawns at the
  system they **last successfully exited**, defined as either (a) quitting the game
  without having been defeated, or (b) docking/orbiting at that system's outpost
  before quitting. This last-exited system is persisted to the account (Nakama
  storage, §3.3) and restored automatically on the next silent login.
- **Defeat (decided)**: if a registered player's last session ended in defeat (ship
  destroyed) rather than a successful exit, they spawn **the same way a guest
  does** — at their faction's home-system outpost.
- **Brand new account (decided)**: a freshly registered player with no "last exited
  system" yet also spawns **the same way a guest does** — home-system outpost, for
  their very first spawn.
- **Outpost scope (resolved)**: every system has an outpost per faction by default,
  with the home-system-plus-nearest-6 exception denying the opposing faction one —
  see §2.7's new "Outposts" subsection for the full rule and implementation. A
  registered player's last-exited system always has an outpost for their own
  faction to dock at (the only systems where a faction has *no* outpost at all are
  the enemy's home-region exclusion zone, which that faction can't be in anyway for
  the innermost 3 — see §2.7).

### 2.10 Controls (decided — key bindings; flight mode itself not built yet)

**Implemented**: `input/game.input_binding` — ported from the other local reference
project's own control scheme (`~/Defold/SuperShips/input/game.input_binding`). A
generic space-flight-sim layout — mechanics/UX conventions, not creative expression,
so reuse is fine per §0.

| Action(s) | Input | What it does |
|---|---|---|
| `pitch_up`/`pitch_down` | W/S, Up/Down | Pitch the ship |
| `yaw_left`/`yaw_right` | A/D, Left/Right | Yaw the ship |
| `boost` | Space (held) | Boost speed — costs Hydrogen/sec (§2.6, §2.1.1) |
| `thrust_down` | Left Ctrl | Reverse/downward thrust |
| `throttle_up`/`throttle_down` | =/−, keypad +/− | Step throttle by 25% |
| `stop_throttle`/`full_throttle` | Q / E | Snap throttle to 0% / 100% |
| `shift` (held) | Shift | Modifier — fine-grained throttle via scroll wheel |
| `slide` | Alt | Activate slide thrusters (a fitted module, §2.8) |
| `activate_scanner` | P | Activate a mineral-analysis-type module (§2.8, ties to mining) |
| `track_target` | Right-click | Track/pivot toward the clicked target |
| `cycle_target`/`cancel_target` | Tab / C | Cycle or clear the current target |
| `target_nearest_enemy`/`target_nearest_missile` | X / Z | Auto-target |
| `match_speed` | T | One-shot: set throttle to match the target's current speed |
| `follow_friend` | Y | Toggle formation-following a same-faction target |
| `camera_cycle` | V | Cycle camera mode |
| `zoom_in`/`zoom_out` | Mouse wheel | Camera zoom |
| `toggle_guns` | G | Toggle all fitted weapons' enabled state at once |
| `weapon_1`–`weapon_9` | 1–9 | Per-slot weapon toggle (§2.8: weapons are toggle-type) |
| `fire_missiles` | F | Fire missiles/ordinance (§2.8) |
| `dock` | K | Dock at a nearby outpost (§2.7/§2.9), or cancel an in-progress FTL jump |
| `execute_jump` | J | Fire the currently-armed FTL jump preset (§2.1.1, §2.7) |
| `toggle_map` | N | Open/close the star system map (§2.7) |
| `touch` | Left-click | Already in use for the GUI screens (§3.2) |

- Every action above is a **binding only** — none of the actual flight-mode
  behavior (movement physics, targeting, weapon firing, docking, jump execution) is
  implemented yet. That's the existing "Build flight mode" TODO (§4); this just
  reserves the control scheme ahead of it so future flight-mode work has a
  consistent, already-decided key layout to build against.
- `esc`/`enter`/`backspace`/`text` are generic UI-focused bindings (menus/text
  input), not flight-specific.

## 3. Technical Architecture

- **Engine**: Defold (Lua scripting, component/GO-based).
- **Target**: HTML5 via Poki SDK (`game.project` dependency:
  `extension-poki-sdk`), plus `extension-websocket` and `heroiclabs/nakama-defold`
  (the Nakama client SDK, §3.3).
- **Display**: 1920×1080 base, HTML5 `stretch` scale mode, WASM streaming on.
- **Bootstrap**: `main/main.collection` → embeds the `start_screen` game object
  (§3.2's start screen, `main/start_screen.gui`) as its first on-screen content.
  `main/main.script` still exists but is currently unattached to anything — the
  original empty template scaffold, not yet repurposed.
- **Project layout** (current):
  ```
  Galaxy/
    game.project          # engine + Poki SDK + Nakama client SDK config
    main/
      main.collection      # embeds start_screen + faction_select + outpost + patrol_1_preview
      main.script          # unused so far
      start_screen.gui         # §3.2 boot screen
      start_screen.gui_script
      faction_select.gui         # §1.1 guest faction-choice screen
      faction_select.gui_script
      outpost.gui                # §2.8/§2.9 fitting + Ships tabs
      outpost.gui_script
      session.lua           # §3.2's in-memory guest session state
      data/                # §3.1's data tables (star_systems.lua, ships.lua, modules/)
      models/patrol_1/     # §2.9's real 3D hull (patrol_1.gltf + .model)
      images/               # patrol_1.atlas + the extracted top-down PNG
    input/
      game.input_binding    # touch/mouse-click binding (see note below)
    nakama-server/          # §3.3's self-hosted Nakama + Postgres setup
    tools/
      build_patrol1_model.py   # regenerates the hull model + top-down plan (§2.9)
    .internal/               # Defold build cache
  ```
- Shared script state is enabled (`[script] shared_state = 1`).
- No fullscreen button / "made with Defold" badge shown (Poki requirement compliance).
- **Input-binding note**: `game.project` deliberately has **no** explicit `[input]
  game_binding = ...` line. Defold's own documented default already resolves it to
  `/input/game.input_bindingc` (the compiled form of `input/game.input_binding`,
  which exists) — adding the line explicitly isn't needed, and doing so triggered
  what looks like a genuine bug in the Bob 1.13.1 command-line build tool (a resource
  path validator that consistently truncated the path by one character and failed
  the build). Confirmed working without it: a full `bob.jar build` compiled every
  resource cleanly, including `input/game.input_bindingc`, `main/main.collectionc`,
  and `main/start_screen.guic`/`.gui_scriptc`.

### 3.1 Data conventions
- **Every distinct data table gets its own file** — one file per table, not one big
  file holding many tables. Applies to any tabular game data as it's built out: ship
  class stats, module/fitting stats, faction definitions, resource/economy costs, rank
  progression curves, etc.
- Rationale: keeps each table easy to open, scan, and diff in isolation as the game
  grows, rather than hunting through a monolithic data file.
- Suggested layout once data work starts (Lua modules returning tables, Defold's usual
  pattern):
  ```
  main/data/
    ship_classes.lua
    ships.lua              -- ✅ implemented, §2.1.2 (first entry: Patrol 1)
    factions.lua
    resources.lua
    currencies.lua
    ranks.lua
    star_systems.lua       -- ✅ implemented, §2.7
    modules/
      weapons_autocannons.lua
      weapons_launchers.lua
      hull_modules.lua
      engine_modules.lua
      computer_modules.lua
      ordinance.lua
  ```
  (Everything else in this layout is still just a plan — `star_systems.lua` and
  `ships.lua` are the two actually written so far.)

### 3.2 Authentication & session (decided — flow and mechanism)

**Implemented (partial)**: `main/start_screen.gui` + `main/start_screen.gui_script`,
wired into `main/main.collection` — the screen for boot-flow step 3 below (no valid
token). Pressing **Play as Guest** now hands off to `main/faction_select.gui` (a
second embedded instance in the same collection), which offers **The Accord** or
**The Swarm** and stores the pick in the new `main/session.lua` (in-memory only, per
the guest-state design above). Register/Log In still just shows a placeholder
status. Built and verified with Defold's command-line build tool (`bob.jar`): every
file compiles cleanly, no errors. Not yet implemented: the step 1/2 silent-login
check, or what happens after a faction is actually picked (spawning at the
home-system outpost, §2.9) — see §4.

**Two ways to play**: Guest, or Registered Account (register or log in) — same
distinction as §1.1, detailed here as an implementation flow.

**Silent re-entry for returning registered users**: once a user has registered/logged
in, issue a persisted **bearer token** (a signed session token, e.g. JWT), stored
client-side (browser storage). On future visits, a valid stored token authenticates
the user automatically — they go straight into the game with no login screen and no
faction prompt (their faction is already permanently set, §1.1).

**Boot flow**:
1. Game loads → check for a stored, still-valid auth token.
2. **Valid token found** (returning registered user) → skip straight into the game;
   account's permanent faction loads automatically.
3. **No valid token** (first-time visitor, guest, logged-out, or expired session) →
   show **one combined start screen** with two choices: **Play as Guest** or
   **Register / Log In**. Guest and register/login share this same first screen
   rather than being separate entry points.
   - **Play as Guest** → faction-choice prompt shown immediately, every time (§1.1).
   - **Register** (new account) → account creation, then the one-time **permanent**
     faction-choice prompt (§1.1), then issue + store the auth token for future
     silent logins.
   - **Log In** (existing account, new device or cleared storage) → credential
     check, then straight into the game with the account's already-locked faction —
     no faction prompt, since it was set at registration.

Token expiry/refresh handling and exact client storage (localStorage vs. cookie) are
still TBD — see §4.

**Guest identity/session state (decided)**: in-memory only, client-side — a plain
Lua table in the running game instance (using the `shared_state = 1` already set in
`game.project`), holding the guest's chosen faction and session data for that
page-load's lifetime only. Nothing is written to localStorage/IndexedDB or any other
persistent client storage for guests — that's reserved for registered-account tokens
above. This is what makes the "reprompt every load" rule in §1.1 automatically true:
there's nothing to persist, so there's nothing to leak between loads. Server-side
counterpart is in §3.3's guest caveat (an ephemeral Nakama session, never a stored
account).

### 3.3 Backend: Nakama (decided)

**Nakama** (Heroic Labs' open-source game server) is the backend, used underneath the
Poki SDK client wrapper — the two operate at different layers and don't conflict:
Poki SDK stays a purely client-side ad/session-analytics wrapper (it has no concept of
accounts), while Nakama runs actual game state.

- **Why Nakama fits this project**: Defold has an **official Nakama client SDK** —
  the most natively-supported backend option available for this engine, not a
  third-party bolt-on.
- **Auth**: Nakama's built-in authentication (device ID / email+password / custom,
  with session + refresh tokens) directly implements the bearer-token/silent-login
  flow already decided in §3.2 — no custom auth server needed.
- **Storage**: Nakama's storage engine covers saved game history/achievements
  (§1, registered-account requirement).
- **Wallet**: Nakama's built-in wallet (balance + transaction ledger) is a natural
  fit for the two-currency economy — **Scrip** and **Valor** (§2.6) — as separate
  wallet balances on the same account.
- **Groups**: maps onto player-formed "wings"/"fleets" (§2.4).
- **Leaderboards**: maps onto rank/PvP progression (§2.2).
- **Authoritative server-side match modules**: important given this game has a real
  economy and competitive PvP — module power/cooldown/wear and combat resolution
  (§2.8) should run authoritatively on the Nakama server, not be trusted from the
  client, to keep the economy and PvP fair.
- **Caveat — guest mode vs. Nakama's usual device-auth pattern**: Nakama's typical
  "guest" flow is device-ID auto-authentication, which quietly creates a persistent
  per-device account server-side. That conflicts with the decided guest rule (no
  persistence, faction re-prompted every load, §1.1) — so **guest mode should not use
  Nakama's device-auth path**. Only Register/Log In creates a real, stored Nakama
  account. **Decided (§3.2)**: guests still get a Nakama session for the current
  visit only — needed since the game world is live/shared (other players, contested
  nodes, shared mining) — but it's a throwaway session, never written to Nakama's
  persistent user/device tables and never looked up again after disconnect.
- **Caveat — infrastructure**: Nakama is self-hosted (or via Heroic Labs Cloud) —
  this adds real server hosting/ops/cost to a project that would otherwise be a
  static Poki-hosted HTML5 build. This is the concrete answer to the earlier open
  "does this project need its own backend" question — yes, once persistent accounts,
  a real economy, and PvP fairness are all requirements, a backend (Nakama) is
  effectively required regardless of Poki hosting.
- **New consideration**: real accounts (email/password) put real user data in scope
  — needs a privacy policy/ToS and GDPR-type handling, which wasn't relevant when the
  design was client-only.

**Implemented — server setup (decided: self-hosted via Docker Compose)**, mirroring
the other local reference project's own Nakama setup (`~/Defold/SuperShips/nakama-server/`)
with one deliberate deviation:
- `nakama-server/docker-compose.yml` — Postgres 16.8-alpine + Nakama 3.37.0
  (same pinned versions as the reference setup), Postgres never published to the
  host (`expose:` only), Nakama's ports (7349/7350/7351) published, healthchecks on
  both, a `migrate up` step before Nakama actually starts.
- `nakama-server/.env.example` — copy to `.env` (gitignored) to override
  `POSTGRES_PASSWORD` for any real deployment; defaults to `localdb` for local dev.
- `nakama-server/modules/` — empty for now (just a README pointing at the reference
  project's background-match/NPC-population pattern as a model for later — not
  ported directly, since that logic is specific to its own roster).
- **Deviation from the reference setup**: the reference project also wires up Steam
  auth (`STEAM_PUBLISHER_KEY`/`STEAM_APP_ID` env vars, `--social.steam.*` flags) —
  **omitted here**, since Galaxy targets Poki/HTML5 (§3, `game.project`), not Steam.
  Flag if this is wrong and a Steam release is actually planned too.
- **Client dependencies added** to `game.project`: `heroiclabs/nakama-defold` (the
  official Nakama client SDK) and `defold/extension-websocket` (Nakama's client
  needs it), matching the reference project's own dependency list minus its
  Steam extension.
- This resolves part of the earlier "self-hosted vs. Heroic Labs Cloud" question
  (§4) — self-hosted via Docker Compose is now the concrete setup, matching the
  reference project, though a managed Cloud option could still replace this later.

### 3.4 HTML5 bundling — defensive fix for offline/sandboxed testing

**Not a bug affecting normal builds** — confirmed the game builds and runs fine
end-to-end in a normal environment with real internet access. The item below only ever
triggers when `game-cdn.poki.com` can't be reached at all (a sandboxed/offline test
environment, not normal local development), so it's a defensive patch, not a fix for
something broken.

`extension-poki-sdk`'s own bundled `manifests/web/engine_template.html` gates
`Module.runApp("canvas")` behind **both** the WASM runtime being ready **and** the Poki
SDK's `init()` promise resolving, and that promise only ever resolves via the
`game-cdn.poki.com/scripts/v2/poki-sdk.js` script's `onload` handler — there's no
`onerror` fallback. In the one situation where that request can never complete (no
network route to the CDN at all), the engine loads everything successfully but sits
frozen forever on a black canvas with no console error. Found while testing from a
sandboxed tool environment with no real internet access; does not reproduce in a normal
browser with normal internet access, where `onload` fires within milliseconds as
expected.

**Fix applied**: added a matching `onerror="poki_sdk_unreachable()"` handler to the same
`<script>` tag, plus a small `poki_sdk_unreachable()` function that flips the same
`isPokiSDKInited` flag `poki_sdk_loaded()` would have and calls `runFunc()`. Harmless —
in the normal/production path `onload` still wins first, so this never fires; it only
helps the specific case of testing somewhere with no route to the CDN at all.

**Where the fix lives**: applied directly to the **cached dependency zip** under
`.internal/lib/` (not a tracked project source file), via
`tools/patch_poki_sdk_local_dev.py` — idempotent, safe to re-run, prints "already
patched" if there's nothing to do. Re-run it after any `bob.jar resolve` that
re-fetches `extension-poki-sdk`, or after deleting `.internal/`, if this ever matters
again (e.g. building somewhere without internet access):
```
python3 tools/patch_poki_sdk_local_dev.py
```
A project-level app-manifest override (this repo's own `ext.manifest` +
`manifests/web/engine_template.html`, the same mechanism extension-poki-sdk itself
uses) would make this a tracked source file instead of a build-cache edit, but Bob
didn't pick that up when tried — not worth chasing further given this isn't a real
day-to-day issue.

## 4. Open Questions / TODO
- [ ] Give the four card-list panels a scroll-position indicator (e.g. a simple
      scrollbar thumb or "3/6" counter) — §2.8.4's new scrolling has no visual cue
      yet that a list has more rows below/above the visible area, only the mouse
      wheel actually working once you try it.
- [x] ~~Enforce `ship_class` at fitting time~~ — resolved (§2.8.5): the Shop and
      Owned lists now only offer weapons/components that fit the active ship's
      class. Still open: this filters what's *offered* to drag, not a drag-drop-time
      block — there's no second ship class in the roster yet to prove a mismatched
      item can't be forced onto a slot some other way (e.g. dragging an
      already-installed item from one ship's loadout after switching to a
      differently-classed ship, once that's possible at all).
- [ ] Design real upgrade cost/effect: `session.upgrade(instance_id)` (§2.8.2) exists
      and increments an instance's `level`, but has no cost (Scrip? materials?) wired
      up yet, and no stat effect defined for what a level actually changes (§2.8's
      shared module-stat schema) — both still undesigned, per §0/§4's "don't invent
      unconfirmed numbers" rule. There's also no in-game UI trigger for it yet (no
      "Upgrade" button on the outpost screen) — only reachable by calling
      `session.upgrade` directly, which is how the test harness demonstrates it.
- [x] ~~Finalize faction names~~ — resolved: **The Accord** and **The Swarm** locked
      in, quick online sanity check done (§1).
- [ ] Decide art direction (must be built or licensed independently — no BSG-derived
      hull silhouettes or UI chrome).
- [ ] Define resource + currency names.
- [x] ~~Map BSGO's fitting-slot counts per ship tier to original tuning values~~ —
      first ship done: Patrol 1 started from the reference game's own Viper Mk II
      **standard** tier slot counts, then had H bumped 1→2 per direct instruction —
      now **W=3, C=2, E=3, H=2** (10 slots total, §2.1.2/§2.8) — plain integers, a
      balancing fact not creative expression. Escort 1 now exists (§2.1.2) but its
      slot counts are deliberately still empty (no source number given, unlike
      Patrol 1's Viper Mk II tier) — Frigate/Carrier still have no ships at all yet.
- [ ] Decide session/match structure: persistent MMO-style (like BSGO) vs. matchmade
      sessions (more typical for a Poki HTML5 title — likely a better fit given Poki's
      short-session audience).
- [ ] Expand the backstory (§1) into a full original lore doc — creation-order
      skeleton is decided (Accord created Robots → augmented some into the Swarm →
      abandoned the un-augmented rest), but needs prose/detail.
- [ ] Write the story of why/how the Swarm broke from Accord control to become an
      independent, player-selectable faction — flagged as an open thread in §1.
- [x] ~~Decide where guest identity/session state technically lives~~ — resolved:
      in-memory Lua state client-side + an ephemeral, never-stored Nakama session
      server-side (§3.2, §3.3).
- [ ] Decide UI/flow placement for the guest faction-choice screen in the boot sequence
      (before or after `main/main.collection` loads).
- [ ] Decide whether Robots need their own distinct ship/unit designs, or reuse a
      subset of Accord/Swarm ship tiers for PvE encounters.
- [x] ~~Research BSGO's actual Veil Sector map topology~~ — resolved: sourced from a
      prior local project's own reconstruction (`~/Defold/SuperShips/main/sector_map.lua`),
      58 systems with positions/sizes/home-system flags. Implemented in
      `main/data/star_systems.lua` (§2.7).
- [x] ~~Assign real star/system names to every map node~~ — resolved: all 58 systems
      named, no duplicates, none of BSGO's own names reused. Home systems: **Sol**
      (Accord), **Polaris** (Swarm). See `main/data/star_systems.lua` (§2.7).
- [x] ~~Real per-system connectivity beyond distance/FTL-range reachability~~ —
      resolved: no named lanes/chokepoints. **Pure straight-line distance** between
      systems, checked against **the current ship's own FTL range** (§2.1.1's FTL
      Range stat), is the final reachability model — exactly what
      `M.distance`/`M.reachable_from`/`M.in_ftl_range` in `star_systems.lua` already
      implement (§2.7). No further work needed here.
- [ ] Tune the 58 systems' `threat` values for real (currently a carried-over
      reference, same caveat as other researched numbers, §0/§4).
- [x] ~~Clarify whether Scrip is general-purpose or Water-scoped~~ — resolved:
      Scrip is earned from combat/mining/dailies/selling Water/real money — a single
      general-purpose currency (Marque abandoned and folded into it); see §2.6.
- [ ] Confirm **Valor** as the final name for the PvP-only currency (proposed,
      pending confirmation like Scrip was).
- [ ] Confirm final yield/conversion rates across Hydrogen/Iron/Water →
      Scrip/Valor and crafting material, using the researched BSGO structure
      in §2.6 as a starting point only (not copied 1:1).
- [ ] Define which specific purchases require Hydrogen alone vs. Hydrogen+Scrip
      together, now that Hydrogen is a direct-spend resource rather than a
      Scrip-source (§2.6).
- [x] ~~Define the repair mechanic for module wear~~ — resolved: **Iron** repairs
      hull/module wear (§2.6, §2.8). Still open: where repairing is allowed (station/
      home system only vs. mid-mission).
- [x] ~~Confirm whether Hydrogen keeps the ship-fuel mechanic~~ — resolved: yes,
      confirmed by the universal ship-stat baseline (§2.1.1) — FTL Cost and Boost
      Cost are both denominated in Hydrogen.
- [x] ~~Fill in per-class stat blocks~~ — resolved: not needed. The §2.1.1 baseline
      applies to all four classes equally; classes are differentiated by fitting
      capacity/slots (§2.8) and role, not by inherent hull/engine/FTL/computer stats.
- [ ] Decide whether destroying an enemy Carrier or damaging/routing a siege
      objective (§2.5) grants a Valor bonus exactly as researched, and tune the
      PvP-kill Valor amount vs. the Valor-bonus-for-siege-objectives ratio.
- [x] ~~Decide whether Robots pay out Scrip on defeat~~ — resolved for now: no.
      Scrip has exactly two sources (selling mined Water, real-money purchase);
      Robot kills, combat rewards, and daily assignments are not currently Scrip
      sources (§2.6).
- [x] ~~Design a pay-to-win mitigation for Scrip~~ — moot: the no-pay-to-win stance
      itself is abandoned (§2.6). Real-money Scrip purchases can buy fitting/upgrades
      without restriction.
- [x] ~~Define fitting-slot counts for Patrol 1~~ — resolved: W=3, C=2, E=3, H=2
      (started from Viper Mk II standard tier, H then bumped 1→2, see above).
      Escort 1 exists now too, but with slot counts deliberately left undefined
      (§2.1.2) — Frigate/Carrier still fully open, no ships exist for those classes.
- [ ] Define concrete power-pool mechanics: capacity per ship class, regen rate, and
      cooldown durations per module type/subtype.
- [ ] Populate actual module entries (specific auto cannons, launchers, hull/engine/
      computer modules) once stats are designed — no concrete items exist yet, only
      the type taxonomy and behavior rules.
- [ ] Define the variety of **ordinance** types and their specs (damage, blast
      radius, special effects, etc.) across cannon ammo, missiles, and torpedoes —
      mentioned as "to be stated later" by design, nothing concrete yet beyond the
      shared-table classification scheme in §2.8.
- [ ] Balance the Mining Cannon vs. Ordinance Cannon tradeoff (mining yield rate vs.
      combat ineffectiveness) once resource yield numbers (§2.6) are defined.
- [x] ~~Decide Nakama hosting~~ — resolved for now: self-hosted via Docker Compose
      (`nakama-server/`, §3.3), matching the reference project's setup. A managed
      Cloud option could still replace this later if the ops cost becomes an issue.
- [ ] Confirm the Steam-auth omission (§3.3) is correct — deliberately dropped since
      Galaxy targets Poki/HTML5, not Steam, unlike the reference project.
- [ ] Write the actual custom Nakama runtime modules (`nakama-server/modules/` is
      currently empty) — combat resolution, module wear enforcement, siege/economy
      state, opposing-ship population cap (§2.7/§3.3), and a Robots-population
      background match analogous to the reference project's own NPC scheduler.
- [ ] Decide token/session storage mechanism on the client (localStorage vs. cookie
      vs. IndexedDB) and expiry/refresh behavior for the silent-login flow (§3.2).
- [x] ~~Design the actual combined guest/register/login start screen~~ — first
      version **implemented**: `main/start_screen.gui` + `.gui_script`, wired into
      `main/main.collection` as the game's actual boot screen. Two buttons ("Play as
      Guest" / "Register / Log In") with placeholder status text on click — no real
      Nakama calls yet (both paths just log/display their intended next step). Still
      open: what happens if a stored session has expired vs. is simply absent (§3.2
      step 1/2's silent-login check isn't built yet — this screen only covers the
      "no valid token" case).
- [ ] Build the silent-login check itself (§3.2 steps 1–2: look for a stored token
      before ever showing `start_screen.gui`).
- [x] ~~Build the Guest faction-choice screen~~ — **implemented**:
      `main/faction_select.gui` + `.gui_script`, a second embedded instance in
      `main/main.collection`. Pressing "Play as Guest" on the start screen disables
      it and enables this one; picking **The Accord** or **The Swarm** hands off to
      the outpost screen below. Register/Log In still leads nowhere real (§3.2/§3.3
      auth not wired up).
- [x] ~~Build the home-system outpost screen~~ — **implemented and since expanded**
      (§2.8): `main/outpost.gui` + `.gui_script`, a third embedded instance. On
      faction pick, a new character is gifted the **Patrol 1** ship (§2.1.2) fitted
      with one **Auto Cannon** (Ordinance-type) and one **Mining Cannon**
      ("Digger") — hull/engine/computer slots stay empty. The screen shows the
      home system name (Sol/Polaris, §2.7), the faction + ship label, and a 3-tab
      fitting view (**Installed** / **Owned** / **Shop**, §2.8), with a **Launch**
      button. Launch doesn't do anything yet — flight mode isn't built.
      - Verified: clean `bob.jar build` (all files compile) plus runtime data-flow
        tests in plain `lua` (faction → home system name → ship class → all three
        tab lists all resolve correctly end-to-end).
- [ ] Implement the guest Nakama session as genuinely ephemeral/throwaway (per §3.3)
      — verify it never gets written to a persistent user/device table, only Nakama's
      normal device-auth path should ever do that.
- [ ] Write a privacy policy/ToS covering registered-account data (email/password,
      saved history/achievements) now that a real backend with real user data exists.
- [ ] Design the specific server-authoritative Nakama match modules needed for combat
      resolution, module power/cooldown/wear enforcement, and siege/economy state
      (§3.3), rather than trusting client-reported outcomes.
- [ ] Clarify whether non-nuclear torpedoes exist alongside missiles, or if
      "torpedo" currently means "nuclear torpedo" only; and whether the
      general-purpose launcher can fire both missiles and any non-nuclear torpedoes.
- [ ] Define the Nuclear Launcher / Nuclear Torpedo as their own concrete module +
      ordinance entries (stats, fitting restrictions, whether they need their own
      ship-class gating beyond the general launcher/missile fitting rules).
- [x] ~~Pick Patrol 1's actual per-faction display names~~ — resolved (proposed):
      **Sardine** (Accord), **Hummingbird** (Swarm), per the new fish/bird naming
      convention (§2.1.2). Set in `main/data/ships.lua`; flag if you want different
      species.
- [x] ~~Assign fish/bird species names for the Escort class~~ — resolved (proposed):
      **Barracuda** (Accord), **Falcon** (Swarm), per direct instruction (§2.1.2).
- [ ] Assign fish/bird species names for the Frigate/Carrier classes once those ships
      actually exist in the roster (§2.1.2) — only illustrative ideas noted so far
      (e.g. Whale Shark/Albatross for Carrier, Frigatebird for Frigate).
- [x] ~~Build Patrol 1's 3D model~~ — resolved (rudimentary): a shared, original
      small-patrol-boat-scale hull now exists (§2.9) — `main/models/patrol_1/`,
      generated by `tools/build_patrol1_model.py`. Not per-faction yet (both share
      it) — see the new TODO below.
- [ ] Give Patrol 1 **distinct** per-faction 3D models (currently both factions
      share the same rudimentary hull, §2.9) and a real weapon GUI/icon set — must
      stay original, no BSG-derived hull silhouettes or UI chrome (§0).
- [ ] Get real hull dimensions/outline for Patrol 1 (currently: 12m length, 3m beam,
      a simple 7-point deck outline — reasonable but not a considered design, §2.9) —
      re-run `tools/build_patrol1_model.py` after editing its constants.
- [ ] Populate the rest of the ship roster (§2.1.2) — Patrol 1 and Escort 1 exist;
      Frigate/Carrier classes still have no individual ships defined yet.
- [x] ~~Decide the starting Auto Cannon's `cannon_type`~~ — resolved: one
      Ordinance-type Auto Cannon + one Mining Cannon ("Digger"), not two of the
      same (§2.8).
- [x] ~~Confirm "Prospector" as the Mining Cannon's name~~ — resolved, then
      superseded: the Patrol-tier mining cannon is now **"Digger"**; "Prospector" was
      reused for the (not yet built) Carrier-tier mining cannon instead — see the
      mining naming-scale table above (§2.8).
- [x] ~~Name the basic combat Auto Cannon~~ — resolved: **Gnat** (Patrol-tier), part of
      a new insect-naming convention for combat auto cannons sized by ship class
      (Escort/Frigate/Carrier tiers reserved as Hornet/Locust/Beetle, §2.8).
- [ ] Confirm the Asteroid Analyser's `behavior = "active"` (proposed to match the
      `activate_scanner` key binding, §2.8/§2.10) — flag if it should be passive.
- [x] ~~Wire up actual install/purchase interaction on the outpost screen~~ —
      resolved: drag-and-drop from Owned/Shop onto a matching slot (§2.8), modeled
      on the reference project's in-flight component panel.
- [ ] Define real pricing for Shop items (currently `(price TBD)` / free-grant
      placeholder, §2.8).
- [ ] Design server-side enforcement of "components can only be added/removed at an
      outpost" (§2.8) once flight mode exists — currently trivially true since
      there's nowhere else to try it from yet.
- [x] ~~Decide real per-class fitting-slot counts~~ — resolved for Patrol 1: W=3,
      C=2, E=3, H=2 (started from Viper Mk II standard tier, H then bumped 1→2, see
      above) — no longer the earlier 2-Weapon/1-Computer drag-and-drop demo
      placeholder.
- [ ] Decide whether moving an installed item between two slots should be a true
      two-way swap instead of the current "displace to spare" behavior
      (`main/session.lua`'s `M.install`).
- [ ] Get real slot coordinates for Patrol 1's `slot_positions`
      (`main/data/ships.lua`) — recalculated to sit on the real hull (bow gun, stern
      gun, cabin-mounted computer, §2.9) but still placeholder positioning, not a
      considered design; explicitly waiting on specific values.
- [x] ~~Replace the outpost screen's placeholder ship-visual box with an actual
      top-down ship silhouette~~ — resolved: `main/images/patrol_1_topdown.png`,
      extracted directly from the new 3D model, wired in as the `ship_visual`
      node's texture (§2.9). Still rudimentary/placeholder-quality art, not final.
- [ ] Decide whether fitted modules (`owned`/`loadout`, §2.8) should be scoped
      per-ship once a second ship exists, instead of the current single global pool
      (§2.9's Ships tab) — deferred, not solved, since there's nothing to test it
      against yet.
- [ ] Define real ship pricing for the Ships tab's For Sale list (currently
      `(price TBD)` / free-grant placeholder, same as module Shop pricing, §2.9).
- [ ] Build flight mode — the outpost screen's Launch button currently just logs
      that it was pressed; there's no actual space-flight scene to enter yet. The
      control scheme it should read from is already decided/implemented
      (`input/game.input_binding`, §2.10) — flight mode needs the actual
      movement/targeting/weapon/docking/jump handling logic, none of which exists.
- [ ] Decide what else besides the Asteroid Analyser fills out hull/engine/computer
      module slots — Computer now has one defined (purchasable, not gifted, §2.8);
      Hull and Engine still have zero concrete entries.
- [x] ~~Confirm the spawn-on-defeat fallback~~ — resolved: same as guest,
      home-system outpost (§2.9).
- [x] ~~Confirm the brand-new-account first-spawn fallback~~ — resolved: same as
      guest, home-system outpost (§2.9).
- [x] ~~Decide outpost scope~~ — resolved: every system has an outpost per faction
      by default, with a home-region exception. Implemented in
      `main/data/star_systems.lua` (§2.7).
- [ ] Design outpost combat: how outposts can be attacked and what defense systems
      they have — explicitly deferred by the user, not designed yet (§2.7).
- [ ] Tune the outpost corner-placement inset (`M.OUTPOST_CORNER_FRACTION = 0.8`,
      §2.7) — currently a placeholder, not real level-design placement.
- [ ] Confirm the opposing-ship population cap value (`M.OPPOSING_SHIP_CAP = 50`,
      §2.7) — explicitly called out as TBC, needs real balancing.
- [ ] Design server-side enforcement of the population cap (counting live ships per
      system in real time) as one of the Nakama match modules (§3.3).
- [ ] Decide the spawn concept for a faction entering a system where it has no
      outpost (the population-capped zone, §2.7) — `M.spawn_points` only covers the
      normal has-an-outpost case.

---

*Maintenance note: update this file as design decisions are made. Keep the IP section at
the top authoritative — if any later section conflicts with it, the IP section wins.*
