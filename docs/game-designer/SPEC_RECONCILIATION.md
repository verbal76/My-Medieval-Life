> **HISTORICAL / SUPERSEDED DESIGN SOURCE — NOT ACTIVE DEVELOPMENT AUTHORITY (owner, 2026-10-27).** This file records early Game Designer interview material, a prototype decision or an obsolete design proposal. Retain it for provenance, not as a current specification, task list, owner approval or permission to implement features. Current guidance comes from `CLAUDE.md`, `docs/PROJECT_MEMORY.md`, `docs/requirements/requirements.json`, later applicable owner directives and validated game code. See `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md`. An old design idea needs new owner confirmation before becoming active.

# Game Designer spec: reconciliation with the project

Register entry: REC-004 (`docs/requirements/requirements.json`). Written 2026-10-20.

This document compares the Game Designer ("Bob") spec in this folder with what the repository records. It does not
change any decision. It does not answer any owner question. No spec item becomes approved because it is listed here.

## How to read it

**Sources compared.**

- **Spec:** `docs/game-designer/THE_WELL_SPEC_v1.md` (Bob's `CLAUDE.md`, stored under that name). "L12" means line 12 of that file.
- **Prompt:** `docs/game-designer/MASTER_PROMPT.md`.
- **Notes:** `docs/game-designer/CORRECTION_NOTES.md`.

**The project's records.**

- Root `CLAUDE.md`.
- `docs/DECISIONS.md`. Its entries are cited by date and opening words, because the table has no numbers.
- `docs/GAME_DESIGN.md`.
- `docs/BUILD_DECISIONS.md`.
- `docs/PROJECT_MEMORY.md`.
- `docs/WORLD_DESIGN_RULES.md` (WDR).
- `docs/EXPANSION_ROADMAP.md`.
- The register: `docs/requirements/requirements.json`, cited by entry id.

**Which side wins.** Owner decisions and owner directives recorded in the repository win over the spec. Agent
proposals in the repository do not outrank the owner's interview answers in the spec. Where only an agent proposal
stands against an owner answer, the row says so.

**Classes.**

| Class | Meaning |
|---|---|
| AGREES | The project records the same thing. The row cites where. |
| DIFFERS | The project records something else. The row says how, and which side wins. |
| NOT IN PROJECT | Only the spec has it. It stays an open question. It is not adopted here. |
| OBSOLETE | A later owner decision or directive has replaced it. The row cites that decision. |
| UNRESOLVED | Used inside a row when the evidence does not settle a point. The row gives the reason. |

## Context: how the spec reached the project

- **2026-10-17T18:44Z.** The owner uploaded `The_Well_corrected_two_documents.zip`, the three files in this folder.
- **18:46Z, owner message #27.** On the name, the owner answered: "In the repository and in all of our developments
  called my medieval life, but the working title that might be the publishing title is probably going to be the well
  because it's based on the novel the well of the end of the world". This is the register's REC-005 source.
- **Owner message #27, the instruction.** The register's REC-004 `owner_wording` quotes its first and last sentences.
  The full text below comes from the session transcript of 2026-10-17, which is not in the repository.
  `docs/requirements/RECOVERY_2026-10-19.md` rows 19-21 summarize it.
  - "Merge the corrected documents with the existing Medieval Life project documentation, but do not begin
    implementing game features."
  - "Treat The Well as the working game title only. Do not rename the repository, Android package, project
    directories, or application identifiers without my explicit approval."
  - "Resolve contradictions by comparing Bob's specifications against our established design decisions. Do not
    automatically assume either document is correct."
  - "Preserve the existing Mote system and its integration requirements. Identify any missing access or dependencies
    rather than inventing replacements."
  - "Correct Steam Deck platform labeling without changing supported platforms."
  - "Before modifying any files, show me exactly what you intend to merge, preserve, replace, or remove".
- **18:48Z.** The agent presented a merge proposal with conflicts C1-C13 and four questions. Nothing was merged.
- **Owner message #28 (18:48Z).** The owner then asked to build "the first playable version of The Well" from "the
  Game Designer documents we have just reviewed and reconciled", aiming at "a fully playable medieval village populated
  by 100 NPCs".
- **Open since then.** The proposal's questions (C1, C2, C10, "Where is Mote?") were never answered on the record
  (REC-004 `approval`; REC-010 `source`).
- **No handoff documents.** Bob's other handoff documents were never supplied. These include `EXCLUSIONS.md`,
  `REQUIREMENTS_LEDGER.md` and `project.json` (notes L5; `docs/requirements/RECOVERY_2026-10-19.md` line 25).

## 1. The owner's interview answers recorded in the spec

These are the answers that Part A presents as the owner's own (spec L64-L177, L680). The quotes are the spec's exact
words.

| # | Spec's words (line) | Class | Recorded in the repository? Where |
|---|---|---|---|
| I-01 | **Game name.** "**Game name:** The Well (owner said: "The Well")" (L153) | DIFFERS | **Recorded in the register only:** REC-005, COMPLETE AND VERIFIED, quoting the owner's later answer. It limits The Well to a working title. "Do not rename the repository, Android package, project directories, or application identifiers without my explicit approval." **Repository wins.** The repo name, package and identifiers stay My Medieval Life (`game/export_presets.cfg` `com.hotatticgames.mymedievallife.dev`). **Not in `docs/DECISIONS.md` or the root `CLAUDE.md`.** `docs/BUILD_DECISIONS.md` mentions the name only in its title. |
| I-02 | **Genre.** "**Genre:** Survival / crafting, RPG, Simulation / management / idle" (L108) | AGREES | `docs/GAME_DESIGN.md` Confirmed 2 ("Mini RPG") and 8 ("an open-world life simulation with RPG mechanics"). "Idle" appears nowhere in the project. |
| I-03 | **World structure.** "**World / level structure:** Large connected/open map" (L109). Part E: "The world is one connected open map; never convert it into discrete levels." (L684) | AGREES | `docs/DECISIONS.md` 2026-10-18 "The map's hard border is replaced by a seed-generated, chunk-streamed overworld" (B8-011). Also 2026-10-18 "Building interiors use a roof fade, not separate interior scenes: the world stays continuous". `docs/GAME_DESIGN.md` U5 still lists world structure as undecided. |
| I-04 | **View and dimension.** "**2D or 3D:** 2.5D (owner said: "2.5D")" (L110). "it's going to be like a top-down pixel map, but the characters aren't going to be top down. They're going to be kind of at an angle" (L72-L73). "It will have eight directional Sprite characters with animated Sprite sheets and it'll be almost isometric so it'll be you're looking at it top down with the the buildings that you won't just see the top of the building. You'll see a little bit of the side and the edge." (L92-L93) | DIFFERS (UNRESOLVED) | **The project records:** `docs/DECISIONS.md` 2026-10-17 "Working visual direction: 2D/2.5D isometric with 8-direction animated sprites" (Owner, directive §11). The same appears in `docs/GAME_DESIGN.md` Confirmed 11. **The spec's own wording varies:** its reconciliation reads the answer as "2.5D / three-quarter view" (L16), but its section 2 says "**Perspective:** Top-down" (L245; prompt L47). **What "isometric" means is an open owner decision:** DGA-D1 (`docs/DESIGN_GAP_ASSESSMENT.md` section 12, D1) and OD-03. **Open call C10** (section 4). |
| I-05 | **Audience.** "**Intended audience:** A general audience" (L111) | NOT IN PROJECT | No record. The target rating is open (`docs/GAME_DESIGN.md` U21). |
| I-06 | **Game length.** "**Expected game length:** Endless (owner said: "Endless")" (L112) | NOT IN PROJECT | No decision records it. It fits WDR 005 (a world living on its own), but it is not recorded as an answer. |
| I-07 | **Multiplayer.** "**Multiplayer:** Host-owned persistent world; first-milestone networking scope unresolved" (L113) | AGREES | `docs/DECISIONS.md` 2026-10-17 "Multiplayer: player-hosted worlds for about 3–4 players, no always-on central server; the world stops when the host stops" (Owner). `docs/GAME_DESIGN.md` Confirmed 10. Register MP-01 (two-player LAN milestone, host-authoritative, `docs/directives/2026-10-19_multiplayer_foundation.md`). |
| I-08 | **Platforms.** "**Target platforms:** Android, Windows PC, Linux, Steam Deck (handheld PC) (owner said: "Android, Windows PC, Linux, Steam Deck (handheld PC)")" (L114) | DIFFERS | **The project records three platforms:** `docs/DECISIONS.md` 2026-10-18 "Platforms: an installable Android APK first, then a PC version" (Owner); `docs/GAME_DESIGN.md` Confirmed 13 (Android, then Windows and Linux); root `CLAUDE.md` section 1. **Steam Deck is not named as a target in any decision.** It appears only in release notes ("Linux / Steam Deck (desktop mode)", `docs/release/BUILD_13_PACKET.md`) and in device-check lists. **The owner said to correct the label without changing the platforms** (#27, quoted above). The owner's instruction stands. How Steam Deck is labelled is open (section 4). |
| I-09 | **First platform.** "**First platform to build and test:** Android" (L115) | AGREES | `docs/DECISIONS.md` 2026-10-18 "Platforms" (Owner). Root `CLAUDE.md` section 8. |
| I-10 | **Feeling.** "**Intended feeling:** I want them to feel like they're accomplishing something like they're building towards a better character and a bigger, better story" (L116) | NOT IN PROJECT | No record. |
| I-11 | **Core loop.** "**Core gameplay loop:** Explore find something neat. Do something with it. Be able to do something different. Explore" (L117) | NOT IN PROJECT | `docs/GAME_DESIGN.md` U4 ("Core loop") is still open. The owner's answer is not recorded there. |
| I-12 | **Movement feel.** "**Movement and camera feel:** Smooth and responsive" (L118) | NOT IN PROJECT | Not recorded as a requirement. Related work: CQ-01 (sword responsiveness) and the camera dead zone (`docs/BUILD_DECISIONS.md` "Controls, screen and settings"). |
| I-13 | **Combat.** "**Combat style:** Aim and shoot in real time, Melee and combos, Abilities on cooldowns" (L119). Owner correction: "**Combat:** Yes [corrected by the owner]" (L157) | AGREES (part UNRESOLVED) | **Recorded:** register REC-009, approved, UNKNOWN — INVESTIGATION REQUIRED, target 20+. **Built:** sword combat (`docs/DECISIONS.md` 2026-10-18 "Attack mode"; 2026-10-19 "Sword combat responsiveness"), and Fireball with a cooldown. **Not built:** combos and aimed ranged attacks. Archery is DEFERRED (FR-10). The CQ-01 entry says "archery not authorised". When ranged combat comes is open (section 4). |
| I-14 | **Hero.** "**Characters / classes:** One hero (owner said: "Your main character is the hero")" (L120) | DIFFERS (UNRESOLVED) | `docs/DECISIONS.md` 2026-10-17 "The player is an ordinary inhabitant of an original village in an original county, **not the chosen one**" (Owner). The same appears in `docs/GAME_DESIGN.md` Confirmed 8. Whether "one hero" conflicts with this is **open call C1** (section 4). |
| I-15 | **Progression.** "**Progression:** New abilities and equipment" (L121) | AGREES | Skills with perks and tiers (`docs/BUILD_DECISIONS.md` "Skill tiers and the XP curve", agent proposals). Equipment slots (`docs/DECISIONS.md` 2026-10-18 "Inventory"). Fireball learned from the sage (`docs/DECISIONS.md` 2026-10-18 "The first storyline quest"). |
| I-16 | **Classes and tech tree.** "It's going to have class progression, system jobs, whole nine yards." (L77). "The game has class progression and system jobs" (L91). "I like a mix of an tech and research tree and new abilities and equipment" (L101) | DIFFERS (UNRESOLVED) | **Recorded:** register REC-010, approved, UNKNOWN, target "owner decision". **Not built:** no class system and no tech or research tree. **Conflicting text:** the living-world reference says "without being forced through a class or level ladder" (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §1, line 12). That document is "Conceptual, non-binding", and line 12 is outside its §2 "established intent". So neither side clearly wins. **Open call C2** (section 4). |
| I-17 | **Economy.** "**Economy and resources:** The world operates as a fully simulated medieval production economy. ... Goods and money physically change ownership through transactions rather than appearing from nowhere. ... The world simulation pauses when the host closes the game and resumes when reopened." (L122-L128) | AGREES | `docs/DECISIONS.md` 2026-10-17 "Living world: an interdependent production economy with real movement of goods and money" (Owner). `docs/GAME_DESIGN.md` Confirmed 12. WDR 001-005 and 013. |
| I-18 | **Citizens and simulation speed.** "Citizens are persistent people with names, homes, jobs, inventories and real money. ... Simulation speed: Near the players, NPCs are fully simulated; far away, they are simulated in simplified scheduled steps, and nothing duplicates when they switch between the two." (L129-L131) | AGREES | Citizens: as I-17. **Near/far tiers:** register REC-008, approved, UNKNOWN, target 20+. **Built today:** villagers near the player update every frame and the rest every 0.5 s, by the same rules (`docs/BUILD_DECISIONS.md` "Village and people"). No abstract tier exists. |
| I-19 | **Building rules.** "Players can build a house and live in it. You can only build on land you own or rent, and buildings snap to a grid. ... A wooden-frame construction site appears with a sign ... Building takes materials only, with no extra build time. ... A half-finished site can be cancelled, and everything put in is returned. NPCs build the same way under the same rules. You start by building houses, then workshops ... Your house is where you sleep, store belongings and respawn ... Damage, repair, fire and selling buildings will be decided later." (L133-L143) | AGREES | **The rules:** `docs/DECISIONS.md` 2026-10-18 "Property and construction (after the audit ...)" (Owner): owned or leased ground, hired helpers, workshops after a house, crowded households building by the player's rules. Phase 2 (2026-10-18). `docs/BUILD_DECISIONS.md` "Player", "Building" row (frame, progress bar, materials only, cancel returns everything). **Home as respawn point:** `docs/HOUSING_LAND_AUDIT.md` line 19 ("the home is the heir's respawn point"). **Changed since:** selling is no longer "decided later". The owner decided the player may sell their house (same 2026-10-18 entry). **Not built:** villagers never build workshops (`docs/BUILD_DECISIONS.md` "Known gaps"). |
| I-20 | **Open numbers.** "Not decided yet: exact production rates, population size and game-time speed. Start small: one village, one mine, one smith, one food seller." (L145) | OBSOLETE | **Population:** set at 100 (owner #28; `docs/BUILD_DECISIONS.md` "Village and people"). **Game time:** set by the owner, "One world calendar ... a game year is 8 game days" (`docs/DECISIONS.md` 2026-10-19). **Production rates:** still agent proposals in `game/data/balance.json`, provisional until a balance review (`docs/DECISIONS.md` 2026-10-18 "Theft fines, success chances ..."). |
| I-21 | **Death.** "**Difficulty and failure:** Character permadeath with descendant succession; no world/run reset; inheritance details unresolved" (L146) | AGREES | **Owner decisions:** `docs/DECISIONS.md` 2026-10-18 "An heir inherits only the starting kit ..." and 2026-10-19 "Heirs come from the family graph ...". **Rules as built:** `docs/BUILD_DECISIONS.md` "Player", "Permadeath" row. The "inheritance details unresolved" part is now OBSOLETE (S-06). |
| I-22 | **Art style.** "**Art style:** Pixel art (owner said: "Pixel art")" (L147) | AGREES | `docs/GAME_DESIGN.md` Confirmed 3. Root `CLAUDE.md` section 8 (nearest-neighbour, integer scale). |
| I-23 | **Budget.** "**Budget:** A small budget if it clearly helps" (L148) | NOT IN PROJECT | No record. Root `CLAUDE.md` section 11 requires owner authorization for paid services and dependencies with cost. |
| I-24 | **Updates.** "**Over-the-air updates:** Yes - over-the-air updates (Mote architecture)" (L149). "**What must be updateable after install:** Text and translations, ... Scripts, Gameplay logic, Engine behavior, Native code" (L150). "**How automatic updates are:** Fully automatic" (L151) | AGREES | **Recorded:** register REC-002, approved, BLOCKED, target 20+, quoting these answers. **Not recorded** in `docs/DECISIONS.md`. **Not built:** no update system exists. **Spec's own limit:** "Native code and engine behavior cannot be updated over the air on any platform" (L486). |
| I-25 | **Test builds.** "**How test builds reach you:** GitHub pre-release with the file attached" (L152) | OBSOLETE | **Base agrees:** `docs/DECISIONS.md` 2026-10-18 "Every build (APK, Windows, Linux) is published under GitHub Releases" (Owner). **Changed since:** Builds 1-7 were pre-releases (`docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md` line 290). Since Build 8, the owner's decision is "the release workflow now makes a draft release by default (visible only to collaborators)" (`docs/DECISIONS.md` 2026-10-18 "Build 8 is authorized as a private testing build only"; root `CLAUDE.md` section 5). |
| I-26 | **Lore.** "The lore of this game is going to be based off of the well at the end of the world book." "I have a complete geographical locations MD file and a entire lore file already in the repository" (L102-L103) | AGREES | `docs/DECISIONS.md` 2026-10-17 "The game's world is built on William Morris's *The Well at the World's End*" (Owner). `docs/GAME_DESIGN.md` Confirmed 7. The research is in `docs/world/` and `research/`. |
| I-27 | **Places.** "It's going to have taverns houses castles dungeons caves the whole nine yards." (L76). "I don't want it to be as expansive as Skyrim." (L79) | AGREES | **Recorded:** register REC-006, approved, DEFERRED, target 20+. **Built:** taverns and houses. **Not built:** castles, dungeons and caves. Cave mouths are planned with B14-09. The "Skyrim" remark is not recorded anywhere; the spec itself tags it "contextual statement". |
| I-28 | **NPC lives.** "I want the NPCs all to have lives and jobs so they're all going to do their own things. Think of all the characters and like the children of the Nile games." (L80-L82) | AGREES | WDR 005 (Living World Independence). `docs/DECISIONS.md` 2026-10-17 "Living world". |
| I-29 | **Crafting and sourcing.** "But I also want crafting and once you have to go out and craft things, don't you have to go source materials? You might have to mind your own materials hunting." (L83-L84) | AGREES | Recipes and resources as data (`game/data/recipes.json`, `game/data/resources.json`; root `CLAUDE.md` section 4). Hunting: `docs/DECISIONS.md` 2026-10-17 "Farm animals are livestock that become meat; wild animals live in the woods and are hunted for meat" (Owner). |
| I-30 | **Example play.** "Find an iron deposit. I forge a sword out of the iron and then I go on a quest and I start defeating bandits and random enemies. And on the way I meet an NPC who gives me the power of fireballs" (L95-L97) | AGREES | Iron, smithing and bandits exist (`docs/BUILD_DECISIONS.md` "Village and people"). `docs/DECISIONS.md` 2026-10-18 "The first storyline quest: learn Fireball from the sage in the hut to the north" (Owner). |
| I-31 | **First build.** "I want a small playable village. I want all the different NPCs markets, stalls, minerals, all the resources. I want the skill tree laid out and I want a starter character and I want to progress all the way through to collecting everything I need to make a weapon armor and build a house" (L104-L106, L165) | AGREES | **Village and stalls:** `docs/BUILD_DECISIONS.md` "Village and people". **Skills window:** "Skill tiers and the XP curve". **Armour recipes:** "Side quests" (leather armour at Crafting 2). **House building:** I-19. |
| I-32 | **Done when.** "I need a fully playable entire village. The village should have maybe 100 NPCs. I should be able to use every part of the game crafting mineral collection interactions, buying stuff from vendors the whole 9 yd" (L171) | AGREES | 100 villagers in 23 households (`docs/BUILD_DECISIONS.md` "Village and people"). `docs/PROJECT_MEMORY.md` "What the project is". |
| I-33 | **Must not change.** "It should not reinterpret that the game itself is alive and we're interacting with a simulation" (L680) | AGREES | WDR 005. `docs/PROJECT_MEMORY.md`: "the player is the variable that changes its history, not what keeps it alive". |
| I-34 | **Asset policy.** "Asset policy: **free/CC0 assets, then original work, cat.characters=supplied>original, gaps=default** (chosen by the owner)." (L177; Part E L685) | DIFFERS | **Repository wins.** The owner's later standing asset policies use the owner's bought and supplied packs (root `CLAUDE.md` section 3, "Asset licensing, copyright standing and credits" and "Asset integration policy", owner 2026-10-18 and 2026-10-19). Example: `docs/DECISIONS.md` 2026-10-18 "Every button comes from the flat UI pack the owner supplied". **The spec contradicts itself:** L175 itself says "The owner did not say what to use for the gaps; that part is Bob's default", and L179 makes supplied packs "the FIRST choice for every asset need". |

## 2. The rest of the spec, section by section

### Bob's corrected interpretation (spec L7-L21, prompt L3-L17)

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-04 | Game identity: "A living medieval-world RPG/life simulation, not a conventional quest hub or roguelite" (L11) | AGREES | `docs/GAME_DESIGN.md` Confirmed 8 and 12. WDR 005. |
| S-05 | **Multiplayer.** Host owns the world, the world pauses when the host closes, "Whether networking must ship in the first playable milestone is **UNRESOLVED**" (L12; also L451, L464; prompt L32) | AGREES | **Agrees:** as I-07. **Timing since set by the owner:** MP-01 (a two-player LAN milestone on its own branch, `wip/multiplayer`). Merging it into staging needs the owner (`docs/PROJECT_MEMORY.md`, "What must not begin without further authorization"). |
| S-06 | "Exact inheritance, descendants' availability, and what skills transfer remain **UNRESOLVED**" (L13) | OBSOLETE | **Inheritance:** answered by the owner, `docs/DECISIONS.md` 2026-10-18 "An heir inherits only the starting kit ... starts every skill from nothing". **Heir choice:** 2026-10-19 "Heirs come from the family graph". |
| S-07 | **NPCs and economy.** Conserved quantities and "no arbitrary restocking". "Near NPCs use detailed simulation; distant NPCs use consistent abstract simulation" (L14) | AGREES | WDR 004, 005 and 013. `docs/DECISIONS.md` 2026-10-17 "Living world". The tier names are recorded in `docs/DECISIONS.md` 2026-10-17 "Adopt the simulation tier names Detailed / Abstract / Dormant" (Agent). The abstract tier is not built (REC-008). |
| S-08 | **Production.** Interdependent gathering through commerce. "Exact recipes, rates and counts remain design work" (L15) | AGREES | WDR 001-003. `game/data/resources.json`. Metallurgy is extended by Expansion A (`docs/EXPANSION_ROADMAP.md`, Build 17). |
| S-09 | **First milestone.** "Demonstrate a coherent end-to-end economy ... before scaling to the owner's requested playable village of roughly 100 NPCs" (L17) | OBSOLETE | Owner #28: "Do not reduce the target population of 100 NPCs". The village has 100 (`docs/BUILD_DECISIONS.md` "Village and people"). |
| S-10 | **World generation.** "Procedural world generation is **UNRESOLVED**" (L18) | OBSOLETE | **Village:** fixed by the owner, `docs/DECISIONS.md` 2026-10-19 "Village generator v6, one new fixed village" (Owner). **Overworld:** seed-generated, an owner-approved task, `docs/DECISIONS.md` 2026-10-18 "The map's hard border is replaced by a seed-generated, chunk-streamed overworld". **Future villages:** the owner set the direction for procedural villages, `docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md` Phase 2 (PVG-01..07). **Always:** generation is deterministic (root `CLAUDE.md` section 6). |
| S-11 | **Unsupported additions.** "Bosses, a mandatory ending, renewable resource respawn timers ... are **PROPOSED/UNCONFIRMED** ... Finite ore deposits ... must not be undermined by arbitrary respawning" (L20) | AGREES | **Finite resources:** WDR 013; WDR 018 and `docs/DECISIONS.md` 2026-10-19 "Protected breeding refuges ... no instant respawning". **Not a resource respawn:** the owner approved skeletons with a "3-day respawn" (B14-09). They are monsters, not a resource. |
| S-12 | **Evidence.** "Distinguish explicitly confirmed, inferred, proposed, and unresolved requirements" (L21) | AGREES | Root `CLAUDE.md` section 9a ("Ideas are not approvals") and section 12. |

### Authority and lifecycle (spec L1-L41, prompt L1, L19-L28)

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-01 | **Authority.** "This file is the authoritative specification for **The Well**" (L39). The prompt says to read the repository-root `CLAUDE.md` as "the authoritative specification" (prompt L22) | DIFFERS | **Repository wins.** The root `CLAUDE.md` is the project's single rules file and wins where another document disagrees (its opening paragraph; `docs/DECISIONS.md` 2026-10-17 "`CLAUDE.md` is the single project rules file"). Bob's file is stored here as reference (`README.md`). |
| S-02 | **Lifecycle marker.** `<!-- GAME-DESIGNER-LIFECYCLE: PROTOTYPE -->` and the handoff rules (L5, L23-L35; prompt L25-L28) | OBSOLETE | **The project follows the owner's directives:** root `CLAUDE.md` section 0; OVN-01 and ROAD-01 (`docs/DECISIONS.md` 2026-10-20 "Five-build roadmap"). **By the spec's own trigger:** an owner instruction "beyond the prototype scope" ends the prototype phase (L27). The owner's later directives (new mechanics, three expansions) are such instructions. **UNRESOLVED:** no record says the owner formally accepted a prototype. The stored copy keeps its `PROTOTYPE` marker, because it is never edited. |
| S-03 | **Who decides.** "Creative and product decisions belong to the owner; engineering decisions belong to you." (L41; prompt L148-L149) | AGREES | Root `CLAUDE.md` section 11. OVN-01 (autonomous engineering, `docs/directives/2026-10-20_master_overnight_development_directive.md`). |

### Part A0: Hot Attic Games platform policy

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-13 | "Android Target API 36 is REQUIRED" (L47-L53; prompt L41) | AGREES | **Recorded:** register REC-003, approved, UNKNOWN, target 15. **Investigated:** the Android builds already target API 36 through Godot 4.7.2's template (`docs/release/OVERNIGHT_REPORT_2026-10-20.md`, REC-003 row). **Not recorded** in `docs/DECISIONS.md` or the root `CLAUDE.md`. The owner's confirmation of the policy is open (section 4). |
| S-14 | **OTA mechanism.** Over-the-air updates on the Mote reference: fingerprint, signed artifacts, staging, rollback, owner-controlled publication, static hosting, "INTERNET only" (L55-L62, L475-L490; prompt L42) | AGREES | **Recorded:** REC-002, BLOCKED, target 20+. **Not built:** no update system. **The Mote code was never located:** the register notes a lead, verbal76/Axolotl titled "Mote". Network features also need owner authorization (root `CLAUDE.md` section 11). The hosting rules (L490) are not designed yet. |

### Part B: recommendations the spec says the owner accepted or delegated (L191-L194)

Bob's Part D says these two were "Delegated to Bob's recommendation" (L671). The project has no record of that
delegation.

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-15 | **Survival meters.** "Core survival needs (health plus one or two meters)" (L193) | AGREES | **Built:** health, hunger and stamina; the HUD shows heart, food bag and bolt (`docs/BUILD_DECISIONS.md` "Controls, screen and settings", UI pack row). **Not recorded as decided:** `docs/GAME_DESIGN.md` U15 ("Survival systems") still lists it as undecided. |
| S-16 | **Tools and recipes.** "tiered tools and stations, recipes in data files" (L193) | AGREES | `game/data/recipes.json`. Tool tiers and stations in `docs/BUILD_DECISIONS.md` ("Skill tiers", "Health, jobs and stations"). |
| S-17 | **Hotbar.** "a hotbar+inventory UI with search/filter" (L193) | NOT IN PROJECT | **What exists:** an inventory with item tabs and gear slots (`docs/DECISIONS.md` 2026-10-18 "Inventory"). **Not built:** no hotbar and no search or filter in `game/scripts`. A hotbar is mentioned only in `docs/release/BUILD_11_PUNCH_LIST_1.md` (PL1-08). |
| S-18 | **Finite deposits.** "resource nodes governed by finite deposits, replenishment where ecologically appropriate, and conservation rules" (L193) | AGREES | WDR 013 and 018. `game/data/resources.json` (`tools/check_resources.py`). |
| S-19 | **Story.** "**Story:** Full story with dialogue" (L194, L261) | DIFFERS | **Repository wins** (an owner answer). The owner chose "Side quests now, story later (Recommended)" (register REC-011, DEFERRED). **Built:** one story quest, Fireball (`docs/DECISIONS.md` 2026-10-18 "The first storyline quest"). **The world's story is history:** "the novel's story is the world's history, not the player's quest" (`docs/DECISIONS.md` 2026-10-17). Related to C1. |

### Part C: Bob's engineering defaults (L196-L223)

The spec calls these "designer assumptions, not owner requirements" (L196).

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-20 | **Saving.** "**Saving:** Autosave with Continue" (L203, L512) | AGREES | **Built:** autosave every game hour (`game/scripts/main.gd`, `autosave_hour`) and a Continue button (`game/scripts/ui/game_ui.gd`). **Save safety:** `docs/DECISIONS.md` 2026-10-18 "Post-audit remediation ... saves go through `SaveStore`". **Not recorded as decided:** `docs/GAME_DESIGN.md` U6 still lists save behaviour as undecided. |
| S-21 | **Tutorial.** "**Tutorial / onboarding:** Dedicated interactive tutorial" (L204, L260) | DIFFERS | **Repository wins** (an owner direction). The project gives "Guidance without a tutorial": the first message, journal notes and "Trade with …" (`docs/BUILD_DECISIONS.md` "Paid work for the player", "owner, 2026-10-18, B7-005"). |
| S-22 | **Effects.** "**Effects and game feel:** Moderate" (L205, L353) | NOT IN PROJECT | No record. |
| S-23 | **Audio.** "**Audio and music:** Music and sound effects" (L206, L354) | AGREES | **Recorded:** register FR-08 "Music and sound", approved, BLOCKED, target 20+. **Not built:** "No audio yet" (`docs/BUILD_DECISIONS.md` "Known gaps"). |
| S-24 | **Menus and settings.** "Main menu, Pause menu, Volume controls, Graphics quality, Controls, Accessibility, Reset/erase save data, Credits and licenses" (L207, L356) | AGREES | **Settings:** volumes, display, interface size and buttons (`docs/BUILD_DECISIONS.md` "Controls, screen and settings"; `docs/DECISIONS.md` 2026-10-18 "Controls"). **Credits page:** root `CLAUDE.md` section 3. **Not recorded:** graphics-quality, accessibility and reset-data options. |
| S-25 | **Accessibility.** Text size, colour-blind modes, reduced motion, captions, haptics, large targets, difficulty assists, "Full remapping" (L208, L222, L346, L518-L529) | NOT IN PROJECT | Only an idea entry exists: B12A-05, "Accessibility not yet added", implementation "OPEN (not requested by owner)", target 20+. `docs/GAME_DESIGN.md` U19 is open. |
| S-26 | **Network.** "**Network use:** Fully offline" (L209) | OBSOLETE | Owner multiplayer decision, `docs/DECISIONS.md` 2026-10-17 "Multiplayer". It supersedes the earlier proposal P6 ("Fully offline, single player", `docs/GAME_DESIGN.md`). The spec's own L12 and L451 also replace it. |
| S-27 | **Versioning.** "**Versioning:** Semantic version + incrementing build code" (L210, L581) | DIFFERS | **Repository wins.** One shared build number for all three platforms, stamped into the versions by `.github/workflows/release.yml` ("Stamp the build number into the versions"; `docs/DECISIONS.md` 2026-10-18 "Post-audit remediation"; root `CLAUDE.md` section 5). `game/export_presets.cfg` holds `0.1.0-dev` as the base. |
| S-28 | **Distribution.** "**Distribution:** Just me / sideload" (L211, L582) | AGREES | **In practice:** the APK comes from private draft releases (root `CLAUDE.md` section 1, "Builds"). **Formally open:** the distribution channel (`docs/GAME_DESIGN.md` U18). |
| S-29 | **Orientation.** "**Phone orientation:** Landscape" (L212, L347) | AGREES | `game/project.godot` `window/handheld/orientation=0` (landscape). Not written in any decision. |
| S-30 | **Enemies.** "A roster of distinct enemy archetypes (chaser, ranged, swarm, tank, elite) ... plus bosses with phase-based patterns" (L213, L271) | NOT IN PROJECT | **The spec unconfirms it** (L20). **What exists:** bandits, wolves, bears and boar (`docs/DECISIONS.md` 2026-10-19 "Forest animals"). **Owner remarks:** "Lizards ... and spiders are good enemies" (`docs/DECISIONS.md` 2026-10-18; "Enemy behaviour is not designed yet"). Skeletons are B14-09. No boss is recorded anywhere. |
| S-31 | **Controls.** "**Controls:** Touch, Keyboard and mouse, Gamepad" (L214, L344) | AGREES | `docs/DECISIONS.md` 2026-10-18 "Controls: touch, gamepad, and keyboard and mouse, detected automatically" (Owner). |
| S-32 | **Touch scheme.** "Pan and pinch-zoom camera with tap to act" (L215, L345) | AGREES | `docs/BUILD_DECISIONS.md` "Controls, screen and settings", "Looking around" row (owner: "2 fingers ... drag the screen to look around"), and tap-to-walk and tap-to-use. |
| S-33 | **HUD.** "Clean readable HUD showing only essential state (health, XP/progress, active abilities) ... a pause menu reachable at all times" (L216, L355) | AGREES | **HUD bars:** `docs/BUILD_DECISIONS.md` "Controls, screen and settings". **Readable phone text:** `docs/DECISIONS.md` 2026-10-18 "Readable phone text" (Owner). |
| S-34 | **Performance.** "**Performance target:** 60 fps"; cold start under 4 s; documented memory ceiling (L217, L503-L508) | NOT IN PROJECT | Root `CLAUDE.md` section 8: "Budgets (target fps, memory, load time, build size) get written here once the owner sets them". |
| S-35 | **Engine.** "**Engine / framework:** Godot Engine 4.x" (L218, L437-L447) | AGREES | **In use:** Godot 4.7 (root `CLAUDE.md` section 1). **Formally still Proposed:** `docs/DECISIONS.md` 2026-10-17 "Engine: **Godot 4** recommended" (Agent, *Proposed*); `docs/GAME_DESIGN.md` U2; register DGA-D10. |
| S-36 | **Build pipeline.** GitHub Actions builds "on every push to the working branch and on tags" (L219, L501) | DIFFERS | **Repository wins** (owner release policy). `release.yml` runs by hand only. `tests.yml` runs tests on staging pushes and publishes nothing (root `CLAUDE.md` sections 1 and 5; `docs/DECISIONS.md` 2026-10-18 "Post-audit remediation"). |
| S-37 | **Testing.** Unit tests, headless smoke playtests, economy simulation, persistence tests (L220, L531-L542) | AGREES | **Tests:** root `CLAUDE.md` section 5 (pre-push checks). **Long simulations:** `docs/release/LONG_RUN_SIMULATION.md`, `tools/sim_gate.py` (`docs/PROJECT_MEMORY.md`). |
| S-38 | **Content counts.** "**Scope:** Go with your recommendation"; Compact tier with 12 resources, 30 recipes, 2 biomes, 6 creatures, 1 boss, 4 zones and 12 quests (L221, L328-L340) | NOT IN PROJECT | **The spec's own status:** "UPPER-BOUND EFFORT HEURISTICS, not owner requirements" (L332). **Project scope:** set by build instead (ROAD-01, `docs/EXPANSION_ROADMAP.md`). |
| S-39 | **Names and identifiers.** "**Package / app ID:** com.hotatticgames.thewell" (L223, L580); "Display name: **The Well**" (L579); "Artifact names: The Well Build NN APK" (prompt L140) | DIFFERS | **Repository wins** (owner, REC-005): no renaming without explicit approval. **The project uses:** package `com.hotatticgames.mymedievallife.dev` (`game/export_presets.cfg`); release name "My Medieval Life Build N" and files `MyMedievalLife-buildN-*` (`.github/workflows/release.yml`). |

### Sections 2-8 (L225-L435)

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-40 | Anti-slop criteria (L225-L235; prompt L100-L113) | AGREES | **Same idea in the project:** "Visual output must actually be looked at before it is reported as verified" (root `CLAUDE.md` section 5); no unlooked-at output reported as verified (section 12). **Not adopted as a list:** the specific criteria (caves, bosses) are not. |
| S-41 | **Not a prototype.** "The first build is a genuinely playable, complete game ... not a prototype. No unfinished-work markers, placeholder gameplay or stubbed systems ship" (L247-L253; prompt L20, L137) | DIFFERS | **Repository wins** (owner roadmap). **The project calls itself a prototype:** "Playable prototype in `game/`" (root `CLAUDE.md` section 1). It grows build by build under ROAD-01. **Stand-ins are recorded openly:** for example `docs/DECISIONS.md` 2026-10-19 "House storefronts ... The awning is a stand-in". |
| S-42 | **Genre checklist.** Includes "respawn timers/regeneration", "a defined end goal or sandbox rule", "bosses, a defined ending", "balance spreadsheet" (L300-L317) | DIFFERS | **Repository wins, as does the spec's own correction:** "renewable resource respawn timers" and "a mandatory ending" are unconfirmed (L20). Finite resources follow WDR 013. **Agrees:** quests, dialogue and the journal exist (`docs/BUILD_DECISIONS.md` "Side quests"; `docs/DECISIONS.md` 2026-10-18 "A journal that looks like a book"). |
| S-43 | **Cross-cutting.** Pause without loss, no soft-locks, no silent item loss, sinks balanced by headless simulation (L319-L326) | AGREES | **Saves and recovery:** root `CLAUDE.md` section 7; `docs/release/SAVE_CONTINUITY.md`. **Long runs:** `docs/release/LONG_RUN_SIMULATION.md`. |
| S-44 | **Asset sources.** Per category: Kenney and other CC0 sets for tiles, UI, fonts, sound and music, procedural fallback; `ASSETS.md`; `assets/licenses/` (L358-L427; prompt L126-L127) | DIFFERS | **Repository wins** (owner asset policies, root `CLAUDE.md` section 3). The owner's packs are used: Shade's tiles, the flat UI pack and Kenney Input Prompts. **The records are different files:** `ASSET_MANIFEST.md`, `docs/assets/packs.json`, `game/assets/PROVENANCE.json`, `game/data/credits.json`. |
| S-45 | **Branding.** "**Game icon:** none supplied; create an original one." "**Studio logo / splash:** intentionally omitted." (L181-L183, L429-L435) | DIFFERS | **Repository wins** (owner). The Windows executable carries "the approved My Medieval Life artwork" (`docs/DECISIONS.md` 2026-10-18 "Before Build 7"). **The spec contradicts itself:** L575 asks for "the studio splash (Hot Attic Games, or the owner-supplied logo above)". |

### Section 9: architecture, toolchain and platforms (L437-L501)

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-46 | **Architecture.** One shared gameplay core with thin platform layers. Android first. "Windows builds are produced on a Windows machine or a Windows CI runner" (L453-L460; prompt L31-L33) | AGREES | **Shared core:** "Keep code platform-neutral" (root `CLAUDE.md` section 8). **One commit for all three:** root `CLAUDE.md` section 5. **One difference:** Windows is exported on the same Linux runner (`release.yml` `runs-on: ubuntu-latest`), with the icon embedding checked by `tools/check_exe_icon.py` (`docs/DECISIONS.md` 2026-10-18 "Before Build 7"). |
| S-47 | **Steam Deck labelled web.** "Steam Deck (handheld PC) (web): Updates are new deployments of versioned static files; no separate OTA machinery. ... A web build is redeployed." (L484) | DIFFERS (UNRESOLVED) | **The project ships no web build.** Steam Deck runs the Linux build ("Linux / Steam Deck (desktop mode)", `docs/release/BUILD_13_PACKET.md`). **The owner asked:** "Correct Steam Deck platform labeling without changing supported platforms" (#27). **The 2026-10-17 agent proposal (C6):** "Steam Deck uses the Linux desktop build and the Linux self-updater". It was never confirmed (section 4). |
| S-48 | **Repository rules.** Logic separate from rendering, numbers in data files, `main` never unbuildable, no force-push (L492-L497) | AGREES | **Numbers in data:** `game/data/balance.json` (`docs/BUILD_DECISIONS.md` intro). **Branch rules:** root `CLAUDE.md` section 5. **File names differ:** Bob's `HANDOFF.md` and `ASSETS.md` correspond to `docs/CURRENT_DEVELOPMENT_STATE.md` and the asset records in S-44. |

### Sections 10-18 and Parts D-E (L503-L699)

| # | Spec point (line) | Class | Project record and notes |
|---|---|---|---|
| S-49 | **Saves.** "Saves are versioned with explicit migrations and tested with fixture saves from every previous version. Writes are atomic ... Settings persist separately" (L510-L516) | AGREES | **Agrees:** root `CLAUDE.md` section 7; `docs/DECISIONS.md` 2026-10-18 "Post-audit remediation"; settings in `user://settings.cfg` (`docs/BUILD_DECISIONS.md` "Controls, screen and settings"). **One owner exception:** at save version 13 the owner made older saves disposable; they are refused and kept, not migrated (`docs/DECISIONS.md` 2026-10-19 "Village generator v6"). Save continuity between builds: SAVE-00..09. |
| S-50 | **Device checks.** Verify on every platform, including Steam Deck controller-only at 1280x800, and on a physical phone (L544-L564; prompt L163-L182) | AGREES | **Agrees in principle:** "Automated is not device" (root `CLAUDE.md` section 9a). **Not done:** no real device has been used yet (`docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md` line 31). |
| S-51 | **Deliverables.** A README with install steps and `docs/VERIFICATION.md`; Android "16 KB page-size compatibility where native code is used" (L570-L575; prompt L23) | DIFFERS | **Repository wins.** The project records the same facts in its release packets and readiness reports (`docs/release/BUILD_14_PACKET.md`, `docs/release/BUILD_14_READINESS.md`). There is no `docs/VERIFICATION.md`. **16 KB page size:** not recorded anywhere. UNRESOLVED whether it applies; no native plugins are recorded. |
| S-52 | **Phases and milestones.** Phases 0-5, milestones M1-M6, the core-first strategy, "Build the ENTIRE approved game through M6" (L591-L599, L626-L633; prompt L135-L137, L156-L161) | OBSOLETE | The owner's five-build roadmap (`docs/DECISIONS.md` 2026-10-20 "Five-build roadmap"; ROAD-01; `docs/EXPANSION_ROADMAP.md`) and OVN-01. |
| S-53 | **Resource discipline.** One rules file, decisions in files, sparing subagents, "Do not ask the owner anything already answered" (L601-L610; prompt L147-L154) | AGREES | **Same rules:** root `CLAUDE.md` section 0 step 8 and section 9a. **Agent limits:** `docs/DECISIONS.md` 2026-10-18 "Development queue and coordination" ("about four or five at most"). |
| S-54 | **Prototype exclusions.** "[prototype-only] Not required for this prototype: finished builds for Windows PC, Linux, Steam Deck" (L618) | OBSOLETE | Owner release policy: Linux, Windows and Android are always built together from one commit (`docs/DECISIONS.md` 2026-10-18 "Master build, release and work-preservation policy"; root `CLAUDE.md` section 5). |
| S-55 | **Handoff package.** Fourteen documents in `docs/` (L624; prompt L134) | DIFFERS | **Never supplied** (notes L5). **Repository wins:** the register, the ledger and the state file fill those roles (`docs/PROJECT_MEMORY.md`, "Where everything is"). Bob's `docs/GAME_DESIGN.md` is not the project's file of the same name. |
| S-56 | **Gameplay invariants.** `docs/GAMEPLAY_INVARIANTS.md` and narrowly scoped repairs (L635-L639; prompt L138) | NOT IN PROJECT | No such file. The nearest rule: a failing test is fixed, never weakened (root `CLAUDE.md` section 5). |
| S-57 | **Repair escalation.** "After TWO failed attempts ... After THREE failed attempts: write an escalation report"; `docs/FAILURE_LOG.md` (L641-L648; prompt L139) | NOT IN PROJECT | No such rule or file. |
| S-58 | **Who may authorize what.** Separate authorization for test releases, OTA, stores, `main` merges and identity changes (L650-L658; prompt L140) | AGREES | Root `CLAUDE.md` sections 5 and 11. The "pre-release" wording is replaced by private drafts (I-25). |
| S-59 | **Progress reports.** Plain reports with an evidence class for every claim (L660-L665; prompt L141) | AGREES | Root `CLAUDE.md` section 12. Evidence classes are used in `docs/release/BUILD_12_FULL_AUDIT.md` (for example "[D] Real device"). |
| S-60 | **Part D.** "None unresolved. Every build-critical decision is resolved by the owner, delegated, or left to implementation discretion above." "Delegated to Bob's recommendation ...: Survival and crafting, Story." (L667-L673) | OBSOLETE | **Replaced by the spec's own correction:** its reconciliation section lists UNRESOLVED items (L12, L13, L18), and notes L7 lists outstanding owner decisions. **Story:** the owner later answered "Side quests now, story later" (REC-011). |
| S-61 | **Connected map.** Part E, implied: "The world is one connected open map" (L684) | AGREES | As I-03. |
| S-62 | **Human-only step.** "Install and playtest the first build on a real device" (L689-L691) | AGREES | Root `CLAUDE.md` section 9a. The device queue is in the Roadmap section of `docs/DEVELOPMENT_LEDGER.md`. |

### `CORRECTION_NOTES.md`

| # | Notes point (line) | Class | Project record and notes |
|---|---|---|---|
| S-63 | Other generated documents "may still contain contradictory values, including single-player exclusions and roguelite death" (notes L5) | AGREES | Those documents never reached the project (`docs/requirements/RECOVERY_2026-10-19.md` line 25). The project records neither single-player-only play nor roguelite death (I-07, I-21). |
| S-64 | "Outstanding owner decisions: multiplayer in first milestone, detailed descendant/inheritance rules, procedural world generation, and precise content scope." (notes L7) | OBSOLETE | **Multiplayer:** MP-01 (S-05). **Inheritance:** S-06. **World generation:** S-10. **Still open:** precise content scope is UNRESOLVED. It is not settled by any one decision: the owner sets it build by build (ROAD-01), and several design areas stay open (OD-09, `docs/GAME_DESIGN.md` U3-U5, U13, U16-U21). |

## 3. Counts

| Class | Interview answers (section 1) | Rest of the spec (section 2) | Total |
|---|---|---|---|
| AGREES | 20 | 34 | 54 |
| DIFFERS | 6 | 13 | 19 |
| NOT IN PROJECT | 6 | 8 | 14 |
| OBSOLETE | 2 | 9 | 11 |
| **Rows** | **34** | **64** | **98** |

Rows I-04, I-13, I-14, I-16 and S-47 are partly UNRESOLVED. Their open parts are listed below.

**Gaps in the record.** Several AGREES rows are true of the game as built, but `docs/GAME_DESIGN.md` still lists the item
as undecided. These are U4 (core loop, I-11), U5 (world structure, I-03), U6 (saves, S-20) and U15 (survival, S-15).
Only the owner can move an item to Confirmed (root `CLAUDE.md` section 9).

## 4. Open for the owner

These need the owner's decision. Nothing here is answered or adopted. Each item quotes the texts that conflict.

**C1. "One hero" and "not the chosen one."** (REC-004; I-14; S-19)

- Spec, the owner's interview: "**Characters / classes:** One hero (owner said: "Your main character is the hero")"
  (L120). Bob's recommendation: "**Story:** Full story with dialogue" (L194).
- Project, owner decision: "The player is an ordinary inhabitant of an original village in an original county,
  **not the chosen one**" (`docs/DECISIONS.md` 2026-10-17). "the novel's story is the world's history, not the
  player's quest" (same file, 2026-10-17).
- Question: does "one hero" mean one player character (not a party), or a hero role in the story? The 2026-10-17
  agent proposal read it as "one player character, not a party". That reading was never confirmed.

**C2. Class progression and the tech tree.** (REC-010; I-16)

- Spec, the owner's interview: "It's going to have class progression, system jobs, whole nine yards." (L77). "I like
  a mix of an tech and research tree and new abilities and equipment" (L101).
- Project: "A player may become a miner, shepherd, blacksmith, merchant, tailor, farmer, builder, mercenary, or
  bandit—or mix professions—without being forced through a class or level ladder."
  (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §1, a non-binding reference). Today there are skills 1-10 with perks
  (agent proposals) and no classes or tech tree.
- Question: are classes wanted, and in what form? The 2026-10-17 agent proposal read them as "learnable jobs and
  skill paths". That reading was never confirmed. Is a tech or research tree wanted?

**C10. The view.** (DGA-D1, OD-03; I-04)

- Spec, the owner's interview: "it's going to be like a top-down pixel map, but the characters aren't going to be top
  down. They're going to be kind of at an angle" (L72-L73). "it'll be almost isometric so it'll be you're looking at it
  top down with the the buildings that you won't just see the top of the building. You'll see a little bit of the side
  and the edge. I don't know what that's called" (L92-L94).
- Spec, Bob's reading: "2.5D / three-quarter view with eight-direction animated character sprites; avoid flattening
  this to pure top-down" (L16), and also "**Perspective:** Top-down" (L245).
- Project, owner decision: "Working visual direction: 2D/2.5D isometric with 8-direction animated sprites"
  (`docs/DECISIONS.md` 2026-10-17).
- Project, open question D1: "A true 2:1 diamond projection, or an oblique 3/4 top-down view like today's art
  (sometimes called 2.5D)? Please give a reference picture." (`docs/DESIGN_GAP_ASSESSMENT.md` section 12).

**Aimed ranged combat and combos.** (REC-009, FR-10; I-13)

- Spec, the owner's interview: "Aim and shoot in real time, Melee and combos, Abilities on cooldowns" (L119).
- Project: archery is DEFERRED (FR-10), and the CQ-01 entry says "archery not authorised" (`docs/DECISIONS.md`
  2026-10-19 "Sword combat responsiveness"). There are no combos.
- Question: when, if ever, do aimed ranged attacks and melee combos come?

**Steam Deck labelling.** (I-08; S-47)

- Spec: Steam Deck is a target platform (L114) and is labelled "(web)" for updates (L484).
- Owner, #27: "Correct Steam Deck platform labeling without changing supported platforms."
- Project: three platforms are recorded (Android, Windows, Linux). Steam Deck appears only as "Linux / Steam Deck
  (desktop mode)" in release notes.
- Question: confirm that Steam Deck is a supported target served by the Linux build. That was the 2026-10-17 agent
  proposal (C6), never confirmed.

**Where Mote is.** (REC-002; S-14)

- Spec: "Inspect and follow the actual Mote OTA implementation (its repository or reference material)" (L58).
- Owner, #27: "Preserve the existing Mote system and its integration requirements. Identify any missing access or
  dependencies rather than inventing replacements."
- Project: no Mote code in this repository. The agent asked "Where is Mote?" on 2026-10-17, with no answer on record.
  The register notes a lead (verbal76/Axolotl, titled "Mote") that the owner has not confirmed.

**The API 36 policy.** (REC-003; S-13)

- Spec: "Android Target API 36 is REQUIRED (Hot Attic Games standing policy; it is not negotiable per project)" (L47).
- Project: the builds already target 36 (`docs/release/OVERNIGHT_REPORT_2026-10-20.md`). The policy is not in
  `docs/DECISIONS.md` or the root `CLAUDE.md`. The overnight report lists the owner's confirmation as open.

**Items already open in the project that the spec also raises.** These are not new questions.

- Engine approval: U2, DGA-D10 (S-35).
- Distribution channel: U18 (S-28).
- Content rating and audience: U21 (I-05).
- Accessibility: B12A-05 (S-25).
- Performance budgets: root `CLAUDE.md` section 8 (S-34).
- Enemy design and bosses (S-30).
- Precise content scope (S-64).

The spec's other "NOT IN PROJECT" rows are open in the same way. The owner may adopt or drop any of them.
