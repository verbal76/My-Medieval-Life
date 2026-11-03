# Seed travelers (Build 25 Revision 1, B25R1-009)

Owner directive 2026-11-03, `docs/directives/2026-11-03_b25r1_seed_travelers.md` (on `wip/requirements-control`):
"We are seeding reasons for existing people to travel, not seeding fake people into the countryside." Owner decision the
same day (about 14:15 EST), relayed by the lead: keep the ambient countryside passers-by as well ("We can have them as
well"). So the roads carry both: ambient passers-by (scenery, `Countryside`) and real residents who travel (this work).

Branch `wip/b25r1-travelers`, from `wip/b25r1-interact` (10491e7). Interaction manifest INT-695; decisions in
`docs/DECISIONS.md` (2026-11-03, B25R1-009 rows).

## 1. Audit: who is on the roads, and how

| Who | Representation | Moves in the world? | Interactive? | Economy |
|---|---|---|---|---|
| Village residents | Full `NPC` objects in `World.npcs` (household, home, job, purse, pack, relations, judgment, memory, skills), saved one by one | Yes: `World._walk` along `n.path` (village A* inside the village, `VillageMap.find_path_world` outside, at most 140 cells across) | Yes: `Main._creature_at` / `World.present` find any NPC on the surface level wherever they stand; Talk, trade window, attack, pickpocket | Real coins and goods, every transfer booked |
| A village resident on a journey | The same `NPC` with `n.journey = {to, purpose, leg, since, gate}` (saved, optional key) | Yes: `Journeys` (REGION-NAV-01 AD-4/S3) plans village path to the south gate, `Overworld.road_route` to the site, the site, back; rests by the road 20:00-6:00; turns back on a closed road; dies by the ordinary rules (`World.kill` ends the journey; slain, the pack lies where they fall) | Yes, as above (before this work they brushed the player off while walking: `Dialogue.busy`) | `World.trade` refuses a villager on a journey at home (world.gd, "buys and sells nothing at home") |
| Purposes that send them | Envoys (`Envoys`, the reeve's survey), buying trips (`RegionTrade.dawn` on fresh intel, S6), now seed errands | | | |
| Other settlements' people | Household records in `OffMapSettlement.hh` (members as `[born, sex]` pairs, a purse, a pantry), stepped once a day without walking anyone | No. At a settlement's site `SettlementFolk.people` derives the keepers, the official and the self-employed crafters from those records (names hashed from the seed, settlement, household and member), shown at their doors in working hours; the trader is "on the road" on caravan visit days but is not drawn walking | Keepers: their window (`GameUI.show_keeper`): buy and sell at the settlement's price, ask the way | Their own books (`SettlementParty`), audited (`Regions.audit`) |
| Migration between village and settlements | `Migration` moves a person or household on a caravan visit day, instantly ("the road itself is not walked"), converting between an `NPC` and an off-map member | No | n/a | Purse and goods move with them |
| Couriers | `CourierService` jobs with a courier villager; regular routes and special deliveries in journey days | Abstract (days), not walked | Booth window | Fees and goods booked both sides |
| Ambient countryside passers-by | `Countryside.travellers_near`: pedlars, pilgrims and wayfarers on the gate trails, a pure function of seed and clock, nothing saved, in no ledger; plus the caravan's wagon and driver on its visit days | Drawn only (Main._sync_countryside) | Since 10491e7: tapped or used, a word and the way to every settlement (`GameUI.show_traveller`, `Atlas.learn_place`) | None (they carry and sell nothing) |

### Purchases from a settlement keeper

`SettlementFolk.buy_from(w, buyer_ref, person, item, n)`: the person must be present (working hours, the trader not on the
caravan road, a crafter with something to sell); `sale_cap` limits what they hand over; the price is the settlement's market
price (`OffMapSettlement.price`); the buyer's coins (`CourierService.coins_of`) and pack room are checked. The settlement's
side is `SettlementParty.deal` (its checks, `outside_*` flow line, journal); the village side is booked exactly as the
courier edge books it (`_village_side`: `imported_<item>`, `coin_sources`, `caravan_coins_out`), so both audits balance and
the coin identity `total_coins + regions.coins == coin_sources + regions.net_paid_by_village` holds. `RegionTrade.act_buy`
is the villager's face-to-face use of it (within 3 tiles of the seller's door).

### How the ambient passers-by differ

They are not people: no identity, household, purse or pack, not saved, not in the population or any ledger, cannot be
hurt or followed home. They stay (owner decision above) as scenery; the real residents on the road now walk among them.

### Defect found while testing: travellers starved

A journey's traveller ate only from their pack (`Journeys.night_and_food`) and nothing ever put food in it, so a resident
sent on a trip of more than about two days (hunger 3 an hour; at 0 hunger, 2 hit points an hour of 30) starved on the road
or at the site. The first seed run showed it: all three seed travellers died of starvation on days 3 and 4. This is a
mechanic failing its function (WDR-022), so it is fixed within the existing rules (section 2).

## 2. Design

- **Designation** (`SeedTravelers.designate`, called once at the end of `World.setup`; never on loading, never again).
  `settlements.json` `seed_travelers`: `count` 3, `max_price` 15, `wait_mornings` 3, `skip_jobs` (posts the village cannot
  spare: guards, reeve, sage, tavern keepers, cooks, merchants, clergy, manor hands). Candidates: living adults of a village
  household with a home, no manor job, not on a journey; ranked by `Overworld.hash32(seed, id, salt)` (no rng draw, so nothing
  else in the founding moves). Each takes the first settlement, in a hashed rotation with places no earlier seed traveler took
  first, where a keeper or crafter (else the trader, never a trader who is on the road every day) sells an item they can pay
  for from their coins above their reserve, priced at most `max_price`, with room in their pack (`errand_at`).
- **The journey** is the ordinary buying journey: `Journeys.start(w, n, sid, {kind: "buy", about, item, qty: 1, price,
  seed: true, wait})`. Only the starting village's residents are seed travelers: the other settlements' people are household
  records, and walking one would need a second representation of the same person (duplication), which the directive forbids.
- **The purchase** is `RegionTrade.at_site` / `act_buy` unchanged, plus one rule: a purpose with `wait` (only seed errands set
  it) waits for a seller who is not at their door (the trader on the caravan road), a morning at a time, up to `wait` mornings
  (`stay_until`), then goes home with nothing. Sold out or too dear by then: the existing out-of-date fallback, home with nothing.
- **Food for the road** (`Journeys.provision`, `buy_food`, `trip_minutes`; applies to every journey, envoys and buying trips
  too): on setting off the traveller moves food for the estimated walk (road tiles at the walking pace, with the night rests)
  from the household pantry to the pack, at most half the pantry's food points; at the site, when hungry with an empty pack and
  when leaving for home, they buy food for the walk from the people there who sell it (cheapest per food point first, one unit
  at a time, `SettlementFolk.buy_from`). An empty pantry, no food on sale or no coins: they go hungry by the existing rules.
- **Afterwards**: `Journeys.end` clears the journey (stat `seed_travelers_ended_<how>`); the brain plans their ordinary day.
- **Talking on the road**: a villager on a journey stops for a word (`Main.approach` no longer brushes them off while they
  walk) and says where they are going and why (`Dialogue._doing`: "I'm on the road to Netherton to buy wheat.").
- **Saves**: nothing new in the save format: the purpose (with `seed` and `wait`) is part of `NPC.journey`, already saved;
  plans are not saved and `Journeys.resume` replans from where they stand.

### General function for other workers (homesteading, wip/b25r1-homestead)

- `Journeys.start(w, n, sid, purpose)` sends any villager to a settlement and home along the roads; `World.journey_hook`
  (`(n) -> bool`) is where a purpose gives them work at the site.
- For a destination that is not a settlement (a wilderness cell), a plan step `{k: "go", to: cell}` already walks the
  world's cells outside the village (`World._walk` uses `VillageMap.find_path_world` when either end is outside, limited to
  `WORLD_PATH_CELLS` 140 across); longer walks would chain road legs (`Overworld.road_route`/`route_between`) the way
  `Journeys.resume` does.
