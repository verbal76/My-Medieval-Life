# Regional world reconstruction (B25R1-018)

Owner directive `docs/directives/2026-11-03_b25r1_regional_world_reconstruction.md` (register B25R1-018). It is
governed by B25R1-015 (the full scope, nothing deferred), B25R1-Q5 (saved games), B25R1-Q6 and Q7 (presence) and B25R1-019
(the shared presence system). The owner's intent: "I want to walk out of my village and feel as though I'm entering a real
medieval world."

The layout data is `game/data/region_layout.json` (`mml-region-layout/1`). This document gives its reasons. Labels follow
`docs/world/` and CLAUDE.md section 4:

- **A / CANON**: stated by Morris, with a paragraph id in `research/corpus/paragraphs.json` and a short verbatim quote.
- **B / CANON-INFERRED**: our reading of what Morris states.
- **C / GAME EXPANSION**: ours and never Morris's.

Every position in the file is an agent design and provisional. The relationships the positions satisfy are what the
classification below protects.

The work is split between workers:

| Worker | Owns |
|---|---|
| Region worker (`wip/b25r1-region`) | Geography, layout, sites, streets, the founding population and the out-of-view economy rules |
| Water worker (`wip/b25r1-water`) | Water courses, crossings as structures, `is_water` |
| Presence worker (`wip/b25r1-presence`) | The live and calculated transitions |

## (a) Classification of places, features, distances and crossings

### Places

| Item | Class | Evidence (paragraph id, quote) | How the game uses it |
|---|---|---|---|
| Upmeads, a petty kingdom of meadows, with no city, castle or abbey | A | BONE-C1-P004; BONE-C1-P009 "very fair meadows at the end of the upland tillage" | The player's village stands in the Upmeads country (J-D2, section b) |
| The player's village | C | none | A game-original village in the Upmeads meadows on the north side of the Water, as the High House lies "in an ingle of the river" (BONE-C1-P009) |
| Wulstead is south of Upmeads, on the high road | A | BONE-C3-P004 "a good cheaping-town hight Wulstead" | 20 road miles south of the village |
| Wulstead's market-place, fountain and buttercross | A | BONE-C3-P005 "maids gathered about the fountain amidst the market-place, and two or three dames sitting under the buttercross" | Market square with a fountain and a cross (phase 3) |
| Wulstead on a little hill amid plain meadows | A | BFOUR-C25-P003 (gazetteer) | The site sits on a rise |
| House of Black Canons at the west of Wulstead | A | BFOUR-C25-P010, BFOUR-C26-P004 | Landmark `wulstead_canons` at the west edge |
| Netherton: a thorp beside a stream, a fair church, a little house of Canons, at the Downs' foot | A | BONE-C4-P002 "a little thorp beside a stream, and thereby a fair church and a little house of Canons"; "Just before the slopes began to rise" | Site with a church and the canons' house; the stream passes beside it |
| Bear Hill above Netherton; its chalk figures on a westward bent, unseen from Netherton but clear from nearer Wulstead | A | BONE-C4-P005 "the bent looked westward down into the hollow of the hill" | Hill at (90,450) (its top raised, generation 5), figures on its west face (22,470) |
| Wulstead lies west of the Netherton to Bear Hill line | B | Reading of BONE-C4-P005 | A westward bent can only be seen from the west: Wulstead is at x -60, Bear Hill at x 90 |
| Bear Castle, an earthwork of the ancient folk on Bear Hill's top | A | BONE-C4-P005 "At the top of it was an earth-work of the ancient folk, which also was called Bear Castle" | Ringed earthwork landmark |
| The Downs: downs on downs, no road to call a road, no castle, church or homestead, waterless | A | BONE-C3-P037 "nought but downs on downs with never a road to call a road ... for otherwise the place is waterless"; BONE-C4-P006 "no trees thereon, nor houses" | Polygon region: open chalk ground, almost no trees, no springs, no settlement |
| The Greenway, a green road over the Downs | A | BONE-C4-P006 "a green road that went waving up and down"; BONE-C4-P023 "the Greenway" | Route of the `ancient` type, Bear Castle to Higham |
| Seven grave-mounds in a row on a low hill the road tops | A | BONE-C4-P009 "seven grave-mounds of the ancient folk in a row" | Landmark on the Greenway |
| "Little less than twenty" miles to Higham, some two miles past the mounds | A | BONE-C4-P010, P011 | Mounds at y 522; drovers' bent at y 548, 18 miles from Higham |
| Saint Ann's Chapel | A (name) / B (position) | BFOUR-C22-P009 "anigh to Saint Ann's Chapel"; BONE-C3-P037 "a little chapel thereby in some swelly of the chalk, where the water hath trickled into a pool" | A chapel in a chalk hollow with the only pool on the Downs. Identifying it with Clement's hermit chapel is our reading |
| Mileham, Milton, Garton: "the thorps at the feet of the downs toward Higham" | A (names, foot of the downs) / B (order, positions) | BFOUR-C22-P011 "it may be at Mileham, it may be at Milton, it may be at Garton" | Three thorps along the south foot: Mileham to the west, Garton in the middle, Milton to the east |
| Garton under the first hill of the Down country, on the road from Higham; its street cross; the barn on the western outskirt | A | BFOUR-C21-P017 "a little thorp under the hanging of the hill"; "by the cross a big fire"; BFOUR-C21-P021 (barn) | Site at the south foot, with a cross in the street and a barn at the west |
| Garton to Bear Castle: sunrise to two hours before noon, across country, shorter than the Greenway | A | BFOUR-C23-P003, P010 | Garton road (dirt): about 22 miles |
| Higham: walled, with a castle and a rich abbey; the best market; below the Downs' end in the fertile plain; Coldlake | A | BONE-C3-P031, P037, P038; BONE-C5-P002 | Walled town site (phase 3) |
| Higham's white castle on a knoll, three church towers and the Abbey church | A | BONE-C5-P002 "overlooked by a white castle on a knoll ... three towers of churches ... the Abbey Church" | Landmarks inside the walls |
| South gate, faubourg with gardens and orchards, meadows along the water | A | BONE-C6-P029; BONE-C7-P003 | Gate at (20,797), faubourg south of it |
| The road south crosses the river thrice: a stone bridge and two fords; the road is straight and the river winds | A | BONE-C7-P003 "once by a goodly stone bridge and twice by fords; for the road was straight, and the river wound about much" | Coldlake crosses x = 20 at y 830 (bridge), 855 and 885 (fords) |
| The vine country: little hills and dales, vineyards and orchards on the slopes, corn in the dales | A | BONE-C7-P004 | Region polygon south of the meadows |
| Bourton Abbas: grey stone houses in a valley of wild-wood; the tavern of the Nicholas; a vineyard; the Abbey's outermost land | A | BONE-C7-P007, P009 | Site in a wooded vale, with the tavern and the vineyard |
| The waste beyond Bourton: rough, dry and parched, the road straight through it | A | BONE-C8-P002 | Region polygon `dry_waste` |
| The Wood Perilous: a long ridge with a thick wood, at first all beech, with a beaten way through | A | BONE-C8-P002; BONE-C7-P012 | Region polygon: dense beech, no settlements, no supernatural mechanics |
| The eight hamlets (section d) | C | none | Game-original names and places |

