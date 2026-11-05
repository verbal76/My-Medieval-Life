# Owner directive, 2026-11-02: complete the current build before packaging (B25-CLOSE-01)

Received in session, verbatim:

> MY MEDIEVAL LIFE — COMPLETE CURRENT BUILD BEFORE PACKAGING
>
> Owner correction: Do NOT prepare or push a playtest release while known work belonging to the current build remains unfinished.
>
> Our objective is to COMPLETE the current build, not package an incomplete development snapshot.
>
> Work from the authoritative integration branch "wip/expansion20", last reported at "34e1041". Confirm its actual HEAD first.
>
> Use ONE active Claude worker and ONE authoritative code integration branch. Do not restart parallel development.
>
> Phase 1 — Establish build closure
>
> Audit the current build's requirements, owner decisions, known issues, unfinished work, and acceptance criteria.
>
> Classify every outstanding item as:
>
> - Required for this build and unfinished
> - Implemented but awaiting integration or verification
> - Investigated and legitimately closed
> - Explicitly assigned to a future build
>
> Do not silently defer an existing build requirement to make packaging easier.
>
> Report any scope ambiguity requiring an owner decision.
>
> Phase 2 — Finish existing work
>
> 1. Preserve and verify the integrated KI-HOME-DOOR repair.
> 2. Finish Farming Phase 2 using saved work at "710fce9". Carefully resolve its overlap with the home-door changes in "world.gd". Preserve both fixes.
> 3. Complete the missing farming test, save compatibility checks, and relevant suites.
> 4. Fix the confirmed cart-hitch behavior loop. A villager already holding a cart must not repeatedly attempt to hitch another.
> 5. Preserve the documented conclusions that excess wheat sales and player-directed contract cancellations are expected behavior.
>
> Do not expand the scope beyond existing build commitments and necessary defect repairs.
>
> Phase 3 — Integrated validation
>
> After the required work is integrated, freeze one exact source SHA.
>
> Reuse valid prior test evidence and run targeted tests for newly integrated changes and their interactions.
>
> Check home references, homelessness and nightly rest, farming, seed corn migration, cart ownership, save/load, and relevant economy integrity.
>
> Do not automatically run another 365-day campaign. Assess whether existing simulation evidence and targeted replays are sufficient for this build. Request owner approval before any new full-year campaign.
>
> Resolve genuine blockers before proceeding.
>
> Phase 4 — Build and release
>
> Only after the current build's acceptance criteria are satisfied:
>
> - Determine the next correct build number.
> - Package Android, Windows, and Linux from the same verified SHA.
> - Perform necessary package and startup smoke checks.
> - Upload all three packages and checksums to a PRIVATE GitHub draft release.
> - Verify that the actual draft assets are present.
>
> Never publicly publish or upload to Steam without separate authorization.
>
> Phase 5 — Final report
>
> Provide the completed requirement checklist, exact integrated SHA, tests and results, remaining known issues classified by build, package verification evidence, and private draft release link.
>
> If a required current-build item remains unfinished, STOP before packaging and explain the blocker.
>
> Do not call an incomplete build ready simply because its tests are green.
>
> When the release is complete, stop MML development again. Do not automatically begin the next build.
