# Build 16 audits: DVW-A7, DVW-A8, DVW-A12

Three read-only code audits from the requirements register (`docs/requirements/requirements.json`). The source for
all three is `docs/reference/DESIGNING_VIRTUAL_WORLDS.md`, section A, rows A7 (line 32), A8 (line 33) and A12 (line 37).

- **How it was done:** the code was read at staging commit `d317739`. No `.gd` file was changed. No simulation was
  run: Godot is not installed in this workspace, so every number below comes from the code and the data files.
  A runtime figure that was not measured is marked UNVERIFIED.
- **Classification:** each finding uses World Design Rule 022's three categories (`docs/WORLD_DESIGN_RULES.md:265`):
  defect, legitimate outcome or future improvement.
- **Moving or changing code:** this document does neither. It lists findings and recommends a classification; the
  lead agent and the owner decide.

---

## DVW-A7: over-production from raising skills by use

**What the book warns about** (DVW row A7, F1 p. 751): in Ultima Online, skills rose by use. Players made goods only
to gain skill, and the goods flooded the economy. The audit has two questions. Do our skills rise by use? If they do,
can that make more goods than the village uses or sells?

### How skills rise

| Fact | Evidence |
|---|---|
| Skills exist **only on the player**. `PlayerState.skills` maps a skill to its xp; NPCs have no skill or xp field | `game/scripts/core/player_state.gd:18`, `:68-75`; nothing in `game/scripts/core/npc.gd` or `npc_brain.gd` reads a skill |
| NPCs craft whatever their trade needs, at any level | `docs/BUILD_DECISIONS.md:21` ("NPCs craft at stations regardless of their skill level; skill levels gate only the player"); NPC craft step `npc_brain.gd:1823-1830` reads no skill |
| Xp per level: `100 × L × (1 + 0.25 × (L − 1))`, levels 1 to 10. Level 10 needs **10,500 xp** | `game/data/skills.json` (`step_base` 100, `step_growth` 0.25, `max_level` 10); `game/scripts/core/skills.gd:46-55` |
| Mining: 8 xp a unit of ore | `game/scripts/main.gd:2394` |
| Woodcutting: 12 xp a felled tree | `main.gd:2531` |
| Smithing, Crafting, Cooking: the recipe's `xp` each time it is made (3 to 50) | `main.gd:2623`; `game/data/recipes.json` |
| Combat: 4 xp a blow on a villager, 2 on an animal | `main.gd:2670`, `:2773` |
| Magic: 6 xp a cast, 6 more if it lands; 100 xp when Fireball is learned | `main.gd:2886`, `:2908`; `game/scripts/ui/game_ui.gd:2078` |
| Trading: 2 to 30 xp a deal (`2 + coins / 5`) | `skills.gd:117-118`; `game_ui.gd:2350`, `:2358`; `business.gd:907` |
| Stealth: 1 to 8 xp a try at a pocket, a lock or a container | `main.gd:2210`, `:2245`, `:2343` |

So skills do rise by use, but only the player's.

### Does higher skill raise output?

Yes, for the player only. Every effect is read through `Skills.value` (`skills.gd:89-103`).

| Effect | What it does | Where |
|---|---|---|
| `ore_extra_chance` (Mining 2-10: 25% to 65%) | A second unit, **taken from the same deposit** (`world.mine_unit` again) | `main.gd:2382-2385`; `world.gd:845-860` |
| `log_bonus` (Woodcutting 2, 6, 10: +1, +2, +3) | A felled tree gives `4 + bonus` logs instead of 4 | `main.gd:2518`; `world.gd:892` |
| `sapling_bonus` (Woodcutting 5, 8) | A chance of a second sapling | `main.gd:2526`; `world.gd:924-929` |
| `mine_time`, `chop_time`, `craft_time` | The work takes less time | `main.gd:2375`, `:2401`, `:2609` |
| `tool_wear_save`, `axe_wear_save` | The tool wears less | `main.gd:2390`, `:2530` |
| `save_chance` (Smithing 5, 8; Crafting 5, 9; Cooking 6, 10: 15% to 30%) | The recipe's **inputs are given back**: the output is made and nothing is used up | `main.gd:2616-2619` |
| `bonus_chance` (Smithing 6, 10; Crafting 7, 10; Cooking 8, 10: 10% to 25%) | **One extra unit** of a product that is not gear | `main.gd:2620-2622` |
| `price_bonus` (Trading 2-10: 3% to 20%) | Better prices for the player | `world.gd:695-697` |

