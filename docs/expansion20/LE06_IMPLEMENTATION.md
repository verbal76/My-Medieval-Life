# Expansion 20, LE-06: implementation note (multi-seed long runs, determinism, profiling; the save bound first)

Register LE-06 (gate "No errors/leaks; legitimate failure allowed"; branch `wip/x20-le06`, from `353d12b`). Authority: owner
directive 2026-10-30 `docs/directives/2026-10-30_b24_review_remediation_x20_integration.md` (on staging): first and mandatory,
bound the economy's save storage "with evidence that preserves the intended knowledge and market behavior" (it was 1.97 MB at
day 30 on seed 1, mostly 7,752 knowledge entries). The switch stays off.

## 1. The save bound (done)

Measured (seed 1, market driving, day 3, before): economy section 810 KB, of which knowledge 672 KB (3,043 entries, about 220
bytes each: by latest source word_of_mouth 1,758, dealing 743, in_person 455, own 75, contract 12). Knowledge grows with who dealt
with whom (firsthand) and is bounded only for hearsay (max_hearsay); its entries never age out.

The least behaviour-changing combination, both parts lossless for every decision:

1. **Compact encoding (no behaviour change).** `EconKnowledge.to_dict` writes format 2: one sorted string table (refs, items,
   sides, sources, locations) and one row of numbers per entry, every field kept. `load_dict` reads format 2 and the older
   `"entries"` (format 1), so Build 24 and LE-01..LE-04 saves load unchanged; the change is confined to the optional economy
   section (never written while the economy is off). Day 3: knowledge 672 KB -> 131 KB (5.1x), same 3,043 entries, same values.
2. **Forgetting what can no longer be acted on (the design's own decay).** An entry's reliability is trust x 0.5^(age /
   half_life_days) with trust at most 1, and every decision that reads knowledge (believed: asks, bids, floors, ceilings;
   direct dialogue; speculation) ignores entries under `market.min_reliability`. Past age half_life x log2(1/min_reliability)
   (14 days with the provisional 7 and 0.25) an entry can never be acted on again, so `forget_unusable` (knowledge, on) drops it
   at dawn. The only other reader is word-of-mouth retelling, freshest first: a stale price passed on arrives just as stale (the
   teller's seen_day travels with it) and can be acted on by no one. This is not a new gameplay rule but the existing decay
   (OD-LE-10 D09 "may be wrong or stale"); reported to the owner as the choice made.

Evidence (`game/tests/le06_save_test.gd`, 21 checks): lossless format 2 and format 1 round trips; the window equals the action
threshold (entries past it are below 0.25 even at full trust; 14 days kept, 15 dropped); with and without forgetting every
villager's believed price, sellers, buyers and best bid are identical and the set of entries any decision can act on is the same;
the record stays bounded over 60 days of daily news; at three checkpoints of a market-driven world the economy section loads
exactly as saved and two worlds loaded from the same save run on identically; a real Build 24 save (fixture
`b24_save_v23_single.json`, written by the unmodified 4611d86) loads with the economy off (no new key) and on (empty economy, runs,
saves and loads exactly). Long-run sizes at days 30, 90 and 365 and the market comparison with run 41135583126: section 3.

**Finding outside the economy (reported to the lead):** a whole world saved and loaded is not identical to the never-saved world
even immediately after the load, with the economy OFF (World.load_dict rebuilds state). Two worlds loaded from the same save do
run on identically. So "save/load determinism" holds as deterministic replay from a save, not as save-transparency.

## 2. Remaining LE-06

Multi-seed long run (365 days, seeds 1 and 2, `--market`, checkpoints), determinism, profiling (OD-LE-15), on the integrated
`wip/expansion20` after the food-trade merge; one G0. Then LE-05, then LE-07.

## 3. Evidence

To be filled from the one 365-day `--market` run (sizes at days 30, 90, 365; market activity vs run 41135583126 at day 30).
