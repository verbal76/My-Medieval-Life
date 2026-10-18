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
| [Climb-Up](repos/Climb-Up.md) | Upwardly (working title "Climb up") | public | `main` @ `91597f1f392b` | 2026-10-15 | libGDX 1.14.2 (Java/Gradle): Android, Windows, Linux/Steam Deck | active | `ccr-cb458cd1-w4dh5c` |
| [Tartaria-RPG](repos/Tartaria-RPG.md) | Tartaria Realms | public | `main` @ `487de55121cd` | 2026-10-17 | Expo / React Native, TypeScript | active | `golem-line` |
| [Game-Designer](repos/Game-Designer.md) | Game Designer | public | `main` @ `b28ff434aaa0` | 2026-10-17 | Kotlin / Gradle (Android) | active | unresolved |
| [808-Beats](repos/808-Beats.md) | (not recorded) | private | not read | | | not scanned (owner rule) | |

Not yet scanned in this registry version: Fix-Tremors, Backrooms-Survivor, Axolotl, Ocean-spore, Purgatory-Dungeon, Ragdoll-Rally, Endless-Escaspe, Idle-game, My-Personal-Crossow0rd, Zombie-squisher, voiceforge, LLM-Trainer, Cfm-calculator, spiroglyphics, personal-assistant-, Manual-J, web_auditor, HotAtticGames.github.io
