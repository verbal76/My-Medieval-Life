# Trees

Every tree in the game is a Living Forest lifecycle tree (see `docs/DECISIONS.md`, 2026-10-18). The model is
`game/scripts/core/trees.gd` (stages, lazy growth), the rules are in `World` (felling, planting, saves) and
`Overworld` (generated trees, changed trees), the drawing is `game/scripts/view/tree_view.gd`. The art is
imported from the private Living Forest package by `tools/living_forest.py` into `game/assets/trees/`.

Stages: sapling, young, growing, mature (state `grown`), then a stump after felling. Provisional numbers are in
`game/data/balance.json` under `tree_growth` (stage lengths in game days, blows to fell, sapling chance, heal time).

## Development-only growth speed-up

`--tree-growth N` after the `--` on the command line makes every growth stage and the stump's regrowth N times
faster (for example `godot --path game -- --tree-growth 200`). It is honoured only when `OS.is_debug_build()` is
true, so a release export ignores it; tests set `Trees.growth_speed` directly.
