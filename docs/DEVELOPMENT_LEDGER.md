# Development ledger: the requirements register

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`; do not edit.
The register is the one manually maintained list (schema: `docs/requirements/SCHEMA.md`); progress by build is in
`docs/requirements/views/STATUS.md`. Proposals, ideas and open owner decisions are never counted as approved work.

## Approved requirement (595)

| ID | Item | Build | Approval | Implementation | Verification | Release | Completion |
|---|---|---|---|---|---|---|---|
| AR-OWNER | Audit remediation owner checklist: public-release environment, repository visibility, private infrastructure repository | owner action | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| AR-P0-1 | Fixed `21647e2` |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| AR-P0-2 | Assessed; remediation needs owner |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| AR-P0-3 | Owner must delete `inventory/registry` by hand | owner action | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| AR-P1-1 | Prepared; owner must create key |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| AR-P1-2 | Fixed on staging; PR #1 branch still has push-triggered workflow | owner action | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a place, stock, a path, and trades with the player (the owner's playtest: never available) | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| ARMOR-01 | Armour is acquired in play, physical, and visible when worn | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| B12A-01 | 1-11 fixed (B13-01..10); 12 → B13-14 |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B12A-02 | Fixed (WHAT_WAS_DONE:135) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B12A-03 | Fixed / one withdrawn (addendum :1631) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B12A-04 | Not recorded as done |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B12A-06 | Sword page added by CQ-01 (`3e283b6`); others not recorded |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B12A-07 | Art blockers: crop stages, tool swings, sitting poses, chimney, sawhorse (Craftpix crops could supply crop art, B14-10) | 20+ | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| B12A-08 | Deferred features from the Build 12 audit (umbrella; each child item tracked on its own) | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B12A-09 | RTK token tool persistence in the cloud environment (owner action) |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B12A-10 | Hardware verification of everything on real devices (umbrella of the device queue) | owner action | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B12A-11 | "Not investigated further" |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B13-01 | Retirement opens no post |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-02 | Gold ore has no source |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-03 | Medicine effect text |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-04 | Attendant hired as carrier |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-05 | health_jobs_test in CI; always-true checks |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-06 | Rule 1: no purchase without money |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-07 | Rule 2: bulk prices per unit |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-08 | Rule 3: seed from real stock |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-09 | Rule 4: theft by items/value |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-10 | Stale text and documents |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-11 | Livestock production chain |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-12 | B closes only quantity selector | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B13-13 | Touch sprint | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B13-14 | Station occupancy |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B13-15 | Android signing stability | owner decision | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager beside it | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B14-02 | Villagers' home production: forage, brew poultices, treat their own wounds |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-03 | House storefronts (player and villager households) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-04 | Cart parts and handcarts |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-05 | Local-availability pricing |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, household market runs | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B14-07 | Cliff steps (pickaxe, Mining), wooden stairs and walkways (planks, nails, Carpentry, a mallet) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B14-08 | Forest animals (MiniFolks): grazers, predators, fox raids, fights |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-09 | Skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| B14-10 | Craftpix farm plants: crop stages, produce, crates, fruit trees chopped like the others | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| B14-11 | Animal Farm pack: the horse and farm animals | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| B14-12 | Sprite list with pixel-grid copies for Aseprite (missing and weak sprites) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14-13 | A controller connected to a phone or tablet hides the touch buttons and uses the pad controls | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B14R-01 | Record completed 100-day economy simulations (start, seeds, currency, wealth, jobs, trade, resources, food, population, shortages, regressions) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14R-02 | Compare the manor reserve and the caravan money limit (four configurations) and recommend |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-03 | Investigate iron and coal running out by day 10; document sustainable alternatives without changing the resource model |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-04 | Build 14 tester notes |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-05 | Identify the Build 14 candidate commit and ask the owner for build approval |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14R-06 | Permanent requirements register, lifecycle, validation, silent-deletion detection, startup and handoff rules |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14R-07 | Second historical requirements recovery pass and coverage report |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-08 | Reconcile the original 16 World Design Rules (restore text if the source is found) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-09 | Stable Android test-signing procedure documented (credentials, secrets, setup, key preservation, risks, install and update test) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-10 | Separate real-device verification queue (phone, controller, Windows, cross-platform and two-device LAN) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B14R-11 | Review draft PR #1 for unique content before recommending closure |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B14R-12 | Long-run regression: wild animals reach 0 by day 320 and the population falls from 100 to 69 in the 365-day run | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B16-AUDIT | Build 16 complete status audit, maintained (docs/BUILD_16_STATUS.md) | 16 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| B16-READY | Build 16 development audit and release-readiness report | 16 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| B18-DIR | Build 18 master integration directive (visual polish, character customization, armour, crop sharing) | 18 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| B7-001 | Starting coins | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-002 | Quest rewards reserved |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B7-003 | Jewellery/helmets have buyers |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B7-004 | Harvest-work wheat theft |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B7-005 | Earning money discoverable; "Trade with" | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-006 | Hired work pays poorly (mine shift 8 for ore worth ~18; axe needed) | 17 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B7-007 | Deposits never refill; no stone source | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-008 | Player can drain buyers to 0, kill all wildlife | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B7-009 | Treasury starts below reserve; no paid manor work until ~day 12 | 15 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| B7-010 | HUD anchoring on Android | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-011 | Tapping trees/ore does nothing | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-012 | Gather mode | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-013 | Brown glyph icons | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B7-014 | Caravan grows currency ~12x a year | 15 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| B7-015 | Missed meals while food piles up | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| B7-016 | Tanners/goods merchants end at 0 coins | 16 | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| B7-017 | No building in a year (no births) |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B8-001 | (earlier fix) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-002 | Village pasted over terrain |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-003 | Floating/partial trees |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-004 | Broken mining area |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-005 | Tree collision/transparency |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-006 | Harvest animation never stops |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-007 | Wrong tool shown | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| B8-008 | Deposits misidentified |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-009 | Collection notices need icons |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-010 | Inventory blocked during harvest |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-011 | No cancel |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-012 | Oversized inventory highlights |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-013 | Oversized prompts |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-014 | NPC blocks a workstation |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-015 | Weapon racks |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-016 | Essential trade succession |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-017 | Personal chests in public rows |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-018 | Roof flicker indoors | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| B8-019 | Unclear HUD |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-020 | Death cause |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-025 | Player clipped behind tabletops |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-026 | Grey boulders not minable |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-027 | Sprint |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-028 | Sawmill |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8-029 | Calendar, aging, families, animal life cycles |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-001 | Pad cannot reach Wear/Drop |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-002 | Trapped inside a door |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-003 | Trapped between trees |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-004 | Sage's hut door off by one |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-005 | Hunger icon looked like coin bag |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B8R-006 | Where to cook raw meat |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| B8R-007 | Overlapping house edges |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-008 | Family name signs at houses |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-009 | Trading skill never gains XP |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-010 | Pickpocketing children allowed |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-011 | Map border; large world |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-012 | Hit feedback |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-013 | Cow attack shows no damage |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-014 | Pad cycles all buttons |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-015 | Flowers pickable/walkable |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-016 | Berry bushes pickable |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-017 | Field half-plants at edges |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-018 | Villagers swing tools idly |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-019 | Building collision, interior nav, roof flicker |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| B8R-020 | Gathering banners fill phone screen |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| BANDIT-RETURN | Outlaws return: a season after the band is wiped out, 2-3 outlaws arrive from outside and camp in the woods | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| BARBER-01 | Barber service: change hairstyle in the village through the economy | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| CC-01 | Character creator replaces the eight preset looks (appearance only, civilian) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| CON-01 | Universal negotiated goods-procurement contracts (item, quantity, price per unit; accept, reject or counter; any party to any party) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CON-02 | Service contracts in the universal CON-01 engine (labour and services; player-NPC, NPC-player, NPC-NPC; terms, feasibility, real work through existing systems, payment from real funds, signing rules) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CON-02-KINDS | CON-02 unfinished service kinds: further labour and service contracts beyond dig and survey (e.g. work on the buyer's materials with existing recipes), tracked as open dependencies of the Build 17 approval | unassigned | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-03 | Restricted negotiated service advances (CON02-S-1) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-04 | Negotiated service compensation structures: work, results, base plus bonus (CON02-S-2) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-05 | Contract protections and dispute process before the local authority (CON02-S-3) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-06 | Agricultural labour contracts (CON02-S-4) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-07 | Independent villager service hiring across industries (CON02-S-5) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-08 | Separate formal-signing threshold for service contracts (CON02-S-6) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CON-UX-01 | Contract window needs design work | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| CQ-01 | Sword responsiveness and hit detection (buffer, reach, phases, walls) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-01 | Player courtship and marriage through gifts: attraction, dating, proposal that can be declined if too early | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-02 | Friendship: a Befriend option appears after help and gifts; no proposal needed | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-03 | Courtship between players in multiplayer (the other player may decline a proposal) | multiplayer | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| CRT-04 | Villagers court each other through gifts, dating and proposals by the player's rules, replacing the random pairing chance | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-05 | Gift tastes follow obvious things: a villager's trade and current needs; favourite gifts speed courting, traditional gifts always work | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-06 | Friendship benefits: better prices, help and favours, gossip and news, backing in disputes and votes | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-07 | Courtship and marriage between any two humans, same sex included; humans only for now | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-08 | Shared experiences start friendships and romances: working together and personal interactions build regard and attraction | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-09 | Weighting of closeness and conversation: proximity about 1 point, a conversation 0.25, later ones about 0.11, so talk spamming does little | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-10 | Relationship weighting system: closeness over time (the nearby-name prompt), many factors, distinct days known; no button spamming to a quick marriage | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-11 | Single villagers with spare money and goods actively seek company: spend time near the one they court or befriend, and buy gifts | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CRT-12 | Proposals can be refused: not wanting to marry, a rival suitor with a better offer, or the suitor's deeds (killing villagers, crimes, theft from their friends or family) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armorer, smith, carpenter, others as they develop) has a working customer counter | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeeper walks to the counter to serve | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summoned an available one comes, else the player is told clearly; employees or family may serve; no interrupted emergencies, no duplicate service tasks | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| CTR-04 | Permanent counters are not market stalls: no stall commission on counters without an approved rule | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A1 | Stale heir comment (:26) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| DVW-A10 | No black-hole spaces (:35) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| DVW-A11 | Threats never scale to player (:36) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| DVW-A12 | Keep rules in `core/`, not UI; audit list (:37) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| DVW-A13 | Every visible object has a use (:38) | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| DVW-A14 | Play one whole life before each release (:39) | 15 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| DVW-A2 | Rotate several dated save backups, not one `.bak` (:27) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A3 | Re-measure money supply, 100 and 365 days, 2-3 seeds, no player (:28) | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| DVW-A4 | Faucet and drain ledger for coins and each item (:29) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A5 | Exploit-player test (arbitrage, round trips, cornering, flooding) (:30) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A6 | Coins and goods conserved across save/load and tier transitions (:31) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A7 | Over-production from raising skills by use (:32) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A8 | Audit player-only perks vs same rules (:33) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| DVW-A9 | Player can always escape predators/bandits (:34) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | 19 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| DVW-B3 | Coin sinks people enjoy (luxury imports, feasts, weddings, offerings, heriot) | 18 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| DVW-B3-CHAPEL | Coin sink: offerings at a village chapel or shrine (a chapel building is needed) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| DVW-B3-FEAST | Coin sink: wedding feasts and seasonal feasts at the tavern, food and ale really bought and eaten | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| DVW-B3-LUX | Coin sink: luxury imports sold by the caravan for status | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| DVW-B4 | Goods decay (grain spoils, clothes/armour/carts wear) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| DVW-B5 | Predictable taxes with hysteresis, announced | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| DVW-B6 | Wildlife wandering in from the overworld | 18 | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DVW-B7 | Life chronicle, titles, memorial | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| DVW-B9 | Readable danger: howl/roar cues, lethal-need warnings, cause on succession screen | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| E20-P1 | Expansion 20 phase 1: LE-00 audit, requirements registration and isolated LE-01 foundation (no live economy) | 20 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| E22-OD-01 | Hybrid regional simulation: detailed nearby NPCs and abstract distant settlements that preserve individual identities, households, property, economic state and history | 22 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| E22-OD-02 | Continuous geography: streamed regions, persistent world coordinates, persistent player and NPC modifications | 22 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| E22-P1 | Expansion 22 phase 1: read-only audit of the Settlement Advancement specification against Build 18 (complete, partial, missing), Phases A-E dependency map, capability matrix, regional data model proposal, player views and diagnostics plan; no implementation | 22 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| E23-BANA | Expansion 23 BAN-A: existing-system audit and requirements reconciliation for bandit factions and criminal careers (Rule 016, the bandit roadmap); no criminal actions or faction behaviour | 23 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| EARTH-01 | Reuse of excavated earth: farmland improvement, road embankments, plot grading, defensive earthworks, landscaping (MIN-E-Q1) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| ECON-P1.3 | Caravan as finite regional market (:73) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| ECON-P3 | Household vs business money: a shop has its own till; the owner pays themselves from it and may choose to move money; World.spendable | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| EMP-CONTRACT-01 | Contracted services: the player negotiates a specific task or quantity (e.g. 50 iron ore) without employing the NPC, by existing contract conventions; real activity only | 20 | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| EMP-PERM-01 | Permanent employment by the player for production roles (miner at a mine, smith at a forge, carpenter, attendant, assigned production role) through the existing job-offer and wage systems, working on during normal simulation subject to real resources, equipment and wages | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| ENV-RTK | RTK token tool and its hook persistent in the cloud environment | owner action | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| EQ-01 | Human civilization sustains itself without the player | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-02 | Nature sustains itself: reproduction, aging, predation, competition, dispersal, habitat, local extinction, recolonization, recovery | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-03 | Humans and nature affect each other through real NPC decisions | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-04 | A functioning society survives individual losses (succession of trades, households, leadership, businesses) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-05 | The player is the disruptive variable: no hidden protection of the world from player consequences | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| EQ-06 | Build 16 acceptance simulations: multi-seed, player inactive, 100 and 365 days and generations, plus player-intervention scenarios | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-07 | Investigate and correct the 365-day failures: population 100 to 69, wildlife to zero, no houses built | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-08 | Births do not require a free bed; the crowding a birth causes is what drives a household to split and move | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-09 | Local stone deposits run out (day 160-190 in the Build 15 runs); verify that the owner-approved caravan stone (20 a visit once 10 or less remain) keeps house building supplied | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-10 | Economy simulation: axe and hammer ledger residuals of 1-3 from day 120 in 365-day runs | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-16 | World equilibrium: an untouched world stays viable across generations; the player is the disruptive variable | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-17 | Long simulations: a household that loses its house leaves an empty home id; births and members then raise script errors | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-18 | Tool recovery and essential trades over a year: job seekers can buy the trade tool where tools are sold (seek_work looked among timber sellers, so nobody without an axe became a woodcutter and the trade died out), and an essential trade left for other work opens its succession post (seed 2 had no smith from day 240) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-19 | The manor supports the essential trades from its treasury (OD-16 b): it keeps the smithy and the woodlands working by buying iron and tools for the village's workers, or lending to the smith against future output | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-20 | Bandit coins recirculate (OD-16 a): bandits spend their hoards at the market, and guards recover loot to the treasury | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-21 | The caravan buys more of the village's surplus (OD-16 c): meat, hides and other over-produced goods | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| EQ-22 | Caravan buying order: smiths first starves the hide and leather chain after parity | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| EXP-A | Expansion A: Mining & Industrial Development (independent future expansion; supporting document is the primary specification) | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| EXP-B | Expansion B: Settlement Advancement & Regional Economy (independent future expansion; supporting document is the primary specification) | 18 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| EXP-D | Living Economy Expansion: needs-driven economic architecture (needs, offers, adaptive prices, contracts, reservations, credit, bounded knowledge, organic safety levers) across households, employment, production, construction, markets, caravans, mining, the manor, bandits and NPC decisions; its OWN standalone build | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| F-1 | NPC workshop construction | 18 | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| F-2 | Births, children, aging, family growth |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| F-3 | Music and sound |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| FAM-01 | Household succession: when one parent dies the surviving parent (either sex) becomes responsible for the dependants and every household decision; the household keeps functioning | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-02 | Both parents dead: dependent children never found households or start construction; an existing household takes them in | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-03 | Informal adoption order: living grandparents (both sides), then the nearest eligible blood relative by genealogy, then another villager's household with a responsible adult; no adoption authority | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-04 | Integration: the child becomes a dependant of the receiving household and uses its house; genealogy (mother, father, birth family) is never overwritten; a surname change is allowed and does not corrupt the tree | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-05 | Occupancy after a child is taken in is recalculated; any housing need it creates belongs to the receiving household's responsible adult; no house is built automatically | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-06 | Family scenario tests: the eight family scenarios of the directive, written when the mechanics are implemented | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-07 | Unplaced orphans join the bandit clan (OD-11): after surviving parent, grandparents, nearest eligible blood relative and a willing villager household; the child keeps identity, age, genealogy and relationships and stays a child (no adult combat) | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FAM-08 | Future: an adult raised in the bandit clan decides their own future from circumstances, relationships, opportunities, needs and personal decisions (NPC Judgment, bandit factions); beyond the interim rule of FAM-07 | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FAM-SAC-01 | Family sacrifice and responsibility: the father figure puts children, then spouse, then parents before himself, giving up food, comfort, wealth, time and reasonable safety in hardship, without suicidal choices that would leave the family worse off; through the existing household, needs, personality and decision code; factors recorded through XEXPL-01 and the flight recorder | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FARM-01 | Farmland plots: any household (player or villager) leases a small plot through the existing lease framework at 2 coins, registered so no one else can claim it | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-02 | Developing farmland: clear trees and obstructions, then build a fence and gate from logs and stone through the normal construction system | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-03 | Ploughing and sowing a family plot with real seed by the established farming mechanics (one model for player and villagers) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-04 | Household participation: family members work the plot by age, ability, skill and time; no farmer occupation required | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-05 | Whether a household takes up a plot: from its circumstances, needs, skills, resources and opportunities (no quota, no forced farming) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-06 | Manor fields need seed and labour like any farm (no free seed, crops or materials) | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FARM-07 | The farmland lease's recurring charge: 2 coins under the existing weekly lease framework (first week at once), ambiguity reported to the owner | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-08 | Shared-yield comparison: the per-cell model and seasonal farming together at several yields (0.9-3 a cell), identical seeds; grain produced/consumed/sold/stored/unsold, seed use and recovery, labour a harvest, food security and starvation causes, manor and family-farm viability, prices and demand, livestock feed and milk, seasonal timing; the milk collapse explained; a recommended yield for the owner's approval | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| FARM-08A | No script error when a homeless household's couple or founder looks for a building site | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-08B | Cattle decline under the shared and seasonal farming model: investigation | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FARM-08C | Wheat price floor: record as an economic finding | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen centre, lease or buy, confirm | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting work | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| FARM-CROP-SEED | Seed kept back from a shared field is split among its cutters by work, as the grain is | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| FIX-D1D2 | Saves never activate a disabled feature, and a disabled feature keeps its saved section untouched (D1 judgment, D2 economy), following the civic-records pattern | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| FIX-D3 | Friendly-guard fine rule behind the judgment switch: Build 18 behaviour exactly with judgment off; halve, never waive, with judgment on | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| FIX-RECF1 | Fix the unsold-goods re-decision loop (REC-F1): find the actual cause and correct the condition that makes villagers reconsider an unavailable action hundreds of times; no arbitrary cooldown; autonomy, economy and prompt reaction preserved; isolated from other systems | 19 | OWNER APPROVED | IN DEVELOPMENT | NOT TESTED | NOT READY | OPEN |
| FR-01 | Lizards and spiders as enemies | 20+ | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| FR-02 | Forgotten Memories waterfalls, fences and props | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FR-03 | A campfire for cooking raw meat outside the village | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen controls list | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FR-05 | Title window opens scrolled into the controls list |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FR-06 | Wiki pages missing: magic, the employer star, journal and map, death causes, caravan, bandits | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FR-07 | Economy and household simulations in CI (short variant) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FR-08 | Music and sound | 20+ | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| FR-09 | Crime from desperation | 19 | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| FR-10 | Archery | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | 19 | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FSE-00 | Food security, household production, land use, markets and goal-driven economic behavior (final master directive) | 16 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| FSE-01 | Current-system audit: agriculture, consumption, hunting, husbandry, land and commerce | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-02 | Food sustainability calculation: food and productive land per villager, household and village | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-03 | Gap analysis: agriculture, husbandry, hunting, rental, commerce and AI behavior | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-04 | Cross-system dependency map for the food and living economy | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-05 | Implementation roadmap: Build 16 foundations vs the living-economy build | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-06 | Testing strategy for the food and living economy | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-07 | Unresolved owner questions arising from the food-security directive | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-08 | The directive's 25 deterministic tests (section 17) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-09 | Build 16 food-security defects and foundations (classes B and C) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-10 | Living-economy build: gardens, rented land and pens, side hunting, household stalls, multiple incomes, goal-driven individual choices (class D) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| FSE-11 | Village sowing consumes seed (seed consumption correction) | 16 | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| FSE-12 | One agricultural model for player and village farming (parity) | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FSE-13 | Seasonal farming for village fields (implemented and tested in isolation; activation needs owner review) | 16 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| FSE-14 | Dynamic land planning: design and safe foundations (land rental for plots and pens) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-15 | Recalculate the land requirement after the seed, season and parity corrections | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-16 | Seed-2 starvation: root cause of each of the 11 deaths | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-17 | Manor relief checks and draws on every food store (amends the B3 relief rule) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-18 | The family chest: a household's food is kept in its pantry, communal; traders keep sellable stock and stock the chest first | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B05 | A pen whose keeper is gone is let again (its animals starved untended) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B06 | Bandits' poaching and the clan's camp meals feed them only from real food | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B07 | Villagers can sell flowers to the Apothecary | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B08 | A hunt cut short releases its claim on the animal | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B09 | Hunter job openings count only game hunters may take | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B10 | The player's kills enter the wildlife ledger | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B11 | The home hearth gives the player and villagers the same recipes | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| FSE-B12 | Hunting experience by one rule for the player and villagers | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| HEALTH-01 | Medieval health, injury and medical system (injury severity, accidents incl. collapses, illness, bleeding and infection, practitioners, apothecary and potions, costs, rest and recovery, lasting harm, death, NPC treatment decisions) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| HOUSE-01 | Housing need arises from circumstances: crowding, a couple living apart, an adult leaving home, no permanent residence, a lost home; not every extra person needs a house | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-02 | The household's responsible adult decides and builds; no sex or strength restriction (a mother can initiate and complete construction; same-sex couples found homes too) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-03 | A persistent housing goal begins before the household can afford it: the plan (existing recipe, materials owned, to buy, cost, own labour, help) is kept and worked toward | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-04 | Money and materials come from real systems: work, saving, buying, materials the household owns, gathering, producing, trading, help from kin and neighbours; never free supplies | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-05 | Construction is real work over time: it consumes materials, progresses as they arrive, keeps unfinished progress, yields to survival needs and resumes after a shortage | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-06 | No construction deadlock: a household reconsiders its approach with what exists (save, buy elsewhere, another existing recipe such as added quarters) without new building types or bypassed costs | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-07 | EQ-07 investigation and tests: trace need to completion (the directive's ten questions), name the root causes, tests for the seven housing scenarios, re-run the simulations labelled old and new code | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-08 | Bed sharing in the crowding rule (OD-13): couples share a bed and young children share beds within an age limit; crowding counts sleeping places, not people | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-09 | Original village houses can take living-quarters expansions (OD-13): the ground under a generated house becomes its parcel so modules attach; the quarters still cost real materials, labour and time | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-10 | Smaller attached rooms for existing houses (OD-14): a bedroom-sized addition that fits the current tile grid, built through the existing construction and module systems on legitimate adjoining ground, with real materials, labour and time | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| HOUSE-11 | Evaluate the alternatives where a ground-floor addition is impossible (OD-14 item 6): a smaller configuration, and whether an upper-floor or attic conversion is practical in the existing building system; no new upper-floor system invented to bypass geometry | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| HOUSE-12 | Sleeping loft: a lightweight house improvement adding sleeping places after real construction (materials, labour, time), integrated with sleeping, occupancy and household behaviour; not a navigable second floor | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| ID-01 | One persistent person identity across migration (between settlements, away and back), save/load, household and relationship changes, death and inheritance, and future detailed/abstract transitions; no replacement people, no reused identities; existing saves migrated without discarding or reassigning history | unassigned | OWNER APPROVED | IN DEVELOPMENT | TARGETED TESTS PASSED | NOT READY | OPEN |
| INFO-01 | Sharing and selling prospecting information (MIN-C-Q2) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| INFRA-01 | Long-run test reliability: preserve long-running simulation progress or prevent session-idle termination, without altering simulation results | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| INFRA-02 | Manual GitHub Actions workflow for long-duration simulations: seed and duration inputs, isolated output, artifacts, commit/seed/runtime/fingerprint/ledger recorded, clear failure, no builds or releases, no automatic year-long runs, bounded concurrency; validated against a local 10-day run first | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| INV-18 | Categorized inventory: eight capacity pools, separate equipment, two upgrade stages | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| JOB-01 | Shared job board for salaried manor hands: eligible for appropriate board work, no extra wage, specialised exclusions kept, no universal priority, no double booking | 17 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| JOB-02 | Offered compensation on the manor job board: each funded posting offers pay that eligible workers weigh and may decline; the manor may raise its offer; jobs may stay unfilled; pay from real funds, in full on completion; no extra pay to salaried hands; CON-01 contracts stay separate | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| JUICE-00 | Preliminary Game Juice and player feedback assessment (unnumbered presentation workstream, read-only) | 20+ | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| K-1 | 5 coins vs land 60+ |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| K-2 | Tavern child and sage on pallets; no lying frame |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| K-3 | Every provisional number awaits the owner's balance review |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| LAW-SKILL | Law skill: learned by witnessing and carrying documents, taught by the clergy or reeve; needed by a courier to notarise | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| LE-00 | Living Economy stage LE-00: Repository audit and cross-system dependencies (read-only architecture audit first) | 20+ | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | UNKNOWN | OPEN |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and contract model | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settlement | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budgets | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behavior | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-05 | Living Economy stage LE-05: Construction, ecology, mining, bandits and regional links | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profiling | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LE-07 | Living Economy stage LE-07: Release readiness and platform builds | 20 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| LOG-01 | Unclaimed manor deliveries fall back to an available salaried manor hand or the reeve, physically, recorded once, without an extra wage; urgent relief keeps its protection until a physical replacement is safe | owner decision | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MAINT-01 | Need-driven maintenance, village expansion and road construction: structures and infrastructure wear with real consequences; the reeve arranges repair and construction projects with real materials, labour, time and money by priority (urgent, routine, logistics, growth, discretionary); roads as real infrastructure; no treasury-driven make-work | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| MAP-01 | Map shows where you are beyond the village | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| MEM-01 | Persistent project memory: PROJECT_MEMORY.md index, CURRENT_DEVELOPMENT_STATE.md handoff, mandatory session-start instructions, checkpoints, safeguards and a fresh-session recovery test | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| MEM-02 | Permanent project memory: index covers every listed source (incl. the 231-entry reconciliation), 8-step session start, baseline of the 231 open and 142 closed entries, 9-question recovery test | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| MERCH-01 | A village seed merchant or booth selling crop and flower seed, berry cuttings and fruit-tree seed or saplings, with real stock, coins and restocking | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIGRATE-18 | Migration both ways between the village and the off-map settlements for work, land, marriage or hunger | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| MIN-A | Mining expansion phase A: Audit terrain, elevation, mining, inventory, recipes, AI, pathfinding, saves and map generation; architecture and measurable acceptance tests | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-B | Mining expansion phase B: Exhausted ore outcrops stay quarryable stone; quarry chain and stone logistics | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-C | Mining expansion phase C: Natural prospecting clues, prospector profession, forge-made toolkit, samples and assay | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-C-Q1 | Prospector compensation: support manor commissioning, not as the only employer; compatible with negotiated contracts | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-C-Q3 | The smith remains the assayer; no separate assayer profession without approval |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| MIN-COLLAPSE | Binary collapse outcome: a person caught survives or dies deterministically; deaths through existing death handling; survivors handled physically | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-D | Mining expansion phase D: Finite hidden deposit discovery; settlement mining capability levels 1-4 with autonomous NPC adoption | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-D2 | The player counts toward the settlement's mining capability by exactly the villagers' rules (MIN-D-Q2) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-D3 | Trial pits yield conserved, recoverable topsoil, dirt and spoil through the MIN-E item and heap system (MIN-D-Q3) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-E | Mining expansion phase E: Open-pit excavation, spoil, dirt and topsoil as materials, ramps, hauling and geological layers (where the architecture supports them) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-EQUIP | Mining equipment made by carpenters and smiths (supports, ladders, minecarts, metal parts, repair materials) and obtained by villagers and the manor through ordinary trade and procurement | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-F | Mining expansion phase F: Underground and cave mining, cutaway presentation, supports, minecarts, track construction and full industrial dependencies | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-F2 | Implement the owner's MIN-F-Q1..Q5: support deterioration and collapse, hidden underground ore and manor tunnelling jobs, minecart preference, vertical shafts and levels, player-directed backfilling | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-G | Mining expansion phase G: 100/365-day multi-seed simulations and gameplay tests; save validation; economic conservation; no resource spawning | 17 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| MIN-H | Enterable caves and underground mining environments (roof-fade principle, NPC pathing, persistence) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-RIGHTS | Open access to common ground; legitimate property respected (MIN-E-Q3) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-SHOVEL | Craftable shovels for topsoil and loose earth; pickaxes for rock; both wear (MIN-E-Q2) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MIN-SKILLCAP | Capability counts real skills, equipment and facilities, not job titles; specialists and equipped labourers both dig (MIN-E-Q4) | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritative | multiplayer | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| MUSIC-18 | Game music from the owner's three songs (Prosperous Village, Sunrise over the Village, Misted Ancient), played on the Music bus; Music and Sound-effect volume sliders in Settings working | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| OD01-QUEST | Retire the fixed-reward quest 'A shift in the mine' (8 coins for 6 iron ore): never offered again; existing accepted shifts handled safely | 17 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| OPS-01 | Resolve PR #1 as routine maintenance: inspect, compare with staging, preserve any unique work on a remote branch, then close with a comment |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| ORE-PLACE-01 | Natural ore evidence and finds kept out of the developed village footprint | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| OVN-01 | Master overnight directive: autonomous lead-engineer execution of approved work, Builds 15 to 18 strictly in order, the build-completion definition, the skipped-items register, release and decision authority | 15 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| OVN-02 | Final development mandate: Build 15 closure standard, living-world philosophy (WDR-022), release when functionally complete, then Builds 16, 17, 18 in order, autonomous engineering | 15 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| OWN-01 | Asset integration pipeline (skill, policy, registry, scaling standard, tools) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-03 | Calendar (8-day year), human aging, explicit family links, heirs from family graph, animal life stages |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-04 | Village generator v6, fixed village, save v13 refusal |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-05 | Overworld (B8-011) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-06 | Living Forest tree lifecycle |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-07 | Flowers/berries walkable and gatherable |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-08 | Post-audit remediation (SaveStore, tests.yml, release gates, stable test key) | owner decision | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| OWN-10 | Queue + parallel agents; resource manifest, Gather mode, journal page |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-11 | Continuous development; reeve employment |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-12 | Build 7 corrections; "Not approved yet (investigate first)": mining wage 15+, 15-coin reserve on player sales, deposit regeneration, wildlife respawn, broad changes |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| OWN-13 | Windows exe icon |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-14 | Interiors roof fade, sleepers reachable |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-15 | Property phases 1-2, construction, helpers, households split |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-16 | GitHub workflow; work preservation; off-machine copies; backup branch |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-17 | Provisional numbers await a separate balance review |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| OWN-18 | Inventory tabs, six gear slots, tavern food theft, stealing, pickpocketing, buttons sized, camera dead zone |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-19 | Quest markers; Fireball storyline; side quests; busy-villager bubbles | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| OWN-20 | Trees walk-under; heir kit; journal book |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-21 | Every build published under GitHub Releases |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| OWN-22 | Platforms: Android first then PC; touch/gamepad/KBM auto-detected; settings | owner decision | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| OWN-23 | UI recolour brown; flat UI pack buttons; Kenney prompts |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-24 | Lizards and spiders as enemies |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| OWN-25 | Attack mode; blood splats; readable phone text |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-26 | Animal breeding, hunger, livestock as meat, wild animals hunted |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-27 | Manor government B3 |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| OWN-28 | Living world intent; Morris world; ordinary inhabitant; magic learnable; multiplayer 3-4 host; isometric 8-dir; research rules | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| P21-00 | Expansion 21 phase 1: government architecture audit (what exists, works, is incomplete or absent, by civic system) | 21 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| P21-01 | Expansion 21 phase 1: isolated civic foundations (office ids, holders and tenure, jurisdiction, eligibility and authority metadata, succession events, treasury attribution, duty records, legacy records), all behaviour disabled | 21 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| P21-02 | Expansion 21 phase 1: political decision architecture map (owner system, information needed, open owner choices per decision) and the grouped 12-topic owner decision packet | 21 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| P21-MAYOR | Elected mayor: elected by established adult residents who are also eligible to stand; four-game-year terms; incumbents may stand again; an early vacancy calls a replacement election as soon as possible, the longest-serving eligible civic official holding authority meanwhile; voters judge candidates individually by policies, competence, interests, trust, relationships, family and their own priorities | 21 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PAR-00 | The player is a villager: one set of world rules for player and villagers | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-01 | OD-18.1: villagers develop skills exactly as the player does | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-01A | Starting experience only at world creation, from a plausible occupational history; one-time migration for older saves | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-01B | Career changes neither grant nor reset experience | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-01C | Experience comes from activities, whatever the occupation | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-02 | OD-18.2: one trade eligibility rule (the trader's coin reserve) for player and villagers | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-02A | OD-19: a dynamic, necessity-based reserve in place of fixed coin floors | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-03 | OD-18.3: villagers recover health by the player's rest model | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-04 | OD-18.4: villagers can craft every recipe the player can, under the same requirements | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PAR-05 | OD-18.5: crime awareness by legitimate means only, the same for assault and theft | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PERF-01 | Simulation performance audit: measured explanation of the runtime growth since the 530-689 s 365-day benchmark (regression, contention, environment or estimates) | 15 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PERF-02 | Profile a representative 10-day run by subsystem (npc_brain decisions, _run_plan, movement and pathfinding, fauna, hourly and daily world processing, harness sampling) before any optimization | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PERF-03 | Determinism gate for optimizations: baseline fingerprints, then identical fingerprints and ledgers at 10 and 30 days on the same seeds after each change | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PERF-04 | Small, measured, low-risk optimizations (indexes or caches for NPC scans, fauna membership sets, hot-loop config reads) that pass the determinism gate; no bigger STEP, no disabled systems, no shortcuts | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PERF-05 | Parallel seeds: two seeds as separate processes with isolated save, temp and output paths, against the same two run sequentially | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PERF-06 | Long-simulation checkpoint and resume: evaluate design and determinism risks before any implementation (owner: do not implement until evaluated) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| PICK-01 | A caught pickpocket raises a witness report through World.witness (OD-20), as assault does (PAR-05): awareness only from legitimate witnesses, no omniscient guards, not always an audible alarm | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PIT-02 | Larger and deeper open pits, strata, spiral and switchback ramps (MIN-E-Q5) | owner decision | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL1-01 | Settings > Controls exit freezes game |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-02 | One tabbed Settings with Back |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-03 | Merchant quantity control | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PL1-04 | Health recovery + Apothecary |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-05 | current/max inside bars | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PL1-06 | Every stone minable, size-based |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-07 | NPCs sunk into beds/chairs | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PL1-08 | Consumable effects shown everywhere |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-09 | Gold star over employer |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL1-10 | Player businesses, staged (1-4) | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PL1-11 | Google Drive cloud saves (staged) | owner decision | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PL1-12 | Red flowering plant not pickable | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PL1-13 | Recognisable stove | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PL2-001 | Forge occupancy wrongly blocks |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-002 | Chests, locks, lockpicking |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-003 | Dialogue text |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-004 | Animal loot, leather |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-005 | Longer skill trees |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-006 | Harvest everywhere |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-007 | Fields grow, ripen, regrow |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-008 | Expandable property | 18 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| PL2-009 | In-game wiki |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-010 | Recognisable sawhorse | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PL2-011 | No interactions through walls |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-012 | Storage UI quantities, focus |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| PL2-013 | Usable furniture | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| PL2-014 | Modular house/workshop expansion | 18 | OWNER APPROVED | INTEGRATED | NOT TESTED | NOT READY | OPEN |
| PL2-015 | Farming, livestock, hand plough | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PL2-015-BUYANIMALS | Farming: caravan animals other than the horse (deferred from PL2-015; fits LE-05) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL2-015-COOPS | Farming: coops and animal shelters (deferred from PL2-015; goes with weather) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL2-015-HIRED | Farming: hired farmhands (deferred from PL2-015; fits LE-03) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL2-015-OTHER | Farming: oxen, per-crop art and the rest of the deferred-on-purpose list in docs/BUILD_DECISIONS.md (deferred from PL2-015) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL2-015-TRAP | Farming: trapping (deferred from PL2-015; fits LE-05) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PL2-015-WATER | Farming: weather and expanded watering, crop and animal loss (deferred from PL2-015) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PROS-18 | Expansion 18 prospective implementation (settlement capability and specialization, regional supply and demand, routes and transport, settlement inventories and reports, competition and cooperation, caravan subsidy replacement plan, conservation tests) | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | 19 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| PVG-01 | Procedural villages: expansion-aware house placement (footprint, parcel, road access, adjoining construction space, terrain and elevation, neighbours and boundaries, future rooms, household activity space) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-02 | Procedural villages: realistic medieval density and variation (compact homes by central roads and markets, larger plots outward, trades by infrastructure, farms on suitable land, irregular terrain-following roads and parcels) | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-03 | Procedural villages: viable long-term housing options per home where practical (attached additions, smaller rooms, upper floors if supported, acquiring adjoining land, a new home elsewhere), decided by the real building and property systems | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-04 | Procedural villages: reserve physical space for potential expansion footprints before placing neighbouring buildings and roads, without keeping it empty for ever | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-05 | Procedural villages: growth over generations through inhabitants' legitimate construction (homes, roads, workshops in response to population, land, resources and finances), never an omniscient builder | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-06 | Procedural villages: validation before acceptance (road access, no illegal parcel overlap, valid footprints, traversable routes, reasonable expansion opportunities, growth not blocked by the initial layout, terrain and resources fit the settlement type), configurable criteria, tested across seeds, terrain and densities | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| PVG-07 | Procedural villages: deterministic generation and persistence; buildings, parcels, modifications, ownership and construction progress persist; regenerating or loading a region never overwrites player or NPC changes | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| Q-03 | Resource manifest and registry (INT-067) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| Q-04 | Resources & Gathering journal page | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| Q-05 | Reeve employment, real jobs, NPCs same rules (INT-066) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| Q-06 | Long-duration simulations 10/30/100/365 |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| Q-08 | Resource depletion and wildlife sustainability | owner decision | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| Q-10 | Hot Attic Games read-only registry | owner action | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| REC-001 | Adoption and orphan guardianship (NPCs and the player) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| REC-002 | Over-the-air updates on the Hot Attic Games Mote architecture (fully automatic) | 20+ | OWNER APPROVED | IMPLEMENTATION BLOCKED | NOT TESTED | NOT READY | OPEN |
| REC-003 | Android builds target API 36 (Hot Attic Games standing platform policy) | 15 | OWNER DECISION REQUIRED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| REC-004 | Merge the Game Designer ('Bob') corrected spec into the project docs and record its owner answers | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| REC-005 | Working title 'The Well'; repository, package and identifiers stay My Medieval Life |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| REC-006 | Castles, dungeons and caves in the world | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| REC-007 | Several settlements (villages, towns, cities) with their own economies; NPC migration and regional jobs between them | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| REC-008 | Near/far simulation tiers (detailed near the player, abstract far away, nothing duplicated on switching) | 20+ | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REC-009 | Combat style: real-time aimed attacks, melee combos and abilities on cooldowns | 20+ | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REC-010 | Class progression, 'system jobs' and a tech/research tree | owner decision | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REC-011 | Main storyline after the first story quest (side quests now, story later) | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| REC-012 | Tiny Ranch pack: on hold by the owner, not cancelled | 20+ | DEFERRED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| REC-013 | Need-based maintenance (wear) model and the other unanswered job-board questions | 17 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| REC-014 | Revisit the settlement, agriculture, food, resource, population and trade foundations using the recent research | owner decision | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REC-015 | NPC competition and economic rivalry (as a game system) |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| REC-016 | NPC self-improvement and prosperity (as a game system) |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| REC-017 | Bring stale project documents up to date (handoff, plan, game design, build decisions, CLAUDE.md release list, resources.json exception) | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| REC-19 | Build 19 Simulation Flight Recorder: full-scope interaction, decision, state-change and causal recording of the whole active simulation (player-independent), invariant and anomaly checks, coverage audit, structured archive with Excel export on Android, Windows and Linux; recording on/off deterministic; developer layer of XEXPL-01 | 19 | OWNER APPROVED | IN DEVELOPMENT | TARGETED TESTS PASSED | NOT READY | OPEN |
| REC-DIAG | Use the flight recorder now for autonomous simulation analysis: progressively longer runs, analysis between runs, findings with evidence, causes and recommended corrections; defects told apart from emergent behaviour; instrumentation gaps reported; no unrelated fixes without the owner | 19 | OWNER APPROVED | IN DEVELOPMENT | NOT TESTED | NOT READY | OPEN |
| REC-STORE | Recorder keeps every decision's alternatives and factors in full; no reduction, sampling or discarding; storage limit stops recording, keeps data, marks the session incomplete | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| RECON-01 | Reconcile overlaps: one calculation for tolerance (temperament life shifts vs personality drift) and one reservation mechanism per inventory quantity (contract holds vs economic reservations); behaviour unchanged with flags off | unassigned | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| REG-BUY-01 | The village buys food and other goods from the five settlements (villagers, households, businesses and the treasury as buyers), paying the settlement's sellers, carried by the traders' visits | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REG-BUY-P1 | Settlement food-selling policy (REG-BUY-01), owner approved: (1) the traders also carry food bought from their settlement's farms, herds and cookshop; (2) a settlement releases only food above its local claim: its households' foreseeable need over reserve_days less their pantries and less the food its businesses expect to produce (World.necessity, NPCBrain._sale_stock: local buyers first); (3) a food-producing business with a demonstrated cash shortfall for essential operating expenses (wages, seeds, animal feed or other established necessities, from existing expense mechanisms) may sell into its necessity reserve, limited to that shortfall; (4) the settlement's own floating prices | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT APPLICABLE | OPEN |
| REG-COURIER-01 | Connect courier booths, routes and special deliveries to the five settlements and wire couriers into the live game loop and saves | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REG-DEMO-01 | Off-map settlement demographics under the village's life rules: member ages, births, age-related deaths, children growing up into workers, household formation and dissolution, inheritance | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REG-EVAL-01 | After REG-PARTY-01, REG-BUY-01, REG-COURIER-01 and REG-DEMO-01, evaluate whether the regional economy has genuine circulation failures (REG-CIRC-D1), against the 2026-10-23 baseline evidence | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| REG-INV-01 | Regional economy investigation: Higham's treasury decline, village sustainability under settlement traders, village buying from settlements, courier booths on the five settlements, settlement demographics | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| REG-PARTY-01 | One trading-party interface over the five settlements (trader, businesses, treasury, households) replacing the prospective SettlementLedger parties in RegionalMarket and Couriers | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL-14-16 | Release Builds 14, 15 and 16 (three platform packages each) when the eight release conditions hold | 15 | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| REL-15-18 | Release authorization for Builds 15 to 18: create and publish each when all its release gates pass (section 4), with the established platforms, naming and procedure; private test builds stay private | 15 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| REL18-DET | Build 18 release gate: Determinism gate re-recorded on Build 18 code (two independent runs identical) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL18-DEVICE | Build 18 release gate: Device and owner playtest of every player-facing Build 18 requirement (the playtest queue) | 18 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REL18-EXPORT | Build 18 release gate: Android, Windows and Linux packages from one commit and one build number | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL18-LONGRUN | Build 18 release gate: Conservation and long runs: one 365-day run per required seed, no ledger leak (SIM-01) | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| REL18-OWNER | Build 18 release gate: The owner's approval to publish a Build 18 distributable (B17-DIR exception carried to Build 18) | 18 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| REL18-PACKAGE | Build 18 packaging gate: no Build 18 test package until every punch-list item is closed or explicitly accepted as permanently blocked; no early or partial builds | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL18-SAVE | Build 18 release gate: Save compatibility: a real Build 17 save loads into Build 18, plus migration fixtures | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL18-SUITES | Build 18 release gate: All automated suites pass on the final Build 18 integration commit | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REL18-WIKI | Build 18 release gate: WIKI-01 release gate: new and changed mechanics documented, wiki checks pass | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| REQ-BANDIT | Bandit factions, criminal careers and outlaw leadership |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| REQ-CTRL-01 | One authoritative requirements and decision register with separate status dimensions, validation, generated views and divergence control | unassigned | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT APPLICABLE | OPEN |
| REQ-CTRL-02 | Requirements recovery audit: dry run, immutable sources, conflict and evidence audit, recovered-work classification, Builds 18-21 status | unassigned | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| REQ-GRAVE | Graveyards, ancestry and NPC legacy |  | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| ROOMS-18 | Inner doorways between joined house rooms, and the two survey plots relaid onto open ground | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| SAVE-00 | Save continuity across separate test builds (Android reinstall): user-selected save location or Android-supported export/import; permanent signing key deferred | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-01 | Inspect and document the current save architecture before modifying it (requirement 1) |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| SAVE-02 | A stable save identity independent of build numbers (requirement 2) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-03 | Explicit save-schema versioning and forward migration from older supported formats (requirements 3, 4) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-04 | Back up the original before migrating, validate the migrated save before adopting it, preserve the original on failure, never leave a partial conversion, never destroy the only usable save (requirements 5-8, 15) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-05 | A clear way to reconnect to an existing save after an Android reinstall, using supported Android storage (Storage Access Framework or equivalent), no unrestricted filesystem access (requirements 9, 10) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-06 | The same versioning and migration principles on Windows and Linux (requirement 11) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-07 | Migration tests over persistent world data: terrain changes, resources, NPCs, households, relationships, buildings, inventories, settlements, simulation state (requirement 12) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-08 | Preserve unknown or future data where practical; no claim of backward compatibility unless implemented and tested (requirement 13) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SAVE-09 | An independently recoverable backup and documented recovery instructions (requirement 14) | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SEED-01 | Seed and propagation audit: crops, fruit trees, berry bushes, flowers (acquire, store, plant, grow, harvest) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| SEED-02 | Planting consumes real seed or propagation material for every plant type; harvests recover seed or cuttings at a deterministic chance | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SEED-03 | Perennials (fruit trees, berry bushes) survive harvest and bear again by season; growth follows the 8-day year | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SEED-04 | Households save planting material from their own harvests | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cross-industry skill schema, save compatibility, dependency audit | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industry capabilities, NPC knowledge, workshops, prerequisites, decay and continuity | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settlements with finite demand, supply and budgets; variable caravan trade | 18 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| SET-C-FIVE | Five off-map settlements of mixed kinds, each a simulated economy (SET-C-SIM) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| SET-C-SIM | Off-map settlements as lighter-detail simulated economies: households, a manor or council treasury, businesses, wages, taxes and prices under the village's rules, stepped daily | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| SET-D | Settlement expansion phase D: Settlement development: growth and decline, specialization, housing, infrastructure, population and employment | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SET-D-MULTIGEN | Multigenerational verification of settlement development (SET-D) over a horizon long enough to show several generations | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SET-E | Settlement expansion phase E: Actual inter-settlement network: persistent settlements, routes, logistics, competition, merchant AI | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SFX-18 | Sound effects and ambience from the owner's Cozy RPG SFX pack (ambience loops supplied: forest birds, cave wind, dungeon drips, campfire), on the SFX bus under the Sound effects slider | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SHOP-01 | Skilled businesses sell what they produce or stock and buy useful goods by real need and funds (a carpenter buys timber, an armorer materials), the same mechanics for player and villagers | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SIM-B17 | SIM-01 in Build 17: one monitored longest run per seed, checkpoints for shorter milestones, stop at the first broken ledger | 17 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| SJD-A | Judgment expansion Gate A: Build 16 stabilization and baseline (seeds, remote commit, known defects); no implementation | 16 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | 19 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| SKILL-TRADES-18 | Carpentry, Masonry and Tanning skills, started from each person's Crafting experience; the matching work earns them | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| STALL-01 | Stalls are built by anyone on cleared land through the construction system with real materials, under the realm's 5% sales lease | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| STALL-02 | A stall's own inventory: goods are moved into it for sale and are in one place only | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| STALL-03 | OPEN STALL: the stall sells unattended to real buyers through the existing market; auto-closes when sold out, with a notification | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| STALL-04 | CLOSE STALL: sales stop, the unsold goods stay in the stall, the session's sales are totalled | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| STALL-05 | The realm's 5% commission on each session's actual sales, through real coins (100 sold: 5 to the treasury, 95 to the seller) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| STALL-06 | Villager households build, stock, open, close and restock stalls by the player's mechanics, selling surplus with the family's needs weighed | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| STONE-01 | Raw quarry stone and finished building blocks as separate items: stoneworkers process raw stone into blocks with real labour, tools and time; construction uses blocks; no automatic conversion or free blocks | 17 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| STONE-02 | Personal-use stone dressing by any villager (own house or repairs), same rules as the player | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| STONE-03 | Materials by kind of work: major masonry reconstruction in blocks and mixed raw-stone-and-block jobs | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| STONE-04 | Skill-based stone dressing efficiency with conserved waste (one rule for player and villagers) | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| STONE-05 | Stoneworking skill: a distinct skill in the existing skill system that governs stone dressing | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| STONE-06 | Iron chisel: smith-made, worn by use, needed with the mallet to dress stone | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| SYNC-17 | Synchronize Expansions 18 and 19 one way with the Build 17 baseline cd7439c | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | COMPLETE |
| TAILOR-18 | Tailor: a village NPC service selling the two backpack upgrades | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| TIME-01 | Time-system audit: every timed system's duration, unit, meaning, calendar equivalent, calibration, balance effect and parity | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| TIME-02 | Explicit time units in configuration and code; one shared conversion layer (no third clock) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| TIME-04 | Player starvation damage follows the villagers' rule (time-audit defect D4) | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| TRADE-01 | Trade-specific purchasing at counters through the shared trade rules (OD-19 reserve, PAR-02) | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| TRADE-AXE-01 | Playtest: cannot buy Clement Ward's axe (listed 45) holding 47 coins | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| TRADE-CREDIT | Barter and credit with trust: goods-for-goods deals and recorded debts that must be repaid; unpaid debts hurt standing | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| TRADE-UI-02 | Contract proposal's answer shown in view | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| TREAS-01 | The manor treasury as the village reserve: fees in, real purchases out, relief from owned stock | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| UI-HUD-01 | HUD status panel too large: shrink and move the date line | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| UI-HUNGER-01 | Hunger icon becomes a drumstick | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| UI-PROGRESS-01 | Progress bar visible on light and dark ground | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| UI-WIKI-01 | Village Encyclopedia: navigable, searchable wiki window | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VER-CON-50ORE | Focused contract verification: a 50-iron-ore quantity contract with existing functionality (production, inventory conservation, delivery, payment, deadline) | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | COMPLETE |
| VIS-ANIMAL-01 | Stray fragments above animals removed at the source | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VIS-AXE-01 | Lumberjack axe: believable chop, blade never through the head | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VIS-CROP-01 | Ripe wheat recognizable; planted, growing, mature, harvested look distinct | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VIS-DOOR-01 | Doorway transition: characters no longer pass under a closed door | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VIS-STEPS-01 | Steps cut through rock need real step art | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VIS-TREE-02 | Tree fragments: no stray old tree pieces; stages and stumps draw correctly | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| VP-01 | Living village politics: offices, individual NPC voting, elections, civic authority | 21 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-001-C | Comply with World Design Rule 1: Material Interdependency | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| WDR-003-C | Comply with World Design Rule 3: Meaningful Recipes | 17 | OWNER DECISION REQUIRED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| WDR-005-C | Comply with World Design Rule 5: Living World Independence | 16 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| WDR-006-C | Comply with World Design Rule 6: Maintain the Existing Interlocking Systems Manifest |  | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | UNKNOWN | COMPLETE |
| WDR-007-C | Comply with World Design Rule 7: Automated Compliance | 15 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | RELEASED | COMPLETE |
| WDR-008-C | Comply with World Design Rule 8: Player Knowledge and Wiki | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | 19 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-010-C | Comply with World Design Rule 10: Depth Without Obscurity | 15 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| WDR-013-C | Comply with World Design Rule 13: Finite Resources and Actual Consumption | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-014-C | Comply with World Design Rule 14: Graveyards, Ancestry, and NPC Legacy | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-015-C | Comply with World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment | 20+ | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-016-C | Comply with World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership | 20+ | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-017-C | Comply with World Design Rule 17: Generational Memory and Living History | unassigned | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-018-C | Comply with World Design Rule 18: Protected Ecological Continuity | unassigned | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-019-C | Comply with World Design Rule 19: Living Political Agency and Democratic Consequences | unassigned | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| WDR-020-C | Comply with World Design Rule 20: Autonomous Housing | unassigned | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-021-C | Comply with World Design Rule 21: Household Succession and Family Care | unassigned | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WDR-022-C | Comply with World Design Rule 22: classify every finding as defect, legitimate outcome or future improvement; no hidden rescue; tests check mechanics and integrity, never prosperity | 15 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WIKI-B17 | Build 17 documentation reconciliation: in-game wiki pages and developer references for every merged and verified Build 17 feature (mining and geology, production and equipment, economy and labour, mortality), planned features only in 'Not in the game yet', health placeholders, wiki validation | 17 | OWNER APPROVED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT READY | OPEN |
| WORLD-LIFE-01 | The countryside is empty of people and animals; its trails lead nowhere yet | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| WR-01 | Protected wildlife breeding refuges, offspring cohorts and dispersal | 15 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| WR-02 | Grazers in a wood all stop eating while the wood is over its grass capacity, so some starve together | 16 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, effective capability capped by operational facilities | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six industries, farming as labour efficiency | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or scheduled delivery, negotiated special deliveries, self-collection; smoke tests | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regular routes (flat fee per load or scheduled delivery); special deliveries negotiated by choosing a recipient among the people and businesses the buyer knows | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, recipient, location, collect payment, deliver or deposit proceeds, money/item type and amount, route or special) assembled into a readable instruction; recipients from known people and businesses incl. prior trading contacts (owner represents the business; location from world records); fee computed from route type, distance, burden, capacity, stops, return/deposit, labour, notarial service; physical execution; fulfilled only when obligations are done | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts and ownership transfers signed face to face, or through a courier-notary with legal skill carrying the documents; no remote instant signing; smoke tests for incomplete, rejected, interrupted and completed agreements | 18 | OWNER APPROVED | INTEGRATED | INTEGRATION VERIFIED | NOT READY | OPEN |
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, aggressive; levels 0,2,5,8,10; implemented industries; settlement size, resource and labour scenarios; 30 and 90 days) and a recommendation; no permanent constants before owner review | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dresses and sells building blocks | 18 | OWNER APPROVED | INTEGRATED | TARGETED TESTS PASSED | NOT READY | OPEN |
| X19-FOUND | Expansion 19 foundations round: personality, relationship history and family reputation (judgment off) | 19 | OWNER APPROVED | PARTIALLY IMPLEMENTED | TARGETED TESTS PASSED | NOT READY | OPEN |
| X19-FOUND-BONDS | Relationship history and reconciliation: resentment softens with growth, neutrality restores neither friendship nor trust, familiarity gives about 10% more friendship progression to former friends (non-stacking, suspended by negative standing), trust recovers only by reliability; serious grievances last at least about one game year | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| X19-FOUND-FAMREP | Family reputation: known family history colours descendants' impressions, positive reputation about 5% more friendship progression (about 12% combined with familiarity, not 15%), familiarity not inherited, personal experience overrides inherited impressions, small spillover of wrongdoing onto relatives without inheriting the wrongdoing, trust stays individual | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| X19-FOUND-PERS | Personality framework: evolving traits, soft limits, learning from costly mistakes, practical wisdom, temporary emotions and anger, recovery and growth; about 30% of villagers with potential for self-defeating stubbornness (population level) | 19 | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | TARGETED TESTS PASSED | NOT READY | OPEN |
| X19-MISINFO | Deliberate misinformation and its correction: NPCs may fabricate false accusations; listeners weigh credibility; accusations can be investigated; a falsehood proven false immediately corrects the negative judgment it caused, independent grievances remain; deliberate dishonesty has consequences by intent, harm, repetition and relationships | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| X19-STORY-LIFE | Family stories: reputation extends through a recognized family name, observers judge family members by their own knowledge, family reputation recovers through positive conduct, important stories may survive generations, minor stories fade when no longer retold | 19 | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |
| XAUDIT-01 | Cross-expansion preservation audit of Expansions 19-23 against the repository (read-only): branch inventory, historical timeline, five capability matrices, ownership map, duplicates, regression risks, test evidence and gaps, requirements already met, remaining work, sequence | unassigned | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | NOT TESTED | NOT READY | OPEN |
| XEXPL-01 | Decision Explainability: a shared, deterministic, compact explanation record for significant NPC decisions (decision, principal factors, needs, obligations, resources, beliefs, relationships, information available, outcome and alternatives, event references), shown in three layers (in-world, player inspection limited to the character's knowledge, developer traces); one shared architecture, not one per expansion | unassigned | OWNER APPROVED | NOT STARTED | NOT TESTED | NOT READY | OPEN |

## Proposal awaiting an owner decision (not approved) (38)

| ID | Item | Build | Approval | Implementation | Verification | Release | Completion |
|---|---|---|---|---|---|---|---|
| DGA-D1 | Meaning of "isometric" | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D10 | Formal platform/engine approval (U1, U2) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D11 | Living-society scope (U20, U21, P1-P3, balance review) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D12 | Approval to start phase 1 | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D2 | Isometric art source (J-G4) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D3 | Connectivity with no server | multiplayer | PROPOSED | PARTIALLY IMPLEMENTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D4 | Shared-world rules (pause, characters, heir) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D5 | Reputation/ownership/PvP (J-S3, U21) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D6 | Combat model and latency (U7) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D7 | Visible gear | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D8 | Era, county, political status, map scale | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-D9 | Magic (J-M1..4) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-R | Refactors (coordinates, players collection, command layer, fixed step + state hash, save split, appearance data, magic schema) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DGA-S | Isometric look spike; network feasibility spike | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DVW-B10 | Onboarding, first ten minutes | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DVW-B11 | No instant fast travel (rule) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DVW-B12 | Ethics/lore: thralldom, Church, content note | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| DVW-B13 | Story kept as sparks; audit `story: true` quests | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| E20-RISK-QUEUES | Unbounded growth and population-wide scans found in Build 18 economic code: NPCBrain.miss_log never cleared; courier jobs, agreements and contacts never pruned; credit._villager_deals O(n^2) at dawn; the heir-removal id reuse (life.gd:660) | 19 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| ECON-P1.1 | Demand-driven mining (:71) | 17 | REJECTED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| ECON-P1.2 | Manor mining rights, royalty, quota, stone reserve (:72) | 17 | REJECTED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| ECON-P1.4 | Prospecting new seams (:74) | 17 | SUPERSEDED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| ECON-P1.5 | Distant quarry (:75) | 17 | REJECTED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | CLOSED |
| ECON-P2 | Wildlife carrying capacity, sex floor, migration pool, hunting rights/quota, extinction, seasons (:116-121) | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| ECON-P3.3 | Stock targets in days of sales (agent proposal P3.3, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 185) | 20 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| ECON-P3.4 | Hire wages from the market quote (agent proposal P3.4, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 186) | 20 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| MIN-L5 | Mining capability level 5 (integrated industrial mining) | 20+ | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| OWN-02 | Wildlife balance follow-up; horse imported, use pending | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| OWN-29 | Era, county, atlas storage, Godot, Android, PCG32 | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| Q-11 | Design gap assessment, phased sequence | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| REC-F1 | Recorder finding (10-day run, seed 1): villagers holding goods nobody buys ('holding unsold pottage, log, stone, feathers') re-decide every few game minutes without acting (400-600 decisions a day each against 4-19 actions by day 9), tripling decision volume as unsold stock grows. Existing Build 18 behaviour; not changed. | 19 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| ROAD-02 | Master Expansion Roadmap and Documentation Pack (owner, 2026-10-21): 17 Mining, 18 Settlements, 19 Judgment approved; 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy, Exploration and Multiplayer as proposed numbering | owner decision | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| TIME-03 | Recommended time retuning (outliers): proposals only, owner review before any change | 16 | PROPOSED | INTEGRATED | INTEGRATION VERIFIED | NOT APPLICABLE | COMPLETE |
| VP-01A | Village politics stage: Audit of the reeve, guard pay and succession decision points | 21 | PROPOSED | NOT STARTED | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| VP-01B | Village politics stage: Offices and civic work | 21 | PROPOSED | NOT STARTED | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| VP-01C | Village politics stage: Voting and the election lifecycle | 21 | PROPOSED | NOT STARTED | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| VP-01D | Village politics stage: Political consequences in village life | 21 | PROPOSED | NOT STARTED | NOT APPLICABLE | NOT APPLICABLE | OPEN |
| VP-01E | Village politics stage: Soak, calibration and owner review | 21 | PROPOSED | NOT STARTED | NOT APPLICABLE | NOT APPLICABLE | OPEN |

## Unapproved idea (8)

| ID | Item | Build | Approval | Implementation | Verification | Release | Completion |
|---|---|---|---|---|---|---|---|
| B12A-05 | Accessibility not yet added: text scaling, a colour-blind mode, key rebinding, turning off the blinking | 20+ | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-DEPLETE | Build 17 finding: 26-28 ore seams worked out a seed by day 365; resource depletion trend | 18 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-FOOD | Build 17 finding: missed meals for want of money (606-5,417 a year across seeds) | 20+ | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-HENS | Build 17 finding: chickens died out early on seeds 2 and 3 | 20+ | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-JOBS | Build 17 finding: unemployment of 6-30 adults at day 365 | 20+ | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-PERF | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) | 19 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| B17F-SIMREPORT | economy_sim reporting fixes: open pits counted as building sites; checkpoint lines not in the job log | 18 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |
| CAP-TOOLHOLDER | Design review: a villager holding a tool only for sale counts as a capability practitioner | 18 | PROPOSED | NOT STARTED | NOT TESTED | NOT APPLICABLE | OPEN |

## World design rule (32)

| ID | Item | Build | Approval | Implementation | Verification | Release | Completion |
|---|---|---|---|---|---|---|---|
| AGENT-01 | Controlled parallel development: at most two subagents at once (three agents with the lead), bounded tasks, no nested agents, only the lead runs long simulations; an agent summary in progress reports | 16 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| B17-DIR | Build 17 combined integration direction: continue MIN-D, DVW-A12, FARM-08 and MIN-C visual verification; reuse passing evidence; no new distributable without explicit owner approval | 17 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| B18-SCOPE | Build 18 stays combined: tracks A, B and C; multiplayer excluded | 18 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| MILE-01 | Milestone assignments are respected: nothing moves into Build 16 from the expansions (the Living Economy build, Build 19's NPC Judgment) without the owner | 16 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| MSW-01 | Minimum Sufficient Work: correctness mandatory, redundancy justified |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| PROS-01 | Parallel prospective development of Expansions 18 and 19 on isolated branches while Build 17 stays the priority; no merge, release or presentation as integrated gameplay before the reconciliation gates | 18 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| REL-CONT | Standing release model: continuous develop, test, release, advance; minor decisions made and documented |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| SIM-01 | Continuous long-run simulation testing: the longest run once per seed, monitored, with checkpoints |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| SIM-02 | Simulation monitoring: observe, never restart active runs without owner approval; check-ins from measured runtimes; prompt reporting |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-001 | World Design Rule 1: Material Interdependency |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-002 | World Design Rule 2: Professional Interdependency |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-003 | World Design Rule 3: Meaningful Recipes |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-004 | World Design Rule 4: Economic Consequences |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-005 | World Design Rule 5: Living World Independence |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-006 | World Design Rule 6: Maintain the Existing Interlocking Systems Manifest |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-007 | World Design Rule 7: Automated Compliance |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-008 | World Design Rule 8: Player Knowledge and Wiki |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-009 | World Design Rule 9: Emergent Gameplay |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-010 | World Design Rule 10: Depth Without Obscurity |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-011 | World Design Rule 11: NPC Self-Improvement and Prosperity |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-012 | World Design Rule 12: NPC Competition and Economic Rivalry |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-013 | World Design Rule 13: Finite Resources and Actual Consumption |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-014 | World Design Rule 14: Graveyards, Ancestry, and NPC Legacy |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-015 | World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-016 | World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-017 | World Design Rule 17: Generational Memory and Living History |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-018 | World Design Rule 18: Protected Ecological Continuity |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-019 | World Design Rule 19: Living Political Agency and Democratic Consequences |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-020 | World Design Rule 20: Autonomous Housing |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-021 | World Design Rule 21: Household Succession and Family Care |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WDR-022 | World Design Rule 22: A Village Is Allowed to Fail; the Simulation Is Not |  | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |
| WIKI-01 | Permanent wiki and documentation maintenance: a feature is not complete without accurate documentation; player-facing in-game wiki and developer reference kept separate; updated in the same workstream; implemented-only; reported; a release documentation gate | 17 | OWNER APPROVED | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE | COMPLETE |

## Owner decisions (211)

| ID | Question | Build | Disposition | Blocks implementation |
|---|---|---|---|---|
| ARMOR-Q | Armour scope: Option A (exact text to be presented) | owner decision | APPROVED |  |
| B18-DP-01 | PL1-10: finish production chains (attendants work the player's stations), stall goods display, shops in leased village houses with existing systems? | 18 | APPROVED |  |
| B18-DP-02 | PL2-008: treat ROOMS-18 as the answer to its open question and close on playtest (villager modules and module signs not in its text)? | 18 | APPROVED |  |
| B18-DP-03 | PL2-014: close with PL2-008 on playtest (module signs not in its text)? | 18 | APPROVED |  |
| B18-DP-04 | PL2-015: build coops/shelters, trapping, watering, buying animals with existing systems; no rebalancing; Farming skill speeds but never gates; bought seed from sellers' stock; hired help stays later (not Build 18)? | 18 | APPROVED |  |
| B18-DP-05 | SET-D: settlement development at lighter detail from existing rules (trade switching with lasting unmet demand, capacity follows workers, no off-map housing yet), closed by a 365-day multi-generation run? | 18 | APPROVED |  |
| B18-DP-06 | WDR-004-C: close by the Build 18 long runs (100 and 365 days) and a scarcity-response audit, no new mechanic? | 18 | APPROVED |  |
| B18-DP-07 | WDR-011-C: a light Build 18 aspiration model over the five domains from villagers' real state, steering existing choices (Build 19 adds personality), or move it to Build 19? | 18 | APPROVED |  |
| B18-DP-08 | WDR-012-C: specialization by local prices, hiring competition by wage offers within existing rules, relocation of failing stalls? | 18 | APPROVED |  |
| B18-DP-09 | STONE-D1 recommendation: 3 raw stone -> 2 blocks + 1 rubble at Masonry 1, existing Masonry save/bonus tiers; today's building costs kept where maintenance and reconstruction cannot be told apart? | 18 | APPROVED |  |
| B18-DP-10 | STONE-D2 recommendation: forge_chisel 1 iron bar, 30 min, Smithing 1; durability 150 (the mallet's); one wear per dressing; value by the existing forged-tool rule? | 18 | APPROVED |  |
| B18-DP-11 | CHAPEL-R5: chapel art not a release blocker (a sign or bell-cote from an owned pack if one fits)? | 18 | APPROVED |  |
| B18-DP-12 | CHAPEL-R1: let the player volunteer on the church field by the villagers' rule? | 18 | APPROVED |  |
| B18-DP-13 | X18-FEES and CON-08-Q: ship the provisional courier fees and the 50-coin signing threshold as Build 18 values? | 18 | APPROVED |  |
| B18-DP-14 | Q18-6: confirm the reading that settlements develop different profiles because their resources, trades and people differ (Q18-3)? | 18 | APPROVED |  |
| B18-DP-15 | WDR-002-C: give the sage a trade that depends on it (recommended: guards keep healing goods bought from the sage), or record the sage as a deliberate exception? | 18 | APPROVED |  |
| B18-DP-16 | ECON-P3's title also lists 'quotes follow money, stock days, market hire wages' (agent proposals P3.2-P3.4 in docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md lines 183-187). The owner's answer approved the separation of business and household money only. Are P3.2-P3.4 part of the approved Build 18 requirement, or should they be split off as unapproved proposals? | 18 | APPROVED |  |
| BANDIT-Q | Should outlaws ever return once the band is wiped out? | owner decision | APPROVED |  |
| BARBER-Q | Barber: staffing, place, price and what counts as a haircut | owner decision | APPROVED |  |
| CARAVAN-TMP | The daily caravan allowance is a labelled, adjustable temporary stand-in for unsimulated outside settlements during Builds 15-16 (30 coins a day) | 15 | SUPERSEDED |  |
| CHAPEL-R1 | Should the player be allowed to volunteer on the church field? (Today only villagers and the clergy work it.) | 18 | APPROVED |  |
| CHAPEL-R2 | Can offerings sustainably fund the clergy's wages (3 and 2 coins a day, unpaid days owed up to 14)? Needs long-run evidence before the owner decides. | 18 | APPROVED |  |
| CHAPEL-R3 | Can old-save migration preserve the existing wild plants and other objects on the chapel ground instead of removing them (22 plants today)? | 18 | APPROVED |  |
| CHAPEL-R4 | Does the chapel's placement change seeded hidden-ore locations in a way that violates the determinism or save-compatibility requirements? | 18 | APPROVED |  |
| CHAPEL-R5 | Does the chapel need distinct artwork (steeple, sign) before the Build 18 release? | 18 | APPROVED |  |
| COMP-R1 | Hiring competition (WDR-012-C): is a raise of at most 3 coins over the manor day wage (6 to 9) acceptable as the ceiling, and should construction helpers and business attendants also raise wages when places go unfilled? Provisional working values; non-blocking review | 18 | APPROVED |  |
| CON-08-Q | Numerical formal-signing threshold for service contracts (owner to choose; 50 coins remains the working default) | owner decision | APPROVED | yes |
| CON02-S-1 | Service advances: should a buyer advance a seller's costs (e.g. assay fees), or the seller bear them (current default)? | owner decision | APPROVED |  |
| CON02-S-2 | Pay for work or for results: is a barren survey reading paid (current default: yes, work is paid)? | owner decision | APPROVED |  |
| CON02-S-3 | Incomplete or disputed service work: lapse with the reserve returned and finished units paid (current default), or another rule? | owner decision | APPROVED |  |
| CON02-S-4 | Should harvest be offered as a service contract (the harvest-hire rules now belong to paid quests kept by Q-C2)? | owner decision | APPROVED |  |
| CON02-S-5 | Which real need should make a villager hire a service on its own (none yet, so the live economy is unchanged)? | owner decision | APPROVED |  |
| CON02-S-6 | Confirm the 50-coin formal signing line for services as for goods | owner decision | APPROVED |  |
| E22-OD-03 | Knowledge persistence: how industrial knowledge passes on (teaching, apprenticeship, written records) or is lost when skilled people die or leave; Build 18 keeps it only in living people | 22 | OPEN |  |
| E22-OD-04 | Regional trade and transport: do traders' trips take real travel time, carry limited loads and risk loss on routes (replacing the instant six-day road trade), and do settlements trade with each other beyond the village | 22 | OPEN |  |
| E22-OD-05 | Population across the region: should off-map settlements get housing and land that limit growth (REG-DEMO-D1 left this to future systems), and may whole settlements be abandoned | 22 | OPEN |  |
| E23-OD-01 | Bandit factions: territory and jurisdiction, how many factions may exist and how they form, how leadership changes, and whether crimes act only on real inventories reached by real travel | 23 | OPEN |  |
| FARM-08-Q-CROP | How is a field's crop divided among the farmers who work it? |  | APPROVED |  |
| HORSE-Q | Plough horse: price and what it does | owner decision | APPROVED |  |
| ID-D1 | Identity: when an heir takes over, does the village's view of the player carry on to the heir (Build 18 behaviour), or do the parent's ties stay with the parent's own identity while the heir starts from the ties they had as a villager? | unassigned | APPROVED |  |
| ID-D2 | Identity changes the determinism gate: off-map people and player characters now draw ids from the one counter, so later villagers' ids shift and id-seeded pair chemistry diverges from Build 18 (seeds 1 and 2 differ from day 10; no leaks). Options: (a) one counter as built, accept a new gate baseline; (b) off-map people and player characters in a separate id band (1,000,000+): village ids match Build 18 and day 10 is identical, day 30 still differs once a settlement-born person arrives keeping their id (inherent to the approved rule); accept a new baseline from that point. Either way a re-baseline is needed. Also: a kept heir-child record lets kin (a grandmother) take in that child's orphaned children, which Build 18 did not. | unassigned | APPROVED |  |
| ID-D3 | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its only divergences (day 13 on both seeds) come from arrivals keeping their permanent band id, which changes traits Build 18 hashes from the id (chapel piety, caravan taste, skill seed, willingness, sprite). Alternatively those traits could be seeded from a stored per-person seed so they no longer depend on the id value (a design change). | unassigned | OPEN |  |
| INV-Q1 | INV-18 borderline item classifications | owner decision | APPROVED |  |
| INV-Q2 | INV-18 upgrade acquisition and cost | owner decision | APPROVED |  |
| MIN-C-Q2 | Sharing or selling discoveries: proposed, not approved; no ownership, access or extraction-rights mechanics | owner decision | APPROVED |  |
| MIN-D-Q1 | Should a business or the player be able to commission a survey through CON-01 (needs a service-contract term, OD-LE-03)? | owner decision | APPROVED |  |
| MIN-D-Q2 | Should the player's tools and skills count toward the settlement's mining capability (built: they do not)? | owner decision | APPROVED |  |
| MIN-D-Q3 | Should trial pits yield dirt or topsoil items (with MIN-E's item decision)? | owner decision | APPROVED |  |
| MIN-E-Q1 | What is earth (topsoil, dirt, spoil) used for beyond backfill: topsoil on farmland, embankments, earthworks? | owner decision | APPROVED |  |
| MIN-E-Q2 | Should there be a spade (and its recipe) for digging earth? | owner decision | APPROVED |  |
| MIN-E-Q3 | Should staking a pit need the manor's leave or mining rights (cf. ECON-P1.2)? | owner decision | APPROVED |  |
| MIN-E-Q4 | Should 'excavator' become a job, or should capability level 3 count whoever digs? | owner decision | APPROVED |  |
| MIN-E-Q5 | Should bigger or overworld pits be built to allow spiral ramps and more layers? | owner decision | APPROVED |  |
| MIN-F-Q1 | Should unsupported spans collapse, supports decay and need repair, and ventilation and lighting be real needs? | owner decision | APPROVED |  |
| MIN-F-Q2 | Should tunnelling find hidden underground deposits, the manor post tunnelling and track jobs, and the carpenter make supports and track to sell (no villager tunnels on its own now)? | owner decision | APPROVED |  |
| MIN-F-Q3 | Should miners haul by minecart instead of carrying? | owner decision | APPROVED |  |
| MIN-F-Q4 | Should there be shafts between underground levels? | owner decision | APPROVED |  |
| MIN-F-Q5 | Should spoil be allowed back into tunnels below ground? | owner decision | APPROVED |  |
| MIN-F2-Q1 | Who makes mining equipment: should the carpenter make supports, ladders and minecarts for sale, and the manor buy supports and post repair work? (Without a maker the village never tunnels, hauls by cart or digs shafts on its own) | owner decision | APPROVED |  |
| MIN-F2-Q2 | Should an underground collapse injure or kill people beneath it (today they are moved to the nearest floor unharmed)? | owner decision | APPROVED |  |
| MIN-STONE-Q | Are quarry stone and building blocks different items? | owner decision | APPROVED |  |
| OD-01 | Owner decision: deposit sustainability (P1) and the mine wage (B7-006) | 17 | APPROVED |  |
| OD-02 | Owner decision: balance review of every provisional number | owner decision | OPEN |  |
| OD-03 | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | owner decision | OPEN |  |
| OD-04 | Owner decisions: chest and lock questions | owner decision | OPEN |  |
| OD-05 | Owner decisions: inner doorways, relaying survey plots | 18 | APPROVED |  |
| OD-06 | Owner decisions: farming (Farming skill, wheat versus wages) | 18 | APPROVED |  |
| OD-07 | Owner decision: hunting in Gather mode | owner decision | OPEN |  |
| OD-08 | Owner decision: is honest arbitrage intended? | 18 | APPROVED |  |
| OD-09 | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | owner decision | OPEN |  |
| OD-10 | Owner decision: a lasting stone source before Build 17 (stone runs out by day 160-190 and stalls house building) | 16 | SUPERSEDED |  |
| OD-11 | Owner decision: an orphaned child for whom no household is eligible: what temporary care applies (stay in the family house watched by neighbours, lodge at the manor, other) | 16 | APPROVED |  |
| OD-12 | Owner decision: choosing between equally close eligible relatives (for example two grandparent households, or an aunt and an uncle) | 16 | APPROVED |  |
| OD-13 | Owner decision: crowded families that no member can leave (two parents, young children, often a grandparent, more people than beds). Should young children share beds, so such a family is not crowded? Should the original village houses be extendable with living quarters (the ground under them surveyed as parcels)? Both, or neither? | 15 | APPROVED |  |
| OD-14 | Owner decision: no original village house has room for the living-quarters module. The module is house-sized (9x10), must touch the house and cannot cover a road; on the current layout every original house is hemmed in. Options: (a) detached quarters on nearby free ground, counted as the household's rooms; (b) a smaller added room (a new building type); (c) accept that original houses do not expand, and rely on bed sharing, households splitting and new houses. | 15 | APPROVED |  |
| OD-15 | Should the player's sales stop at a trader's 15-coin floor, as villagers' sales do (B7-008)? | 15 | APPROVED |  |
| OD-16 | The village's trade economy stops around day 120-140 on seed 1 (smith out of coins, no iron, no axes, no timber): how should money flow back to the essential trades? | 15 | APPROVED |  |
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' against the confirmed 'not the chosen one'), C10 the view (top-down at an angle, three-quarter, or isometric; with DGA-D1), and Steam Deck labelling (the spec's '(web)' build; the owner said to correct the label without changing the platforms). Class progression is REC-010, ranged combat REC-009, Mote REC-002, the API 36 policy REC-003 | 16 | OPEN |  |
| OD-18 | Player-only perks and rules found by the DVW-A8 and DVW-A12 audits | owner decision | APPROVED |  |
| OD-19 | PAR-02: the universal coin-reserve threshold | owner decision | APPROVED |  |
| OD-20 | PAR-05: should a caught pickpocket's cry (theft rules 2026-10-18; the Stealth guard_radius perk) become a report like assault's? | 16 | APPROVED |  |
| OD-21 | Explicit time model and calendar consistency (approved architectural decision) | owner decision | APPROVED |  |
| OD-22 | Which definition the shared farming model starts from (per-cell, per-field, or an explicit difference) | owner decision | APPROVED |  |
| OD-23 | What the manor's fields cost their farmers (lease, crop share, or free to any farmer) | owner decision | APPROVED |  |
| OD-24 | Rent for villager merchants' stalls (pay as the player does, or the player's pitch free) | owner decision | APPROVED |  |
| OD-25 | Owner decision resolution for Build 16 (2026-10-21): FARM-07 2 coins a week; FARM-01/02 variable plots, materials from the perimeter; STALL-01/05 5% of completed sales after audits, rounding not approved; FSE-12 behind a switch with comparison; FSE-13 comparison then review; FSE-B06 deadwood interim; OD-20 witness reports; EQ-22 buying by need; OD-17 still blocked; DVW-A12 to Build 17; DVW-B6 to Build 18 | 16 | APPROVED |  |
| OD-26 | Owner decision 2026-10-21: one shared per-cell farming model for player, households and manor approved as the direction; no yield approved; both switches off; compare several shared yields (between about 0.9 and 3 wheat a cell) with seasonal farming on, identical seeds; investigate the seasonal milk collapse; recommend a yield for approval | 16 | APPROVED |  |
| OD-27 | Owner answers to the land and stall questions Q8-Q13 (2026-10-21) | 16 | APPROVED |  |
| OD-28 | Owner decisions for Build 17 (2026-10-21): enterable caves and underground mining; one deposit system everywhere; universal negotiated goods contracts; DVW-A12 direction | 17 | APPROVED |  |
| OD-29 | Owner decisions (2026-10-21): Build 17 starts now beside Build 16; separate underground maps tied to their surface locations, open pits on the surface; contract defaults provisional | 17 | APPROVED |  |
| OD-30 | Official expansion numbering: 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy; Exploration unnumbered; Multiplayer a separate track | owner decision | APPROVED |  |
| OD-LE-01 | Owner decision (Living Economy): Standalone build number and placement without displacing existing Build 19 Judgment | owner decision | APPROVED |  |
| OD-LE-02 | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules | 20 | APPROVED | yes |
| OD-LE-02B | Offer visibility: who can see an offer (in person at stalls and meetings, by word of mouth, a notice board), the remaining part of OD-LE-02 | 20 | OPEN |  |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | 20 | OPEN | yes |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | 20 | OPEN | yes |
| OD-LE-05 | Owner decision (Living Economy): Loan interest, collateral, default and collection rules | 20 | APPROVED | yes |
| OD-LE-05B | Interest and lending: whether loans carry interest or fees, who may lend money, and collection procedures (the remaining part of OD-LE-05) | 20 | OPEN |  |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | 20 | OPEN | yes |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | 20 | OPEN | yes |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | 20 | OPEN | yes |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | 20 | OPEN | yes |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | 20 | OPEN | yes |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | 20 | OPEN | yes |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | 20 | OPEN | yes |
| OD-LE-13 | Owner decision (Living Economy): Contract cancellation, penalties and death of a party | 20 | APPROVED | yes |
| OD-LE-13B | Death of a party to a contract: does the contract end, pass to the heir or the household, or go to the estate (the remaining part of OD-LE-13) | 20 | OPEN |  |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | 20 | OPEN | yes |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | 20 | OPEN | yes |
| OWN-09 | Build 8 private only; registry public-only; no sustainability changes until decided |  | APPROVED |  |
| P21-RESIDENCY | How long must an adult live in a settlement to count as an established resident (to vote and stand for mayor)? | 21 | OPEN |  |
| P21-STRUCTURE | Beyond the elected mayor: councils and their powers, the manor or a lord's authority over the village, regional government, and whether smaller settlements have simpler government | 21 | OPEN |  |
| PACK-Q | Pack capacity: how many kinds the player can carry | owner decision | APPROVED |  |
| Q-C1 | CON-01 Q-C1: Manor tool orders stay separate from CON-01 (advance payment preserved; counted as obligations) | 17 | APPROVED |  |
| Q-C2 | CON-01 Q-C2: Paid work quests stay separate (full payment on completion or none) | 17 | APPROVED |  |
| Q-C3 | CON-01 Q-C3: opportunity_weight = 1.0 (a seller weighs what the same hours earn in its own trade) | 17 | APPROVED |  |
| Q-C4 | CON-01 Q-C4: risk_margin = 0.15 (a scheduling buffer on work-time estimates, not a profit margin) | 17 | APPROVED |  |
| Q-C5 | CON-01 Q-C5: cancel_premium = 0.10 per recorded early cancellation with the same seller, 14-day record window; no blacklisting | 17 | APPROVED |  |
| Q-C6 | CON-01 Q-C6: formal_total = 50 coins; smaller agreements unsigned and may be concluded remotely; formal ones signed physically | 17 | APPROVED |  |
| Q-C7 | CON-01 Q-C7: sign_reach = 3 tiles, same place and level; the reeve represents the manor | 17 | APPROVED |  |
| Q-C8 | CON-01 Q-C8: offer_days = 2: an unsigned formal agreement expires after two days, nothing reserved or moved before signing | 17 | APPROVED |  |
| Q-C9 | CON-01 Q-C9: npc_counter_tolerance = 0.25 above the buyer's own price, within its real purchasing power; quantity limits and 10-day wait kept | 17 | APPROVED |  |
| Q-POL-1 | Political structure of the starting village (manor with a reeve, elected mayor, council, or a mix; what the lord retains) | 21 | OPEN | yes |
| Q-POL-2 | Franchise: who votes and who may stand | 21 | APPROVED | yes |
| Q-POL-3 | Office terms, election season and by-elections (with the 8-day game year) | 21 | APPROVED | yes |
| Q-POL-4 | Vote privacy and which totals are public | 21 | OPEN | yes |
| Q-POL-5 | Ties in elections | 21 | OPEN | yes |
| Q-POL-6 | Removal from office | 21 | OPEN | yes |
| Q-POL-7 | Placement and gate: politics waits for Expansion 19's live judgment, or an interim voter model behind a switch | 21 | OPEN | yes |
| Q-POL-8 | The constable and the law: a constable and crime records before Expansion 22; the friendly guard (X19 conflict 3) | 21 | OPEN | yes |
| Q-POL-9 | Taxes under an elected authority and DVW-B5's predictability | 21 | OPEN | yes |
| Q18-1 | Q18-1: Carpentry, Masonry (stoneworking) and Tanning become skills of their own, seeded from existing Crafting experience |  | APPROVED |  |
| Q18-10 | Anyone may buy from another settlement; the buyer fetches the goods or pays a willing carter; no free delivery, no merchant-only buying, nothing created | 18 | APPROVED |  |
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | 18 | PROVISIONAL |  |
| Q18-11A | Which compensation and productivity percentages per industry and level 0-10? (Candidate +20% output / +8% pay at level 10, diminishing; research-informed proposal, NOT approved) |  | APPROVED |  |
| Q18-11B | How do worker experience, tools, facilities and infrastructure compose a settlement's capability rating? (Options to be presented; no weighting or permanent advancement system without approval) |  | APPROVED |  |
| Q18-12 | May a buyer hire a villager or carter to haul goods between settlements, and on what terms (day wage, fee per load, or a negotiated service contract)? Overlaps OD-LE-03 and MIN-D-Q1 | 18 | APPROVED |  |
| Q18-13 | Should CON-01 contracts gain parties for households and off-map settlements, or should a household buy through a named member and a region through a named merchant? | 18 | APPROVED |  |
| Q18-14 | Q18-14: a new Law skill qualifies a courier to notarise |  | APPROVED |  |
| Q18-15 | Q18-15: any business with a shop may open its own courier booth |  | APPROVED |  |
| Q18-16 | Q18-16: with no free stall, the village courier builds a booth near the market |  | APPROVED |  |
| Q18-2 | Q18-2: first industries are forestry, carpentry, masonry, smithing, farming, tanning, trade and mining |  | APPROVED |  |
| Q18-3 | Q18-3: off-map settlements are simulated economies like this one (money from their villagers, government and companies), same rules at lighter detail |  | APPROVED |  |
| Q18-4 | Q18-4: five off-map settlements of mixed kinds |  | APPROVED |  |
| Q18-5 | Q18-5: barter and credit with trust |  | APPROVED |  |
| Q18-6 | Q18-6: may abstract regions show 'two settlements develop different profiles' | 18 | APPROVED |  |
| Q18-7 | Q18-7: migration both ways between the village and the other settlements, for reasons |  | APPROVED |  |
| Q18-8 | Q18-8: visiting other settlements in person stays at Build 20 or later (SET-E) |  | APPROVED |  |
| Q18-9 | Settlement capability levels affect pay scales and production output only; never a permission gate | 18 | APPROVED |  |
| REC-D1 | Flight recorder: available in playtest and development builds only (Settings, Diagnostics), off by default, never in public releases? | 19 | APPROVED |  |
| REC-D2 | Flight recorder storage cap: stop and mark the session incomplete, or rotate out the oldest days? | 19 | APPROVED |  |
| REC-D3 | Flight recorder per-tick quantities (hunger, movement, work minutes): hourly samples plus threshold events rather than per-frame records? | 19 | APPROVED |  |
| REC-D4 | Flight recorder money attribution: move the hottest coin-change sites to one transfer helper (touches Build 18 code paths, gate identical), or rely on balance reconciliation only? | 19 | APPROVED |  |
| REG-BUY-D1 | When the village buys food from a settlement, may the settlement's sellers sell food its own households will need (the market decides), or do they release only a surplus above their own households' needs? | 18 | APPROVED |  |
| REG-CIRC-D1 | Coins paid to Garton for ore pile up in Garton's households with nothing to buy (no maker there and the traders carry no finished goods), so they never return. Should the traders also carry finished goods a settlement's households want and cannot make (a design change), or is this one-way flow a legitimate outcome? | 20+ | DEFERRED |  |
| REG-DEMO-D1 | Off-map settlements now follow the village's birth rule with no housing limit (the village has houses; the settlements have none, by lighter detail). In a settlements-only year they grow from 261 to 735 people, and Higham and Wulstead outgrow their harvests (74 and 30 hunger deaths). Should settlement births be limited by a housing or land capacity, as the village's are by houses, or is growth to the food limit the intended outcome? | 18 | APPROVED |  |
| REG-WAGE-D1 | Merge the necessity-wage correction (wip/b18-wagefix): a settlement business pays its hungry worker household that cannot buy a day's food even below its working reserve (PAR-02A)? It removes 9 of Higham's 10 deaths in 200 days; nothing else changes. | 18 | APPROVED |  |
| ROAD-01 | Five-build roadmap: 15 simulation stabilization, 16 long-term equilibrium, 17 Mining & Industrial, 18 Settlement & Regional Economy, 19 NPC Judgment | 15 | APPROVED |  |
| SIM-F2 | Recorder finding F2: a stonecutter re-chose a failing iron-chisel purchase 328 times in one day (day 2, seed 1), losing a working day; same re-decision family as REC-F1. Approve a narrow fix? | 19 | OPEN |  |
| SIM-F3 | Recorder finding F3: bandits stalking at night leave their plan empty, so the brain re-decides every tick (400+ empty decisions a day each); behaviour works through the chase target. Approve giving the stalk a lasting plan step (performance fix, no behaviour change intended)? | 19 | OPEN |  |
| SIM-F4 | Recorder finding F4: the whole bandit band died within nine days; a bandit's only food purchase (_bandit_market) needs 15 coins and at least 60% health, so an injured or starving bandit with money cannot buy food. Confirm with death causes first; then should the health gate stop blocking food purchases? | 19 | OPEN |  |
| SJD-Q01 | Judgment open decision: Should there be a NEUTRAL objective event type, or must every judged event begin GOOD/BAD? | 19 | APPROVED |  |
| SJD-Q02 | Judgment open decision: Should scores decay, or change only through new events, forgiveness and corrected beliefs? | 19 | APPROVED |  |
| SJD-Q03 | Judgment open decision: Different disposition thresholds per NPC, or one calibrated scale? | 19 | APPROVED |  |
| SJD-Q04 | Judgment open decision: Should very large GOOD and BAD totals with NET near 0 create ambivalence behaviour? | 19 | APPROVED |  |
| SJD-Q05 | Judgment open decision: How much may prior judgment bias interpretation of ambiguous events? | 19 | APPROVED |  |
| SJD-Q06 | Judgment open decision: How should confidence and rumours influence points: multiplier, threshold, or separate belief layer? | 19 | APPROVED |  |
| SJD-Q07 | Judgment open decision: How far should gossip spread; should reach depend on social proximity and personality? | 19 | APPROVED |  |
| SJD-Q08 | Judgment open decision: How should legal guilt, moral judgment and personal loyalty interact? | 19 | APPROVED |  |
| SJD-Q09 | Judgment open decision: Always highest utility, or sometimes near-optimal via seeded randomness? | 19 | APPROVED |  |
| SJD-Q10 | Judgment open decision: What judgment information, if any, can the player see? | 19 | APPROVED |  |
| SJD-Q11 | Judgment open decision: How should memory persistence and forgiveness vary by severity? | 19 | APPROVED |  |
| SJD-Q12 | Judgment open decision: What makes an event important enough to score? | 19 | APPROVED |  |
| SJD-Q13 | Judgment open decision: How should individual decision weights be learned, configured or tuned? | 19 | APPROVED |  |
| SJD-Q14 | Judgment open decision: Which domain gets the first live integration after the prototype? | 19 | APPROVED |  |
| STONE-D1 | Stone dressing efficiency values by skill (STONE-04) and the materials rule's numbers | 18 | APPROVED | yes |
| STONE-D2 | Iron chisel wear and recipe (STONE-06) | 18 | APPROVED | yes |
| STONE-Q | STONE-01 follow-up questions: fittings/mending on blocks, dressing waste, a mason trade | owner decision | APPROVED |  |
| STONE-Q1 | STONE-Q part 1: materials match the actual construction or repair (raw stone, blocks, or both) |  | APPROVED |  |
| STONE-Q2 | STONE-Q part 2: stone lost in dressing depends on the worker's skill (Option C), Expansion 18 |  | APPROVED |  |
| STONE-Q3 | STONE-Q part 3: a dedicated Stoneworking skill and a mallet plus iron chisel (1B + 2B), Expansion 18 |  | APPROVED |  |
| STONECUT-R1 | WDR-002: the stonecutter (X18-STONECUT) supplies no other profession; its building blocks are bought by the raw-goods merchant and built into houses and workshops by households and the manor, and the game has no builder trade. Approve a documented exception with checked evidence, as for the sage (B18-DP-15), or direct another remedy? | 18 | APPROVED | yes |
| TAILOR-Q | Where the tailor comes from | owner decision | APPROVED |  |
| X18-D1 | Expansion 18 D1: starting experience seeded once from recorded skills (farming from PAR-01A history) |  | APPROVED |  |
| X18-D2 | Expansion 18 D2: what limits effective capability | 18 | APPROVED |  |
| X18-D3 | Expansion 18 D3: no thresholds on the 0-10 levels; novice/journeyman/master names in player reports |  | APPROVED |  |
| X18-D4 | Expansion 18 D4: industry for unattributed work (stall trade to trade; slaughter, clearing, fencing to farming; survey and digging work to mining; hunting, foraging, building, hauling none; player's cancelled actions credit seconds worked) |  | APPROVED |  |
| X18-D5 | Expansion 18 D5: real-valued levels interpolate between whole-level table values |  | APPROVED |  |
| X18-D6 | Expansion 18 D6: posted manor job wages are fixed when the job is taken, at the taker's effective level |  | APPROVED |  |
| X18-D7 | Expansion 18 D7: crop shares split by work done (minutes x the cutter's own work rate) |  | APPROVED |  |
| X18-D8 | Expansion 18 D8: wages with skill modifiers round to the nearest whole coin |  | APPROVED |  |
| X18-D9 | Expansion 18 D9: experience is dropped at the next dawn after death or departure |  | APPROVED |  |
| X18-FEES | Courier fee coefficients and the small-agreement threshold (X18-Q12, X18-Q13) | 18 | APPROVED |  |
| X19-ASSAULT | Should being assaulted oneself be a permanent memory (the proposed threshold makes it so; at the stress rate victims accumulate many)? | 19 | APPROVED |  |
| X19-BOND-LIMITS | Do specific relationship or reputation effects need additional balancing limits? | 19 | OPEN |  |
| X19-CRT12 | Courtship proposals use fixed notoriety and regard cut-offs (CRT-12); keep 'no marrying a killer' absolute and weigh the rest with judgment, or keep the cut-offs? | 19 | APPROVED |  |
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | 19 | PROVISIONAL |  |
| X19-EVENT-Q | Expansion 19 event feeds raised four questions: (1) should a guard killing an assailant count as a killing (today it does: the game cannot tell them apart)? (2) should first acquaintance be recorded as a meeting fact? (3) should a late repayment score as a fair deal? (4) self-defence cannot yet be told from an attack: add that distinction later? | 19 | OPEN |  |
| X19-GOSSIP-FLOOR | Gossip closeness (X19-Q-TIMING): a story passes between strangers with the agent-proposed chance gossip.closeness_floor_permille = 500 (half the time), rising to certain between the closest friends. Keep 500, or another value? | 19 | OPEN |  |
| X19-GUARD | A guard who is the player's friend waives the fine (CRT-06) while SJD-Q08 says a guard can like someone and still enforce: keep, always enforce, or let friendship reduce but never waive the fine? | 19 | APPROVED |  |
| X19-HARMED | Relations.harmed lowers the player's standing with a victim's kin and friends instantly; when judgment is live, should word of mouth carry it instead (SJD-Q07 no instant broadcasts)? | 19 | APPROVED |  |
| X19-PERS-FORMULA | The numerical formulas for personality evolution (rates by frequency, severity and duration; soft limits; learning acceleration; emotion length; recovery) | 19 | OPEN |  |
| X19-PERSONALITY | Agent-proposed numbers for per-person temperament (SJD-Q03, Q13): tolerance and weights vary by up to 30% between people; being wronged lowers tolerance 4% per severity point, being helped raises regard for opinion 3% per point, at most 25% either way; a shift applies to all dealings, not only the kind of deed. Keep, or change? | 19 | OPEN |  |
| X19-Q-TIMING | Gossip timing: keep 'spread' (identical results to telling an hour's meetings at once; rare long catch-up frames ~8.6 ms on a phone) or allow 'scheduled' (each meeting at its own seeded minute: smallest frames, but word passes at different times, so outcomes differ slightly)? | 19 | APPROVED |  |
| X19-REGARD | Relations regard is both trust (believing stories) and harm (a seen crime lowers it), so victims believe culprits less: accept this coupling or separate trust from regard? | 19 | APPROVED |  |
| X19-REP-TRANSMIT | The numerical formulas for family reputation transmission (how stories, their significance and retelling set an inherited impression) | 19 | OPEN |  |
| X19-RUNNERUP | Near-best choices (SJD-Q09): the agent-proposed chance that a villager takes a close second instead of the best option is 150 permille (15%), only among options within 2 points of the best. Keep 15%, or another value? | 19 | OPEN |  |
| X19-SPILL-REACH | How far does reputation spillover reach through extended family (parents, children, siblings, cousins, in-laws)? | 19 | OPEN |  |
| X19-TRAIT-DIST | Population trait distributions and learning percentages beyond the approved 30% stubbornness potential | 19 | OPEN |  |
| X19-TRUST-RATES | Agent-proposed numbers for Expansion 19 awaiting the owner: trust starts at a quarter of liking (a stranger at 0); a fair deal +4 trust, a cheat or false accusation -20, a rumour borne out +4 for the teller, one shown false -15; trust does not fade; a friendly guard halves a theft fine (at least 1 coin). Keep, or change any? | 19 | OPEN |  |
| XEXPL-D1 | Decision explainability: is an optional player-inspection panel wanted in this generation of builds, or only in-world explanation (dialogue, rumours, notices) for now? | unassigned | OPEN |  |

