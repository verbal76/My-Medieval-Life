# Owner decision briefs: ECON-P1.1, ECON-P1.2, ECON-P1.4, ECON-P1.5

Prepared 2026-10-21 under the owner's directive `docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md`
(section 7). Nothing here is implemented or approved. Code references are to staging `6607000`.

Labels: **VERIFIED** (current behaviour, read in the code named), **APPROVED** (existing approved design),
**HISTORICAL** (the proposal itself: an agent proposal of 2026-10-18, never approved), **RECOMMENDATION** (this
document's advice), **OPEN** (the owner's decision).

## Where the proposals come from

- **Register.**
  - Each of the four entries in `docs/requirements/requirements.json` has kind "proposal", status BLOCKED and
    approval "agent proposal; not approved".
  - Each source is `docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md`, with the line number in the title: (:71),
    (:72), (:74), (:75).
  - All four have target build 17, with the roadmap reason "older deposit proposals; inputs to the mining phases
    (candidates to supersede by MIN-B..D)".
- **The document.** Written for the owner's directive of 2026-10-18, which asked why the village runs out of ore and
  stone. Its own words (lines 9-10): "**Nothing in the proposals is implemented.** Every proposal and number below is
  an agent proposal, *provisional — balance review pending*, and needs the owner's approval". Last changed in
  `9c13794` (2026-10-18).
- **The finding it answered** (lines 61-65, verbatim):
  > 1. Fixed stock caps instead of demand, plus a caravan that buys everything above half the cap.
  > 2. No stock check before mining, no quotas, and no ownership of the deposits.
  > 3. Before `ae0e01f`, no outside source of stone.
  > 4. Miners change jobs only when every deposit is at zero.
- **One constraint stated under the table** (line 77): "Not proposed: bigger deposits. The owner ruled that out, and it
  would only hide the extraction."
- **What has changed since 2026-10-18 (VERIFIED):**
  - The caravan no longer buys the village's raw ore, coal or stone (`NPCBrain.NOT_EXPORTED`, `npc_brain.gd` line
    69; used in the caravan's purchase loop, line 3566). Root cause 1's "export sink" is therefore gone.
  - The fixed 15-coin buyer floor was replaced by each person's dynamic necessity reserve (OD-19, PAR-02A;
    `World::reserve_of`, `purchase_qty`).
  - Smiths now buy inputs only for recipes they have the skill for, in recipe batches (SHOP-01; `NPCBrain::wants`,
    `batch_unit`).
  - The owner then approved the Mining Expansion (EXP-A, MIN-A..G, 2026-10-20) and, on 2026-10-21, universal
    negotiated contracts and the rejection of a mining-specific wage (directive section 5).
- **Measured today (VERIFIED, from the Build 15 runs recorded in `docs/EXPANSION_ROADMAP.md`):** iron, coal, copper
  and gold seams are worked out by about day 20; stone reaches 0 by about day 160-190. The caravan then supplies ore
  and coal to smiths and up to 20 stone a visit to the raw merchants.

---

## ECON-P1.1: Mining driven by demand

**Exact text** (`docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md` line 71, verbatim):

> | P1.1 | **Mining driven by demand** | A smith's ore target = observed smelting per day × `forge_stock_days` 4. A raw merchant's target = open building need + caravan orders + `market_stock_days` 3 × observed local sales. A miner mines an ore only while orders exceed what miners and merchants hold or carry. After `idle_order_days` 2 without orders, the miner goes to day labour or looks for work. |

**A. The question.** Should villager miners dig only as much as the village is actually using, judged from what the
smiths smelt and the merchants sell, instead of digging whenever a buyer has room on its shelf?

**B. Today (VERIFIED).**
- **What a miner does.** A villager miner keeps mining while some buyer will take the ore (`NPCBrain::_miner`,
  `_buyer_for`).
- **When a buyer has room.** It is below a fixed shelf limit (`NPCBrain.BUYS`: smith iron ore 30, coal 30; raw
  merchant iron ore 20, coal 20, stone 40), counted in recipe batches (`wants`, `batch_unit`), and can pay while
  keeping its necessity reserve (`World::purchase_qty`).
- **Which ore.** It depends only on the first smith's coal-to-iron ratio, plus a 15 % chance of copper
  (`_wanted_ores`). Nothing compares stock with use.
