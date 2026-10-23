# P21-01: civic records (offices, tenure history, legacy)

Owner directive 2026-10-23 (`docs/directives/2026-10-23_expansion21_phase1_authorization.md`, VP-01), World Design Rules 015 and
019. Plan: `P21_READINESS.md` section 3, items 1 to 3. Branch `wip/expansion21-preparation` only. **Records only, behind a
disabled switch.** Nothing here is player-facing, so no wiki page changes (nothing playable has landed).

## What it is not

No election, voting eligibility, term, tax rate, punishment, office power, council or appointment exists or is implied. The
authority text is a description of what a post does today in code, read by no rule. No second government, no second treasury,
no money or goods. Treasury attribution (item 4) is not built: it goes through Expansion 20's economic event record.

## Switch and attach point

`game/data/civic.json` (`mml-civic/1`), `"enabled": false`. One attach point, `CivicRecords.attach(world, saved)`, called at the
end of `World.setup` and of `World.load_dict`.

| | disabled (shipped) | enabled |
|---|---|---|
| `World.civic` | null, nothing constructed | the records |
| save | no `civic` key (a section already in a loaded save is kept in `World.civic_foreign` and written back unchanged, never erased) | optional key `civic`, written only when non-empty; `SAVE_VERSION` stays 19 |
| rng, money, goods, the hour-17/18 sequence | untouched | untouched: the records only read the world |

Tests and `economy_sim.gd --civic` use `CivicRecords.override` (1 on, 0 off).

## Records

**Office registry** (`scripts/core/civic/civic_offices.gd`, derived, never stored): jurisdictions `village` plus the five
settlement ids of `settlements.json`; offices `village/reeve`, `village/guard/1..N` (N = `Population.JOBS.guard`, 6 today),
`village/sage`. A settlement jurisdiction carries its government's name only; its officials stay `OffMapSettlement`'s.

**Tenure** (`scripts/core/civic/civic_records.gd`, append-only): `{id, office, holder "npc:<id>", name, family, from, to, how,
cause, observed}`. `to` is -1 while open. `how`: `death`, `migration`, `left_post`, `replaced`. `observed` marks a tenure
seeded when the records attached ("observed from" that day, not a claim about earlier history). A vacancy is the gap between one
tenure's `to` and the next one's `from`; it is not stored twice.

**Legacy** (`legacy["npc:<id>"]`): `{name, family, end "death"|"departure", day, cause, destination, trades [{job, since}], offices}`.
The cause is the reason `World.kill` was given, else `"unknown"`. Trades are what the villager already carries at that moment
(`left_job`, `job`, `job_since`). Kept apart from `NPC.memory` and the 300-line log; never removed.

## Observed paths (one guarded call each, `if civic != null`)

| Path | Call | Effect |
|---|---|---|
| `World.kill` | `on_death(n, cause)` | closes tenures (`death`, cause), writes the legacy |
| `Migration._gone` | `on_departure(n, settlement)` | closes tenures (`migration`), writes the legacy (`departure`) |
| `NPCBrain._reeve_succession` | `on_reeve(n)` | opens the reeve tenure when `reeve_id` is set |
| `NPCBrain._install` | `on_installed(n, job)` | opens a guard (lowest free slot) or sage tenure |
| `NPCBrain._post_left` | `on_post_left(n, job)` | closes tenures (`left_post`) |

## Invariants (tested in `game/tests/civic_records_test.gd`)

1. At most one open tenure per office, and one office per holder at a time; a new holder closes the old tenure as `replaced`;
   observing the same holder again opens nothing.
2. Holders are `npc:<id>` references with name and family copied in, so they resolve after death, departure or removal from
   `World.npcs` (the heir child, `life.gd`).
3. Deterministic: tenure ids are the order opened; slots are assigned lowest-free-first; no rng, no clock.
4. Event-driven: nothing in `World.update` or any hourly pass calls the records; cost per event is independent of history length
   (about 6 microseconds with 3,600 tenures).
5. Observation only: coins, treasury, goods and the RNG state are identical with the records on or off.
6. `audit()` (diagnostic, not run by the game) compares the open tenures with the live world.

Known limitation: a post changed by a path not listed above (none known today) would leave a stale open tenure until the next
listed event for that holder; `audit()` finds it. A guard beyond the watch's strength has no slot and is counted in `unslotted`.

## Future consumers

Elections and appointments (open tenure, vacancy gap, eligibility reads `legacy` and `tenures`); graves and history
(WDR-014-C: `legacy` is the death record they need); treasury attribution (Expansion 20's event record names an actor and an
office id; the office id from here is the stable key); Expansion 19 family reputation (offices held by kin).
