# Build 18: overnight report (session of 2026-10-22, read 2026-10-23)

Factual record of the overnight session under `docs/directives/2026-10-22_build18_master_overnight_execution.md`. Owner
playtesting has not happened since you went to sleep. Nothing was built, published or released. Build 17 (`cd7439c`) is
untouched.

## Executive summary

- **`wip/build18`:** `0fafb8b` to `c7df646` (32 commits).
- **Staging:** the latest records commit is on `staging/my-medieval-life`.
- **Merged into Build 18 tonight:**
  - the categorized inventory (INV-18: save version 19);
  - the tailor's upgrade purchase (TAILOR-18; nobody is a tailor yet, see TAILOR-Q);
  - armour Option A with the character redraw (ARMOR-01, which completes CC-01);
  - Expansion 18 with its inactive parts off;
  - rock-cut step art;
  - the contract window fits the screen;
  - grammatical refusals;
  - a fix for 14 script errors my own buy-box change had caused.
- **Completion estimate (same scope and method as before):** about 47% by count, up from about 42% last night. By effort,
  roughly 35–45%. Estimates, not measurements.
- **Approved Build 18 requirements (49):**

  | Status | Count |
  |---|---|
  | Complete and verified | 1 |
  | Implemented, awaiting your playtest | 19 |
  | Partially implemented | 8 |
  | Active development | 7 |
  | Not started | 12 |
  | Deferred | 2 |

- **Workers tonight:** three started, all on Sonnet (armour, Expansion 18 readiness, polish). The inventory worker was
  already running on the session's inherited model. No worker is running now.
- **Blockers:** owner decisions (below); then the release gate. No defect is open.
- **Simulation integrity:**
  - no conservation or determinism failure seen;
  - item and coin conservation is covered by the inventory tests;
  - the determinism gate has not been re-recorded on Build 18 code: prospecting placement, crop sharing and experience
    recording changed what a run produces.

## Development

| Commit on `wip/build18` | What |
|---|---|
| `5f82f0c` | INV-18 merge (worker commits `2e62c61`, `bf63118`, `5f9ff33`, `ba1369e`) |
| `609635d` | ARMOR-01 Option A merge (`9f3a237`): iron armour shows the metal breastplate, the iron helmet the novice helm; leather draws nothing extra |
| `d63d8d7` | Expansion 18 merge |
| (merge) | Polish (`8366315`) |
| `c7df646` | Quantity box script-error fix |

**Expansion 18:**
- experience recording is live and only records;
- the capability hook is OFF;
- couriers, formal contracts, the settlement report and regional trade are present but nothing calls them;
- conflicts were resolved by keeping both sides, which gives identical values while the hook is off.

**Fixed tonight:** the 14 quantity-box script errors (introduced by my TRADE-AXE-01 fix).

**Worker reports, corrected by the lead:**
- the inventory worker's "3+1 save-timing failures" came from concurrent runs sharing a user folder; rerun isolated,
  both suites pass;
- the armour worker's uncertain wiki test passes on the merge.

## Build 18 status

**Remaining critical path:**
1. Your decisions: TAILOR-Q, BARBER-Q, then Expansion 18 D2–D9, HORSE-Q.
2. Implement what they unlock: tailor placement, barber, Expansion 18 activation and simulations, the horse.
3. Track C items, which need design specifics first.
4. The release gate:
   - integrated suites;
   - determinism re-record;
   - conservation;
   - one year-long run per seed;
   - save migration from Build 17;
   - three-platform export;
   - device checks.

**Outstanding owner decisions, in dependency order:**
1. TAILOR-Q: where the tailor comes from.
   - A: add one tailor to the starting population (changes new-world generation).
   - B: convert an existing worker (e.g. a merchant).
   - C: an existing trade sells the upgrades on the side (e.g. the tanner).
   - D: a job-market place nobody takes (effectively unavailable).
2. BARBER-Q: who, where, price, and whether colour and beard count.
3. Expansion 18 D2 (facility limits), then D3–D9 in order (`docs/expansion18/DECISIONS_PENDING.md`); then Q18-1..8 and
   Q18-14..16 for couriers, regional trade and formal contracts.
4. HORSE-Q: the plough horse's price, feed and what it does.
5. Track C specifics: player businesses, property, modular buildings, coin sinks, taxes, World Design Rule 11.
6. Older items: BANDIT-Q, OD-05, OD-06, OD-08, ECON-P1.3, ECON-P3, CON-UX-01 (the wider contract-window design),
   WORLD-LIFE-01, seed sharing in crop shares.
7. Multiplayer: excluded from Build 18 by your instruction.

## Testing

**Run tonight** (Godot, each process with its own `XDG_DATA_HOME`), on the code each merge produced:

| Tested at | Results |
|---|---|
| `d63d8d7` | `run_tests` 3,584 checks; start 506 steps; play 39 steps; inventory 88; experience 61; capability 72; farming 224; crop sharing 19; contracts 138; courier 44; settlement 83; wiki and character look passed. All 0 failures |
| `c7df646` | start 506, `run_tests` 3,584, inventory 88, play 39: all 0 failures and 0 script errors |
| The polish merge | contracts 138, services 51, terrain 34, wiki: 0 failures |
| ARMOR-01 merge | equipment 51, character look, start, wiki: 0 failures |

Python 105 tests: OK. Asset, interaction and register checks: 0 problems.

**Reused, not rerun:** Expansion 18's focused results from its branch (settlement 83, regional 71, contract signing 20),
tree 45, prospecting 73, and the earlier track A evidence.

**Deliberately avoided (MSW-01):** year-long runs, determinism and conservation campaigns, three-platform exports and
the full gate. They're premature while the decisions above are open, and the evidence would go stale.

**Save migration:** version 19 migration is tested on version-18 fixtures, including over-capacity categories. Expansion
18's optional keys seed experience once on load. A real Build 17 save has not yet been loaded into Build 18 (that's part
of the gate).

## Claude usage

- **Models:** the session ran on the configured model. The armour, readiness and polish workers ran on Sonnet, matching
  the preference recorded in `docs/release/BUILD_12_AI_EFFICIENCY_AUDIT.md`. The inventory worker, started before
  tonight's directive, inherited the session model and was not restarted.
- **Workers started tonight:** 3. Work per worker:
  - armour: ARMOR-01 and the redraw;
  - readiness: a review note and focused test results;
  - polish: steps, grids, grammar.
- **Usage limits:** none hit. Remaining account usage can't be seen from here.
- **Duplicate work:** none found. The only reruns were the lead's isolated checks of two suites the inventory worker
  reported as failing.
- **Checkpointing:** all work is committed and pushed, the recovery handoff is current, and no worker is running.