- **Job changes.** Miners change trade only when every seam is empty (`_change_job` to manor hand). The job market
  opens miner places by ore left / 40 (`NPCBrain::job_market`).
- **No export.** The caravan does not carry the ore away (`NOT_EXPORTED`).

**C. The change, as a mechanic.**
- Each smith keeps a running figure of how much ore it smelts a day, and wants four days of that in stock.
- Each raw merchant wants the stone the open building sites still need, plus anything ordered, plus three days of its
  recent sales.
- A miner looks at the total wanted minus what the merchants and other miners already hold or carry, and digs only
  while that is above zero.
- A miner who finds nothing wanted for two days leaves for day labour or other work.

**D. Alternatives.**
1. Keep current behaviour.
2. P1.1 as written.
3. A lighter version: replace the fixed shelf limits with "days of use" targets, but keep miners' choices as they
   are.
4. Leave demand to contracts. Smiths and merchants post ore and stone orders under the new universal contract
   (CON-01, `PROCUREMENT_CONTRACTS.md`), and miners mine to fill accepted orders or to sell. That is the approved
   direction (directive section 5; Living Economy EXP-D: "prices are offers ... accepted orders are real
   obligations").

**E. System-wide consequences of P1.1.**
- **NPC decisions:** miners idle or change trade when the forge is stocked. Their decision depends on a village-wide
  sum, which is global knowledge the Living Economy design forbids ("Never grant every NPC global market knowledge",
  EXP-D section 13).
- **Households:** miners' income falls and becomes uneven. Households with a miner lean more on the necessity
  reserve and on other members.
- **Employment:** more movement between mining, day labour and manor hands. The job market's "open" places shrink
  with demand.
- **Resources:** seams last much longer, roughly in proportion to local use, but stay finite. Depletion still comes,
  only later.
- **Production:** unchanged in amount (the forge's use is the limit); smaller stocks mean more chance of a short
  wait for ore.
- **Prices:** smaller shelf stocks raise the unit price buyers pay (`buy_price_at` falls with stock).
- **Trade:** the caravan's ore and coal imports start later.
- **Money and inventory conservation:** unaffected. Nothing is created; only timing changes.
- **Manor finances:** more manor hands paid from the treasury when miners leave; treasury pressure rises.
- **Long-term equilibrium:** a slower draw on a finite stock. It postpones the import dependence but does not
  remove it.

**F. Engineering.**
- **Work:**
  - New per-smith and per-merchant running averages (saved).
  - A village-wide "open orders" sum each time a miner decides.
  - A two-day idle counter.
  - Three new balance numbers.
- **Touches:** `npc_brain.gd` (`_miner`, `wants`, the labour market), `balance.json`, the save (`SAVE_VERSION`
  bump), `economy_sim` reporting.
- **Tests:** deterministic per seed; a miner idles when targets are met; a 365-day multi-seed run.
- **Risks:**
  - It would be replaced when contracts or EXP-D arrive (wasted work).
  - The global sum conflicts with bounded knowledge.
  - It changes every long-run baseline.

**G. Recommendation.**
- Do not approve P1.1 as a separate formula. Keep current behaviour until CON-01 lands.
- Record P1.1 as **superseded by CON-01 / EXP-D**: demand-driven mining through real orders that miners accept or
  decline.
- Reason: the same goal (dig what is wanted) through the architecture the owner has approved, with local
  knowledge, instead of a stop-gap that would later be removed.

**Question for the owner:**
Approve P1.1, keep current behaviour, or mark P1.1 superseded by the contract system (recommended)?

---

## ECON-P1.2: The manor's mining rights, royalty, quota and stone reserve

**Exact text** (line 72, verbatim):

> | P1.2 | **The manor's mining rights** | Deposits are owned by the manor, as fields and pens are. Mining pays a royalty (`mine_royalty_share` 0.1 of the quote) into the treasury. The daily quota per ore is local need × 1.2. For stone the need includes open building sites plus a `stone_building_reserve` of 60 that may not be exported. The caravan may buy only what is left above that reserve, times `export_share` 0.5. |

**A. The question.** Should the manor own the seams, as it owns the open fields, the market pitches and the surveyed
plots? If so, should every miner pay it a tenth of the ore's price, should mining stop at a daily limit, and should
60 stone be held back from export?

**B. Today (VERIFIED).**
- **Ownership.** The seams belong to nobody: `resources.json` seam nodes say "Nobody: the seams belong to no one (the
  manor's mining rights are only proposed, ... P1.2)" and "Never theft".
- **What the manor does own.** The open fields, the market pitches and the surveyed plots (`World::setup`, `owner =
  MANOR`). It earns from rents, leases and pitches, not from mining.
- **No limits.** There is no royalty and no quota.
- **The stone-export part is already met another way.** The caravan never buys the village's stone at all
  (`NOT_EXPORTED`).
- **The manor's own quarry job.** It takes stone from the seams for its works (`ManorWork::post_quarry`).

**C. The change, as a mechanic.**
- Each seam becomes the manor's property.
- Whoever mines it (a villager, a manor hand or the player) owes the treasury a tenth of the ore's current price for
  each unit.
- Each ore has a daily limit of 1.2 times the village's need, after which mining stops for the day.
- 60 stone is reserved for building and may not be exported; the caravan may buy half of anything above that.

**D. Alternatives.**
1. Keep seams unowned (current).
2. Manor ownership only, with no fee: the manor decides who may mine, through licences or hiring.
3. Ownership with a royalty, without a quota.
4. P1.2 in full.
5. Decide ownership later, with the manor's powers (Living Economy OD-LE-06, "Permissible manor interventions") and
   village politics (VP-01).

**E. System-wide consequences.**
- **NPC decisions:** miners net 10 % less a unit and may prefer other work. With a quota, mining stops when the
  limit is reached, whatever the buyers want.
- **Households:** miners' households earn less.
- **Employment:** the royalty raises the treasury, which pays manor jobs and support. Some money moves from miners to
  manor hands.
- **Resources:** the quota slows depletion. The stone reserve has no effect today, because stone is never exported.
- **Production and prices:** a quota can short the forge on busy days; prices rise as stock falls.
- **Trade:** export rules are already stricter than P1.2's.
- **Money conservation:** preserved (a transfer to the treasury), but every royalty must be one counted transfer.
- **Inventory:** unaffected.
- **Manor finances:** a new steady income, tied to mining and therefore ending when the seams are worked out.
- **Player:** mining the manor's seam without paying becomes taking the manor's property. Whether that is theft is a
  further question (crime is the owner's call).
- **Long-term equilibrium:** a mild brake on extraction and a mild boost to manor spending; seams stay finite.

**F. Engineering.**
- **Work:** an owner on each deposit (saved; older saves default to the manor or nobody); a royalty at the moment of
  mining (simplest, in `World::work_mine`) or at sale (harder, since ore has no origin mark); a daily quota counter
  per ore; theft rules for seams (`ResourceNodes::theft_note`); the journal and wiki texts.
- **Touches:** `world.gd`, `npc_brain.gd` (`_miner`), `manor_work.gd` (quarry exemption), `resources.json` and
  `tools/check_resources.py`, the interaction manifest.
- **Tests:** conservation of every royalty coin; quota reset at dawn; player and villager parity (PAR-01 rule).
- **Risks:**
  - The quota duplicates P1.1's demand logic.
  - The stone reserve is dead code under `NOT_EXPORTED`.
  - Ownership must also be settled for seams found later (MIN-D).

**G. Recommendation.**
- Do not approve P1.2 now. Keep seams unowned in Build 17.
- Its stone-export part is already achieved by `NOT_EXPORTED`, and its quota part duplicates P1.1.
- The ownership and royalty part is a real manor-finance and political mechanic. Decide it with OD-LE-06 (manor
  powers) and VP-01, where who governs the seams can be answered once for fields, woods and mines.
- **One thing does need an answer before MIN-D:** who owns a newly discovered seam. It is listed below.

**Questions for the owner:**
1. Approve P1.2, reject it, or defer ownership and royalty to the manor-powers decision (recommended)?
2. Separately, for MIN-D: is a newly discovered seam nobody's (as today), its finder's, or the manor's?

---

## ECON-P1.4: New seams by prospecting

**Exact text** (line 74, verbatim):

> | P1.4 | **New seams by prospecting** | A seeded, finite list of hidden deposits per map, e.g. 2 iron, 1 coal and 1 stone of 40–80 units each. When known reserves fall below 10 days of demand, the manor pays a miner a day's wage (6) to prospect. Each day reveals the next hidden seam with chance 0.2. A found seam is the manor's, under P1.2. When the list is used up there are no more. |

**A. The question.** Should the world hold a fixed, finite number of hidden seams that are found by prospecting, paid
for by the manor when the known ore runs low, each day's search finding the next one with a one-in-five chance?

**B. Today (VERIFIED).**
- There is no prospecting and no hidden deposit. The 15 seams of `village.json` are all there is
  (`World::setup`); when they are empty the caravan supplies ore.
- Only a seam added to the map after a save was made is appended on loading (`World::load_dict`).
- **APPROVED since:** the Mining Expansion's phases MIN-C (natural clues, a prospector profession, a forge-made
  toolkit, samples and an assay with uncertainty) and MIN-D (finite hidden deposits; settlement mining capability
  levels; NPCs deciding for themselves) cover the same ground in more depth (spec stage 2 and section 8: "A failed
  prospecting venture costs time and resources").

**C. The change, as a mechanic.**
- When a world is made, a seeded list of a few hidden seams is drawn (for example 2 iron, 1 coal, 1 stone, 40-80
  units each).
- When the known ore would last less than 10 days of use, the manor pays a miner 6 coins a day to search.
- Each day of search has a 20 % chance to reveal the next seam on the list, which becomes the manor's.
- When the list is empty, searching finds nothing.

**D. Alternatives.**
1. Keep current behaviour (no new seams; caravan supply).
2. P1.4 as written.
3. MIN-C and MIN-D as approved: clues point to search areas, prospectors with real tools, assays that can be wrong,
   finite hidden seams, ventures that fail.
4. P1.4 as a first, simple step of MIN-D, replaced by MIN-C's richer prospecting later.

**E. System-wide consequences.**
- **NPC decisions:** a new paid task chosen by the manor, not by the villagers. MIN-C has villagers and settlements
  choosing to prospect.
- **Households:** a miner household gains the prospecting wage on search days.
- **Employment:** mining employment lasts longer after the first seams empty.
- **Resources:** adds finite ore (about 160-320 units in the example), not regeneration.
- **Production:** the forge works longer on local ore.
- **Prices and trade:** caravan imports start later and come back once the new seams are worked out.
- **Money:** the treasury pays wages (a transfer).
- **Inventory:** found seams join the ledger.
- **Manor finances:** a cost with an uncertain return.
- **Long-term equilibrium:** a longer local phase, then the same import dependence. It is still finite (WDR-013).

**F. Engineering.**
- **Work:** a seeded hidden list (determinism: its own seeded stream, never `world.rng`, or every later random draw
  shifts); a saved "found" state; the reveal keyed by an id, not (x, y) (the load merge risk in
  `DEPOSIT_SUSTAINABILITY.md`); a place to put new seams (the fixed village has little room; underground levels
  would give room, `UNDERGROUND_ARCHITECTURE.md`); the manor trigger; and whether unfound seams count toward the
  caravan threshold.
- **Tests:** nothing hidden is mineable or counted before it is found; the list is finite; same seed, same
  discoveries.
- **Risk:** building P1.4 and then MIN-C/MIN-D means building prospecting twice.

**G. Recommendation.**
- Mark P1.4 **superseded by MIN-C and MIN-D** (approved and richer).
- Carry two of its ideas into MIN-D's design as inputs, not as approved rules:
  - a seeded, finite list of hidden seams per world;
  - "known ore below N days of use" as one reason a settlement may decide to prospect.
- The ownership of a found seam is the open question listed under P1.2.

**Question for the owner:**
Approve P1.4 as written, or mark it superseded by the approved prospecting phases MIN-C and MIN-D (recommended)?

---

## ECON-P1.5: A distant quarry

**Exact text** (line 75, verbatim):

> | P1.5 | **A distant quarry** | An off-map quarry owned by the manor. A cart trip takes 1 day there and back and carries 20 stone, for one hired hand (6) plus a quarry fee of 0.5 a stone to the manor. Delivered cost is about 1.5–2 coins a stone: a real cost, not free stone. |

**A. The question.** Should the village be able to send a hired hand with a cart to a manor quarry off the map, a
day's round trip, bringing back 20 stone at a real cost of wages and a fee, as a second lasting source of stone?

**B. Today (VERIFIED).**
- **Village seams.** 240 stone in three seams; Build 15 runs reach 0 at about day 160-190.
- **Caravan stone.** Once 10 or fewer remain, the caravan sells the raw merchants up to 20 stone a visit at 2 coins
  each (stone's value 1 x `caravan_stone.markup` 2.0; `NPCBrain::_caravan_stone`). The coins leave the village.
- **Boulders.** They give stone too, but only the player breaks them (`npc_harvest: false`), including the endless
  overworld's boulders (`Overworld::boulder_at`).
- **Villagers cannot leave the village grid** (`VillageMap::find_path`).
- **Handcarts exist** (`carts.gd`).
- **APPROVED since:** MIN-B, under which an exhausted ore seam stays quarryable for ordinary stone (a local, finite
  source). The Regional Economy expansion (EXP-B, Build 18) treats quarries and regional trade as real, finite places
  ("Ecology and land: farming, forests, mines, quarries and wildlife remain finite", its section on dependencies).

**C. The change, as a mechanic.**
- A quarry that is not on the map, owned by the manor.
- A buyer of stone hires a hand (6 coins) who takes a cart there and back in one day and returns with 20 stone; the
  manor charges 0.5 a stone at the quarry.
- Stone delivered costs about 1.5-2 coins a unit.
- The trip would be simulated out of sight, as wildlife refuges move young between woods unseen (`refuges.gd`),
  because villagers cannot walk off the village map.

**D. Alternatives.**
1. Keep the caravan's stone (current; about 2 coins a stone, coins leave the village).
2. P1.5 as written.
3. MIN-B (approved): worked-out seams keep giving stone, locally and finitely.
4. A real quarry in the overworld that villagers walk to. That needs villagers to leave the village grid, an
   architecture step (`UNDERGROUND_ARCHITECTURE.md` section 7, item 4).
5. Leave distant quarries to the Regional Economy expansion (EXP-B), where other places are real.

**E. System-wide consequences.**
- **NPC decisions:** a new hauling trip someone must decide to take. Today only the player hires carriers; NPC
  hiring would need the contract system.
- **Households:** a hauling wage stays in the village, unlike the caravan's price.
- **Employment:** one carter job per trip.
- **Resources:** **the text does not say the quarry is finite.** An unlimited off-map source would conflict with
  World Design Rule 013 (finite resources) and the mining spec ("Ore bodies and stone layers remain finite"), so it
  would need a finite reserve.
- **Production:** steady stone for building at a known cost.
- **Prices and trade:** stone priced by wage and fee; it competes with the caravan's stone.
- **Money conservation:** the hand's wage and the fee are transfers. The stone itself enters from outside, so it must
  be counted as an import (`imported_stone`) with a named source.
- **Inventory conservation:** the cart's load must be accounted for on the way.
- **Manor finances:** the fee is income, and the manor may also be the buyer, paying itself.
- **Long-term equilibrium:** a lasting stone supply, finite only if made so.

**F. Engineering.**
- **Work:** an off-map trip state for an NPC and a cart (saved mid-trip); a quarry stock (finite or not, the owner's
  call); hiring by NPC buyers (today only the player hires); the import counting; the wiki and journal.
- **Touches:** `carts.gd`, `construction.gd` or the contract module, `npc_brain.gd`, `world.gd` save,
  `economy_sim`.
- **Tests:** a trip in progress survives save and load; every stone is counted as an import; costs are paid exactly;
  the quarry runs out if finite.
- **Risks:** a second abstract "off-map" mechanism beside the caravan, which the regional expansion would later
  replace.

**G. Recommendation.**
- Do not approve P1.5 now.
- For Build 17, the caravan's stone (already approved, real price, real coins leaving) and MIN-B's local stone cover
  supply without a new off-map mechanism.
- A distant quarry is better built where it is a real place: the Regional Economy expansion (EXP-B), or the overworld
  once villagers can travel there.
- If the owner wants P1.5 anyway, it should have a finite reserve and use the contract system for hiring the carter.

**Question for the owner:**
Approve P1.5, keep the caravan's stone plus MIN-B (recommended), or move a distant quarry to the Regional Economy
expansion?

---

## Not covered here

- **ECON-P1.3** (the caravan as a finite regional market, line 73) is a separate register entry (target Build 18).
  It was not asked for.
- The register records that a different finite caravan purse was built instead (B7-014, `9c13794`), a
  contradiction for the owner to resolve there.
