# Bartle, *Designing Virtual Worlds*, pages 319–455: notes for My Medieval Life

Source: `part_CD.txt`. I read all of it. The file has the last pages of Chapter 3 (pp. 319–328)
and Chapter 4, "World Design", from p. 329 to p. 455. **It stops partway through "Ownership" (p. 455).
The Chapter 4 sections on ecology and the rest of ownership are not in this file**, so these notes do
not cover them. Page numbers are the book's own page numbers.

To compare with the game I used: the game brief, `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md`,
`game/data/balance.json`, `docs/release/LONG_RUN_SIMULATION.md` (Build 7 rules),
`docs/SYSTEM_INTERACTION_MANIFEST.md` (the B7-014 caravan entry), and a grep of `game/scripts` and
`game/tests`. These notes only read the repository; nothing in it was changed.

---

## 1. Section-by-section summary

### End of Chapter 3: immersion (pp. 319–328)
- **Control (pp. 322–324).** Don't take a character out of the player's control. The exceptions
  are effects the player agreed to (alcohol) or mild environmental ones. Players need a way to turn
  down goals the game hands them.
- **Detail (pp. 324–325).** Detail must not contradict itself and must sit at the **same depth
  everywhere**. If only one tree can be felled, players feel the world is incomplete. The world
  should feel as if it had a working past before the player arrived.
- **Freedom of choice (p. 326), self-expression (p. 327).** Players must know they *could* have
  tried something.
- **Things to demote (pp. 327–328).** Reality and sterility. "Boring the players" is the surest way
  to kill a world.

### Chapter 4, World Design
- **Scope (pp. 330–333).** Business, technical and gameplay limits are given. A single "big idea"
  takes over the whole project.
- **Ethos (pp. 333–336).** The designer picks an ethos and makes the world reward it.
- **Unending or circular (pp. 336–338).** There is a trade-off between reusing content and the
  world changing for good. In a single-player game a mistake means going back to a save. MML has
  permadeath with heirs instead, which is a deliberate "unending" choice.
- **Hands on or hands off (pp. 338–341).** Live-team actors and referees. Not applicable to MML.
- **Categories (pp. 341–346).** Classless systems with "character kits" are better than classes.
  Alignment is not worth tracking.
- **Intimate or grand scale (pp. 346–349).** Size should suit the content. A small world packed
  with things to do beats a large empty one. Travel speed and teleporting change how big a world
  feels.
- **Purposeful or decorative (pp. 349–352).** Decide at the start whether every object does
  something. Deciding later leaves "trees you can't chop down". The virtual economy is one of the
  main losers when gameplay and business pull in different directions.
- **Closed or open economic model (pp. 352–355).**
  - A closed economy has a fixed amount of money and resources go round in a cycle. It is hard to
    balance, very sensitive to bugs and "too easy to gouge".
  - An open economy works by faucets and drains. In practice money is easier to hand out than to
    take back, so it inflates and players fall back on barter.
  - The three options: an unbreakable closed economy, a *managed* open economy, or no formal
    currency.
  - Economy and ecology work the same way at an abstract level.
- **Information versus immersion (pp. 355–357).** Choose the default early. Players will reverse-
  engineer the numbers anyway.
- **Geography (pp. 357–375).**
  - Top-down levels: world, zones, regions, areas, rooms or tiles.
  - The map must be believable and must provide a meaningful ecology and economy through where
    resources are placed.
  - Edges of the world (pp. 365–366). Terrain in layers: elevation, geology, vegetation, cover,
    volume (p. 367).
  - Weather and seasons (pp. 367–368).
  - **Implicit terrain (pp. 368–370):** generate from a seed and record player changes on top. This
    is exactly MML's overworld.
  - Movement and getting lost (pp. 370–375). Forests are a classic place to get lost, so give
    landmarks and maps.
  - Teleporting turns a world into a set of separate sub-worlds (pp. 374–375).
- **Settlements (pp. 376–381).**
  - Settlements need level ground, food, water, building materials, communication links and a
    population.
  - Don't judge a settlement by how many player houses it has. A mining town nobody visits may
    supply everyone's iron.
  - Three ways to staff new buildings: NPCs simply appear, staff come with the building, or
    economics (NPCs move where business is good).
  - Build in stages with visible progress.
- **Population and NPCs (pp. 381–392).**
  - The roles NPCs play: trade, services, guards, loot, quests, lore, sidekicks, extras.
  - Guards must actually be able to guard.
  - NPCs with continuity (the mother and her reckless son, p. 388) create attachment.
  - **NPCs must trade so that prices move, because players don't trade enough (p. 389).**
  - Model behaviour either as a whole population or per NPC. If you already simulate individuals,
    let the totals come out of their actions (p. 390).
  - **PCs should be able to do anything NPCs can, and the other way round (pp. 391–392).**
- **Player characters (pp. 392–395).**
  - Players want a big world, then want to shrink it with teleports.
  - Perks that only players get (teleporting, coming back after death) break the economy.
  - The wine example: France to Scotland, transport cost is what makes local prices. "At a stroke,
    you have completely wrecked the economy."