### Can it drive over-production?

**NPCs: no.** They have no skills, so nothing they make is made for xp. They make goods for their trade and sell
only what a buyer wants: `wants()` caps each buyer's stock (`npc_brain.gd:1347-1351`, the `BUYS` table at `:13-30`).
Sellers keep `trader_cash_floor` coins back (`npc_brain.gd:1789`).

**The player: yes, it can make goods for xp alone, but the economy limits where they go.**

1. **Inputs are finite, except outside the village.**
   - The village's seams hold 300 iron ore, 200 coal, 240 stone, 60 copper ore and 8 gold ore (the sum of `deposits`
     in `game/data/village.json`).
   - Smithing level 10 needs 10,500 xp. Smelting iron gives 10 xp for 2 ore (`recipes.json` `smelt_iron`), so
     1,050 bars and 2,100 ore. The best chain (smelt the bars, then forge iron armour, `forge_iron_armor`, 50 xp for
     5 bars) gives about 10 xp an ore: 1,050 ore. Either way it is more than three times the village's iron.
   - The caravan imports ore only after the seams are worked out, and only up to `caravan_import_stock` a visit
     (`balance.json:220`; `npc_brain.gd:3096-3110`).
   - Cooking and Crafting need wheat, meat, hides and logs. These come from real harvests, kills and felling.
   - **Exception:** the overworld outside the village never runs out. It has endless trees, stone boulders and
     flowers, and only the player can reach it (see DVW-A8, row P4). Woodcutting xp (875 trees to level 10, at least
     3,500 logs), Mining xp from stone (about 1,313 units) and flower recipes can all be raised there without limit.
2. **Sales are capped.**
   - The player sells only what the buyer still wants: `player_sell_many` refuses more than `brain.wants()`
     (`world.gd:2244`).
   - The price falls with every unit the buyer takes (`world.gd:657-659`, `:664-674`).
   - The buyer must also have the coins (`world.gd:2244`; `trade` at `:590-596`).
3. **What leaves the village is capped.**
   - Merchants pass goods above half their cap to the caravan (`npc_brain.gd:3044-3054`).
   - The caravan spends at most `caravan_coins` (600) a visit, and never more than its purse. The purse refills by
     `caravan_allowance` (30 a day), with nothing at the per-head ceiling (`balance.json:130-135`;
     `npc_brain.gd:2998-3007`, `:3062-3083`).
   - Ore, coal and stone are never exported (`npc_brain.gd:54`).
