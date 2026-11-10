# Investigations: p:52's failed purchases and the bandit-clan children who starved (2026-11-10)

Owner directive `docs/directives/2026-11-10_continued_investigation_merge_prep.md`, sections 2B and 2C; register ids
**B25-INV-P52-BLOCKS** and **B25-INV-BANDIT-CHILD**. Read-only investigation: no game code, register or other branch was
changed. Proposed corrections below are descriptions only; none is implemented.

## Evidence used

| Source | What |
|---|---|
| Campaign 42788018729, commit `fbfd6ad`, seed 1 | `findings.json` / `findings.md` (F003, F005, F006, F024), `lives/B_migration_ledger.md` |
| Recorder archive, artifact 13765709395 (`fr-seed1-seg4-archive`, session `s1794311491`, mml-recorder/2) | days 300-307 and 355-359 extracted (event, state_change, participant, factor, alternative, sample, snapshot). The archive starts at day 300, so F003's start (day 287) is not in it. |
| Batch 3, commit `b57261f`, campaign 42760291468, seed 1 | `findings.md`: F013/F014 (p:52 building_block x42, day 360), F016 (starved with means, household 25, days 155-156) |
| Code | `git show fbfd6ad:<path>`; diff `b57261f..fbfd6ad` |
| Probe | a 10-line headless Godot 4.7.2 script (scratchpad only, nothing committed), result in C.3 |

Event rows quoted as `[seq, id, parent, root, object, day, minute, settlement, x, y, system, subsystem, category, subtype,
actor, outcome, reason, rule, detail]`; samples as `[seq, day, hour, entity, hunger, hp, x, y, doing, coins]`.

---

## B. p:52: 453 failed building-block purchases (and 476 coal, 1033 refused trades)

### B.1 Who p:52 is and what they were doing

- p:52 is an adult **merchant** (decision factor `guard/job = merchant`), the Lambert storefront's keeper
  (`"keeping the Lambert storefront"`, day 358 07:00), purse 122-148 coins over days 355-358.
- The planner is **CON-01 contract fulfilment, route `buy`**: the decision chain's winning branch is `contract`
  (alternative row `[40570952,2579868,"contract","yes",true,...]`), and every plan reads
  `doing=buying building block for Rose Ward; plan=go,do:buy_from`. That string exists only at
  `game/scripts/core/contracts.gd:1442` (`fbfd6ad`).
- The contract: `[40498598,2574330,...,"contracts","contract","contract","opened","p:52",...,"contract=963 item=building_block qty=6 price_each=5 days=3 deadline_day=360 kind=goods route=buy"]`
  (day 358 06:00). p:52 agreed to sell Rose Ward 6 building blocks at 5 each, to be bought from another villager and resold.
- **The coal streak (F005, day 355) is the same planner**: samples read `"buying coal for Rose Ward"` all day 355
  (08:00-18:00). It is not the smith/`_fetch_for_order` path the lead fixed separately.

### B.2 The execution path and the refusal

1. Planner, `contracts.gd:1438-1445`: `_vendor(n, c.item, price_each)` finds the cheapest seller below the contract price
   (p:31, 4 coins); it plans when `n.coins - w.reserve_of(n) >= w.deal_price(w.sell_price(v, c.item), n, v)`, i.e. **the raw
   purse above the reserve covers one unit**, and asks for `qty = owed - held`.
2. Act, `npc_brain.gd:3118-3162` (`"buy_from"`): `for_need` is false (not a pantry, order, necessity or job tool);
   `ventures.budget` is -1 (see below); then `npc_brain.gd:3142`:
   `while qty > 0 and not for_need and funded.is_empty() and not w.can_afford(buyer, up * qty): qty -= 1`.
3. `World.can_afford` (`world.gd:2051-2056`) with the Living Economy on (it is: session flags `"economy": true`,
   `game/data/economy.json` `enabled: true`, `market.drive: true`) counts **`claims_free_coins`** (`world.gd:1806`,
   `EconClaims.free_units`, `econ_claims.gd:163-176`): the purse less coins held by the actor's own open market bids
   (`econ_offers.gd:66-68` reserves `qty x price_each` coins per bid), which yield only to a purchase of the same item or a
   necessity.
4. With qty cut to 0, the trade is never asked (`traded` false), `buy_failed[n.id]` is set (`:3158`) and
   `_record_refused_buy` writes the refused trade (`:3160`, `:2905-2913`).