- **Economics (pp. 395–409).**
  - Four kinds of economy: none, fixed prices, free market, faddish.
  - Wealth comes in from drops, quest rewards, farming and mining, and starting money.
  - A closed economy grinds to a halt when people hoard.
  - In an open economy, fixed prices make goods effectively free and ruin crafters.
  - **Pay rewards in goods, not cash** (pp. 401, 407–408).
  - Players act out of self-interest:
    - bakery wars, where a rich player undercuts and then monopolises;
    - pelt hoarding, where a cartel restricts supply;
    - nobody buys the tailor's clothes;
    - "an honest day's pay for an honest day's work".
  - Fixed prices and fixed incomes lead to everyone affording everything, or no one affording
    anything.
  - Ultima Online's economy came closest to working. Lack of sinks finally broke it.
  - Asheron's Call collapsed into hyperinflation after coin-duplication ("duping") bugs, and an
    informal economy replaced it.
- **Interference in economies (pp. 409–412).**
  - Secure trading is fine.
  - An over-smoothed economy kills the profit window, much like monsters that scale to the player.
  - Interest-rate or tax levers work, but players don't trust a hidden "nerf knob".
- **Tips (pp. 412–419).** Have things wear out. Charge for services. Multiple currencies. Give money
  weight, with no banks. Multiple uses for resources and substitute goods. Charge for advancement.
  Charge for abstraction: put a price on chores such as eating.
- **Non-player players (pp. 419–421).** Not applicable.
- **Physics (pp. 421–433).**
  - Follow players' common-sense ("naive") physics.
  - Model one conceptual level deeper than the deepest command.
  - Six kinds of command: quit, help, bug, communication, create or destroy, state change.
  - Extensions beyond real physics (magic and the like) need the same rigour.
  - If NPCs used the player's cheap healing, the world would be different (p. 432).
- **Objects (pp. 433–452).** Integrate everything: wear and health are the same property.
  - Assemblies via recipes and resource "atoms" (pp. 437–440).
  - Collections and generators; generators are where duplication bugs come from (pp. 440–442).
  - Containers and encumbrance (pp. 442–447).
  - Fluids, mixing, gases, fire. Fire must not spread, because of arson (pp. 447–452).
  - State changes (p. 452).
- **Properties (pp. 452–454).** Let the engine list every property of an object.
- **Ownership (pp. 454–455, cut off).**
  - Either an explicit "owned by" property, or "you own what you carry".
  - Mixing makes it hard to say who owns something. Stolen coins are fungible: who owns what is
    left?

---

## 2. Principles that apply (with a verbatim quote and page)

