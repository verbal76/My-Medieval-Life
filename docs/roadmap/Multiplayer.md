# Multiplayer (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/Multiplayer.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

Multiplayer — Player-Hosted Persistent Worlds
My Medieval Life | Implementation-ready design baseline | 21 October 2026
DOCUMENT STATUS: Consolidates approved requirements with explicitly labeled proposed implementation stages. Proposed numbering for 21–23 is not yet an owner-approved register assignment.
Governing constraints
Owner-approved directives and existing repository rules take precedence over proposed engineering detail. The world remains finite and autonomous. Every item, coin, event, death, relationship and political action needs legitimate provenance. A village may fail; the simulation may not cheat to save it. Preserve seeded determinism, save migrations, the existing development ledger, Interlocking Systems Manifest, and in-game Wiki. Expansion means active coding on an isolated branch; Build means final acceptance and packaging; Release means published three-platform artifacts.
Authoritative references
docs/directives/2026-10-19_multiplayer_foundation.md
docs/DEVELOPMENT_LEDGER.md, MP-01, DGA-D3, CRT-03
wip/multiplayer branch, code status requires audit
Current status and scope
An implementation track already exists: wip/multiplayer; ledger records MP-01 active, DGA-D3 partially implemented, and two-process networking tests. This is NOT proof multiplayer shipped in Build 15. Audit branch, commits, exported packages and actual two-device behavior before assigning a release.
Owner vision: Minecraft-style host/join, 2–4 players, no mandatory dedicated server. The host owns the canonical world. When host exits, world stops; when host reloads, it resumes.
Host authority and simulation
Only the host advances NPCs, wildlife, economy, resource depletion, time, crime, family history, elections, inventories and save state. Clients send validated inputs/actions, not competing simulations.
Single-player remains supported and save compatible. Do not replicate the whole world every frame; use relevant deltas and bounded network updates.
Joining and persistent identity
Menu: Single Player, Host With Friends, Join Nearby Game. Host selects world, max players, optional password and can inspect connected players.
LAN discovery preferred; manual IP advanced fallback. Provide clear errors for wrong password, incompatible version, host loss, and network failure.
Persistent character ID is world-bound, not temporary peer ID. Restore player inventory, equipment, skills, location and progress after disconnect/rejoin without duplication.
Cross-platform progression
First: Windows/Linux host with Android and PC clients. Later: Android host with Android/PC clients. Verify real Android permissions, network discovery, touch controls, sleep and keyboard behavior.
Future: four-player LAN, shared inventory and interactions, Android hosting, optional Internet friend joining if feasible without required operating costs.
Shared interaction integrity
Host validates simultaneous purchases, harvests, crafting, container access, player-to-player transfers, combat and property changes. No double-spending, duplicate items or client-authoritative inventory edits.
Player-to-player courtship must permit rejection; do not assume one player can force a relationship on another.
Phases (audit then develop)
MP-A audit wip/multiplayer against released Build 15, record exact SHA and functioning features.
MP-B prove two real Godot processes host, discover, join, move and animate independently.
MP-C world-bound identities, save/load, disconnect/reconnect and security checks.
MP-D host-validated shared interactions, 2–4 players and Android client verification.
MP-E Android hosting and optional Internet joining, only after earlier gates.
Acceptance
Two actual processes join the same world; both see movement and facing; guest disconnects/rejoins with same world-bound character.
Host exits and world stops; host resumes and history continues without duplicated items.
Two clients competing for one resource cannot both acquire it. Single-player behavior remains intact.
Distinguish automated process tests from physical PC/Android validation.
Open questions
Exact existing Build 15 shipping status, public Internet NAT traversal strategy and Android hosting feasibility require verification; do not reimplement proven code.
Handoff checklist
Reconcile this specification against current branch and owner decisions before coding.
Create or update existing development-register tasks, not a second backlog.
Record data schema and save migrations; protect inventory, currency and history conservation.
Use narrow tests for changed code and reuse relevant green CI.
Keep expansion work on remote GitHub staging/WIP branch; do not publish a build until the build stage.
Update in-game Wiki, developer documentation and Interlocking Systems Manifest.