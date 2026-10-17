# Decision log

Newest first. **Owner** = decided by the owner. **Agent** = proposal or technical decision made by
an agent within its authority (CLAUDE.md, section 11). An agent proposal that needs approval stays
marked *Proposed* until the owner approves it.

| Date | Decision | By | Notes |
|---|---|---|---|
| 2026-10-17 | Animal breeding: one male and one female of a species reproduce as long as they are fed; babies show at half scale and switch to full scale at a set age | Owner | Owner message with the Cozy Farm pack. Open: the feeding rule, the litter size, the time between births, the growing age, and whether animals are livestock, decoration or huntable (asked, not yet answered) |
| 2026-10-17 | Living world: an interdependent production economy with real movement of goods and money; persistent NPCs with occupations, inventories and finances; persistent consequences of robbery and death; productive and criminal paths | Owner | `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §2 "established intent". Its other proposals stay open (U20). Review: `docs/LIVING_WORLD_ALIGNMENT.md` |
| 2026-10-17 | Adopt the simulation tier names Detailed / Abstract / Dormant | Agent | Aligns H §7 with the living-world document §11 |
| 2026-10-17 | The game's world is built on William Morris's *The Well at the World's End*; the novel's story is the world's history, not the player's quest | Owner | Master design directive §1, §15 |
| 2026-10-17 | The player is an ordinary inhabitant of an original village in an original county, **not the chosen one** | Owner | Master design directive §2 |
| 2026-10-17 | Magic is a learnable discipline (knowledge, proficiency, capacity), not a bloodline power; its scientific framing is GAME EXPANSION, never attributed to Morris | Owner | Directive §8; energy source and progression not yet decided (`docs/world/J_OPEN_DECISIONS.md` J-M1 to M4) |
| 2026-10-17 | Multiplayer: player-hosted worlds for about 3–4 players, no always-on central server; the world stops when the host stops | Owner | Directive §10; supersedes proposal P6 (offline single player) |
| 2026-10-17 | Working visual direction: 2D/2.5D isometric with 8-direction animated sprites | Owner | Directive §11; supersedes proposal P2 (top-down orthogonal). Asset implications are open (J-G4) |
| 2026-10-17 | Research classifications CANON / CANON-INFERRED / GAME EXPANSION / UNRESOLVED and geographic certainty Fixed / Constrained / Flexible / Original | Owner | Directive §3, §5 |
| 2026-10-17 | Research from the local novel text only; Project Gutenberg material excluded by recorded boundaries; at most one subagent, only with explicit owner approval | Owner | Source-access and token-budget corrections |
| 2026-10-17 | Game era: recommend Ralph's reign (E3) or generations later (E4) | Agent, *Proposed* | `docs/world/J_OPEN_DECISIONS.md` J-D1 |
| 2026-10-17 | Starting county: candidates C1 (west of Upmeads) and C4 (west of the Wood Perilous) recommended for discussion | Agent, *Proposed* | `docs/world/G_STARTING_COUNTY_CANDIDATES.md`; not final |
| 2026-10-17 | Store the generated world atlas in the save so dataset or solver updates never move places | Agent, *Proposed* | `docs/world/H_WORLD_GENERATOR_SPEC.md` §6 |
| 2026-10-17 | Engine: **Godot 4** recommended; libGDX is the alternative | Agent, *Proposed* | `docs/ARCHITECTURE.md` §1. Needs owner approval (U2) |
| 2026-10-17 | Primary platform: Android recommended if confirmed; desktop as the dev/CI target | Agent, *Proposed* | `docs/ARCHITECTURE.md` §2. Needs owner approval (U1) |
| 2026-10-17 | Generator RNG to move to PCG32 (generator v2) once an engine port is approved | Agent, *Proposed* | Needed for bit-identical generation across languages |
| 2026-10-17 | `CLAUDE.md` is the single project rules file; decisions are logged here | Agent | Required by the owner's master development prompt |
| 2026-10-17 | `build_manifest.py` ignores `CLAUDE.md`/`README.md`; a test guards the manifest's coverage | Agent | Fixes a defect: the manifest counted `CLAUDE.md` as an asset |
| 2026-10-17 | Building atlas keyed by the guide's names; non-guide sprites stay "unidentified" | Agent | No invented names |
| 2026-10-17 | Animation data marks unclear layouts `uncertain` instead of guessing | Agent | Owner rule: no invented frames |
| 2026-10-17 | Rivers run off the map edge, not into the sea | Agent | The tileset has no river-to-sand tiles; matches Shade's own samples |
| 2026-10-17 | Rivers, roads, bridges and animation/building data are the M0 scope; no gameplay | Owner | Asset-preparation assignment |
| 2026-10-17 | Procedural generation must be deterministic per seed | Owner | Asset-preparation assignment |
| 2026-10-17 | Engine, platform and mechanics need owner approval before implementation | Owner | Master development prompt |
| 2026-10-17 | Remove duplicate uploads only when byte-identical, never by name | Owner | First repository instruction |
