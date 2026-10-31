# My Medieval Life: project instructions

Hot Attic Games. Repository `verbal76/My-Medieval-Life`. This file is the single source of project
rules for every agent and contributor. If another document disagrees with it, this file wins until
the owner says otherwise. Update it in the same PR as any change to the workflow it describes.

## 0. Session start (mandatory, every session; owner directives 2026-10-20, MEM-01 and MEM-02)

The GitHub repository is the project's memory; conversation memory, the container and private artifacts never
are. No file is read automatically because it exists: do these steps, in order, before any new work.

1. **Identify the repository, branch and latest remote commit.** Repository `verbal76/My-Medieval-Life`;
   development branch `staging/my-medieval-life`. Run `git fetch origin staging/my-medieval-life`, check out or
   update that branch, and note `git log origin/staging/my-medieval-life -1`.
2. **Read `docs/PROJECT_MEMORY.md`**, the index of where every authoritative record lives.
   Then **`docs/expansions/README.md`** (owner, 2026-10-31, DOC-RECON-01): the status of every expansion and system, the
   precedence of owner decisions (latest explicit owner decision first, regardless of branch) and the one status vocabulary;
   historical documents are indexed there and are never current instructions. A revised owner specification set becomes
   authoritative only on the owner's explicit final approval (DOC-AUTH-01).
