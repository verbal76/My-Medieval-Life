# Early-economy review (Build 7)

Owner question (2026-10-18): the player starts with 5 coins and land costs 60 or more. Does the
early game give accessible, understandable, repeatable ways to earn money without exploits or theft?

**Answer: not yet.**
- Mining iron is the only strong method. Nothing points the player to it, and it runs dry once the
  village has worked the deposits out (about day 10).
- Harvest work is the only lasting one. It comes in bursts and is hard to find.
- A player who earns nothing starves on day 5.

Nothing here has been changed. Every number below is current Build 7 behaviour. Changes are listed
as proposals at the end, for the owner's approval.

## How it was measured

`game/tests/earn_sim.gd` runs a scripted new player for 10 game days in the real `World`
simulation (seed 1; seed 2 for the deposits check). It uses one earning method only, and buys and
eats food when hungry. Walking time is ignored, so the results are upper bounds.
- A game day takes 12 real minutes (`game_minutes_per_second` 2.0).
- Food costs about 3 coins a day.

```sh
godot --headless --path game --script res://tests/earn_sim.gd -- --strategy idle|mine|harvest|hunt|observe --days 10 --seed 1
```

| Strategy | Coins after 10 days | Reached 60 | Reached 150 | Notes |
|---|---|---|---|---|
| Idle (buys food, earns nothing) | dead | — | — | Starved on day 5 at 19:22; 5 coins buys about two meals |
| Mining iron, 08:00–17:00 | 221 | day 1, 17:00 | day 4, 17:00 | The rusty pickaxe broke on day 3; replacements cost 45–46; 32 ore went unsold because the smiths had 0–1 coins on days 2–5 |
| Harvest jobs only | 171 | day 3 | day 10 | 33 jobs at 6 coins each; 147 of about 180 half-hourly checks found no work |
| Hunting | 49 | day 1 | never | 12 kills, all on day 1; wild animals did not come back |

## Earning methods

| Method | How the player finds it | Pay | Limits |
|---|---|---|---|
| Mining | "Mine iron ore (N left)" prompt; "Mine" on the map. No NPC mentions it | About 3 a ore (iron), falling as buyers stock up | Deposits are finite and never refill; NPC miners alone empty them by about day 10–14 |
| "Any work for me?": harvest | Talking to an adult farmer, woodcutter or miner; no marker | 6 for 24 wheat | Only when a field has 24+ ripe wheat and the farmer has 6 coins; bursty |
| Hire: mine shift | as above | 8 for 6 ore | Pays less than selling the same ore (about 18) |
| Hire: woodcutting | as above | 6 for 6 logs | Needs an axe (about 45), which a new player cannot afford |
| Side quests | Marker over the giver | 4–30 | At most 4 offers in the village; the reward is cut to whatever the giver holds (B7-002) |
| Hunting | "attack to hunt it" | Boar about 10, rabbit about 2 | About 12 wild adults; the player can kill them all |
| Crafting | Station prompts | Smelting and tanning about +2 an item; cooking for yourself saves money | Rings, amulet and the two helmets have no buyer (B7-003) |
| Felling and selling logs | "Fell this tree" | About 1 a log | Needs an axe |
| Manor day labour, wages, public works | — | — | NPCs only; not open to the player |

Selling pays `value × clamp(1.2 − 0.04 × buyer's stock, 0.4, 1.2) × 0.6` (`world.gd:488`). Buyers
are limited by their coins: smiths sat at 0–15 for days and cooks at about 15.

## Problems found

These are recorded in `BUILD_7_ISSUES.md` as B7-001 to B7-007.

## Proposals for the owner (not applied)

| For | Proposal | Changes |
|---|---|---|
| B7-001 starting pressure | Start with 15–20 coins (about a week of food) | `start_coins_player` 5 → 15–20 |
| B7-001, B7-006 steady work | Let the player ask the reeve for manor day labour, paid from the treasury (100–380 coins in the runs) | New dialogue choice; uses `day_labour_wage` 6 |
| B7-006 mine shift | Pay more than the market value of the ore | Mine shift wage 8 → 15+, or fewer ore |
| B7-005 discoverability | Opening message and journal hint: "Ask farmers, woodcutters and miners for work; the smith buys ore"; shop window titled "Trade with …" | Text only |
| B7-002 quest pay | Offer a quest only when the giver can pay the full reward, and set it aside | Quest offer rule |
| B7-004 harvest exploit | Wheat cut for harvest work belongs to the farmer: marked stolen if the job lapses | Theft rule |
| B7-003 dead-end crafts | The goods merchant buys rings, amulets and helmets | `BUYS.merchant_goods` |
| B7-007 deposits | Stone in the caravan's imports, and/or deposits that slowly refill | `caravan_import_stock`, a new refill rate |
| B7-008 buyer drain | The 15-coin cash floor for NPC buyers also applies to the player's sales | `trader_cash_floor` |
