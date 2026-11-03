# Owner directive, 2026-11-03 (about 15:00 EST): Build 25 Revision 1, full approved scope is mandatory

Saved verbatim. Register: B25R1-015. Applies to B25R1-001..014 and B25R1-Q1.

---

MY MEDIEVAL LIFE — B25R1

OWNER DIRECTIVE: FULL APPROVED SCOPE IS MANDATORY

This directive clarifies and supersedes all previous language suggesting that approved features may be deferred, disabled, or moved into a future build because of implementation difficulty.

Everything the owner has approved for Build 25 Revision 1 belongs in Build 25 Revision 1.

This includes all previously approved work involving:

- Wilderness interactions and real NPC/animal behavior
- Regional map, discovery, navigation, and controller support
- Character creation and interface improvements
- Stone roads, natural path formation, wear, paving, and repair
- Real resident travelers and existing ambient travelers
- Young-adult and established-adult homesteading
- Persistent wilderness homes, households, construction, farming, livestock, and economic survival
- Youth runaways and hardship-driven life decisions
- Sustainable bandit recruitment and population continuity
- Adult bandits leaving outlaw life
- Shared lawful and outlaw wilderness settlements
- Hidden bandit homes, workshops, and trading locations
- Bandit skilled occupations, crafting, equipment, agriculture, livestock, trade, and supplemental raiding
- Real player discovery, interaction, combat, and obtainable equipment
- Conservation, deterministic simulation, save/load, and long-term population validation

The requirements register remains authoritative for all previously approved details.

1. No unilateral deferrals

Do not silently:

- Move approved functionality to Build 26 or another expansion.
- Remove it from Revision 1.
- Substitute a placeholder for functioning gameplay.
- Disable it to pass release tests.
- Mark an incomplete implementation as complete.
- Narrow an approved feature without owner authorization.

2. When implementation encounters a blocker

Investigate the actual obstacle and report:

1. What specifically is preventing implementation?
2. Which existing systems are involved?
3. What solutions are technically feasible?
4. Which solution do you recommend, and why?
5. What are the consequences for performance, determinism, compatibility, and development time?

Ask the owner for a decision only when a genuine architectural or gameplay tradeoff requires one.

Do not treat ordinary engineering work as an approval blocker.

3. Continue working independently

Workers should continue implementing all unblocked work.

Use the existing systems wherever possible, extend them where necessary, and coordinate shared code ownership.

Do not stop unrelated workers while resolving one obstacle.

Do not repeatedly ask for approval on decisions already made.

4. Release criteria

The Revision 1 private draft is not ready until all approved functionality is implemented, integrated, and validated.

Tests must verify actual gameplay behavior, not merely the existence of code or UI elements.

Validate conservation, identity, mortality, economy, persistence, deterministic replay, and multigenerational stability.

Reuse passing test evidence for the exact source commit when applicable. Avoid redundant expensive campaigns.

Preserve the original Build 25 draft as the rollback.

5. Documentation

Record this directive in the requirements register and recovery handoff.

Audit the existing B25R1 requirements for any features incorrectly marked optional, deferred, or excluded.

Correct those classifications.

Report any genuine contradictions between approved requirements rather than resolving them silently.

Owner's final instruction:

We are building the complete approved Revision 1, not a reduced version that happens to pass tests.

If we hit a wall, bring the problem and possible solutions to me. We will work through it.

Do not lower the scope without my explicit decision.

Proceed with implementation.
