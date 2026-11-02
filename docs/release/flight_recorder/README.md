# Flight recorder campaigns (FLIGHT-REC-01)

The owner's standing command **"Run flight recorder"** (directive 2026-11-02,
`docs/directives/2026-11-02_permanent_flight_recorder_simulation_system.md`; register FLIGHT-REC-01) launches independent
365-game-day simulations of normal integrated village play on GitHub Actions, records every instrumented interaction with the
flight recorder, searches the whole archive for abnormal behaviour, and keeps an Excel workbook, a findings report and all the
evidence, whatever happens to the run. GitHub runs and collects; Claude (or ChatGPT) reviews.

A village is allowed to fail; the simulation is not (WDR-022). Starvation, unemployment, business failure and deaths are
outcomes to report, never reasons to stop or to call something a defect.

## Running it

The campaign is the reusable workflow `.github/workflows/flight-recorder-campaign.yml` (plan, one chain per seed through
`flight-recorder-seed.yml`, campaign report). GitHub dispatches only workflows whose file is on the default branch (`main`), and
then runs the version on the dispatched ref, including every workflow it calls by a local path (`uses: ./.github/workflows/...`)
and every local action. So **today the campaign is dispatched through `long-sims.yml` with `flight: true`** (long-sims is on
`main`; nothing on `main` changes). `flight-recorder.yml` is a thin dispatch wrapper with the directive's defaults, kept for when
it reaches `main` with an owner-authorized merge; it calls the same campaign.

