# Missing and at-risk sources

Owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md` §6, DOC-RECON-01): "If an original
document is not accessible, record it as a missing source requiring recovery. Do not reconstruct its contents from
assumptions or declare its features unapproved merely because the file is absent."

How to use this file:
- Each entry says what is missing, who cites it, what the repository holds instead, and the action needed.
- The rest of each expansion's approved scope stands as recorded in the register and its directives.
- **At risk** means the only copy sits on an unmerged `wip/*` branch: it is not missing, but would be lost with that branch.

Search method (2026-10-31): `git log --all --diff-filter=A --name-only` over every ref fetched from `origin` (7,188 paths
ever added), plus listings of `origin/wip/roadmap-docs` (`e1e8236`) and `origin/wip/expansion21-preparation` (`8ac88f5`),
`docs/directives/` on staging, and the session's audit notes. Each expansion agent adds its own section below.

## Expansions 21-27

### Missing (recovery required)

**M-25-1. The original owner-supplied "Weather, Seasons & Disasters" design packet.**
- *Cited by:* the owner, 2026-10-31 §6 ("the original Weather, Seasons & Disasters … design packets").
- *What the repository holds:*
  - `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md`, written by the agent on 2026-10-23 at the owner's request
    ("documents for each expansion packet that I can download"), with the owner's words in its appendix;
  - its deleted predecessors `docs/design/EXPANSION25_WEATHER_DESIGN.md` (`f2688e1`..`27894a6`) and
    `EXPANSION25_WILD_WORLD_DESIGN.md` (`c64dd52`, deleted in `6c28fbc`), recoverable with `git show 6c28fbc^:<path>`;
  - the verbatim directive `docs/directives/2026-10-23_dynamic_weather_idea.md`.
- *Not found:* no owner-authored or externally developed version (docx, pdf or md) on any branch.
- *Action:* the owner supplies the original if one exists beyond the repository packet. Then compare it with WEATHER-01
  and the packet, and record any differences as decisions. Until then, the features in the original are **not**
  unapproved; they are unknown.

**M-26-1. The original owner-supplied "Creatures & Heroes" design packet.**
- *Cited by:* the owner, 2026-10-31 §6.
- *What the repository holds:*
  - the agent packet `docs/design/EXPANSION26_CREATURES_AND_HEROES.md` (2026-10-23), with the owner's words appended;
  - the Wild World draft (history, as above);
  - `docs/directives/2026-10-23_monsters_bounties_companions_idea.md` and `2026-10-23_animal_domestication_idea.md`.
- *Not found:* no owner-authored version on any branch.
- *Action:* as M-25-1.

**M-22-1 (conditional). A separate Settlement Advancement *Phase 2* specification.**
- *What the repository holds:* the owner's Expansion 18 specification,
  `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf` (6 pages) and `.txt`, on
  staging. The kickoff directive (`2026-10-23_expansions_22_23_kickoff.md`) names it as "the existing standalone
  Settlement Advancement & Regional Economy specification … the primary authority".
- *Not found:* no further Phase 2 document on any branch.
- *Action:* only if the owner holds one, recover it. Otherwise this entry closes as "none exists".

**M-27-1. "Prior owner world exploration and magic discussions".**
- *Cited by:* the master roadmap's Exploration starter, as the source of "a vast explorable overworld, broader county,
  world consequences and learnable, rule-based magic".
- *Not found:* no dedicated directive. The wording traces to the historical game-design material
  (`docs/DESIGN_GAP_ASSESSMENT.md` and the Game Designer import). The old-design magic and Morris atlas parts are parked
  by OD-17 / D32 (2026-10-27).
- *Action:* none required unless the owner wants the original discussion recovered. The parked status stands.

**M-X-1. `MY_MEDIEVAL_LIFE_39_DECISIONS_HANDOFF_PACKAGE.zip`.**
- *Cited by:* `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md`. That directive is the provenance
  of D19-D30, which covers Q-POL-1..9, P21-RESIDENCY, P21-STRUCTURE, E22-OD-03..05 and E23-OD-01.
- *Not found:* never committed. The directive says "The original package has not been applied to GitHub by this
  document."
- *Impact:* low. The owner's current-first directive replaces the package as the controlling text.
- *Action:* recover only for provenance.

### At risk (single copy on an unmerged branch)

**R-ROADMAP. The owner's Master Expansion Roadmap and Expansion Documentation Pack (2026-10-21).**
- *Location:* `origin/wip/roadmap-docs` `e1e8236` (3 commits, merged nowhere): `docs/roadmap/source/*.docx` and text
  extractions.
- *Contents:* `Master_Expansion_Roadmap`, `Documentation_Index`, `21_Politics`, `22_Bandits` (now Expansion 23),
  `23_Legacy` (now Expansion 24), `Exploration_Combat` (now Expansion 27), `Multiplayer`.
- *What staging holds:* only the roadmap's text (`docs/directives/2026-10-21_master_expansion_roadmap.md`).
- *Why it matters:* the starters are the specifications that the 2026-10-24 directive (Legacy, "the approved
  specification") and ROAD-Q1 (27, "Preserve the complete existing specification") point to.
- *Action:* bring them into the consolidated repository in Build 26, keeping their file names and old numbers, under a
  historical/numbering banner.

**R-X21. Expansion 21 phase 1.**
- *Location:* `origin/wip/expansion21-preparation` `8ac88f5`, on Build 18.
- *Contents:* P21-00 audit, P21-01 civic records (code and tests), P21-02 decision map, `docs/expansion21/*`.
- *Action:* preserve. Where it is brought forward (Build 26 recovery or Build 27) is an open owner question
  (`EXPANSION_21.md`).

## Other expansions, multiplayer and standalone systems

Recorded so far in the per-expansion files (added by their agents; to be gathered here):
- **Expansion 17:** none (`EXPANSION_17.md` §10).
- **Expansion 18:** the owner's three research papers (`TenureExperience.pdf`, `9501lync.pdf`, `c8781.pdf`). They were
  never committed; their findings are kept in `docs/expansion18/RESEARCH_DIGEST.md`@`wip/expansion20` (`EXPANSION_18.md`
  §10).
- **Expansion 19:** the owner's 2026-10-17 "living-society" message (#47) behind FR-11 and FR-09, summarized only
  (`EXPANSION_19.md` §10). `B19_CALIBRATION.md` was never written (an agent document, not an owner source).
- **Expansion 20:** the Living Economy docx is present, not missing. These were never written:
  - `B19_CALIBRATION.md`;
  - the X20-B24-REVIEW report;
  - the X20-B24-REMED report.

  `TRADER_SUSTAINABILITY_ANALYSIS.md` exists only on `wip/x20-trader-inv` (`EXPANSION_20.md` §11).
- **Multiplayer:** none (`MULTIPLAYER.md`).
- **Historical and referenced documents:** `HISTORICAL_DOCUMENTS.md` §5. It lists the Game Designer files and the owner's
  original over-the-air update answers, among others.
