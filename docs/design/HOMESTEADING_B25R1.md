# Homesteading (Build 25 Revision 1, register B25R1-010): audit and plan

Owner directive 2026-11-03, `docs/directives/2026-11-03_b25r1_homesteading.md` (on `wip/requirements-control`; the 16 sections
are the requirement). Worker branch `wip/b25r1-homestead`, from `wip/b25r1-interact` (`10491e7`, the outside world made
interactive). This file is the audit the directive asks for before code (section 15), the design taken, and the phased plan.

## 1. Audit: what exists

| System | Where | What it does today | Reusable for homesteads |
|---|---|---|---|
| Geography | `Overworld` (`overworld.gd`) | Endless seeded world in village coordinates (village `(0,0)-(119,89)`), chunks of 32, trees, boulders, flowers, cliffs, mountain tops, a road network; five settlement sites (`sites`: rect, slots drawn with village stamps, solid by `site_building_at`) joined to the roads; `road_route(gate, sid)` (Dijkstra, deterministic) | All of it: site search reads chunk trees, boulders, flowers, solidity, roads; the road routes give the way to market; site buildings are the precedent for drawing and colliding a building outside |
| Water | none | The overworld has no water tile (overworld_tiles.json: grass, cliff, dirt path, trees, sapling, rock, flowers, bushes) | Not scorable: recorded as a limitation (section 5) |
| Settlement control | none | No influence or jurisdiction area exists: the village is its map rectangle, a settlement its site rectangle | A control area is defined here (agent proposal): the village rect and each site rect grown by a margin |
| Village land | `Property` (`property.gd`), `World.plots`, `Construction` | The manor's land office: parcels, purchase, lease, rent, `can_claim` over the village grid only; sites (`p.site` {kind, cost, need, done, owner}), `World.start_site / deliver / _finish_site` | The ownership references (`hh:<n>`, the player ref), the site record shape, the house cost (`balance.json house_cost`), the house stamp (`village.json stamps.house`: layers, solid rows, interior spots), the ledger stats (`used_building_<item>`). Not the land office itself: wilderness is outside the manor's jurisdiction, and the village grid (`place_idx`, `map.set_solid`, `Property.can_claim`) cannot hold cells outside the map |
| Construction | `construction.gd` | Materials only, no build time; helpers hired by the day; crowded households split (`_found`), couples found (`_found_couple`), `_find_home`, `_keep_building`, family help | The household-formation moment is the hook (`_found`, `_found_couple`); the founding household record (`founded_from`, `founded_day`) and the coin share taken from the family (`_take`, `found_start_share`) |
| Household formation | `construction.gd` daily, `life.gd` | Age of independence = adulthood (`life.adolescent_until` 16); a grown child (`_grown_child`) founds when the house is crowded; partners found a home; `_may_found` bars the founding households (0-2), reeve, sage, guards, parents of young children | The same gates, plus the homestead's own |
| Demography | `life.gd` | Year = 8 game days; stages child <12, adolescent <16, adult <55, elder; old-age death from 60; births to partners (food in the household, interval); `has_room` needs a house building | Births and deaths apply to homesteaders unchanged (births need household food only; `has_room` is false at a homestead, so a homestead child couple founds a village household, a legitimate path) |
| Migration | `settlement/migration.gd` | Caravan-day moves to/from the five off-map settlements for hunger, work, land, marriage | Barred for a homestead household (the homestead has its own failure path); `_pre_leave` and `NPCBrain.on_death` are the departure bookkeeping reused when a founder leaves their posts |
| NPC AI and paths | `npc_brain.gd`, `World._walk`, `VillageMap.find_path / find_path_world`, `Journeys` | Villagers plan on the village grid (outside is a wall to `is_solid`); `find_path_world` is a bounded A* (140 cells) over `is_solid_world`; `Journeys` walks envoys along `road_route` with a hand-laid path and rests by the road at night | A homesteader is driven like a traveller (`World._update_npc` hands the plan to the driver before `brain.decide`); trips reuse the road routes and the Journeys path-laying idea; acts reused unchanged: `chop` (overworld trees through `World.tree_at`), `mine` (overworld boulders through `World.deposit_at`), `eat_home`, `rest_end`, `buy_from`, `buy_food`, `sell_to` |
| Economy | `World.trade / transfer / purchase_qty`, `NPCBrain._plan_sell`, `_seller_of`, `buy_qty`, `_plan_provision` | Every sale moves goods and coins together through the one transaction rule | Market trips use these primitives; nothing is created |
| Bandits | `npc_brain._bandit`, `_prey_for` | The band lives at the village's camp (village map); at night it stalks the player within 18 tiles or a villager outdoors within 40 tiles of the camp, unguarded, carrying 3+ coins | Applies to homesteaders on their way to and from the village by the existing rule; the band does not range over the overworld (limitation, section 5) |
| Wildlife | `Fauna`, `Countryside` | Village woods animals are simulated; countryside animals are ambient (pure in seed and clock) and adopted into Fauna only within 10 tiles of the player (B25R1-002) | A homestead the player is at has real animals round it; far from the player there are none (limitation) |
| Offscreen | `World.update` | Every villager is simulated; beyond `detail_radius` in 0.5 s steps (the abstract tier) | Homesteaders are villagers: simulated everywhere by the same tier, no new architecture |
| Saves | `World.to_dict / load_dict` | Households are saved whole (`duplicate(true)`), NPCs by `NPC.to_dict`, optional keys need no version bump | A new optional `homesteads` section; household key `homestead` |
| Census | `SettlementHoldings.holders`, `World.total_coins` | The goods and coin ledger walk | Homestead stores and site materials added as a holder |
| Storage | `Chests` | Units by id (`chest:<b>:<k>`, containers, carts), access own/foreign/decor, theft rules | A `homestead:<id>` unit: the player's own store, or a household's pantry (foreign) |
| Map | `Atlas`, region map (`wip/b25r1-map`) | Player-known places and explored chunks | A homestead is known to a player who comes near it or claims it; `Homesteads.known_markers(p)` is the hook for the map worker |
| Identity | `identity.gd`, `World.people` | Register `where` = "village" for every living villager record | Unchanged for a homesteader (their civic affiliation stays the village); residence is the household's `homestead`, location their position, history `founded_from` |

