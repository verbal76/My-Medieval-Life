# Determinism gate after the identity foundation (ID-01, ID-D2 option B): analysis

> **HISTORICAL** (documentation reconciliation DOC-RECON-01, 2026-10-31). Current status: `docs/expansions/EXPANSION_19.md`. Analysis of code `45d68d3` (2026-10-23). The candidate baseline it describes is not blessed: the owner's 2026-10-28 ruling on ID-D3 requires a same-commit, current-branch conservation, determinism and first-divergence audit before any identity baseline is promoted. Content below is kept unchanged as the historical record.

Authority: `docs/directives/2026-10-23_id_d2_succession_decisions.md` ("Do not blindly replace the determinism baseline. First verify
that remaining divergences are explained by approved permanent-identity behavior. Record the exact first divergence, its cause, and the
new baseline for both test seeds. Investigate any unrelated divergence"). Candidate baseline: `docs/design/IDENTITY_GATE_CANDIDATE.json`
(a copy of the gate's output, code commit 45d68d3; **`docs/release/sim_baseline.json` is untouched and no `--write` was run**; the owner
approves any new baseline). Verdict for both seeds: **explained**; nothing unexplained.

## What was run

- `python3 tools/sim_gate.py` semantics (seeds 1 and 2, 30 days, checkpoints 10 and 30, both seeds in parallel) on this branch:
  day 10 identical to the baseline on both seeds (so the band restored Build 18's village sequence up to there); day 30 differs on
  both (alive, currency, treasury, fingerprint, animals, deposits, item ledger). Currency and item leaks are 0 at every checkpoint.
- Reference: the baseline's own code. `origin/wip/build18` (239bdff, this branch's base) reproduces the baseline exactly (days 10 and
  30, both seeds), so the baseline is still valid for Build 18 and any difference is this branch's.
- Determinism: two independent runs of each seed on this branch (the gate run and a separate `economy_sim.gd --every 1` run) give
  identical day 10 and day 30 summaries.
- First divergence: a read-only hourly trace (analysis script, not committed) of both trees, seeds 1 and 2, days 10 to 14, comparing
  every villager (keyed by name, family and birth, not by id: id, alive, away, coins, position, hunger, job, goods, household,
  partner, doing), the event log, the RNG state, the treasury, the chapel fund and the population, every game hour. A second pass
  ignored the id values themselves (partner links compared as people) to find the first hour a behaviour differs.

## Seed 1

- First difference of any kind: day index 13, hour 4 (game clock "Autumn, Year 2, Day 6, 12:00"). Amice Holt arrives from Netherton to
  marry Roger Holt. Only the id differs: Amice is 122 in Build 18 (a new village id given on arrival) and 1000067 here (the id she has
  had since the world was founded as a member of Netherton); Roger's partner field follows. Nothing else differs.
- First difference in behaviour: day 13, hour 8 (16:00), the weekly service at the chapel. The village gave 305 coins in Build 18 and
  280 here; Amice holds 73 coins in Build 18 and 98 here. The chapel's piety is a fixed number from the world seed and the person's id
  (`Chapel.piety`, `chapel.gd:153`; a person at or above `min_piety` 0.3 gives a share of their spare coins). For seed 1, id 122
  gives piety 0.94 (she gives 25 coins) and id 1000067 gives 0.21 (below 0.3: nothing).
- Cause: a returning/arriving person keeps their permanent id (a settlement resident, band id), where Build 18 issued a fresh village id.
  Verdict: **explained**. Everything after is the consequence of 25 coins staying with a household.

## Seed 2

- First difference of any kind and first behavioural difference coincide: day 13, hour 4 (12:00, same clock). Rose Underwood arrives from
  Wulstead to marry Richard Underwood; she is 127 in Build 18 and 1000017 here. The same noon the caravan visit differs: Build 18
  "From the caravan, Rose Underwood a fine cloth, Simon Brook a spices, Robert Webb a spices (74 coins)"; here "Simon Brook a spices,
  Robert Webb a spices, Cecily Ford a spices (54 coins)".
- A caravan buyer needs a taste of at least `min_taste` 0.4, a fixed number from the world seed and the person's id (`Luxury.taste`,
  `luxury.gd:48`). For seed 2, id 127 gives 0.61 (Rose passes and buys the fine cloth) and id 1000017 gives 0.39 (she does not);
  the next candidate, Cecily Ford, takes the third place and buys spice. Coins and goods differ accordingly (Rose 100 against 138,
  Cecily 82 against 64; the goods are one fine cloth less and one spice more, ledger consistent).
- Cause: the same; Verdict: **explained**.

## Why this is the approved behaviour, and what it means

The owner approved (ID-D2 option B, ID-01 item 1) that a person's id is permanent: an arrival from a settlement keeps the id they
already have (a returning migrant is the same record; a settlement-born or settlement-founded resident keeps their band id). In Build 18
an arrival was a new person with a new village id. Rules that are a fixed function of the person's id therefore give an arrival a
different value: piety (`chapel.gd:153`), caravan taste (`luxury.gd:48`), and also the skill seed (`skills.gd:127`), willingness
(`relations.gd:289`) and sprite choice (`id % 48`). Those are the only id-seeded rules in the code; the two above are the ones that
changed the first behaviour. A village person's id sequence is exactly Build 18's (day 10 identical on both seeds), so no villager
already in the village changes.

## For the owner's decision (not a defect)

An arrival's chapel piety, luxury taste and willingness now come from their permanent band id, so they differ from what Build 18 would
have drawn for the same arrival. This is a consequence of the approved permanent ids. If the owner would rather such traits stay
independent of the id's value, the alternative is to seed them from a stable trait seed stored with the person; that is a design
change and is not done here. Approving the candidate baseline accepts the consequence above.

## Candidate baseline

`docs/design/IDENTITY_GATE_CANDIDATE.json` holds the gate output for seeds 1 and 2 at days 10 and 30 (same format as
`docs/release/sim_baseline.json`, `mml-sim-baseline/1`). Day 10 equals the current baseline; day 30 is new. Copy it over the baseline
only on the owner's approval.
