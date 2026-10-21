# Farm and stall audit (FARM-01, FARM-02, FARM-07, STALL-01, STALL-05)

Read-only audit of the code at `origin/staging/my-medieval-life` `1fefddb`, required by the owner before any
implementation (`docs/directives/2026-10-21_build16_owner_decision_resolution.md` sections 1-3;
`docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md`). It records what exists, with file:line evidence,
and where the code is silent. Nothing here is a decision: every "option" is for the owner, and the one
proposal (A1.4) is marked as a proposal awaiting approval. Paths are relative to `game/` unless they start with
`docs/` or `tests/`.

---

## Audit A: farmland (FARM-01, FARM-02, FARM-07)

### A1. Fences and gates: what any existing definition builds

| Definition | Where | Builds | Materials | Scales with size? | Labour |
|---|---|---|---|---|---|
| Player pen | `scripts/core/farming.gd:357-421`; numbers `data/balance.json:551-552` | A rectangular fence (`fence_cells`, every border cell, `farming.gd:369-375`) with one gate in the middle of the top side (`farming.gd:385`, `413`); fence solid except the gate (`farming.gd:424-427`) | Planks only: `ceili((border cells - 1) / fence_cells_per_plank)`, `fence_cells_per_plank` = 3 (`farming.gd:378-379`; `balance.json:552`). The gate cell is the "- 1": it costs nothing. No logs, no stone | Yes, by perimeter, but the rectangle itself is fixed per species (`farming.pens`: chicken 5x4, sheep 7x5, pig 6x5, cow 7x6, `balance.json:551`; `pen_rect`, `farming.gd:357-359`) | None: built instantly from the pack (`build_pen`, `farming.gd:407-421`); no site, no deliveries, no helpers |
| Manor pens | `data/village.json` `pens` (4 pens, 7x6, with `gate`), loaded by Fauna (`scripts/core/fauna.gd:21-22`) | Fences drawn by the village generator | None (map data) | n/a | n/a |
| Buildings (house, workshops, rooms, loft) | `scripts/core/construction.gd:24-26`, `68-75`; `balance.json:183-203` | Buildings only; no fence or gate kind | planks, stone, logs (iron bars for a smithy) | No: fixed per kind, and the footprint is fixed per kind (`construction.gd:116-117`; stamps 9x10, room 5x6 in `data/village.json` `stamps`) | Site + delivery (below) |
| Shop equipment | `balance.json:173-182`, `scripts/core/fitting.gd:36-37` | Counter, shelves, chests, stations inside a room | planks, stone, iron bars | No | Instant from the pack |
| Crafting recipes | `data/recipes.json` | No fence, gate, post or stall item exists. `saw_planks`: 1 log -> 2 planks at a sawhorse (`recipes.json:24`) | | | |

Findings:

1. **No existing recipe builds a fence and a gate from logs and stone.** The only fence rule is the player
   pen's: planks by perimeter, the gate free. Planks are made from logs (`recipes.json:24`), so the pen rule is
   "logs" only indirectly; stone appears in no fence or gate definition.
2. The pen rule's geometry already works for any rectangle (`fence_cells`, `pen_planks` take a `Rect2i`);
   only the size table (`farming.pens`) fixes it per species. Examples of the existing formula:
   5x6 = 18 border cells -> 6 planks (3 logs sawn); 9x10 = 34 cells -> 11 planks; 12x8 = 36 cells -> 12 planks.
3. A pen is a Fauna record with an animal kind, cap and trough (`farming.gd:414-417`; `fauna.gd:21`); it is
   not a farmland record, and pen cells cannot be tilled (`farming.gd:81-84`, `395-396`).
4. **Gap and smallest consistent addition (PROPOSAL, not approved, not implemented):** reuse the existing fence
   geometry and per-perimeter rule (`fence_cells`, `fence_cells_per_plank`) for a farmland fence of any
   rectangle, and add one new number for the gate (stone for its posts), since the existing rule charges nothing
   for the gate and uses no stone. Whether "logs" may be satisfied by planks sawn from logs, or must be raw logs
   at an equivalent rate (1 log = 2 planks, so 6 fence cells a log), is the owner's choice (Question 2).

