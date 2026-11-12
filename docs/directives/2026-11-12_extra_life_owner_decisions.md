# Owner decisions, 2026-11-12 (Build 25 completion and Extra Life release directive), answered in the lead session

Recorded verbatim from the owner's answers to the lead's questions (AskUserQuestion). Never edited.

1. **F015/P99 merge.** Question: may wip/b25-f015-p99 (3d515d6) be integrated into the Build 25 candidate, after its own full Tests and gate? (The births investigation, docs/audits/2026-11-12_F015_BIRTHS.md, found no birth-rule regression.) Answer: **"Approve (Recommended)"**: integrate after its own full Tests + gate on top of the current candidate; any unexplained new finding stops it.
2. **REG-03 and REG-08 (courier dead ends).** Answer: **"Estate + timeout (Rec.)"**. REG-03: a dead sender's proceeds go to their heir or estate by the existing death rule, as any of their coins. REG-08: a delivery not dispatched within a set time (e.g. 7 days) ends; the goods return to the sender (or their estate) and the unearned fee is refunded.
3. **BIZ-07 (a player hiring a venture's hand).** Answer: **"Refuse while a hand (Rec.)"**. The player cannot employ someone while they are a venture's hand; the offer is refused with a reason (they work for the smithy). This is the same rule BIZ-05 applied to the venture's own hiring.
4. **EMP-06 (day labour for the unemployed).** Answer: **"Allow day labour (Rec.)"**. The unemployed may take open manor day labour when their household is short of food, like labourers do. It changes simulation outcomes, so it gets the full gate.
5. **EMP-04, EMP-05, TRD-03, NPC-05, REG-01 (not reproducible).** Answer: **"Close with guard tests (Rec.)"**. Integrate the five guard tests into CI and record each as resolved: not reproducible, guarded, with the tested conditions documented. Reopen if a guard ever fails.

6. **ND-23 (manor relief to the outlaw band).** Answer: **"Exclude the band (Rec.)"**. The manor's relief goes only to the village's households; the outlaw band (and its clan children) fend for themselves, as outlaws. It changes simulation outcomes slightly; full gate before the final build.

7. **MP-07 family links (asked about the MP-PLAYER-FAMILY versus MP-07 possible conflict, DCR-01).** The owner's answer, verbatim:

> MP-07 OWNER DECISION — OPTION 1, WITH PRIVACY BOUNDARIES
>
> Marriage, spouses, children, and parents are public family relationships in MML multiplayer.
>
> These relationships may appear in household, family, and genealogy views because they are part of the village's social structure.
>
> However:
>
> 1. Public family relationships do not grant access to private information.
> 2. Debts, crimes, personal knowledge, private notes, hidden relationships, inventories, and other protected records remain private.
> 3. Family membership does not automatically authorize another player to access a household's private records.
> 4. Secret or undisclosed relationships must not become public merely because the underlying family system knows about them.
> 5. Only expose relationships that are established as publicly known within the game's existing systems. Do not invent new visibility or discovery mechanics without approval.
> 6. Enforce privacy on the server and in multiplayer snapshots, not merely by hiding UI elements.
>
> Preserve existing public family and genealogy functionality while closing unauthorized private-record exposure.
>
> Test multiplayer visibility for the owner, unrelated guests, household members, and other players. Document precisely which relationship fields remain public and which records are withheld.
>
> Proceed with MP-07 using this decision.
