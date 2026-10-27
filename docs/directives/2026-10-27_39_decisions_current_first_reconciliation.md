# MY MEDIEVAL LIFE — CURRENT-FIRST RECONCILIATION OF 39 ANSWERS
## Replace the stale original-game-design-based handoff with this document

**Owner instruction (2026-10-27):** “Bring the answers more in line with what we have worked on, the new chat was pulling from the original game design document that has been moot since last week.” This instruction controls interpretation of this handoff.

**Read this first. The original game design document / Game Designer import / Bob's source file is historic reference, NOT the active game's specification.** The game is an already-developed, deterministic Godot 4 living-world simulation. Do not restart its design, assert fantasy lore from imported notes, or overwrite shipped features with a speculative reboot.

**Provenance:** This handoff reconciles the 39 selections recorded in `MY_MEDIEVAL_LIFE_39_DECISIONS_HANDOFF_PACKAGE.zip` with actual work and owner directives through 2026-10-27. It preserves the choices as **owner answers in that prior chat**, but distinguishes a choice made to an obsolete-premise question from a fresh authorization to build it. **The original package has not been applied to GitHub by this document.** Any real conflicts are marked REVIEW rather than silently decided for the owner.

### Verified repository snapshot (do not mistake for a future live status)

- Repo: `verbal76/My-Medieval-Life`. Staging decision register branch `staging/my-medieval-life` at **`abc170dc`** (checked 2026-10-27). The register still reports **39 OPEN decision records** and **194 APPROVED**; that is a register status, not the same population as “39 answers in a chat.” Do NOT claim those are committed merely because this handoff includes selected answers.
- Active Expansion 20 integration: `wip/expansion20` at **`0dc0014`**. Build 22 (`wip/build22`, `b7e1c91`) is a separate existing **private three-platform draft**: DO NOT reopen it or regenerate it to address these design questions.
- Expansion 20 includes Living Economy **LE-01 foundation**, off by default; Android UI work, persistent Messages journal, pager and channel fixes, Build 19 recovery R1/R3, R2 witness reporting and R4 historical memory. **LE-02 through LE-07 are NOT STARTED** as tracked in the register. No statement here makes the living economy active/finished.
- `wip/x20-r5` at **`2fe35ae`**: an actual worker branch implementing the approved **six-domain aspirations** (food/security, wealth, property, profession, family, **social standing**), with survival and family safeguards and flags off. It has not thereby become a merged/released feature. The first seven aspiration owner questions were already approved/closed on staging. Q8 remains OPEN in the live register; the imported package selects **Q8=A**, pending documentation integration.
- `wip/x20-mp-interact` at **`0ce4c9e`** has the player-targeting/interactions correction and targeted tests, **NOT merged** into X20. Human-player touch/click/keyboard/controller, gifts/trades/contracts/messages/consent were exercised in code tests, not all real device pairs. Two additional questions `MP-INTERACT-Q1` (player-to-player service contracts) and `MP-INTERACT-Q2` (Talk priority versus nearby NPC) are still open and NOT resolved by the 39 selections.
- **MANDATORY RELEASE GATE:** No Expansion 20 build of *any kind*, including private APK/Windows/Linux, until MP-INTERACT-01 is merged **LAST** into the final validated integrated baseline and appropriately validated on Android, Windows, Linux, host/guest and controller/touch/mouse. No publication without separate owner approval. Build 22 is not reopened.
- Last merged-source evidence and current-source evidence are not interchangeable. The former validated `4f50ffb` baseline had 17 passing suites and G0 unchanged; new changes after that point need applicable targeted and combined verification. Reuse valid tests; don't run redundant full campaigns.

### Authority hierarchy for interpreting all 39 answers

1. **Latest explicit owner instruction** — especially this correction that the original GDD is moot as a current specification.
2. Later approved owner-specific directives and the `docs/requirements/requirements.json` register (check provenance, scope and supersessions).
3. Actual implementation on currently relevant branches, source code, passing CI and real-device playtests, with correct implementation status.
4. Current expansion plans and living-economy design documents where not in conflict with #1–3.
5. Old `docs/GAME_DESIGN.md`, `docs/DESIGN_GAP_ASSESSMENT.md`, `docs/game-designer/` original Bob imports and old prose: **historical reference only, never primary authority**.

