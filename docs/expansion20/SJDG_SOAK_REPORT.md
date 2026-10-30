# SJD-G: judgment soak and calibration report (Gate G)

Register SJD-G (worker D, branch `wip/x20-sjdg`, base `de8d225` = Build 24 `4611d86` plus the CI fixes and multiplayer Batch D;
the judgment code and `world.gd` are byte for byte Build 24's). Authority: owner directive
`docs/directives/2026-10-30_master_development_resumption.md` s.3, 5, 10; judgment spec
`docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt` s.5.2, 15.1, 16, 22-24; owner answers SJD-Q01..Q14,
X19-DECAY, X19-ASSAULT. Gate H (owner review) is not part of this work: section 7 is its input.
Developer reference only: nothing player-facing changed, so no wiki page changes (WIKI-01).

Rules kept: judgment, aspirations off, job choice off and the economy model off exactly as shipped (no switch enabled); no
number retuned, no decay, cap or weight added or changed (owner 2026-10-30, reaffirmed); WDR-022: a village failing is an
outcome, measured, never a defect by itself.

## 1. What was run

| Run | Where | Commit | Configuration | Seeds | Days | Result |
|---|---|---|---|---|---|---|
| ON (shipped) | Actions 41129188776 | `d0f623b` | shipped switches (judgment on) | 1, 2 | 365, checkpoints every 10 | PENDING |
| OFF | Actions 41129193143 | `d0f623b` (pushed as `wip/x20-sjdg-off`) | `--no-judgment` | 1, 2 | 365, checkpoints every 10 | PENDING |
| Measure neutrality | local | `d0f623b` vs `de8d225` | shipped, 3 days, every day | 1 | 3 | fingerprints at 0-3 identical, judgment state hash identical (897634669) |
| Shortcut exactness | local | `32da11d` vs `de8d225` | shipped, 12 days, every 4 | 2 | 12 | fingerprints at 0, 4, 8, 12 identical; judgment state hash identical (3486771965); 263 s against 292 s |
| Recorder (loops, refusals) | local | `32da11d` | shipped, `--record` | 1 | 8 | archive valid, 0 problems (`tools/recorder_archive.py`) |
| Re-post instrumentation | local, not committed | `32da11d` + counters | shipped | 1 | 10 | section 4.4 |

Budget (lead, 2026-10-30): at most two 365-day configurations, seeds 1 and 2, one dispatch each; 100-day values read from
the 365-day checkpoints (SIM-01). Two branches carry the same commit only so the two dispatches run side by side (the
workflow allows one run per branch at a time); nothing else was dispatched. The 30-day G0 on the integration branch is the
lead's existing evidence; this branch's code change is proved world-identical by the 12-day comparison and the tests.

Measurement (`game/scripts/core/judgment/judgment_soak.gd`, `JudgmentSoak.metrics`): a `JUDGE {...}` line at each checkpoint,
read only (no gossip told, no dawn applied; ledgers decayed on local copies with the store's own integer steps; proved
neutral above and in `judgment_soak_test`), and a `JUDGE_SAVE` line at the end (judgment section and world save bytes,
static memory). `long-sims.yml` keeps those lines, the `growth:` line (courtships, partnerships, households) and, for a
recorded run, the recorder's abnormal-run totals and choice profiles in the job log (artifact downloads are blocked here).

## 2. Results (100 and 365 days)

PENDING

## 3. Findings, classified

PENDING

## 4. Investigations

### 4.1 Performance: the judgment shortcut never applied under the shipped selection (DEFECT, fixed)

`JudgmentLive._first_stands` lets the live rule's first pick stand without scanning every other candidate when no other can
win. It was written for `argmax`; the shipped selection is `margin` (SJD-Q09, seeded near-best), so it never applied and every
villager sale (`trade_sell`, about 600 a day) priced every possible buyer. Local measure, seed 1, 3 days: judgment ON 76 s,
OFF 48 s; the trade choice alone 55 s of the 76.

Fix (`32da11d`): under `margin` the first stands when no other candidate can come within the margin of it
(`step - gain > margin`: the near-best draw then has nobody to draw, `JudgmentWeighting._choose`). Exact by construction and by
test: `judgment_live_test` (12 opinion mixes) and `judgment_soak_test` (40 mixes with saturated opinions and family colour,
26 shortcuts) pick exactly as the full scan; 12 simulated days of seed 2 give identical fingerprints and the same judgment
state hash as Build 24's code, 10% faster (263 s against 292 s); 3 days of seed 1, 58 s against 76 s. Two latent exactness
points closed in the same change: the first's disposition is computed as the choice computes it (personal disposition
clamped, then the family colour, clamped again; the old single clamp overstated it when a NET beyond +-50 points met a
colour), and the aspiration layer (extra factors, scaled weights) and recorded runs (whose archive keeps every weighed
choice) always take the full scan. What remains of the trade-choice time is the live rule's own buyer search, which judgment
OFF pays too.

