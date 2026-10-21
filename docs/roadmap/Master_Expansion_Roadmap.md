# Master_Expansion_Roadmap (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/Master_Expansion_Roadmap.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

MY MEDIEVAL LIFE
Master Expansion Roadmap and Design Starter Pack
Planning baseline | 21 October 2026 | Owner-approved scope distinguished from draft recommendations
PURPOSE. Preserve the established sequence through Expansion 19; organize the Living Economy and subsequent approved systems; create usable first-pass specifications for subjects lacking a standalone master document. This is a planning artifact, not permission to publish new builds or merge isolated branches.
Terminology and operating rules
EXPANSION N = implementation, automated testing and commits on an isolated remote development branch. BUILD N = integrated release-candidate stage: final acceptance, packaging and release checks. RELEASE N = published three-platform milestone.
The owner-approved numbered sequence is 17 Mining, 18 Settlements, 19 Judgment. Numbers 20 onward are recommendations only, until owner approval and register update.
No duplicate world ledger, NPC memory, inventory, contract or governance implementation. Extend existing authoritative systems. Preserve finite resources, world persistence, seeded determinism, migrations and long-run simulation checks.
Keep Build 16 release work separate. The 17 development branch may progress independently; final integration and release depend on appropriate gates.
Executive roadmap
Stage
Working scope
Source status
Dependencies
17
Mining & Industrial Development
Master PDF + planning docs
16 baseline; terrain audit
18
Settlement Advancement & Regional Economy
Master PDF
17 capability schema
19
NPC Judgment / Universal Decision Engine
Master PDF
16 baseline; event history
20?
Living Economy
Master DOCX
17–19 interfaces
21?
Village Politics & Civic Authority
Owner directive + world rules; starter below
19 judgment; 20 economics useful
22?
Bandit Factions & Criminal Careers
World rules + requirements; starter below
19 judgment; 20 trade useful
23?
Generational Legacy & Historical Presentation
Detailed owner directive + world rules; starter below
19 memory foundation
24? / unnumbered
World Exploration, Dungeons & Encounters
Scattered approved items; starter below
terrain/world expansion; assets
Separate track
Player-hosted Multiplayer
Detailed owner directive + active branch
branch audit and integration authorization
Documentation inventory
Expansion
Existing canonical documents / locations
Documentation gap
17
docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf; docs/EXPANSION_ROADMAP.md; wip/build17-plan decision documents
Engineering validation of underground architecture; verify proposed contract defaults
18
docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf
Implementation plan, larger-map staging, acceptance matrix
19
docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf
Resolve SJD-Q01..Q14 and integration gates
20?
docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx and .txt
OD-LE-01..15, especially placement
21?
docs/directives/2026-10-19_memory_refuges_politics.md Part III; docs/WORLD_DESIGN_RULES.md Rules 015/019; VP-01
Standalone politics master spec not verified; draft included
22?
docs/WORLD_DESIGN_RULES.md Rule 016; WDR-016-C; FAM-07/08
Standalone factions master spec not verified; draft included
23?
docs/directives/2026-10-19_memory_refuges_politics.md Part I; Rules 014/017; GM-01, DVW-B7
Consolidated implementation specification; draft included
24?
B14-09, FR-01 and future-content entries in docs/DEVELOPMENT_LEDGER.md
Full expansion scope not owner-assigned; draft only
Multiplayer
docs/directives/2026-10-19_multiplayer_foundation.md; wip/multiplayer; MP-01
Code and device validation audit; release integration decision
Expansion 17 — Mining & Industrial Development
Status: Owner assigned; planning branch established
Primary references: Mining_Industry_Expansion.pdf; EXPANSION_ROADMAP.md; Build 17 plan commits 375b855 and afbd635
Replace exhausted-resource dead ends with finite, discoverable, physically worked extraction and interdependent trades.
Approved scope and design baseline
Finite seams; quarry stone after exposed ore; prospecting, clues and assay; hidden deposits.
Open pits, excavation, usable spoil, ramps; separate underground maps under surface locations recommended in current planning; supports, carts, rails, transport and worker risk.
Mining capability levels linked to future settlement capability model; contracts and resource ownership must use shared ledgers.
Proposed implementation plan
MIN-A terrain/elevation/navigation/save and deposit audit; specify seam levels and test fixtures.
DVW-A12 refactor: move mining, felling, crafting rules into core in isolated tested steps.
MIN-B quarry and persistent exhausted-seam stone; MIN-C prospecting; MIN-D industrial capabilities with SET-A schema design.
MIN-E open pits; MIN-F enterable underground; MIN-G end-to-end economy and acceptance.
Verification and acceptance
Verify no spontaneous ore/stone; no duplication after saves or excavation.
Run 100/365-day multi-seed production and economy tests; check pathfinding, transport and performance.
Unresolved decisions / scope boundaries
Confirm architecture choice is recorded as owner approval rather than recommendation.
Owner-directed contract terms vs provisional defaults must be reconciled; no unapproved major economy redesign.
Expansion 18 — Settlement Advancement & Regional Economy
Status: Owner assigned; specification exists
Primary references: Settlement_Advancement_Regional_Economy_Expansion.pdf; EXPANSION_ROADMAP.md; SET-A..E
Make villages capable of developing distinct trades and real exchange rather than receiving guaranteed caravan income.
Approved scope and design baseline
Capability belongs to settlement infrastructure, labor, knowledge and tools, not merely population.
Regional prices and goods flow from real supply, demand, purchasing power, distance and risk.
Growth may stagnate or reverse; a small mining village can outperform a larger town in mining.
Proposed implementation plan
SET-A capability schema designed during 17; SET-B implement capability progression and skill/infrastructure requirements.
SET-C replace temporary 30-coin caravan allowance with accounted regional trading model.
SET-D settlement growth and differentiated services; SET-E physical multiple-settlement network after larger-world prerequisites.
Verification and acceptance
Prove trade goods and currency conserved across settlement boundaries.
Simulate shortages, losing workers, isolated settlements and merchant refusal to trade.
Unresolved decisions / scope boundaries
SET-E larger map likely later than 18 per current roadmap; avoid silently promising it in Release 18.
Prepare detailed engineering plan before implementation.
Expansion 19 — Subjective Judgment & Universal Decision Engine
Status: Owner assigned; detailed master spec exists
Primary references: Judgment_Decision_Engine_Master_Spec.pdf; SJD-A..H; 2026-10-19 memory directive
NPCs form individually weighted, revisable judgments; judgment influences but never automatically dictates a decision.
Approved scope and design baseline
Witnessed actions, credible hearsay, family history and competing interpretations feed memory and trust.
The 50-iron example: even a character with a strongly negative opinion may trade if the need and alternatives justify it.
Apply consistently to trade, aid, employment, crime, courtship, politics and family; no single global morality switch.
Proposed implementation plan
SJD-A/B baseline and decision-point audit; SJD-C event/belief prototype; SJD-D utility and explanation traces.
SJD-E low-risk feature-flag integration; SJD-F progressive domains; SJD-G long-run soak; SJD-H release review.
Verification and acceptance
Seeded reproducibility; explainable choices; no omniscient NPC knowledge; memory persistence and CPU profiling.
Test both friendly and hostile interpretations of same event and rational choices despite dislike.
Unresolved decisions / scope boundaries
SJD-Q01..Q14 still require disposition, not necessarily owner interruption for every tunable.
Generational memory foundation can land here, but full memorial/chronicle presentation can remain later.
Expansion 20 (proposed) — Living Economy
Status: Standalone expansion approved; number NOT yet approved
Primary references: My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx; EXP-D, LE-00..07
A village may fail, but its rules and accounting must remain consistent. Replace hidden rescues with real actor choices.
Approved scope and design baseline
Needs-driven households, firms, manor, merchants, bandits; bounded knowledge and genuine alternatives.
Bids, asks, counteroffers, prices, inventory reservations, delivery obligations, credit, breach and renegotiation.
Real work, tools, wages, transport, ownership, scarcity and opportunity cost; organic response rather than scripted production commands.
Proposed implementation plan
LE-00 audit; LE-01 actors, needs, knowledge and obligations; LE-02 negotiation and settlement.
LE-03 jobs/production/household budgets; LE-04 finance and manor; LE-05 cross-system integration; LE-06 soak; LE-07 release.
Verification and acceptance
Atomic trades; no duplicate stock commitments; trace every coin/item; long-run failure scenarios are legitimate.
Test coal exhaustion, housing shocks, smith lacking planks, insolvent manor and bandit hoards.
Unresolved decisions / scope boundaries
OD-LE-01 explicitly decides Build 20 placement; OD-LE-02..15 cover policies.
Do not silently substitute Build 17 contract defaults for the later comprehensive economic contract model.
Expansion 21 (proposed) — Village Politics & Civic Authority
Status: Approved world system; NEW consolidated starter specification
Primary references: 2026-10-19_memory_refuges_politics.md Part III; WORLD_DESIGN_RULES.md Rules 015 and 019; VP-01
Civic life is part of the simulation: actual voters, offices, duties and policy consequences, not a separate election minigame.
Approved scope and design baseline
Player and NPC may seek mayor/village leader, constable, captain of guard and guard positions.
Every eligible NPC independently evaluates candidates using known history, kinship, reputation, competence, safety, economic interest and personal priorities; may abstain.
Office succession via election, appointment, promotion, council or inheritance as appropriate; no universal election rule.
Real treasury, wages, patrols, civic work, lawful authority, campaign promises, policies and public consequences.
Proposed implementation plan
POL-A audit current manor/reeve/guard/tax/office ownership and decision events.
POL-B civic office data model: terms, selection rules, eligibility, authority, responsibilities and succession.
POL-C candidate and voter behavior using Judgment and documented memory provenance.
POL-D campaigning, policy choices and real budget execution using Living Economy interfaces.
POL-E succession, vacancy, removal, unrest and historical chronicle integration.
Verification and acceptance
Recount election from actual individual votes; test abstention, equal votes, deaths and save/reload.
Demonstrate two voters choosing differently based on known facts; never fabricate voter knowledge.
Policy must change actual finances or services, not only dialogue.
Unresolved decisions / scope boundaries
Exact franchise/term lengths and authority boundaries are not established here: design decisions, not silently fixed.
Politics after 19 is approved; numbering 21 is a recommendation.
Expansion 22 (proposed) — Bandit Factions & Criminal Careers
Status: Approved world system; NEW consolidated starter specification
Primary references: WORLD_DESIGN_RULES.md Rule 016; WDR-016-C; FAM-07/08; Living Economy sections 9/10/12
Banditry is a possible livelihood for NPCs and player, with needs, alliances, competition and consequences.
Approved scope and design baseline
Discover, join, leave, rise through and potentially lead factions; leadership challenges and autonomous succession.
Hideouts, supplies, equipment, stolen goods, livestock raids, smuggling, fences, territory and recruitment are real resources.
Distinct perceptions among bandits, villagers and guards; authorities investigate, patrol, prosecute or offer bounties based on knowledge.
Faction fragmentation, migration, survival and collapse proceed without the player; orphan-clan fallback must preserve child status.
Proposed implementation plan
BAN-A audit existing bandits, crime, property, inventory, guard, orphan and relationship systems.
BAN-B faction identity, membership, hierarchy, safehouse ownership and persistent faction resources.
BAN-C career actions, recruitment, theft/raids, resale, suspicion and response.
BAN-D rank, challenge, leadership, schism and autonomous succession.
BAN-E economy/judgment/politics integration; long-run simulations.
Verification and acceptance
No invented loot or currency; stolen items keep provenance and custody.
NPC factions can fail and disband; guards act only on knowable crimes.
Child dependents do not acquire adult combat abilities.
Unresolved decisions / scope boundaries
Leadership challenge rules, jurisdiction and faction numbers need design decisions.
Keep bandit faction work distinct from skeleton/dungeon combat content.
Expansion 23 (proposed) — Generational Legacy & Living History
Status: Approved detailed directive; NEW consolidated implementation starter
Primary references: 2026-10-19_memory_refuges_politics.md Part I; WORLD_DESIGN_RULES.md Rules 014/017; GM-01; DVW-B7
The world remembers real events, objects and relationships across generations, including the consequences of what people did.
Approved scope and design baseline
Events carry actor, witness, time, place, quantities, affected property, outcomes, provenance and causal links.
Knowledge is firsthand, told, rumored, recorded or inferred; descendants inherit stories, not firsthand memory or skill.
Graves, named headstones, family trees, biographies, property histories, life chronicle, village history and in-game wiki.
Example: thirty actual donated planks can be traced to a house, descendants and later dialogue only if the game recorded the chain.
Proposed implementation plan
LEG-A reconcile Expansion 19 event/belief store and prevent a second history database.
LEG-B persistent event graph, significance/retention, kinship and provenance links.
LEG-C dialogue from real history, memorial biographies, graveyard and chronicle presentation.
LEG-D lineage and heir continuity, political/criminal/professional careers, damaged/rebuilt/sold properties.
LEG-E historical query performance, saves and long-run multigenerational tests.
Verification and acceptance
No fictional causal links, omniscient gossip or duplicate events after reload.
Test multiple generations, disputed memory, heir identity and destroyed/rebuilt house history.
Unresolved decisions / scope boundaries
Much of foundation belongs in 19; only remaining historical presentation and long-range systems should be a separate expansion.
Number 23 and final boundary need approval.
Future unnumbered — Exploration, Dungeons & Encounters
Status: Partially approved features; DRAFT grouping only
Primary references: DEVELOPMENT_LEDGER.md B14-09, FR-01; prior owner world exploration and magic discussions
Connect the starting village to a larger county and broader world, with meaningful encounters and consequences rather than making the player the predetermined hero.
Approved scope and design baseline
Approved tracked item: skeletons in caves and uncleared woods, guarding by day, roaming at night, three-day respawn, bones and rusty gear.
Lizards and spiders are approved enemies but blocked pending suitable owner assets.
Earlier owner direction supports a vast explorable overworld, broader county, world consequences and learnable, rule-based magic rather than birthright.
Proposed implementation plan
WORLD-A audit map scale, streaming, navigation, save identities and mining cave entrances.
WORLD-B specify overworld regions, encounter locations and travel persistence; do not assume infinite procedural generation is technically available.
WORLD-C implement approved skeleton behaviors and loot under existing combat and conservation rules.
WORLD-D integrate environmental encounters, performance and multiplayer boundaries; define magic as separate scoped work before coding.
Verification and acceptance
Saved travel state and encounter state consistent across reload.
No enemies respawn into occupied/invalid locations; asset/license validation and device performance.
Unresolved decisions / scope boundaries
This grouping is NOT a fully approved expansion or numbered release. Castles, dungeons, large-world implementation and magic mechanics need separate scope decisions.
Avoid merging cave-mining architecture with dungeon gameplay merely because both use underground maps.
Parallel track — Player-hosted Multiplayer
Status: Existing active branch; NOT verified as a shipped Build 15 feature
Primary references: 2026-10-19_multiplayer_foundation.md; wip/multiplayer; MP-01; DGA-D3
Minecraft-style host/join for two to four people, with host-authoritative world and characters bound to that world.
Approved scope and design baseline
Windows/Linux host and Android guest first; Android hosting later; no dedicated server requirement.
LAN discovery, host/join UI, movement, facing, animation, disconnect/reconnect, stable player identity and saved gear.
Host simulates NPCs, economy, wildlife and time; clients request actions; world stops when host stops.
Proposed implementation plan
MP-A forensic audit of wip/multiplayer vs Build 15 commit and staging; identify implemented code and passing tests.
MP-B two real instances, host discovery, movement, reconnection and persistence; retain single-player behavior.
MP-C four players, shared commerce/crafting/harvesting/combat with host-validated atomic transactions.
MP-D cross-platform real-device testing, Android hosting and optional later internet invitations.
Verification and acceptance
Two separate Godot processes plus actual devices; measure sync, duplication, bandwidth and save identity.
Never claim shipped multiplayer merely from the branch or a passing connection test.
Unresolved decisions / scope boundaries
Ledger says active development on isolated branch and partially implemented connectivity; Build 15 inclusion not proven.
Do not merge wip/multiplayer into staging without explicit owner authorization.
Cross-expansion dependencies and recommended workstream order
17 supplies finite materials and settlement capability schema design; 18 turns capability into regional specialization and replaces placeholder caravan income.
19 provides individual judgment and memory interpretation; 20 adds generalized need/market/contract behavior, using judgment as one factor.
21 political votes require 19 and benefit from 20; 22 outlaw choices depend on 19 and economic interactions benefit from 20.
23 legacy should reuse the 19 event store, not wait to begin all underlying historical recording.
Multiplayer remains a separately gated branch; audit before promising release placement or Build 15 completion.
World exploration can be designed in parallel but must respect 17 underground mapping, 18 larger-region plans and future multiplayer persistence.
Immediate documentation actions
Register this document as a roadmap proposal; retain owner-approved 17–19 numbering. Request explicit owner designation before converting 20–23 to official build targets.
Extract sections 21, 22, 23 and World Exploration into individual master design documents, preserving their source citations and draft/approved distinctions.
Have Claude compare each new starter against the original owner directives and existing requirement IDs, then record missing technical decisions without manufacturing owner approvals.
For 18, produce a phase-by-phase engineering plan; for 19, reconcile SJD questions; for multiplayer, compare wip/multiplayer to Build 15 and run two-instance tests.
Keep all plans under version control on a documentation/planning branch, not in Build 16 release code.
Canonical source paths
docs/EXPANSION_ROADMAP.md
docs/DEVELOPMENT_LEDGER.md
docs/WORLD_DESIGN_RULES.md
docs/directives/2026-10-20_two_decisions_three_expansions.md
docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf
docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf
docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf
docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx
docs/directives/2026-10-19_memory_refuges_politics.md
docs/directives/2026-10-19_multiplayer_foundation.md
docs/CURRENT_DEVELOPMENT_STATE.md
Source note: repository paths and requirements were inspected through connected GitHub at the staging branch on 21 October 2026. Owner discussions supply additional direction where identified. Proposed architecture, sequencing and acceptance outlines in newly drafted sections are starting specifications, not claims of existing implementation or new owner decisions.