Never create a second economy, AI decision system, world time model, currency, reputation ledger, player identity layer, or multiplayer host. Preserve history rather than deleting imported source. **Owner policy approved** is not the same as **implemented**; **implemented** is not the same as **validated on device** or **released**.

### Four practical design anchors established in recent work

**Living village, not a player-centered story:** NPCs are agents with real needs, finite goods, work, property, money, family relationships, independent judgment, knowledge and failure. Player starts as an ordinary person in the same rules. Do not invent a mandatory chosen-hero campaign or victory quest.

**Existing judgment system:** An observer holds separate Good and Bad ledgers for each actor; that person's interpretation can be favorable or unfavorable depending on relations and interests. Opinion is a *weighted factor* in decisions against actual necessity, not a universal refusal threshold. Family sacrifice priorities (children > spouse > parents > self, for guardians of any sex) stay in force with rare exceptions and long-term family survival respected. No runtime LLM.

**Economy and production:** Inventory, funds, item transfers, contracts and ownership must conserve real resources. Contract negotiation is general-purpose product/quantity/unit-price (e.g., wheat or iron), not a mining-only pay mechanic. Surface, open-pit and cave ore objects use the SAME sustainability/depletion behavior. Work experience is individual, 0–10, industry-specific modifiers; facility shortages lower effective skill, not earned experience. Farming experience improves speed **not harvest yield**. No independent settlement-wide bonus unless separately approved.

**Networking and release discipline:** Host-owned world, characters tied to that world, stops when host is offline; up to ~3–4 friends is the design direction. Android, Windows, Linux and controller support. Cross-platform player-selection failure was real; isolated fix branch exists, integration last. Do not infer device passes from unit/sim tests. No unattended publication, and no silent auto-updater. Respect the specific project/release's explicitly approved delivery mechanism rather than applying unrelated Mote requirements.

### Decision classification guide

- **CURRENT** = aligns to established MML behavior and can be recorded into the appropriate existing requirement as policy, without asserting implementation.
- **FUTURE** = coherent owner-selected direction, **design only**; do not begin the expansion or create subsystems now.
- **ENGINEERING** = correct an evidenced regression/defect using existing semantics; targeted tests; not a new gameplay policy.
- **GDD-REVIEW** = original-document premise is obsolete/untethered to recent MML. Keep the selected answer as historical data **but do not silently elevate its speculative content into the active scope**. Require an explicit current-game design review before implementation or core requirements supersession.
- **CONDITIONAL** = selected with a measurable gate or pending compatibility check. Cannot close until evidence exists.

---
## 1. Decision map, D01–D39 (current code and roadmap aligned)

**Every row is a corrected interpretation of an owner selection, NOT a claim of existing code.** A selection from the imported package may need a requirement update before it is operative. “FUTURE” means policy intent only; if live repo or a newer owner directive conflicts, flag it and preserve the existing gameplay until settled.

### D01 — `OD-LE-02B` · answer C · **CURRENT**

Trade offers local to real encounters/stalls/direct dialogue; gossip carries what a villager genuinely learned, not a universal offer board. Preserve NPC-limited information and player visibility.

### D02 — `OD-LE-03` · answer C · **FUTURE**

Existing wage and hiring rules remain intact while current contracts may negotiate explicit item, quantity and unit price. Broader negotiated wages/services must be layered into LE-03 behind flags; do not replace functioning pay or invent universal wages.

### D03 — `OD-LE-04` · answer A · **FUTURE**

One owner per business initially, with ownership recorded separately from household money and estate inheritance. Multiple businesses are possible if existing ownership permits; no partnership model in this first stage.

### D04 — `OD-LE-05B` · answer C · **FUTURE**

Loans, interest, collateral, repayment and default are selected future economic behavior, NOT present in LE-01. No agent-selected rates or lender powers. Real funds/estate limits, explicit terms, consent and auditable default. Build only in authorized finance stage.

### D05 — `OD-LE-06` · answer C · **FUTURE**

