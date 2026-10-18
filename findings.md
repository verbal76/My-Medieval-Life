# Findings

Observations only. Every item is a proposal; nothing was moved, merged, renamed or deleted.

## Duplicated files across repositories (same git blob SHA)

- 93 blobs appear in two or more repositories.
- 87 are controller/keyboard glyph PNGs (the same prompt icon pack copied under different names into up to 9 repos, e.g. blob `3bf4371d26e8` = Xbox A).
- The studio logo blob `e11f8c576652` is in 5 repos (see assets.md).

| Blob | Repositories and paths |
|---|---|
| `e11f8c576652` | Axolotl: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Climb-Up: `assets/branding/studio_splash.png` (+1); Game-Designer: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Ocean-spore: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Tartaria-RPG: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` |
| `1b33c55baabb` | Climb-Up: `gradle/wrapper/gradle-wrapper.jar`; Game-Designer: `gradle/wrapper/gradle-wrapper.jar` |
| `23d15a936707` | Climb-Up: `gradlew`; Game-Designer: `gradlew` |
| `573541ac9702` | Backrooms-Survivor: `godot/min_base_build.txt`; Tartaria-RPG: `.ci-mission-claims-baseline` (+1) |
| `5eed7ee84528` | Climb-Up: `gradlew.bat`; Game-Designer: `gradlew.bat` |
| `c18dd8d83cee` | Backrooms-Survivor: `.gitignore`; Fix-Tremors: `.gitignore` |

## Possibly abandoned or stale branches

A branch is listed when it is not contained in the repository's reference line (authoritative per records, else the most recent branch) and its last commit is more than 5 days older than the newest branch. Not verified at content level: work may have been cherry-picked or squashed.

- **Climb-Up** (reference `ccr-cb458cd1-w4dh5c`): `backup/build43-f7b6a39` (2026-10-09, `19e1cef72a42`), `main` (2026-10-08, `91597f1f392b`), `verify-secrets` (2026-10-09, `609dbf269587`)
- **Tartaria-RPG** (reference `golem-line`): `Dev_engine_PC` (2026-07-03, `3a39fe837f4a`), `HaL2001` (2026-08-20, `6435954f696e`), `api36-config-proof` (2026-09-15, `d68b35bd0ebf`), `apple_ios` (2026-08-19, `4784a10e3ef2`), `arbiters-line` (2026-07-03, `fd338c746da8`), `claude/armor-coating-golem` (2026-07-03, `5f4c96f428ec`), `claude/armor-coating-tartaria` (2026-07-03, `a43a4440cd8e`), `claude/armor-resist-preview-golem` (2026-07-03, `a86f3a326b41`), `claude/armor-resist-preview-tartaria` (2026-07-03, `dd4e5caef247`), `claude/coating-land-rule-golem` (2026-07-03, `a9327cf571d4`), `claude/coating-land-rule-tartaria` (2026-07-03, `8f3b625140da`), `claude/coatings-section-hal2001` (2026-07-03, `49dc899d52ac`), `claude/coatings-section-port` (2026-07-03, `abc89aa068a4`), `claude/handoff-review-gI5Ve` (2026-07-03, `f3722170e620`), `claude/hello-iteration-8-yctnkj` (2026-09-25, `b42fbbc9e625`), `claude/iteration-8-followups` (2026-10-05, `516aa68fec20`), `claude/jolly-cori-g4l8rg` (2026-10-04, `487de55121cd`), `claude/new-session-MvF82` (2026-07-03, `77e163997ce0`), `claude/rpg-final-review-MpGGM` (2026-07-24, `e286c07d2067`), `claude/sleepy-bohr-4kXYm` (2026-07-03, `82f0e47f5cbd`), `claude/steam-deck-compat` (2026-10-11, `58b5319cd850`), `claude/tartaria-game-handoff-n9cn1h` (2026-07-17, `e6849ee89f4c`), `engine_Dev` (2026-07-26, `d8ef2a759aae`), `html_dev` (2026-08-20, `70987a4caa88`), `iOS-initial` (2026-07-03, `33773c11fa2b`), `linux_dev` (2026-08-21, `3df147db4671`), `mac_dev` (2026-08-21, `91edf82f226d`), `main` (2026-10-04, `487de55121cd`), `promotions` (2026-09-27, `9cfcbebf5719`), `release/prod-aab-arb39` (2026-07-03, `8f0c94527493`), `revert` (2026-07-03, `e8cec6b40714`), `steam_Dev` (2026-08-20, `592339c5a3e9`), `submit-workflow-to-main` (2026-07-03, `b86bb39f5d05`)
- **Game-Designer** (reference `ccr-6330e20f-dm7zhm`): `main` (2026-10-07, `b28ff434aaa0`)
- **Axolotl** (reference `claude/mote-release-source`): `claude/mote-autoresume-wip` (2026-10-01, `f6b6b75d9679`), `claude/mote-leaves-wip` (2026-10-01, `5a71d34dbc88`), `claude/mote-menucam-wip` (2026-10-01, `01ea6e33dcfd`), `claude/mote-polish-a-wip` (2026-10-01, `a663fad4e0f2`), `main` (2026-10-04, `f3779f7c7f6e`), `preserve/mote-audit-round` (2026-10-07, `55fe0927eb81`), `preserve/mote-prey-pass` (2026-10-08, `1e5c02a6b5bf`)
- **Ocean-spore** (reference `ccr-47defc1a-89uvnr`): `claude/fix-ui-add-menus-3q8N7` (2026-05-12, `44202cdb838c`)

## Conflicting or unresolved sources of truth

- **Default branch is not the product line** in most repos: Climb-Up, Tartaria-RPG, Axolotl, Ocean-spore, Purgatory-Dungeon, Ragdoll-Rally, Endless-Escaspe, Idle-game, My-Personal-Crossow0rd, Zombie-squisher, LLM-Trainer, Cfm-calculator, Manual-J, voiceforge, spiroglyphics, Fix-Tremors and Game-Designer keep a small upload snapshot on `main` while work lives on `claude/*` or `ccr-*` branches. Purgatory-Dungeon's ledger says agent worktrees "are cut from the default branch", so agents start from the wrong code.
- **Zombie-squisher**: docs/BRANCH_LEDGER.md names `ccr-27903f19-fy49jb` the authoritative line; README.md on the same branch calls `Github-build-pipeline-zombie-crusher` the "Primary working branch". The game name (Squisher vs Crusher) is an open owner decision.
- **Tartaria-RPG**: HANDOFF.md says `golem-line` is the trunk and `HaL2001` is archived but the HAL product "is the live line"; `main` is a 12-file snapshot.
- **Idle-game**: product name differs by branch ("Boarder" on `main`, "Where's the Bottom?" on the agent lines); the authoritative line is named in `authoritative.json`.
- **Climb-Up / Upwardly**: the store-art location is unknown (not in any repo); `docs/windows/STEAM_PACKAGING.md` ("Nothing here has been uploaded to Steam") is outdated against HANDOFF.md (Build 70 live on Steam).
- **My-Medieval-Life**: `wip/agent-a71e3cddb5b8d02d4` and `wip/agent-a892fc619ec33a8eb` have parents outside staging: unresolved whether integrated by content. CLAUDE.md says the formal engine entry in docs/DECISIONS.md is still *Proposed* while the Godot 4.7 prototype is in use. Four asset packs carry the `verify` licence label.
- **Visibility**: only 8 repos had visibility given; the rest were readable through the session git proxy, which may carry credentials. Manual-J's CLAUDE.md says not to make the repo public; its actual visibility is unchecked.

## Consolidation opportunities (proposals only)

- One shared studio-assets source (studio logo, controller glyph pack, Kenney packs) instead of copies in up to 18 repos; repos would record the source and hash.
- Make each repo's authoritative line its GitHub default branch (owner action), or record the authoritative branch in the README, so new agents and clones start from the right code.
- Prune or archive agent session branches already contained in the authoritative line (listed as "contained in" in each repo file), after the owner reviews them.
- Move `ClimbUp_restore_backup.zip` out of My-Medieval-Life to Climb-Up or Game-Designer, where it belongs (its manifest entry already says it is not an art pack).
- Remove the byte-identical duplicate uploads on My-Medieval-Life `main` when the owner next merges staging (staging already has one copy).
- Put the Upwardly Steam store and library art in `branding/steam/` on the authoritative line once located, beside the icons and achievements.
- Give HotAtticGames.github.io real content (it holds only README.md), e.g. one page per product from this registry.
