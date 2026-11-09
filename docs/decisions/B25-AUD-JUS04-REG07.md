# B25-AUD-JUS04-REG07: crime knowledge reaches relatives only through the game (PR #20); market intelligence ages within one game year (PR #21); merged at `53a56d3`

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - PRs #20 and #21, with their bodies and their 2026-11-08 20:33 comments;
> - issue #4 comments 9-11;
> - commits `e26a24f`, `b54fd3a`, `c06e524`, `a9d1538`, `4f1b3c8` and `53a56d3`;
> - Actions runs;
> - the state file.
>
> No `docs/audits/` evidence file exists for these two PRs; the PR comments are their evidence record. Times are UTC.

## A. Identity and timeline
- **IDs:** audit items MML-JUS-04 and MML-REG-07. Proposed register ids B25-AUD-JUS-04 and B25-AUD-REG-07.
- **Timeline:**
  - 2026-11-08 20:21-20:23: the owner's decisions (issue #4 comments 9 and 10).
  - 20:25-20:29: commits; PRs opened at 20:25 and 20:26.
  - 20:27-20:31: focused runs.
  - 2026-11-09 00:33: merged onto `wip/b25-next-batch` (base `f0a854c`).
  - 00:45: `4f1b3c8`.
  - 00:50: strict run 42542326507 and gate 42542329406.
  - 02:42: campaign 42552442930, with `record: false`.
  - 05:58: recorded campaign 42570299554.
  - 10:00: merge commit `53a56d3` onto `96b071c`; strict run 42597744977.
  - 11:04: `wip/b25r2-rev2` fast-forwarded to `53a56d3`.
  - 11:05: PRs #20 and #21 marked merged.

## B. Original situation
- **JUS-04 (audit 010, an owner question):** a witness's relatives and friends took social penalties as soon as the witness saw a
  crime, before any knowledge reached them.
  - Owner: "Criminal reputation consequences may affect relatives only after the relevant crime information has actually reached
    them through the game's knowledge systems". Issue #4 comment 9 also says to "Preserve separate existing approved rules for a
    direct victim's kin".
- **REG-07 (audit 009B):** trade intelligence went stale at 20 days and was forgotten at 40, with envoys refreshing every 30. On
  an 8-day game year, that is several years.
  - Owner: "valid for no longer than one eight-day game year".
  - Owner: "choose and document smaller technical thresholds based on trip durations and measured game behavior, not a second
    owner policy" (comment 10).

## C. Evidence and investigation

| Run | Commit | What | Result |
|---|---|---|---|
| 42520193478 | `e282731` | JUS-04 focused, first | failure |
| 42520219728 | `0489889` | JUS-04 focused | failure: "a test setup mistake (regard clamps at zero), not established proof of a code regression" (issue #4 comment 11) |
| 42520403018 | `fbc0384` | JUS-04 focused, after "seed positive regard" | 6/0 |
| 42520195602, 42520222693 | `55f6c2d`, `8ca63ed` | REG-07 focused | 20/0 |
| 42520216806, 42520214052 | | duplicate push-triggered runs | cancelled |
| 42520518399 | `57373be` (audited code `fe7d8f8` + tests only) | red reproduction of both | JUS-04 6/1 ("distant eyewitness relative does not gain automatic criminal knowledge/penalty"); REG-07 20/5 (old 20/40-day ages, 30-day envoy refresh, aged offers still actionable, old word accepted, old book record kept) |

On the integration branch, the lead repeated red and green by swapping in `f0a854c`'s `world.gd`, `envoys.gd`, `intel.gd` and
`settlements.json` (`4f1b3c8` message):
- `jus04_witness_knowledge_test`: 6/1 red, 6/0 green;
- `intel_test`: 20/5 red, 20/0 green.

## D. Communication and coordination
- The owner's decisions were posted to issue #4 by ChatGPT. The ChatGPT conversation itself is not available.
- ChatGPT wrote both PRs and ran the focused and red runs.
- The lead integrated them:
  - dropped the temporary workflows `audit-jus04-focused.yml` and `audit-reg07-focused.yml`;
  - added the floors: `jus04_witness_knowledge_test` 6 (new); `intel_test` 13 → 20, since PR #21 added 7 checks.
- The owner's "continuous engineering" directive of 2026-11-08 15:37 EST (recovered) set this batch as next after the twelve.
- The owner's overnight directive of 2026-11-09 set the merge order: LIFE-03/04, then PROP-06, then JUS-04/REG-07.

## E. Decision and rationale
- **JUS-04:** the two witness-only `World.relations.harmed(...)` calls pass `spread=false` (PR #20). Eyewitnesses still react,
  and the direct-victim kin rule is unchanged.
  - Smallest change. No alternative is recorded.
- **REG-07:**
  - offers are actionable to day 4 and forgotten after day 8 (one game year);
  - envoys re-survey every 4 days;
  - the reeve's book prunes expired offers when it is read (PR #21; `settlements.json`, `intel.gd`, `envoys.gd`).
  - The 4/8/4 values are ChatGPT's engineering choice inside the owner's 8-day maximum. The measured trip durations the owner
    asked to base them on are not recorded (PARTIAL).
- **Approval:** owner policy for both. The thresholds are an engineering choice.

## F. Implementation and verification

| Evidence | Commit | Result |
|---|---|---|
| Strict Tests 42542326507 | `4f1b3c8` | 11 of 12 shards passed. Shard 9 (`demo_test`) crashed natively once (double free; every check before it ok) and passed on re-run. The run's conclusion reads "failure" because the report job reads only the re-run artifacts (KNOWN_ISSUES KI-09 and KI-10) |
| Gate 42542329406 | `4f1b3c8` | 32 blocking, all baseline-difference kind (the 20 printed); REG-07 changes simulated trade, so differences were expected |
| Campaign 42552442930 (`record: false`, input error) | `4f1b3c8` | not comparable |
| Recorded campaign 42570299554 | `4f1b3c8` | seed 1: 365/365, 0 CRITICAL, 48 HIGH, 65 MEDIUM, 0 confirmed. Seed 2: 365/365, 0 / 94 / 36, 0 confirmed; archive ok |
| Strict Tests 42597744977 | `53a56d3` (merge onto `96b071c`) | passed |

## G. Consequences and next action
- **JUS-04:** relatives learn of crimes only through gossip, witnessing or being told.
- **REG-07:** settlement traders act on fresher market intelligence. That changes simulated trade, which is visible in the gate's
  differences from `df67e8e`.
- **Remaining:**
  - REG-04 and REG-05 (physical couriers and migration) are separate, approved and not implemented;
  - the cause of the `demo_test` native crash was not investigated.
