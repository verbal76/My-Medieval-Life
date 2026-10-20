# Skipped items register

**Owner directive:** 2026-10-20 (`docs/directives/2026-10-20_master_overnight_development_directive.md`, section 5).

A noncritical, isolated, safely deferrable issue may be recorded here and the work moves on. **Not deferrable:**
- missing mandatory gameplay systems, crashes, save corruption, broken essential NPC behaviour;
- serious economic deadlocks, invalid resource or currency accounting;
- broken core construction or survival systems;
- failed mandatory simulation integrity checks;
- regressions that invalidate a build's intended functionality.

Every entry keeps its register id (`docs/requirements/requirements.json`); the register stays authoritative for status. Nothing is removed from this table: a resolved row gets its resolution and commit.

| Build | Id | Description | Severity | Reason for deferral | Affected functionality | Workaround | Recommended correction | Reconsider at | Resolution |
|---|---|---|---|---|---|---|---|---|---|
| 15 | WDR-010-C | Rule 010's example "obstructed cart routes should show useful feedback": no feedback exists | Low (presentation) | A pulled cart follows its puller at a fixed trail distance without collision (`Carts.update`), so a cart route is never obstructed and there is nothing yet to explain; giving carts collision is a gameplay change that needs its own design. The rule's other parts are met (sword reach and timing readable, CQ-01; wiki guides). The device playtests stay open as `playtest` | Cart handling only | None needed: carts never stick | When carts gain collision or route planning, show why a route is blocked and where | Build 16 (or when carts are next changed) | Open |
