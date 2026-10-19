# Player-hosted multiplayer foundation

Owner directive, received 2026-10-19T17:05:36.985Z (verbatim; kept so approved requirements stay traceable).

---

MY MEDIEVAL LIFE — PLAYER-HOSTED MULTIPLAYER FOUNDATION

Build 14 / Future Release Development Directive

Implement a practical, testable foundation for Minecraft-style player-hosted multiplayer in My Medieval Life.

The game remains fully playable in single-player mode.

The long-term goal is for 2–4 players to inhabit the same persistent medieval world, with a player hosting from a Windows/Linux PC or Android device.

Prioritize PC hosting with Android clients first, while designing the architecture to support Android hosting as well.

Do not require the owner to operate a dedicated server.

1. Core multiplayer design

Implement a host-authoritative architecture.

The host runs the canonical world simulation, including:

- NPC behavior and schedules
- Economy and market transactions
- Wildlife
- Crafting and resource consumption
- Inventory changes
- Farming and harvesting
- Crime and consequences
- World time
- Persistence and saving

Clients send player inputs or validated action requests.

The host determines authoritative outcomes and synchronizes relevant state.

Do not run competing independent simulations on every client.

Preserve the existing single-player experience and save compatibility.

2. First playable milestone

Create a functional two-player LAN multiplayer prototype.

Required capabilities:

1. Host an existing or new world.
2. Discover a host on the same local network.
3. Join from a second device.
4. Spawn two independent player characters.
5. Show both characters moving in the same world.
6. Synchronize movement and facing direction.
7. Synchronize basic player animations.
8. Support player disconnect and reconnect.
9. Save and restore player-specific state within the host's world.
10. Preserve normal single-player operation.

This milestone must run on actual Godot multiplayer networking, not simulated local characters.

3. Simple player interface

Add clear menu options:

- Single Player
- Host With Friends
- Join Nearby Game

For hosting, provide:

- World selection
- Maximum players, initially 2–4
- Optional session password
- Host/Start button
- Connected-player list
- Leave/Stop Hosting

For joining, provide:

- Automatically discovered local games
- Host name
- World name
- Player count
- Join button
- Clear connection errors

Avoid requiring players to type IP addresses for ordinary LAN play.

Provide a manual IP option under Advanced settings for troubleshooting.

4. Cross-platform networking

Support the same compatible game protocol across:

- Windows
- Linux
- Android

Prioritize:

1. Windows/Linux host with Android clients.
2. Windows/Linux host with PC clients.
3. Android host with Android clients.
4. Android host with PC clients.

Use Godot's supported networking facilities, such as ENet and RPC, where appropriate.

Implement local-network discovery using an appropriate supported discovery mechanism.

Account for Android networking permissions, Wi-Fi restrictions, device sleep and background behavior.

Do not assume LAN discovery will work on every router or hotspot. Provide a documented fallback.

5. Character persistence

Each joining player must have a stable identity within the hosted world.

A player's character, equipment, inventory, skills, location and progress must belong to that player's identity within that world.

When the host exits, the world stops.

When the host resumes, the world continues from its saved state.

When a guest rejoins, their character should be restored rather than replaced with a new character.

Do not rely solely on temporary network peer IDs for persistent character identity.

Protect against accidental character duplication and identity collisions.

Do not expose player identities or save data unnecessarily.

6. World simulation integration

Create a clear boundary between:

- Simulation authority
- Player input
- World state
- Network synchronization
- Presentation and UI
- Save/load persistence

Identify systems that currently assume only one player exists.

Document the changes needed to make them multiplayer-safe.

Do not immediately rewrite every existing system.

Begin with movement, player identity, spawning, and persistence.

Then progressively extend networking to shared interactions.

7. Shared interaction safety

Establish a reusable host-validated interaction pattern for future systems.

Examples include:

- Two players attempting to purchase the same item.
- Two players harvesting the same resource.
- Two players using one workstation.
- Players transferring items between inventories.
- Players interacting with the same container.
- Players damaging the same animal or NPC.

Prevent duplicated resources, conflicting transactions and inconsistent world state.

Implement representative tests before expanding the pattern to every gameplay system.

8. Mobile usability

Design the multiplayer interface for Android touchscreens.

Use readable buttons and text.

Avoid small connection-status indicators.

Provide understandable messages such as:

- Looking for nearby games
- Joining world
- Host disconnected
- Wrong password
- Game version mismatch
- Connection lost

Avoid technical error messages where a simple explanation is possible.

Ensure the Android keyboard closes when text entry is complete.

Maintain existing mobile movement and interaction controls.

9. Performance

Target a maximum of four players initially.

Avoid synchronizing the entire world every frame.

Synchronize only relevant changes and use appropriate update rates.

Measure:

- Network bandwidth
- Movement smoothness
- Host CPU load
- Client CPU load
- Memory usage
- NPC simulation stability
- Reconnection behavior

Do not compromise single-player performance unnecessarily.

10. Testing

Create automated multiplayer tests using at least two separate Godot processes.

Verify:

- Hosting
- Discovery where testable
- Joining
- Movement replication
- Player identity
- Disconnect and reconnect
- Save and reload
- Basic shared interactions
- Rejection of invalid actions
- Compatibility with single-player

Clearly distinguish automated tests from actual PC/Android device testing.

Do not declare Android hosting verified until it has been tested on a real Android device.

11. Development isolation

Build this feature on an isolated branch or safely separated workstream.

Do not disrupt ongoing Build 14 asset integration, carts, economic systems or other active work.

Do not merge incomplete networking code into the release branch.

Preserve existing saves and releases.

Do not initiate a public release.

12. Expansion roadmap

After the two-player LAN milestone works, plan:

Phase 2: Four-player LAN sessions.

Phase 3: Shared inventories, crafting, commerce, harvesting, combat and world interactions.

Phase 4: Android hosting and cross-platform stability.

Phase 5: Internet hosting with simple friend invitations, if feasible without imposing unnecessary infrastructure or operating costs.

Keep the long-term goal of a persistent, player-hosted world with characters tied to that world.

13. Deliverables

Produce:

- A functional multiplayer prototype
- Host and Join menus
- LAN discovery
- Two-player movement synchronization
- Persistent guest-character identity
- Multiplayer tests
- Architecture documentation
- A list of existing systems requiring multiplayer adaptation
- A clear account of what works and what remains incomplete

Report the exact branch and commit IDs.

Success means two real instances of the game can connect, display independent player characters, move together in the same world, and reconnect with preserved character state.

Do not claim multiplayer is complete merely because the network connection succeeds.

Continue autonomous development, preserve the existing World Design Rules and Interlocking Systems Manifest, and do not expand this task into a full networking rewrite before the first playable milestone is verified.
