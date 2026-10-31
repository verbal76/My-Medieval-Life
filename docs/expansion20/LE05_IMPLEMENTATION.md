# Expansion 20, LE-05: implementation note and handoff (construction, ecology, mining, bandits, regional links)

Register LE-05 (gate "Integration matrix covered", design s.9, s.17; branch `wip/x20-le05`, from LE-06's `857f9f8`; Worker G from
`784f0e5`, merged with `wip/expansion20` `531da40`, for LE05-REPAIR and LE05-RENTAL, owner directive 2026-10-31
`docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md`, section "LE-05 — TOOL REPAIR AND RENTAL"). Rules: behind
`economy.json` `enabled` false (and `market.drive`); deferred systems behind off flags; no unbounded saved state; additive saves
only; the settlement layer (`game/scripts/core/settlement/`, Worker B) is consumed through its interfaces and `World.transactions`,
never edited without telling the lead; anything that changes gameplay outcomes or needs the owner is stopped and reported.
Actions: none until LE-06's run 41143001791 reports; at the LE-05 milestone one local `tools/sim_gate.py` (economy off) and one
`--market` run.

## Status (keep current)

| Part | State | Where |
|---|---|---|
| Travel in a delivered contract's price (design s.5 "travel and risk", deferred from LE-02) | done | `contracts.gd::travel_per_unit`, `price_terms`; INT-612; `le05_test::test_travel` |
| Risk in prices (route danger) | documented gap (section 2): no route-danger measure exists | |
| Tool repair (owner 2026-10-31, LE-05 A: normal play, economy on or off) | done (section 4); Worker G | INT-650; `le05_repair_test.gd` |
| Tool rental (owner 2026-10-31, LE-05 B: behind the switch) | done (section 5); Worker G | INT-651; `le05_rental_test.gd` |
| Paid commercial repair (a smith mending another's tool for coins; economy on) | not built: next step (section 4.4) | |
| Player's market journal (OD-LE-14 D13; must not break the guest journal network path) | done (section 3) | INT-613; `le05_test::test_market_journal` |
| Construction: bids for materials, hiring (design s.9) | housing material bids exist since LE-02 (need kind `housing`); hiring is LE-04's wages flag (off) | |
| Ecology / mining under existing depletion rules; bandits; regional links via `World.transactions` | not started; regional food trade is Worker B's (X20-SETTLE-FOOD, merged) | |

## 1. Travel in a delivered contract's price

Design s.5: a seller's minimum covers "labor, material cost, household needs, other bids, stock and opportunity cost"; LE-02 left
"no travel cost in pricing ... for LE-05's regional links". `Contracts.price_terms` gains a `travel` term, added to the minimum:
the round trip between the seller's workplace and where the buyer takes delivery (its workplace; the manor's reeve; the player's
home), at walking speed (`walk_tiles_per_second`, `game_minutes_per_second`), valued at the seller's own earnings per working
minute (`NPC.avg_income` over the working day: the measure `alternatives` already uses), over a `delivery_lot`. No new number:
only `market.travel_cost` (on) gates it; the switch off leaves CON-01 exactly as before. A seller who earns nothing values its walk
at nothing. Face-to-face market deals (encounters) carry no travel (nothing is carried).

## 2. Route risk in prices: a documented gap (not invented)

