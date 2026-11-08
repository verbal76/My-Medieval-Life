MY MEDIEVAL LIFE — PROP-06 ESTATE, TENANCY, AND MIGRATION DIRECTIVE

OWNER AUTHORIZATION: Proceed with the following PROP-06 implementation and verification rules.

Repository: "verbal76/My-Medieval-Life"
Development branch: "wip/b25r2-rev2"

1. MULTI-PARCEL ESTATES

A household owning several parcels or an expanded estate must be allowed to migrate.

Owning additional property is not grounds for permanently preventing migration.

When a household voluntarily migrates:

1. Identify every property it legally owns.
2. Identify the parcels, buildings, and extensions belonging to each estate.
3. Treat an interconnected estate as one complete property transaction.
4. Calculate the appropriate sale value for every included component without double-counting.
5. Sell the estate to the manor using the established property valuation rules.
6. Transfer the actual purchase money from the manor treasury to the departing household.
7. Preserve the estate's physical structure and completed buildings.
8. Return legal ownership to the manor.
9. Make the estate available for subsequent legitimate sale or leasing, subject to existing occupancy and construction restrictions.

Do not dismantle an estate merely because its original household migrates.

Do not allow the existing restriction against selling an estate's anchor before its modules to permanently block migration.

Use an appropriate estate-level transaction or safely ordered component transfers.

The final result must be consistent regardless of the number of parcels.

2. PROPERTY RENTED TO ANOTHER HOUSEHOLD

Selling a property must not automatically evict its tenant.

If the departing household owns property currently rented to another household:

1. The manor purchases the property from its legal owner.
2. The departing owner receives the appropriate sale proceeds.
3. The existing tenant retains the right to occupy the property under the established lease.
4. The manor becomes the new landlord.
5. Future rent is paid to the manor rather than the previous owner.
6. Existing lease terms, due dates, and legitimate obligations must be preserved.
7. The tenant's personal possessions, inventory, and legally owned assets remain theirs.
8. Buildings and improvements remain physically present.
9. No additional goods or money are created during ownership transfer.

A change of landlord is not automatically grounds for terminating a lease.

The tenant may continue living and working there until the lease ends through normal gameplay.

If the existing property architecture cannot represent this correctly, extend the relevant ownership and tenancy handling rather than removing the tenant to make the sale succeed.

Distinguish ownership of land and buildings from ownership of movable goods and independently operated businesses.

3. PROPERTY LEASED BY THE MIGRATING HOUSEHOLD

Preserve our previously approved rule.

If the departing household is the tenant rather than the owner:

- The household surrenders its lease to the manor.
- The manor retains the land and permanent improvements.
- Unfinished construction and materials already delivered to the leased site remain with the manor.
- The migrating household receives no compensation for surrendered improvements.
- Remaining rent obligations are handled according to the established lease rules.
- The property becomes available for future legitimate occupancy when the tenancy and construction state permit it.

Do not confuse surrendering a lease with selling outright-owned property.

These are legally and economically different transactions.

4. FAILED SALES MUST BE ATOMIC

No partial property liquidation is permitted during migration.

The current behavior in which several parcels may be sold before a later transaction fails is unacceptable.

Implement a complete preflight and transaction mechanism.

Before making irreversible changes:

1. Identify all properties requiring settlement.
2. Validate actual legal ownership and tenancy.
3. Calculate the total purchase price.
4. Confirm that the manor has the required funds.
5. Validate the estate's complete transfer.
6. Check unfinished construction and materials.
7. Check outstanding contractual and financial obligations.
8. Confirm that the transaction can complete without violating existing property rules.

Only after all conditions pass should the transaction be committed.

If an unexpected failure occurs during execution, restore the original state completely.

That includes ownership, tenancy, buildings, construction materials, household inventory, treasury money, and financial records.

Either the entire transaction succeeds or none of it happens.

The failure path must not create or destroy coins, duplicate materials, transfer ownership without payment, or leave the household partly migrated.

5. MANOR INSOLVENCY

A household cannot receive fictional money because the manor lacks funds.

If the manor cannot afford the required purchase:

- Do not fabricate sale proceeds.
- Do not confiscate outright-owned property.
- Do not complete only part of the estate sale.
- Do not transfer ownership without the agreed compensation.
- Leave the attempted property settlement unchanged.
- Keep the household eligible to attempt migration again when the financial conditions permit.

