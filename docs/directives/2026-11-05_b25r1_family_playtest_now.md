# Owner directive, 2026-11-05: Build 25R1 family playtest now, final validation in parallel

Saved condensed (structure and every instruction kept; the owner's full text is in the session record). Supersedes the release-gate
ordering of `2026-11-05_b25r1_dining_room_release.md` for the family package only.

- Feature scope CLOSED. Two parallel tracks.
- TRACK A, family playtest now: source `wip/b25r1` `a9e9f6e` (or a newer integrated and verified-safe commit, with the reason); no
  unfinished experimental fixes; do not alter the frozen baseline; isolated build branch or worktree. Focused smoke checks, using
  existing tests: Windows launch; world generation from a seed; multiplayer join; shared world; player persistence; world
  persistence; save, exit, reopen, load; reconnect and resume; economic persistence (balances and a purchase survive save/reload).
  A check needing a real multiplayer session that cannot be automated is reported unverified with the smallest manual check. Build
  the complete Windows game as a ready-to-play ZIP, record SHA and build time, label "My Medieval Life — Build 25R1 Family
  Playtest", brief launch and multiplayer instructions, publish as a downloadable GitHub Release asset with known issues and
  unverified checks; then Android and Linux from the same baseline without delaying Windows.
- Blocks the playtest only: cannot launch or generate a world; multiplayer cannot share a world; shared-world sync broken; save/load
  fails or corrupts; coins, items or player state lost or duplicated on normal save/reload; a repeatable crash. A determinism
  mismatch alone, an unfinished 365-day campaign, unrelated regression failures are not blockers. Fresh playtest saves.
- Buyer 39: continue independently; establish whether the 10-coin difference is a differently ordered legitimate transaction, an
  accounting defect or another simulation problem; do not assume harmless or corrupting.
- TRACK B: do not cancel or restart running workflows (42141394672, 42141398779, 42141779390, 42124902114, 42144094135,
  42144097399); read artifacts and sim.log; keep defects, test defects, infrastructure failures, legitimate behaviour and unresolved
  findings distinct. Final candidate after f2pre (`8254089`, an early check): integrate verified corrections, confirm scope,
  multiplayer and persistence, full regression, simulation and determinism gates on the exact final SHA.
- Outcome A (defects): root cause, targeted fixes, update the family package if gameplay, multiplayer or persistence is affected.
  Outcome B (all pass): FREEZE BUILD 25 AUTOMATICALLY (final SHA, fixes included, integrity, gates, package matches source, record
  evidence, final tag and verified release artifacts, mark feature-complete and frozen); no further owner approval needed; never
  freeze with a gate failed or unverified.
- Reporting: counts not percentages, exact commits and timestamps, no speculative estimates, no unverified claims, no repeated
  requests for permission.
