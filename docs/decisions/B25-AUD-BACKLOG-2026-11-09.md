# B25-AUD-BACKLOG-2026-11-09: the overnight audit backlog (LIFE-05, BIZ-03, BIZ-04, TRD-02, INV-04, INV-05, SAV-02; EMP-03 unchanged) and the PROP-03 test, merged at `c9da5db`

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - the overnight directive of 2026-11-09 (saved verbatim);
> - issue #4 comment 12 (BIZ-03);
> - commits `cbd91f6`, `93327ae`, `3e9b9a1`, `36fa011`, `969a8f4`, `e42a37f`, `f67afdb`, `199809b` and `c9da5db`;
> - Actions runs;
> - the state file and the audit register reconciliation (`257475c`).
>
> All the code was written by the lead (Claude). Times are UTC.

## A. Identity and timeline
- **IDs:** audit items MML-LIFE-05, BIZ-03, BIZ-04, TRD-02, INV-04, INV-05, SAV-02, EMP-03 and PROP-03. Proposed register ids
  B25-AUD-* (coverage register, section 8).
- **Branch:** `wip/b25-backlog`, based on `f0a854c`, worked 2026-11-09 07:00-08:44.
- **Timeline:**
  - 08:54: strict run 42589325057 on `f67afdb`.
  - 11:11: `wip/b25-backlog-merge`, with `199809b` (backlog onto `53a56d3`) and `c9da5db` (plus `b727954`).
  - 11:11: strict run 42607051457 and gate 42607055494.
  - 12:40: attempt 2 of the strict run.
  - 13:37: recorded campaign 42627103286.
  - 17:25: `wip/b25r2-rev2` fast-forwarded `53a56d3` → `c9da5db`.

## B. Original situation and owner decisions
The audit raised these as owner questions or code-supported concerns. The owner answered them on 2026-11-08, and the overnight
directive of 2026-11-09 lists the answers verbatim ("Approved decisions"). The directive also told the lead to "reconcile the
decision register ... against these approved decisions" and to continue the backlog without routine check-ins.

## C-F. Per item: defect found, decision, change, evidence
Every "red" figure below is the new test on the previous code, run locally by the lead. Every "green" figure is the same test on
the commit.