### A2. Placement, clearing and labour as they work today

| Step | Code | What it does |
|---|---|---|
| Green-square ghost | `scripts/main.gd:2928-2947` (`begin_placement`), `3070-3087` (`_update_ghost`), `scripts/view/placement_ghost.gd` | Shows a footprint green or red with the reason from `Construction.can_place`; the size is the building kind's fixed footprint (`main.gd:2937`), and the bar shows the ground's price and weekly rent from `ground_terms` (`main.gd:3080-3083`). There is no variable-size mode |
| Legality | `Construction.can_place` `construction.gd:108-127` | House-first rule, exact footprint size (`116-117`), `Property.can_claim`, door step clear and reachable from the player spawn (`123-126`) |
| Claim | `Construction.place` `construction.gd:144-156` -> `Property.claim` `scripts/core/property.gd:619-642` | Surveys a new parcel, buys or leases it on the spot, then `World.start_site` |
| Clearing at claim | `property.gd:576-578`, `632-641` | A grown tree blocks the claim ("fell it first"); stumps, saplings and wild plants on the rectangle are **grubbed up free and instantly** when it is claimed |
| Clearing by farming | `farming.gd:93-163`, `705-716` | On held ground the player digs out stumps (axe, stamina), pulls up young trees, grubs up plants, mines boulders; each is a timed action |
| Bare land route today | `scripts/ui/game_ui.gd:2615`, `2621` | The player buys or leases a whole surveyed parcel from the land office (the map's two 9x10 plots, `data/village.json` `plots`, or parcels left by others); no UI claims bare ground of a chosen size |
| Site | `World.start_site` `scripts/core/world.gd:1820-1830`, `deliver` `1838-1856`, `site_progress` `1944-1958`, `cancel_site` `1963` | A site needs its materials delivered; it completes on the last load. Owner rule 2026-10-18: "materials only and no extra build time" (`world.gd:1813-1814`) |
| Labour | `Construction.hire` `construction.gd:279`, `plan_helper` `362-408`, `_make_timber` `420-442`, `act` `475-531` | Labour is carrying: the builder or hired helpers (wage `helper_wage` 6, `balance.json:202`) fetch or buy materials and deliver them; a builder may fell and saw their own timber |

Findings: the existing "normal construction" is a site plus real deliveries with no build time; a pen skips
even that. `Property.claim`'s free grubbing of stumps and plants differs from the farming actions that make
clearing a timed activity; FARM-02 requires clearing, so a farmland flow would have to choose which existing
path applies (implementation detail, no new rule needed: the farming actions already exist).

### A3. Ploughing, sowing and harvest; can it run on a leased plot?

- Per-cell farming is the player's only: every function takes a `PlayerState` (`farming.gd:167-274`,
  `682-717`). Till by hand or plough (`balance.json:533`), sow real seed (`farming.gd:221-229`), hourly growth
  (`233-247`), harvest with seed back (`262-274`). Cells are saved (`721-735`).
- **Leased ground works:** `parcel_at` accepts any parcel the player `holds`, owner or tenant
  (`farming.gd:58-62`; `World.holds` `world.gd:2749-2750`). Refused on a parcel with a site or building
  (`farming.gd:72-73`), next to a building, on roads, pens, containers (`66-88`).
- **NPC households cannot farm a plot today.** Villagers farm only the manor's six fields (`data/village.json`
  `fields`, 11x6 each) as farmers (`World.fields`, `world.gd:52`; harvest `npc_brain.gd:2125`). Nothing lets a
  villager till, sow or harvest a parcel (parity gap for FARM-01/OD-22; an implementation task, not a new rule).
