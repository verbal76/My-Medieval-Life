MY MEDIEVAL LIFE — BUILD 18: ORE DEPOSIT PLACEMENT DEFECT

OWNER PLAYTEST FINDING

Ore-bearing deposits appear to be spawning directly inside the developed village, including areas near buildings, roads, and farmland.

This conflicts with the established design that natural mining deposits belong outside the developed village.

REQUIRED WORK

1. Inspect the world-generation and ore-deposit placement rules.

2. Determine whether deposits are being generated inside the settlement or whether settlement construction is overlapping deposits generated earlier.

3. Confirm that the markings in the supplied screenshot are actually ore deposits before changing generation code.

4. Prevent inappropriate natural ore placement within the developed village footprint, including buildings, roads, farms, and common settlement areas.

5. Preserve valid deposits in appropriate mining areas outside the developed settlement.

6. Preserve existing land ownership, mining rights, extraction tools, depletion, sustainability, and physical resource conservation.

7. Do not create separate regeneration or depletion rules for surface versus underground deposits.

8. Check how settlement expansion should interact with existing deposits. Do not silently delete physical ore or change ownership to solve an overlap problem.

9. Apply the smallest appropriate correction to placement or settlement-generation ordering.

VALIDATION

Use focused world-generation checks across representative seeds.

Verify that ore remains available outside the settlement and that the village footprint does not contain inappropriate natural deposits.

Do not rerun unrelated simulation campaigns.

RELEASE BOUNDARY

Add this to the Build 18 defect list.

Do not change frozen Build 17 or invalidate its validation evidence.

Apply MSW-01: Minimum Sufficient Work.
