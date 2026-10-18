# Backrooms-Survivor

Scanned 2026-10-18T15:41:31Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Backrooms Survivor |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Godot 4.3 (godot/); legacy LÖVE2D Lua reference in the root |
| GitHub default branch | `main` @ `e33d7d94dda3daa20fae477f1e9762d770e80f16` (moving) |
| Most recent branch | `claude/fervent-franklin-hrrnb7` |
| Last commit on any branch | 2026-10-15 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Backrooms-Survivor |

## Purpose

"One game, one codebase. The LÖVE2D Lua files in the repo root are the **legacy reference implementation** ... The product is the Godot 4.3 project in `godot/`" (`main:CLAUDE.md`)

## Source of truth

docs/BRANCH_LEDGER.md (claude/fervent-franklin-hrrnb7): "**Authoritative line: `dev`**".

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `claude/exciting-cerf-8bng06` | `075d2fdcf8fcd92927f9a35439eab331f0e14cd9` | 2026-10-10 | 1 / 79 | agent session branch | NOT contained in `dev` | Add LÖVE shortcuts (Uninstall, LOVE, Documentation) |
| `claude/fervent-franklin-hrrnb7` | `9680d10e95959f575a16f74b9f6958a00e99f312` | 2026-10-15 | 8 / 0 | agent session branch | NOT contained in `dev` | Android: persistent signing identity (repo secrets, fail-closed release, pinned-certificat |
| `claude/jolly-cori-g4l8rg` | `916c3e1bdc01ed25837d71446f1a18e4720b2bdd` | 2026-10-11 | 0 / 61 | agent session branch | contained in `dev` | Add CC0 asset packs and credits for the Godot port |
| `dev` | `d71eacbf9507508f29f73b35b53062d699a52623` | 2026-10-15 | 7 / 0 | authoritative line (per repo records) |  | Phone layout: stat bars to the left edge, minimap toggled by a MAP button (default hidden, |
| `main` | `e33d7d94dda3daa20fae477f1e9762d770e80f16` | 2026-10-12 | 0 / 0 | GitHub default | contained in `dev` | R-2: manual-only authorized OTA publishing (dev-build.yml), shared build/OTA number sequen |

Pull-request refs on the remote: #1, #2, #3, #4, #5 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `build-14` | `759988f8994dd2ecbce6c0e9b32ec594382872ca` | 2026-10-13 | unknown | Minimap: every pickup and chaos orb as a dot in its own colour; headla |
| `dev` | `e33d7d94dda3daa20fae477f1e9762d770e80f16` | 2026-10-12 | unknown | R-2: manual-only authorized OTA publishing (dev-build.yml), shared bui |

## Asset manifests and licence records

- `docs/THIRD_PARTY_ASSETS.md`
- `enemies/manifest.lua`
- `godot/CREDITS.md`
- `godot/assets/third_party/animated_traps/LICENSE.txt`
- `godot/assets/third_party/kaykit_rpg_tools/License.txt`
- `godot/assets/third_party/screaming_brain_horror_textures/License.txt`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (293 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `DevTools/Spritesheet_Output/enemy_crawler_spritesheet.png` | 2048x128 | 57049 | `289389a97efc` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/enemy_crawler_spritesheet.png) |
| `DevTools/Spritesheet_Output/enemy_hound_spritesheet.png` | 2048x128 | 57049 | `289389a97efc` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/enemy_hound_spritesheet.png) |
| `DevTools/Spritesheet_Output/world_assets/_spritesheet_temp/frame_000.png` | 640x640 | 154989 | `0a4c85c11ad1` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/world_assets/_spritesheet_temp/frame_000.png) |
| `DevTools/Spritesheet_Output/world_assets/chair_office.png` | 640x640 | 215357 | `47219270571f` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/world_assets/chair_office.png) |
| `DevTools/Spritesheet_Output/world_assets/chair_simple.png` | 640x640 | 183286 | `31299df18439` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/world_assets/chair_simple.png) |
| `DevTools/Spritesheet_Output/world_assets/desk_standard.png` | 640x640 | 154794 | `498730d2665b` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/world_assets/desk_standard.png) |
| `DevTools/Spritesheet_Output/world_assets/filing_cabinet.png` | 640x640 | 125646 | `86ae0d0fddae` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/DevTools/Spritesheet_Output/world_assets/filing_cabinet.png) |
| `docs/android_ui_before_after/01_hud.jpg` | 2566x614 | 278455 | `ddda29ac5047` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/01_hud.jpg) |
| `docs/android_ui_before_after/02_status.jpg` | 2566x614 | 258554 | `0de3dc6d7b61` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/02_status.jpg) |
| `docs/android_ui_before_after/04_map.jpg` | 2566x614 | 171519 | `e6c2711da826` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/04_map.jpg) |
| `docs/android_ui_before_after/06_tip.jpg` | 2566x614 | 284599 | `48678a9674ed` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/06_tip.jpg) |
| `docs/android_ui_before_after/07_levelup.jpg` | 2566x614 | 112963 | `5d60e0e59980` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/07_levelup.jpg) |
| `docs/android_ui_before_after/08_pause.jpg` | 2566x614 | 114155 | `24b3d22c13d8` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/08_pause.jpg) |
| `docs/android_ui_before_after/09_options.jpg` | 2566x614 | 102037 | `2e759c944d68` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/09_options.jpg) |
| `docs/android_ui_before_after/10_howto.jpg` | 2566x614 | 199046 | `7acb1353fe92` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/10_howto.jpg) |
| `docs/android_ui_before_after/p01_title.jpg` | 2566x614 | 129870 | `7441859112fa` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/p01_title.jpg) |
| `docs/android_ui_before_after/p05_options_display.jpg` | 2566x614 | 95034 | `e9ed2edc9325` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/p05_options_display.jpg) |
| `docs/android_ui_before_after/p08_options_touch.jpg` | 2566x614 | 96183 | `8f0d3b083037` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/p08_options_touch.jpg) |
| `docs/android_ui_before_after/p09_death.jpg` | 2566x614 | 124442 | `153674de7228` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/android_ui_before_after/p09_death.jpg) |
| `docs/rc_before_after/deck.jpg` | 2566x834 | 394709 | `318c5eb56c2c` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/deck.jpg) |
| `docs/rc_before_after/howto_touch_after.jpg` | 1280x580 | 89965 | `d7f22c2b29e5` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/howto_touch_after.jpg) |
| `docs/rc_before_after/phone.jpg` | 2566x614 | 271282 | `17edb4abe36c` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/phone.jpg) |
| `docs/rc_before_after/phone_layout2_map_off.png` | 1280x580 | 924425 | `8f2f9f894604` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/phone_layout2_map_off.png) |
| `docs/rc_before_after/phone_layout2_map_on.png` | 1280x580 | 858201 | `7b1c8c5d44d9` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/phone_layout2_map_on.png) |
| `docs/rc_before_after/windows.jpg` | 3846x1114 | 640078 | `8d3230363b8a` | `dev` +1 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/docs/rc_before_after/windows.jpg) |
| `enemies/1 rect 1.png` | 1536x1024 | 1684188 | `6be2daef72e6` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/1%20rect%201.png) |
| `enemies/1 rect 2.png` | 1536x1024 | 1965140 | `4db73f838b62` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/1%20rect%202.png) |
| `enemies/1 rect 3.png` | 1536x1024 | 2822947 | `d9d54cdc7132` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/1%20rect%203.png) |
| `enemies/1 rect 4.png` | 1536x1024 | 1433035 | `e90b7c48465e` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/1%20rect%204.png) |
| `enemies/1 rect 6.png` | 1536x1024 | 3789544 | `19fd8de20163` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/1%20rect%206.png) |
| `enemies/12 grids 1.png` | 1536x1024 | 4358540 | `609486ebf5d0` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%201.png) |
| `enemies/12 grids 2.png` | 1536x1024 | 4158642 | `823f8c77329a` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%202.png) |
| `enemies/12 grids 3.png` | 1536x1024 | 4164529 | `cd153f6b81e4` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%203.png) |
| `enemies/12 grids 4.png` | 1536x1024 | 4245503 | `d7c839eacb31` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%204.png) |
| `enemies/12 grids 5.png` | 1536x1024 | 4216532 | `d95a7e154b3f` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%205.png) |
| `enemies/12 grids 6.png` | 1536x1024 | 2703731 | `90015dea78e9` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%206.png) |
| `enemies/12 grids 7.png` | 1536x1024 | 4084212 | `3a6c318433e8` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%207.png) |
| `enemies/12 grids 8.png` | 1536x1024 | 4058755 | `68c69aec638d` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/12%20grids%208.png) |
| `enemies/2 rect 5.png` | 1536x1024 | 1420086 | `b29178853785` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/2%20rect%205.png) |
| `enemies/sample creature blurr.png` | 1024x1024 | 2244555 | `3c2d4626de62` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/sample%20creature%20blurr.png) |
| `enemies/sample creature w detail.png` | 1024x1024 | 2380095 | `ee0537664c14` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/sample%20creature%20w%20detail.png) |
| `enemies/spacing test character.png` | 853x471 | 681363 | `cba241ec3da8` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemies/spacing%20test%20character.png) |
| `enemy_crawler_spritesheet.png` | 2048x128 | 192498 | `43b3bf278351` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemy_crawler_spritesheet.png) |
| `enemy_hound_spritesheet.png` | 2048x128 | 231207 | `dc17f50273f0` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemy_hound_spritesheet.png) |
| `enemy_shade_spritesheet.png` | 2048x128 | 233437 | `5f59e24fc0c9` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemy_shade_spritesheet.png) |
| `enemy_skinstealer_spritesheet.png` | 2048x128 | 258089 | `7bb7cfd84d76` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemy_skinstealer_spritesheet.png) |
| `enemy_wretch_spritesheet.png` | 2048x128 | 321514 | `c14b547a338f` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/enemy_wretch_spritesheet.png) |
| `godot/assets/branding/icon_192.png` | 192x192 | 40185 | `8f5f9ba4c2fc` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/branding/icon_192.png) |
| `godot/assets/branding/icon_512.png` | 512x512 | 246951 | `de05f6e78fed` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/branding/icon_512.png) |
| `godot/assets/branding/icon_bg_432.png` | 432x432 | 623 | `d97f3c314492` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/branding/icon_bg_432.png) |
| `godot/assets/branding/icon_fg_432.png` | 432x432 | 98583 | `4114552cb80c` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/branding/icon_fg_432.png) |
| `godot/assets/branding/studio_logo.png` | 1280x833 | 1693308 | `0093e717ee2d` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/branding/studio_logo.png) |
| `godot/assets/enemies/enemy_crawler_spritesheet.png` | 2048x128 | 192498 | `43b3bf278351` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/enemies/enemy_crawler_spritesheet.png) |
| `godot/assets/enemies/enemy_hound_spritesheet.png` | 2048x128 | 231207 | `dc17f50273f0` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/enemies/enemy_hound_spritesheet.png) |
| `godot/assets/enemies/enemy_shade_spritesheet.png` | 2048x128 | 233437 | `5f59e24fc0c9` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/enemies/enemy_shade_spritesheet.png) |
| `godot/assets/enemies/enemy_skinstealer_spritesheet.png` | 2048x128 | 258089 | `7bb7cfd84d76` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/enemies/enemy_skinstealer_spritesheet.png) |
| `godot/assets/enemies/enemy_wretch_spritesheet.png` | 2048x128 | 321514 | `c14b547a338f` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/enemies/enemy_wretch_spritesheet.png) |
| `godot/assets/objects/chair_office.png` | 640x640 | 215552 | `f638a4b0cd9d` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/objects/chair_office.png) |
| `godot/assets/sprites/player_spritesheet.png` | 2048x128 | 79783 | `e5d1aa1065d1` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/sprites/player_spritesheet.png) |
| `godot/assets/textures/carpet-tile.jpg` | 1050x700 | 96152 | `718e2cc0c393` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/textures/carpet-tile.jpg) |
| `godot/assets/textures/wood_grain.jpg` | 960x640 | 199970 | `97785f982be3` | `dev` +2 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/textures/wood_grain.jpg) |
| `godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_blueprint.png` | 512x512 | 39613 | `5f397fa49ac1` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_blueprint.png) |
| `godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_map.png` | 512x512 | 39727 | `59500ed13a8d` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_map.png) |
| `godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_map_empty.png` | 512x512 | 2387 | `489268e929cd` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_map_empty.png) |
| `godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_texture.png` | 1024x1024 | 28269 | `58cf2b3fa0ea` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/kaykit_rpg_tools/Textures/tools_bits_texture.png) |
| `godot/assets/third_party/monster_creatures_fantasy/Flying eye/Attack3.png` | 900x150 | 2617 | `03c97fa1b57e` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/monster_creatures_fantasy/Flying%20eye/Attack3.png) |
| `godot/assets/third_party/monster_creatures_fantasy/Goblin/Attack3.png` | 1800x150 | 5451 | `19b5823082fd` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/monster_creatures_fantasy/Goblin/Attack3.png) |
| `godot/assets/third_party/monster_creatures_fantasy/Goblin/Bomb_sprite.png` | 1900x100 | 4945 | `67a4a7f65b39` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/monster_creatures_fantasy/Goblin/Bomb_sprite.png) |
| `godot/assets/third_party/monster_creatures_fantasy/Mushroom/Attack3.png` | 1650x150 | 4342 | `940231779bca` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/monster_creatures_fantasy/Mushroom/Attack3.png) |
| `godot/assets/third_party/monster_creatures_fantasy/Skeleton/Attack3.png` | 900x150 | 4059 | `a94e99a02cb2` | `dev` +3 | [view](https://github.com/verbal76/Backrooms-Survivor/blob/d71eacbf9507508f29f73b35b53062d699a52623/godot/assets/third_party/monster_creatures_fantasy/Skeleton/Attack3.png) |
| ... 24 more in registry.json | | | | | |

Other art/source files (svg, psd, pdf, ...): 1; first few: `godot/icon.svg`

## Features and layout

Top level of `dev`:

`.github/` (4), `.gitignore` (1), `BUILD_ALL_AND_EXECUTABLE.bat` (1), `Blackcraft.ttf` (1), `CLAUDE.md` (1), `DevTools/` (27), `README.md` (1), `_installer.iss` (1), `bomb.lua` (1), `conf.lua` (1), `docs/` (29), `enemies.lua` (1), `enemies/` (18), `enemy_crawler_spritesheet.png` (1), `enemy_hound_spritesheet.png` (1), `enemy_shade_spritesheet.png` (1), `enemy_skinstealer_spritesheet.png` (1), `enemy_wretch_spritesheet.png` (1), `enemysounds.lua` (1), `godot/` (750), `input.lua` (1), `items.lua` (1), `main.lua` (1), `map.lua` (1), `music.lua` (1), `music/` (8), `options.lua` (1), `orbs.lua` (1), `player.lua` (1), `player_spritesheet.png` (1), `progression.lua` (1), `props.lua` (1), `props_placeholder.png` (1), `render.lua` (1), `shaders.lua` (1), `sounds/` (56), `tools/` (14), `weapons.lua` (1), `weapons/` (15), `world_assets/` (6)

Top level of default `main`: `.github/` (4), `.gitignore` (1), `BUILD_ALL_AND_EXECUTABLE.bat` (1), `Blackcraft.ttf` (1), `CLAUDE.md` (1), `DevTools/` (27), `README.md` (1), `_installer.iss` (1), `bomb.lua` (1), `conf.lua` (1), `docs/` (11), `enemies.lua` (1), `enemies/` (18), `enemy_crawler_spritesheet.png` (1), `enemy_hound_spritesheet.png` (1), `enemy_shade_spritesheet.png` (1), `enemy_skinstealer_spritesheet.png` (1), `enemy_wretch_spritesheet.png` (1), `enemysounds.lua` (1), `godot/` (750), `input.lua` (1), `items.lua` (1), `main.lua` (1), `map.lua` (1), `music.lua` (1), `music/` (8), `options.lua` (1), `orbs.lua` (1), `player.lua` (1), `player_spritesheet.png` (1), `progression.lua` (1), `props.lua` (1), `props_placeholder.png` (1), `render.lua` (1), `shaders.lua` (1), `sounds/` (56), `tools/` (14), `weapons.lua` (1), `weapons/` (15), `world_assets/` (6)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `claude/fervent-franklin-hrrnb7:.github/workflows/build-all.yml` | Build all platforms (reusable) | workflow_call:     inputs:       sha:         description: Full commit SHA to build (every platform uses exactly this)         required: true         type: stri |
| `claude/fervent-franklin-hrrnb7:.github/workflows/dev-build.yml` | OTA publish (manual only) | workflow_dispatch:     inputs:       source_sha:         description: Full 40-char SHA to publish (must be the current tip of dev)         required: true        |
| `claude/fervent-franklin-hrrnb7:.github/workflows/release-build.yml` | Coordinated release build (manual) | workflow_dispatch:     inputs:       platform:         description: android, windows, linux or all. A github_releases destination requires all (a coordinated re |
| `claude/fervent-franklin-hrrnb7:.github/workflows/validate-build.yml` | Validate build (non-publishing) | pull_request:     types: [opened, synchronize, reopened, labeled]     paths:       - "godot/**"       - "tools/**"       - ".github/workflows/**"   workflow_dis |
| `main:.github/workflows/build-all.yml` | Build all platforms (reusable) | workflow_call:     inputs:       sha:         description: Full commit SHA to build (every platform uses exactly this)         required: true         type: stri |
| `main:.github/workflows/dev-build.yml` | OTA publish (manual only) | workflow_dispatch:     inputs:       source_sha:         description: Full 40-char SHA to publish (must be the current tip of dev)         required: true        |
| `main:.github/workflows/release-build.yml` | Coordinated release build (manual) | workflow_dispatch:     inputs:       platform:         description: android, windows, linux or all. A github_releases destination requires all (a coordinated re |
| `main:.github/workflows/validate-build.yml` | Validate build (non-publishing) | pull_request:     types: [opened, synchronize, reopened, labeled]     paths:       - "godot/**"       - "tools/**"       - ".github/workflows/**"   workflow_dis |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 19 blobs.
- `38d528d6b481`: `DevTools/Spritesheet_Output/_spritesheet_temp/frame_008.png`, `DevTools/Spritesheet_Output/_spritesheet_temp/frame_010.png`, `DevTools/Spritesheet_Output/_spritesheet_temp/frame_011.png`
- `ec5a7a713303`: `Blackcraft.ttf`, `godot/assets/fonts/Blackcraft.ttf`
- `262f9dca6198`: `DevTools/Spritesheet_Output/_spritesheet_temp/frame_003.png`, `DevTools/Spritesheet_Output/_spritesheet_temp/frame_005.png`
- `6e67ab9b8e39`: `DevTools/Spritesheet_Output/_spritesheet_temp/frame_007.png`, `DevTools/Spritesheet_Output/_spritesheet_temp/frame_009.png`
- `29f05cd83fb2`: `DevTools/Spritesheet_Output/_spritesheet_temp/frame_013.png`, `DevTools/Spritesheet_Output/_spritesheet_temp/frame_015.png`
- `289389a97efc`: `DevTools/Spritesheet_Output/enemy_crawler_spritesheet.png`, `DevTools/Spritesheet_Output/enemy_hound_spritesheet.png`
- `43b3bf278351`: `enemy_crawler_spritesheet.png`, `godot/assets/enemies/enemy_crawler_spritesheet.png`
- `dc17f50273f0`: `enemy_hound_spritesheet.png`, `godot/assets/enemies/enemy_hound_spritesheet.png`
- `5f59e24fc0c9`: `enemy_shade_spritesheet.png`, `godot/assets/enemies/enemy_shade_spritesheet.png`
- `7bb7cfd84d76`: `enemy_skinstealer_spritesheet.png`, `godot/assets/enemies/enemy_skinstealer_spritesheet.png`
- `c14b547a338f`: `enemy_wretch_spritesheet.png`, `godot/assets/enemies/enemy_wretch_spritesheet.png`
- `eab55da3b4b8`: `godot/assets/glyphs/ps4/share.png`, `godot/assets/glyphs/ps4/view.png`
