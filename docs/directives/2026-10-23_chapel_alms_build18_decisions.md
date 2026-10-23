# Owner directive, 2026-10-23: Build 18 owner decisions (chapel alms, deferrals, release gate)

Verbatim:

> MY MEDIEVAL LIFE — BUILD 18 OWNER DECISIONS
>
> The chapel audit has demonstrated a substantial circulation problem and identified an unimplemented portion of my previously approved Priest + alms design.
>
> CHAPEL-R2 — APPROVE OPTION A
>
> Implement the missing alms distribution so that offerings support the clergy and the remaining available funds are distributed to the poorest eligible households.
>
> This is completion of an approved design, not authorization for a new economic system.
>
> Requirements:
>
> 1. Preserve clergy wages and existing food-relief behavior.
> 2. Identify the existing household poverty/need indicators and use them rather than inventing a separate wealth classification system.
> 3. Distribute actual coins from the chapel fund to eligible households, maintaining strict conservation.
> 4. Prevent negative chapel balances and duplicate payments.
> 5. Respect existing offering and wage timing.
> 6. Preserve sufficient funds for existing clergy obligations using the narrowest rule consistent with the original design.
> 7. Do not introduce arbitrary new taxes, offering rates, economic multipliers, or unrelated redistribution.
> 8. If the original design does not specify an essential reserve or distribution rule, present the smallest implementation choice for my approval before proceeding.
>
> ECONOMIC VERIFICATION
>
> After implementing alms:
>
> - Verify offerings, clergy wages, alms, and chapel balances reconcile.
> - Verify households actually receive the coins.
> - Confirm deterministic behavior and no money creation or destruction.
> - Compare the chapel fund, manor treasury, employment, and household money against the existing baseline.
> - Confirm that remaining unemployment caused by fixed job capacity is not incorrectly attributed to the chapel.
> - Run the minimum sufficient targeted and long-run checks needed to validate the economic change.
>
> Do not alter offering rates unless I separately approve them.
>
> REG-CIRC-D1 — DEFER
>
> Document the settlement circulation concern, including Netherton's population loss and household cash decline.
>
> Do not implement a settlement economy redesign during Build 18.
>
> SET-D — DEFER
>
> Keep multigenerational settlement verification as an open item for a later build.
>
> Do not launch an extended simulation campaign now.
>
> OTHER DECISIONS
>
> - DP-17: Approved and complete.
> - DP-18: Retain the provisional +3 wage ceiling.
> - DP-19: Retain neutral 1.0 capability factors.
> - Chapel old-save corrections: Accept subject to existing compatibility checks.
>
> RELEASE GATE
>
> Once the approved alms implementation is verified, report the updated economic results and Build 18 candidate readiness.
>
> Prepare Android, Windows, and Linux candidate packages only after the remaining Build 18 gates are satisfied.
>
> No public publication without my approval.
>
> Apply RCA-01 and MSW-01. Avoid additional agents, unnecessary full-suite reruns, or unrelated economic changes.

## The owner's answers on the unspecified alms rules (requirement 8; 2026-10-23, verbatim choices)

- Reserve: **"Owed + one week"**: keep any wages already owed plus one week's wages (the time until the next service
  refills the fund), from the existing wages and weekly service only.
- Alms rule: **"Fill up to their reserve"**: on the service day, after wages, adults and elders whose coins are below their
  own necessity reserve (OD-19/PAR-02A) get coins up to that reserve, households with the largest shortfall first, until the
  alms money runs out; anything left stays in the fund.