3. **Read `docs/CURRENT_DEVELOPMENT_STATE.md`**, the handoff: branches, workers in flight, next actions,
   interrupted processes (session state only; it never restates a requirement's status).
4. **Review the register and unresolved decisions:** the generated views in `docs/requirements/views/` (STATUS,
   BUILD_18..23, DECISIONS, QUEUES, BACKLOG; all generated from `docs/requirements/requirements.json`, the one register
   and decision register), `docs/EXPANSION_ROADMAP.md` and `docs/WORLD_DESIGN_RULES.md`.
5. **Review the design specifications for the current work:** the documents the active entries cite in their
   `source` (owner directives in `docs/directives/`, the specs the index names).
6. **Check Git status and recent commits:** `git status`, `git log --oneline -15`, `git worktree list`, and run
   `python3 tools/check_requirements.py` (it must report 0 problems).
7. **Determine what was completed, what remains unverified and what is authorized next,** from the register's
   statuses and evidence and the state file's next tasks; never from memory of a conversation.
8. **Resume only currently authorized work.** Use the live requirements register, latest owner directives and active worker branches. Build sequence (owner, 2026-10-31, BUILD-SEQ-25-27): Build 25 = Expansion 20 validation and freeze (`wip/expansion20` `ad281dc`, frozen only after the owner approves the validation); Build 26 = repository recovery and consolidation from the frozen Build 25 SHA; Build 27 = Expansion 21, only after Build 26 is frozen and the owner explicitly authorizes it. Build numbers are not expansion numbers. Expansions 22-27 are not authorized. Never answer owner decisions, compromise save/security rules, or merge to main without authorization.

**After a context compaction or in a fresh session** (owner directive 2026-10-20, `docs/directives/2026-10-20_compaction_readiness.md`):
- Do steps 1-8 before any further decision.
- Build authority is the live requirements register, generated STATUS/QUEUES views and most recent explicit owner directives. Build 24 is the latest private test build; development resumed 2026-10-30 (X20-RESUME). WDR-022 remains in force. Recovery: `docs/handoffs/CURRENT_SESSION_RECOVERY.md`; checkpoint around 70–75% context.
- What a conversation summary lacks was not thereby unapproved: the register, the decision log and `docs/directives/` are the record.
- Do not repeat completed work, and never restart a simulation or test before checking whether it is still running (the state file's workers and processes: GitHub Actions runs, local processes).
- Compaction is not a reason to stop: continue the next approved task.

At each meaningful checkpoint, and before a session ends, a context handoff or a build: update
`docs/CURRENT_DEVELOPMENT_STATE.md` and every touched register entry, run
`python3 tools/check_requirements.py --write`, commit and push to staging, and confirm the remote head.

## 1. Purpose and status

My Medieval Life is a 2D medieval game built from 16x16 pixel-art packs (mostly by Shade). The
GitHub repo describes it as a "Mini RPG". Its direction is set by the owner's directives (`docs/directives/`) and
World Design Rules (`docs/WORLD_DESIGN_RULES.md`): a living medieval village that sustains itself without the player,
summarised in `docs/PROJECT_MEMORY.md`. **Its founding principle (owner, 2026-10-20, World Design Rule 022): "A village is allowed to fail. The simulation
is not."** The game simulates a functioning world; it never guarantees a successful one. Fix what is broken (a mechanic
failing its approved function, script errors, coins or items without a valid transaction, lost state); preserve
legitimate outcomes (bankruptcy, shortage, decline) even when the statistics are unfavourable; add no hidden rescue. The current game design and open owner questions come from the live requirements register and applicable later directives. `docs/GAME_DESIGN.md`, `docs/DESIGN_GAP_ASSESSMENT.md`, `docs/game-designer/` and Morris world research are historical reference only.

Status (keep current):

| Area | State |
|---|---|
| Asset inventory, dedupe, licences | Done: `ASSET_MANIFEST.md`, `asset_manifest.csv` |
| Asset tooling (Python) | Done: terrain, rivers/roads, animation and building data, renderers |
| Morris world research | Done: all 119 chapters extracted and quote-verified; registries, deliverables A–J in `docs/world/` |
| Design authority | World Design Rules, live register and applicable owner directives; original design drafts are historical. |
| Engine | Established Godot 4.7 implementation; prototype engine proposals are historical. |
| Platforms | Android APK first, then PC (Windows, Linux), as the owner directed; touch, gamepad, and keyboard and mouse |
| Gameplay code | Established living-world simulation, economy, family, Judgment and multiplayer; active requirements and branch evidence control status. |
| Builds | Build 24 (Expansion 20 checkpoint, `4611d86`, run 40636966840, 2026-10-28) is the latest private three-platform draft: Build 23's content plus till ownership (TILL-D1), free migration, visible swords, flight-recorder diagnostics and the LE-02 market behind the off switch. Not device-checked. Development resumed 2026-10-30 (X20-RESUME): Living Economy LE-03+, settlement food trade, multiplayer Batch D. Builds 22 and 23 are frozen. |

## 2. Repository layout

| Path | What it is | Authoritative? |
|---|---|---|
| `*.zip`, `Miniworld-Guide.docx`, `punyworld-dungeon-tileset.png`, `16x16 Assorted RPG Icons (partial)/`, `Flat Game UI Icon Pack/` | Original source assets | Yes; never modified (section 3) |
| `ASSET_MANIFEST.md`, `asset_manifest.csv` | Inventory of every file in every archive | Generated by `tools/build_manifest.py` |
| `tools/` | Python asset tooling, the reference implementation of all generators | Yes |
| `data/` | Generated game data (animation metadata, building atlas) | Generated; regenerate, never hand-edit |
| `docs/` | Design, architecture, plan, decisions, data formats | Yes |
| `docs/PROJECT_MEMORY.md`, `docs/CURRENT_DEVELOPMENT_STATE.md` | The project memory index and the live session handoff (section 0) | Yes; the state file is updated at every checkpoint |
| `docs/EXPANSION_ROADMAP.md` | Builds 15-19, the three expansions and their dependencies | Yes |
| `docs/requirements/baseline_*.json`, `docs/requirements/RECONCILIATION_*.md` | Frozen reconciliation baselines and the reports generated from them | Baselines frozen, never edited; reports generated by `tools/check_requirements.py --write` |
| `docs/systems/` | Resource node manifest and resource usage registry | Generated from `game/data/resources.json` by `tools/check_resources.py --write`; never hand-edit |
| `docs/systems/MATERIAL_INTERDEPENDENCY.md`, `docs/systems/material_exceptions.json` | Material and profession coverage against World Design Rules 001-003 and 007, and its recorded exceptions (`mml-material-exceptions/1`) | The report generated by `tools/check_materials.py --write`, never hand-edited; the exceptions file is hand-kept |
| `docs/world/` | World knowledge base from *The Well at the World's End* (deliverables A–J) | Partly generated; see its README |
| `research/` | The novel (`sources/`), its paragraph corpus, chapter notes and extractions, merged registries | Notes, `merges.json` and sources yes; the rest generated by `tools/lore/` |
| `tests/` | `unittest` suites for tools and data | Yes |
| `out/` | Previews and scratch output (git-ignored) | No |
| `game/` | The Godot project: scripts, scenes, data (`game/data/`), imported art (`game/assets/`, via `tools/import_game_assets.py` only), tests (`game/tests/`) | Yes; `game/assets/` is generated by the import tool |
| `game/data/resources.json` | The one definition of harvestable resource nodes and code-defined resource uses (`mml-resources/1`), read at run time by `ResourceNodes` (`game/scripts/core/resource_nodes.gd`) and validated by `tools/check_resources.py` | Yes |
| `game/data/overworld_tiles.json` | The tile ids the run-time overworld generator (`game/scripts/core/overworld.gd`) draws with (`mml-overworld-tiles/1`) | Generated by `tools/build_overworld_tiles.py`; never hand-edit |
| `docs/requirements/requirements.json` | The requirements register: every owner-approved requirement, proposal, open decision and World Design Rule, with source, approval, acceptance, status and history (`mml-requirements/1`) | Yes; validated by `tools/check_requirements.py`, which generates `docs/DEVELOPMENT_LEDGER.md` (never hand-edit the ledger) |
| `docs/directives/` | The owner's directives, verbatim | Yes; never edited |
| `docs/WORLD_DESIGN_RULES.md` | The owner's numbered World Design Rules (001-016 original, 017 onward) | Yes |
| `docs/assets/` | Asset registry (`packs.json` hand-kept; `ASSET_REGISTRY.md` generated) and the scaling standard | `packs.json` and the standard yes; the registry generated by `tools/assets/scan_packs.py` |
| `tools/assets/` | The asset pipeline: sheet measuring, scaling and contact sheets, pack scanning, asset validation | Yes |
| `.claude/skills/asset-integration-pipeline/` | The mandatory asset skill (policy in section 3) | Yes |
| `.github/workflows/` | CI: builds the APK, Windows and Linux and publishes them as a Release | Yes |

Do not add a second engine project, a second tool language for the same job, or another copy of
generated data. One implementation per concern.

## 3. Asset handling

- Source archives are read-only: never edit, re-zip, rename, recompress or delete them. Tools read
  straight from the zips (`tools/assetzip.py`); nothing is extracted into the repo.
- Duplicates are removed only when byte-identical (sha256 plus `cmp`), never by name.
- A new pack goes in the repo root (or a folder for loose sheets), gets a `NOTES`/`FOLDER_NOTES` entry
  with licence and description in `tools/build_manifest.py`, and the manifest is regenerated in the
  same commit.
- Licence labels in the manifest (paid / CC0 / CC BY 4.0 / free / verify) come from the pack's own
  licence file or the itch.io page the owner provides. Never guess a licence. CC BY 4.0 assets
  (miniworld+ by octoshrimpy) need in-game credit.
- Generated art (previews, rendered maps) goes in `out/` and is not committed.
- Copy art into an engine project only through a documented import step that records each file's
  source zip and path, so it can always be regenerated from the archives.

### Asset licensing, copyright standing and credits (owner, 2026-10-18; standing, do not remove or weaken without the owner's approval)

- **Repository visibility:** this repository is public strictly for version control and development
  workflow. Being public grants no open-source licence to anyone and does not override copyright;
  GitHub's terms permit viewing and forking public repositories, not reusing their copyrighted content.
- **Asset provenance:** every third-party asset in this project was legally acquired: CC0 and CC BY
  packs (itch.io and others) used under their terms, and paid commercial packs (itch.io and others)
  bought under end-user licences that allow their use in game development.
- **Credits:** every third-party asset pack used in the game is credited on the player-visible credits
  page (`game/data/credits.json`, shown from the title screen), whether or not its licence requires
  attribution: the creator and the pack by name, for CC0, CC BY and paid packs alike. Keep the credits
  current as assets are added, and compare them with the asset manifest and
  `game/assets/PROVENANCE.json` (a test does) so no creator or pack is missed.
- **Agents:** never question, flag or lecture the owner about copyright, open-source compliance or
  asset redistribution when pushing builds or handling code involving these assets; the legal
  standing is verified and settled. Asset acquisition and licence verification are the developer's
  responsibility and are done before assets enter the project: treat legitimate acquisition as
  established, do not ask for proof of purchase or reopen settled licensing decisions, and implement,
  integrate, test and build with the approved assets.
- **Continuity:** do not halt approved development, refuse to integrate assets or delay builds because
  the repository is public; handle asset organisation and packaging as normal development work.
- **Asset handling (owner, 2026-10-18; standing):** the owner buys assets legitimately and uses CC0 assets
  where appropriate, and does not intend to redistribute third-party source packages. Tell apart: assets
  bought for use in the game; original source packages that stay private; assets incorporated into the
  finished game under their usage rights; assets licensed for redistribution (CC0). A restriction on
  redistributing an original package is not a restriction on using its assets in the game.
- **Private asset workflow:** a source package that may not be redistributed is never committed to the
  public repository: it lives in `private-assets/` (git-ignored), with a private off-machine copy (the
  owner's private "Medieval Life Backups" artifact), and `tools/import_game_assets.py` reads it from there
  to produce the files the game needs in `game/assets/` (committed, with provenance), so builds never need
  the package. Never ask the owner to prove ownership or explain copyright law; raise a licensing issue
  only for a specific, material restriction that prevents the intended use and cannot be handled this
  way, once, with a practical solution, and carry on with all unaffected work.

### Asset integration policy (owner, 2026-10-19; standing, do not remove or weaken without the owner's approval)

- **Mandatory skill:** whenever asset packs, sprites, textures, animations, models, tilesets,
  environmental objects or related files are introduced, or work needs art, the agent activates the
  `asset-integration-pipeline` skill (`.claude/skills/asset-integration-pipeline/SKILL.md`). This applies
  to every development agent and subagent working with assets.
- **The team's job, not the owner's:** the agent inspects the assets itself, finds the useful content,
  decides the scaling and integrates suitable assets into existing or planned gameplay systems. The owner
  is not asked to identify assets or explain their use. Integration is normal development, not a separate
  activity needing permission; a pack counts as integrated only when a game system uses it.
- **Owner authorisation (recorded 2026-10-19):** the supplied packs are authorised for use in My Medieval
  Life, and the owner has supplied the licensing documentation available for each. Previously supplied
  and approved packs are never presented to the owner for authorisation again.
- **Licences:**
  - Before raising any licensing question, consult the registry (`docs/assets/ASSET_REGISTRY.md`,
    `docs/assets/packs.json`), `ASSET_MANIFEST.md` and the pack's own licence files.
  - Repository visibility, a private development copy and a distributed compiled game are different
    contexts. Terms that forbid redistributing source files are met by keeping the pack in `private-assets/`
    and committing only the imported game files, with provenance and credits; they are not a reason to
    leave the art unused.
  - Only a specific, unresolved restriction that prevents the intended use is escalated, once, with a
    compliant alternative. Nothing settled is reopened without new evidence.
- **Scaling** follows `docs/assets/ASSET_SCALING_STANDARD.md` (one pixel density; integer factors). Mixed
  source resolutions are an integration problem to solve, not a reason to drop a pack.
- **Tools:** use `tools/assets/` (`sheets.py`, `scan_packs.py`, `check_assets.py`) and
  `tools/import_game_assets.py`; never copy art into `game/assets` by hand.
- **Keep the knowledge:** every pack has an entry in `docs/assets/packs.json` with its decisions,
  opportunities and status, regenerated into the registry by `scan_packs.py`. Future packs enter the
  pipeline automatically.

### Wiki and documentation maintenance (owner, 2026-10-21; standing, do not remove or weaken without the owner's approval)

`docs/directives/2026-10-21_permanent_wiki_maintenance.md`, register WIKI-01. **A feature is not complete without accurate
corresponding documentation.** Every agent and worker, on every task:
- **Two layers, kept apart.** The player-facing manual is the in-game wiki (`game/scripts/core/wiki*.gd`, built from the
  game's data plus provider pages; checked by `game/tests/wiki_test.gd`): what a feature does, how to reach it, tools,
  materials, costs, what can go wrong, interactions, in plain words, without internals or values the owner wants found by
  play. The developer reference is `docs/` (design notes such as `docs/build17/*.md`, `docs/SYSTEM_INTERACTION_MANIFEST.md`,
  `docs/DECISIONS.md`, the register): architecture, data ownership, timing, conservation, determinism, NPC decisions,
  dependencies, saves, parameters, limitations, tests, linked to requirement ids and owner decisions.
- **Workflow:** decisions → implement → validate → update the affected wiki pages and technical references in the same
  workstream → check links, navigation and terminology (`wiki_test`, `tools/check_interactions.py`, `tools/check_requirements.py`)
  → report. Update an existing page before creating one; no duplicate or conflicting explanations; one terminology across
  wiki, interface, register and decisions.
- **Implemented only.** Describe as playable only what has landed and passed verification. Approved future systems go in
  the "Not in the game yet" section or developer roadmap documents, never as player instructions. Correct or remove
  obsolete instructions when a feature changes or goes.
- **Report.** Every substantial completion report has a "Wiki and Documentation" section: pages created, pages updated,
  technical references changed, whether wiki validation passed, what remains (or why none was needed). Never claim an
  update that was not made.
- **Release gate.** Before recommending a release: new and changed player-facing mechanics documented, obsolete
  instructions corrected, technical docs match, wiki checks pass, known limitations stated. A missing or outdated entry
  is a documentation defect; material player-facing errors block, trivial wording does not.
- Narrow documentation changes need only the targeted checks, not the full suites.

## 4. Coding conventions

- Match the surrounding code: naming, comment density, idioms. Python tools: standard library plus
  Pillow and numpy only; small modules; a module docstring saying what the tool does and how to run
  it.
- Generators are libraries first (a `build_*`/`generate` function returning data) with a thin CLI.
  Rendering is separate from generation.
- Data files are JSON with a `format` field (e.g. `"miniworld-animations/1"`). Bump the version on any
  breaking change and update `docs/ASSET_DATA.md`.
- Morris research: every canonical claim cites a paragraph id and a verbatim quote that the tools verify.
  Label claims CANON, CANON-INFERRED, GAME EXPANSION or UNRESOLVED, and never present an expansion as
  Morris's. Correct a claim by editing its chapter note (or `research/registries/merges.json`) and
  rebuilding; never hand-edit generated registries or documents.
- Any change to how one game system affects another adds or updates its `INT-###` entry in
  `docs/SYSTEM_INTERACTION_MANIFEST.md` in the same change; `tools/check_interactions.py` validates it.
- Any change to a harvestable node, a harvested material, a recipe or a resource use updates
  `game/data/resources.json`, regenerates the manifests (`python3 tools/check_resources.py --write`)
  and passes `tools/check_resources.py`, in the same commit (owner rule, 2026-10-18).
- Never invent asset facts. When the art does not settle something (frame order, building name),
  record it as `uncertain` with a reason.
- Engine code conventions get added here once the engine is approved.

## 5. Branching, commits, tests, releases

- **GitHub is the source of truth; the cloud machine is a temporary workspace (owner, 2026-10-18).**
  - `staging/my-medieval-life` is the remote branch for ongoing development. Committing and pushing
    development checkpoints to it is a **standing authorization**: push completed, tested work
    regularly, without asking. Never force-push or delete it (`tools/git_hooks/pre-push`, enabled
    with `git config core.hooksPath tools/git_hooks`, refuses both).
  - Unfinished agent work goes to `wip/<worktree name>` branches as snapshot commits.
  - `python3 tools/checkpoint.py --push [--wip <worktrees>]` does both and checks every remote hash.
  - `main` is the approved integrated source: it changes only when the owner merges or explicitly
    permits a merge. Staging-push authorization is not permission to merge, build, deploy or release.
  - Integrate agents' work into staging carefully: keep both sides of overlapping changes and run the
    regression tests before pushing.
  - The manifest, decision logs and test records are committed alongside the code.
- **Continuous development (owner, 2026-10-18; standing).** The default state is active
  development. Build authorization is separate from development authorization: "do not build"
  means no distributable release, never stop working. When one task is blocked on an owner decision,
  ask, and continue with other approved tasks; when an approved task is done, take the next from
  `docs/CURRENT_DEVELOPMENT_STATE.md` ("Next approved tasks") without waiting to be told. Scheduled check-ins only preserve work; they
  neither start nor end development. Only an explicit owner instruction to pause stops approved work.
  If a session must end, update and push `docs/CURRENT_DEVELOPMENT_STATE.md` naming the next approved task.
- Commits: one logical change each, imperative subject (e.g. "Add rivers and roads to the Puny World
  generator"), and a body that says what changed and why.
- Before every push, run:
  ```sh
  python3 -m unittest discover -s tests
  python3 tools/miniworld_anims.py && python3 tools/miniworld_buildings.py && python3 tools/build_manifest.py
  python3 tools/lore/build_registries.py && python3 tools/lore/build_constraints.py && python3 tools/lore/render_world_docs.py
  python3 tools/assets/check_assets.py && python3 tools/assets/scan_packs.py
  python3 tools/check_requirements.py --against origin/staging/my-medieval-life
  git status   # regenerated data must show no diff unless the change was intended
  ```
  A failing test is fixed, never skipped, disabled or weakened to pass.
- **Testing philosophy (owner, 2026-10-20, WDR-022):** mechanical correctness and simulation integrity are mandatory;
  economic outcomes are measured and analysed, never pass/fail thresholds unless an approved requirement sets one. Do not
  rerun year-long simulations in pursuit of favourable statistics.
- **MSW-01, Minimum Sufficient Work (owner, 2026-10-22, `docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md`;
  permanent core principle).** Correctness is mandatory; redundancy must be justified. Before work, weigh the objective,
  the existing evidence, the work actually required, the minimum sufficient validation, the stop and escalation
  conditions and the non-goals, in proportion to the task (no planning overhead for small ones). Reuse valid evidence; do
  not rerun tests for reassurance, create work to occupy workers or interrupt successful work; documentation-only changes
  need no tests.
- **Continuous long-run simulation (owner, 2026-10-21, SIM-01, `docs/directives/2026-10-21_continuous_long_run_simulation.md`;
  permanent).** Run the longest required duration once per required seed and configuration, monitored throughout, and read
  shorter milestones (days 30, 90, 100, ...) from its checkpoints (`economy_sim.gd --every`); never restart the same world
  only to report a shorter duration. A broken invariant (currency or item ledger) stops the run at the checkpoint where it
  is seen (`FATAL day N` line), reported with seed, day and state; a village failing (starvation, decline, shortage) is an
  outcome, recorded, and the run goes on. Separate runs only for genuinely different conditions (seeds, scenarios,
  configurations, regression reproductions, focused tests) and the two independent runs a determinism comparison needs.
  Reports name the commit, seed and configuration, intended and reached days, checkpoint results, failures, village
  outcomes, conservation and determinism evidence, and why any separate run was needed.
- **Simulation monitoring (owner, 2026-10-21, SIM-02, `docs/directives/2026-10-21_simulation_monitoring.md`; permanent,
  supplements SIM-01).** Never cancel, restart, redispatch or duplicate an active simulation to check or report on it;
  reading status, logs and artifacts is the only action, and a restart needs the owner's approval with the stall
  evidence, progress, time to finish, time saved and evidence at risk (an automatic fail-fast on a real defect is the one
  exception). Never change code under a running test. Set check-ins from the job's measured runtime: first soon after
  dispatch (runner assigned), then near the expected finish and about every 10-15 minutes after it while it runs (for
  GitHub 365-day economy runs, measured 41-84 minutes a seed on Build 16 code); read and report results as soon as a job
  finishes, never waiting for a later scheduled check. Prefer completion events; no busy-wait loops. GitHub Actions jobs
  show no log until they finish, so the simulated day of a running job is not visible; say so rather than claim live
  monitoring.
- Visual output must actually be looked at before it is reported as verified.
- **Current Expansion 20 overriding restriction (owner, 2026-10-27; satisfied for Build 23, MP-INTERACT-01 merged last at `87b69ab` and validated):** no packaging, private draft, publishing, APK, Windows or Linux export for Expansion 20 before MP-INTERACT-01 is merged last and validated on the relevant platforms. After this gate, provide a release-readiness report and follow the owner's applicable publication authorization. Do not reopen Build 22. This takes precedence over older automatic-release directions for Expansion 20.
- **Release policy (owner standing directive 2026-10-21, `docs/directives/2026-10-21_standing_continuous_release_directive.md`;
  supersedes the 2026-10-18 rule that each release needs the owner's approval for that occasion).** Development runs on a
  continuous develop, test, release and advance model:
  - When a milestone (a build's approved scope) is complete and its automated gate passes (suites, determinism gate,
    conservation, the four-seed runs of the normal game, save migration, three-platform export), run
    `.github/workflows/release.yml` by hand and publish its APK, Windows and Linux packages to GitHub Releases without
    asking again; reuse valid test evidence on unchanged code. All three platforms come from one exact commit and one
    build number, and the files live in GitHub Releases, never only on the cloud machine.
  - Visibility (owner clarification 2026-10-21, `docs/directives/2026-10-21_release_publication_clarification.md`): the
    owner explicitly authorizes **publishing** completed milestone releases, Build 16 included, to the GitHub Releases
    tab once their required acceptance tests pass: run the workflow with `visibility: public` (and its confirmation
    text). This supersedes the master directive's "Do not publish a public release" for completed milestones;
    intermediate or development builds are still not published.
  - The owner's playtesting is informal and never a release gate; device checks stay recorded in the register's
    `playtest` field. Move on to the next approved build once a release is out.
  - Decide minor implementation details yourself, document them (`docs/DECISIONS.md`, agent decision) and continue;
    escalate only what changes the game's vision, contradicts an explicit owner decision, adds significant cost, or
    commits to an irreversible architecture.
  - **Three platforms, always (owner, 2026-10-24, BUILD-3PLATFORM, `docs/directives/2026-10-24_mandatory_three_platform_build_policy.md`;
    permanent).** "Build" means Android APK, Windows ZIP and Linux ZIP together, for every checkpoint, playtest, candidate and
    release: one commit, one version and build number, checksums and the source commit, one private draft release. A build
    with one or two platforms is not complete: repair the failing one. Sign Android only with the owner's permanent release
    identity in the four `ANDROID_RELEASE_*` secrets (owner, 2026-10-24, ANDROID-RELEASE-SIGNING,
    `docs/directives/2026-10-24_permanent_android_signing_integration.md`; `docs/release/ANDROID_SIGNING.md`): never print,
    rename, regenerate or replace them, never fall back to a throwaway key (the `allow_temporary_key` input is removed from
    Build 21's workflow), and never change the package id `com.hotatticgames.mymedievallife.dev` without the owner.
    One exception: Build 20 (Checkpoint 1) only, signed with a throwaway key (owner, 2026-10-24,
    `docs/directives/2026-10-24_build20_signing_exception.md`); every later build needs the stable key.
  - **Build 17 exception (owner, 2026-10-21, B17-DIR, `docs/directives/2026-10-21_build17_combined_integration_direction.md`):**
    do not publish a new APK, Windows or Linux distributable without the owner's explicit approval; when Build 17's gate
    passes, report its readiness and wait.
  - Pushes go only to staging and `wip/*` branches; merging to `main` still needs the owner.
- **Work preservation (owner, mandatory; a permanent part of the workflow).** Commit completed work
  locally (a local commit is not a push). Never reset or clean a tree in a way that loses work; never
  overwrite another agent's work; integrate agents' changes through the lead agent.
  - **Local checkpoint:** `python3 tools/checkpoint.py` bundles every branch and saves every working
    tree's uncommitted changes (agent worktrees included) outside the repository, then proves they
    restore. It is on the same machine, so it is not a backup by itself.
  - **Off-machine copy:** `python3 tools/checkpoint.py --offsite DIR` snapshots every worktree's
    uncommitted work as `refs/backup/*` commits (without touching the worktrees) and writes a git
    bundle of everything GitHub lacks, as base64 text plus a README with its sha256. The lead agent
    uploads both text files to the owner's private "Medieval Life Backups" artifact
    (https://claude.ai/artifact/2cTyP9BigtJUmmsxEywQjF), adds the checkpoint to that page, then
    **verifies**: downloads the bundle back from the artifact, checks the sha256, restores it into a
    fresh clone from GitHub and confirms the head commit, the commit count and each snapshot's tree.
    Only then is the checkpoint reported as secured.
  - **When:** before integrating an agent's work, before a save-format migration, before anything
    destructive, and after every completed piece of work; never let more than a few commits or one
    agent's work go unsecured. If the off-machine copy fails, report it at once and stop risky work.
  - **Day to day,** GitHub staging is the preservation mechanism (above); the off-machine package is
    the occasional independent disaster-recovery copy. Webhooks, Pages, environments and app
    installations cannot be inspected from this session (the proxy refuses those endpoints), nor
    can rulesets or branch protection be written, so staging is protected by the local hook only.

## 6. Deterministic generation

- Same generator version + same inputs (seed, size, options) = byte-identical output on every
  machine. Tests check this.
- All randomness comes from a seeded RNG passed in explicitly. No global `random`, no wall-clock time,
  and no iteration over unordered collections where order affects output (sort first).
- Any change that alters output for an existing seed is a **generator version bump**. Record it in
  `docs/DECISIONS.md`, and handle saves that depend on it (section 7).
- The Python generators in `tools/` are the reference. A port to the game engine must reproduce their
  output for a fixed set of golden seeds, checked by a test, before it replaces them.

## 7. Save data

(Applies once saving exists. The format is designed in `docs/ARCHITECTURE.md`.)

- Saves are versioned (`save_version`) and record the generator version and seed of the world they
  belong to.
- Every format change ships with a migration from every older released version, plus a test that
  loads a fixture save from each old version.
- Never silently drop or reinterpret saved data. If a save cannot be migrated, refuse to load it with
  a clear message and keep the file.
- A generator version bump must not break existing worlds. Either keep the old generator version
  loadable, or store the generated map in the save.

## 8. Performance and platforms

- The owner directed Android first, then Windows and Linux (section 1). Keep code platform-neutral and
  treat a mid-range phone as the slowest target.
- Pixel art renders with nearest-neighbour filtering at integer scale. Batch tiles; never draw one
  sprite per tile per frame without culling.
- Budgets (target fps, memory, load time, build size) get written here once the owner sets them; the
  engine entry in `docs/DECISIONS.md` is still Proposed.

## 9. Recording decisions

- `docs/DECISIONS.md` is the decision log: date, decision, who decided (owner / agent proposal), and
  why. Owner decisions are marked as such; agent proposals stay "Proposed" until the owner approves.
- `docs/GAME_DESIGN.md` moves an item from Undecided or Proposed to Confirmed only when the owner
  approves it, with a link to the decision entry.
- **Decision continuity (owner, 2026-10-27, DCR-01, `docs/directives/2026-10-27_design_continuity_directive.md`; standing).**
  Before implementing any newly approved decision, compare it with the earlier owner directives, settled decisions, the
  register, the code, verified behaviour, saves and migrations, and the release restrictions, and classify it as a
  **compatible extension**, an **intentional revision** (say exactly what changes and why) or a **conflict**. A later answer
  never silently supersedes an earlier one; context matters, above all for questions drawn from the historical design
  documents. Return only genuine conflicts to the owner, each with: requirement id, previous rule, its source, the new rule,
  the exact difference, systems and code affected, a proposed reconciliation and whether owner approval is needed. Never
  rewrite the earlier rule; preserve it and document any intentional change. Future-stage answers authorize no
  implementation. First review: `docs/design/DECISION_CONTINUITY_REVIEW_2026-10-27.md`.

## 9a. Requirements register (owner, 2026-10-19; standing, do not remove or weaken without the owner's approval)

The repository remembers what the owner asked for, not the agent. `docs/requirements/requirements.json` is the one
manually maintained register of requirements and owner decisions (owner directive 2026-10-23, REQ-CTRL-01,
`docs/directives/2026-10-23_master_requirements_reconciliation.md`; schema, status dimensions and procedure in
`docs/requirements/SCHEMA.md`). Everything else is generated (`docs/DEVELOPMENT_LEDGER.md`, `docs/requirements/views/`)
or historical (`docs/DECISIONS.md` narrative log, `docs/DEVELOPMENT_QUEUE.md`, archived handoffs).

- **One copy, edited on staging only.** The lead edits the register on `staging/my-medieval-life` with
  `tools/requirements_update.py`; build and task branches carry a synchronized copy and never edit it (the pre-push
  hook refuses it). Workers report to the lead; they do not edit the register.
- **Separate dimensions.** Approval, implementation, verification and release status are separate fields (SCHEMA.md);
  owner decisions carry a disposition (OPEN, APPROVED, PROVISIONAL, SUPERSEDED, REOPENED, DEFERRED). A commit, a merge
  or a passing local test never promotes a record by itself; COMPLETE needs integrated code, integration-level tests and
  every playtest need done. A recommendation is never an approval; PROVISIONAL is not final.
- **Progress comes from the views.** Every progress or completion figure reported to the owner is read from
  `docs/requirements/views/` (regenerated first), never estimated by hand; requirement counts and effort bands are
  reported separately.
- **Change control.** Approved decisions state design intent; when evidence shows a problem, record the intent, the
  problem, the affected records and the smallest fix, and ask the owner only when gameplay behaviour meaningfully
  changes (SCHEMA.md). Engineering corrections that keep the intent go ahead.

- **Capture at once.** Whenever the owner authorizes a feature, fix, system, rule or design change (a directive, a
  message, an answer to a question), before working on it: search the register for existing coverage; add or update the
  entry (stable id, title, the owner's wording, source, approval evidence, acceptance criteria, dependencies, related
  systems and rules, status, a history line); save a long directive verbatim in `docs/directives/`; run
  `python3 tools/check_requirements.py --write`; commit. Capture comes before compaction can lose it.
- **Nothing disappears.** An approved entry stays until it is COMPLETE against its acceptance criteria,
  SUPERSEDED by a named entry, or REJECTED with the owner's words cited. Ids are never deleted or reused; every
  status change gets a history line (who, when, what, why). A broad feature is not closed because one part works:
  give it child entries (`parent`) and close the parent only when its criteria are met.
- **Ideas are not approvals.** Agent proposals, ideas, open owner decisions and rules have their own kinds and are never
  counted as, or promoted to, approved work without the owner. Uncertain approval is OWNER DECISION REQUIRED.
- **Automated is not device.** Items needing a phone, controller, Windows PC or two devices keep `playtest` until a
  real device check is recorded; they cannot be COMPLETE before.
- **Enforced.** `tools/check_requirements.py --against <ref>` fails if an entry disappears or changes status without a
  history line; it runs in CI (against the previous commit), in the pre-push hook (against the remote branch) and in
  the pre-push checks below. `tests/test_requirements.py` proves it with a simulated deletion.
- **Session start.** Follow section 0: the views (STATUS, BUILD_18..21, DECISIONS, QUEUES), the next actions in
  `docs/CURRENT_DEVELOPMENT_STATE.md`, blocked and deferred items, the current build target, branches and worktrees
  (`git worktree list`), regressions, pending owner decisions, `docs/WORLD_DESIGN_RULES.md` and the system interaction
  manifest (`docs/SYSTEM_INTERACTION_MANIFEST.md`). Conversation memory is never the record.
- **Handoff and build boundaries.** Before a session ends, a context handoff or a build: update every touched entry
  (status, branch, commit, tests, known failures, next action) and push; `docs/CURRENT_DEVELOPMENT_STATE.md` names the active ids, branch,
  commit, uncommitted work, failures, blockers and next actions and points to the register instead of copying it. A
  build never starts a new backlog: unfinished entries carry over with their evidence.
- **Agents.** Every agent uses the register's ids, never makes a second list, and a completion claim needs evidence
  before its entry is closed.

## 10. Parallel agents

- The lead agent integrates and pushes to `staging/my-medieval-life` under section 5's standing authorization. A
  parallel agent (a subagent or another session working beside the lead) uses one branch and one draft PR per task,
  or a `wip/*` branch, and says which files and areas the task owns.
- Do not edit files another open PR owns. Coordinate through the PR or ask the owner.
- Generated data (`data/`, the manifest) is regenerated after rebasing or merging, never merged by
  hand. If two branches change a generator, the later one regenerates on top of the earlier.
- The requirements register (section 9a) is the shared task record: before a worker starts, the lead sets the record
  to IN DEVELOPMENT with `assigned_worker` and `branch` and names it in the state file, so two agents never take the
  same item (`docs/requirements/views/QUEUES.md`). Every worker brief includes the checklist in
  `docs/requirements/SCHEMA.md` ("Workers"): read the record, confirm approval, build, dependencies and acceptance
  criteria; stay in scope; report commits, tests and what still needs gameplay verification; never declare a record
  complete from local tests. `docs/DEVELOPMENT_PLAN.md` is the historical milestone plan.

## 11. Needs owner authorization

- Merging to `main`, changing repository settings, or force-pushing a shared branch
- Choosing or changing the engine, language or primary platform
- Any gameplay mechanic, or changing a Confirmed design item
- Adding, deleting or replacing source asset archives, or changing a licence label without a source
- Breaking save compatibility
- New third-party dependencies with licence or cost implications; paid services; new network or online capabilities outside the already approved multiplayer and MP-INTERACT-01 scope
- Publishing builds, releases or store listings

## 12. Reporting

- Report what was done, how it was verified, and what was not done, plainly. Never report a skipped
  step or an unlooked-at output as verified.
- Blockers that need the owner: state the decision needed, the options, and a recommendation, then
  stop that line of work and continue with anything unblocked.
- Incomplete work stays on its branch with a draft PR, and the PR description lists what remains.
