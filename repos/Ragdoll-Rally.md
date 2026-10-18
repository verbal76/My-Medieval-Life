# Ragdoll-Rally

Scanned 2026-10-18T15:42:05Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Ragdoll Rally Launch |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Godot 4.7.1 (launch/) |
| GitHub default branch | `main` @ `41f5f5a8667bc3930eedfa2a322855a440dc1e9d` (moving) |
| Most recent branch | `claude/launch-gameplay-pivot` |
| Last commit on any branch | 2026-10-12 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Ragdoll-Rally |

## Purpose

CLAUDE.md: "Game name stays **Ragdoll Rally Launch** in the app and About"; "ONE game, ONE Godot project (`launch/`), many targets (Android, Windows, Linux/Steam Deck)." (`claude/launch-gameplay-pivot:CLAUDE.md`)

## Source of truth

docs/BRANCH_LEDGER.md: "Authoritative development line: `claude/launch-gameplay-pivot` @ `c27db17ab323`" (the branch has since moved; see branch table).

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `ccr-7c0d7291-e3d5o1` | `e2c16e4defcfb154c9321a296a62a3d71a277e03` | 2026-10-03 | 8 / 1 | agent session branch | contained in `claude/launch-gameplay-pivot` | Fix About/Settings panel and update overlay layout (found via screenshot review) |
| `claude/launch-api36-modernization` | `a389ec4d650fc5cbee1a2d51883f252753a18535` | 2026-10-03 | 11 / 1 | agent session branch | contained in `claude/launch-gameplay-pivot` | Docs: G2 migration record, physical test checklist, Play identity update |
| `claude/launch-expanded-playfield` | `db4534ef32eba4fa33b011e843f5dc791c256385` | 2026-10-03 | 14 / 1 | agent session branch | contained in `claude/launch-gameplay-pivot` | Launch: much deeper/wider city (23 targets, grand castle), overdrive power band, bullseye  |
| `claude/launch-gameplay-pivot` | `979fcce4c99026864c72412ba78dd1fd583419b9` | 2026-10-12 | 93 / 1 | authoritative line (per repo records), agent session branch |  | Build pipeline repair: register build.yml via a pull_request echo job (builds stay dispatc |
| `claude/launch-mayhem-upgrades` | `822588236d8ecef772748bba1b99010116a7c556` | 2026-10-04 | 21 / 1 | agent session branch | contained in `claude/launch-gameplay-pivot` | Release convention: public version v<N> from release/release.json, v11 retrofit, About sho |
| `main` | `41f5f5a8667bc3930eedfa2a322855a440dc1e9d` | 2026-10-04 | 0 / 0 | GitHub default | NOT contained in `claude/launch-gameplay-pivot`; 8 days older than the newest branch: possibly stale or abandoned (unverified by content) | Add files via upload |
| `verbal76-patch-1` | `3f482014011480e9e55e32ed79f3f5a708a97ca5` | 2026-10-03 | 0 / 3 | unknown | contained in `claude/launch-gameplay-pivot` | Add files via upload |
| `windows-internal-test` | `758a309762f5aff4155b940843b000a0a2e72d3c` | 2026-10-11 | 9 / 7 | unknown | NOT contained in `claude/launch-gameplay-pivot` | Steam Deck internal test builds (Linux native + Windows) |
| `wip/gameplay-pivot` | `027f9d8f4bbe8493dd5ea129762d0bc93435f309` | 2026-10-04 | 21 / 1 | agent WIP snapshot | contained in `claude/launch-gameplay-pivot` | WIP: gameplay pivot (characters, skipping, limbs, fire, upgrades, Test Yard) - not a relea |

Pull-request refs on the remote: #1, #2, #3, #4, #5, #6 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `v18` | `dcb9c4d7faec092e18f2ca08145923ad334342d0` | 2026-10-11 | unknown | Deliver Ragdoll Rally Launch v18: left stick no longer cycles menu but |
| `v17` | `2a80b903cd4714bac869bb3346a57e0308104016` | 2026-10-11 | unknown | Deliver Ragdoll Rally Launch v17: exit button, bigger cities, persiste |
| `v16` | `7a97a8fcd418439afcdd119619b74678b0c7e94d` | 2026-10-11 | unknown | Deliver Ragdoll Rally Launch v16: remappable controller SELECT button  |
| `v15` | `15c414af269066424fbde47a1b7da221c6f7704c` | 2026-10-11 | unknown | Release Ragdoll Rally Launch v15 (deliver) |
| `launch-ota-channel-poc-g2` | `faeb937439ced8fe8751deaf25c9f898b0110e6e` | 2026-10-08 | unknown | OTA: republish mayhem/destruction pass to channel poc-g2 (the channel  |
| `launch-ota-poc-g2-3-faeb937` | `faeb937439ced8fe8751deaf25c9f898b0110e6e` | 2026-10-08 | unknown | OTA: republish mayhem/destruction pass to channel poc-g2 (the channel  |
| `launch-ota-channel-poc` | `28d5c0d75a2aecf81d043524a3fcb0cf0170131f` | 2026-10-08 | unknown | OTA: publish mayhem/destruction pass to channel poc (all local gates g |
| `launch-ota-poc-2-28d5c0d` | `28d5c0d75a2aecf81d043524a3fcb0cf0170131f` | 2026-10-08 | unknown | OTA: publish mayhem/destruction pass to channel poc (all local gates g |
| `v14` | `60064326748fee796e4bde3f7c5bebe32534713c` | 2026-10-07 | unknown | Deliver Ragdoll Rally Launch v14 (physical-test candidate); license no |
| `v13` | `8c1caab4468584bc13a2229207737298799560c2` | 2026-10-05 | unknown | Deliver Ragdoll Rally Launch v13 |
| `v12` | `5ff3d5de79fa2ad8bda047c931745dc001410f69` | 2026-10-04 | unknown | Fix release-notes step arguments (pass versionCode and CI run separate |
| `rr-launch-b15` | `cac2e291732485d879f93d2e8e336b71912a4172` | 2026-10-04 | unknown | Test: skid check asserts it never dead-stops instead of a tight margin |
| `v11` | `cac2e291732485d879f93d2e8e336b71912a4172` | 2026-10-04 | unknown | Test: skid check asserts it never dead-stops instead of a tight margin |
| `launch-g2m-b12` | `9fa7d1df3501ab60013ab6fba4746b3178e004c6` | 2026-10-04 | unknown | Launch: add canonical Hot Attic Games logo (studio splash now shows) |
| `launch-g2m-b11` | `8bdee8959a4e36e76ee31c788ed26e8a44634083` | 2026-10-03 | unknown | Launch: fix runaway/backward skid assist, keep forward speed on first  |
| `launch-g2x-b9` | `db4534ef32eba4fa33b011e843f5dc791c256385` | 2026-10-03 | unknown | Launch: much deeper/wider city (23 targets, grand castle), overdrive p |
| `launch-g2x-b8` | `1114f10671f73b99356bacd9e83881e9ae29b595` | 2026-10-03 | unknown | Launch: expanded playfield (angled opening camera + camera-basis aim,  |
| `launch-g2-b7` | `5f6a122a01b157fdb84d89ba72deab3eb1095614` | 2026-10-03 | unknown | Launch G2: Godot 4.7.1 migration (Gradle route, targetSdk 36), physics |
| `launch-poc-b6` | `e2c16e4defcfb154c9321a296a62a3d71a277e03` | 2026-10-03 | unknown | Fix About/Settings panel and update overlay layout (found via screensh |
| `launch-ota-channel-test` | `67d965aac1550b2ff471e3cebbf66416d8ee4ca7` | 2026-10-03 | unknown | OTA workflow: publish on committed request file (channel test pipeline |
| `launch-ota-test-1-67d965a` | `67d965aac1550b2ff471e3cebbf66416d8ee4ca7` | 2026-10-03 | unknown | OTA workflow: publish on committed request file (channel test pipeline |
| `launch-poc-b5` | `67d965aac1550b2ff471e3cebbf66416d8ee4ca7` | 2026-10-03 | unknown | OTA workflow: publish on committed request file (channel test pipeline |
| `launch-poc-b4` | `5ca7b477e846bd5ab45a4173656ae3da165f2c93` | 2026-10-03 | unknown | CI: fix release name YAML quoting |
| `launch-poc-b2` | `b179d6f1914b4cfc4674dd2a5eee5cfadd4cbd20` | 2026-10-03 | unknown | Playable POC: launcher, Jolt ragdoll, destructible town, scoring, rese |
| `launch-poc-b1` | `94d5e83f3f7cdd43ac09a6d5c825f6f2d53ac3ab` | 2026-10-03 | unknown | Add Android APK CI workflow and export preset |

## Asset manifests and licence records

- `docs/RECOVERY_MANIFEST.md`
- `launch/ASSETS_LICENSES.md`
- `launch/assets/kenney/blocky-characters/License.txt`
- `launch/assets/kenney/retro-fantasy-kit/License.txt`
- `launch/tests/fixtures/ota_manifest_poc-g2_seq3_faeb937.json`
- `third_party/kenney_building-kit/License.txt`
- `third_party/kenney_modular-buildings/License.txt`
- `third_party/kenney_splatpack/License.txt`
- `tools/provenance.py`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (173 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `branding/RR_Launch_Icon.png` | 1254x1254 | 2064473 | `bbc63db5bc08` | `claude/launch-gameplay-pivot` +2 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/branding/RR_Launch_Icon.png) |
| `docs/v14_evidence/fx_blood_fire_smoke.jpg` | 1024x576 | 77147 | `c135abf8bc46` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/fx_blood_fire_smoke.jpg) |
| `docs/v14_evidence/fx_blood_fire_smoke_b.jpg` | 1024x576 | 68488 | `e61263f675b1` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/fx_blood_fire_smoke_b.jpg) |
| `docs/v14_evidence/hill_rolling_high.jpg` | 1024x576 | 128784 | `39bfedaab007` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_rolling_high.jpg) |
| `docs/v14_evidence/hill_rolling_launch.jpg` | 1024x576 | 82404 | `3ed3606d28e0` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_rolling_launch.jpg) |
| `docs/v14_evidence/hill_rolling_mid.jpg` | 1024x576 | 106939 | `5bbfe2f0e212` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_rolling_mid.jpg) |
| `docs/v14_evidence/hill_skyline_high.jpg` | 1024x576 | 143302 | `50c7c02d9854` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_skyline_high.jpg) |
| `docs/v14_evidence/hill_skyline_launch.jpg` | 1024x576 | 86325 | `4f3b3548af50` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_skyline_launch.jpg) |
| `docs/v14_evidence/hill_skyline_mid.jpg` | 1024x576 | 110093 | `1e53c598f9db` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_skyline_mid.jpg) |
| `docs/v14_evidence/hill_steep_high.jpg` | 1024x576 | 136532 | `7d0b0087db1f` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_steep_high.jpg) |
| `docs/v14_evidence/hill_steep_launch.jpg` | 1024x576 | 83926 | `0c7fdc7f4990` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_steep_launch.jpg) |
| `docs/v14_evidence/hill_steep_mid.jpg` | 1024x576 | 113194 | `3abe49a9c067` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_steep_mid.jpg) |
| `docs/v14_evidence/hill_valley_high.jpg` | 1024x576 | 143326 | `f703ff4cbbf5` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_valley_high.jpg) |
| `docs/v14_evidence/hill_valley_launch.jpg` | 1024x576 | 88217 | `7f0a55599774` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_valley_launch.jpg) |
| `docs/v14_evidence/hill_valley_mid.jpg` | 1024x576 | 113356 | `e1056c5a6139` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/hill_valley_mid.jpg) |
| `docs/v14_evidence/run_hill_steep_00_aim.jpg` | 1024x576 | 79319 | `aa9c0df062d6` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/run_hill_steep_00_aim.jpg) |
| `docs/v14_evidence/run_hill_steep_03_run.jpg` | 1024x576 | 104426 | `0412a4114ce1` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/run_hill_steep_03_run.jpg) |
| `docs/v14_evidence/run_hill_steep_06_run.jpg` | 1024x576 | 106653 | `0cee3da3b7aa` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/run_hill_steep_06_run.jpg) |
| `docs/v14_evidence/run_hill_steep_10_run.jpg` | 1024x576 | 69563 | `ff2d26cd548c` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/run_hill_steep_10_run.jpg) |
| `docs/v14_evidence/trajectory_profile.png` | 980x560 | 79727 | `9e71f48abdef` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/docs/v14_evidence/trajectory_profile.png) |
| `launch/assets/fx/splat_atlas.png` | 768x768 | 136772 | `21d70b3834f5` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/fx/splat_atlas.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-a.png` | 1024x1024 | 20171 | `7c054d8d6898` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-a.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-b.png` | 1024x1024 | 15606 | `9d7f85c2342a` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-b.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-c.png` | 1024x1024 | 12829 | `ecf680d0d693` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-c.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-d.png` | 1024x1024 | 13151 | `809546b9eeeb` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-d.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-e.png` | 1024x1024 | 14509 | `68f3cf5bd237` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-e.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-f.png` | 1024x1024 | 15886 | `38fe58986f18` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-f.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-g.png` | 1024x1024 | 16069 | `6cb06fdae2cc` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-g.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-h.png` | 1024x1024 | 16215 | `fdda30b9c47d` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-h.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-i.png` | 1024x1024 | 14496 | `19ec6cba8f8a` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-i.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-j.png` | 1024x1024 | 17576 | `7c74a3c1be7d` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-j.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-k.png` | 1024x1024 | 17437 | `ad7e356c18f5` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-k.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-l.png` | 1024x1024 | 22764 | `c4a7996ce61c` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-l.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-m.png` | 1024x1024 | 19343 | `8b98e3d03ef0` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-m.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-n.png` | 1024x1024 | 16824 | `5ad33102dc6a` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-n.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-o.png` | 1024x1024 | 21064 | `e7776591eb34` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-o.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-p.png` | 1024x1024 | 18000 | `43eddd9d8791` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-p.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-q.png` | 1024x1024 | 16102 | `f4d122428770` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-q.png) |
| `launch/assets/kenney/blocky-characters/Textures/texture-r.png` | 1024x1024 | 13909 | `76171dca3314` | `claude/launch-gameplay-pivot` +5 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/blocky-characters/Textures/texture-r.png) |
| `launch/assets/kenney/modular-buildings/Textures/colormap.png` | 512x512 | 6524 | `965e424c992f` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/modular-buildings/Textures/colormap.png) |
| `launch/assets/kenney/modular-buildings/Textures/variation-b.png` | 512x512 | 5451 | `a0106002388f` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/assets/kenney/modular-buildings/Textures/variation-b.png) |
| `launch/branding/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `claude/launch-gameplay-pivot` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/branding/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `launch/branding/RR_Launch_512.png` | 512x512 | 428960 | `feee7f0cca2e` | `claude/launch-gameplay-pivot` +2 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/branding/RR_Launch_512.png) |
| `launch/branding/RR_Launch_adaptive_bg_432.png` | 432x432 | 803 | `df3db4d563f4` | `claude/launch-gameplay-pivot` +2 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/branding/RR_Launch_adaptive_bg_432.png) |
| `launch/branding/RR_Launch_adaptive_fg_432.png` | 432x432 | 171892 | `c5a31dc49009` | `claude/launch-gameplay-pivot` +2 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/branding/RR_Launch_adaptive_fg_432.png) |
| `launch/branding/RR_Launch_main_192.png` | 192x192 | 75946 | `3ff2df32c21a` | `claude/launch-gameplay-pivot` +2 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/979fcce4c99026864c72412ba78dd1fd583419b9/launch/branding/RR_Launch_main_192.png) |
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `main` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/41f5f5a8667bc3930eedfa2a322855a440dc1e9d/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `branding/RR_Legacy_Icon.png` | 1254x1254 | 2136605 | `682508703230` | `claude/launch-mayhem-upgrades` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/branding/RR_Legacy_Icon.png) |
| `launch/branding/Hot_Attic_Games_Master_Logo.png` | 1536x1024 | 2838266 | `e11f8c576652` | `claude/launch-mayhem-upgrades` +1 | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/launch/branding/Hot_Attic_Games_Master_Logo.png) |
| `legacy/branding/RR_Legacy_512.png` | 512x512 | 427931 | `8ea19678e699` | `claude/launch-mayhem-upgrades` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/legacy/branding/RR_Legacy_512.png) |
| `legacy/branding/RR_Legacy_adaptive_bg_432.png` | 432x432 | 803 | `df3db4d563f4` | `claude/launch-mayhem-upgrades` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/legacy/branding/RR_Legacy_adaptive_bg_432.png) |
| `legacy/branding/RR_Legacy_adaptive_fg_432.png` | 432x432 | 168646 | `cb08f71bdcc6` | `claude/launch-mayhem-upgrades` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/legacy/branding/RR_Legacy_adaptive_fg_432.png) |
| `legacy/branding/RR_Legacy_main_192.png` | 192x192 | 73642 | `4a091dcd1ce2` | `claude/launch-mayhem-upgrades` | [view](https://github.com/verbal76/Ragdoll-Rally/blob/822588236d8ecef772748bba1b99010116a7c556/legacy/branding/RR_Legacy_main_192.png) |

Other art/source files (svg, psd, pdf, ...): 1; first few: `launch/icon.svg`

## Features and layout

Top level of `claude/launch-gameplay-pivot`:

`.github/` (5), `.gitignore` (1), `CLAUDE.md` (1), `README.md` (1), `branding/` (1), `docs/` (51), `kenney_blocky-characters_20.zip` (1), `kenney_retro-fantasy-kit.zip` (1), `launch/` (718), `release/` (6), `third_party/` (12), `tools/` (10)

Top level of default `main`: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `README.md` (1), `docs/` (2), `kenney_blocky-characters_20.zip` (1), `kenney_retro-fantasy-kit.zip` (1)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `claude/launch-gameplay-pivot:.github/workflows/build.yml` | Coordinated build | pull_request:     paths:       - '.github/workflows/build.yml'   workflow_dispatch:     inputs:       platform:         description: 'Platforms to build'        |
| `claude/launch-gameplay-pivot:.github/workflows/checks.yml` | Lightweight checks | pull_request: |
| `claude/launch-gameplay-pivot:.github/workflows/launch-ota.yml` | Launch OTA publish | workflow_dispatch:     inputs:       confirm:         description: 'Type exactly: PUBLISH OTA'         type: string         required: true       request_sha256: |
| `claude/launch-gameplay-pivot:.github/workflows/release-retrofit.yml` | Release retrofit (one-off) | workflow_dispatch: |

## Sensitive files (paths only; contents not read)

- `launch/debug.keystore`

## Unknowns and duplicates

Same blob under more than one path on some branch head: 2 blobs.
- `e11f8c576652`: `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`, `launch/branding/Hot_Attic_Games_Master_Logo.png`, `launch/branding/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`
- `df3db4d563f4`: `launch/branding/RR_Launch_adaptive_bg_432.png`, `legacy/branding/RR_Legacy_adaptive_bg_432.png`
- The GitHub default branch `main` holds only 6 files while work lives on `claude/launch-gameplay-pivot`; anyone cloning the default sees an upload snapshot, not the product.
