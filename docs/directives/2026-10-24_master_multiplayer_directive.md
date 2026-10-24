# Owner directive, 2026-10-24: master multiplayer development directive

Saved verbatim from the session.

---

# MY MEDIEVAL LIFE
# MASTER MULTIPLAYER DEVELOPMENT DIRECTIVE
**Owner Authorization | October 2026**

## 1. Mission and Priority

Multiplayer is the next major development milestone for My Medieval Life.

**Approved development sequence:**

1. Complete owner playtesting, acceptance, and finalization of Build 19.
2. Begin dedicated multiplayer integration and development.
3. Complete and validate multiplayer against the acceptance requirements in this directive.
4. Resume Expansion 20, Living Economy.
5. Continue the approved remaining expansion roadmap.

This directive supersedes previous multiplayer scheduling instructions.

Multiplayer was approved on October 17, 2026. A preliminary prototype was implemented on October 19, but was isolated and never integrated into a release. That omission must not happen again.

**Do not begin implementation until Build 19 is accepted by the owner.** Architecture assessment, dependency planning, documentation, and preparation are authorized now.

## 2. The Exact Multiplayer Experience

The intended design is Minecraft-style, player-hosted multiplayer.

One player hosts a persistent medieval world. Approximately three or four players, including the host, can inhabit that world together.

Every player is a fully participating character in the same living simulation.

The world belongs to the host's save, not to a central online account.

When the host closes the world, simulation time stops. When the host loads it again, the saved world resumes.

No continuously running dedicated game server is required.

Players must be able to live alongside one another, work, explore, trade, build, own property, develop relationships, form families, commit crimes, defend themselves, and experience the consequences of their decisions.

**Multiplayer must extend the existing single-player game, not replace it with a simplified simulation.**

## 3. Mandatory Cross-Platform Support

The target platforms are:

- Android, including the Pixel 10 Pro XL.
- Windows.
- Linux, including Steam Deck compatibility.

Every platform must be able to host and join worlds.

All platforms must use one compatible multiplayer protocol and world-save architecture.

### Required Compatibility Matrix

| Hosting platform | Android guest | Windows guest | Linux guest |
|---|---|---|---|
| Android | Required | Required | Required |
| Windows | Required | Required | Required |
| Linux | Required | Required | Required |

Every combination must be validated.

Android must not become a reduced-function multiplayer client.

A world hosted on Android must support Windows and Linux guests, and vice versa.

The host is authoritative regardless of platform.

### Android Requirements

Account for:

- Network permissions.
- Application backgrounding.
- Screen locking and device sleep.
- Cellular and Wi-Fi connections.
- Network changes and temporary disconnections.
- Device memory and CPU limitations.
- Battery consumption and thermal throttling.
- Reliable save operations when the application is interrupted.

Do not sacrifice Android gameplay feel, controls, performance, or existing functionality to accommodate desktop multiplayer.

### Steam Deck

Linux multiplayer must remain compatible with Steam Deck controls and networking.

Steam Deck hosting and joining must be included in the validation plan.

## 4. Internet and LAN Multiplayer

Support local network play and practical internet connections between invited players.

The player should not need to operate a dedicated server.

Investigate:

- ENet networking already present in the prototype.
- LAN discovery.
- Manual IP connections.
- NAT traversal.
- Relay-based connectivity when necessary.
- Host connectivity over cellular networks.
- Connection authentication and password protection.
- Connection timeouts and reconnect handling.

Do not assume that a LAN prototype automatically provides functional internet multiplayer.

Do not introduce a paid networking service or recurring operating expense without owner approval.

If a relay, account system, or external service is required, present its costs, dependencies, privacy implications, and alternatives before implementation.

The objective is a simple host-and-join experience without unnecessary infrastructure.

## 5. Host-Authoritative Architecture

The host owns and executes the authoritative world simulation.

Guest devices send player intentions and receive synchronized authoritative outcomes.

Examples include:

- Movement requests.
- Item collection.
- Purchases and sales.
- Crafting.
- Construction.
- Combat actions.
- NPC interactions.
- Theft and criminal actions.
- Family and relationship interactions.

The host validates each action using the same underlying simulation rules applied to the host player.

Guests must not independently create authoritative coins, items, NPCs, buildings, or world events.

Preserve deterministic simulation behavior and resource conservation.

Network latency must not change the fundamental simulation rules.

Client-side prediction or interpolation may be used for responsiveness, provided authoritative outcomes remain controlled by the host.

## 6. Full Player Equality

Guest players must have access to the same gameplay systems as the host player.

The multiplayer implementation must support the existing game's applicable systems, including:

### Character and Survival

- Movement and exploration.
- Hunger and other needs.
- Health, injury, and death.
- Skills and experience.
- Inventory and equipment.
- Employment and wages.
- Character progression.

