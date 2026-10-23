# Cross-expansion preservation audit: Expansions 19-23 (2026-10-23)

Owner directive: `docs/directives/2026-10-23_cross_expansion_preservation_audit.md` (register XAUDIT-01). Read-only: no code,
test, branch or switch was changed; no test was run for it (existing evidence is cited with its commit). Labels: **V** verified
(read in git or code), **P** partially verified, **U** unverified. Companion detail: `EXPANSIONS_19_21_ALIGNMENT.md`,
`EXPANSIONS_22_23_AUDIT.md`, the Expansion 20 refresh and the Expansion 21 readiness report on their branches.

## 1. Executive summary

- **Nothing completed has been lost.** Build 17 and the whole Expansion 18 branch are inside Build 18 (V); Expansions 19, 20 and
  21 each sit on Build 18 and add to it (V). Every major system listed below is still present and active in Build 18 (V), except
  the caravan allowance, which Build 18 retired on purpose (V, bf312b8).
- **Build 18 already delivered most of what later planning called Settlement Advancement** (V): capability, experience, five
  conserved off-map economies, migration, couriers, regional trade, the allowance's retirement.
- **The new foundations extend rather than duplicate**, with five exceptions found by this audit (section 10), three of them
  defects to fix before any merge: (a) a saved `judgment` section switches judgment on even when the switch is off; (b) a saved
  `economy` section is silently dropped when the switch is off; (c) the X19-GUARD fine change is live behaviour on the Expansion
  19 branch, not behind the judgment switch (owner-approved rule, but it changes gameplay with the switch off and no test of the
  gate can see it).
- **Identity does not survive migration** (V): a person who leaves and returns gets a new id in every system. This is the main
  architectural obstacle to E22-OD-01 and to Expansion 19's long memory.
- **The register is mostly current** on staging; a handful of records disagree with the code (section 13).

## 2. Repository and branch inventory (V, 2026-10-23)

| Branch | Head | Contents |
|---|---|---|
| `main` | de76782 (10-19) | approved integrated source (owner merges only) |
| `staging/my-medieval-life` | b3eaae7 + this report | records (register, directives, design documents) |
| `wip/build18` | 239bdff | Build 18 integration; private draft release from 61ec528 (run 39935635926) |
| `wip/build17` | dfec7ec | Build 17, frozen (release code cd7439c); contained in Build 18 |
| `wip/expansion18-preparation` | 3de7a8f | fully contained in Build 18 (0 commits outside) |
| `wip/expansion19-preparation` | c756211 | Build 18 + judgment (33 commits, 47 files, +8245) |
| `wip/x19-personality`, `wip/x19-bonds` | a3aa237, 9460e9a | worker branches, merged into c756211 |
| `wip/expansion20-preparation` | 4d9bc05 | Build 18 + economy foundation (1efb59f, 4d9bc05; 17 files, +1490) |
| `wip/expansion21-preparation` | 8ac88f5 | Build 18 + civic records (15 files, +1086) |
| `wip/multiplayer` | d18d7d1 | MP-01, untouched |

No Expansion 22, 23 or 24 branch exists (correct: nothing implemented). No agent is running.

**Numbering (OD-30), history preserved (V):** 2026-10-21 the owner set 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy.
2026-10-23 the owner renumbered: 22 Settlement Advancement Phase 2, 23 Bandit Factions and Criminal Careers, 24 Legacy (recorded
as a history line on OD-30; the original answer is kept in the record). The Settlement Advancement specification was developed as
Expansion 18 and released in Build 18. The bandit roadmap (`2026-10-21_master_expansion_roadmap.md` lines 178-200) still says
"Expansion 22": a historical document, not edited. **No numbering change still needs confirmation.**

## 3. Historical implementation timeline (V unless noted)

