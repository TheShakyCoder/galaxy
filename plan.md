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

### Acknowledged §0 exception — reference weapon designations (per direct instruction)

Per direct instruction, the **combat weapons** (§2.8) now use *Battlestar Galactica
Online's* own published weapon names **verbatim** — the Colonial/Cylon pairings from
`bsgo.fandom.com/wiki/Weapons` (e.g. `MEC-A6 "Fang"` / `Type A "Aggressor"`, `MEC-A8
"Tornado"` / `Type A1 "Lasher"`, `HD-70 "Lightning"` / `Type B "Bereaver"`). This
**knowingly departs** from the boundary above: the designation codes (`MEC-A6`, `Type
A`, `HD-70`, …) are BSGO's specific item names, not generic genre terms.

It is recorded here as a **flagged, explicit exception** — the same "explicitly
acknowledged, not silent" treatment the SuperShips-sourced ship models get (§2.1.2) —
not a blanket waiver. Faction names remain **The Accord** / **The Swarm**, every other
§0 rule still stands, and where the reference has no name (its Line/Frigate page is
empty) the earlier original names are kept instead of invented BSGO ones.

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
  from `ship_classes.lua` — with three deliberate overrides: **Hull Points 600** (vs.
  the class baseline's 650), **FTL Range 4.5 LY** (vs. 5.5 LY), and **FTL Cost 20
  Hydrogen/LY** (vs. 30). Every other field currently matches the baseline as-is,
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

**Ship naming convention (decided)**: real-world animal species, two-dimensional —
crossing **size tier** (Patrol/Escort/Frigate/Carrier, bigger species for bigger
sizes) with **class/role** (Interceptor/Support/Assault/Tactical, a consistent
flavor per row regardless of size):
- **The Accord**: fish species.
- **The Swarm**: bird species.

Accord (fish) matrix — Carrier column intentionally not yet addressed:

| Role ↓ / Size → | Patrol | Escort | Frigate |
|---|---|---|---|
| **Interceptor** | **Sardine** (proposed) | **Barracuda** (proposed) | **Marlin** (proposed) — large, exceptionally fast open-water fish, scales up Sardine/Barracuda's speed flavor |
| **Support** | **Pilotfish** (proposed) — small fish that shadows/assists larger predators, literal support-role flavor | **Remora** (proposed) — attaches to and aids bigger fish, mid-size support flavor | **Manta Ray** (proposed) — large, gentle, glides alongside other sea life; "big support" flavor |
| **Assault** | **Piranha** (proposed) — small, aggressive pack predator | **Moray** (proposed) — mid-size ambush predator, brute aggression | **Tiger Shark** (proposed) — large apex predator, heavy-hitter flavor |
| **Tactical** | **Anglerfish** (proposed) — small, wins by trickery/lures rather than speed | **Lionfish** (proposed) — mid-size, venomous, precise ambush predator | **Hammerhead** (proposed) — large shark famous for its sensory/tactical edge |

- **Patrol Interceptor's proposed names** — same confirm-or-correct pattern as
  Tope/Valour: Accord = **Sardine**, Swarm = **Hummingbird**. Set in
  `main/data/ships.lua`'s `faction_skins`, replacing the old `<TBD>` name
  placeholders — flag if you want different species. (Sardine specifically maps
  to the **Interceptor** row above.)
- **Escort Interceptor's proposed names**, same pattern: Accord = **Barracuda**,
  Swarm = **Falcon**. Set in `main/data/ships.lua`'s `escort_interceptor` entry.
  (Barracuda maps to the **Interceptor** row above.)
- The 10 new Accord names above (Interceptor/Frigate plus the full Support/Assault/
  Tactical rows) are proposed but not yet wired into `ships.lua` — no ship data
  entries exist yet for those class/role × size combinations (only
  `patrol_interceptor` and `escort_interceptor`, both Interceptor-row, exist in
  the roster today). Add them once real stat blocks for those ships are decided.

Swarm (bird) matrix — same role/size structure as the Accord table above, Carrier
column intentionally not yet addressed:

| Role ↓ / Size → | Patrol | Escort | Frigate |
|---|---|---|---|
| **Interceptor** | **Hummingbird** (proposed) | **Falcon** (proposed) | **Frigatebird** (proposed) — large seabird famed for speed/aerial agility, scales up Hummingbird/Falcon's speed flavor (also doubles as a pun on the Frigate size-tier name) |
| **Support** | **Oxpecker** (proposed) — small bird that rides/cleans larger animals, symbiotic support flavor (parallels Pilotfish) | **Egret** (proposed) — mid-size, often seen alongside larger animals/herds (parallels Remora) | **Pelican** (proposed) — large, cooperative group-fishing behavior, gentle-giant flavor (parallels Manta Ray) |
| **Assault** | **Shrike** (proposed) — small but notoriously vicious, impales prey (parallels Piranha) | **Goshawk** (proposed) — mid-size, aggressive ambush forest hunter (parallels Moray) | **Golden Eagle** (proposed) — large apex aerial predator, heavy-hitter flavor (parallels Tiger Shark) |
| **Tactical** | **Kingfisher** (proposed) — small, wins through exact-timing precision dives rather than trickery (parallels Anglerfish) | **Osprey** (proposed) — mid-size raptor with a specialized reversible-talon grip technique built for one job (parallels Lionfish) | **Harpy Eagle** (proposed) — large, extraordinary sensory/hunting precision (parallels Hammerhead) |

- **Patrol Interceptor's proposed names** — Swarm = **Hummingbird**, mapping to
  the **Interceptor** row above (Accord counterpart: Sardine).
- **Escort Interceptor's proposed names** — Swarm = **Falcon**, mapping to the
  **Interceptor** row above (Accord counterpart: Barracuda).
- The 10 new Swarm names above (Interceptor/Frigate plus the full Support/Assault/
  Tactical rows) are proposed but not yet wired into `ships.lua`, same caveat as
  the Accord names — no ship data entries exist yet for those combinations.
- The Carrier column for both factions is still open — *Whale Shark*/*Albatross*
  remain illustrative ideas, not addressed in this pass.
- **First ship data entry for this matrix**: `frigate_support` (Support row,
  Frigate size) added to `ships.lua` — Accord = Manta Ray, Swarm = Pelican, both
  `model` still `<TBD>` (see correction note below — a model was briefly wired to
  Pelican here, then moved to Frigatebird instead). Also introduces a new `role`
  field on ship entries (Interceptor/Support/Assault/Tactical) separate from the
  existing `class` field (which stays the size tier — `ship.class` is already
  read elsewhere for display/module-compatibility).
- **Correction**: the SuperShips `aesir.glb` model (see the §0 exception note
  below) was initially wired to Pelican (`frigate_support`) but actually belongs
  to **Frigatebird** — added as a new `frigate_interceptor` entry (Interceptor
  row, Frigate size; Accord = Marlin, `model` still `<TBD>`) per direct
  correction. Assets moved from `assets/models/frigate_support/pelican.*` to
  `assets/models/frigate_interceptor/frigatebird.*`; `frigate_support`'s Pelican
  skin reverted to `model = "<TBD>"`.
- **§0 exception, explicitly acknowledged, not silent**: Frigatebird's `model` is
  sourced from `~/Defold/SuperShips`'s `bsgo_ships_improved/hd/aesir/aesir.glb`.
  That asset's own manifest/README describe it as a "reference-guided
  interpretation" of an actual BSGO "Colonial"-faction capital ship, explicitly
  built so its silhouette is recognizable — i.e. it *is* BSG-derived vehicle
  design, the same category of asset §0 (and this plan's own Patrol Interceptor/
  Escort Interceptor notes) already ruled out for the Viper Mk II/Cylon Raider
  meshes. Flagged directly and used anyway per direct instruction after being
  shown a live render and the specific resemblance risk (raised bridge tower,
  swept flight-pod struts). Treat this as a one-off, called-out exception rather
  than a precedent — future models from that same SuperShips folder should get
  the same flag-and-confirm treatment, not be assumed pre-cleared by this one.
- **Chassis IDs renamed (direct instruction)** to a `<size>_<role>` scheme so the
  role dimension is visible in the id itself, not just in the `role` field:
  `patrol_1` → **`patrol_interceptor`**, `escort_1` → **`escort_interceptor`**,
  `frigate_1` → **`frigate_support`**. Applied everywhere the old ids appeared —
  `ships.lua` keys/paths, `session.lua`'s `STARTING_SHIP_ID`, `outpost.gui`/
  `outpost.gui_script` (texture names, preview camera lookup tables),
  `main.collection` (preview embedded-instance ids and model component paths),
  and the asset files themselves (`assets/models/patrol_1/` →
  `assets/models/patrol_interceptor/` etc., `main/images/patrol_1.atlas` →
  `patrol_interceptor.atlas`, `tools/build_patrol1_model.py` →
  `build_patrol_interceptor_model.py`, regenerated rather than hand-renamed so
  the embedded glTF node/material names stay in sync). Earlier sections above and
  the historical log below (§2.8.9/§4 entries) still say `patrol_1`/`escort_1`/
  `frigate_1` in places — left as-is since those describe what was actually built
  at the time, same convention as this plan's other "(renamed from X)" notes.
- **Second ship data entry added**: `escort_support` (Support row, Escort size) —
  Accord = Remora, Swarm = Egret (`model` still `<TBD>`). Same universal-baseline
  stat block and empty `components`/`slot_positions` as every other Escort/
  Frigate-tier ship so far.
- **§0 exception, explicitly acknowledged, not silent — second instance**:
  Remora's `model` is sourced from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/glaive/glaive.glb`. Same pattern as Frigatebird's
  `aesir.glb`: `"faction": "Colonial"`, referenced from `playbsgo.com/fleet.html`,
  described in its own manifest as a "reference-guided interpretation" with an
  explicitly recognizable silhouette ("broad flattened hexagonal command bow;
  narrow waist; flared stern drives") — i.e. BSG-derived vehicle design, §0's
  excluded category. Flagged directly a second time (not assumed pre-cleared by
  the Frigatebird precedent, per that entry's own note) and used anyway per
  direct instruction after being shown the render. Same one-off-exception
  framing applies: future SuperShips models still need their own flag-and-confirm
  pass, not a blanket pre-clearance from these two.
- Both new ships (`frigate_interceptor`, `escort_support`) got matching preview
  wiring in `main.collection` (`frigatebird_preview`/`remora_preview` embedded
  instances) and `outpost.gui_script` (`PREVIEW_WORLD_POS`/`PREVIEW_CAMERA`
  entries, eye offset/far-plane computed from each model's actual bounding
  radius — ~321 units for Frigatebird, ~119 for Remora, both with no node-level
  scale transform to account for) so their 3D models actually render, correctly
  framed, in the outpost's ship detail view once selected — not just present on
  disk with no preview hookup.
- **Third ship data entry added**: `frigate_tactical` (Tactical row, Frigate
  size) — Accord = Hammerhead, wired to a model; Swarm = Harpy Eagle (`model`
  still `<TBD>`). Same universal-baseline stat block and empty
  `components`/`slot_positions` as every other Escort/Frigate-tier ship so far.
- **§0 exception, explicitly acknowledged, not silent — third instance**:
  Hammerhead's `model` is sourced from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/gungnir/gungnir.glb`. Same pattern as the previous two:
  `"faction": "Colonial"`, referenced from `playbsgo.com/fleet.html`, described
  in its own manifest as a "reference-guided interpretation" of a canon
  Battlestar-line capital ship with an explicitly recognizable silhouette ("long
  rectangular gunship bow; red armored shoulder pods around the stern") — i.e.
  BSG-derived vehicle design, §0's excluded category. Flagged directly a third
  time (not assumed pre-cleared by the prior two) and used anyway per direct
  instruction after being shown the render. Same one-off-exception framing still
  applies: future SuperShips models still need their own flag-and-confirm pass.
- `frigate_tactical` got the same preview wiring as the other two new ships —
  `hammerhead_preview` in `main.collection`, `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA`
  entries in `outpost.gui_script` (~349-unit bounding radius, the largest model
  in the roster so far, no node-level scale transform).
- **BSGO-identifying internal metadata stripped (direct instruction)** from all
  three SuperShips-sourced GLBs above (Frigatebird/`aesir.glb`, Remora/
  `glaive.glb`, Hammerhead/`gungnir.glb`) - node/mesh names renamed from the
  source ship's own name (e.g. `"Aesir"`) to `<our name>_hull`, materials
  renamed from `colonial_*`/`engine_glow` to `<our name>_*`, and each node's
  `extras` block (`ship_id`/`faction: "Colonial"`/`ship_class`) removed
  entirely - matching this file's own established "stripped of identifying
  third-party metadata before being added" rule (§2.1.2's Barracuda/Falcon
  note). Verified the patched GLBs still render identically (geometry/UVs/
  materials untouched, only name strings and the extras block changed).
  Confirmed via `assets/models/**/*.glb` audit that every other model in the
  roster (`barracuda`, `falcon`, `hummingbird`, `sardine`, the two hand-authored
  hulls) was already clean - this scrub was needed only for the three
  SuperShips-sourced ones.
- **Fourth ship entry filled in, fourth §0 exception**: Pelican
  (`frigate_support`'s Swarm skin, previously `<TBD>`) now points at
  `assets/models/frigate_support/pelican.glb`, sourced from
  `~/Defold/SuperShips`'s `bsgo_ships_improved/hd/hel/hel.glb` (BSGO-identifying
  metadata stripped the same way as the other three, per the note above -
  `"Hel"` → `pelican_hull`, `cylon_*` materials → `pelican_*`). **Stronger flag
  than the previous three**: `hel`'s manifest tags it `"faction": "Cylon"` -
  the *other* explicitly-named banned term in §0 (alongside "Colonial") - and
  its render is a wide bone-white organic shell with a row of glowing red
  lights, the show's signature Cylon bio-mechanical/red-scanner-eye look,
  arguably more immediately recognizable than the three Colonial-line ships
  used so far. Flagged directly, called out as a *stronger* match than
  precedent (not treated as equivalent-and-therefore-pre-cleared), and used
  anyway per direct instruction. Got the same preview wiring as the others
  (`pelican_preview` in `main.collection`, `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA`
  in `outpost.gui_script`, ~310-unit bounding radius).
- Running tally: **four** acknowledged §0 exceptions now in the roster
  (Frigatebird/aesir, Remora/glaive, Hammerhead/gungnir, Pelican/hel) — still
  each individually flagged-and-confirmed, never treated as a blanket
  pre-clearance for the SuperShips folder as a whole.
- **Fifth ship entry added, fifth §0 exception**: new `escort_assault` chassis
  (Assault row, Escort size) — Accord = Moray, wired to a model; Swarm =
  Goshawk (`model` still `<TBD>`). Same universal-baseline stat block and empty
  `components`/`slot_positions` as every other Escort/Frigate-tier ship so far.
  Moray's `model` is sourced from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/maul/maul.glb`, BSGO-identifying metadata stripped on
  copy this time (not retroactively) - `"Maul"` → `moray_hull`,
  `colonial_*`/`engine_glow` materials → `moray_*`, `extras` removed. Same
  pattern as the four exceptions before it: `"faction": "Colonial"`,
  `playbsgo.com/fleet.html` reference, "reference-guided interpretation" of a
  canon Colonial Escort-class assault ship. Flagged directly a fifth time and
  used anyway per direct instruction. Got the same preview wiring as the others
  (`moray_preview` in `main.collection`, `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA` in
  `outpost.gui_script`, ~99-unit bounding radius - the smallest SuperShips-
  sourced model in the roster so far).
- **Batch of three (direct instruction)**: `rhino`→Piranha, `liche`→Osprey,
  `scythe`→Barracuda, all from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/`, all flagged and confirmed together before wiring
  in, all BSGO-identifying metadata stripped on copy (same as every prior
  SuperShips-sourced model in this file).
  - **Sixth ship entry, sixth §0 exception**: new `patrol_assault` chassis
    (Assault row, Patrol size) — Accord = Piranha, wired to `rhino.glb`; Swarm =
    Shrike (`model` still `<TBD>`). `rhino` is tagged `"faction": "Colonial"`,
    `"cls": "Strike"` — an 11m small strike-fighter, unlike the capital/escort-
    scale sources used so far — "reference-guided interpretation" of a canon
    Colonial strike craft (armored cockpit wedge, stub wings, raised rear engine
    cluster). Uses the unmodified universal baseline stat block, not Patrol
    Interceptor's own hull_points=600 override (that override was ship-specific,
    not Patrol-tier-wide).
  - **Seventh ship entry, seventh §0 exception**: new `escort_tactical` chassis
    (Tactical row, Escort size) — Swarm = Osprey, wired to `liche.glb`; Accord =
    Lionfish (`model` still `<TBD>`). Same "Cylon" pattern as Pelican's `hel.glb`
    - `liche` is tagged `"faction": "Cylon"`, bone-white/metallic split-blade
    shape, same bio-mechanical Cylon design language.
  - **Eighth §0 exception, on an EXISTING ship**: Barracuda's `model`
    (`escort_interceptor`, previously a clean, non-SuperShips user-supplied
    asset per its own long-standing note) was **replaced** with `scythe.glb`,
    copied directly over the old `assets/models/escort_interceptor/barracuda.glb`
    file path. `scythe` is tagged `"faction": "Colonial"`, "reference-guided
    interpretation" of a canon Colonial Escort-class ship (tall axe-shaped hull,
    cruciform stern fins). Falcon's model on the same ship entry is unaffected -
    still the original clean asset, no §0 flag. `outpost.gui_script`'s
    `PREVIEW_CAMERA` entry for `barracuda.model` was recomputed against the new
    file's own ~114-unit bounding radius (the old asset was a different scale).
- Running tally: **eight** acknowledged §0 exceptions now in the roster across
  seven ship entries (Frigatebird/aesir, Remora/glaive, Hammerhead/gungnir,
  Pelican/hel, Moray/maul, Piranha/rhino, Osprey/liche, and Barracuda's
  replacement/scythe) — still each individually flagged-and-confirmed, never
  treated as a blanket pre-clearance for the SuperShips folder as a whole.
- **Batch of two (direct instruction)**: `nidhogg`→Harpy Eagle, `jormung`→Golden
  Eagle, both from `~/Defold/SuperShips`'s `bsgo_ships_improved/hd/`, flagged
  and confirmed together before wiring in, both BSGO-identifying metadata
  stripped on copy.
  - **Ninth §0 exception, fills in an existing `<TBD>`**: Harpy Eagle
    (`frigate_tactical`'s Swarm skin, previously `<TBD>`) now points at
    `assets/models/frigate_tactical/harpy_eagle.glb`. `nidhogg` is tagged
    `"faction": "Cylon"`, "reference-guided interpretation" of a canon Cylon
    ship - an organic central spear wrapped by four outward-curving skeletal
    claws. The claw shape happens to read as a fitting coincidence for an
    eagle-named ship, though that wasn't the selection reason.
  - **Tenth ship entry, tenth §0 exception**: new `frigate_assault` chassis
    (Assault row, Frigate size) — Swarm = Golden Eagle, wired to `jormung.glb`;
    Accord = Tiger Shark (`model` still `<TBD>`). `jormung` is tagged
    `"faction": "Cylon"`, "reference-guided interpretation" of a canon Cylon
    capital ("Line" class) ship - deep vertical blade hull, flared forward edge,
    the same row-of-red-lights motif as Pelican's `hel.glb`. At ~400-unit
    bounding radius this is the **largest model in the roster so far**.
  - Both got the same preview wiring as every other model (`harpy_eagle_preview`
    / `golden_eagle_preview` in `main.collection`, matching
    `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA` entries in `outpost.gui_script`).
- Running tally: **ten** acknowledged §0 exceptions now in the roster across
  nine ship entries — still each individually flagged-and-confirmed, never
  treated as a blanket pre-clearance for the SuperShips folder as a whole.
- **Batch of three (direct instruction)**: `fenrir`→Marlin, `vanir`→Manta Ray,
  `jotunn`→Tiger Shark, all from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/`, flagged and confirmed together before wiring in.
  This batch **completes the entire Frigate row** on the Accord side of the
  naming matrix (Interceptor/Support/Assault/Tactical all now have Accord
  models; only Tactical's Swarm counterpart, Harpy Eagle, was already filled
  separately). All three BSGO-identifying-metadata-stripped on copy.
  - **Eleventh §0 exception, fills an existing `<TBD>`**: Marlin
    (`frigate_interceptor`'s Accord skin) now points at `fenrir.glb`.
    **Cross-faction note**: `fenrir`'s manifest tags it `"faction": "Cylon"` -
    despite being used here for an Accord (fish-named) ship, not a Swarm one -
    flagged specifically as a mismatch, not just a generic resemblance risk.
    Sleek forked-hull/lance shape, confirmed anyway per direct instruction.
  - **Twelfth §0 exception, fills an existing `<TBD>`**: Manta Ray
    (`frigate_support`'s Accord skin) now points at `vanir.glb`. Tagged
    `"faction": "Colonial"` - twin-parallel-hull shape with connecting bridges,
    a fitting-coincidence silhouette for a ray, though not the selection reason.
  - **Thirteenth §0 exception, fills an existing `<TBD>`**: Tiger Shark
    (`frigate_assault`'s Accord skin) now points at `jotunn.glb`. Tagged
    `"faction": "Colonial"` - deep armored assault hull with stepped dorsal deck
    and rear outriggers.
  - All three got the same preview wiring as every other model
    (`marlin_preview`/`manta_ray_preview`/`tiger_shark_preview` in
    `main.collection`, matching `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA` entries in
    `outpost.gui_script`, bounding radii ~300/~286/~327 units respectively).
- Running tally: **thirteen** acknowledged §0 exceptions now in the roster
  across nine ship entries — still each individually flagged-and-confirmed,
  never treated as a blanket pre-clearance for the SuperShips folder as a whole.
- **Batch of four (direct instruction)**: `raider`→Hummingbird, `heavy_raider`→
  Oxpecker, `marauder`→Shrike, `war_raider`→Kingfisher, all from
  `~/Defold/SuperShips`'s `bsgo_ships_improved/hd/`. This batch **completes the
  entire Patrol row** on the Swarm side of the naming matrix.
  - **Fourteenth §0 exception - HIGHEST SEVERITY IN THE FILE**: Hummingbird's
    `model` (`patrol_interceptor`, previously a clean CC-BY-4.0 Sketchfab asset,
    attribution JazOone "SpaceShip") was **replaced** with `raider.glb`. Flagged
    to you explicitly before proceeding, distinct from every prior exception:
    `raider` is not merely "BSG-derived" like the other thirteen - it IS, by
    name, the **Cylon Raider** - the exact ship this plan's own Patrol/Escort
    model notes have repeatedly cited BY NAME as the paradigm example of what
    §0 excludes ("deliberately NOT... the actual Viper Mk II/Cylon Raider
    meshes"). Its SuperShips manifest also carries a note none of the other
    thirteen sources have: `"note": "reference only; friend already has a
    Raider"` - a separate signal from the asset pack's own author that this
    file wasn't intended for general reuse, on top of the BSG-IP question.
    Used anyway per direct instruction after being shown the render and both
    of these points called out explicitly - logged here as a conscious,
    acknowledged override of this plan's own most-repeated exclusion example,
    not a slip.
  - **Fifteenth §0 exception, new ship entry**: new `patrol_support` chassis
    (Support row, Patrol size) - Swarm = Oxpecker, wired to `heavy_raider.glb`
    (`"cls": "Strike"`, 10m transport-variant scale, same Raider design family
    as Hummingbird's model); Accord = Pilotfish (`model` still `<TBD>`).
  - **Sixteenth §0 exception, fills an existing `<TBD>`**: Shrike
    (`patrol_assault`'s Swarm skin) now points at `marauder.glb` - a close
    visual cousin of the Raider silhouette (single curved wing/body, red light
    bar) despite being a distinct named source ship.
  - **Seventeenth §0 exception, new ship entry**: new `patrol_tactical` chassis
    (Tactical row, Patrol size) - Swarm = Kingfisher, wired to `war_raider.glb`
    (a broader flying-wing shape, less identical to the classic Raider look but
    same design family); Accord = Anglerfish (`model` still `<TBD>`).
  - All four got the same preview wiring as every other model
    (`oxpecker_preview`/`shrike_preview`/`kingfisher_preview` new in
    `main.collection`, Hummingbird's existing preview camera entry in
    `outpost.gui_script` recomputed for the new file's ~6.7-unit radius).
- Running tally: **seventeen** acknowledged §0 exceptions now in the roster
  across twelve ship entries — still each individually flagged-and-confirmed,
  never treated as a blanket pre-clearance for the SuperShips folder as a
  whole, and the Hummingbird/raider one specifically logged as a conscious
  override rather than lumped in as "more of the same."
- **Batch of three (direct instruction)**: `banshee`→Falcon, `spectre`→Egret,
  `wraith`→Goshawk, all from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/`. This batch **completes the entire Escort row** on
  the Swarm side of the naming matrix (Interceptor/Support/Assault/Tactical all
  now have Swarm models - Tactical's Osprey was already done separately).
  - **Eighteenth §0 exception, replaces an existing clean asset**: Falcon's
    `model` (`escort_interceptor`, previously a distinct per-faction
    user-supplied asset, not SuperShips-sourced, no prior §0 flag) was
    **replaced** with `banshee.glb`, copied over the old
    `assets/models/escort_interceptor/falcon.glb` file path - same pattern as
    the earlier Barracuda/scythe and Hummingbird/raider swaps. Tagged
    `"faction": "Cylon"`, "reference-guided interpretation" of a canon Cylon
    Escort-class ship (compact rear body, four long separated forward lances).
    `outpost.gui_script`'s PREVIEW_CAMERA entry recomputed for the new file's
    ~128-unit radius.
  - **Nineteenth §0 exception, fills an existing `<TBD>`**: Egret
    (`escort_support`'s Swarm skin) now points at `spectre.glb` - three
    pronounced radial fins around a long forward spear.
  - **Twentieth §0 exception, fills an existing `<TBD>`**: Goshawk
    (`escort_assault`'s Swarm skin) now points at `wraith.glb` - angular split
    armored jaws with a central opening and large red inner vents, an
    aggressive shape fitting the Assault row.
  - All three got the same preview wiring as every other model
    (`egret_preview`/`goshawk_preview` new in `main.collection`, matching
    `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA` entries in `outpost.gui_script`).
- Running tally: **twenty** acknowledged §0 exceptions now in the roster across
  twelve ship entries — still each individually flagged-and-confirmed, never
  treated as a blanket pre-clearance for the SuperShips folder as a whole.
- **Batch of three (direct instruction)**: `viper_mk2`→Sardine, `raptor`→
  Pilotfish, `viper_mk7`→Anglerfish, all from `~/Defold/SuperShips`'s
  `bsgo_ships_improved/hd/`. This batch **completes the entire Patrol row** on
  the Accord side of the naming matrix.
  - **Twenty-first §0 exception, HIGHEST SEVERITY, tied with Hummingbird/
    raider**: Sardine's underlying mesh (`patrol_interceptor.model` wraps
    `assets/models/patrol_interceptor/sardine.glb`, a separate file from the
    project's own hand-authored `patrol_interceptor.glb` hull - a pre-existing
    gap between this file's old comment and its actual wiring, not introduced
    here) was **replaced** with `viper_mk2.glb`. This completes the EXACT named
    pair this project has always cited as its paradigm §0 exclusion example -
    "Viper Mk II/Cylon Raider" - now with the Viper Mk II half wired to
    Sardine, the very ship the original "no Viper Mk II" comment was about.
    Same `"note": "reference only; friend already has a Mk II"` marker as
    Raider's manifest entry. Its render was already confirmed earlier in this
    session (during the original IP-risk discussion, before any SuperShips
    model had been used at all). Used anyway per direct instruction after being
    shown this framing explicitly - a conscious override, not a slip.
    `outpost.gui_script`'s PREVIEW_CAMERA entry recomputed for the new file's
    ~5.1-unit radius.
  - **Twenty-second §0 exception, fills an existing `<TBD>`**: Pilotfish
    (`patrol_support`'s Accord skin) now points at `raptor.glb` - the
    well-known Colonial transport/scout ship from the source material.
  - **Twenty-third §0 exception, fills an existing `<TBD>`**: Anglerfish
    (`patrol_tactical`'s Accord skin) now points at `viper_mk7.glb` (Viper Mk
    VII) - a later, distinct numbered Viper variant, still individually
    recognizable though less singularly iconic than Mk II.
  - Note: the SuperShips source folder was reorganized externally during this
    session - models already used got moved into a `bsgo_ships_improved/hd/
    copied/` subfolder. This batch's three files were found there rather than
    at their original top-level paths; content/provenance unaffected.
  - All three got the same preview wiring as every other model
    (`pilotfish_preview`/`anglerfish_preview` new in `main.collection`,
    matching entries in `outpost.gui_script`).
- Running tally: **twenty-three** acknowledged §0 exceptions now in the roster
  across twelve ship entries — still each individually flagged-and-confirmed,
  never treated as a blanket pre-clearance for the SuperShips folder as a
  whole, and both Hummingbird/raider and Sardine/viper_mk2 specifically logged
  as conscious overrides of this project's own named exclusion pair rather than
  lumped in as "more of the same."

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

**Three harvestable resources — renamed from the source's own three (confirmed
BSGO reference: Tylium → Hydrogen, Titanium → Iron, Water → Water):**

| Our name | Role | Reference-game role it replaces (internal only, never player-facing) |
|---|---|---|
| **Hydrogen** (renamed from **Tylium**) | Base/general resource — **does not convert into Tope**. Instead, Hydrogen is spent **directly** as a basic-tier currency-resource: cheap/everyday shop purchases can be paid for with Hydrogen alone. More advanced purchases require an additional resource/currency **on top of** Hydrogen (Tope being the main example) — mirrors the source game's pattern where its base resource paid for most things outright, but pricier items needed it combined with the premium currency. Also confirmed as **ship fuel** — FTL jumps and boost both cost Hydrogen (§2.1.1). | Replaces **Tylium** (per confirmed intent — the source's base resource *and* ship fuel, matching Hydrogen's own double role). |
| **Iron** | Dedicated **repair** resource — repairs ship wear/tear over time (hull + module wear, §2.8). | Replaces **Titanium** (per confirmed intent). |
| **Water** | Sells toward **Tope** (Marque abandoned — see below; Water's sale now
feeds Tope directly instead) — an efficient farming resource. | Water (name unchanged) — in the source game Water was a minor/flavor resource whose main gameplay purpose was conversion into the premium currency |

**Two currencies** (Marque abandoned — folded into Tope; down from the earlier
three-currency draft):

| Currency | Tier | Earned via | Spent on |
|---|---|---|---|
| **Tope** | General | **For now, exactly two sources, decided**: (1) mining an asteroid that contains Water and selling that Water for Tope; (2) buying Tope directly with real money. No other earn source (combat rewards, daily assignments, Robot kills, etc.) is active yet — those were provisional ideas from the Marque-merge, not confirmed for Tope. | Everything beyond basic Hydrogen-only purchases — advanced items, ships, ship upgrades, booster items, resources — typically **required alongside Hydrogen** rather than replacing it |
| **Valour** (new, replaces "Merits") | PvP-only | **PvP kills only** (never from PvE/Robots) — small amount per kill, a bonus for damaging/forcing the retreat of an enemy siege objective (ties directly into the contested-node siege mechanic, §2.5), and a bigger bonus for destroying an enemy Carrier | Nuclear ordinance specifically (Nuclear Torpedoes/Launchers, §2.8) and Carrier-class ships — gates the highest-end purchases behind PvP performance, not spending |

- Name **Valour** is confirmed (British spelling, per direct instruction) — no
  longer a placeholder.
- Marque (the premium-tier currency) is **abandoned** — its spend role (ships,
  upgrades, boosters) has folded into Tope, which is now the single non-PvP
  currency. Only two of Marque's former earn sources (selling Water, real-money
  purchase) carried over — see the confirmed two-source list above.
- Deliberately not carried over: the source game's specific named ships tied to its
  PvP currency (e.g. specific multirole/stealth ship names) — those are BSG-specific
  proper nouns, out of bounds regardless of context (§0).
- Resources convert to refined material for crafting/fitting.
- Module fitting: weapon / armor / engine / utility slots per ship tier.
- Poki/F2P monetization: cosmetics, convenience (queue skips, extra ship slots), and
  **direct real-money purchase of Tope**, which buys most fitting/upgrades —
  pay-to-win is accepted as part of the monetization model (the earlier "no
  pay-to-win" stance is abandoned).

#### 2.6.1 Tope balance implemented (decided — with placeholder prices)

Per direct instruction: the outpost screen now **always shows the player's Tope
balance, updating live as items/ships are bought and sold**. This needed a real,
working balance and real transaction amounts to do honestly, not just a static
number on screen — so `main/session.lua` now tracks an actual `tope` value, and
every buy/sell function spends or credits it for real.

- **Starting balance and every price/refund are FLAT PLACEHOLDER values** — 500
  starting Tope, 100 to buy any module (flat, not per-item), 50 refund selling one,
  500 to buy a ship (flat, not per-ship), 250 refund selling one. **Not real economy
  design** (§2.6's actual pricing is still fully open work) — introduced purely so
  the currency display has something genuine to show and update, per §0/§4's "don't
  invent unconfirmed numbers" rule: the *mechanic* is real, the *numbers* are
  explicitly flagged placeholders, same spirit as Patrol 1's stat block before real
  tuning existed.
- **Insufficient funds are handled, not ignored**: `session.purchase`/
  `purchase_ship` refuse (return `nil`/`false`, spend nothing) if the balance is too
  low. The outpost screen checks affordability before opening the normal purchase
  dialog and shows a distinct "Not enough Tope to buy X (need N, have M)" notice
  instead — reusing the same confirmation-dialog UI (§2.8.6) with a no-op callback,
  rather than a new dialog type.
- **UI**: a `tope_label` node in `main/outpost.gui`, positioned outside all three
  tabs' static-node groups (top-right, alongside the title) so it's never hidden
  regardless of active tab — "always show," literally. `refresh_currency` in
  `main/outpost.gui_script` keeps it in sync, called on `show_outpost` and
  (unconditionally) right after every confirmation-dialog resolution, since that's
  the only place the balance can ever change.
- Shop/For Sale card labels and every purchase/sell confirmation message now state
  the actual (placeholder) price/refund instead of the old generic "(price TBD)" —
  since a real number is genuinely being charged now, showing "TBD" next to it would
  be dishonest, not just incomplete.
- **Verified**: both outpost-screen test harnesses extended with balance assertions
  around their existing purchase/sell flows (module purchase, module sale, ship
  purchase, ship sale) confirming the exact expected balance and readout text after
  each, plus a new case forcing the balance below a module's price and confirming
  the distinct insufficient-funds notice appears, spends nothing, and installs
  nothing. A real `bob.jar build` compiles cleanly.

#### 2.6.2 Water/Iron/Hydrogen readouts added (decided — display only, static values)

Per direct instruction: the outpost screen's always-visible currency header
(§2.6.1) now shows **all four** of the player's balances — Tope, **Water**,
**Iron**, and **Hydrogen** (the "fourth resource," §2.6's renamed fuel stat) —
stacked in a column at the top-right, `tope_label` on top and the other three
below it in the same style.

- `main/session.lua` gained `M.water`/`M.iron`/`M.hydrogen`, each a flat
  placeholder starting balance of 500 (`STARTING_WATER`/`STARTING_IRON`/
  `STARTING_HYDROGEN`), set in `choose_faction` exactly like `M.tope`, plus
  `get_water()`/`get_iron()`/`get_hydrogen()` getters.
- **Unlike Tope, these three are honestly static** — no mining, repair, or
  FTL/boost mechanic exists yet to actually spend or earn them, so nothing
  ever changes them after the starting value is set. **(Since superseded:**
  mining an asteroid now credits the depleting player's Water/Iron/Hydrogen,
  and FTL jumps spend Hydrogen — see §2.11 and §2.10.1. The starting values
  below are still placeholders, and the scale mismatch against
  `repair_cost_iron` is still open, §4.**)** `ships.lua`'s
  `repair_cost_iron`/`boost_cost_hydrogen_per_sec`/`ftl_cost_hydrogen_per_ly`
  fields are stats a future mechanic will read, not something currently
  deducting against these balances — flagged explicitly in `session.lua`'s
  comments so a future pass doesn't mistake "static" for "working." Also
  flagged: the starting placeholders (500 each) aren't reconciled against
  `repair_cost_iron`'s existing placeholder value (10,000) — nothing spends
  against either number yet, so that scale mismatch is open work (§4).
- **UI**: `water_label`/`iron_label`/`hydrogen_label` text nodes in
  `main/outpost.gui`, stacked below `tope_label` in the same top-right
  column (all four outside every tab's static-node group, so none are ever
  hidden regardless of active tab). `tope_label` itself shrank from 60px to
  32px tall to fit the four-row stack in the available space above the
  Fitting tab's Shop panel. `refresh_currency` in `main/outpost.gui_script`
  now sets all four texts in one place, called at the same two sites as
  before (`show_outpost`, and after every confirmation-dialog resolution).
- **Verified**: both outpost-screen test harnesses extended with assertions
  that all four readouts show the correct starting values on `show_outpost`,
  and that Water/Iron/Hydrogen remain exactly unchanged after unrelated
  Tope-spending flows (module/ship purchases and sales) elsewhere in the
  same test run. A real `bob.jar build` compiles cleanly.

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
- **Default position (revised, per direct instruction)**: opposite diagonal
  corners of the system's horizontal extent, on the **Y=0 plane** (Y is up,
  matching `main/player_ship.script`'s own `UP = (0,1,0)` convention — X/Z are
  the horizontal plane), inset a **flat 1000 units** from each corner
  (`M.OUTPOST_CORNER_INSET`) — not a fraction of the system's size like the
  earlier 80%-to-edge placeholder, a fixed absolute margin regardless of how
  big the system is. Still computed generically, not hand-placed per system,
  for any system that doesn't need to deviate.
- **Explicit per-system override (new, per direct instruction: "allow for
  coordinates for each of the outposts to be sent explicitly")**: a system
  entry's own `outposts = { accord = {x,y,z}, swarm = {x,y,z} }` table, when
  present, is returned as-is for that faction instead of the generic default
  above. No system uses this yet — it's a provision, same "schema now, real
  values later where needed" footing as other per-entry overrides in this
  project (e.g. ships.lua's `flight_camera`, §2.10.1).
- **Per-system world extent (new, per direct instruction)**: systems now
  specify `width_m`/`height_m`/`depth_m` independently (was a single uniform
  `size_m`) — defaults to `M.DEFAULT_SYSTEM_SIZE_M` (10,000) in each
  direction when a system entry doesn't set its own; only the 3 systems that
  actually deviate (antares/fomalhaut/deneb, still a uniform 40,000 cube
  each) set all three explicitly. Spawn points (below) derive from the same
  width/depth-based corner geometry, always following the DEFAULT corners
  regardless of whether a system's actual outpost position was overridden —
  no per-system spawn-point override exists yet, only for the outpost itself
  (flag if a system's overridden outpost ever needs its spawns to follow it
  too, §4).
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
  Verified working via a standalone `luajit` check (not just code review): a
  default 10,000-unit system returns `(±4000, 0, ±4000)` (width/2 − 1000
  inset, Y=0), the 40,000-unit systems return `(±19000, 0, ±19000)`, setting
  a system's own `outposts.accord` override returns that exact table for
  Accord while Swarm still falls through to the computed default on the same
  system, and `M.spawn_points` returns the two expected corner-adjacent
  midpoints. No external code calls either function yet (no docking/travel
  system exists to call them from) - purely a data-layer provision ahead of
  that, same footing as `M.reachable_from`/`M.hydrogen_cost` already were.
- **Outpost defence (proposed — reference data in §2.13 I)**: how outposts can be
  attacked and what defences they have is still not *decided* (§4), but the
  second-pass BSGO research (§2.13) now supplies a concrete, reference-backed shape
  to design from — recorded here so §4's TODO starts from a real proposal rather
  than a blank page. Per §0, everything below is *structure/mechanics* usable as a
  starting point, not final tuning; the names are BSG's and are reference-only.
  - **The outpost is armed, not a passive hull**: the reference outpost carries
    long-range cannons, long-range missile launchers and point-defence batteries
    (the anti-missile role — its platform point defence has the highest accuracy in
    the reference, ~700, and platform guns are omnidirectional, half-angle ≥180°).
    Reference hull ladder: 50,000 regular → 55,000 upgraded → 60,000 fortified.
    Our server's `nakama-server/modules/outposts.lua` `OUTPOST_HULL = 50000`
    already matches the regular tier.
  - **Sentry platforms are the real defence layer** — up to 4 immobile weapons
    platforms placed equidistantly around the outpost, graded light/medium/heavy,
    whose count and loadout scale with the system's control/outpost-progress level
    (reference ladder: L3 → 2 light; L4 → 4 light; L5 → upgraded outpost + 2
    light→medium; L6 → 4 medium; L7/L8 → heavy platforms in; ~L7–L8 (275–300%)
    → fortified outpost ringed by 4 heavy). Reference stat blocks:
    - **Light** — 7,500 hull / 3,000 power / armour 35 — 8× light autocannon
      turrets + 2× interceptor missile launchers.
    - **Medium** — 10,000 hull / 3,000 power / armour 60 — 8× medium cannon
      turrets + 5× medium missile launchers.
    - **Heavy** — 15,000 hull / 3,000 power / armour 75 — 2× flak cannons + 2×
      point-defence turrets + 8× heavy cannon turrets + 5× heavy missile launchers.
  - **Platform defensive behaviour (the AI shape we'd copy)**: dormant until
    attacked or until a ship closes to ~1,200 m, then fires until the target is
    destroyed or leaves range; gun range ~1,600 m (light) to ~2,000 m (heavy), with
    missiles reaching ~3,500 m; no hull regen in combat (ships do, after 15 s); a
    destroyed platform respawns in place after ~10 min.
  - **Still to decide (§4)**: whether our outpost gets this layered defence at all;
    whether the fortification level is driven by our own control points (§2.7's
    opposing-ship cap / conflict zones) or is fixed per system; whether sentry
    platforms are separate targetable objects (as in the reference) or folded into
    the outpost's own hull/weapon numbers; whether they are server-simulated
    (recommended — the server already owns all outpost damage) or client-visual
    only; and how the whole layer scales with a system's threat rating (§2.7).

**Outpost 3D models (decided, first pass — basic placeholder shapes, per direct
instruction: "let's begin by building two basic shapes")**:
- **Accord**: a cuboid that "vaguely represents a fish tank" (fits the Accord's
  own fish naming theme, §2.1.2) — a dark stand (the faction's own established
  blue, `main/faction_select.gui`'s `accord_button` color) under a lighter
  cyan/teal "glass" volume. `tools/build_accord_outpost_model.py` →
  `assets/models/outposts/accord_outpost.glb`/`.model`. Overall bounding box:
  300w × 360h × 1000 long.
- **Swarm**: a cylinder, "similar size" to the Accord shape — read as matching
  its overall ~1000-unit extent (here, height, standing upright rather than
  lying on its side) rather than its footprint. A dark flared base under a
  taller main body, both in the faction's own established purple
  (`swarm_button` color). `tools/build_swarm_outpost_model.py` →
  `assets/models/outposts/swarm_outpost.glb`/`.model`. Overall bounding box:
  380 diameter × 1000 tall.
- Same low-poly/flat-shaded/vertex-color GLB-writing technique as every ship
  hull builder (e.g. `build_sardine_model.py`) — an ORIGINAL design each,
  hand-authored, not sourced from anywhere (§0). Deliberately basic per direct
  instruction - two stacked primitive volumes each, no greebling/detail.
- **Placed at each system's own real `M.outpost_position()` coordinates**
  (per direct instruction: "render them in the position set in each system") —
  `main/main.collection` gained two new embedded instances, `accord_outpost` at
  Sol's own outpost position `(-4000, 0, -4000)` and `swarm_outpost` at
  Polaris's own `(4000, 0, 4000)` (both computed from §2.7's own default-corner
  formula above, confirmed via a standalone `luajit` check against the real
  `star_systems.lua` function, not hand-typed). Only these two exist in-world
  so far — there's no per-system scene separation yet (§4, flight mode is
  still the single shared collection §2.10.1 describes), so Sol/Polaris (the
  two home systems, the only ones actually reachable in the current minimal
  flight slice) are what's actually renderable right now, not the other 56
  systems' outposts.
- **Verified live**: real engine build (`/command/build`, zero issues), driven
  with synthetic mouse clicks into flight, with a temporary debug spawn
  override (reverted after) placing the ship in front of each outpost in turn
  and screenshotting - confirms both render at their correct world position,
  correct relative scale against the ship, and the intended silhouette (a
  tank-like stand+glass box for Accord, a tower-like stand+cylinder for Swarm).

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

**Weapon firing arc (decided — schema only, per direct instruction)**: a weapon
mount doesn't fire in every direction — it can only hit a target somewhere within a
cone centered on a specific bearing. Two halves, split the same way slot geometry
already is between the ship (`ships.lua`) and the item (`weapons_autocannons.lua`/
`weapons_launchers.lua`):
- **Where the cone points is a per-slot, per-ship fact**, not a weapon fact — the
  same weapon dropped into a bow slot vs. a side-mounted slot on the same hull
  points a different direction. So it lives alongside `slot_positions` in
  `ships.lua`'s chassis table: each **weapon** slot entry (`W1`, `W2`, ... — Hull/
  Engine/Computer slots don't fire, so they don't get this field) gains an
  `angle_deg` field — degrees from the ship's own bow/forward axis (0° = dead
  ahead), positive rotating clockwise toward starboard (+x in `slot_positions`'
  own screen-space convention), matching the "forward = +y" sense `E1`/`E3`'s
  stern-ward *negative* y already implies.
- **How wide the cone is is a per-weapon fact**, not a slot fact — a
  wide-traverse turret and a fixed forward gun differ by weapon, not by which
  ship they're bolted to. So it lives on the module entry itself (`arc`, total
  cone width in degrees, centered on whichever slot's own `angle_deg` it's
  fitted into — e.g. `arc = 60` covers ±30° either side of center). **Decided,
  per direct instruction**: every auto cannon in `weapons_autocannons.lua`
  (`auto_cannon_basic`, `mining_cannon_basic/escort/frigate/carrier`) now
  defaults to `arc = 75`, applied uniformly rather than tuned per weapon.
- **Implemented as a schema provision** — `patrol_interceptor`'s `W1`-`W4`
  slots in `main/data/ships.lua` now carry a placeholder `angle_deg` (same
  "real numbers TBD, structure isn't" treatment `slot_positions` itself already
  got — see that field's own "STILL PLACEHOLDER" note above). No targeting/
  firing/line-of-sight code reads either field yet — combat resolution doesn't
  exist yet at all (§4) — this just gets the data shape in place ahead of that.

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
`auto_cannon_basic`, `cannon_type = "ordinance"` — the reference's `MEC-A6 "Fang"` /
`Type A "Aggressor"`) and one **Mining Cannon** (`mining_cannon_basic` — the
reference's `Gopher` / `Gouger`) — not two of the same cannon. Earlier working names
for these ("Tempest"/"Stalker" and "Digger") were superseded when the weapons moved
to the reference's own naming (below).

**Combat weapon naming convention (decided, revised — "exact reference names")**:
combat auto cannons and launchers now carry the **reference game's own published
designations verbatim** — the Colonial name on the Accord side, the Cylon name on the
Swarm side — per the direct instruction to match `bsgo.fandom.com/wiki/Weapons` as
closely as possible (e.g. `MEC-A6 "Fang"` / `Type A "Aggressor"`). This is the
**acknowledged §0 exception** recorded at the top of this file. Still one entry per
item: the two names live side by side in a `faction_names` table (`{ accord = ...,
swarm = ... }`) on the entry, with `name` holding the Accord name as the
default/reference value. Where the reference lists only **one shared name** (its Escort
cannon batteries, and `Nova`/`Thunderbolt`/`Mole`), the entry carries a single `name`
and no `faction_names`. `catalog.name_for(entry, faction)` resolves the right name for
the player's faction (mirroring how ships resolve `faction_skins[faction].name`,
§2.1.2), and every module-name call site on the outpost screen and flight HUD reads
through it instead of `entry.name` directly. Where the reference has **no name** at all
(its Line/Frigate page is "(tbc)"), the earlier original names are retained rather than
inventing BSGO ones.

The full set (Accord / Swarm):

| Category | Patrol | Escort | Frigate |
|---|---|---|---|
| General cannon | `MEC-A6 "Fang"` / `Type A "Aggressor"` | `MEC-E12 "Claw"` (shared) | `AC-F "Monsoon"` / `Type F "Colossus"` |
| Rapid cannon | `MEC-A8 "Tornado"` / `Type A1 "Lasher"` | `MEC-E13 "Hurricane"` (shared) | `AC-FR "Wildfire"` / `Type FR "Reaver"` |
| Long-range cannon | `MEC-A9 "Hawk"` / `Type A2 "Disabler"` | `MEC-E17 "Falcon"` (shared) | `AC-FL "Zenith"` / `Type FL "Overwatch"` |
| Precision (−P) cannon | `MEC-A6P "Fang-P"` / `Type AP "Aggressor-P"`; `MEC-A8P "Tornado-P"` / `Type A1P "Lasher-P"`; `MEC-A9P "Hawk"` / `Type A2-P "Disabler"` | — | — |
| General launcher | `HD-70 "Lightning"` / `Type B "Bereaver"` | `HD-M50 "Thunderbolt"` (shared) | `ML-F "Downpour"` / `Type MF "Volley"` |
| Nuclear/anti-capital launcher | `HD-96 "Nova"` (shared) | `NL-E "Sunburst"` / `Type NE "Annihilator"` | `NL-F "Supernova"` / `Type NF "Obliterator"` |

Aligned with the reference item keys: `auto_cannon_basic` = `Fang`, `auto_cannon_rapid`
= `Tornado`, `auto_cannon_long_range` = `Hawk`, `auto_cannon_precision` = `Fang-P`,
`auto_cannon_rapid_precision` = `Tornado-P`, `auto_cannon_long_range_precision` =
`Hawk-P`, `auto_cannon_escort`/`_rapid`/`_long_range` = `Claw`/`Hurricane`/`Falcon`,
`missile_launcher_basic` = `Lightning`, `nuclear_launcher_basic` = `Nova`,
`missile_launcher_escort` = `Thunderbolt`.

**Implemented** (`main/data/modules/weapons_autocannons.lua`): each class carries its
role variants per direct instruction ("create all the known auto cannons and missile
launchers for the 3 classes") — a **general-purpose** model plus **rapid-fire** and
**long-range** ones, mirroring the reference's per-tier autocannon families — and the
**Patrol** tier also gets the reference's three **−P precision** models
(`Fang-P`/`Tornado-P`/`Hawk`), which share their base model's damage/range/reload but
climb in `CriticalOffense` (100→150) with upgrade instead of staying flat. The Escort
cannons (`Claw`, `Hurricane`, `Falcon`) carry a **single shared name** each (the
reference gives no Cylon counterpart); the Frigate rows keep the earlier original names
(the reference's Line page is empty — see the table above for the full set).

Only the **Patrol** variants carry published combat stats — the reference wiki only
tabulated its Strike-tier weapons; its Escort/Line pages are empty stubs, and no
other source carries real numbers for them. The Escort/Frigate entries are therefore
created with their identity/fitting fields but **no `dps`/range block**, per §0/§4's
"don't invent unconfirmed numbers" rule — the same treatment the Carrier mining
cannon already gets (flagged in §4). The Patrol variants' stats are real, including
the reference's `Accuracy` (400), `CriticalOffense` (100, or the −P curve 100→150) and
`Durability` (2500→5000): general cannon = the general light autocannon (DPS 11→22,
750 m max, 300 m optimal, 0.5 s reload); the rapid variant (DPS 13.75→27.5, 600 m,
250 m, 0.4 s); the long-range variant (DPS 9.16→18.33, 900 m, 350 m, 0.6 s). All
default to `arc = 75` (§2.8).

**Weapon projectiles live in their own hub (decided, per direct instruction)**: all
cannon/projectile rendering — the visible tracer and the firing sound — was extracted
out of `main/asteroid_hub.script` (which is about the asteroid field alone) into a
dedicated `main/shot_hub.script` / `main/shot_hub.go` game object. The hub draws a
**generic tracer** by default and lets the *firing cannon's own projectile data
override it*: `player_ship.script` forwards a weapon's `tracers` / `shot_speed` /
`shot_scale` / `shot_tint` / `shot_burst_stagger` fields in the `shot` message, and
any value present wins over the hub's own default (per direct instruction: "data
relating to that specific cannon or projectile should overwrite it when activated").

**Every cannon's burst visual + size/speed, applied universally (decided, revised — the
original Pass marked only the Patrol combat cannons)**: each shot from **any cannon —
combat or mining — now draws a three-streak burst** instead of one tracer, and every
streak is **much smaller and slower**: `tracers = 3`, `shot_scale = { 0.33, 0.33, 3.96 }`
(first cut to 33% of `shot_hub`'s default `2, 2, 24`, then halved again = 16.5% of
default) and `shot_speed = 300` m/s (the hub's 1200 default halved twice). This is
**purely cosmetic** — the fields only change how many streaks a shot spawns and how
they fly; damage and rate of fire are unchanged, and the server still resolves a single
shot. The streaks launch a quarter of the shot's own flight time apart, so the spacing
scales with range and they chase each other down the same path.

The first cut put these fields only on the general/rapid/long-range Patrol stat blocks,
which left the **Mining Cannons** (Gopher/…, which carry no combat-stat block at all)
and the Escort/Frigate cannons still firing a single full-size, 1200 m/s tracer — the
gifted W2 mining cannon is the one players actually fire early on, so the change looked
like it had not applied (per direct instruction: "the reduced speed and three bullets
should apply to all cannons"). The look is now stamped onto **every** entry by one
shared loop at the bottom of `weapons_autocannons.lua` (`for _, entry in
pairs(M.AUTOCANNONS) do … end`), so a cannon can never silently miss it and any cannon
added later inherits it for free. The values are stored as plain numbers rather than
`vmath` types because this data module is also loaded by the Nakama server (`economy.lua
→ session.lua → catalog.lua`), where `vmath` does not exist; `player_ship.script`
converts the triple to a real `scale` when it builds the `shot` message (with
`shot_hub.script`'s `to_scale()` as a fallback).

**"The changes aren't showing" — root-caused to a stale served bundle (and the
mining-cannon gap above)**: the three-tracer wiring *is* correct —
`weapons_autocannons.lua` sets `tracers = 3`, `shot_hub.script` schedules one tracer per
count, and `tests/shot_hub_harness.lua` proves it (three streaks, staggered a quarter of
the flight time apart, one firing sound). Two separate things kept it from being seen:
(1) the Mining Cannon gap above — the weapon players were firing had no burst/speed
fields; and (2) the **served HTML5 bundle was stale**. Inspecting the bundle's compiled
`main/data/modules/weapons_autocannons.luac` showed `AUTOCANNON_SHOT_SPEED = 600` and no
tracer fields on the mining cannons, i.e. it predated even the final 300 m/s reduction.
`ddev restart` does **not** rebuild this — the bundle is only regenerated by building
HTML5 **in the Defold editor**, so any rules change is invisible in the browser until
that build is redone (the same trap that caused an earlier "nothing works" report).
Separately, at the original 1200 m/s the projectile crossed to a 100-200 m asteroid in
0.08-0.17 s, so consecutive streaks were only ~0.02-0.04 s apart and — fired almost
straight ahead, i.e. nearly along the camera's view axis — overlapped on screen; the
slower 300 m/s doubles the flight time and therefore the gap, letting the streaks
separate.

**Implemented — Launchers and ordinance** (`main/data/modules/weapons_launchers.lua`,
`main/data/modules/ordinance.lua`; both new, per direct instruction "create all the
known ... missile launchers" + "create both files"). Launchers are the second weapon
subtype (§2.8), defined as a **general + nuclear pair per class**. Names shown as
Accord / Swarm (the reference gives a single shared name for `Nova` and `Thunderbolt`):

| Ship class | General missile launcher | Nuclear / anti-capital launcher |
|---|---|---|
| Patrol | **HD-70 "Lightning"** / **Type B "Bereaver"** (`missile_launcher_basic`) | **HD-96 "Nova"** (shared) — the reference's specialized anti-capital light launcher, whose role our `nuclear_launcher_basic` fills (reference Nova fires missiles; ours fires nuclear torpedoes) |
| Escort | **HD-M50 "Thunderbolt"** (shared, `missile_launcher_escort`) | **NL-E "Sunburst"** / **Type NE "Annihilator"** (`nuclear_launcher_escort` — no reference entry; original retained) |
| Frigate | **ML-F "Downpour"** / **Type MF "Volley"** (`missile_launcher_frigate` — reference Line page empty; original retained) | **NL-F "Supernova"** / **Type NF "Obliterator"** (`nuclear_launcher_frigate` — original retained) |

A launcher carries **no damage of its own** — `launcher_type = "general"` or
`"nuclear_launcher"` is all it holds; the payload lives in `ordinance.lua`, the single
shared ammo table §2.8 specified. Every row there is classified by `weapon_type`
(`cannon` / `missile` / `torpedo`) and `compatible_weapon`: cannon rounds and the four
real round families (HE / HESC / AP / HERT, with their §2.13B per-grade bonus
percentages) are `"ordinance_cannon"`; the missiles (interceptor, heavy, siege,
dumbfire rocket pod) are `"general"`; the **Nuclear Torpedo** is `"nuclear_launcher"`
only, so a general launcher cannot load it. The restriction is **enforced by data**,
not by separate tables — `ordinance.fits(weapon, round)` and
`launchers.accepts(launcher, round)` are the two helpers that express it (§2.8).
Launchers default to `arc = 75`. Since the reference published no launcher or torpedo
numbers at all (the launcher is just a mount; the missile figures sit on the
ammunition, and the nuclear torpedo has none), neither the launchers nor the nuclear
torpedo carry invented stats — flagged in §4. Ordinance carries the same two-faction
`faction_names` treatment (resolved by `ordinance.name_for`), though nothing displays
ordinance names yet (flagged in §4). Like the cannons, one entry per item — the
faction difference is the name only, exactly as §2.1.2's ship `faction_skins` keep one
entry per ship.

**Mining cannon naming convention (decided, revised)**: mining-type cannons now also
follow the reference's own names where it publishes them (same direct instruction),
and keep original mining/prospecting names where it doesn't:

| Ship class | Mining cannon name | Notes |
|---|---|---|
| Patrol | **Gopher** / **Gouger** | `mining_cannon_basic` — the reference's "Gopher"/"Gouger" Light Mining Cannon; two-faction names |
| Escort | **Mole** | `mining_cannon_escort` — the reference's "Mole" Medium Mining Battery; a single shared name, no Cylon counterpart |
| Frigate | **Speculator** (reserved) | No Frigate-tier cannon exists yet, and the reference names none |
| Carrier | **Prospector** (reserved) | No Carrier-tier cannon exists yet, and the reference names none |

All four tiers are defined in `weapons_autocannons.lua`: **Gopher** carries the
reference's published figures (DPS 5→16, Mining ×5, 600 m, 250 m optimal, 0.5 s
reload); the reference names no numbers for the Escort-tier **Mole**, and none at all
for the Frigate/Carrier tiers, so those keep their placeholder figures (flagged in §4).

**Weapons belong to exactly one ship class each (decided)** — per direct
clarification: a cannon isn't a generic item that happens to carry a class-flavored
name, it's built *for* that class specifically. The starting cannon and Gopher are
both **Patrol-only** (`ship_class = "Patrol"` in `weapons_autocannons.lua` — a **singular**
field holding a plain string, not the plural `ship_classes = { "Patrol" }` list it
briefly was, and no longer the earlier
`ship_classes = { "Patrol", "Escort", "Frigate", "Carrier" }` "fits anywhere for now"
placeholder before that). The Escort and Frigate combat cannons and
Miner/Speculator/Prospector each carry their own entry
(`ship_class = "Escort"`/`"Frigate"`/`"Carrier"`) rather than one shared cannon
fitting every class. This
singular-string shape is
specific to auto cannons, where the "exactly one class" rule is decided — other
module types (e.g. the Asteroid Analyser, `computer_modules.lua`) still use the
plural `ship_classes` list from the general shared-fields schema (§3.1) above, since
they weren't part of this decision. **Now enforced in the Shop/Owned lists** — see
§2.8.5.

**New Computer module: Asteroid Analyser** (decided) — `main/data/modules/computer_modules.lua`, `behavior = "active"` (one-shot
trigger, matching the `activate_scanner` (P key) binding already reserved in §2.10 —
proposed, flag if it should be passive instead). Its scan covers every asteroid
within **`range_m = 400 m` of the ship** (per direct instruction — set explicitly to
400 m, no longer tied to a ship's visual range), revealed after `scan_time_s = 2`. It
is a **normal, separately fitted
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
  first, for real — a flat placeholder Tope price, §2.6.1 — through the
  confirmation dialog, §2.8.6); drag an installed marker off to uninstall it back to
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
- Clicking a **For Sale** ship purchases it — for real, spending a flat placeholder
  Tope price (§2.6.1) through the confirmation dialog (§2.8.6) — and selects it as
  active on success.
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
  the `.model` file otherwise, so it would have silently gone unbuilt. Originally
  just enough to prove the asset is genuinely valid, with no camera/render setup at
  all (§4's original note here). **Since repurposed** (§2.8.9): this is the exact
  same instance, now also carrying `main/ship_preview.script` (a slow constant
  rotation) and moved from the world origin out to `(100000, 0, 0)` — the off-world
  position `render/custom.render_script`'s dedicated offscreen pass renders it from,
  feeding the Ships tab's live ship detail preview. Still not a flight-mode/3D scene
  (there's still no camera/render setup for THAT, §4) — this one's sole purpose is
  the ship preview render target.
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

**Escort 1's first real 3D model, and a top-down plan extracted from it (decided,
implemented)** — per direct instruction ("create a 3D model of the barracuda"), same
approach as Patrol 1's above: a rudimentary, wholly original 3D hull plus a top-down
plan derived directly from the same geometry, replacing the old `<TBD>` model state.
- **The model**: `main/models/escort_1/escort_1.gltf` — 22m long, 5m beam, 4.4m tall
  including the bridge/cabin (26 unique vertices, 44 triangles, flat shaded, no
  texture) — "one size class up from Patrol 1," the only actual design intent
  confirmed so far for Escort-tier scale (§2.1.2/§4, still placeholder proportions,
  same caveat Patrol 1's own dimensions carry). A 9-point hull outline rather than
  Patrol 1's 7-point curve — boxier, more parallel-sided amidships, meant to read as
  a distinct "first real combat hull" silhouette at a glance rather than just a
  scaled-up boat. Generator script: `tools/build_escort1_model.py` (needs Pillow;
  none was installed in this environment, so a throwaway scratchpad venv was created
  and removed afterward rather than touching system Python).
- **Material**: `/builtins/materials/model.material` (the plain/unlit one, same
  choice §2.8.9 made for Patrol 1 and for the same reason — self-contained default
  lighting baked into the material, no external `light` resource needed).
- **Wired in**: `main/data/ships.lua`'s `faction_skins.accord/swarm.model` for
  `escort_1` now point at `/main/models/escort_1/escort_1.model` (both factions
  share this one hull, same as Patrol 1 — distinct faction art is still open, §4).
- **A preview instance** (`escort_1_preview`, a fifth embedded object in
  `main/main.collection`, bare `model` component) added for the same reason as
  Patrol 1's original one: proves the mesh/model resource chain actually builds,
  since nothing else references a `.model` file as a structured resource dependency
  (`ships.lua`'s own reference is just a plain Lua string, invisible to `bob.jar`'s
  dependency scanner).
- **Follow-up — wired into the live 3D preview too (decided)**: the user tried the
  Barracuda's detail modal and reported the preview as blank (the honest
  "not available yet" placeholder this ship correctly had at first, since only
  Patrol 1's model was hooked up). Extended §2.8.9's single-ship preview to support
  any number of ships **sharing one render target/camera** rather than needing one
  per ship: moved `escort_1_preview` to the exact same off-world anchor as
  `patrol_1_preview` (both now at `(100000, 0, 0)`) — since the offscreen pass's
  camera is fixed and looks at that one point, whichever rig's `model` component is
  *enabled* is the one that actually shows up in the render, so only one is ever
  enabled at a time. `main/outpost.gui_script` gained a `PREVIEW_RIGS` table (model
  path → rig instance id); `show_ship_detail` now looks up the clicked ship's model
  path in it and, on a match, `msg.post`s `"enable"` to that rig's `#model` and
  `"disable"` to every other rig's, before assigning the shared `"ship_preview"`
  texture — so opening a different ship's modal swaps which mesh the same render
  target is actually showing. No render script changes needed at all. Also gave
  `escort_1_preview` its own `main/ship_preview.script` component (it wasn't
  rotating before, since it had no script yet).
- **Verified**: the top-down PNG was visually inspected before finalizing (sent to
  the user); both outpost-screen test harnesses re-run with new assertions (Escort
  1's modal now gets the `"ship_preview"` texture and no longer shows the
  no-preview fallback text; Patrol 1's modal still gets it too afterward — a
  regression check that switching rigs for one ship doesn't leave another
  ship without its own) — all passing; a real `bob.jar build` compiled the new/
  changed `.gltf`/`.model`/`.collection`/`.gui_script` cleanly both times (before
  and after the live-preview follow-up). **Still not independently confirmed
  on-screen**, same honest caveat as §2.8.9's own original verification note — the
  automated browser click-through remains blocked in this environment (see there
  for the full description of that limitation); a fresh local HTML5 bundle with
  this fix was rebuilt and redeployed to the same local dev server either way, so
  the user's own next manual check will see it.
- **Real bug, this time reported from the user's own real browser click (not the
  automation limitation above) — clicking a ship in either list did nothing at
  all.** Root cause: `show_ship_detail`'s rig-switching `msg.post` calls (added by
  the live-preview follow-up just above) ran **before** the loop that actually
  `gui.set_enabled`s every modal node — so if a `msg.post` call ever threw (the
  real engine throws on a bad/nonexistent message address; it doesn't silently
  no-op), the whole function aborted right there and the modal's nodes were never
  enabled at all. Indistinguishable from "nothing happens" at the click. Fixed two
  ways: (1) reordered `show_ship_detail` so the modal is opened (state set, every
  node enabled, button labels/visibility decided) **first**, with the rig-switching
  block - the riskier, "bonus visual effect" part - moved after, and wrapped in
  `pcall` so it can never again take the whole modal down with it; (2) also
  corrected the message address itself to `"/" .. rig .. "#model"` (a leading `/`,
  root-relative - the likely actual mistake). This is exactly the kind of bug a
  no-op `msg.post` test stub can never catch, so both harnesses' stub was upgraded
  to behave like the real engine here: it now throws for any address that isn't
  `"."`, a bare `"#fragment"`, or one of the actual embedded instance ids in
  `main.collection` - re-running both harnesses under this stricter stub confirms
  the reordered function still opens the modal correctly either way. A real
  `bob.jar build` also re-confirmed afterward, and a fresh local HTML5 bundle was
  rebuilt/redeployed with this fix.
- **The actual missing piece for the live render, found after the modal's preview
  panel came back as a plain white square (the classic "texture name didn't resolve,
  engine fell back to its default white texture" symptom) once the click-through bug
  above was fixed enough to see it at all.** §2.8.9's original research confirmed
  the `.render` file's own `render_resources { name path }` mechanism (real, via
  `RenderPrototypeDesc`'s compiled fields) and took at face value a fetched doc
  claim that `gui.set_texture(node, "name")` could reference that name directly with
  "no per-`.gui`-scene texture declaration needed" — **that specific claim was
  wrong** (or for a different engine version). Checked further and found the real
  mechanism by the same direct-inspection method as before: `main/outpost.gui`'s own
  compiled schema (`Gui$SceneDesc`) has a **separate, dedicated `resources` field**
  (repeated `{ name, path }`, distinct from the existing `textures` field) — a GUI
  scene has to declare the render target as one of ITS OWN resources too, the same
  declarative shape as the `.render` file's own list, not just rely on the global
  render-pipeline declaration. Added `resources { name: "ship_preview" path:
  "/render/ship_preview.render_target" }` to `main/outpost.gui` alongside its
  existing `textures { ... }` blocks — `gui.set_texture(node, "ship_preview")` in the
  script needed no changes, it was already correct once this was in place.
- **Verified**: a real `bob.jar build` compiled the new `resources {}` block
  cleanly (confirming the field/schema guess was right, the same way every other
  hand-derived protobuf shape this session was confirmed); both harnesses re-run
  with no regressions (this is a pure `.gui`-file addition, invisible to their
  stubbed `gui` table); a fresh local HTML5 bundle rebuilt/redeployed. Still
  pending the user's own on-screen confirmation that the ship itself now actually
  renders inside the preview panel, not just that the white-square symptom's likely
  cause has been addressed — same automated-click-through limitation as before.

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
- **The mining cannon (the Patrol-tier one — "Prospector", then "Digger", now
  **Gopher**; see the mining naming-scale table above) redesigned again**,
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
  one-off style just for this icon.
- **Data**: each `main/data/modules/*.lua` entry gets an `icon` field (the atlas
  region name). Ship-agnostic — the icon is a property of the *module*, not the ship
  or slot.
- **Switched to hand-provided "Octagon" icon set (decided)**: per direct instruction,
  a batch of new octagon-shaped icons (`main/images/icons/Octagon *.png`) replaces the
  procedurally-generated ones for both the empty-slot outlines and the two auto-cannon
  types — these are supplied finished art, not drawn by
  `tools/build_module_icons.py` (that script now just lists them, `MANUAL_ICONS`, so
  re-running it to regenerate the *other* icons doesn't drop these from
  `icons.atlas`). Mapping:
    - Empty slot, by type: weapon → `"Octagon W"`, computer → `"Octagon C"`,
      engine → `"Octagon E"`, hull → `"Octagon H"` — `outpost.gui_script`'s new
      `SLOT_EMPTY_ICON` table, replacing the old `"slot_" .. type .. "_empty"` naming.
    - A mining-type cannon (Gopher and its Escort/Frigate/Carrier counterparts) →
      `"Octagon Cannon Asteroid"`.
    - The normal ordinance combat cannon (`auto_cannon_basic`) →
      `"Octagon Cannon Spaceship"`.
    - `"Octagon Empty.png"` was also supplied but nothing maps to it yet — listed in
      the atlas/`MANUAL_ICONS` for future use, not wired to any slot/module (§4 — don't
      guess its purpose).
  - Asteroid Analyser (the one computer module) keeps its old procedurally-generated
    `"asteroid_analyser"` icon — no Octagon-prefixed replacement was provided for it.
- **Component icon display size pinned to the old placeholder size (decided)**: the
  hand-provided Octagon icons are much higher-resolution than the old
  procedurally-generated placeholders (1400×1400 for the four empty-slot icons,
  1800×1506 — not even square — for the two Cannon icons and the unused "Octagon
  Empty", vs. the old flat 128×128 canvas every generated icon used), per direct
  instruction the on-screen icon must still render at the same size as before. Fixed
  by explicitly forcing `gui.set_size_mode(icon, gui.SIZE_MODE_MANUAL)` right after
  creating the marker's icon node in `build_markers` (`main/outpost.gui_script`) — so
  it always renders at `ICON_SIZE` (48×48) regardless of the assigned texture's own
  pixel dimensions/aspect ratio, rather than risk `SIZE_MODE_AUTO` inflating (and, for
  the non-square Cannon icons, distorting the layout around) the node to match the
  source image.
- **Octagon icon files downsized for a smaller build (decided)**: the hand-provided
  originals were far larger than needed for a 48×48 on-screen icon (1400×1400 for the
  four empty-slot icons, 1800×1506 for the two Cannon icons and "Octagon Empty" — over
  1MB each, ~7.1MB total). Per direct instruction, downsized in place with
  `sips -Z 128` (matches this project's existing 128px icon convention,
  `tools/build_module_icons.py`'s `SIZE`) — the non-square Cannon/Empty icons scaled
  proportionally (now 128×107, same aspect ratio as before) rather than forced square,
  so this doesn't add any distortion beyond what square-node stretching (the
  `SIZE_MODE_MANUAL` fix above) already did. Total dropped from ~7.1MB to ~96KB
  (>98% smaller) — matters for this being a Poki/HTML5 game where the whole build is
  downloaded up front. Full-resolution originals kept in the session scratchpad (not
  checked into the project) in case higher-res source art is ever wanted for something
  else later.
- **Follow-up correction — icon size increased to match the grey marker box, not the
  old small icon (decided)**: per direct instruction, "the same size as the current
  placeholder" (above) actually meant the grey/colored octagon marker box itself
  (`box`, `MARKER_SIZE`, 74×74, §2.8.3) — the thing an empty slot's grey octagon is
  standing in for — not the old small 48×48 icon footprint. The Octagon art is a
  complete octagon graphic in its own right (its own border/fill baked into the
  image), meant to cover the marker's whole visible face rather than float as a small
  badge in its middle. `ICON_SIZE` changed from a fixed 48×48 to just `MARKER_SIZE`
  (74×74) so the two always stay in sync; the `SIZE_MODE_MANUAL` fix above still
  applies unchanged (still needed, just pinning to the new bigger `ICON_SIZE` instead
  of the old one) — the Octagon PNGs' non-square/high-resolution originals still can't
  be allowed to dictate the node's actual rendered size.
- **"Octagon Cannon Asteroid" rotated 45° (decided)**: per direct instruction, the
  image itself (`main/images/icons/Octagon Cannon Asteroid.png`, by this point
  user-cropped down to a square 99×99 — see the file-size bullet above) was rotated
  45° in place — `magick "…" -background none -rotate 45 -gravity center -extent
  99x99 "…"` (ImageMagick), transparent fill for the corners the rotation exposes,
  re-cropped back to the original 99×99 canvas rather than left to expand — the
  artwork has enough margin around the octagon shape that nothing gets clipped by
  cropping back to the original bounds. Pure asset edit, no code change; the
  pre-rotation original is kept in the session scratchpad backup alongside the other
  full-resolution originals.
- **Recolored by slot type (decided)**: per direct instruction, the four per-type
  empty-slot icons no longer all share the same gold - weapon (`Octagon W.png`) stays
  gold/amber (hue ≈49° on the HSL wheel, unchanged), and the other three were
  hue-rotated in place with ImageMagick (`magick <file> -modulate 100,100,<hue>`,
  100=no shift, 1 unit≈1.8°) to: **engine → red** (`Octagon E.png`, modulate hue 73,
  landed ≈358°), **computer → blue** (`Octagon C.png`, modulate hue 6, landed ≈235°),
  **hull → green** (`Octagon H.png`, modulate hue 139, landed ≈119°). A pure hue
  rotation rather than a flat recolor, so each keeps the exact same neon-glow
  gradient (soft halo + bright core + dark rim) the gold version had, just shifted to
  a different hue family. `Octagon Empty.png` and both `Octagon Cannon *.png`
  (weapon-type, filled-slot icons) are unaffected - explicitly out of scope, per
  direct instruction to leave weapon icons as they are. Pre-recolor gold copies of
  `Octagon E/C/H.png` kept in the session scratchpad backup.
- **Shop/Owned component cards color-coded by type too (decided)**: per direct
  instruction, extended the same weapon=gold/engine=red/computer=blue/hull=green
  scheme from the slot icons above to the Fitting tab's Shop (available for sale) and
  Owned (player's spares in storage) card lists (`main/outpost.gui_script`) — a new
  `TYPE_CARD_COLOR` table (solid, dark-toned versions of the same four hues, since
  these are plain colored card backgrounds behind light text, not glow-icon art) is
  looked up by `module.type` in `shop_rows`/`owned_spare_rows` and passed through
  `build_card_list`'s existing `row.color or CARD_COLOR` fallback (no changes needed
  there — it already supported a per-row override color, previously only used for
  the Ships tab's "current ship" highlight). A module whose type isn't one of the
  four falls back to the old flat `CARD_COLOR` rather than guessing a color. Ships
  tab lists (For Sale/Owned Ships) are untouched — the request was about components,
  not ships.
- **Verified**: both outpost-screen test harnesses re-run with no regressions (their
  stub `gui` table needed `set_texture`/`play_flipbook` no-ops added, matching the
  real API used to assign an atlas image to a runtime-created box node); a real
  `bob.jar build` confirmed the new atlas/textures block/`.gui_script` changes compile
  through Defold's actual texture pipeline, not just well-formed data. Re-verified
  again after the Octagon-icon switch above, same two harnesses + a real build, no
  regressions.

#### 2.8.2 Module upgrades (decided — per-instance)

Direct question that surfaced this: if a player upgrades a weapon and then unloads it
at an outpost, does the upgrade survive for next time? **Decided: yes — upgrades are
per physical INSTANCE, not shared across every copy of a type.** Two owned copies of
the same cannon can be at different upgrade levels; uninstalling one never resets it.

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
  of just adding a type key to a set — buying a second copy of a cannon is now a real, separate,
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
  square too). Originally sized to comfortably fit a smaller 48×48 module icon plus
  its corner labels; `ICON_SIZE` was later changed to match `MARKER_SIZE` exactly
  (§2.8.1's "icon size increased to match the grey marker box" follow-up), so the icon
  now covers the marker's whole face and the corner labels sit on top of it instead.
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
- **Follow-up correction — rotated so flat edges face top/bottom/left/right (decided)**:
  with 8 perimeter vertices evenly spaced starting at the default 0° (3 o'clock),
  the octagon had a *vertex* (point) at the top/bottom/left/right and a flat edge on
  each diagonal — per direct instruction, this needed to be the other way around,
  flat edges at top/bottom/left/right. Fixed by rotating the whole node 22.5° (half
  the 45° gap between 8 evenly-spaced vertices) via `gui.set_rotation(node,
  vmath.vector3(0, 0, 22.5))`, added at the end of `new_octagon_node` in
  `main/outpost.gui_script` — this shifts every vertex onto a diagonal, leaving a
  flat edge centered on each of the four axes. Applies to both `box` and `border`
  for every marker, same as the rest of `new_octagon_node`. **Verified**: both
  outpost-screen test harnesses' stubbed `gui` table given a `set_rotation` no-op
  (records `n.rotation`, mirroring the other cosmetic setters) and re-run with no
  regressions; a real `bob.jar build` still compiles cleanly.

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
  Patrol-class starting ship includes the starting cannon/Gopher/Asteroid Analyser and excludes
  Mole/Speculator/Prospector. This incidentally shrank the real Shop list back down
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
  - The message names the specific item/slot/ship involved (e.g. "Buy MEC-A6 'Fang'
    and install it in W2?" / "Swap MEC-A6 'Fang' into W2, replacing Gopher?" / "Switch your
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
  "Sell MEC-A6 'Fang'?" / "Sell Barracuda?" — Cancel does nothing, Confirm actually removes it.
- **Verified**: `outpost_harness.lua` gained a case selling a component spare (via
  its Sell button + dialog) and confirming it's actually gone, not just uninstalled.
  `outpost_harness2.lua` gained cases confirming the Sell button is absent on the
  only owned ship, appears on both ships once a second is bought, actually removes
  a sold ship via the dialog, and confirming `session.sell_ship` itself refuses to
  sell the last remaining ship even if called directly (not just a UI-level guard).
  A real `bob.jar build` compiles cleanly.

#### 2.8.8 Shop/Owned type-filter buttons (decided)

Per direct instruction: **"on the list of available components and offload
components put a filter where clicking each of the component type filters the list
by the component such as engine hull computer and weapon."** Read as: one shared
filter (not two independent ones) that narrows *both* the Fitting tab's Shop
(available for sale) and Owned (spares in storage) lists to a single module type at
a time.

- **UI**: four new buttons — Weapon/Computer/Engine/Hull — added to `main/outpost.gui`
  as a row directly above the Shop heading (`filter_weapon/_computer/_engine/_hull`
  + matching `_label` text nodes, x-centers 1110/1330/1550/1770, same 880-wide span as
  the Shop/Owned panels). To make room without touching `PANEL_HEIGHT` or any
  scroll-clipping math, `shop_heading`/`shop_panel`/`owned_heading`/`owned_panel`
  were all shifted down 45px (845→800, 715→670, 575→530, 445→400) — this exactly
  matches the Ships tab's own `forsale_heading`/`forsale_panel`/
  `ownedships_heading`/`ownedships_panel` y-positions (800/670/530/400), which
  already left this same gap unused above them, so the shift aligns the two tabs'
  vertical rhythm rather than introducing a new one.
- **Toggle, not two states**: clicking a type sets `self.type_filter` to it; clicking
  the *same* button again clears it back to `nil` (show everything) — no separate
  "All" button needed. Buttons recolor via a new `FILTER_ACTIVE_COLOR` table (bright
  version of each `TYPE_CARD_COLOR` hue, §2.8.1's card-coloring bullet) when their
  type is the active filter, dim `TYPE_CARD_COLOR` otherwise — same
  active/inactive-highlight pattern as the main Overview/Fitting/Ships tab bar.
- **Filtering itself**: `shop_keys`/`owned_spare_instances` (and the `shop_rows`/
  `owned_spare_rows` built from them) take an optional `type_filter` param, ANDed
  onto the existing ship-class fit check — `main/outpost.gui_script`. The mouse-wheel
  scroll-clamp handler was updated to pass `self.type_filter` through too, so
  scrolling still clamps correctly against the *filtered* row count, not the full one.
  `self.type_filter` is deliberately NOT reset when leaving/re-entering the Fitting
  tab — a standing preference for the session, same as the per-panel scroll offsets.
- **Real bug found and fixed by the harness before it ever reached a build**: the
  toggle was first written as `self.type_filter = (self.type_filter == type_name) and
  nil or type_name` — the classic Lua `and/or` ternary idiom, which silently breaks
  whenever the "true" branch value is itself `nil` (or `false`): `X and nil` is
  always `nil`, so `nil or type_name` always evaluates to `type_name`, regardless of
  `X`. In practice this meant clicking an already-active filter button did nothing —
  it looked selected forever and could never be cleared. Caught immediately by this
  feature's own new harness case (click a filter, assert it's active; click the same
  button again, assert it's cleared — the second assertion failed) and fixed with a
  plain `if/else`.
- **Verified**: `outpost_harness.lua`/`outpost_harness2.lua` updated with the new
  `filter_*` stub nodes at the real file's (shifted) coordinates; `outpost_harness.lua`
  gained a new case exercising the filter end-to-end (narrows Shop to just
  computer-type items, confirms it's strictly smaller than the unfiltered list,
  clears back to the full list on a second click) — this is what caught the
  and/or bug above. Both harnesses re-run clean after the fix; a real `bob.jar build`
  confirms the shifted/added `main/outpost.gui` nodes compile.

#### 2.8.9 Ship detail modal + ship preview (decided — live 3D render attempted, rolled back to a static image)

Per direct instruction: **"in the ships tab when you click the ship rather than
confirming the purchase, show a modal with a 3D rendering of the ship along with the
stats. At the bottom of the modal put a Purchase link and a Cancel link. If the ship
is already purchased put a Select link and a Cancel link."** Clarified with the user
before building: the 3D render had to be a genuine **live** render (not a reuse of
the existing static top-down PNG), and the modal's Purchase/Select button acts
**immediately** — no follow-up plain confirm dialog (§2.8.6) — except insufficient
Tope on a Purchase, which still falls back to that plain notice-only dialog.

This is the first 3D content ever rendered in this project (every screen before this
was pure 2D GUI), so it needed a real render-to-texture pipeline, not just another
GUI/script edit — considerably bigger in kind than anything else this session. Went
through `EnterPlanMode` given that scope, and researched the exact engine mechanism
by extracting and reading the real compiled files this project's own `bob.jar`
bundles (not guessing/paraphrasing docs) before writing anything.

**A. Ship detail modal** (`main/outpost.gui`/`.gui_script`) — new nodes
`ship_detail_scrim/panel/name/preview/stats/primary/primary_label/cancel/cancel_label`,
same "modal gates all other input" pattern as the existing `confirm_*` dialog, just a
bigger panel. Clicking a Ships-tab card (`ship_forsale` or `owned_ship`) now calls
`show_ship_detail(self, ship_id)` instead of `show_confirm(...)` directly:
- Stats (`ship_stats_text`) are a curated real subset of `main/data/ships.lua`'s
  `data`/`components` (Hull Points, Armor, Speed/Boost, FTL Range, Power, Sensor
  Range, W/C/E/H slot counts) — same numbers the Overview tab's fitting breakdown
  already reads, not invented.
- Button state: not owned → Purchase; owned, not active → Select; owned AND already
  active → no primary button at all (view-only + Cancel) — this used to be a silent
  no-op click on the card itself; now it's an explicit state instead of a dead end.
- Purchase/Select act immediately in `on_input`'s new `self.ship_detail` gate.
  Insufficient Tope on Purchase closes the modal and falls back to the existing
  plain `show_confirm` notice.
- Sell (§2.8.7) is unchanged — still the card's own inline Sell button + the plain
  confirm dialog, untouched by this feature.

**B. Live 3D ship preview** — confirmed directly from this project's own `bob.jar`
(extracted and read the actual compiled files, not assumed):
- `game.project` had no `[bootstrap] render` key at all before this, so every screen
  implicitly used `/builtins/render/default.render` →
  `/builtins/render/default.render_script`. Added `render = /render/custom.renderc`;
  `render/custom.render_script` starts as an **exact copy** of that real default
  script (pulled from `bob.jar`, not reconstructed from memory) with one addition —
  every other screen's rendering is unaffected.
- `render/custom.render` declares a `render_resources { name: "ship_preview" path:
  "/render/ship_preview.render_target" }` entry — confirmed via
  `RenderPrototypeDesc`'s actual compiled protobuf fields that this is a real,
  current mechanism (not newer-version-only) for exposing a named render target as a
  plain texture usable anywhere by name, including `gui.set_texture(node,
  "ship_preview")` with **no per-`.gui`-scene texture declaration needed**.
- `render/ship_preview.render_target` — one 512×512 `TEXTURE_FORMAT_RGBA` color
  attachment + a matching `DEPTH_STENCIL_FORMAT_D32F` depth attachment (both enum
  names confirmed the same way, via `RenderTargetDesc`'s compiled fields).
- `render/custom.render_script`'s added `draw_ship_preview` binds that target
  (`render.set_render_target("ship_preview")` — confirmed via Defold's own docs to
  accept the resource name directly, no separate handle-fetch call needed), clears
  it, sets a **fixed** perspective look-at view/projection computed once in `init()`
  (the rig only rotates, never moves), draws the `model` predicate into it, then
  restores `render.RENDER_TARGET_DEFAULT` before the rest of the frame proceeds
  exactly as before. Deliberately does NOT use a `camera` game-object component for
  this — that mechanism drives the *main* on-screen `camera_world` globally
  (`set_camera_world`/`camera.get_cameras()` in the real default script), and
  hijacking it would silently break any future flight-mode 3D content.
- **Preview rig**: repurposed the existing `patrol_1_preview` embedded instance in
  `main/main.collection` (originally added, per this same section's earlier history,
  purely so `bob.jar` would validate the model/mesh resource chain, with no
  camera/render setup at all) — moved from the world origin to `(100000, 0, 0)`, far
  outside the normal on-screen stretch-projection bounds so it never appears in the
  regular pass, and gave it a new `main/ship_preview.script` (a constant slow
  Y-rotation, `go.set_rotation` each frame — the only thing that changes; position is
  fixed).
- **Lighting - changed the approach after checking, not guessed**: `patrol_1.model`
  originally referenced `/builtins/materials/model_lit.material`, confirmed (by
  reading its actual `.fp` shader) to need real per-frame light data from engine
  `light` components via a `LightBuffer` uniform. Checking further, this project's
  `bob.jar` has **no `.light` resource builder/proto at all** for a fixed-schema
  light file — lights in this engine version are authored as a generic, schema-less
  `DdfStruct` (key/value struct), which would have been genuinely high-risk to
  hand-author correctly with no live editor to verify against. Switched
  `patrol_1.model` to the plain `/builtins/materials/model.material` instead — its
  own `.fp` shader (also read directly) has a **self-contained default light
  constant baked into the material** (a `"light"` vertex constant defaulting to
  `(1,1,1,1)` as a world-space light position, plus a hardcoded 0.2 ambient term) and
  needs no external light component or resource at all. Nothing else in the project
  referenced `patrol_1.model`'s material choice, so this had no other side effects.
- **Modal wiring**: `show_ship_detail` sets `gui.set_texture(preview_node,
  "ship_preview")` only when the clicked ship's `faction_skins[faction].model`
  matches `PREVIEW_MODEL_PATH` (currently only Patrol 1 — Escort 1 is still `model =
  "<TBD>"`, §4); any other ship shows the existing `"Octagon Empty"` icon as an
  honest placeholder plus a note in the stats text, rather than a stale or faked
  render.

**Verified — and an honest limitation**:
- Both outpost-screen test harnesses extended with the new `ship_detail_*` stub
  nodes and full behavioral coverage of section A (Purchase/Select/just-Cancel
  states, immediate action, insufficient-funds fallback) — all passing, no
  regressions to any earlier case.
- A real `bob.jar build` compiled every new/changed file cleanly on the first real
  attempt — `.render_target`/`.render`/`.render_script`/the edited `.collection`
  and `.model`/`main/outpost.gui` — confirming the hand-derived protobuf schemas
  were read correctly.
- Went further than a compile check for this specific task, since a wrong runtime
  Lua call here (unlike everything else this session) would compile fine but
  silently render nothing: built a real local HTML5 bundle (not just the remote
  `resolve build` validation used elsewhere) and loaded it in the already-connected
  Chrome browser. The engine boots cleanly with **zero console errors** across
  multiple full reloads, which is itself meaningful evidence — the custom render
  script's new offscreen pass runs unconditionally every single frame starting
  immediately at boot (before any navigation), so an uncaught Lua error in it (e.g. a
  wrong render API call) would have broken the *entire* render pipeline and left the
  GUI unrendered; instead the start screen renders correctly every time.
  **However**: clicking through to the Ships tab to actually SEE the modal and its
  live texture could not be completed — synthetic clicks (both the browser tool's
  own click action and manually-dispatched pointer/mouse event sequences with
  correct focus, coordinates, and down/move/up ordering, verified via direct page JS)
  did not register with the game's canvas, for reasons that didn't resolve after
  reasonable troubleshooting (checked for blocking overlays, focus state, coordinate
  scaling, and event ordering — none explained it). This reads as an
  automation/environment limitation specific to driving this WASM/SDL canvas via
  synthetic input, not a defect surfaced by my changes. **Not yet independently
  confirmed**: that the ship model actually appears correctly framed/lit inside the
  live texture (as opposed to rendering successfully but off-frame, or some other
  visual issue the "nothing crashed" evidence above can't rule out). Flagging this
  plainly rather than claiming full verification — the user can check this directly
  in their own browser (real mouse input, not simulated) at
  `http://127.0.0.1:8934/index.html`.

**Final outcome — rolled back to a static image (decided)**: the user did check in
their own real browser, and reported the preview as a plain white square — the
classic "texture reference didn't resolve" symptom. Two further fix attempts (a
`main/outpost.gui`-level `resources {}` declaration for the render target, found via
the same direct-file-inspection method as the rest of this section; then, when that
still didn't work, offering to keep debugging vs. fall back) did not resolve it, and
with no way to get real-time visual feedback in this environment (the click-through
limitation above), the user chose to abandon the live-render approach rather than
keep guessing at an increasingly narrow, hard-to-verify runtime API. **Rolled back
entirely**:
- `game.project`'s `[bootstrap] render` key removed (back to the implicit engine
  default render pipeline).
- `render/custom.render`, `render/custom.render_script`, and
  `render/ship_preview.render_target` deleted.
- `main/outpost.gui`'s `resources { ship_preview }` block removed; `main/ship_preview.script`
  deleted.
- `patrol_1_preview`/`escort_1_preview` in `main/main.collection` reverted to bare
  `model`-only instances (their original, pre-§2.8.9 form, still off-world so they
  never appear in the normal on-screen pass) — kept, not deleted, since they still
  serve their ORIGINAL purpose of proving each ship's mesh/model resource chain
  actually builds (§2.9's own note on `patrol_1_preview`'s original purpose).
- **Replaced with**: the exact same reliable mechanism the Fitting tab's
  `ship_visual` node already uses — a `PREVIEW_IMAGES` table in
  `main/outpost.gui_script` mapping each ship's model path to its own
  `{texture, image}` atlas reference (`patrol_1`/`patrol_1_topdown`,
  `escort_1`/`escort_1_topdown`, both already-existing atlases/PNGs from this
  ship's own §2.1.2/§2.9 model-building work) — `gui.set_texture` +
  `gui.play_flipbook`, the same pair of calls the marker icons already use, no
  render pipeline involved at all. A ship with neither model nor image still shows
  the honest "no preview image available" placeholder.
- **Verified**: both outpost-screen test harnesses updated (Escort 1's/Patrol 1's own
  preview atlas+image assertions replace the old `"ship_preview"` texture checks) and
  re-run with no regressions; a real `bob.jar build` compiled the rollback cleanly; a
  fresh local HTML5 bundle rebuilt/redeployed. This is a plain static-texture
  mechanism already proven to work elsewhere in this same screen, so — unlike the
  live-render attempt — this doesn't carry the same "still needs the user's own
  on-screen confirmation" caveat to the same degree, though the user's own visual
  check is naturally still the final word.

**Second attempt, after fixing browser-automation click-through (decided — settled,
not attempting a third time)**: once the click-testing problem itself was root-caused
and fixed (§3.5), the live 3D render was rebuilt from scratch (same design as above:
`render/custom.render`+`.render_script`, the `ship_preview.render_target`, the
`resources {}` GUI declaration, off-world rigs with a rotation script) to actually
verify it with real visual feedback this time, rather than guessing blind. Compiled
cleanly again — but the moment the ship detail modal was actually opened for real,
**the entire browser tab froze solid**, needing a forced navigation (and, once, a
fresh tab) to recover — not a cosmetic bug like the white square, an actual hang. This
is a categorically more serious failure than last time: it means a GUI scene
referencing an offscreen render target as a texture (`resources { path:
"*.render_target" }`) is not just poorly-documented in this engine build, it's
**unsafe** — plausibly a genuine native-level deadlock (e.g. a resource-readiness wait
that never resolves) rather than anything reachable/fixable from script or GUI-file
content. Rolled back a second time, identically to the bullet above. **Settled**: the
static top-down image is the final approach for this feature, verified working
end-to-end with real (automation-fixed) clicks — Ships tab → both ships' detail
modals open correctly with their own art/stats/buttons, Cancel closes cleanly, no
errors, no freeze. Not attempting the live 3D render a third time — two independent
attempts, the second one actively breaking the page rather than just looking wrong,
is enough signal that this isn't a good use of further time in this engine build.

**Third attempt, per direct instruction to "try again" (decided — working, live
3D render shipped)**: despite the above, the user asked again to "show a 3-D
rendering of the ship when the player select the ship." Given the second attempt's
real freeze, flagged the risk explicitly and asked how to proceed
(`AskUserQuestion`); the user chose **"Try a different technical approach"** —
not a blind retry. New design, deliberately avoiding both suspect mechanisms from
attempt two at once (a GUI `resources {}` block referencing a `.render_target`, and
`msg.post` from a GUI script to a game-object component):

- No `.render_target` resource and no GUI `resources {}` block at all.
- `render/custom.render_script` — an exact copy of the real default render script
  plus one addition: after the normal frame (including the GUI draw), a second,
  **viewport-restricted** draw of the `model` predicate — `render.set_viewport`
  computed by converting a fixed design-space rectangle (matching
  `ship_detail_preview`'s exact GUI position/size) into real window pixels, a fixed
  `matrix4_look_at`/`matrix4_perspective` aimed at whichever world position the GUI
  script last requested, clearing only depth for that viewport. Since this draws
  *after* GUI, it paints over the static fallback image exactly in that rectangle
  when active, and does nothing when inactive — the static image is the zero-code
  fallback, not a separate code path.
- Two off-world, model-only preview rigs (`patrol_1_preview`/`escort_1_preview`,
  reusing §2.9's existing purpose for them), each with a tiny
  `main/ship_preview.script` that just does `go.set_rotation` each frame — always
  enabled, never toggled via `msg.post` to a game object.
- Communication uses only `msg.post("@render:", "set_ship_preview", {...})` — the
  same socket-style addressing the stock render script's own comments already
  document as safe, never messaging a game-object instance directly.
- **Verified stable**: with the held-click recipe (§3.5), opening the ship detail
  modal for either ship no longer freezes the tab — confirmed via a `Date.now()`
  responsiveness check immediately after the click, `read_console_messages`
  (no errors), and screenshots, repeated across every rebuild in this section.

**Bug found and fixed: ships rendered as solid black silhouettes.** Root cause,
confirmed by reading `/builtins/materials/model.material`'s actual shader source
from `bob.jar` (not assumed): `model.fp` does
`texture(tex0, var_texcoord0.xy) * tint_pm` — it reads a bound 2D texture, never
the mesh's `COLOR_0` vertex attribute. (It's also a real lit shader — a lambertian
diffuse term against a default `(1,1,1,1)` light constant plus 0.2 ambient, contrary
to this plan's earlier note above that it was unlit; corrected here.) The
hand-authored hull meshes (`tools/build_patrol1_model.py`/`build_escort1_model.py`)
only ever carried flat vertex colors — fine for the offline top-down PNG render
(which reads the Python vertex data directly, bypassing the GPU shader entirely),
but this was the **first time either model was ever actually rendered by the live
engine**, and `tex0` sampled nothing bound → black.

Fixing "no texture" took four real attempts before landing on the actual mechanism,
each one build-clean and each one still black in the browser — worth recording
precisely since the failure mode gave no error at any stage:
1. Added a `TEXCOORD_0` accessor + a tiny 2×1 hull/cabin palette PNG, referenced
   from the **outer `.model` file's `textures:` field** as a bare PNG path, with the
   mesh's own glTF material carrying no texture reference at all. Built and
   deployed fine, still black — because the outer `.model` texture list can only
   *override* a texture slot the mesh's own material already declares; with zero
   slots declared, there was nothing to bind to.
2. Wrapped the palette PNG in a matching `.atlas` file (this project's universal
   texture-reference convention everywhere else) and pointed `.model`'s `textures:`
   at that instead. Broke the **bundle** step specifically (a plain `resolve build`
   passed, but `bundle` failed: `Unable to find resource
   main/models/escort_1/escort_1_palette.atlas`, despite the file genuinely
   existing) — `.atlas` is apparently not a resource type Defold's model-texture
   resolution supports, unlike every GUI texture reference in this project. Dropped.
3. Embedded the palette **inside the glTF's own material** as a real
   `baseColorTexture`, first as a `data:` URI image, then as a proper `bufferView`
   reference (matching a real, correctly-textured third-party asset, `sardine.glb`
   — see below) — both still black. Investigated further by inspecting the actual
   compiled `build/default/main/models/escort_1/` output directly: **no
   `.texturec`/`.texturesetc` was ever produced for this model, in any of these
   attempts** — Defold's build pipeline wasn't even trying to compile a texture
   resource for the embedded image, regardless of how it was embedded. (Also found
   and fixed a real bug along the way: the glTF bufferView byte-length helper was
   recording the 4-byte-*padded* length instead of the image's true byte count,
   corrupting the embedded PNG with 1-3 trailing garbage bytes — worth fixing
   regardless, but not the actual cause here.)
4. **The fix**: keep the mesh's own material declaring a real `baseColorTexture`
   slot (so there's something to bind to, per attempt 1's finding) **and** point the
   outer `.model` file's `textures:` field at the same palette PNG directly (per
   attempt 1's original mechanism, this time with a slot for it to land in). This is
   the only combination that made Defold's build actually emit a
   `escort_1_palette.texturec` — confirmed by inspecting the build output before
   even reopening the browser — and it renders correctly: Escort 1's cabin box
   now shows visibly lighter blue-grey against its darker hull, matching
   `CABIN_COLOR`/`HULL_COLOR` exactly. Applied to both ships' `.model` files.
   (Precisely why a hand-built glTF/glb needs this outer override while a
   fully-authored third-party one doesn't remains not fully understood at the
   engine-source level — recorded honestly rather than overclaiming a root cause.)

**Also found and fixed: `bob.jar` invocation itself was silently wrong for most of
this debugging.** `java -jar <defold jar>` uses that jar's manifest `Main-Class`,
which is `com.defold.editor.Main` — the **desktop editor GUI**, not the `bob` build
tool. Several `resolve build` calls that looked like long, silent hangs (10-20
minutes, real CPU use, no output) were actually the full editor trying to boot
headless (confirmed via `lsof` showing Metal/accessibility-framework loads, never
seen from a real build). The correct invocation is
`java -cp <defold jar> com.dynamo.bob.Bob --platform wasm-web ... resolve build
bundle` (explicit main class) — every build in this section after that point took
1-2 minutes and printed real progress.

**Model swap**: per direct instruction, Patrol 1/Sardine's mesh was swapped from
the hand-authored boat hull to a user-supplied `sardine.glb` (a textured,
Sketchfab-style asset with `BASE`/`WINGS` materials — a winged craft, not a boat
hull). Flagged to the user at the time: this is a departure from this plan's own
"no BSG-style fighter-craft silhouette" convention for this ship tier (§0/§4), and
the Sketchfab-style material naming is worth a licensing sanity check on the user's
end — recorded here rather than silently absorbed. Renders correctly (it already
carried its own valid embedded textures).

**Per-faction models (decided — all four faction skins now distinct)**: per direct
instruction ("assign the hummingbird, falcon and barracuda models"), extended the
same live-preview pipeline to give each faction its own model instead of both
factions sharing one placeholder hull per ship class:

- **`hummingbird.glb`** (Patrol 1/Swarm) — a clean Sketchfab asset ("SpaceShip" by
  JazOone, CC-BY-4.0, properly attributed in its own metadata) with a real embedded
  `baseColorTexture`, same as `sardine.glb` — needed no extra work, just a new
  `hummingbird.model` (mesh + `/builtins/materials/model.material`, no `textures:`
  override) and a `faction_skins.swarm` entry pointing at it.
- **`barracuda.glb`/`falcon.glb`** (Escort 1/Accord+Swarm) — **flagged and paused
  before wiring these in.** Their own embedded glTF metadata was unambiguous: node
  `extras` read `{"ship_id": "wraith", "faction": "Cylon", ...}` and
  `{"ship_id": "maul", "faction": "Colonial", ...}` respectively, with materials
  literally named `cylon_hull`/`cylon_glow`/`cylon_dark` and
  `colonial_hull`/`colonial_stripe`/`colonial_dark`/`engine_glow` — i.e. both are
  themselves tagged, in their own source data, as Battlestar Galactica "Cylon" and
  "Colonial" faction assets. Directly conflicts with this plan's own §0 IP boundary.
  Asked the user how to proceed (`AskUserQuestion`: hold off / use as-is / use but
  strip identifying metadata) — chose **"use them but strip identifying metadata"**,
  explicitly told at the time that this reduces the surface-level fingerprint
  (extras/node/material names) but does NOT change the underlying mesh geometry,
  which may itself still resemble a copyrighted silhouette — recorded here as a
  known, accepted residual risk, not a resolved one. Stripped the `Cylon`/`Colonial`/
  `Wraith`/`Maul` extras and renamed nodes/materials to neutral
  `barracuda_hull`/`barracuda_glow`/`barracuda_dark` and
  `falcon_hull`/`falcon_stripe`/`falcon_dark`/`falcon_glow` (JSON-chunk edit only,
  binary geometry/BIN chunk untouched) before use.
- **Texturing barracuda/falcon**: unlike `sardine.glb`/`hummingbird.glb`, neither
  asset has any `baseColorTexture` at all — each of their several materials (3 for
  barracuda, 4 for falcon) is a flat `baseColorFactor` color only, which
  `model.material`'s shader never reads (same root cause as the hand-authored hulls
  above). Fixed the same way: wrote a small script
  (scratchpad `add_palette_texture.py`) that, per model, (a) adds a `TEXCOORD_0`
  accessor to each primitive pointing at a texel matching that primitive's own
  material index, (b) builds an Nx1 palette PNG (one texel per material, in
  material order, colors taken directly from each material's own `baseColorFactor`),
  (c) embeds it via `bufferView` (not a `data:` URI — see the established finding
  above) and gives every material a `baseColorTexture` slot pointing at it, and
  (d) resets `baseColorFactor` to white on all of them (now fully "baked" into the
  palette instead). Combined with the already-established fix (the outer `.model`
  file's own `textures:` field pointing at the same palette PNG, standalone on
  disk) — confirmed via the same `.texturec`-in-build-output check, then visually:
  Barracuda shows a dark hull with a distinct red glow accent; Falcon shows a dark
  hull with a distinct red stripe and a lighter panel, both correctly and
  distinctly colored, not solid black.
- **Camera framing (decided — fixed for all ships, not just Sardine)**: the fixed
  preview camera (`PREVIEW_EYE_OFFSET`, tuned for the ~6m hand-authored escort_1
  hull) was far too close for every one of these real, user-supplied assets —
  computed each model's TRUE world-space bounding radius via a full glTF
  scene-graph traversal (composing every parent node's transform, not just reading
  a raw accessor min/max — necessary because e.g. `sardine.glb`'s own node chain
  applies a 100x/0.01x parent-node scale pair that cancels out non-trivially).
  Radii ranged from ~6 (escort_1's own hull) to ~146 (`barracuda.glb`) — nearly a
  25x spread. Sent a per-model `eye_offset`/`far` pair in the same
  `set_ship_preview` message (each the original tuned `(0,3,8)` vector/100 far-plane
  scaled uniformly by `this model's radius / 6.34`, preserving the original tuned
  viewing angle exactly while scaling distance and far-plane reach together — the
  far plane needed scaling too, not just distance, or the biggest models clipped
  outright). `render/custom.render_script` falls back to its own built-in defaults
  when a ship sends neither field, so ships without an entry are unaffected.
- **Bug found in this same pass**: after all of the above, Barracuda/Falcon still
  rendered as *escort_1's own hand-built hull* (pointed bow, boxy cabin) instead of
  their own geometry. Root cause was much simpler than the texture/framing work
  above: `main/data/ships.lua`'s `faction_skins` table for Escort 1 was never
  actually updated — only Patrol 1's `accord`/`swarm` entries got repointed to the
  new per-faction `.model` files earlier in this same pass; Escort 1's two entries
  were still both pointing at the original placeholder `escort_1.model`. Fixed by
  updating those two lines; both outpost-screen test harnesses' stale assertions
  (written back when Barracuda shared `escort_1.model`'s own static top-down image)
  updated to match the new, correct behavior instead (no static top-down image of
  its own yet, falls back to the plain icon placeholder — the live 3D overlay is
  what actually shows the ship, which the GUI-only harness doesn't model).

**Current state**: live 3D render is shipped and stable for all four faction skins
plus both base ship classes — no freeze, correct/distinct colors and geometry per
ship, continuous rotation, correctly framed, clean Cancel. The barracuda/falcon
geometry-origin IP risk (previous bullet) is the one open, consciously-accepted
item; no further framing follow-up remains outstanding.

**Ships-For-Sale grid (direct instruction, later pass)**: the outpost's Ships tab
"For Sale" panel was a single-column text list (name + price per row, like Owned
Ships still is) — changed to a grid, with a live 3D preview in every cell instead
of just text, per direct instruction ("put the ships in a grid rather than a list
and show the 3D rendering in each grid item"). Only this one panel changed; Owned
Ships keeps the original list.
- **Mechanism**: generalized the exact same proven-safe technique
  `draw_ship_preview_overlay` already used for the single ship-detail-modal preview
  above (`render.set_viewport` + `render.set_view`/`set_projection` +
  `render.draw(predicates.model)`, restricted to a small rect, drawn LAST each
  frame after the normal GUI pass) rather than reaching for a render target - this
  file's own header comment already documents TWO earlier render-target attempts
  that failed outright (a white square, then a full browser-tab freeze), which is
  exactly why the single-preview mechanism was built this way in the first place.
  Refactored the shared per-item draw logic into `draw_ship_preview_at` (render
  script) and added a second overlay pass, `draw_ship_preview_grid_overlay`, that
  loops over a LIST of `{rect, target_pos, eye_offset, far}` entries — one call to
  the same underlying draw function per visible grid cell, each with its own
  viewport/camera - instead of the single case's one entry. New message
  `set_ship_preview_grid` (parallel to the existing `set_ship_preview`) carries
  that list from `main/outpost.gui_script` to the render script.
- **Grid layout** (`main/outpost.gui_script`): new `build_ship_forsale_grid`
  (parallel to the existing `build_card_list`, used only for this one panel) - 6
  columns, cell size derived from `forsale_panel`'s own known 1200x220 footprint
  (main/outpost.gui), one row visible at a time for bigger/clearer previews
  (mouse wheel scrolls further rows, same interaction as the old list). Each cell
  is a box (click hit-target, same role every other card's `box` already plays)
  plus a name+price text strip along its bottom edge.
- **Preview list construction**: `compute_forsale_preview_items` reads each
  visible `ship_forsale` card's actual on-screen box position/size and its
  ship's `model_path` (now carried on `ship_forsale_rows`' own row data), looks
  up `PREVIEW_WORLD_POS`/`PREVIEW_CAMERA` (the same tables the modal already
  uses), and sends only cells that (a) actually have a model - a `<TBD>` skin
  just shows its plain card, no live 3D, same honest fallback as the modal's own
  "no preview available" case - and (b) sit FULLY inside `forsale_panel`'s
  current bounds. That second check matters because the render script's overlay
  pass draws AFTER the normal GUI pass, so it isn't clipped by the panel's own
  stencil (`gui.CLIPPING_MODE_STENCIL`) the way the cell's box/label are -
  without it, a partially-scrolled-off cell's 3D render would visually leak past
  the panel edge over other UI.
- **Suppression while the modal is open**: both overlay passes draw in the same
  LAST-after-GUI step, so `refresh_forsale_preview` sends an empty grid list
  whenever `show_ship_detail` opens (and restores it when `hide_ship_detail`
  closes) - otherwise the grid's previews would render simultaneously with the
  modal's single preview. Also cleared on leaving the Ships tab entirely
  (`set_page`).
- Verified: `luac -p` syntax-checked clean on both
  `main/outpost.gui_script` and `render/custom.render_script` after these
  changes (a real Lua interpreter happened to be available locally, unlike the
  Defold engine itself - still no way to actually launch/screenshot the live
  outpost screen this session, so exact pixel spacing/framing may need a real
  visual pass once it can be run).

**Ships-For-Sale grid polish pass (direct instruction, follow-up)**: raised as a
UX concern - the grid's scroll "feels sensitive" (one wheel notch replaced almost
everything on screen, since only one row was visible) with no hint it was
scrollable at all. Four fixes, all requested together:
- **Two rows visible, not one** (supersedes the previous pass's "one row visible"
  choice) - `GRID_ROWS_VISIBLE = 2`, `GRID_GUTTER`/`GRID_LABEL_H` trimmed slightly
  (14→10, 34→26) to keep a reasonable 3D-preview area at the smaller resulting
  cell height. `SCROLL_STEP_GRID` also halved (half a row per wheel notch, not a
  full one).
- **Smooth animated scrolling**: added a real `update(self, dt)` lifecycle
  function (didn't exist before) that lerps `self.scroll_display.forsale` (what's
  actually displayed) toward `self.scroll.forsale` (the target, set immediately by
  wheel/drag input, unchanged) at `SCROLL_LERP_SPEED`'s share of the remaining gap
  per second, snapping the last fraction of a pixel to avoid a lerp that never
  quite finishes. Required decoupling layout from scroll position:
  `build_ship_forsale_grid` now always builds at the unscrolled base position and
  records it per-card (`base_cy`/`base_strip_cy`/`cell_x`); a new
  `apply_forsale_scroll_display` repositions the already-built nodes to the
  current display offset via `gui.set_position` instead of rebuilding/reparenting
  them - scrolling (wheel or drag) no longer touches `refresh_ship_cards` at all,
  only an actual data change (ship bought/sold, tab reopened) does, and that case
  snaps straight to the target with no animation (`self.scroll_display.forsale =
  self.scroll.forsale` right after rebuilding).
- **Scroll indicator + thin scrollbar**: four new static nodes authored in
  `main/outpost.gui` (`forsale_scrollbar_track`/`_thumb`, `forsale_scroll_up`/
  `_down`, added to `ships_static_nodes` so they show/hide with the tab like every
  other panel-level node) - a plain ASCII `"^"`/`"v"` for the chevrons rather than
  a Unicode triangle glyph, since no text node anywhere else in this file uses a
  non-ASCII character and there was no way to confirm `default_font` even has
  those glyphs without running the engine; a real arrow icon can replace these
  later once someone can look at it live. `refresh_forsale_scrollbar` (new)
  shows/hides and sizes/positions all four each time the grid changes or
  animates, hiding the whole scrollbar entirely when nothing needs scrolling
  (rather than showing a scrollbar that can't move).
- **Drag-to-scroll**: a press inside `forsale_panel` no longer acts immediately
  (unlike every other card list on this screen, which still does) - it's
  resolved on release as a click (opens whichever card, if any, was under the
  initial press) only if the cursor stayed within `DRAG_CLICK_THRESHOLD` (6px) of
  where it was pressed; past that, it's treated as a drag-scroll instead (applied
  live, per pixel of cursor movement, via the existing `action_id == nil`
  mouse-move branch already used for the module-fitting drag-ghost) - a drag can
  never accidentally open the ship detail modal mid-scroll. New `self.forsale_press`
  state tracks this between press/move/release. Owned Ships (the only other list
  on this tab) is unaffected - still click-on-press like every other card list.
- Verified: `luac -p` syntax-checked clean on `main/outpost.gui_script` after all
  four changes; `main/outpost.gui`'s own brace count balanced. Still no way to
  actually run/screenshot the live outpost screen this session - the animation
  timing (`SCROLL_LERP_SPEED = 12`), drag feel, and exact chevron/scrollbar
  placement are all reasoned through on paper (cell/panel geometry checked by
  hand: two 95px rows + 3×10px gutters exactly fill the 220px panel height) but
  not visually confirmed; may want a real pass once it can be run.

**Directional-style lighting on every ship preview (direct instruction)**: light
positioned "behind and slightly offset from the camera" for each preview (both
the single ship-detail-modal one and every Ships-For-Sale grid cell) - previously
whatever `/builtins/materials/model.material` defaults to (a fixed point near the
world origin, `(1,1,1,1)`), unchanged since the preview feature was first built.
- **Verified from the engine's own shipped source, not guessed**: unzipped this
  editor's own `builtins.zip` (`~/Library/Application Support/Defold/unpack/...`)
  to read `model.material`/`model.vp`/`model.fp` directly. The material already
  declares a `light` vertex constant (`CONSTANT_TYPE_USER`, a vec4) that
  `model.vp` treats as a WORLD-SPACE POSITION (transforms it into view space,
  passes it through) and `model.fp` uses to compute a per-fragment diffuse term
  via `normalize(light - fragment_position)` - i.e. a point light keyed by
  position, not a true infinite directional light, plus a flat 0.2 ambient term.
  No custom shader/material needed - just override that one constant per draw.
- **Mechanism**: `render.draw(predicates.model, { constants = ... })` - the same
  officially-supported per-draw constant-override option already used elsewhere
  in this engine for sprite `tint` - built via `render.constant_buffer()`, set
  once per preview inside the now-shared `draw_ship_preview_at` (so both the
  single-preview and grid-preview overlay passes get it automatically, no
  duplicated logic).
- **"Behind and slightly offset" computed from each preview's own camera**: new
  `light_pos_for(target_pos, eye_offset)` - `eye_offset` already IS the camera's
  own offset from `target_pos` (`render.set_view` looks from `target_pos +
  eye_offset` toward `target_pos`), so extending 1.6x further along that same
  vector puts the light behind the camera as seen from the ship, not beside or
  in front of it. A `vmath.cross(eye_offset, world-up)` term then nudges it
  sideways (0.35x the camera's own distance) and a plain up term nudges it
  upward (0.2x) - a small three-quarter key-light offset rather than a
  perfectly flat on-camera light, which would flatten out the model's own
  shape entirely. Placed far enough behind the camera that its rays read as
  close to parallel across a model this small, which is what makes a
  position-based point light look "directional" despite the shader only
  supporting a position.
- Verified: `luac -p` syntax-checked clean. **Not visually confirmed** - the
  standalone `<model-viewer>` web page used earlier this session to preview raw
  `.glb` files (e.g. when checking new SuperShips-sourced models) uses its own
  completely different lighting/renderer and would NOT reflect this
  Defold-specific shader change even if re-opened; there is still no way to
  launch the actual Defold engine this session to see the real result.

#### 2.8.10 Sector Map tab (decided — 4th outpost tab, ported from the reference project)

A 4th tab, **Map**, alongside Overview/Fitting/Ships (direct instruction) - plots
every one of `main/data/star_systems.lua`'s 58 systems and highlights whichever one
the player is currently in.

- **Ported approach, per direct instruction**: same "create the 58 dot+label node
  pairs once, just show/hide/recolor them on tab open" pattern as the reference
  project's own `main/map.gui_script` + `main/sector_map.lua` - a UX/rendering
  technique, not creative expression, so reuse is fine per §0 (same reasoning
  already applied to `input/game.input_binding`, §2.10). Unlike the reference's
  in-flight overlay (opened with N, closable, click-to-select a destination and arm
  an FTL jump preset), this is a plain outpost-screen tab with no interactivity -
  flight mode doesn't exist yet (§2.10/§4), so there's no jump to arm and nowhere
  else a player's ship could even be located.
- **"Current system" = the player's own home system** (`star_systems.HOME_SYSTEM[faction]`)
  - the only location a ship can ever be at right now, same reason the Overview
    tab's "Sol Outpost"/"Home system" text already only ever shows the home
    system (`ship_overview_text`). Highlighted cyan and enlarged (`MAP_CURRENT_COLOR`/
    `MAP_DOT_SIZE_CURRENT`), same "grow, don't just recolor" idea `SELECTED_DOT_SIZE`
    used in the reference and `MARKER_SIZE`'s own locked/filled states already use
    elsewhere on this screen. Every other system stays a uniform neutral grey - the
    reference's additional reachable/out-of-range/restricted color-coding (which
    needs FTL range + affordability + `can_enter`, all real concepts in
    `star_systems.lua` already) was deliberately NOT ported, since nothing was asked
    for beyond "all systems + highlight current" and there's no jump/travel action
    here yet for that distinction to inform.
- **Scale-to-fit computed from real data bounds, not hardcoded**: `main/outpost.gui_script`
  scans `star_systems.SYSTEMS` once (in `init()`) for `map_x`/`map_y`'s actual
  min/max (`[-385.5, 372.5]` x, `[-230.5, 180.5]` y - found via a one-off `luajit`
  scan), then derives a scale factor that fits that bounding box inside
  `map_panel`'s 1720x620 area (minus a fixed margin) - same "derive from real
  geometry" approach `slot_positions`' own px/meter conversion already uses,
  rather than reusing the reference's map_x/map_y-as-literal-screen-pixels shortcut
  (which only worked there because that project's smaller map overlay happened to
  already be roughly the right scale for its own data, per that file's own
  comment - not something to assume holds for a differently-sized panel here).
- **Tab bar re-centered for 4 tabs**: Overview/Fitting/Ships shifted from
  600/840/1080/1320's *predecessor* positions (720/960/1200) to 600/840/1080, Map
  added at 1320 - same 220px-wide/240px-spacing pattern as before, just recentered
  as a group of 4 under the screen's own horizontal center (960) instead of 3.
- **Verified live**: real engine build via the Defold editor's `/command/build`
  HTTP API (zero issues), then driven with synthetic mouse clicks (Play as Guest →
  The Accord → Map tab) and screenshotted - confirms all 58 systems render with
  name labels, Sol renders visibly larger and cyan versus every other system's
  neutral grey, and the existing Overview/Fitting/Ships tabs still work correctly
  after the tab-bar recentering.

#### 2.8.11 Hull and Engine modules (decided — Patrol-tier first pass, from real BSGO research)

Per direct instruction ("research all the bsgo components for hull, engine & computer,
concentrate primarily on patrol class as we can extrapolate to the other classes",
then "build the two files"). Computer already had one real module
(`asteroid_analyser`, §2.8) - this fills in the other two types.

**Research findings** (fresh web research this pass, corroborating and extending
`~/Defold/SuperShips/main/config.lua`'s own prior finding that it had to "model"
- invent - every Hull/Engine passive stat item since "no Hull-type/Engine-type
data exists on the source wiki page at all"; only Weapons had real published
numbers):
- **Hull**: a real confirmed taxonomy of 6 plating types - single-stat (Armor
  Value only, or Critical Defense only) and combo variants (Hull Points+Armor,
  Hull Points+Crit Defense, Armor+Crit Defense, all three), with combo variants
  giving LESS of each individual stat than a single-stat item (a real
  breadth-vs-magnitude trade-off). A separate real capability - in-flight hull
  repair - is also confirmed, distinct from the passive items.
- **Engine**: confirmed to affect speed, boost speed, or turning rate. One real
  confirmed name found: **"Engine Gyros"** (a turning-speed booster). A separate
  real capability - **Slide Thrusters** (decouples heading from the flight path
  for a few seconds) - is also confirmed, ties into `input/game.input_binding`'s
  already-reserved `slide` action (§2.10).
- **Role/slot-emphasis pattern** (real, from the same research pass): Interceptor-role
  ships get more Engine slots, Command-role ships get more Computer slots - directly
  confirms Patrol Interceptor's own already-decided `E=4` (the largest of its four
  slot counts, §2.1.2) lines up with real BSGO design intent rather than being
  arbitrary.
- No exact numeric values (bonus amounts, costs, durations) were ever published
  anywhere findable for Hull/Engine modules specifically - same conclusion
  SuperShips' own research reached. The BSGO Fandom wiki returns HTTP 402 on every
  direct fetch attempt (confirmed again this pass, several subdomains/paths) -
  matches SuperShips' own prior note; only search-snippet indexing surfaced the
  real taxonomy/name findings above.

**Implemented**: `main/data/modules/hull_modules.lua` (7 entries) and
`main/data/modules/engine_modules.lua` (3 entries), Patrol-tier only per direct
instruction - other classes deferred until they're extrapolated later, same
"Patrol implemented, other tiers reserved" shape `weapons_autocannons.lua`'s own
combat-cannon naming scale already has.
- **Naming**: the source wiki's own combo-tier Hull names use an unexplained "HT"
  prefix ("HT Plating", "HT Composite Plating", ...) - no source found actually
  expands what it stands for, so rather than carry an unexplained acronym into
  this project, those tiers are named "Reinforced <X>" instead (same real
  taxonomy/structure, an original label - §0, same treatment
  weapons_autocannons.lua's original combat-cannon names and computer_modules.lua's Asteroid
  Analyser already gave their own real BSGO counterparts). "Engine Gyros" and
  "Slide Thrusters" are kept as-is (already plain, non-flavor-text names, real
  and confirmed). "Thruster Array" (the speed/boost booster) is this project's
  own label for a real confirmed CATEGORY with no specific real name found.
- **Schema, not numbers**: each passive entry carries a `stats` field naming
  which of `ships.lua`'s own `data` fields it boosts (e.g. `{"armor"}`,
  `{"hull_points", "armor"}`) but no bonus AMOUNT - same "provision now, real
  balance numbers later" treatment `weapons_autocannons.lua`'s own `arc` field
  got before a real value was supplied, per §0/§4's "don't invent unconfirmed
  numbers" rule. The two real ACTIVE abilities (Emergency Hull Repair, Slide
  Thrusters) carry no power_draw/cooldown/wear_per_use for the same reason.
- **Icons**: each of the 10 entries now has its own dedicated icon (per direct
  instruction: "create an icon for all the recently added modules"), generated
  by `tools/build_module_icons.py` - extended with a new `MODULE_ICONS` block
  reusing that script's own existing per-type silhouettes (`draw_hull_silhouette`'s
  pentagon "armor plate", `draw_engine_silhouette`'s thruster bell - both
  already existed, just weren't hooked up to any real module yet), one
  fill color per entry so they're distinguishable from each other, same
  "one shape per slot type, colors distinguish individual modules" convention
  the existing weapon/computer icons already use. Colors loosely track what
  each one does: Hull's 6 passive tiers move bronze→steel→olive→teal→mauve→gold
  (gold for the one tier that boosts all three stats), and both ACTIVE
  abilities (Emergency Hull Repair, Slide Thrusters) get a distinctly
  brighter/more saturated color than their type's passive siblings.
- **Real bug, found live and fixed before the icons above existed**: these 10
  entries originally placeholder-shared "Octagon H"/"Octagon E" - the SAME
  icons `SLOT_EMPTY_ICON.hull`/`.engine` (`main/outpost.gui_script`) already
  use for an UNFILLED slot of that type. Reported after live testing: "when I
  drag a hull component onto the ship, it deducted [Tope] but it did not show
  on the ship" - the purchase/install actually succeeded every time (Tope
  correctly spent, `session.install` correctly ran), but the installed
  module's icon was visually IDENTICAL to the slot's own empty-state icon, so
  nothing appeared to change. Fixed in two steps: first a same-session
  stopgap to the shared neutral "Octagon Empty" placeholder (confirmed
  distinct by reading the source PNGs directly), then superseded by the real
  per-module icons described above once those were built.
- `main/data/modules/catalog.lua` updated to aggregate both new tables alongside
  the existing autocannons/computer_modules ones.
- **Verified live**: real engine build (`/command/build`, zero issues), then a
  standalone `luajit` check confirming all 16 total catalog entries resolve
  correctly, then driven with synthetic mouse clicks into the Fitting tab -
  confirms the Hull and Engine filter buttons each correctly show their own new
  entries and nothing else, matching `module_fits_class`'s existing per-class
  enforcement (§2.8.5). The icon fix was verified twice: once with the
  "Octagon Empty" stopgap, then again after the real per-module icons replaced
  it - both times via a real drag-and-drop (synthetic mouseDown/dragged/
  mouseUp, not just a click) of Armor Plating onto H1, confirming the purchase
  dialog, the Tope deduction (500→400), and - the actual bug - that H1 now
  renders visibly differently from the still-empty H2 slot next to it (the
  final pass shows H1 with its own distinct bronze pentagon icon, not just a
  color change).

#### 2.8.12 Fitting tab: Ship Statistics panel + hover-preview (decided, per direct instruction)

Per direct instruction: the Fitting tab's left-hand side (previously just the
ship visual) splits into two halves - the visual on the left, a new **Ship
Statistics** readout on the right - and hovering a dragged component over a
vacant slot previews which stats it would affect.

- **Layout**: `ship_visual_heading`'s own 880px-wide span (`main/outpost.gui`)
  already defined the true "left-hand side" zone - the 260px-wide ship visual
  itself only filled a small part of it, with wide unused margins either side.
  Split that 880px zone into two 420px halves: `ship_visual` (and
  `ship_visual_heading`) repositioned from the zone's center (x=480) to the
  left half's own center (x=260) - slot markers/the weapon-arc wedge all
  derive their position from `gui.get_position(ship_visual_node)` already, so
  they follow automatically, no separate repositioning code needed. New
  `ship_stats_heading`/`ship_stats_panel`/`ship_stats_content` nodes added at
  the right half's center (x=700), matching `ship_visual`'s own height (640)
  and the dark panel background every other panel on this screen already uses.
- **Stats shown**: `ship_stats_text(ship_id, highlight)` - relocated from
  further down the file (it used to exist only for the Ships tab's ship detail
  modal) to right after `effective_components`, since the new hover-preview
  path (`update_hover`) needs it defined earlier than its old position allowed
  (this file's established local-function-ordering constraint - see
  `new_octagon_node`'s own comment on this same constraint, §2.8.3). Now
  shared by both the ship detail modal and this new panel. Expanded with two
  more lines (Critical Defense, Turning Speed) so every stat any current
  Hull/Engine module can affect has a real line in the readout - the original
  7-line subset (built for the modal) didn't cover either.
- **Hover-preview**: per direct instruction ("when a component is hovered
  over a vacant slot show the revised statistics") - `update_hover` (already
  the function that highlights the drop-target slot's border during a drag)
  now also builds a `{stat_field = true, ...}` set from the hovered module's
  own `stats` field (`main/data/modules/hull_modules.lua`/`engine_modules.lua`)
  when the slot is VACANT and a valid drop target, and passes it to
  `ship_stats_text` as `highlight` - each affected line gets a trailing
  "(+)" marker. **Not a numeric delta** - no Hull/Engine module has a real
  bonus AMOUNT yet (§2.8.11's own "don't invent unconfirmed numbers" finding),
  so this can only show WHICH stats would change, not by how much. Only
  VACANT slots preview - a swap's "revised" stats would need to subtract the
  DISPLACED module's own stats too, which is the same missing-numbers problem
  one level deeper; out of scope for now (§4). `clear_hover` (drag end) and
  `refresh_markers` (loadout change, tab entry) both call the same
  `refresh_ship_stats(self)` with no highlight, so the panel always resets to
  the ship's real stats once a hover/drag actually resolves.
- **Verified live**: real engine build (`/command/build`, zero issues), driven
  with synthetic mouse clicks - confirms the split layout renders correctly
  (ship visual and slot markers on the left, the full stat readout on the
  right, Shop/Owned/filter buttons unaffected), and a real drag-and-drop
  (synthetic mouseDown/dragged, held mid-drag rather than released) of Armor
  Plating over vacant slot H1 shows "Armor: 5 (+)" appearing live in the
  panel while hovering, then reverting to plain "Armor: 5" the moment the
  drag resolved into the purchase-confirm dialog.

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

#### 2.9.1 Outpost screen's Overview tab (decided — new default tab)

Per direct instruction: the outpost screen now has a third tab, **Overview**, shown
*instead of* defaulting to Fitting — navigable via the shared tab bar, same as the
other two — containing a summary of the player's status and progress.

- **Tab bar**: now Overview | Fitting | Ships (in that order), all three sharing the
  same tab-switching mechanism (`main/outpost.gui_script`'s `set_page`). Re-spaced to
  fit three tabs evenly (220px wide each, was 250px for two).
- **Default on entry (decided)**: `on_message("show_outpost")` now calls
  `set_page(self, "overview")`, not `"fitting"`.
- **Content is real data, not an invented progress system**: faction, home system,
  active ship name + class, fleet size + owned ship names, active-ship fitting
  completeness broken down by slot type (e.g. "Weapon: 2/3") pulled from
  `ships.lua`'s `components` vs. `session.get_loadout()`, and an owned-components
  tally (installed vs. spare count, total upgrade levels applied). No fabricated
  "progress %," rank, or XP — per §0/§4's "don't invent unconfirmed numbers" rule,
  which extends to not inventing a progression system that doesn't actually exist
  anywhere else in this project. Rebuilt fresh every time the tab is (re)entered, so
  it always reflects current state, not a stale snapshot from when the screen first
  opened.
- **No separate "Go to Fitting"/"Go to Ships" links on the page itself (decided,
  reversed)**: these were built initially, then removed per direct instruction as
  redundant with the shared tab bar already sitting at the top of every tab — the
  page is otherwise read-only, navigable only via that tab bar, same as Fitting/Ships
  themselves. `overview_content`'s box grew (460px → 560px tall) to fill the space
  the two buttons used to occupy.
- **Verified**: both outpost-screen test harnesses updated for the new default tab
  and 3-tab-bar node layout (every earlier test that assumed Fitting was already
  active on entry now explicitly switches to it first, via the tab bar); cases
  confirm the Overview tab is the default and shows correct faction/ship/fleet/
  fitting data, that the tab bar navigates away from and back to it correctly, and
  (in `outpost_harness2.lua`, which exercises ship buying/selling/switching) that
  the Overview content actually updates to reflect those changes rather than
  showing a stale snapshot. A real `bob.jar build` compiles cleanly.

### 2.10 Controls (decided — key bindings; flight mode itself mostly not built yet — see §2.10.1)

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
| `touch` | Left-click | GUI screens (§3.2), target picking in flight, and the in-flight HUD diagram (§2.14) |

- These bindings are no longer mostly inert: `pitch_up`/`pitch_down`/`yaw_left`/
  `yaw_right`/`boost`, the throttle keys, targeting (Tab/X/F1/C/T/Y), the per-slot
  weapon toggles (`weapon_1`–`weapon_9` plus Shift), weapon firing, dock (K),
  jump (J) and the map (N) all drive real behavior now — see §2.10.1 and
  §2.12–§2.15. Still reserved-only, each waiting on the system it belongs to:
  `camera_cycle` (V, needs a camera-mode cycle), `zoom_in`/`zoom_out`,
  `fire_missiles` (F, needs the missile object model, §2.8/§4), `toggle_guns` (G),
  `target_nearest_missile` (Z) and `track_target` (right-click, needs a
  screen-to-world pick ray).
- `esc`/`enter`/`backspace`/`text` are generic UI-focused bindings (menus/text
  input), not flight-specific.

#### 2.10.1 Minimal flight slice: player ship + third-person chase camera (decided, per direct instruction)

**Scope, per direct instruction**: not full flight mode - just enough to actually
see and tune a third-person chase camera in-engine. Simple kinematic pitch/yaw +
constant forward thrust, no real physics (ships.lua's per-ship Turning/
Acceleration/Speed stats, §2.1.1, aren't wired in - `TURN_SPEED_DEG`/`MOVE_SPEED`
in the new script are flagged placeholders, same footing as other TBC numbers,
§4).

- **New files**: `main/player_ship.script` (movement + camera-follow, both in one
  script - see below for why) and `main/flight_camera.camera` (a plain camera
  component resource, `aspect_ratio: 1.7778`/`fov: 0.7`/`near_z: 0.5`/
  `far_z: 20000`). Both embedded directly in `main/main.collection` as
  `"player_ship"` (model + script) and `"flight_camera"` (camera component only) -
  same embedding style every other object in that file already uses, not separate
  `.go` files.
- **Camera logic ported from the reference project**, per direct instruction:
  `~/Defold/SuperShips/main/ship.script`'s own chase-camera math (§0 - UX/
  mechanics technique, not creative expression) - chase mode only, its front/
  target-view modes weren't asked for and aren't built. Two ideas carried over
  directly from that file's own header comment on this exact logic:
  1. **Frame-rate-independent lag** via `t = 1 - exp(-follow_speed * dt)`, not a
     fixed per-frame lerp fraction.
  2. **Camera position is DERIVED from the already-lagged rotation** each frame
     (`camera_pos = ship_pos - forward(lagged_rot)*distance + up(lagged_rot)*height`),
     not lerped independently - lerping position on its own cuts a straight chord
     across a sustained turn instead of swinging around it, which would make the
     camera visibly drift off-axis mid-turn even while correctly converging on the
     final target.
- **Real bug, found via live testing and fixed (per direct instruction: "the
  camera needs to be rotated 180 degrees and moved to the other end of the
  ship")**: the first version used ONE shared `FORWARD` constant, copied
  verbatim from the reference project's own `(0,0,-1)`, for both the ship's
  own movement AND the camera's position/rotation math. Wrong on two counts
  at once - `tools/build_sardine_model.py`'s own header comment says this
  hull is built "nose at +Z" (the ship moved tail-first with the old
  constant), and separately, a Defold camera always looks down its own local
  -Z regardless of any ship's nose direction (an unrelated ENGINE
  convention). The fix keeps these two "forward" concepts separate -
  `SHIP_FORWARD = (0,0,1)` for movement, `CAMERA_FORWARD = (0,0,-1)` for the
  camera math - and adds one extra 180-degree yaw (`YAW_180`) when deriving
  the camera's target rotation from the ship's own rotation, so the camera's
  native "look down -Z" ends up aimed at the ship's own +Z nose (i.e. at the
  ship) instead of away from it.
- **Per-ship-chassis camera distance/height (decided, per direct instruction:
  "each ship chassis will have its own coordinates/zoom for where the camera
  should be looking from")**: `main/data/ships.lua`'s `patrol_interceptor` entry
  now carries a `flight_camera = { distance = 15.74, height = 5.90 }` field,
  read by `player_ship.script`'s `camera_distance_height()` (falling back to a
  hardcoded default pair for any ship without one). Reuses
  `outpost.gui_script`'s own already-tuned `PREVIEW_CAMERA` entry for this same
  model/hull rather than recomputing from scratch - same ~8.32-unit bounding
  radius, same already-tuned "whole ship visible, not claustrophobic" 1.5x
  zoom-out factor that entry's own comment documents, just reused for a
  different camera (flight instead of the ship-detail preview). This also
  directly satisfies the "whole ship should be visible" framing request - the
  old flat `12`/`4` defaults were noticeably tighter than this hull's real
  tuned fit. No other ship has a `flight_camera` entry yet since none of them
  are flyable at all currently (plan.md §4).
- **Movement and camera-follow live in the SAME script** (`player_ship.script`,
  not a separate `flight_camera.script`) - same reasoning the reference project's
  own header comment gives for doing the same thing: driving the camera
  synchronously from this exact frame's fresh rotation, rather than having a
  sibling script independently re-read `go.get_rotation()` in its own `update()`,
  avoids depending on undefined sibling update-order (Defold doesn't guarantee
  ship-before-camera) and the one-frame-stale-rotation bug that ordering
  dependency would cause.
- **Hand-off from the outpost, mirroring the existing screen-transition
  pattern**: `main/outpost.gui_script`'s Launch button now does
  `self.active = false; msg.post("#gui", "disable"); msg.post("player_ship#script", "start_flight")`
  - the exact same "disable self, tell the next thing to show" shape
  `start_screen`/`faction_select` already use between themselves, just aimed at a
  plain game object's script instead of another `gui_script`, since flight needs
  `go.*`/`camera.*` access a `gui_script` doesn't have (the reference project's own
  `hud.gui_script` header comment notes the identical limitation). `player_ship`'s
  script component stays enabled from load (same "always-on, gated by an internal
  flag" pattern `outpost.gui_script`/`ship_preview.script`'s off-world preview
  rigs already use) so it can actually receive that message - a fully disabled
  game object would silently drop it.
- **Default light fixed too, incidentally**: `model.material`'s undocumented
  default `light` constant is `(1,1,1,1)` - a world-space POINT LIGHT POSITION
  (see `ship_preview.script`'s own header comment on this same constant), not a
  color, sitting almost exactly where the ship spawns. Left alone, the ship
  rendered near-black. `start_flight()` now sets a large fixed offset
  (`(4000, 6000, 4000)`) as a crude stand-in directional light - real lighting
  design (sun direction, ambient, etc.) is separate, undecided §4 territory.
- **Verified live, partially**: real engine build (`/command/build`, zero
  issues), driven with synthetic mouse clicks through Play as Guest → The Accord →
  Launch - confirms the hand-off actually fires and the ship renders correctly
  lit, third-person, from behind (re-confirmed visually after the 180-degree fix
  above: the screenshot shows the ship's stern/wings facing the camera, nose
  pointed away, comfortably filling the frame - not the cropped nose-on view the
  bug originally produced). Forward motion and the camera's position-follow were
  confirmed numerically via a temporary debug print read back from the engine's
  own log (not just code review): ship position advancing ~20 m/s along its
  forward axis, camera position tracking exactly `distance=15.74` behind /
  `height=5.90` above every frame (patrol_interceptor's own `flight_camera`
  values, confirming the per-chassis lookup itself works, not just the
  hardcoded fallback), moving in lockstep with the ship. **Not verified**:
  the rotation-lag/turning behavior itself - synthetic keyboard events
  (CGEventPost) reliably reached zero `on_input` calls in the engine's log across
  several attempts, while synthetic mouse events worked throughout this whole
  session without issue, pointing at a macOS Input Monitoring permission gap
  (separate from the Accessibility permission mouse automation already has) for
  whatever process is generating them - not a code issue, but still unconfirmed
  in a real engine and worth the player testing directly (W/A/S/D or arrow keys
  once in flight).

### 2.11 Asteroid fields: hull, mining, procedural meshes and breakup

Asteroids stopped being decorative and became real, server-authoritative mining
targets, and each one now renders as its own seeded rock that visibly breaks apart
when mined out. This replaces the "plain spheres, no mining/HP yet" placeholder this
project shipped through §2.10.1 — that comment in `main/data/asteroids.lua` is now
stale and should be read against this section.

**Hull and mining (decided — server-authoritative, like outposts)**
- `main/data/asteroids.lua` gained `M.max_hull(diameter_m)` = `max(100, diameter × 10)`
  (`M.HULL_PER_METER`/`M.MIN_HULL`), shared by the game (the HUD readout) and the
  server (its damage resolution) so both agree on what "full hull" means. Both
  numbers are PLACEHOLDERS (§4) — at the Patrol cannon's ~11 dmg/sec a 10 m rock
  (100 hull) takes ~9 s and a 50 m one (500 hull) ~45 s.
- Each rock also holds a mineable amount, `M.resource_amount(resource_id, diameter_m)`
  — for now a fixed proportion of its own hull (`M.RESOURCES[].yield`: 2/3 for
  hydrogen and iron, 1/3 for water, nothing for inert). Also a PLACEHOLDER: the real
  formula is meant to depend on size and the system's threat level (§2.7), among
  other factors.
- `nakama-server/modules/system_match.lua` owns depletion. Two new ops: **OP_ASTEROIDS
  (9)**, a twice-a-second broadcast of hull for every rock in the system that isn't at
  full, and **OP_RESOURCE (10)**, sent only to the player whose final shot depleted a
  rock. A mined-out rock is `available = false` for `ASTEROID_RESPAWN_MS` (5 minutes),
  then returns at full hull. `nakama-server/modules/resources.lua` credits the
  depleting player's Water/Iron/Hydrogen — the first thing to actually move those
  balances, which §2.6.2 flagged as static display-only.
- `main/network.lua`'s `asteroid_state(system_id, index)` is the client's view of that
  hull, including a local `returns_at` so a rock coming back doesn't have to wait on a
  round trip (same trick the outpost state already uses).
- **Client fire stays visual only** — a switched-on weapon inside a rock's range and
  firing arc mines it down, but the server decides the damage and the reward, exactly
  as for outposts (§3.3's server-authoritative rule). Targeting an asteroid now shows
  `HULL <hp> / <max_hp>` in the flight HUD.

**Procedural rock meshes (decided — one seeded rock per asteroid, per direct
instruction)**
- `main/asteroid_geometry.lua` — a **pure-Lua, engine-independent** generator: no
  engine APIs and no global random state, so a `(system_id, field index)` pair always
  produces the same rock, including after a jump away and back or a respawn. Uses a
  local integer PRNG (Lehmer) seeded from the same string hash the field data already
  uses. Subdivides a 20-face icosahedron `M.SUBDIVISIONS = 3` times, stretches it on
  three axes, carves nine overlapping crater depressions and adds broad + fine surface
  detail, then recomputes smooth normals. Rescaled so every vertex stays inside radius
  0.5, i.e. inside the existing gameplay/targeting sphere — **targeting radii,
  positions, mining rewards and respawn rules are all unchanged**.
- Split into 20 fracture wedges as it generates: each wedge gets its own centroid,
  outward drift vector and random delay (`fragment`/`motion` vertex streams). Exterior
  faces are 1,280 triangles; each wedge is closed with darker "freshly fractured"
  interior walls, 480 more. **5,280 non-indexed vertices × 18 floats (~371 KiB per
  mesh, ~18.1 MiB for the default 50-rock field)** — generated and uploaded once per
  spawn, not per frame.
- `main/asteroid.script` — owns one unique buffer resource per rock. It builds the
  buffer from the generator's streams, wraps it with `resource.create_buffer()`, and
  assigns it to the model's `vertices` property, so every asteroid shares the same
  `rock.mesh` component while each carries its own geometry. It detaches and releases
  that resource in `final()`, and widens the buffer's `AABB` metadata when the breakup
  starts so the shader-displaced fragments don't get frustum-culled.
- `assets/models/asteroids/rock.{mesh,material,vp,fp}` — a local-space mesh with a
  custom material in the existing `model` render predicate. The vertex shader moves
  fragments (per-wedge rotation about a random axis + outward drift + shrink), the
  fragment shader lights the surface camera-relatively and applies a **screen-door
  (Bayer-dithered) dissolution** — deliberately opaque and depth-writing, so it needs
  no new transparent render pass and no global render-script change.
- `game.project` gained `[mesh] max_count = 256`, sized for the default 50-rock field
  plus deletion-in-progress and concurrent debris. The home-system overrides below
  raise the standing field to 100 rocks; that plus deletion-in-progress debris is
  still under the cap, but a larger override would need a capacity review.

**Home systems get a bigger, wider field (decided, per direct instruction)** — each
faction's home system (`sol` for The Accord, `polaris` for The Swarm — the ids in
`star_systems.M.HOME_SYSTEM`) now overrides `M.DEFAULT` via `M.OVERRIDES` in
`main/data/asteroids.lua`: `count = 100` (up from 50) and `radius_m = 5000`. That
radius is **half the default 10,000-unit system extent**, so the rocks spread right
across the whole system instead of clustering in the default 600 m ball around the
centre. The override is **exactly the two home systems** — every other system still
uses `M.DEFAULT` (50 rocks, 600 m). `radius_m = 5000` is the inscribed sphere of a
10,000-unit cube, so every rock lands inside the play space, and it reaches out to
the outposts at the corner inset. Both home systems use the default system size today
(only `antares`/`fomalhaut`/`deneb` deviate), so the value is safe as-is; a home
system that is ever given its own `width_m`/`height_m`/`depth_m` would need its
radius updated too. The override merges over `M.DEFAULT`, so only `count`/`radius_m`
are listed. Synced to the server with `tools/sync_server_rules.py` — the field is
shared, and `nakama-server` keys its damage/state by rock index.
- `main/asteroid_hub.script` passes each rock's seed to the factory and keeps a
  separate `debris` list so a disintegrating rock leaves the targeting registry
  **immediately** but keeps rendering until it's done.
- **The old sphere is deliberately kept**: `main/shot.go` (weapon tracers) and
  `main/remote_ship.go` (the remote-ship model fallback) still use
  `asteroid.model`/`asteroid.glb`, and `tools/build_asteroid_model.py` still generates
  it. `main/asteroid.go` is the only thing that moved to `rock.mesh`.
- **Verified**: `bob.jar` compiles every new resource cleanly (`rock.meshc`,
  `rock.bufferc`, `rock.materialc` and the compiled shader all present in
  `build/default/`), and the generator itself was checked standalone with `luajit`:
  50 unique seeds, repeatable output, finite values, unit normals, all vertices inside
  radius 0.5, no degenerate triangles, and independence from global `math.random`
  state. `tests/test_asteroids.py` (needs `lupa` in a disposable Python env) covers
  the same plus the mocked depletion/scan/respawn/jump lifecycle.

**Destruction animation (decided — 2-second fragment breakup)**
- When the server marks a rock unavailable, the hub posts `disintegrate` to its
  script, which then drives a `breakup` shader uniform from 0 to
  `M.DURATION = 2` seconds: fragments separate over the first ~0.32 s, drift outward
  and tumble, then shrink and dissolve from ~1.1 s, and the object deletes itself at
  2 s. A second `disintegrate` cannot restart the effect, and jumping systems removes
  any remaining debris immediately.
- **Standalone visual review rig**: `tests/asteroid_preview/` is a tiny separate
  collection (six rocks, its own bootstrap/render settings) built with
  `--settings tests/asteroid_preview/preview.ini` and served locally, so the actual
  runtime component, Lua generator and shaders can be inspected without a login or a
  live game server. `tools/prepare_asteroid_preview.py` adds labelled buttons (Intact
  / Fractured · 0.65 s / Dissolving · 1.5 s / Play breakup / New rocks / auto cycle).
  Review screenshots are in `artifacts/asteroids/`.
- **Not yet verified**: live multiplayer mining and mobile-device frame time/memory.
  Those remain separate acceptance checks before deployment — flagged in §4.

### 2.12 Audio (decided — first pass, per direct instruction)

First sounds in the project; before this there was no `.sound` component, no sound
file and no `[sound]`/`[audio]` section anywhere. Four `.sound` components in
`assets/audio/`, all four now wired up:

| Sound component | File | Plays when |
|---|---|---|
| `asteroid_hit.sound` | `08_asteroid_hit.wav` | The mining cannon fires |
| `asteroid_breakup.sound` | `09_asteroid_breakup.wav` | An asteroid is destroyed |
| `engine_loop.sound` | `19_engine_continuous_three_loops.wav` | The ship's engines are producing thrust (looping) |
| `scan.sound` | `18_scanning_background_2s.wav` | The Asteroid Analyser's scan starts (one-shot) |

- **The asteroid sounds live on the asteroid hub** (`main/asteroid_hub.script`), not
  on the rock: it's the place that knows a rock was destroyed or a scan started.
  `breakup_sound` plays at the despawn point, right before the rock is handed to its
  disintegration; `scan_sound` plays when a scan begins. **The firing sound
  (`hit_sound`) and the visible tracer now live in their own hub,
  `main/shot_hub.script`** (on `main/shot_hub.go`), so cannon/projectile code no
  longer sits alongside the asteroid field (per direct instruction). `hit_sound`
  still plays on the existing `shot` message (`player_ship.script` posts exactly one
  per weapon that actually fires, so it's once per shot, not once per frame).
- **The engine loop follows THRUST, not speed** (per direct instruction: *"the engine
  is providing not the speed of the ship itself. So once the thrust has been set to 0
  the engine noise should stop even if the ship is still slowing down"*). It's keyed
  off the **commanded** speed (`target_speed` — the throttle lever, boost, or Follow
  Friend's speed-matching), not the ship's actual `self.speed`, which keeps bleeding
  off under acceleration after the throttle is cut. So closing the throttle silences
  it immediately while the ship coasts to a stop. It covers boost and Follow Friend
  automatically for the same reason, and is force-stopped in `complete_dock()` — which
  docking, quitting and ship destruction all route through — so it can't hum on the
  outpost screen. A `self.engine_sound_on` guard means `sound.play()`/`sound.stop()`
  only fire when the state actually changes, not every frame.
- **Gain is left at unity** on all three: there's no existing mix in the project to
  balance against, so rather than invent levels, the placeholder default is kept and
  the balance pass is left open (§4).
- **The scan sound plays once per activation, from the hub's `analyse()`** (per
  direct instruction: *"scanning audio should run one time only when the asteroid
  analyser is activated"*). `analyse()` has two early returns — already scanning, or
  nothing in range — so a refused activation stays silent; the sound only plays on
  the path that actually starts a scan, and it isn't played per rock. It's a plain
  one-shot, deliberately unlike the engine loop: neither `finish_scan()` nor
  `cancel_scan()` stops it early.
- **The clip is 2.0 s — deliberately cut to match the scan's own length**
  (`computer_modules.lua`'s `scan_time_s = 2`), so the sound ends as the scan does.
  It replaced an earlier 4.8 s take (`16_scanning_background_only.wav`) that
  overhung the scan; that file is now unreferenced and can be deleted.
- **The engine loop's pitch scales with thrust level** (per direct instruction:
  *"scale the engine pitch with thrust level"*), from the recorded pitch at idle to
  **+20% at full thrust** (`ENGINE_PITCH_MAX = 0.2`). Thrust level is the *commanded*
  speed as a 0..1 fraction of the ship's unboosted top speed, so it rises smoothly
  with the throttle and clamps at the top — boost commands above top speed, so it
  holds at +20% rather than running away. It rides the same thrust-vs-speed rule as
  the loop itself: idle (0) both silences the loop and resets the pitch, and the
  pitch is re-applied every frame while thrust is held so it follows the lever.
  There is no `sound.set_speed()` — unlike `pan`/`gain`, `speed` is a component
  property — so it's written with `go.set` (`main/audio.lua`'s `M.set_speed`).
  **Verified against 1.13.1's `comp_sound.cpp`** that this is safe to do per frame:
  `SoundSetParameter(PARAMETER_SPEED)` updates the component *and* retunes every live
  voice (`dmSound::SetParameter`), so an already-playing loop follows the throttle
  live rather than only on the next `sound.play`. The 0→1→1.2 mapping was checked
  standalone with `luajit` (idle, half, full, boost-clamped, below-min-thrust, and
  zero/nil top-speed safety).
- **The engine loop uses `19_engine_continuous_three_loops.wav`** (18 s, three
  seamless loops, per direct instruction), replacing the earlier 12 s
  `12_movement_loop_preview.wav` preview take — which is now unreferenced and can
  be deleted. The component keeps `looping: 1`/`loopcount: 0`, so the single
  three-loop clip plays indefinitely while thrust is held.
**Spatialisation (decided — camera-relative pan + gain, per direct instruction)**

Every sound is positioned in the world, each at the origin that actually makes it:

| Sound | Origin |
|---|---|
| Weapon fire | The **firing weapon's own mount** |
| Asteroid breakup | The **rock's own position** |
| Scan | The **analyser's fitted slot** |
| Engine loop | The **rear of the ship** |

- **The constraint that shapes this**: Defold's built-in sound system has **no
  listener and no 3D position**. A component's only spatial controls are `pan`
  (-1..1, i.e. ±45°) and `gain`; `sound.play` accepts both, and `sound.set_pan`/
  `sound.set_gain` retarget an already-playing voice (verified against the pinned
  **1.13.1** engine source, `script_sound.cpp`). True 3D positional audio —
  elevation, HRTF, occlusion — would need a native extension (OpenAL, or FMOD).
  **Not adopted**, because it would add a native dependency to a Docker build that
  has already failed once fetching one, and FMOD additionally adds megabytes and
  licensing terms. The built-in pan/gain route is the technique Defold's own engine
  team recommends for positional audio.
- **`main/audio.lua`** is the one place that does the maths, shared by
  `player_ship.script` (the listener) and the world hubs `asteroid_hub.script` /
  `shot_hub.script` (the world sounds).
  `M.mix(world_pos)` returns pan and gain for a world position; `M.play` plays a
  one-shot at a position; `M.play_loop`/`M.update_loop` drive a positioned loop.
- **The listener is the chase camera, and its own axes drive everything**: pan is
  the dot product of the unit direction-to-source with the listener's own local
  `+X` (`RIGHT`), and gain falls off linearly from full at 20 m to silent at
  2,000 m (both placeholders). Because it's derived from the listener's basis and
  not from any assumption about where the camera sits, **a future camera mode
  changes the panning for free** — a camera looking up from below the ship flips
  left/right automatically, with no change to `audio.lua`. This was the deciding
  factor in choosing this approach over the extensions.
- **A sound dead ahead and one dead astern both pan centre** — correct for a
  left/right control, and the reason elevation can't be represented (a rock
  directly above pans identically to one directly below; height only shows up
  through distance). Flagged as a known limit (§4).
- **Origins come from data, not hardcoding**: weapon and analyser mounts use
  `ships.lua`'s existing `slot_positions` table (the same `{x, y}` the outpost
  screen draws its fitting markers from, `+y` toward the bow), converted to world
  space with the ship's rotation; the ship-local axes (+z bow, +x starboard) are
  the same convention that table already uses. The engine's stern offset is a
  placeholder constant — a real per-chassis value belongs in `ships.lua` beside
  `flight_camera` and `slot_positions` (§4). Ships with empty `slot_positions`
  (Escort/Frigate, §2.1.2) fall back to the ship's centre rather than erroring.
- **One-shots pass pan per-play; the loop drives it through the component.** Two
  weapons can fire in the same frame from one shared component, and each needs its
  own pan — so `sound.play`'s per-play pan (which *adds to* the component's) is
  used, leaving the component at 0. A loop is alone on its component, so it uses
  `set_pan`/`set_gain`, which is what lets an already-playing loop follow a moving
  camera.
- **Verified**: the pan/gain maths was checked standalone with `luajit` against a
  stubbed `vmath` — right/left pan signs, centre for dead ahead/astern/above, the
  ~0.707 pan at 45° off-axis, the 20 m/2,000 m falloff (including clamping to
  silence beyond range), the no-listener fallback (centre, full gain — never
  silent by ordering accident), `attenuate = false` keeping full gain, and the key
  case: yawing the listener 90° re-pans the same world source, proving pan follows
  the camera's orientation rather than any fixed assumption.
- **Verified (build)**: `bob.jar` builds cleanly with all four components,
  `engine_loop.soundc` compiles with looping enabled (`looping: 1`, `loopcount: 0`),
  `scan.soundc` references its `.wavc` correctly, and the served HTML5 bundle's
  archive grew with the new audio. (Note: the growth is *not* exactly the raw WAV
  byte count — bob re-packs the audio, so the archive delta is smaller than the
  source `.wav` total. Compare `build/default/assets/audio/*.wavc` for the real
  packaged sizes.)
- **Not yet verified**: how the panning actually *sounds* in a live session — the
  maths is checked, but the perceptual result (whether ±45° reads as convincingly
  "over there" from the chase camera) is a listening test (§4).

### 2.13 BSGO research — second pass (playbsgo.com, bsgo.fun, both wikis)

Per direct instruction, went back through the two live BSGO revival sites and the
wikis for **game data we don't yet have**. This section records what was found and
what it maps to in this project. As everywhere else (§0), the *mechanics/structure*
are usable; the **names, item text and lore are BSG's and are reference-only** —
anything adopted gets renamed/labelled originally, exactly like Tylium→Hydrogen,
Titanium→Iron, Cubits→Tope, Merits→Valour, Draden→Sensor Range already did.

**Sources read this pass**
- `playbsgo.com` ("BSGO Nova") guides: `game-features.html`, `combat-reference.html`,
  `bonus-handbook.html`, `upgrade-costs.html`, `mining.html`.
- `playbsgo.com/api/public/upgrade-costs` — the live catalogue the upgrade-cost page
  reads from (246 upgradeable items, build 0.0.61; saved to `/tmp/bsgo_upgrade_costs.json`).
- `bsgo.fandom.com` (main wiki): `Weapons`, `Mining`, `Currency`, `Missiles and
  Torpedoes`, `Daily Assignments`, `Skills`, `In-game ranks`, `Platforms`, `Outposts`.
- `bsgonline.fandom.com` (second wiki): `Inventory List`, `Cannon Ammo`, `Missile
  Ammo`, `Viper Mark II` (a full ship stat block), and its page index.
- `bsgo.fun` — the landing page only; it exposes no wiki/database/API (its nav is a
  launcher download). Nothing usable beyond what's already noted.

**A. Combat maths — the biggest gap closed.** `combat-reference.html` publishes the
whole resolution formula, read from a live server, and this project has **no combat
resolution at all** (§4). Everything below is *genre maths*, not creative expression,
so it is directly usable as the starting point for the Nakama combat module:
- Hit chance `= 67.5 + 0.15 × (Accuracy − Avoidance)`, clamped 0.05–0.95. Only the
  difference matters; the 95% ceiling is +183, the 5% floor is −417.
- Effective avoidance scales with throttle for Strike/Escort:
  `Avoidance × max(throttle ÷ top_speed, 0.25)` — a parked fighter keeps 25% of it;
  boosting always restores 100%. Line/capital hulls don't fade.
- Range never changes damage, only hit chance: full chance up to optimal range, then
  linear decay to ~0.01% at maximum range (the 5% floor does **not** apply past
  optimal). Below minimum or beyond maximum the weapon simply won't fire.
- Damage `= roll(DamageLow…DamageHigh) × crit × armour × situational` — a uniform
  roll, no damage types, no resistances, no range falloff. Crit is a flat ×2, rolled
  as `5 + 0.15 × (CritOffence − CritDefence)` (uncapped).
- Armour is linear: `damage kept = (100 − (target_armour − piercing)) ÷ 100`, clamped
  at 0 (surplus piercing is wasted), minimum 0.1% always gets through.
- **Firing arcs are half-angles** on the card (a listed 45 = a 90° cone), and both
  range and arc are measured **from each weapon mount, not the hull centre**. Line
  hulls deliberately can't bring all guns to bear at once. This directly resolves
  §2.8/§4's undecided `angle_deg`/`arc` semantics: our per-slot `angle_deg` should be
  read as a half-angle per mount, and `weapons_autocannons.lua`'s uniform `arc = 75`
  is therefore a 150°-wide cone — flagged in §4 to re-check.
- Power: regen is flat and continues in combat; hull regen is blocked for 15 s after
  taking damage; a refused shot (out of arc/range/power/cooldown) costs nothing.
- Missiles/torpedoes never roll to hit — they are physical objects. Counters: ECM
  (100% no-roll lock break), flares (10%→95% by proximity), point defence (must chew
  through the missile's own hull points), cloak, or outlasting their lifetime. Missile
  hull points: strike 5, strike torpedo 15, capital 25, line 30, heavy 45, carrier
  150, **escort 900** (effectively immune to point defence).
- Per-ship combat reference values worth keeping: avoidance (Viper Mk-II 510,
  Rhino 490, Gungnir 50, Jotunn 30, Pegasus 15), armour (5/10/40/45/60), hull
  (450/715/4,550/4,500/80,000), crit defence (80/120/80/120/200), power
  (100/150/500/750/2,000, regen 5/5/25/25/60, boost 0.5/0.7/6.3/8.1/30 per tick),
  and the minimum-range dead zones (carrier cannon 2,300, escort missile 1,350,
  line torpedo 1,200, carrier flak 900, strike torpedo 600, line flak 500, KKC 100).

**B. Ammunition — a whole system we have none of.** Both wikis and the combat
reference agree on a four-family cannon-round ladder and an ordnance ladder:
- Cannon rounds: **HE** (damage, both ends: +3/+6/−/+15%), **HESC** (minimum damage
  only: +10/+25/+40/+60%), **AP** (armour piercing: +20/+25/−/+50%), **HERT**
  (accuracy: +10/+15/−/+25%). Grade C exists only for Line ships. Because HESC raises
  only the floor, a strong enough grade makes the low end pass the high end and the
  weapon stops rolling entirely — a real, documented quirk.
- Ordnance (missiles, flak, point defence): standard / high-quality (+15%) / master
  (+30%). Support consumables: repair cells, power cells, flares (all +15/+30),
  mines (+10/+20).
- Specialist: radiation packs (+2%, elite +10% decay resistance), escort metal plates
  (+25%/+50% duration), mini-nukes (+400%), torpedo tokens (+1,900%).
- Ammo types are **identical percentages across ship classes** — only the underlying
  weapon differs.
- Torpedo splash is flat (every hostile in radius takes the full roll), no friendly
  fire, and torpedoes also drain energy via EMP.
- Our §2.8 has the `cannon_type` = ordinance/mining split and §4 already lists
  "define the variety of ordinance types" — this is the real taxonomy to build from.

**C. Upgrade economy — real per-level numbers.** `playbsgo.com`'s upgrade-costs page
and its API give the exact per-level cost ladder for all 246 items, which is far
finer than the single placeholder "100 Tope" this project currently charges (§4):
- Two paths: **currency** (always succeeds) and **tuning kits** (a gamble).
  `chance = kits ÷ (cubit_price ÷ 1000)`; a guaranteed upgrade costs
  `ceil(cubit_price ÷ 1000)` kits, and kits are consumed win or lose.
- Levels 1–10 are paid in resources (tylium, sometimes merits); **levels 11–15 can
  only be bought with kits** — the resource path is refused past level 10. Every item
  caps at level 15. This is a clean, directly mappable shape for §4's "real upgrade
  cost/effect": our Tope/Iron/Hydrogen could be the resource path and a new
  "tuning kit"-style item the premium path.
- Cost scales by item tier: Strike weapons ~76,500 cubits / 90,000 tylium over the
  ladder, Escort ~114,550 / 135,000, Line ~153,000 / 180,000, Capital ~105,000 flat.
- `playbsgo.com/guides/upgrade-costs.html` itself is worth re-reading whenever the
  upgrade economy is designed — it also has a working calculator.

**D. Module catalogue breadth — 246 real items in 9 slot families.** The live
catalogue's internal keys confirm whole *slot families* this project has no concept of
(our §2.8 is only weapon/hull/engine/computer, Patrol-tier only, ~15 entries):
- `launcher` (missile/torpedo/rocket launchers), `gun` (machine guns, flechette
  cannons, KKC), `defensive_weapon` (flak, point defence), `special_weapon`
  (anti-carrier nuclear launcher), `role` (bomber/stealth/recharge/outpost-mode
  abilities), plus computer sub-families our schema doesn't name: **buff/debuff**
  (weapon/engine/computer/avoidance), **firewall**, **penetration/emitter**,
  **dradis enhancer**, **resource scanner** (normal + experimental/area), **energy
  capacitor**, **power control unit**, **target designator**, **combat viruses**,
  **repair/recharge**, **jump transponder**. Multi-role/stealth hulls get their own
  distinct equipment sets. Worth folding into §2.8's taxonomy when the module list is
  next expanded.

**E. Real ship stat block — confirms §2.1.1 was a genuine BSGO hull.** The second
wiki's full Viper Mk-II infobox (hull 450, hull recovery 2.5/s, durability 4,500,
armour 5, crit defence 80, avoidance 510, turn 52°/s, turn accel 55°/s², inertia
comp 175 m/s, accel 13.5 m/s², speed 55 m/s, boost 90 m/s, boost cost 0.5/s, FTL
range 4.5 LY / charge 15 s / cost 20/LY, power 100 / recharge 5/s, emitter 100,
firewall 100, sensor 2,000 m, visual 200 m, slots 3W/2H/2C/4E + 1 paint + 1
avionics) is almost exactly this project's own §2.1.1 baseline — which is a useful
sanity check that the baseline was transcribed correctly, and it surfaces two
numbers we lack: **Visual Range** (we use 500 m; the real Viper is 200 m) and a
**paint/avionics slot pair** beyond the four stat groups. Starter loadout is also
recorded (2× light autocannon, 1× light missile launcher, 2× hull plating, combat
module, ECM module, 2× gyro, 2× RCS ducting, 2× mining cannon, 1× scanner).

**F. Economy & progression.** The bonus handbook gives the real multiplier maths
this project will eventually need for its own economy:
- Target-level loot dial `= 2.0 + (level ÷ 255) × 2.0` (2×→4×); cubits
  `= 1.0 + (level ÷ 255) × 1.4` (1×→2.4×).
- **Squad curve**: your share `= 0.5 + 0.1 × pilots`, break-even at 5, 1.50× at 10;
  salvage/equipment/objective rewards are *never* divided.
- Mission tiers stack (daily/weekly/monthly all advance on one kill), and both
  objective and payout scale `1 + (level − 1) × 0.1`, capped at level 50.
- Boosters: +100% each, same-type adds, different-type multiplies, hard 3× ceiling.
- Merits capped 500/day, 7,000/week, overflow converts to a refining currency.
- The level formula `√(XP ÷ 1000) + 1` matches our `ranks.lua` exactly; the wiki's
  rank list (Nugget→Captain, Optio→Tribune) is BSG-flavoured and stays unused — our
  original ranks (§2.2) are already in place.

**G. Skills — 57 skills in 19 groups, each 0–10.** The wiki's full skill list (with
per-level train times and XP costs, ~192,000 XP to max one) is a *genre* progression
design. Note the live revival has since **maxed all skills for everyone** and made
progression come purely from hull + equipment + upgrade level — a useful design
signal, though this project's §2.2 skill-tree intent is still open.

**H. Assignments — real objectives, targets and reward shapes.** The wiki's daily
assignment list (Asteroid Recon, Disable Weapon Platforms, Disrupt Enemy Operations,
Drone Clearance, Freighter Interception, Intercept Enemy Patrols, Mining Disruption,
Regional Combat Patrol, Salvage Recovery, Supply Allocation, System Patrol, Resource
Extraction) with their level-scaled target ranges (e.g. scan 20→100 asteroids) is a
ready-made shape for expanding our 3-entry `assignments.lua`; our `Asteroid Recon`
already mirrors it. The live revival adds weekly/monthly tiers and a dynamic wartime
Regional Combat Patrol layer.

**I. Platforms & outposts — real structure for §2.7's deferred outpost combat.**
The wiki gives concrete platform tiers (Light/Medium/Heavy × Interdiction/Sentinel/
Guardian/Suppression, levels 12–20, hull 1,250–8,750, power 500–1,000) and outpost
control levels 0–10 tied to an outpost-progress counter (capture at 50%, outpost
appears at 90%, fortification and 4 heavy sentry platforms by 300%), including the
±36% dominant/underdog hull scaling. This is exactly the design material §4's
"design outpost combat" TODO was waiting for.
- **Sentry platform armament** (read per-platform from `bsgonline.fandom.com`'s
  `*_Sentry_Platform` pages, agreeing with the main wiki's `Outposts` page):
  - Light: 7,500 hull / 3,000 power / armour 35 — 8× 20 mm autocannon turrets +
    2× interceptor missile launchers.
  - Medium: 10,000 hull / 3,000 power / armour 60 — 8× 127 mm cannon turrets +
    5× medium missile launchers.
  - Heavy: 15,000 hull / 3,000 power / armour 75 — 2× 63 mm flak cannons + 2×
    15 mm point-defence turrets + 8× 40.6 cm cannon turrets + 5× heavy missile
    launchers.
  (The two wikis disagree on whether heavies first appear at control L7 or L8/250%.)
- **The outpost core's own armament** (both wikis): long-range cannons, long-range
  missile launchers, point-defence batteries; power 4,500, visual range 1,300 m.
  BSGO Nova's `game-features.html` frames fortification as an outpost score of
  0–3,000 (active at 900, jump beacon at 1,000, "fortified hull plus four heavy
  platforms" at 3,000); `combat-reference.html` confirms platform guns are
  omnidirectional (arc ≥180°) with the platform's point defence at ~700 accuracy.
- **Generic weapon platforms** (main wiki's `Platforms` page — a related AI-defence
  shape): dormant until attacked or a ship is within ~1,200 m; light gun range
  ~1,600 m, heavy ~2,000 m, missiles ~3,500 m; no hull regen; respawn in place after
  ~10 min; Guardian = 2 cannons + 1 launcher, Suppression = 2 cannons + 2 launchers;
  hull/power tiers Light 1,250/500, Medium 4,250–5,750/750, Heavy 7,250–8,750/1,000.
- Folded into a concrete proposal in §2.7 ("Outpost defence (proposed)") and left as
  an open §4 item; not implemented.

**J. Mining, planetoids and the event loop.** Planetoid mining (scan → call a mining
ship for a fee → defend it from escalating waves → it breaks up when drained) is a
whole PvE loop this project has no concept of; §2.11 is asteroid-only today. The
four live events (Fleet in Distress, Drone Nexus, Guardian Basestar, Typhon
asteroids) and DRADIS Interdiction are likewise new shapes. Scan colours (red none /
yellow tylium / purple titanium / blue water) match our §2.11 resource colours and
confirm the four-resource scheme.

**K. Item shop pricing (second wiki).** The Inventory List gives real buy/sell
prices (Tuning Kit 1,000 cubits, Comm Access 300, Technical Analysis Kit 500;
salvage sell values 7.5→4,800 tylium across ten grades; the full booster price list),
useful for the per-item pricing §4 still has as a flat placeholder.

**Not usable / deliberately excluded**: all ship, faction, character, place and
item *names*; the rank names; the lore text; the ship silhouettes. `bsgo.fun` gave
nothing beyond a landing page. The revival sites are fan projects and their *numbers*
are their own tuning (the pages say so explicitly), so treat every figure as a
starting point, not gospel — same caveat as §0's research rule.

### 2.14 In-flight HUD ship diagram — interactive module toggling (decided, per direct instruction)

The flight HUD's bottom-left ship diagram (§2.10.1's `main/flight_hud.gui_script`) is
now **interactive**: hovering a fitted slot shows what it is and how to toggle it,
and clicking it does the toggling — the same job that slot's own key already does,
just reachable with the mouse. Reuses the existing diagram rather than adding a
second panel; the outpost screen's own ship-visual markers (§2.8.1) remain a
separate, docked-only rig.

- **Hover tooltip**: hovering a usable marker shows the fitted module's name and its
  key. The Shift modifier is drawn as an **icon** box (`main/images/icons/key_shift.png`,
  generated by `tools/build_module_icons.py`'s new `draw_shift_key()` and added to
  `main/images/icons.atlas`) placed **before** the digit, per direct instruction — not
  the literal text "Shift+". The tooltip is a shared set of nodes
  (`tooltip_bg`/`tooltip_name`/`tooltip_shift`/`tooltip_key`) created once and
  shown/hidden/re-filled per hover (`update_tooltip`).
- **Click to toggle**: a click on a usable marker posts `slot_click { slot = ... }`
  to `main/player_ship.script`, whose `on_message` routes it to `toggle_slot()`:
  a weapon flips `self.weapons_on[slot]` and flashes `<name> (Wn) ON/OFF`; an active
  module runs (`activate_module_slot`); a passive module reports `IS PASSIVE (ALWAYS
  ON)`; an empty slot reports `NOTHING FITTED`. Identical outcomes to pressing the
  slot's own key (`Shift+n` for weapons, the computer/engine/hull key for modules),
  which still works unchanged — the diagram is an additional pointer path to the one
  `toggle_slot`, not a parallel implementation.
- **Only usable markers react**: `marker_at()` hit-tests with `gui.pick_node` against
  the marker's octagon `box` and refuses any marker whose `usable` is false (no
  module, or a locked slot), so empty/locked slots neither hover nor click. A hit
  returns `true` from `on_input`, consuming the touch so it can't also fall through
  to the ship's own left-click targeting (`pick_target`, §2.10).
- **Input-focus real bug, found via live testing**: the HUD's gui component is
  disabled in `init` and only enabled by `show_flight_hud`; a **disabled** gui
  component silently ignores `acquire_input_focus`, so the HUD never joined the input
  stack and `on_input` was never called (clicks and hovers did nothing). Fixed by
  re-posting `acquire_input_focus` from `update()` for the first few frames after
  enabling (`self.focus_retry`), which reliably lands the HUD on top of the stack.
  Same root-cause class as §3.5's other automation findings: the code looked correct,
  only the live engine showed the missing focus.
- **Also (same file, separate small change)**: the flight HUD gained a
  `build_version` readout in its top-right, its text set from `main/version.lua` so
  the running build is identifiable in flight — matching the login screen's own
  version label.
- **Drawn at 66% (decided, per direct instruction)**: the whole bottom-left diagram
  — the panel background, the silhouette, the marker boxes, the key labels, the
  cooldown bars and the hover tooltip — is now drawn at **66%** of its authored size.
  One factor, `DIAGRAM_UI_SCALE = 0.66`, drives it: every full-size (100%) pixel
  constant in `main/flight_hud.gui_script` (`MARKER_SIZE`, `KEY_LABEL_OFFSET_Y`,
  `SHIFT_ICON_SIZE`, the tooltip sizes/offsets, the cooldown-bar geometry, the key
  and icon x-offsets) is passed through a small `ui(v)` helper, and `DIAGRAM_SCALE`
  becomes `0.8 * DIAGRAM_UI_SCALE`. Scaling the markers by the same factor is what
  keeps them from colliding — shrinking only the diagram would pull the 60px markers
  closer together while they stayed full size. The panel's **bottom-left corner is
  held fixed** (not its centre) so the smaller widget stays tucked into the screen
  corner rather than floating inward; its derived centre (143.7, 226.2) and size
  (257.4, 422.4) are mirrored onto the authored `diagram_panel` node in
  `main/flight_hud.gui`.
- **Verify noted**: slot clicks were confirmed live (`on_input` reported the touch at
  the W1 marker's own screen coordinates, and `gui.pick_node` hit). The tooltip's
  exact on-screen appearance and any touch-device equivalent of "hover" are not yet
  checked (touch has no pointer-move hover) — see §4.

### 2.15 Space dust starfield (decided, per direct instruction)

While flying and moving, a Starfield of dust speckles now streams past the ship, so
speed actually reads as speed. Per direct instruction it travels proportional to the
ship's own speed and **always along the ship's long axis, not where the camera is
looking**. It started at **2× the ship's speed**, was **halved to 1×** on direct
instruction, and while the ship is idle the motes are **left in place** (also per
direct instruction — an earlier version hid them; that was changed to leaving them
exactly where they are).

- **New files**: `main/starfield.script` (the manager), `main/starfield.go` (the hub:
  the script plus a `dust_factory`), and `main/starfield_dust.go` (one mote — a `model`
  component reusing the existing asteroid mesh and light/tint path, so no new art is
  introduced, §0). The hub is a new `starfield` instance in `main/main.collection`,
  alongside `shot_hub`/`asteroid_hub` — the same "one hub owns one effect" split
  (`shot_hub` owns tracers, `asteroid_hub` owns rocks).
- **World-space motes** (this replaced an earlier ship-local field that had a real
  bug): each mote keeps a real **world position**. Every frame it is translated along
  the ship's CURRENT front-to-back axis (front = `+Z` — the same convention
  `ships.lua`'s `slot_positions` and `player_ship.script`'s `SHIP_FORWARD` use) by
  `DUST_SPEED_FACTOR = 1.0` × the ship's speed, but its position is **never rotated by
  the ship's rotation**. A mote that leaves a slab around the ship — behind it
  (`FIELD_BACK = -120`), too far ahead (`FIELD_FRONT = 80`), or too far off the axis
  (`FIELD_RADIUS = 30`) — is recycled to a fresh random spot ahead of the bow, so the
  field follows the ship without running out or visibly repeating.
- **Real bug — the dust swung sideways on a turn** (found live, per direct
  instruction: *“when I turn the ship left the particles also appear to move to the
  left”*). The first version stored each mote as a **ship-local offset** and rebuilt
  its world position as `ship_pos + ship_rot * offset` every frame, which made the
  whole field a rigid body welded to the hull: yawing the ship yawed every mote with
  it, so dust that had been dead ahead swung left exactly as the ship turned left.
  The fix is the world-space model above — a turn now changes only the **direction**
  the dust travels (it always tracks the hull's current axis), never yanks the dust
  sideways. Written up and guarded by a harness test (below).
- **Why the ship's axis, not the camera's**: the chase camera deliberately **lags**
  the ship through a turn (§2.10.1's smoothed `camera_rot`), so orienting the effect
  off the camera would swing the streaks sideways whenever the camera caught up — the
  dust would look like it blew out of the turn. Tracking the ship's own axis keeps the
  dust running straight down the hull's length from any camera angle, which is exactly
  what the instruction asked for.
- **Idle leaves the field in place**: `IDLE_SPEED = 0.5` m/s; below it `update()`
  returns early, so the motes are neither moved nor recycled nor hidden — a
  stationary ship keeps the field exactly where it was (per direct instruction; an
  earlier version disabled the field here instead). The pool is built once at launch
  (`"start"`), so the field is already there from the first frame of the flight.
- **Speed source, and teleports**: the hub reads the sibling `player_ship` instance's
  own transform (`go.get_position`/`go.get_rotation` — no per-frame message and no
  shared module needed) and derives speed from its frame-to-frame movement,
  `length(pos - prev_pos) / dt` — which *is* the ship's actual speed (the same value
  `self.speed` converges to). A launch or a jump teleports the ship, which would
  otherwise read as one enormous frame speed and fling the whole field, so any move
  above `TELEPORT_SPEED = 500` m/s is treated as a teleport (the field simply follows,
  with no streak) rather than a real velocity.
- **Life-cycle**: `player_ship.script` posts `"start"` to the hub in `start_flight()`
  and `"stop"` in `complete_dock()` (which docking, quitting and destruction all
  route through). While docked the flight camera is off and the outpost screen is up,
  and the world is drawn with the default render camera there — so the field is
  **disabled** when stopped, or its motes would float over the outpost menu.
- **Budget note**: the pool is `DUST_COUNT = 60` (halved from 120 on direct
  instruction), each mote a separate `model` draw call, on top of the asteroid field
  and the ships — well under `game.project`'s `[model] max_count = 512` today, but
  worth re-checking once larger custom asteroid fields exist (§4). Mote sizes were
  halved on direct instruction too: `DUST_SCALE_MIN`/`DUST_SCALE_MAX` are now
  0.03125..0.0875, three times reduced from the original 0.25..0.7.
- **Verified standalone, not in-engine**: `tests/starfield_harness.lua` stubs Defold's
  `vmath`/`go`/`factory`/`msg` and drives the real script, asserting: the pool is
  built at launch and **left in place while idle**, the **perceived speed** equals
  `DUST_SPEED_FACTOR` × the ship's speed,
  the **no-sideways-swing-on-a-turn** invariant (a mote's world position is untouched
  by a 90° yaw — the regression test for the bug above), the teleport guard, recycling
  at the field edges, that moving again re-enables the field, and that `"stop"`
  disables it. The actual on-screen look (mote density/size against the real camera)
  has not been seen in the engine yet.

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
    game.project          # engine + Poki SDK + Nakama client SDK config ([mesh] count too)
    main/
      main.collection      # embeds start_screen + faction_select + outpost + the previews
      main.script          # unused so far
      start_screen.gui         # §3.2 boot screen
      start_screen.gui_script
      faction_select.gui         # §1.1 guest faction-choice screen
      faction_select.gui_script
      outpost.gui                # §2.8/§2.9 fitting + Ships tabs
      outpost.gui_script
      flight_hud.gui             # §2.10.1 in-flight HUD
      flight_hud.gui_script
      flight_map.gui             # §2.7 star map, opened with N
      flight_map.gui_script
      player_ship.script         # §2.10.1 movement + chase camera + §2.12 engine loop
      asteroid_hub.script        # §2.11 spawns/despawns the field, owns the asteroid audio
      shot_hub.script            # §2.8/§2.12 renders weapon tracers + the firing sound
      starfield.script           # §2.15 moving space-dust starfield (ship-local field)
      starfield.go               # §2.15 the starfield hub (script + dust factory)
      starfield_dust.go          # §2.15 one dust mote (model, reuses the asteroid mesh)
      asteroid.script            # §2.11 per-rock buffer resource + breakup timer
      asteroid_geometry.lua      # §2.11 pure-Lua seeded rock generator
      network.lua                # §3.3 Nakama client: ops, state, prediction
      session.lua           # §3.2's in-memory guest session state
      data/                # §3.1's data tables (star_systems.lua, ships.lua, asteroids.lua, modules/)
      models/              # per-ship hulls (§2.1.2); patrol_1/ is the first
      images/               # atlases + extracted top-down PNGs
    assets/
      audio/                # §2.12 .wav sources + their .sound components
      models/asteroids/     # §2.11 rock.mesh/.material/.vp/.fp + the retained sphere
    input/
      game.input_binding    # flight + UI bindings (§2.10)
    nakama-server/          # §3.3's self-hosted Nakama + Postgres setup
    render/                 # custom render script (ship-preview overlay)
    tests/                  # Lua harnesses + the §2.11 asteroid preview rig
    tools/
      sync_server_rules.py     # copies shared rules from main/ to nakama-server/
      build_*_model.py         # per-model generators (§2.9/§2.11)
    docs/ASTEROIDS.md       # §2.11 implementation/cost detail
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
      weapons_autocannons.lua   -- ✅ implemented
      weapons_launchers.lua     -- ✅ implemented
      hull_modules.lua          -- ✅ implemented
      engine_modules.lua        -- ✅ implemented
      computer_modules.lua      -- ✅ implemented
      ordinance.lua             -- ✅ implemented (cannon rounds, missiles, torpedoes)
  ```
  (The rest of this layout is still just a plan — `ship_classes.lua`, `factions.lua`,
  `resources.lua`, `currencies.lua` and `ranks.lua` aren't written yet; `ships.lua`,
  `star_systems.lua` and every file under `modules/` are.)

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
  fit for the two-currency economy — **Tope** and **Valour** (§2.6) — as separate
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

### 3.5 Browser-automation click testing (decided — root cause found, reusable recipe)

Clicking anything in the running game via the browser-automation tooling (this
session's Chrome extension/CDP-driven tab) silently did nothing for a long stretch —
no errors, no visible response, indistinguishable from the game itself being broken.
It wasn't: the user's own real clicks in the same browser worked the whole time. Root
cause turned out to be **two separate, stacking problems**, both about how automated
input differs from a real hardware click, neither a defect in this project's code:

1. **The Chrome window wasn't getting real OS-level focus.** The tab could be
   "selected"/driven by the extension while the actual window sat behind other
   windows on screen, unfocused at the OS level. `document.hasFocus()` confirmed
   `false` in this state. Confirmed via direct instrumentation that clicks still
   arrived as genuine, browser-trusted (`isTrusted: true`) events at the exact right
   target/coordinates even while unfocused — so this alone doesn't explain a fully
   silent failure, but it's a real prerequisite.
   - **Fix**: an AppleScript that finds the specific Chrome *window* containing the
     target tab (not just `activate`, which can raise the wrong window if more than
     one is open) and raises it:
     ```applescript
     tell application "Google Chrome"
       repeat with w in windows
         repeat with i from 1 to (count of tabs of w)
           if (URL of (tab i of w)) contains "8934" then
             set active tab index of w to i
             set index of w to 1
             activate
           end if
         end repeat
       end repeat
     end tell
     ```
2. **The bigger factor: automated clicks release far faster than a real click.**
   Traced into the actual compiled engine JS (`Galaxy_wasm.js`, this project's own
   `bob.jar`-produced output) and found mouse input is a legacy GLFW-style shim whose
   button-changed handler gates on a callback slot (`GLFW.mouseButtonFunc`) that
   turned out to be dead/unused in this engine version either way — but the real
   effect observed was that a synthetic press-and-release completing in ~2ms (this
   session's default browser-automation click) can complete entirely **between** two
   of the engine's own per-frame input polls, so the "pressed" state is never
   observed at all. A real human click naturally holds the button down for tens of
   milliseconds, spanning several rendered frames.
   - **Fix**: hold the synthetic mousedown for a real duration (~250ms) before
     releasing, dispatched as a genuine `pointermove`→`pointerdown`/`mousedown`→
     (wait)→`pointerup`/`mouseup`→`click` sequence via page JS (`dispatchEvent` on
     the canvas), not the automation tool's default instant click.

**Confirmed as the actual fix, not a guess**: with both applied, automated clicks
navigate the full game correctly (start screen → faction select → outpost tabs →
opening/closing the ship detail modal), matching what the user's own real clicks
already did.

**Reusable recipe for future sessions** — before any automated click-testing of this
project:
1. Run the window-raising AppleScript above (swap the URL substring for whatever's
   being tested).
2. Use a held-down synthetic click (mousedown → wait ~250ms → mouseup/click) instead
   of an instantaneous one, for every click, not just the first.
3. If a page ever stops responding to automation mid-session (see §2.8.9's own
   account of a genuine engine freeze), a plain reload isn't always enough to recover
   the *automation connection* itself — closing the tab and opening a fresh one, then
   reapplying steps 1–2, resolved it when a reload alone didn't.

## 4. Open Questions / TODO
- [ ] Tune real weapon firing-arc numbers (§2.8): `ships.lua`'s per-weapon-slot
      `angle_deg` (bearing the mount points, still placeholder on Patrol
      Interceptor's W1-W4) is still undecided real layout. `weapons_autocannons.lua`'s
      per-weapon `arc` (cone width) now defaults every auto cannon to a uniform
      `75` (decided, per direct instruction) rather than a value tuned per weapon -
      revisit once individual weapons need to differ. No targeting/firing/
      line-of-sight code reads either field yet (combat resolution doesn't exist
      at all yet, see below).
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
      and increments an instance's `level`, but has no cost (Tope? materials?) wired
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
- [x] ~~Clarify whether Tope is general-purpose or Water-scoped~~ — resolved:
      Tope is earned from combat/mining/dailies/selling Water/real money — a single
      general-purpose currency (Marque abandoned and folded into it); see §2.6.
- [x] ~~Confirm **Valor** as the final name for the PvP-only currency~~ — resolved:
      **Valour** (British spelling, per direct instruction).
- [ ] Confirm final yield/conversion rates across Hydrogen/Iron/Water →
      Tope/Valour and crafting material, using the researched BSGO structure
      in §2.6 as a starting point only (not copied 1:1).
- [ ] Define which specific purchases require Hydrogen alone vs. Hydrogen+Tope
      together, now that Hydrogen is a direct-spend resource rather than a
      Tope-source (§2.6).
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
      objective (§2.5) grants a Valour bonus exactly as researched, and tune the
      PvP-kill Valour amount vs. the Valour-bonus-for-siege-objectives ratio.
- [x] ~~Decide whether Robots pay out Tope on defeat~~ — resolved for now: no.
      Tope has exactly two sources (selling mined Water, real-money purchase);
      Robot kills, combat rewards, and daily assignments are not currently Tope
      sources (§2.6).
- [x] ~~Design a pay-to-win mitigation for Tope~~ — moot: the no-pay-to-win stance
      itself is abandoned (§2.6). Real-money Tope purchases can buy fitting/upgrades
      without restriction.
- [x] ~~Define fitting-slot counts for Patrol 1~~ — resolved: W=3, C=2, E=3, H=2
      (started from Viper Mk II standard tier, H then bumped 1→2, see above).
      Escort 1 exists now too, but with slot counts deliberately left undefined
      (§2.1.2) — Frigate/Carrier still fully open, no ships exist for those classes.
- [ ] Define concrete power-pool mechanics: capacity per ship class, regen rate, and
      cooldown durations per module type/subtype.
- [x] ~~Populate actual module entries~~ — **weapons done**: three combat auto cannon
      variants each for Patrol/Escort/Frigate (§2.8) and a general + nuclear launcher
      pair per class (`weapons_launchers.lua`); hull/engine/computer modules remain a
      first pass (Patrol-tier hull entries, the Asteroid Analyser).
- [ ] Design real combat stats for the **Escort/Frigate** auto cannons and every
      launcher: the reference published none (§2.8), so those entries are
      identity/fitting data only so far — same open question as the Carrier mining
      cannon. Decide whether to extrapolate from the Patrol tier (as the mining
      cannon ranges already do: 600 → 900 → 1350 m) or source real numbers.
- [ ] Give the new weapon variants their own icons — every combat auto cannon and
      every launcher currently placeholder-shares the one "Octagon Cannon Spaceship"
      region.
- [x] ~~Define the variety of **ordinance** types and their specs~~ — **weapons-side
      done**: `ordinance.lua` now holds the four real cannon-round families (HE/HESC/
      AP/HERT with §2.13B per-grade bonuses), four missiles (interceptor/heavy/siege/
      dumbfire rocket), a baseline standard round and the Nuclear Torpedo. Still open:
      mines, support consumables (repair/power cells, flares), the master/high-quality
      ordnance ladder, and *how much* ammo a ship carries (inventory/ammo counts).
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
      ("Gopher") — hull/engine/computer slots stay empty. The screen shows the
      home system name (Sol/Polaris, §2.7), the faction + ship label, and a 3-tab
      fitting view (**Installed** / **Owned** / **Shop**, §2.8), with a **Launch**
      button. Launch doesn't do anything yet — flight mode isn't built.
      - Verified: clean `bob.jar build` (all files compile) plus runtime data-flow
        tests in plain `lua` (faction → home system name → ship class → all three
        tab lists all resolve correctly end-to-end).
      - **Since superseded**: the tab set described above (Installed/Owned/Shop) is
        the very early version; by the time Ships/Sell/Confirm/etc. were added the
        real tabs had become **Fitting** (ship visual + Shop/Owned lists, §2.8) and
        **Ships** (Ships For Sale/Owned Ships, §2.1.2) — see §2.9.1 below for the
        third tab, **Overview**, added after that and made the default.
- [ ] Implement the guest Nakama session as genuinely ephemeral/throwaway (per §3.3)
      — verify it never gets written to a persistent user/device table, only Nakama's
      normal device-auth path should ever do that.
- [ ] Write a privacy policy/ToS covering registered-account data (email/password,
      saved history/achievements) now that a real backend with real user data exists.
- [ ] Design the specific server-authoritative Nakama match modules needed for combat
      resolution, module power/cooldown/wear enforcement, and siege/economy state
      (§3.3), rather than trusting client-reported outcomes.
- [ ] Apply the reference weapon fields recorded but not used yet in combat —
      `Accuracy` (400), `CriticalOffense` (100, or the −P curve 100→150), `Durability`
      (2500→5000) and the mining `Mining` ×5 multiplier (§2.8). Until then the three
      Patrol −P models play identically to their base model.
- [ ] Clarify whether non-nuclear torpedoes exist alongside missiles, or if
      "torpedo" currently means "nuclear torpedo" only; and whether the
      general-purpose launcher can fire both missiles and any non-nuclear torpedoes.
- [x] ~~Define the Nuclear Launcher / Nuclear Torpedo as their own concrete module +
      ordinance entries~~ — done: `nuclear_launcher_<class>` entries in
      `weapons_launchers.lua` (`launcher_type = "nuclear_launcher"`, otherwise
      identical fitting rules to the general launcher — no extra ship-class gating),
      and a `torpedo_nuclear` entry in `ordinance.lua` restricted to them. Stats still
      open: the reference published no torpedo numbers, and the Valour gate (§2.6) is
      not wired up yet.
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
      Ordinance-type Auto Cannon + one Mining Cannon (now the reference's
      **"Gopher"** / "Gouger"), not two of the same (§2.8).
- [x] ~~Confirm "Prospector" as the Mining Cannon's name~~ — resolved, then
      superseded twice: the Patrol-tier mining cannon passed through "Prospector" →
      "Digger" → and is now the reference's **"Gopher"** / "Gouger"; "Prospector"
      remains the (not yet built) Carrier-tier mining cannon — see the mining
      naming-scale table above (§2.8).
- [x] ~~Name the basic combat Auto Cannon~~ — resolved, then superseded by the
      "exact reference names" pass: the basic combat Auto Cannon is now **MEC-A6
      "Fang"** (Accord) / **Type A "Aggressor"** (Swarm) (§2.8). Earlier names in
      turn: the insect scheme (Gnat/Hornet/Locust), then the invented `AC-P "Tempest"`
      / `Type P "Stalker"`.
- [ ] Confirm the Asteroid Analyser's `behavior = "active"` (proposed to match the
      `activate_scanner` key binding, §2.8/§2.10) — flag if it should be passive.
- [x] ~~Wire up actual install/purchase interaction on the outpost screen~~ —
      resolved: drag-and-drop from Owned/Shop onto a matching slot (§2.8), modeled
      on the reference project's in-flight component panel.
- [ ] Define real, per-item Shop/ship pricing — currently a flat placeholder Tope
      price for any module (100) and any ship (500) regardless of what it actually
      is, not real per-item economy design (§2.6.1).
- [ ] Wire up real mining/repair/FTL-boost mechanics that actually spend/earn Water,
      Iron, and Hydrogen (§2.6.2) — all three are currently static display-only
      balances (500 each, never touched after character creation); also reconcile
      their placeholder starting values against `repair_cost_iron = 10000`
      (`main/data/ships.lua`), which is on a completely different, unreconciled scale
      since nothing spends against either number yet.
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
- [ ] Define real per-ship pricing for the Ships tab's For Sale list — currently a
      flat 500-Tope placeholder regardless of ship class, same as module Shop
      pricing (§2.6.1).
- [x] ~~Build flight mode~~ — resolved: the outpost Launch button hands off to
      `main/player_ship.script` (movement + third-person chase camera, §2.10.1),
      which now also carries targeting, weapon firing, docking, the FTL jump, the
      in-flight HUD (§2.12–§2.14) and the starfield (§2.15). Combat resolution,
      ammunition and real lighting remain open, tracked as their own items below.
- [ ] Tune the starfield (§2.15) against a real flight: `DUST_COUNT` (60), the mote
      size range, `FIELD_RADIUS`/`FIELD_FRONT`/`FIELD_BACK`, `IDLE_SPEED` and
      `DUST_TINT` are placeholders chosen for legibility, not measured — the speed
      factor itself is per direct instruction. Also re-check `[model] max_count = 512`
      with the dust pool, the asteroid field and the ships all live at once.
- [ ] Give the in-flight HUD diagram's hover tooltip (§2.14) a touch equivalent —
      touch has no pointer-move, so on a phone/tablet the tooltip never appears
      (click-to-toggle still works).
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
- [ ] Implement the proposed outpost defence (§2.7, reference data in §2.13 I): an
      armed outpost core plus up to 4 graded sentry platforms. Decide the
      fortification/control-point scaling, whether platforms are separate
      server-side targets or folded into the outpost's own numbers, and the
      defensive AI (dormant until ~1,200 m, ~1,600–2,000 m guns, ~3,500 m missiles,
      no hull regen, ~10 min respawn). The attack side already exists
      (`nakama-server/modules/outposts.lua`, §2.7); only the defensive layer is new.
- [ ] Tune the outpost corner-placement inset (`M.OUTPOST_CORNER_FRACTION = 0.8`,
      §2.7) — currently a placeholder, not real level-design placement.
- [ ] Confirm the opposing-ship population cap value (`M.OPPOSING_SHIP_CAP = 50`,
      §2.7) — explicitly called out as TBC, needs real balancing.
- [ ] Design server-side enforcement of the population cap (counting live ships per
      system in real time) as one of the Nakama match modules (§3.3).
- [ ] Decide the spawn concept for a faction entering a system where it has no
      outpost (the population-capped zone, §2.7) — `M.spawn_points` only covers the
      normal has-an-outpost case.
- [ ] Balance asteroid hull and resource yield for real (§2.11):
      `M.HULL_PER_METER`/`M.MIN_HULL` and `M.RESOURCES[].yield` are placeholders, and
      the resource formula is meant to depend on size and the system's threat level
      (§2.7) rather than a flat proportion of hull.
- [ ] Verify live multiplayer mining and mobile-device frame time/memory for the
      procedural asteroids (§2.11). Geometry and mocked lifecycle tests pass and the
      standalone preview was inspected, but a 50-rock default (100-rock home-system)
      field with concurrent breakup debris has not been measured in a real
      multiplayer session.
- [ ] Re-check `[mesh] max_count = 256` (§2.11) now that the two home systems
      override the default 50-rock count with a 100-rock field (`M.OVERRIDES` in
      `main/data/asteroids.lua`): 100 live rocks plus up to 100 deletion-in-progress
      debris is still under the cap on paper, but confirm on-device and review the cap
      before any still-larger override.
- [ ] Balance the four sounds' gain (§2.12) — all are at unity because there was
      no existing mix to match. The engine loop in particular may need to sit under
      the shot/breakup sounds.
- [ ] Delete the now-unreferenced audio sources (§2.12): `16_scanning_background_only.wav`
      (superseded by the 2.0 s `18_`) and `12_movement_loop_preview.wav` (superseded by
      the 18 s `19_`). Both are untracked, so removal is just a file delete once no
      longer wanted as reference takes.
- [ ] Listen-test the §2.12 spatialisation in a live session — the pan/gain maths is
      verified standalone, but whether ±45° pan and the 20 m→2,000 m falloff read as
      convincingly positional from the chase camera is a perceptual check.
- [ ] Move the engine loop's stern offset (§2.12, currently a placeholder constant
      in `player_ship.script`) into `ships.lua` beside `flight_camera` and
      `slot_positions`, so each chassis can define where its own engines actually
      are — the current single value is roughly the Patrol hull's stern.
- [ ] Decide whether elevation should ever be represented in the audio (§2.12) —
      pan is a single left/right value, so a source directly above and one directly
      below are indistinguishable. Only a real 3D audio extension (OpenAL/FMOD) can
      fix this; noted as an accepted limit of the built-in approach, not a bug.
- [ ] Design real lighting for the rock shader (§2.11) — `rock.fp` uses a fixed
      camera-relative key/fill pair as a readable stand-in, same undecided
      "real lighting design (sun direction, ambient)" territory §2.10.1 already flags
      for the ship material.
- [ ] Decide whether mined-out asteroid debris should be audible/visible to other
      players in the system (§2.11) — the breakup is currently local-only, like the
      scan pulse, and nothing broadcasts it.
- [ ] Build a combat-resolution module from the §2.13 combat maths (hit chance,
      throttle-scaled avoidance, range decay, damage roll, crit, linear armour) —
      this is the single biggest system the game still lacks, and the formula is now
      fully known. Must be server-authoritative (§3.3).
- [ ] Add **ammunition** as a system (§2.13B): the HE/HESC/AP/HERT cannon-round
      families and the standard/high/master ordnance ladder, plus support consumables
      (repair/power cells, flares, mines) — nothing exists today beyond §2.8's
      `cannon_type` split.
- [ ] **Launcher/ordnance modules** (§2.13B/D): launcher + nuclear-launcher module
      entries and the shared `ordinance.lua` table now exist (§2.8) — the missile/
      torpedo **object model** is still open: never-miss flight, lifetime, missile hull
      points, and the ECM/flare/point-defence counters, plus rocket packs, mines and
      the defensive-weapon (`flak`/point-defence) family from §2.13D.
- [ ] Add the missing **slot families** to §2.8's taxonomy (§2.13D): launcher, gun
      (MG/flechette/KKC), defensive_weapon (flak/point defence), special_weapon,
      role, and the computer sub-families (buff/debuff, firewall, emitter/penetration,
      DRADIS enhancer, resource scanner, energy capacitor, power control, target
      designator, combat virus, jump transponder).
- [ ] Design the **upgrade economy** using §2.13C: resource path for levels 1–10,
      a tuning-kit-style premium path for 11–15, per-item per-level costs, and the
      kit-success formula — replaces the flat placeholder price in §2.8.2/§4.
- [ ] Re-check `weapons_autocannons.lua`'s uniform `arc = 75` against §2.13A: in
      BSGO the card number is a **half-angle**, so 75 would be a 150° cone — decide
      whether our `arc` means half-angle or full width and make it consistent with
      `ships.lua`'s `slot_positions[].angle_deg`.
- [ ] Reconcile §2.1.1's **Visual Range** (500 m) against the real hull value in
      §2.13E (200 m for the Viper-class hull) — the baseline may have transposed it.
- [ ] Decide whether to add a **paint/avionics** slot pair (§2.13E) — §2.1.2 already
      has `skin_collections.lua`/`skins.lua`, so this may just be wiring, but no ship
      currently declares either slot.
- [ ] Expand `assignments.lua` toward the real assignment list and level-scaled
      targets (§2.13H), and consider the stacking daily/weekly/monthly tier model.
- [ ] Design **outpost control / platform tiers** from §2.13I to close §4's
      "design outpost combat" item, and decide whether to adopt the
      outpost-progress counter and dominant/underdog scaling.
- [ ] Decide whether to add **planetoid mining** as a second, riskier PvE resource
      loop (§2.13J) — currently §2.11 is asteroid-only, and the project has no
      planetoid, mining-ship, or event concept.
- [ ] Tune the squad/reward multiplier maths from §2.13F into the economy once
      loot/rewards are actually implemented.

---

*Maintenance note: update this file as design decisions are made. Keep the IP section at
the top authoritative — if any later section conflicts with it, the IP section wins.*