Day 358, the first purchase and the loop (archive rows):

```
[40559955,2579159,...,358,502.0,...,"brain","act","action","buy_from","p:52","ok","","","{\"item\":\"building_block\",\"qty\":6,\"vendor\":31}"]
[40559950,2579160,"p:52","coins",144,136,-8,"world.trade"]          state_change: 2 bought at 4 each
[40559953,2579160,"p:31","item:building_block",6,4,-2,"world.trade"] the seller held 6 and kept 4
...
[40570954,2579868,-1,...,358,513.0,...,"decision","plan_next","p:52","ok","","","doing=buying building block for Rose Ward; plan=go,do:buy_from"]
[40570958,2579870,...,358,513.0,...,"economy","trade","transaction","trade","p:52","refused","refused_by_rules","","below_reserve"]
[40570959,2579869,...,358,513.0,...,"brain","act","action","buy_from","p:52","failed","act_returned_false","","{\"item\":\"building_block\",\"qty\":4,\"vendor\":31}"]
```

The same three rows repeat **every game minute**: 482 plan_next, 472 refused trades and 472 failed buy_from rows on day 358
(476 on day 355 for coal; 47 on day 357). p:52 stands at the seller's stall (52,65) from 08:00 to 18:00.

### B.3 Precise refusal reason (verified by elimination; the recorded figures are lost)

- The recorded reason is `refused_by_rules / below_reserve`. **The figures `_record_refused_buy` composes (item, qty,
  price, purse, reserve, stock) are not in the archive**: `rec.begin(..., {"detail": detail})` is followed by
  `rec.end(ev, "refused", ..., "below_reserve")`, and `FlightRecorder.end` (`flight_recorder.gd:232-245`) overwrites
  `EV_DETAIL` with its non-empty `detail` argument. Recorder defect **R-1** (B.6).
- Not stock: the seller held 4 after the sale (state_change above) and the refusal path records `below_reserve` only when
  the seller has the item.
- Not a business till (B25-BIZ-D1): the successful 08:22 purchase drew 8 coins straight from p:52's purse with no till
  pay-out row (`ventures.fund` would have written one), so `ventures.budget(p:52, building_block)` is -1.
- Not the reserve alone: within one minute the planner and the act use the same `deal_price` (same buyer, seller, minute)
  and the same `reserve_of` (cached per game hour, `world.gd:1948-1957`). The planner passed
  `coins - R >= price`; the act refused one unit, `free - price < R`. Both hold only if **free < coins**, i.e. **coins held
  by a claim**. With `contract_held` 0 for coins (`reservations.gd:89-92`), the only claim on coins is an
  `EconReservations` hold, which in live play comes from p:52's own open market bids (LE-02, `econ_offers.gd:66-68`); the
  model reports 252 open offers and 252 reservations that day (`economy_model` factors).
- **Unverified:** which bid(s) p:52 held and for how many coins. The recorder has no offer- or reservation-level rows
  (no `offer` event or state change exists for p:52 in days 355-358). A probe on the day-300 save can list
  `economy.offers.open_of("npc:52")` to confirm.

**Root cause (B):** the contract-purchase planner (`contracts.gd:1441`) decides affordability by its own rule (raw purse
minus reserve, one unit) instead of the act's rule (`World.can_afford` over claim-free coins, the whole quantity), and it
never consults `NPCBrain.buy_held`/`buy_qty`. When the act refuses, the plan is empty, the decision chain reaches the same
branch the next minute and chooses the same purchase. The SIM-F2 memory (`buy_failed`, `BUY_RETRY_MINUTES = 60`) is
written by the act but read only through `buy_qty`/`buy_held`, which this planner does not call. The contract's capacity
check at acceptance (`contracts.gd:364-372`, `free := n.coins - w.reserve_of(n)`) has the same blind spot, so p:52 accepts a
quantity the act will not let them buy.

### B.4 Regression or amplification?

`git diff b57261f fbfd6ad`: `contracts.gd` is unchanged; the `buy_from` act, `buy_qty`, `buy_held`, `can_afford`,
`claims_free_coins` and `EconClaims` are unchanged (the economy files differ in comments only, "the Living Economy is on").
The npc_brain change in that range (B25-HH-BIZFOOD-D1 and `_affordable_meal`) does not touch this path. **Not a new
regression**: the same defect fired 42 times on day 360 in batch 3 and 453-476 times a day here because the run diverged
(different bids open, a different purse, contracts accepted earlier in the day so the loop runs for ten hours instead of
less than one). It ends only when the purse or the claims change (contracts 963's predecessors were fulfilled on days 356
and 357).

