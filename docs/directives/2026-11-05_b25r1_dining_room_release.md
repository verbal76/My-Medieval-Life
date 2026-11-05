# Owner directive, 2026-11-05: B25R1 dining room release, fastest safe delivery

Saved as received (condensed formatting only).

---

B25R1 — DINING ROOM RELEASE: FASTEST SAFE DELIVERY

This is a FAMILY PLAYTEST, not a Steam release or public production launch. Our priority is the earliest possible playable Windows
package, followed by the remaining requested packages. Keep the existing frozen source F ("a9e9f6e"), validation requirements, naming
conventions, DEMO-01 preset, and established release workflow.

1. Finish the validation already running. Do not restart passing tests or duplicate campaigns. Investigate actual failures; do not
   bypass safety-critical checks. Do not wait for the 365-day campaign unless it reveals a critical issue. Reconcile the simulation
   baseline and obtain required approval. Verify P differs from F only in "sim_baseline.json".
2. Start packaging immediately after the required gates pass. No additional planning cycles, new features, workflow redesigns, or
   unrelated documentation delays. Use existing parallel GitHub Actions jobs. Do not serialize independent builds unnecessarily.
3. Prioritize Windows delivery. The full Windows game is the first priority. The Windows DEMO-01 package is the second priority.
   Android and Linux full packages follow, with their automatic demo variants. If Windows packages pass their established smoke tests
   before other platforms finish, make them downloadable immediately if the existing workflow permits it without risky modifications.
   Do not delay a ready Windows package merely to complete other platform uploads.
4. Public GitHub Release. Publish the established package names and release tag. Make the release easy to find and mark it Latest
   when appropriate. Verify assets are downloadable. No Steam uploads and no changes to repository visibility. No unnecessary
   additional testing beyond the established release gates.
5. Report measured times, not padded estimates. Report when each stage starts and finishes, the exact SHA and run IDs, and the first
   verified Windows download link.

If an existing workflow dependency prevents early Windows delivery, identify that dependency and its actual time cost. Do not rewrite
the workflow tonight merely to save a few minutes.

This is a dining room release. Get the verified game into our hands as quickly as safely possible.
