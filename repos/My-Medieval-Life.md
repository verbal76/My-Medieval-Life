# My-Medieval-Life

Scanned 2026-10-18T15:51:02Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | My Medieval Life |
| Kind | game |
| Visibility | public |
| Engine / language | Godot 4.7 (game/), Python 3 tooling (tools/) |
| GitHub default branch | `main` @ `1031a2e3fef25abc6821cc1b795626bd8b5c9ec8` (moving) |
| Most recent branch | `inventory/registry` |
| Last commit on any branch | 2026-10-18 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/My-Medieval-Life |

## Purpose

"My Medieval Life is a 2D medieval game built from 16x16 pixel-art packs (mostly by Shade)." (`staging/my-medieval-life:CLAUDE.md`)

## Source of truth

Per CLAUDE.md section 5: `staging/my-medieval-life` is the remote branch for ongoing development; `main` is "the approved integrated source" and changes only when the owner merges; `wip/<worktree>` hold unfinished agent snapshots. Build 7 (`679907121654c7630b170690752429b55a74b8ac`) is the active testing release (CLAUDE.md, docs/release/BUILD_7_ISSUES.md).

## Current development (My-Medieval-Life records)

- `staging/my-medieval-life` head at scan: `60ac3e21329be47f43a4427feb5cb05d1416e951` (moving). `main` head: `1031a2e3fef25abc6821cc1b795626bd8b5c9ec8` (moving; owner-merge only).
- Records read on staging at that SHA: `CLAUDE.md`, `docs/DEVELOPMENT_QUEUE.md`, `docs/HANDOFF.md`, `docs/release/BUILD_7_ISSUES.md`, `ASSET_MANIFEST.md`, `asset_manifest.csv`, `game/assets/PROVENANCE.json` (`mml-provenance/1`), `game/data/resources.json` (`mml-resources/1`), `docs/systems/RESOURCE_NODE_MANIFEST.md`, `docs/systems/RESOURCE_USAGE_REGISTRY.md`.
- `docs/DEVELOPMENT_QUEUE.md`: "Build 7 is the testing release. No Build 8, no replacement release, no merge into `main` without the owner's explicit authorization." Item 10 is this registry ("Discovery only; nothing moved").
- `docs/release/BUILD_7_ISSUES.md`: Release `build-7` (pre-release), source commit `679907121654c7630b170690752429b55a74b8ac`.

### wip/agent-* snapshot branches

Each is a snapshot commit on top of agent work. "Head in staging" uses `git merge-base --is-ancestor`; a snapshot head is never an ancestor, so the parent is checked too. Content-level integration was not verified.

| Branch | Head | Head in staging | Parent | Parent in staging | Diff vs staging merge-base |
|---|---|---|---|---|---|
| `wip/agent-a217c774f1de24975` | `2ed67ca8113bfb8ea169df71631f4a920078f281` | no | `4ff0cc9ccec15d3c133e4b04e62fd049a05f817d` | yes | 21 files changed, 1447 insertions(+), 188 deletions(-) |
| `wip/agent-a2a2ffd98ae088c5c` | `90f383105668dee4e1f1fe6366a14230242535c3` | no | `fabb58fcbf83f27f0d8acec9dd46b10ee84a4242` | yes | 7 files changed, 498 insertions(+), 8 deletions(-) |
| `wip/agent-a71e3cddb5b8d02d4` | `ca7cb871f337d44fa366c2bfdd205150249ff748` | no | `76360004e74c8b51686d8d3b1cc2fc9eb90f02e9` | no | 6 files changed, 798 insertions(+), 2 deletions(-) |
| `wip/agent-a73835a027337e85e` | `a6a09f335c63fb971e8a75aa57f37a7ce5423c40` | no | `020bb8889c4362dec497e890c3fba20e318efc22` | yes | 14 files changed, 738 insertions(+), 94 deletions(-) |
| `wip/agent-a892fc619ec33a8eb` | `394195d2af9100719b1afbe8f9b8b568cb8bc241` | no | `36f66e1672c803445c563afe158791fe57417c6b` | no | 12 files changed, 2472 insertions(+), 13 deletions(-) |
| `wip/agent-ac3f19ceb6d7088ba` | `4048139333cf16c17226b0a8bceb0077c6efd342` | no | `020bb8889c4362dec497e890c3fba20e318efc22` | yes | 14 files changed, 873 insertions(+), 87 deletions(-) |
| `wip/agent-ad98d07112ec5147a` | `615cd0c357680c56e5e8ece4c51cb3cd958e20ef` | no | `c8033acd92433aa6b548608b73bc00b185e41a09` | yes | 22 files changed, 2499 insertions(+), 152 deletions(-) |

