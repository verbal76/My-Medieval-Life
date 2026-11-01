# Expansion 19: the fourteen Judgment questions (SJD-Q01..Q14) reconciled with the code

Prepared 2026-10-21 on `wip/roadmap-docs`, as the Master Expansion Roadmap's immediate documentation action for 19.
Planning only: no code, data or register change, and **no question is answered here**. Each entry gives the
question exactly as the register and the spec state it, the current code facts, the options, a recommendation for the
owner, and a classification.

Sources: `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt` ("spec s.N"; the PDF is
authoritative), register entries EXP-C, SJD-A..H, SJD-Q01..Q14, CRT-12, DVW-B1, DVW-B2, GM-01, FR-09; code at staging
`b3bbb1c`.

## 0. The rule for these questions

- **APPROVED (owner, 2026-10-20):** "The 14 judgment-system questions remain unresolved until explicitly answered by
  the owner" (`docs/directives/2026-10-20_permanent_project_memory_hardening.md`; also
  `2026-10-20_project_memory_hardening.md`). Every SJD-Q entry is BLOCKED with next action "await the owner's answer;
  no default is chosen on the owner's behalf".
- **APPROVED (spec s.19):** "Claude should first recommend defaults, identify implementation consequences, and group
  questions by urgency. Do not interrupt for trivial details that can remain configurable; do ask before committing to
  irreversible gameplay semantics."
- **How the two fit (proposal for the owner to confirm):** the recommendations below are recommendations only. A
  question marked **TUNABLE** is one where the engineer may, during the isolated Gates C-D (no effect on live
  behaviour, spec s.17), build the behaviour as a data-driven switch (spec invariant 6) and run tests with clearly
  labelled fixture values; the owner's answer then sets the value before Gate E. A question marked **OWNER** shapes
  the architecture or irreversible semantics and needs the owner's answer before the prototype commits to it.
  Whether the owner accepts this classification is itself **OPEN DECISION Q19-0**.
- **Urgency** (spec s.19 asks for grouping): **Before Gate C** (shapes the event and ledger schema), **Before Gate D**
  (shapes the decision engine), **Before Gate E** (live integration).

## 1. Code facts shared by several questions (staging `b3bbb1c`)

- F1. `Relations` keeps **one tie per pair** with `regard` and `attraction`, each **clamped to 0..100**
  (`relations.gd::_raise`). There is no negative opinion and no separate GOOD and BAD totals; a NET of -6.59 cannot be
  represented today.
- F2. Harm is **player-centred**: `Relations.harmed` lowers only villagers' ties *with the player*, and spreads at once
  to the victim's kin (`kin_harm_share` 0.6) and friends (`friend_harm_share` 0.4) whether or not they learned of it.
- F3. Ties **decay** without contact: `Relations.dawn` subtracts `decay_per_day` (0.5) from attraction and half of
  it from regard each day without contact (`balance.json` `relations`).
- F4. **Notoriety** is a fixed threshold: crimes with witnesses in the last `notoriety_days` (16) plus killings x
  `killing_weight` (3); at `notoriety_refuse` (3) a proposal is refused (CRT-12). Killings are never forgotten
  (`Relations.killings`). EXP-C's notes record this as a known conflict to resolve at Gate B.
- F5. Witnessing is binary and sight-based (`World.witness`, `witness_radius`); reports by victim or witness reach
  guards (`World.report_crime`; PAR-05, PICK-01). No confidence, rumour or gossip layer exists (DVW-B1 is PARTIALLY
  IMPLEMENTED: "no gossip/favour code").
- F6. `NPC.memory` is at most 8 free-text lines ("saw ...", "met ..."); no event ids, no causal links (GM-01 not
  started).
- F7. Decisions are **rule-based** in `NPCBrain.decide` (a fixed priority order: bandit, clan child, report, eat, rest,
  guard, sleep, work); a few choices draw from the single shared `World.rng` (e.g. children's wandering,
  `npc_court_chance` 0.15). No utility scoring.