| # | Principle | Quote | Page |
|---|---|---|---|
| P1 | Open economies inflate because it's easy to pay money in and hard to take it out | "it's much easier to give characters money than it is to take it from them; rampant inflation is the result." | 353 |
| P2 | Not enough sinks leads to hoarding and money losing its value | "If the cash sinks aren't big enough, then players can hoard money, which therefore decreases its value" | 353 |
| P3 | Manage the faucets and drains actively | "Create a managed open economy. Put in checks and balances that will regulate both the flow of the faucet and the outflow of the drain" | 354 |
| P4 | A strictly closed economy stalls | "It's a vicious circle, which guides the economy to a grinding halt." | 399 |
| P5 | Economy and ecology should follow the same rules | "If you have a closed economy and open ecology (or vice versa) you should ask yourself why one works in closed form and the other doesn't." | 355 |
| P6 | Fixed prices ruin crafters once money inflates | "In any system with fixed pricing, inflation hurts everyone who crafts goods for which fixed prices pertain." | 400 |
| P7 | Fixed prices and fixed incomes break the economy in one direction or the other | "Fixed prices and incomes are bad for an economy, as eventually either everyone can afford everything (inflationary world) or no one can afford anything (deflationary world)." | 408 |
| P8 | Reward in goods, which the market prices | "The trick is to give goods rather than cash as rewards. Goods get their value from the free market" | 401 |
| P9 | Goods inflate too: common items stop being worth anything | "A mobile dropping a +1 sword is dropping nothing if everyone already has a +1 (or greater) sword." | 408 |
| P10 | Running out of sinks is what kills an economy | "What finally broke it was the lack of sinks: People didn't have enough to spend their money on, so it simply accumulated." | 408 |
| P11 | Coins are where duplication bugs hit | "stackable objects (such as coins) are their weakest point." | 409 (fn 67) |
| P12 | Generators (infinite sources) cause duplication bugs | "one false move by the programmers here and you get the duping bugs" | 441 (fn 84) |
| P13 | NPCs must trade so prices move | "players don't buy or sell enough objects to sustain an economy, therefore NPCs should engage in commerce to ensure that prices rise or fall appropriately." | 389 |
| P14 | Let the totals come out of individual agents; don't run a parallel model | "arrange for their collective behavior to emerge from their individual actions, rather than simulating it and having the two diverge." | 390 |
| P15 | The player and NPCs follow the same rules | "With some minor qualification for the virtual world's fiction, the answer should be yes" | 391 |
| P16 | Perks only the player gets break the economy | "This special treatment for players is not in itself necessarily bad. It only becomes bad when it subverts systems, such as the ecology or (especially) the economy." | 393 |
| P17 | Distance and transport cost make local prices | "They want tin to be cheap near tin mines and expensive elsewhere" | 395 |
| P18 | Instant transport wrecks local markets | "At a stroke, you have completely wrecked the economy as it stood." | 394 |
| P19 | Restricting supply creates cartels | "This is how cartels operate: By restricting supply, demand is artificially inflated" | 403 |
| P20 | Players expect their work to pay | "Players want an honest day's pay for an honest day's work." | 405 |
| P21 | Leave a profit window, don't over-smooth | "There has to be enough opportunity to make a success of something before the bandwagon arrives, otherwise it's just not worth trying." | 411 |
| P22 | Slow adjustment is where trade gameplay comes from | "One of the things about an imperfect economy is that it takes time for production and demand to fall into step. During that time, profits can be made." | 411 |
| P23 | Hidden economic levers need to be trusted | "It's an issue of trust." | 412 |
| P24 | Wear is the easiest sink, if it is realistic | "The easiest way to do this is to have stuff wear out so that replacements have to be bought." | 413 |
| P25 | Wear must make sense | "you'd be hard-pressed to justify why a ring wore out." | 413 |
| P26 | Charge for services that save work | "They are quite happy to pay for things that reduce the amount of work they have to do." | 413 |
| P27 | Heavy coin and no banks keep markets local | "When coin has weight, the act of transporting it is non-trivial. Someone who is rich in one city is not so rich in another." / "No banks, no banknotes." | 415 |
| P28 | Money that can be stolen is hoarded less | "If they can't, they will be less likely to hoard it (because it could be stolen)." | 400 (fn 59) |
| P29 | Multiple uses create conflict, and substitutes protect the economy | "having multiple uses for resources is a neat way to introduce it." / "can keep a virtual economy from being mugged" | 416 |
| P30 | Charge for happy, occasional events | "By charging for things that don't happen all the time and that the player is happy about, these negative effects are greatly reduced." | 417 |
| P31 | Upkeep the player would automate is a chore; present needs as bonuses | "If players routinely automate responses, why bother having the events that trigger the responses at all?" | 418 |
| P32 | Reward food rather than punish its absence | "when phrased so it sounds like it's giving players something for performing an action (rather than taking something away for not performing it), it's more acceptable." | 418 |
| P33 | Depth must be the same everywhere | "Better you can fell no trees than just one." | 324 |
| P34 | Recorded changes on top of generated terrain | "Any changes made by the player (for example, burying treasure) are recorded so as to supersede the implicit definition" | 369 |
| P35 | Small and full beats big and empty | "Players would rather play in a world that is small yet packed with interesting things than a world that is large but empty." | 348 |
| P36 | NPC businesses move or change trade on economics | "Economics. NPCs periodically look at how their business is going, and if it's poor, they move to somewhere else where it won't be poor." | 380 |
| P37 | Build in stages with visible progress | "Let them build in stages." / "A wait can heighten the anticipation, especially if progress is visible." | 380 |
| P38 | A settlement's value isn't how many player houses it has | "measuring the success of a settlement merely by the number of player-occupied houses is not enough." | 378–379 |
| P39 | Assemblies from recipes and resource atoms | "By defining all objects to be constructed from other objects and a limited number of recognizable resource "atoms"" | 439 |
| P40 | Fungible stolen goods make ownership unclear | "who can lay claim to the 7 UOC that I have left?" | 455 |
| P41 | What players do is not the same as what they enjoy | "It's easy for designers to mistake what people do for what people enjoy doing." | 406 (fn 65) |
| P42 | Starting kit beats starting cash | "It's better to give them a range of kit" | 407 |
| P43 | Healing that is cheap for the player would change NPC society | "Player characters may take advantage of the inexpensive healing and curing facilities of temples, but if NPCs did then the world would be a very different place." | 432 |
| P44 | Fire that spreads invites arson | "the temptation to destroy a virtual world that way would be irresistible." | 452 |
| P45 | Pick what information to show players | "Decide what you want to tell them and why. Then tell them." | 357 |

Note: the quotes above use straight apostrophes. The book's text uses curly ones (').

---

## 3. Actionable items for My Medieval Life

Each item gives a priority, the system it belongs to, the principle and page behind it, and what
the game already does.

### Economy: money (coins)

