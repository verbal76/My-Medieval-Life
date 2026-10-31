# Owner decisions pending: consolidated report (2026-10-31)

Prepared at the owner's request of 2026-10-31 (`docs/directives/2026-10-31_doc_recon_review_decisions.md` s.7: "Prepare one
consolidated owner-decision report that includes each unresolved question, existing evidence, available options,
dependencies, and your recommendation clearly marked as a recommendation").

How to read it:
- **Nothing here is a decision.** Every "Recommendation (agent, not a decision)" is the agent's view only. No default has
  been chosen or applied, and every question stays open in the register until the owner answers it.
- **Sources:** the register `docs/requirements/requirements.json` (records of kind `decision` with disposition OPEN or
  PROVISIONAL, and records with approval OWNER DECISION REQUIRED), the "Outstanding owner decisions" sections of
  `docs/expansions/*.md`, `docs/requirements/views/DECISIONS.md` and the dated owner directives in `docs/directives/`.
- **Code evidence** is read from `origin/wip/expansion20` at `ad281dc` (2026-10-31, the commit under Build 25 validation),
  shown as "X". Nothing on that branch was changed.
- **Questions already answered** by a later owner decision are not asked again; they are listed at the end with the
  answering source. Where an answer is partial, the block below asks only the remaining part.
- **Order:** by area. Within each area, what blocks the Build 25 freeze comes first, then Build 26 planning, then later
  expansions (in the approved order 20 → 21 → 23 → 22 → 24 → 25 → 26 → 27).
- **The rebuilt design package.** The owner's revised master package (prepared with ChatGPT; DOC-AUTH-01, 2026-10-31) will
  become the authoritative design once the owner approves it. Many later-expansion questions below could be settled
  inside that package instead of one by one.

---

## Summary

