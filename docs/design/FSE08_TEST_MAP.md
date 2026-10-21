# FSE-08: the food-security directive's 25 required tests, mapped

Owner directive of 2026-10-20 (`docs/directives/2026-10-20_food_security_goal_driven_economy.md` section 17). FSE-08's
acceptance: each of the 25 is mapped to an existing test, a new test for an implemented system, or the build whose
feature it needs. Test names are `file::function` under `game/tests/`; every file named runs in CI (`tests.yml`).

| # | Required test | Covered by | Status |
|---|---|---|---|
| 1 | One villager's annual food consumption | `run_tests::test_food_rules` (meals and hunger), `reserve_test::scenarios` (a household's food days); annual totals measured by `economy_sim` (food ledger) | Covered |
| 2 | Productive land required per villager | FSE-15 (recalculate the land requirement), Worker A of the Build 16 push | Build 16, in progress |
| 3 | Crop planting, growth and harvest | `farming_test::test_crops`, `world_test::_fse12_shared_fields`, `world_test::_fse13_seasonal_fields` | Covered |
| 4 | Seed retention and consumption | `farming_test::test_household_seed`, `farming_test::test_propagation`, `world_test::_fse12_shared_fields` (seed sown and returned) | Covered |
| 5 | Failed harvests | No crop-failure mechanic exists and no register entry asks for one. A field left unsown for want of seed is counted (`field_unsown_no_seed`) | **Owner question**: is crop failure (weather, blight) wanted, and in which build? Not invented here |
| 6 | Non-farmers growing food | FARM-03/FARM-04 (family plots, household labour), Worker A; `farming_test::test_crops` covers the player, a non-farmer | Build 16, in progress |
| 7 | Land rental and rent payments | `property_test::test_rules`, `business_test::_rent` / `_rent_daily`; farmland leases FARM-01/FARM-07, Worker A | Covered for houses and stalls; farmland in progress |
| 8 | Livestock acquisition, care, reproduction and production | `farming_test::test_pens_and_animals`, `aging_test::test_animals`; the cattle investigation FARM-08B | Covered; FARM-08B open |
| 9 | Non-hunters hunting for food | Goal-driven choice of activity: FSE-10, moved to the standalone Living Economy build (MILE-01, EXP-D) | Later build |
| 10 | Hunting pressure on wildlife populations | `refuge_test::test_overhunt_and_recolonize`, `wildlife_test::test_hunting` | Covered |
| 11 | Households buying food when it is economically attractive | FSE-10 (Living Economy build) | Later build |
| 12 | Households producing food when market prices rise | FSE-10 (Living Economy build) | Later build |
| 13 | Producing food despite low prices, for personal goals | FSE-10 (Living Economy build) | Later build |
| 14 | Villagers saving money toward housing | `housing_test::test_saving_before_the_full_price`, `housing_test::test_crowding_is_a_goal` | Covered |
| 15 | Choosing paid work over self-production | FSE-10 (Living Economy build) | Later build |
| 16 | Multiple income streams | FSE-10 (Living Economy build) | Later build |
| 17 | Households selling surplus goods | `home_test::test_villager_storefront`, `farming_test::test_market`, `od16_test::test_caravan_buys_producers_surplus` | Covered |
| 18 | Market stalls transferring real goods and coins | `business_test::_attended_sales`; the stalls STALL-01..06, Worker B (`stalls_test`) | Covered for existing stalls; new stalls in progress |
| 19 | Retaining food or seed instead of selling everything | `reserve_test::scenarios` (OD-19 reserve), `farming_test::test_household_seed` | Covered |
| 20 | Different choices under similar market conditions | FSE-10 (Living Economy build) | Later build |
| 21 | Financial reserves responding to production and goals | `reserve_test::scenarios`, `world_test::_par02_reserve` (PAR-02A dynamic reserve) | Covered for production; goals with FSE-10 |
| 22 | Experience outside the primary occupation | `parity_test::test_careers_and_incidental_experience` | Covered |
| 23 | No simultaneous impossible labour allocation | `world_test::_station_conflict` (one user a station), `world_test::_ctr01_counters` (a keeper puts down work to serve) | Covered |
| 24 | No unexplained creation or destruction of goods or coins | `conservation_test`, the `economy_sim` ledger (every Actions run fails on a leak), `tools/sim_gate.py` | Covered |
| 25 | Player and NPC through the same systems | `parity_test` (skills, recipes, trade), `world_test::_par02_reserve`, `_par03_rest`, `_par05_awareness` | Covered |

**Summary:** 13 covered (1, 3, 4, 8, 10, 14, 17, 19, 21, 22, 23, 24, 25); 4 in progress in Build 16 (2, 6, 7 for
farmland, 18 for the new stalls); 7 belonging to the goal-driven economy that the owner placed in the Living Economy
build (9, 11, 12, 13, 15, 16, 20); 1 owner question (5).
