# Owner directive, 2026-11-03 (about 16:20 EST): Build 25 Revision 1, integration, water systems, regression protection and flight recorder

Saved verbatim. Register: B25R1-017. Amends the approved B25R1 scope (B25R1-Q3 water, B25R1-015, B25R1-016); not a new expansion.

---

MY MEDIEVAL LIFE — BUILD 25 REVISION 1

Integration, Water Systems, Regression Protection, and Flight Recorder Directive

Continue the current B25R1 development and integration work. This is an amendment to the existing approved scope, not a new expansion or permission to restart completed work.

Do not interrupt active tests, duplicate existing work, or create another owner-approval loop.

1. Travelers and roads integration

The travelers branch has been merged into the B25R1 integration branch. Confirm its changes remain intact as the roads, map, and homesteading work are integrated.

Verify that:

- Travelers are real, persistent NPCs drawn from existing populations.
- Travel uses actual world routes, roads, trails, and bridges.
- Travelers consume real resources and participate in the existing economy.
- Road wear, traffic-driven path formation, repair, and overgrowth remain functional.
- All travel and settlement changes survive saving and loading.
- No NPCs, money, inventory, or resources are artificially created or duplicated.

Reuse existing passing test evidence where applicable.

2. Credits regression — diagnose before correcting

The roads merge reportedly broke a credits test.

Determine whether this is:

1. A legitimate regression affecting the credits screen or its data.
2. An outdated test expectation.
3. A merge conflict or unrelated test infrastructure problem.

Preserve all existing credits and attribution, including licensed asset acknowledgments.

Fix the underlying issue rather than weakening or deleting the test.

Run the narrowly relevant credits tests, then rely on the full suite already in progress wherever its evidence remains valid.

3. Rivers, streams, waterfalls, and bridges

Implement the approved countryside water features as part of B25R1.

Use the existing Miniworld and Forgotten Memories assets where their licenses and visual compatibility permit.

The screenshots supplied by the owner are visual references, not assets to copy.

Required presentation:

- Naturally winding streams and rivers.
- Uneven grassy banks and shoreline transitions.
- Rocks, shallows, and appropriate water-edge details.
- Animated flowing water.
- Waterfalls at genuine elevation drops, with pools below.
- Plank bridges on trails and appropriate unpaved routes.
- Stone bridges on established stone roads.
- Visual consistency with the existing character scale, terrain, and 16×16 art language.

Do not place waterfalls randomly on flat terrain or bridges where no actual crossing exists.

Capture representative screenshots showing the player character beside streams, bridges, and waterfalls. Evaluate the result at normal gameplay zoom, not just enlarged pixel-art previews.

4. Water must be a real world system

Do not implement water solely as a decorative map overlay.

Integrate it with the existing world architecture so that:

- Streams and rivers have persistent locations and connected courses.
- Flow direction follows terrain elevation where applicable.
- Waterways influence pathfinding and require valid crossings.
- Bridges are traversable world structures rather than visual-only sprites.
- Homesteads can obtain water from accessible streams or functioning wells.
- Wells and water access follow existing resource, construction, and persistence rules.
- Wilderness households and outlaw communities use the same underlying water-access system.
- Save/load and deterministic generation preserve water features and crossings.

Prepare clean extension points for the planned future weather, rain, flooding, and seasonal systems.

Do not implement the entire future weather expansion now. Build the underlying water architecture correctly so those features can be added without replacing it.

5. Existing-world compatibility

Preserve the approved policy that existing saves retain their established maps.

Do not silently regenerate terrain or place new waterways through existing buildings, roads, or settlements.

Ensure existing worlds remain playable, with functioning wells or other already-approved water sources where waterways are absent.

Verify compatibility through targeted save/load and migration tests.

6. Homesteading and outlaw settlement integration

Confirm that the water and road systems support both lawful wilderness homesteads and persistent outlaw communities.

Settlement decisions must account for practical access to water, traversable terrain, resources, and existing economic systems.

Do not artificially spawn residents, equipment, food, or building materials to make settlements work.

Preserve individual NPC identities, households, histories, skills, possessions, and family relationships.

7. Flight recorder and long simulation

Maintain the previously approved 365-day flight recorder requirements.

Record meaningful water-related settlement and travel events, including:

- Settlement water-source selection and availability.
- Failed settlement attempts caused by inaccessible water or terrain.
- Bridge construction, use, and relevant travel failures.
- Travel route choices involving crossings.
- Water-related survival or settlement outcomes where supported by actual gameplay systems.

Use stable entity identifiers and preserve deterministic replay.

Do not invent simulated outcomes merely to populate charts.

The final 365-day campaign must run against the completed, integrated B25R1 source. Reuse existing green tests and avoid unnecessary duplicate campaigns.

8. Integration and validation discipline

Continue parallel development where workers can operate safely without conflicting edits.

For each completed workstream:

1. Confirm its exact source commit.
2. Merge into the B25R1 integration branch.
3. Resolve genuine integration conflicts.
4. Run only newly necessary focused tests.
5. Preserve existing valid CI evidence.
6. Update the recovery index, decision register, and implementation records.

After the complete feature set is integrated, run the appropriate final validation on the exact integrated SHA.

Do not call B25R1 complete while an approved feature is missing, disabled, deferred, or merely represented by a placeholder.

9. Reporting and autonomy

Proceed with implementation and routine merges under existing owner authorization.

Do not stop for decisions already made.

Report significant integration failures, genuine architectural conflicts, or choices that materially alter the approved game design.

When reporting progress, distinguish clearly between:

- Implemented and merged.
- Implemented but not merged.
- Under test.
- Validated.
- Still outstanding.

Keep all reports and decisions in GitHub so a future Claude or ChatGPT session can reconstruct the work without another manual handoff.

Objective: Deliver B25R1 as one coherent, fully integrated game build, with functioning travelers, roads, waterways, homesteading, outlaw settlements, preserved credits, compatible saves, and verifiable long-term simulation evidence.

Continue the work already underway. Do not restart it.