1. **HIGH: write one coin faucet/drain ledger and keep it current.**
   - *Principles:* P1, P2, P3 (pp. 353–354).
   - *What to do:* list every way coins enter or leave the village in a short table with its
     balance key. Coins **enter** through the caravan buying surplus (and its `caravan_allowance`),
     `newcomer_coins` (60), and the starting purses. Coins **leave** through caravan imports (ore,
     apothecary stock, seed) and anything else the code does.
   - Separately, list **internal transfers**: taxes, rent, stall and shop fees, fines, wages and
     quest rewards. These move coins inside the village and are not sinks.
   - *Already done:* coins are conserved through trades, deaths, imports and public works
     (`run_tests.gd`, `w.coin_sources`). Build 7 had flow-accounting identities. B7-014 made the
     caravan a finite purse with a per-head ceiling (`caravan_ceiling_per_head` 100): a year with
     no player now grows currency about 3.4-fold, against 12-fold before.
   - *Missing:* the per-faucet breakdown in one place, and a check that a newcomer's 60 coins is
     counted in `coin_sources`.

2. **HIGH: rerun the long-run report on the Build 13 rules and record the money supply over time.**
   - *Principles:* P2, P10 (pp. 353, 408).
   - *What to do:* run `econ_report.gd` for `--days 100` and `--days 365` on 2–3 seeds, with no
     player, and once with a scripted "greedy player" (see item 8).
   - Record: total currency, coins per head against the 100 ceiling, the treasury, the Gini or
     max/median household cash, who holds the money, and coins idle for more than 30 days.
   - *Why:* `LONG_RUN_SIMULATION.md` is from **Build 7**. Since then stock pricing, local supply,
     storefronts, carts, births and deaths, and the seed rules have all changed it.
   - *Pass rule (proposal):* currency per head levels off below the ceiling, and no single NPC
     holds more than X% of all coins.

3. **HIGH: add desirable, occasional coin sinks (spending that leaves the village or is destroyed)
   before player wealth builds up.**
   - *Principles:* P10, P30 (pp. 408, 417).
   - *What to do:* Ultima Online broke because there was nothing to spend money on. In Build 7 the
     median household reached 842 coins with 0 houses built. Candidates that match the owner's
     rule that "nothing comes from nowhere" and the Morris setting:
     - luxury imports from the caravan (wine, spices, fine cloth; Bartle's own wine example,
       p. 394);
     - tithes or offerings to a chapel;
     - feasts and weddings, which can tie into the births and partnering system;
     - dowries and inheritance fees;
     - pilgrimage or travel costs toward the Well, as lore allows.
   - These are "happy" spending, not punishment taxes.
   - Needs an owner decision, because it is a gameplay mechanic (CLAUDE.md §11).

4. **HIGH: decide the manor treasury's role as a holding pool.**
   - *Principles:* P2, P3.
   - *What to do:* in Build 7 the treasury held 3,300–4,900 coins idle. Public works spend it, but
     only from about day 64.
   - Recommend a target treasury band in days of obligations (it already has `treasury_reserve_days`
     10). Spend anything above the band at once, on public works, relief and paid hauling, so coins
     go back into circulation.
   - Also lower taxes when the treasury is above the band. A low-treasury rate already exists
     (0.12 / 0.06); a symmetric "high-treasury holiday" is the missing half. Partly done.

5. **MEDIUM: index wages, rents and land prices to the money supply, or derive them from prices.**
   - *Principles:* P6, P7 (pp. 400, 408).
   - *What to do:* every wage is a constant 6 coins: `guard_wage_per_day`, `manor_wage_per_day`,
     `day_labour_wage`, `helper_wage`, `reeve_wage_per_day`. `plot_price` is 60, `house_price` 150
     and `stall_rent_day` 5.
   - Prices for goods float only between 0.6× and 1.8× of a fixed base value. If currency per head
     triples, every fixed number gets relatively cheaper ("everyone can afford everything").
   - Options:
     - (a) the ceiling keeps currency per head bounded, so constants are acceptable: prove this
       with item 2;
     - (b) scale these numbers by a "village price level" taken from recent trade prices;
     - (c) set wages from what the work produces at today's prices (a miner's wage from what 6
       ore sells for).
   - Recommend (a) plus a test, and (c) for manor jobs.

6. **MEDIUM: check whether `price_min`/`price_max` (0.6–1.8 × base value) make the economy
   "fixed-price" at the edges.**
   - *Principle:* P6 (p. 400).
   - *What to do:* when stock is very high, every seller sits at 0.6× and the price stops carrying
     information. Wheat reached 14,495 in Build 7. Log the share of trades made at the floor or
     the ceiling.
   - If it is high, either widen the bounds or add a real outlet for surplus: spoilage (item 10)
     or exports.

7. **LOW: no banks; keep money physical and stealable.**
   - *Principles:* P27, P28 (pp. 400, 415).
   - *Already done:* bandits rob, villagers can be pickpocketed (`pickpocket_coins_max` 5), coins
     on a dead miner are real, and there is no bank in `game/scripts`.
   - *What to do:* keep it that way. Consider a lockable household strongbox that bandits or a
     thief can target, so idle hoards carry risk. Giving coins weight is optional; at village scale
     it adds little and would annoy players on a touch screen.

### Economy: player as an actor (the single-player version of "players beat it to a pulp")