Design s.5 asks buyers to weigh "travel and risk". Read-only search of the settlement and bandit layers (2026-10-30): couriers can
be waylaid (`settlement/couriers.gd`: the load drops as loot), and `Outlaws.band_alive` / `camp_cell` say whether a band is about,
but nothing measures danger on a route (no record of losses or attacks per road, per settlement link or per area). Per the lead's
instruction no measure is invented: route risk is not priced. When the settlement or bandit layer records losses by route (e.g. the
couriers' waylaid loads or caravan losses by road), a risk premium can read it here: the expected loss on the route over a trip,
added to the seller's travel term and the buyer's ceiling. Until then a delivered contract prices travel time only (section 1).

## 3. The player's market journal (OD-LE-14 D13)

When the player talks with a villager (`Relations.talked`) and the market drives, it learns that villager's open offers in person
(OD-LE-02B), and each price new to it, changed or older becomes a "market" line in its Messages journal: "<name> sells plank at 4
each (seen day 1, <place>)". The category is added to the journal's bounded ordinary tier (`message_journal.json`); staleness is the
line's day against today. Nothing else lists offers to a player (no feed). The host's player gets the line through
`World.player_tell`; a guest's is recorded under its reference in the host's world (the `c_journal` record, saved there): no new
network verb, so the guest journal path is unchanged. Known limit: a guest's own journal page shows those lines once its copy next
syncs with the host's saved journal, not at the moment. Not playable while the economy is off, so no wiki page yet (WIKI-01).


## 4. Tool repair (LE05-REPAIR; owner 2026-10-31, LE-05 A: normal play, with the economy on or off)

The owner approved Worker A's proposal (`LE05_RENTAL_REPAIR_PROPOSAL.md` s.3) with one change: repair is **not** behind the switch.

### 4.1 The rule (one for the player and every smith, PAR-01)

- **What:** an item with durability and a forge recipe at the anvil making one of it (`forge_<id>`, `World.repair_recipe`): tools
  (axe, pickaxe, hammer, chisel, prospecting kit), weapons, armour and helmets. No forge recipe, no repair: a shovel (assembled at
  the workbench), a plough, a mallet, clothes, leather armour and caps, rusty finds. Nothing is invented for them.
- **Terms** (`World.repair_terms`), from that recipe only, by the share of durability missing (`missing / full`):
  each input `ceil(qty x missing / full)`; minutes `ceil(minutes x missing / full)`, at least 1; experience
  `floor(xp x missing / full)`; the recipe's Smithing level. The axe (2 iron bars, 1 plank, 60 minutes, 18 xp): half worn
  1 bar, 1 plank, 30 minutes, 9 xp; 110 of 120 worn 2, 1, 55, 16; one use left 2, 1, 60, 17 (never more than forging); one use
  worn 1, 1, 1 minute, 0 xp.
- **The work** (`World.work_repair`): the inputs leave the worker's pack (counted `used_<input>`, so the goods ledger closes); the
  worn unit is mended to full where it lies, its durability record cleared, as GP-SHARPEN mends (the existing equipment rule: one
  worn unit per holder per item, X20-WEAR-TRANSFER); it keeps its holder, id and count; anvil work wears the worker's hammer (2) as
  forging does; no practised-hand saving and no bonus unit (nothing is made). Counted `repaired`, `repaired_<id>`,
  `repair_wear_mended`. Economy on: inputs earmarked for a contract are refused (`EconClaims.craft_ok`), as for crafting.
- **No value from nothing** (requirement 4): inputs are rounded up, so a repair always uses at least the forge inputs' share of
  what it restores (`le05_repair_test::test_no_value_from_nothing`, each of the 48 repairable items at one use, half and nearly full wear: 144 cases).
- **Tiny repairs** (agent decision): each input is rounded up to whole units, so even one use of wear takes one of each input:
  repeated small repairs always cost more than one larger repair of the same wear (tested for six items), and nobody is refused
  a repair they want. A minimum missing share was the alternative; it would refuse the player for no visible reason, so it was not
  chosen. No quality tier and no permanent durability penalty.

### 4.2 The player

The anvil's window (`GameUI._repair_rows`) lists each worn repairable item in the pack: how worn, what mending takes (with what
the pack holds), the Smithing level, and a Repair button core enables (`World.repair_refusal`). `main.repair` →
`World.player_repair_begin` (an anvil the player may use, in reach; the anvil held for the repair's time at the game's speed and
the skill's craft_time) → `World.player_repair` when the time is up. A guest's two verbs go to the host (`NetActions.VERBS`, C2),
which applies them to the guest's own pack (World.as_actor): the same rule at the guest's own cost, no new design question.
Wiki: `sys:repair` "Repairing tools at the anvil" (linked from the sharpening page and the smelting guide); `todo:tool_rental`
says renting and paid mending are not in the game yet.

### 4.3 NPC smiths

`NPCBrain._smith`, after the manor's paid orders and before forging stock: `repair_job` finds the first worn repairable item of the
smith's own or of a living member of its household (by holder id, then item id) with at least `balance.json`
`repair.npc_min_missing` (0.5, provisional) of its durability gone, within the smith's Smithing level and with the inputs in the
smith's own pack; `_do_repair` reserves an anvil the smith may use and plans the work (`repair` act, the hammer's swing), and the
act calls `work_repair` with the item in its holder's pack and the smith's materials. A household's tools are mended where they are
(an abstraction like the household's shared pantry; nothing moves). Nobody outside the household: that is paid repair.

### 4.4 Paid commercial repair: the next step (not built)

A smith mending another's tool for coins belongs behind the switch (directive: "Paid commercial repair services and their
associated financial transactions may depend on the economy system"). It does not fit cleanly yet: the tool would have to be
handed over and back (custody), the price agreed, and the work scheduled, which is a CON-02 service contract (`market.services`,
off, "nothing behind it yet", LE-04). Next step: a `repair` service kind under `market.services` whose price is the repair's inputs
at the smith's asking prices plus its minutes at its earnings a minute (the CON-01 travel/opportunity measure), the tool in the
authority's custody during the work. GP-SHARPEN (a weapon sharpened for a coin at the grinding wheel) is unchanged.

### 4.5 Saves

No saved state: the wear was already saved (`Inventory.durability`); repair clears it. Old saves load and their worn tools can be
mended (`test_saves`: a Build 24 v23 fixture). No `SAVE_VERSION` change.

## 5. Tool rental (LE05-RENTAL; owner 2026-10-31, LE-05 B: behind the Living Economy switch)

Built with the economy (`EconomyFoundation.rentals`, `game/scripts/core/economy/econ_rentals.gd`); acts only with
`market.drive` and `market.rental` (economy.json, true; `rental_days` 3, provisional). Economy off: nothing changes, no save key.

- **Who and when:** a worker short of its trade's tool (`NPCBrain._get_tool`: the woodcutter's axe, the miner's pickaxe) weighs,
  once a day (`EconRentals.consider`), buying from the seller the existing path would use, renting from each owner with a spare
  (`spare`: what it holds beyond its own use), or doing without for now, through `JudgmentWeighting.choose` (profile `market_buy`:
  need, what each costs against its purse, the number of sources, its opinion of each counterparty; the forgo is waiting). Renting
  is never preferred by rule: buying is listed first and wins ties; a disliked lender loses to a seller; without the deposit the
  rent is infeasible (no free tool). With the manor's EQ-19 tool on its way (an advance or a commission) it does not rent: that is
  the existing way of borrowing. No substitute tools exist for these trades (the rusty tools are loot, not accepted by the trade),
  so "using another tool" has no candidate.
- **The owner's word:** `owner_willing` (profile `market_sell`: its need for coin; the price at its own floor, 50 points, as the fee
  only pays the wear; a spare it does not advertise, 50 points; its opinion of the renter). A comfortable owner refuses someone it
  strongly dislikes; one in need of coin may still lend (C1: judgment influences, need can outweigh it). Refusal is valid.