By the ancestry test no wip head is in staging, so none counts as integrated. Where the parent is in staging, only the snapshot of uncommitted work is outside it; where the parent is not (`wip/agent-a71e3cddb5b8d02d4`, `wip/agent-a892fc619ec33a8eb` at scan time), committed agent work is outside staging too. Whether any of it reached staging by another route (cherry-pick, re-implementation) is unresolved.

### Builds 1 to 7

| Release | Tag commit | In staging | In main |
|---|---|---|---|
| `build-1` | `c13c54b68bdd16d4ab1bb4b33bfb56b6fedc8a07` | yes | no |
| `build-2` | `2bf0b45c341dae3ac9dc6b1a49a39ac1dea23397` | yes | no |
| `build-3` | `73342cbd5bf14c8878a737703ffa0644e22e75af` | yes | no |
| `build-4` | `c6518eeb17a58b079b2e3e6da71d43dee1545bb8` | yes | no |
| `build-5` | `6d9ded95eb7eccafa0d8d845e34a86fe96f9e1f0` | yes | no |
| `build-6` | `3d7bbce28953514344de27c1efeda7c2d63f525e` | yes | no |
| `build-7` | `679907121654c7630b170690752429b55a74b8ac` | yes | no |

Every build tag is contained in staging and none in `main`, consistent with CLAUDE.md section 5 ("An approved test build may come from an approved staging commit without merging into `main`").

### Asset records

- `ASSET_MANIFEST.md` / `asset_manifest.csv` (generated by `tools/build_manifest.py`): every file in every source archive with size, SHA-256 and image dimensions. Licence labels: paid / CC0 / CC BY 4.0 / free / verify.
- Labelled `verify` (licence unresolved in the repo's own records): `Character-Customizer.zip`, `My_Medieval_Life_Icon_Pack.zip` (the game's app icon, 48 to 1024 px), `PUNY_WORLD_v1.zip`, `Flat Game UI Icon Pack/`.
- `ClimbUp_restore_backup.zip` is described in the manifest as "NOT an art pack: backup of a separate 'Climb up' game-designer project (project.json + splash image)". Its splash member `studio_splash_e3d9bb56.png` (1536x1024, sha256 `e3d9bb56...`) is the Hot Attic Games master logo, the same file as Climb-Up's `branding/master/studio_splash_e3d9bb56.png`. It belongs to Climb-Up / Game-Designer, not this game: a consolidation candidate (proposal only).
- `main` holds byte-identical duplicate uploads: `MiniWorldSprites.zip`, `MiniWorldSprites (1).zip`, `MiniWorldSprites (2).zip` (blob `25d808fffc66`), and `PUNY-WORLD-PAID_v1.zip`, `PUNY-WORLD-PAID_v1 (1).zip` (blob `fd6c1a26e133`). Staging keeps one copy of each.
- `game/assets/PROVENANCE.json` (`mml-provenance/1`) records each imported file's source zip, member, transform and sha256; `game/data/resources.json` (`mml-resources/1`) is the one definition of resource nodes; `docs/systems/*.md` are generated from it.

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `claude/charming-albattani-8jjfya` | `3d7bbce28953514344de27c1efeda7c2d63f525e` | 2026-10-18 | 83 / 0 | agent session branch | contained in `staging/my-medieval-life` | Add the side-quest engine: offers from real needs, delivered goods, paid by the giver |
| `inventory/registry` | `cd07f74b04425c6bc8feb40160806436f67ccc34` | 2026-10-18 | 5 / 4 | this registry (orphan) | NOT contained in `staging/my-medieval-life` | Add registry batch 4: My-Personal-Crossow0rd, Zombie-squisher, voiceforge, LLM-Trainer |
| `main` | `1031a2e3fef25abc6821cc1b795626bd8b5c9ec8` | 2026-10-17 | 0 / 0 | GitHub default | contained in `staging/my-medieval-life` | Add files via upload |
| `staging/my-medieval-life` | `60ac3e21329be47f43a4427feb5cb05d1416e951` | 2026-10-18 | 141 / 0 | authoritative line (per repo records) |  | Add the Build 8 readiness report (no build authorized) |
| `wip/agent-a217c774f1de24975` | `2ed67ca8113bfb8ea169df71631f4a920078f281` | 2026-10-18 | 111 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | WIP snapshot of agent-a217c774f1de24975's uncommitted work |
| `wip/agent-a2a2ffd98ae088c5c` | `90f383105668dee4e1f1fe6366a14230242535c3` | 2026-10-18 | 135 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | Add the journal's Resources & Gathering page, built from the resource registry |
| `wip/agent-a71e3cddb5b8d02d4` | `ca7cb871f337d44fa366c2bfdd205150249ff748` | 2026-10-18 | 122 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | WIP snapshot of agent-a71e3cddb5b8d02d4's uncommitted work |
| `wip/agent-a73835a027337e85e` | `a6a09f335c63fb971e8a75aa57f37a7ce5423c40` | 2026-10-18 | 106 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | WIP snapshot of agent-a73835a027337e85e's uncommitted work |
| `wip/agent-a892fc619ec33a8eb` | `394195d2af9100719b1afbe8f9b8b568cb8bc241` | 2026-10-18 | 128 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | Generate the resource manifests and add uses, sources and chains |
| `wip/agent-ac3f19ceb6d7088ba` | `4048139333cf16c17226b0a8bceb0077c6efd342` | 2026-10-18 | 108 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | WIP snapshot of agent-ac3f19ceb6d7088ba's uncommitted work |
| `wip/agent-ad98d07112ec5147a` | `615cd0c357680c56e5e8ece4c51cb3cd958e20ef` | 2026-10-18 | 113 / 0 | agent WIP snapshot | NOT contained in `staging/my-medieval-life` | WIP snapshot of agent-ad98d07112ec5147a's uncommitted work |