### Waters and crossings

| Item | Class | Evidence (paragraph id, quote) | How the game uses it |
|---|---|---|---|
| Upmeads Water winds from west to east, with a low ridge along its south side and higher hills beyond running east and west | A | BONE-C1-P009 "a low ridge which ran along the water, as it wound along from west to east" | River `upmeads_water`; regions `southern_ridge` |
| The Ford in the ingle by the High House, with a willow copse | A | BONE-C3-P002 | The Ford on the village's road south (40,129) |
| The high road crosses the Water by "a fair bridge late builded", with a house of Canons on the north side | A | BONE-C3-P004 | Stone bridge (-170,128); the canons' house is a landmark |
| The Netherton stream: rises at the scarp foot and flows north-east to Upmeads Water | A (stream) / C (course) | BONE-C4-P002 | Order-1 stream |
| Coldlake winds about Higham's meadows and laps the town | A | BONE-C3-P038 "a little river hight Coldlake windeth about the meadows"; BONE-C5-P002 "a river lapping it about" | Loops round Higham, then crosses the south road three times |

### Distances

| Item | Class | Evidence | How the game uses it |
|---|---|---|---|
| Wulstead to Higham is "a matter of forty miles" | A | BONE-C3-P037 | 40.6 miles straight between the anchors |
| Upmeads to Wulstead "short was the road" (an afternoon's ride for old folk) | A | BFOUR-C30-P010 | 22 miles as the crow flies; about 24 by road |
| Higham to Bourton: one morning's ride | B | BONE-C7-P007 "So he rode till it was noon" | 15 miles |
| Every other distance | C | none | Ours |

## (b) J-D2 and J-G1

**J-D2, the starting county: the Upmeads country.** It is the only place in the novel described as a home country of meadows
and yeomen (BONE-C1-P004, P009). It is where the journey south begins, and the option keeps every canonical neighbour where
Morris put it. The options in `G_STARTING_COUNTY_CANDIDATES.md` that sit west of the Wood Perilous or on the Whitwall plain
would put the village beyond the five settlements, which the game already treats as its neighbours. The game's village is
not the High House: it is a game-original village in the Upmeads meadows, which Morris's text allows (J-D5: original places
are allowed where they do not change a named polity's character, and a village of yeomen is Upmeads' character).

**J-G1, the scale: S3 hybrid, keeping 12 tiles a mile between places, at building scale inside places.**