Existing manor relief, tax bands, guard funding and supplies continue. Selected controlled emergency loans/interventions need actual treasury, authority and the future politics dependency; not arbitrary price control or minted relief.

### D06 — `OD-LE-07` · answer A · **CURRENT**

Business tills/stock/obligations must be separate from household holdings (already owner-approved ECON-P3). Owners can make explicit recorded contributions, legitimate profit distributions or estate transfers, but no silent pooling. Fix LE-01 storefront/counter till actor gaps before new finance logic.

### D07 — `OD-LE-08` · answer B · **FUTURE**

Keep existing barter running. Renting/repair/substitutes selected as possible economic extensions; model real assets, time, repairs and contracts in phased LE work, not an immediate broad overhaul or infinite transformation recipes.

### D08 — `OD-LE-09` · answer A · **CURRENT**

Retain current bandit buying and off-village trading. Do not suddenly ban bandits from stalls or create a stolen-goods merchant system. Later bandit factions and physical regional transport are separate, deferred work.

### D09 — `OD-LE-10` · answer C · **CURRENT**

Knowledge of prices comes from observation/direct offers/existing gossip with source, age and trust, and may be wrong/stale. Use the integrated historical gossip/judgment plumbing; no separate price rumour engine or omniscient player market.

### D10 — `OD-LE-11` · answer B · **FUTURE**

Villager speculation/hoarding is an approved design direction *once adaptive prices, resource accounting and storage are present.* Nothing can manipulate supply by fiat; scarcity, inventory, consequences and finite purses govern decisions. Do not turn it on within off-flag LE-01.

### D11 — `OD-LE-12` · answer C · **CURRENT**

Extend existing family help, chapel aid and manor relief by voluntary, real-resource donations where meaningful. All transfers obey family sacrifice hierarchy, judgment-weighted willingness and conservation. No extra independent charity economy.

### D12 — `OD-LE-13B` · answer B · **FUTURE**

Death of a contract party can generate estate claims up to real estate assets; heirs bear no automatic liability from separate personal funds. Current temporary contract-death/lapse handling remains until the authorized contract/estate stage and migrations. Do not invent penalties or force a new collection system into Build 22.

### D13 — `OD-LE-14` · answer C · **FUTURE**

A personal market journal may track only offers the player actually learned, with date/place/staleness. Align with already integrated **persistent per-world Messages journal**, do not make a separate omniscient marketplace feed, and don't corrupt the guest journal network action path.

### D14 — `OD-LE-15` · answer C · **CURRENT**

Economy target approximately 500 NPC on mid-range Android, work staggered to ~4ms maximum per game frame. A target to PROFILE not a success claim. Do not sacrifice deterministic outcomes or break 16MB/500-person memory evidence from earlier targeted tests.

### D15 — `WDR-011-C; WDR-011-Q8` · answer C · **CURRENT**

NPC courtship is voluntary, requires separate days and avoids A-button spam. Existing attraction, personal judgment, opinion, family/kin constraints and consent remain. Personality-specific suitability is within eligibility, not automatic financial cutoffs. Q8=A from imported answer should be reconciled into the existing Q8 record, not a parallel dating system.

### D16 — `ARMOR-CATALOG-D1` · answer B · **CONDITIONAL**

Existing Build 22 four armour categories/items and visuals stand. Numerical armor/buff/crafting rules remain PROVISIONAL pending actual owner balance/art review; do not interpret the imported decision as approving exact proposed fireball stats, cloth hats or material substitution. No Build22 rebuild.

### D17 — `SIM-F2` · answer C · **ENGINEERING**

Stonecutter buying a chisel unsuccessfully 328 times/day is a repeated redecision defect. Introduce a bounded reevaluation keyed to a meaningful change (price, stock, purse, elapsed time). Track lost work in recorder; do not add a huge shopping AI or change economic conservation.

### D18 — `SIM-F3` · answer C · **ENGINEERING**

Bandit stalk plan empty/redecision each tick is recorder-proven performance defect; keep a persistent deterministic plan while conditions unchanged and re-evaluate on real state changes. No new bandit combat/faction mechanics as part of this fix.

