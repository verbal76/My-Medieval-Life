# Informal services and expanded service contracts (Decision 2, CON-03..CON-08)

Developer reference. Register ids: B25-NINE-D2, X20-SERVICES-SCOPE, CON-03, CON-04, CON-05, CON-06, CON-07, CON-08.
Owner words: `docs/directives/2026-11-01_nine_owner_decisions_consolidated.md` Decision 2 (on `wip/requirements-control`);
`docs/directives/2026-10-21_build17_consolidated_14_decisions.md` items 12-17 (CON02-S-1..6). Code:
`game/scripts/core/contract_services.gd`, `game/scripts/core/contracts.gd`. Interactions: INT-189 (CON-02),
INT-664 (terms), INT-665 (harvest and villager hiring). Test: `game/tests/services_d2_test.gd`. Player wiki:
`sys:contracts` (Hiring for work, How hired work is paid, Favours, Disputes, Working for hire, Villagers' own
contracts) and `sys:farming`.

## 1. One engine

Everything is a CON-01/CON-02 contract record (`Contracts.list`): negotiation (`evaluate`, counters, `buyer_answer`),
the coins set aside (`reserved`), payment per unit (`_pay_units`), lapse, cancellation, death and save are the
existing ones. Decision 2's "informal work need not be a formal contract" is the existing signing rule: an agreement
under the signing line is concluded with a word, where it is made (Q18-13); there is no business or licence check
anywhere in the service path. A service record carries `terms` (`pay`, `bonus_each`, `retain`, `advance`) and the
counters `retained`, `advance`, `advance_spent`, `results`, and when ended early with pay held back, `dispute`.

## 2. What each item does

| Item | Behaviour | Where |
|---|---|---|
| Decision 2 favour | `pay: "favour"`: nothing set aside or paid; only a friend, partner or kin (`Contracts.close_to`), not while the seller is short of its reserve, one at a time, judgment's refusal when attached; never formal; earns a help's regard | `favour_refusal`, `on_fulfilled`, `set_aside_of` |
| CON-03 advance | `{amount, purpose}`; only a survey's `assay_fee`, at most qty x fee; set aside with the price; drawn to the seller only as an assay fee is paid (villager: at the forge; player: on reporting the readings); not drawn on a refused assay; the rest returned on any end; the seller's least price excludes what the advance meets | `terms_refusal`, `spend_advance`, `_undraw`, `Contracts.evaluate` |
| CON-04 pay | `on_delivery` (default), `on_result` (dig: stone brought up; survey: a reading with ore), `base_bonus`; the most it could pay is set aside; a seller asks `result_premium` x its least price for results only | `pay_for`, `price_needed`, `set_aside_of`, `_step_dig`, `tell` |
| CON-05 retention, disputes | `retain` up to `retain_max` of each payment held in `reserved`; released on completion; on an early end held in dispute; the reeve (`World.reeve_id`) rules when a party brings it or after `dispute_days`, and at a party's death before the estate passes | `hold_of`, `Contracts.dispute`, `Contracts.rule`, `ruling` |
| CON-06 farm labour | kind `harvest`: ripe cells of a field the buyer holds, cut straight into the owner's store by `FarmPlots.harvest` / `Farming.harvest_into`; worker never holds the crop; no tool; Farming xp | `site_refusal`, `ripe_cells`, `_plan_harvest`, `_step_harvest`, `player_harvest` |
| CON-07 villager hiring | each dawn, agriculture phase: the eight questions in `_hire_harvest` (need; own hands by `FarmPlots.free_minutes` over `hire_days`; worth it; affordable; providers asked in turn, a past good provider first; terms; feasible; obligations); else offered to the player | `npc_hire`, `_hire_harvest` |
| CON-08 signing line | `contracts.services.formal_total` null: the 50-coin goods line applies; set, services use it alone | `Contracts.formal_of` |

Experience (Decision 2 (8)) comes from the work itself: a dig and a sample train Mining, an assay the smith's skill,
a cut cell Farming. Repeat work and reputation (10): the buyer remembers who served it well and asks them first next
time; a promise kept earns regard (existing), a favour more.

## 3. Conservation and determinism

No coin is created: every coin a contract might pay is moved out of the buyer's purse into `reserved` at opening and
moves only to the seller (pay, advance, released retention, a ruling for the seller) or back to the buyer (unused
price, bonus or advance; a ruling for the buyer). `Contracts.reserved_total` counts all of it, so `World.total_coins`
is unchanged; `WorldRecorder.contract_settled` records the moves that are not pay. No good is created: a hired harvest
is the farming faucet the owner's own cutting is (`farm_harvest_*`), into the owner's store. No random draws; villagers
are visited in `World.npcs` order and sellers sorted by (served before, id).

## 4. Saves

New keys are optional on a service record (`terms.pay/bonus_each/retain/advance`, `retained`, `advance`,
`advance_spent`, `results`, `dispute`); `Contracts.load_dict` defaults them (an older record is paid for the work
done). No save version change.

## 5. Decision continuity (DCR-01)

- Decision 2 and CON-03..CON-07: **compatible extension** of CON-01/CON-02 (owner 2026-10-21): same engine, same
  default (paid for the work done), the 50-coin signing rule untouched.
- CON02-S-4 against the earlier CON-02 note "harvesting another's field (the farming hire and theft rules are the paid
  work quests')": an **intentional revision** that the owner made in CON02-S-4 itself (authorised harvest under a
  valid contract is not theft); the paid work quests and the theft rule for unauthorised cutting are unchanged.
- CON-08: **compatible**; the number is not chosen (owner: "do not invent or silently approve a number").
- No conflict found.

## 6. Agent decisions and limits (provisional)

- Balance values in `contracts.services` (`result_premium` 2.0, `retain_max` 0.5, `dispute_days` 3,
  `harvest_walk_minutes` 30, `hire_per_day` 2, `hire_days` 2, `hire_asks` 6) are agent proposals.
- A harvest's going rate is the manor's mending wage a minute over a cell's minutes; with whole coins the floor is
  1 coin a cell.
- CON-07 is switched on in normal play (`npc_hire` true) for the agriculture phase only; it triggers only when a
  household's able members cannot cut its ripe field, which is rare by construction (plots are sized to their labour).
- Repair as a service: villagers' paid repair is LE-05 (Living Economy switch) and household repair is
  `World.work_repair`; no contract kind duplicates it. A free repair between friends is not built.
- Not wired: services feeding business founding (`ventures.gd`) or permanent employment; villager hiring of digs or
  surveys (villagers own no pits and no clue rights to hire for); the lapse of a harvest whose cells the owner cut
  first counts against the worker's regard as any lapse does (the reeve's ruling on held-back pay does weigh it).
