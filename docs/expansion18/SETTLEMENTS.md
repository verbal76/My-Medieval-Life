# The five neighbouring settlements (SET-C-FIVE; register SET-C-SIM, SET-C-FIVE, ECON-P1.3)

Expansion 18 (Build 18). Owner answers 2026-10-23: Q18-4 "5 of mixed kinds"; Q18-3 "Those settlements have simulated economies just
like this one, it comes from their villagers, or village political structure or companies."; "Same rules, lighter detail";
"Their traders (Recommended)" for the caravan (`docs/directives/2026-10-23_owner_answers_q18_2_q18_3.md`,
`..._q18_4_q18_8.md`, `..._caravan_purses_skills.md`); and the reminder "Remember we are basing this off of the lore locations
document from the book, it is in the repository" (`docs/directives/2026-10-23_lore_locations_basis.md`). The lore locations document is
`docs/world/B_GAZETTEER.md` (with `D_POLITICAL_ATLAS.md`, `E_ECONOMY.md`, `G_STARTING_COUNTY_CANDIDATES.md`), built from
*The Well at the World's End* (William Morris, 1896).

**Labels** (as everywhere in `docs/world/`): **CANON** = stated in the novel, with the paragraph id and a verbatim quote (checked
against `research/corpus/paragraphs.json` when this file was written); **CANON-INFERRED** = a reasonable reading, not stated;
**GAME EXPANSION** = ours, never Morris's; **UNRESOLVED** = open. Nothing under GAME EXPANSION is presented as Morris's.

## 1. How the five were chosen

The starting county is still undecided (`G_STARTING_COUNTY_CANDIDATES.md`: C1 west of Upmeads, C3 the Down-foot vale; decision
J-D2, *Proposed*). Both open onto the same ground: the road south from the Four-want-way through Wulstead, over the Downs to
Higham-on-the-Way and the vine country beyond. So the five are the named places along that road, nearest first, with the most
different characters the text gives (a market town, an abbey town, a hamlet, an unwalled village, an abbey village). They are
not in the novel's war: the settings use the peaceful picture of the first era (E1 in `D_POLITICAL_ATLAS.md`; the era question, J-D1,
is open; the Burgers' raids of E2 are not simulated here). **The village's own place on this road is GAME EXPANSION and
UNRESOLVED (J-D2)**: the distances below are measured from the village taken as a point in the Upmeads country, so that the
nearest settlement is Wulstead, a ride the novel itself calls short (BFOUR-C30-P010).

Distances: **GAME EXPANSION**. The novel gives one fixed distance on this road, "a matter of forty miles" from Wulstead to Higham
(`BONE-C3-P037` "A matter of forty miles"); every other figure below is ours: Wulstead 20 miles from the village, Netherton
30, Garton 50, Higham-on-the-Way 60 (the forty miles on from Wulstead), Bourton Abbas 72 (a morning's ride from Higham, CANON-INFERRED
from `BONE-C7-P007` "So he rode till it was noon"). One mile is 12 map tiles (`game/data/settlements.json`, `tiles_per_mile`);
the caravan's visit rhythm follows the distance (section 4).

## 2. The five

| Settlement | Kind (game) | People | Lore basis | Government in the game | Trades in the game (GAME EXPANSION) |
|---|---|---|---|---|---|
| **Wulstead** | market town | 67 | cheaping-town, mayor and tipstaves, a market-place with a fountain and a buttercross | the mayor and council (3 officials) | farming, herding, woodcutting, sawpit, tannery, cookshops, weaving, herb garden, traders and horse-dealers |
| **Netherton** | hamlet | 16 | a thorp beside a stream at the foot of the Downs, a fair church and a little house of Canons | the canons' steward (1 official) | farming, herding, a herb garden, one trader |
| **Garton** | village (thorp) | 47 | a poor, unwalled thorp at the Down-foot with elders and spearmen | the elders of the street cross (1 official) | farming, herding, woodcutting, **mining** (diggings in the chalk hills), a forge, one trader |
| **Higham-on-the-Way** | abbey town | 99 | big walled town with a castle and a very rich abbey, "no better market betwixt this and Babylon" | the Abbot's reeve and the burgesses (3 officials) | farming, herding, woodcutting, sawpit, **masonry**, a forge, tannery, cookshops, weaving, herb garden, traders and horse-dealers |
| **Bourton Abbas** | abbey village | 32 | grey-stone thorp in a wooded valley on the Abbey's outermost land, a tavern, a vineyard | the abbey's bailiff (1 official) | farming, woodcutting, **a stone quarry**, masons, a cookshop and tavern, one trader |