8. **HIGH: write an "exploit player" simulation test.**
   - *Principles:* P16, P19, P21, plus bakery wars and pelt hoarding (pp. 393, 402–404).
   - *What to do:* script a player who repeatedly:
     - (a) buys the cheapest unit in the village and resells it to the dearest buyer, using
       local-supply pricing within 40 tiles;
     - (b) buys out one good, such as all bread or all bandages, to corner it, then sells at
       `price_max`;
     - (c) undercuts the cook or baker from a storefront until they go broke, then raises prices;
     - (d) sells overworld logs and stone into the village without limit.
   - Assert that no loop makes unbounded profit per game day. `sell_ratio` 0.6 and
     `caravan_coins` per visit are the guards today.
   - Assert that the undercut NPC's trade comes back after the player stops. Job mobility and
     `job_return_days` 14 exist; check that they bring the trade back.

9. **HIGH: audit perks only the player gets, against the rule that the player follows the same
   rules as NPCs.**
   - *Principles:* P15, P16, P43 (pp. 391–393, 432).
   - *What to do:* known asymmetries in `balance.json`:
     - Saplings from felling go to "the player only" (`tree_growth._note`).
     - The overworld is endless, its resources regrow, and only the player gathers there. Village
       deposits run out (Build 7: all deposits gone by day 10–13), so the player becomes the only
       local raw-goods faucet.
     - The fireball (`fireball_price` 50): who sells it, and do NPCs ever use it?
     - Do NPC farmers get `seeds_back` like the player?
     - Medicine: do NPCs and the player heal on the same terms?
   - For each, either give NPCs the same ability (for example, NPC woodcutters replant saplings)
     or write down why it is a "minor qualification for the fiction" (p. 391).

10. **HIGH: add sinks for goods (spoilage and wear) so items don't pile up.**
    - *Principles:* P9, P24, P25, P5 (pp. 355, 408, 413).
    - *What to do:* today only 8 tools and weapons carry `durability` (pickaxe, axe, hammer,
      swords, plough). Only carcasses spoil (`ANIMAL_LOOT_DAYS`).
    - Realistic, explainable wear to add: clothes and armour (`plain_clothes`); carts and
      handcarts (wheels); slow decay of stored grain and food (granary rot, pantry spoilage, ale
      going sour); slow loss of building condition (`mend` jobs exist, so tie them to real wear).
    - Bartle's warning: wear only where it is believable (no wearing rings).
    - Build 7 had 14,495 wheat hoarded by farmers. Spoilage is the natural drain that also gives
      the granary a reason to rotate stock.
    - The design doc §9 already lists "goods spoil", but it is not implemented beyond carcasses.

11. **MEDIUM: count goods the same way as coins (a ledger per item).**
    - *Principles:* P5, P12 (pp. 355, 441).
    - *What to do:* for each item id, track produced, imported, consumed, exported, worn out,
      spoiled and held. Build 7 had an `Items` identity, and `run_tests.gd` checks grain
      conservation.
    - Extend this to every item and to **generators**: wild plant regrowth, tree regrowth,
      overworld boulders, livestock products and breeding. These are exactly the "dispenser"
      sources where duplication happens.
    - Add a test that walking away from an overworld chunk and back restores nothing early.
      *Already done for persistence:* overworld `changes`, `rock_changes` and `plant_changes` are
      saved.

12. **MEDIUM: test coin and item conservation across save/load and across simulation tiers.**
    - *Principles:* P11, P12 (pp. 409, 441).
    - *What to do:* run a random sequence of trades, robberies, deaths and inheritances, save and
      load in the middle, and assert that totals are unchanged. In the same test, cover NPCs
      entering and leaving any abstract or off-screen state, and the overworld chunk freeing at
      `overworld_chunk_radius`.
    - Design doc §12 lists these failure cases; check which are already tested.

13. **MEDIUM: keep a profit window.**
    - *Principles:* P21, P22 (p. 411).
    - *What to do:* local-supply pricing (`weight` 0.02 per unit, cap 25) cuts a seller's asking
      price as soon as more units are offered nearby. Check that a player who opens a new trade,
      such as the first cheese seller or the first cart maker, earns a margin for some game days
      before NPCs respond.
    - *Already partly done:* `job_switch_cooldown_days` 7, `job_switch_margin` 1.25 and
      `job_switch_min_gain` 2 slow NPC entry.

14. **MEDIUM: show the player why the economy is in its current state.**
    - *Principles:* P20, P23, P45 (pp. 357, 405, 412).
    - *What to do:* in a single-player game the "trust" problem becomes "the player can't see why
      their goods didn't sell". Show:
      - a merchant's reason for refusing: no coins, or enough stock;
      - local stock and price trends;
      - the treasury's tax rate and why it changed (an in-world notice from the reeve).
    - The in-game wiki exists, and design doc §14 item 12 asks for a "why" debug view. A
      player-facing market notice board would answer Bartle's tailor problem (p. 404) without
      guaranteeing buyers.