| Measure | Value at 12 tiles a mile |
|---|---|
| Walking (2.6 tiles per real second, 2 game minutes per second) | 1 mile = 4.6 s real = 9.2 game minutes, about twice real walking pace |
| Village to Wulstead (about 270 tiles of road) | about 1 3/4 real minutes, 3.5 game hours |
| Wulstead to Higham (about 520 tiles of road) | about 3.3 real minutes, 6.7 game hours |
| Village to Higham | about 5 real minutes, a game day's journey |
| World dimensions | the region spans x -700..720 and y -60..1260 (the Wood Perilous's spurs reach about 1296, generation 7): about 1400 x 1300 tiles, 118 x 108 miles |
| Settlement sizes | the village is 120 x 90 tiles. Higham's walls (90 x 62 tiles) would be 7.5 miles across at true scale, so places are at building scale (one tile is about a stride) |

The game's travel times are the novel's ride times compressed into playable minutes, as S3 intends. The overworld is
generated in 32-tile chunks on demand, so the cost depends on what is seen, not on the world's size.

Why the scale stays:
- Doubling the scale (24 tiles a mile) doubles every journey (10 real minutes to Higham on foot) for no gain in believability.
- Halving it (6 tiles a mile) would put Higham's walls (90 tiles) wider than a quarter of the forty miles to Wulstead, and
  the Downs would be crossed in a minute.
- Changing the constant would change every route time, caravan rhythm and regional trade in settlements.json.

The scale is **unchanged**.

## (c) The regional layout

The six principal places keep their order and the forty miles, but leave the 70-tile strip:

| Place | Anchor (x, y) |
|---|---|
| Village | (60, 45) |
| Wulstead | (-60, 285) |
| Netherton | (40, 400) |
| Garton | (-110, 700) |
| Higham | (20, 765) |
| Bourton Abbas | (90, 946) (935 until the 2026-11-04 repair: moved 11 tiles south, clear of Higham's ground) |

The canonical thorps Mileham (-210, 712) and Milton (195, 700; 150 until the 2026-11-04 repair, when its ground lay on
Higham's and its houses there stood unbuilt) are added, and the eight hamlets are spread 240-330 tiles
(20-28 miles) to the east and west.

The settlements' `miles` in settlements.json become the road distance in miles from the village (section g).

Main route:
- Village south gate, over the Ford, south-west across the meadows and over the low ridge, to join the high road from the
  fair bridge.
- South to Wulstead on its hill.
- South-east across the plain to Netherton.
- Up the white road winding round Bear Hill to Bear Castle.
- The Greenway waving south-south-west over the Downs, by the seven mounds and the drovers' bent, down to Higham's north gate.
- Higham's south gate, straight over the bridge and two fords, among the vine hills to Bourton. **This straight
  causeway is canon and must stay straight** (BONE-C7-P003: "once by a goodly stone bridge and twice by fords; for the
  road was straight, and the river wound about much"). Beyond it the road bends east among the vine hills.
- Straight through the waste into the Wood Perilous.

Side roads join the hamlets and the Mileham-Garton-Milton road along the south foot.

Repair of 2026-11-04 (B25R1 Revision 1 coordinator): every settlement's ground is impassable to the roads laid round and
between them. (1) No two sites' grounds overlap (overworld_test checks it; the three anchors above moved). (2) A hamlet's
side road is laid once every site the main routes reach is joined, and takes the nearest route node whose way (from any of
the hamlet's four sides, through its bent points), widened by the road's wobble, keeps off every settlement's ground; failing
that, a way round one settlement's corner (Overworld._side_road). (3) A ring road round a site is laid in stretches of at most
40 tiles, and only where none of its cells would lie on a neighbour's ground (Overworld._site_ring). (4) No country trail
leaves from a layout crossing's own point (the bridge's end): the fair bridge's trail on seed 1 ran along the bank beside the
land road. (5) Paving's busy count is over the pairs of the village and the towns (RegionRoads.busy_cells): over all 120 pairs
of Revision 1's places almost every main road was busy, and 4883 of 9368 main road cells were stone. There is also the Garton road over
the Downs to Bear Castle. `routes` in the layout gives control points; RegionRoads routes between them along terrain, and
roads keep their three types: main (maintained), dirt and ancient (the Greenway), with trails by wear.

The Downs: a polygon from y about 400 (the north foot by Netherton) to y about 695 (the south foot by Garton). That is
24 miles north to south, x -470..470. It has no springs: the water generator suppresses them; the chalk pool by Saint
Ann's Chapel is the only water. Ground and trees: open down-turf with very few trees.

Water anchors are listed in the layout's `rivers` and `crossings`. The water worker traces the courses through these points,
with its own meander and downhill logic.

## (d) Hamlets

**The count: eight game-original hamlets**, plus the canonical thorps Mileham and Milton as thorps of the same size. This
is ten small places, of 5-6 households each.

### Usable area

| Area | Extent | Hamlets |
|---|---|---|
| The plain north of the Downs | about 1060 x 230 tiles (88 x 19 miles), minus Wulstead, Netherton and the village | 5 |
| The plain and vine country south of the Downs | about 940 x 200 tiles | 3, plus Mileham and Milton |

The Downs, the waste and the Wood Perilous get no hamlet, by canon.

### Travel

Every hamlet is within 3-6 miles (about 20-55 game minutes, 0.5-1 real minute) of a main road. That puts a place in
view-reaching distance of a side turning every few minutes of travel, without continuous development.

### Population budget

Ten small places of 5.5 households and about 3.6 people each add about 200 people (the settlements' founding average is
3.6 people a household). Measured cost in calculated mode: 34 us per member per game day, so 200 people cost 7 ms per game
day, which is negligible. The live cost arises only near the player (section e).

### Measured alternatives

| Small places | People | Calculated cost per game day | Spacing |
|---|---|---|---|
| 6 | 120 | 4 ms | sparse: long empty roads east and west |
| **10 (chosen)** | 200 | 7 ms | one place every 15-25 miles of the side roads |
| 16 | 320 | 11 ms | close to continuous development in the plain; each new trade seller dilutes the five settlements' markets |

### Economy

Each hamlet has one or two businesses its land supports:

| Hamlet | Position | Businesses | Water |
|---|---|---|---|
| Rushford | (-330, 128) | farm, weaver | Upmeads Water |
| Ashcombe | (330, 40) | forest, sawyer | a well |
| Fallowley | (-250, 300) | farm, cook (alehouse) | a well |
| Wendholt | (180, 262) | farm, smith | the Netherton stream |
| Ewedean | (-260, 385) | herd, tanner | a well |
| Brookhurst | (-208, 797) (-190, 758 until the 2026-11-04 repair: its ground lay on Mileham's and Garton's) | farm, healer | Coldlake |
| Elmcote | (220, 790) | farm, mason | a well |
| Cressbrook | (185, 915) | farm, cook (tavern) | a well |

A hamlet has no trader of its own. Its people buy and sell at the nearest principal settlement's market through the
existing regional trade, so it adds no caravan to the village's rotation.

### Names

The names are restrained English landscape compounds: ford, combe, ley, holt, dean, hurst, cote, brook. All eight were
checked against the corpus, the gazetteer and the game's data, with no collisions. All are GAME EXPANSION.

## (e) Population architecture (owner B25R1-Q6, B25R1-Q7, B25R1-019)

### Measured on this machine

`game/tests/region_pop_probe.gd`; Xeon 2.1 GHz, 4 cores; seed 1, one game day, steps of 0.5 s, as economy_sim runs.

| Measure | Value |
|---|---|
| Village villagers | 111, at 8.5 ms per game minute (77 us per NPC per game minute) |
| Their dawn decisions | 4.0 s per day (36 ms per NPC) |
| Wall time | 17.9 s per game day headless |
| Static memory | 31 MB for the world |
| Off-map settlement members | 282, at 9.6 ms per game day (34 us per member per day) |

A full NPC costs about 150 ms per game day and a calculated member 0.034 ms: a ratio of about 4,500 to 1.

### Projections

**Full NPCs everywhere** (village plus five settlements plus ten small places, about 590 people):
- about 45 ms per 0.5 s step here;
- 150-180 ms on a mid-range phone, at 3-4 times slower: a third of a core all the time;
- a dawn spike of about 21 s here, over a minute on a phone;
- the 365-day sim gate would run about 9 hours a seed.

**Chosen** (owner Q6, Q7): residents are persistent people in the existing population system, calculated by
`OffMapSettlement` and `Regions` out of view, and made live by the presence system (`wip/b25r1-presence`) inside the
player's view plus its margin.

### One person, one record

The person is the `World.people` id (ID-01), which every off-map member already carries at `mem[i][5]`. Their household
(`hh`), purse, pantry, trade (household `trade`) and business (`biz`, the households' shared till and stock) are their
books in both modes. The region worker adds what a live person needs and the presence system reads:
- **home**: a site building of the household;
- **work**: the business's building, or a field or yard;
- **market**: the settlement's market square;
- **schedule**: the same work hours as SettlementFolk, 7 to 18.

These are derived from the household id and the site layout, so nothing extra is saved.

### Live cost of a materialised Higham

99 founding people would cost about 99 x 77 us = 7.6 ms per game minute here, the same as the village today. On a phone
that is about 25-30 ms per 0.5 s. That is acceptable, because the village and the other places are calculated while the
player is in Higham. This is to be measured once, with the presence worker, when its API lands (coordinated through the
lead, so it is not measured twice).

### What each option does

**Determinism.** Calculated mode is a pure function of the seed and the day, as today. Watching changes nothing only if
the live mode's books agree with calculation; the presence worker owns that comparison test (B25R1-Q6 item 4).

**Saves.** Calculated mode saves as `OffMapSettlement` already does. Live state folds back into the record before a save.

**Economy.** Unchanged rules; the founding books grow by the hamlets (section f).

## (f) The initial population model

At the founding of a new world, each settlement and hamlet is set up from settlements.json, as the five are today
(`OffMapSettlement` setup). Its opening books are the world's founding endowment:
- households from `trades` (members, ages, sexes, pairs);
- purses in `household_coins`;
- tills;
- the treasury's coins;
- goods.

They are recorded in `start` and counted in `Regions` totals. They are part of the world as created, not wealth created
during play. Conservation is measured from the founding (`Regions.audit`, economy_sim's ledgers), so nothing may enter
afterwards except by the existing flows.

A hamlet's government is a single elder household, with no treasury officials: its toll and tax go to its parent
settlement's treasury, the lord of the land:

| Lord | Hamlets |
|---|---|
| The Abbot (Higham) | Brookhurst, Elmcote, Cressbrook, Mileham, Milton |
| Wulstead's council | Fallowley, Wendholt, Ewedean |
| None (Upmeads has no lord's officials in the game) | Rushford, Ashcombe; the village's manor taxes nothing outside the village, so no tax |

After the founding, the existing rules apply unchanged:
- births to couples, deaths by the mortality curve, coming of age at 16, marriage from 18 and new households (REG-DEMO-01);
- migration between places (MIGRATE-18) and the homestead worker's household formation in the wild.

The founding and later changes are reported separately (founding counts in `start`; births, deaths and moves in
`move_counts` and the flight recorder).

## (g) Save compatibility (owner B25R1-Q5)

The owner: "Don't worry about saved games." New worlds get the new geography as overworld **GEN_VERSION 4**, the one
bump shared with the water worker.

A save from older code (generation 3 or below, or one whose settlements do not match this file's) is **refused with a clear
message, and the file is kept** (CLAUDE.md section 7: never silently reinterpret). There is no migration. Determinism holds:
same seed and version give the same world, and save and load round trips in the new code are exact.

## (h) Ownership and interfaces with the water worker

**Region worker**
- `game/data/region_layout.json`: its format and anchors.
- `Overworld._setup_sites` and the site helpers.
- The site and gate road links.
- `RegionGeo` (`game/scripts/core/region_geo.gd`: `region_at(cell)` and the landmarks), with small calls into it from
  `_generate`, covering ground and tree density.
- The Landmarks entries.
- settlements.json: the new places and the layout positions.

**Water worker**
- Every water field and course.
- `is_water` and `nearest_water`.
- Bridges and fords as structures.
- Pathing over water.
- Its own calls in `_generate`.

**Interface**
- The water worker READS `rivers`, `crossings` and `downs` (with `springs: "none"` and `water_ok`).
- Canonical courses with `passes_settlement` may pass inside the settlement clearance, never over a built cell.
- Hamlets without a listed course get a well, placed by the region worker as a site feature and counted by `nearest_water`.

GEN_VERSION 4 is bumped once by whoever lands first; the other rebases.

## (i) Presence, trips and the shared walking rule (owner B25R1-Q6, Q7, B25R1-019; agreed through the lead)

The presence worker (`wip/b25r1-presence`) owns the live range and the transitions. Settlement and hamlet residents use its
provider protocol:
- `w.presence.register(provider)`;
- each update, `presence_candidates()` gives `[{id, pos}]` for every member, at `trip_pos(now)` when travelling, else at the
  member's station by the hour: home, work or the market square;
- `materialise(id)` makes an NPC from the member (the same ID-01 id, name, age, sex, skills, household and job), adds it to
  `w.npcs` and marks the member `live`;
- `fold(npc)` writes the changes back into the member and removes the NPC in the same call.

Residents move between their record and `w.npcs`. They are not kept as permanent calculated NPCs: the dawn decide alone
would cost about 17 s a game dawn here for about 480 people (section e). There is exactly one live record per person at any
moment. While a member is live, the settlement's step skips their personal acts. The household's books stay the one purse,
pantry and till: the live NPC trades through `SettlementParty.deal` on them.

**Trips.** Trade between places is carried by real walkers on the route network, never by an abstract transfer (owner
clarification 2026-11-03). Each errand is one trip record on its settlement, saved:

```
{tx, who: person id, from, to, purpose: {kind: market|wholesale|food|errand}, leg: out|there|back,
 depart: game minute, pace: 1.3, pack: {item: n}, coins}
```

- The route is `Overworld.site_route(from, to)`, a pure function of the seed, so it is not saved.
- The position is `trip_pos(trip, m)`: the route indexed by `Presence.road_tiles(depart, m, pace)`. This is the shared rule:
  1.3 tiles a game minute, resting 20:00-06:00 (`Journeys.REST_FROM` and `REST_TO`), the same for every traveller on the
  road.
- On fold, `depart` is rewritten so that `road_tiles(depart, now)` equals the index reached.
- `Regions.road_trade` and the X20 food shipments become trips carried by the traders, the shipment's due date becoming
  the trip's arrival.

## (j) Site layout (phase 3) and civic art

`Overworld._site_plan` lays each settlement along east-west streets. The buildings stand on the north side of each street,
with the doors opening onto it. A north-south main street runs through the middle, where the routes come in, and the
middle street opens into a market square.

There is one building per business, a home per founding household (slot `kind: "home"`, `hh: <household id>`), and a few
spare houses for households formed later. The rows vary in length and start, and the gaps vary, as a function of the seed.

Civic art, checked through the asset pipeline:
- **Higham's walls and the castle's curtain**: from Puny World (paid) `sample-castle-1.tmj`, in the same style as the game's
  buildings.
- **Church, abbey and towers**: there are no Puny World church or tower pieces. Miniworld's `Keep` and `Chapels` are a
  different scale; using them would mean breaking the one-pixel-density rule.
  - Recommended: assemble the abbey church and towers from Puny World's modular stone-wall and slate-roof kit, as
    build_village.py assembles its workshops.
  - The alternative is a pack from the owner.

### Civic art as built (second region worker)

All of it is cut from the paid Puny World tileset by `tools/build_region_stamps.py` into `game/data/region_stamps.json`
(`stamps`, `wall`, the `white` look). The layout's `plan` places it: `civic` [{stamp, at, id}], `walls`, `castle`.

| Piece | Source in the art | Where |
|---|---|---|
| Town walls | castle sample's Walls layer: 9-row east-west run (merlons, walkway, parapet, stone face), 5-column north-south run, the face's end column; banners from its Object layer | Higham: round the town, gates 7 wide on the main street N and S, gate towers |
| White castle | the same wall kit, its faces in the light grey brick (rows 3139-3800), a keep in slate and light stone | beyond Higham's NE corner, gate to the south |
| Abbey church, churches, towers | slate hall: the manor roof of sample village-2 (ridge N-S, any odd width and length), front in the wall kit's stone face with Shade's door and shuttered windows; a tower is a narrow hall with a tall face | Higham north band (abbey + tower, church + tower x2), Wulstead west (Black Canons), Netherton east |
| Buttercross | a small slate roof on the round-arched stone arcade (4019-4021), open beneath | Wulstead's square |
| Fountain | the round stone basin (3225/3226/3445/3446) | Wulstead's square |
| Grave-mounds | Cozy Farm's 3 x 3 rough-turf patch, walked over | seven in a row on the Greenway's low hill |
| Chalk figures, Bear Castle | chalk cut into the turf by the chunk generator (`_marks`): the figure from its rows in the layout (a tree, a bear ramping either side) at scale 3; the earthwork a broken ring bank | the west bent of Bear Hill; its top |

Art gaps (no suitable art in the registered packs, or in the private packs either: rechecked 2026-11-05 by looking at Puny
World paid `punyworld-tiles.png`, Miniworld `Tombstones.png`, Forgotten Memories `Props.png`, Larchrow, Kassuii Cozy Village
`ATLAS_FREE.png`, the FL Houses demo and the craftpix dungeon objects; none has a cross, a fountain with water or a white
crenellation):
- a standing stone cross: Garton's street cross, and the cross head on Wulstead's buttercross;
- a fountain with water: Wulstead's fountain (now the dry round basin);
- a white-stone battlement: the merlons and wall-walk of Higham's white castle (now the grey kit, with light-grey faces).

Until the owner's pack arrives, the cross stays out. Its layout entry `garton_cross` keeps its place and an empty `object`, and
its Landmarks entry is withheld until it stands.
### Towns rebuilt (third region worker; owner B25R1-Q8: "Owned art and a pack I'm going to give you")

The site plan now lives in `game/scripts/core/site_plan.gd` (`Overworld._site_plan` calls it). It is still a pure function of the
seed and the settlement, in integer arithmetic only, so it is the same on every machine.
- **Streets.** The main street runs north-south and bends with an integer wave. In a town it widens into a lens-shaped
  market place. Cross streets two cells deep branch east and west, bending too, with different lengths on each side. More
  are added, alternately north and south, while buildings still need frontage, and each is cut back past its last building
  when the plan is done.
- **Frontage.** Each building takes the next place that fits on a line of frontage, nearest the middle first:
  - on the north side of a cross street, its door on the street;
  - or gable-on beside the main street, with a footpath from its door.
  The gaps vary by kind of place: terraced in Higham, a few cells in a market town, up to six cells in a hamlet. The set-back
  from the street varies too.
- **Houses** come in seven shapes, resampled from Shade's small house (`house_7` to `house_13`, the deeper `*d` ones, and the
  original with its ivy), with thatch on 35% in towns and 60% elsewhere. Towns also have manors cut whole from the village
  map. Every household still has a home and every business its building, and slot order is unchanged.
- **Yards and street furniture** are `props` on a site: drawn and solid like buildings, never entered, and listed after the
  slots:
  - fenced gardens, vegetable plots, sheds, wood piles and barrels behind the houses; haystacks, apple crates and casks from
    Larchrow;
  - wells beside the streets;
  - Larchrow market stalls round the edge of the market place, a signpost at each crossroads, and lamp posts along a town's
    main street.
- **Churches and the abbey** have light-stone fronts, lower roofs and the tower at the west end. Beside each is a fenced
  churchyard with Shade's Miniworld tombstones (`tools/region_props.py`, MapView atlas 8).
- **Higham.** The town is planned first, then the walls are drawn round it. The main street runs straight through both
  gates. Outside the south gate the road runs on, with houses straggling along it, and the Way runs east-west under the
  south wall. The castle stands beyond the north-east corner.
- **Ways in.** A site's `entries` (N, E, S, W) are where its own streets reach the site's edge, and the routes join there.

Swapping art is data, not code. A stamp in `game/data/region_stamps.json` (built by `tools/build_region_stamps.py`) names its
tiles. A new sheet goes into `MapView.EXTRA_ATLASES` and is referenced by tile id (atlas x 100000 + index).

The owner's Larchrow pack is used only for small props. Its roofs and walls are drawn straight down, not in Shade's
three-quarter view, so beside Shade's houses they read as a different game. The town houses stay Shade's.

The chalk figure and Bear Castle are now drawn as follows:
- **The figure** is a white line cut into whole turf: the dirt path autotile recoloured to chalk (region_props rows 1-2),
  joined by its four neighbours.
- **Bear Castle's ring** is a bank three cells broad of Cozy Farm's rough turf, drawn as a 9-slice, with four gaps where the
  ways went in.

#### Bear Hill and the castle knoll: raised (generation 5, `wip/b25r1-terrain`)

Built on the assessment that stood here (three rules needing exceptions); each is now handled:
- **Data.** A landmark in `region_layout.json` may carry `raised`. Bear Hill has `{"r": 22}`: a disc round Bear Castle whose
  outline wanders by up to a tile and a half with the seed (`_point` noise, integer). The white castle has
  `{"site": "higham", "slot": "castle", "margin": [1, 4, 5, 5]}`: a top round the castle slot, grown by those tiles west,
  north, east and south, with its corners rounded. The west margin is one tile so that the rim keeps clear of the town
  wall. `Overworld._setup_raised` reads both (only for `gen >= 5`).
- **Drawing.** `_generate` sets the cliff corners of the B14-07 grass/cliff wangset on every raised corner. This skips the
  clearance (`VILLAGE_CLEAR`), the pass lattice and the region rule (the Downs have no ranges), and it covers roads too.
  The top is open turf. Raised tops get none of the mountains' pines, boulders or snow; the ring bank and the figure stay
  path overlays.
- **The way up.** A road cell that falls on a raised rim becomes steps cut in the rock. It is walkable and drawn with the
  B14-07 `steps_ns`/`steps_ew` tiles, running toward the top. So every road over Bear Hill (the Downs road, the Greenway,
  the Garton road and any grid road) climbs the rim by steps and runs on over the top. The knoll has three steps below the
  castle gate, in the rim's south row. All of these are `Overworld.fixed_works`, which are generated and never saved.
  `way_at` returns a player's way or a generated one; `is_solid` and `is_rim` treat both alike, and `OverworldView` draws
  both.
- **Clearance and sites.** `Overworld.raised_at(c)` names the raised ground a cell is on. A site may reach onto raised
  ground:
  - Netherton's rect reaches Bear Hill's north rim. Netherton lies under Bear Hill (BONE-C3-P037).
  - Higham's rect holds the knoll.
  
  overworld_test counts those rim cells apart from the "site is clear" rule. It checks that none stands on or against a
  building or yard.
- **The figure** moved 12 tiles west, from x 34 to 22. It is still on the hill's westward slope, now below the rim, and its
  whole turf zone is off the plateau.
- **Saves.** Cells and objects on and round both places changed, so `GEN_VERSION` is 5 and `GEN_COMPATIBLE` is `[5]`. A
  generation 4 save is refused by `World.load_dict` with its existing message, and the file is kept (owner B25R1-Q5).
- **Landmarks.** Bear Hill is now a Landmarks entry, with `object` "hill".

Limits of the existing art: the wangset's rim is one tile of low rock edge, so both places read as a raised terrace with a
rocky lip, not as a tall mound. A higher cliff face, a ramp or a white chalk scarp would need art.

## (k) The hamlets in the economy, trips and residents (settlement worker, `wip/b25r1-settle`)

**Implemented, as built** (code: `game/scripts/core/settlement/trips.gd`, `people.gd`; data: `game/data/settlements.json`
`hamlets`, `trips` and the ten entries; INT-770 to 773; DECISIONS 2026-11-04).

### Hamlets

| Place | Households (trades) | Lord | Market | Water |
|---|---|---|---|---|
| Rushford | farmer 3, herder, weaver | none | Wulstead | Upmeads Water |
| Ashcombe | forester 2, sawyer, farmer 2 | none | Wulstead | well |
| Fallowley | farmer 4, herder, cook | Wulstead | Wulstead | well |
| Wendholt | farmer 3, herder, smith | Wulstead | Wulstead | the Netherton stream |
| Ewedean | herder 3, farmer, tanner | Wulstead | Wulstead | well |
| Brookhurst | farmer 3, herder, healer | Higham | Higham | Coldlake |
| Elmcote | farmer 3, forester, mason | Higham | Higham | well |
| Cressbrook | farmer 3, herder, cook | Higham | Bourton Abbas | well |
| Mileham | farmer 3, herder 2, weaver | Higham | Garton | well |
| Milton | farmer 4, forester | Higham | Higham | well |

A hamlet is an OffMapSettlement with `hamlet` true: same households, businesses, market, food, life and migration rules; no
trader, no officials. The elder (the household of the eldest member) carries the box of tolls and tax to the lord weekly; a place
with no lord collects neither. Each household goes to market every 6 days, staggered, when it needs food its own place cannot
spare or a wish good nobody there makes. Each business carries what the market wants and buys its missing inputs.

### The initial population (section f, as built)

Founding adds the ten places' households and books to the founding endowment (`start`), as the five's. Seed 1: 52 households and
about 190 people, each with a band id of their own (hamlet_test: no duplicate, none a villager's). Births, deaths, marriages and
migration after that are the existing rules, counted apart (`move_counts`, flows).

### Trips

One record per errand (section i's shape, plus `hid`, `owner`, `sent`):
- the route is Overworld.site_route, or a straight line when there is no world;
- the position at minute m is `along(route, road_tiles(depart, m))`;
- the arrival is `arrival(depart, length)`;
- at the destination the walker deals for `errand_minutes` (60) through SettlementParty (holder `trip:<tx>`), then walks home and
  unpacks into the owner's books.

Purposes:
- **wholesale**: the old road_trade, now walked;
- **food**: the old food shipment, now walked, bought at the day's price, never dearer than planned;
- **market**: hamlet households and businesses;
- **dues**: the elder's box.

A trip whose walker dies, or whose household is gone, ends: the pack goes to the owner's books, or to the treasury when the
owner is gone too. The pack's coins and goods are counted in the settlement's coins and goods, so `audit` holds at every minute.

### Residents live and calculated

SettlementPeople is the presence provider. It is attached in Regions.bind_world and registers only when `w.presence` exists.
Candidates are refreshed every 10 game minutes for those at their stations and every call for walkers. Stations are their trade's
building door from 7 to 18 for an adult, else their household's home slot, else the gate.

The pack crosses into the village ledger on materialise and back on fold (outside lines both sides). fold rewrites `depart` with
`depart_for(now, reached)`. hamlet_test proves:
- three rounds of 121 residents materialised and folded with both ledgers balanced;
- a walker met mid-road who walks live, is folded and whose errand completes;
- a save with a live walker (World.to_dict folds first) that loads mid-trip and ends exactly as the original.

### Limits and what remains

- **Not yet live:** nobody is made live until the presence branch merges.
- **Life events while live:** a live member's old-age death waits. Any other change to their household's record (a move out,
  `release_household` or `release_person`; a loss, `_remove_member`) folds them first (`OffMapSettlement.fold_hook`), so no NPC is
  ever left without a record.
- **Carried over on fold:** health and skills, in the member's seventh entry `M_BODY` {hp, max, sk: skill -> xp, the village
  NPC's shape}. Materialise sets them and fold writes them back. They are saved, and they go with the person when they move (the
  load's `sk`). An older save without the entry loads at full health with no recorded skills. Relations live in the world's own
  records by person id, so they need nothing here.
- **Wells:** booked as the hamlet's own use (flows.used), with `add_well(..., count := false)` (wip/b25r1-homestead 5236f89); the
  village's ledger never sees them.


#### Generation 6: the B25R1 flyover repair (2026-11-05, `wip/b25r1-visual`)

The seed-1 drone flyover (`game/tests/drone_shot.gd`) and the owner's notes on it found these; each is fixed in the generator
(`Overworld.GEN_VERSION` 6; a generation 5 world is refused like the older ones, owner B25R1-Q5):
- **Water erased at settlements.** `_water_clear` kept every course `VILLAGE_CLEAR` (14) tiles off a settlement's whole
  rectangle (2 for a `passes_settlement` one), and the site rectangles are the plans' bounding boxes, so Upmeads Water lost
  about 60 tiles by Rushford, the Netherton stream its first 80 tiles and its way past Wendholt, and Coldlake almost all of
  its course through Mileham, Garton and Higham. A canonical course now keeps only off built ground (`Overworld._built`: each
  building and yard piece grown by `BUILT_CLEAR` 2, a lamp or signpost by 0, a walled town's walls), and a settlement's streets
  count as road for the water, so a street it meets is bridged and one it runs along keeps the bank. The courses that ran
  through houses are laid round them in `region_layout.json`: the Netherton stream rises at the scarp foot east of Netherton
  and passes Wendholt's west and north sides; **Coldlake** rises at the Downs' foot east of Milton, runs under Milton and down
  outside Higham's east wall, under the faubourg, and crosses the straight road south three times as the canon has it (the
  stone bridge at (20,857), heading west; fords at (20,870), heading east, and (20,895), heading west), then away south-west
  as before; the **Garton brook** (new, GAME EXPANSION) brings the water of Mileham and Garton down outside Higham's west wall
  into Coldlake below the faubourg, west of the road, so the town is lapped on both sides and the road still crosses water
  only thrice. Coldlake could not keep its 2026-11-03 line (from the west through the town's north), which the walled plan
  built over; reaching the road from the west would have meant a fourth crossing or an eastward exit into Bourton.
- **Dark green rectangles behind thatched roofs.** `tools/build_region_stamps.py` mapped every tile of a house stamp to its
  counterpart in the thatch colour block, including the house's ground layer (the village's grass), whose counterpart is the
  block's darker grass. Ground and path layers are no longer mapped (`region_stamps.json` thatch: 80 tiles to 49).
- **Higham's castle had no way to the town.** It stood beyond the walls' north-east corner, its gate facing the east wall,
  and walled Higham is entered only by its north and south gates. It now stands on its knoll above the north wall's east end
  (`SitePlan`: the first place whose knoll and way are clear, from just past the walls' east end westward), and the castle
  way runs from the steps below its gate to a street along the outside of the north wall, which joins the main street at the
  north gate. The layout's x, y for each landmark a site's plan places are now that place on seed 1 (overworld_test checks).
- **Streets ending in the grass.** A site's streets were run out to its edge on all four sides; a side no road came in by
  ended in grass (Wulstead's west and east lanes, the hamlets' north stubs, Higham's Way). `Overworld._trim_entries` takes
  those sides' cells off once the roads are laid. A cross street no building fronts is not laid, and each is cut to a few tiles past its last building, the market's
  too (`SitePlan._trim`, now also for the faubourg's streets): Higham's empty street below the faubourg, Wulstead's east lane
  (its west lane ends at the canons' churchyard).
- **Country trails ending in the grass** (owner: roads "fade into open ground"): a grid node whose other trails fell in an
  exclusion (the village, a settlement, the Downs, the waste, the Wood Perilous) was left with one trail that stopped there.
  A trail is now laid only between living nodes (`_node_alive`: a node a settlement's, gate's or main route's road reaches, or
  with two trails to living nodes, looked along three nodes); on seed 1, 21 such spurs in the flyover's area, now none.
- **Parallel roads and ring frames.** A site's ring road leg was laid even where it ran within a tile or two of a road already
  there (seed 1: Ewedean's west leg beside its main road's join, x -313 to -310, y 300-440) or alongside the canonical water.
  And every point of a ring (its corners and 40-tile stretch points) sent its own country trail to the nearest grid node: by
  Fallowley and Ewedean five trails fanned into one node at (-312,328). Now a point only on ring roads sends none and a grid
  node takes one trail, from the nearest route node (`_trail_target`).
  A ring leg beside a road is now left out (`_ring_leg_free`) while the site's ways in stay joined round the rest of the ring; when leaving
  it out would cut them apart, every leg is laid as before. The other legs keep the rectangular ring (a design of
  2026-11-04, kept): reworking them as curved bypasses is a separate change.
- **The Wood Perilous's straight edge** (owner): its polygon is a rectangle ("a long ridge with a thick wood", BONE-C8-P002;
  nothing in the text squares it). A region may carry `edge_wobble`; the wood's is 40: its edge wanders in a smooth wave (up to about 20 tiles; the waste beside it, `edge_wobble` 12)
  (`RegionGeo._wobble`, 56 tiles long, the same in every world), its extent the same on average.
- **Road legibility** (owner: roads "extremely faint"): measured, not changed. At the game's zoom (48 px a tile, drone
  `cam=48`) the dirt roads read clearly, tan against the grass; the trails are fainter but followable. In the 4 px a tile
  overview a one-tile road is a faint line: the dirt tile's mean luminance is 168 against the grass's 152 (about 1.1 : 1),
  carried by its hue, and the stone road's 155 (grey against green). An overview-only fix (a heavier line on the region map
  or flyover) is a proposal, not done here: no new art.


#### Generation 7: the Wood Perilous as a ridge, the castle way on every seed, no way along the water (2026-11-05, `wip/b25r1-wood`)

Owner decisions of 2026-11-05 on the flyover v2 (`Overworld.GEN_VERSION` 7; a generation 6 world is refused like the older
ones, owner B25R1-Q5):
- **The Wood Perilous redrawn** (owner, question 29: "a long ridge with a thick wood", replacing the rectangle; DCR-01:
  an intentional revision of the 2026-11-03 rectangle and of generation 6's wave on it, the same canon and intent). Its
  polygon in `region_layout.json` follows a ridge running west to east about 1,100 tiles south of the village: the spine bends
  (y 1080-1150), the flanks are of uneven width, with spurs running down them and coves between (100 points, a fixed hash
  jitter of a few tiles, drawn once by a script and stored, the same for every world). About the same area (about 247,000
  tiles visible against the rectangle's 248,400) and extent (x -445..555, y about 973..1306: the south flank's spurs reach a
  little past the old south edge). Its north edge lies under the waste between x -25 and 190 (the waste, earlier in the file,
  wins there), so the waste's own wandering edge is the boundary and the road south runs straight from the waste into the
  wood; east of it the ridge's edge keeps south of the country by Cressbrook, with coves; Bourton Abbas, its vale and the
  waste are untouched. `edge_wobble` is 16 now (it was 40 on the rectangle): the outline does the large shape, the wave only
  roughens it. **One way through:** the layout's road south ended at (96,1040) just inside the wood, and the way on through
  it was one of Bourton's far point's joins to the grid; with the new outline more grid nodes beyond the wood came into that
  far point's reach and three joins ran through the trees (the first v3 flyover showed them). The road south is now carried
  on through the wood to its far side ((100,1180), (104,1330); the beaten way, BONE-C8-P002), and a far point's join with
  more than `WOOD_THROUGH` (100) cells in the wood is not laid (`Overworld._wood_cells`); country trails keep out of the wood
  as before.
- **Higham's castle way on every seed.** Generation 6 placed the castle after the houses outside the walls; where they had
  taken the ground above the north wall (seeds 11, 18, 19 and 1000 of 24 tried) the castle fell back to its old place beyond
  the north-east corner with no way. `SitePlan._castle_place` now chooses and claims the castle's knoll, its way and the
  street along the north wall right after the walls, before the houses outside are placed (the knoll's slopes kept open
  while they are, then open ground again); the castle stands above the north wall with its way to the north gate on every
  seed tried (overworld_test `_test_castle_way`: seeds 1, 2, 3, 7, 11, 18, 19, 1000), at the same place as before on the
  seeds where it already had room.
- **No way along the water** (flyover v2: plank pieces on Upmeads Water's bank west of Rushford). Rushford's south far point
  (where its gate road meets the network) lay in the river, so its joins to the grid and its ring's south and west legs ran
  along the river, bridged wherever they wandered over the water. Now (`Overworld._water_run`, `LINK_WATER_RUN` 9: the most
  cells in a row on the canonical water; a crossing has a few): a site's far point on or within 4 tiles of the canonical
  water goes on down across it to the far bank (Rushford's, Milton's on Coldlake); a far point's join to the grid that would
  run along the water is not laid and the next nearest node is taken (the three nearest dry ones; with none dry, one a little
  further within 200 tiles, else the one least along it); a ring leg along the water is never laid, and a ring corner left
  with one leg by it loses that one too, back to a side's far point, so no stub ends in the water; a hamlet's side road takes
  a way that keeps off the water when it has one (`_side_dry`, each leg judged by the key it is laid with), else its way as
  before; a walled town's far point is not moved (Higham's road south keeps the layout's fords and bridge). Ring stretches
  keep the key they were judged by. On seeds 1, 2 and 11 no join, ring leg, side road or trail runs along the water now
  (seed 1: Rushford's and Milton's did; seed 2: a side road by Coldlake's second ford, whose road cells the water broke).
  Not changed (the owner: roads stay as they are): country trails, which on seed 7 run along Coldlake south of Higham for
  a stretch and by the fair bridge, and the high road at the fair bridge (a canonical crossing at a slant).
