# Sleeping loft: integration report (HOUSE-12)

**Owner direction:** 2026-10-20 (`docs/directives/2026-10-20_sleeping_loft_and_long_run_reliability.md`).
- **What:** a lightweight sleeping loft as a legitimate house improvement, giving more sleeping capacity after construction with real materials, labour and time.
- **Not:** a navigable second floor. The full multi-level system is deferred (HOUSE-11, `docs/design/UPPER_FLOORS_SCOPE.md`).
- **First:** report whether it fits the existing house and bed systems without substantial changes to pathfinding, rendering or save compatibility.

**Status:** report only, nothing built. The figures are agent proposals for the owner to approve.

## Fit with the existing systems (read in the code)

| System | How the loft fits | Change |
|---|---|---|
| **Beds and occupancy** | A house's sleeping places are the `bed` spots of its interior (`World.home_spot`, `Construction.beds_in`). The interior is rebuilt from the building records at start, on load and when a building is finished (`World.index_interiors`, `interior_for`). A finished loft is a `loft` field on the house record; `interior_for` then adds the loft's bed spots. `beds_in`, crowding (`beds_needed`, HOUSE-08), `Life.has_room` and the sleep order all count them with no change. | Small: one field and a few lines in `interior_for` |
| **Sleeping** | A villager walks to their bed spot's `use` cell and lies there (`NPCBrain._plan_bed`). A loft bed's `use` cell is the ladder: an existing walkable floor cell inside the house. The villager walks to the ladder, as to any bed, and sleeps. | None |
| **Pathfinding** | Nothing new to walk: the ladder cell is already floor. | None |
| **Drawing** | A sleeper is drawn lying where they sleep. A loft sleeper is drawn **not at all** while asleep (they are up in the loft), and appears at the ladder on waking. One check where villagers are drawn. A ladder tile is drawn only if the owned packs have one (asset pipeline). If not, the house looks unchanged and the wiki and house panel say it has a loft. | Small |
| **Saves** | Building records are saved whole, so the `loft` field persists. Older saves have no field, meaning no loft. While building, the site is a normal construction site record. No save-version change is needed. A save from a build with lofts opened in an older build is refused as newer, as today. | None |
| **Construction** | Uses the existing site, helper and delivery path (`World.start_site`, `deliver`, `Construction._keep_building`) on the house's own parcel. An original house's ground is surveyed first (`Property.survey_under`, HOUSE-09, nothing paid). When the last load is in, `_finish_site` sets the house's `loft` field, instead of making a new building, and rebuilds the interiors. The beds exist only then. | Small: one branch in `_finish_site`, one kind in `Construction` |

**Conclusion:** the loft fits without substantial changes to pathfinding (none), rendering (one hide-while-asleep rule) or save compatibility (none).

## Proposed construction requirements (agent proposal, provisional)

| | Proposal | Why |
|---|---|---|
| Materials | 12 planks, 6 logs, no stone | Timber floor and joists under the roof: a third of a house's planks and logs, and no masonry |
| Money | Only what the household pays for materials it does not hold. To start: found_start_share (25 %) of the materials' price in hand, as for any building. No ground to buy. | The same start rule as houses and quarters |
| Labour and time | Every load carried to the house by a household member or a hired helper. The loft is finished when the last load is delivered (several trips over one or more days), as for every building. | The existing construction rule |
| Capacity | 2 sleeping places | Under the roof of a 9x10 house; with bed sharing (HOUSE-08), that holds up to 4 young children, or 2 more grown people |
| Limit | One loft per house | |
| Eligibility | Any house its household holds (owned or leased), original or built | Needs no ground, so it reaches the 18 houses that have none |

## How households and villagers use it

1. **Choosing:** a crowded household that nobody can leave works through its options in order:
   - a **loft**, if the house has none yet: cheapest, and needs no ground;
   - else a **5x6 room** or quarters where there is legitimate ground beside the house (HOUSE-10);
   - else its goal records that the house cannot grow, and it relies on bed sharing, a member founding a household when one can, or another home.
   
   The goal keeps the plan and the reason, so a blocked house does not retry an impossible placement.
2. **Building:** the responsible adult (HOUSE-02) saves, buys and carries as for any building, keeping back food and a missing tool's price.
3. **Sleeping:** with the loft finished, the household's sleep order gives the loft beds to the members after the ground-floor beds. Those members walk to the ladder at bedtime, are hidden while asleep, and come down in the morning.
4. **Occupancy:** the house's sleeping places rise by 2 when the loft is finished, not before. Crowding, births, moving in and founding all see the new count.

## Tests (when approved)

- A crowded family in an original house with no ground builds a loft:
  - the materials are bought or taken from the store, none from nothing;
  - no bed exists before the last load;
  - 2 more sleeping places after;
  - the house is no longer crowded.
- A loft sleeper goes to the ladder, sleeps, and wakes there; a second loft is refused.
- Saving and loading keeps the loft and its beds; a save without the field loads with no loft.
- Ownership, rent and household membership are unchanged by the loft.
