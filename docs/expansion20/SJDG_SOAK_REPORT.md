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
| ON (shipped) | Actions 41129188776 (jobs 124315489019 seed 1, 124315488869 seed 2) | `d0f623b` | shipped switches (judgment on) | 1, 2 | 365 of 365 reached, 37 checkpoints each | success; 11043 s and 15526 s |
| OFF | Actions 41129193143 (jobs 124315505716 seed 1, 124315505867 seed 2) | `d0f623b` (pushed as `wip/x20-sjdg-off`) | `--no-judgment` | 1, 2 | 365 of 365 reached, 37 checkpoints each | success; 12551 s and 12348 s |
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

Read from the 365-day runs' checkpoints (SIM-01). Every run: exit 0, 0 script errors, currency leak 0 and item leaks none at all
37 checkpoints, no FATAL line.

| | ON s1 | OFF s1 | ON s2 | OFF s2 |
|---|---|---|---|---|
| Day 100: alive / households / food days | 149 / 26 / 15.3 | 143 / 26 / 15.4 | 140 / 25 / 18.9 | 154 / 26 / 18.4 |
| Day 100: courtships / partnerships / households founded | 14 / 15 / 1 | 14 / 14 / 1 | 6 / 10 / 0 | 7 / 13 / 1 |
| Day 100: unemployed adults; household cash min/median/max | 25; 1/107/228 | 31; 1/110/287 | 14; 1/139/291 | 18; 0/85/314 |
| Peak alive (day) | 507 (310) | 557 (310) | 512 (365) | 449 (365) |
| Day 365: alive / households / food days | 312 / 47 / 0.8 | 288 / 52 / 0.7 | 512 / 31 / 3.6 | 449 / 28 / 6.8 |
| Deaths: old age / starvation; first starvation day | 114 / 81; 329 | 99 / 164; 320 | 111 / 0; none | 114 / 0; none |
| Births; households split; houses built | 833; 14; 7 | 660; 14; 6 | 679; 6; 6 | 518; 3; 1 |
| Day 365: courtships / partnerships / households founded | 167 / 110 / 14 | 145 / 82 / 14 | 147 / 89 / 6 | 112 / 76 / 3 |
| Meals missed: no food for sale / no money | 71939 / 4587 | 129217 / 5136 | 57 / 7 | 12 / 15 |
| Bandits killed | 234 | 6 | 143 | 7 |
| Runtime (s) | 11043 | 12551 | 15526 | 12348 |
| World save at the end (bytes); judgment section | 20201337; 4428882 | 13181025; 0 | 15438378; 5752694 | 9317436; 0 |
| Static memory at the end / peak (MB) | 724 / 734 | 580 / 590 | 559 / 569 | 365 / 375 |
| Final fingerprint; judgment state hash | c2c7a859...; 515069640 | bf43dbb9... | 13663e05...; 3159741524 | ecb6e7bd... |

Judgment ON, the store (JUDGE lines; NET in points, milli-points / 1000):

| | s1 day 100 | s1 day 365 | s2 day 100 | s2 day 365 |
|---|---|---|---|---|
| Facts live; memories (permanent); contributions; ledger entries | 77; 4483 (2529); 3024; 2177 | 632; 33115 (25211); 27410; 34652 | 124; 6811 (4822); 5526; 2019 | 739; 53207 (43422); 45832; 25766 |
| Effective NET p1 / p5 / p50 / p95 / p99 | -2.2 / -1.3 / -0.05 / +0.02 / +0.05 | -2.1 / -0.7 / 0 / 0 / +0.2 | -4.6 / -2.7 / -0.09 / 0 / +0.1 | -3.2 / -1.4 / -0.07 / 0 / 0 |
| NET min / max | -24.6 / +0.6 | -23.7 / +4.8 | -11.2 / +1.2 | -13.4 / +3.7 |
| Entries at 10+ / 25+ / 50+ points; dispositions at the 0 or 100 bound | 2 / 0 / 0; 0 | 4 / 0 / 0; 0 | 2 / 0 / 0; 0 | 4 / 0 / 0; 0 |
| Lifetime GOOD max / BAD max (never decayed) | 9.5 / 33.8 | 19.6 / 35.1 | 10.0 / 15.6 | 10.0 / 18.6 |
| Entries with a permanent part; its largest | 599; 22.7 | 5715; 23.7 | 629; 10.6 | 14281; 11.3 |
| Most contributions behind one entry | 31 | 68 | 42 | 90 |
| Subjects' mean NET, lowest / highest; subjects at -10 or below | -1.8 / +0.04; 0 | -2.2 / +0.3; 0 | -2.9 / +0.04; 0 | -2.8 / +0.06; 0 |
| Identical live facts (by type) | assault 17 | assault 26, theft 64 | assault 9, trade_cheat 1 | assault 31, theft 48 |
| Events published; thefts; assaults; killings | 452; 55; 33; 0 | 4248; 1054; 60; 0 | 441; 93; 53; 0 | 3629; 804; 133; 0 |
| trade_sell choices / changed by judgment | 58846 / 152 | 107113 / 311 (0.29%) | 57730 / 185 | 114380 / 275 (0.24%) |
| trade_buy_from choices / changed | 1968 / 56 | 8901 / 205 (2.3%) | 1860 / 35 | 5534 / 113 (2.0%) |
| Refusals: contract, credit, barter, work (declined of asked) | 0/35, 0/0, 0/4, 0/0 | 0/148, 0/4, 0/6, 0/10398 | 0/15, 0/0, 0/0, 0/0 | 0/87, 0/5, 0/6, 0/61 |
| Friendships held back by judgment | 12 of 332 | 142 of 5983 (2.4%) | 16 of 286 | 83 of 3672 (2.3%) |
| Repeats ignored (dup_ignored); beliefs upgraded | 342; 21864 | 4586; 249375 | 220; 23474 | 4763; 243106 |
| Lies; corrected; refuted | 29; 601; 120 | 150; 1761; 207 | 61; 814; 130 | 245; 1918; 235 |
| Measure's own cost at the checkpoint (ms) | 20 | 360 | 22 | 355 |

