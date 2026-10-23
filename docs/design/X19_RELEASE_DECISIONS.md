# Expansion 19: the decisions left before the release gate (2026-10-23)

Owner directive `docs/directives/2026-10-23_x19_complete_release_scope.md` (register X19-SCOPE): Build 19 ships complete,
with personality and family reputation live and influencing decisions. This packet lists every Expansion 19 choice the
register still holds open, after removing everything already answered (SJD-Q01..Q14, X19-ASSAULT, X19-CRT12, X19-GUARD,
X19-HARMED, X19-Q-TIMING, X19-REGARD, X19-MISINFO and X19-STORY-LIFE in principle, FAM-SAC-01 and its four answers, the
approved 10% / 5% / 12% friendship bonuses, the 30% stubbornness potential, the one-year minimum for serious grievances).

**Calendar used for every duration below:** a game year is 8 game days (2 per season); a game day is 12 real minutes. One
calendar week is therefore about 3.7 game hours, "several weeks" about one game day, and a year 8 game days. Every rate is
deterministic (seeded by the permanent person id, never a roll per decision unless stated).

The mechanisms already exist on `wip/expansion19-preparation` with every number at a placeholder (`judgment.json`
sections "traits" and "bonds"); answering these sets the numbers and switches the layers on. No new architecture.

## A. Numbers already proposed (each had a recommendation in the 2026-10-23 packet)

| Id | Recommendation | In play |
|---|---|---|
| X19-DECAY | Ordinary deeds fade with a half-life of 2 game years (16 game days); murder and assault never fade | a slight or an unfair price is mostly forgotten after a few years; a killing never is |
| X19-GOSSIP-FLOOR | A story passes between strangers half the time, certainly between close friends | news travels mostly through friends |
| X19-RUNNERUP | A close second (within 2 points of the best) is chosen 15% of the time | villagers are not perfectly predictable |
| X19-TRUST-RATES | Trust starts at a quarter of liking; fair deal +4, cheat or false accusation −20, a rumour borne out +4, shown false −15; trust does not fade | trust is slow to build, quick to lose |
| X19-PERSONALITY | Temperaments differ by up to 30%; being wronged lowers tolerance 4% per severity point, being helped raises regard for opinion 3% per point, at most 25% either way | people differ, and hard lives harden them |
| X19-EVENT-Q | (1) a guard killing an attacker is not a killing; (2) first meetings are not recorded as facts; (3) a late repayment is a fair deal with half the trust gain; (4) self-defence: **recommend now in Build 19** (an attack answered within the same fight is not judged as an attack) since the scope is complete | guards and defenders are not branded killers |
| Tolerance | The personality formula replaces (does not add to) today's tolerance step for the same event | one owner of tolerance change |

## B. Personality evolution (X19-PERS-FORMULA, X19-TRAIT-DIST)

| Part | Recommendation |
|---|---|
| Starting traits | Tolerance: each person ±30% around the village norm (A). Stubbornness: the approved 30% start between 20% and 60%; the other 70% start at 0 |
| Drift | Each firsthand provocation pulls tolerance down and stubbornness up by 2% per severity point; each help pulls back by the same |
| Frequency | Each earlier experience of the same kind within the last game year adds a quarter to the pull, at most doubling it |
| Duration | Ongoing hardship (hunger, debt, a feud) adds 10% a day it lasts, at most 50% |
| Soft limit | The further a trait is from where the person started, the less a pull works: falling evenly to a fifth of its force at 40% away, never to zero (no wall) |
| Recovery and growth | Positive experience pulls a trait back at full rate; past the person's origin it keeps going at half rate (growth beyond the original) |
| Practical wisdom | A costly mistake teaches 2% per point of cost; each repeat within a game year adds half again, at most three repeats; a quarter of what is learnt carries to every situation; wisdom tops out at 50% and reduces how much stubbornness weighs in a choice by that share |
| Anger | A provocation sets anger at 10% per severity point, fading evenly over one game day ("several weeks"); a reminder (meeting the offender, hearing the story again) brings back a quarter of the first peak, never above half of it |
| Stubborn override | Anger at or above half sets the stubborn override for its remaining time: the person refuses the offender and repeats their own last choice even when a better one exists |

**Stubbornness in a decision** (the open "what it does"): a stubborn person adds a penalty to every option that means
dealing with someone they resent or giving up a choice they already made, scaled by stubbornness × (1 − wisdom). A
**costly mistake** is a choice whose cost the game already measures afterwards: a meal missed, coins lost, a purchase
refused, an injury, while a better recorded alternative existed. A **reminder** is meeting the person the grievance is
about, or hearing the story retold.

## C. Family reputation (X19-SPILL-REACH, X19-REP-TRANSMIT, X19-BOND-LIMITS)

| Part | Recommendation |
|---|---|
| Reach of good name | Parents and grandparents: a descendant is seen through what the observer knows of them (full weight for parents, half for grandparents) |
| Reach of spillover | First degree only (parents, children, siblings, spouse) at the approved small share (30% of the relative's standing, negative side only); no cousins or in-laws |
| Transmission | The impression is the sum of the observer's own remembered judgments of those relatives (no new store); stories fade with X19-DECAY, permanent deeds stay; each personal dealing with the descendant replaces a tenth of the inherited impression |
| Limit | An inherited impression never weighs more than a quarter of the strongest personal judgment, and spillover alone can never make someone refuse a deal or aid (it only colours) |

**Owner answer and clarification (2026-10-23):** wider reach, including cousins down to second cousins, with weights
falling by relationship distance. Provisional starting values (not owner-selected, tunable): spillover 30% for the first
ring (parents, children, siblings, spouse), 15% for the second (grandparents, grandchildren, aunts, uncles, nieces,
nephews, in-laws), 7.5% for first cousins, 3.75% for second cousins; a good name from ancestors and kin at the same falling
weights. Inherited reputation stays separate from direct, relationship-weighted reactions to witnessed deeds, and can
never cause a refusal on its own (`docs/directives/2026-10-23_owner_clarifications_famrep_simf4.md`).

## D. Lies, family stories, explainability

| Id | Recommendation |
|---|---|
| X19-MISINFO (how often) | Only someone holding serious resentment or a rivalry against the subject may lie, at most one invented story per liar per game year, 5% of the meetings where they would gossip about that person; a lie is proven false when a guard's report or a firsthand witness contradicts it; only those who learn it correct their judgment, and the liar loses 15 trust with them (A) |
| X19-STORY-LIFE (how) | Parents pass permanent deeds (murder, assault, betrayal) and serious good deeds to their children as family stories when the child comes of age and at home at the gossip rate; ordinary deeds fade with X19-DECAY and are not passed on |
| XEXPL-D1 | In-world explanation only in Build 19 (dialogue, rumours, notices); the shared record keeps a panel possible later |

## What happens after the answers

1. Set the numbers in `judgment.json`, wire the layers live, turn the judgment switch on by default for Build 19.
2. Merge Expansion 19 with the identity foundation, the REC-F1 and SIM-F9 fixes, FAM-SAC-01 and the recorder (off in
   public builds); targeted integration tests; combined determinism check on both seeds; one proposed baseline.
3. Present Build 19 for release authorization (no publication).
