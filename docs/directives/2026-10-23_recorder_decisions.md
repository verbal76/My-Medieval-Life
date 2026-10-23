# Owner decisions, 2026-10-23: flight recorder REC-D1 to REC-D4 and implementation instructions

Saved verbatim. Answers `docs/design/FLIGHT_RECORDER_DESIGN.md` section 12 (register REC-19).

---

Approved REC-D1 through REC-D4 with the following decisions:

REC-D1: Recorder available in development and private owner playtest builds, disabled by default. Do not include active recording in public releases at this stage.

REC-D2: When storage reaches its configured limit, stop recording, preserve all existing records, and explicitly mark the session incomplete. Never silently delete or overwrite evidence.

REC-D3: Record every meaningful executed interaction, decision, outcome, and state change throughout the active village, regardless of player involvement. Use hourly snapshots for continuous conditions such as hunger, movement, and work progress. Do not record every rendered frame or walking step. Snapshots must never substitute for actual interaction records.

REC-D4: Begin with balance auditing and instrumentation of existing central transaction paths. Do not rewrite approximately 150 currency mutation locations as part of Build 19. Flag unattributed changes and document coverage gaps. Centralize additional currency paths later only when justified by evidence.

Implementation priority: Preserve the Expansion 19 release schedule. Reuse XEXPL-01 and permanent person IDs. Implement the smallest shared recorder architecture that preserves complete event detail where instrumented and allows additional coverage without redesign.

Do not represent incomplete instrumentation as complete coverage.

Once the identity foundation is ready, proceed with the approved implementation on the appropriate development branch. Do not merge or publish without authorization.

Reuse existing valid test evidence. Run only targeted new tests for recorder behavior, deterministic equivalence, export integrity, and measured performance.

Keep the other expansion workers progressing independently wherever safe. Report genuine blockers and actual performance measurements, not speculative delays.