### Economy and Property

- Buying and selling.
- Negotiation.
- Contracts.
- Crafting and production.
- Construction.
- Building ownership.
- Land and property rights.
- Personal wealth and possessions.

### Society and Relationships

- NPC conversations.
- Friendship and rivalry.
- Reputation and judgment.
- Gossip and trust.
- Courtship and marriage.
- Family relationships.
- Children and inheritance.
- Family reputation and historical memory.

### Crime and Conflict

- Theft.
- Combat.
- Bandit encounters.
- Witnessed crimes.
- Reputation consequences.
- Self-defense.
- Protection of family members.

Where a feature already exists in single-player, multiplayer should use that same gameplay system.

Do not create separate, simplified versions for guests.

Do not freeze guest survival needs as the original prototype did.

Where an existing feature is incomplete in single-player, report the limitation rather than inventing new expansion scope.

## 7. Persistent World and Character Ownership

Each hosted world maintains its own player characters.

A character created in one world belongs to that world.

Joining another world does not automatically transfer equipment, money, property, skills, or progression.

The host's world save contains all participating characters and their persistent state.

At minimum, preserve:

- Permanent player identity.
- Character name and appearance.
- Position and relevant location.
- Inventory and equipment.
- Coins and financial records.
- Skills and progression.
- Property ownership.
- Relationships.
- Reputation and criminal history.
- Family associations.
- Character status and survival information.

A returning player must reconnect to their existing character rather than receiving a duplicate.

A player must not be able to impersonate another player's character merely by changing a displayed name.

Identity credentials must not expose private authentication secrets to other guests.

## 8. Disconnects and World Persistence

The world continues while the host remains active, even if a guest disconnects.

The world stops when the host closes it.

Rejoining players must receive the current authoritative state.

Prevent:

- Duplicated inventory.
- Lost or duplicated coins.
- Duplicate characters.
- Conflicting ownership.
- Replayed transactions.
- Invalid construction.
- Desynchronized NPC states.

**Owner decision required:** Determine what happens to a guest's character while disconnected.

Present practical alternatives, including whether the character becomes inactive, remains physically present, or continues participating in selected simulation activities.

Explain survival, combat, property, and fairness consequences before selecting a policy.

Do not silently invent disconnected-character behavior.

## 9. Preserve the Existing Simulation

Multiplayer must preserve the approved Build 19 baseline, including:

- Permanent NPC identities.
- NPC autonomy and daily schedules.
- Personality and stubbornness.
- Judgment and reputation.
- Gossip and trust.
- Family reputation and stories.
- Lying and deception.
- Family-sacrifice behavior.
- Bandit survival and healing.
- Resource conservation.
- Economic transactions.
- Construction.
- Existing underground environments.
- Save and load behavior.
- Deterministic simulation results.

Do not reduce simulation depth or simplify NPC behavior to achieve multiplayer performance.

Any unavoidable architectural tradeoff requires owner approval.

Single-player mode must remain fully functional without an internet connection.

## 10. Existing Multiplayer Prototype

The forensic audit identified:

- Branch: `wip/multiplayer`
- Commit: `d18d7d1`
- Approximately 1,551 added lines across 20 files.
- Based on code predating Build 14.
- Approximately 602 commits behind Build 19 at the time of audit.

The prototype includes:

- ENet host-and-join.
- LAN discovery.
- Password and version checks.
- Basic player identity.
- Host-owned guest saves.
- Movement synchronization.
- Limited shared interactions.
- Two-process local testing.

It does not provide complete gameplay parity, tested three-to-four-player support, or verified Android/internet multiplayer.

### Integration Rules

Preserve the original prototype branch.

Do not blindly merge or rebase it into Build 19.

Audit every networking component for compatibility with the current architecture.

Reuse proven components where appropriate.

Replace obsolete assumptions rather than distorting current gameplay to accommodate them.

Preserve historical audit evidence and implementation records.

## 11. Architecture Assessment

Before implementation, determine how the current game handles:

- Player and NPC identities.
- Actor lookup and ownership.
- Player-specific references.
- Inventory and economic transactions.
- World saves.
- Construction and property.
- Relationships and family records.
- Combat.
- Underground locations.
- Simulation ticks and event ordering.
- Randomness and deterministic replay.
- UI and input handling.

Identify every assumption that only one human player can exist.

Recommend an architecture that supports multiple human-controlled characters without duplicating the simulation.

Do not implement multiplayer by treating guests as temporary visual objects disconnected from the actual world systems.

## 12. Implementation Batches

After Build 19 acceptance and explicit implementation authorization, organize development into the following logical batches.

### Batch A — Multiplayer Foundation