| System | Introduced | First release | State in Build 18 | Tests |
|---|---|---|---|---|
| NPC memory | 6891005 (10-17) | Build 7 | active | run_tests, start_test |
| Treasury, reeve's day, guards' pay | 1ca902d / 6891005 | Build 7 | active | treasury_test, succession_test, competition_test |
| Witness, guard confrontation | 1ca902d, d358bb8 | Build 7 | active | chests_test, relations_test |
| Property, construction | c8033ac, 948dcac | Build 7 | active | property_test, housing_test |
| Bandits (`_bandit`) | 6891005 | Build 7 | active | world_test |
| Caravan | 6891005 | Build 7 | active, now run by settlement traders | regions_test, luxury_test |
| Caravan purse and allowance | 9c13794; 30 a day e6cbb2a | Builds 11 and 15 | **obsolete**: removed bf312b8 (Build 18) | |
| Vacancy succession, skills | 4e68d45, 8afb5ba | Build 12 | active | succession_test, skills_test |
| Relations (friendship, courting, notoriety) | 1c1d4a5, afe8ae2 | Build 15 | active | relations_test |
| Bandit market, loot recovery, guardianship | a6c7699, a7d187f | Build 15 | active | od16_test, family_test |
| Determinism gate | 244f5e7 | Build 15 | exists; **not run by any workflow or hook** | |
| Crime reports (PAR-05), reeve succession, stalls, band meals, clan orphans | 3f8a47d, 1e88118, afef91d, 6ab7d50, 7a63025 | Build 16 | active | family_test, stalls_test (report_crime has no test by name) |
| Contracts, service contracts | daf08f3, 0954de3 | Build 17 | active | contracts_test, services_test |
| Tax bands (DVW-B5), credit and barter, business tills | a77cce0, d765440, 749c7df | Build 18 | active | tax_test, credit_test, business_money_test |
| Off-map settlements, regional trade | bf312b8 | Build 18 | active | regions_test, regional_test, settlement_test |
| Couriers, migration | ef57da7 (live 5da89d8), e75b3f6 | Build 18 | active | courier_test, courier_live_test, migration_test |
| Worker experience, capability, industries, profile | 4ce9927, dad51a5, 92b6e0c, bea0ac7 | Build 18 | active; capability neutral (factors 1.0, Q18-11) | experience_test, capability_test, profile_test |
| Chapel, outlaws | 1b1b2f5, 6295deb | Build 18 | active | chapel_test, outlaw_return_test |

Save versions: Build 7 = 6, Build 8 = 8, Build 11 = 12, Builds 12-15 = 14, Build 16 = 16, Build 17 = 17, Build 18 = 19; all three
prospective branches keep 19 and add optional keys only.

## 4-8. Capability matrices

Status words: Design proposed / Design approved / Code (on a branch) / Tests pass / Enabled / Released / Verified in play.
No prospective capability is enabled, released or verified in play.

### 4. Expansion 19 (branch c756211, judgment off)

| Capability | Status | Files | Evidence | Label |
|---|---|---|---|---|
| Friendship, courting, rivals | Released (Build 15) | relations.gd | relations_test 79 | V |
| Notoriety, killings | Released | relations.gd `notoriety` | relations_test | V |
| Good and Bad ledgers, interpretation | Code, Tests pass | judgment_store.gd | judgment_test 217 | V |
| Trust apart from liking | Code, Tests pass | judgment_store.gd trust | judgment_test (X19-REGARD) | V |
| Gossip at meetings, closeness | Code, Tests pass | judgment_store.gd, relations.gd `share` | judgment_test, judgment_perf | V |
| Personality, wisdom, anger | Code (inert), Tests pass | judgment_personality.gd | judgment_personality_test 65 | V |
| History, resentment, familiarity, family reputation | Code (reach inert), Tests pass | judgment_bonds.gd | judgment_bonds_test 97 | V |
| Live event feeds, six decision hooks | Code, Tests pass | judgment_live.gd + guarded calls in credit, contracts, construction, prospecting | judgment_live_test 142 | V |
| Identical game with judgment off | Tests pass | guards on every hook | sim_gate identical at c756211; refactored loops read as equivalent | P (gate does not exercise player theft or every refactored path) |
| Misinformation, story lifetime | Design approved | | | V |
| Romance via judgment, crime and politics integration | Not started | | | V |

### 5. Expansion 20 (branch 4d9bc05, economy off)