- `Journeys.trip_minutes`, `provision` and `buy_food` are general (any NPC with a household; `buy_food` needs a settlement
  destination in `n.journey.to`).

## 3. Evidence

`game/tests/seed_traveler_test.gd` (in `.github/workflows/tests.yml`), 48 checks, 0 failures. In seed 1 the nearest seed
traveler, Wat Shepherd (farmer), walks to Netherton for a healing tonic, finds the trader away on the caravan road and buys
wheat from Joan Stone, the farm's keeper, instead (SeedTravelers.refresh), and is home the next day. Covers designation (count, real residents, affordability, no duplicates, population unchanged, not re-sent on load), one whole
journey (road, site, purchase in person, item in pack, seller's stock down by one, village goods up by one booked as imported,
coins conserved every minute, books balance, home, the same person, ordinary life after, not sent again), determinism (same
choices and the same hourly trace from two worlds of one seed), save/load mid-road (same person, place and journey; walks on,
buys, comes home; coins conserved), and the real main scene (a seed traveler on the road is tapped, walked up to, talked to,
and says where they are going).

Other suites on the same code: run_tests (3 days) 3602/0, world_test 339/0, outside_interact_test 23/0, countryside_test
38/0, journey_test 14/0, journey_s3_test 19/0, envoy_test 31/0, region_trade_test 23/0, region_sim_test 8/0,
settlement_folk_test 36/0, conservation_test 8/0, wiki_test passed; `tools/check_interactions.py` 0 problems. Test
corrections, each explained in its commit: region_trade_test's "no forced trade" check skips the seed travelers (not sent by
RegionTrade); run_tests' grain census counts the chapel's alms parcels (as `Census` already did); region_sim_test's
save-mid-mission scenario keeps the seed travelers: with them seed 1's job board stays busy and the envoy post (ranked last)
waits weeks for a taker, an outcome, so after two days untaken a free villager takes it from the board by the board's own
`take`/`plan` and the scenario saves and loads that mission.

