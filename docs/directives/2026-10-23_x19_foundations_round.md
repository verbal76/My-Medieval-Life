# Owner directive, 2026-10-23: Expansion 19 authorized implementation round (foundations)

Saved verbatim.

---

MY MEDIEVAL LIFE — EXPANSION 19

Authorized Implementation Round: Approved Personality, Relationships, and Reputation Foundations

You are authorized to begin a limited implementation round for Expansion 19 using only the approved design decisions below.

This authorization does not extend to unresolved mechanics, unapproved balancing formulas, activating the judgment system, publishing builds, or changing existing gameplay behavior.

1. First: Inspect and protect the existing project

Before modifying anything:

1. Inspect the current repository, branch, active workers, and uncommitted changes.
2. Read the current Expansion 19 specifications, decision records, recovery handoffs, and test results.
3. Identify existing relationship, familiarity, reputation, trust, gossip, morality, and personality systems.
4. Identify the existing judgment feature hook and verify its current disabled state.
5. Preserve existing simulation determinism, save compatibility, economic balance, and performance.
6. Avoid duplicating functionality already implemented.

Do not overwrite another worker's changes.

2. Approved personality framework

Implement or extend the foundation for:

- Individual personality traits that can evolve over a villager's lifetime.
- Mostly stable traits with gradual changes caused by meaningful experiences.
- Personality change influenced by event frequency, severity, and duration.
- Soft trait limits that discourage runaway extremes without creating absolute barriers.
- Gradual learning from costly mistakes.
- Accelerating learning when similar mistakes repeatedly cause consequences.
- Practical wisdom that can transfer across situations.
- Temporary emotional overrides that can revive stubborn behavior for several in-game weeks.
- Anger that gradually fades but can be modestly reactivated by reminders.
- Long-term personality changes caused by repeated provocations.
- Full recovery from negative personality changes through sustained positive experience.
- Positive development beyond original personality levels.

Preserve the approved population-level target that approximately 30% of villagers have some potential for self-defeating stubbornness.

Do not treat that percentage as a per-decision probability.

Do not invent precise personality-change formulas or unapproved population subdivisions.

3. Keep psychological systems separate

Maintain distinct concepts for:

- Personality
- Moral judgment
- Trust
- Resentment
- Temporary emotions
- Practical wisdom
- Friendship
- Familiarity
- Family reputation

These systems may influence one another, but must not become interchangeable values.

Historical events remain recorded even when emotional responses change.

4. Relationship history and reconciliation

Approved behavior:

- Personality growth can gradually soften old resentment without direct contact.
- Old resentment may eventually return to neutrality.
- Neutrality does not automatically restore friendship or trust.
- Historical betrayals remain recorded.
- Former friends can rebuild friendship more readily because of shared personal history.
- Personal familiarity provides approximately 10% additional friendship progression when eligible.
- This advantage persists after the former friendship level is restored.
- Active negative relationship standing suspends the familiarity advantage.
- Repeated separations and reunions cannot stack additional familiarity bonuses.
- Trust must recover independently through demonstrated reliability.

Preserve all existing relationship daily caps, diminishing returns, and multi-day progression requirements.

Serious grievances should retain meaningful persistence, with the previously approved expectation that serious nonfatal feelings last at least approximately one in-game year. Do not invent a fixed decay curve without approval.

5. Family reputation

Approved behavior:

- Family reputation can influence descendants who know their family's history.
- Qualifying positive family reputation provides approximately 5% additional friendship progression.
- Personal familiarity is not inherited.
- Reputation persists according to remembered stories, their significance, and how they are transmitted.
- Personal experiences gradually override inherited impressions.
- Individual wrongdoing can create small reputational spillover onto relatives.
- Relatives do not inherit another person's actual moral wrongdoing.
- Trust remains individual and independently earned.

When personal familiarity and family reputation both qualify, the combined friendship progression advantage targets approximately 12%, rather than the full additive 15%.

These percentages are calibration targets, not authorization to invent arbitrary independent probability rolls.

6. Explicitly unresolved decisions

Do not decide or implement mechanics that depend on unresolved questions, including:

- Exactly how far reputation spillover reaches through extended family.
- The precise numerical formulas for personality evolution and reputation transmission.
- Whether specific relationship or reputation effects require additional balancing limits.
- Any unapproved population trait distributions or learning percentages.

Where necessary, create isolated interfaces, data structures, or test fixtures that allow these choices to be added later without architectural rework.

If an approved behavior cannot be implemented without an unresolved design decision, leave that behavior disabled or deferred and document the dependency.

7. Implementation and testing boundaries

- Keep the Expansion 19 judgment hook OFF.
- Do not activate unfinished systems in normal gameplay.
- Do not alter existing economic outcomes with the hook disabled.
- Maintain deterministic simulation results.
- Preserve current saves and existing player-facing behavior.
- Do not create runtime LLM dependencies.
- Avoid expensive per-frame or per-NPC processing.
- Prefer event-driven updates and existing simulation scheduling.
- Add unit and integration tests for the approved behaviors.
- Include regression tests confirming the disabled hook preserves baseline results.
- Validate memory and performance impacts, including larger villages where existing test infrastructure supports them.

Do not publish an APK, Windows build, Linux build, release, or OTA update.

8. Required completion report

When this implementation round is complete, report:

1. Existing systems reused.
2. Files and systems changed.
3. Approved features implemented.
4. Approved features deferred and why.
5. Test results and deterministic comparisons.
6. Performance and memory findings.
7. Any unresolved architectural risks.
8. Decisions still required from the owner.
9. Commit and branch information.

Do not claim an untested feature is complete.

9. Working authority

You may implement and test the explicitly approved foundations in this prompt.

You may not invent missing design decisions, activate the judgment hook, publish builds, or expand the scope without authorization.

Continue working on this bounded implementation round while the owner and ChatGPT finish the remaining Expansion 19 design questions.
