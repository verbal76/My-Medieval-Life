# Owner decision, 2026-10-22: FARM-08-Q-CROP (verbatim)

OWNER DECISION — FARM-08-Q-CROP

Approved: Option B — Proportional Harvest Sharing

The harvest belongs to the farmers who contribute labor to harvesting the field.

Required behavior

1. Track each participating farmer's actual contribution to the cutting work.
2. Divide the distributable harvest proportionally according to those contributions.
3. Farmers who contribute equal labor receive equal shares.
4. Farmers who contribute different amounts receive shares proportional to their work.
5. Farmers who contribute no harvesting labor receive no harvesting share.
6. Preserve the existing seed reservation and cattle-feeding priority before dividing the remaining crop.
7. Allocate indivisible wheat units deterministically. No wheat may be created, duplicated, or lost.
8. Preserve the existing field ownership, harvesting permissions, and theft rules.
9. Ensure the allocation is independent of which farmer's job completion event happens first.

Implementation scope

Record this as the approved owner decision FARM-08-Q-CROP.

Because the defect also exists with both experimental farming switches OFF, identify the smallest safe correction to the shared harvest-allocation logic.

Do not modify Build 17 while its release validation is underway.

Prepare the correction in Expansion 18 or an isolated branch, as appropriate. Do not merge it into Build 17 without explicit owner authorization.

Use MSW-01: Minimum Sufficient Work.

Validate proportional allocation, deterministic remainder handling, and conservation using focused tests. Do not launch another 365-day simulation solely for this correction.

Do not change milk prices, herd economics, seasonal farming, or other unrelated systems.

Both experimental farming switches remain OFF.

Report the implementation, test evidence, and any remaining owner decisions before proposing a merge.