Sim gate (SIM-GATE-01): re-recorded from `df67e8e`, determinism re-check PASS, currency leak 0 and no item leaks;
`docs/release/SIM_BASELINE_CHANGES_B25R1_TRAVELERS.md`.

### Flight recorder hooks (B25R1-016)

`Journeys.record(w, n, what, data)` is the one funnel: guarded `w.recorder != null and has_method("journey_event")`, read-only,
the person by stable id (`NPC.id`, the Identity id). Calls: `Journeys.start` (refused: no road; started: decision, trigger,
origin, destination, purpose, seed flag, coins), `leg_done` (arrived), `end` (ended: home, turned_back, died, lost, no road;
a death on the road comes through `World.kill` -> `end`), `provision` (provisioned), `buy_food` (bought_food),
`RegionTrade.act_buy` (bought: seller, item, qty, coins paid, instead_of), `RegionTrade._out_of_date` (failed: why),
`RegionTrade.at_site` (waited), `SeedTravelers.designate` (seed_designated). The recorder worker defines `journey_event`;
until it exists the calls are skipped.

## 4. Limitations

- Only the starting village's residents travel as seed travelers; the other settlements' people stay household records
  (no walking representation without duplication). Their trader's caravan visits remain abstract (not drawn walking).
- The ambient passers-by are kept by the owner's decision; they are scenery, not residents.
- A seed traveler's purchase can fail by the ordinary rules (sold out, too dear, seller away past the wait), and they can die
  on the road; these are outcomes, not defects (WDR-022).
- `trip_minutes` estimates the walk from the road length and pace; it does not foresee waiting days at the site (covered by
  buying food there).
