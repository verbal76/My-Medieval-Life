# Simulation baseline changes: B25R1 presence by view (B25R1-019, B25R1-020)

Branch `wip/b25r1-presence`. SIM-GATE-01 evidence note. The baseline (`docs/release/sim_baseline.json`) is NOT re-recorded on
this branch. The lead re-records it once, on the integrated B25R1 candidate, because the region, water, homestead and
settlement branches change it too (MSW-01).

## Gate run

- **Run:** the sim gate, gate-only mode, on `47cea96` (`a970731` plus the lead's two workflow commits, branch
  `wip/b25r1-presence-ci`).
- **Blocking checks, all clean:** no leaks, no script errors, no FATAL lines. Determinism was identical between the recorded
  and unrecorded runs, with both the shipped switches and the X20 switch set.
- **Baseline comparison:** 27 differences from the accepted baseline, in `eq_s1`, seeds 1 and 2, at days 10 and 30.
  Examples:
  - currency 3314 → 3187 at day 10;
  - alive 112 → 111 at day 30.

## Why the outcomes change (expected, not defects)

1. **Animals move everywhere, on the world's tick.**
   - Before, only animals within 34 tiles of a player strolled, fled and chased (`Fauna._move`), and a hungry hunter chased
     the nearest prey only near the player.
   - Now every animal moves, using its own random stream (`Fauna.move_rng`), and hunters chase the nearest prey everywhere.
   - Dispersing young reach their settling point through `_move`.
   - This removes an observation effect: where game was found used to depend on where the player stood. It also changes
     hunting, and through it food, coins and lives.
2. **The judgment gossip runs per tick, not per frame.** Headless runs already ticked at 0.5 s, so this changes nothing
   there. It matters in the live game.
3. **Crowd management (B25R1-020)** was active in headless runs on `a970731`, round the inert stand-in player. From the
   next commit it runs only when a screen reports a view (`economy_sim --view-sweep`, or the game itself). The gate's
   differences on the integrated candidate will therefore come from (1) alone.

## Evidence

- `game/tests/presence_test.gd` (37 checks):
  - the same seed with the view parked or sweeping gives identical villagers, coins, random numbers and animals;
  - a traveller met on the road ends its errand as its unwatched twin does.
- The 60-day runs on Actions (lead):
  - `--no-crowd`: 0 leaks, alive 104 → 130, food 3 → 8 days;
  - `--view-sweep`: the crowd exception measured on its own.
- The 240-day measurement run (SIM-01): seed 1, every 40 days. Its outcome is compared with the earlier full-simulation
  numbers as an outcome, not a threshold (WDR-022).
