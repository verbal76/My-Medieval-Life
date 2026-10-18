# Purgatory-Dungeon

Scanned 2026-10-18T15:41:42Z from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.

| | |
|---|---|
| Product | Purgatory Dungeon |
| Kind | game |
| Visibility | not stated (read through the session git proxy; may be private) |
| Engine / language | Godot 4.6, GDScript (Forward Plus, Jolt) |
| GitHub default branch | `main` @ `f0eaa471c85d8b76fb68b35a37efba485a054364` (moving) |
| Most recent branch | `ccr-5f32885a-gvu16v` |
| Last commit on any branch | 2026-10-13 |
| Status | active (active = a commit within 14 days of 2026-10-18) |
| Links | https://github.com/verbal76/Purgatory-Dungeon |

## Purpose

"First-person procedural dungeon-crawler roguelike (Barbarian or Mage) built in **Godot 4.6**" (`ccr-5f32885a-gvu16v:README.md`)

## Source of truth

docs/BRANCH_LEDGER.md (2026-10-12): "Authoritative line at the time of the audit: branch `ccr-5f32885a-gvu16v`"; `main` "still points at the old v2.5 upload snapshot".

## Branches

Branch heads move; the SHA is the head at scan time.

| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |
|---|---|---|---|---|---|---|
| `android-port` | `93702f853773bd6a518ac9344d3100fd35da3d3e` | 2026-10-05 | 49 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Swarm rooms (red barriers) stay dormant until the player's first daily buff selection |
| `ccr-5f32885a-gvu16v` | `94408dec77c72caf68bbd6b63d9090661e99beb9` | 2026-10-13 | 309 / 0 | authoritative line (per repo records), agent session branch |  | Build 9: OTA pointer validation, no activation without a verified save backup, VERSION 9 / |
| `checkpoint/pre-ui-brand-93702f8` | `93702f853773bd6a518ac9344d3100fd35da3d3e` | 2026-10-05 | 49 / 2 | backup / checkpoint | contained in `ccr-5f32885a-gvu16v` | Swarm rooms (red barriers) stay dormant until the player's first daily buff selection |
| `checkpoint/v6-candidate-23cdb6b` | `23cdb6b538fb11842787343ec6e44be0c213c5af` | 2026-10-05 | 114 / 2 | backup / checkpoint | contained in `ccr-5f32885a-gvu16v` | Docs: baked control art, asset list, sizes, states, regeneration |
| `main` | `f0eaa471c85d8b76fb68b35a37efba485a054364` | 2026-10-05 | 0 / 0 | GitHub default | contained in `ccr-5f32885a-gvu16v` | Add files via upload |
| `ota-chain` | `a9168e16ceac23b0dbb00d3f34f12ff3be070901` | 2026-10-05 | 115 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v6 release commit (version metadata only) |
| `ota/dev/0e1d11095e8a2196abed3e1c4d1d9261bc5678da` | `0e1d11095e8a2196abed3e1c4d1d9261bc5678da` | 2026-10-07 | 247 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | Fix an intermittent release-gate failure in test_dungeon_entry (no behaviour or tuning cha |
| `ota/dev/0f3dc9ad1a939052ff06de27c05c233e0fd09b56` | `0f3dc9ad1a939052ff06de27c05c233e0fd09b56` | 2026-10-07 | 248 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | Run the floor-mesh repairs before the worker-thread prop loads start (fixes the intermitte |
| `ota/dev/1e0e97b85ea1810776fc40dfa7a4ef8fa5a3ced4` | `1e0e97b85ea1810776fc40dfa7a4ef8fa5a3ced4` | 2026-10-07 | 246 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | v8.1: keep the opening's population near the player (fixes the 2-3 minute enemy drought) |
| `ota/dev/3c9ee9f7b6b9d4c986dc31902bc243aeac15a93e` | `3c9ee9f7b6b9d4c986dc31902bc243aeac15a93e` | 2026-10-08 | 254 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | test_repulse_hud: sample cooldown values away from whole-second boundaries (a 30 Hz tick c |
| `ota/dev/40abff25f8c24c200b68c6a37f21c0b94c1f97c8` | `40abff25f8c24c200b68c6a37f21c0b94c1f97c8` | 2026-10-11 | 263 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | ota_build_payload: list the payload to a file before 'head' (a listing over 60 entries kil |
| `ota/dev/66b884d7e7649c6c146544600f09a6d6c1d034a3` | `66b884d7e7649c6c146544600f09a6d6c1d034a3` | 2026-10-06 | 215 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | Props: furniture-group pieces are checked against walls like wall furniture |
| `ota/dev/6dd77bea6c73b5c677b0e6f7d0144ee7e72cd567` | `6dd77bea6c73b5c677b0e6f7d0144ee7e72cd567` | 2026-10-06 | 181 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | tests: generation 'exhaust' case no longer depends on one seed's layout (minimum fill abov |
| `ota/dev/9712819ec53c57211f0ca1fa42e76570b73d1427` | `9712819ec53c57211f0ca1fa42e76570b73d1427` | 2026-10-08 | 249 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | v8.2: starting health Barbarian 150 -> 200, Mage 100 -> 135 (health only; no other balance |
| `ota/dev/a8de90b442161c86d127e5857e94050534d7c911` | `a8de90b442161c86d127e5857e94050534d7c911` | 2026-10-11 | 264 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | Footsteps use the project's own single footstep; enemies stand down when the player is dea |
| `ota/dev/a9099a40c0dec8fd65ea5b2ca18c0019e6d62500` | `a9099a40c0dec8fd65ea5b2ca18c0019e6d62500` | 2026-10-11 | 267 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | test_physics_queries: pick the test spot clear both ways and re-verify after settling |
| `ota/dev/ae7e4badfcbff35344a6db24930dc80debf01030` | `ae7e4badfcbff35344a6db24930dc80debf01030` | 2026-10-11 | 262 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | tests: track juice_shots.gd.uid |
| `ota/dev/e6fd6ec7df88e1d7ae14e95df2356241ee1e9406` | `e6fd6ec7df88e1d7ae14e95df2356241ee1e9406` | 2026-10-08 | 255 / 2 | OTA channel/line | contained in `ccr-5f32885a-gvu16v` | test_enemy_pooling: a reborn enemy already in attack range may begin its own attack (own s |
| `post-v7-2-round` | `f2328f108205e65b487e43f5d37f42c175ec2e97` | 2026-10-07 | 244 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | docs/.gdignore: Godot must not import or export anything under docs/ (the icon preview PNG |
| `promote/v1/37143051773/073e34b9f2976f2336aedb6311bd2da33282eb17/notlatest` | `18e331afdf52319f79f00d01fbe1be09fac206c6` | 2026-10-04 | 25 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Release workflow: promote via helper branch; authenticated tag-exists check |
| `promote/v2/37152299390/ef24eb4cf184dbc61f0d11f7d8b81aca2ab1a88c` | `04e1684d41ec04482f666babd44e9ab4000bc784` | 2026-10-04 | 26 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | publish_release.sh: report Latest via the API (gh has no isLatest field) |
| `purgatory-stabilization-round2` | `18d82faa33ee5d75e525ed484e0a48976cd69278` | 2026-10-05 | 31 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Add the canonical Hot Attic Games logo to the v3 candidate |
| `release/v3` | `18d82faa33ee5d75e525ed484e0a48976cd69278` | 2026-10-05 | 31 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | Add the canonical Hot Attic Games logo to the v3 candidate |
| `release/v4` | `53e92ab588246f33827ad9bdd7e5fe77236ee791` | 2026-10-05 | 48 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | test_app_lifecycle: do not assume slot 0 is empty (shared scratch in the full suite) |
| `release/v5` | `7b5112bffdbaa9e1fd79d4a7ca0903ae411245d4` | 2026-10-05 | 78 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v5 release commit (version metadata only) |
| `release/v6` | `a9168e16ceac23b0dbb00d3f34f12ff3be070901` | 2026-10-05 | 115 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v6 release commit (version metadata only) |
| `release/v7` | `af11f45d22211cb1d84686bd9540a5045e6d41b2` | 2026-10-06 | 169 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v7 release commit (version 7, runtime relock, release history) |
| `release/v8` | `f2328f108205e65b487e43f5d37f42c175ec2e97` | 2026-10-07 | 244 / 2 | release-related | contained in `ccr-5f32885a-gvu16v` | docs/.gdignore: Godot must not import or export anything under docs/ (the icon preview PNG |
| `ui-brand` | `7b5112bffdbaa9e1fd79d4a7ca0903ae411245d4` | 2026-10-05 | 78 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v5 release commit (version metadata only) |
| `v7-1-ota` | `479457bac70d7d5f5589f445707c68ecc3127365` | 2026-10-06 | 182 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | docs: OTA evidence after the first real publication (v7.1, ota-dev-000001) |
| `v7-2-ota` | `66b884d7e7649c6c146544600f09a6d6c1d034a3` | 2026-10-06 | 215 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Props: furniture-group pieces are checked against walls like wall furniture |
| `v7-ota` | `af11f45d22211cb1d84686bd9540a5045e6d41b2` | 2026-10-06 | 169 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | Purgatory Dungeon v7 release commit (version 7, runtime relock, release history) |
| `v8-1-ota` | `e6fd6ec7df88e1d7ae14e95df2356241ee1e9406` | 2026-10-08 | 255 / 2 | unknown | contained in `ccr-5f32885a-gvu16v` | test_enemy_pooling: a reborn enemy already in attack range may begin its own attack (own s |

Pull-request refs on the remote: #1, #2, #3, #4, #5, #6, #7, #8, #9, #10 (refs only; PR state not read).

## Tags and releases

Release details could not be read (the GitHub API refused: repository outside this session's scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.

| Tag | Commit | Commit date | Release | Commit subject |
|---|---|---|---|---|
| `ota-dev-000007` | `a9099a40c0dec8fd65ea5b2ca18c0019e6d62500` | 2026-10-11 | unknown | test_physics_queries: pick the test spot clear both ways and re-verify |
| `ota-dev-000006` | `40abff25f8c24c200b68c6a37f21c0b94c1f97c8` | 2026-10-11 | unknown | ota_build_payload: list the payload to a file before 'head' (a listing |
| `ota-dev-000005` | `e6fd6ec7df88e1d7ae14e95df2356241ee1e9406` | 2026-10-08 | unknown | test_enemy_pooling: a reborn enemy already in attack range may begin i |
| `ota-dev-000004` | `9712819ec53c57211f0ca1fa42e76570b73d1427` | 2026-10-08 | unknown | v8.2: starting health Barbarian 150 -> 200, Mage 100 -> 135 (health on |
| `ota-dev-000003` | `0f3dc9ad1a939052ff06de27c05c233e0fd09b56` | 2026-10-07 | unknown | Run the floor-mesh repairs before the worker-thread prop loads start ( |
| `v8` | `f2328f108205e65b487e43f5d37f42c175ec2e97` | 2026-10-07 | unknown | docs/.gdignore: Godot must not import or export anything under docs/ ( |
| `ota-dev-000002` | `66b884d7e7649c6c146544600f09a6d6c1d034a3` | 2026-10-06 | unknown | Props: furniture-group pieces are checked against walls like wall furn |
| `ota-dev-000001` | `6dd77bea6c73b5c677b0e6f7d0144ee7e72cd567` | 2026-10-06 | unknown | tests: generation 'exhaust' case no longer depends on one seed's layou |
| `v7` | `af11f45d22211cb1d84686bd9540a5045e6d41b2` | 2026-10-06 | unknown | Purgatory Dungeon v7 release commit (version 7, runtime relock, releas |
| `v6` | `a9168e16ceac23b0dbb00d3f34f12ff3be070901` | 2026-10-05 | unknown | Purgatory Dungeon v6 release commit (version metadata only) |
| `v5` | `7b5112bffdbaa9e1fd79d4a7ca0903ae411245d4` | 2026-10-05 | unknown | Purgatory Dungeon v5 release commit (version metadata only) |
| `ota-channel-dev` | `f0eaa471c85d8b76fb68b35a37efba485a054364` | 2026-10-05 | unknown | Add files via upload |
| `v4` | `53e92ab588246f33827ad9bdd7e5fe77236ee791` | 2026-10-05 | unknown | test_app_lifecycle: do not assume slot 0 is empty (shared scratch in t |
| `v3` | `18d82faa33ee5d75e525ed484e0a48976cd69278` | 2026-10-05 | unknown | Add the canonical Hot Attic Games logo to the v3 candidate |
| `v2` | `ef24eb4cf184dbc61f0d11f7d8b81aca2ab1a88c` | 2026-10-03 | unknown | Docs: round-2 findings, dispositions and test coverage |
| `v1` | `073e34b9f2976f2336aedb6311bd2da33282eb17` | 2026-10-03 | unknown | CI: record the real head commit SHA in build info and artifact name |

## Asset manifests and licence records

- `addons/kenney_particle_pack/LICENSE.txt`
- `addons/kenney_ui_audio/LICENSE.txt`
- `data/addons_manifest.json`
- `docs/THIRD_PARTY_ASSETS.md`
- `scripts/ota/ota_manifest.gd`
- `scripts/ota/ota_manifest.gd.uid`
- `tests/test_licenses.py`
- `tools/ota_make_manifest.gd`
- `tools/ota_make_manifest.gd.uid`

## Important artwork

Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head (360 distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.

| Path | Size (px) | Bytes | Blob | Seen on | Link |
|---|---|---|---|---|---|
| `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` | 1536x1024 | 2838266 | `e11f8c576652` | `ccr-5f32885a-gvu16v` +30 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png) |
| `Music & background images/VPP_logo_from_source_256.ico` | 256x256 | 93315 | `4115e96336d3` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/VPP_logo_from_source_256.ico) |
| `Music & background images/background menu image.png` | 1081x566 | 505323 | `ce1e66ab6b42` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/background%20menu%20image.png) |
| `Music & background images/jumpsc.png` | 684x683 | 295984 | `e8c27f86106d` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/jumpsc.png) |
| `Music & background images/logo_vpp.png` | 565x536 | 295988 | `f14aa4d40d95` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/logo_vpp.png) |
| `Music & background images/parchment.jpeg` | 600x376 | 47812 | `2e9eb9fa65b7` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/parchment.jpeg) |
| `Music & background images/unused_media/night_sky_with_beautiful_twinkling_stars.png` | 8192x4096 | 20058483 | `933513d46f0e` | `ccr-5f32885a-gvu16v` | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/Music%20&%20background%20images/unused_media/night_sky_with_beautiful_twinkling_stars.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_AnotherPlanet_Equirect.png` | 8192x4096 | 18123713 | `6f37903fa7bf` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_AnotherPlanet_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_CartoonNightSky_Equirect.png` | 4096x2048 | 3064352 | `963576bfbb3a` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_CartoonNightSky_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ClearBlueSky_Equirect.png` | 4096x2048 | 4063261 | `f11d17528cae` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ClearBlueSky_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ColdNight_Equirect.png` | 16384x8192 | 43417291 | `8f13e57a1cb1` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ColdNight_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ColdSunset_Equirect.png` | 16384x8192 | 79869056 | `80f91f0cd792` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_ColdSunset_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_DeepDusk_Equirect.png` | 16384x8192 | 50754568 | `59f4315f793c` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_DeepDusk_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_EpicBlueSunset_Equirect.png` | 8192x4096 | 19472329 | `f8044081b5af` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_EpicBlueSunset_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_EpicGloriousPink_Equirect.png` | 8192x4096 | 23641400 | `492371f73c19` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_EpicGloriousPink_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_MoonBurst_Equirect.png` | 8192x4096 | 13408490 | `476213bf4a09` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_MoonBurst_Equirect.png) |
| `addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_OvercastLow_Equirect.png` | 4096x2048 | 800607 | `0dddacac6384` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/AllSkyFree/Skyboxes/AllSkyFree_Sky_OvercastLow_Equirect.png) |
| `addons/kenney_particle_pack/circle_01.png` | 512x512 | 66234 | `fe1acd041700` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/circle_01.png) |
| `addons/kenney_particle_pack/circle_02.png` | 512x512 | 41442 | `84df6aaf34cc` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/circle_02.png) |
| `addons/kenney_particle_pack/circle_03.png` | 512x512 | 69716 | `630df9f75e92` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/circle_03.png) |
| `addons/kenney_particle_pack/circle_04.png` | 512x512 | 56681 | `7da3ee576e07` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/circle_04.png) |
| `addons/kenney_particle_pack/circle_05.png` | 512x512 | 59553 | `3c30a1179ff7` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/circle_05.png) |
| `addons/kenney_particle_pack/dirt_01.png` | 512x512 | 46129 | `3bf82433236c` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/dirt_01.png) |
| `addons/kenney_particle_pack/dirt_02.png` | 512x512 | 52813 | `6904c5105004` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/dirt_02.png) |
| `addons/kenney_particle_pack/dirt_03.png` | 512x512 | 112585 | `d1a011406b0c` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/dirt_03.png) |
| `addons/kenney_particle_pack/fire_01.png` | 512x512 | 95429 | `f5c92195d12d` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/fire_01.png) |
| `addons/kenney_particle_pack/fire_02.png` | 512x512 | 84307 | `f29157180fcc` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/fire_02.png) |
| `addons/kenney_particle_pack/flame_01.png` | 512x512 | 51191 | `edd700faa85b` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_01.png) |
| `addons/kenney_particle_pack/flame_02.png` | 512x512 | 64804 | `73f2054b1792` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_02.png) |
| `addons/kenney_particle_pack/flame_03.png` | 512x512 | 47727 | `b4fd776e25d9` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_03.png) |
| `addons/kenney_particle_pack/flame_04.png` | 512x512 | 67316 | `d07221b59d74` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_04.png) |
| `addons/kenney_particle_pack/flame_05.png` | 512x512 | 12625 | `99d6d2d3e0f1` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_05.png) |
| `addons/kenney_particle_pack/flame_06.png` | 512x512 | 15133 | `a0fedd3e50a1` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flame_06.png) |
| `addons/kenney_particle_pack/flare_01.png` | 512x512 | 39143 | `bd25bd874e47` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/flare_01.png) |
| `addons/kenney_particle_pack/light_01.png` | 512x512 | 86592 | `0192157986a9` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/light_01.png) |
| `addons/kenney_particle_pack/light_02.png` | 512x512 | 87708 | `30fbdb4c7ad1` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/light_02.png) |
| `addons/kenney_particle_pack/light_03.png` | 512x512 | 94243 | `ccd8472c9416` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/light_03.png) |
| `addons/kenney_particle_pack/magic_01.png` | 512x512 | 77122 | `e7e80ab95a1b` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/magic_01.png) |
| `addons/kenney_particle_pack/magic_02.png` | 512x512 | 82611 | `7623d49ea850` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/magic_02.png) |
| `addons/kenney_particle_pack/magic_03.png` | 512x512 | 55275 | `47c4a22ff7b1` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/magic_03.png) |
| `addons/kenney_particle_pack/magic_04.png` | 512x512 | 46627 | `84d42b0081f8` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/magic_04.png) |
| `addons/kenney_particle_pack/magic_05.png` | 512x512 | 69579 | `67b3582a720a` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/magic_05.png) |
| `addons/kenney_particle_pack/muzzle_01.png` | 512x512 | 77833 | `ce0324cf9025` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/muzzle_01.png) |
| `addons/kenney_particle_pack/muzzle_02.png` | 512x512 | 53879 | `379ddf2aee5b` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/muzzle_02.png) |
| `addons/kenney_particle_pack/muzzle_03.png` | 512x512 | 53994 | `b529fafdd9d0` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/muzzle_03.png) |
| `addons/kenney_particle_pack/muzzle_04.png` | 512x512 | 59586 | `80d1e38991c7` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/muzzle_04.png) |
| `addons/kenney_particle_pack/muzzle_05.png` | 512x512 | 51350 | `c3ba2108a24a` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/muzzle_05.png) |
| `addons/kenney_particle_pack/rotated/flame_05_rotated.png` | 512x512 | 11368 | `7a1fa0becb3d` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/flame_05_rotated.png) |
| `addons/kenney_particle_pack/rotated/flame_06_rotated.png` | 512x512 | 14109 | `028248e1eb1f` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/flame_06_rotated.png) |
| `addons/kenney_particle_pack/rotated/muzzle_01_rotated.png` | 512x512 | 71320 | `5b1ee838f788` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/muzzle_01_rotated.png) |
| `addons/kenney_particle_pack/rotated/muzzle_02_rotated.png` | 512x512 | 45917 | `2c47dfd11c95` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/muzzle_02_rotated.png) |
| `addons/kenney_particle_pack/rotated/muzzle_03_rotated.png` | 512x512 | 44439 | `1bdd7fdca854` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/muzzle_03_rotated.png) |
| `addons/kenney_particle_pack/rotated/muzzle_04_rotated.png` | 512x512 | 47215 | `f9184cfd3bee` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/muzzle_04_rotated.png) |
| `addons/kenney_particle_pack/rotated/muzzle_05_rotated.png` | 512x512 | 41198 | `4458f37d89fa` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/muzzle_05_rotated.png) |
| `addons/kenney_particle_pack/rotated/spark_05_rotated.png` | 512x512 | 52038 | `a759fc0d2255` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/spark_05_rotated.png) |
| `addons/kenney_particle_pack/rotated/spark_06_rotated.png` | 512x512 | 38202 | `921310002d86` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/spark_06_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_01_rotated.png` | 512x512 | 24939 | `8aa813f0d43f` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_01_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_02_rotated.png` | 512x512 | 27041 | `b0a860c41990` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_02_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_03_rotated.png` | 512x512 | 30245 | `571965aca293` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_03_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_04_rotated.png` | 512x512 | 32911 | `5cff381c7dc7` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_04_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_05_rotated.png` | 512x512 | 32814 | `ca63907b2472` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_05_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_06_rotated.png` | 512x512 | 27261 | `1898aaa9671b` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_06_rotated.png) |
| `addons/kenney_particle_pack/rotated/trace_07_rotated.png` | 512x512 | 24187 | `4549a85343c3` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/rotated/trace_07_rotated.png) |
| `addons/kenney_particle_pack/scorch_01.png` | 512x512 | 57261 | `badfa98c1d16` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/scorch_01.png) |
| `addons/kenney_particle_pack/scorch_02.png` | 512x512 | 70510 | `e0554e3f8f75` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/scorch_02.png) |
| `addons/kenney_particle_pack/scorch_03.png` | 512x512 | 87486 | `496363a87a3d` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/scorch_03.png) |
| `addons/kenney_particle_pack/scratch_01.png` | 512x512 | 61785 | `1f91e6f1f716` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/scratch_01.png) |
| `addons/kenney_particle_pack/slash_01.png` | 512x512 | 23710 | `692d653247ce` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/slash_01.png) |
| `addons/kenney_particle_pack/slash_02.png` | 512x512 | 35485 | `307bd547f392` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/slash_02.png) |
| `addons/kenney_particle_pack/slash_03.png` | 512x512 | 15675 | `31f250ab448f` | `ccr-5f32885a-gvu16v` +32 | [view](https://github.com/verbal76/Purgatory-Dungeon/blob/94408dec77c72caf68bbd6b63d9090661e99beb9/addons/kenney_particle_pack/slash_03.png) |
| ... 139 more in registry.json | | | | | |

Other art/source files (svg, psd, pdf, ...): 8; first few: `Music & background images/VPP_logo_from_source_256.svg`, `Music & background images/icon.svg`, `addons/props/SM_GeneralProps_Mat_GeneralProps_AlbedoTransparency.tga`, `addons/props/SM_GeneralProps_Mat_GeneralProps_MetallicSmoothness.tga`, `addons/props/SM_GeneralProps_Mat_GeneralProps_Normal.tga`, `addons/props/chests and keys/SM_Chests_Mat_Chests_AlbedoTransparency.tga`, `addons/props/chests and keys/SM_Chests_Mat_Chests_MetallicSmoothness.tga`, `addons/props/chests and keys/SM_Chests_Mat_Chests_Normal.tga`

## Features and layout

Top level of `ccr-5f32885a-gvu16v`:

`.editorconfig` (1), `.gitattributes` (1), `.github/` (4), `.gitignore` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png.import` (1), `Music & background images/` (120), `README.md` (1), `VERSION` (1), `addons/` (380), `android_icons/` (8), `app_icon/` (4), `archive/` (3), `assets/` (375), `autoloads/` (8), `characters/` (155), `data/` (6), `default_bus_layout.tres` (1), `docs/` (26), `dungeon modules/` (90), `export_presets.cfg` (1), `objects/` (5), `ota/` (2), `player_guard_sword0.bin` (1), `production/` (2), `project.godot` (1), `scenes/` (12), `schizophrenia_audio.gd` (1), `schizophrenia_audio.gd.uid` (1), `scripts/` (156), `tests/` (237), `tools/` (65)

Top level of default `main`: `.editorconfig` (1), `.gitattributes` (1), `.gitignore` (1), `CLAUDE.md` (1), `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png` (1), `Music & background images/` (62), `README.md` (1), `a_high_resolution_game_ui_concept_art_composite_im.png` (1), `addons/` (379), `archive/` (3), `autoloads/` (8), `characters/` (155), `claude.md.txt` (1), `data/` (4), `dungeon modules/` (90), `export_presets.cfg` (1), `objects/` (5), `player_guard_sword0.bin` (1), `production/` (2), `project.godot` (1), `scenes/` (11), `schizophrenia_audio.gd` (1), `schizophrenia_audio.gd.uid` (1), `scripts/` (70)

## CI workflows

Path and trigger only; never changed or run.

| Branch:path | Name | Trigger (`on:`) |
|---|---|---|
| `ccr-5f32885a-gvu16v:.github/workflows/ci.yml` | Build (manual) | workflow_dispatch:     inputs:       platform:         description: Platform to build         type: choice         options: [android, windows, linux, all]       |
| `ccr-5f32885a-gvu16v:.github/workflows/ota-publish.yml` | OTA publish | push:     branches:       - 'ota/**' |
| `ccr-5f32885a-gvu16v:.github/workflows/ota-tests.yml` | OTA tests (reusable) | workflow_call:     inputs:       ref:         description: Full 40-hex commit SHA to test         required: true         type: string |
| `ccr-5f32885a-gvu16v:.github/workflows/tests.yml` | Tests | push:     branches: [main]   pull_request:     types: [opened, synchronize, reopened, ready_for_review]     paths-ignore: ['docs/**', '**/*.md', 'LICENSE', '.gi |

## Sensitive files (paths only; contents not read)

- none matched

## Unknowns and duplicates

Same blob under more than one path on some branch head: 9 blobs.
- `49c0cd55cd65`: `dungeon modules/2 section hallway each side of 90_colormap.png`, `dungeon modules/2 section hallway straight_colormap.png`, `dungeon modules/New_room_closer_flush_colormap.png`, `dungeon modules/hall end_colormap.png` (+13)
- `74cf120000a9`: `Music & background images/[Simulation] Andromeda galaxy colliding with the Milky Way.mp4`, `Music & background images/unused_media/[Simulation] Andromeda galaxy colliding with the Milky Way.mp4`
- `ce1e66ab6b42`: `Music & background images/background menu image.png`, `dungeon modules/temp_menu_screen_background.png`
- `933513d46f0e`: `Music & background images/night_sky_with_beautiful_twinkling_stars.png`, `Music & background images/unused_media/night_sky_with_beautiful_twinkling_stars.png`
- `16dd11176a4a`: `addons/kenney_ui_audio/SM_WoodenContainerWithBottles.fbx`, `addons/props/SM_WoodenContainerWithBottles.fbx`
- `f1525da943c1`: `characters/Lutsch Mage/vampire gtlf/vampire-mage_1.png`, `characters/Lutsch Mage/vampire gtlf/vampire-mage_4.png`
- `4180ee4e52cc`: `assets/ui/glyphs/switch/l3.png`, `assets/ui/glyphs/switch/lstick.png`
- `d74c3197169e`: `assets/ui/glyphs/switch/r3.png`, `assets/ui/glyphs/switch/rstick.png`
- `894d27f351ce`: `a_high_resolution_game_ui_concept_art_composite_im.png`, `docs/art/PD_Mobile_Control_Art_Reference.png`
