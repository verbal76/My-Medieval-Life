# Decision authority: what governs now

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write` (tools/decision_authority.py, HAG-AUTH-01). Do not edit.

Before any significant change, find its record here and follow `Governing record` to the decision in force. A document outside the register that disagrees with an ACTIVE record is historical unless the register says otherwise.

## Current authority

| | |
|---|---|
| Development line (code) | `wip/b25r2-rev2` |
| Records branch | `wip/requirements-control` |
| Frozen / historical branches (never resume work on them) | `wip/expansion20`, `wip/b25r1`, `wip/b25r2-playtest`, `staging/my-medieval-life` |
| Set by | owner 2026-11-09 resolutions to HAG-AUTH-01, decision 3 (docs/directives/2026-11-09_owner_resolutions_hag_auth_01.md): development line wip/b25r2-rev2, records branch wip/requirements-control kept separate (BRANCH-POL-Q1/Q2, DEV-LINE-B25). Update this block when the owner names a new line. |

## Lifecycle counts

| Lifecycle | Records |
|---|---|
| ACTIVE | 904 |
| SUPERSEDED | 43 |
| COMPLETED | 246 |
| REJECTED | 3 |
| DEFERRED | 19 |
| UNDER REVIEW | 78 |

## Superseded records and what governs instead

| Record | Title | Superseded by | Governing record now | Governing lifecycle | Why superseded |
|---|---|---|---|---|---|
| AGENT-01 | Controlled parallel development: at most two subagents at once (three agents with the lead | PAR-AGENTS-01 | PAR-AGENTS-01 | ACTIVE | owner resolutions to HAG-AUTH-01 decision 1: the worker-count subject is governed by PAR-AGENTS-01; AGENT-01 was superseded 2026-11-02 by MM |
| AR-P1-1 | Prepared; owner must create key | B13-15 | ANDROID-RELEASE-SIGNING | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B12A-04 | Not recorded as done | FR-04 | FR-04 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B12A-06 | Sword page added by CQ-01 (`3e283b6`); others not recorded | FR-06 | FR-06 | COMPLETED | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B12A-09 | RTK token tool persistence in the cloud environment (owner action) | ENV-RTK | ENV-RTK | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B12A-11 | "Not investigated further" | FR-05 | FR-05 | COMPLETED | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B13-15 | Android signing stability | ANDROID-RELEASE-SIGNING | ANDROID-RELEASE-SIGNING | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). Owner 2026-10-20 deferred the permanent signing |
| B25-CLOSE-02 | Close Build 25 under strict scope: finish the targeted tests, freeze one SHA, ONE final ye | B25-SCOPE-REGION | B25-SCOPE-REGION | ACTIVE | per docs/audits/B25R1_REQUIREMENTS_AUDIT_2026-11-05.md and the register's own 2026-11-02 history: the strict-scope freeze of 4b51c92 was ove |
| B25R2-Q3 | Public release or private draft for Play Test Build One? | B25R2-DRAFT-01 | B25R2-DRAFT-01 | ACTIVE | HAG-AUTH-01 retroactive audit 2026-11-09: same question (Play Test Build One visibility) answered again the same evening: DRAFT-01 'private  |
| B7-017 | No building in a year (no births) | EQ-07 | EQ-07 | COMPLETED | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B8R-005 | Hunger icon looked like coin bag | B8-019 | B8-019 | COMPLETED | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| B8R-006 | Where to cook raw meat | FR-03 | FR-03 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| CARAVAN-TMP | The daily caravan allowance is a labelled, adjustable temporary stand-in for unsimulated o | ECON-P1.3 | ECON-P1.3 | ACTIVE | the owner's answer of 2026-10-23 (docs/directives/2026-10-23_owner_answers_caravan_purses_skills.md): the caravan becomes the settlements' t |
| DGA-D3 | Connectivity with no server | MP-D5 | MP-D5 | ACTIVE | DOC-RECON-01 consistency (checker rules): names the replacing record |
| ECON-P1.4 | Prospecting new seams (:74) | MIN-C | MIN-C | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| EMP-CONTRACT-01 | Contracted services: the player negotiates a specific task or quantity (e.g. 50 iron ore)  | CON-02 | CON-02 | ACTIVE | Owner decisions docs/directives/2026-10-23_dp15_dp16_con02_empperm.md |
| F-2 | Births, children, aging, family growth | B8-029 | B8-029 | COMPLETED | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| F-3 | Music and sound | FR-08 | MUSIC-18 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| FR-08 | Music and sound | MUSIC-18 | MUSIC-18 | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). Stale BLOCKED ('no audio supplied'): the owner  |
| FSE-11 | Village sowing consumes seed (seed consumption correction) | FARM-06 | FARM-06 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| GP-BASELINE-POLICY | Single-player baseline may be updated for intentional approved changes, with each differen | BASELINE-AUTH-01 | BASELINE-AUTH-01 | ACTIVE | owner resolutions to HAG-AUTH-01, 2026-11-09 (docs/directives/2026-11-09_owner_resolutions_hag_auth_01.md), decision 4: 'No agent has indepe |
| GP-STALL-TABLE-10 | Market stall table shows ten goods comfortably | GP-MARKET-SHELVES | GP-MARKET-SHELVES | ACTIVE | duplicate resolved: the owner's Craftpix market shelf directive (docs/directives/2026-10-24_build21_craftpix_market_stalls.md) replaced the  |
| JUICE-JD1 | Audio: may the owned Living Forest sounds be integrated as FR-08's first slice, which even | MUSIC-18 | MUSIC-18 | ACTIVE | DOC-RECON-01 consistency (checker rules): names the replacing record |
| K-3 | Every provisional number awaits the owner's balance review | OD-02 | OD-02 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritative | MP-MASTER | MP-MASTER | ACTIVE | register hygiene (owner 2026-10-30, X20-RESUME s.11): status corrected to match shipped evidence: superseded in scope by MP-MASTER (history  |
| OD-10 | Owner decision: a lasting stone source before Build 17 (stone runs out by day 160-190 and  | B7-007 | B7-007 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| OWN-12 | Build 7 corrections; "Not approved yet (investigate first)": mining wage 15+, 15-coin rese | OD-01 | OD-01 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| OWN-17 | Provisional numbers await a separate balance review | OD-02 | OD-02 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| OWN-21 | Every build published under GitHub Releases | OWN-09 | OWN-09 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| OWN-24 | Lizards and spiders as enemies | FR-01 | FR-01 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| OWN-29 | Era, county, atlas storage, Godot, Android, PCG32 | OD-03 | OD-03 | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). Proposal 'Era, county, atlas storage, Godot, An |
| Q-11 | Design gap assessment, phased sequence | OD-09 | OD-09 | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). The design-gap assessment's phased sequence (PR |
| REC-002 | Over-the-air updates on the Hot Attic Games Mote architecture (fully automatic) | OD-17 | OD-17 | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). Over-the-air fully automatic updates on the Mot |
| REC-010 | Class progression, 'system jobs' and a tech/research tree | OD-17 | OD-17 | ACTIVE | DOC-RECON-01 (owner 2026-10-31, docs/directives/2026-10-31_documentation_reconciliation.md). Open OWNER DECISION REQUIRED answered by a late |
| REC-015 | NPC competition and economic rivalry (as a game system) | WDR-012-C | WDR-012-C | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| REC-016 | NPC self-improvement and prosperity (as a game system) | WDR-011-C | WDR-011-C | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| REC-F1 | Recorder finding (10-day run, seed 1): villagers holding goods nobody buys ('holding unsol | FIX-RECF1 | FIX-RECF1 | COMPLETED | DOC-RECON-01 consistency (checker rules): names the replacing record |
| REL-14-16 | Release Builds 14, 15 and 16 (three platform packages each) when the eight release conditi | REL-15-18 | REL-15-18 | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| REL-CONT | Standing release model: continuous develop, test, release, advance; minor decisions made a | REL-OWNER-01 | REL-OWNER-01 | ACTIVE | owner resolutions to HAG-AUTH-01, 2026-11-09 (docs/directives/2026-11-09_owner_resolutions_hag_auth_01.md), decision 2: 'No automatic publis |
| REQ-BANDIT | Bandit factions, criminal careers and outlaw leadership | WDR-016-C | WDR-016-C | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| REQ-GRAVE | Graveyards, ancestry and NPC legacy | WDR-014-C | WDR-014-C | ACTIVE | master requirements reconciliation (docs/directives/2026-10-23_master_requirements_reconciliation.md) |
| X20-ACTIVATION-AUTHORITY | Does X20-RESUME's automatic Living Economy activation on objective readiness (2026-10-30)  | B25-LE-ACTIVATE-D1 | B25-LE-ACTIVATE-D1 | ACTIVE | HAG-AUTH-01 retroactive audit 2026-11-09: superseded for Build 25 by the owner 2026-11-01 (its own 2026-11-01 history line: 'Superseded for  |
| X20-REMAINING-PLACEMENT | Where does the remaining Expansion 20 scope go relative to the Build 25 freeze (LE-07, EMP | B25-SCOPE-D1 | B25-SCOPE-D1 | ACTIVE | HAG-AUTH-01 retroactive audit 2026-11-09: B25-SCOPE-D1 owner answer: 'The October 31 records assigning stranded-work recovery to Build 26 do |

## Active owner decisions and rules (in force; implementation status does not retire them)

| Record | Kind | Title | Supersedes |
|---|---|---|---|
| ARMOR-CATALOG-D1 | decision | Approve the armour catalogue: the four classes, the buffs (including the new fireball-damage buff), materials  |  |
| ARMOR-Q | decision | Armour scope: Option A (exact text to be presented) |  |
| B17-DIR | rule | Build 17 combined integration direction: continue MIN-D, DVW-A12, FARM-08 and MIN-C visual verification; reuse |  |
| B18-DP-01 | decision | PL1-10: finish production chains (attendants work the player's stations), stall goods display, shops in leased |  |
| B18-DP-02 | decision | PL2-008: treat ROOMS-18 as the answer to its open question and close on playtest (villager modules and module  |  |
| B18-DP-03 | decision | PL2-014: close with PL2-008 on playtest (module signs not in its text)? |  |
| B18-DP-04 | decision | PL2-015: build coops/shelters, trapping, watering, buying animals with existing systems; no rebalancing; Farmi |  |
| B18-DP-05 | decision | SET-D: settlement development at lighter detail from existing rules (trade switching with lasting unmet demand |  |
| B18-DP-06 | decision | WDR-004-C: close by the Build 18 long runs (100 and 365 days) and a scarcity-response audit, no new mechanic? |  |
| B18-DP-07 | decision | WDR-011-C: a light Build 18 aspiration model over the five domains from villagers' real state, steering existi |  |
| B18-DP-08 | decision | WDR-012-C: specialization by local prices, hiring competition by wage offers within existing rules, relocation |  |
| B18-DP-09 | decision | STONE-D1 recommendation: 3 raw stone -> 2 blocks + 1 rubble at Masonry 1, existing Masonry save/bonus tiers; t |  |
| B18-DP-10 | decision | STONE-D2 recommendation: forge_chisel 1 iron bar, 30 min, Smithing 1; durability 150 (the mallet's); one wear  |  |
| B18-DP-11 | decision | CHAPEL-R5: chapel art not a release blocker (a sign or bell-cote from an owned pack if one fits)? |  |
| B18-DP-12 | decision | CHAPEL-R1: let the player volunteer on the church field by the villagers' rule? |  |
| B18-DP-13 | decision | X18-FEES and CON-08-Q: ship the provisional courier fees and the 50-coin signing threshold as Build 18 values? |  |
| B18-DP-14 | decision | Q18-6: confirm the reading that settlements develop different profiles because their resources, trades and peo |  |
| B18-DP-15 | decision | WDR-002-C: give the sage a trade that depends on it (recommended: guards keep healing goods bought from the sa |  |
| B18-DP-16 | decision | ECON-P3's title also lists 'quotes follow money, stock days, market hire wages' (agent proposals P3.2-P3.4 in  |  |
| B18-SCOPE | rule | Build 18 stays combined: tracks A, B and C; multiplayer excluded |  |
| B19-BASELINE | decision | Approve the Build 19 determinism baseline on wip/build19 a7c84e9 (docs/design/BUILD19_BASELINE_PROPOSAL.md)? |  |
| B25-AMBITION-D4 | decision | Activate the career ambition system? |  |
| B25-BIZ-TENANT-Q | decision | May a household that does not own its house (a tenant, a family in a manor cottage) build a standalone worksho |  |
| B25-BUSINESS-D2 | decision | May villagers establish independent businesses? |  |
| B25-CAREER-D1 | decision | How is career advancement decided? |  |
| B25-CHAPEL-FOOD-Q | decision | The church plot (8x7 cells, replaces its own seed, ripens every 2 days) yields about 12-18 wheat a day; in a f |  |
| B25-ECON-P1 | decision | Business founding requires the trade's benches to be full and busy (Ventures.refusal, skilled_place busy_share |  |
| B25-ECON-P2 | decision | Coinless adults cannot take open miner or woodcutter places because those jobs need a tool and the manor's too |  |
| B25-ECON-P3 | decision | Retired villagers keep trade stock forever (day 120: 68 iron ore, 47 coal, 24 iron bars, 8 pickaxes, 7 axes he |  |
| B25-ECON-P4 | decision | Ore imports stall: Garton's quarry stock rose 63 to 175 but its trader had no coins to buy it, so 0 iron ore c |  |
| B25-ECON-P5 | decision | Village land (fields, trees, game, ore) is fixed while population roughly triples in a year, so unemployment r |  |
| B25-EMPLOY-D3 | decision | How do skilled occupations grow? |  |
| B25-LE-ACTIVATE-D1 | decision | Living Economy activation policy for Build 25 | X20-ACTIVATION-AUTHORITY |
| B25-NINE-D1 | decision | Organic skills, apprenticeship and career development |  |
| B25-NINE-D2 | decision | Informal services and expanded service contracts |  |
| B25-NINE-D3 | decision | Farming yield and food security |  |
| B25-NINE-D4 | decision | Individual crime-reporting judgment |  |
| B25-NINE-D5 | decision | Fully integrated materials and production economy |  |
| B25-NINE-D6 | decision | Armor classification and specialized bonuses |  |
| B25-NINE-D7 | decision | Ordinary clothing is cosmetic |  |
| B25-NINE-D8 | decision | Predefined capabilities and organic societal development |  |
| B25-NINE-D9 | decision | Game juice phases J1 and J2 |  |
| B25-SCOPE-D1 | decision | Is Build 25 the consolidation build containing all approved expansion work and all approved recoverable work f | X20-REMAINING-PLACEMENT |
| B25R1-015 | rule | Full approved Revision 1 scope is mandatory: no deferral, disabling, placeholder or narrowing without the owne |  |
| B25R1-AUDIT-OPT1 | decision | B25R1 requirements audit (2026-11-05): which completion path? Option 1 = finish validating the current code wh |  |
| B25R1-Q1 | decision | Stone roads: none exist in the game's data or the owned art packs (only dirt, sand and water path tiles). Shou |  |
| B25R1-Q2 | decision | Bandit band as a woodland community: move the band to a hidden overworld claim with a household (a), keep the  |  |
| B25R1-Q3 | decision | Water for wilderness settlements: wells built from real materials, streams added by an overworld generator cha |  |
| B25R1-Q4 | decision | Outlaw camp defenders: add a surrender outcome to combat, or fight or flee only (B25R1-014 section 8 'accordin |  |
| B25R1-Q5 | decision | Save compatibility for Revision 1: must existing saves migrate across the B25R1 world changes (generator, regi |  |
| B25R1-Q6 | decision | Population architecture for the reconstructed region (B25R1-018 section 6): full NPCs everywhere, or persisten |  |
| B25R1-Q7 | decision | Does the live-near-the-player rule (B25R1-Q6) also apply to the starting village's people, or only to the rest |  |
| B25R1-Q8 | decision | Town art gap (Higham, Wulstead, churches, chalk figure not store-quality; owned packs lack a stone market cros |  |
| B25R1-Q9 | decision | Do hamlets count as civic places (civic_records test premise), and with what institutions? |  |
| B25R2-BRUSHOFF | decision | Dialogue.brush_off reads n.plan[0] without checking the plan is empty (dialogue.gd:526): a SCRIPT ERROR when a |  |
| B25R2-CAVE | decision | A guest who followed the host into a cave was left in the black outside it, unable to move (the guest's copy o |  |
| B25R2-DRAFT-01 | decision | May Play Test Build One be published, and how? | B25R2-Q3 |
| B25R2-HOST4 | decision | Open to friends admits only one guest (the window asks for no player limit, so hosting defaults to 2): how man |  |
| B25R2-PKG-01 | decision | May the existing Windows package built from candidate 1f2ff4f (release run 42297641550, artifact pkg-full-wind |  |
| B25R2-Q1 | decision | Which source for Play Test Build One? |  |
| B25R2-Q2 | decision | How far should the My Folklore name change go in this release? |  |
| B25R2-Q4 | decision | How should the Claude usage budget be spent on the B25R2 repairs? |  |
| B25R2-STUTTER | decision | Walking south of the starter village to the next settlement froze the game for about a second every other step |  |
| B25R2-VER-01 | decision | How should the next Play Test Build One package identify itself? |  |
| BANDIT-Q | decision | Should outlaws ever return once the band is wiped out? |  |
| BARBER-Q | decision | Barber: staffing, place, price and what counts as a haircut |  |
| BRANCH-POL-Q1 | decision | Records line and code line: keep wip/requirements-control (records, lead-written) separate from wip/expansion2 |  |
| BRANCH-POL-Q2 | decision | Amend BRANCH-POL-01's rule text (CLAUDE.md section 5a, 'One integration branch for code: wip/expansion20') to  |  |
| CHAPEL-R1 | decision | Should the player be allowed to volunteer on the church field? (Today only villagers and the clergy work it.) |  |
| CHAPEL-R2 | decision | Can offerings sustainably fund the clergy's wages (3 and 2 coins a day, unpaid days owed up to 14)? Needs long |  |
| CHAPEL-R3 | decision | Can old-save migration preserve the existing wild plants and other objects on the chapel ground instead of rem |  |
| CHAPEL-R4 | decision | Does the chapel's placement change seeded hidden-ore locations in a way that violates the determinism or save- |  |
| CHAPEL-R5 | decision | Does the chapel need distinct artwork (steeple, sign) before the Build 18 release? |  |
| COMP-R1 | decision | Hiring competition (WDR-012-C): is a raise of at most 3 coins over the manor day wage (6 to 9) acceptable as t |  |
| CON-08-Q | decision | Numerical formal-signing threshold for service contracts (owner to choose; 50 coins remains the working defaul |  |
| CON02-S-1 | decision | Service advances: should a buyer advance a seller's costs (e.g. assay fees), or the seller bear them (current  |  |
| CON02-S-2 | decision | Pay for work or for results: is a barren survey reading paid (current default: yes, work is paid)? |  |
| CON02-S-3 | decision | Incomplete or disputed service work: lapse with the reserve returned and finished units paid (current default) |  |
| CON02-S-4 | decision | Should harvest be offered as a service contract (the harvest-hire rules now belong to paid quests kept by Q-C2 |  |
| CON02-S-5 | decision | Which real need should make a villager hire a service on its own (none yet, so the live economy is unchanged)? |  |
| CON02-S-6 | decision | Confirm the 50-coin formal signing line for services as for goods |  |
| DCR-01 | rule | Decision continuity rule: before implementing a newly approved decision, compare it with earlier directives, s |  |
| E22-OD-03 | decision | Knowledge persistence: how industrial knowledge passes on (teaching, apprenticeship, written records) or is lo |  |
| E22-OD-04 | decision | Regional trade and transport: do traders' trips take real travel time, carry limited loads and risk loss on ro |  |
| E22-OD-05 | decision | Population across the region: should off-map settlements get housing and land that limit growth (REG-DEMO-D1 l |  |
| E23-OD-01 | decision | Bandit factions: territory and jurisdiction, how many factions may exist and how they form, how leadership cha |  |
| E25-OD-01 | decision | Rivers and creeks on the maps (none exist): add a river and creek to the village map and the overworld? |  |
| E25-OD-02 | decision | Where does the river run relative to the houses (flood risk)? |  |
| E25-OD-04 | decision | Rebuild where it stood or on a safer plot? |  |
| E25-OD-05 | decision | Does weather reach the off-map settlements? |  |
| E25-OD-07 | decision | When to build Expansion 25 relative to Expansions 20-24 |  |
| E26-BOSS-D1 | decision | Expansion 26 bosses and hero status: does the 2026-10-27 parking of the imported boss roster (OD-17 D36g) and  |  |
| FARM-08-Q-CROP | decision | How is a field's crop divided among the farmers who work it? |  |
| FARM-YIELD-D1 | decision | Shared farming model: which wheat yield per cell, and may shared_manor_farming (FSE-12, FARM-06) and seasonal_ |  |
| HORSE-Q | decision | Plough horse: price and what it does |  |
| ID-D1 | decision | Identity: when an heir takes over, does the village's view of the player carry on to the heir (Build 18 behavi |  |
| ID-D2 | decision | Identity changes the determinism gate: off-map people and player characters now draw ids from the one counter, |  |
| ID-D3 | decision | Identity gate baseline: approve the candidate new baseline (docs/design/IDENTITY_GATE_CANDIDATE.json)? Its onl |  |
| INV-Q1 | decision | INV-18 borderline item classifications |  |
| INV-Q2 | decision | INV-18 upgrade acquisition and cost |  |
| JUICE-J1 | decision | May phase J1 (quick wins: notification split, coin tick, prompt pulse, hurt frames, 'Reduce effects' setting,  |  |
| LE05-RENTAL-REPAIR | decision | LE-05 tool repair and rental (OD-LE-08 direction approved; worker A's proposal on wip/x20-le05, nothing built; |  |
| MILE-01 | rule | Milestone assignments are respected: nothing moves into Build 16 from the expansions (the Living Economy build |  |
| MIN-C-Q2 | decision | Sharing or selling discoveries: proposed, not approved; no ownership, access or extraction-rights mechanics |  |
| MIN-D-Q1 | decision | Should a business or the player be able to commission a survey through CON-01 (needs a service-contract term,  |  |
| MIN-D-Q2 | decision | Should the player's tools and skills count toward the settlement's mining capability (built: they do not)? |  |
| MIN-D-Q3 | decision | Should trial pits yield dirt or topsoil items (with MIN-E's item decision)? |  |
| MIN-E-Q1 | decision | What is earth (topsoil, dirt, spoil) used for beyond backfill: topsoil on farmland, embankments, earthworks? |  |
| MIN-E-Q2 | decision | Should there be a spade (and its recipe) for digging earth? |  |
| MIN-E-Q3 | decision | Should staking a pit need the manor's leave or mining rights (cf. ECON-P1.2)? |  |
| MIN-E-Q4 | decision | Should 'excavator' become a job, or should capability level 3 count whoever digs? |  |
| MIN-E-Q5 | decision | Should bigger or overworld pits be built to allow spiral ramps and more layers? |  |
| MIN-F-Q1 | decision | Should unsupported spans collapse, supports decay and need repair, and ventilation and lighting be real needs? |  |
| MIN-F-Q2 | decision | Should tunnelling find hidden underground deposits, the manor post tunnelling and track jobs, and the carpente |  |
| MIN-F-Q3 | decision | Should miners haul by minecart instead of carrying? |  |
| MIN-F-Q4 | decision | Should there be shafts between underground levels? |  |
| MIN-F-Q5 | decision | Should spoil be allowed back into tunnels below ground? |  |
| MIN-F2-Q1 | decision | Who makes mining equipment: should the carpenter make supports, ladders and minecarts for sale, and the manor  |  |
| MIN-F2-Q2 | decision | Should an underground collapse injure or kill people beneath it (today they are moved to the nearest floor unh |  |
| MIN-STONE-Q | decision | Are quarry stone and building blocks different items? |  |
| MP-D1 | decision | Multiplayer: what happens to a guest's character while that guest is disconnected (inactive and removed, physi |  |
| MP-D2 | decision | Multiplayer: resting and sleeping that skip time (only when every connected player rests, no skipping with gue |  |
| MP-D3 | decision | Multiplayer: menus and placement mode that pause the world (never pause with guests connected, or only the hos |  |
| MP-D4 | decision | Multiplayer: a player dies while others play (continue as heir at once with the world running, or a short wait |  |
| MP-D5 | decision | Multiplayer internet connection method: free methods first (LAN, manual address, automatic port mapping, a doc | DGA-D3 |
| MP-D6 | decision | Multiplayer: an Android host leaving the app (world pauses for everyone, or a foreground service keeps hosting |  |
| MP-D7 | decision | Multiplayer: a new guest character (a newcomer to the village, or a member of an existing household)? |  |
| MP-D8 | decision | Multiplayer: player-to-player marriage, children and inheritance follow the same rules as with villagers (CRT- |  |
| MP-INET-RELAY | decision | Internet multiplayer beyond free methods: hosts on mobile data or behind carrier-grade NAT cannot be reached b |  |
| MP-INTERACT-Q2 | decision | Talk targeting: Talk takes the nearest person, so a closer villager comes before another player (a tap, a clic |  |
| MP-Q-PLAYER-CHILDREN | decision | Should a marriage between two players have children? (births currently need a villager parent) |  |
| MSW-01 | rule | Minimum Sufficient Work: correctness mandatory, redundancy justified |  |
| OD-01 | decision | Owner decision: deposit sustainability (P1) and the mine wage (B7-006) | OWN-12 |
| OD-02 | decision | Owner decision: balance review of every provisional number | K-3, OWN-17 |
| OD-03 | decision | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | OWN-29 |
| OD-04 | decision | Owner decisions: chest and lock questions |  |
| OD-05 | decision | Owner decisions: inner doorways, relaying survey plots |  |
| OD-06 | decision | Owner decisions: farming (Farming skill, wheat versus wages) |  |
| OD-07 | decision | Owner decision: hunting in Gather mode |  |
| OD-08 | decision | Owner decision: is honest arbitrage intended? |  |
| OD-09 | decision | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | Q-11 |
| OD-11 | decision | Owner decision: an orphaned child for whom no household is eligible: what temporary care applies (stay in the  |  |
| OD-12 | decision | Owner decision: choosing between equally close eligible relatives (for example two grandparent households, or  |  |
| OD-13 | decision | Owner decision: crowded families that no member can leave (two parents, young children, often a grandparent, m |  |
| OD-14 | decision | Owner decision: no original village house has room for the living-quarters module. The module is house-sized ( |  |
| OD-15 | decision | Should the player's sales stop at a trader's 15-coin floor, as villagers' sales do (B7-008)? |  |
| OD-16 | decision | The village's trade economy stops around day 120-140 on seed 1 (smith out of coins, no iron, no axes, no timbe |  |
| OD-17 | decision | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your mai | REC-002, REC-010 |
| OD-18 | decision | Player-only perks and rules found by the DVW-A8 and DVW-A12 audits |  |
| OD-19 | decision | PAR-02: the universal coin-reserve threshold |  |
| OD-20 | decision | PAR-05: should a caught pickpocket's cry (theft rules 2026-10-18; the Stealth guard_radius perk) become a repo |  |
| OD-21 | decision | Explicit time model and calendar consistency (approved architectural decision) |  |
| OD-22 | decision | Which definition the shared farming model starts from (per-cell, per-field, or an explicit difference) |  |
| OD-23 | decision | What the manor's fields cost their farmers (lease, crop share, or free to any farmer) |  |
| OD-24 | decision | Rent for villager merchants' stalls (pay as the player does, or the player's pitch free) |  |
| OD-25 | decision | Owner decision resolution for Build 16 (2026-10-21): FARM-07 2 coins a week; FARM-01/02 variable plots, materi |  |
| OD-26 | decision | Owner decision 2026-10-21: one shared per-cell farming model for player, households and manor approved as the  |  |
| OD-27 | decision | Owner answers to the land and stall questions Q8-Q13 (2026-10-21) |  |
| OD-28 | decision | Owner decisions for Build 17 (2026-10-21): enterable caves and underground mining; one deposit system everywhe |  |
| OD-29 | decision | Owner decisions (2026-10-21): Build 17 starts now beside Build 16; separate underground maps tied to their sur |  |
| OD-30 | decision | Official expansion numbering: 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy; Exploration unnumbered; M |  |
| OD-LE-01 | decision | Owner decision (Living Economy): Standalone build number and placement without displacing existing Build 19 Ju |  |
| OD-LE-02 | decision | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules |  |
| OD-LE-02B | decision | Offer visibility: who can see an offer (in person at stalls and meetings, by word of mouth, a notice board), t |  |
| OD-LE-03 | decision | Owner decision (Living Economy): Wages, rents and service contracts in first release |  |
| OD-LE-04 | decision | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance |  |
| OD-LE-05 | decision | Owner decision (Living Economy): Loan interest, collateral, default and collection rules |  |
| OD-LE-05B | decision | Interest and lending: whether loans carry interest or fees, who may lend money, and collection procedures (the |  |
| OD-LE-06 | decision | Owner decision (Living Economy): Permissible manor interventions and political authority |  |
| OD-LE-07 | decision | Owner decision (Living Economy): Restricted-use advances and business/household account separation |  |
| OD-LE-08 | decision | Owner decision (Living Economy): Barter, rental, repair and resource substitution |  |
| OD-LE-09 | decision | Owner decision (Living Economy): Bandit market participation and regional trading limits |  |
| OD-LE-10 | decision | Owner decision (Living Economy): Economic rumor, memory persistence and reliability |  |
| OD-LE-11 | decision | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation |  |
| OD-LE-12 | decision | Owner decision (Living Economy): Charity, kinship support and communal relief |  |
| OD-LE-13 | decision | Owner decision (Living Economy): Contract cancellation, penalties and death of a party |  |
| OD-LE-13B | decision | Death of a party to a contract: does the contract end, pass to the heir or the household, or go to the estate  |  |
| OD-LE-14 | decision | Owner decision (Living Economy): Player intervention and visibility of market decisions |  |
| OD-LE-15 | decision | Owner decision (Living Economy): Performance and population acceptance targets |  |
| OWN-09 | decision | Build 8 private only; registry public-only; no sustainability changes until decided | OWN-21 |
| P21-RESIDENCY | decision | How long must an adult live in a settlement to count as an established resident (to vote and stand for mayor)? |  |
| P21-STRUCTURE | decision | Beyond the elected mayor: councils and their powers, the manor or a lord's authority over the village, regiona |  |
| PACK-Q | decision | Pack capacity: how many kinds the player can carry |  |
| PROS-01 | rule | Parallel prospective development of Expansions 18 and 19 on isolated branches while Build 17 stays the priorit |  |
| Q-C1 | decision | CON-01 Q-C1: Manor tool orders stay separate from CON-01 (advance payment preserved; counted as obligations) |  |
| Q-C2 | decision | CON-01 Q-C2: Paid work quests stay separate (full payment on completion or none) |  |
| Q-C3 | decision | CON-01 Q-C3: opportunity_weight = 1.0 (a seller weighs what the same hours earn in its own trade) |  |
| Q-C4 | decision | CON-01 Q-C4: risk_margin = 0.15 (a scheduling buffer on work-time estimates, not a profit margin) |  |
| Q-C5 | decision | CON-01 Q-C5: cancel_premium = 0.10 per recorded early cancellation with the same seller, 14-day record window; |  |
| Q-C6 | decision | CON-01 Q-C6: formal_total = 50 coins; smaller agreements unsigned and may be concluded remotely; formal ones s |  |
| Q-C7 | decision | CON-01 Q-C7: sign_reach = 3 tiles, same place and level; the reeve represents the manor |  |
| Q-C8 | decision | CON-01 Q-C8: offer_days = 2: an unsigned formal agreement expires after two days, nothing reserved or moved be |  |
| Q-C9 | decision | CON-01 Q-C9: npc_counter_tolerance = 0.25 above the buyer's own price, within its real purchasing power; quant |  |
| Q-POL-1 | decision | Political structure of the starting village (manor with a reeve, elected mayor, council, or a mix; what the lo |  |
| Q-POL-2 | decision | Franchise: who votes and who may stand |  |
| Q-POL-3 | decision | Office terms, election season and by-elections (with the 8-day game year) |  |
| Q-POL-4 | decision | Vote privacy and which totals are public |  |
| Q-POL-5 | decision | Ties in elections |  |
| Q-POL-6 | decision | Removal from office |  |
| Q-POL-6-CONFLICT | decision | Removal from office: the owner's 2026-10-19 directive allows removal through the established political system  |  |
| Q-POL-7 | decision | Placement and gate: politics waits for Expansion 19's live judgment, or an interim voter model behind a switch |  |
| Q-POL-8 | decision | The constable and the law: a constable and crime records before Expansion 22; the friendly guard (X19 conflict |  |
| Q-POL-9 | decision | Taxes under an elected authority and DVW-B5's predictability |  |
| Q18-1 | decision | Q18-1: Carpentry, Masonry (stoneworking) and Tanning become skills of their own, seeded from existing Crafting |  |
| Q18-10 | decision | Anyone may buy from another settlement; the buyer fetches the goods or pays a willing carter; no free delivery |  |
| Q18-11 | decision | What pay factor and output factor should each settlement capability level give, and for which industries? (Unt |  |
| Q18-11A | decision | Which compensation and productivity percentages per industry and level 0-10? (Candidate +20% output / +8% pay  |  |
| Q18-11B | decision | How do worker experience, tools, facilities and infrastructure compose a settlement's capability rating? (Opti |  |
| Q18-12 | decision | May a buyer hire a villager or carter to haul goods between settlements, and on what terms (day wage, fee per  |  |
| Q18-13 | decision | Should CON-01 contracts gain parties for households and off-map settlements, or should a household buy through |  |
| Q18-14 | decision | Q18-14: a new Law skill qualifies a courier to notarise |  |
| Q18-15 | decision | Q18-15: any business with a shop may open its own courier booth |  |
| Q18-16 | decision | Q18-16: with no free stall, the village courier builds a booth near the market |  |
| Q18-2 | decision | Q18-2: first industries are forestry, carpentry, masonry, smithing, farming, tanning, trade and mining |  |
| Q18-3 | decision | Q18-3: off-map settlements are simulated economies like this one (money from their villagers, government and c |  |
| Q18-4 | decision | Q18-4: five off-map settlements of mixed kinds |  |
| Q18-5 | decision | Q18-5: barter and credit with trust |  |
| Q18-6 | decision | Q18-6: may abstract regions show 'two settlements develop different profiles' |  |
| Q18-7 | decision | Q18-7: migration both ways between the village and the other settlements, for reasons |  |
| Q18-8 | decision | Q18-8: visiting other settlements in person stays at Build 20 or later (SET-E) |  |
| Q18-9 | decision | Settlement capability levels affect pay scales and production output only; never a permission gate |  |
| REC-D1 | decision | Flight recorder: available in playtest and development builds only (Settings, Diagnostics), off by default, ne |  |
| REC-D2 | decision | Flight recorder storage cap: stop and mark the session incomplete, or rotate out the oldest days? |  |
| REC-D3 | decision | Flight recorder per-tick quantities (hunger, movement, work minutes): hourly samples plus threshold events rat |  |
| REC-D4 | decision | Flight recorder money attribution: move the hottest coin-change sites to one transfer helper (touches Build 18 |  |
| REG-BUY-D1 | decision | When the village buys food from a settlement, may the settlement's sellers sell food its own households will n |  |
| REG-DEMO-D1 | decision | Off-map settlements now follow the village's birth rule with no housing limit (the village has houses; the set |  |
| REG-WAGE-D1 | decision | Merge the necessity-wage correction (wip/b18-wagefix): a settlement business pays its hungry worker household  |  |
| REG-X20-D1 | decision | Off-map settlements: may a hungry household that is the only worker household of its business migrate for hung |  |
| REG-X20-D3 | decision | Off-map settlements: should settlement-to-settlement food trade get a live path? The owner's REG-BUY-D1 answer |  |
| REGION-NAV-Q1 | decision | Stage structure: keep the eight approved REGION-NAV-01 stages as the only work packages (the lead's a/b/c labe |  |
| REGION-NAV-Q2 | decision | Moved work: accept the site buildings in S2 and the roads-through-sites fix in S3 as recorded moves, or re-att |  |
| REGION-NAV-Q3 | decision | AD-1: settlements at their existing OffMapSettlement.pos (built, one geography with trade distances), or at th |  |
| REGION-NAV-Q4 | decision | Crafters in S2 and S4: (a) business keepers and the official only (built); (b) also every worker household's h |  |
| REGION-NAV-Q5 | decision | S2 trade path: keep the courier edge (books both sides) as an approved deviation, or rework onto SettlementPar |  |
| REGION-NAV-Q6 | decision | Next: finish S2's outstanding items (save and load test; crafters per Q4) and S3's three outstanding tests, th |  |
| ROAD-01 | decision | Five-build roadmap: 15 simulation stabilization, 16 long-term equilibrium, 17 Mining & Industrial, 18 Settleme |  |
| ROAD-Q1 | decision | Expansion 27: which specification is it? (none found; candidates World Exploration, Dungeons & Encounters, or  |  |
| ROAD-Q2 | decision | Expansion 23 before 22: limit 23 to the village, existing roads and off-map books, with route banditry across  |  |
| ROAD-Q3 | decision | Skeletons, lizards and spiders (B14-09, FR-01): keep in Expansion 26 or return them to the unnumbered explorat |  |
| ROAD-Q4 | decision | Building condition: design it with 22-D (abandonment) or with 25 (disasters)? |  |
| ROAD-Q5 | decision | Batch 0 (bring wip/expansion20 and wip/expansion21 preparation onto Build 19 together) as the first step after |  |
| SIM-01 | rule | Continuous long-run simulation testing: the longest run once per seed, monitored, with checkpoints |  |
| SIM-02 | rule | Simulation monitoring: observe, never restart active runs without owner approval; check-ins from measured runt |  |
| SIM-F2 | decision | Recorder finding F2: a stonecutter re-chose a failing iron-chisel purchase 328 times in one day (day 2, seed 1 |  |
| SIM-F3 | decision | Recorder finding F3: bandits stalking at night leave their plan empty, so the brain re-decides every tick (400 |  |
| SIM-F4 | decision | Recorder finding F4: the whole bandit band died within nine days; a bandit's only food purchase (_bandit_marke |  |
| SIM-F9 | decision | The REC-F1 root cause also affects plans that start with a work step in eating, taking medicine and a homeless |  |
| SJD-H-CAL | decision | SJD-H calibration package (worker D's SJD-G soak report on wip/x20-sjdg; defaults keep today's behaviour): C1  |  |
| SJD-Q01 | decision | Judgment open decision: Should there be a NEUTRAL objective event type, or must every judged event begin GOOD/ |  |
| SJD-Q02 | decision | Judgment open decision: Should scores decay, or change only through new events, forgiveness and corrected beli |  |
| SJD-Q03 | decision | Judgment open decision: Different disposition thresholds per NPC, or one calibrated scale? |  |
| SJD-Q04 | decision | Judgment open decision: Should very large GOOD and BAD totals with NET near 0 create ambivalence behaviour? |  |
| SJD-Q05 | decision | Judgment open decision: How much may prior judgment bias interpretation of ambiguous events? |  |
| SJD-Q06 | decision | Judgment open decision: How should confidence and rumours influence points: multiplier, threshold, or separate |  |
| SJD-Q07 | decision | Judgment open decision: How far should gossip spread; should reach depend on social proximity and personality? |  |
| SJD-Q08 | decision | Judgment open decision: How should legal guilt, moral judgment and personal loyalty interact? |  |
| SJD-Q09 | decision | Judgment open decision: Always highest utility, or sometimes near-optimal via seeded randomness? |  |
| SJD-Q10 | decision | Judgment open decision: What judgment information, if any, can the player see? |  |
| SJD-Q11 | decision | Judgment open decision: How should memory persistence and forgiveness vary by severity? |  |
| SJD-Q12 | decision | Judgment open decision: What makes an event important enough to score? |  |
| SJD-Q13 | decision | Judgment open decision: How should individual decision weights be learned, configured or tuned? |  |
| SJD-Q14 | decision | Judgment open decision: Which domain gets the first live integration after the prototype? |  |
| STONE-D1 | decision | Stone dressing efficiency values by skill (STONE-04) and the materials rule's numbers |  |
| STONE-D2 | decision | Iron chisel wear and recipe (STONE-06) |  |
| STONE-Q | decision | STONE-01 follow-up questions: fittings/mending on blocks, dressing waste, a mason trade |  |
| STONE-Q1 | decision | STONE-Q part 1: materials match the actual construction or repair (raw stone, blocks, or both) |  |
| STONE-Q2 | decision | STONE-Q part 2: stone lost in dressing depends on the worker's skill (Option C), Expansion 18 |  |
| STONE-Q3 | decision | STONE-Q part 3: a dedicated Stoneworking skill and a mallet plus iron chisel (1B + 2B), Expansion 18 |  |
| STONECUT-R1 | decision | WDR-002: the stonecutter (X18-STONECUT) supplies no other profession; its building blocks are bought by the ra |  |
| TAILOR-Q | decision | Where the tailor comes from |  |
| TEST-AUDIT-Q1 | decision | Should villagers' current plans (a market run with a cart, a walk to work) be saved, so a loaded world goes on |  |
| TEST-AUDIT-Q2 | decision | Accept a new simulation baseline (SIM-GATE-01) recorded from the final B25R2 commit, for overworld generation  |  |
| TILL-D1 | decision | Storefront till of a living household that loses or gives up its house (lease taken back for arrears, lease gi |  |
| WDR-001 | rule | World Design Rule 1: Material Interdependency |  |
| WDR-002 | rule | World Design Rule 2: Professional Interdependency |  |
| WDR-003 | rule | World Design Rule 3: Meaningful Recipes |  |
| WDR-004 | rule | World Design Rule 4: Economic Consequences |  |
| WDR-005 | rule | World Design Rule 5: Living World Independence |  |
| WDR-006 | rule | World Design Rule 6: Maintain the Existing Interlocking Systems Manifest |  |
| WDR-007 | rule | World Design Rule 7: Automated Compliance |  |
| WDR-008 | rule | World Design Rule 8: Player Knowledge and Wiki |  |
| WDR-009 | rule | World Design Rule 9: Emergent Gameplay |  |
| WDR-010 | rule | World Design Rule 10: Depth Without Obscurity |  |
| WDR-011 | rule | World Design Rule 11: NPC Self-Improvement and Prosperity |  |
| WDR-011-Q1 | decision | Aspirations: the game has no illness system; should low health and near-starvation hunger count as illness for |  |
| WDR-011-Q2 | decision | Aspirations: should careers be steered only through accepting work and contracts, or add a job-choice decision |  |
| WDR-011-Q3 | decision | Aspirations: may villagers who care about wealth or property favour suitors with means, or does courting stay  |  |
| WDR-011-Q4 | decision | Aspirations: who perseveres after a setback: the existing stubborn villagers (about 30%), with experience spee |  |
| WDR-011-Q5 | decision | Aspirations: approve the provisional values (priorities, thresholds, adaptation rates) as a starting point tun |  |
| WDR-011-Q6 | decision | Aspirations: should social standing be a sixth domain (read from the village's overall opinion), beyond Rule 0 |  |
| WDR-011-Q7 | decision | Aspirations: should players see villagers' aspirations: none in v1, or a dialogue line from the leading aspira |  |
| WDR-011-Q8 | decision | Aspirations, scope of Q3: individual romantic preferences now apply to whom an NPC chooses to court. Should th |  |
| WDR-012 | rule | World Design Rule 12: NPC Competition and Economic Rivalry |  |
| WDR-013 | rule | World Design Rule 13: Finite Resources and Actual Consumption |  |
| WDR-014 | rule | World Design Rule 14: Graveyards, Ancestry, and NPC Legacy |  |
| WDR-015 | rule | World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment |  |
| WDR-016 | rule | World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership |  |
| WDR-017 | rule | World Design Rule 17: Generational Memory and Living History |  |
| WDR-018 | rule | World Design Rule 18: Protected Ecological Continuity |  |
| WDR-019 | rule | World Design Rule 19: Living Political Agency and Democratic Consequences |  |
| WDR-020 | rule | World Design Rule 20: Autonomous Housing |  |
| WDR-021 | rule | World Design Rule 21: Household Succession and Family Care |  |
| WDR-022 | rule | World Design Rule 22: A Village Is Allowed to Fail; the Simulation Is Not |  |
| WIKI-01 | rule | Permanent wiki and documentation maintenance: a feature is not complete without accurate documentation; player |  |
| X18-D1 | decision | Expansion 18 D1: starting experience seeded once from recorded skills (farming from PAR-01A history) |  |
| X18-D2 | decision | Expansion 18 D2: what limits effective capability |  |
| X18-D3 | decision | Expansion 18 D3: no thresholds on the 0-10 levels; novice/journeyman/master names in player reports |  |
| X18-D4 | decision | Expansion 18 D4: industry for unattributed work (stall trade to trade; slaughter, clearing, fencing to farming |  |
| X18-D5 | decision | Expansion 18 D5: real-valued levels interpolate between whole-level table values |  |
| X18-D6 | decision | Expansion 18 D6: posted manor job wages are fixed when the job is taken, at the taker's effective level |  |
| X18-D7 | decision | Expansion 18 D7: crop shares split by work done (minutes x the cutter's own work rate) |  |
| X18-D8 | decision | Expansion 18 D8: wages with skill modifiers round to the nearest whole coin |  |
| X18-D9 | decision | Expansion 18 D9: experience is dropped at the next dawn after death or departure |  |
| X18-FEES | decision | Courier fee coefficients and the small-agreement threshold (X18-Q12, X18-Q13) |  |
| X19-ASSAULT | decision | Should being assaulted oneself be a permanent memory (the proposed threshold makes it so; at the stress rate v |  |
| X19-BOND-LIMITS | decision | Do specific relationship or reputation effects need additional balancing limits? |  |
| X19-CRT12 | decision | Courtship proposals use fixed notoriety and regard cut-offs (CRT-12); keep 'no marrying a killer' absolute and |  |
| X19-DECAY | decision | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1- |  |
| X19-EVENT-Q | decision | Expansion 19 event feeds raised four questions: (1) should a guard killing an assailant count as a killing (to |  |
| X19-GOSSIP-FLOOR | decision | Gossip closeness (X19-Q-TIMING): a story passes between strangers with the agent-proposed chance gossip.closen |  |
| X19-GUARD | decision | A guard who is the player's friend waives the fine (CRT-06) while SJD-Q08 says a guard can like someone and st |  |
| X19-HARMED | decision | Relations.harmed lowers the player's standing with a victim's kin and friends instantly; when judgment is live |  |
| X19-PERS-FORMULA | decision | The numerical formulas for personality evolution (rates by frequency, severity and duration; soft limits; lear |  |
| X19-PERSONALITY | decision | Agent-proposed numbers for per-person temperament (SJD-Q03, Q13): tolerance and weights vary by up to 30% betw |  |
| X19-Q-TIMING | decision | Gossip timing: keep 'spread' (identical results to telling an hour's meetings at once; rare long catch-up fram |  |
| X19-REGARD | decision | Relations regard is both trust (believing stories) and harm (a seen crime lowers it), so victims believe culpr |  |
| X19-REP-TRANSMIT | decision | The numerical formulas for family reputation transmission (how stories, their significance and retelling set a |  |
| X19-RUNNERUP | decision | Near-best choices (SJD-Q09): the agent-proposed chance that a villager takes a close second instead of the bes |  |
| X19-SPILL-REACH | decision | How far does reputation spillover reach through extended family (parents, children, siblings, cousins, in-laws |  |
| X19-TRAIT-DIST | decision | Population trait distributions and learning percentages beyond the approved 30% stubbornness potential |  |
| X19-TRUST-RATES | decision | Agent-proposed numbers for Expansion 19 awaiting the owner: trust starts at a quarter of liking (a stranger at |  |
| X20-SCOPE | decision | Expansion 20 scope: bring the Living Economy answers classed FUTURE (OD-LE-03, -04, -08, -11, -13B, -14) forwa |  |
| X20-SERVICES-SCOPE | decision | Does X20-SCOPE's 'negotiated wages and service contracts behind their switches (OD-LE-03/D02)' include the app |  |
| X20-TRADER-CLOSE | decision | Review finding 1 (settlement traders): once traders close when nobody works them, all five settlement traders  |  |
| X21-RECOVERY-D1 | decision | When is the Expansion 21 phase-1 work (P21-00..02 on wip/expansion21-preparation 8ac88f5, built on Build 18) b |  |
| XEXPL-D1 | decision | Decision explainability: is an optional player-inspection panel wanted in this generation of builds, or only i |  |

## Under review (not authority until the owner decides)

| Record | Kind | Title |
|---|---|---|
| B17F-DEPLETE | idea | Build 17 finding: 26-28 ore seams worked out a seed by day 365; resource depletion trend |
| B17F-FOOD | idea | Build 17 finding: missed meals for want of money (606-5,417 a year across seeds) |
| B17F-HENS | idea | Build 17 finding: chickens died out early on seeds 2 and 3 |
| B17F-JOBS | idea | Build 17 finding: unemployment of 6-30 adults at day 365 |
| B17F-PERF | idea | Build 17 finding: long-run performance analysis (seed 2 took 118 min against 66-93) |
| B17F-SIMREPORT | idea | economy_sim reporting fixes: open pits counted as building sites; checkpoint lines not in the job log |
| B25-AUD-REG-08 | decision | REG-08 courier stranded deliveries: who receives stranded goods/coins, how a waiting route job ends, whether the flat fe |
| B25-Q33-TRADER-RESERVE | decision | Q33 trader reserve (80 coins instead of 85% of the till) and the caravan economy: why it lowers caravan purchases and vi |
| BAN-B | proposal | Expansion 23 BAN-B: faction identity, membership, hierarchy, safehouse ownership and persistent faction resources |
| BAN-C | proposal | Expansion 23 BAN-C: career actions, recruitment, theft and raids, resale, suspicion and response (within E23-SCOPE) |
| BAN-D | proposal | Expansion 23 BAN-D: rank, challenge, leadership, schism and autonomous succession |
| BAN-E | proposal | Expansion 23 BAN-E: economy, judgment and politics integration; long-run simulations |
| CAP-TOOLHOLDER | idea | Design review: a villager holding a tool only for sale counts as a capability practitioner |
| CHAPEL-GIVE-14-Q | decision | With the 14-day hardship line now governing chapel food alms, households offer wheat to the chapel only above 14 days of |
| DGA-D1 | proposal | Meaning of "isometric" |
| DGA-D10 | proposal | Formal platform/engine approval (U1, U2) |
| DGA-D11 | proposal | Living-society scope (U20, U21, P1-P3, balance review) |
| DGA-D12 | proposal | Approval to start phase 1 |
| DGA-D2 | proposal | Isometric art source (J-G4) |
| DGA-D4 | proposal | Shared-world rules (pause, characters, heir) |
| DGA-D5 | proposal | Reputation/ownership/PvP (J-S3, U21) |
| DGA-D6 | proposal | Combat model and latency (U7) |
| DGA-D7 | proposal | Visible gear |
| DGA-D8 | proposal | Era, county, political status, map scale |
| DGA-D9 | proposal | Magic (J-M1..4) |
| DGA-R | proposal | Refactors (coordinates, players collection, command layer, fixed step + state hash, save split, appearance data, magic s |
| DGA-S | proposal | Isometric look spike; network feasibility spike |
| DVW-B10 | proposal | Onboarding, first ten minutes |
| DVW-B11 | proposal | No instant fast travel (rule) |
| DVW-B12 | proposal | Ethics/lore: thralldom, Church, content note |
| DVW-B13 | proposal | Story kept as sparks; audit `story: true` quests |
| E20-RISK-QUEUES | proposal | Unbounded growth and population-wide scans found in Build 18 economic code: NPCBrain.miss_log never cleared; courier job |
| E25-OD-03 | decision | Wells for bucket lines away from the river (packet recommendation: one or two wells as public works the reeve can build) |
| E25-OD-06 | decision | May the reeve keep a disaster reserve in the treasury? (recommendation: yes, inside the existing reserve rule, no new mo |
| E25-OD-08 | decision | How long is a swept-away person missing? (recommendation: 1 to 3 game days by a seeded draw) |
| E25-OD-09 | decision | Can a building be insured or protected (stone versus wood)? (recommendation: stone resists fire and wind better; no insu |
| E26-OD-01 | decision | Foxes: pets only, or also companions? (recommendation: companions too; only their pen use is pets-only) |
| E26-OD-02 | decision | Monster respawn (recommendation: skeletons 3 days as approved, spiders alike; a killed boss not back for a game year, so |
| E26-OD-03 | decision | How often a monster attacks the village (recommendation: about once in several game years, never more than one at a time |
| E26-OD-04 | decision | Bounties when the treasury is empty (recommendation: no bounty without the coins; villagers may pool coins) |
| E26-OD-05 | decision | Bounty prices (recommendation: set by the reeve within an owner-approved band, proposal 20-60 coins monsters, 150-400 bo |
| E26-OD-06 | decision | Monster goods recipes (recommendation: one special item per boss plus bones and rusty gear from skeletons) |
| E26-OD-07 | decision | Companion combat numbers (recommendation: wolf about a wild wolf, fox weaker but quicker; heal with rest and food) |
| E26-OD-08 | decision | Can villagers' pets or guard dogs fight in village defence? (recommendation: guard dogs join the guards' line) |
| E26-OD-09 | decision | When to build Expansion 26, and may phases 26-A..C and 26-F start before Expansion 25? |
| ECON-P2 | proposal | Wildlife carrying capacity, sex floor, migration pool, hunting rights/quota, extinction, seasons (:116-121) |
| ECON-P3.3 | proposal | Stock targets in days of sales (agent proposal P3.3, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 185) |
| ECON-P3.4 | proposal | Hire wages from the market quote (agent proposal P3.4, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 186) |
| FR-11 | approved | Personality, prestige and migration (owner's living-society list, 2026-10-17) |
| JUICE-JD2 | decision | Day and night: should the picture darken at night (how dark at midnight; interiors; underground already dark)? |
| JUICE-JD3 | decision | Villager chatter: how often may villagers show what they are doing in bubbles (OWN-19 extension)? |
| JUICE-JD4 | decision | Screen shake and haptics: allowed at all, on which events, and default on or off? |
| JUICE-JD5 | decision | Notifications: which village notes the player sees in the corner log by default, and whether a filter exists. |
| LEG-A | proposal | Expansion 24 LEG-A: reconcile Expansion 19's event and belief store; prevent a second history database |
| LEG-B | proposal | Expansion 24 LEG-B: persistent event graph, significance and retention, kinship and provenance links (on Expansion 20's  |
| LEG-C | proposal | Expansion 24 LEG-C: dialogue from real history, memorial biographies, graveyard and chronicle presentation |
| LEG-D | proposal | Expansion 24 LEG-D: lineage and heir continuity, political, criminal and professional careers, damaged, rebuilt and sold |
| LEG-E | proposal | Expansion 24 LEG-E: historical query performance, saves and long-run multigenerational tests |
| MIN-L5 | proposal | Mining capability level 5 (integrated industrial mining) |
| OWN-02 | proposal | Wildlife balance follow-up; horse imported, use pending |
| P21-OFFICES-Q1 | decision | Political offices other than the mayor: their terms, succession, dismissal and vacancy rules (the mayor's rule is not ex |
| REC-003 | approved | Android builds target API 36 (Hot Attic Games standing platform policy) |
| REC-008 | approved | Near/far simulation tiers (detailed near the player, abstract far away, nothing duplicated on switching) |
| REC-014 | approved | Revisit the settlement, agriculture, food, resource, population and trade foundations using the recent research |
| ROAD-02 | proposal | Master Expansion Roadmap and Documentation Pack (owner, 2026-10-21): 17 Mining, 18 Settlements, 19 Judgment approved; 20 |
| SAV-04 | decision | SAV-04: exact requirement for uninterrupted wildlife/combat continuity versus deterministic continuation from a saved st |
| TIME-03 | proposal | Recommended time retuning (outliers): proposals only, owner review before any change |
| VP-01A | proposal | Village politics stage: Audit of the reeve, guard pay and succession decision points |
| VP-01B | proposal | Village politics stage: Offices and civic work |
| VP-01C | proposal | Village politics stage: Voting and the election lifecycle |
| VP-01D | proposal | Village politics stage: Political consequences in village life |
| VP-01E | proposal | Village politics stage: Soak, calibration and owner review |
| WDR-003-C | approved | Comply with World Design Rule 3: Meaningful Recipes |
| WORLD-A | proposal | Expansion 27 WORLD-A: audit map scale, streaming, navigation, save identities and mining cave entrances |
| WORLD-B | proposal | Expansion 27 WORLD-B: overworld regions, encounter locations and travel persistence; no assumed infinite procedural gene |
| WORLD-C | proposal | Expansion 27 WORLD-C: approved skeleton behaviours and loot under existing combat and conservation rules (behaviour from |
| WORLD-D | proposal | Expansion 27 WORLD-D: environmental encounters, performance and multiplayer boundaries; magic defined as separate scoped |
| X19-SWITCHES-D1 | decision | Enable in normal play the integrated-but-off Build 19 recovery features: R5 aspirations (judgment.json aspiration.enable |

Active and completed requirements are listed with their status in `STATUS.md` and the build views; COMPLETED means the implementation met its acceptance criteria, not that a decision stopped governing.

