# Build 18 decision package, 2026-10-23

Requested by the owner (`docs/directives/2026-10-23_rel18_device_and_decision_package.md`): every remaining owner-level
blocker for Build 18 in one place. Each item: (1) approved intent, (2) the unresolved issue, (3) recommendation,
(4) alternatives that change gameplay, (5) what it unblocks. Decision ids B18-DP-01..14 are in the register. No approved
decision is reopened; a recommendation is not an approval.

Answer in any form, e.g. "DP-01 recommended, DP-05 alternative B, DP-07 recommended".

## A. The eight items without a settled design

### B18-DP-01 · PL1-10 Player businesses, staged
1. **Intent:** (BUILD_11_PUNCH_LIST_1, owner) "(1) rentable stall … (2) NPCs buy only for real modelled needs … (3) larger
   stalls, shops, equipment placement; (4) attendants, production chains".
2. **Issue:** stages 1-4 are built and verified except three parts an agent deferred: production chains in stage 4, a stall
   display sprite, and shops in rented village houses. These are in the approved text, so they cannot be dropped silently.
3. **Recommendation:** finish them with existing systems:
   - production chains: the player's hired attendant works the player's own workshop stations with the existing recipes
     and the existing attendant wage, and stocks the stall;
   - the stall shows its goods with the existing item icons;
   - a player may lease a village house and open it as a shop by the existing lease and storefront rules (B14-3).
   Effort M.
4. **Alternatives:** (A) production chains by attendants only; display and house shops after Build 18, by your explicit
   acceptance. (B) Production chains also run while the player is away (more automation, a bigger economy effect).
5. **Unblocks:** PL1-10.

### B18-DP-02 · PL2-008 Expandable property and B18-DP-03 · PL2-014 Modular house/workshop expansion
1. **Intent:** (PL2-008) "start with a house or basic structure and add facilities to the same plot over time, without
   demolishing"; (PL2-014) "connected additions (carpentry, smithy, kitchen, bakery, apothecary, storage, living quarters)
   with walls, doors, roofs, navigation and working stations; mixed use … no profession lock-in".
2. **Issue:** the build is integrated; the record's only open question (inner doorways, survey plots) was answered by you on
   2026-10-23 and built as ROOMS-18 ("doorways plus relaid plots"). Not done: villager households add no modules (they
   split instead), and modules have no sign of their own. Neither is in the approved text.
3. **Recommendation:** treat ROOMS-18 as the answer to the open question; close both when the playtest confirms them.
   Villager-built modules and module signs are not part of these records (clarification, not new scope). Effort XS.
4. **Alternative:** (A) villagers also add modules to their own houses (a new behaviour; M; changes how the village grows).
5. **Unblocks:** PL2-008, PL2-014.

### B18-DP-04 · PL2-015 Farming, livestock, hand plough
1. **Intent:** (owner) "clear and till … craftable hand plough … fences, pens, gates, coops, shelters; buy or trap animals,
   feed, water, breed, raise young; eggs, milk, wool, meat, hides … markets, later hired help".
2. **Issue:** the core loop and the plough are built; the horse plough was approved and built in Build 18. Deferred by an
   agent although in the text: coops and shelters, trapping, watering, buying animals. "Later hired help" is your own
   word "later". Three questions were left open: balance a player cell against wages; a Farming skill gating the work;
   taking bought seed from the sellers' stock.
3. **Recommendation:**
   - build the missing listed parts with existing systems: a coop or shelter as a roofed pen variant; rabbit trapping on
     the existing wildlife; animals drink from the existing troughs; buy animals from the settlements' herds and farms
     through the traders (REG-BUY-01);
   - the open questions: no rebalancing (your rule); the Farming skill speeds work but never gates it, the existing
     skill convention; bought seed comes from the seller's real stock (conservation, WDR-022);
   - "hired help" stays later, as you wrote; please confirm that it is not Build 18.
   Effort L.
4. **Alternatives:** (A) bought seed stays a standing offer (not from stock). (B) Hired farmhands in Build 18 (L, a new labour
   relation).
5. **Unblocks:** PL2-015.

### B18-DP-05 · SET-D Settlement development
1. **Intent:** (Settlement Advancement spec, phase D) "Growth/decline, specialization, housing, infrastructure, population
   and employment", verified by "multi-generation simulations across settlement types"; REG-DEMO-D1: no arbitrary cap,
   housing and other systems "as those systems become available".