- Bring forward compatible networking code.
- Establish player identity and session management.
- Implement hosting and joining.
- Establish authoritative world synchronization.
- Preserve single-player behavior.

Checkpoint: two processes can connect and maintain consistent world state.

### Batch B — Player Persistence

- Save guest characters in the host world.
- Restore returning characters.
- Handle disconnects and reconnection.
- Validate inventory and currency persistence.
- Prevent character duplication.

Checkpoint: host restart and guest reconnection tests.

### Batch C — Full Gameplay Integration

- Movement and exploration.
- Resource gathering.
- Inventory and equipment.
- Economy and employment.
- Crafting and construction.
- Property and ownership.
- Combat and crime.
- NPC interactions.
- Relationships and family systems.
- Underground environments.

Group related systems into implementation sub-batches.

Checkpoint: each completed group passes focused tests and uses the established simulation rules.

### Batch D — Cross-Platform Connectivity

- Android hosting and joining.
- Windows hosting and joining.
- Linux hosting and joining.
- Mixed-platform connections.
- LAN connectivity.
- Internet connectivity.
- Android lifecycle handling.
- Steam Deck compatibility.

Checkpoint: real-device and mixed-platform tests.

### Batch E — Three-to-Four-Player Validation

- Simultaneous player actions.
- Conflicting transactions.
- Shared construction.
- Combat synchronization.
- Multiple players interacting with one NPC.
- Player disconnections.
- Host shutdown and restoration.
- Performance under normal simulation load.

Checkpoint: successful sessions with the approved player count.

### Batch F — Final Integration

- Full regression testing.
- Single-player compatibility.
- Determinism.
- Resource conservation.
- Save integrity.
- Multiplayer security.
- Performance.
- Platform packaging.
- Release-readiness review.

Do not publish without owner authorization.

## 13. Development Efficiency

Use one primary development agent unless a clearly independent task justifies additional agents.

Do not run competing CPU-intensive test campaigns unnecessarily.

Implement related changes in batches.

Use focused regression tests during development and comprehensive testing at major integration boundaries.

Avoid repeated full builds after individual minor changes.

Do not rewrite working systems merely to make them easier to network.

Maintain a clear record of completed features, test evidence, and unresolved issues.

## 14. Mandatory Acceptance Criteria

Multiplayer is complete only when:

1. Android, Windows, and Linux can each host and join supported sessions.
2. Cross-platform combinations have been tested on real devices.
3. Three to four players can inhabit one world.
4. Guests can participate in the existing gameplay systems with the same rules as the host.
5. Character ownership and progression persist correctly.
6. The host remains authoritative.
7. Resources and currency cannot be duplicated through networking.
8. NPCs and world state remain synchronized.
9. Disconnects and reconnections are handled correctly.
10. Host shutdown and restart preserve the world.
11. Internet multiplayer works through a documented, usable connection method.
12. Single-player gameplay remains intact.
13. Performance remains acceptable on the supported hardware.
14. No known critical save-corruption, synchronization, or security defects remain.

A passing LAN movement demonstration is not sufficient.

A successful two-player test is not sufficient.

A desktop-only test is not sufficient.

## 15. Reporting and Accountability

Multiplayer must remain visible in every development status and release-readiness report until accepted.

Reports must distinguish:

- Designed.
- Implemented on an isolated branch.
- Integrated.
- Tested locally.
- Tested on real devices.
- Accepted by the owner.
- Released.

Do not label a feature complete without corresponding evidence.

Do not silently defer approved work.

Any feature excluded from a release must be explicitly identified.

Maintain a current outstanding-decisions list.

## 16. Immediate Authorized Work

Effective immediately:

1. Record this directive in the development register.
2. Update the roadmap to place multiplayer immediately after Build 19.
3. Preserve the old prototype and its forensic audit.
4. Prepare the Build 19 compatibility assessment.
5. Identify reusable components and architectural changes.
6. Produce the implementation batch plan.
7. Identify owner decisions required before implementation.
8. Estimate effort and technical risks.
9. Report any networking services or operating costs that might be necessary.

**Do not begin implementation until Build 19 receives owner acceptance.**

Do not merge branches, activate unfinished networking code, start release workflows, or publish builds as part of this preparation.

Once the preparation is complete, report the findings and stop for owner authorization.

## Final Design Principle

**I am not asking for multiplayer characters that can walk around the same map. I am asking for multiple people to live in the same medieval world.**

Every player must be subject to the same world rules, participate in the same economy and society, and experience persistent consequences.

The game must retain the simulation depth, emergent behavior, and existing gameplay feel that have already been developed.

Cross-platform support across Android, Windows, and Linux is mandatory.

No dedicated always-on server.

No watered-down guest experience.

No loss of existing single-player functionality.

**Build 19 first. Full multiplayer next. Expansion 20 afterward.**