- When a lease ends, nothing clears the tilled cells: `give_up_cells` runs only when a building site is marked
  out (`farming.gd:287-299`, called only at `world.gd:1823`); the cells stay saved but `parcel_at` no longer
  admits the player (`farming.gd:60`). Player pens on the ground stay the player's (`property.gd:401-407` changes
  only the parcel unit).

### A4. How the weekly lease is charged today

| Element | Code | Behaviour |
|---|---|---|
| Land price | `Property.land_price` `property.gd:178-179` | `max(1, ceil(plot_price x w x h / 90))`, `plot_price` 60 for a 9x10 plot (`balance.json:144`) |
| Rent | `Property.rent_of` `property.gd:191-192` (duplicated in `Construction.ground_terms` `construction.gd:137-139`) | `max(1, ceil(price x weekly_rent_share))`, share 0.1 (`balance.json:146`). A parcel with a house is priced at `house_price` 150 -> 15 a week (`property.gd:182-188`) |
| Lease | `Property.lease` `property.gd:345-358` | The first week's rent is paid at once (`_pay_manor`, purse -> treasury, `290-306`), then `set_tenant` stores `rent` on the record |
| Schedule | `World.set_tenant` `world.gd:2763-2773` | `due_day = today + 7`, `arrears = 0`, `missed = 0`; rent 0 erases all four fields |
| Collection | `Property.collect_rents` `property.gd:413-434`, run each morning (`world.gd:379`) | For every record with a tenant, `rent > 0` and `due_day <= today`: charges the **stored** `rent` + arrears, advances `due_day` by 7. Unpaid: `arrears = owed`, `missed += 1`; at `rent_evict_missed` = 2 (`balance.json:148`) the lease ends (`_release`, `401-407`) and arrears are let go; a building the tenant put up passes to the manor |
| Giving up | `Property.end_lease` `property.gd:385-396` | Pays arrears as far as the purse allows, then releases |
| Reserve | `World.necessity` `world.gd:698-701` | Counts rent falling due from the stored `r.rent` |

The framework does **not** distinguish an initial payment from recurring rent: the first payment is one week's
rent (`property.gd:345`). So OD-23's "initial vs recurring" distinction does not arise.

The owner's "6-coin house lease" is the rent of a bare 9x10 parcel (60 x 0.1); a house built on leased ground
keeps the rent stored at lease time (6), while leasing a parcel that already has a house costs 15
(`property.gd:182-192`).