People are the founding numbers (`game/data/settlements.json`); they change from there by what the settlement's own economy allows.
They are also **GAME EXPANSION**: the novel gives no population for any of them except the 23 spearmen of Garton (below).

The owner's first industries (Q18-2: forestry, carpentry, masonry, smithing, farming, tanning, trade, mining) are all present
somewhere among the five, and each settlement is listed with the ones it practises in `industries`. Where the lore names no trade
(the Down-foot diggings, the forge, the quarry) the trade is ours and says so here.

### 2.1 Wulstead: the market town

- CANON: "a good cheaping-town hight Wulstead," is the road's town south of Upmeads (`BONE-C3-P004` "a good cheaping-town hight Wulstead").
- CANON: a market-place with a fountain and a buttercross (`BONE-C3-P005` "maids gathered about the fountain amidst the market-place, and two or three dames sitting under the buttercross").
- CANON: a mayor and tipstaves (`BONE-C3-P021` "I spake about the mayor and the tipstaves"), hence the council as its government here.
- CANON: forty miles from Higham (`BONE-C3-P037` "A matter of forty miles").
- Not simulated: the House of Black Canons of Wulstead and the later palisade (E2, `BFOUR-C25-P002`); a house of Canons stands in our Netherton.
- GAME EXPANSION: the trades above; the weavers and the herb garden stand for the household crafts of a market town; the horse-dealers
  are the traders who keep horses (section 5). Its smith is not here: the nearest ore is Garton's, and no forge is kept without iron.

### 2.2 Netherton: the hamlet

