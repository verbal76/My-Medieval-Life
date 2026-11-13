# Build 42: flight-recorder analysis of the chain 12 year-long campaigns (Agent I, 2026-11-13)

Recorded by the lead from Agent I's report. Evidence downloads were in /dev/shm/agentI (volatile); run ids below are the
durable source.

## Campaigns on record
| Run | Code | Seeds | Config | Result |
|---|---|---|---|---|
| 43332151718, 43332156022 | b3c9eb5 (chain 12) | 1-2, 3-4 | long-sims flight, 365 d, every 10, segments 100, recorder on, no twin | 365/365 all seeds; money and item ledgers balance every segment; 0 script errors, 0 FATAL; archive checks ok; determinism not tested; findings C/H/M s1 0/7/62, s2 0/66/31, s3 0/30/44, s4 0/15/39 |
| 43332363247 (INV-02) | cebae28 | 1-4 | long-sims --spoil-storage, no recorder | 365/365; leak 0; starvation 2/17/12/14; alive 377/200/324/306 |
| 43530227383 (early, running) | 0bbee94 | 1-4 | same as chain 12 | dispatched 2026-11-13, ~6.5-7 h |

Alive day 10/100/200/365: s1 107/136/230/327, s2 105/140/195/218, s3 104/137/180/281, s4 109/137/191/313. Starvation
deaths 15/24/2/6. Not reusable as Build 42 closure evidence: b3c9eb5..a5a0b7c changed world.gd (ND-19 re-path),
farm_plots.gd, fauna.gd (hunt AI), balance.json (wildlife.struck). journeys.gd, envoys.gd, chapel.gd and the world path
finder are unchanged b3c9eb5..0bbee94.

## Findings
- A. CONFIRMED DEFECT: envoys starve on the road home: 23 of 47 starvation deaths (s1 11, s2 7, s3 1, s4 4). journeys.gd
  start() provisions one leg only (capped at half the pantry); the return depends on buying at the destination, which
  needs coins; resume() waits for sellers only when coins > 0. Example s1 p:168, envoy to Garton day 325, died day 328
  05:46 on the road. Assigned Agent F (wip/b42-reg-travel); lead decision: provision the round trip from the household's
  own food within the existing cap, refuse to send when a safe return cannot be covered; no advance pay (economic change,
  owner's call).
- B. CONFIRMED DEFECT: villagers stranded after delivering chapel relief outside the village: 11 deaths (s2 p:109
  (0,162) d14-15, p:110 (3,158), p:86 (2,160), p:36, p:88, p:164, p:190, p:99, p:29; s1 p:17 (162,124); s3 p:68
  (79,139)). chapel.gd _dest() targets the first member's current cell for a household with no village home;
  village_map.gd find_path_world refuses search boxes over WORLD_PATH_CELLS = 140 (probable, unproven); outbound route
  unexplained. Assigned Agent L (wip/b42-nav-stranding).
- C. CONFIRMED DEFECT: walk back-off bypass (MML-NPC-01 related, flight finding F009): world.gd _walk resets path_fails
  on a plan's first successful walk, so the second walk's failure is always "first"; 200-554 re-plans a day (s2 p:36, p:88,
  p:1000004, p:110, p:109). Assigned Agent L.
- All 47 starvation deaths are travel or navigation (23 envoy; 24 with unreachable-goal findings before death, 11 of them
  B). Granary and household stocks positive at every death; the interim "unemployed adults not fed" hypothesis is
  withdrawn.
- D. Unemployment (B17F-JOBS, JOB-02): adults ~60 -> 150-170; employed flat 66-78 after day 90; job none at day 365
  96/84/93/87; "looked and found none" 8.7k-12k; INV-02 116/45/95/94. Population growth (births 225-426, arrivals 108-189)
  to be checked against requirements. Agent H.
- E. Businesses: none open at day 365 in any seed; seeds 3, 4 never opened one; mostly venture_refused_experience.
  Unclassified. Agent H.
- F. Ore: iron, coal, copper at 0 by days 30-90 every seed; stone by 300-365 (s3, s4); 7-13 miners stay employed. Finite
  deposits to be checked against design. Agent H.
- G. Recorder alert economy.unbacked_reservation ('violation', 156-200 per seed from day 3) from the LE-01 model
  (recorder labels it observing only): reservations exceed holdings; item ledger 0 leaks. Unresolved; needs an owner.
- H. Workbook running totals restart at segment boundaries (report artefact).
- Not yet examined: full-year Q33 trader cash, cold nights, stalled construction (s1 6 of 10 sites open day 310),
  inheritance. s1 median household purse 115 -> 23 (other seeds 93-150): treated as a seed outcome for now.

## Build 42 campaign (prepared, not dispatched)
long-sims.yml on the candidate branch after confirming the head SHA: flight true, seeds 1,2,3,4, days 365, every 10,
segment_days 100, record true, sim_args "--twin" (determinism twins + 8 targeted scenarios). ~16 concurrent runners,
3.5-4 h wall. Dispatch after 43530227383 finishes. Fix A, B and C first.