**What a fixed 2-coin farm rent touches:** only the amount computed at lease time (`Property.lease`
`property.gd:349`, and the ghost's text from `ground_terms`, `construction.gd:137-139`, `main.gd:3080-3083`). Once
stored, `collect_rents`, arrears, eviction, `end_lease` and `World.necessity` charge whatever `rent` the record
holds, so they need no change and cannot charge twice. **Documented conflict (not resolved by changing the
price):** the size formula gives 2 coins only for areas of 16 to 30 cells (price 11-20); a 3x3 gives 1, a 6x6
gives 3, a 9x10 gives 6. A farm parcel would need its rent set to 2 instead of `rent_of`, i.e. a farm-kind rule
on the record. The parcel's `price` field (`property.gd:624`) would still follow area and is what `buy` charges.

### A5. Land-system constraints on plot size and placement

| Constraint | Code |
|---|---|
| At least 3x3 | `property.gd:549-550` |
| Inside the village, a 1-cell margin | `property.gd:551-552` |
| No overlap with any parcel (surveyed or claimed) or building record: a surveyed plot is leased whole, never cut | `property.gd:553-555` |
| Not on the manor's fields or any pen | `property.gd:556-564` |
| No stall, stall serving cell, station, container, mine seam or grown tree inside | `property.gd:565-581` |
| No road cell, no solid cell | `property.gd:582-590` |
| No maximum size; no limit on parcels per household | (absent in `can_claim`) |
| Door reachability: only for buildings | `construction.gd:123-126` |
| Farming cells: not beside a building's front row, not on road or exit cells, not on pens or containers | `farming.gd:66-88` |
| Fixed footprint in the only placement UI | `construction.gd:116-117`, `main.gd:2937` |

---

## Audit B: stalls (STALL-01, STALL-05)

### B1. Existing stall-like arrangements

| Arrangement | Where | Ground | Built from | Charge | Who sells, how |
|---|---|---|---|---|---|
| Merchants' stalls `stall0`-`stall5` | `data/village.json` `stalls` (6, y = 63); loaded `world.gd:112-117` (kind raw/food/goods by index, owner the manor) | Manor's market, no parcel | Map data, no recipe | **Rent-free**: `set_tenant(stall, npc)` with no rent (`scripts/core/population.gd:188-191`; on a job change `npc_brain.gd:3098-3102`); a vacant one is relet "Rent-free for now (provisional)" (`property.gd:521-539`; `balance.json:143`) | The merchant's own inventory and purse, sold through `World.trade` at their post (`world.gd:602-623`, `2442-2453`); no till |
| Player pitches `pitch0`, `pitch1` | `Business.PITCHES` `scripts/core/business.gd:38`, created `53-68` | Manor's, 2 cells wide, no parcel | Nothing: drawn with the merchants' awning art (`business.gd:39`) | `stall_rent_day` 5 a day (`balance.json:151`), paid at renting and each morning from purse then till (`business.gd:329-348`, `443-482`); `stall_evict_days` 2 unpaid mornings closes it (`466-469`). Larger stall: 40 coins once, 9 a day (`513-522`; `balance.json:161-162`) | The stall record's `stock`, `prices`, `till` (`business.gd:22-23`) |
| Player shop in a room | `business.gd:540-566`; counter `balance.json:174` (3 planks) | The player's building | Fitting pieces from the pack | `shop_licence_day` 4 a day (`balance.json:165`; `business.gd:255-260`) | Same record as a pitch, kept in `building.shop` |
| Storefronts (player and villager households) | `business.gd:76-193`; cost `storefront_cost` {plank 6, iron_bar 1} (`balance.json:500-501`, agent proposal, provisional) | Against the front wall of a house the household holds (`business.gd:94-115`, `122-133`) | 6 planks + 1 iron bar from the pack, instant (`137-177`) | None: "the household's own ground" (`business.gd:80-81`, `255-257`) | Player: the shop record. Villagers: the keeper moves surplus from the pantry into their own inventory and sells at the counter as a shopkeeper (`npc_brain.gd:393-414`, `434-449`); no till |

No construction recipe exists for a free-standing market stall. The only stall-like recipe is the storefront's
6 planks + 1 iron bar, the same figures the owner declined to adopt automatically, and it is tied to a house
wall. A stall's art (two awning tiles, a serving cell below) is narrower than `can_claim`'s 3x3 minimum
(`property.gd:549`), and `can_claim` refuses any rectangle containing a stall or its serving cell ("the market",
`property.gd:566-568`).

### B2. Classification against OD-24 (nothing converted)

| Location | Covered by OD-24's built-stall model? | Evidence |
|---|---|---|
| A stall a player or villager would build on cleared land | Yes: this is the model OD-24 and STALL-01 describe | Directive 2026-10-20 OD-24 "Building a stall" 1-6 |
| `stall0`-`stall5` (merchants) | Distinct, preexisting: the manor's market built into the map and let to its merchants as their workplace, kept by succession (`population.gd:188-191`, `property.gd:521-539`). Not built by anyone, on no parcel. **But** the question OD-24 answered was about exactly these stalls' rent (`docs/design/FOOD_SECURITY_AUDIT.md:353-354`), so whether the 5% applies to them is unresolved (Question 5) | |
| `pitch0`, `pitch1` (player, 5 coins a day) | Distinct, preexisting manor pitches, not built; the 2026-10-21 directive says the 5% "replaces the proposed flat pitch rent for stalls operating under the approved OD-24 model", which does not say whether these pitches become OD-24 stalls or are withdrawn (Question 5) | `business.gd:5-12`, `38` |
| Player shops (licence) | Distinct: a shop in a building, not a stall | `business.gd:25-31` |
| Storefronts | Distinct: on the household's own ground, rent-free, an agent proposal (B14) | `balance.json:501` |

### B3. Selling and settlement today (player premises)

| Question | Answer, with evidence |
|---|---|
| When is revenue recorded? | At each sale, in `Business.sell` (`business.gd:883-911`): goods leave `stock`, the buyer pays, `till += total`, `earned += total`, one line in `sales`, stats `stall_sold_<item>` and `stall_coins`. Atomic (`886-887`) |
| Unattended selling? | **Not possible**: sales run only when the player is within `stall_range` 7 tiles or a hired attendant is at the counter (`attended`, `business.gd:749-752`; `_send_buyers` `842`; `arrive` `873`). OD-24 step 5 needs this changed |
| Who buys? | Only villagers with a modelled need, their own coins above their reserve, at a price within the local ceiling (`business.gd:760-826`); at most 3 sent an hour (`balance.json:155`). These customer rules cover the player's premises only; villagers' storefronts sell through the shopkeeper path |
| How do proceeds move? | The till is coins held by the premises; `collect` moves it to the purse at any time (`business.gd:402-407`); rent and wages draw on it through `_charge` (`476-482`) |
| Session / close | No session concept. The pitch stays rented and open until `close`, which returns stock and till and gives the pitch back (`business.gd:413-437`). Selling out does not close it (`_send_buyers` just stops, `842`) and rent keeps accruing |
| Per-session total? | Not kept: `earned` is cumulative per rental; `sales` keeps the last 40 lines only (`stall_sales_log`, `balance.json:158`; `business.gd:904-905`); the till is reduced by collections, rent and wages. A 5% settlement needs its own per-session sales counter |
| Commission machinery | None. The existing coin route to the treasury is `Property._pay_manor` (purse -> treasury, all or nothing, `property.gd:290-306`), used by the pitch rent after `_charge` (`business.gd:457-458`) |
| Save and load mid-session | `World.stalls` (with `stock`, `prices`, `till`, `earned`, `paid_day`, `missed`, `costs`, `sales`) and `buildings` (with `shop`, `front`) are saved whole (`world.gd:3044`). Not saved: `Business.heading` (buyers on their way, `business.gd:44`; `arrive` re-checks everything, `870-878`) and `World.front_keepers` (`world.gd:56`; the villagers' stock is in the keeper's saved inventory). A mid-session save therefore keeps every coin and good; there is no settlement state to recover yet |
| Double settlement guard | None (nothing is settled) |
| Coin conservation | `World.total_coins` counts purses, treasury, reservations, loot and every till (`world.gd:874-888`; `Business.tills` `business.gd:915-921`); `tests/conservation_test.gd:45-52` checks start + in - out = now across save/load |
| Goods conservation | `tests/census.gd:11-46` counts every holder, including the player's premises' `stock` and `store` (`census.gd:37-40`); used by `tests/economy_sim.gd` and `tests/conservation_test.gd`. Runtime has no check; tests do |

### B4. Monetary rounding: every place money comes from a fraction

| Where | Rule | Direction |
|---|---|---|
| Land price `property.gd:179` | `max(1, ceili)` | up (manor's favour) |
| Weekly rent `property.gd:192`; `construction.gd:139` | `max(1, ceili)` | up |
| Manor buy-back `property.gd:196` | `roundi` | nearest |
| Market sell / buy prices `world.gd:804`, `810` | `max(1, roundi)` | nearest |
| Trading-skill price `world.gd:863` | `max(1, roundi)` | nearest |
| Young animal price `farming.gd:452`; seed price `farming.gd:610` | `max(1, roundi)` | nearest |
| Theft fine share `world.gd:2077` | `roundi` | nearest |
| **Household tax** `npc_brain.gd:2331` | `int((cash - exemption) x rate)` | **truncated (down, payer's favour)**; the only existing percentage levy paid to the treasury |
| Repairs budget `npc_brain.gd:2345` | `int(...)` | truncated |
| Caravan allowance `npc_brain.gd:3421`; caravan prices `3490`, `3501`, `3560`, `3651` | `roundi` | nearest |
| Stall buyer ceiling `business.gd:761`, `766` | `roundi`, then `floori` | nearest, then down |
| Site estimates and founding money `construction.gd:243`, `796`, `902`, `1101`, `1308` | `ceili` | up |
| Necessity reserve `world.gd:689-697` | `ceili` | up |

No authoritative convention exists: the code uses up, nearest and down case by case, and no decision log
records one (`docs/DECISIONS.md`, `docs/BUILD_DECISIONS.md`, `docs/WORLD_DESIGN_RULES.md` searched for
"rounding"). The nearest analogue to a 5% commission, the household tax, truncates. Godot's `roundi` rounds
halves away from zero.

### B5. What the approved behaviour needs that does not exist (implementation work, no new rule)

A built-stall record on cleared land; OPEN STALL / CLOSE STALL sessions; unattended selling; automatic close
when saleable stock is gone, with a notice; a per-session sales total; one settlement per session that moves 5%
to the treasury through real coins; an NPC stall path (villagers stocking and opening their own); the same
customer rules for player and villager stalls; save/load of an open session. The open questions below are the
points where these cannot be built from the approved rules alone.

---

## Questions for the owner

1. **Rounding of the 5% commission** (no convention applies, B4). On a session total S:
   (a) round down, as the household tax does: sessions under 20 coins pay nothing, the realm never takes more
   than 5%; (b) round to nearest, as prices do: under 10 coins pays nothing, 10-29 pays 1; (c) round up, as rent
   does: any sale pays at least 1 coin (a 1-coin session pays 100%); (d) keep the exact fraction as a saved
   remainder per stall and settle whole coins as they accrue: exactly 5% over time, one more saved field.
2. **"Logs and stone" for the farm fence and gate** (A1). The only fence rule uses planks (sawn from logs, 3
   fence cells a plank) and makes the gate free with no stone. (a) Reuse the pen rule unchanged (planks; no
   stone): no new recipe, but no stone as the directive names; (b) the pen rule for the fence plus one new number
   of stone for the gate posts (the proposal in A1.4); (c) the fence in raw logs at the sawing ratio (6 cells a
   log) plus stone for the gate; (d) a new fence/gate recipe with the owner's own quantities.
3. **A stall's construction materials** (B1). No free-standing stall recipe exists. (a) The storefront's 6 planks +
   1 iron bar (an existing, provisional agent number the owner declined to adopt automatically); (b) the shop
   counter's 3 planks (an existing fitting); (c) a new stall recipe for approval.
4. **Plot size limits under a flat 2 coins** (A4, A5). The land system has no maximum parcel size and no
   per-household limit, so at a flat rent a household could lease any amount of clear land for 2 coins a week.
   (a) No limit: need, labour and fencing materials limit size; (b) a maximum from an existing size (e.g. the 9x10
   house plot); (c) one farmland lease per household. Related: may farmland be bought outright through the
   existing buy path (priced by area, `property.gd:178-179`), or only leased?
5. **Which existing stalls OD-24 covers** (B2). (a) Merchants' `stall0`-`stall5` stay the manor's rent-free
   workplaces and the pitches keep 5 coins a day, OD-24 applying only to newly built stalls; (b) the 5% also
   applies to the merchants' stalls (their sales today are ordinary trades with no session or till) and/or
   replaces the pitches' daily rent; (c) the pitches are withdrawn once built stalls exist.
6. **Proceeds before the session closes** (B3). Today the till can be emptied at any time. If the owner of a stall
   spends the proceeds before CLOSE STALL, the commission may be unpayable, and the directive forbids new
   penalties. (a) Proceeds stay in the stall until the session is settled; (b) proceeds may be withdrawn except
   the commission's share, which stays in the till; (c) withdrawal is free and an unpaid commission is handled by
   the existing arrears rules (which would then apply to stalls).