### What is missing (and added here)

1. Land eligibility outside settlements and a claim registry (non-overlapping, persistent, owner, bounds).
2. A building that stands outside the village: drawn and solid in the overworld, its interior spots (bed, chest, table) usable.
3. A homesteading decision at household formation, with settlement-health gates.
4. A driver for a homesteader's day outside the village (travel, claim, build, live, market trips, failure, return).
5. Player claiming, delivering, storing and sleeping at a homestead.
6. Measurement: a demographic report line in the economy simulation.

## 2. Design

### 2.1 Claims (`game/scripts/core/homesteads.gd`, `World.homesteads`)

A claim: `{id, owner (an ownership reference: hh:<n> or the player's), founder (person id), x, y, w, h (the claimed land),
house {x, y, w, h, door} (the shelter's footprint inside it), site {kind, cost, need, done, owner} (World's site record shape),
status (intended, claimed, built, abandoned), stage (the household's step), store (Inventory: the player's chest), day,
trade, why, anchor {gate, sid, i} (the road cell it is reached from), known (player ids who know it)}`.

Eligible land (`refusal(land)`): outside the village control area (the village rect grown by `village_control`) and every
settlement's (its site rect grown by `site_control`), not overlapping another claim grown by `claim_gap`, no road on or within
`road_gap` of the house; the house's ground and the ring round its walls free of cliffs, mountain tops and rims and boulders.
Trees are allowed (at most `max_clear`): the measured landscape is wooded enough that no 9 x 10 meadow without one exists near
the roads (probe on seed 1: 0 of 2,333 candidates), so, as the manor's land office grubs a building ground
(`Property.claim`), a claim's saplings, young trees and stumps are grubbed up (`clear_ground`, state "cleared", never regrow)
and its mature trees must be felled first (their logs are the feller's); the house cannot be finished on uncleared ground. The house is the village's house stamp (one construction for
everybody); the claim is the house footprint grown by `claim_margin`.

### 2.2 Who and when (no quota, no annual percentage)

The moments are household formation (`Construction._found`, `_found_couple`) and, rarely, an adult whose household's housing
goal has waited `adult_wait_days`. **Who chooses to go is the decision model of sections 7-8, awaiting the owner**: an early
placeholder (a per-person hash against the 1-3 %) was removed on the owner's clarification of 2026-11-03 (no isolated random
percentage); the hooks now call `Homesteads.decider`, unset, so nobody decides. Gates applied once someone has chosen: the village not declining (population
not below `decline_share` of its level `health_days` ago), at least `min_working_adults` working-age adults and
`min_households` living households remain, the household keeps a working adult, no homesteader left the same household
within `household_gap_days`, the person is no office-holder, trader, guard, player kin or founding-household member
(Migration's and Construction's existing bars), and at most `max_starting` households are setting out at once. Taxes are only
the minor factor above.