| Ref | ID | Question (short) | Blocks | Recommendation (short, agent) |
|---|---|---|---|---|
| **Expansion 19 / judgment** | | | | |
| 1.1 | X19-SWITCHES-D1 | Switch on aspirations (with job choice) and the witness-report hook in normal play? | Normal-play behaviour after Build 25; Build 26 planning | Keep both off through Build 25 and Build 26; decide later, with their own validation |
| 1.2 | ID-D3 | Does an existing current-commit baseline count as the required identity audit, or is a dedicated audit needed? | Promoting the identity-gate baseline | Dedicated audit on the frozen Build 25 SHA in Build 26, reusing existing evidence |
| **Expansion 20 / economy** | | | | |
| 2.1 | X20-MERGED-VALIDATION (with SJD-H Gate H) | Accept the year-long validation results and freeze Build 25? | **Build 25 freeze; all of Build 26** | No recommendation until the consolidated report exists |
| 2.2 | X20-SERVICES-SCOPE | Do service contracts CON-03..CON-08 belong to the Expansion 20 remainder? | Build 26 planning scope | Keep them unscheduled; include only in Build 26 dependency analysis |
| 2.3 | ARMOR-CATALOG-D1 | Armour numbers, buffs (fireball buff), materials A or B, cloth headgear | Ends a PROVISIONAL state; nothing blocked | Owner balance and art review when convenient; materials B as built |
| **Multiplayer** | | | | |
| — | — | No open owner questions | — | — |
| **Expansion 21 politics** | | | | |
| 4.1 | P21-OFFICES-Q1 | Terms, succession, dismissal and vacancy for offices other than the mayor | Expansion 21 design before Build 27 | Answer in the rebuilt package, office by office |
| 4.2 | (no record) | Office powers, election formulas, tax rates, punishments, equality fallback, campaigns, courts | Expansion 21 implementation (Build 27) | Settle in the rebuilt package before Build 27 authorization |
| **Expansions 22-27 (Wild World = 25 + 26)** | | | | |
| 5.1 | E23 (no record) | Approve the faction architecture; leadership challenge, jurisdiction, faction numbers | Expansion 23 | Settle in the rebuilt package; refresh the stale audit first |
| 5.2 | E22 (no record) | Approve the Expansion 22 architecture after the E22-P1 audit | Expansion 22 | Same; design together with Expansion 27 world scale |
| 5.3 | E24 (no record) | Boundary between the Expansion 19/20 foundations and Expansion 24 | Expansion 24 | Settle in the rebuilt package |
| 5.4 | E25-OD-07 | Confirm the 2026-10-24 order as the final answer on when to build 25 | Closing a PROVISIONAL record | Confirm |
| 5.5 | E26-OD-09 | May 26-A..C and 26-F start before Expansion 25? | Wild World sequencing | Decide when the Wild World is authorized |
| 5.6 | E25-OD-03 | Wells as public works for bucket lines? | Expansion 25 fire response | Packet: one or two wells the reeve can build |
| 5.7 | E25-OD-06 | May the reeve keep a disaster reserve? | Expansion 25 treasury | Packet: yes, within the existing reserve rule |
| 5.8 | E25-OD-08 | How long is a swept-away person missing? | Expansion 25 floods | Packet: 1-3 game days, seeded |
| 5.9 | E25-OD-09 | Stone versus wood protection; insurance? | Expansion 25 damage (on Expansion 22's condition system) | Packet: stone resists better; no insurance |
| 5.10 | E26-OD-01 | Foxes in pens, or companions only? (companion part already answered) | Expansion 26 pets | Packet: pens are for pets only |
| 5.11 | E26-OD-02 | Respawn for spiders and bosses (skeletons already 3 days) | Expansion 26 monsters | Packet: spiders like skeletons; bosses a year, some never |
| 5.12 | E26-OD-03 | How often a monster attacks the village | Expansion 26 defence | Packet: once in several game years, one at a time |
| 5.13 | E26-OD-04 | Bounties when the treasury is empty | Expansion 26 bounties | Packet: no bounty without coins; villagers may pool |
| 5.14 | E26-OD-05 | Bounty price band | Expansion 26 bounties | Packet: reeve sets within an owner band |
| 5.15 | E26-OD-06 | Monster goods recipes | Expansion 26 market | Packet: one special item per boss, bones and rusty gear |
| 5.16 | E26-OD-07 | Companion combat numbers | Expansion 26 companions | Packet: wolf as a wild wolf; fox weaker, quicker |
| 5.17 | E26-OD-08 | Do guard dogs fight in village defence? | Expansion 26 defence | Packet: yes, in the guards' line |
| 5.18 | E27 (no record) | Scope decisions: castles, dungeons, large world, magic | Expansion 27 | Settle in the rebuilt package, with 5.2 |
| **Standalone systems** | | | | |
| 6.1 | WIKI-B17 | Close the Build 17 wiki reconciliation as covered, or do a Build-17-only review? | Register clean-up in Build 26 | Close as covered by REL18-WIKI and WIKI-01 |
| 6.2 | REL18-DEVICE, REL18-OWNER | Keep the Build 18 release gates open, or close as not applicable? | Register clean-up | Close both as not applicable |
| 6.3 | DGA-D3 | Confirm "superseded by MP-D5" | Register clean-up | Confirm |
| 6.4 | FR-11 | Is personality, prestige and migration fully covered by later records? | Register clean-up | Confirm covered, unless something is missing |
| 6.5 | WDR-003-C | Approve the Rule 003 compliance work (a purpose for every recipe) like the other rule records? | Rule 003 compliance | Approve, as documentation work in Build 26 |
| 6.6 | REC-003 | Confirm Android target API 36 as a standing requirement | Platform record | Confirm, under D36f maintenance |
| 6.7 | FARM-YIELD-D1 | Wheat yield per cell; switch on shared and seasonal farming? | FSE-12, FSE-13, FARM-06, FARM-08 (4 PARTIAL records) | Keep off; re-measure on current code before deciding |
| 6.8 | JUICE-J1 | Approve phase J1 quick wins, and in which build? | All game-feel work | After Build 26 |
| 6.9 | JUICE-JD5 | Which village notes appear in the corner log; a filter? | J1 notification split | Split gains from village notes, compact size kept |
| 6.10 | JUICE-JD3 | How often villagers show what they are doing in bubbles | Phase J5 | Only near the player, on a task change, throttled |
| 6.11 | JUICE-JD4 | Screen shake and haptics: allowed, on which events, default? | Phase J1/J2 effects | Allow on a few rare events under "Reduce effects" |
| 6.12 | JUICE-JD2 | Should the picture darken at night? | Phase J4; overlaps Expansion 25 | Decide with the Wild World design |
| 6.13 | REC-014 | Does the 2026-10-18 "revisit the foundations" intent still stand? | Nothing active | Close as fulfilled by FSE and the Living Economy, if the owner agrees |
| 6.14 | REC-008 | Near/far simulation tiers: approve, and when? | Larger world or multiplayer scale | Place with Expansion 22 and 27 world design |
| 6.15 | REC-010 (remainder) | Is a tech or research tree wanted at all? | Nothing | No recommendation |
| 6.16 | (group) | Build placement of approved design-only systems | Their implementation | Place through the rebuilt package and Build 27+ planning |

Counts: Expansion 19: 2; Expansion 20: 3; multiplayer: 0; Expansion 21: 2; Expansions 22-27: 18; standalone: 16. **Total 41.**

---

## 1. Expansion 19 / judgment

SJD-H Gate H (the owner's review of the judgment results) is part of the Build 25 validation review: see 2.1.

### 1.1 X19-SWITCHES-D1 — integrated-but-off Build 19 recovery features
- **Question:** Should the R5 aspirations (with job choice) and the R2 judgment-weighted witness-report hook be switched on in
  normal play, and if so, when?
- **Why it matters / blocks:** These change normal-play behaviour and the simulation baseline. They sit behind the Build 25
  freeze and the SJD-H review. Nothing else is blocked while they stay off.
- **Evidence:**
  - X `game/data/judgment.json`: `aspiration.enabled false`; `decision.integration.report false`,
    `job_choice false` (the other 15 integration flags are true). The file's note: "OFF (enabled false) until validation and
    owner review"; every aspiration number is a "PROVISIONAL AGENT VALUE".
  - Content of aspirations: approved and final (`2026-10-27_final_aspirations_decisions.md`).
  - Already answered in part: "Do not activate aspirations, career choice, witness-reporting decisions, or the Living
    Economy model merely because related code has been implemented" (`2026-10-27_complete_expansion20_first.md`), and
    "Aspirations feature off until separately reviewed" (`2026-10-27_39_decisions_current_first_reconciliation.md` s.2).
  - The 2026-10-31 C1 decision authorizes auditing and correcting judgment integration
    (`2026-10-31_sjdh_decisions_le05_authorization.md`). It does not switch these two on.
- **Options (from the record):** on; off; or on after a named validation (G0 plus long-run evidence for the changed
  baseline, per SIM-01), chosen separately for each switch.
- **Recommendation (agent, not a decision):** keep both off through Build 25 and Build 26. Decide after the SJD-H review,
  each switch with its own validation. Switching either on would change the baseline that Build 25 is being frozen on.

### 1.2 ID-D3 — identity-gate baseline (PROVISIONAL)
- **Question:** Does one of the determinism baselines already rewritten on current commits count as the required
  same-commit conservation, determinism and first-divergence audit, or should a dedicated audit be run?
- **Why it matters / blocks:** Until it is settled, no identity-gate baseline can be promoted.
- **Evidence:**
  - Owner D38 (2026-10-27): answer A, conditional; promote "only after same-commit current-branch
    conservation/determinism/first-divergence audit". Ruling 2026-10-28: the condition stands and "the identity design is not
    reopened" (so the per-person stored seed alternative is off the table).
  - The old candidate `docs/design/IDENTITY_GATE_CANDIDATE.json` (code `45d68d3`) is not blessed. Baselines rewritten since:
    `2685a26` (Build 19), `465a6a2`, `6ee13c7`, `ad281dc` (Expansion 20) (`docs/expansions/EXPANSION_19.md` s.6).
- **Options:** (a) accept an existing current-commit baseline as the audit; (b) run a dedicated audit on a named commit.
- **Recommendation (agent, not a decision):** (b), on the frozen Build 25 SHA during Build 26. Reuse the `ad281dc`
  conservation and determinism evidence and add only the first-divergence comparison, which none of the rewrites recorded.

---

## 2. Expansion 20 / economy

### 2.1 X20-MERGED-VALIDATION (with SJD-H Gate H) — Build 25 freeze review
- **Question:** After the three year-long runs finish, does the owner accept the results and freeze Build 25 at the
  validated SHA?
- **Why it matters / blocks:** **Everything after it.** Build 26 integration may not begin until Build 25 is validated and
  frozen (2026-10-31 s.1). It also holds SJD-H Gate H and, through Q-POL-7, Expansion 21's real votes.
- **Evidence:**
  - Approved runs (`2026-10-31_x20_merged_validation_decisions.md`; `2026-10-31_x20_yearlong_validation_release_readiness.md`):
    `ad281dc`, Actions 41233948995 (normal, seeds 1 and 2) and 41233970504 (economy on, seed 1).
  - Register: IN DEVELOPMENT, results pending. The owner asked for a consolidated report with findings classed A (release
    blockers), B (significant defects) and C (non-blocking).
- **Options (from the directive):** accept and freeze; or first order the smallest justified correction for any A or B
  finding.
- **Recommendation (agent, not a decision):** no recommendation until the consolidated report exists.

### 2.2 X20-SERVICES-SCOPE — service contracts CON-03..CON-08
- **Question:** Does X20-SCOPE's "negotiated wages and service contracts behind their switches" include the approved service
  contracts CON-03..CON-08, or do they stay unscheduled?
- **Why it matters / blocks:** It sets the scope of Build 26 planning for the Expansion 20 remainder, and what counts as
  "Expansion 20 complete".
- **Evidence:**
  - CON-03..08 (CON02-S-1..6 answers, 2026-10-21): approved as directions; target "owner decision".
  - X20-SCOPE (`2026-10-27_x20_scope_and_free_migration.md`): "Negotiated wages and service contracts, respecting their
    established feature switches and baseline behavior".
  - X `economy.json`: `enabled false`, `market.negotiated_wages false`, `market.services false`. The LE-04 note: "negotiated_wages
    and services (OD-LE-03 D02, broader part) are off". Nothing reads `services`.
  - 2026-10-31 s.1 places only LE-07, EMP-PERM-01, the LE-05 remainder and activation preparation in Build 26, and for
    planning only.
  - 2026-10-30 (`x20_trader_pay_final_decision.md`): when wages and service contracts are ready, present compensation
    alternatives first.
- **Options (from the record):** (a) included in the Expansion 20 remainder; (b) stay unscheduled.
- **Recommendation (agent, not a decision):** (b) for now, with CON-03..08 listed in Build 26's dependency analysis. The
  owner's Build 26 list does not name them, and six contract kinds would roughly double the remainder.

### 2.3 ARMOR-CATALOG-D1 — armour numbers and materials (PROVISIONAL)
- **Question:** Approve, or change, the armour values, the buffs (including the fireball-damage buff), the material choice
  (A or B), and whether the cloth headgear is included.
- **Why it matters / blocks:** Nothing is blocked. The values in the game stay provisional until the owner reviews them.
- **Evidence:**
  - D16 (2026-10-27, conditional) and ruling 2026-10-28: Build 22's four categories, items and visuals stand. Numbers, buffs
    and materials stay PROVISIONAL. Not approved by implication: "exact proposed fireball stats, cloth hats or material
    substitution".
  - X `items.json` carries `fire_damage` on 16 entries.
  - Proposal: `docs/design/ARMOUR_CATALOGUE_PROPOSAL.md` s.5.
- **Options (from the proposal):**
  - Materials: A (add steel, tin, silk and fur properly, with sources and recipes) or B (existing materials only, as built
    for Build 22).
  - Example values: approve, or change any.
  - Fireball buff: keep or drop.
  - Cloth headgear: include (sold by the tailor) or not.
- **Recommendation (agent, not a decision):** a single balance-and-art review when convenient. Keep B as built; A would add
  new goods to the economy's material web during a freeze.

---

## 3. Multiplayer

No open owner questions. MP-D1..D8, MP-Q-PLAYER-CHILDREN and MP-INTERACT-Q2 are approved. MP-INTERACT-Q1 is deferred.
MP-INET-RELAY is option A (free methods only). Paid networking returns to the owner only with the device-matrix report
(`docs/expansions/MULTIPLAYER.md` s.6). See the answered table.

---

## 4. Expansion 21 politics

Build 27 is the intended start (X21-RECOVERY-D1, answered). The mayor's rule is fixed: a four-year term ends early only
through death or permanent absence.

### 4.1 P21-OFFICES-Q1 — offices other than the mayor
- **Question:** For each office the Expansion 21 design names other than the mayor: what is its term, how is it succeeded,
  can its holder be dismissed, and how is a vacancy filled?
- **Why it matters / blocks:** It must be settled before Expansion 21 is implemented (Build 27). The owner said the mayor's
  rule is not to be extended automatically.
- **Evidence:** `2026-10-31_doc_recon_review_decisions.md` s.5: "Record their terms, succession, dismissal, and vacancy rules as
  unresolved design questions. Do not invent policies."
- **Options:** to be defined by the owner.
- **Recommendation (agent, not a decision):** answer office by office in the rebuilt Expansion 21 document, before Build 27
  authorization.

### 4.2 Expansion 21 unresolved mechanics (no register record)
- **Question:** What are the final rules for office powers, election formulas, tax rates and punishments, the explicit
  equality fallback (D22), campaign rules and courts?
- **Why it matters / blocks:** The 2026-10-23 politics directive says these are not built "without owner approval". The
  `[FUTURE]` answers give direction, not final rules. This blocks Expansion 21 implementation.
- **Evidence:** `docs/expansions/EXPANSION_21.md` "Outstanding owner decisions" item 3. Q-POL-5 (D22): "runoff, then service
  tenure, then age"; the "deterministic equality fallback must be explicit before final implementation".
- **Options:** to be defined by the owner.
- **Recommendation (agent, not a decision):** settle them in the rebuilt package before Build 27 is authorized, and register
  each as its own decision record so none is lost.

---

## 5. Expansions 22-27 (Wild World: 25 and 26 designed together)

None of 22-27 is authorized for implementation (2026-10-30; 2026-10-31). 25 and 26 are one "Wild World" design scope with
two expansion numbers. Listed in roadmap order: 23, 22, 24, then 25/26, then 27.

### 5.1 Expansion 23 — faction architecture and open detail (no register record)
- **Question:** Does the owner approve the proposed faction architecture from the BAN-A audit? What are the rules for
  leadership challenges, jurisdiction and faction numbers?
- **Why it matters / blocks:** Expansion 23 is next after 21.
- **Evidence:**
  - Audit: `docs/design/EXPANSIONS_22_23_AUDIT.md` s.4, written against Build 18 and partly stale
    (`docs/expansions/EXPANSION_23.md`).
  - E23-OD-01 gives `[FUTURE]` direction only. "One faction to start" is a proposal, not approved.
- **Options:** approve the audit's architecture or ask for changes. The detail rules are to be defined by the owner.
- **Recommendation (agent, not a decision):** settle in the rebuilt package. Refresh the stale audit rows against current
  code first.

### 5.2 Expansion 22 — architecture approval (no register record)
- **Question:** Having the E22-P1 audit, does the owner approve the Expansion 22 architecture?
- **Why it matters / blocks:** The owner required this before any implementation: "Do not begin implementation until we review
  the audit and approve the architecture" (`2026-10-23_expansions_22_23_kickoff.md`). It also holds the placement of SET-E's
  successor and SET-D-MULTIGEN (Expansion 18 file).
- **Evidence:** E22-P1 is done (`docs/design/EXPANSIONS_22_23_AUDIT.md` s.1-3, 5-6). E22-OD-01 and E22-OD-02 are approved as
  design only.
- **Options:** approve or ask for changes.
- **Recommendation (agent, not a decision):** settle in the rebuilt package, and design continuous geography (E22-OD-02)
  together with Expansion 27's map scale (WORLD-A), as `EXPANSION_27.md` notes.

### 5.3 Expansion 24 — foundations boundary (no register record)
- **Question:** Where is the line between what the Expansion 19/20 foundations already provide and what Expansion 24
  (Generational Legacy) adds?
- **Why it matters / blocks:** It prevents rebuilding work that already exists (GM-01 landed in the Expansion 20 line).
- **Evidence:** the starter's open item "Number 23 and final boundary need approval". The number is settled as 24
  (`docs/expansions/EXPANSION_24.md`).
- **Options:** to be defined by the owner.
- **Recommendation (agent, not a decision):** settle in the rebuilt package.

### 5.4 E25-OD-07 — when to build Expansion 25 (PROVISIONAL; remaining part only)
- **Question:** Does the owner confirm that the 2026-10-24 order (20 → 21 → 23 → 22 → 24 → 25 → 26 → 27) is the final answer,
  so the record can close?
- **Why it matters / blocks:** It only closes a PROVISIONAL record. Implementation authorization stays separate.
- **Evidence:** `2026-10-24_owner_roadmap_question_decisions.md`; restated as a known example on 2026-10-31
  (`2026-10-31_documentation_reconciliation.md` s.3).
- **Options:** confirm; or name another order.
- **Recommendation (agent, not a decision):** confirm. The owner has restated the order twice since.

### 5.5 E26-OD-09 — early Expansion 26 phases (remaining part only)
- **Question:** When the Wild World is authorized, may phases 26-A (taming and pets), 26-B (pens and companions), 26-C
  (monsters) and 26-F (bounties and hunters) start before Expansion 25?
- **Why it matters / blocks:** Sequencing inside the Wild World scope. The order "26 after 25" is already answered (2026-10-24).
- **Evidence:** `docs/design/EXPANSION26_CREATURES_AND_HEROES.md` s.4: "Phases A to C and F do not need Expansion 25".
- **Options (from the packet):** keep all of 26 after 25; or allow A-C and F earlier.
- **Recommendation (agent, not a decision):** decide when the Wild World is authorized. Nothing gains from deciding it now.

### 5.6 E25-OD-03 — wells for bucket lines
- **Question:** Should one or two wells be public works the reeve can build, so bucket lines can work away from the river?
- **Why it matters / blocks:** Expansion 25 firefighting (bucket lines were answered on 2026-10-23).
- **Evidence:** X `resources.json`: the well is "a station … It gives nothing: the game has no water item".
- **Options (from the packet):** adopt the packet's wells; or not (bucket lines from the river only).
- **Recommendation (agent, not a decision):** the packet's proposal. It reuses the existing well and public-works paths.

### 5.7 E25-OD-06 — disaster reserve
- **Question:** May the reeve keep a disaster reserve in the treasury?
- **Why it matters / blocks:** Expansion 25 recovery funding (rebuilding was answered as "owner with village aid").
- **Evidence:** the existing reserve rule (OD-19, `2026-10-20_od19_dynamic_reserves.md`). WDR-022: no hidden rescue.
- **Options (from the packet):** yes, inside the existing reserve rule, no new money; or no.
- **Recommendation (agent, not a decision):** yes, as the packet proposes. It creates no money and fits WDR-022.

### 5.8 E25-OD-08 — how long a swept-away person is missing
- **Question:** How long is a person swept away by a flood missing before their fate is known?
- **Why it matters / blocks:** Expansion 25 floods ("mixed fates" was answered on 2026-10-23).
- **Evidence:** packet `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md` s.6. The 8-day calendar year (OD-21) makes one
  game day several calendar weeks.
- **Options:** the packet's 1 to 3 game days by a seeded draw; or another span set by the owner.
- **Recommendation (agent, not a decision):** the packet's 1-3 days, seeded (deterministic).

### 5.9 E25-OD-09 — stone versus wood; insurance
- **Question:** Do stone buildings resist fire and wind better than wood, and is there any insurance or protection?
- **Why it matters / blocks:** Expansion 25 damage. It must reuse Expansion 22's building-condition system (ROAD-Q4,
  2026-10-24), so the answer also shapes Expansion 22.
- **Evidence:** packet s.6. ROAD-Q4: "Design one extensible system rather than separate damage models."
- **Options (from the packet):** stone resists better and no insurance; or other combinations set by the owner.
- **Recommendation (agent, not a decision):** the packet's proposal, defined inside Expansion 22's condition system.

### 5.10 E26-OD-01 — foxes (remaining part only)
- **Question:** Tame foxes can already be companions; may they also be kept in pens like other tamed animals, or are pens
  for other pets only?
- **Why it matters / blocks:** Expansion 26 phases A-B.
- **Evidence:** owner 2026-10-23: "You should be able to pick a pet fox or a pet wolf as a companion and they should follow you
  on missions and defend and Hunt things for you" (`2026-10-23_monsters_bounties_companions_idea.md`). That answers the
  companion part. The packet adds "only their pen use is pets-only".
- **Options:** as the packet says; or foxes kept in pens as well.
- **Recommendation (agent, not a decision):** as the packet says. A companion fox needs no pen.

### 5.11 E26-OD-02 — monster respawn (remaining part only)
- **Question:** How do spiders and bosses respawn? Skeletons are already approved at 3 days (B14-09).
- **Why it matters / blocks:** Expansion 26 monsters, and Expansion 27's placement of them (ROAD-Q3).
- **Evidence:** B14-09 owner wording: "3-day respawn". The boss roster is kept as design scope (2026-10-31 s.3).
- **Options (from the packet):** spiders like skeletons; a killed boss away at least a game year, some (the dragon) never in
  the same lair; or other rules set by the owner.
- **Recommendation (agent, not a decision):** the packet's proposal.

### 5.12 E26-OD-03 — how often monsters attack the village
- **Question:** How often may a monster attack the village?
- **Why it matters / blocks:** Expansion 26 village defence.
- **Evidence:** the owner's words: "attack The villages every now and then which would be rare" (2026-10-23).
- **Options (from the packet):** about once in several game years, more when lairs are near and the guard is weak, never more
  than one at a time; or another rate set by the owner.
- **Recommendation (agent, not a decision):** the packet's proposal. It matches "rare".

### 5.13 E26-OD-04 — bounties when the treasury is empty
- **Question:** What happens to bounties when the treasury has no coins?
- **Why it matters / blocks:** Expansion 26 bounties. The reeve's bounties come "from the treasury" (owner, 2026-10-23).
- **Evidence:** WDR-022 (no hidden rescue); every transfer is real and conserved.
- **Options (from the packet):** no bounty without the coins, and villagers may pool coins for one; or other rules set by the
  owner.
- **Recommendation (agent, not a decision):** the packet's proposal. It creates no money.

### 5.14 E26-OD-05 — bounty prices
- **Question:** How are bounty prices set?
- **Why it matters / blocks:** Expansion 26 bounties and the economy.
- **Evidence:** packet s.5.
- **Options (from the packet):** set by the reeve from the danger and the treasury, within an owner-approved band (proposal:
  20-60 coins for monsters, 150-400 for bosses); or another band.
- **Recommendation (agent, not a decision):** the reeve-within-a-band approach. Check the band against Expansion 20's
  validated coin levels before approving numbers.

### 5.15 E26-OD-06 — monster goods recipes
- **Question:** What does each monster give, and what is made from it?
- **Why it matters / blocks:** The Expansion 26 monster goods market (approved 2026-10-23) and World Design Rule 003.
- **Evidence:** packet s.5. Bosses kept as design scope (2026-10-31 s.3).
- **Options (from the packet):** one special item per boss (crab-shell shield, Buwaya-hide armour, yeti-fur cloak,
  minotaur-horn tool, necromancer's bone-dust medicine, dragon-scale armour), plus bones and rusty gear from skeletons; or
  other recipes.
- **Recommendation (agent, not a decision):** the packet's list, entered through `game/data/resources.json` when authorized.

### 5.16 E26-OD-07 — companion combat numbers
- **Question:** How strong are companion wolves and foxes, and how do they heal?
- **Why it matters / blocks:** Expansion 26 companions.
- **Evidence:** packet s.5.
- **Options (from the packet):** a wolf about as strong as a wild wolf, a fox weaker but quicker, both heal with rest and
  food; or other values.
- **Recommendation (agent, not a decision):** the packet's proposal. It reuses existing wildlife numbers.

### 5.17 E26-OD-08 — guard dogs in village defence
- **Question:** Do villagers' pets or guard dogs fight when the village is attacked?
- **Why it matters / blocks:** Expansion 26 defence ("Guards, then volunteers", answered 2026-10-23).
- **Evidence:** packet s.5.
- **Options (from the packet):** guard dogs join the guards' line; or pets and dogs stay out of fights.
- **Recommendation (agent, not a decision):** the packet's proposal.

### 5.18 Expansion 27 — scope decisions (no register record)
- **Question:** How far should castles, dungeons, large-world implementation and magic beyond the Fireball go in
  Expansion 27?
- **Why it matters / blocks:** The specification itself requires separate scope decisions for these.
- **Evidence:** `docs/expansions/EXPANSION_27.md`. Magic is parked beyond the Fireball (D32i, 2026-10-27). REC-006 (castles,
  dungeons, caves) is DEFERRED.
- **Options:** to be defined by the owner.
- **Recommendation (agent, not a decision):** settle in the rebuilt package, together with 5.2.

---

## 6. Standalone systems

### 6.1 WIKI-B17 — Build 17 wiki reconciliation
- **Question:** May this record close as covered, or does the owner want a Build-17-only wiki review?
- **Why it matters / blocks:** Register accuracy only. No feature is blocked.
- **Evidence:**
  - `0147066` and `3dcd583` closed every known gap; `wiki_test` passed.
  - The register says "what remains is unrecorded".
  - The Build 18 gate REL18-WIKI (implemented) covered Build 17 mechanics, and the wiki has been revised in every build since
    under WIKI-01.
- **Options:** close as complete; or a Build-17-only review.
- **Recommendation (agent, not a decision):** close as complete, citing REL18-WIKI and WIKI-01.

### 6.2 REL18-DEVICE and REL18-OWNER — Build 18 release gates
- **Question:** Keep these two Build 18 gates open, or close them as not applicable?
- **Why it matters / blocks:** Nothing is blocked. They keep Build 18 "not ready" in the views.
- **Evidence:**
  - Build 18 is frozen and superseded by Builds 19-24, and was released only as a private draft.
  - Owner 2026-10-24: "My personal playtesting is NOT a prerequisite for continuing development"
    (`2026-10-24_owner_start_multiplayer_now.md`).
  - Device needs are kept on each feature record's `playtest` field.
- **Options:** keep open; or close as not applicable.
- **Recommendation (agent, not a decision):** close both as not applicable. Device checks stay on the feature records.

### 6.3 DGA-D3 — confirm supersession
- **Question:** Does the owner confirm that the historical proposal "Connectivity with no server" is superseded by MP-D5
  (free methods first, 2026-10-24), with MP-INET-RELAY option A (2026-10-30)?
- **Why it matters / blocks:** Register accuracy only. The supersession is already recorded on the reconciliation branch,
  marked "to confirm".
- **Evidence:** the register record's notes and history (2026-10-31).
- **Options:** confirm; or reopen.
- **Recommendation (agent, not a decision):** confirm.

### 6.4 FR-11 — personality, prestige and migration
- **Question:** Is FR-11 fully covered by the later records, or is part of it still wanted?
- **Why it matters / blocks:** Register accuracy. The record is stuck at OWNER DECISION REQUIRED.
- **Evidence:**
  - Personality: X19-FOUND-PERS (live).
  - Prestige and standing: WDR-011-C aspirations (integrated, off; see 1.1).
  - Migration: MIGRATE-18, X20-MIGRATE.
  - Deferred by the owner: dislike-driven migration and go-between buying (2026-10-31).
  - The original wording (owner message #47, 2026-10-17) survives only as a summary (`docs/expansions/MISSING_SOURCES.md`).
- **Options:** confirm covered (close it, pointing to those records); or name what is missing.
- **Recommendation (agent, not a decision):** confirm covered, unless the owner remembers something in the 2026-10-17 list
  that is not above.

### 6.5 WDR-003-C — Rule 003 (Meaningful Recipes) compliance
- **Question:** Is the compliance work for Rule 003 (record a purpose for every counted recipe) approved development work,
  like the other rule-compliance records?
- **Why it matters / blocks:** Rule 003 compliance cannot be tracked to completion while its approval is unresolved.
- **Evidence:**
  - The rule is owner-approved: World Design Rules v1.0, "Any unimplemented mechanics should be tracked as development work".
  - Its approval status came from a 2026-10-23 schema migration ("UNKNOWN"), not from an owner statement.
  - The next action is "Document each counted recipe's purpose".
- **Options:** approve, with a build placement; or leave unscheduled.
- **Recommendation (agent, not a decision):** approve, as documentation and audit work in Build 26 consolidation (it changes
  no gameplay).

### 6.6 REC-003 — Android target API 36
- **Question:** Does the owner confirm "Android Target API 36" as a standing project requirement?
- **Why it matters / blocks:** Platform record only. The builds already comply.
- **Evidence:**
  - The Godot 4.7.2 Android template sets targetSdk 36, compileSdk 36 and minSdk 24; `game/export_presets.cfg` overrides
    none of them.
  - No aapt2 check of a built APK is recorded.
  - Partial answer: D36f (2026-10-27): "Maintenance only: keep supported SDK/API requirements compliant and regression-test".
- **Options:** confirm 36 as the current required target; or treat D36f's maintenance rule as the whole answer, with no fixed
  number.
- **Recommendation (agent, not a decision):** confirm 36 as the current target under D36f's maintenance rule. Record it in
  CLAUDE.md s.8 and check the Build 24 APK with aapt2.

### 6.7 FARM-YIELD-D1 — shared farming yield and switches
- **Question:** What wheat yield per sown cell should the shared farming model use, and may `shared_manor_farming` (FSE-12,
  FARM-06) and `seasonal_village_farming` (FSE-13) be switched on in the normal game?
- **Why it matters / blocks:** Four PARTIAL records (FSE-12, FSE-13, FARM-06, FARM-08) wait on it. Their code is built behind
  switches.
- **Evidence:**
  - Owner 2026-10-21: "I am not approving the existing 3-wheat-per-cell yield or selecting a replacement yield yet. Keep both
    … switches off" (`2026-10-21_fse12_fse13_farming_decision.md`).
  - X `balance.json`: `shared_manor_farming 0`, `seasonal_village_farming 0`, `shared_wheat_yield 0`.
  - `docs/design/FARM08_YIELD_COMPARISON.md`:
    - First matrix: 1.0 starves people; 1.5 is the smallest yield with no starvation.
    - Section 6 proposed 2.0 with both switches.
    - The later 24-run results (`dbbb66a`): five herds died, all with seasonal farming on, at any yield; the cause of the
      keeper's empty purse was not established. "Manor only, yield 2.0" kept herds and had 682-986 food days at the end.
    - The document closes with "No recommendation is made here".
  - Crop sharing was decided afterwards (option B, 2026-10-22, FARM-CROP-01).
  - Parity: the player's crop gives 3 a cell, so a different village yield needs one rule for everyone or an explanation.
- **Options (from the comparison):** a yield of 1.0, 1.5, 2.0, 2.5 or 3.0; manor only, seasonal only, or both; or keep both
  off. Also the player's crop: move to the same yield, or explain the gap.
- **Recommendation (agent, not a decision):** keep both off now. The evidence predates crop sharing and the Living Economy.
  If the owner wants to proceed, re-measure on current code after Build 26. Manor-only at 2.0 is the best-supported starting
  point.

### 6.8 JUICE-J1 — game-feel quick wins
- **Question:** May phase J1 be implemented, and in which build? J1 covers:
  - a split of the notification log;
  - a coin tick;
  - a prompt pulse;
  - hurt frames;
  - a "Reduce effects" setting;
  - using the unused `fx_dust`;
  - one pooled effects helper.
- **Why it matters / blocks:** All game-feel work. J2-J5 build on J1's helper.
- **Evidence:**
  - "Report the top ten improvements … and wait for approval" (`2026-10-22_game_juice_preliminary_assessment.md`).
  - The assessment exists only on `origin/wip/juice-assessment` (`bebf1f3`), sections 6-7.
  - Constraint from 2026-10-26 (`messages_journal_persistence.md`): "Do not enlarge the gameplay notification box … The compact
    notification layout should remain unchanged."
- **Options:** approve J1 for a named build; or not yet.
- **Recommendation (agent, not a decision):** recover the assessment document in Build 26; place J1 in or after Build 27.
  Build 26 is consolidation.

### 6.9 JUICE-JD5 — notifications
- **Question:** Which village notes should the player see in the corner log by default, and should there be a filter?
- **Why it matters / blocks:** J1's notification split.
- **Evidence:**
  - X `game_ui.gd`: `LOG_LINES 2`, `LOG_SECONDS 3.0`, gains and village notes share it.
  - Important notes are kept in the Messages journal (2026-10-26).
  - The compact box must stay the same size (2026-10-26).
- **Options (from the assessment):** split gains (the player's) from village notes into two places; optionally a filter in
  Settings.
- **Recommendation (agent, not a decision):** the split, within the compact layout. Leave the filter until players show a
  need.

### 6.10 JUICE-JD3 — villager chatter
- **Question:** How often may villagers show what they are doing in speech bubbles?
- **Why it matters / blocks:** Phase J5 (social visibility). It extends OWN-19 (busy-villager bubbles, partly implemented).
- **Evidence:** the assessment, rank 10: "a villager's speech bubble say[s] what it is doing when the player is near and it
  changes task" (throttled). SJD-Q10: attitudes are shown through behaviour, never numbers.
- **Options:** to be defined by the owner (frequency). The assessment's proposal is above.
- **Recommendation (agent, not a decision):** the assessment's proposal: only near the player, on a task change, throttled.

### 6.11 JUICE-JD4 — screen shake and haptics
- **Question:** Are screen shake and haptics allowed at all, on which events, and on or off by default?
- **Why it matters / blocks:** J1's "Reduce effects" setting and J2's activity effects.
- **Evidence:** the assessment's ideas: a short shake on a mine collapse; Android haptics for a landed blow or a felled tree;
  one "Reduce effects" setting that turns off shake, flashes and particles.
- **Options:** not allowed; or allowed on named events, default on or off.
- **Recommendation (agent, not a decision):** allow, limited to the few rare events named above, always under "Reduce
  effects". No recommendation on the default; that is the owner's taste.

### 6.12 JUICE-JD2 — day and night
- **Question:** Should the picture darken at night? If so, how dark at midnight, and what about interiors? Underground is
  already dark.
- **Why it matters / blocks:** Phase J4 (atmosphere: tint, fireflies, lit windows). It affects readability on phones and
  overlaps Expansion 25's seasons and weather presentation.
- **Evidence:** X has no `CanvasModulate` or night tint. The clock and sleep schedule exist.
- **Options:** to be defined by the owner (darken or not; depth; interiors).
- **Recommendation (agent, not a decision):** decide it as part of the Wild World (Expansion 25) presentation, so night and
  weather lighting are designed once.

### 6.13 REC-014 — revisit the foundations
- **Question:** Does the 2026-10-18 intent ("The foundational settlement, agriculture, food production, resource
  distribution, population, and trade systems will be revisited using research we have recently discussed") still stand,
  and if so, which research?
- **Why it matters / blocks:** Nothing active. The record is unscoped.
- **Evidence:** since 2026-10-20 the owner has issued the food-security, farming, regional economy and Living Economy
  directives. DVW-A3/A4 and ECON-P1..P3 overlap.
- **Options (from the record):** say what research and whether it still stands; or close it as fulfilled by the later work.
- **Recommendation (agent, not a decision):** close it as fulfilled by the FSE, regional economy and Living Economy
  directives, if the owner agrees that was the rework meant.

### 6.14 REC-008 — near/far simulation tiers
- **Question:** Is the near/far simulation design (full detail near players, simplified steps far away, nothing duplicated on
  switching) an approved requirement, and when is it built?
- **Why it matters / blocks:** It is needed only when more of the world or more players are simulated at once.
- **Evidence:** not implemented. All villagers run in full; settlements off the map run abstractly since Expansion 18. The
  owner's interview answer is quoted in the record. DECISIONS.md tier names are an agent proposal.
- **Options:** approve, with a placement; or leave unscheduled.
- **Recommendation (agent, not a decision):** approve as a direction and place it with Expansion 22 and 27 world-scale design
  (5.2, 5.18).

### 6.15 REC-010 — tech or research tree (remaining part only)
- **Question:** Class progression and "system jobs" were answered by D36b (2026-10-27: "the present skill and career system,
  no class lock"). Is a tech or research tree wanted at all?
- **Why it matters / blocks:** Nothing. If wanted, it needs a new record.
- **Evidence:** REC-010 notes (2026-10-31).
- **Options:** to be defined by the owner.
- **Recommendation (agent, not a decision):** no recommendation.

### 6.16 Build placement of approved design-only systems (group)
- **Question:** Which build should take each approved but unscheduled system?
  - Mining follow-ons: PIT-02, EARTH-01, INFO-01.
  - Contract kinds: CON-02-KINDS (CON-03..08: see 2.2).
  - JOB-02 (it overlaps LE-04's wage bargain).
  - MAINT-01; HEALTH-01; procedural villages PVG-01..07.
  - FSE-10 and PL2-015-*.
  - FAM-08; DVW-A9, B7, B9; DVW-B6 (its target has passed).
  - FR-02, FR-03.
- **Why it matters / blocks:** Each stays DESIGN ONLY, NOT AUTHORIZED until placed.
- **Evidence:** `docs/expansions/STANDALONE_SYSTEMS.md` s.3, 5-7, 15, 17; `docs/expansions/EXPANSION_17.md` s.6.
- **Options:** to be defined by the owner, per system.
- **Recommendation (agent, not a decision):** place them through the rebuilt package and Build 27+ planning, not one by one
  now.

Not owner questions (kept off this list):
- JD6, the effect art source: the team decides asset use (CLAUDE.md s.3).
- MIN-G's old "harness one-line fix" note: overtaken by its recorded long-run evidence; lead clean-up.
- Agent-provisional tuning values (family ring weights, danger radii and others, `EXPANSION_19.md` s.6): the owner may tune
  them; they block nothing.
- Owner actions that are not design decisions: AR-OWNER, AR-P0-3, Q-08, Q-10 (`STANDALONE_SYSTEMS.md` s.20).

---

## Answered, not asked again

| Item | Former question | Answered by |
|---|---|---|
| X20-REMAINING-PLACEMENT | Where LE-07, EMP-PERM-01, the LE-05 remainder and activation go relative to the Build 25 freeze | Owner 2026-10-31, `2026-10-31_doc_recon_review_decisions.md` s.1: Build 26, planning, reconciliation and dependency analysis only; Build 25 frozen first |
| X20-ACTIVATION-AUTHORITY | Does the 2026-10-30 automatic Living Economy activation still stand? | Same file s.2: no; kept off by default; activation only on the owner's explicit authorization. The future authorization itself is not asked now; it follows Build 26's evidence |
| E26-BOSS-D1 (conflict C-26-1) | Did the 2026-10-27 parking erase the 2026-10-23 boss roster and hero status? | Same file s.3: the roster (giant crab, Buwaya, minotaur, yeti, necromancer, dragons) is kept as design scope, not implementation. Hero recognition emerges from deeds, witnesses and judgment; no scripted titles |
| X21-RECOVERY-D1 (Batch 0 placement) | Bring Expansion 21 phase-1 work over in Build 26 or Build 27? | Same file s.4: recover and reconcile in Build 26 without activating politics; Build 27 is the intended start. Implementation authorization is asked once Build 26 is frozen |
| Expansions 25/26 packet approval | Approve the agent-written packets? | Owner 2026-10-31 s.6 and DOC-AUTH-01 (`2026-10-31_document_authority_replacement_policy.md`): the owner's revised master package becomes authoritative on approval; the status files are the evidence layer |
| Expansions 22-27 implementation now | Start any of 22-27? | Owner 2026-10-30 ("Do not begin Expansions 22–27") and 2026-10-31 (no implementation without explicit authorization) |
| E25-OD-07 (order part) | When to build 25 | Owner 2026-10-24 order; only the confirmation is asked (5.4) |
| E26-OD-09 (order part) | 26 relative to 25 | Owner 2026-10-24 order (26 after 25); only the early-phases part is asked (5.5) |
| E26-OD-01 (companion part) | May foxes be companions? | Owner 2026-10-23 ("pick a pet fox or a pet wolf as a companion"); only the pen part is asked (5.10) |
| E26-OD-02 (skeleton part) | Skeleton respawn | B14-09 owner wording: 3-day respawn; only spiders and bosses are asked (5.11) |
| X19-SWITCHES-D1 (automatic part) | Switch on because the code exists? | Owner 2026-10-27 (`complete_expansion20_first.md`): no; only on, off or after which validation is asked (1.1) |
| ID-D3 (design alternative) | Seed traits from a stored per-person seed instead? | Owner ruling 2026-10-28: identity design not reopened; only the audit question is asked (1.2) |
| ARMOR-CATALOG-D1 (classes, items, visuals) | Approve the four classes and Build 22's items | D16 (2026-10-27) and ruling 2026-10-28: they stand; only numbers, buffs, materials and headgear are asked (2.3) |
| X20-TRADER-PAY | Change settlement traders' pay? | Owner 2026-10-30 (`x20_trader_pay_final_decision.md`): DEFERRED until wage and service evidence exists |
| Go-between buying; dislike-driven migration | Build them in Expansion 20? | Owner 2026-10-31 (`x20_merged_validation_decisions.md`): DEFERRED |
| MP-INTERACT-Q1, MP-INTERACT-Q2, MP-INET-RELAY | Player-to-player service contracts; Talk priority; internet relay | Q1 DEFERRED, Q2 APPROVED (2026-10-28); relay option A, free methods only (2026-10-30) |
| Q18-11 (Expansion 22 dependency) | Capability factors | D37 (2026-10-27): APPROVED at 1.0 |
| DVW-B3 heriot placement | Where to place the heriot coin sink | Owner 2026-10-23 (`owner_answers_coin_sinks.md`): heriot not chosen |
| JUICE-JD1 | Audio | Owner audio directive 2026-10-23 (MUSIC-18, SFX-18); record SUPERSEDED |
| REC-009 | Combat style | Parked by OD-03 and OD-17 (2026-10-27); record DEFERRED |
| GP-REPAIR-SOCIAL next action | Earshot distances; trade refusal for known killers | Owner 2026-10-24 (`multiplayer_batch_c_g2.md`): the bell carries farther but does not inform everyone; judgment decides refusal |

21 rows: 14 fully answered, and 7 partly answered (E25-OD-07, E26-OD-09, E26-OD-01, E26-OD-02, X19-SWITCHES-D1, ID-D3,
ARMOR-CATALOG-D1), whose remaining part stays open above.
