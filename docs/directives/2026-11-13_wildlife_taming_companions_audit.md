# MML — Wildlife Taming and Animal Companions: Feature Audit

Owner directive, 2026-11-13, received in the Build 25 lead session. Saved verbatim.

---

MML — Wildlife Taming and Animal Companions: Feature Audit
I previously discussed a feature allowing players to offer food to wild animals, particularly foxes and wolves, potentially earning their trust until they become companions.
These companions would be able to follow the player on journeys or missions and provide assistance.
Before starting development:

1. Search the requirements register, expansion plans, decision records, existing branches, and game code for wildlife taming, feeding, bonding, pets, followers, and animal companions.
2. Identify which species were originally intended to be eligible.
3. Determine whether any portion is implemented, partially implemented, planned, or missing.
4. Identify any existing systems for animal feeding, trust, following, combat assistance, ownership, and persistence through save/load.
5. Check for conflicts with the current boar, wolf, bear, and hunting-AI work.
6. Preserve any previously approved design decisions. Do not invent missing requirements.
7. Report the feature's exact status, relevant files, and remaining implementation work.

Do not interfere with the boar worker, ND-29, or Build 40.
Do not merge, dispatch CI, package, or release.
Return the audit first so we can determine what remains to be implemented.