| Capability | Status | Files | Evidence | Label |
|---|---|---|---|---|
| One money truth and census | Released | world.gd `total_coins`, settlement/holdings.gd | conservation_test, economy_sim FATAL | V |
| Contracts, credit, barter, tills | Released (Builds 17-18) | contracts.gd, credit.gd, business_money.gd | contracts_test, credit_test, business_money_test | V |
| Wages and hiring competition, experience | Released (Build 18) | npc_brain.gd `job_market`, `_hiring_competition`; experience.gd | competition_test, experience_test | V |
| Prices from local availability | Released (Build 14) | world.gd `sell_price_at` etc. | several | V |
| Actor resolver, reservations, event ring | Code (off), Tests pass | game/scripts/core/economy/ | economy_foundation_test 66 checks; world 339, migration 92, save_transfer 21, conservation 8; gate identical | V |
| No competing state | Code | the foundation holds no coins or goods; `total_coins` unchanged | diff read | V |
| Combined pricing, negotiation, installments, collateral | Design approved | | | V |
| Needs, offers, knowledge | Not started (OD-LE-02B, OD-LE-10 open) | | | V |

The 66 checks are a new suite; the existing suites they relate to (world, migration, save_transfer, conservation) were rerun on
the same commit and passed.

### 6. Expansion 21 (branch 8ac88f5, civic off)

| Capability | Status | Files | Evidence | Label |
|---|---|---|---|---|
| Reeve's daily government, treasury, guard pay | Released (Build 7 onward) | npc_brain.gd `reeve_day`, `pay_guards` | treasury_test, succession_test | V |
| Tax bands | Released (Build 18) | tax_policy.gd | tax_test | V |
| Fines | Released, partial (player theft only) | world.gd `guard_confront` | relations_test | V |
| Reeve and guard succession | Released | `_reeve_succession`, vacancies | succession_test | V |
| Offices, tenures, legacy records | Code (off), Tests pass | game/scripts/core/civic/ | civic_records_test 48; on/off identity over 30 days | V |
| Elected mayor | Design approved (P21-MAYOR) | | | V |
| Courts, investigation, elections | Not started | | | V |

### 7. Expansion 22 (Build 18 is the baseline)

| Capability | Status | Files | Evidence | Label |
|---|---|---|---|---|
| Five settlements with conserved economies | Released (Build 18) | settlement/offmap.gd, regions.gd | regions_test, settlement_test, regions_sim | V |
| Regional trade (traders, road trade) | Released, instant trips | regions.gd `road_trade` | regional_test | V |
| Couriers with journeys and losses | Released | settlement/couriers.gd | courier_test, courier_live_test | V |
| Migration (both ways) | Released | settlement/migration.gd | migration_test | V |
| Worker experience | Released | settlement/experience.gd | experience_test | V |
| Industrial capability | Released, neutral factors | industries.gd, profile.gd, capability_hook.gd (`bind` turns per-worker on) | capability_test, profile_test | V |
| Finite settlement resources | Released (quarry reserve, finite stocks) | offmap.gd | regions_test | P |
| Caravan allowance retired | Released (Build 18) | bf312b8 | regions_test | V |
| Hybrid simulation (E22-OD-01), continuous geography (E22-OD-02) | Design approved | | | V |
| Off-map housing, abandonment, knowledge transfer, travel-time trade | Not started | | | V |

### 8. Expansion 23

| Capability | Status | Files | Evidence | Label |
|---|---|---|---|---|
| Bandit NPCs, market trips, meals, robbery | Released | npc_brain.gd `_bandit`, `_bandit_market`, `band_eat`, `_prey_for` | world_test, od16_test, family_test | V |
| Loot recovery, stolen marks | Released | `_loot_to_recover`, player marks | od16_test, chests_test | V |
| Clan orphans, outlaws' return | Released | guardianship.gd `join_clan`, outlaws.gd | family_test, outlaw_return_test | V |
| Player assault and theft | Released (no fines for assault) | world.gd `player_hit_npc`, `player_assault` | relations_test | V |
| Factions, careers, hideouts, fencing, bounties, criminal reputation | Not started | | | V |

## 9. Authoritative ownership map (V)