## 3. Findings, classified

| # | Finding | Class | Evidence | Action |
|---|---|---|---|---|
| F1 | The judgment shortcut never applied under the shipped `margin` selection: every sale priced every possible buyer | DEFECT (performance) | trade choice 4386 s of 11043 s (s1) and 4869 s of 15526 s (s2); local 76 s ON vs 48 s OFF | fixed `32da11d`, exact (4.1) |
| F2 | The shortcut's first-pick disposition used one clamp where the choice uses two (personal, then colour) | DEFECT (latent: argmax only, never shipped) | code reading; covered by the new 40-mix test | fixed `32da11d` |
| F3 | Seed 1 boom and bust: population to 507 (ON) / 557 (OFF) by day 310, food to 0.3 days, then starvation (ON 81, OFF 164) of elders and children | LEGITIMATE EMERGENT (WDR-022) | happens with judgment OFF as well, worse there; 0 leak; meals missed for want of food for sale, not money | none; reported |
| F4 | Bandits killed 234 / 143 ON against 6 / 7 OFF | LEGITIMATE (owner-approved FAMILY-01 danger behaviour) with an open CALIBRATION question | family_danger fight 9524 / shield 398 (s1), fight 1452 / shield 20755 (s2) | C4 |
| F5 | No runaway score inflation: effective NET stays within a few points; at most 4 of 25-35 thousand entries reach 10 points; no disposition at a bound; distribution as narrow at 365 days as at 100 | NO DEFECT; CALIBRATION (influence small) | section 2 | C1 |
| F6 | No duplicate moral postings: a person judges an event once (knowers, dup_ignored 4586 / 4763), corrections replace, never add. Identical live facts are real repeated deeds: a bandit re-robbing the same victim every 2 game minutes until nothing is left (recorder trace, seed 1 day 3: six thefts 1389-1399, the last taking nothing), and repeated blows each publishing an assault | NO DEFECT in judgment; CALIBRATION (episode counting) | recorder archive of the local 8-day run; JUDGE twins | C3; the bandit re-robbing loop is world behaviour (npc_brain), reported to the lead |
| F7 | Permanent memories dominate growth: 25211 of 33115 (s1) and 43422 of 53207 (s2) memories are permanent (assault and killing hearsay, owner rule "like murder"); ordinary memory stays bounded | BY DESIGN; CALIBRATION (save growth) | JUDGE n.memories_permanent; judgment section 4.4 MB / 5.8 MB | C2 |
| F8 | Judgment never refused a contract, credit, barter or job offer in 730 village-days; it moved 0.24-0.29% of sales and 2.0-2.3% of timber buys and held back 2.3-2.4% of friendships | NO DEFECT ("influence, not dictate"); CALIBRATION | section 2 | C1 |
| F9 | No infinite action loops: recorded 8 days, archive valid, 70 empty decisions in all, at most 5 by one person in a day; trade_sell never forgoes | NO DEFECT | `tools/recorder_archive.py`; choice profiles | none |
| F10 | Courtship pacing: no regression (day 100 equal or within one; day 365 more partnerships ON: 110 vs 82, 89 vs 76, with larger populations) | NO DEFECT | growth lines | none |
| F11 | Spontaneous family formation from high NET: impossible by construction and not seen. court_choice only weighs the live rule's candidates (courting allowed, attraction at least interest_at); befriend can only hold a friendship back; proposals are weighed only with aspirations on (0 weighed); households founded equal at day 100 | NO DEFECT | code (JudgmentLive.pick_court, befriend_ok, Relations._befriend_if_close); growth lines | none |
| F12 | In seed 2 no lie was refuted or corrected after day 200 while 98 more were told (seed 1: 18 more refutations) | LEGITIMATE (a lie is refuted only when a guard or kin of the accused hears it; X19-MISINFO) | JUDGE stats | none; noted |
| F13 | Re-evaluated contributions are replaced by undecayed differences | CALIBRATION NOTE, immaterial | 4.4 | none |
| F14 | SJD-Q04 ambivalence ("wary but willing") has weight 0 in every profile, and `JudgmentStore.ambivalence` reads lifetime (never decayed) totals | CALIBRATION (approved answer not yet in behaviour) | judgment.json; code | C5 |
| F15 | judgment.json's top note still says the X19-DECAY rate is "untouched until the calendar is explained", while the decay section records the owner's approval (42 permille, 16-day half-life) | DOCUMENTATION (stale note) | judgment.json | lead (data file housekeeping) |

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