### D19 — `Q-POL-1; P21-STRUCTURE` · answer C · **FUTURE**

Elected mayor/council is an approved long-term direction. The currently working manor/reeve system is not to be ripped out. Draft transition and legal authority for Expansion21 once judgment is live, not in ongoing X20 economy groundwork.

### D20 — `P21-RESIDENCY` · answer C modified · **FUTURE**

Voting eligibility after 8 game days (one game year), council candidates after 16 days (two game years) as selected. Require persistent real residency and adult status; no instant arbitrary status. Implement only with approved politics rollout.

### D21 — `Q-POL-4` · answer A · **FUTURE**

Secret individual votes, aggregated published totals; deterministic internal audit. NPCs do not magically learn private ballots; all vote decisions use real judgment/knowledge.

### D22 — `Q-POL-5` · answer A · **FUTURE**

Runoff first, then qualifying service tenure, then age. Deterministic equality fallback must be explicit before final implementation; defer to Exp21.

### D23 — `Q-POL-6` · answer A · **FUTURE**

No automatic impeachment/recall. Elected term and exceptional death/permanent absence, with negative consequences on reputation and later ballots. Do not enable removal mechanics contrary to selected rule.

### D24 — `Q-POL-7` · answer A · **CURRENT**

Real voter choices must wait for operational tested individual Judgment System; no interim omniscient scripted political vote engine. Design-only scaffolding may exist without activation.

### D25 — `Q-POL-8` · answer B · **FUTURE**

Mayor/council select a constable through real governance, constable commands guards under existing law. Don't create a competing guard/crime system or assume mayor has infinite coercive power.

### D26 — `Q-POL-9` · answer B · **FUTURE**

Mayor proposes taxes within existing bands and spending, council approval for major items, finite treasury. Integrate with current tax/guard/manor ledger once authorized.

### D27 — `E22-OD-03` · answer C · **FUTURE**

Skills/craft knowledge gained by experience, real teaching/apprenticeship and records can transfer or die out across generations. Preserve existing individual capability 0–10 and no automatic inheritance of skills. No telepathic diffusion.

### D28 — `E22-OD-04` · answer C · **FUTURE**

Future physical caravans carry finite actual goods over time with capacity/danger. DO NOT assume this currently replaced the six-day intersettlement trade abstraction. Add only in approved regional stage, maintain same ledgers and saves.

### D29 — `E22-OD-05` · answer C · **FUTURE**

Autonomous distant settlements may grow, decline or be abandoned, constrained by land/housing/food. Preserve existing abstract-world state, person IDs and economic conservation; do not promise fully simulated new regions in X20.

### D30 — `E23-OD-01` · answer C · **FUTURE**

Future bandit factions may have members, territory and leaders, with actual inventory, crimes and social reintegration; not an autonomous magical spawn engine. Existing bandit behaviors and SIM-F3 fix stay in place.

### D31 — `OD-02` · answer C · **CURRENT**

Continue the simulation flight recorder, deterministic gates, conservation measures, population/performance profiling, source-tagged decision evidence. Never automatically rebalance every provisional number or rerun whole suites after no change.

### D32 — `OD-03` · answer nested selections · **GDD-REVIEW**

Split: existing 2.5D/eight-direction view, multiplayer world-tied persistence, single actor, family succession and controls are CURRENT constraints; imported Ralph/Ursula novel geography, county lore, full magic cosmology, and new PvP/combat/engine redesigns are NOT current game commitments merely because they appeared in old GDD questionnaire. See section 3.

### D33 — `OD-04` · answer B · **CURRENT**

Locks/keys/chests use ownership, existing lockpick/crime behaviors and realistic finite items. Improve only as existing system supports; don't build a new locksmith simulation or undo Build22 lockpick fixes.

### D34 — `OD-07` · answer A · **CURRENT**

Hunting is manual/intentional via combat, separate from Gather mode. Gather does not auto-target or slaughter wildlife. This was explicitly confirmed by owner in recent conversation.

### D35 — `OD-09` · answer C · **CURRENT**