| State | One owner | Readers in the expansions |
|---|---|---|
| Person identity | `NPC.id` (int) in `World.npcs`; refs `npc:<id>` | judgment (int), economy and civic (refs) |
| Personality and decisions | `NPCBrain` decides; judgment re-weighs feasible options | Expansion 19 |
| Relationships | `Relations` ties (regard, attraction) | judgment reads regard; bonds scale gains |
| Moral judgment, trust, beliefs, gossip | `JudgmentStore` (off) | |
| Free-text memory | `NPC.memory` (8 lines, dialogue) | parallel to judgment memories |
| Inventories and ownership | `NPC.inv`, pantries, chests, owner fields on things | economy reads them |
| Currency and accounting | World holders, `total_coins`, settlement books | |
| Economic transactions | `World.trade`/`give`, contracts, credit | economy event ring (off) records |
| Employment and skills | `NPCBrain` job market, `skills.gd`, `experience.gd` | |
| Settlements and population | `World` (village), `OffMapSettlement` (five) | |
| Migration and regional travel | `migration.gd`, `regions.gd`, `couriers.gd` | |
| Offices and civic finance | `World.reeve_id`, `vacancies`, `treasury`, `reeve_day` | civic records observe (off) |
| Crime and enforcement | `World.witness`, `guard_confront`, `report_crime`, `player.crimes` | judgment records deeds (off) |
| Historical records | `World.log_lines` (300), `NPC.memory`, `stats` | civic legacy (off) adds deaths and careers |
| Geography | village map, `overworld.gd`, `settlements.json` (miles, x) | |
| Explanations and diagnostics | scattered (section 7 of the alignment report) | |

## 10. Duplicate or overlapping implementation findings

| # | Finding | Kind | Label |
|---|---|---|---|
| D1 | A save holding a `judgment` section switches judgment on at load even when `judgment.json` says off (`world.gd:load_dict`) | **defect** (switch bypass) | V |
| D2 | A save holding an `economy` section loses it at the next save when the economy is off (`EconomyFoundation.attach` returns null) | **defect** (CLAUDE.md s.7: never silently drop saved data); Expansion 21's `civic_foreign` keeps it, the right pattern | V |
| D3 | X19-GUARD (friend guard halves a fine) is live behaviour on the Expansion 19 branch, not behind the judgment switch | owner-approved rule; a gameplay change with judgment off, not visible to the gate | V |
| D4 | Tolerance has two accumulators for the same firsthand event: the temperament's `life` shift (live) and personality drift (inert); setting the personality rates would count an event twice | overlap to resolve before the owner's formulas | V |
| D5 | Expansion 20 reservations and `contracts.held_for` both earmark goods; `available()` sees only its own, so integrating one without the other could claim goods twice | overlap to resolve at integration | V |
| D6 | "Is this person a known killer" has two answers: `Relations.killings`/`notoriety` (global) and judgment killing facts (per observer); owner kept the CRT-12 cut-offs | parallel by owner decision | V |
| D7 | `NPC.memory` (free text) and judgment memories run side by side | parallel by design | V |
| D8 | Economic-event types overlap Expansion 19's event catalogue with no bridge | complementary, unconnected | V |
| D9 | `CivicRecords.audit()` checks only open holders, not "a living reeve or guard with no tenure" as documented | incomplete diagnostic | V |
| D10 | A villager whose name begins with the player's name could publish a killing twice (`world.gd:kill` prefix match) | edge-case risk | U |

**Identity (V):** `Migration._person_of` carries no id; a returning person gets a new `NPC.id`, so relations, judgment, civic legacy
and economy refs all restart. The child who becomes the player's heir is erased from `npcs` (`life.gd:660`): its history is lost
and its id can be reused. Off-map people have no ids at all. One person-id space is the prerequisite for E22-OD-01.

## 11. Regression-risk matrix