### 2.3 Site choice

Candidates along the south gate's road routes to each settlement, `road_from..road_to` cells out, `offset_min..offset_max`
cells to either side, eligible, reachable from the road (`find_path_world`). Score (deterministic, ties by coordinates):
timber (grown trees within `scan` cells), stone (boulders), open ground (meadow cells), market distance (road cells to the
gate), road access, danger (dense woods: wild animals; nearness to the bandit camp), weighted by the founder's trade and
skills (a woodcutter favours timber, a miner stone, a farmer or herder open ground).

### 2.4 The sequence (directive section 6)

`outfit` (in the village: buy food for the pantry and what materials the purse allows, keeping a food reserve) -> `travel`
(walk the road and the last cells) -> claim on arrival (status claimed, the frame marked) -> `build` (deliver what is
carried; fell trees for logs; market trips to sell logs or stone and buy planks, blocks and food) -> the last load in: the
house stands (drawn and solid in the overworld, its interior spots usable) -> `live` (sleep in its beds, eat from the
pantry, firewood from felling, livelihood by trade, market trips when food runs low or goods pile up). Every coin and good
moves through the existing acts and `World.trade`; the founder's start coins are taken from the family as `_found` does
(no land price: the land is free).

Failure: building not finished in `give_up_days`, or the household cannot feed itself (no food and no coin for a day's food)
for `starve_days`: they give up, the site's delivered materials go back to the household's pantry (cancel_site's rule), the
claim is abandoned and freed, and they walk back to the village (a village household again, seeking a home by the village's
rules). Death is by the existing systems; a household with nobody left: its claim is abandoned (the house stands, recorded),
its pantry follows `Property.household_ended`.

### 2.5 Daily life, trade, family

Driven by `Homesteads.drive(n)` from `World._update_npc` (as `Journeys.resume`): children and elders stay round the house;
adults work, trade and build. Births, deaths, courting and inheritance by household continue unchanged. A grown child may
stay (a working member) or found a village household (`couples_needing_home`; `has_room` is false at a homestead); no
automatic new homestead. Nothing forms a village.

### 2.6 Player

Outside the village, facing north on eligible ground: "Claim this land and mark out a homestead here" (the target list; the
house goes north of the player, its door step where they stand). The frame: "Bring materials" (the same delivery as a village
site, from the pack, and the trees on its ground felled). The finished house is entered like a village house (the overworld
collides it with the stamp's solid rows and an open doorway; its roof fades while the player is inside): its chest
(`homestead:<id>`, the player's own store, saved) and its beds (rest). One unfinished claim at a time; no free materials.
Multiplayer guests cannot claim yet (host only).

### 2.7 Map hook

`Homesteads.known_markers(p)` returns `[{id, cell, name, own}]` for the claims player `p` knows (their own, or one they came
within `discover_radius` of). The region map worker reads it; no region-map change is made here.

## 3. Integration points (edits outside the new module, each local)

`world.gd` (create, save, load, `_update_npc` hand-off, dawn, player discovery), `construction.gd` (`_found`, `_found_couple`
hooks, `daily` skips homestead households, `can_hire` refuses homesteaders), `npc_brain.gd` (`act` "homestead", `seek_work`
skips homestead households), `migration.gd` (`_barred`), `property.gd` (`household_ended` hook), `holdings.gd` (census),
`chests.gd` (`homestead:` units), `overworld.gd` (homes collision), `overworld_view.gd` (homes drawn), `main.gd` (targets
and verbs), `balance.json` (`homestead` block), wiki, economy_sim report line.

## 4. Risks

- Shared hot files (world.gd, main.gd, npc_brain.gd) are edited by other R1 workers: edits kept to a few lines each.
- A villager outside the village with a village plan would get lost (`find_path_world` is bounded): every homesteader and
  returner is driven by road routes, never by `brain.decide` outside the village.
- Determinism: no `w.rng` draw in any decision (hash rolls), so the fixed-seed gate is unchanged unless a homestead is
  actually founded in the gate's 30 days.
- Conservation: site materials and stores counted by the census; coins only move between purses.

## 5. Known limitations (recorded, not hidden)

- No water in the overworld: not scored.
- No farming outside the village: the farmland system is the manor's land office; a farmer homesteader chooses open ground
  but lives by timber and stone like the others until outside fields exist.
- Bandits stay on the village map (their camp and paths); homesteaders meet them only near the village. Countryside animals
  are real only near the player. Danger at a remote homestead offscreen is therefore low by the existing systems; no attack is
  invented.
- Only the house stamp is built at a homestead (no modules or lofts outside yet).
- The village's log market is often full (LE-03 contracts with the village's woodcutters): a homesteader's logs may find no
  buyer (measured in the probe: two sales planned, both refused at the counter for want of demand). That is a market outcome
  (WDR-022); a homestead that cannot feed itself gives up and returns.
- Hired helpers do not walk out to a homestead; the household carries its own materials.

## 6. Phases

1. Module, eligibility, claims, save, census, overworld collision and drawing.
2. Player: claim, deliver, chest, bed.
3. NPC: decision gates, site choice, driver (outfit, travel, claim, build, live, trips, failure, return).
4. Tests (homestead_test, player homestead test), CI, wiki, manifest, decisions.
5. Measurement (economy_sim HOMESTEAD line, a multigenerational run, tuning), sim gate.

## 7. How the existing simulation makes major life choices (decision-making audit; owner clarification 2026-11-03 section 3)

Source: `docs/directives/2026-11-03_b25r1_owner_clarifications.md` section 3. This section is the audit asked for; section 8 is the
proposal for the owner. Until it is answered nobody in the game decides to homestead (`Homesteads.decider` is unset; the hooks
at household formation return without effect, checked by `homestead_test`).

### 7.1 The one decision architecture

There is no general "life planner". Every NPC choice has the same two layers:

1. **The live rule decides what is feasible**, in the system that owns the action (NPCBrain, Construction, Ventures, Migration,
   the economy's market). It finds the candidates, applies the hard gates (money in hand, skill, ground, tools, posts that
   cannot be left), and orders them by its own preference.
2. **`JudgmentWeighting.choose` (Expansion 19, `scripts/core/judgment/judgment_weighting.gd`) chooses among the feasible
   candidates**, or "forgo". Each candidate carries factor values (0..100000); a profile in `game/data/judgment.json`
   `decision.profiles` gives permille weights and a forgo utility to beat. Into that one function enter, beside the caller's
   factors: the chooser's judgment of a counterparty (disposition, trust, fear, loyalty, ambivalence: `JudgmentStore`), the
   family name's colouring (never alone a refusal), personality (`JudgmentPersonality`: a per-person weight spread,
   stubbornness for about 30 %, practical wisdom learnt from costly mistakes, anger with a timer), and, where the profile has
   them, aspirations (`JudgmentAspiration`, R5/WDR-011-C). It returns the choice with a full trace (the flight recorder records
   every alternative). It is deterministic (no `World.rng`; a "margin" pick is seeded by the decision's key). A profile is used
   only when `decision.integration.<profile>` is on and judgment is attached; with it off the live rule's own order stands.

Profiles in use today (26): trading (trade_buy, market_buy, market_sell, trade_sell, trade_buy_from, food_seller, tool_buy,
contract_seller), work (hire_choice, work_accept, contract_accept, job_choice), money (credit_lend, barter_accept), family
(family_help, family_meal, family_pay, family_work, family_danger), social (befriend, court_choice, proposal_accept, report),
chapel_offering, bandit_danger, and the one life-course choice of the kind homesteading is: **business_found**.

### 7.2 What feeds a life choice

| Input | Where it lives | How a decision reads it today |
|---|---|---|
| Ambitions / aspirations | `JudgmentAspiration` (judgment.json "aspiration", ON since Build 25 for the career only, B25-AMBITION-D4; `apply` keeps the yes-or-forgo factor, courting and proposals off) | Six domains: food, wealth, property, profession, family, standing. Per person: priority (temperament hash +/-300, age: under 25 lean to family and profession, over 50 away from career; life's shifts), satisfaction (property: owned home 60, leased 40, none 15, farmland +20, an unpaid housing goal -20, a missing tool -20; family: single 15, courting 35, partnered 60, children 70-90; wealth from purse and income), pressure, survival level (hunger, injury, recent danger) that makes food rise and the rest yield. Read by job_choice (scaled_by profession), the ambitious look for work (`NPCBrain.seek_work`), business_found (`ambition` = effective profession priority) |
| Occupation and skills | `NPC.job`, `NPC.skills`, `Skills`; `JudgmentAspiration.skill_fit`, `growth_fit`, `profession_sat` | job_choice weighs skill and growth; business_found weighs skill_fit; Ventures' eligibility needs a founding trade and its level |
| Finances | member purses (`Property.purse("hh:n")`), household `econ` (`NPCBrain.evaluate_household`: cost, days, streak, sustainable), `World.reserve_of`, `World.necessity` (OD-19) | Construction founds only what the household can start (`_home_plan`, `found_start_share`, `_keep` for those staying); Ventures needs `start + working` spare; business_found weighs capital |
| Household circumstances | `Construction.crowded`, `beds_needed`, `housing_goals` (need, since, plan, short, why), `founder_of`, `_may_found`, `_grown_child` | Formation: a crowded household's grown child (else a single adult) founds; couples apart, or a grown child with a partner in a full house, found a home (`couples_needing_home`); a need that cannot be paid waits as a goal |
| Marriage and family | `Relations` (courting, CRT-04), `Life` links, `JudgmentFamily` (FAMILY-01: children, partner, parents, self; never weighed against survival) | Partners are never split; a partner moves in where there is a bed (`Life._move_in`); relatives help build (`_family_help`) |
| Available housing | `Property.market` (empty houses for sale or lease), `Construction.find_ground` (village ground), `_home_plan` | An empty house is bought or leased before ground is built on |
| Other settlements | `Migration` (MIGRATE-18), `RegionTrade.dawn` (S6), `Intel.told_price`, `Journeys`, envoys | **Migration is rule-based, not judged**: on caravan days a real signal on both ends (hunger, work, land, marriage) moves a person or household, at most one per reason, direction and settlement a visit. Tradespeople weigh what envoys and travellers told of the neighbouring places' prices (S6) for buying trips, through the live rules. Nobody weighs "a better life elsewhere" in judgment today |

### 7.3 Adulthood and independent household formation

`Life`: a year is 8 game days; child under 12, adolescent 12-16, adult 16-55 (`NPC.role` follows age at dawn), partners from 18
(`partner_min_age`), births to partners with food in the household. Independence is not an age event: a grown son or daughter
leaves when the house is **crowded** (`Construction.crowded`: more sleeping places needed than beds) and the family can spare a
start (`_found`), or when **a couple needs a home** (`_found_couple`); otherwise they stay. The household is founded with
`founded_from`, the founder's share of the family's coins, and a home by `_home_plan` (an empty house, else village ground and
a house built by the player's rules). These two functions are the "moment of independence", and the homestead hooks
(`Homesteads.consider`, `consider_couple`) sit at the top of them, before the village home is chosen.

### 7.4 Can personality, judgment or aspiration support a homesteading choice?

Yes, with no new engine: `business_found` is the precedent. Ventures (B25-BUSINESS-IMPL) finds the eligible villagers on their
own weekly morning (`looks_today`: a per-person hash of the day), checks ability, premises, capital, household finances and
demand by live rules (`Ventures.refusal`), then asks `JudgmentWeighting.choose(..., "business_found", [{id: "found",
factors: {ambition, demand, capital, skill}}])` against forgo. Homesteading is the same shape of decision: an option the live
rules find feasible, weighed with the person's aspirations, personality and circumstances against the alternatives.

### 7.5 Costs, benefits and risks of leaving (what exists, what does not)

Exists: money (start cost, what the family keeps), housing need (goals and their age), property satisfaction (owning a home
counts far more than leasing or lodging), the family hierarchy, survival and recent danger (`JudgmentAspiration._danger`: harm
the person knows of), the trade's earnings (job_market, income_days). Not modelled anywhere today: a value placed on
independence or isolation, an expected distance-to-market cost, or a learnt sense of wilderness danger. These are what a
homestead profile has to supply as factors, from the site search's real geography (`Homesteads._score`: timber, stone, open
ground, road distance to the village, woods density, nearness to the bandits' camp).

### 7.6 Settlement population safeguards

None exist for leaving: Migration's pace is one move per reason, direction and settlement a caravan visit, and nobody's
leaving is checked against the village's health. The homestead gates are new (`Homesteads.gate`): no departure while the
village's people are below `decline_share` of their number `health_days` ago, at least `min_working_adults` and
`min_households` left, the household keeps a working adult, `household_gap_days` between departures from one household,
`max_starting` households setting out at once, and the existing bars (office-holders, traders, guards, player kin, founding
households, employees, stall attendants).

### 7.7 From a decision to the sequence (built and tested)

`Homesteads.begin(h, who, leaving)` (the entry a decision calls): gates, a site (`find_site`), the start coins from the family
(as `_found`), the new household (`homestead` key, `founded_from`), the posts left (Migration's departure bookkeeping, posts
handed on as after a death, the trade kept on the claim), then the driver (`World._update_npc` hands their plan to
`Homesteads.plan`): outfit at the market, walk the road, claim on arrival (or another site, or give up), clear the house's
ground (fell, grub), buy and carry materials, the house built through the village's site rule, life there (beds, pantry,
firewood, felling or quarrying, market trips), failure and return, abandonment when the household ends.

## 8. Proposed decision process (for the owner)

**Moment.** Only where the village already makes an independence choice: `Construction._found` (a crowded household's grown
child is to found a household) and `_found_couple` (a couple needs a home), plus a rare secondary moment for an adult whose
household's housing goal has waited `adult_wait_days`. No daily roll for everybody.

**Feasibility first (live rules, unchanged by the decision).** The gates of 7.6, a site found by real geography, and the
coins for a start. If any fails the homestead is simply not a candidate, and formation goes on as today.

**The choice (one `JudgmentWeighting.choose`, new profile `homestead_choice`, `decision.integration.homestead_choice`).**
Candidates: `village` (the home `_home_plan` would give: always present, the default) and `homestead` (the best site), so the
person weighs one against the other rather than a yes/no in isolation. Proposed factors, all from existing state:
- `property_gap`: the property aspiration's effective priority times how far its satisfaction is below what the homestead
  gives (owned land and house versus lodging, leasing or a long-unpaid goal): the strongest reason to go;
- `trade_fit`: how the site serves their trade and skills (timber for a woodcutter, stone for a miner, open ground for a
  farmer; `_score`), scaled by the profession priority;
- `village_prospect` (on the village candidate): the household's sustainability and the trade's earnings in the village
  (`econ.sustainable`, job_market pay);
- `capital`: spare coins against the start and the house's estimated cost;
- `family_ties` (against going): partner, children and parents in the village, the family priority, loyalty (`JudgmentStore`);
- `isolation_risk` (against going): road distance to market, woods density, nearness of the bandits' camp, the person's own
  recent danger and practical wisdom;
- `tax` (minor, at most a tenth of the weights): the village's tax band.
Personality enters as for every choice (weight spread, stubbornness, anger); a margin pick seeded by the decision's key keeps it
deterministic.

**The brakes (population balance, not the reason).** The 1-3 % is a cap on the outcome, applied before the choice: the
homestead candidate is offered only while the young adults who chose a homestead stay within `young_share` (2 %) of those who
formed a household over a rolling `share_window` (for example 5 game years), counted from the village's own history; the
adult path has its own much smaller cap. Weights are tuned by the demographic run so the reasoning, not the cap, produces most
of the "no"s: the cap only stops a run of departures. No quota: nobody is ever made to go.

**From choice to action.** `homestead` chosen: `Homesteads.begin` (7.7). `village` chosen: `_found` / `_found_couple` carry
on exactly as today. Every choice and its trace go to the flight recorder like any judged choice.

**Switches and safety.** Off unless `decision.integration.homestead_choice` and judgment are on (as business_found);
aspiration factors read only through the existing `JudgmentAspiration` readers. With the switch off the game is exactly as
now (no homesteads by NPCs; the player's homesteading is unaffected).

**Owner questions (one each, if the lead puts them):** (a) approve the profile, its candidates and factors above, or name
others; (b) the brake: the share of young adults forming households over a rolling window (proposed 2 % over 5 game years),
or another form; (c) whether the secondary (established adult) path is wanted now or later.
