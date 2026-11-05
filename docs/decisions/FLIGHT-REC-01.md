# FLIGHT-REC-01: "Run flight recorder" is a standing command for a year-long recorded campaign

## Identification
- Decision ID: FLIGHT-REC-01 (register, kind `approved`)
- Date: 2026-11-02
- Project / build: My Medieval Life, Build 25 and all future expansions
- Decided by: owner (the standing authorization); lead and worker (how it was built)
- Source of authority: [`docs/directives/2026-11-02_permanent_flight_recorder_simulation_system.md`](../directives/2026-11-02_permanent_flight_recorder_simulation_system.md)
- Status: approval OWNER APPROVED; implementation INTEGRATED (`cad96c4`); completion OPEN. Copied 2026-11-02; the register
  is authoritative.

## Original problem
In the owner's words: a villager had been found trying to buy an axe hundreds of times, and the owner wanted that kind of
behaviour found automatically. Also, long runs should not spend hours simulating a dead village.

## Owner's direction (quoted)
> From this point forward, whenever I say: "Run flight recorder" You must automatically initiate a complete, 365-game-day simulation campaign on GitHub. No additional explanation, configuration questions, or approval should be necessary.

> We previously discovered NPC behavior involving a villager repeatedly attempting to purchase an axe hundreds of times.
>
> I want the system to find that kind of behavior automatically.

> However, do not waste several hours simulating an extinct village.

> Ordinary starvation, unemployment, business failures, economic hardship, and individual deaths are NOT reasons to terminate a simulation. [...] A village is allowed to fail. The simulation is not.

> Do not unnecessarily rebuild working infrastructure.

**Defaults set by the owner:**
- 365 days;
- seeds 1 and 2;
- at most 2 jobs;
- recorder on;
- checkpoints every 10 days;
- normal integrated play;
- the latest suitable integrated commit.

## Interpretation (lead and the worker on `wip/b25-flight-recorder`)
- **Dispatched through `long-sims.yml`** with `flight: true`, which calls the reusable `flight-recorder-campaign.yml` and
  `flight-recorder-seed.yml`. The reason is recorded in the changelog: "GitHub dispatches only workflows whose file exists on
  `main`. `long-sims.yml` does, and `main` is the owner's." Adding a new top-level workflow would have needed a change to
  `main`, which only the owner makes.
- **100-day segments with save and resume,** because a recorded year may exceed the job time limit. The directive allows
  "a reliable checkpoint/resumption mechanism".
- **Early stop** only when the village has been extinct for 30 days with no open succession post, or on a fatal integrity
  failure. The 30-day margin is an agent choice.
- **CRITICAL findings** are reserved for confirmed defects.

## Reasoning and alternatives
- Why: the owner's reasons, quoted above.
- Alternatives the owner considered: UNKNOWN.
- **Implementation alternatives** considered by the agents:
  - **A separate workflow file.** It was not used for the dispatch entry point, because of the `main` restriction above.
  - **The older recorded path,** `long-sims` with `record: true`. The owner's first command ran on it (run 41458375116),
    because the dedicated workflow was not finished. It remains available.

## Consequences
- **"Run flight recorder" needs no further approval.** Do not cancel older runs because development continues, and do not
  rerun a failed year without examining it first. (From the directive.)
- **Recording must not change outcomes.** This was shown: the fingerprint is identical with and without `--record`.
- **Coverage gaps are listed honestly** in the flight recorder's `COVERAGE.md` on the Build 25 source, at
  `docs/release/flight_recorder/`. They include the chapel, manor work, parts of the farming and mining scripts, and about 150
  unattributed coin sites.

## Implementation
- Branch `wip/b25-flight-recorder` (`4dd8362`, `98f4342`, `8e59dfb`), merged as `cad96c4`.
- **Trial:** [41464356721](https://github.com/verbal76/My-Medieval-Life/actions/runs/41464356721) on `cad96c4`, seed 1, 20
  days in two 10-day segments. It succeeded end to end:
  - the second segment resumed from the first one's save;
  - the analyser read 111,804 events;
  - the 14-sheet workbook was checked;
  - findings: 2 MEDIUM, 4 INFORMATIONAL, 0 CRITICAL.
- **First full campaign:** [41469410306](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469410306) on `8acbdea`,
  in progress when this record was written.
- **Not yet shown:**
  - full-year runtime and analyser memory on a year's archive;
  - the extinction stop in action.

## When to reconsider
The owner set no trigger (UNKNOWN). The defaults change whenever the owner names different seeds, durations or scenarios;
the directive says such instructions override them.