### B.5 Every `doit("buy_from"` planner in fbfd6ad and its affordability check

"Act rule" = the act's own decision: `World.can_afford` over claim-free coins with the bargained price for the whole
quantity, or the whole purse for a necessity / pantry / order / job tool. **No planner reads claim-free coins**: even
`buy_qty` uses `n.coins - spent - up*q < floor` (`npc_brain.gd:820-837`), so with Living Economy bids open every planner can
choose a purchase the act refuses. What differs is whether a refusal repeats every minute (no `buy_held`) or at most once
an hour per unchanged purchase (`buy_held`).

| Planner (file:line of the `doit`) | Affordability before planning | buy_held? | Repeat risk |
|---|---|---|---|
| CON-01 contract route `buy`, `contracts.gd:1443` | raw purse - reserve >= 1 unit at deal price; qty = owed - held | no | **every minute (this finding)** |
| Guard rearm, `decay.gd:202` | `armour_seller`: `can_afford(n, deal price, false, item)` for 1 unit | no | every minute when claims differ |
| Family fence materials, `farm_plots.gd:666` | `can_afford(n, list price x qty)` (list, not deal price) | no; `_first_try` once a day per item | once a day |
| Homestead grain, `homesteads.gd:1515` | `buy_qty(..., need=true)` | yes | hourly at most |
| Homestead seed, `homesteads.gd:1532` | `buy_qty(..., need=true)` | yes | hourly at most |
| Homestead firewood, `homesteads.gd:1539` | `buy_qty(..., need=true)` | yes | hourly at most |
| Homestead house materials, `homesteads.gd:1564` | `buy_qty(n, s, id, want)` | yes | hourly at most |
| Claim errand materials, `wilds.gd:1190` | `buy_qty(n, s, id, want)` | yes | hourly at most |
| Miner's minecart, `mine_supply.gd:329` | `can_afford(n, deal price)` | no | every minute when claims differ |
| Provision firewood, `npc_brain.gd:403` | `n.coins >= 3` and `buy_qty(.., true)` | yes | hourly at most |
| Provision grain, `npc_brain.gd:411` | `n.coins >= 4` and `buy_qty(.., true)` | yes | hourly at most |
| Medicine, `npc_brain.gd:475` | `buy_open` | yes | hourly at most |
| Storefront build materials, `npc_brain.gd:604` | `n.coins >= storefront_coins`, seller stock only | no | every minute possible |
| Dressing tool, `npc_brain.gd:872` | `buy_open` | yes | hourly at most |
| Dressing stone, `npc_brain.gd:883` | `buy_open(n, v, "stone", short)` | yes | hourly at most |
| Parts trip, `npc_brain.gd:944` | `buy_qty(.., spent)` and floor | yes | hourly at most |
| Handcart, `npc_brain.gd:986` | `buy_open` | yes | hourly at most |
| Gift ale/bread (seek company), `npc_brain.gd:1104` | `n.coins >= gift_coins` (list) | no | rare (social branch, failure harmless) |
| Meal for a dependant (payer), `npc_brain.gd:1166` | `_affordable_meal` (deal price vs whole purse; food is a necessity) | no | low (fixed in `1381eb3`) |
| Smith forge inputs, `npc_brain.gd:1733` / plank `:1740` | `n.coins >= 10` / `>= 6` | no | **every minute** (lead's separate fix) |
| Manor order plank `:1802` / inputs `:1813` | `n.coins >= sell_price` (list); act pays as an `order` from the whole purse | no | low (order bypasses the reserve) |
| Livestock feed wheat, `npc_brain.gd:1988` | `n.coins / list price` | no | low if wheat is a necessity (whole purse) - unverified |
| Bandit market food, `npc_brain.gd:2170` | `buy_open` | yes | hourly at most |
| Job tool, `npc_brain.gd:2757` | `buy_open` | yes | hourly at most |
| Prospecting kit, `prospecting.gd:582` | `n.coins >= list price` | no | every minute when reserve/claims bind |
| Stall stock, `stalls.gd:502` | `can_afford(n, deal price x short)` | no | every minute when claims differ |

### B.6 Proposed correction (not implemented)

1. **One affordability rule.** Give the planners the act's own decision: a single `NPCBrain` (or `World`) function that
   returns the quantity `buy_from` would sell, computed exactly as the act does (deal price, `for_need` flags,
   `ventures.budget`, `World.can_afford` over claim-free coins), and use it in `buy_qty` itself. Then every `buy_qty`/
   `buy_open` caller is right by construction.
2. **Contract route `buy`** (`contracts.gd:1438-1445`): plan with that quantity (`buy_qty(n, v, c.item, owed - held)`), so
   it also honours `buy_held`; the capacity check at acceptance (`:364-372`) should use the same free coins, so a seller
   does not accept what they cannot fund.
3. The non-`buy_qty` planners marked "every minute" in B.5 (rearm, minecart, storefront, prospecting kit, stall stock,
   smith inputs) move to the same function.
4. Recorder **R-1**: `_record_refused_buy` should pass its figures as the `detail` of `rec.end` (and the rule code in its
   own column), so a refusal says which figure decided it; add `free` (claim-free coins) to the figures.

### B.7 Regression tests (failing first)

- **T-B1 contract loop:** economy on; merchant M with 140 coins, an open market bid holding enough coins that
  `claims_free_coins(M) - price < reserve_of(M) <= M.coins - price`; an open contract, route `buy`, with stock at a vendor.
  Run M's decision 30 times over 30 minutes. Fails now (30 refused buy_from); passes when at most one is attempted per
  `BUY_RETRY_MINUTES` while purse, price, stock and claims are unchanged, and M does something else meanwhile.
- **T-B2 planner/act agreement (table test):** for each planner in B.5, a scenario where the raw purse covers the purchase
  and claim-free coins do not; assert the planner does not plan it (or plans the quantity the act then sells in full).
- **T-B3 acceptance capacity:** a contract is not accepted (or is accepted for the smaller quantity) when claim-free coins
  cover fewer units than the raw purse.
- **T-B4 recorder:** a refused buy's event row carries `item=... qty=... price=... purse=... reserve=... free=... stock=...`.

---

## C. Bandit-clan children who starved with food in their household

### C.1 Who and when

| Child | Age | Died | Last fed |
|---|---|---|---|
| p:1000856 | 12.9 | day 305 14:05 | camp meal day 302 ~19:00 (hunger 59 -> 92) |
| p:1000832 | 13.9 | day 305 20:45 | same |
| p:259 (Robert Oakley) | 3.1 | day 306 05:50 | eats on day 303 ~15:00 (58.8 -> 97.8) |
| p:1000886 | 11.9 | day 306 12:18 | day 303 ~19:00 (56 -> 88.8) |

All four were children of household 27 (Oakley; slept at home at (93-94,15-19) on days 300-301). Their last adult died on
day 302; at 06:00 Guardianship placed three siblings with household 5 and these four with the clan:
`[1290836,83185,"p:1000856","household",27,25,-2,"life"]`, event `guardianship_clan ... "no household could take the child"`.
From then they lived at the band's camp (102-108, 10-17) and every meal attempt was `camp_meal`.

### C.2 Where the food was

- **Household 25 is the band's household** (`family: "Outlaw"`, `band: true`; `Wilds.found_band`, `wilds.gd:1219-1271`;
  the chapel's carrier's plan reads `doing=carrying the church's food to the Outlaw household`).
