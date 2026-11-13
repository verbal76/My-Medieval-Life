# Owner directive 2026-11-12 (received about 23:10 EST): MML Build 25 — Complete Owner Direction, November 12

Saved verbatim by the lead.

---

MML Build 25 — Complete Owner Direction, November 12

Priority 1: Extra Life Build 40

Finish the pending Windows smoke test and report the exact result.

Preserve Build 40 at commit a5a0b7c. Do not silently replace it or delay the private preview for unrelated Build 25 work.

Windows Hardware Playtest

Prepare a clear, step-by-step playtest checklist for me to follow when I launch Build 40.

The checklist must cover:

1. Launching the game and entering a world.
2. Walking, navigating around obstacles, and interacting with villagers.
3. Talking to villagers and using dialogue options.
4. Chopping trees and collecting wood.
5. Mining and gathering resources.
6. Equipping and using the sword, axe, and pickaxe.
7. Hunting deer, boar, and bear.
8. Observing whether animals face the attacker, flee naturally, or defend themselves without unnatural bouncing or sliding.
9. Harvesting animals and collecting loot.
10. Crafting and using inventory.
11. Visiting the reeve's job board and accepting work.
12. Buying, selling, eating, and checking money balances.
13. Saving, exiting, restarting, and continuing the same character.
14. Checking whether progress, inventory, equipment, and money survive reloads.
15. Checking audio, visual appearance, performance, and responsiveness.
16. Watching for excessive memory growth, long pauses, crashes, or script errors.

For each activity, distinguish between:

- Functionally working.
- Visually and mechanically believable.
- Broken or requiring improvement.

Provide a simple method for me to report problems, including what happened, what I expected, and how to reproduce it.

Animal Behavior — Future Build 25 Work

- Boars may charge and defend themselves when attacked, but should not always charge.
- Preserve believable flight and defensive responses.
- Keep current reaction timing provisionally until hardware playtesting.
- Struck livestock should flee naturally within their enclosures without passing through fences.
- Add deterministic regression coverage.

ND-29 — Firewood

- Approve deadwood gathering without an axe for ordinary homesteaders.
- Approve equivalent player gathering using existing interaction systems.
- Provisionally accept 60 minutes per log, one log per tree every four days, and a 40-tile gathering radius.
- Protect three reserved hearth logs from nonessential building consumption.
- Verify resource conservation, determinism, save/load persistence, and long-term sustainability.
- Keep ND-29 separate from Build 40 until simulation consequences are approved.

Android

Approve release exports for future Android builds while retaining the existing signing identity.

Verify installation, launch, saving, and update compatibility before distribution.

Do not publish or deploy.

INV-02

Provide per-store spoilage figures before requesting approval to activate the switch.

Finish the remaining 365-day simulations and investigate unexplained differences.

Kept Demo Worlds

Continue the previously approved implementation when a worker becomes available.

Project Governance

- Keep the 69-item integration tracker accurate.
- Preserve the simulation-baseline approval gate.
- Investigate unresolved findings rather than accepting them without evidence.
- Record exact commits, timestamps, tests, and results.
- Do not merge release candidates or publish to Steam or Google Play.
- Do not dispatch additional CI runs without authorization.

Reporting Priority

First, report the Windows smoke-test result and any critical Build 40 issues.

Second, provide my Windows hardware-playtest checklist and installation instructions.

Third, report progress on animal behavior, ND-29, INV-02, Android release exports, and kept demo worlds.

The objective is a playable, believable Windows demonstration for tomorrow's Extra Life stream—not a finished Steam release.
