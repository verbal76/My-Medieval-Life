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
| Bear Hill above Netherton; its chalk figures on a westward bent, unseen from Netherton but clear from nearer Wulstead | A | BONE-C4-P005 "the bent looked westward down into the hollow of the hill" | Hill at (90,450), figures on its west face (62,452) |
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
| World dimensions | the region spans x -700..720 and y -60..1260: about 1400 x 1300 tiles, 118 x 108 miles |
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
| Bourton Abbas | (90, 935) |

The canonical thorps Mileham (-210, 712) and Milton (150, 700) are added, and the eight hamlets are spread 240-330 tiles
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

Side roads join the hamlets and the Mileham-Garton-Milton road along the south foot. There is also the Garton road over
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
| Brookhurst | (-190, 758) | farm, healer | Coldlake |
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

Art gaps (no suitable art in the registered packs): a standing stone cross (Garton's street cross; also Wulstead's
cross head on the buttercross), a true white-stone battlement (the castle's merlons are the grey kit's), and a fountain with
water. Options: a pack from the owner, or leave the cross out as now (the Landmarks entry is withheld until it stands).
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

#### Bear Hill and the castle knoll: not raised (assessed, not started)

The overworld's raised ground is its cliff wangset: cell corners marked cliff in `_generate` form a plateau with a rocky
rim, and the top is B14-07 ground that is reached only through steps or stairs the player builds. Raising a plateau from
`region_layout.json` data (cliff corners in a disc) is easy. It is not a clean small change, because three existing rules
would each need an exception:
1. **Tops are wooded rock.** A top is covered with pines and boulders (unreachable) and draws snow variants. Bear Hill on
   the open, treeless Downs and a castle courtyard both need a bare top. Tree, boulder and snow placement would need a
   "data plateau" case.
2. **Clearance.** No cliff corner lies within `VILLAGE_CLEAR` (14 tiles) of a site, and the castle is part of Higham's
   site. A knoll under it needs a clearance exception, rim cells inside a site's rect (solidity, `site_building_at`), and
   the reachability checks (overworld_test floods every door from the village).
3. **The way up and the chalk.** A built-in ramp would have to be generated `works` (today they are player-made and saved)
   or a gap left where a road crosses the rim. Bear Castle's ring bank and the hill figure are cut with the chalk
   wangset on the same corners the cliff wangset would take: two corner sets on one cell.

What it would need: a `plateau` entry per landmark (centre, radius, way-up side); in `_generate`, cliff corners for it that
skip the clearance and road rules except on the way-up side; bare tops for data plateaus; the figure kept off the rim;
tests for reach and solidity. This is roughly a day's work for the next region worker, and the rest of the generator would
be unchanged.
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

