# Proposed CLAUDE.md text (FLIGHT-REC-01)

For the lead to place in `CLAUDE.md` section 5 (after "Simulation monitoring"). Proposed wording, not yet in CLAUDE.md.

---

- **Flight recorder campaigns (owner, 2026-11-02, FLIGHT-REC-01, `docs/directives/2026-11-02_permanent_flight_recorder_simulation_system.md`;
  permanent standing authorization; `docs/release/flight_recorder/README.md`).**
  - **"Run flight recorder"** means, with no further question or approval: dispatch `.github/workflows/flight-recorder.yml` on
    the latest suitable integration commit (if a known, imminent fix makes it unsuitable, use the corrected commit) with the
    defaults (seeds `1,2`, `days` 365, `every` 10, `sim_args` empty = normal integrated play, `record` true, `segment_days` 100),
    or the seeds, days or scenario the owner names. Check first that no flight recorder run is still in progress
    (`gh run list --workflow flight-recorder.yml`); give the owner the run link at once; never wait for it, and continue
    development. It is independent of CI, long-sims, packaging and releases, and never blocks other work. Never cancel, restart
    or rerun a running or failed campaign before reading why it stopped (SIM-02).
  - **"What did the flight recorder find?"** means: take the latest completed run (`gh run list --workflow flight-recorder.yml`),
    read each seed's `summary.json` and `findings.md` (artifact `fr-seed<N>-results`; if downloads are blocked, the analysis job's
    log prints them), and the workbook for trends. Report, most important first: what happened (commit, days reached, stop reason
    per seed), what worked, what failed, which NPCs behaved strangely (with the finding ids, days and counts), which systems may be
    interfering, and what deserves investigation. CRITICAL findings are confirmed defects; HIGH and MEDIUM are suspicions with
    evidence: never call one a defect without investigating it, never change gameplay to suppress unusual behaviour, and keep
    WDR-022 (a village may fail; the simulation may not). Record confirmed defects in the register through the lead.

---

Section 2's layout table could also gain a row:

| `docs/release/flight_recorder/` | Flight recorder campaigns: how to run and review them, coverage audit | Yes |