2. **Issue:** most of phase D now exists in the five (births and deaths, households forming, job moves, capability
   levels). No rule yet for a settlement gaining or losing businesses and infrastructure.
3. **Recommendation:** at lighter detail, with existing rules only:
   - a household moves into a trade with lasting unmet demand by the existing switch rule, and a trade with no worker
     closes;
   - a business's capacity follows its workers;
   - no housing model off the map yet (REG-DEMO-D1);
   - close phase D with a multi-generation run of all five (365 days).
   Effort M.
4. **Alternatives:** (A) add an off-map housing stock that limits household formation (a new mechanic; L). (B) You accept
   SET-D as a later expansion phase (it would be your explicit decision, recorded).
5. **Unblocks:** SET-D (and REG-EVAL-01 evidence).

### B18-DP-06 · WDR-004-C Economic Consequences (World Design Rule 4)
1. **Intent:** "Supply, shortages, production and trade must influence prices, availability, jobs and behavior";
   verification: "Compare 100- and 365-day simulations, including wealth, jobs, supplies and trade".
2. **Issue:** not a design gap: the rule and its test are defined. Remaining: the comparison runs and an audit of scarcity
   responses.
3. **Recommendation:** close it with the Build 18 long runs (REL18-LONGRUN, read at 100 and 365 days) and a written
   scarcity-response audit; no new mechanic. Effort S, done by me.
4. **Alternatives:** none that change gameplay.
5. **Unblocks:** WDR-004-C.

### B18-DP-07 · WDR-011-C NPC Self-Improvement and Prosperity (World Design Rule 11)
1. **Intent:** "Track five aspiration domains: food/security, money/wealth, goods/property, professional growth, and
   family/household development … Priorities must change after successes and setbacks … Link ambitions to actual purchases,
   production, relationships, housing, inheritance and employment."
2. **Issue:** no aspiration model exists. Build 19's judgment engine (SJD, personality) is the natural home of personality,
   but WDR-011-C is assigned to Build 18.
3. **Recommendation:** a light Build 18 model, with no personality engine:
   - each villager weights the five domains from their real state: food from the necessity reserve, wealth from coins
     above the reserve, property from home and lease, profession from skills and job, family from partner and children;
   - the weights move after events: death, illness, marriage, a good season;
   - they steer only existing choices: saving or spending, seeking a better job, building or leasing, marrying;
   - its verification scenario as a test.
   Build 19 later replaces the weights with personality. Effort L.
4. **Alternatives:** (A) you move WDR-011-C to Build 19 with the judgment engine (your explicit decision). (B) A fuller
   aspiration model now (XL).
5. **Unblocks:** WDR-011-C.

### B18-DP-08 · WDR-012-C NPC Competition and Economic Rivalry (World Design Rule 12)
1. **Intent:** compete "for employment, customers, workers, materials, land, property, contracts"; respond "through pricing,
   specialization, expansion, relocation, hiring or business failure"; the player gets no preference.
2. **Issue:** pricing competition and business failure exist; specialization, relocation and hiring competition do not.
3. **Recommendation:**
   - specialization: a craftsman favours the recipes that sell best at the local prices;
   - hiring competition: employers short of labour raise the wage they offer, within the existing wage rules, to win
     workers;
   - relocation: a failing stall moves to a free stall with more passers-by;
   - its verification test.
   Effort M.
4. **Alternative:** (A) hiring competition and specialization only; relocation later, by your explicit acceptance.
5. **Unblocks:** WDR-012-C.

## B. The stone values

### B18-DP-09 · STONE-D1 Dressing efficiency by skill and the materials numbers
1. **Intent:** (STONE-Q2, owner) "Less experienced workers produce more waste. More experienced workers recover a greater
   proportion … The same mechanics apply to players … Occupation titles do not grant automatic production bonuses."
   (STONE-Q1) materials match the work: raw stone for rough work, blocks for structural masonry, mixed for mixed jobs.
   STONE-03: "Where the existing system cannot distinguish ordinary maintenance from major structural reconstruction,
   retain the current functioning behavior".
2. **Issue:** the waste numbers, and the block/stone split per kind of work.
3. **Recommendation:**
   - dressing becomes 3 raw stone into 2 blocks plus 1 rubble at Masonry level 1, conserved: the rubble is raw stone
     fragments, usable where raw stone is (STONE-Q1);
   - skill then works through the existing Masonry tiers (save_chance 0.15 at level 5 and 0.25 at level 9; bonus_chance
     0.1 at 7 and 0.2 at 10), the same convention as every craft, so a master wastes little;
   - Masonry is the dedicated Stoneworking skill (STONE-Q3). It already starts from Crafting experience, so the starting
     levels and migration credit are settled;
   - materials: keep today's building costs where the game cannot tell maintenance from reconstruction (STONE-03 says so),
     with blocks for new stone buildings and raw stone for repairs and hearths.
