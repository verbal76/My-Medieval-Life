# Expansion 18: Settlement Advancement & Regional Economy, engineering plan (SET-A..E)

Prepared 2026-10-21 on `wip/roadmap-docs`, as the Master Expansion Roadmap's immediate documentation action for 18.
Planning only: no code, data or register change. It does not authorize starting Build 18 (OVN-01 section 4 and ROAD-01:
Build 18 starts only after Build 17 qualifies).

Sources: `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.txt` (the PDF beside it is
authoritative; cited as "spec s.N"), `docs/directives/2026-10-20_two_decisions_three_expansions.md`, register entries
EXP-B, SET-A..E, CARAVAN-TMP, B7-014, ECON-P1.3, REC-007, DVW-B3, DVW-B5, DVW-B8, MIN-D, CON-01, OD-28, OD-29,
`docs/EXPANSION_ROADMAP.md`, and `origin/wip/build17` (`0fd94b3`: `docs/build17/MIN_A_ARCHITECTURE.md` section 9 holds
the SET-A schema sketch; `contracts.gd` is CON-01's first slice). Code read at staging `b3bbb1c`.

**Labels.** **APPROVED** (owner source cited) · **PLAN** (this document's engineering proposal) · **OPEN DECISION**
(needs the owner; never assumed) · **FACT** (code or register today).

## 0. Scope and placement

| Phase | Register | Target build (register) | Owner text |
|---|---|---|---|
| SET-A design and ledger | SET-A | 18, gate "needed during 17" | spec s.10 phase A |
| SET-B capability model | SET-B | 18 | spec s.4, s.10 phase B |
| SET-C abstract regional economy | SET-C | 18 | spec s.5, s.7 intermediate phase, s.10 phase C |
| SET-D settlement development | SET-D | 18 | spec s.3, s.8, s.10 phase D |
| SET-E actual inter-settlement network | SET-E | **20+** ("needs a larger world map") | spec s.7 mature phase, s.10 phase E |

- APPROVED: the expansion, its phases and acceptance (spec s.11, s.12 "Approved direction"; owner directive
  2026-10-20). Build 18 = Expansion B (ROAD-01).
- FACT: SET-E is targeted 20+ in the register; the Master Roadmap agrees ("avoid silently promising it in Release
  18"). Release 18 therefore holds SET-A..D. Promising SET-E in 18 would need the owner.

## 1. What exists today (the audit the spec asks for first, s.13)

| Area | Code (staging `b3bbb1c`) | Relevance |
|---|---|---|
| Settlement representation | One village map (`village_map.gd`, `game/data/village.json`, 120x90) plus a generated, chunk-streamed overworld (`overworld.gd`) with no towns. FACT | There is no `Settlement` object; the village is implicit in `World`. Note: "settlement" in `stalls.gd`/`world.gd` means a stall's accounting settlement, a name collision to avoid. |
| Caravan | `NPCBrain.caravan()` every `caravan_every_days` (2) at noon: tops up `World.caravan_purse` by `caravan_allowance` (30) a day scaled by room under `caravan_ceiling_per_head`; ore/coal imports (`_caravan_imports`), stone (`_caravan_stone`), apothecary and seed resupply; buys village surplus within `caravan_coins` and the purse; keeps food reserve days and tools the village needs; EQ-21 buys producers' surplus; `succession_caravan()` brings newcomers for unfilled posts. FACT | SET-C replaces the allowance (CARAVAN-TMP acceptance: "Replaced by demand-driven trade in EXP-B"). The newcomer coupling must survive a caravan that may not come. |
| Money supply | `World` header: coins are created only by the explicit caravan source; `coin_sources` counts them; `caravan_purse` saved since v9. FACT | SET-C changes the only coin faucet. |
| Skills | `skills.json` (`mml-skills/2`): mining, woodcutting, smithing, crafting, cooking, combat, magic, trading, stealth; villagers have skills since save 15 (PAR-01). FACT | No farming, carpentry, masonry, tanning or husbandry skill (DVW-B8 "skills for farming, husbandry, hunting, healing" is a BLOCKED proposal). Capability for those industries cannot be skill-based yet. |
| Jobs and succession | `Population.JOBS` (14 jobs); B8-016 succession (apprentice, then caravan newcomer); EQ-04 guard posts and reeve. FACT | "Knowledge continuity" (spec s.4) partly exists as apprenticeship. |
| Infrastructure | Stations and workshops (`village_map.gd`, `property.gd` workshops, `construction.gd` sites, `stalls.gd`, `carts.gd`, `chests.gd`). FACT | Inputs to capability needs. |
| Finance | Manor treasury (TREAS-01), tax, relief, wages (`npc_brain.gd` evening business), stall commission (STALL-05). FACT | Civic capacity for growth (spec s.8). |
| Measurement | `game/tests/economy_sim.gd` (ledger of coins, goods, animals, deposits; fingerprint), `econ_report.gd`, `conservation_test.gd`, `od16_test.gd`, `exploit_test.gd`, `run_tests.gd`; CI short variant (FR-07). FACT | Acceptance gates for every phase. |
| Saves | `World.SAVE_VERSION` 16 on staging, 17 on `wip/build17`; `SaveTransfer.MIGRATIONS` (empty), `MIN_VERSION` 14. FACT | Every phase that saves state bumps the version after Build 17's. |
| Build 17 (not on staging) | `contracts.gd` CON-01 (goods procurement, reserved coins, partial delivery, lapse); `underground.gd`, `level_map.gd`; SET-A schema sketch (`mml-capabilities/1`) in `MIN_A_ARCHITECTURE.md` s.9. FACT | SET-A starts from that sketch; SET-C should use CON-01 for orders. |

## 2. Dependencies on Build 17

1. **SET-A schema designed during 17** (APPROVED placement, register SET-A gate; `EXPANSION_ROADMAP.md`). The sketch
   exists on `wip/build17`: industries -> levels -> needs (`deposit_access`, `practitioners` by skill or job,
   `tool_stock`, `transport`, `records`, `structure`, `portal`, cross-industry `industry` needs); levels **derived at
   dawn, never stored as truth**; the save keeps last levels and change dates. PLAN: adopt it unchanged as SET-A's
   starting point; MIN-D implements only the mining industry on it.
2. **MIN-C discovery records** with knowledge provenance feed the `records` need. No knowledge system exists (FACT,
   BUILD_17_PLAN). SET-B must reuse MIN-C's record, and later EXP-C's event store, not invent a third.
3. **CON-01 contracts** (APPROVED in principle, OD-28; defaults provisional, OD-29): the caravan's orders in SET-C
   should be CON-01 contracts between a regional buyer party and village sellers. The Master Roadmap warns not to
   substitute Build 17's defaults for the Living Economy's comprehensive model; CON-01's record is already the Living
   Economy's `Contract` in smallest form (FACT, `contracts.gd` header), so this is compatible.
4. **DVW-A12 refactor** (owner direction OD-28): mining, felling and crafting rules move into `core/` first; SET-B reads
   those rules, so it starts after R1-R3 land.
5. **Underground levels** (OD-29): mining level 4 needs a portal (`underground.json`).
6. **Save sequencing**: Build 17 ends at save 17 or later; SET phases bump from there with fixtures from Build 17's last
   version.
7. **Baseline**: Build 16's acceptance seeds and Build 17's final multi-seed runs are the control for SET-C/D
   comparisons (spec s.11).

## 3. Phase plan

### SET-A: design and ledger (during Build 17, design only)

- **Deliverables** (PLAN): `docs/build18/SETTLEMENT_DESIGN.md`; child register entries under SET-B..D (one per
  testable requirement, created when Build 18 is authorized); the `mml-capabilities/1` data format documented in
  `docs/ASSET_DATA.md` (CLAUDE.md section 4); a dependency audit (this section 1,
  refreshed against Build 17's final code); save-compatibility plan.
- **Data model** (PLAN): `game/data/capabilities.json` (`mml-capabilities/1`) as sketched; a `settlements` save section:
  `{id, name, kind: "local"|"regional", levels: {industry: {level, since_day}}, history: [...]}`. The village is
  settlement 0.
- **Files**: docs and the data file only; a validator in `tools/` only if `check_resources.py` cannot be extended
  (CLAUDE.md: one implementation per concern).
- **Tests**: Python schema test in `tests/` (format field, needs vocabulary, no cycles in cross-industry needs).
- **Needs the owner**: nothing to start (approved); thresholds stay OPEN (spec s.12 "to be designed").

### SET-B: settlement capability model

- **Systems and files likely touched** (PLAN): new `game/scripts/core/capabilities.gd` (name chosen to avoid the stall
  "settlement" collision) recomputed in `World._new_day`; reads `NPC.skills` (`skills.gd`), `NPC.job`
  (`population.gd`), inventories (`inventory.gd`), stations and workshops (`village_map.gd`, `property.gd`,
  `construction.gd`), `World.deposits`, MIN-C records, `underground.gd` portals. Gates on actions: `npc_brain.gd`
  (whether a job or recipe is attempted), `world.gd::work_craft` and mining (only where a level is a real prerequisite,
  never a free bonus). Wiki: a new `wiki_settlement.gd` page generated from the data (Rule 008). Manifest: new INT
  entries (`docs/SYSTEM_INTERACTION_MANIFEST.md`, `tools/check_interactions.py`).
- **Knowledge continuity**: reuse B8-016 apprenticeship; levels fall when the last practitioner dies (spec s.4
  "population loss can erode capacity").
- **Tests** (`game/tests/capability_test.gd`): unlock when every need holds; loss of the last specialist drops the level;
  an heir does not inherit skill (PAR-01, Rule 011); a small mining village outranks a larger farming one in mining
  (spec s.11 bullet 2); determinism; save round trip; no coin or item moves because of a level.
- **Risks**: capability as a hidden buff (spec s.9 forbids skills by time elapsed or abstract points); dawn recompute
  cost on Android (bounded: per industry, cached counts).
- **Needs the owner**: Q18-1 and Q18-2 (section 5).

### SET-C: abstract regional economy (replaces the 30-coin allowance)

- **Systems and files** (PLAN): `npc_brain.gd` `caravan()` and helpers (`_caravan_imports`, `_caravan_stone`,
  `_caravan_apothecary`, `_caravan_seeds`, `caravan_line_need`, `succession_caravan`); `world.gd` (`caravan_purse`,
  `coin_sources`, save keys, the header's conservation statement); `balance.json` caravan keys and `_caravan_note`;
  new `game/data/regions.json` (`mml-regions/1`: off-map settlements with distance, population, per-good needs, finite
  stocks, production, purse, restock rules); `contracts.gd` (orders as CON-01 contracts); `economy_sim.gd` and
  `econ_report.gd` (regional ledgers); wiki caravan page (FR-06); `docs/release/LONG_RUN_SIMULATION.md`.
- **Data model** (PLAN): each region `{id, name, distance_days, purse, stock{}, needs{}, production{}, prices{}}`
  saved; a caravan visit is a route from one region with a capacity; orders are contracts priced from the region's
  need, distance and risk; empty trips allowed (spec s.7, s.11 bullet 4).
- **Accounting**: every coin and unit reconciles across village and regional holders (spec s.11 bullet 5). The region's
  restock and income rules are explicit lines in the ledger (spec s.7: "explicit restocking and settlement-accounting
  rules; avoid unexplained daily currency creation").
- **Tests**: `regions_test.gd`: a caravan buys nothing without demand; buys with demand and funds; a cash-poor
  starving town cannot import (spec s.11 bullet 6); exact reconciliation; save round trip; determinism (dedicated RNG
  stream, not `world.rng`, so other streams do not shift). Then 100/365-day multi-seed runs vs the Build 17 control,
  analysed, not pass/fail on prosperity (Rule 022).
- **Risks**: (1) the village's only coin faucet changes; an earlier closed-currency trial failed (B7-014 note), so the
  money supply may contract; this is a legitimate outcome under Rule 022 unless a mechanic is broken; (2) newcomer
  succession currently rides the caravan; decouple it (newcomers arrive by road on their own schedule); (3) imports
  of ore, coal and stone (EQ-09) become demand-dependent, which interacts with Build 17's quarry chain; (4) EQ-21's
  producer purchases must move into the regional model, not be duplicated; (5) overlap with the Living Economy
  (EXP-D, LE-04/LE-05 "merchants", "regional links"): keep one merchant model that EXP-D extends.
- **Needs the owner**: Q18-3, Q18-4, Q18-5.

### SET-D: settlement development

- **Systems and files** (PLAN): `population.gd` (migration in and out; FR-11 is UNKNOWN — INVESTIGATION REQUIRED);
  `construction.gd` and the housing rules (HOUSE-01..09, WDR-020); procedural village validation (PVG-06, OD-14);
  `stalls.gd`, `business.gd` (services); `property.gd`; treasury spending on public works (TREAS-01);
  coin sinks (DVW-B3, target 18) and predictable taxes (DVW-B5, target 18) belong here; classification labels
  (hamlet, village, town) computed, never unlocking technology (spec s.3).
- **Tests**: growth and decline with traceable causes; no automatic unlock at a population threshold; two
  settlements with different profiles (with SET-C's regions as the second and third settlements until SET-E);
  multi-generation runs (spec s.10 phase D evidence).
- **Risks**: SET-D's "settlement types" need more than one simulated settlement; until SET-E, only the village is
  simulated in full and regions are abstract (spec s.7 intermediate phase). Acceptance "at least two settlements
  develop different industry profiles" (spec s.11) must be met with abstract regions or wait for SET-E: OPEN.
- **Needs the owner**: Q18-6, Q18-7.

### SET-E: actual inter-settlement network (register: 20+)

- Requires a larger map (REC-007, DGA-D8), persistent populations per settlement, routes, merchant AI and near/far
  simulation tiers. PLAN: design the `settlements` save section in SET-A so SET-E adds rows rather than a new format.
  Not part of Release 18 unless the owner moves it.

## 4. Cross-cutting

- **Rules served** (`EXPANSION_ROADMAP.md`): 001, 002, 004, 005, 009, 011, 012, 013, 015; plus 022 for every test.
- **Determinism**: dedicated seeded streams per new system; sorted iteration; fixed-point or integer accounting.
- **Multiplayer**: host-authoritative by design (the regional model lives in `World`); no client state.
- **Documentation per phase**: register children, manifest INT entries, Wiki pages, `DECISIONS.md` for any generator or
  save change.

## 5. Decisions needed from the owner (open; none assumed)

| Id | Question | Why it matters | Recommendation (not an approval) |
|---|---|---|---|
| Q18-1 | Do farming, carpentry, masonry, tanning get skills (DVW-B8, BLOCKED) so their capability can be skill-based? | Spec s.4 asks capability from trained residents; only 9 skills exist | Until decided, measure those industries by practitioners (job, tenure) and infrastructure, labelled interim |
| Q18-2 | Capability thresholds and the industries beyond mining in the first release | Spec s.12 lists them "to be designed" | Ship mining plus two (smithing, carpentry), data-driven |
| Q18-3 | Is the region's currency closed (fixed total) or does it have an explicit, accounted income? | Changes the only coin faucet; a closed trial failed before | An explicit regional income line, bounded and reported, so a failing village stays possible |
| Q18-4 | How many off-map regions, with what character (spec s.6 examples) | Defines who demands what | Three fixed regions per world seed, data-driven |
| Q18-5 | Barter and credit for cash-poor buyers (spec s.12 "credit/barter rules") | Spec s.6 "trade may fail without barter, credit" | Defer credit to the Living Economy (OD-LE-05); allow barter only through CON-01 goods-for-goods if approved |
| Q18-6 | May SET-D's "two settlements" acceptance be met by abstract regions, or must it wait for SET-E? | Spec s.11 bullet 2 | Abstract regions for Release 18; full proof with SET-E |
| Q18-7 | Migration out of the village (NPCs leaving for regions) | Population decline path (spec s.3); FR-11 UNKNOWN | Allow, recorded as history; needs EXP-C judgment for the choice, so start with need-based leaving |
| Q18-8 | Confirm SET-E stays 20+ | Release 18 content | Keep 20+ |
