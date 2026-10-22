# Baseline evidence, regional economy, 2026-10-23 (REG-INV-01)

Preserved by owner instruction (2026-10-23, `docs/directives/2026-10-23_regional_economy_decisions.md`): "Preserve the
observed economic outcomes as baseline evidence." Raw outputs, unedited. Findings: `../2026-10-23_regional_economy.md`.
Later evaluations (REG-EVAL-01) compare against these.

| File | Command | Code |
|---|---|---|
| `economy_sim_90d_seed1_36beb67.log`, `.json` | `economy_sim.gd -- --days 90 --seed 1 --every 15 --out ...` | `wip/build18` 36beb67 (chapel and settlements) |
| `regions_sim_200d_seed1_higham_36beb67.txt` | `regions_sim.gd -- --days 200 --seed 1 --every 25 --detail higham` | 36beb67, before the wage correction |
| `economy_sim_30d_seed1_7fc4426.log`, `..._seed2_...` | `economy_sim.gd -- --days 30 --seed N --every 10` | 7fc4426 (plus feasts and luxuries), before the wage correction |