- CANON: `BONE-C4-P002` "a little thorp beside a stream, and thereby a fair church and a little house of Canons".
- CANON: it is at the foot of the Downs, "Just before the slopes began to rise" (`BONE-C4-P002` "Just before the slopes began to rise"); it is named in `BONE-C4-P005` "the thorp beneath, which was called Netherton".
- CANON-INFERRED: a church and a house of Canons make a church-led hamlet; its government here is the canons' steward, and the
  tithe (the settlement's toll rate, section 3) goes to him.
- GAME EXPANSION: farming and herding for a few households, the Canons' herb garden as the infirmary, one trader (a chapman).

### 2.3 Garton: the village

- CANON: it lies "under the hanging of the hill that was the beginning of the Down country" (`BFOUR-C21-P017` "a little thorp under the hanging of the hill that was the beginning of the Down country on that road"), and is one of the "thorps at the feet of the downs toward Higham" (`BFOUR-C22-P011` "go adown to the thorps at the feet of the downs toward Higham", naming it: `BFOUR-C22-P011` "it may be at Garton").
- CANON: "we be a poor unwalled people" and its elders receive the newcomers (`BFOUR-C21-P021` "we be a poor unwalled people"); hence the elders as its government.
- CANON: twenty-three spearmen (`BFOUR-C23-P002` "The spearmen of the thorp did not fail them, and numbered twenty and three all told.") , in the war year (E2); the game's peaceful picture does not keep a muster, only one official.
- GAME EXPANSION and UNRESOLVED: the novel names no mine. The Down country is hill country with the Greenway and chalk, so a small diggings (iron, coal, copper, stone
  with finite reserves) is placed here as the nearest ground the lore leaves open; this is where the caravan's ore and coal come from. If the owner prefers another place for it, the data is one entry (`quarry` and `reserves`).

### 2.4 Higham-on-the-Way: the abbey town

- CANON: `BONE-C3-P031` "a big town plenteous of victuals, with strong walls and a castle, and a very rich abbey of monks".
- CANON: peace within its walls "because the father abbot wages a many men to guard him and his" (`BONE-C3-P031` "the father abbot wages a many men to guard him and his"); hence the Abbot's reeve and three paid officials.
- CANON: `BONE-C3-P031` "No better market is there betwixt this and Babylon"; the countryside brings food and wares to town and Abbey (`BONE-C6-P029` "folk were coming in from the countryside with victual and other wares for the town and the Abbey"), and the street trades are chapmen, shoe-smiths, glovers, tinsmiths, coppersmiths and horners (same paragraph).
- CANON: the wealth of the Abbey's lands (`BONE-C5-P012` "the wealth of the lands of St. Mary's at Higham") and "the wool of the downs is good" (`BONE-C3-P038` "the wool of the downs is good").
- GAME EXPANSION: the masons and the quarry stone it works (from Bourton and Garton by the traders), the forge and the other crafts, sized as the largest of the five.

### 2.5 Bourton Abbas: the abbey village

- CANON: `BONE-C7-P007` "a little thorp of grey stone houses, trim enough, in a valley wherein there was more of wild-wood trees and less of fruit-bearers".
- CANON: a tavern that serves `BONE-C7-P007` "bread and flesh, and good wine of the hill-side", and a vineyard (`BONE-C7-P009` "a vineyard hard by").
- CANON: `BONE-C7-P009` "this thorp, which is called Bourton Abbas, is a land of the Abbey of Higham; though it be the outermost of its lands"; hence the Abbey's bailiff as its government.
- CANON-INFERRED: grey stone houses and wild-wood suggest stone and timber as its trades. GAME EXPANSION: the quarry (its stone, with a finite reserve) and the masons; the vineyard is not a good in the game yet, so its fields grow wheat and seed.

## 3. How each one runs (the same rules, lighter detail)

Each settlement is an economy of its own, stepped once a day by `OffMapSettlement` (`game/scripts/core/settlement/offmap.gd`),
without walking anyone: **households** (adults and children, a purse, a pantry of the village's own foods, hunger), **businesses**
(a till, a stock, workers, the village's real recipes from `game/data/recipes.json`), a **treasury** (collects the village's tax
rule, pays its officials, buys upkeep goods, hires day labour for the hard-up, relieves a hungry household with food it buys) and one
**market** with a price per good that floats with yesterday's imbalance inside the village's own price band. Coins and goods move
only by matched lines; the book of each settlement balances every day (`OffMapSettlement.audit`). The details, rules and numbers
are in `docs/expansion18/DESIGN.md` section 10, `docs/DECISIONS.md` and `docs/SYSTEM_INTERACTION_MANIFEST.md` (INT-230 to INT-233).

**The people live a life too** (REG-DEMO-01): every member has an age on the village's 8-day year; they are born to couples, die of old age
by the village's own mortality curve, grow up at 16, marry at 18 and older into households of their own that work for a business, and
a household that loses its last adult passes its coins and food to kin (else the treasury). Same rules, household level; the rules and
what is provisional are in `DESIGN.md` section 12 ("The people") and INT-260.

## 4. The traders are the caravan

The merchants of each settlement are its **trader**: the only party that meets the village's caravan, with its own till and stock. On a
visit day the traders whose turn it is come to the village (a settlement's turn comes every `ceil(miles / 20)` caravan visits: Wulstead
every visit, Netherton every second, Garton and Higham every third, Bourton every fourth; the first visit brings all five). A trader
sells the village only what it holds, and buys from the village only what its settlement still wants and only with the coins in its
till. Between themselves the traders keep a wholesale round every six days so that, for instance, Garton's ore can reach Higham's
forge. There is no allowance, no purse that fills by itself, no coin created: the settlements' coins are their own and change only by
what the village and they pay each other.

## 4a. The traders sell food (REG-BUY-01, REG-BUY-P1)

Owner Q18-10 ("anyone may purchase goods from another settlement") and REG-BUY-D1 (a settlement may sell food; willingness and
quantity account for household consumption, reserves, expected production and economic necessity; no absolute prohibition; the
settlement keeps its agency and may decide unfavourably). The approved policy, and where each part lives (`offmap.gd`):

1. **What a trader carries.** Besides ore, seed and medicine, food bought from its own settlement's food businesses (those whose
   output or recipes make a food: farm, herd, cookshop), taken along when it goes on the road (`begin_visit` -> `stock_trader_food`).
   Food it holds is sold to the village like any carried good; what it does not sell is offered to its settlement's households next
   morning.
2. **The local claim.** A settlement releases only food above `food_claim_pts()`: its households' need over the village's
   `reserve_days` (per household, need less pantry, as `World.necessity` does), less what its businesses expect to produce over those
   days (`expected_food_pts`, natural output at the workers they have; the cookshop's pottage is made of food already counted).
   The households shopped that morning before the trader (the step runs at six, the visit is at noon): local buyers first, as
   `NPCBrain._sale_stock` does. A business's recipe and tool inputs (`_keep`) and a farm's horses' feed over `reserve_days` are never offered.
3. **A demonstrated cash shortfall.** A food business may sell into the protected food only up to its shortfall
   (`cash_shortfall` = `_expense_due` less its till; `_expense_due` = the wage bill, `_wage_bill`, plus the cost of the inputs and
   tools it lacks, `_inputs_short`, the same list `_business_buys` buys from). No new expense category and no number of ours.
4. **Prices.** The settlement's own floating price (`price`/`food_price`); the trader pays the producer `trader_pays_share` of it
   (as `_trader_collects`), from its own till above its trading capital. The village's buyers take the cheapest trader on the road
   (`Regions.food_seller`).

The village's side is `NPCBrain._caravan_food` (households with no food to be had in the village, the treasury's granary, the
food merchant, cook and tavern); see `docs/SYSTEM_INTERACTION_MANIFEST.md` INT-290 and INT-291. Every coin and unit crosses the
border as in any caravan trade (`coin_sources`, `imported_*`, `caravan_coins_out`).

## 4b. Food between the settlements (X20-SETTLE-FOOD, Expansion 20)

REG-BUY-D1 (owner 2026-10-23) lets a settlement sell food to another; REG-X20-D3 found no live path (road trade carried no food,
`RegionalMarket` was not wired in). Implemented on `wip/x20-settle-food` through the existing settlement layer only: no new purchasing
system, nothing in the village's `World.trade`, and the six-day abstraction of E22-OD-04 (physical caravans are a future stage).

- **When.** `Regions.food_round(d)` runs on the traders' wholesale day (`road_trade_every_days`, after `road_trade`), from both
  `step_day` and `step_hour`; `Regions.day` (saved) guards against a second round on a loaded save.
- **Who buys.** The trader of every settlement whose people hold under three days of food (`wants()._food_pts`, which now counts food
  already bought and on the road). Its demand (SettlementParty trader need) is that shortfall in `rules.food_trade_items` (wheat).
- **Who sells.** In every other settlement that is not short: its trader (food it carries, never food it imported) and its food
  businesses, each capped by `food_release(items)`, the REG-BUY-P1 rules read only (food above the households' claim over
  `reserve_days`; a business with a demonstrated cash shortfall up to that shortfall, at the settlement's price). Parties are
  `SettlementParty` handles with `sells_only` and `release`; no business or household buys in this round.
- **Negotiation and payment.** `RegionalMarket.plan(..., only = items)`: the seller asks its settlement's floating price
  (`ask_of` -> `SettlementParty.ask_price`); the buyer pays at most `willing` (value plus `scarcity_premium` as it runs out) from
  `spend_limit` (the trader's till above its floor and half its trading capital, the rule of `road_trade`); cheapest delivered
  offer, then the shorter trip. Unmet demand keeps its reason: no supplier, price, funds, no carriage.
- **The transaction (owner direction 2026-10-30: one transaction mechanism).** Each plan line is one call to the world's transaction
  authority (`World.transactions`, Worker A's LE-03, `docs/expansion20/TRANSACTION_AUTHORITY.md`, INT-606) through `Regions.ship_line`:
  `ship("settle_food/<buyer place>:<seq>", buyer, seller, item, qty, total, due)` takes the seller's goods into transit custody (still
  the seller's) and the buyer's price into escrow (still the buyer's), together or not at all, booked as `outside_*` lines on both
  settlements. A rejection (`no_stock`, `no_funds`, `party_unavailable`, ...) moves nothing. An id executes at most once; `food_seq`
  (saved) numbers the attempts. This layer has no transfer of its own; without a world (regions_sim, Regions-only tests) there is no
  authority and nothing is bought.
- **Transport and delivery.** The buyer's trader fetches it: one load a round (`self_capacity`: a 12-unit pack, a 60-unit handcart where
  its place keeps horses). Due day = twice the route's days, at least 1. The buyer's settlement keeps what it awaits in `transit`
  (saved); at its first step on or after the due day (`_deliver`, before its market) it asks for `deliver` (goods to its trader, marked
  `imported`; the escrow to the seller). One the authority cannot close (a party unavailable) stays awaited and open and is asked
  again daily; `food_lapse_days` late it is `fail`ed (goods back, price refunded) when both parties can take them. A shipment found
  closed otherwise is dropped once (a failed one is written as never arrived). Imported food is for the place's own households:
  `trader_has`, `sell_to_village` and the trader's `sale_cap` leave it out until the place no longer wants food (`release_imported`).
- **Books.** The shipment's sides are outside lines on each settlement (its audit balances); a count of the whole region adds the
  settlements' part of `in_transit()` (`Regions.tx_in_transit`: custody and escrow) as a holder, the LE-03 ledger rule; the village's
  currency check and `economy_sim`'s regional checks need nothing extra (the two outside lines cancel against each other once
  delivered, and while in transit the seller's goods and the buyer's coins are booked out on both sides). `Regions.audit` also fails on an orphan (an open `settle_food/` shipment no
  settlement awaits, or an awaited one that is not open). Goods lost in transit (`lose`, `transactions.sunk`) are not used by this
  trade (E22-OD-04: route danger is a future stage).
- **Records.** Flow counts `food_bought`, `food_sold`, `food_delivered`, `food_unmet`; journal lines in both settlements; flight
  recorder events (INT-622). Interactions INT-620 to INT-622; tests `game/tests/settle_food_test.gd`.
- **Saves.** Optional keys only: a settlement's `transit`, a trader's `imported`, the four flow counts, `Regions.food_seq`; the
  authority's own `transactions` key (Worker A). An older save loads with nothing on the road.
- **Limits (provisional, agent).** Only wheat is traded between settlements (the staple every place grows; other foods still reach
  households through local markets and the caravan). One load a round. Households and councils do not travel to buy food themselves
  in this stage. No route loss or danger (E22-OD-04 future stage).

## 5. The plough horse

The horse comes from a horse-dealer among the traders on the road that day: Wulstead and Higham keep horses (3 and 2 at the start; they
feed them, and breed from a pair every 45 days up to six, GAME EXPANSION). The nearest dealer with a horse sells it. If none of
today's traders has one, the horse is not for sale that day. (Decision recorded in `docs/DECISIONS.md`.)

## 5a. Luxuries (DVW-B3-LUX)

Owner answer 2026-10-23 (`docs/directives/2026-10-23_owner_answers_coin_sinks.md`): "luxury imports, costly caravan goods (spices, fine cloth, jewellery)
bought for status, the coins leaving with the caravan". The two richest markets hold them in their traders' stock: Wulstead (a market town) and
Higham-on-the-Way (the abbey town with "no better market betwixt this and Babylon", CANON, `BONE-C3-P031`). CANON basis for the goods: the chapman's
booth "full within of many wares and far-fetched and dear-bought things; as pieces of good and fine cloth plumbed with the seal of the greatest of the
cities; and silk of Babylon, and spices of the hot burning islands, and wonders of the silversmith's and the goldsmith's fashioning" (`BTWO-C14-P002`).
**GAME EXPANSION**: that these two places hold them, the quantities (Wulstead 12 spices, 8 fine cloth, 3 jewellery; Higham 20, 12, 8), that they come from
beyond the map and are neither made nor restocked (a finite supply, WDR-022), and every price and rule. The mechanics (who buys, from what money, where
the coins go) are in `docs/DECISIONS.md` and INT-250 to INT-252.

## 6. Not chosen, and why

- **Upmeads**: a petty kingdom with no city, castle or abbey (`BONE-C3-P003` "none who were not friends to King Peter and his sons"); its villages are unnamed (a gap, `D_POLITICAL_ATLAS.md` 3.1). Our village is, in effect, in that country.
- **Mileham and Milton**: named only as two more thorps at the Down-foot (`BFOUR-C22-P011` "it may be at Mileham, it may be at Milton"); the text says nothing else of them, so they are left as room for later settlements.
- **Hampton under Scaur, the Burg, Abundance, Whitwall, Swevenham**: beyond the Wood Perilous or the Downs (days, not a ride), in the Burg's and the Dry Tree's war in the first era, or far to the east. They suit later travel, not neighbours the caravan reaches every few days.
- **Apthorp**: debateable ground between the Burg and the Dry Tree.

## 6a. Anyone may buy from another settlement (REG-PARTY-01)

Each settlement's trader, businesses, treasury and households are trading parties (`SettlementParty`, `DESIGN.md` section 12a) that
the regional market and the couriers address as `region:<settlement>/<holder>`; they move the settlement's own coins and goods and
leave flow lines its audit checks. Nothing calls the market from the daily loop yet. The couriers are live (REG-COURIER-01): each
settlement's booth is kept by its trader party, regular routes run from the village to each (days from the settlement's miles), and a
villager who really dealt with the trader may send goods to it (`DESIGN.md` section 11a).

## 6b. People move between the village and the settlements (MIGRATE-18)

Owner Q18-7, "Both ways, for reasons": villagers leave and outsiders arrive for work, land, marriage or hunger, taking their purses and
goods; no new population mechanic and no change to any demographic rate (REG-DEMO-D1). `Migration` (`game/scripts/core/settlement/migration.gd`)
runs on the caravan's visit day, first thing in `NPCBrain.caravan`, for each settlement whose trader is on the road (so the nearer places see
more traffic and the road itself is not walked: a move is immediate on the day, provisional). For each settlement it tries each reason in
both directions, at most one move (a person, a couple or a household) per reason, direction and settlement per visit, a pace and not a cap.

| Reason | Villager leaves when | Outsider arrives when |
|---|---|---|
| Hunger | the household has under `relief_trigger_days` of food while the village is in famine (its own relief cannot cover it), and a settlement's food businesses hold food above their own claim | the settlement household is hungry and cannot buy a day's food, the village is out of famine with more than `reserve_days` of food in hand, and there is a home to lease or a room to share |
| Work | an adult without a trade, in a household that cannot live on its income, finds no place open in the labour market, and a settlement business paid its workers at least `switch_to_at_least` a day last week | an adult of a settlement household that earned under `switch_below` a day for a week takes a village post nobody could fill (a succession vacancy past `succession_days` with no apprentice: a real migrant now fills it before a newcomer is made), else an open tool-free place that pays more than their household earned |
| Land | the household's housing goal ("no home", or "crowded" with a grown member who would found a household) has waited on coins for `mobility_unsustainable_days`; a settlement whose land yields food above its claim takes them in (the off-map has no houses) | a settlement household formed by a marriage there can pay for a house on the manor's market by the village's rule (buy, else two weeks' rent) |
| Marriage | a grown, unpartnered, willing woman meets a settlement man within the village's partnering ages and gap, and they have known each other `marry_min_days` (the pair meets at each caravan) | the same, a settlement woman and a village man whose house has a bed |

