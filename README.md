# Hot Attic Games repository registry

A read-only inventory of every repository owned by GitHub user `verbal76` (Hot Attic Games). It lives on the orphan branch `inventory/registry` of `verbal76/My-Medieval-Life` and contains no game files. Nothing in any repository was changed to build it.

## How to use it

- This table: one line per repository. `repos/<repo>.md`: purpose, branches, tags/releases, manifests, artwork, layout, CI, sensitive paths (names only), duplicates.
- `assets.md`: cross-repo artwork index (Upwardly Steam art first). `releases.md`: releases and their source commits. `findings.md`: duplicates, stale branches, conflicting sources of truth, consolidation proposals.
- `registry.json` (`hag-registry/1`): machine-readable; every entry has repo, branch, path, SHA and scan date.

## Legend

- **Branch head SHA**: where a moving branch pointed at scan time; re-check with `git ls-remote` before relying on it. **Tag commit**: immutable unless the tag is moved.
- **Authoritative**: only when the repo's own records say so (README, CLAUDE.md, ledger, manifest); otherwise **unresolved**.
- **Status**: active = a commit on any branch within 14 days of the scan; dormant = older; unknown = not scanned.
- **Visibility**: as given by the owner; "not stated" repos were read through the session git proxy, which may carry credentials, so they may be private.

## Scans

All scans on 2026-10-18 (UTC). Per-repo timestamps are in each `repos/*.md` and in `registry.json`.

## Repositories

| Repository | Product | Visibility | Default branch @ head (moving) | Last commit | Engine / language | Status | Authoritative line (per records) |
|---|---|---|---|---|---|---|---|
| [My-Medieval-Life](repos/My-Medieval-Life.md) | My Medieval Life | public | `main` @ `1031a2e3fef2` | 2026-10-18 | Godot 4.7 (game/), Python 3 tooling (tools/) | active | `staging/my-medieval-life` |
| [Climb-Up](repos/Climb-Up.md) | Upwardly (working title "Climb up") | not stated (read through the session git proxy; may be private) | `main` @ `91597f1f392b` | 2026-10-15 | libGDX 1.14.2 (Java/Gradle): Android, Windows, Linux/Steam Deck | active | `ccr-cb458cd1-w4dh5c` |
| [Tartaria-RPG](repos/Tartaria-RPG.md) | Tartaria Realms | public | `main` @ `487de55121cd` | 2026-10-17 | Expo / React Native, TypeScript | active | `golem-line` |
| [Game-Designer](repos/Game-Designer.md) | Game Designer | public | `main` @ `b28ff434aaa0` | 2026-10-17 | Kotlin / Gradle (Android) | active | unresolved |
| [808-Beats](repos/808-Beats.md) | (not recorded) | private | not read | | | not scanned (owner rule) | |
| [Fix-Tremors](repos/Fix-Tremors.md) | Fix-Tremors | not stated (read through the session git proxy; may be private) | `main` @ `5ae585bf69d0` | 2026-10-17 | Windows batch / config patch for an Unreal Engine 4.23 game | active | unresolved |
| [Backrooms-Survivor](repos/Backrooms-Survivor.md) | Backrooms Survivor | not stated (read through the session git proxy; may be private) | `main` @ `e33d7d94dda3` | 2026-10-15 | Godot 4.3 (godot/); legacy LÖVE2D Lua reference in the root | active | `dev` |
| [Axolotl](repos/Axolotl.md) | Mote | not stated (read through the session git proxy; may be private) | `main` @ `f3779f7c7f6e` | 2026-10-14 | Godot (project.godot), Android + iPhone | active | unresolved |
| [Ocean-spore](repos/Ocean-spore.md) | Ocean Spore | not stated (read through the session git proxy; may be private) | `main` @ `4e1c3774237c` | 2026-10-13 | Expo SDK 54 / React Native 0.81, three.js | active | unresolved |
| [Purgatory-Dungeon](repos/Purgatory-Dungeon.md) | Purgatory Dungeon | not stated (read through the session git proxy; may be private) | `main` @ `f0eaa471c85d` | 2026-10-13 | Godot 4.6, GDScript (Forward Plus, Jolt) | active | `ccr-5f32885a-gvu16v` |
| [Ragdoll-Rally](repos/Ragdoll-Rally.md) | Ragdoll Rally Launch | not stated (read through the session git proxy; may be private) | `main` @ `41f5f5a8667b` | 2026-10-12 | Godot 4.7.1 (launch/) | active | `claude/launch-gameplay-pivot` |
| [Endless-Escaspe](repos/Endless-Escaspe.md) | Endless Escape | not stated (read through the session git proxy; may be private) | `main` @ `84f6b740b8ac` | 2026-10-12 | Expo / React Native, TypeScript | active | unresolved |
| [Idle-game](repos/Idle-game.md) | Where's the Bottom? (formerly "Boarder") | not stated (read through the session git proxy; may be private) | `main` @ `968e195d5dac` | 2026-10-12 | Babylon.js + TypeScript inside an Expo WebView shell; EAS Update OTA | active | `claude/repo-gameplay-review-loq9rq` |
| [My-Personal-Crossow0rd](repos/My-Personal-Crossow0rd.md) | My Personal Crossword | not stated (read through the session git proxy; may be private) | `main` @ `f7775d606c15` | 2026-10-12 | Kotlin / Gradle Android, plus a desktop (Windows/Linux/Steam Deck) front end | active | `claude/native-stack-modernization` |
| [Zombie-squisher](repos/Zombie-squisher.md) | Zombie Squisher / Zombie Crusher (name is an open owner decision) | not stated (read through the session git proxy; may be private) | `main` @ `2f8dac01d9e4` | 2026-10-12 | Expo SDK 54 / React Native 0.81, three.js (react-three-fiber) | active | `ccr-27903f19-fy49jb` |
| [voiceforge](repos/voiceforge.md) | Voice Forge | private | `main` @ `5e0b01d474a3` | 2026-10-11 | Expo / React Native, TypeScript (plus trainer/) | active | unresolved |
| [LLM-Trainer](repos/LLM-Trainer.md) | LLM Trainer | not stated (read through the session git proxy; may be private) | `main` @ `f05d9bbc6900` | 2026-10-06 | Python factory core + Kotlin/Gradle Android app | active | unresolved |
| [Cfm-calculator](repos/Cfm-calculator.md) | Verbal's CFM Calculator | not stated (read through the session git proxy; may be private) | `main` @ `05abc05c5329` | 2026-10-06 | Capacitor 8 / Android API 36, TypeScript + Vite | active | unresolved |
| [spiroglyphics](repos/spiroglyphics.md) | Spiroglyphics | private | `main` @ `aa133ddd4534` | 2026-10-06 | Expo / React Native, TypeScript | active | unresolved |
| [personal-assistant-](repos/personal-assistant-.md) | Personal Assistant | private | `main` @ `d76315144df7` | 2026-10-06 | Expo / React Native, TypeScript | active | unresolved |
| [Manual-J](repos/Manual-J.md) | Manual J | not stated (read through the session git proxy; may be private) | `main` @ `2df7d7596637` | 2026-10-06 | Capacitor / TypeScript + Vite | active | unresolved |
| [web_auditor](repos/web_auditor.md) | Website Auditor | private | `main` @ `2e9d4a9fd304` | 2026-10-04 | Python (PyInstaller spec, build.bat) | active | unresolved |
| [HotAtticGames.github.io](repos/HotAtticGames.github.io.md) | Hot Attic Games studio site | public | `main` @ `6ac9ef8e8032` | 2026-04-26 | GitHub Pages (README only) | dormant | unresolved |
