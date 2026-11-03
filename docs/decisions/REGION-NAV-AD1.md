# REGION-NAV-AD1: the settlements stand at their existing trade coordinates (approved design amendment)

- **Date:** 2026-11-03.
- **Decided by:** the owner (REGION-NAV-Q3), conditionally.
- **Source:** `docs/directives/2026-11-03_region_nav_owner_decisions_q1_q6.md`.
- **Amends:** AD-1 of the REGION-NAV-01 plan as approved at `611c294`, which placed each settlement at the road node nearest a
  bearing and distance.

## The amendment

Each settlement stands at its `OffMapSettlement.pos`, relative to the village's centre: `x` tiles across and `miles × 12` tiles
south. These coordinates already existed, and the regional trade measures distances between settlements by them
(`Regions.route_table`). Wulstead on the road south is canon.

## Technical rationale

- **One geography.** Placing the settlements by new bearings would have given them two positions: a physical one for travel
  and the old one for trade costs, courier days and the regional market. That is the "separate coordinates" the owner rules
  out.
- **No churn.** The existing coordinates needed no change to the saved settlement economies, the couriers or the trade
  routes.

## The owner's condition (to be verified, REGION-NAV-01 S1/S2)

The following must agree as one model:
- physical locations;
- regional distances;
- road connections;
- travel times;
- economic geography (courier days, trade carriage).

A test establishes it; until then the amendment is approved but not verified. Built at `2745f2f`; the reachability of every
settlement is shown in `overworld_test`.
