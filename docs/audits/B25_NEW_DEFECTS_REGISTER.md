# Build 25: defects found after the original 69 (B25-TRACK-69-02)

Owner directive 2026-11-10: newly discovered defects are kept here, apart from the original 69
(`docs/audits/B25_69_ITEM_TRACKER.md`), linked to an original item only where they share a cause or a system. Each also has a
requirements-register record (column Register). Same verification columns as the tracker (Y / N / part / n/a).

| ID | Defect | Found in | Register | Linked original item | Branch / commit | Code | Focused | Full CI | Sim | Merged | Device | Release |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ND-01 | A seller was made the payer for their own goods (self-trade loop, p:64 refused 1262 times a day) | campaign 42734194963 | B25-SELFTRADE-VAL-01 | - | `b57261f` + test `fc16aa4`, in `fbfd6ad` | Y | Y (11/0, 4 red) | Y (42788023867) | Y (42788018729) | N | N | N |
| ND-02 | A food seller's household starved beside the family's business stock | owner directive | B25-HH-BIZFOOD-D1 | - | `7594f37`, in `fbfd6ad` | Y | Y (22/0, 10 red) | Y | Y | N | N | N |
| ND-03 | Meal planned at the list price, asked at the deal price (p:149 refused bread 2776 times) | campaign 42760291468 | (with B25-HH-BIZFOOD-D1 batch) | - | `1381eb3`, in `fbfd6ad` | Y | Y (7/0, 1 red) | Y | Y | N | N | N |
| ND-04 | F015: lone homesteader starves holding coins (coins counted as food held; no grain fallback) | campaigns 42760291468, 42788018729 | B25-F015-FOOD-01 | - | `wip/b25-f015-p99` `3d515d6` | Y | Y (14/0, 8 red) | Y (42832327842) | running (42832338970) | N | N | N |
| ND-05 | p:99: smiths re-plan forge purchases the act refuses (planner ignored the reserve rule) | campaign 42788018729 | B25-P99-PAYER-01 | - | `wip/b25-f015-p99` `3570832` | Y | Y (11/0, 2 red) | Y (42832327842) | running (42832338970) | N | N | N |
| ND-06 | p:100: meals planned from stock promised to a contract (LE-03 claims); refusals mislabelled "pack full" | campaign 42788018729 | B25-INV-P100-FULLPACK | NPC-02 (same class: goods held for a contract) | `wip/b25-meal-claims` `d0ddf8f` | Y | Y (14/0, 5 red) | Y (42843756504; one UI-timing check failed, re-run alone 42856156793 passed) | N | N | N | N |
| ND-07 | p:52: contract purchases planned on the raw purse; its own bids held the coins | campaign 42788018729 | B25-INV-P52-BLOCKS | - | `wip/b25-meal-claims` `d0ddf8f` | Y | Y | Y | N | N | N | N |
| ND-08 | Contract acceptance counted committed coins (bids) and double-counted open buy contracts | owner decision | B25-CONTRACT-FUNDS-D1 | - | `wip/b25-contract-funds` `11fdaa9` | Y | Y (10/0, 3 red) | running (42859327767) | N | N | N | N |
| ND-09 | Clan children could not eat from their household's pantry | campaign 42788018729 | B25-INV-BANDIT-CHILD | - | `wip/b25-clan-child-pantry` `bd17bd8` | Y | Y (7/0, 2 red) | Y (42846530801) | N | N | N | N |
| ND-10 | Household member ids are floats after any load: erase/has/find fail (phantom members) | investigation of campaign 42788018729 | B25-INV-BANDIT-CHILD | BIZ-08 (same JSON-float class; fixed there for venture hands only) | `wip/b25-hh-member-ids` `cdfa395` | Y | Y (5/0, 3 red) | Y (42843763261) | N | N | N | N |
| ND-11 | Phantom memberships already written into older saves | follows ND-10 | B25-SAVE-PHANTOM-D2, -D3 | REG-06 (household records out of step) | `wip/b25-hh-phantom-repair` `7e844e3` (D3 extension in progress) | Y (D2) | Y (30/0, 15 red; real save: 13 repaired) | running | N | N | N | N |
| ND-12 | Recorder kept only the end detail of an event: refused buys lost their figures (only "below_reserve"), player verbs lost what was asked; events never lost or duplicated | investigation report | B25-ND12-01 | - | `wip/b25-nd12-recorder-detail` `12d7549` | Y | Y (11/0, 4 red) | running | n/a (reporting only; neutrality 5/0) | N | n/a | N |
| ND-13 | p:52-type contract acceptance capacity blind to claims (now ND-08) | investigation report | B25-CONTRACT-FUNDS-D1 | - | see ND-08 | - | - | - | - | - | - | - |
| ND-14 | KI-09 demo_test exit crash (RegionGeo cache, two threads) | CI | KI-09 | - | `167b235` merged | Y | Y (1/20 -> 0/20) | Y | n/a | Y | N | N |
| ND-15 | Godot's full-precision JSON does not round-trip every float exactly (10 of 345 hunger/position values differ in the last bit): real saves are not bit-exact; same-save reloads stay deterministic | SAV-05 work (WP-1) | - | SAV-05, SAV-04 (continuity policy) | `0d6a484` (save_continuity_test now fails on it, on purpose) | N | Y (reproduced) | N | n/a | N | n/a | N |
| ND-16 | The campaign harness writes its segment saves at default JSON precision (economy_sim.gd _fr_write): resumed campaign segments reload a lossy copy, not a production-equivalent save | SAV-05 work (WP-1) | - | SAV-05 | none | N | N | N | N | N | n/a | N |

Open questions outside the 69: ND-15 (bit-exact saves: change the float encoding, a save-format change, or accept the 1-ulp difference under the SAV-04 policy) and ND-16 (switch the campaign harness to full precision: makes segments faithful to real saves but campaigns after the change are not comparable with earlier ones).
