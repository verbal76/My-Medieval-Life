# FSE-14: land planning (land supply, plots and pens on rent, legitimate rent)

Register entry FSE-14. Acceptance: "Design for land supply, rental of small and large plots and pens, legitimate rent;
foundations in Build 16 only where safe; the rest scheduled with the living-economy build (FSE-10)."

The owner's words: "The six existing fields must not remain the permanent agricultural capacity of a growing village.
However, the answer is not to automatically create another field whenever population increases."

**Status of this document.** Sections 1 and 2 describe the code as it stands on `wip/b16-farms2` (`014b079`).
Sections 3 to 5 are **design proposals**: nothing in them is approved unless it cites an owner decision. The
owner-approved parts are Q9 and Q11 of `docs/directives/2026-10-21_build16_master_completion_directive.md`
(fence and gate materials; variable plots, lease and purchase priced by area). Paths are relative to `game/`
unless they start with `docs/`.

---

## 1. Land supply today

**Where farmland can be claimed.** Farmland goes on any rectangle that `FarmPlots.refusal`
(`scripts/core/farm_plots.gd`) accepts. That check is the land office's `Property.can_claim`
(`scripts/core/property.gd`) plus three access rules:

- **Size:** at least 3x3 (a fence round one cell). There is no maximum size and no limit on plots per household.
- **Inside the village:** the village map is 120 x 90 cells, and a 1-cell margin is kept at its edge.
- **Not on anything held or kept:** no parcel (surveyed or claimed), building, manor field, pen, market stall or
  its serving cell, station or its use cell, container, or mine seam.
- **No grown tree:** "fell it first". Stumps, saplings and young trees may stand on farmland, but its holder must
  clear them (FARM-02).
- **No road and no solid cell.**
- **Access rules (FarmPlots):** no building's door step, no trail out of the village, and a gate on some side
  that opens onto ground reachable from the village (the same path check buildings use for their doors).

**What limits supply.**

- **Fixed:** the village bounds and the road network.
- **Shrinks as the village grows:** every parcel, building and pen (each new house takes ground).
- **Can be won back:** grown trees, by felling (woodcutters and builders fell them; the player can too), and
  boulders, by mining.
- **Never released:** the manor's six fields (11 x 6 each, 396 cells) and the four manor pens are map data.
- **Freed when a lease ends:** land returns to the manor whole, fence included (`Property._release`), and is
  offered again.

**Measured (cheap diagnostic at world start, seeds 1 and 2, identical because the village map is fixed).**

| Measure | Value |
|---|---|
| Village cells | 10,800 (120 x 90) |
| Cells free of every blocker in `Construction._free_sums` (inside the margin) | 5,598 |
| Manor field cells | 396 |
| 4x4 farm plots that fit, placed greedily with a 1-cell gap and each passing `FarmPlots.refusal` | 78 |
| 9x10 plots that fit the same way | 5 |

The free ground is plentiful but fragmented by paths, trees and buildings. Small plots are easy to place; large
rectangles are scarce until trees are felled. The greedy count is a lower bound on packing, not a maximum.

## 2. Foundations built in Build 16