- Its **pantry held 10 wheat** (wheat is in `NPCBrain.EDIBLE`, 20 food points each) the whole time: the only rows that touch
  it are the chapel's weekly wheat offering and the church's relief returning it, on day 300 and again on day 307
  (`[479279,30715,"hh:25","item:wheat",10,9,-1,"world.transfer"]`, `[610055,39035,"hh:25","item:wheat",9,10,1,...]`;
  the same pair on day 307). The death diagnostics agree: `household.food_units 10`, `food_days 4.9-10.4`, `purse 1`.
- 10 wheat is 200 food points; each child's hunger was falling about 1.8 points an hour, so it was several child-days of
  food. **Not a genuine shortage of the household; a supply its members could not reach.**
- The band itself had nothing: the three bandits (p:285, p:286, p:287, household -1) were at hunger 0 by the evening of day
  305 and were all slain by Cecily that evening (deaths rows, `cause=slain by Cecily; role=bandit ... household=-1`). With
  the bandits' packs empty, the band's own stores were genuinely bare (WDR-022 allows that).

### C.3 Why the children could not eat it (verified in code)

1. `NPCBrain._decide` (`npc_brain.gd:270-272`) sends a child with `clan == "bandit"` to `_clan_child` **before** the
   ordinary eat branch (`:279`, `_plan_eat`), so a clan child never plans `eat_home`.