| Existing mechanic | 19 | 20 | 21 | 22 | 23 |
|---|---|---|---|---|---|
| Friendship gains and caps (Relations) | **high** (bonds scale gains) | - | - | low | low |
| Trade choices, contracts, credit | **high** (six hooks) | **high** (offers, reservations) | low | medium (regional traders) | medium (fencing) |
| Courtship and marriage | medium | - | - | - | - |
| Treasury, taxes, guard pay | low | medium (transactions) | **high** (offices, mayor) | low | medium (bounties) |
| Fines and guard confrontation | **changed** (D3) | - | **high** (courts) | - | **high** |
| Succession of reeve and posts | - | - | **high** (elections) | - | medium (faction leaders) |
| Migration and settlements | low | medium | low | **high** (hybrid, ids) | medium (route banditry) |
| Bandits, loot, outlaws | low (feeds) | medium | medium | medium | **high** |
| Saves (version 19, optional keys) | **D1** | **D2** | low (kept) | **high** (geography, ids) | medium |
| Determinism (shared `w.rng`) | low (seeded hashes) | low | low | high | **high** (bandit logic uses `w.rng`) |

## 12. Test evidence and coverage gaps

- 101 test scripts in Build 18; CI runs 85 suites plus a 10-day `economy_sim` (V). 15 scripts exist outside CI (regions_sim,
  census, housing_trace and others) (V). `tools/sim_gate.py` is in no workflow or hook (V): determinism is checked only when run by hand.
- Branch CI additions: judgment suites (x19), economy_foundation_test (x20), civic_records_test (x21) (V). No CI run of
  `economy_sim --judgment` or `--civic` (V).
- Evidence on the current commits: c756211 ten suites and the gate (this session); 4d9bc05 and 8ac88f5 their workers' runs and the gate (V).
- **Gaps (V):** settlement promote/demote (no code); trade travel time; bandit faction state; elections; reservations wired to live
  trade; judgment over a long run (CI 10 days only; decay demo without a world); `report_crime` has no test by name; the player-theft
  path through `guard_confront` is outside the gate; the D1 and D2 save cases have no test.

## 13. Requirements already completed in earlier builds, and register corrections

Released or integrated (V, staging register): TREAS-01, EQ-19, EQ-20, EQ-21, STALL-05, FAM-07, PICK-01, CON-01, CON-02, DVW-B5,
TRADE-CREDIT, MIGRATE-18, REG-COURIER-01, REG-BUY-01, SET-A, SET-B, SET-C-FIVE, SET-C-SIM, SET-D, ECON-P1.3, X18-CAPCOMP, X18-CAPNUM,
PROS-18, REL18-SAVE.

Records that disagree with the code (proposed corrections, not made: the audit is read-only):
- B7-014 and B14R-02 still describe the caravan allowance, removed in bf312b8: mark superseded by ECON-P1.3.
- DVW-B1 "PARTIALLY IMPLEMENTED, NOT TESTED": relations_test has covered Relations since Build 15 (verification at least TARGETED TESTS PASSED).
- EXP-B, EXP-C, EXP-D and LE-01 "NOT STARTED": work exists beneath them (Build 18 settlements; the judgment branch; the economy
  foundation partly covers LE-01's actor and reservation records).
- WDR-015-C text "no elections, council, magistrate" is current; WDR-016-C "no factions" is current.

## 14. Genuine remaining work

1. Fix D1 and D2 (save handling of switched-off sections) and decide D3 before any of the three branches merge.
2. One person-id space across village, settlements, migration and heirs (E22-OD-01 prerequisite; also protects judgment and civic history).
3. Resolve D4 (one tolerance accumulator) and D5 (one goods earmark) at their integrations.
4. Merge plan for `world.gd` (Expansions 20 and 21 conflict in four places; all three in `to_dict`).
5. CI: the determinism gate and a long `economy_sim --judgment` run belong in a workflow.
6. Then the approved but unbuilt items per expansion (judgment activation and misinformation; needs, offers, knowledge; elections;
   hybrid simulation and geography; factions).

## 15. Recommended development sequence (for the owner's decision; no assignment opened)

1. **Preservation fixes on the prospective branches**: D1, D2 (and D3 per the owner), with tests for each save case.
2. **Identity foundation** (stable person ids through migration and heirs), because Expansions 19, 21 and 22 all depend on it.
3. **One integration branch for 19-21 foundations** (switches off), resolving the `world.gd` conflicts once, gate in CI.
4. **Expansion 19 Gate E** after the owner's numbers; **Expansion 20 LE-01/02** after the architecture review; **Expansion 21
   elections** after P21-STRUCTURE; **Expansion 22 hybrid and geography** after the identity foundation; **Expansion 23 BAN-B**
   after its decisions.