| Item | What was wrong (from the commit) | Change | Test (green; red) | Related suites |
|---|---|---|---|---|
| LIFE-05 `cbd91f6` | `Life.heir_of` took the eldest adult child before the partner, and `role != "child"` included bandits, so a child with the bandits inherited ahead of the family at home | heirs in the owner's order (adult children, partner, parents, siblings, minor children), skipping bandits; the eldest bandit kin only when nobody at home is left; a returned child inherits normally | life05_bandit_heir 8/0; 3 red | family 51, family_first 104, jus03 9, aging 136: 0 failures |
| BIZ-03 `93327ae` | `Business.daily` (the owner's draw from a venture till) ran before `Employment.daily` (wages), so an owner short of reserve took the till's coins and the employee went unpaid, which ended the job. `Ventures._hire` checked one wage's runway | wages still owed today stay in the till before any draw; hiring checks (current payroll + new wage) × `hire_runway_days`. New helpers `Employment.payroll` and `payroll_due` | biz03_payroll_priority 12/0; 3 red | business_ownership 165, business_founding 77, business_money 37, business 160, business_works 61, till_ownership 71, le04 68, le03_economy 38, le07_gates 32: 0 failures |
| BIZ-04 `3e9b9a1` | `keep_tills_of` settled only storefront tills, so a venture's till stayed behind and escheated to the manor | it also settles every venture the household runs to the household's own funds before it leaves | biz04_venture_till_migration 5/0; 2 red (57 coins left behind) | till_ownership 71, settle_review 112, migration 109, business_ownership 165, business_money 37 |
| TRD-02 `36fa011` | `World.trade` recorded the whole sale price as the seller's earnings, and the stall commission settled later never corrected it | `Stalls.settle` takes the commission off the merchant's recorded earnings | trd02_merchant_net_earnings 6/0; 1 red (40 recorded for 38 net) | stalls 104, settle_review 112, business 160, le02_market 102, till_ownership 71 |
| INV-04 `969a8f4` | a player's container stash stayed keyed to the building after it passed to a new holder, so the goods were counted but nobody could reach them | `World._handed_over` calls `Chests.hand_over_stash`: the stash goes to the new holder's store (overflow to the ground as loot); unchanged under a tenant; the family chest stays the player's | inv04_stash_handover 9/0; 4 red | chests 72, inv03 7, lockpick 19, property 123, multiplayer_c 326 |
| INV-05 `e42a37f` | rubble laid as stone came back as dressed stone when a fitting was removed or a site given up | `Fitting.place` and site deliveries record the rubble used, and refunds return rubble as rubble; the made_stone/used_rubble stats are reversed so the goods ledger balances | inv05_rubble_refund 12/0; 4 red | conservation 8, homestead_presence 19, homestead 49, le05_construction_hire 10, player_homestead 60. The commit says prop01, prop02 and stone_test were "still running"; their own results are not recorded, but the full strict run on `c9da5db` covers them |
| SAV-02 `f67afdb` | `earned_at_dawn`, `laboured_today`, the morning market reading and this hour's caches were not saved; a mid-day load reset them (23 coins of the day's income became 0 in the test) | saved as the optional keys `brain_day` and `hour_caches`; no `save_version` change, and older saves load as before | sav02_day_state 6/0; 4 red | save suites cited only as "see the next commit or the state file"; the strict run on `c9da5db` covers them |
| EMP-03 | owner: count everyone actively seeking work | no change. The lead's finding: "the code already counts every seeker, including those who then took other work" | none written | **PARTIAL:** no test and no code line were recorded for this finding |
| PROP-03 `b727954` | see [B25-AUD-PROP-06](B25-AUD-PROP-06.md) | test only | prop03_eviction_site 5/0; red 4 (commit) or 3 (state file), unresolved | none |

**Alternatives.** None are recorded for these items. Each commit implements the owner's stated rule with the smallest change that
turns its test green. BIZ-03's two options were the owner's (Option B chosen; issue #4 comment 12).

## Merge and verification

| Evidence | Commit | Result |
|---|---|---|
| Strict Tests 42589325057 | `f67afdb` | failed 1 check in `net_fault_test` (a "ghost" peer still listed 15 s after a simulated drop); 54/0 locally on `f67afdb` |
| Local overlap suites (where PROP-06's sale and BIZ-04's till rule meet), 9 suites | `c9da5db` | 0 failures |
| Strict Tests 42607051457, attempt 1 | `c9da5db` | `net_fault_test` and `net_mp4_test` failed 1 check each; see [B25-CI-FLAKE-C9DA5DB](B25-CI-FLAKE-C9DA5DB.md) |
| Strict Tests 42607051457, attempt 2 (full re-run) | `c9da5db` | passed |
| Gate 42607055494 | `c9da5db` | 33 blocking, all baseline-difference kind (19 printed); determinism identical |
| Recorded campaign 42627103286 | `c9da5db` | seed 1: 365/365, 0 CRITICAL, 17 HIGH, 46 MEDIUM, 0 confirmed. Seed 2: 365/365, 0 / 63 / 42, 0 confirmed; no FATAL |

`c9da5db` = `53a56d3` + `f67afdb` (via `199809b`) + `b727954`. Conflicts were only in `tests.yml` and the floors, and both sides'
lines were kept. The lead wrote the merges with git plumbing (`commit-tree`), because the disk was nearly full.

## G. Consequences and next action
- Business payroll now has priority over the owner's withdrawals.
- Migrating households keep their venture money.
- Merchants' recorded income is net.
- Goods left in a building pass to its new holder.
- Rubble is no longer turned into dressed stone.
- A mid-day load continues the day's economy.
- **Outstanding:**
  - EMP-03 needs a test or code citation;
  - the PROP-03 red count needs re-measuring if it matters;
  - none of these changes has an owner playtest.
