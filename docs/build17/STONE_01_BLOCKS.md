# STONE-01: raw quarry stone and finished building blocks (Build 17)

Register: STONE-01 (parent MIN-B). Owner decision 2026-10-21, verbatim in
`docs/directives/2026-10-21_quarry_stone_blocks_decision.md`: "Raw quarry stone and finished building blocks will be
separate inventory items. Stoneworkers must physically process raw stone into building blocks using real labor, tools,
and time. ... Quarry extraction → Raw stone → Stoneworking → Finished building blocks → Construction. No automatic
conversion or free creation of finished blocks." Branch `wip/b17-stone` (base `wip/build17` `54340fc`).

Labels: **APPROVED** (the owner's decision), **DONE** (implemented and tested here), **DECISION** (an agent decision on a
minor detail under the standing release directive, recorded here and in `balance.json` `_stone_blocks_note`),
**OWNER QUESTION** (left as it is; the owner's to decide).

## 1. The chain

| Step | Who and how | Label |
|---|---|---|
| Quarry extraction | Unchanged (MIN-B): stone seams, host rock of worked-out ore seams, boulders; the player, labourers, miners, manor quarry hands, contract sellers; one swing rule (`World.work_mine`) | APPROVED / unchanged |
| Raw stone | The item `stone` ("Stone"), value 1, unchanged | DONE |
| Stoneworking | Recipe `dress_stone`: **2 stone → 2 building blocks, 30 game minutes at a workbench, a mallet held (worn 1 a batch), Crafting level 1, 4 xp**, `exact` (no practised-hand saving and no bonus block) | DONE / DECISION (numbers) |
| Finished building blocks | New item `building_block` ("Building block"), value 3 (a stone and half an hour's labour; plank is 2 from a log of 2 for comparison), type resource, icon `Blocks/Stone-Block-02` of the 16x16 Survival RPG Icons pack (a squared grey block, apart from raw stone's rough chunk) | DONE / DECISION (value, icon) |
| Construction | Houses and every workshop and module (`house_cost`, `workshop_cost`) take `building_block` where they took `stone`, in the same numbers | DONE |

### Why these choices

- **Station: the workbench** (existing; the village's in the smithy, and every carpenter's shop and fitted room has
  one). A mason's banker is a heavy bench; adding a new station type would need art, stamps and fittings for no gain in
  play. DECISION.
- **Tool: the mallet** (existing item, tool kind `mallet`, durability 150; made by the carpenter to order for the goods
  merchant, B14-07). The brief allowed reusing a mallet/chisel-type tool; a chisel item would need a smith's recipe, an
  outlet and an icon for the same role. The recipe names the tool kind (`"tool": "mallet"`), so a chisel can be added
  later as another item of that kind or a second required tool. DECISION.
- **Skill: Crafting** (the game's hand-work skill, which already covers carpentry). No new skill: a new skill tree
  entry needs tiers, xp and wiki text and the owner has not asked for one. DECISION; see owner question 3.
- **Ratio 1:1 (2 stone → 2 blocks).** Real dressing wastes stone, but a waste ratio would double-count against the
  finite quarry (MIN-B sized the host rock at "about 17 houses at 20 stone each") and silently raise every house's stone
  draw; the owner's decision asks for labour, tools and time, which this has. The batch of two keeps the player able to
  dress small amounts and villagers from walking to the bench for every block. DECISION; see owner question 2.
- **`exact`:** Crafting 5+ `save_chance` and 7+ `bonus_chance` would otherwise give back the stone or add a block: a
  block from nothing. The recipe flag turns both off for this recipe only (`World.work_craft`). DONE.
- **Recipe keys `tool` and `exact`** are new optional keys of `mml-recipes/1` (documented in the file's note). Old data
  without them behaves as before; no format bump (no existing reader breaks). DECISION.

## 2. The same rule for the player and villagers (PAR-04)

- `World.work_craft` (the one crafting rule): refuses `"tool"` when the crafter holds no tool of the recipe's kind
  (`World.craft_tool`: the player's tool in hand or best of that kind; a villager's first in their pack), wears it 1 a
  batch, and applies `exact`. The player's refusal (`player_craft_refusal`) says "You need a mallet."; the time is the
  recipe's minutes by the skill's `craft_time`, as for every recipe.
- Villagers: `NPCBrain._can_make` and `_do_recipe` check the same tool, so contracts' craft route (`Contracts.means`)
  and every planner see the same requirement.

## 3. The villager producer: the labourer

The labourer is the village's stoneworker (`NPCBrain._mason`, run before `_miner` in the labourer's branch of
`_plan_job`). The job system has no clean slot for a new trade (population roles, the labour market, sprites, the
material checker's professions), and the labourers already quarry stone and sell it to builders
(`Construction.SELLERS.stone`). DECISION.

1. A labourer holding blocks sells them to a buyer (the raw-goods merchant, `OUTLETS.building_block`) through the
   existing sale (`_plan_sell`, `World.purchase_qty`).
2. **Demand** (`_block_demand`): a buyer takes blocks from them (the raw-goods merchant's stock for builders,
   `BUYS.merchant_raw.building_block` = 20, as it kept 40 stone), or the open building sites need more blocks than the
   labourers and raw-goods merchants hold. Without demand the labourer does nothing new (false: the day goes on as
   before). Nothing is dressed for nobody.
3. With demand: a labourer without a mallet buys one from the goods merchant or a carpenter (coins above their reserve;
   none on sale: they carry on quarrying); with two stone and a mallet they dress at a workbench they may use; short of
   stone they quarry it as before, or buy the raw-goods merchant's when no stone is left to quarry or the merchant has all
   the stone it will take (that is where the caravan's raw stone goes).
4. Labourers keep their mallet (`KEEPS.laborer`).

Builders buy blocks from the raw-goods merchants and labourers (`Construction.SELLERS.building_block`); the stall
procurement (`Business.needs`) lists blocks for open sites as it lists stone. Blocks are not exported by the caravan
(`NOT_EXPORTED`: the village's own finite stone, dressed). `tools/check_materials.py` cites `_mason` as the labourer's
crafting.

## 4. Audit of every use of `stone`

| Use | Where | Decision |
|---|---|---|
| House (20) | `balance.json` `house_cost` | **Blocks** (construction) |
| Workshops and modules: smithy 30, carpentry 15, bakehouse 30, kitchen 20, apothecary 15, storage 10, quarters 15, room 6 | `workshop_cost` | **Blocks** (construction) |
| Loft, storefront, market stall | `loft.cost`, `storefront_cost`, `stall_cost` | No stone; unchanged |
| Shop fittings: oven 6, stove 4, forge 8 | `shop_equipment` (`Fitting`, the player's rooms) | **Raw stone** (DECISION): a hearth, bread oven or forge is rubble and clay, not dressed ashlar; and a fitted piece taken up returns today's `Fitting.cost`, so switching would hand back blocks for pieces paid in stone in older saves. Owner question 1 |
| Farmland gate (2) | `farm_plot.gate_stone` (`FarmPlots.build_fence`) | **Raw stone** (DECISION): two set gate posts; the number itself still awaits the owner (FARM-02) |
| Manor repairs and public works | `NPCBrain.reeve_day`, `_public_works` → the works yard (`ManorWork`) | **Raw stone**: mending roads, bridges, the well and the mill race (rubble and road metal). Also `manor_work.gd` belongs to the MIN-F2 worker. Owner question 1 |
| Manor quarry job | `ManorWork.post_quarry` (quarry `stone` to the works yard) | Raw stone; unchanged |
| Caravan stone imports (B7-007, INT-065) | `NPCBrain._caravan_stone`, `caravan_stone`, `caravan_import_when_left` | **Raw stone, unchanged** (no prior owner rule says otherwise; the decision names stone as the quarry's output and blocks as the stoneworker's). The threshold still reads the village's stone left (`Quests.deposit_left("stone")`, MIN-B); the labourers buy the merchant's imported stone to dress when nothing is left to quarry |
| Contracts (CON-01) and services (CON-02) for stone | `Contracts.means` (route `mine`), `ContractServices` | Raw stone; unchanged. Blocks are contractable through the generic craft route (a seller with a mallet, the skill and stone) |
| Quests and manor job texts | `game_ui.gd`, `main.gd` (bring stone to the works yard) | Raw stone; unchanged |
| Merchant starting stock (12 stone) | `Population._equip` | Raw stone; unchanged. No starting blocks: the first blocks are dressed (no block from nothing) |
| Raw-goods merchant stock cap (40) | `BUYS.merchant_raw.stone` | Unchanged; blocks have their own cap (20) |
| Labourers' quarrying, miners' stone | `NPCBrain._miner` | Unchanged |
| Discovery, prospecting, pits, galleries (stone found, spoil) | `discovery.gd`, `open_pits`, `underground` | Raw stone; unchanged (mining files untouched) |
| Debug scene setups (`site`, `site_world`) | `main.gd` | Give blocks for the house site |
| Economy sim ledgers | `economy_sim.gd` `MATERIALS` | `building_block` added to the reported materials; the goods ledger is generic (`made_`, `used_`, `used_building_`) |
| Material and resource checks | `docs/systems/*` | Regenerated (`check_materials.py --write`, `check_resources.py --write`) |

## 5. Saves

No save format change: `SAVE_VERSION` stays 17 (`building_block` is an ordinary inventory id; the recipe keys are data).

- **Raw stone in packs, chests, pantries, merchants, the works yard, carts and contract loads** stays raw stone. Nothing
  converts it (no free blocks); it is still quarry output, sellable and dressable.
- **Building sites from older saves** (Build 16 and earlier Build 17) keep the cost and need they were marked out with
  (`p.site.cost`, `p.site.need`, both saved): they go on taking raw stone for their recorded need, their builders and
  helpers still buy stone for them (`SELLERS.stone`, `open_need("stone")`), they finish with stone, and cancelling gives
  back the delivered stone as stone. New sites take blocks.
- **Sites with no recorded cost** (saves before version 6, which `SaveStore` refuses) were previously costed at today's
  `house_cost`; that would now count blocks never delivered. `World.site_cost` uses `LEGACY_HOUSE_COST` (30 plank, 20
  stone, 10 log, the house cost of their day) instead.
- **Fitted ovens, stoves and forges** in older saves were paid in stone and still cost stone: taking one up gives back
  stone (section 4).

## 6. System interactions (for the lead's INT entries)

- Crafting ↔ Construction: building sites now consume `building_block` made by `dress_stone` (new interaction).
- Labour (labourers) ↔ Market: labourers dress blocks to the raw-goods merchant's demand and open sites' need, sell
  them to the merchant and to builders' helpers; buy mallets from the goods merchant (carpenter-made, B14-07) and raw
  stone from the raw-goods merchant (new).
- Quarrying (MIN-B) ↔ Stoneworking: quarried raw stone is the only input of blocks (new).
- Caravan (B7-007, INT-065): unchanged rule, raw stone only; blocks are not exported.
- Contracts (CON-01): the craft route now honours a recipe's tool (`_can_make`).

## 7. Owner questions

**Owner decisions, 2026-10-21** (`docs/directives/2026-10-21_stone_q1_and_stonecutting_trade.md`):

- **Question 1 answered (STONE-Q1, Option C):** materials match the work. Raw stone for rough construction, rubble, road
  maintenance, minor repairs and ordinary ovens, stoves and forge hearths; blocks for structural masonry, substantial
  stone construction and major masonry reconstruction; both, in the right quantities, where a job needs both. Build 17
  already matches this where it distinguishes the work (blocks for houses, workshops and rooms; stone for fittings, the
  gate and the manor's mending). The manor's mending has one kind, so the split between ordinary maintenance and major
  reconstruction, and mixed jobs, are recorded as STONE-03 (Expansion 18) and Build 17 keeps its behaviour. Fittings
  refund their cost in stone, so no save turns stone into blocks.
- **Question 3 answered:** stonecutting is a general activity, not only a trade. The recipe has no job gate and the
  player can dress stone for their own house today; a villager household dressing blocks for its own building or repairs
  is STONE-02 (Expansion 18, with the trade, since both extend the same villager production decision). The professional
  stonecutter's business is X18-STONECUT (Expansion 18, register on staging), on these same mechanics: same recipe, tool,
  station, skill and conservation; the business adds stock, buying, selling, orders and decisions.
- **Question 2 answered (STONE-Q2, Option C):** how much stone becomes blocks will depend on the worker's skill, by one
  rule for everyone, with the rest kept as conserved waste or spoil. Expansion 18 (STONE-04); no ratios approved yet, a
  model goes to the owner first. **Build 17 keeps 1:1** (`dress_stone` unchanged, `exact`).
- **Question 3 answered (STONE-Q3, 1B + 2B):** a dedicated Stoneworking skill in the existing skill system (STONE-05)
  and a smith-made iron chisel used with the mallet (STONE-06), in Expansion 18. Build 17 keeps Crafting and the mallet.
- **All three answered.** Expansion 18 stoneworking: X18-STONECUT (the trade), STONE-02 (villagers dressing for their
  own use), STONE-03 (materials by kind of repair), STONE-04 (skill-based efficiency, conserved waste), STONE-05
  (Stoneworking skill), STONE-06 (iron chisel). Values left to the owner then: starting levels and migration credit,
  efficiency values, chisel durability and wear, chisel recipe quantities.

Original questions:


1. **Shop fittings and the manor's mending:** should ovens, stoves and forge hearths, and the manor's repairs and public
   works (roads, bridges, the well, the mill race), take dressed blocks rather than raw stone? Recommendation: keep raw
   stone (rubble work); if blocks are wanted, record the cost on each fitted piece first so older pieces give back what
   they were paid in.
2. **Waste in dressing:** blocks are 1:1 with raw stone now. A waste ratio (for example 3 stone to 2 blocks, the rest
   as spoil) is more realistic but draws the finite quarry harder. Recommendation: keep 1:1 until the balance review.
3. **A stonemason trade and skill:** labourers are the stoneworkers and Crafting is the skill. A dedicated mason job
   (and a Stoneworking skill or a chisel tool) is a larger change to the job system. Recommendation: revisit with the
   Expansion's labour-market work.

## 8. Tests

`game/tests/stone_test.gd` (45 checks): data; recipe parity for the player and a villager (no mallet: refused, stone
kept; with one: two blocks, Crafting xp, the mallet worn); no free blocks (one stone makes none; a Crafting 10 master
turns 200 stone into exactly 200 blocks; every block in the world was made); villager production only to demand, sold
to the raw-goods merchant, a mallet bought when needed; construction consumes blocks and refuses stone for them; an
older site keeps its stone cost over a save, takes stone, cancels to stone; a cost-less site counts nothing; save
round trip of blocks and stone; determinism of one seed.

## 9. Wiki and documentation (WIKI-01)

- **New in-game page** `sys:stoneworking` "Stoneworking: building blocks" (`game/scripts/core/wiki_stone.gd`, registered
  in `Wiki.build`): raw stone versus blocks, dressing (workbench, mallet, time, skill, from `recipes.json`), what needs
  blocks and what keeps raw stone, who makes them (labourers to demand), the caravan. Numbers come from the data.
- **Updated:** the labourer's job line (`Wiki` job texts: dresses stone into blocks when builders want them); the
  stall page's list of what builders buy (`wiki_business.gd`: building blocks). The item and recipe pages for
  `building_block` and `dress_stone`, and every room's materials (`wiki_property.gd`), are generated from the data.
- `wiki_test` passes.

## Build 18 update (B18-DP-09, B18-DP-10)

`dress_stone` is now **3 stone to 2 blocks and 1 rubble (a by-product, raw stone for raw-stone work only), a mallet and an iron chisel held (each worn
1 a batch), the Masonry tiers applied inside conservation** (`conserve`: never more blocks than stone); the chisel is forged from an iron bar (`forge_chisel`); any villager
may dress for their own house (`Construction._dress_own`) and the stonecutter is a trade of the job market. The sections
above describe the Build 17 rule that these supersede; see the Build 18 row of `docs/DECISIONS.md` and INT-198, INT-360 to
INT-362.