Reconcile old document question IDs against newer requirements while leaving imported sources immutable. Mark superseded premises instead of assuming original GDD is a binding fresh specification. Latest user correction takes precedence.

### D36 — `OD-17` · answer nested selections · **GDD-REVIEW**

Preserve ordinary playable person, existing professions, Godot/Android/Windows/Linux, Steam Deck checklist, scalable UI and owner-controlled packaging. Do not bootstrap Bob's Mote OTA, made-up hero system, large boss/creature roster, far-future combat/magic or full MMO from this old GDD. See section 4.

### D37 — `Q18-11` · answer A · **CURRENT**

No extra settlement-wide pay/output multipliers (1.0 neutral). Existing individual 0–10 skills and industry-specific output/pay, facility effective cap, farming TIME not yield retained. Do not erase actual individual capability profiles.

### D38 — `ID-D3` · answer A conditional · **CONDITIONAL**

An identity-gate baseline may be promoted only after same-commit current-branch conservation/determinism/first-divergence audit; don't bless arbitrary code drift using an old candidate from a different commit.

### D39 — `WDR-011-Q8` · answer A · **CURRENT**

NPC's PERSONAL romance preferences affect both selecting a courtship target and accepting/refusing an eligible proposal. Preserve mandatory kinship/age/existing-partner/hard-limit checks and human player consent. Inside the eligible pool, weigh bond, opinion, circumstances, personality and ambitions. Don't double-count standing. Q8 still OPEN in staging pending import/approval recording.

---

## 2. Non-negotiable current-game constraints when resolving any of these

**Simulation/Judgment:** The existing observer-relative signed Good/Bad judgments are unique per NPC; social opinion is a weight, not a mandatory cutoff. Necessity, scarcity, family hierarchy, individual character and consequences are considered together. Need can produce a trade even with dislike; dislike can produce refusal without a universal threshold. Preserve first-talker and diminishing conversation gains, separate-days relationship pacing, witness/knowledge provenance and the learned/remembered distinction. The new **sixth aspiration of social standing** means desiring respect, NOT mechanically adding the same reputation score twice. Aspirations feature off until separately reviewed.

**Households:** Family responsibility hierarchy for caregivers = children, spouse, parents, self. Willing to give up food, coins, comfort, reasonable safety, but no automatic suicidal behavior where continued survival better protects dependents. Orphans, adopted children and spouse's parents are considered in the already-approved care rules. Use the existing family-first decision weighting; rare extreme exception preserved.

**Work and materials:** Owner has already specified general-purpose quantity-and-unit-price procurement, not mining-only wages. Deposit sustainability is shared across open pits, surface and caves; don't create underground regeneration. Independent miners can mine for themselves or sell, using actual buyers and inventory. Skill mastery is earned individually; shortages lower effective production and can affect output/time but do not erase experience. Farming improvement changes time, not the field's biological yield. No new unexplained settlement multiplier.

**Integrity and testing:** One host authoritative world; all economy transfers atomic and consent-bound; no free money/goods. Keep the current save migration chain, permanent IDs and player's world-tied identity. Preserve network security (recipient versus impersonation), Android touch and keyboard/controller functionality, and existing Messages journal persistence/retention. Test code/UI end-to-end and later real devices where required. Preserve successful exact-commit test evidence. No builds or drafts until X20 MP gate clears.

---

## 3. D32 old GDD review — what is ACTIVE versus what is ARCHIVED

The imported 39-answer packet expands D32 into a speculative foundation design drawn from an **obsolete original game-design questionnaire**. **Do not allow it to reset current MML.** This is the decisive correction the owner requested. Selected letters are preserved for trace but they are **not a blanket green light** for the original game's untouched assumptions.

