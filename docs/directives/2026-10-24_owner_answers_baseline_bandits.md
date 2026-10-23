# Owner answers, 2026-10-24: Build 19 baseline and bandit food (SIM-F4)

Answers given in the session to the questions on `docs/design/BUILD19_BASELINE_PROPOSAL.md` and SIM-F4. Saved verbatim.

- Baseline (B19-BASELINE): **"Approve (Recommended)"**: write it as the Build 19 baseline; Build 18's is kept as history. If
  the bandit answers below change behaviour, the change is measured and the baseline updated once more before release,
  without re-baselining per fix.
- Bandit food: **"Also lower coin minimum"**: health no longer blocks, and a bandit may buy as soon as they can afford one
  item of food (not 15 coins).
- Healing: **"Heal at camp (Recommended)"**: bandits heal by resting and sleeping at the camp, the same way villagers
  recover.