- **Opening** (`EconRentals.open` → `EconTransactions.lend`, single-use id): one unit, with its wear, owner → renter; the deposit
  (the tool's value, `deposit_for`) from the renter's purse into escrow. The renter must hold none of the item (`already_held`), so
  the rented unit is its one worn unit throughout; `owner_of(holder, item)` names the owner.
- **Fees** (`_bill`, each dawn): the value of the wear used so far (`fee_for`: value x durability used / full, rounded up) less what
  was paid, renter → owner by `transfer_coins` (booked as earnings), as far as the renter's purse goes; the rest is owed.
- **Ends** (`_end` → `EconTransactions.end_rental`, once; the fee owed from the escrow to the owner, the rest of the deposit back):
  returned at the term's end, or earlier when the renter changed trade or has one of its own besides (an NPC), or by the player's
  verb: the wear used, the tool back to its owner with its wear; broken in use (`World._work_wear` → `on_broke`): the whole
  durability it had when lent; not held at a dawn (lost, stolen, sold, given away, not returned): the same, the tool staying where
  it went; the renter died (`World.kill` → `on_death`, before the inheritance): what it holds goes back to the owner (it is not
  inherited), the refund to its estate (`estate_of`); the owner died: its estate (household, else the manor) succeeds it and later
  receives the tool and the fees.
- **Coins:** the escrow stays inside the village (`World.total_coins` counts `EconRentals.escrow`; economy_sim's `rental_escrow`).
  No coin or good is made or lost on any path (`le05_rental_test`, exact checks per path).
- **Players and guests:** `World.player_rent_tool(owner, item)` and `player_return_tool(item)`, host verbs (`NetActions.VERBS`, C3):
  the renter is the acting player's own reference, so a guest gives back only its own rental; a repeated request is refused
  (`already_renting`), a replayed id moves nothing, a second give-back finds nothing open. No window yet (the economy is off by
  default); the wiki's `todo:tool_rental` says so.
- **Saves:** optional `economy.rentals`: `{records: [open, and the last 30 closed], considered: {renter: [day, act]}}` (today's
  choices only, pruned at dawn), bounded by the tools lent. An economy save without it loads with none.

### 5.1 Validation

See the commits' bodies and the lead's report for the counts: `le05_repair_test` (57 checks) and `le05_rental_test` (53 checks),
both failing first (neither compiled against `784f0e5`+merge: the API did not exist).

### 5.2 Economy off (G0): what repair changes

Local, `economy_sim.gd` seeds 1 and 2, 30 days, every 10 (the `tools/sim_gate.py` command line), compared with
`docs/release/sim_baseline.json` by `sim_gate.py`'s own `summarise` and `compare` (baseline not rewritten). The merged tree before
the LE-05 work (`ff41f18`) matched the baseline exactly (seed 1 `d4a1d71d`, seed 2 `40a3f050` at day 30).

| | Seed 1 | Seed 2 |
|---|---|---|
| Repairs in 30 days | 1 (an axe of the smith's household, 63 of 120 uses mended, before day 10) | 0 |
| Against the baseline | differs from day 10 (fingerprint `292da391` at day 10, `e64c5530` at day 30; alive 113 vs 117, coins 3,958 vs 3,733, treasury 26 vs 6 at day 30): the repair's iron bar and plank and the smith's time, then the usual divergence of a changed run | identical at days 10 and 30 |
| Conservation | currency leak 0, item ledger empty at every checkpoint (0, 10, 20, 30); no script error | same |

The difference is the approved repair only (economy-off rental code never runs: no `rentals` key, `World.total_coins` unchanged
with no economy). Outcomes are not judged (WDR-022). The baseline is the lead's to replace when LE-05 is integrated.
