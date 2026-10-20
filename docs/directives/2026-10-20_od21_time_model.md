# Owner decision, 2026-10-20: OD-21, explicit time model and calendar consistency

Saved verbatim. The owner's answer to the agent's question of 2026-10-20 (are the biological, economic and agricultural
systems calibrated to the same eight-day year?): Option A, with a clarification. Register: OD-21 (approved
architectural decision), TIME-01 (the time-system audit), TIME-02 (explicit units and a shared conversion layer),
TIME-03 (recommended retuning, owner review before any change).

---

MY MEDIEVAL LIFE — OWNER DECISION

OD-21: EXPLICIT TIME MODEL AND CALENDAR CONSISTENCY

Claude, approve Option A with the following clarification.

Keep the existing eight-game-day year and four two-day seasons.

Do not lengthen the year.

Do not change the current baseline merely to make every system use the same duration.

The game intentionally uses accelerated long-term progression so that villagers can experience meaningful life cycles, family development, economic advancement, and generational change within reasonable gameplay time.

However, every timed system must have a clearly defined meaning.

1. Establish explicit time semantics

Document three conceptual categories:

Operational time: Hunger, sleep, daily work, travel, immediate actions, and other moment-to-moment activities.

Economic time: Wages, rents, prices, contracts, reserves, production costs, and commercial decisions.

Calendar time: Seasons, aging, births, generational development, seasonal agriculture, and long-term biological processes.

These are classifications, not three separate clocks.

Economic systems may legitimately use operational days or calendar periods depending on the underlying obligation.

Do not force every economic system onto one clock.

2. Preserve the existing calendar

Retain:

- 24 game hours per game day.
- 8 game days per calendar year.
- 4 seasons per year.
- 2 game days per season.

Do not change the fundamental passage of time.

3. Audit and document every timed system

For each system, record:

- Current duration.
- Current clock or time unit.
- Intended gameplay meaning.
- Equivalent duration in calendar years or seasons.
- Whether its current calibration is reasonable.
- Whether changing it would affect simulation balance.
- Whether player and NPC rules are consistent.

Make time units explicit in configuration and code where practical.

Avoid ambiguous values whose meaning depends on undocumented assumptions.

4. Identify calibration outliers

Specifically review:

- Tree growth and regrowth.
- Crop growth and seasonal restrictions.
- Egg and milk production.
- Livestock breeding and lifespans.
- Rent and land leases.
- Courtship and marriage.
- Food reserves.
- Manor relief.
- Granary targets.
- Treasury reserves.
- Tax holidays.
- Caravan frequency.
- Reputation and notoriety.
- Any other timed systems uncovered by the audit.

Do not automatically retune these values.

Recommend adjustments based on gameplay purpose, economic consequences, and world consistency.

5. Separate time-model correctness from balancing

A system is not defective simply because its duration is unrealistic compared with the real world.

A system is defective when it:

- Uses the wrong clock relative to its intended design.
- Changes behavior unexpectedly when calendar settings change.
- Violates player–villager parity.
- Creates unintended economic or biological consequences.
- Produces inconsistent results because time units are confused.

Do not apply real-world realism at the expense of gameplay without owner approval.

6. Protect the existing simulation baseline

Complete the ongoing seed-2 starvation investigation.

Preserve the current agricultural and economic simulation baselines.

Do not activate major changes to seasons, biological reproduction, production rates, rents, or economic periods without comparing their consequences.

Any retuning that materially affects village behavior requires owner review.

7. Future-proof the calendar

Where appropriate, express calendar-dependent values in years, seasons, or clearly identified calendar units rather than unexplained day counts.

If the number of days per year changes in a future development version, calendar-dependent systems should remain internally consistent.

Operational daily systems should not automatically change simply because the calendar changes.

Use shared conversion functions or a common time-definition layer rather than scattered hardcoded assumptions.

Do not introduce a third running clock.

8. Reporting

Register OD-21 as an approved architectural decision.

Produce a time-system audit identifying:

1. Systems already consistent with their intended time model.
2. Systems with ambiguous time units.
3. Genuine defects.
4. Gameplay-balance concerns.
5. Recommended retuning, with expected consequences.
6. Dependencies affecting agriculture, livestock, household economics, and generational simulation.

Implement safe documentation, unit clarification, and architectural improvements through the approved staging workflow.

Do not change major gameplay timings without owner approval.

Do not merge or publish a build without authorization.

Continue the approved Build 16 investigations and development.

Final governing principle: The game may compress years into days, but every system must know which kind of time it is measuring.