Preserve the current safe financial restriction unless an alternative legitimate buyer or established financing mechanism already exists and is authorized.

The presence of multiple parcels or existing tenants must not itself cause an otherwise valid sale to fail.

Do not introduce an unapproved lending or money-creation mechanism to solve manor insolvency.

6. PHYSICAL MIGRATION

The owner has also approved REG-05:

Households must physically travel when migrating.

PROP-06 must remain compatible with that requirement.

Property liquidation should occur at the appropriate actual departure point, not when a household merely considers migrating.

An interrupted or cancelled departure must not leave an unintended completed property settlement.

Do not treat an instantaneous population transfer as acceptable final migration behavior.

Coordinate PROP-06 with the physical migration implementation so the household's property, funds, inventory, and identity remain consistent throughout the process.

7. REQUIRED REGRESSION TESTS

Extend the existing PROP-06 regression coverage.

Test at least:

1. One outright-owned parcel.
2. Multiple separately owned parcels.
3. One estate containing several modules.
4. A household owning more than one estate.
5. An owned property rented to another household.
6. Tenant rights surviving transfer to the manor.
7. Rent subsequently reaching the correct landlord.
8. A household surrendering several leases.
9. Owned property containing unfinished construction.
10. Leased property containing unfinished construction.
11. Insufficient manor funds.
12. A deliberately failed transaction partway through an estate sale.
13. Complete rollback after failure.
14. Coin and material conservation.
15. Save/load before and after property transfer.
16. Migration involving only part of a household.
17. Migration involving a complete household.
18. Interactions with business ownership and independent business tills.

Ensure each test executes meaningful assertions.

Where a test exposes an existing defect, preserve red/green evidence demonstrating the failure before correction and success afterward.

Do not weaken existing assertions or modify simulation baselines to achieve passing results.

8. CONTINUE THE EXISTING INTEGRATION PROCESS

Your current 12-correction integration remains the immediate priority.

Preserve the separation between:

Batch A — Original 11 audit corrections plus B25R2-BRUSHOFF

Continue strict CI and 365-day campaign verification.

Merge into "wip/b25r2-rev2" only when the required gates are satisfied.

The 32 reconciled baseline differences must remain documented. Establishing that they are expected does not by itself authorize replacing the accepted baseline.

Batch B — Approved gameplay features

- LIFE-03 — Sage succession.
- LIFE-04 — Widow/widower remarriage.
- PROP-06 — Migration property settlement.
- MP-05 — Mutual multiplayer asset sharing.

LIFE-03 and LIFE-04 can proceed through their own verified integration process.

Correct PROP-06 using the rules above.

Continue the outstanding MP-05 security verification independently. Its testing requirements remain in force.

Do not hold completed, independently verified features indefinitely because another unrelated feature requires additional engineering.

9. PERMANENT ENGINEERING REQUIREMENTS

For PROP-06:

- Preserve existing property valuation and ownership rules where compatible.
- Preserve contractual rights.
- Do not create or destroy economic resources.
- Preserve deterministic behavior.
- Preserve existing saves and support compatible migration of older save records.
- Investigate interactions with BIZ-04, INV-04, PROP-03, REG-02, and REG-05.
- Verify all affected systems against the exact integrated SHA.
- Update the audit register and development-state documentation.
- Record why each correction was necessary.

Do not merge into "main".

Do not publish packages or upload Steam builds.

Do not launch additional paid independent audits.

FINAL DIRECTION

A family owning multiple properties should be able to sell its estate and move away.

A family renting someone else's property should not be evicted merely because the landlord moves away.

A failed sale must never leave behind partially transferred ownership or lost money.

These rules should be implemented consistently throughout the migration system.

Complete the existing 12-correction integration first, provided its required verification gates genuinely pass.

Then advance LIFE-03 and LIFE-04 through their verification and development-branch integration.

Correct and thoroughly test PROP-06 using this directive.

Continue the established MP-05 security work without reopening approved gameplay decisions.

Report:

- Corrections actually merged.
- Features actually merged.
- Exact tested commit SHAs.
- Exact merge SHAs.
- Test checks passed and failed.
- Simulation results.
- Remaining engineering blockers.

Proceed with implementation, testing, and verified development-branch integration.