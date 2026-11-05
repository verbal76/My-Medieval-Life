# Owner decision, 2026-11-05: B25R1 aerial maps for tonight's playtest

Saved as received. Register: B25R1-025.

---

B25R1 — Add Aerial Maps to Tonight's Playtest

Owner decision: Approved for B25R1 tonight.

Replace the simplified in-game village and region map presentation with beautiful, detailed aerial views of the actual procedurally generated world.

We already have a working stitched flyover capture system ("game/tests/drone_shot.gd"). Reuse its proven camera and capture techniques where practical.

1. Region map
- Display the entire generated region from overhead.
- Show the actual terrain, forests, rivers, roads, settlements, and landmarks.
- Add readable labels for villages, hamlets, and significant named landmarks.
- Display the player's current position.
- Support zooming and panning.
- Preserve the existing region-map controls and functionality.

2. Village maps
- Provide detailed overhead views of individual settlements.
- Show actual houses, streets, farms, wells, businesses, bridges, walls, and surrounding terrain.
- Add useful labels for important buildings and locations.
- Show the player's position when applicable.
- Support zooming and panning.

Labels should remain readable without covering the scenery excessively.

3. Technical requirements
These must be real maps of the player's generated world, not generic illustrations.
- Work with different world seeds.
- Reflect the correct world-generator version, including the upcoming generation 7 changes.
- Do not use seed 1's flyover as a universal map.
- Do not run the expensive development flyover process every time the player opens a map.
- Investigate efficient generation, caching, and image resolution so opening maps is responsive.
- Avoid large memory or loading-time increases, particularly on Android.
- Preserve existing map navigation and gameplay behavior.
- Do not change world terrain or road tiles merely to improve map appearance.

4. Validation
Test region and village maps against the actual generated world.
Verify labels, player position, map alignment, zooming, panning, and opening/closing.
Test multiple seeds, including seed 1 and seed 11.
Measure generation time, memory use, and map-opening performance. Investigate any unacceptable results before packaging.

5. Integration and tonight's package
Develop this in a separate worktree so it doesn't interfere with the ongoing economy, multiplayer, or Wood Perilous work.
Record this owner-approved scope addition and the reasons behind it in the decision register.
Integrate the verified implementation into "wip/b25r1", then include it in final validation and tonight's private playtest packages.

Priority: A functioning, attractive, accurate aerial map system for tonight. Avoid unrelated feature expansion.

Report any genuine technical blockers promptly, with evidence and options rather than silently substituting a simplified map.
