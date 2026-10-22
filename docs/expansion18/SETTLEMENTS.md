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

## 7. What is not done yet

Migration is separate (MIGRATE-18): nobody moves in or out of a settlement by marriage here, so marriages are within one settlement,
and a settlement with few young people (Netherton) can shrink. Houses, partners from the village and elders at founding are not
modelled.

Barter and credit between the village and these settlements (TRADE-CREDIT), people moving between them (MIGRATE-18), courier booths
(COURIER) and visiting a settlement in person (Build 20 or later, Q18-8) are separate registers; the seams for them are named in
`docs/expansion18/DESIGN.md` section 10.
