# Owner approval, 2026-10-20: sleeping loft and GitHub Actions long-duration simulations

Saved verbatim from the owner's message. Register: HOUSE-12, INFRA-01, INFRA-02.

---

Claude, I approve both proposals, subject to the following requirements.

1. Sleeping loft — APPROVED

Proceed with the lightweight sleeping loft described in "docs/design/SLEEPING_LOFT.md".

Approved initial construction requirements:

- 12 planks.
- 6 logs.
- No stone.
- Two sleeping places.
- Existing child bed-sharing rules apply.
- Maximum one loft per house initially.

Keep construction quantities configurable through the existing balance system.

The loft must be constructed through normal gameplay using actual materials, hauling, and construction work. It must not grant sleeping capacity until construction is complete.

Use the existing ladder-cell approach without introducing a fully navigable second floor.

Preserve existing household ownership, sleeping behavior, saves, and compatibility with older houses.

A loft sleeper must not appear to be sleeping on the ground floor.

NPC decision-making

A crowded household should evaluate available housing solutions based on actual circumstances.

Do not automatically force every family to construct a loft before considering other legitimate options.

Factors should include household size, available money, materials, existing construction goals, and available building space.

The smaller 5×6 attached room remains an approved option where physically possible.

If neither option is feasible, preserve the household's housing goal without creating an impossible construction loop.

2. GitHub Actions long-duration simulations — APPROVED

Create a manually triggered GitHub Actions workflow for running long-duration simulations independently of the Claude development container.

Requirements:

1. Use the existing simulation harness and gameplay rules.
2. Support selecting the simulation seed and duration.
3. Keep each simulation's output and temporary files isolated.
4. Preserve simulation logs and results as downloadable workflow artifacts.
5. Record the commit hash, seed, runtime, simulation duration, final state fingerprint, and resource-ledger results.
6. Fail clearly when a simulation or validation fails.
7. Do not publish game builds or releases.
8. Do not automatically launch expensive year-long runs on every commit.
9. Avoid unnecessary concurrent runs or uncontrolled resource usage.

Determinism validation

Before relying on GitHub Actions results, compare a 10-day run against a local run using identical code, seed, and configuration.

Require matching state fingerprints and resource-ledger results.

If they differ, investigate the cause rather than assuming the environments are equivalent.

After validation, use GitHub Actions for unattended long-duration testing where practical.

3. Development priorities

Do not interrupt the currently running year-long simulations.

Continue Build 15 housing stabilization and the approved development work.

Implement and test the loft through the existing WIP and staging workflow.

The GitHub Actions workflow may be developed independently, provided it does not delay critical housing corrections.

Commit and push approved work to remote GitHub under the existing testing requirements.

No distributable game build or release without my explicit authorization.

Report the loft test results, GitHub Actions validation results, and final status of the currently running simulations.
