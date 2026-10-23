# Owner decisions, 2026-10-23: ID-D2 and succession

Saved verbatim. Answers register ID-D2.

---

Owner decisions — ID-D2 and succession

Approve ID-D2 Option B, using a separate, collision-free ID allocation range for settlement residents and player characters beginning at 1,000,000, while preserving existing village IDs and Build 18 behavior wherever possible.

Permanent IDs must remain globally unique, never reused, and unchanged through migration, death, succession, and save/load. Verify the allocation strategy against existing saves and future population growth.

Do not blindly replace the determinism baseline. First verify that remaining divergences are explained by approved permanent-identity behavior. Record the exact first divergence, its cause, and the new baseline for both test seeds. Investigate any unrelated divergence before approval of that baseline.

Approve retaining the heir child's permanent record and the resulting legitimate family relationships, including a grandmother caring for orphaned grandchildren. Preserve the existing Build 18 transfer of village regard to the heir.

Continue the recorder work independently. Once the identity changes are verified, integrate them into the recorder branch with targeted tests for stable person references, migration, succession, save/load, and determinism.

Resolve the identified "world.gd" conflicts deliberately. Do not merge the Expansion 19, 20, and 21 gameplay branches merely because the textual conflicts are limited to one file. Check their overlapping logic and preserve feature flags.

Keep Expansion 19's playable release as the priority. Reuse passing test evidence and avoid redundant full-suite campaigns.

Do not publish or merge into the release baseline without further authorization.
