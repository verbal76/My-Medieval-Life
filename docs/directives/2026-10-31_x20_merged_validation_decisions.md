# Owner decisions 2026-10-31: merged year-long validation, go-between purchasing and judgment migration

Verbatim, as received in the coordinating session on 2026-10-31. Register: X20-MERGED-VALIDATION, X20-GO-BETWEEN, X20-JUDG-MIGRATION.

---

Claude, here are my decisions for Expansion 20.

1. APPROVED — Merged year-long validation.

After integrating Workers D, F, and G, run the two standard 365-day simulations (seeds 1 and 2, normal settings) plus one 365-day economy-enabled simulation.

This approval covers three year-long runs total. Do not run an additional historical bandit baseline.

Use the merged Expansion 20 commit, record its exact SHA, and reuse previously passing test evidence wherever the source remains unchanged.

The validation must specifically cover:

- Corrected bandit intelligence and villager casualty rates.
- Bandit deaths during robberies versus deaths during retreat, travel, and camp recovery.
- Bandit retreat, rescue, and combat decisions.
- Robbery and attempted-robbery incident counting.
- Judgment-driven buying, hiring, contracts, and seller selection.
- Judgment memory decay and save-size behavior.
- Blacksmith necessity-versus-dislike behavior.
- Tool repairs and rentals, including economy integrity.
- No unexpected coin or item creation or destruction.
- No new script errors, regressions, or save/load failures.

Report results separately for each run and compare them against the available earlier evidence. Do not conceal regressions behind averages.

2. DEFER — Go-between purchasing.

Do not implement purchasing through an intermediary in Expansion 20. Preserve the concept for later design and approval.

3. DEFER — Judgment-driven migration.

Do not introduce strong dislike as a fifth independent migration reason. Keep the four previously approved migration reasons unchanged. Judgment may influence existing decisions only where already authorized.

Integration instructions

Continue integrating the three completed worker branches into "wip/expansion20", resolving conflicts carefully and running only the relevant integration tests.

Once the merge is complete, establish the updated 30-day baseline once, then perform the approved year-long validation.

Keep the economy disabled by default. Preserve Build 24 unchanged.

Do not package, release, or publish anything.

After validation, provide the consolidated results, identify remaining defects and risks, and stop for my review before proceeding to another expansion or release.