No second year-long run of a seed was dispatched (budget). Evidence: two local runs of seed 1 (3 days, every day) give identical
fingerprints at every checkpoint and the same judgment state hash (897634669), as do 12 days of seed 2 on Build 24's code and on
`32da11d` (3486771965); the integration branch's 30-day G0 (lead's evidence) is identical to `docs/release/sim_baseline.json`.
The Actions runs record each seed's final fingerprint and judgment state hash (section 2) for any later comparison.

### 4.4 Decay and re-evaluated contributions (calibration note, no change)

X19-DECAY decays each observer's fading ledger part daily (the sum of each deed's contribution decayed from when it was
posted). When a belief is later re-evaluated (a more confident telling, a correction, a refuted lie), the store replaces the
contribution with the undecayed difference (new - old), not the difference of the decayed values. Measured over 10 days of
seed 1 (temporary counters, not committed): 1180 re-posts, mean deed age 4.2 days, mean change 0.033 points, no ledger
clamped at 0 by a retraction. The difference from exact per-deed decay is therefore about a fifth of 0.03 points per re-post:
immaterial to any choice. Recorded, not changed (a change would alter G0 and the save's contribution rows for no observable
effect).

## 5. Spec s.15.1 checklist

| Check | Result |
|---|---|
| Conservation of money and resources | leak 0, item leaks none, at all 148 checkpoints of the four runs |
| No impossible purchases | the trade choices weigh only the live rule's feasible candidates (no forgo in trade_sell/buy_from); conservation holds |
| No duplicate moral postings | none (F6) |
| No runaway score inflation | none (F5) |
| No infinite action loops | none (F9) |
| No courtship pacing regression | none (F10) |
| No spontaneous family formation from high NET alone | none (F11) |
| Save/load, replay, determinism | 4.2, 4.3 |
| Stress, soak | two 365-day seeds each way, 312-557 people |

## 6. Performance, memory and save size

- Runtime is dominated by population (peak 449-557): ON 11043 s / 15526 s, OFF 12551 s / 12348 s; the pairs are not matched
  worlds (the seeds diverge from day 0), so the whole-run difference is not judgment's cost alone.
- Judgment's own time, ON (microseconds kept by the store): the trade choice 4386 s (s1) and 4869 s (s2), of which part is the
  live rule's own buyer search (paid OFF too); gossip (meetings due and told) 281 s and 357 s, the dawn update 1.5 s and
  1.6 s for the year. F1's fix removes the redundant scan: locally 3 days of seed 1 58 s against 76 s, 12 days of seed 2 263 s
  against 292 s.
- Memory: static memory at the end ON 724 MB / 559 MB, OFF 580 MB / 365 MB (different populations: 312/288, 512/449).
- Save: the judgment section 4.43 MB (s1, 312 alive) and 5.75 MB (s2, 512 alive) at day 365, 22% and 37% of the world save
  (20.2 MB / 15.4 MB; OFF 13.2 MB / 9.3 MB). Its growth is the permanent records (F7); ordinary memories are bounded by
  memory.capacity, facts by the 30-day horizon except permanent ones, ledgers by pairs of people who judged each other.
- The soak measure itself: 0.02-0.36 s a checkpoint.