A traveller keeps name, age, sex and skills; a settlement-born member gets a name drawn reproducibly from the settlement, day and sex, and
the skills of the village's own starting rule (`Skills.start_xp`, PAR-01A) for their household's trade. The purse and the pack travel with
them (and a whole household's pantry). Villagers who cannot go: the reeve, the sage, guards, clergy, tailor and barber,
anyone tied to the player, the founding households. Market traders may go like anyone (REG-X20-D1, owner 2026-10-27, free migration;
the stock in their own pack goes with them), and no settlement household is kept back because its business has no other (the old
sole-worker and last-household rules are removed); an idle business closes by `_close_idle`. The villager who leaves is kept in the village's people as no longer
alive with `away` set; their post and stall are handed on as after a death. Coins and goods cross exactly like the couriers' (INT-280): the
village's `coin_sources`, `caravan_coins_in/out`, `exported_/imported_`, the settlement's `outside_*` flow lines, and people are counted on
both sides (`Regions.move_counts` against the settlements' `migrants_in/out`). The settlement writes each move into its own journal,
beside its tax announcements (DVW-B5: each settlement now uses the village's banded, announced tax rule, INT-313). INT-310 to INT-312.

## 6c. Settlements grow, shrink and specialize (SET-D; owner B18-DP-05)

Owner B18-DP-05: settlements grow, decline and specialize through the same economic and demographic rules as the village, at off-map
detail; no population cap, no new off-map housing inventory, demographic rates unchanged (REG-DEMO-D1). Population and employment already
follow the daily rules (births, deaths, marriages, hunger, `_move_jobs`); a business's output is its living workers' share (`_produce`).
SET-D adds the two things that were missing, once a week, after the job moves (`OffMapSettlement._develop`, INT-380 and INT-381):

- **A trade opens.** A trade the settlement lacks (a workshop made from the village's recipes, or a field, flock, wood or quarry that
  closed earlier) opens when the goods it would sell went unmet (units wanted and not found for sale, at the market price) worth at least
  `switch_to_at_least` a day in each of two weeks running (`switch_stay_days / switch_every_days`), and a household that has stayed in its
  trade `switch_stay_days`, whose business keeps another household, earning under half that a day, has savings above its keep-cash
  of at least the new business's working reserve. The household takes up the trade and its savings become the till. One a week. A
  workshop opens only if the settlement has or makes an input of one of its recipes (the natural-resource constraint); a trade made
  from what the land gives opens only where it was before.
- **A business closes.** One with no living worker household for two weekly looks (`switch_stay_days`) closes, except the traders. Its
  till goes to the treasury; its stock is bought by the traders at market price as far as their till above its reserve reaches and the
  rest goes into the treasury's granary (the rule for a household with no kin). The place (horses, quarry reserve, its fields) is kept
  and a household may open it again.

No new numbers: every threshold above is an existing `settlements.json` rule. Provisional (agent decisions): what counts as "unmet demand"
(the settlement's own `flows.unmet` record, which counts every failed purchase attempt, so it overstates a day's real shortfall); that
the founding household brings its whole surplus; that closing hands stock to the traders. Not done: new natural-output businesses (the
off-map has no land model), more than one new business a week, and any housing limit.

Verification (365 days): a 365-day run is one year of simulation. Under the 8-day calendar year it is about 45 game years for the settlements'
ages and births, so people are born, grow up, marry and have children of their own in it, but it is not labelled multi-generation
verification here. `regions_sim.gd --report` prints the facts (people present at the start still alive, births by couple-generation,
openings and closings by trade and day); the numbers are in the DECISIONS.md row.

## 7. What is not done yet

A settlement has no houses, so "land" draws a village household out only when it has waited for a home, and draws a settlement household in
only after it has married there and can pay for a house. A settlement member's experience (hours worked) is not tracked, so it does not
travel; the skills do. Visiting a settlement in person is Build 20 or later.

Barter and credit between the village and these settlements (TRADE-CREDIT), shops' own courier booths (Q18-15) and visiting a settlement
in person (Build 20 or later, Q18-8) are separate registers; the seams for them are named in `docs/expansion18/DESIGN.md` section 10.