2. `_clan_child` (`npc_brain.gd:2214-2224`) plans `work(15, "camp_meal")` when hungry; the act (`:3358-3361`) calls
   `band_eat`.
3. `band_eat` (`npc_brain.gd:2181-2209`) takes food only from **packs**: the child's own and those of every living NPC
   with `role == "bandit"` (raw meat roasted at the fire). It never reads the band household's pantry, the claim's stores,
   or anything the church delivered.
4. `camp_meal` **returns true whether or not anything was eaten**, so the recorder logs dozens of `camp_meal ... "ok"` rows a
   day for a child who ate nothing, and the death chain reads as a fed child (F024's chain: `camp_meal ok` every 16
   minutes up to the death). Recorder/act defect **R-2**.
5. No process was meant to feed them from the pantry: no adult of household 25 cooks or serves at the camp; the bandits
   are not members of household 25 (household -1, see C.4) and do not deposit or draw from its pantry; the church's relief
   for household 25 went into that pantry (`chapel.gd:846-866`), out of the children's reach.

Ordinary village children are not affected by this path: they reach `_plan_eat` (`npc_brain.gd:1113`) and eat from the
household pantry at home (`eat_home`, `:2962-2973`). The same unreachable-pantry defect applies to **any clan child** in
the band household (FAM-07 placements, children born into the band, `life.gd:668`, children of a homestead that turned
outlaw, `wilds.gd:1600`), whenever the bandits' packs are empty while the household's pantry is not.

### C.4 Membership defect found on the way (verified: a type mismatch after loading a save)

The register of household members is inconsistent after a save is loaded:

- The four children were "placed with the clan" **again every dawn** (days 303, 304, 305: `household 25 -> 25`), and their
  three siblings moved **5 -> 21/26/29 -> 5 -> ...** every dawn
  (`[1943554,125019,"p:178","household",5,21,...]`, `[2604161,167275,"p:178","household",21,5,...]`).
- Household 25's chapel offering is decided on days 300 and 307 by **p:142 (Henry Outlaw)** as its lowest-id living adult
  (`participant [479259,30714,"p:142","chooser"]`, followed by the `hh:25` wheat transfer), and the church delivered household
  25's relief to p:142's cell (24,52). Yet p:142 was moved by Guardianship from household 25 to household 21 on day 183
  (`B_migration_ledger.md` line 512) and lives and eats in the village.
