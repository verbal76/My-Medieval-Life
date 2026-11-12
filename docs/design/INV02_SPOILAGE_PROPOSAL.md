# INV-02: food spoilage by storage condition, investigation and proposal

Register: **B25-INV02-SPOIL-D1** (owner, 2026-11-10: "APPROVED IN PRINCIPLE, INVESTIGATE BEFORE IMPLEMENTATION").
Audit finding: **MML-INV-02**. Related: **DVW-B4** (goods decay, gentle rates), **WDR-022** (a village may fail; the
simulation may not), **BASELINE-AUTH-01** (owner baseline authority), **SIM-01/SIM-02** (long-run measurement rules).

Status: investigation and proposal. **No shipped behaviour changes.** A prototype exists on this branch behind a new
static flag `Decay.storage_on` (default `false`); it is not wired into any shipped path and is not part of the running
Build 25 validation campaign. It is for the owner's decision.

Branch: `wip/b25-inv02-proposal` (from `origin/wip/b25r2-rev2` at `72729e5`).

---

## A. Where food can sit, and whether it spoils today

Rule today (`game/scripts/core/decay.gd`, `Decay.dawn`, called once a day from `NPCBrain.dawn`): each perishable stack
loses `count x rate` units a day (the whole part, plus one more unit when a draw hashed from seed, day, holder key and
item falls under the remainder). No `world.rng`; every unit lost is counted `spoiled_<item>` (the goods ledger's drain)
and `decay_<item>` (diagnostics). One rate per item, the same in every holder: there is no notion of storage condition.

The canonical list of every goods holder is `SettlementHoldings.holders` (`game/scripts/core/settlement/holdings.gd`, the
census the conservation checks and the flight recorder use). Each holder below is checked against `Decay.dawn`.

Measured food (units of every edible plus raw meat) in seed 1, a 60-day run of the real World with the inert player
(probe `game/tests/_inv02_probe.gd`, not committed; same stepping as `economy_sim.gd`; no `--record`):

| Holder | Owner | Spoils today? | Food day 0 / 10 / 30 / 60 (seed 1) |
|---|---|---|---|
| Villagers' packs (`NPC.inv`), market roles and tavern tables included | each villager | yes, base rate | 167 / 248 / 1,426 / 2,123 |
| Household pantries (`households[h].pantry`; also the "foreign" chests, crates and barrels in their homes, which are views on it) | household | yes | 279 / 289 / 889 / 1,793 |
| Manor granary (`World.granary`) | manor | yes | 394 / 287 / 251 / 224 |
| Chapel store and parcels on the way | chapel | yes | 0 / 0 / 122 / 368 |
| Player pack and family chest, every player (`player_list`, away guests included) | each player | yes | 2 / 1 / 1 / 1 |
| Tavern tables (`containers` kind `table`) | keeper | yes | counted in the row above |
| Carts (`carts[].store`) | owner | yes | 0 throughout |
| Loot on the ground (not carcasses; a carcass goes whole after 3 days, `World._new_day`) | nobody | yes | 0 throughout |
| Manor lots, works yard, job loads (`ManorWork`) | manor | yes | 0 / 47 / 0 / 16 |
| Player's premises stock / store / work; villagers' built stalls' stock (`Business`) | owner | yes | 0 / 0 / 3 / 3 (stalls) |
| **Players' other containers** (`Chests.stash`: chests, crates and barrels in a home the player holds) | player | **no** | 0 throughout (player-driven; inert player stores nothing) |
| **Homestead chests** (`Homesteads.claims[].store`) | claim owner (player or NPC claim) | **no** | 0 throughout (1 claim) |
| **Pens' troughs** (`fauna.pens[].trough`, an integer of wheat) | pen owner | **no** | 64 / 142 / 180 / 178 |
| **Courier booths' store** (`CourierService.booths[].store`, with `deposits` per sender) | courier service / senders | **no** | 0 throughout |
| **Courier loads on the road** (`jobs[].cargo`, a Dictionary) | sender | **no** | 0 throughout |
| Construction sites and contract loads (`site_goods`, `construction.carried`), service contracts (`contracts.goods`), pits | builders | no | no food seen; building materials, ore and earth only |
| **Off-map settlements** (`Regions.list[]`: household pantries, business and own-trade stock, treasury granary, walkers' packs) | the five settlements | **no** (its own books, `OffMapSettlement.flows`; outside the village census) | pantries 814 / 723 / 1,033 / 1,134; business stock 0 / 2,883 / 5,135 / 5,194; granaries 0 / 0 / 6 / 521; trips 0 / 156 / 0 / 0 |
| Ripe crop left standing in fields (`f.crop`), seeds | farmers | no | not inventories (out of scope) |

Spoilage today in the same run: **1,710 units in 60 days** (wheat 430, pottage 355, meat 201, milk 134, carrot 132,
blueberries 109, egg 98, roast meat 76, red berries 69, potato 52, bread 29, apple 13, ale 10, cheese 1, rotten apple 1),
against about 4,500 food units held in the village on day 60 (troughs apart).

**Headline.** In a normal NPC year the holders the rule misses hold almost no village food: the stash and homestead
chests are filled only by players, and the courier booths and loads carried no food in this run. The two holders that
matter by volume are **the pens' troughs** (about 150 to 200 wheat, never spoiling) and, by far, **the off-map
settlements** (about 6,800 food units by day 60, more than the whole village holds, none of it ever spoiling). For the
player, the misses are an exploit: food put in a stash crate or a homestead chest keeps for ever, while the same food in
the family chest spoils.

Limits of this measurement: one seed, 60 days, the inert player. It cannot show what an active player keeps in the stash
or homestead chests, and settlement food trade (a resumed workstream) may put food on the courier roads later.

## B. Perishable and shelf-stable foods (`balance.json` `decay.spoil`, `items.json`)

Half-life is ln 2 / rate (the rule is memoryless: no ages are stored).

| Item | Type, food points | Rate a day | Half-life | Remark |
|---|---|---|---|---|
| wheat | resource, 20 | 0.004 | ~173 d | grain; slowest by design (DVW-B4). Plausible for a dry store |
| potato | food, 14 | 0.005 | ~139 d | root store; plausible |
| cheese | food, 35 | 0.005 | ~139 d | hard cheese; plausible |
| carrot | food, 12 | 0.01 | ~69 d | plausible for a clamp or cellar |
| ale | food, 10 | 0.01 | ~69 d | **flag: slow.** Medieval (unhopped) ale soured in days to a couple of weeks |
| apple | food, 15 | 0.03 | ~23 d | **flag: possibly fast** for stored apples (keep months), fine for windfalls |
| egg | food, 10 | 0.03 | ~23 d | plausible |
| bread | food, 50 | 0.04 | ~17 d | **flag: slow.** Bread stales in days (gentle on purpose?) |
| red_berries, blueberries | food, 6 | 0.05 | ~14 d | **flag: slow.** Fresh berries last days |
| pottage | food, 40 | 0.05 | ~14 d | cooked; acceptable (kept in the pot) |
| roast_meat | food, 60 | 0.05 | ~14 d | cooked meat; acceptable |
| meat (raw) | resource | 0.08 | ~9 d | **flag: slow** for unsalted raw meat (1 to 3 days) |
| milk | food, 12 | 0.1 | ~7 d | **flag: slow** (1 to 2 days unchilled); gentle on purpose |
| rotten_apple | food, 6, harms 3 | 0.1 | ~7 d | consistent |
| herbal_tonic | food, 4, heals 12 | none | keeps | shelf-stable, consistent with medicines |
| seeds, cuttings, saplings, spice, medicines | resource / medicine | none | keep | shelf-stable; correct |
| hide, rabbit_pelt (not food) | resource | none | keep | **flag (minor):** raw hides rot until tanned; not food, out of this scope |

The flags are realism notes, not defects: DVW-B4 approved *gentle* rates, and the fast foods are all ones the village
eats quickly. Rates are tuning; changing them is decision F4. The rules' ordering (grain slowest; milk and raw meat
fastest) is right.

Two related behaviours, both today:
- Villagers eat in `NPCBrain.EDIBLE` order (roast meat, pottage, wheat, ale, cheese, bread, berries, apple, egg, milk,
  carrot, potato), not the food nearest to spoiling first; the chapel already gives its fastest-spoiling food first
  (`Chapel.give_order`). Decision F6.
- Nothing turns into a spoiled item (an apple never becomes a rotten apple); spoiled food just goes. Kept as is.

## C. Proposed storage-condition model

Keep the one existing rule and add a single number per holder: **effective rate = item base rate x storage-class
multiplier.** The player and villagers never choose a class: it follows from where the food is. No ages, no freshness
per unit, no new save data.

| Class | Multiplier (proposed) | Holders |
|---|---|---|
| **open** (exposed) | 1.5 | loot on the ground, tavern tables (dishes set out), manor lots waiting at a place, pens' troughs |
| **carried** (pack or transport) | 1.0 | villagers' and players' packs, carts, manor job loads, chapel parcels; later courier loads on the road |
| **home** (household or commercial storage) | 1.0 | household pantries, family chests, players' chests and crates (stash), homestead chests, the chapel store, the works yard, shops' and stalls' stock, store and work; later courier booths |
| **cellar** (purpose-built or sealed) | 0.5 | the manor granary, barrels (a stash unit whose container kind is `barrel`) |

Why these values: today's rates were tuned as the "in store" rate (the wiki and item text say "spoils in store"), so
**home and carried stay at 1.0** and most of the village's food behaves exactly as now. Only the extremes move: food left
in the open spoils half as fast again, a granary or a barrel keeps it twice as long. That gives the player a real,
no-micromanagement reason to put food in a barrel or sell grain to the granary, and stops the stash and homestead chests
being a no-spoil store.

Mechanics:
- **Deterministic.** Unchanged hashed draw (`Decay.draw(seed, day, holder key, item)`); the multiplier only changes the
  fraction. New holders get stable keys (`stash:<unit>`, `homestead:<claim>`, `trough:<pen>`) and are walked in sorted
  order. A multiplier of exactly 1.0 leaves the result bit-identical (`rate x 1.0`).
- **Ledger-exact.** Every unit removed is counted `spoiled_<item>` and `decay_<item>`, as now; the economy sim's item
  ledger and the flight recorder already treat `spoiled_` as consumption. Trough wheat is in the census as `troughs`, so
  removing it with `spoiled_wheat` keeps the ledger exact.
- **Data.** The shipped version moves the class table to `balance.json` `decay.storage` (`{open, carried, home, cellar}`)
  with `decay.storage.enabled`; the prototype keeps it as a constant in `decay.gd` so the shipped data files are untouched.
- **Couriers (not in the prototype).** Booth stores carry per-sender `deposits` and loads carry booked quantities, so
  spoiling them needs a rule first for who bears the loss (decision F3) and matching changes to the deposit and delivery
  books. Engineering: spoil per deposit line and per job's cargo, record `courier_spoiled` on the job, deliver what is left.
- **Off-map settlements (not in the prototype).** Their books balance by `OffMapSettlement.flows`; spoilage needs a new
  `spoiled` flow line in `FLOW_GOODS`, the audit formula extended, and `Regions.audit` updated. Same rates and classes
  (pantries home, business stock home, the treasury granary cellar, walkers' packs carried), stepped once a day like the
  rest of the settlement (decision F2).

## D. Expected impacts

Measured numbers are in section G; the rest is reasoning, to be confirmed by the campaign in E.

- **Hunger and household survival.** In the village, small: about 99% of the food the rule touches stays at multiplier
  1.0. The granary at 0.5 keeps relief stocks slightly longer (less hunger in a lean spell). Food on tables and on the
  ground loses more. Stash and homestead chests now spoil, which matters only for players who hoard there.
- **Trade and food supply.** Today the off-map settlements never lose food, so their business stock grows (about 5,200
  units by day 60 in seed 1) and whatever they sell the village is drawn from a stock that never decays: a quiet bias
  in their favour. Spoiling it (F2) lowers their surplus and so what the caravan and couriers can sell, raises regional
  food prices a little, and may cause off-map hunger in lean years (a legitimate outcome under WDR-022).
- **Regional economy.** With F2 on, a settlement's farm and cookshop must keep producing rather than living off a hoard;
  less food on the market means higher prices and more coins flowing to food sellers. This is the largest economic change
  and must be measured over a year.
- **Saves.** None for the model: classes follow from the holder type, rates from data; no new saved field, no migration,
  no save version bump. Saved troughs, stashes and claims load as they are. If F2 is approved, the settlement `flows`
  gains a `spoiled` key, read as 0 when absent (old saves load; the audit treats missing as 0).
- **Performance.** One extra pass a day over the stash (at most about 120 units), the claims and the pens: negligible
  next to the existing walk over every villager. Off-map: one pass a day over a few hundred small dictionaries.
- **Multiplayer.** Guests' packs and chests already spoil, keyed by the guest's ref. The stash is per container, so a
  guest's crate spoils like the host's. Open question: an away guest (MP-D1) is not worn (`active_players`) but their
  pack and chest do spoil (`player_list`) (decision F5). Guest-held homestead chests spoil by the claim's key. The host
  computes all of it, so clients see the result and do not compute it.
- **Tests and baselines.** With the flag on, the simulation's output changes (fingerprints, food totals, deaths, prices).
  Turning it on needs **BASELINE-AUTH-01** owner authority and a recorded campaign; it must not touch the running Build 25
  validation campaign. With the flag off, the output is byte-identical (section G).

## E. Testing requirements (before any enabling)

1. **Focused unit tests per holder** (prototype test `game/tests/inv02_storage_proto_test.gd` covers the first three): a
   stash chest spoils; a barrel keeps better than a chest; a homestead chest spoils; with the flag off a stash does not.
   Still to add: a trough spoils. To add when built: each class's multiplier on a known stack (expected loss = count x rate x
   multiplier within a tolerance over many days, as `decay_test` does for the base rate); granary at the cellar rate;
   tables and loot at the open rate; courier deposits and cargo after F3; off-map pantries, stock and granary after F2.
2. **Ledger and conservation.** Every removed unit counted (`census before - census after == spoiled_ added`), for each
   holder; `conservation_test`, the economy sim's item ledger (no FATAL) and, for F2, `OffMapSettlement.audit` and
   `Regions.audit` with the new `spoiled` flow.
3. **Determinism.** Two worlds of the same seed spoil identically (prototype test); the determinism gate (two independent
   runs, the same fingerprints at every checkpoint) with the flag on.
4. **Save/load.** A world saved mid-run with food in a stash, a homestead chest, a trough and (F3) a booth reloads and
   spoils on the next dawn exactly as an unsaved world; an old save loads with no migration.
5. **Flag-off identity.** The economy sim with the flag off gives the same fingerprint at every checkpoint as the branch
   base (done for seed 1, 60 days; repeat on the integration commit).
6. **Long-run comparison (SIM-01).** One 365-day run per seed for seeds 1 to 4 with the flag on, monitored, read at days
   30, 90, 180 and 365 from its checkpoints, compared with the authorized baseline of the same commit with the flag off:
   starvation and other deaths, first starvation day, mean hunger, food days, households in want, granary and chapel
   stocks, relief given, food prices and food trade with the settlements, settlement hunger and deaths (F2), spoiled units
   by holder group (`inv02_spoiled_<group>` stats), coins and goods ledgers (no FATAL). Outcomes are measured and
   reported, not pass/fail (WDR-022); only ledger, determinism and save failures fail.

## F. Decisions for the owner

Engineering choices I can make without the owner: holder keys, sorted walks, where the table lives in data, the stats,
the test fixtures, how the courier books record a loss once F3 is decided.

1. **F1. Storage classes and multipliers.** (a) No classes, only extend today's rule to the missed holders (smallest
   change; stash and homestead chests and troughs spoil at the base rate); (b) the four classes above with open 1.5,
   carried 1.0, home 1.0, cellar 0.5; (c) the classes with stronger contrasts (open 2.0, cellar 0.25). **Recommendation:
   (b).** It satisfies "storage conditions must influence preservation" while leaving most food as tuned.