4. **Alternatives:** (A) a per-level waste curve (level 1 loses a third of the stone, level 10 none). Steeper early, and a
   new table. (B) Waste is lost entirely, with no rubble (simpler, less conserved material).
5. **Unblocks:** STONE-02, STONE-03, STONE-04, X18-STONECUT (with DP-10).

### B18-DP-10 · STONE-D2 The iron chisel
1. **Intent:** (STONE-Q3, owner) dressing needs "a mallet" and "an iron chisel … a real, physically conserved inventory item.
   Blacksmiths manufacture chisels using the existing smithing and production systems … Do not invent a permanent chisel
   durability value, wear rate, production recipe quantity, or market price without first checking existing conventions
   and obtaining owner approval".
2. **Issue:** the chisel's recipe, durability and value.
3. **Recommendation (from existing conventions):**
   - recipe: `forge_chisel` at the anvil, 1 iron bar, 30 minutes, Smithing level 1 (as the hammer, but no haft);
   - durability: 150 dressings, the mallet's;
   - one use worn per dressing, like other tools;
   - Masonry's wear saving follows the existing tool_wear_save convention only if Masonry gains it (it does not today:
     no wear saving);
   - value: by the existing value rule for forged tools, about the hammer's.
4. **Alternative:** (A) a sturdier chisel (400, the hammer's durability): fewer chisels bought, a smaller smith trade.
5. **Unblocks:** STONE-02, STONE-06, X18-STONECUT (with DP-09).

### B18-DP-15 · WDR-002-C The sage supplies no other profession (added 2026-10-23, from the close-out audit)
1. **Intent:** World Design Rule 2, Professional Interdependency (owner's rules): every profession depends on others and supplies others.
2. **Issue:** nine of ten production professions pass; the sage (medicines) supplies nobody but end users (`tools/check_materials.py`: supplies_nobody). Fixing it needs another trade to genuinely depend on the sage's goods, which is a gameplay change.
3. **Recommendation:** the guards keep healing goods bought from the sage (a poultice or tonic per guard, replaced when used in a fight), using the existing medicine items and guard wages; no new numbers beyond the stock kept (one per guard).
4. **Alternatives:** (A) the tavernkeeper or cook buys herbs or tonics from the sage; (B) record the sage as a deliberate exception in `docs/systems/material_exceptions.json` (healers serve people, not trades).
5. **Unblocks:** WDR-002-C.

### B18-DP-16 · ECON-P3 scope: "quotes follow money, stock days, market hire wages" (added 2026-10-23)
1. **Intent:** the owner's answer (`docs/directives/2026-10-23_owner_answers_caravan_purses_skills.md`): "Business and household money separate: a shop has its own till, the owner pays themselves from it, and may choose to move money". Built and merged (749c7df).
2. **Issue:** the ECON-P3 record's title also carries P3.2-P3.4 from an agent proposal (`docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md` lines 183-187): prices quoted from the buyer's money, stock targets in days of sales, and hire wages from market quotes (an employer share of 0.35). The owner's answer did not mention them.
3. **Recommendation:** treat them as unapproved proposals: split them out of ECON-P3 into proposal records (Build 20 living economy, where wages and market behaviour are your open decisions OD-LE-02/03), and close ECON-P3 on the separation of money.
4. **Alternative:** (A) approve them for Build 18 (larger market and balance changes; M-L, and a fresh round of economic runs).
5. **Unblocks:** ECON-P3's closure.

## C. Other owner-level items for Build 18

### B18-DP-11 · CHAPEL-R5 Chapel artwork before release
1. **Intent:** chapel and clergy (owner, 2026-10-23); no art requirement was stated.
2. **Issue:** the chapel uses Shade's small-house art, with no steeple or sign. Is distinct art a Build 18 release
   requirement?
3. **Recommendation:** not a release blocker. Add a sign or a bell-cote from an owned pack if one fits (asset pipeline),
   otherwise ship as is.
4. **Alternative:** (A) distinct chapel art required for Build 18 (an art search; may need a new pack).
5. **Unblocks:** closes CHAPEL-R5 and the chapel record's art question.

### B18-DP-12 · CHAPEL-R1 Player volunteering on the church field
1. **Intent:** villagers volunteer on the church plot; the player and NPCs follow the same rules (parity).
2. **Issue:** the player cannot volunteer.
3. **Recommendation:** allow it by the same rule as villagers (parity). Effort S.
4. **Alternative:** (A) villagers only.
5. **Unblocks:** CHAPEL-R1.

CHAPEL-R2 (can offerings pay the clergy) is answered by the long-run evidence, not by a decision. CHAPEL-R3 (old saves
losing wild plants) and CHAPEL-R4 (ore layout) are engineering checks I will settle under CLAUDE.md sections 6 and 7: a
saved world must not change, and new worlds may.

### B18-DP-13 · X18-FEES and CON-08-Q Courier fees and the signing threshold
1. **Intent:** Q18-12 and Q18-13 approved; the fee coefficients and the 50-coin formal-signing threshold are provisional
   working defaults.
2. **Issue:** confirm the defaults for Build 18, or set your own.
3. **Recommendation:** ship the provisional defaults as Build 18 values; revisit after playtesting.
4. **Alternative:** you set different numbers now.
5. **Unblocks:** X18-Q12, X18-Q13 and REG-COURIER-01 closing without open numbers.

### B18-DP-14 · Q18-6 Settlements developing different profiles
1. **Intent:** Q18-3 (owner): each settlement is a simulated economy under the same rules.
2. **Issue:** Q18-6 was recorded as my reading ("settled by Q18-3"), not your answer.
3. **Recommendation:** confirm the reading: settlements differ because their resources, trades and people differ.
4. **Alternative:** none.
5. **Unblocks:** Q18-6.

Q18-11 (capability pay and output factors) was held back until the X18-SIM report; it is now B18-DP-19 below.

## Added after the Build 18 integration (2026-10-23)

### B18-DP-17 · STONECUT-R1 The stonecutter under Rule 002 (blocks WDR-002-C closing)
1. **Intent:** X18-STONECUT (approved): a professional stonecutter dresses and sells building blocks. WDR-002: every
   profession depends on and supplies others; B18-DP-15 approved a documented, evidence-checked exception for the sage.
2. **Issue:** the stonecutter's blocks (and rubble) are bought by the raw-goods merchant and built into houses and
   workshops by households and the manor. The game has no builder trade, so the checker finds that the stonecutter
   "supplies nobody", as it did for the sage.
3. **Recommendation:** (A) the same treatment as the sage: a documented exception whose evidence the checker verifies
   (the code path, a test showing a household or the manor building with blocks bought from the stonecutter's trade, and
   the goods), with no global weakening. Effort S.
4. **Alternatives:** (B) make the labourer the builder trade that buys blocks for the sites it builds, which the checker
   would then count (a change to who buys construction materials; effort M); (C) leave the finding open and WDR-002-C
   unfinished in Build 18.
5. **Unblocks:** WDR-002-C closing.

### B18-DP-18 · COMP-R1 The hiring-competition wage ceiling (non-blocking)
1. **Intent:** B18-DP-08: employers short of labour may offer higher wages within the established wage system.
2. **Issue:** the manor's offer for an unfilled hand's place rises 1 coin after 3 unfilled mornings, at most 3 coins over
   the day wage (6 to 9), and eases back once filled. The ceiling and steps are provisional working values (no rule set
   one). Construction helpers and business attendants have no unfilled-place signal, so they do not compete yet.
3. **Recommendation:** keep the provisional values for Build 18 and revisit after playtesting; leave helpers and
   attendants as they are (EMP-PERM-01, Build 20, covers employment terms).
4. **Alternatives:** you set a different ceiling or tie it to local incomes; or extend the raise to helpers and attendants
   now (effort M).
5. **Unblocks:** nothing blocked; settles the provisional values.

### B18-DP-19 · Q18-11 Capability pay and output factors (non-blocking)
1. **Intent:** Q18-11: no permanent capability constants before your review of the simulations (X18-SIM).
2. **Issue:** the X18-SIM report is in (`docs/expansion18/CAPABILITY_SIMULATIONS_90DAY.md` on `wip/build18`, merged at b196303) but covers 9 of about 46
   planned runs; every factor is 1.0 (no effect) until you choose.
3. **Recommendation:** ship Build 18 with every factor at 1.0 and decide after a fuller simulation set.
4. **Alternative:** adopt the report's per-industry recommendation now, as provisional values.
5. **Unblocks:** nothing blocked; Q18-11 stays PROVISIONAL either way.
