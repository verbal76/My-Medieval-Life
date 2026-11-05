# Owner directive, 2026-11-05: B25R1 final package directive

Saved as received (condensed formatting only).

---

B25R1 — FINAL PACKAGE DIRECTIVE

Deliver four packages:

1. Full Android build
2. Full Windows build
3. Full Linux build
4. Windows PC demo

Naming and packaging

- Use the exact package naming conventions, directory structures, version labels, and release procedures established last night.
- Inspect the existing release documentation and previous packages to confirm those conventions. Do not invent new names or formats.
- Continue using the current My Medieval Life identity. No rebranding to My Folklore or Realm Life.
- Keep the Windows demo separate from the full Windows game.

Build integrity

- Frozen integration commit: "a9e9f6e".
- Complete the required validation and baseline reconciliation before releasing packages.
- If the approved baseline-only commit P is necessary, verify that its only change from F is "sim_baseline.json".
- All four packages must derive from the same verified release source.
- No additional features, economy changes, or unrelated merges.
- Do not introduce new demo functionality or restrictions without first checking the existing demo conventions and obtaining approval for any unresolved decision.

Execution

- Reuse the existing GitHub Actions packaging workflows.
- Build independent platform packages in parallel where supported.
- Verify all four artifacts exist, inspect the logs, and smoke-test what the established procedures require.
- Publish private draft artifacts using the established release conventions.
- Do not publish the demo publicly to Steam without explicit authorization.
- The 365-day campaign continues independently and blocks release only if it reveals a critical safety issue.

Reporting
Report the exact source SHA, workflow run IDs, artifact names, sizes, and validation results for each package. Identify any missing or failed package explicitly.

Priority is getting all four packages delivered without expanding scope or repeating unnecessary tests.
