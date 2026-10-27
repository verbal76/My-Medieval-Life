# Expansion 20: execution batches

Owner authorization 2026-10-26 (`docs/directives/2026-10-26_build22_expansion20_execution_authorization.md` and the amendment
`docs/directives/2026-10-26_build22_final_owner_answers_amendment.md`): begin substantive Expansion 20 implementation as soon as Build 22's
private packages are prepared. Scope: `X20-OPEN-ITEMS` in the register (snapshot `docs/expansion20/X20_OPEN_ITEMS.md`). The register
holds every item's status; this file holds only the order of work. Base for every batch: the Build 22 release commit.

| Batch | Items | Work | Gates |
|---|---|---|---|
| X20-B0 | the 14 Build 22 items | Reconcile in the register against the Build 22 evidence so nothing is built twice | register check |
| X20-B1 | E20-P1, FIX-D1D2 (D2), RECON-01 (Expansion 20 part) | Merge the Living Economy foundation from `wip/expansion20-preparation` (`1befd0e`; reservations, event ring, actor resolver, contract-hold recognition, disabled economy section kept on save) onto the Build 22 line. A trial merge onto `6567c04` (2026-10-26) touched 12 files, about 960 lines, with two mechanical conflicts in `world.gd` (keep both sides). Stays disabled (`economy.json enabled false`) | economy_foundation_test, run_tests, start_test, save round trip of a Build 21/22 save with and without an economy section, G0 identical, conservation |
| X20-B2 | GP-ANDROID-RECENTER, GP-ANDROID-HUD-SCALE, GP-ANDROID-ACTION-BUTTONS, GP-ANDROID-USE-TALK-TARGETING, GP-INTERACTABLE-OUTLINES, GP-INTERACTION-PROMPT-LIFECYCLE | Android usability and interaction targeting, presentation and input only | targeted tests, screenshots looked at, G0 identical; device checks outstanding |
| X20-B3 | LE-01 | The shared actor, need, offer, knowledge and contract model on the foundation, behind the disabled switch, per `docs/expansion20/LE01_DATA_CONTRACTS.md` (on `wip/expansion20-preparation`); no formula or policy chosen | conservation, determinism, persistence; G0 identical with the switch off |
| X20-B4 | Build 19 carry-forward (`X20_OPEN_ITEMS.md` section 4a) | First establish what Build 19 actually enables (the release notes say Expansion 19 is complete and on; the register says the SJD-F..H rollout gates are not started), then implement only what is genuinely missing, without redesigning judgment or reputation | per item |
| X20-MP (last; **release blocker**) | MP-INTERACT-01 | Player-to-player selection and interaction, host and guest, Windows, Linux and Android, keyboard and mouse, touch and controller, on the frozen integrated baseline; existing network, consent and transaction systems only (`docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md`) | multiplayer suites driving the real interaction interface, combined regression, G0, three exports; owner-device combinations listed. **No Expansion 20 build, private included, without it** |
| Owner-held | LE-02 to LE-07 policy, OD-LE-02 .. OD-LE-15 | Each needs an owner policy or number (market form, wages and rents, lending, manor interventions, and so on). Presented as specific questions; never guessed. Technical work around them continues | the owner's answers |
| Device | items integrated but awaiting a phone, controller or PC check | recorded in each item's `playtest`; never marked verified without the device | owner playtest |

Workers only where the tasks are independent; the lead integrates on one branch and keeps the register and
`docs/CURRENT_DEVELOPMENT_STATE.md` current.
