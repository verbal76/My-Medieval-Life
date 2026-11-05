# Owner directive, 2026-11-03 (received 2026-11-02 21:24 EST): permanent development reporting standard, timestamps (REPORT-TS-01)

Saved verbatim.

---

PERMANENT DEVELOPMENT REPORTING STANDARD — TIMESTAMPS

Effective immediately, include a timestamp at the beginning of every development progress update, test report, commit report, and completion summary.

Required format:
"[YYYY-MM-DD HH:MM EST/EDT] — Project / Build / Status"

Requirements:

1. Use America/New_York time, automatically accounting for EST and EDT.
2. Obtain the actual current time from the system or execution environment. Never invent or estimate timestamps.
3. Timestamp the report when it is generated, not when the underlying work began.
4. For GitHub Actions runs, include actual workflow start and completion times when available.
5. When referencing earlier commits or tests, distinguish their recorded timestamps from the current reporting timestamp.
6. Continue using the existing work-package status and evidence reporting standards.
7. Record this convention in the repository's permanent Claude instructions so it survives conversation resets.

This is a reporting change only. Do not interrupt active tests, expand development scope, or trigger additional validation to implement it.

Apply immediately and continue working without requesting approval.
