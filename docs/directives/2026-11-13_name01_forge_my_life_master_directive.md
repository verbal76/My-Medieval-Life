# MASTER DIRECTIVE — NAME-01: FORGE MY LIFE

Owner directive, 2026-11-13, received in the Build 25 lead session. Saved verbatim.

---

MASTER DIRECTIVE — NAME-01: FORGE MY LIFE
Project: My Medieval Life → Forge My Life
Studio: Hot Attic Games LLC
Steam App ID: 5615690
Directive: 2026-11-13
Authorization: Implement and locally verify. Do not merge, trigger CI, package, or publish without approval.
1. Official Game Name
The official player-facing name is now:
Forge My Life
The acronym FML may be used internally, but the game should be marketed professionally as Forge My Life.
Replace the previous player-facing title throughout the game and active release materials.
Retain Hot Attic Games LLC branding.
2. Existing Saves — Owner Decision
I am the only current player. There are no external players or customer saves to preserve.
Therefore:

* Rename the internal save directory to match Forge My Life.
* Update save export filenames and file-type labels.
* Update relevant project settings and paths.
* Do not implement legacy save-directory migration or backward-compatibility code solely for the rename.
* Preserve working save/load functionality.
* Test new saves, loading, exporting, importing, and restarting the game.

No unnecessary compatibility infrastructure should remain simply to support the old working title.
3. Android Identity
Keep the existing Android application ID:
`com.hotatticgames.mymedievallife.dev`
This is an internal application identifier, not the player-facing game name.
Changing it would create an unnecessary application identity change.
Update the visible application label to Forge My Life where appropriate.
Verify Android launch configuration and packaging remain valid.
4. Repository and Development Infrastructure
Keep the existing repository name unchanged.
Do not rename internal source packages, namespaces, stable identifiers, or automation references unless a specific change is required for correct player-facing branding.
Avoid unnecessary disruption to development infrastructure.
Historical Git commits, directives, test records, and completed development documentation should remain intact.
Update current instructions, active documentation, and release-related references where necessary.
5. Player-Facing Rename Scope
Audit and update:

* Game window and taskbar title.
* Main menu and title screen.
* Credits and studio attribution.
* Android application display label.
* Save export filenames and file-type descriptions.
* Current game descriptions and metadata.
* Export presets.
* Build artifact filenames.
* Active release workflows and package naming.
* Current documentation used to prepare releases.
* Any other visible references to My Medieval Life or its previous working titles.

Search the complete project for remaining old-name references.
Classify each occurrence as player-facing, active infrastructure, internal identifier, or historical record.
Do not blindly replace every occurrence.
6. Steam Integration
Forge My Life is a newly registered Steam application.
Correct Steam App ID: 5615690
The previously identified number 1442556 is a store item ID, not the game App ID.
Audit Steam configuration, build scripts, upload manifests, depot configuration, and release workflows.
Verify that Forge My Life uses the correct application identity.
Do not invent depot IDs or package IDs. Obtain their actual values from verified Steamworks configuration.
Do not copy Upwardly's Steam application or depot identifiers.
Do not upload or publish anything to Steam without explicit authorization.
7. Branch Isolation
Build 40 remains preserved at commit `a5a0b7c`.
Implement NAME-01 on its own dedicated branch.
Do not mix the rename with unrelated gameplay, economy, animal, multiplayer, performance, or simulation changes.
Keep the changes focused and reviewable.
Do not merge into Build 40 or any active integration branch without authorization.
8. Mandatory Parallelization
Parallelization remains a mandatory development practice wherever independent tasks can safely run concurrently.
Divide the rename into independent workstreams where practical:
Workstream A — Game presentation: title screen, credits, window title, application labels.
Workstream B — Saves and settings: save directory, filenames, export/import, persistence tests.
Workstream C — Packaging and Steam: export presets, artifact names, release scripts, Steam configuration audit.
Workstream D — Documentation and verification: active documentation, reference audit, remaining-name inventory, regression checks.
Coordinate ownership of shared files to prevent conflicting edits.
Tasks with dependencies must run in the correct sequence.
Do not run performance measurements alongside resource-intensive tasks that would contaminate results.
Parallelization does not authorize additional CI cycles or uncontrolled merges.
9. Testing and Verification
Perform relevant local verification before reporting completion.
Required checks:

1. Game launches displaying Forge My Life.
2. Window and taskbar use the correct title.
3. Credits and studio branding are correct.
4. New save files are created in the intended directory.
5. Saved games load correctly after restarting.
6. Exported saves use the new filename convention.
7. Imported saves load correctly.
8. Android application identity remains unchanged.
9. Export presets and package naming are correct.
10. Steam App ID is verified.
11. Gameplay behavior and simulation remain unchanged.
12. Deterministic fingerprints match the approved reference.

Do not automatically re-record or update baselines.
Investigate any mismatch before proposing changes.
If a check cannot be performed locally, identify it as unverified rather than claiming success.
10. Development Governance
The following rules remain mandatory:

* Investigate unresolved issues rather than dismissing them.
* Separate confirmed findings from assumptions.
* Preserve evidence for technical decisions.
* Do not alter gameplay mechanics as part of a naming change.
* Do not change unrelated systems.
* Do not automatically approve your own integration.
* Do not start unnecessary GitHub Actions workflows.
* Do not package or publish without authorization.
* Do not expose repository links in player-facing materials.
* Record timestamps and commit identifiers in development reports.
* Report progress using completed and outstanding item counts rather than percentages.

11. Completion Report
When the implementation and local verification are finished, provide:

1. The branch name and commit SHA.
2. Number of files changed, organized by workstream.
3. Player-facing changes completed.
4. Save/load/export/import test results.
5. Android identity verification.
6. Steam configuration findings.
7. Deterministic fingerprint comparison.
8. Remaining references to the old name, categorized by reason for retention.
9. Any unresolved issues or unverified checks.
10. Explicit confirmation that no CI, packaging, publishing, or unauthorized merge occurred.

Final instruction: Implement the complete Forge My Life rename in isolation, verify everything practical locally, and stop at the approval gate.
Do not ask for approval again for decisions already authorized here. Ask only when a genuinely new decision is required.
