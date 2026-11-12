# Build 25 R2 merge chain (B25R2-CONT-01 section 1)

Owner conditional authorization 2026-11-11 (`docs/directives/2026-11-11_b25r2_authorization_continuation.md`). Each fix is merged
on top of the previous step (`wip/b25r2-chainN`); the development line `wip/b25r2-rev2` moves to a step only when that step's full
Tests and gate pass and every finding change is explained. Gate comparison by `scratchpad/tools/gatecmp.py`: each finding's
identity (run + description), severity, blocking flag, expected and actual values, plus the determinism lines. `rot_*` runs use new
seeds on every commit (not comparable run to run); their findings are classified by kind. Accepted baseline `df67e8e` unchanged.

| Step | Fix (source) | Chain commit | Tests | Gate | Finding changes vs previous step | Merged |
|---|---|---|---|---|---|---|
| 1 | Household member ids after load (`cdfa395`) | `ab72074` | 43124190693 pass | 43124194923: 33 blocking, all unchanged; determinism identical | rot only (new seeds): rot_1298 "14 villagers stayed 3+ hours on one cell" (longest 43 h, on the way home to a homestead; known stuck-villager class, NPC-01) | yes, dev line `ab72074` (2026-11-11 20:35 EST) |
| 2 | Phantom household repair (`837e3e1`) | `977fbaf` | 43124198918 queued | 43124202901: unchanged; determinism identical | rot only (rot_7894, same class) | waits for Tests |
| 3 | Clan children eat from the pantry (`bd17bd8`) | `3db4e9c` | 43124207067 pass | 43124211471: unchanged; determinism identical | rot only | after step 2 |
| 4 | Meal purchases respect contract claims (`d0ddf8f`) | `39e2a8b` | 43124215890 running | 43124220147: blocking unchanged; determinism identical | removed 2 non-blocking: hunt_out and kill_smiths "1 villager stayed 3+ hours on one cell" (3-4 h taking survey samples to the assayer); meal-claims changes what villagers buy and when, so those days run differently; nothing added: an improvement, not a regression | after step 3 |
| 5 | Contracts use only uncommitted money (`11fdaa9`) | `166e87f` | 43124224113 running | 43124228216 queued | - | - |
| 6 | ND-15 tolerances (`d7217b8`) | `6c91c13` | 43124232365 running | 43124236217 queued | - | - |
| 7 | ND-16 save precision (`df48840`) | `5503614` | 43124241072 running | 43124245095 queued | - | - |
| 8 | Emigration and marriage (B25-EMIG-MARRIAGE-D1, `6d0b084`) | to be chained after 7 | targeted 43127833247 running | - | - | - |
