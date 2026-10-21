# Build 17 save compatibility: a real Build 16 save

Checked 2026-10-21 by the lead (CLAUDE.md section 7; audit item "real Build 16 save → Build 17").

1. **Written by Build 16:** the released Build 16 code (`b3bbb1c`, a worktree of that commit) set up seed 7, ran two game
   days and wrote `World.to_dict()`: save version 16, day 4, 107 villagers, 3450 coins, 15 deposits.
2. **Loaded by Build 17** (`wip/build17` at `e9a01e4`, with CON-02): `SaveStore.inspect_text` → `ok`; loaded at day 4 with
   107 villagers and 3450 coins (unchanged); 21 deposits (the save comment's default: the adit gallery's 6 seams added
   full); mining capability level 1; 11 prospecting clues placed from the seed; no contracts, pits or finds.
3. **Played on** two days: day 8, 102 alive, 4419 coins (the caravan's ordinary inflow; the determinism gate's fresh
   worlds follow the same course), 0 script errors.
4. **Re-saved** as version 17 and **reloaded**: 4419 coins and 21 deposits before and after.

Not covered: a save from a player who had used Build 16's farmland, stalls and guardianship heavily (the Build 16 tests
cover those keys' round trips); on-device import from the Android build (the APK's throwaway key means Build 17 cannot
install over Build 16: export the save, uninstall, install, import).