- **Cause:** world saves are JSON (`World.to_dict`; the campaign's segments resume with `JSON.parse_string`,
  `economy_sim.gd:2610`; players' saves likewise, `save_store.gd`, `save_transfer.gd`), so every id in
  `households[h].members` comes back as a **float**; `World.load_dict` (`world.gd:6726-6729`) copies the household
  dictionaries without converting them (homestead claims' members are converted, `homesteads.gd:1877`). In Godot 4.7.2
  `Array.erase(int)` does **not** remove an equal float. Probe (headless 4.7.2):

  ```
  JSON.parse_string('{"members":[142,259]}').members -> types: 3 (float)
  has(142): false
  after erase(142): [142.0, 259.0]
  ```

  So after the day-300 resume, `join_clan` / `move` (`guardianship.gd:206`, `:253`) could not remove the children from
  household 27's list: household 27 never ended, `Guardianship.orphans(27)` found the same children every dawn, and each
  dawn re-placed them (clearing their plans). Likewise p:142 (a float entry from the day-100 resume) stayed in household
  25's list after the day-183 move: a **phantom adult** in the band household. That phantom also explains why the
  re-joins moved none of household 25's pantry to the children: `_take_share` (`guardianship.gd:275-294`) moves nothing
  from a household with a living adult member.
- **Scope:** every `members.erase(<int id>)` site (at least `construction.gd:1139, 1220`, `guardianship.gd:206, 253`,
  `homesteads.gd:777`, `life.gd:512, 525, 872`, `life_decisions.gd:387, 517, 608`, `main.gd:1039`) and every
  `members.has(int)` check, for any household loaded from a save, in the campaign and in players' games. Effects seen:
  orphan churn, households that never end, phantom adults blocking orphan care and steering chapel offerings and church
  deliveries. Ordinary village households are affected by this defect.
- It did not by itself starve the clan children (C.3 is sufficient), but it removed the one transfer that would have put
  household food into their packs, and it hides who household 25 really holds.

### C.5 Root cause (C), summarised

**A distribution defect, not a legitimate outlaw shortage.** The clan children's only meal path (`band_eat`) reads the
bandits' packs and their own, never the pantry of the household the game puts them in; with the bandits' packs empty, the
children starved over three days beside 10 wheat in their own household's pantry, which the church's relief also refilled.
The repeated `camp_meal ... ok` rows hid it. The band's own empty packs and the bandits' deaths are a legitimate outcome
(WDR-022); the children's inability to eat their household's food is not.

Batch 3 (seed 1, days 155-156, household 25, p:156/p:142/p:159) shows the same pattern; it was not re-extracted, so its
pantry contents are **unverified** here.

### C.6 Proposed correction (not implemented)

1. **Clan meals reach the band household's pantry.** `band_eat` (or `_clan_child`'s meal) takes food from the band
   household's pantry (the clan child's own household's, `n.household`) after the eater's own pack and before the other
   bandits' packs, by the same `EDIBLE` order; raw wheat as the village eats it, or cooked at the camp fire by the oven's
   rule if that is the intended standing (an owner question only if cooking at the camp changes behaviour).
   Ownership: the pantry is the household's; its members (the children) may eat from it as any household's members do.
2. **Bandits share their household's stores.** Optionally, homeless bandits are joined to the band household (or
   `band_eat` reads it for them too), so the band's food has one home; check against `found_band`'s intent before changing.
3. **`camp_meal` returns whether anything was eaten** (or records `nothing_to_eat`), so a hungry clan child's failure is
   visible and the starved-with-means detector does not read a fed child (R-2).
4. **Members are ints after load:** `World.load_dict` converts every household's `members` to ints (as homesteads already
   do), and a save-continuity check asserts it; one-time repair on load: drop entries whose NPC's `household` differs and
   de-duplicate. Consider a single `World.household_remove(h, id)` that erases by `int()` comparison.
5. Chapel offerings and church relief should not count or route through a member whose `NPC.household` is not the
   household (falls out of 4).

### C.7 Regression tests (failing first)

- **T-C1 clan child eats from the band pantry:** a band household with 4 wheat in its pantry, a clan child at hunger 30 in
  it, no living bandit holding food. Run the child's decision and act. Fails now (hunger unchanged, `camp_meal` true);
  passes when the child's hunger rises and the pantry falls by what was eaten.
- **T-C2 genuine shortage stays a shortage:** the same with an empty pantry and empty packs: the child does not eat and
  `camp_meal` returns false (WDR-022: no hidden rescue).
- **T-C3 camp_meal outcome:** a `camp_meal` that ate nothing is recorded as failed (or with a reason), not ok.
- **T-C4 members survive a save:** build a world, `JSON.parse_string(JSON.stringify(w.to_dict()))`, `load_dict`, then
  move an orphan with `Guardianship.move` and `join_clan`; assert the child is in exactly one household's `members`, the old
  household ends when nobody is left, and the next `Guardianship.dawn` does not place the child again. Fails now.
- **T-C5 no phantom adult:** after a save round trip and `Guardianship.move` of an adult or child out of a household,
  `w.brain._members(old)` no longer returns them, and `Chapel.offerings` picks no chooser from another household.
- **T-C6 invariant (save-continuity suite):** for every household and every id in `members`: the id is an int, appears once,
  and `w.npc(id).household == h`.

---

## Unverified and limits

- **B:** the exact claim on p:52's coins (which bid, how many coins): inferred by elimination from the code and the
  same-minute planner/act disagreement; the recorder keeps no offer or reservation rows and lost the refusal's figures
  (R-1). Days 287-299 of F003 are not in the archive.
- **C:** batch 3's household 25 pantry contents (days 155-156) were not re-extracted. That p:142's stale entry dates from
  the day-100 resume is inferred from the segment layout (segments of 100 days) and the Godot behaviour, not read from a
  save. Whether livestock-feed wheat is a necessity (B.5, `npc_brain.gd:1988`) was not checked.
- Downloaded archive: only days 300-307 and 355-359 were extracted; the zip was deleted after extraction.
