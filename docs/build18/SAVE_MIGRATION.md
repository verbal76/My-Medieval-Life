# Build 18 save compatibility: a real Build 17 save (REL18-SAVE)

Checked 2026-10-23 by the lead (CLAUDE.md section 7).

1. **Written by Build 17:** the Build 17 release-candidate code (`cd7439c`, a worktree of that commit) set up seed 7, ran
   about a day and a half and wrote `World.to_dict()`: save version 17, day 1, 107 villagers.
2. **Loaded by Build 18** (`wip/build18` at `9a86f5c` with the profile load fix): `SaveStore.inspect_text` → `ok` (Build 18
   save version 19); loaded at day 1 with 107 villagers, all alive, total coins 3110, 24 deposits.
3. **Played on** two days: 105 alive, total coins 3149 (the village's ordinary trade with the five settlements and the
   caravan), 0 script errors.
4. **Re-saved** as version 19 and **reloaded**: total coins 3149 and 109 people before and after.

Every Build 18 section is optional in the save (settlements, couriers, credit, business tills, the capability profile,
wage offers): an older save reads each as empty or derives it, which the per-feature suites test with old-save fixtures
(`save_transfer_test`, `profile_test`, `settlement_development_test`, `business_works_test`, `competition_test`).

Not covered: on-device import from the Android build (the throwaway signing key means Build 18 cannot install over
Build 17: export the save, uninstall, install, import).