Through long-sims (`flight: true`; its own defaults are the comparison runs', so set them):

| input | value for "Run flight recorder" | meaning |
|---|---|---|
| `flight` | `true` | the campaign instead of the comparison runs (`plan`, `sim`, `recover` are skipped) |
| `seeds` | `1,2` | one independent run per seed (at most four; at most two simulate at once) |
| `days` | `365` | game days |
| `every` | `10` | checkpoint every N days: the 30-, 90-, 180-day milestones are read from these, never from separate runs (SIM-01) |
| `record` | `true` | the flight recorder on |
| `sim_args` | empty | normal integrated play (the shipped switches); allowed: `--aspiration --job-choice --economy --market --no-judgment --scenario NAME --at DAY` |
| `segment_days` | `100` | game days per chained job (see "Why segments"); a multiple of `every`; `days` at most 4 x this |
| `set`, `variants`, `recover_run` | empty | a flight run refuses `set` or `variants`; `recover_run` must be empty |

```sh
gh workflow run long-sims.yml --ref <integration branch> \
  -f flight=true -f seeds=1,2 -f days=365 -f every=10 -f record=true -f sim_args= -f segment_days=100 \
  -f set= -f variants= -f recover_run=
gh run list --workflow long-sims.yml -L 1 --json databaseId,url,headSha,status   # the run's link
# once flight-recorder.yml is on main: gh workflow run flight-recorder.yml --ref <branch>   (its defaults are the directive's)
```

The GitHub MCP tool `actions_run_trigger` (workflow `long-sims.yml`, the same inputs) does the same. Give the owner the run link
at once; do not wait for it. **Use the latest suitable integration commit** (the `--ref`): if a known, imminent fix makes the
current commit unsuitable, wait for the fix rather than spend a campaign on a known defect. A flight dispatch of long-sims has
its own concurrency group (`flight-recorder-<run id>`); without `flight` long-sims keeps `long-sims-<ref>` exactly as before.

### Independence and spending

- Its own concurrency group per run (`flight-recorder-<run id>`): a campaign never cancels or queues behind another, and nothing
  in CI, the long-sims comparison runs, packaging or releases waits for it. Before dispatching, check the long-sims runs
  (`gh run list --workflow long-sims.yml`, a flight run's jobs are named `flight / ...`) for a campaign still running: two at once
  double the runner time for nothing.
- `max-parallel: 2` seeds; each seed is its own chain of jobs (`flight-recorder-seed.yml`), so one seed failing never stops the
  other (`fail-fast: false`).
- Every artifact and status names the commit (`GITHUB_SHA`); the analysis reads it from each segment's status.
- Never cancel, restart or rerun a running campaign to check on it (SIM-02); never rerun a failed one before reading why it
  failed (directive section 8).

## Why segments (the six-hour limit)

Measured: an unrecorded normal-play year takes 3.7 to 4.4 hours a seed on Actions (runs 41362329381, 41403541582: 13,400 to
15,800 s, the village growing to 300-440 people; the last days are the slowest). Recording adds work in proportion to the rows
written: about 9% at 104 villagers locally over 10 days (303 s against 277 s, seed 1), more as the village grows; an 80-day
recorded run took 4,395 s on Actions (2026-10-27). Estimate for a recorded year: 4.5 to 6 hours of simulation, plus the archive
checks, which does not fit a 330-minute job reliably.

So each seed's run is **chained**: segment jobs of `segment_days` (default 100: days 0-100, 100-200, 200-300, 300-365), each
well inside the limit (estimated 1 to 2.5 hours; the simulation itself is stopped at 320 minutes so the uploads always run).

- At its last day a segment saves the world with the game's own save (`World.to_dict`, the JSON the save system writes), the
  world's running counters (`World.stats`, which a save does not hold and the ledgers read) and the harness's records (the ledger
  start, every sample, the counts), gzip-compressed (`economy_sim.gd --save-at DAY --state FILE`). The next job goes on from it
  (`--resume FILE`). Each segment's recorder session is its own (ended and checked on its own); the next one begins with the
  `world_loaded` note.
- **Deterministic from its save, conserving coins and goods**: tested on seed 1 (segment to day 5, resumed to day 10 twice, once
  recorded and once not): the same fingerprint `c8cae8df...` both times, the currency and item ledgers balanced (leak 0, no item
  residual) across the join. The harness's FATAL checks run in every segment against the run's original start.
- **Not identical to an unbroken run**: a save does not hold movement in progress (an animal's or villager's heading, plan and
  path; `game/tests/save_continuity_test.gd`), so a chained run diverges from an unbroken one after the first join. Compare a
  chained run only with chained runs of the same `segment_days`; to compare with an unbroken long-sims run, compare the outcomes
  (population, food, money trends), never fingerprints. The read-only bandit diagnostics (BANDITS lines) restart in each segment.

## When a run stops early

`economy_sim.gd` always writes `status.json` (`mml-flight-status/1`): seed, commit, arguments, days requested, start day, days
reached, **stop reason**, ledgers, fingerprint, recorder state. The workflow adds the exit code, the script errors and the run
link, and writes the status itself when the simulation left none.

| stop reason | when | a defect? |
|---|---|---|
| `completed` | the last day was reached | no |
| `segment` | the segment's last day: the world is saved and the next job goes on | no |
| `extinct` | no villager alive and no open succession post for `--extinct-days` (30) consecutive days | no: an outcome |
| `fatal` | a FATAL ledger line at a checkpoint (currency, items, deposits, animals, the settlements' books) | yes |
| `crash` | the process ended without a status (an engine crash) | yes |
| `timeout` | the simulation passed 320 minutes | infrastructure: lower `segment_days` |

Extinction and the game's repopulation paths: births need living villagers; an open succession post brings a newcomer within
`newcomer_max_days` (10), so an open post keeps the run going; migration in (MIGRATE-18) comes with the caravan, each
settlement at least every 8 days, when the village has a post or food and a home to offer. Any arrival ends the stretch; 30 days
with nobody coming covers all of them. Ordinary starvation, hardship and decline never stop a run.

## What it produces (artifacts)

| artifact | contents | kept |
|---|---|---|
| `fr-seed<N>-results` | `findings.md`, `findings.json`, `summary.json`, `flight-recorder-seed<N>.xlsx`, `workbook_data.json`, `workbook_check.json`, `analyse.log` | 90 days |
| `fr-seed<N>-seg<K>-archive` | the segment's complete recorder session (gzip JSON-lines chunks, `session.json`) | 30 days |
| `fr-seed<N>-seg<K>-run` | `status.json`, `sim.json` (samples, deaths, flows), `sim.log.gz` | 90 days |
| `fr-seed<N>-state<K>` | the saved world and harness at the end of segment K | 30 days |
| `flight-recorder-campaign` | `campaign.json`: every seed's summary and the run link | 90 days |

Sizes: about 0.8 MB of archive a game day at 104 villagers (8.1 MB for 10 days), growing with the population; expect roughly
0.4 to 1 GB per seed-year (each segment's session stays under the recorder's 1 GiB storage cap). Saved worlds are about 0.2 MB.
The step summary of each run shows the stop reason, days reached, counts by severity and the top findings, with the run link.

### The analysis (`tools/flight_analyse.py`)

Standard library only; reads every segment in order. First `tools/recorder_archive.py` checks each session (whole chunks, row
sequence, event ids, references, transitions such as nothing after a death and contracts opened once, snapshots an hour apart).
Then one pass over every row of the event, participant, state_change, sample, snapshot and alert tables (the whole archive, not
the old workbook's 20,000-event cap) looks for:

| finding | rule (threshold) | severity |
|---|---|---|
| repeated failed action | same villager, same action, same target (item, recipe, pen, cell...), failing with no success between: streak >= 50 or >= 20 in a day; >= 15 over 2+ days | HIGH; MEDIUM |
| repeated failed purchase | same buyer and item refused with no purchase between: >= 30; >= 10 (reasons and sellers in the evidence) | HIGH; MEDIUM |
| necessity unbuyable | a food item with >= 50 refusals and more refusals than sales | MEDIUM |
| decision oscillation | plans alternating A,B,A,B... >= 16 times in one day; on >= 5 days | MEDIUM; HIGH |
| empty decisions | >= 40 decisions with no plan by one villager in a day | MEDIUM |
| impossible task | >= 10 navigation failures (walk lost) in a day; on >= 3 days | MEDIUM; HIGH |
| station contention | >= 10 waits given up at one station in a day (villagers named) | MEDIUM |
| stuck villager | one cell for >= 12 hours while travelling or lost; >= 24 | MEDIUM; HIGH |
| starving with means | hunger under 15 for >= 24 sampled hours with >= 10 coins while the village holds >= 1 day of food | HIGH |
| starved with means | a starvation death with coins or food of their own or their household (recorder_archive.py) | HIGH |
| job oscillation; job churn | switching between the same two jobs >= 4 times (>= 8 HIGH); >= 10 job changes | MEDIUM; HIGH |
| duplicate trades | the same trade >= 5 times in one game minute | MEDIUM |
| contracts failing | one party's contracts for one item: >= 5 failed, none fulfilled | MEDIUM |
| failure cascade | hours with failed actions >= max(20, 5 x the median hour) | MEDIUM |
| chapel relief missed | households in hardship (purse 0 and under a day of food for 3+ days) in a checkpoint window, the chapel able (fund above its reserve or food in store) and nobody relieved; or 10+ asks with no relief | MEDIUM |
| death cluster | >= 5 villager deaths in a day (MEDIUM when mostly violent or accidental) | INFORMATIONAL; MEDIUM |
| coin total unattributed | the recorder saw the world's coin total change with no recorded cause | HIGH |
| ledger broken, script errors, crash, archive corrupt, ids changed on load, economy save round trip | the harness's FATAL lines, `SCRIPT ERROR`, no status, recorder_archive.py problems | CRITICAL (confirmed) |
| population, hardship, treasury, tills, settlements | outcomes and abnormal-run evidence | INFORMATIONAL |

The thresholds are reading aids that separate suspicious repetition from repeated work (checked against a recorded 10-day run,
where the longest failure streak was 8 and the longest plan alternation 5); they are recorded in `findings.json` and are never
pass/fail rules. Only CRITICAL findings are **confirmed defects**; every other finding is a suspicion with evidence: the NPC,
the event ids, the day range, the count, the systems and how to reproduce it (commit, seed, harness arguments, the events to read).
Nothing in the analysis changes the game or its behaviour.

### The workbook

`game/tests/flight_workbook.gd` writes the 14 sheets the directive lists with the game's own XLSX writer
(`workbook_builder.gd build_spec`), from `workbook_data.json`: Executive Summary (most significant findings first), Population
and Survival, Food Production and Use, Economy and Employment, Businesses and Trade, Chapel and Relief, Contracts and Credit, NPC
Behaviour and Decisions, Repeated Failed Actions, System Interaction Anomalies, Currency and Inventory, Critical Events and
Deaths, Trends and Graphs, Coverage and Limitations; 14 charts. Daily tables (one row a game day), summaries and prioritised
examples keep it small (about 60 KB for 10 days; a year stays in the low megabytes); the full data stays in the archive.
`tools/check_workbook.py FILE --flight` checks every sheet and chart opens and holds data.

Coverage and its gaps: `COVERAGE.md` (this folder).

## Reviewing results ("What did the flight recorder find?")

GitHub produced everything; reviewing needs no running process. With `gh` (or the GitHub MCP tools, or the REST API):

```sh
gh run list --workflow long-sims.yml -L 10 --json databaseId,url,headSha,status,conclusion,createdAt   # (flight-recorder.yml once on main)
gh run view <run id>                                    # a flight run's jobs are named "flight / ..."; the step summaries
gh run download <run id> -n fr-seed1-results -D fr/seed1   # findings.md, findings.json, the workbook
gh run download <run id> -n flight-recorder-campaign -D fr
```

REST, for ChatGPT or any client: `GET /repos/verbal76/My-Medieval-Life/actions/workflows/long-sims.yml/runs` (a flight run has
the artifact `flight-recorder-campaign`),
`GET /repos/verbal76/My-Medieval-Life/actions/runs/{run_id}/artifacts`, `GET /repos/verbal76/My-Medieval-Life/actions/artifacts/{artifact_id}/zip`
(authenticated), and the job logs `GET /repos/verbal76/My-Medieval-Life/actions/jobs/{job_id}/logs`. Where artifact downloads
are blocked, the logs still hold the essentials: each segment job prints its status, checkpoint lines and any FATAL line, and
the analysis job prints `findings.md` (up to 60 KB) and the summary.

Read `summary.json` first, then `findings.md` (CRITICAL, HIGH, MEDIUM, INFORMATIONAL), then the workbook for trends; open the
archive only to investigate a finding (its event ids; `tools/recorder_archive.py` and `tools/flight_analyse.py` run locally on a
downloaded `run/seg<K>/rec` layout). Report: what happened (days reached, why it stopped), what worked, what failed, which NPCs
behaved strangely, which systems may interfere, what deserves investigation; the most important first. Never call a suspicion a
defect without evidence, and never answer an owner decision.

## Files

- `.github/workflows/long-sims.yml` (`flight`, `segment_days`), `.github/workflows/flight-recorder-campaign.yml`, `.github/workflows/flight-recorder-seed.yml`,
  `.github/actions/flight-segment/action.yml`, `.github/workflows/flight-recorder.yml` (the wrapper for main)
- `game/tests/economy_sim.gd` (`--status`, `--save-at`, `--state`, `--resume`, `--extinct-days`)
- `tools/flight_analyse.py`, `tools/recorder_archive.py`, `tools/check_workbook.py --flight`
- `game/tests/flight_workbook.gd`, `game/scripts/recorder_export/workbook_builder.gd` (`build_spec`), `game/data/sim_workbook.json` (`flight_recorder`)
- `tests/test_flight_analyse.py`
