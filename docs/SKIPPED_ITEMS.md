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
