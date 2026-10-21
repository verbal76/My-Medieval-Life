# Owner decision, 2026-10-21: FSE-12 / FSE-13 farming

Saved verbatim. Register: OD-26 and FARM-08 (the shared-yield comparison), FSE-12, FSE-13.

---

BUILD 16 — FSE-12 / FSE-13 FARMING DECISION

I approve the design direction of one shared per-cell farming model for the player, NPC households, and manor fields.

However, I am not approving the existing 3-wheat-per-cell yield or selecting a replacement yield yet.

Keep both FSE-12 and FSE-13 switches off in the normal game until further approval.

Run controlled comparisons using several reasonable shared yield values, including values between the existing manor productivity of approximately 0.9 and the player productivity of 3 wheat per cell.

Use identical seeds and initial conditions for meaningful comparisons.

Test the shared model and seasonal farming together.

Measure:

- Total grain production.
- Grain consumed, sold, stored, and left unsold.
- Seed consumption and recovery.
- Labor required per harvest.
- Household food security and starvation causes.
- Manor and family-farm economic viability.
- Market demand and prices.
- Livestock feeding and milk production.
- Effects of seasonal planting and harvest timing.

Investigate why the seasonal model sharply reduces milk production. Determine whether this is caused by feed availability, seasonal behavior, labor allocation, or a defect.

Do not artificially eliminate starvation by injecting resources or guaranteeing successful outcomes.

Recommend a shared yield based on the resulting economy, not simply on matching the old manor production total.

Report the comparison results and your proposed value for my approval before enabling either switch globally.

Continue independent approved Build 16 work, including SHOP-01 and TRADE-01.

Preserve existing regression coverage, determinism, and resource conservation.

Commit and push verified work to staging. Do not merge or publish without authorization.
