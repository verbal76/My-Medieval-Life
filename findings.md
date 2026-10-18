# Findings

Observations only. Every item is a proposal; nothing was moved, merged, renamed or deleted.

## Duplicated files across repositories (same git blob SHA)

- 245 blobs appear in two or more repositories.
- 149 are controller/keyboard glyph PNGs (the same prompt icon pack copied under different names into up to 9 repos, e.g. blob `3bf4371d26e8` = Xbox A).
- The studio logo blob `e11f8c576652` is in 18 repos (see assets.md).

| Blob | Repositories and paths |
|---|---|
| `e11f8c576652` | Axolotl: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Cfm-calculator: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Climb-Up: `assets/branding/studio_splash.png` (+1); Endless-Escaspe: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Game-Designer: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Idle-game: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; LLM-Trainer: `branding/hot-attic-games/studio-logo.png`; Manual-J: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; My-Personal-Crossow0rd: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (+2); Ocean-spore: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Purgatory-Dungeon: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Ragdoll-Rally: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (+2); Tartaria-RPG: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; Zombie-squisher: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; personal-assistant-: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (+1); spiroglyphics: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (+1); voiceforge: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; web_auditor: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` |
| `1b33c55baabb` | Cfm-calculator: `android/gradle/wrapper/gradle-wrapper.jar`; Climb-Up: `gradle/wrapper/gradle-wrapper.jar`; Game-Designer: `gradle/wrapper/gradle-wrapper.jar`; LLM-Trainer: `gradle/wrapper/gradle-wrapper.jar` |
| `23d15a936707` | Cfm-calculator: `android/gradlew`; Climb-Up: `gradlew`; Game-Designer: `gradlew`; LLM-Trainer: `gradlew` |
| `5eed7ee84528` | Cfm-calculator: `android/gradlew.bat`; Climb-Up: `gradlew.bat`; Game-Designer: `gradlew.bat`; LLM-Trainer: `gradlew.bat` |
| `809546b9eeeb` | Endless-Escaspe: `assets/characters/texture-d.png`; Idle-game: `src/assets/character-texture.png`; Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-d.png`; Zombie-squisher: `assets-source/characters/texture-d.png` (+1) |
| `6cb06fdae2cc` | Endless-Escaspe: `assets/characters/texture-g.png`; Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-g.png`; Zombie-squisher: `assets-source/characters/texture-g.png` (+1) |
| `7c74a3c1be7d` | Endless-Escaspe: `assets/characters/texture-j.png`; Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-j.png`; Zombie-squisher: `assets-source/characters/texture-j.png` (+1) |
| `7ed6ff82de6b` | Climb-Up: `tools/otalab/release_flag.txt`; Purgatory-Dungeon: `VERSION`; personal-assistant-: `release/PUBLIC_VERSION` |
| `036d09bc5fd5` | Cfm-calculator: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (+1); Manual-J: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (+1) |
| `043df802a29f` | Cfm-calculator: `android/app/.gitignore`; Manual-J: `android/app/.gitignore` |
| `052c4e8e54b4` | Ocean-spore: `assets/blaster-l.glb`; Zombie-squisher: `assets/blaster-l.glb` |
| `0894e4d6e6c1` | Ocean-spore: `assets/blaster-n.glb`; Zombie-squisher: `assets/blaster-n.glb` |
| `0cfbf08886fc` | Climb-Up: `tools/otalab/live_e2e_run.txt` (+2); Purgatory-Dungeon: `VERSION` |
| `0e259d42c996` | Backrooms-Survivor: `godot/assets/third_party/animated_traps/LICENSE.txt`; My-Personal-Crossow0rd: `desktop/packaging/licenses/CC0-1.0.txt` |
| `1087bbafd229` | Ocean-spore: `assets/blaster-q.glb`; Zombie-squisher: `assets/blaster-q.glb` |
| `11f02fe2a006` | Idle-game: `src/vite-env.d.ts`; Manual-J: `src/vite-env.d.ts` |
| `11fd02fa2cf8` | Ocean-spore: `assets/bullet-foam-tip-thick.glb`; Zombie-squisher: `assets/bullet-foam-tip-thick.glb` |
| `19ec6cba8f8a` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-i.png`; Zombie-squisher: `assets-source/characters/texture-i.png` (+1) |
| `1a69bef536a7` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-o.glb`; Zombie-squisher: `assets-source/characters/character-o.glb` (+1) |
| `1be9f8e1ec1d` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-i.glb`; Zombie-squisher: `assets-source/characters/character-i.glb` (+1) |
| `1e8b31496214` | Manual-J: `release/VERSION`; Purgatory-Dungeon: `VERSION` |
| `20c0c70ea047` | Ocean-spore: `assets/blaster-i.glb`; Zombie-squisher: `assets/blaster-i.glb` |
| `25284ee29228` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-d.glb`; Zombie-squisher: `assets-source/characters/character-d.glb` (+1) |
| `2565a681ced4` | Ocean-spore: `assets/blaster-f.glb`; Zombie-squisher: `assets/blaster-f.glb` |
| `2e87c52f83c2` | Cfm-calculator: `android/gradle.properties`; Manual-J: `android/gradle.properties` |
| `2e99b7874675` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-a.glb`; Zombie-squisher: `assets-source/characters/character-a.glb` (+1) |
| `3212ae2cdd69` | Ocean-spore: `assets/blaster-k.glb`; Zombie-squisher: `assets/blaster-k.glb` |
| `38fe58986f18` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-f.png`; Zombie-squisher: `assets-source/characters/texture-f.png` (+1) |
| `394b9c272e33` | Ocean-spore: `assets/blaster-r.glb`; Zombie-squisher: `assets/blaster-r.glb` |
| `398889119c9e` | Ocean-spore: `assets/blaster-p.glb`; Zombie-squisher: `assets/blaster-p.glb` |
| `3a1baaeb36f7` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-g.glb`; Zombie-squisher: `assets-source/characters/character-g.glb` (+1) |
| `3a49ea259ff9` | Ocean-spore: `assets/blaster-g.glb`; Zombie-squisher: `assets/blaster-g.glb` |
| `3b4431d7724b` | Cfm-calculator: `android/settings.gradle`; Manual-J: `android/settings.gradle` |
| `3fcae2199335` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-l.glb`; Zombie-squisher: `assets-source/characters/character-l.glb` (+1) |
| `43eddd9d8791` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-p.png`; Zombie-squisher: `assets-source/characters/texture-p.png` (+1) |
| `44ae9b08bdb6` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-q.glb`; Zombie-squisher: `assets-source/characters/character-q.glb` (+1) |
| `46f06e61538d` | Ocean-spore: `assets/blaster-j.glb`; Zombie-squisher: `assets/blaster-j.glb` |
| `47e95c8a1d94` | Ocean-spore: `assets/blaster-c.glb`; Zombie-squisher: `assets/blaster-c.glb` |
| `48354a3dfc4a` | Cfm-calculator: `android/.gitignore`; Manual-J: `android/.gitignore` |
| `52a1ae1e624e` | Ocean-spore: `assets/silencer-larger.glb`; Zombie-squisher: `assets/silencer-larger.glb` |
| `573541ac9702` | Backrooms-Survivor: `godot/min_base_build.txt`; Tartaria-RPG: `.ci-mission-claims-baseline` (+1) |
| `59493405ab26` | Ocean-spore: `assets/grenade-a.glb`; Zombie-squisher: `assets/grenade-a.glb` |
| `5ad33102dc6a` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-n.png`; Zombie-squisher: `assets-source/characters/texture-n.png` (+1) |
| `5fd059fd0674` | Idle-game: `index.js`; Zombie-squisher: `index.js` (+1) |
| `6247ec57d1c8` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-f.glb`; Zombie-squisher: `assets-source/characters/character-f.glb` (+1) |
| `68f3cf5bd237` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-e.png`; Zombie-squisher: `assets-source/characters/texture-e.png` (+1) |
| `6a01b552c717` | Ocean-spore: `assets/grenade-b.glb`; Zombie-squisher: `assets/grenade-b.glb` |
| `6b0063df06b0` | Ocean-spore: `assets/scope-large-b.glb`; Zombie-squisher: `assets/scope-large-b.glb` |
| `71119df61fdf` | Ocean-spore: `assets/scope-large-a.glb`; Zombie-squisher: `assets/scope-large-a.glb` |
| `755957019277` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-c.glb`; Zombie-squisher: `assets-source/characters/character-c.glb` (+1) |
| `76171dca3314` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-r.png`; Zombie-squisher: `assets-source/characters/texture-r.png` (+1) |
| `7a60b85e148f` | Purgatory-Dungeon: `tools/ota/.gitignore`; Ragdoll-Rally: `.gitignore` |
| `7c054d8d6898` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-a.png`; Zombie-squisher: `assets-source/characters/texture-a.png` (+1) |
| `7f8f011eb73d` | Cfm-calculator: `release/VERSION` (+1); Purgatory-Dungeon: `VERSION` |
| `7fcd30d11631` | Ocean-spore: `assets/blaster-b.glb`; Zombie-squisher: `assets/blaster-b.glb` |
| `81a5cc60b339` | Ocean-spore: `eas.json`; Zombie-squisher: `eas.json` |
| `832c3b0855e3` | Ocean-spore: `assets/blaster-m.glb`; Zombie-squisher: `assets/blaster-m.glb` |
| `83820c6e11cd` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-m.glb`; Zombie-squisher: `assets-source/characters/character-m.glb` (+1) |
| `8600f846c9c2` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/character-k.glb`; Zombie-squisher: `assets-source/characters/character-k.glb` (+1) |
| `8b98e3d03ef0` | Ragdoll-Rally: `launch/assets/kenney/blocky-characters/Textures/texture-m.png`; Zombie-squisher: `assets-source/characters/texture-m.png` (+1) |
| ... | 36 more |

