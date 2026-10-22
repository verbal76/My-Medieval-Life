# Current session recovery handoff (updated 2026-10-22, about 02:00 UTC)

Continuity checkpoint for the lead agent after a context compaction. Authoritative records: the register
(`docs/requirements/requirements.json`), `docs/DECISIONS.md`, `docs/directives/`, `docs/CURRENT_DEVELOPMENT_STATE.md` and
CLAUDE.md (rules MSW-01, SIM-01, SIM-02, WIKI-01 in sections 3 and 5). **V** = verified by the lead; **W** = worker-reported.

## Branches (V, remote heads)

| Branch | Head | State |
|---|---|---|
| `staging/my-medieval-life` (local `wip/b16-integration`, main worktree; push both) | `aec7c6a` | Build 16 code + all records; Expansion 18/19/20/21 register entries |
| `wip/build17` (worktree `scratchpad/b17wt`) | `dfec7ec` | **Build 17, FROZEN.** Released as a private playtest draft (release run 39706003658, commit `80e6b99`, packet `docs/release/BUILD_17_PACKET.md`); no gameplay change allowed |
| `wip/farm-cropshare` (worktree `scratchpad/cropwt`) | `132960a` | FARM-CROP-01 (owner FARM-08-Q-CROP option B) implemented and tested; NOT merged; merge decision carried until after Build 17 (owner) |
| `wip/expansion18-preparation` (worker `a5803847a53d8a4ff`) | `da4d610` (+ snapshot `wip/expansion18-snapshot` `d6b9254`) | Primary development; worker implementing D1 |
| `wip/expansion19-preparation` (worker `a6cffdef98c095994`) | `05adc9d` (+ snapshot `wip/expansion19-snapshot` `239aa50`) | Worker on the gossip-timing proposal, worst-frame and memory investigation |
| `wip/expansion20-preparation` (worktree `scratchpad/x20wt`) | `d82f173` | LE-00 audit done; hold (no implementation without authorization) |
| `wip/expansion21-preparation` (worktree `scratchpad/x21wt`; worker `a4ecc05968f664a95`, idle) | `0eeb3df` | Preliminary plan done; planning only |
| `wip/juice-assessment` (worktree `scratchpad/juicewt`; worker `a4ecc05968f664a95`) | from `dfec7ec` | JUICE-00 Game Juice read-only assessment in progress (owner 2026-10-22); report top ten, nothing implemented |
| `wip/multiplayer` | unchanged | never merged into staging without explicit approval |

Snapshot branches are preservation copies only, never merged.

## Workers (SendMessage ids)

- **Expansion 18** `a5803847a53d8a4ff`: implementing owner D1 (starting experience = cap × recorded skill ÷ 10, once,
  new worlds and saves without records, never overwrite, farming from PAR-01A history, deterministic, hook OFF); then
  report and finalise **D2 (facility limitations)** for the owner. Pending list D1-D9 in `docs/expansion18/DECISIONS_PENDING.md`
  on its branch.
- **Expansion 19** `a6cffdef98c095994`: written X19-Q-TIMING proposal (not implemented), byte-identical worst-frame
  reduction investigation, heavy-rate memory breakdown (17.4 MB vs 16 MB).
- **Planning worker** `a4ecc05968f664a95`: running JUICE-00 (Game Juice assessment, read-only) on `wip/juice-assessment`.

## Decisions taken this session (all recorded; do not reopen)

STONE-Q1..Q3 (stone: materials by work; skill-based dressing STONE-04; Stoneworking skill STONE-05 and iron chisel STONE-06;
X18-STONECUT; all Expansion 18); B7-006 closed (working as designed); FARM-08 diagnostic and FARM-08-Q-CROP (option B,
proportional crop sharing, FARM-CROP-01 on its branch); SIM-01 (one longest run per seed, checkpoints), SIM-02 (never
restart active runs, check-ins from measured runtimes), MSW-01 (Minimum Sufficient Work); SYNC-17 (one-way Build 17 ->
18/19 at `cd7439c`, done); Q18-11B (people's experience capped by facilities; clarified: per-worker modifiers, the industry
average is reporting only); Q18-11A (bounded profile, farming F1: +10% work rate, +4% pay at L10); X18-CAPCOMP part 1
(experience by hours, caps 12/18/24, straight-line level, one-season average); X18-D1 (starting experience); Build 17
personal playtest release; Expansions 18/19/20 directive; Expansion 21 preliminary authorization (Village Politics).

## Open owner decisions (present one at a time; never answer for the owner)

- Expansion 18: **D2 facility limitations (next)**, D3 thresholds, D4 unattributed activities' industries, D5 level
  rounding, D6 wages fixed at posting, D7 crop shares by base-equivalent work (FARM-CROP-01 interaction), D8 whole-coin
  fractions, D9 drop timing; also Q18-1..8, Q18-14..16, stoneworking values, mining 0-10 mapping, CAP-TOOLHOLDER (review only).
- Expansion 19: X19-Q-TIMING (proposal coming), the four mechanics conflicts, Q03/04/05/09/12/13, decay rate.
- Expansion 20: OD-LE-02..15 (first stage needs 02, 10, 07, 13, 15).
- Expansion 21: decisions 1-9 in `docs/expansion21/PRELIMINARY_PLAN.md` (1: interim voter model vs waiting for 19; 2:
  political structure; 3: office powers vs manor, joint with OD-LE-06).
- FARM-08: yield and switches, balance options; merge timing of `wip/farm-cropshare`; whether the seed kept back is shared.
- Build 17 test tooling: B17F-SIMREPORT (economy_sim counts open pits as sites; checkpoint lines not in job logs) deferred.

## Evidence (V)

Build 17 `cd7439c`: CI 39689213264 success; determinism gate two identical runs; 365-day runs 39692107077 seeds 1-4 all
passed (no leaks/errors/FATAL; `docs/build17/MIN_G_LONG_RUNS.md`); release run 39706003658 success. Deferred findings
B17F-FOOD/JOBS/HENS (20+), B17F-DEPLETE/SIMREPORT (18), B17F-PERF (19) in the register.

## Next steps

1. When the Expansion 18 worker reports: record D1 (X18-CAPCOMP), present **D2** with options and a recommendation.
2. When the Expansion 19 worker reports: record, present X19-Q-TIMING and any memory/worst-frame decisions.
3. Expansions 20 and 21: hold at planning until the owner authorizes more.
4. Build 17: frozen; nothing to do unless the owner reports a playtest defect.
