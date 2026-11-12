# Save numeric tolerance (ND-15, B25-ND15-TOL-01)

Owner decision 2026-11-10 (`docs/directives/2026-11-10_build25_merge_decisions.md`, item 2): "Minor floating-point differences
after save/load are acceptable only when proven harmless to gameplay, inventory, money, contracts, deterministic outcomes, and
subsequent simulation behavior. Establish and document numerical tolerances. Exact values must remain exact wherever required for
correctness."

## The behaviour

The game saves with `JSON.stringify(d, "", true, true)` (full precision, `main.gd`). Godot's JSON does not round-trip every double
exactly: a few fractional values come back one unit in the last place (ulp) off. Measured on a 3-day seed 1 world: 162 of about
122,000 values in the save, the largest relative difference 2.2e-16 (for example villager 101's hunger 91.1000000000051 saved,
91.100000000005 loaded; a relationship's 0.9999999999999999 loaded as 1.0).

## Tolerances

| Class | Examples | Rule |
|---|---|---|
| Whole numbers (int, or a whole-valued float) | coins, item counts, prices, amounts, ids, days, contract terms, household members, treasury | exact |
| Text and true/false | jobs, names, item ids, flags, the random stream state | exact |
| Fractional values | hunger, stamina, positions, timers, relationship strengths, partial progress | relative difference at most 1e-12 (about 4,500 ulp; observed 1 to 2 ulp) |

A value is judged by what was saved: if the saved value is whole, the loaded one must equal it exactly.

## Proof of harmlessness (`game/tests/save_tolerance_test.gd`)

1. The game's JSON of a 3-day world keeps every whole number, text and flag exactly and every fraction within the tolerance.
2. The world loaded from that JSON holds what a world loaded from an exact binary copy holds, under the same rule.
3. Both worlds run two more days: every part of their saves then agrees under the rule (165,095 values exact, 33 fractions within
   4e-16), money totals and the random stream are identical. The last-place difference does not change what happens next.

`save_continuity_test` applies the same rule to its "right after loading" check (it failed on purpose on `0d6a484` to expose ND-15).
A later change that lets a whole number drift, a text differ, or a fraction move beyond the tolerance, or that makes the two worlds
part, fails these tests.

## Limits

- Harmlessness is shown for two days from one seed's world; the deterministic-reload guarantee (SAV-04 option (a)) covers longer
  play from the same save. A divergence found later is a defect against this record.
- This is not bit-exact saving. Bit-exact saves would need a save-format change (ND-15 option (b)), not chosen.