| Foundation | Where | What it does |
|---|---|---|
| Farmland is a land-office parcel | `FarmPlots.claim` → `Property.claim(rect, ref, lease, grub=false, {"farm": …})` | Ownership, weekly lease, arrears, eviction after `rent_evict_missed`, escheat and the land office's lists are the existing ones. The parcel carries `farm: {gate, fence}` (saved in `World.plots`). |
| Variable plot size | `FarmPlots.rect_between`, `refusal` | Any rectangle of at least 3x3 that passes the checks in section 1 (owner Q11). |
| Price by area, no new coefficient | `FarmPlots.terms` | Purchase price = `Property.land_price(w, h)` = ceil(plot_price x area / 90), with plot_price 60. Weekly lease = ceil(price x weekly_rent_share), with the share 0.1 (`Property.rent_of`'s rule). A 16-30 cell plot leases at 2 coins, the FARM-07 baseline. Bought land pays no rent. All payments go purse → `w.treasury` (`Property._pay_manor`). |
| Placement UI | `scripts/main.gd` (`begin_farm_placement`, `_farm_input`), `scripts/ui/game_ui.gd` (`show_farm_deal`, `_show_farm_plot`) | Drag a rectangle with mouse, touch or pad; live green or red preview; lease and price mid-screen; explicit deal; refused without the coins (FARM-09). |
| Clearing, fence and gate | `FarmPlots.clear`, `fence_cost`, `build_fence`, `till_block` | Nothing on new farmland is cleared for free. The fence uses the pen rule on the real perimeter (`Farming.pen_planks`: a plank per 3 fence cells, the gate free) plus `farm_plot.gate_stone` stone (provisional, awaiting the owner). Ploughing needs the fence (FARM-02, owner Q9). |
| Household farming | `FarmPlots.till`, `sow`, `harvest`, `hour`, `plan_work`, `act`; hooks in `scripts/core/npc_brain.gd` | Farming's per-cell rules and numbers. The harvest goes to the family chest. Able members work by age and time (FARM-03, FARM-04). |
| Household uptake | `FarmPlots.daily`, `consider`, `find_ground`, `development_cost` | A household takes a plot by need (food days, a sustainable living), labour, season, free ground near home, and coins above its necessity reserve. It buys when it can afford to, else leases. A household with nobody able gives up its lease (FARM-05). |
| Land requirement | `FarmPlots.land_requirement`, `cell_food_per_year`, `labour_cells` | A year's food need against one cell's net yearly yield after seed: 0.64 cells an adult on the current calendar, not the 1.7 assumed before. Capped by the members' working time (FSE-15). |
| Soil follows the holder | `FarmPlots._follow_holders` | Tilled cells pass between the player's field (`Farming.cells`) and a household's (`FarmPlots.cells`) with the plot. |
| Never built over | `Construction._home_plan` | A founding household never chooses a farm parcel for a house. |
| Tests | `tests/farm_plots_test.gd`, `tests/farm_place_test.gd` | |

## 3. Small and large plots, and pens on rent (DESIGN PROPOSAL)

**Small and large plots.** The Q11 rule already covers both. Rent and price grow with area through
`Property.land_price` and the weekly rent share, so a small plot costs little and a large one proportionally more.
No size classes are needed. Proposals that remain open for the owner:

1. **Size cap:** none, the default today. Size is limited only by money, labour and fencing.
2. **Plots per household:** one per household while it decides (the current NPC behaviour); none for the player.
   This is a behaviour, not a rule.
3. **Enlarging a plot:** a second plot beside the first, using the `estate` mechanism parcels already have
   (`Property.estate_id`), rather than re-cutting the first parcel.

**Pens on rent through the same parcel mechanism.**

1. **Lease or buy the ground first.** A pen would stand on an ordinary parcel, marked `pen: {kind}`, claimed
   through the same rectangle UI. The ground is priced and let by the same `FarmPlots.terms`, so rent is
   `Property.rent_of` of bare ground; that is the legitimate rent. The owner is the manor until the ground is
   bought; the tenant pays it weekly through `Property.collect_rents`.
2. **Build the pen.** The fence follows the existing pen rule (`Farming.pen_planks`, gate free), plus the same
   gate stone as farmland if the owner extends Q9 to pens. The Fauna pen record (`Farming.build_pen`'s fields:
   kind, gate, feed_at, trough, owner, tenant) would be created on the parcel, with its owner or tenant mirroring
   the parcel's.
3. **What a pen lease needs that does not exist yet:**
   - `Farming.build_pen` accepts any rectangle inside a parcel the builder holds. Today its size is fixed per
     species by `farming.pens`; that table would become a minimum.
   - Villagers can build and keep their own pens: the keeper's feeding and collecting code
     (`NPCBrain._keeper`) for a household pen, and the purchase of stock from manor keepers by the player's rule
     (`Farming.buy_animal`).
   - When a pen lease ends, the animals go back to the holder's household (or are sold) before the ground
     returns to the manor. This is the one new rule, and it needs the owner's decision.
   - The existing manor pens stay map data, let rent-free to their keepers (unchanged).

## 4. How a growing village gains farmland without automatic fields (DESIGN PROPOSAL; mechanism already built)

- **No field is created by population.** The manor's six fields stay as they are: their size, owner and farmers
  are unchanged, and no code adds a field when the population grows.
- **Each household claims land by its own need and means** (`FarmPlots.consider`):
  - **Need:** food days below `household_savings_days`, or a living it cannot sustain.
  - **Labour:** an able adult.
  - **Means:** coins above its necessity reserve.
  - **Season:** sowing is possible.
  - **Ground:** free ground near home.

  Plot size comes from its land requirement. A larger village therefore has more households weighing land, and
  farmland grows only where a family can pay for it and work it.
- **The player claims land the same way,** at the same prices.
- **Land is a real limit.** Free ground is finite (section 1). When it runs out near home, a household finds
  none (`farm_plot_no_ground` is counted) and buys food instead, which is a legitimate outcome under WDR-022.
  Felling trees widens the supply.
- **Rent is real income for the manor** and returns to the economy through its existing treasury uses.

## 5. Left for FSE-10, the living-economy build (DESIGN PROPOSALS, none approved)

1. Pens on rented or bought ground for households and the player (section 3), with the pen lease-end rule for
   the owner.
2. A household enlarging its farmland, and leasing a second or larger plot as it grows (estate parcels).
3. A land market between households: selling or sub-letting farmland to another household. Today only the manor
   lets land.
4. Whether the manor ever lets out part of its own fields, or keeps them as the village's common work. The
   owner's wording rules out new automatic fields, not this.
5. Measuring land supply over the year: free ground, plots taken, `farm_plot_no_ground` and
   `farm_plot_cannot_afford` counts on the seed runs.
6. Whether a size cap or a per-household limit is wanted once the year runs show how much land households take.
7. Owner approval of `farm_plot.gate_stone` (2, provisional).
8. A farming skill (none exists): whether experience speeds farm work or raises yield, which would also feed
   FARM-04's "by skill".
