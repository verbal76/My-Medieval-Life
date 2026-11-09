# B25-VALIDATION-2026-11: how Build 25 changes were validated 2026-11-06..09 (365-day campaigns, the simulation gate, and why the baseline `df67e8e` was not replaced)

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - the register (TEST-AUDIT-Q2, B25R2-DRAFT-01);
> - `docs/release/SIM_BASELINE_DIFFERENCES_B25R2.md`;
> - the owner's directives of 2026-11-06 and 2026-11-08 (saved or recovered);
> - the gate logs of 42524440558 and 42528190244, read in this recovery;
> - the state file;
> - commit messages.
>
> Times are UTC.

## A. Identity
- **Register:** TEST-AUDIT-Q2 (PROVISIONAL), B25R2-DRAFT-01 (PROVISIONAL), SIM-01, SIM-02, FLIGHT-REC-01, TEST-GOV-01.
- **Who validated:** the lead, using GitHub Actions `long-sims.yml` (flight campaign; `gate: true` for the simulation gate) and
  `tests.yml` (the strict suite, 12 shards).

## B. Original rule
- **Accepted baseline.** `docs/release/sim_baseline.json` was recorded from `df67e8e` (2026-11-03) on the B25R1 line.
- **Generation 8 candidate.** The B25R2 work (generation 8 roads and bridges, the band household `bf20dc9`) changed the simulated
  village. The lead prepared a candidate, `docs/release/sim_baseline_candidate_gen8.json`, from gate 42297641550 on `1f2ff4f`.
  Every difference is attributed, leaks are 0 and determinism is identical.
- **The owner's ruling on TEST-AUDIT-Q2 (2026-11-06; register `owner_answer`):** "Conditional approval only. Do not immediately
  record or accept a new generation 8 baseline ... then prepare the candidate with its commit and comparison report and stop for
  explicit final owner approval."
- **The 2026-11-08 directives (recovered):** "Do not re-record baselines to manufacture passing tests"; "This is not
  authorization to automatically replace the accepted baseline"; "If a baseline change is justified, prepare the supporting
  evidence and request owner authorization".

## C. What the gate showed and how it was read
Every gate run on the development line from `0d252b4` on failed with 32 or 33 blocking findings:

| Gate run | Commit | Blocking findings |
|---|---|---|
| 42509523836 | `0d252b4` | 32 |
| 42517547863 | `46d934c` | count not read in this recovery |
| 42524440558 | `6e02171` | 33 |
| 42528190244 | `2a37653` | 33 |
| 42530880459 | `494af9a` | 33 |
| 42535257321 | `a7071aa` | 33 |
| 42542329406 | `4f1b3c8` | 32 |
| 42607055494 | `c9da5db` | 33 |

The lead's classification, in the state file and commit messages: every printed finding is of the "difference from the old
accepted baseline" kind, and the determinism checks are identical ("the recorder changes nothing and the run is reproducible", log
line confirmed in this recovery for 42524440558 and 42528190244).

On 32 versus 33: the extra finding is one more day-10/30 equilibrium value, from the LIFE-03/04 village. On `0d252b4`, eq_s1 and
eq_s2 at days 10 and 30 were identical to the generation 8 candidate in every value.

**Limit.** The gate log prints only 19 or 20 of the 32-33 findings. The rest are assumed to be the same kind; they were not
individually read.

## D. Decision
- **Do not replace or re-record the baseline.** This is the owner's decision (TEST-AUDIT-Q2: explicit final approval required)
  and the owner's 2026-11-08 directive. Gate red of the baseline-difference kind is the expected state until the owner decides.
- **Merge rule (the lead's, under the 2026-11-08 directives):** merge into the development line only when all of these hold:
  - strict tests are green on the exact commit, or on the merge commit itself;
  - the gate shows only baseline-difference findings, with identical determinism;
  - a recorded 365-day campaign (flight recorder on, `record: true`) is clean: 365/365 on both seeds, 0 CRITICAL, 0 confirmed
    defects, no FATAL.
- **Evidence reuse:** allowed only with a stated reason. The `0d252b4` campaign was reused for `f0a854c` because `brush_off` is
  player-only.

## E. Campaign results (all 365 days, seeds 1 and 2)

| Run | Commit | Recorded | Seed 1 (CRIT / HIGH / MED, confirmed) | Seed 2 | Note |
|---|---|---|---|---|---|
| 42274347279 | `832f711` | yes | 0 / 20 / 78, 0 | 1 CRITICAL confirmed (homestead-water save defect) / 108 / 45 | defect fixed in `c903ce8` (B25R2 checklist) |
| 42297637074 | `1f2ff4f` | yes | 0 / 48 / -, 0 | 0 / 99, 0 | candidate reference |
| 42515726815 | `0d252b4` | yes | 0 / 48 / 65, 0 | 0 / 99 / 45, 0 | Batch A |
| 42536147616 | `494af9a` | **no** (input error) | 365/365, no findings recorded | same | not comparable |
| 42540721533 | `a7071aa` | **no** | 365/365 | 365/365 | not comparable |
| 42552442930 | `4f1b3c8` | **no** | | | not comparable |
| 42557922632 | `494af9a` | yes | 0 / 17 / 46, 0 | 0 / 91 / 35, 0 | LIFE-03/04 |
| 42557925404 | `a7071aa` | yes | 0 / 17, 0 | 0 / 91, 0 | PROP-06 |
| 42570299554 | `4f1b3c8` | yes | 0 / 48 / 65, 0 | 0 / 94 / 36, 0 | JUS-04 and REG-07 |
| 42627103286 | `c9da5db` | yes | 0 / 17 / 46, 0 | 0 / 63 / 42, 0 | backlog; no FATAL |
| 42664730920 | `242ca83` | yes | running | running | MP-05 |

**The `record: false` mistake.** On 2026-11-09 (03:43), the lead found that it had dispatched three campaigns without the
recorder. Those runs show only that the world survived 365 days without leaks. They were re-dispatched with `record: true`
(KNOWN_ISSUES KI-11).

**Unexplained.** HIGH findings changed between branches (seed 1: 20 → 48 → 17; seed 2: 99 → 91 / 94 → 63). No CRITICAL finding and
no confirmed defect appeared in any of these runs. Nobody has analysed why the HIGH counts moved (KNOWN_ISSUES KI-06).

## F. Consequences and when to reconsider
- The development line runs red on the gate by design until the owner accepts a baseline. A reader must not treat that red as a
  regression without reading the findings' kind.
- **Reconsider when:**
  - the owner decides TEST-AUDIT-Q2. The candidate is from `1f2ff4f`, and later merges changed eq values, so a new candidate would
    likely be needed (the state file says so);
  - a gate shows a finding of another kind (determinism or conservation).
- B25R2-DRAFT-01 (private draft of Play Test Build One) still waits on this baseline decision and the other conditions in its
  `owner_answer`.
