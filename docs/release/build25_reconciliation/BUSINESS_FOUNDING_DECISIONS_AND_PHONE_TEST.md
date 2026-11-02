# Build 25: the five business-founding decisions (B25-ECON-P1..P5) and the LE-07 phone test (gate 11)

- **Requested by:** owner, 2026-11-02 (B25-CLOSE-02, `docs/directives/2026-11-02_build25_closure_scope_and_campaign.md`).
- **Evidence:** `docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md`, on the Build 25 source (`d6ab686`): seed 1, 120 days,
  economy off, with FUNNEL, JOBS and ORE diagnostics.
- **Balance:** nothing has been changed. Every value below is the current one, from `game/data/balance.json` on the Build 25
  source.

## Why no villager founds a business today

A villager is considered on their own morning once every `look_days` (7) days. All of these must hold (`Ventures.refusal`):
- they are in a founding trade: smith (a smithy), carpenter or tanner (a carpentry), or cook (a bakehouse);
- skill level at least `min_level` (4) in the trade's own skill;
- at least `min_trade_days` (20) working days in the trade;
- they keep no business already;
- the household has its own or a rented home and is building nothing;
- **the trade has more work than room** (`NPCBrain.skilled_place`): its workers spent at least `busy_share` (0.35) of a working
  day at the trade's stations over the last `window_days` (5) mornings, with free station time and earnings enough for one
  more;
- the household can spare the start: the ground and `found_start_share` of the materials, plus `working_days` (10) days of
  costs;
- the judgment profile `business_found` decides yes.

In seed 1, the founding trades' benches were 2-20 % busy for all 120 days. So every one of the 172 weekly looks stopped at the
"work but no room" test, and nobody reached the money or judgment steps.

## The decisions

| ID | Question | Current behaviour | Options | Recommendation |
|---|---|---|---|---|
| **B25-ECON-P1** | Should founding still require the trade's benches to be full and busy? | Founding needs `busy_share` 0.35: the trade's workers busy at least 35 % of a working day. Benches ran 2-20 % busy, so 0 foundings. | **A** keep the rule: businesses form only where demand exists. **B** the founder weighs independence even with idle benches (the judgment weighing decides, no busy test). **C** a lower threshold for founding only (for example 0.15). | **A.** Act on demand (P2-P4) rather than on the gate. Under WDR-022, no foundings in a village with no demand is a legitimate outcome. |
| **B25-ECON-P2** | Coinless young adults cannot take open miner or woodcutter places, because those jobs need a tool and the manor's tool help covers only workers already in the trade. | All 10 jobless villagers at day 120 came of age in the run, with a median of 0 coins. | **A** keep. **B** the household buys a member's first work tool from its own purse, by the existing purchase rules. **C** the manor advances the tool against wages. **D** tool rental outside the Living Economy. | **B.** It uses existing rules, creates no new money, and turns idle young adults into producers, which raises demand for smiths and carpenters. |
| **B25-ECON-P3** | Retired villagers keep their trade stock forever. | At day 120, elders held 68 iron ore, 47 coal, 24 iron bars, 8 pickaxes and 7 axes, while the working smith held nothing. | **A** keep. **B** elders and adults between jobs sell their goods through the existing sell rule. **C** the stock passes to the trade's successor, as tools already do. | **B.** It returns stranded inputs to the market through the existing sale path, with coins changing hands. |
| **B25-ECON-P4** | Ore imports stall. | Garton's quarry stock rose from 63 to 175, but its trader had no coins to buy it, so 0 iron ore reached the village in 120 days (2 in a year on seed 2). | **A** keep as an outcome. **B** the trader carries ore on consignment, paid on sale. **C** smiths buy from the quarry directly. | **Decide after the final campaign**, leaning **B**. The campaign's economy-on run measures it. |
| **B25-ECON-P5** | Should village land (fields, trees, game, ore) grow with the population? | Land is fixed while the population roughly triples in a year, so unemployment rises with population. | **A** no change. **B** new fields with population, under a rule to be designed. | **A** on present evidence. Farming at 1.75 was food-secure on both seeds, and ore depletion follows the owner's existing rules. |

**For this build:**
- If the owner chooses **A for P1 and P5, B for P2 and P3, and defers P4**, two small changes follow, each through existing
  rules: a household buys a member's first tool (P2), and idle holders sell trade stock (P3).
- Each needs targeted tests. Both would have to land **before** the frozen SHA if they are to be in the campaign.
- Otherwise the campaign runs on the current balance. Zero business founding is then recorded as this build's measured
  outcome, and B25-BIZ-OWN's "found, buy, sell, hire and expand over a year" is reported as not observed, by an owner-accepted
  balance choice.

## LE-07 gate 11: phone performance test (owner device check)

- **Target (OD-LE-15):** about 500 villagers, about 4 ms a frame, on a mid-range Android phone. OD-LE-15 calls it "a target to
  PROFILE, not a success claim".
- **What the game offers today:**
  - a frame rate cap (Settings → Display → Frame rate cap: none, 30, 60 or 120);
  - no on-screen frame-time readout;
  - no in-game switch for the Living Economy;
  - no way to reach 500 villagers without about a year of game time.
- **What the procedure needs:** two small test aids, built only with the owner's agreement and kept out of normal play.
  1. A developer setting, "Show frame time", next to the existing developer recording option. It shows the average and worst
     frame time over the last 10 seconds.
  2. A test save made from the campaign's economy-on run at about day 365 (about 450-500 villagers), shipped as a separate
     download and loaded from the title screen.

**Procedure:**
1. Install the private draft APK over Build 24 on a mid-range phone, the owner's own. Fully charge it, close other apps, set
   brightness to normal, and leave the frame rate cap at none.
2. Load the test save. Turn on "Show frame time".
3. Stand in the village centre at normal speed for 5 minutes, through at least one hour change in game time. Write down the
   average and worst frame time.
4. Walk from the manor to the market and back for 5 minutes. Write down the same two numbers.
5. Wait through a day change (dawn), when the most work runs. Write down the worst frame time across it.
6. Repeat steps 3-5 with the cap at 30.

**Acceptance threshold (proposed for the owner to confirm):**
- **Pass:** a steady 30 fps on the phone. The average frame time is at most 33 ms and the worst frame at most 100 ms, except
  across the dawn change, where the worst is at most 250 ms (a brief, visible pause, not a freeze), with no stutter that makes
  walking feel uneven.
- **Fail:** an average above 33 ms, or repeated pauses of over 250 ms in normal play.
- **On the 4 ms simulation target:** it cannot be read on the phone without a profiler. It is checked on the desktop
  profile instead (`LE00_ARCHITECTURE_AUDIT.md`: 3.67 ms at 500 people) and stays recorded as a profiling target, not a pass
  or fail threshold, as OD-LE-15 says.

Until this check is done or the owner rules on it, gate 11 stays **OPEN**, so the Living Economy cannot be switched on by
default. Build 25 can still be packaged with the economy off, if the owner so decides.