## Possibly abandoned or stale branches

A branch is listed when it is not contained in the repository's reference line (authoritative per records, else the most recent branch) and its last commit is more than 5 days older than the newest branch. Not verified at content level: work may have been cherry-picked or squashed.

- **Climb-Up** (reference `ccr-cb458cd1-w4dh5c`): `backup/build43-f7b6a39` (2026-10-09, `19e1cef72a42`), `main` (2026-10-08, `91597f1f392b`), `verify-secrets` (2026-10-09, `609dbf269587`)
- **Tartaria-RPG** (reference `golem-line`): `Dev_engine_PC` (2026-07-03, `3a39fe837f4a`), `HaL2001` (2026-08-20, `6435954f696e`), `api36-config-proof` (2026-09-15, `d68b35bd0ebf`), `apple_ios` (2026-08-19, `4784a10e3ef2`), `arbiters-line` (2026-07-03, `fd338c746da8`), `claude/armor-coating-golem` (2026-07-03, `5f4c96f428ec`), `claude/armor-coating-tartaria` (2026-07-03, `a43a4440cd8e`), `claude/armor-resist-preview-golem` (2026-07-03, `a86f3a326b41`), `claude/armor-resist-preview-tartaria` (2026-07-03, `dd4e5caef247`), `claude/coating-land-rule-golem` (2026-07-03, `a9327cf571d4`), `claude/coating-land-rule-tartaria` (2026-07-03, `8f3b625140da`), `claude/coatings-section-hal2001` (2026-07-03, `49dc899d52ac`), `claude/coatings-section-port` (2026-07-03, `abc89aa068a4`), `claude/handoff-review-gI5Ve` (2026-07-03, `f3722170e620`), `claude/hello-iteration-8-yctnkj` (2026-09-25, `b42fbbc9e625`), `claude/iteration-8-followups` (2026-10-05, `516aa68fec20`), `claude/jolly-cori-g4l8rg` (2026-10-04, `487de55121cd`), `claude/new-session-MvF82` (2026-07-03, `77e163997ce0`), `claude/rpg-final-review-MpGGM` (2026-07-24, `e286c07d2067`), `claude/sleepy-bohr-4kXYm` (2026-07-03, `82f0e47f5cbd`), `claude/steam-deck-compat` (2026-10-11, `58b5319cd850`), `claude/tartaria-game-handoff-n9cn1h` (2026-07-17, `e6849ee89f4c`), `engine_Dev` (2026-07-26, `d8ef2a759aae`), `html_dev` (2026-08-20, `70987a4caa88`), `iOS-initial` (2026-07-03, `33773c11fa2b`), `linux_dev` (2026-08-21, `3df147db4671`), `mac_dev` (2026-08-21, `91edf82f226d`), `main` (2026-10-04, `487de55121cd`), `promotions` (2026-09-27, `9cfcbebf5719`), `release/prod-aab-arb39` (2026-07-03, `8f0c94527493`), `revert` (2026-07-03, `e8cec6b40714`), `steam_Dev` (2026-08-20, `592339c5a3e9`), `submit-workflow-to-main` (2026-07-03, `b86bb39f5d05`)
- **Game-Designer** (reference `ccr-6330e20f-dm7zhm`): `main` (2026-10-07, `b28ff434aaa0`)
- **Axolotl** (reference `claude/mote-release-source`): `claude/mote-autoresume-wip` (2026-10-01, `f6b6b75d9679`), `claude/mote-leaves-wip` (2026-10-01, `5a71d34dbc88`), `claude/mote-menucam-wip` (2026-10-01, `01ea6e33dcfd`), `claude/mote-polish-a-wip` (2026-10-01, `a663fad4e0f2`), `main` (2026-10-04, `f3779f7c7f6e`), `preserve/mote-audit-round` (2026-10-07, `55fe0927eb81`), `preserve/mote-prey-pass` (2026-10-08, `1e5c02a6b5bf`)
- **Ocean-spore** (reference `ccr-47defc1a-89uvnr`): `claude/fix-ui-add-menus-3q8N7` (2026-05-12, `44202cdb838c`)
- **Ragdoll-Rally** (reference `claude/launch-gameplay-pivot`): `main` (2026-10-04, `41f5f5a8667b`)
- **Endless-Escaspe** (reference `claude/api36-native-qualification`): `Github-APK-Transition-Escap` (2026-05-11, `e970c74d6842`), `claude/boss-pickups-scene-rebuild-0YBha` (2026-04-28, `481e30774301`), `claude/fix-apk-screen-issue-etmic` (2026-05-11, `b595f5d0678b`), `claude/hold-ci-hardening` (2026-10-03, `5e8b92fbd15a`), `claude/hold-scenarios` (2026-10-03, `1c962e51118c`), `claude/ledger-docs` (2026-10-03, `d2c9c4e5e14e`), `main` (2026-10-04, `84f6b740b8ac`)
- **Idle-game** (reference `claude/repo-gameplay-review-loq9rq`): `Github-APK-Transition-snow` (2026-10-03, `bf96e840e574`), `claude/compile-teaching-document-zZQy6` (2026-05-11, `2d64524e17fb`), `claude/fix-ota-updates-rBtFA` (2026-05-08, `7e12a93dd48f`), `claude/hold-api36-migration` (2026-10-03, `db672e2d1aa4`), `claude/hold-save-export` (2026-10-03, `a59ab981e4cf`), `main` (2026-10-06, `968e195d5dac`)
- **My-Personal-Crossow0rd** (reference `claude/native-stack-modernization`): `claude/review-crossword-repro-5mjbG` (2026-04-26, `0960350ef4ec`), `main` (2026-10-04, `f7775d606c15`)
- **Zombie-squisher** (reference `ccr-27903f19-fy49jb`): `claude/fix-bounding-box-controls-7LQLQ` (2026-05-13, `4f454c3d157e`), `claude/fix-build-artifacts-visibility-rwXqU` (2026-05-09, `c74ae564b225`), `claude/github-game-builds-AAswD` (2026-05-09, `dba8096b15ae`)
- **voiceforge** (reference `claude/youthful-brahmagupta-n6sglt`): `claude/follow-dev-doc-KzL3e` (2026-05-18, `9ac6e3d98402`), `claude/pto-ledger-balance-cap-29vll2` (2026-09-18, `87fe0737ac5c`)
- **personal-assistant-** (reference `claude/api36-native-modernization`): `claude/add-recording-folders-Q0wSM` (2026-04-30, `a2149dab2376`), `claude/audio-file-import-wvG8O` (2026-05-05, `255ce4453633`), `claude/debug-record-screen-sGvzp` (2026-04-24, `a74a43be226c`), `claude/debug-search-input-eqnpZ` (2026-04-30, `63fcf7c5e44b`), `claude/fix-white-screen-issue-Hmi6u` (2026-04-24, `557d819e8843`)

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