Pull-request refs on the remote: #1 (refs only; PR state not read).

## Tags and releases

Releases read with the GitHub API (this session's scope). Tags are immutable references unless moved; the commit is the peeled tag target.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `build-7` | `679907121654c7630b170690752429b55a74b8ac` | 2026-10-18 | My Medieval Life Build 7 (pre-release), published 2026-10-18 | Embed the approved icon in the Windows executable and verify it |
| `build-6` | `3d7bbce28953514344de27c1efeda7c2d63f525e` | 2026-10-18 | My Medieval Life Build 6 (pre-release), published 2026-10-18 | Add the side-quest engine: offers from real needs, delivered goods, pa |
| `build-5` | `6d9ded95eb7eccafa0d8d845e34a86fe96f9e1f0` | 2026-10-18 | My Medieval Life Build 5 (pre-release), published 2026-10-18 | Add a book-like journal; an heir inherits only the starting kit |
| `build-4` | `c6518eeb17a58b079b2e3e6da71d43dee1545bb8` | 2026-10-18 | My Medieval Life Build 4 (pre-release), published 2026-10-18 | Walk around obstacles when tapping, and follow a tapped villager to ta |
| `build-3` | `73342cbd5bf14c8878a737703ffa0644e22e75af` | 2026-10-18 | My Medieval Life Build 3 (pre-release), published 2026-10-18 | Show only the latest two village events, fading; the heir inherits no  |
| `build-2` | `2bf0b45c341dae3ac9dc6b1a49a39ac1dea23397` | 2026-10-18 | My Medieval Life Build 2 (pre-release), published 2026-10-18 | Keep typing in the field the player chose |
| `build-1` | `c13c54b68bdd16d4ab1bb4b33bfb56b6fedc8a07` | 2026-10-18 | My Medieval Life Build 1 (pre-release), published 2026-10-18 | Publish every build as a GitHub Release; record the owner's decisions |

## Asset manifests and licence records

- `ASSET_MANIFEST.md`
- `asset_manifest.csv`
- `assets.md`
- `docs/SYSTEM_INTERACTION_MANIFEST.md`
- `docs/systems/RESOURCE_NODE_MANIFEST.md`
- `game/assets/PROVENANCE.json`
- `tools/build_manifest.py`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (255 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `16x16 Assorted RPG Icons (partial)/armours.png` | 144x304 | 28619 | `d47c1b0506ad` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/armours.png) |
| `16x16 Assorted RPG Icons (partial)/books.png` | 224x192 | 6355 | `ba08f8948f86` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/books.png) |
| `16x16 Assorted RPG Icons (partial)/chests.png` | 128x96 | 5736 | `803e43ce647c` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/chests.png) |
| `16x16 Assorted RPG Icons (partial)/consumables.png` | 704x272 | 33301 | `c276af0cc261` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/consumables.png) |
| `16x16 Assorted RPG Icons (partial)/items-1.png` | 112x16 | 2830 | `b24cdf929a56` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/items-1.png) |
| `16x16 Assorted RPG Icons (partial)/items-2.png` | 112x16 | 2483 | `2f413eff82e8` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/items-2.png) |
| `16x16 Assorted RPG Icons (partial)/potions.png` | 336x240 | 28152 | `2d3d30b41ec4` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/potions.png) |
| `16x16 Assorted RPG Icons (partial)/tools-gems-ingots.png` | 96x64 | 4752 | `1d5168bc56aa` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/tools-gems-ingots.png) |
| `16x16 Assorted RPG Icons (partial)/weapons.png` | 128x144 | 4379 | `3446f9d2e747` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/16x16%20Assorted%20RPG%20Icons%20(partial)/weapons.png) |
| `Flat Game UI Icon Pack/preview_set_1_dark.jpg` | 2000x2000 | 185055 | `62799a33eaa2` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/Flat%20Game%20UI%20Icon%20Pack/preview_set_1_dark.jpg) |
| `Flat Game UI Icon Pack/preview_set_1_white.png` | 4167x4167 | 225529 | `b6d9587657a8` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/Flat%20Game%20UI%20Icon%20Pack/preview_set_1_white.png) |
| `Flat Game UI Icon Pack/preview_set_2_dark.jpg` | 2000x2000 | 191811 | `d73e0272914b` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/Flat%20Game%20UI%20Icon%20Pack/preview_set_2_dark.jpg) |
| `Flat Game UI Icon Pack/preview_set_2_white.png` | 4167x4167 | 331184 | `c641dbd484c4` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/Flat%20Game%20UI%20Icon%20Pack/preview_set_2_white.png) |
| `Flat Game UI Icon Pack/preview_set_3.jpg` | 4000x4000 | 1613433 | `bc2ac59ccac4` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/Flat%20Game%20UI%20Icon%20Pack/preview_set_3.jpg) |
| `game/assets/characters/bandit_00.png` | 928x256 | 25531 | `ee20b3296763` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_00.png) |
| `game/assets/characters/bandit_01.png` | 928x256 | 25986 | `126163eca143` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_01.png) |
| `game/assets/characters/bandit_02.png` | 928x256 | 25502 | `824bf189dd92` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_02.png) |
| `game/assets/characters/bandit_03.png` | 928x256 | 26957 | `b71f3e191c0c` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_03.png) |
| `game/assets/characters/bandit_04.png` | 928x256 | 24984 | `f8b957e3a503` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_04.png) |
| `game/assets/characters/bandit_05.png` | 928x256 | 24797 | `0b11a03247a4` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/bandit_05.png) |
| `game/assets/characters/guard_00.png` | 928x256 | 26239 | `95ccbfbaf8b2` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_00.png) |
| `game/assets/characters/guard_01.png` | 928x256 | 26134 | `a08dd6b6a017` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_01.png) |
| `game/assets/characters/guard_02.png` | 928x256 | 26637 | `0c81f3df09db` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_02.png) |
| `game/assets/characters/guard_03.png` | 928x256 | 31079 | `54112851d0c2` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_03.png) |
| `game/assets/characters/guard_04.png` | 928x256 | 28668 | `620725694d5e` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_04.png) |
| `game/assets/characters/guard_05.png` | 928x256 | 26548 | `4ba6fceb6cac` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/guard_05.png) |
| `game/assets/characters/player_00.png` | 928x256 | 37043 | `bb09c226280c` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_00.png) |
| `game/assets/characters/player_01.png` | 928x256 | 29130 | `db86f8c61942` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_01.png) |
| `game/assets/characters/player_02.png` | 928x256 | 29202 | `64b1bf0fc755` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_02.png) |
| `game/assets/characters/player_03.png` | 928x256 | 33608 | `e2eec8acb2bf` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_03.png) |
| `game/assets/characters/player_f0_basic.png` | 928x256 | 24581 | `5276f35c87a8` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f0_basic.png) |
| `game/assets/characters/player_f0_tunic.png` | 928x256 | 24474 | `9c38c8752b10` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f0_tunic.png) |
| `game/assets/characters/player_f1_basic.png` | 928x256 | 25920 | `0aecc5d5c14b` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f1_basic.png) |
| `game/assets/characters/player_f1_tunic.png` | 928x256 | 25997 | `d971f1a3601c` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f1_tunic.png) |
| `game/assets/characters/player_f2_basic.png` | 928x256 | 27919 | `f52426ebc0c1` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f2_basic.png) |
| `game/assets/characters/player_f2_tunic.png` | 928x256 | 27746 | `ec5d1f50cf5c` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f2_tunic.png) |
| `game/assets/characters/player_f3_basic.png` | 928x256 | 27543 | `eca375503d12` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f3_basic.png) |
| `game/assets/characters/player_f3_tunic.png` | 928x256 | 26897 | `e781f5a2e561` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_f3_tunic.png) |
| `game/assets/characters/player_m0_basic.png` | 928x256 | 24882 | `0067477ede07` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m0_basic.png) |
| `game/assets/characters/player_m0_tunic.png` | 928x256 | 25474 | `3984f873f1e3` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m0_tunic.png) |
| `game/assets/characters/player_m1_basic.png` | 928x256 | 24983 | `dddf8bdd67c7` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m1_basic.png) |
| `game/assets/characters/player_m1_tunic.png` | 928x256 | 24984 | `07a210ad5b37` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m1_tunic.png) |
| `game/assets/characters/player_m2_basic.png` | 928x256 | 27840 | `f7b4f9ba7e3e` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m2_basic.png) |
| `game/assets/characters/player_m2_tunic.png` | 928x256 | 26924 | `9ab07f283984` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m2_tunic.png) |
| `game/assets/characters/player_m3_basic.png` | 928x256 | 27128 | `9f05a07185b7` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m3_basic.png) |
| `game/assets/characters/player_m3_tunic.png` | 928x256 | 27077 | `ec656d2fd5aa` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/player_m3_tunic.png) |
| `game/assets/characters/villager_00.png` | 928x256 | 27670 | `9c47dc68021a` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_00.png) |
| `game/assets/characters/villager_01.png` | 928x256 | 27694 | `f173fc1a9358` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_01.png) |
| `game/assets/characters/villager_02.png` | 928x256 | 27404 | `16dfae382569` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_02.png) |
| `game/assets/characters/villager_03.png` | 928x256 | 25435 | `e7d9a2315ca6` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_03.png) |
| `game/assets/characters/villager_04.png` | 928x256 | 30061 | `be54e77fdc3b` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_04.png) |
| `game/assets/characters/villager_05.png` | 928x256 | 25965 | `5680163c0b36` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_05.png) |
| `game/assets/characters/villager_06.png` | 928x256 | 24464 | `3e98f0a1e08a` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_06.png) |
| `game/assets/characters/villager_07.png` | 928x256 | 26950 | `f4872b09b38b` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_07.png) |
| `game/assets/characters/villager_08.png` | 928x256 | 29084 | `68d62ec313bf` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_08.png) |
| `game/assets/characters/villager_09.png` | 928x256 | 24174 | `7bbc08f70b03` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_09.png) |
| `game/assets/characters/villager_10.png` | 928x256 | 30233 | `757b96cdd46f` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_10.png) |
| `game/assets/characters/villager_11.png` | 928x256 | 25556 | `05a0ad19fb7e` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_11.png) |
| `game/assets/characters/villager_12.png` | 928x256 | 26451 | `9ec9370402e5` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_12.png) |
| `game/assets/characters/villager_13.png` | 928x256 | 30564 | `fedffae77a84` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_13.png) |
| `game/assets/characters/villager_14.png` | 928x256 | 24751 | `09d045744ac9` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_14.png) |
| `game/assets/characters/villager_15.png` | 928x256 | 35033 | `c745c9fd3833` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_15.png) |
| `game/assets/characters/villager_16.png` | 928x256 | 27176 | `293b222c21d8` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_16.png) |
| `game/assets/characters/villager_17.png` | 928x256 | 27989 | `2a046a48a193` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_17.png) |
| `game/assets/characters/villager_18.png` | 928x256 | 28324 | `ee37d1f55d5e` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_18.png) |
| `game/assets/characters/villager_19.png` | 928x256 | 30780 | `942610a3f747` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_19.png) |
| `game/assets/characters/villager_20.png` | 928x256 | 24068 | `c334e137a1b9` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_20.png) |
| `game/assets/characters/villager_21.png` | 928x256 | 24833 | `5a213532c4fb` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_21.png) |
| `game/assets/characters/villager_22.png` | 928x256 | 30148 | `74d0ce04f905` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_22.png) |
| `game/assets/characters/villager_23.png` | 928x256 | 26200 | `aba83f76c6a6` | `staging/my-medieval-life` +8 | [view](https://github.com/verbal76/My-Medieval-Life/blob/60ac3e21329be47f43a4427feb5cb05d1416e951/game/assets/characters/villager_23.png) |
| ... 69 more in registry.json | | | | | |

Other art/source files (svg, psd, pdf, ...): 4; first few: `Flat Game UI Icon Pack/Flat_game_UI_set_3.ai`, `Flat Game UI Icon Pack/Flat_game_UI_set_3_copy.pdf`, `Flat Game UI Icon Pack/icons_set_1.ai`, `Flat Game UI Icon Pack/icons_set_2.ai`

## Features and layout

Top level of `staging/my-medieval-life`:

`.github/` (1), `.gitignore` (1), `16x16 Armour RPG Icons.zip` (1), `16x16 Assorted RPG Icons (partial)/` (9), `16x16 Jewelry RPG Icons.zip` (1), `16x16 Survival RPG Icons.zip` (1), `16x16 miniworld - octoshrimpy  -  indoor update.zip` (1), `ASSET_MANIFEST.md` (1), `CLAUDE.md` (1), `Character-Customizer.zip` (1), `ClimbUp_restore_backup.zip` (1), `CozyFarm_full_version.zip` (1), `Flat Game UI Icon Pack/` (11), `MiniWorldSprites.zip` (1), `Miniworld-Guide.docx` (1), `My_Medieval_Life_Icon_Pack.zip` (1), `PUNY-WORLD-PAID_v1.zip` (1), `PUNY_CHARACTERS_v2.1.zip` (1), `PUNY_CHARACTERS_v2.1_tdsm-2026.zip` (1), `PUNY_DUNGEON_v1.zip` (1), `PUNY_MYTH-CREATURES-RPGMAKER_v1.zip` (1), `PUNY_SKILLS_v1.zip` (1), `PUNY_WORLD_v1.zip` (1), `Puny-Characters.zip` (1), `PunyMonsters.zip` (1), `Simple_Falt_Game_Interface_Pack.zip` (1), `SunGraphica_Minimal_Icons_FREE.zip` (1), `TinyRanch_Assets.zip` (1), `asset_manifest.csv` (1), `data/` (2), `docs/` (36), `game/` (539), `kenney_input-prompts_1.5.zip` (1), `kenney_splatpack.zip` (1), `miniworld +__rainbow-refresh.zip` (1), `punyworld-dungeon-tileset.png` (1), `research/` (281), `tests/` (7), `tools/` (28)

Top level of default `main`: `16x16 Armour RPG Icons.zip` (1), `16x16 Jewelry RPG Icons.zip` (1), `16x16 Survival RPG Icons.zip` (1), `16x16 miniworld - octoshrimpy  -  indoor update.zip` (1), `Character-Customizer.zip` (1), `ClimbUp_restore_backup.zip` (1), `MiniWorldSprites (1).zip` (1), `MiniWorldSprites (2).zip` (1), `MiniWorldSprites.zip` (1), `Miniworld-Guide.docx` (1), `PUNY-WORLD-PAID_v1 (1).zip` (1), `PUNY-WORLD-PAID_v1.zip` (1), `PUNY_CHARACTERS_v2.1.zip` (1), `PUNY_CHARACTERS_v2.1_tdsm-2026.zip` (1), `PUNY_DUNGEON_v1.zip` (1), `PUNY_SKILLS_v1.zip` (1), `miniworld +__rainbow-refresh.zip` (1), `punyworld-dungeon-tileset.png` (1)

## CI workflows

Path and trigger only; never changed or run.

None on the default or most recent branch.

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 5 blobs.
- `25d808fffc66`: `MiniWorldSprites (1).zip`, `MiniWorldSprites (2).zip`, `MiniWorldSprites.zip`
- `fd6c1a26e133`: `PUNY-WORLD-PAID_v1 (1).zip`, `PUNY-WORLD-PAID_v1.zip`
- `0966c6e6733b`: `game/assets/ui/attack.png`, `game/assets/ui/slot_weapon.png`
- `7752477124c2`: `game/assets/ui/coins.png`, `game/assets/ui/skill_trading.png`
- `f51ba67641ec`: `game/assets/ui/skill_woodcutting.png`, `game/assets/ui/slot_tool.png`
- The GitHub default branch `main` holds only 18 files while work lives on `staging/my-medieval-life`; anyone cloning the default sees an upload snapshot, not the product.