| D32 part | Selection reported in imported handoff | Correct handling as of this handoff |
|---|---|---|
| 32a perspective | B | **Current:** existing oblique/isometric-feeling 2.5D top-down world with eight-direction sprites; fix roofs, depth, click/tap targeting and structures in existing engine. No wholesale 2:1 renderer conversion. |
| 32b visuals | C | **Current style constraint:** keep licensed existing asset set and targeted visual fixes; don't replace art en masse. |
| 32c multiplayer | C | **Current:** host authoritative; internet joining desired, all three platforms, 3–4 friends, world stops offline, characters bound to host world. Existing MP-INTERACT branch is done in isolation and merges **last**, subject to device tests; do not create another network architecture. |
| 32d succession | C | **Current:** one actively controlled character per connected player, family/heirs and real permanent identities, no forced successor. Respect Build22 family/lineage implementation. |
| 32e player social/PvP | C | **Mostly existing design:** human-to-human actions require consent, NPC morality applies. PvP off by default is a FUTURE gameplay extension unless already integrated and separately approved; don't disrupt multiplayer task to add it. |
| 32f combat model | C | **Keep existing combat stable:** host authority where networked. Client visual prediction/combat re-architecture only if justified in a separately approved task. |
| 32g equipped graphics | C | **Current polish path:** equipment visual layers where implemented, eight-direction assets, mobile framerate, preserve pending armor owner review; no art reboot. |
| 32h era / five Morris region starts / organic county rule / new atlas | E4/B, C, C, C | **GDD-REVIEW, PARK:** Explicitly borrowed from William Morris/Ralph/Ursula and speculative world atlas material. The original GDD is now moot as a current requirements source. Do not rewrite game era, world seed/map, counties or the world lore from these questions. Present as optional future concept ONLY if the owner later reconfirms it against the living build. Large outside-world terrain requested earlier is still a separate approved direction; it does not imply the novel's five-region atlas. |
| 32i five magic/Well choices | C / B / C / C / C | **GDD-REVIEW, PARK:** Existing combat Fireball is real and should be preserved; a sprawling elemental system, a literal Morris Well, longevity magic, lore/social religion consequences and traditional disciplines are **not** active requirements based only on old document questions. No new species, materials, or spell economy without explicit future current-game scope. |
| 32j platforms | existing | **Current:** Godot, Android/Windows/Linux, Deck controller & display support. Do not switch engines. |
| 32k mature content | A | **Current content boundary from imported owner answer:** crime, death, injury with consequences; no automatically activated thralldom/slavery transaction system just because lore mentions it. |
| 32l architecture | C | **Current workflow:** isolated branches/worker ownership, incremental integration, determinism, no redundant suites, multi-platform release gate; never restart the foundation architecture wholesale. |

A prior option selection that references a **moot question premise** is not evidence that all content described in that old source still defines the game. Record the prior selection in a non-authoritative provenance note; any broad lore/magic/world rewrite requires explicit current-game owner confirmation and its own work authorization.

---

## 4. D36 old Game Designer import — retain practical decisions, quarantine the reboot

The earlier packet mixes useful practical owner choices with imported specifications belonging to a different/outdated conception of the game. The most important correction is **no return to a chosen hero, scripted epic, fixed resource quotas or Bob's unrelated Mote infrastructure**.

| Part | Imported selection | Current-first interpretation |
|---|---|---|
| 36a protagonist | A | **Binding:** ordinary player person in independent village, no preordained chosen-one, automatic special title, guaranteed heroic destiny or scripted award system. NPCs can still form opinions based on real deeds. |
| 36b professions/research | C | **Keep present skill/career system:** individual work/experience and negotiated contracts; additional research trees/apprentice mechanics belong to later systems with separate scope. No class-lock refactor. |
| 36c unified combat | C | **Park massive expansion:** preserve today's combat, fireball and host safety. Do not begin melee-combo rewrite, archery projectile overhaul, or all-NPC tactical rework under GDD reconciliation. Future detailed combat requires owner planning. |
| 36d Deck | C | **Current target:** Steam Deck-friendly Linux output, keyboard/mouse/controller and 1280×800 legibility; cannot assert Valve Verified without actual certification. |
| 36e Mote automatic OTA | Custom D | **No automatic/silent app updater; no import of Bob's Mote infrastructure.** The handoff's selected MML preference is owner-controlled versioned APK/Windows/Linux delivery. Do not use this to override distinct manual, explicitly owner-approved delivery mechanisms of other Hot Attic Games products. If an existing MML manual update path is in use, report an actual conflict before deleting it. |
| 36f Android toolchain | C | **Maintenance only:** keep supported SDK/API requirements compliant and regression-test; no discretionary gameplay refactor and no arbitrary unsupported target claim. |
| 36g monsters and bosses | C | **GDD-REVIEW, PARK:** giant crab/dragon/necromancer/“boss” roster from old imported source is not approval to populate current MML. Existing wildlife/bandits and applicable rules stand. No mandatory final boss or scripted heroic rank. |
| 36h accessibility | C | **Current UI roadmap:** Android, larger text, HUD scales, controller menus and prompts, pause/keyboard collapse, Steam Deck. Broader aids are design-only backlog with multiplayer authority safeguards. |
| 36i sales model | C | **Design direction only:** one-time purchase rather than ads/IAP; no unauthorized Steam/Play publication, price decision or schedule. Current repo release gates take priority. |
| 36j scope/quotas | C | **Binding rejection of original quotas:** no forced exact resource/recipe/biome/monster/quest counts or linear finale; living-world needs and tested balance determine content. |