15. **MEDIUM: rewards and starting wealth.**
    - *Principles:* P8, P42 (pp. 401, 407).
    - *Already done:* quest rewards come from the giver's purse (`quests.gd`: "nothing is
      created"); hunting gives goods (meat, hides, pelts); the player starts with kit plus 20
      coins.
    - *What to do:* consider letting villagers pay quest rewards in kind (eggs, cloth, a meal),
      which drains household stock rather than coin. That fits barter in a medieval village and
      keeps rewards fair as prices move.

16. **MEDIUM: use substitutes and multiple uses to make shortages playable.**
    - *Principle:* P29 (p. 416).
    - *What to do:* list the items with one source and one use, and add substitutes where the
      chain fails:
      - fuel: logs or charcoal or coal (Build 7 had firewood shortages and 8,744 logs a year
        burnt);
      - healing: bandage or poultice or tonic;
      - hides from pelts or leather;
      - building: stone or timber framing.
    - The design doc's cross-chain rule says the same thing; `tools/check_resources.py` could
      report items with a single use or a single source.

17. **LOW: charge for services the player dislikes doing.**
    - *Principle:* P26 (p. 413), using the criteria "Player characters can do it. NPCs … can do it
      for them. Players don't like doing it."
    - *Already done:* hired helpers (`helper_wage`), shop attendants, manor hauling.
    - *Next, when carts land:* paid delivery or carting between hubs, and repair at the smith
      instead of re-crafting. Both are natural coin flows.

### Player needs (chore versus gameplay)