4. **Unsold goods stay with the player.** Nothing spoils: there is no decay key in `items.json` or `balance.json`.
   Goods made for xp pile up in the player's pack and chest. The book's intro names this risk ("goods that never decay
   pile up", `DESIGNING_VIRTUAL_WORLDS.md:16`). It stays in the player's hands; it does not reach the village.
5. **Measured runs:** the long-run records in `docs/release/LONG_RUN_SIMULATION.md` and `game/tests/economy_sim.gd`
   run with no player (`economy_sim.gd:2-9`). No run measures a player raising a skill. How fast a real player could
   do it is UNVERIFIED.

### Two accounting findings

- **A1. Two skill effects make items without a valid input.**
  - `save_chance` gives the inputs back (`main.gd:2616-2619`), and `bonus_chance` adds a unit the recipe did not make
    (`main.gd:2620-2622`).
  - This contradicts the World's own invariant: "items only appear through extraction ... or recipes that consume
    their inputs" (`world.gd:11-13`).
  - Both effects are approved: they are in the skill tree, PL2-005 "Longer skill trees", COMPLETE AND VERIFIED in the
    register. So the code does what it was approved to do; what conflicts is the documented invariant.
- **A2. Nothing the player produces is counted in the ledger.**
  - NPC production calls `w.stat("made_"...)`, `stat("mined_"...)` and `stat("felled_"...)` (`npc_brain.gd:1734`,
    `:1802`, `:1815`, `:1827`).
  - The player's mining, felling and crafting in `main.gd` make no `stat` call. A search for `stat(` finds none in
    `main.gd` or `game/scripts/ui/`.
  - The skill-made extras above are therefore invisible to the faucet-and-drain ledger (DVW-A4).
  - It does not affect today's no-player runs. It will matter when DVW-A5 or EQ-05 measures a player.

### Classification (Rule 022)

| Finding | Category | Why |
|---|---|---|
| A player can make goods only for xp | **Legitimate outcome** | Inputs are finite in the village, and sales and exports are capped by real purses, so the goods cannot flood the village. What is left over stays with the player. |
| NPC skill over-production | **Not applicable** | NPCs have no skills (`BUILD_DECISIONS.md:21`) |
| Unlimited overworld inputs feed Woodcutting, Mining (stone) and flower recipes | **Future improvement** | Exports stay within the caravan's purse. Belongs with Expansion B and the overworld (DVW-A8 row P4) |
| A1: `save_chance` and `bonus_chance` make items without inputs | **Needs a decision**, recommended as an *intended faucet*, not a code defect | The approved skill tree (PL2-005) and the invariant (`world.gd:11-13`) disagree. Recommended: the lead amends the invariant comment to name skill bonuses as a faucet, or the owner removes the effects. |
| A2: player production missing from the ledger | **Defect, minor** (accounting: "every coin and item with a legitimate history", Rule 022, *Mandatory*) | It does not block Build 16's no-player runs. Fix it before any player-disruption measurement (DVW-A5, EQ-05): add `stat("made_"/"mined_"/"felled_")` calls for the player's actions, ideally once those actions move to core (DVW-A12). |
| Goods never decay | **Future improvement** | The book warns about it (DVW line 16). No requirement asks for decay. |

---

## DVW-A8: perks only the player gets, against "the same rules"

**The rule:** World Design Rule 012: "The player participates in the same competitive economy and receives no
automatic preferential treatment" (`WORLD_DESIGN_RULES.md:127`); its check asks for "equal rules for player and NPCs"
(`:129`). Also: "The player must be able to participate in the same underlying systems as NPCs wherever the design
calls for it" (`docs/directives/2026-10-20_two_decisions_three_expansions.md:155`). DVW row A8: "each is shared or
gets a written reason."

### Player-only perks, actions and resources

| # | What the player has that NPCs do not | Evidence | Intended? (written reason) | Recommended |
|---|---|---|---|---|
| P1 | **Skills, levels and tier effects** (all nine skills): faster work, more output, less tool wear, better prices, crits, less damage taken | `skills.json`; `skills.gd:11-33`; effects read in `main.gd`, `world.gd:509`, `:696`, `player_state.gd:88` | Partly: `BUILD_DECISIONS.md:21` (agent proposal: "Keeps 100 NPCs simple"). There is no owner decision. Rule 011 asks for NPC "professional growth" (`WORLD_DESIGN_RULES.md:116`); WDR-011-C is NOT STARTED. NPC skills for more trades are DVW-B8 (BLOCKED, proposed) | **Gap with a written agent reason.** Owner decision needed; future improvement under WDR-011-C or DVW-B8 |
| P1b | *The reverse:* NPCs need **no** level. A smith forges iron armour (Smithing 3 for the player) from the start; NPC miners mine gold ore without Mining 3 | NPC craft `npc_brain.gd:1823-1830`; NPC miner ore list includes gold `npc_brain.gd:842-856`; the player's gate at `main.gd:2372`, `resource_nodes.gd:204` | Same reason as P1 | Same as P1. Record that the asymmetry runs both ways |
| P2 | **Skill output bonuses**: extra ore, +1 to +3 logs a tree, inputs given back, extra units | `main.gd:2382`, `:2518`, `:2616-2622` | PL2-005 (register, COMPLETE AND VERIFIED); player only by P1's reason | As P1; also DVW-A7 finding A1 |
| P3 | **Saplings from felling, and planting trees** | `world.gd:922-929` ("A mature tree's sapling(s) for the player"); called only from `main.gd:2526`. NPC felling `npc_brain.gd:1806-1810` uses `fell(t, 0)`, so no sapling. `plant_tree` is called only from `main.gd:2561` | Owner-approved tree task, `DECISIONS.md:103` ("felling gives ... a sapling, the player plants saplings"). Village forests regrow from stumps without planting (`world.gd:883`) | **Intended (DECISIONS.md:103).** Woodcutters can stay as they are, because stumps regrow. Record the reason in the register |
| P4 | **The overworld**: felling trees, breaking boulders for stone and picking flowers outside the village. It never runs out | `overworld.gd:3-11`, `:588-640`; NPCs never leave the village (`DECISIONS.md:102`: "villagers stay inside the village"); `npc_brain.gd` has no overworld reference | Owner-approved overworld task, `DECISIONS.md:102` | **Intended (DECISIONS.md:102).** Economic note: a raw supply only the player can tap (DVW-A7). Future improvement with Expansion B (settlements outside) |
| P5 | **Fireball and Magic** | `main.gd:2869-2911`; learned in `game_ui.gd:2071-2084`; an heir forgets it (`world.gd:566`) | Owner decision, `DECISIONS.md:57` ("The first storyline quest: learn Fireball from the sage") | **Intended.** Note: no NPC casts or learns a spell |
| P6 | **Trading price bonus** (up to 20%) | `world.gd:695-697`, used in `player_quote` `:664-674`; NPC trades use the plain price (`npc_brain.gd:1766-1795`) | Part of P1. Its profit margin is the open owner question in DVW-A5 ("is honest arbitrage intended?") | **Awaiting owner** (DVW-A5) |
| P7 | **Friendship benefits**: friend prices, a friendly guard lets a theft go, carrying without a wage | `world.gd:670-671`; `wiki.gd:596`; `construction.gd` hire | CRT-06 (register, owner-approved list of friendship benefits for the player). Villagers court each other "by the same rules" (`docs/directives/2026-10-19_courtship_friendship.md:7`), but a villager friendship gives no price or leniency | **Intended (CRT-06)** for the player. Future improvement: villager friends trading at a friend price (WDR-012-C) |
| P8 | **Selling a buyer down to 0 coins.** NPC sellers stop at `trader_cash_floor` (15) | Player: `world.gd:2244` checks only `buyer.coins < bill`. NPCs: `npc_brain.gd:1307`, `:1789` | No. B7-008 (BLOCKED) and OD-15 (open owner decision): "the 15-coin floor for player sales was never approved" (register, B7-008 history 2026-10-20) | **Gap, awaiting owner (OD-15).** Recommended answer: yes, the same floor |
| P9 | **Hunting the last animals of a wood.** NPC hunters and predators take only animals the wood can spare | `fauna.gd:214-216` (`can_take` with `spare`); the player's kills (`main.gd:2769-2790`) have no such check | Yes: EQ-05 "Do not secretly protect the world from legitimate player consequences"; the refuges restock (WR-01, register B7-008 history) | **Intended (EQ-05).** A legitimate outcome |
| P10 | **Rest restores full health and stamina** at home | `main.gd:3662-3671` (`p.hp = p.hp_cap()` at `:3670`); villagers "do not otherwise heal" (`npc_brain.gd:262-264`), only with medicine | Agent record only: `BUILD_DECISIONS.md:383-385` ("Rest already restores fully, so no new rest healing was added"). No owner decision | **Gap.** It breaks the "same rules": the same night's sleep heals one person and not another. Owner decision: let villagers recover a little overnight, or record the reason |
| P11 | **Theft by villagers who are not bandits**: picking pockets, taking from containers, picking locks, cutting another's field | `world.gd:2132-2189`, `:2013-2025`, `:1734-1745`; `chests.gd` attempt; only bandits rob among NPCs (`npc_brain.gd:1975-1987`) | Owner rules for the player ("owner rule", `world.gd:2132-2137`; never a child, B8-010). Rule 016 covers criminal careers through bandits | **Intended** for the player. Villager petty crime is a future improvement under Rule 016 |
| P12 | **Hiring a helper** to carry for a building site | Only the talk window calls `Construction.hire` (`game_ui.gd:2187-2207`); no NPC calls it (no match in `game/scripts/core/` outside `construction.gd`) | Owner rule for the player (comment at `game_ui.gd:2059-2060`). WDR-012-C records "no ... hiring competition" | **Future improvement (WDR-012-C)** |
| P13 | **Renting a manor market pitch**, a larger stall, a shop licence | `business.gd:330-337`, `:517`, `:559` (always `World.PLAYER`); `world.gd:117` ("for the player to rent") | PL1-10 (player businesses, owner-approved, staged). Villagers have house storefronts instead (B14-03, COMPLETE AND VERIFIED) | **Intended (PL1-10).** It is partly shared: storefronts are open to both |
| P14 | **Quests and harvest work** from villagers | `quests.gd`; `game_ui.gd:1865-1970` | The player's way in to the villagers' needs (`DECISIONS.md:57`) | **Intended**. Not a perk: work for pay |
| P15 | **Eleven recipes no NPC ever makes**: `brew_strong_tonic`, `brew_tonic`, `craft_plough`, `forge_amulet`, `forge_copper_ring`, `forge_gold_ring`, `forge_iron_helmet`, `knead_flatbread`, `leather_armor`, `leather_cap`, `smelt_gold` | `docs/systems/MATERIAL_INTERDEPENDENCY.md:87-115` ("player only"), built by `tools/check_materials.py:274` | None recorded: none is in `docs/systems/material_exceptions.json`; the related material findings stay **open** (`MATERIAL_INTERDEPENDENCY.md:36-51`) | **Gap (Rules 001-003, WDR-007-C).** Side effect: smiths buy gold ore (`npc_brain.gd:14`) that nobody but the player smelts, and it is never exported (`:54`). That is at most 8 ore, so it is a small dead end |
| P16 | **Sprint and stamina**; walking speed | `main.gd:1656-1706`, `:1584` | A control and presentation mechanic | **No action**: NPCs have no stamina model |

### Things checked and found shared

- **Carts:** households place, pull and park carts (`npc_brain.gd:1686-1724`; `carts.gd:35-90`).
- **Storefronts:** for both player and villager households (B14-03).
- **Building houses:** households build their own (Rule 020; `construction.gd`).
- **Fields and pens:** shared with the farmers (PL2-015; `farming.gd`).
- **Manor work:** the player takes manor jobs too (`manor_work.gd`, `job_of("player")`).
- **Pricing:** stock-based prices apply to both. The player's buy price also counts local supply (`world.gd:672`), as
  NPC sellers' prices do (`world.gd:618-619`).
- **Looting the slain:** guards collect lying coins for the treasury (EQ-20, `balance.json:435`).

### Summary

- **Intended, with a written reason:** P3, P4, P5, P7, P9, P11, P13, P14 and P16.
- **Gaps that need an owner decision:** P1/P1b/P2 (NPC skills; agent reason only), P6 (DVW-A5), P8 (OD-15), P10
  (rest healing) and P15 (player-only recipes).
- **Future improvement:** P12.
- **Defects:** none under Rule 022's definition. Every mechanic does what it was built to do.

---

## DVW-A12: game rules in `game/scripts/core/`, not the UI

**Why it matters** (DVW row A12, A pp. 140-148): rules that live in the view cannot be run by a future host
(`docs/directives/2026-10-19_multiplayer_foundation.md`), cannot be tested headless, and can drift from the NPCs'
version. This audit lists them; moving them is later work.

**Method:**
- Read `game/scripts/main.gd` (3,975 lines) and searched every file in `game/scripts/ui/` and `game/scripts/view/`
  for changes to coins, inventories, crimes, memories, xp, spells, health and world state.
- Files that only draw: `game/scripts/view/*.gd` contain no change to coins, health, inventories or world state (no
  match). Those are not listed.

### Rules that live outside core (should move)

| # | File:line | The rule | Where it should live |
|---|---|---|---|
| R1 | `main.gd:2366-2394` | **Mining:** a pickaxe is required, gold needs Mining 3, the time formula, the extra-ore roll, tool wear, 8 xp an ore | A `World.player_mine(dep)` in core, beside `mine_unit` (`world.gd:845`). The gold check is already in core too (`resource_nodes.gd:204`): one copy should go |
| R2 | `main.gd:2395-2407`, `:2509-2531` | **Felling:** an axe is required, chop time, log bonus, sapling drop, axe wear (3 a tree), 12 xp | `World` (beside `chop_tree`, `world.gd:898`) |
| R3 | `main.gd:2591-2628` | **Player crafting:** the level gate, materials, time, `save_chance` and `bonus_chance` rolls, xp. NPC crafting is in core (`npc_brain.gd:1823-1830`), so the two drift (DVW-A7 A1 and A2) | One recipe runner in core (for example `World.craft(actor, recipe, station)`) for both |
| R4 | `main.gd:2548-2569` | **Planting a sapling:** removing the item, re-checking the refusal | `World.plant_tree` already checks; the item removal should move in with it |
| R5 | `main.gd:2344-2365` | **Taking loot:** items and coins move from a loot pile to the player (`p.coins += int(l.coins)` at `:2362`); the pile is removed when empty | `World.player_loot(i)` |
| R6 | `main.gd:2579-2584` | **Xp award and level-up** (`_xp`); also called from UI (`game_ui.gd:2350`, `:2358`) | `PlayerState.gain` exists (`player_state.gd:68`). Only the level-up message belongs in the view |
| R7 | `main.gd:2664-2682` | **Combat blow:** the target, xp, the crit roll (×2 damage at `:2681`) | `Combat` (`game/scripts/core/combat.gd`) |
| R8 | `main.gd:2792-2805` | **Damage and death:** `max(0.5, dmg − armor × 0.5)` (`:2793`); waking those near; a crime unless a bandit; `world.kill`. The same formula is copied in core at `npc_brain.gd:1998` and `fauna.gd:369` | One `Combat.hit(attacker, target, dmg)` in core |
| R9 | `main.gd:2858-2868` | **Assault as a crime:** the victim's memory, the harm to the relationship, adults fighting back, every guard within **15 tiles** (hard-coded at `:2863`) turning on the player. Theft uses `World.witness`, with sight and `witness_radius` (`world.gd:1753-1770`), so the two crimes follow different witness rules | `World` (with `witness`), and the radius in `balance.json`. Related: DVW-B2 (assault fines, NOT STARTED) |
| R10 | `main.gd:2776-2790` | **Killing livestock is theft** from the keeper: a crime and a note | `Fauna` or `World` |
| R11 | `main.gd:2869-2887`, `:2889-2911` | **Fireball:** whether the spell is known, cooldown, stamina cost, damage `14 × fireball_damage` (`:2897`, base 14 hard-coded), collision, xp | `Combat` or a core `Magic` module; the base damage in `balance.json` |
| R12 | `game_ui.gd:2071-2084` | **Learning Fireball:** the price check, coins from the player to the sage (`:2075-2076`, a direct change of `coins`, not `World.trade`), the spell flag, 100 xp | A core call, for example `Quests` or `World.learn_spell(n, "fireball")` |
| R13 | `game_ui.gd:2350`, `:2358` | **Trading xp** awarded by the trade window after a sale or purchase. The stall's xp is already in core (`business.gd:907`) | Inside `World.player_buy_many` and `player_sell_many` |
| R14 | `game_ui.gd:129`, `:2093` | **Pickpocket reach** (1.8 tiles) is checked only by the talk window; `World.pickpocket` (`world.gd:2138`) does not check distance | `World.pickpocket` |
| R15 | `main.gd:1835-2050` (`_find_target`) | **Reach for every interaction** (1.2 to 2.2 tiles) and wall checks are decided here only; core actions such as `player_take` (`world.gd:2013`) take the player's word | Core refusal checks (a reach check in each `World.player_*` action) |
| R16 | `main.gd:2052-2054` | **Theft is never the default choice**, decided by searching the label text for "theft" | A core `is_theft(target)` flag; the view keeps the ordering |
| R17 | `main.gd:1912-1918` | **Field ownership in the prompt** ("taking it is theft"). The crime itself is in core (`world.gd:1740-1745`); the prompt repeats the test | Presentation, but it should read a core `field_owner(f)` |
| R18 | `main.gd:3662-3674` | **Resting:** runs the world forward, then sets full health and stamina (`:3670`) | `World.player_rest()` (see DVW-A8 P10) |
| R19 | `main.gd:1656-1706` | **Sprint and stamina:** drain, minimum, latch | `PlayerState` or core movement, if a host must check speed. Low priority |
| R20 | `game_ui.gd:2874-2885` | **Moving stolen marks** with goods between the pack and the chest (`take_marks`, `store_marks`) | `World` or `PlayerState` (`player_state.gd:166-195` already holds the mark logic) |
| R21 | `game_ui.gd:2204` | **A helper's buying budget:** `min(estimate, coins − wage)` | `Construction.hire` (`construction.gd:279`) |
| R22 | `main.gd:3092-3111` | **Placement:** refusals come from core (`Construction.can_place`, `Fitting.why_not`), so only the flow is here | Already fine. Listed for completeness |

The register's note for DVW-A12 said `main.gd` holds "crime and storefront-target rules". **Crime:** R9, R10 and R16
confirm it. **Storefront targets:** `main.gd:2023-2041` only chooses which button to offer; the rules
(`Business.storefront_refusal`, `build_storefront`, `open_front`) are in `business.gd`. That part is presentation.

### Pure presentation (fine where it is)

- Labels, prompts and menu order: `_find_target` text, `_shop_target` and `_container_target` (`main.gd:2145-2185`),
  and `_next_hint`.
- Option gates that only hide a button the core also refuses:
  - Court: `game_ui.gd:2121` hides "Ask to court" below half the threshold; `Relations.ask_court` checks the real
    threshold (`relations.gd:443`).
  - Craft: the craft window's "Make" button (`game_ui.gd:2387-2397`). It duplicates R3's check, which is fine once
    R3 moves.
  - Prices and caps shown in windows: `stall_window.gd:312` (`Business.set_price` enforces it at `business.gd:396`)
    and `fit_window.gd:28`.
- Damage numbers, health bars, flashes (`main.gd:2811-2856`), sprites, camera, input, screenshots and save file I/O.
- Debug and screenshot scenarios that set coins directly (`main.gd:195-650`, `:2941-2952`, `:3746`): screenshot
  setups only, not game rules.

### Classification (Rule 022)

- **Not a defect:** each rule works.
- **Future improvement:** under DVW-A12 itself and the multiplayer foundation, since a host must own these rules.
- **Most valuable first:**
  1. R3 (one recipe runner) and R1, R2 (extraction). These also fix DVW-A7 finding A2.
  2. R8 and R9 (one combat and crime path).
  3. R12 (a coin transfer outside `World.trade`).
  4. R14 and R15 (reach checks a host would need).

---

## For the lead: genuine defects

Only one finding fits Rule 022's "defect" category, and it does not block Build 16's no-player work:

- **DVW-A7 A2.** The player's production makes no ledger `stat` call: mining `main.gd:2366-2394`, felling
  `:2509-2531`, crafting `:2591-2628` (skill extras included). Player activity is invisible to the faucet-and-drain
  ledger (DVW-A4). Fix it before any player-disruption measurement (DVW-A5, EQ-05).

Two documentation conflicts need a ruling. They are not code defects:

- **DVW-A7 A1.** `world.gd:11-13` says items appear only from extraction or from recipes that consume their inputs.
  `save_chance` and `bonus_chance` (`main.gd:2616-2622`) break that statement by design (PL2-005).
- **DVW-A12 R9 against `World.witness`.** Assault and theft follow different witness rules (a hard-coded 15 tiles
  against sight and `witness_radius`). This is a consistency gap, not a broken mechanic.

**Owner decisions surfaced:** P1 (NPC skills), P6 (DVW-A5 arbitrage), P8 (OD-15 cash floor), P10 (rest healing),
P15 (the eleven player-only recipes).

---

## Resolution (lead agent, 2026-10-20)

- **DVW-A7 A2, fixed.** The player's mining, felling, saplings and crafting now go through `World.player_gain`, which
  counts them as `mined_`, `felled_` and `made_`; crafting counts its inputs as `used_`, and a broken pick or axe as
  `broke_`. What a full pack cannot hold is set down at the player's feet, where before it was lost. Test:
  `world_test.gd` `_player_gain`.
- **Found while building the EQ-06 scenarios, fixed.** A carcass left to spoil vanished uncounted; it is now
  `spoiled_<item>` and the ledger counts it (`world_test.gd`, PL2-004 block).
- **DVW-A7 A1, documented.** The skill effects are approved (PL2-005), so the invariant comment in `world.gd` now names
  them as the one exception. Their output is counted, so the ledger still balances.
- **Owner decisions:** P1, P8, P10, P15 and R9 are recorded as OD-18 in the register. P6 is DVW-A5's own question.
- **DVW-A12:** the moves are recorded as future work, in the order above; they change no behaviour and are not
  started.
