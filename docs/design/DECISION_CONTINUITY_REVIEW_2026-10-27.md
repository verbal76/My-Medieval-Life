# Decision continuity review of the 39 reconciled answers (2026-10-27)

Owner rule: `docs/directives/2026-10-27_design_continuity_directive.md` (register `DCR-01`). Answers under review:
`docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md` (staging 5484ce1). Each answer was compared with the earlier
owner directives, settled decisions, the register, the code on `wip/expansion20` (0dc0014), saves and the release restrictions.
Nothing was rewritten; earlier rules stand where they are recorded. **One genuine conflict** (section 3) needs the owner.

## 1. The ten checks the owner named

| Check | Result |
|---|---|
| Negotiated contract terms stay authoritative | Yes. OD-LE-13 (approved: context-sensitive breach, renegotiation by the original agreement) is untouched; D02 (OD-LE-03) adds negotiated item, quantity and unit price on top of existing wage rules; D12 (OD-LE-13B) acts only when a party dies. |
| Estate obligations respect contracts, property, assets, inheritance | Yes. D12: claims only up to real estate assets, heirs not personally liable, matching OD-LE-05's "no authority to seize unrelated property". It **intentionally revises** a provisional default (section 2), not an approved rule. |
| Lending extends existing credit | Yes. Existing: goods on credit without interest; OD-LE-05 (approved) extensions, instalments, payment in goods, pledged collateral, surplus returned. D04 (OD-LE-05B) adds money loans with interest, collateral and auditable default in a future finance stage; it must keep every OD-LE-05 rule and leave goods-on-credit as it is. Compatible extension. |
| Business ownership and separate accounts | Yes. D03 (one owner per business, estate inheritance) and D06 (separate tills, ECON-P3) agree with ECON-P3 and the code (`business_money.gd` front and counter tills). D06's precondition is recorded: LE-01's missing till actors are fixed before any finance logic. |
| NPC judgment, personality, family sacrifice | Yes. D11 (charity) and D39 (proposal acceptance) both go through `JudgmentWeighting` with the family order (children, spouse, parents, self), the refusal correction (no fixed cutoffs) and X19-CRT12's courtship cut-offs kept as hard limits. |
| Six aspiration domains | Yes. No answer touches them; D15/D39 keep standing from being counted twice. |
| Mayor's four-game-year term | Preserved. Source: consolidated design 2026-10-23 section 4.2 ("Mayoral terms last four in-game years"). D20 sets residency only (8 days to vote, 16 to stand for council); D23 keeps full terms. Note: 4.2 makes "eligible voters also eligible to run for mayor", so the 16-day rule is read as council seats only and mayoral candidacy follows voter eligibility (8 days). This reading needs no change; if the owner meant 16 days for mayor too, that would be an intentional revision of 4.2. |
| Multiplayer architecture and release restrictions | Unchanged. D32c restates the approved master multiplayer directive (2026-10-24: host-owned world, about three or four players, time stops when the host leaves, LAN and practical internet connections without paid services). The MP-INTERACT-01 gate (integrate last; no Expansion 20 build before it) is untouched. (Correction: the lead's earlier note that internet play needed fresh authorization was wrong; it is approved there, scoped out of Build 21 only.) |
| Future decisions do not authorize implementation | Enforced: the 21 FUTURE answers carry "design direction only; not implemented" in their register entries; Expansion 21 to 23 work stays unauthorized. |
| Historical design documents cannot supersede the living-world design | Enforced: `docs/PROJECT_MEMORY.md` marks them historical; OD-03 and OD-17's old-design parts are parked and not approved. D36a (an ordinary person, no chosen hero) replaces only an *Undecided* question in `docs/GAME_DESIGN.md` (U3), never a Confirmed item. |

## 2. Classification of the 39 answers

- **Compatible extensions (35):** D01, D02, D03, D04, D05, D06, D07, D08, D09, D10, D11, D13, D14, D15, D17, D18, D19 (Q-POL-1, P21-STRUCTURE),
  D20, D21, D22, D24, D25, D26, D27, D28, D29, D30, D31, D32 (current parts), D33, D34, D35, D36 (current parts), D37, D39. D16 and D38 are
  conditional (provisional until their evidence exists) and change nothing yet.
- **Intentional revision (1), no owner action needed:** D12 / OD-LE-13B. Previous: the provisional contract default (OD-29, Build 17,
  "the documented recommended defaults, provisionally") that a party's death ends the contract and a lapse returns coins. New: death can
  create estate claims up to real assets, heirs not personally liable. OD-LE-13B was opened precisely to settle this, the earlier default was
  provisional, and D12 keeps the current handling until the authorized contract and estate stage (with migrations).
- **Conflict (1):** D23 / Q-POL-6, section 3.
- **Parked, not approved:** the old-design parts of D32 and D36 (Morris era and atlas, magic beyond Fireball, PvP, combat re-architecture,
  monster and boss roster).

## 3. Conflict: removal from office (Q-POL-6, D23)

| Field | |
|---|---|
| Requirement ID | Q-POL-6 (Expansion 21), with GM-01's politics part and the Expansion 21 plan item A9 |
| Previous approved rule | "Where appropriate, allow removal from office, replacement, loss of political support, or other consequences through the established political system." |
| Previous approval source | `docs/directives/2026-10-19_memory_refuges_politics.md` (owner directive, 2026-10-19, line 749); echoed by the approved consolidated design 2026-10-23 section 4.2 (early vacancy triggers a replacement election) |
| Newly approved rule | D23 (answer A): "No automatic impeachment/recall. Elected term and exceptional death/permanent absence, with negative consequences on reputation and later ballots. Do not enable removal mechanics contrary to selected rule." |
| Exact difference | 2026-10-19 permits removal through the political system where appropriate; D23 allows no removal at all, so a term ends early only by death or permanent absence, and misconduct costs only reputation and later votes. |
| Systems affected | Expansion 21 civic offices (term, vacancy, succession), elections, judgment (accountability events), history (GM-01 records of office). |
| Existing code affected | None in the live game (no politics). The Expansion 21 groundwork on `wip/expansion21-preparation` holds records only; its plan (A9, readiness table row 5) lists removal as open (Q-POL-3, Q-POL-6). |
| Proposed reconciliation | Read D23's "No **automatic** impeachment/recall" literally: no removal is ever triggered automatically by a score or rule, but the earlier "removal through the established political system" stays available as a deliberate act of that system (for example a council or vote procedure, to be designed with P21-STRUCTURE) for grave misconduct, alongside death and permanent absence. Both texts survive; the 2026-10-19 rule is not discarded. |
| Owner approval required | **Yes.** Choose: (a) the reconciliation above; (b) D23 strictly: no removal mechanics at all (the 2026-10-19 permission is then superseded by name); or (c) another rule. Nothing is built either way until Expansion 21 is authorized. |

## 4. Resolution of the conflict (owner, 2026-10-27)

The owner chose **option B** (`docs/directives/2026-10-27_q_pol_6_conflict_resolution.md`; `Q-POL-6-CONFLICT` closed): D23 holds
strictly. There are no impeachment, recall or political removal mechanics for the mayor, automatic or manual. The mayor serves the
four-game-year term (consolidated design 2026-10-23, section 4.2) unless death or permanent absence ends it early; misconduct,
corruption and unpopular decisions affect reputation, political relationships, public support and future elections only. The
2026-10-19 directive *permitted* removal where appropriate and did not mandate it; D23 is the newer, explicit decision and supersedes
that permission **specifically for mayoral removal**. The 2026-10-19 text is preserved unchanged in `docs/directives/`; other political
mechanics are untouched, and no Expansion 21 work starts.
