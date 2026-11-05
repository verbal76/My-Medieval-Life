# B25-BIZ-TENANT-Q: a tenant may build a standalone workshop on bought land (Option B)

## Identification
- Decision ID: B25-BIZ-TENANT-Q (register, kind `decision`; related B25-BIZ-D5)
- Date: question raised 2026-11-01/02; owner answer 2026-11-02
- Project / build: My Medieval Life, Build 25 (integration branch `wip/expansion20`)
- Decided by: owner. The question and its options were written by the lead agent.
- Source of authority: [`docs/directives/2026-11-02_overnight_autonomous_development_directive.md`](../directives/2026-11-02_overnight_autonomous_development_directive.md),
  section 1, and the register's `owner_answer`.
- Status: disposition APPROVED (copied 2026-11-02; the register is authoritative)
- Supersedes: the lead's interim rule in `f8f9cac`. Under it, tenants could reopen or buy a workshop but not build one.

## Original problem
- **The year-long runs.** Actions [41362329381](https://github.com/verbal76/My-Medieval-Life/actions/runs/41362329381) ran
  on `908a17e`, normal settings, seeds 1 and 2. No villager founded, bought, hired or expanded a business all year. At day
  365 only 0-1 eligible villagers owned their house, because most families live in manor cottages.
  ([`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md), entry "Year-long business run 41362329381".)
- **Two owner rules appeared to conflict.**
  - The owner's rule of 2026-10-18 says "a house first, then workshops", and `Construction.may_build` refused a tenant.
  - Decision 5 A of 2026-11-01 says "a person with sufficient resources may also establish a standalone workshop elsewhere on
    legally acquired land"
    ([`docs/directives/2026-11-01_business_ownership_employment_final_decisions.md`](../directives/2026-11-01_business_ownership_employment_final_decisions.md)).
- **The lead's first attempt.** The lead tried letting tenants build. `Construction.may_build` refused it under the house-first
  rule, so the lead undid the change and raised this question.

## Owner's direction (quoted)
> OPTION B IS APPROVED.
>
> A villager who rents their residence may establish a standalone workshop on legally purchased land.
>
> This is consistent with my existing November 1 Decision 5.
>
> A person does not need to own their residence to own a business.

> My original "a house first, then workshops" rule means a person must have legitimate, suitable housing before pursuing nonessential commercial construction. [...] A legitimately rented home also satisfies the housing requirement for separately owned standalone commercial property.
>
> A tenant does not thereby gain permission to construct additions to a landlord's house.

> This is an additional business-ownership option, not a replacement system.

(Overnight directive, sections 1 and 2.)

## Interpretation
The lead implemented the answer as follows:
- `Construction.may_build` accepts a home held owned or rented, for a standalone workshop.
- `module_refusal` is unchanged, so a tenant never builds onto the landlord's house.
- `Ventures.refusal`: an owner adds the workshop to the house first; a tenant builds standalone on bought ground.

## Reasoning and alternatives
- **Options put to the owner** (register question text, written by the lead):
  - A: keep house-first. Tenants may only buy or reopen a workshop, as under `f8f9cac`.
  - B: a tenant may build a standalone workshop on purchased land. House-first still applies to workshops attached to a
    house. The lead recommended this one.
  - C: tenants may also rent premises. This was not built.
- **The owner's recorded reason for B:** it is consistent with Decision 5, and "a person does not need to own their
  residence to own a business". The owner also explained what the house-first rule was for: suitable housing before
  nonessential construction, not ownership.
- **Why A and C were not chosen:** not stated beyond the above (UNKNOWN).
- **The owner warned against weakening eligibility.** The owner said not to weaken business eligibility until the causal
  chain is understood: "Do not automatically weaken eligibility requirements until we understand the complete causal chain"
  (section 4). Option B is therefore not presented as the fix for the zero-business result.

## Consequences
- Systems affected: construction permissions, ventures (business founding), property and tenancy, and the wiki pages for
  skills and property.
- Must be preserved, by the owner's explicit list in section 2:
  - home-attached workshops, home storefronts and shops;
  - buying and selling businesses;
  - multiple businesses per owner, inheritance and bankruptcy;
  - no arbitrary ownership limit;
  - player and NPC parity.
- The owner asked for regression tests showing every existing business-establishment path still works.
- Later finding: the economic investigation (`d6ab686`) showed that no household reached the decision at all. Founding was
  refused earlier, on demand: benches 2-20% busy against the 0.35 the rule needs. The follow-up policy questions are
  B25-ECON-P1..P5 in the register.

## Implementation
- `3c7e45b` on `wip/expansion20`. Status: INTEGRATED, TESTED (local).
- Tests: business_founding 66, business_ownership 165, business 160, conservation 8 and wiki_test, all 0 failures; run_tests
  3602 and start_test 523 steps, 0 failures. ([`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md), entry
  "B25-BIZ-TENANT-Q answered".)
- Not shown yet: villagers actually founding businesses over a year.

## When to reconsider
The owner set no trigger (UNKNOWN). Any change to the house-first or tenancy rules needs the owner, because it is an
owner-approved gameplay rule.