The ON 365-day run was dispatched before this fix (`d0f623b`), so its runtime is the pre-fix cost.

### 4.2 Save migration (no defect)

`game/tests/judgment_soak_test.gd` (51 checks, 0 failures): every committed fixture with a judgment section loads with every
fact, memory, contribution, ledger value and trust value as saved and nothing kept unread: Build 19 (save 20), Build 20 and
Build 21 guest (save 21), Build 21 couple (save 22), Build 22 (save 23, section v2) and a new Build 24 fixture
(`tests/fixtures/b24_save_v23_judgment.json`, section v3: 84 facts, 1312 memories (227 permanent), 356 contributions, 205
ledger entries (149 with a permanent part), 32 trust values; written by `gen_b24_judgment_fixture.gd` at `de8d225`, whose
judgment and world code are Build 24's). Builds 23 and 24 write the same save version (23) and section version (3). The
Build 24 section re-saves byte for byte after a second load. Carried 16 and 365 days ahead: lifetime GOOD/BAD and the
contribution count never change, permanent parts never fade, fading parts follow the approved integer steps exactly, nothing
goes below 0, all permanent memories stay.

### 4.3 Determinism

PENDING (Actions) plus the local evidence in section 1: two runs of the same seed and commit give identical fingerprints and
judgment state hashes (3 days seed 1 twice; 12 days seed 2 on two commits proved world-identical).

### 4.4 Decay and re-evaluated contributions (calibration note, no change)

X19-DECAY decays each observer's fading ledger part daily (the sum of each deed's contribution decayed from when it was
posted). When a belief is later re-evaluated (a more confident telling, a correction, a refuted lie), the store replaces the
contribution with the undecayed difference (new - old), not the difference of the decayed values. Measured over 10 days of
seed 1 (temporary counters, not committed): 1180 re-posts, mean deed age 4.2 days, mean change 0.033 points, no ledger
clamped at 0 by a retraction. The difference from exact per-deed decay is therefore about a fifth of 0.03 points per re-post:
immaterial to any choice. Recorded, not changed (a change would alter G0 and the save's contribution rows for no observable
effect).

## 5. Spec s.15.1 checklist

PENDING

## 6. Performance, memory and save size

PENDING

## 7. Calibration package for SJD-H (owner decisions)

PENDING

## 8. Tests and commits

| Commit | What |
|---|---|
| `d0f623b` | `JudgmentSoak.metrics`, `JUDGE`/`JUDGE_SAVE` lines in `economy_sim.gd`, `long-sims.yml` keeps them in the log |
| `32da11d` | `_first_stands` under margin (exact), `judgment_soak_test.gd`, Build 24 fixture and its generator |

Local suites on `32da11d` (Godot 4.7.2 headless): judgment_soak_test 51/0, judgment_live_test 161/0, judgment_test 217/0,
judgment_x19_test 117/0, judgment_bonds_test 98/0, judgment_personality_test 91/0, aspiration_test 155/0.
