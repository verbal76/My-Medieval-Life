# MML — Critical Clarification: Movement Stutter Investigation

Owner directive, 2026-11-13, received in the Build 25 lead session. Saved verbatim. It corrects the symptom
description in docs/directives/2026-11-13_movement_stutter_deep_investigation.md (which stays as written).

---

**MML — Critical Clarification: Movement Stutter Investigation**

The owner's description of the problem is:

**"Step, freeze, step, freeze, step, freeze. The whole game freezes momentarily and then catches up."**

This is NOT primarily a report of rubber-banding or the character being pulled backward.

Investigate repeated whole-game micro-freezes, frame-time spikes, simulation stalls, and uneven frame pacing.

Prioritize identifying operations that periodically block the main thread, including world simulation ticks, NPC updates, pathfinding, settlement processing, rendering synchronization, and scheduled background work.

Investigate the previously reported approximately 230 ms world-frame spikes and determine whether they are related.

Measure frame-time distributions, individual long frames, stall frequency, and the specific functions responsible.

Distinguish actual simulation stalls from rendering-only freezes, and establish whether the game catches up by processing accumulated work afterward.

Preserve the previous investigation requirements, but correct the symptom description throughout the records.

**The goal is consistently smooth movement without periodic freezing, not simply preventing position corrections.**

No speculative fixes, baseline changes, merges, CI runs, or releases until the cause is established.
