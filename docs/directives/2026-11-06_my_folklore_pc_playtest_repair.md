# Owner directive, 2026-11-06: My Folklore — PC playtest repair release ("Play Test Build One")

Saved condensed (every instruction kept). Repository verbal76/My-Medieval-Life; new working title My Folklore; release name exactly
"Play Test Build One"; Windows PC only; private household playtesting; scope: five playtest defects, no expansions. An explicit
exception to the expansion freeze.

1. Baseline: inspect release history, version constants, build records, latest Windows package; most recent packaged build and its
   revision, its source commit, the integration/freeze-line commit, newer uncommitted/unmerged/unvalidated work. Keep the build number,
   increment the revision; never invent a new major build number. Public name exactly "Play Test Build One"; internal version and SHA
   recorded separately. Keep the repository name; My Folklore is the working title, no unrelated mass rename or save-path migration.
2. Riverbank autotravel: a long journey drove into a riverbank and stuck; manual steering round it let autotravel resume. Investigate
   world-map routing, water collision, bridges and fords, traversability graphs, local steering, recalculation, stuck detection, manual
   to automatic handoff. Required: find a valid reachable crossing, preferring one in the direction of travel by route distance and
   traversability; route to it, cross, resume; never push repeatedly against a bank; detect an unreachable crossing and replan; with no
   legal route stop safely and say why; deterministic simulation and save compatibility kept. Check whether map and movement disagree
   about crossings.
3. Long-distance stutter: repeated microfreezes far from the starting village. Do not assume terrain streaming. Instrument frame times
   and spikes, region transitions, terrain generation, world-map updates, NPC/settlement simulation, pathfinding, allocation, saves,
   rendering/resource loading, work that scales with distance. Reproduce a fixed-seed repeatable journey; record spikes with times and
   coordinates and correlate. Find the cause first; measured fix without removing features or changing rules; before/after spike
   counts and worst frames.
4. Resume Travel and Cancel Travel: not selectable with an Xbox controller. Both in focus navigation, visible focus highlight, A
   activates, B back/cancel consistent, usable when paused/resumed/interrupted/cancelled, mouse kept, focus never lost on state change.
   Automated regression tests.
5. Whole game playable by controller: audit existing bindings first (D-pad Up/Down shortcuts exist; Left/Right unused). Xbox model:
   stick/D-pad focus, A confirm, B back, LB/RB tabs/panels, D-pad Left/Right between controls/tabs in menu mode, analog stick for map
   movement/scrolling; context-sensitive mappings in menus allowed; do not overwrite shortcuts blindly; explicit input contexts
   (gameplay, map, menus, modal dialogs). Every interactive control reachable and operable without a mouse: main menu, pause menu,
   world map, destination selection, travel controls, journal, inventory, character, settlement and business UIs, dialogs and
   confirmations, save/load, others. Visible focus, logical order, focus restored on open/close. Controller-only automated navigation
   tests, then a Windows gamepad smoke test.
6. Looping bridge geometry: about eight bridge sections looping back to the same bank. Investigate placement rules, endpoints,
   orientation, chaining, road connections, crossing validity, navigation connectivity, determinism. Required: crossings connect valid
   traversable endpoints, coherent segments, no circular chains, navigation matches geometry, manual and automatic travel can cross.
   Test several seeds and difficult banks; record generator changes and their impact on determinism and saves.
7. Discipline: issues may share causes (2 and 6); reproduce or a failing test, cause, evidence, smallest complete fix, regression
   coverage, verify, record uncertainty. Never weaken tests or disable systems.
8. Freeze line: no new economy, settlements, professions, multiplayer, storyline, mechanics, or unrelated UI redesign. Preserve work
   and branches. No new agent unless genuinely required and budget permits.
9. Testing and release: focused tests, then full Windows regression after integrating all five: river navigation, stuck detection and
   replanning, bridge validity, long-travel performance, controller accessibility, travel buttons, save/load, deterministic generation,
   simulation behaviour. GitHub Actions as primary evidence. One Windows package only (no Android, Linux, demos). One GitHub release
   "Play Test Build One" with the package, source SHA, internal build and revision, SHA-256, short notes on the five repairs, known
   issues; published package verified equal to the tested artifact; not on Steam or any storefront.
10. Update status, decision and recovery docs; Eastern Time; counts not percentages; final report: baseline build and revision, final
   internal version, source commit, the five defects (fixed/unresolved/blocked), test counts, performance before/after, Actions run
   ids, package size and checksum, release link.

## Owner answers, 2026-11-06 (session questions)

- Baseline: no preference (agent recommendation taken: F2 `20e579e`, internal Build 25 Revision 2, B25R2).
- Title: no preference (recommendation: My Folklore in the release notes only; game window, files and save folder unchanged).
- Visibility: no preference (recommendation: a public GitHub release like build-34; no storefront).
- Workers: **serial, no extra agents.**
