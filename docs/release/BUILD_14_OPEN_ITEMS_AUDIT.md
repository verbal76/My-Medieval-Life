# Build 14 open-items audit and build-readiness review

Owner directive: `docs/directives/2026-10-19_open_items_audit.md`.
Audit date: 2026-10-19, at staging `1458da8` and `wip/multiplayer` `d18d7d1`.

The register of record is `docs/DEVELOPMENT_LEDGER.md`, updated by this audit; there is no second backlog.
The queue (`docs/DEVELOPMENT_QUEUE.md`) gives the order of work and points to the ledger.

## Evidence sources

**Documents**
- Every planning, issue, punch-list, audit, decision and design document in `docs/`.
- The 147-entry interaction manifest.
- The in-game wiki source.

**Repository and GitHub**
- Every local and remote branch.
- All 37 worktrees.
- `refs/backup/*`.
- GitHub pull requests, issues and releases.

**Transcripts and tests**
- Both session transcripts, which hold about 181 distinct owner messages and 22 answered question rounds, 2026-10-17 to 2026-10-19.
- The full test suites, run during this audit.
- New 100- and 365-day economy runs, started during this audit.

**Coverage gaps (stated, not guessed)**
- The two Build 11 punch lists, Bob's design files, the corrected-documents zip and *Designing Virtual Worlds* arrived as attachments. Their contents are known only through the documents made from them.
- The off-machine backup artifact was not re-downloaded for this audit.
- Your directives refer to "16 World Design Rules". No list of 16 exists in the repository or the transcripts. The design document has 9 numbered principles, and this audit added the three you asked for as 10 to 12.
- No real device (phone, controller, Windows PC, Steam Deck) has ever been used. Every "verified" in this project means headless or virtual-display tests and screenshots.

---

## The ten questions

1. **Outstanding items: 81.** Every requested feature, fix or system not yet complete and verified (register below). Another 109 recorded items are complete and verified headless (ledger).
2. **Actively worked on: 2.**
   - The multiplayer prototype (MP-01, `wip/multiplayer`).
   - The money-supply re-measure (DVW-A3), with 100- and 365-day runs in progress.
3. **Partially implemented: 16.**
4. **Not started: 27** approved items.
5. **Blocked or deferred: 18 blocked and 2 deferred.**
   - Blocked: 8 on an outside need (signing secrets, Google client, art or audio, an owner decision on the horse); 10 are groups of open owner decisions.
   - Also 13 items implemented but unverified (real device or controller), and 3 of unknown status.
6. **Approved requests missing from the backlog: 31.** All are now restored to the ledger (section C).
   - 3 more were in it with the wrong status (carts, Craftpix and Animal Farm were marked "not started").
7. **Biggest bottleneck: verification, not code.**
   - Nothing has ever run on a real phone, controller or Windows PC; 13 items wait only on that.
   - Every Android test build uses a throwaway key, so updating a build deletes the tester's save (B13-15: the signing secrets are missing).
   - In code, the next large approved systems (generational memory, politics) all wait on one unstarted piece, villager relationships (DVW-B1).
