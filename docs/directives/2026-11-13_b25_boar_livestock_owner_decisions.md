# MML Build 25 — Boar and Livestock Owner Decisions

Owner directive, 2026-11-13, received in the Build 25 lead session. Saved verbatim.

---

MML Build 25 — Boar and Livestock Owner Decisions

1. Charge probabilities: Approve the current 30% healthy, 60% badly hurt, and 75% cornered probabilities for hardware playtesting. Do not rebalance yet.
2. Combat: Retain 5 damage per gore, 1.3-second attack intervals, and the existing 8-second / 8-tile disengagement conditions pending hardware testing.
3. Self-defense: Apply the existing wolf/bear self-defense rules to boars. Killing a boar that qualifies as an active threat under those rules should count as self-defense. Do not create a loophole where deliberately provoking an animal automatically grants legal immunity.
4. Add deterministic tests for boar self-defense, including qualifying attacks, nonqualifying attacks, and save/load consistency where applicable.
5. Keep all changes on `wip/b25-animal-boar-livestock`. Do not merge into Build 40 or alter the existing preview packages.
6. Continue the existing verification requirements. Report any unexpected behavioral or simulation differences before changing baselines.

No additional CI runs, packaging, or releases are authorized by these decisions.
