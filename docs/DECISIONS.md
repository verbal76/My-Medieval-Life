# Decision log

Newest first. **Owner** = decided by the owner. **Agent** = proposal or technical decision made by
an agent within its authority (CLAUDE.md, section 11). An agent proposal that needs approval stays
marked *Proposed* until the owner approves it.

| Date | Decision | By | Notes |
|---|---|---|---|
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