8. **Next clean build boundary:** staging at the end of this audit (`1458da8` plus the audit's documentation commit), once the running 100-day economy runs show no regression from the Build 14 systems. It is single-player only; multiplayer stays out.
9. **Recommendation: finish a short list first, then build (Option B).** The list is about one working session (section E).
10. **Immediately afterward:**
    - cliff steps, stairs and walkways (B14-07), which is next in your order;
    - then villager relationships (DVW-B1), which unblocks generational memory and politics;
    - then wildlife refuges (WR-01).
    - Multiplayer continues in parallel on its own branch.

---

## B. Executive summary

**Finished since Build 13** (all verified headless, on staging):
- Build 14's first six items: harvest or talk; villagers' home production; house storefronts; cart parts; local pricing; carts in play.
- Forest animals, with the predator balance follow-up.
- Apple trees from Craftpix.
- The asset integration pipeline, with its skill, registry and scaling standard.
- The sword-combat fix (CQ-01).
- Controller detection on phones (B14-13).
- The Animal Farm horse is imported but not in play.

**Active:**
- Multiplayer: a two-player LAN prototype on `wip/multiplayer`. Its 36 multi-process checks pass, and guests can only walk.
- The money-supply re-measure.

**Approved, not started:**
- Generational memory (GM-01), wildlife refuges (WR-01) and politics (VP-01).
- Seven of the eight *Designing Virtual Worlds* proposals you chose.
- Nine agent checks from the book: backups, re-measure, exploit test, perks audit and others.
- Cliff steps, skeletons and the sprite list.
- Several forgotten requests (section C).

**Blocked:**
- Android signing (your secrets).
- Cloud saves stages 2–5 (your Google client).
- The horse's role (your decision).
- Lizards and spiders, and audio (no assets).
- Ten groups of earlier owner questions, listed in G.

**Health**
- All 19 game suites and 73 Python tests pass on staging, and the multiplayer suite passes on its branch.
- Money is conserved in every test run.
- The first 20 days of the new runs: 100 to 103 villagers alive, nobody starved, no money or item leaks, unemployment 0.
- Iron ore and coal reach 0 by day 10, as in Build 7 (deposits do not refill: B7-007, an open owner decision). The full 100-day results go in `LONG_RUN_SIMULATION.md` when the runs end.

---

## A. Open-items register (81 outstanding items)

**Column key**
- **Code:** code exists / committed / pushed, and the branch.
- **Tests:** whether automated tests cover it and pass.
- **Play:** checked in play (screenshot or scripted scene) as opposed to unit tests only.
- **Docs:** W = wiki, D = developer docs, M = interaction manifest. ✓ = updated, – = not needed or not yet.

All code below is on staging and pushed, unless the branch says otherwise. The last column is the build class:
- **NB:** nonblocking backlog.
- **PL:** a playtest limitation to disclose.
- **BB:** a build blocker. None remain.

### In active development (2)

| ID | Item | Code | Tests | Play | Docs | Blocker / deps | Next action | Pri. | Build |
|---|---|---|---|---|---|---|---|---|---|
| MP-01 | Two-player LAN multiplayer | Yes, `wip/multiplayer` `d18d7d1`, pushed, **not in staging** | net_test 36/36, single-player suites pass on branch | Loopback processes only | D ✓ (MULTIPLAYER.md), W –, M – | Real devices; your approval to merge | Four-process test; the next shared action (buy); Wi-Fi test on two devices | High (parallel) | Excluded |
| DVW-A3 | Re-measure the money supply, 100/365 days | Harness exists | economy_sim self-checks | — | D pending | Running time | Record results in LONG_RUN_SIMULATION.md | Immediate | Gate for Option B |

### Implemented, not verified (13; waiting on a real device or controller)

| ID | Item | Commit | Tests | Missing verification | Build |
|---|---|---|---|---|---|
| B7-001 | 20 starting coins | `ae0e01f` | yes | Play feel on a phone | PL |
| B7-005 | Earning money discoverable | `ae0e01f` | yes | Phone readability | PL |
| B7-010 | HUD anchoring on Android | `633898f` | yes | Phone | PL |
| B7-011 | Tap trees and ore | `633898f` | yes | Phone | PL |
| B7-012 | Gather mode | `c8dce2e` | yes | Phone, pad | PL |
| B7-013 | Brown glyph icons | `49f5cb9` | yes | Phone look | PL |
| Q4 | Resources & Gathering journal page | `8641ff6` | yes | Phone | PL |
| B13-12 | B closes only the quantity picker | `0570f14` | yes | Real controller | PL |
| B13-13 | Touch Run toggle | `0570f14` | yes | Phone | PL |
| B14-01 | Harvest or talk (A / Y) | `60a365b` | yes | Real controller | PL |
| B14-06 | Carts in play | `512f1bc`, `f9fb853`, `8ae29c2` | home_test, 18 cart checks | Phone; stand-in art | PL |
| B14-13 | Controller on a phone hides touch buttons | `1458da8` | start_test | Phone with a pad | PL |
| CQ-01 | Sword responsiveness and reach | `3e283b6` | combat_test 41 | Phone touch feel | PL |

### Partially implemented (16)

| ID | Item | What exists | What remains | Next action | Pri. | Build |
|---|---|---|---|---|---|---|
| B7-007 | Deposit depletion / stone source | Stone by caravan; raw ore not exported | Deposits never refill. The new run shows iron and coal at 0 by day 10 | Your choice among P1.1–P1.5 (G) | High | PL |
| B7-015 | Missed meals while food piles up | Guards provision households (INT-072) | Rest of the design | Re-measure, then decide | Med | NB |
| B7-016 | Tanners and goods merchants end at 0 coins | Merchant retail (INT-073) | P3 proposals | Your decision | Med | NB |
| B7-017 | Households build and grow | Births and aging (B8-029) | Never measured over a year | 365-day run (running) | Med | NB |
| B8-007 | Tool swing art | Icon-in-hand overlay | Real swing art | Art needed | Low | PL |
| PL1-07 / PL2-013 | Sit and lie poses | Lying frame | Sit art | Art needed | Low | PL |
| PL1-10 | Player businesses | Stages 1–4 | Production chains, display sprite, shops in rented houses | Next business pass | Med | NB |
| PL1-13 | Recognisable stove | Hearth with pot | Chimney art | Art | Low | NB |
| PL2-008 / 014 | Modular property | Rooms added later | Inner doorways, survey plots (your questions) | Decision | Low | NB |
| PL2-010 | Sawhorse look | Trestle bench | Saw art | Art | Low | NB |
| PL2-015 | Farming and livestock | Till, sow, pens, products | Coops, farm help, draught animals (horse), trapping, water | After B14-11 | Med | NB |
| B14-10 | Craftpix plants | Apple trees | Crop stages, produce icons, crates on storefronts, more fruit trees | Asset pipeline next pass | Med | NB |
| DVW-B9 | Readable danger | Cause of death | Howl and roar cues, lethal-need warnings | With WR-01 | Med | NB |
| DVW-A6 | Conservation across save/load | Coins checked | Goods | Add a goods round-trip test | High (cheap) | NB |
| DVW-A13 | Every visible object has a use | Handcarts now used | Feathers have no consumer | Fletching or bedding recipe | Low | NB |
| FR-06 | Wiki completeness | Sword, carts, apples added | Magic, employer star, journal and map, death causes, caravan, bandits | Write the pages | Med | PL |

### Planned, not started (27; all approved)

| ID | Item | Deps | Next action | Pri. |
|---|---|---|---|---|
| B14-07 | Cliff steps, wooden stairs, walkways (Forgotten Memories ramps; DVW-A10 no dead ends) | — | Start now (next in your order) | Next |
| B14-09 | Skeletons in caves and wild woods | Overworld generator version bump | After B14-07 | Next |
| B14-12 | Sprite list with pixel-grid copies | `sheets.py contact` ready | Generate the package | Next (cheap) |
| GM-01 | Generational memory (the 30-planks chain) | DVW-B1 | Event records first | Following |
| WR-01 | Wildlife breeding refuges and dispersal | B14-08 | Refuge model, cohorts | Following |
| VP-01 | Village politics, elections, offices | GM-01, DVW-B1 | After GM-01's event layer | Long-term |
| DVW-B1 | Relationships: favours, gifts, harms, gossip | — | Start after B14-07 | Next |
| DVW-B2 | Assault and killing as fined crimes | — | With B1 | Next |
| DVW-B3 | Coin sinks worth spending on | A3 results | After re-measure | Following |
| DVW-B4 | Goods decay and wear | — | | Following |
| DVW-B5 | Predictable taxes (hysteresis, announced) | — | Small | Next |
| DVW-B6 | Wildlife wandering in | WR-01 | Build with WR-01 | Following |
| DVW-B7 | Life chronicle, titles, memorial | GM-01 | Build with GM-01 | Following |
| DVW-A2 | Rotate several dated save backups | — | Small | Next (cheap) |
| DVW-A4 | Coin and goods source/sink ledger | A3 | From sim output | Next |
| DVW-A5 | Exploit test (arbitrage, round trips, flooding) | — | Write test | Next |
| DVW-A7 | Skill over-production check | — | | Following |
| DVW-A8 | Player-only perks audit | — | | Following |
| DVW-A9 | The player can always escape predators | — | | Next |
| DVW-A12 | Rules in core, not UI | — | Audit list | Following |
| DVW-A14 | Play one whole life before a release | — | Add to checklist | Next (cheap) |
| F-1 | NPC workshop construction | — | | Following |
| FR-02 | Forgotten Memories waterfalls, fences, props | — | With B14-07 | Next |
| FR-03 | Campfire for cooking outside the village | — | Small | Next |
| FR-04 | Pad shortcuts for Journal and Build; full controls list | — | Small | Next |
| FR-05 | Title window opens scrolled to the bottom | — | Investigate | Next (cheap) |
| FR-07 | Economy and household sims in CI (short variant) | — | Small | Next |

### Blocked (18)

| ID | Item | Blocked by | Build |
|---|---|---|---|
| B13-15 | Stable Android test key (updates keep saves) | Your three signing secrets | PL (testers must uninstall) |
| PL1-11 | Google Drive cloud saves (stage 1, portable saves, is done; stages 2–5 remain) | Your Google OAuth client | NB |
| B14-11 | The horse and farm animals in play | Your decision on the horse's role | NB |
| FR-01 | Lizards and spiders as enemies | No lizard pack (Puny Monsters spiders could serve caves) | NB |
| FR-08 | Music and sound | No audio supplied | PL (silent game) |
| Q10 | Hot Attic Games registry | Your decision on a private location | NB |
| ENV-RTK | Token tool persistent in the environment | Your environment setup script | NB |
| P0-3 | Delete the old `inventory/registry` branch | You (manual) | NB |
| OD-1 | Economy sustainability P1 (mining, quarry, prospecting) and B7-006 mine wage | Your decision | PL |
| OD-2 | Balance review of every provisional number | Your review | NB |
| OD-3 | Design gap assessment D1–D12 (isometric, magic, era, county) | Your decision | NB |
| OD-4 | Chest and lock questions (NPC relock, NPC thieves, lock tiers) | Your decision | NB |
| OD-5 | Inner doorways; relaying survey plots | Your decision | NB |
| OD-6 | Farming questions (Farming skill, wheat versus wages) | Your decision | NB |
| OD-7 | Hunting in Gather mode | Your decision | NB |
| OD-8 | Is honest arbitrage intended? (DVW-A5) | Your decision | NB |
| OD-9 | GAME_DESIGN items still open (U3–U5, U13, U16–U21, including monetisation) | Your decisions | NB |
| OD-10 | Confirm or reverse what the economy agent built without a recorded decision: the B7-009 day-labour reserve, the caravan purse (B7-014 / P1.3) | Your confirmation | NB |

### Deferred (2) and status unknown (3)

| ID | Item | State |
|---|---|---|
| FR-09 | Crime from desperation | Deferred by you ("not yet") |
| FR-10 | Archery | Deferred: future, not authorised |
| FR-11 | Personality, prestige, migration | Partly present (apprenticeships, memories, newcomers). Personality traits and prestige not found. Scope to settle with GM-01 and VP-01 |
| PL1-12 | Red flowering plant in the overworld | Ledger says verified; the Build 12 audit says it is not drawn outside the village. Recheck needed |
| BK-1 | Off-machine backup current | Not re-verified in this audit. GitHub staging and `wip/multiplayer` hold all current work |

### Complete and verified (headless): 109 recorded items

The rows are in `docs/DEVELOPMENT_LEDGER.md` and the Build 7, 8, 11, 12 and 13 records. They include:
- every B8 master item except tool art;
- PL1-01 to 06, 08, 09;
- PL2-001 to 007, 009, 011, 012;
- B13-01 to 14;
- B14-02 to 05 and B14-08;
- the asset pipeline and WDR-10..12.

---

## C. Owner requests missing from the active backlog (31 restored, 3 corrected)

Found by comparing every owner message in the transcripts with the queue and ledger. All are now ledger rows.

| Restored | Why it was missing |
|---|---|
| DVW-B1, B2, B3, B4, B5, B6, B7, B9 (8) | You approved all eight on 2026-10-19 (`749a9cd`); never given rows |
| DVW-A2 to A9, A12, A14 (10) | The book review said they were "folded into the queue"; they were not |
| B14-13 controller detection | Your message at 18:25 arrived during a restart and was never seen. Built and tested in this audit (`1458da8`) |
| WDR-10..12 | Requested in the memory/politics directive; added in this audit |
| FR-01 lizards and spiders | You called them "good enemies"; the plan listed them as "not approved" |
| FR-02 Forgotten Memories waterfalls, fences, props | No task after the pack check |
| FR-03 campfire | You asked; recorded as "needs approval" |
| FR-04 pad shortcuts | Build 12 audit finding, never queued |
| FR-05 title scroll | Build 13 packet note, never queued |
| FR-06 wiki gaps | Build 12 audit finding, only partly done |
| FR-07 sims not in CI | Found by this audit |
| FR-08 music and sound | On the queue's future list only |
| FR-09 desperation crime | Your design intent, deferred by you |
| FR-10 archery | Named in the sword directive as future |
| FR-11 personality, prestige | From your living-society list |
| **Statuses corrected (3)** | B14-06 carts, B14-10 Craftpix and B14-11 Animal Farm were marked "not started" though built or imported |

**Also found:**
- Your four 2026-10-19 directives were not in the repository. They are now in `docs/directives/`, verbatim.
- Several documents still say Build 7 or 8 is current and births are not built (`HANDOFF.md`, `DEVELOPMENT_PLAN.md`, `GAME_DESIGN.md` undecided items, `BUILD_DECISIONS.md` known gaps).
  - The queue's header and birth line are fixed in this audit.
  - The rest is documentation work (section F).

**Unanswered questions from earlier rounds:**
- 10-18 06:46: the maintenance wear model, staff fallback, manor hands on the job board, board wages.
- 10-19 18:04/18:24: elected reeve or mayor, who votes, the order of the new work, the horse.
  - The politics directive answers most of the first: mayor elected, constable elected or appointed, captain appointed.
  - So only the horse remains in G.

---

## Section 5 of your directive: what is being worked on

**Staging**
- Clean, at `1458da8`, pushed except this audit's documentation commit.
- Builds 8, 12 and 13 are contained in it, and Build 13 is 18 commits behind.

**`wip/multiplayer`**
- `d18d7d1`, pushed today. It was briefly unbacked: the branch audit found it uncommitted; it was committed and pushed within the hour.
- Not merged.

**Other worktrees**
- 36 older agent worktrees. Their content is 84–99% in staging by patch.
- The remainder is superseded generated data (`village.json` before generator v6).
- Ten hold uncommitted files identical to their backup snapshots. None holds work missing from staging that is still wanted.
- They can be pruned later; nothing was touched.

**Pull requests**
- PR [verbal76/My-Medieval-Life#1](https://github.com/verbal76/My-Medieval-Life/pull/1) (draft, build-6 era, into `main`) is stale. Closing it is your call (G).
- No issues are open.
- Releases: Builds 1–7 published as prereleases; Builds 8–13 drafts. CLAUDE.md does not mention drafts 9–11.

**Cart tests**
- They show progress, not regressions:
  1. parts (`d01376c`);
  2. in play (`512f1bc`);
  3. 18 new checks (`f9fb853`);
  4. wiki (`8ae29c2`).
- No cart check has failed in any recorded run. The failures seen during that work were in the wildlife test, caused by a random-number shift; the predator balance fix (`f9fb853`) resolved them.

**Asset pipeline**
- Working: the skill was invoked, `check_assets` reports 0 problems, and the registry is current.
- Packs still planned: Puny Dungeon, Skeletons, Forgotten Memories, Animal Farm.

---

## Section 6: test and regression review

| Suite | Result at staging `1458da8` / `3e283b6` | In CI |
|---|---|---|
| run_tests | 3528 checks, 0 failures | yes |
| start_test | 487 steps, 0 failures | yes |
| business_test | 155/0 | yes |
| home_test | 113/0 (carts, apples, storefronts, pricing) | yes |
| wildlife_test | 57/0 | yes |
| world_test | 116/0 | yes |
| farming_test | 155/0 | yes |
| aging_test | 101/0 | yes |
| chests_test | 72/0 | yes |
| property_test | 62/0 | yes |
| health_jobs_test | 37/0 | yes |
| play_test | 37 steps/0 | yes |
| overworld_test | 101/0 | yes |
| tree_test | 45/0 | yes |
| wiki_test, skills_test, furniture_test | all passed | yes |
| combat_test | 41/0 | yes |
| Python unittest | 73, OK | yes |
| net_test | 36/0 | branch only |
| economy_sim, households_sim | Self-checking; not in CI | no (FR-07) |

**Status of the suites**
- Skipped: none.
- Known flaky: none current. Rng-sensitive suites (start_test, wildlife_test) were fixed at the cause when they broke: the waypoint overshoot, and the predator balance.
- Untested systems: four-player play, Android hosting, real input devices, the overworld beyond its tests, and year-long balance on current rules (running).

**Risk areas**
- **Save/load:** no regression known. The save gains an optional `guests` key only on the multiplayer branch.
- **Economy duplication:** coins and items are conserved in all test runs. No exploit test yet (DVW-A5). The stall-flooding exploit is noted, low risk.
- **Combat:** fixed in CQ-01; NPC and bandit combat is still tested.
- **Controller and touch:** all checks are simulated events; none on hardware.

---

## D. Build-readiness report

| Area | State | Class |
|---|---|---|
| Startup, world generation, loading | All suites pass; fixed village v6, save v14 | OK |
| Core loop (work, earn, craft, trade, build, fight, die, heir) | play_test end to end | OK |
| NPC simulation | 100+ villagers, no starvation in 20 days of the new run | OK; 100-day check pending |
| Economy | Conserved. Iron and coal run out by day 10 (deposits never refill; your open decision) | PL |
| Save/load | Atomic, one backup, refusal of unusable saves | OK (more backups: DVW-A2) |
| Combat | Fixed (CQ-01) | PL (touch feel unverified) |
| Carts | In play, stand-in art | PL |
| UI and controls | Touch, pad and keys, all simulated | PL (no device check) |
| Android | Builds; throwaway key: an update needs an uninstall that deletes the save | PL (B13-15) |
| Sound | None | PL |
| Uncommitted work | None on staging; multiplayer is pushed to its own branch | OK |
| Branch risk | Multiplayer kept out | OK |
| **Build blockers** | **None found** | |

Best checkpoint: staging after this audit's documentation commit.
- It is `1458da8` plus documents only, and contains everything since Build 13.
- It still needs the 100-day results before it is recommended for a build.

---

## E. Next build recommendation

| | A. Build now | B. Short list, then build (recommended) | C. Keep developing |
|---|---|---|---|
| Benefits | Testers get storefronts, carts, pricing, forest animals, apple trees and the sword fix today | The same, plus confidence that 100 days of play do not break the economy or the wildlife; fresh notes for testers | Bigger feature set per build |
| Risks | Year-long effects of the Build 14 systems unmeasured | About one session of delay | Many untested systems pile up; no device feedback on CQ-01 or carts; harder to bisect a regression |
| Blocking tasks | None | 100-day runs (running); fix anything they show; Build 14 packet | — |
| Playtest value | High | High, with better notes | Delayed |
| Validation | Full suites (done) | Suites plus 100-day runs plus a packet | Later, larger |
| Impact on development | Nil | Nil: multiplayer and B14-07 continue meanwhile | Nil now, more later |
| Stopping point | `1458da8` + docs | Same commit or a fix on top | After GM/WR/VP (weeks) |

**B is recommended.** The code is green and Build 14 already holds substantial playable value. The one unmeasured risk is long-run behaviour of seven new systems that touch money and wildlife, and the runs that measure it are already going. Nothing in the short list stops other work.

**The short list for B:**
1. Finish the 100-day runs (both seeds), record them in `LONG_RUN_SIMULATION.md`, and fix any regression they show.
2. Recheck PL1-12 (red plant outside the village) and FR-05 (title scroll). Both are cheap, and both are visible in testing.
3. Write the Build 14 packet with the tester notes:
   - uninstall before installing (unless your signing secrets exist by then);
   - stand-in cart art;
   - no sound;
   - what to check on a phone (section G).
4. Ask you for approval of Build 14 from that commit. Multiplayer is not included.

---

## F. Prioritised development plan

**Immediate (now, in parallel)**
- Option B short list.
- B14-07 cliff steps, stairs and walkways, with FR-02 Forgotten Memories ramps, fences and waterfalls.
- Cheap fixes: DVW-A2 backups, DVW-A6 goods conservation test, FR-04 pad shortcuts, FR-05, FR-07 sims in CI, DVW-A14 checklist line.
- Stale documents: handoff, plan, game design undecided items, BUILD_DECISIONS known gaps, CLAUDE.md drafts 9–11.

**Next build (15)**
- B14-12 sprite package.
- B14-09 skeletons, with the Puny Dungeon caves.
- DVW-B1 relationships and DVW-B2 assault fines.
- DVW-B5 taxes.
- DVW-A5 exploit test, DVW-A9 escape check, DVW-A4 ledger.
- FR-03 campfire.
- FR-06 wiki pages.
- B14-10 crop stages and storefront crates.
- MP-01 phase 2 (four processes), on its branch.

**Following builds**
- WR-01 refuges with DVW-B6 wandering-in and DVW-B9 cues.
- GM-01 generational memory with DVW-B7 chronicle.
- DVW-B3 coin sinks (sized from the re-measure) and DVW-B4 decay.
- DVW-A7, A8, A12 audits.
- PL1-10 business chains.
- MP-01 phase 3 shared interactions, one system at a time.

**Long-term**
- VP-01 politics on top of GM-01.
- MP-01 phases 4–5 (Android hosting, internet).
- F-1 NPC workshop construction.
- Isometric and magic (your D-decisions).

**Independent while blocked**
- Multiplayer (its own branch).
- Asset passes (Craftpix, Forgotten Memories, skeletons).
- Documentation.
- Test hardening.

---

## G. Owner action list (only what needs you)

1. **Approve Build 14** after the short list (E), or tell me to build now (A).
2. **Android signing:** create the test keystore and add its three secrets (`docs/release/ANDROID_SIGNING.md`). Until then every update deletes the tester's save.
3. **Real-device checks** with the next build:
   - phone touch and HUD, Run, Gather, carts, and the sword;
   - a controller on PC and on a phone (B14-13);
   - the Windows exe.
   - For multiplayer later: two devices on your Wi-Fi.
4. **The horse:**
   - (1) plough horse sold by the caravan (recommended);
   - (2) a manor stable, which changes the map;
   - (3) plough plus carts.
5. **Confirm or reverse** the economy agent's undecided changes (OD-10): the day-labour reserve and the caravan purse are in the game and working.
6. **Deposits:** choose a sustainability option (P1.1–P1.5). Iron and coal run out by day 10.
7. **Housekeeping:**
   - close stale PR #1;
   - delete `inventory/registry` (P0-3);
   - say whether drafts 9–11 should be listed.
8. **"16 World Design Rules":** if a list of 16 exists outside the repository, please share it; otherwise rules 10–12 extend the existing nine.
9. **Optional, when convenient:**
   - Google OAuth client (cloud saves);
   - lizard and audio assets;
   - the balance review;
   - the open design decisions (OD-2 to OD-9).