18. **MEDIUM: food as a bonus, not a tax.**
    - *Principles:* P31, P32 (p. 418).
    - *Current state:* the player gets hungry (`player_hunger_per_hour` 3). Eating is a real food
      drain, which the owner wants.
    - *What to do:* frame good meals as temporary bonuses (stamina regeneration, faster work) on
      top of avoiding starvation. Offer a convenience for the chore: eat from the household pantry
      when sleeping at home, or take board at the tavern for a fee (Bartle's "charge for
      abstraction", pp. 418–419). Food is still consumed.

### World, settlements, NPCs

19. **MEDIUM: settlement health is measured by its economic role.**
    - *Principles:* P36, P38 (pp. 378–380).
    - *Already done:* succession (an apprentice, then a newcomer with the caravan), job mobility.
    - *What to do:* track the supply-chain health per trade (days of input, buyers, output) rather
      than headcount. Use it to show that "nobody visits the mine, but the smith needs its ore"
      dependency explicitly in the debug view.

20. **MEDIUM: construction actually happens, in visible stages.**
    - *Principle:* P37 (p. 380).
    - Build 7 found "0 sites started and 0 houses built" in a year. Confirm with item 2 that NPC
      households now spend savings on building, which is also a large and believable goods sink.
      Check that the build sites show progress stage by stage.

21. **MEDIUM: same depth everywhere.**
    - *Principles:* P33, P39 (pp. 324, 437–440).
    - *What to do:*
      - Audit actions that work on one thing and not its neighbours. Can every tree be felled in
        both the village and the overworld? Can every bush be picked? Can every rock be mined?
      - Carts are assemblies (wheels, axle, ironwork). If they can be built from parts, players
        will try to take them apart: decide whether salvage exists, and if not keep it consistent.
      - Treat tool `durability` and creature health as one concept in the UI where sensible
        (p. 433).

22. **MEDIUM: navigation in the forests and the endless overworld.**
    - *Principles:* P35 (p. 348) and p. 374 ("Landscapes packed with similar features, such as
      forests"), p. 375 (landmarks, maps).
    - *What to do:* the overworld has roads and plateaus. Add landmarks or signposts and a map, so
      the endless world doesn't feel empty or confusing. Keep the most interesting content near
      the village (small and packed with things to do).

23. **LOW: horses and fast travel when added.**
    - *Principles:* P17, P18 (pp. 394–395).
    - *What to do:* keep travel physical, with goods carried and at risk. No teleporting with
      cargo, because it would erase the distance pricing the owner wants (B14 local-availability
      pricing). Horses are fine; they are Bartle's "faster but not immediate" (p. 375).

24. **LOW: ownership of mixed and stolen goods.**
    - *Principle:* P40 (pp. 454–455).
    - *Already done:* stolen pieces are marked; fines scale with value.
    - *What to do:* decide and write down whether bread baked from stolen wheat, or coins from
      selling stolen goods, carry the mark. Recommend: marks do not pass through crafting or into
      coins (fungible), and record that as a rule, so guards questioning sellers stays consistent.

25. **LOW: fire.**
    - *Principle:* P44 (p. 452).
    - If the fireball or campfires ever ignite terrain, do not let fire spread to buildings or
      forests without strict limits. Otherwise arson becomes the cheapest way to wreck the
      economy and the ecology.

---

## 4. Warnings and failure modes the game risks

1. **Runaway currency.**
   - Build 7 showed 12-fold growth in a year, with no sink but imports. The B7-014 ceiling cuts it
     to about 3.4-fold, but the ceiling only throttles the *caravan's* faucet.
   - A player selling endless overworld goods to NPCs pulls village coins toward the player rather
     than creating them. That concentrates wealth, and NPC traders go insolvent: Build 7 already
     had tanners and goods merchants at 0 coins.
2. **A closed currency stalls.** The owner's "nothing comes from nowhere" can push toward a fully
   closed system. The project already tried one and it stalled the village (14,000 missed meals,
   3 deaths). This is Bartle's p. 399 "grinding halt", confirmed in the game's own data. Keep the
   managed open model (P3).
3. **Hoarding.** Farmers held 14,495 wheat. The treasury and the richest households held idle
   coins. Hoards without risk or decay take money and goods out of circulation, which causes
   missed meals next to plenty (Build 7 failure #5) and relief despite plenty (#11).
4. **Goods inflation.** Tools, clothes and armour that never wear out or wear out too slowly, and
   regrowing generators, mean items lose meaning ("+1 sword", P9). The rotten apple and spoiled
   meat are the only decay.
5. **Fixed anchors under inflation.** Constant wages and rents and fixed base values with bounded
   price multipliers make land, labour and goods relatively cheaper as coins grow. That drifts
   toward "everyone can afford everything" for the player by mid-game.
6. **The player as monopolist or cartel.** With deep pockets and patience the player can corner a
   good, undercut an NPC trade until it collapses, or starve the smith of ore. The world must
   recover when the player stops (succession and job return), or the village is permanently
   broken by one choice.
7. **Exploit loops from local pricing.** Buy where many sellers sit, sell where there are few. If
   NPC buyers' offers don't respond to the player's selling, the loop pays without limit. Test it
   (item 8).
8. **Duplication.** Coins and stacks, through save/load in the middle of a transaction, chunk
   unloading, NPC tier transitions, generators (plants, boulders, livestock products) and
   inheritance splits. Conservation tests exist; extend them to these edges.
9. **An over-smoothed market.** If local-supply pricing and NPC entry react instantly, player
   entrepreneurship never pays (P21) and the economy feels pointless.
10. **The tailor problem.** Player-crafted goods nobody buys, with no visible reason, read as "the
    game cheated me" (P20). Supply the information (item 14) rather than guaranteed buyers.
11. **Chores.** Hunger, firewood every night and feeding animals can turn into upkeep players
    would script away (P31). Keep each tied to an interesting choice, or offer paid convenience.
12. **Asymmetric perks.** Player-only saplings, the overworld faucet, the fireball and any healing
    only the player can afford quietly break "the player lives under the same rules" (P16, P43).
13. **The "data says they do it" trap.** Long-run sims measure what agents do. Whether players
    enjoy the loops needs playtesting (P41).

---

## 5. Not applicable (single-player, or out of scope)

- Live teams, actors, referees, storytellers and GM events (pp. 338–341); non-player players and
  gods for staff (pp. 419–421).
- Rooms-per-player ratios, crowding, flood-control areas and meeting other players (pp. 347–349);
  partitioning the map to cluster players (p. 359).
- Real-money trade and selling items for cash (pp. 354–355).
- Players quitting for another world as the "real" free market (pp. 402–405). The single-player
  version is player boredom, covered by items 13 and 14.
- Player committees running the "nerf knob" (p. 412); secure player-to-player trade windows and
  long-distance player trading (pp. 409–411).
- Alignment and voting (pp. 345–346); gender and race categories (pp. 342–344). There are no
  player races in MML.
- Text-world command parsing, absolute and relative direction commands, abbreviations
  (pp. 370–372); communication command types (pp. 430–431); multiple inheritance and the OOP
  digression (pp. 434–437).
- Fluid miscibility, gases and plasmas in detail (pp. 447–452). Liquids such as milk and ale are
  simple stack items in MML.
- Charging for advancement (p. 417). Bartle himself dislikes it, and MML's skills grow by use.
- Multiple currencies (p. 414). One village with one coin; reconsider only if other settlements
  are added (design doc phase E).
- Ecology chapter material: **not in this file** (it ends at p. 455). Review it from the next part.

Some items above say "not applicable" only to today's single-player builds. The ones that come
back with multiplayer are in section 6.

---

## 6. For the future player-hosted multiplayer (3–4 players)

The owner has confirmed player-hosted multiplayer for about 3–4 players, with no always-on server
(GAME_DESIGN Confirmed 10; DECISIONS 2026-10-17). It is not built yet. The items below are what
Bartle's multiplayer advice means for a small co-op world: one shared economy, players trading with
each other, and exploits between players. The host's machine holds the authoritative world; the
design doc §12 already prefers host authority.

| # | Priority | System | Item | Principle (page) |
|---|---|---|---|---|
| M1 | HIGH | Netcode / economy | **Only the host creates or destroys coins and items.** Clients send requests; the host validates and applies every transfer atomically. Extend the coin and item conservation tests (sections 3.11–3.12) to run with 2–4 simulated clients, including a client disconnecting mid-trade and the host saving mid-trade. Coins are the classic duplication target, and multiplayer adds new paths for it. | "stackable objects (such as coins) are their weakest point." (409 fn 67); duping in Asheron's Call (409) |
| M2 | HIGH | Trade | **Secure player-to-player trade window** (both sides confirm, then one atomic swap). It is not very immersive, but players accept it, and it makes trade more likely. Keep services (escort, guarding) as informal agreements; the game cannot enforce them. | "The easier it is to trade, the more likely players are to engage in trade." (410); "There will always be unsecure trading" (410) |
| M3 | HIGH | Economy balance | **Re-tune the faucets per player.** 3–4 players gathering from the endless overworld multiply the player faucet of section 3.9 by up to 4×. Scale the caravan allowance and ceiling and the sinks with the number of *active* characters, not just villagers, and rerun the long-run report with 1, 2 and 4 scripted players. | P1–P3 (353–354); ceiling pegged to the number of players: "This may be pegged to some indicator—for example, the total number of players." (352 fn 18) |
| M4 | HIGH | Economy / griefing | **Bakery wars and cartels between players.** One rich player can undercut another player's shop or corner a good (all bread, all ore) that the others need. Make sure NPC suppliers, the caravan and substitutes (section 3.16) always give the others an alternative, and that price bounds (`price_max`) cap what a cartel can charge. | P19 (403); bakery wars (402–403); multiple resources for the same use (416) |
| M5 | HIGH | Law / social | **Checks and balances on power over other players.** Theft from another player's chests and shop, killing their character (permadeath with heirs!), lockpicking their homes, bandit play against friends. Give each one consequences and protections the host can set (for example, a "friendly world" setting that turns off theft from players and attacks on them, or guards and witnesses that apply equally to players). | "Always have checks and balances." (320) |
| M6 | HIGH | Ownership | **Explicit `owned_by` on every item, chest, building and animal in a shared world.** "You own what you carry" fails when several players store goods side by side. Define the rules for goods left on the ground, goods in shared buildings, and mixed or crafted results (whose bread from whose wheat). Decide this before multiplayer saves exist. | P40 (454–455) |
| M7 | MEDIUM | Persistence / time | **What happens when a guest is offline.** The world runs only while the host plays; a guest's character must not starve, be robbed or lose their shop while away. Options: the character is absent ("travelling") while its player is offline; or a support fee charged on return for upkeep while away. | Charge for abstraction / support fee (418–419); travel while offline as "slow portals" (375) |
| M8 | MEDIUM | Saves / rollback | **A reload undoes everyone's progress.** Single-player save-scumming becomes a social problem. Keep autosave and permadeath rules host-controlled, and consider per-player backups of their character's inventory on the host only. | "a restart for one player means a restart for all of them." (336) |
| M9 | MEDIUM | Economy | **Keep a profit window with several traders.** More players means bandwagons arrive faster; local-supply pricing will squeeze margins quickly. Watch that a second player entering a trade doesn't make it worthless for both. | P21, P22 (411); "honest day's pay" (405) |
| M10 | MEDIUM | Economy / trust | **Host-adjustable economy levers must be visible.** Tax rate, caravan allowance and prices changing without explanation look like the host (or the game) favouring someone. Show the rules and announce changes in-world (the reeve, a notice board). | P23 (412) |
| M11 | MEDIUM | Griefing | **Fire and destruction.** In multiplayer, spreading fire or tree felling around another player's home becomes griefing. Keep fire contained and restrict changes to land another player owns or leases. | P44 (452); "One person's self-expression can be someone else's" (327) |
| M12 | MEDIUM | Economy | **A closed economy plus a hoarding player stalls everyone.** One player sitting on a large coin hoard can starve a small village of money. The managed open model, sinks the player enjoys, and theft risk to hoards (sections 3.3 and 3.7) matter more with several players. | "deliberately save money just to watch the whole" edifice tumble (399–400); P28 (400 fn 59) |
| M13 | LOW | Travel | **No teleporting between players or to each other's homes with cargo.** It would erase distance pricing (section 3.23). Meeting at a shared spot or travelling together keeps the map meaningful. | P18 (394); teleports make "a collection of virtual sub-worlds" (375) |
| M14 | LOW | Settlements | **Player-built houses and workshops in a shared village** strongly keep players coming back. Staff them by economics (NPCs move where business is), not with NPCs that simply appear, and let player-made places thrive or decline by their economic role. | P36–P38 (378–380); player-built settlements "too powerful a retention tool to dismiss" (379) |
| M15 | LOW | Community | **Co-op complaints become blame.** When one player's choices (hunting out the wolves, cornering ore) hurt another's trade, the game should show causes in-world (debug "why" view, market board) so blame lands on the in-world situation, not the game. | "Telling players that the miserable time they're having is all their own fault will not endear you to them." (406) |

Bartle's "players quit for another world" (pp. 402–405) is still mostly not applicable with 3–4
friends. Its small-group version is one player stopping because the others captured every
profitable trade (M4, M9).