2. **F2. Off-map settlements.** (a) Their food never spoils (today); (b) the same rates and classes, through a new
   audited `spoiled` flow; (c) a lighter rule (one flat rate on the whole settlement's food, still audited).
   **Recommendation: (b)**, "same rules, lighter detail" (Q18-3); its regional effect is the main thing to measure.
3. **F3. Food in courier care** (booth stores and loads on the road). (a) Does not spoil (simplest; booths are
   short-term); (b) spoils at the carried rate and the **sender** bears the loss (the courier delivers what is left; no
   refund); (c) spoils and the **courier** compensates the sender at the booked price. **Recommendation: (b)**, with
   booths at the home rate; perishables rarely ride long, and (c) adds a money rule.
4. **F4. Base rates.** (a) Keep today's DVW-B4 gentle rates; (b) make the flagged foods faster (ale 0.03, bread 0.08,
   berries 0.1, raw meat 0.15, milk 0.2). **Recommendation: (a)** now; revisit after the classes are measured, since (b)
   changes hunger more than everything else here put together.
5. **F5. An away guest's pack and chest** (multiplayer). (a) Spoil while the guest is away (today); (b) frozen while away,
   as wear is. **Recommendation: (b)**, so a guest returning after a week is not punished for being offline, and so
   spoilage matches wear.