- F8. All tunables live in `game/data/balance.json` with notes marking them "agent proposals, provisional" (spec
  invariant 6 is already the project's practice).
- F9. The player sees a villager's feelings only as words (`Dialogue.regard_words`, from regard and attraction) in the
  gift window; no numbers.
- F10. Friendship already changes prices (`friend_price` 0.1 in `World` trade pricing) and makes friends back the
  player before a guard (CRT-06).

## 2. The fourteen questions

### SJD-Q01: NEUTRAL event type
- **Register:** "Judgment open decision: Should there be a NEUTRAL objective event type, or must every judged event begin GOOD/BAD?"
- **Spec s.19 (25):** "Should there be a NEUTRAL objective event type, or must every morally judged event begin GOOD/BAD?" Spec s.3: the owner's rule is GOOD/BAD; NEUTRAL "is an OPEN DESIGN DECISION; do not silently redefine owner's GOOD/BAD rule".
- **Code:** no event catalog (F6). Many existing events are morally neutral (a trade at a fair price, a meeting, a death from old age).
- **Options:** (a) GOOD/BAD only; neutral happenings are not judged events. (b) NEUTRAL type that informs knowledge and needs but posts no points. (c) NEUTRAL with context tags that observers may interpret either way.
- **Recommendation:** (b): neutral facts are needed anyway for GM-01's history (marriages, purchases, construction) and cost nothing in the ledger; they post no moral points, so the owner's GOOD/BAD rule for judged events is untouched.
- **Class:** OWNER (redefines the owner's rule). **Urgency:** Before Gate C (event schema).

### SJD-Q02: decay
- **Register:** "Judgment open decision: Should scores decay, or change only through new events, forgiveness and corrected beliefs?"
- **Spec s.19 (26):** "Should scores decay or only change through new events, forgiveness, and corrected beliefs?" Spec s.5.2: "Never add automatic decay or universal caps without explicit owner decision. Preserve lifetime historical totals if a separate effective/recent judgment is introduced."
- **Code:** regard and attraction already decay daily without contact (F3); notoriety expires after 16 days (F4).
- **Options:** (a) no decay; change only by events. (b) Lifetime GOOD/BAD kept; a separate "recent" view weights by recency. (c) Decay of totals.
- **Recommendation:** (b), and keep the existing tie decay as *familiarity/closeness* decay (a different concept, spec invariant 7) rather than moral judgment. Note for the owner: today's regard decay is already a form of (c) for the player's ties.
- **Class:** OWNER (spec forbids deciding it without the owner). **Urgency:** Before Gate C.

### SJD-Q03: thresholds
- **Register:** "Judgment open decision: Different disposition thresholds per NPC, or one calibrated scale?"
- **Spec s.19 (27):** "Should different NPCs have different disposition thresholds, or one shared calibrated scale?"
- **Code:** one shared scale today (`befriend_at` 25, `court_at` 30, `marry_regard` 30 for everyone), with per-person variation only in `unwilling_percent` (12%, fixed per person and world) and pair `chemistry`.
- **Options:** (a) one scale; (b) per-NPC thresholds from personality traits; (c) one scale for the ledger, per-NPC weights in decisions (spec s.10: NPCs "differ in factor weights and thresholds").
- **Recommendation:** (c): the ledger stays comparable across NPCs; individuality lives in decision weights (spec s.10).
- **Class:** TUNABLE (the mechanism is configurable either way; values need calibration). **Urgency:** Before Gate D.

### SJD-Q04: ambivalence
- **Register:** "Judgment open decision: Should very large GOOD and BAD totals with NET near 0 create ambivalence behaviour?"
- **Spec s.19 (28):** "Should very large GOOD/BAD totals with NET≈0 create special ambivalence behavior?"
- **Code:** impossible today (F1: one clamped scalar).
- **Options:** (a) no special behaviour; NET only. (b) An ambivalence factor (e.g. min(GOOD,BAD)) available to decision profiles. (c) Ambivalence changes interpretation of new events.
- **Recommendation:** (b): store both totals (already required by the spec) and expose an ambivalence factor that profiles may weight at 0 until calibrated.
- **Class:** TUNABLE (storage is required anyway; the effect is a weight). **Urgency:** Before Gate D.

### SJD-Q05: bias from prior judgment
- **Register:** "Judgment open decision: How much may prior judgment bias interpretation of ambiguous events?"
- **Spec s.19 (29):** "How much may prior judgment bias interpretation of ambiguous events?" Spec s.4.3: "Cap relationship-bias effects".
- **Code:** none (no interpretation step).
- **Options:** (a) none; (b) bounded bias only for events tagged ambiguous, capped; (c) unbounded.
- **Recommendation:** (b) with a cap configurable in data, and bias never applied to firsthand harm to the observer.
- **Class:** TUNABLE for the cap value; the existence of bias is OWNER-adjacent but the spec already approves a capped bias. **Urgency:** Before Gate D.

### SJD-Q06: confidence and rumour
- **Register:** "Judgment open decision: How should confidence and rumours influence points: multiplier, threshold, or separate belief layer?"
- **Spec s.19 (30):** "How should confidence and rumors influence the points: multiplier, threshold, or separate belief layer?" Spec s.4: I = S x P x C is "a proposed initial formulation"; s.6 recommends four separate records.
- **Code:** binary witnessing (F5); harm spreads to kin without any information path (F2).
- **Options:** (a) multiplier C; (b) threshold (belief below confidence posts nothing); (c) separate belief layer with (a) or (b) applied on top.
- **Recommendation:** (c) with (a): the separate belief layer is needed for GM-01 provenance (firsthand vs told vs rumour) and corrections; C scales points. Staged: firsthand only at Gate C, rumour later (spec s.6).
- **Class:** OWNER (architecture). **Urgency:** Before Gate C.

### SJD-Q07: gossip reach
- **Register:** "Judgment open decision: How far should gossip spread; should reach depend on social proximity and personality?"
- **Spec s.19 (31):** "How far should gossip spread, and should its reach depend on social proximity and personality?"
- **Code:** no gossip (F5); the instant kin/friend spread of harm (F2) is the nearest thing and is omniscient within the family.
- **Options:** (a) no gossip at first; (b) hop-limited spread along ties during real conversations; (c) settlement-wide announcements only.
- **Recommendation:** (b), budgeted per day (spec s.13), with reach and credibility weights in data; replace F2's instant spread when it lands.
- **Class:** TUNABLE for reach values; OWNER for the decision to replace F2's current behaviour in live play. **Urgency:** Before Gate E.

### SJD-Q08: law, morality and loyalty
- **Register:** "Judgment open decision: How should legal guilt, moral judgment and personal loyalty interact?"
- **Spec s.19 (32):** "How should legal guilt, moral judgment, and personal loyalty interact?"
- **Code:** guards fine and confront by sight or report (PAR-05, PICK-01); friends back the player before a guard (CRT-06); no trial, no conviction record; NPC crimes have no record (only `PlayerState.crimes`).
- **Options:** (a) legal guilt posts BAD for everyone who learns of it; (b) legal status is a fact; each observer interprets it (loyal kin may reverse); (c) loyalty can hide crimes (refusal to report).
- **Recommendation:** (b), with (c) allowed only as a decision (not reporting is a judged choice with risk), consistent with "a spouse can ... refuse to cover up a murder" (spec s.7.4).
- **Class:** OWNER (moral semantics; affects politics and bandits). **Urgency:** Before Gate E.

### SJD-Q09: best or near-best choice
- **Register:** "Judgment open decision: Always highest utility, or sometimes near-optimal via seeded randomness?"
- **Spec s.19 (33):** "Should NPCs always choose highest utility or sometimes choose near-optimal options via seeded randomness?"
- **Code:** rule-based decisions with some `World.rng` draws (F7).
- **Options:** (a) argmax; (b) seeded softmax/bounded exploration among options within a margin; (c) per-NPC temperament sets the margin.
- **Recommendation:** (b) with a margin in data, drawing from a **dedicated** seeded stream per subsystem (not `World.rng`, so existing streams do not shift; spec s.13 and s.16).
- **Class:** TUNABLE. **Urgency:** Before Gate D.

### SJD-Q10: what the player sees
- **Register:** "Judgment open decision: What judgment information, if any, can the player see?"
- **Spec s.19 (34):** "What judgment information, if any, can the player see?"
- **Code:** words only (F9); developer traces do not exist.
- **Options:** (a) nothing; (b) words from NET (as now); (c) words plus reasons ("remembers you stole from his cousin") from known beliefs; (d) numbers.
- **Recommendation:** (c) for the player, (d) only in developer diagnostics (spec s.14). Rule 010 (depth without obscurity) favours reasons.
- **Class:** OWNER (player-facing design). **Urgency:** Before Gate E.

### SJD-Q11: persistence and forgiveness by severity
- **Register:** "Judgment open decision: How should memory persistence and forgiveness vary by severity?"
- **Spec s.19 (35):** "How should memory persistence and forgiveness vary by event severity?"
- **Code:** killings never forgotten; other crimes count for 16 days (F4); `NPC.memory` keeps 8 lines (F6).
- **Options:** (a) all permanent; (b) severity bands: minor events can be forgiven by later events, severe ones permanent unless forgiven by an explicit act; (c) time-based fading by severity.
- **Recommendation:** (b), consistent with Q02 (b); forgiveness as an explicit event the observer chooses.
- **Class:** OWNER. **Urgency:** Before Gate C (ledger semantics), values TUNABLE.

### SJD-Q12: what is worth scoring
- **Register:** "Judgment open decision: What makes an event important enough to score?"
- **Spec s.19 (36):** "What constitutes an event important enough to score?" Spec invariant 8: no flood of events from repetitive animation or passive ticks.
- **Code:** today's `harmed` and `helped` hooks (quests done, defence, gifts, theft seen, assault) are the de facto list.
- **Options:** (a) a fixed catalog of event types with minimum severity; (b) catalog plus per-type thresholds by quantity or value; (c) significance computed from consequences.
- **Recommendation:** (b), seeded from the existing hooks and the spec's s.3 table; shared with GM-01's significance thresholds so history and judgment use one filter.
- **Class:** TUNABLE (catalog content and thresholds are data). **Urgency:** Before Gate C.

### SJD-Q13: how weights are set
- **Register:** "Judgment open decision: How should individual decision weights be learned, configured or tuned?"
- **Spec s.19 (37):** "How should individual decision weights be learned, configured, or tuned?"
- **Code:** all numbers in `balance.json` (F8); villager traits beyond chemistry and willingness do not exist.
- **Options:** (a) configured per profile in data; (b) per-NPC trait offsets generated from the seed; (c) learned from experience at run time.
- **Recommendation:** (a) plus (b); no run-time learning in the first release (determinism, explainability).
- **Class:** TUNABLE for (a)/(b); OWNER if (c) is wanted. **Urgency:** Before Gate D.

### SJD-Q14: first live domain
- **Register:** "Judgment open decision: Which domain gets the first live integration after the prototype?"
- **Spec s.19 (38):** "Which domain should receive the first live integration after the isolated prototype?" Spec s.17 Gate E: "one low-risk decision domain, feature flag OFF by default".
- **Code:** candidate entry points: trade pricing with friends (`friend_price`), CRT-12 proposal refusal (`relations.gd::refusal`, the recorded conflict), gift acceptance, crime reporting (`_report`), hiring (`construction.gd::can_hire`, `business.gd::hire_refusal`), contracts (CON-01 `evaluate` on `wip/build17`).
- **Options:** (a) trade (the 50-iron canonical case); (b) courtship refusal (replaces the CRT-12 threshold, but touches marriage pacing); (c) hiring and contracts (CON-01's accept/reject already weighs "the relationship").
- **Recommendation:** (a), via CON-01's evaluate step if Build 17 has merged it: it is the spec's canonical scenario, it is measurable with the existing ledgers, and its failure mode (a refused trade) is a legitimate outcome under Rule 022.
- **Class:** OWNER. **Urgency:** Before Gate E.

## 3. Summary table

| Id | Class | Urgency | Recommendation (for the owner) |
|---|---|---|---|
| Q01 | OWNER | Gate C | NEUTRAL facts that post no points |
| Q02 | OWNER | Gate C | No decay of lifetime totals; optional recency view; existing tie decay reclassified as closeness |
| Q03 | TUNABLE | Gate D | One ledger scale; individual decision weights |
| Q04 | TUNABLE | Gate D | Store both totals; ambivalence factor weighted 0 until calibrated |
| Q05 | TUNABLE | Gate D | Capped bias on ambiguous events only |
| Q06 | OWNER | Gate C | Separate belief layer; confidence multiplier; firsthand first |
| Q07 | TUNABLE (values) / OWNER (replace current spread) | Gate E | Hop-limited conversational gossip, budgeted |
| Q08 | OWNER | Gate E | Legal status is a fact each observer interprets |
| Q09 | TUNABLE | Gate D | Bounded seeded choice on a dedicated stream |
| Q10 | OWNER | Gate E | Words and known reasons; numbers only in diagnostics |
| Q11 | OWNER (semantics) / TUNABLE (values) | Gate C | Severity bands; forgiveness as an event |
| Q12 | TUNABLE | Gate C | Catalog with per-type thresholds, shared with GM-01 |
| Q13 | TUNABLE (data, seed) / OWNER (learning) | Gate D | Data profiles plus seeded trait offsets |
| Q14 | OWNER | Gate E | Trade, through CON-01 |

**Owner questions that block Gate C** (the first gate with code): Q01, Q02, Q06, Q11. Gate B (the architecture
audit) needs none and may proceed once Build 18 qualifies and Build 19 is authorized (OVN-01 order).

## 4. Integration gates and conflicts to carry into Gate B

- EXP-C notes (FACT): CRT-12's notoriety threshold and the single regard score are a recorded conflict with the
  judgment design; they become judgment inputs weighed in decisions.
- DVW-B1 (memory of favours and harms, gossip) is subsumed into EXP-C (register note).
- DVW-B2 (assault and killing as recorded, fined crimes; heir inherits fines or stain) and FR-09 (crime from desperation,
  owner-deferred, "owner decision first") are targeted 19.
- GM-01 (generational memory) is placed in 19 "fit to confirm": the event store must serve both (see
  `23_Legacy_comparison.md`).
- **OPEN DECISION Q19-0:** does the owner accept the TUNABLE/OWNER split above, so that TUNABLE items may run with
  labelled fixture values in the isolated prototype while staying formally unanswered?