---

## 5. What the receiving Claude session should actually DO

1. **Do not implement the 39 questions now.** Read current branch, `CLAUDE.md`, staging register and owner directives first. Preserve active `wip/x20-r5`, `wip/x20-mp-interact`, `wip/expansion20`, Build22 source and any in-progress tests. Don't modify someone else's worktree.
2. Reconcile these 39 historical **answers** to existing IDs. The repository reports 39 OPEN entries; do not assume the sets coincide. For each answer, compare the present game's system and provenance. Mark `CURRENT` choices as owner-approved policy **only where they are genuinely a fresh applicable choice**. Record `FUTURE` selected direction with an explicit not-implemented scope. Mark original-GDD content `GDD-REVIEW / obsolete-premise` instead of embedding novel/magic/monster redesigns in current acceptance requirements. Escalate real contradictions, do not invent resolutions.
3. **WDR-011-Q8 = A** in imported owner's 39-answer file; reconcile into the *existing* Q8 entry (currently OPEN). For human-to-human engagements never bypass human consent; NPC eligibility and fixed kinship/courtship exclusions remain hard limits. Let R5 worker own shared judgment changes.
4. **SIM-F2/F3 are evidenced defects**, not invitations for new economic policy; propose focused recorder-backed fixes using existing state and no new long-run campaign until relevant changes land. The new package's options about learning from failure do not authorize a new autonomous loan system to repair the chisel bug.
5. **Living Economy only LE-01 is foundation integrated/off**; code LE02+ only under active approved milestone and after exact owner-policy reconciliation. Separate tills, transactions and historical memory; do not silently enable economy. If a new 39-question answer changes the current LE plan, show the before/after and effect on tests/baselines.
6. **MML multiplayer release gate unchanged**: integrate MP-INTERACT-01 last, verify actual Android/Windows/Linux host/guest and UI input. Q1/Q2 are not answered here. No Expansion 20 private or public builds before gate; no Build22 reopening.
7. Do NOT revive old GDD's Morris setting, Well lore, magic system, monsters, chosen hero, Bob/Mote updater, or fixed content quotas. Their imported selection history remains archived, not active instructions. Only a **new explicit owner approval grounded in the current MML game** can activate a future roadmap incorporating them.
8. If old roadmap docs, design-gap notes, Game Designer questionnaire or import files contradict current directives, **mark them superseded/non-authoritative** in reconciliation documents while preserving them physically. Do not delete them.
9. Give a short change report: decisions mapped to ID, truly already approved vs newly selected, GDD-REVIEW items, conflicts and dependencies, current status of branches/tests; no broad implementation. Update requirement records using the repo's prescribed requirements-update tooling only and regenerate views; never edit generated tables manually.
10. Use existing CI evidence for same commit; targeted tests for changes; verify individual operation and conservation. Owner sign-off for ambiguous gameplay policy, changed major balance, cross-platform release and publications. Context checkpoints at ~70–75% because session compaction generally occurs around 80%.

**Owner's intent:** Continue building the current My Medieval Life, not revive an old concept that was made moot last week.