## 7. Calibration package for SJD-H (owner decisions)

Nothing below was changed: each is an owner decision (no number retuned, no decay, cap or weight added). Each has a default,
which is what the game does today, so nothing waits on the answers.

**C1. How strongly judgment should show.** Evidence: with the approved decay (half-life 16 game days) and the catalog's
severities (0.2-3 points a deed), opinions stay within a few points of neutral on the 0-100 disposition scale (section 2);
judgment changed 0.24-0.29% of sales, 2.0-2.3% of timber buys and 2.3-2.4% of friendships, and refused nothing in two
village-years. Options: (a) keep as is; (b) larger severities; (c) slower decay of ordinary deeds (X19-DECAY would be
revisited); (d) larger disposition weights in the profiles. Recommendation: (a) until the owner has played with it, then
decide by feel; if more is wanted, (b) is the least invasive. Default: (a).

**C2. Permanence of assault and killing for everyone who hears of it.** Evidence: permanent memories are 76-82% of all
memories after a year (25211 and 43422) and drive the judgment save to 4.4-5.8 MB at 312-512 people; they grow with
people x violent deeds and never shrink (owner Q11, X19-ASSAULT "like murder"). Options: (a) keep (permanent for all who
know); (b) permanent for the victim, kin and eyewitnesses, ordinary (fading, bounded) for hearsay; (c) keep the judgment
permanent but let the hearsay memory fade (Q11 already separates memory from judgment, except for murder). Recommendation:
(c) for assault, murder unchanged: no judgment changes, memory and save stay bounded. Default: (a).

**C3. Repeated deeds in one episode.** Evidence: every blow publishes an assault; a bandit robbing the same victim six times
in ten minutes publishes six thefts, the last for nothing taken; one observer holds up to 68-90 contributions against one
subject; theft severity does not depend on the value taken (theft min_value 0). Options: (a) keep, each a deed; (b) one deed
per episode (same actor and victim within self_defence.fight_minutes), the most serious; (c) (b) and no theft for nothing
taken (min_value 1). Recommendation: (c) (the spec s.5.2 "event spam prevention"; it uses the fight window that already
exists). Default: (a). Separately, for the lead: the bandit re-robbing loop itself is world behaviour (NPCBrain chase and
robbery), outside judgment.

**C4. Family danger: fight or shield.** Evidence: with FAMILY-01 on, heads chose fight 9524 times and shield 398 (s1) but
fight 1452 and shield 20755 (s2), re-deciding at each decision while the threat stays near; bandits killed 234 and 143 a year
against 6 and 7 with judgment off. The behaviour is owner-approved ("Shield and fetch help"); its weights (cornered 900,
stubborn_stand 400, live_order 100, guard_near 300) are agent values. Options: (a) keep; (b) shield first unless cornered at
arm's length; (c) lower cornered. Recommendation: owner to say whether fighting off bandits this often is intended; if not,
(b). Default: (a).

**C5. Ambivalence (SJD-Q04 "mixed feelings: wary but willing").** Evidence: the factor has weight 0 in every profile, so the
approved answer is not in behaviour; and the factor reads lifetime totals, which never decay, so if weighted it would grow
without bound. Options: (a) leave inert; (b) weigh it in trade and contract profiles from the effective (decayed plus
permanent) GOOD and BAD; (c) (b) with "payment up front" as a contract term. Recommendation: (b) when the owner wants it, from
effective values. Default: (a).

**C6. Confirmation only: decay over a year.** X19-DECAY (approved) makes an ordinary deed fade to half in 16 game days; by
day 365 effective NETs are mostly the permanent parts (the 10-point entries are assaults and killings). No decision is
needed unless the owner wants ordinary deeds remembered longer (C1 c).

What SJD-H needs from the owner: answers to C1-C5 (or "keep the defaults"), and, separately, approval of any release or
broad enablement (spec s.24); nothing here is enabled or published.

## 8. Tests and commits

| Commit | What |
|---|---|
| `d0f623b` | `JudgmentSoak.metrics`, `JUDGE`/`JUDGE_SAVE` lines in `economy_sim.gd`, `long-sims.yml` keeps them in the log |
| `32da11d` | `_first_stands` under margin (exact), `judgment_soak_test.gd`, Build 24 fixture and its generator |
| this commit | the report with the Actions results and the calibration package |

Local suites on `32da11d` (Godot 4.7.2 headless): judgment_soak_test 51/0, judgment_live_test 161/0, judgment_test 217/0,
judgment_x19_test 117/0, judgment_bonds_test 98/0, judgment_personality_test 91/0, aspiration_test 155/0.