6. **F6. Eating the food that spoils soonest first.** (a) Keep today's order; (b) villagers eat their most perishable
   edible first (as the chapel already gives). **Recommendation: (b)** as a separate, small change: it is realistic,
   costs nothing to the player and partly offsets added spoilage; it changes villager behaviour, so it needs the owner.
7. **F7. Player tools for preserving food** (salting meat, drying fruit, a "salted meat" item) are new mechanics and new
   items. **Recommendation: not now**; record as a later idea.

## G. Prototype and measurements (seed 1, 60 days, no `--record`)

All runs on this branch's base `72729e5` code (and the branch), seed 1, 60 days, `--every 10`, the inert player, run
locally on 2026-11-10. Logs were kept in the session scratchpad only.

**Flag off is byte-identical to the branch base.** `economy_sim.gd -- --days 60 --seed 1 --every 10` from a copy of the
base tree and from this branch (flag off): final fingerprint `a10438013b1f20a1b53f99223fa1eacc` in both; the two logs
differ only in wall-clock timing fields (the judgment `timing.*_us` and the run's seconds). No ledger leak in either.

**Flag on** (`--spoil-storage`, open 1.5 / carried 1.0 / home 1.0 / cellar 0.5, plus stash, homestead chests and troughs):
ledger exact (`LEAKS: currency 0; items {}`), fingerprint `feff878f81ff638b313eff8ff4a59431` (as expected, it differs).

| Day 60, seed 1 | Flag off | Flag on |
|---|---|---|
| Alive (of 104) | 133 | 133 |
| Starvation deaths, first starvation day | 0, none | 0, none |
| Other deaths (all old age) | 10 | 8 |
| Mean hunger | 68.9 | 69.3 |
| Village food, days of need | 9.33 | 10.04 |
| Granary wheat | 224 | 298 |
| Relief grain given | 118 | 78 |
| Meals missed for want of food for sale | 14 | 0 |
| Caravan coins in / out | 3,135 / 1,941 | 3,701 / 1,996 |
| Units spoiled (probe, 60 days) | 1,710 | 1,619 |

Where food spoiled with the flag on (probe, 60 days): pantries 796, villagers' packs 707, troughs 45, granary 35,
chapel 31, shops and stalls 4, players 1; tables, loot, carts and the stash and homestead chests 0 (nothing was left there
by NPCs or the inert player).

Reading: one seed, 60 days. The village is not worse off: the granary keeps more grain (cellar rate) and the troughs
lose about 45 wheat. The other differences (deaths, coins, missed meals) are the two worlds diverging after the first
changed draw, not an effect that one seed can attribute; they are why section E asks for four seeds over a year. The
prototype does not touch the off-map settlements or the couriers, so the largest expected effect (F2) is not measured
here.

## Files on this branch

- `docs/design/INV02_SPOILAGE_PROPOSAL.md` (this document).
- `game/scripts/core/decay.gd`: `Decay.storage_on` (default false), `STORAGE`, `smul`, an optional multiplier argument
  on `spoil_inv`/`spoil_dict` (1.0 by default), `_spoil_unreached` (stash, homestead chests, troughs) and per-group
  diagnostics (`inv02_spoiled_<group>`), all inert while the flag is off.
- `game/tests/economy_sim.gd`: `--spoil-storage` turns the prototype on for a measurement run.
- `game/tests/inv02_storage_proto_test.gd`: the prototype's focused test.
