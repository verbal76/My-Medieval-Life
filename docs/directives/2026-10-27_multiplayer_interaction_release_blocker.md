# MULTIPLAYER INTERACTION RELEASE BLOCKER (owner directive, Expansion 20, 2026-10-27)

Received in the session of 2026-10-26/27, verbatim:

MY MEDIEVAL LIFE

OWNER DIRECTIVE — MULTIPLAYER INTERACTION RELEASE BLOCKER

I am establishing a mandatory release requirement for the next Expansion 20 build.

The build must not be packaged for distribution, published, or delivered for playtesting until the cross-platform player-to-player interaction problem has been corrected, integrated, and validated.

This applies to:

- Android APK
- Windows executable
- Linux executable

DEVELOPMENT SEQUENCE

You may complete the other workstreams first.

Continue the existing:

1. Build 19 recovery and outstanding integrations.
2. Living Economy development.
3. Android usability improvements.
4. Persistent Messages journal.
5. Existing approved Expansion 20 work.

The multiplayer interaction correction may be implemented last, as a dedicated integration batch on top of the other completed work.

Do not unnecessarily interrupt existing workers.

Do not restart previously completed development.

However, this task cannot be deferred to another build.

MULTIPLAYER REQUIREMENT

Our real-world playtest confirmed that the Windows player could see Bob, the Android player, but could not select or interact with him.

We did not test the reverse direction.

Treat this as a cross-platform system deficiency until testing establishes otherwise.

Audit and correct player-to-player interaction across:

- Windows
- Linux
- Android

Both host and guest must be able to initiate interactions.

At minimum, verify that players can select one another using the appropriate input controls, open an interaction menu, and access the previously approved multiplayer functionality.

This includes conversation, gifts, trading, contracts, and relationship interactions to the extent defined by the existing approved multiplayer specifications.

Do not invent unapproved economic or relationship policies.

Interactions requiring mutual agreement must provide a genuine opportunity for the receiving player to accept, decline, or negotiate where supported by the applicable system.

Reuse the existing network architecture, authoritative world state, player identities, transaction systems, and consent mechanics.

Do not create a separate multiplayer economy.

REQUIRED TESTING

The final integration must validate:

- Windows initiating interactions with Android and Linux.
- Android initiating interactions with Windows and Linux.
- Linux initiating interactions with Windows and Android.
- Host initiating interactions with guests.
- Guests initiating interactions with the host.
- Keyboard and mouse controls.
- Touchscreen controls.
- Controller controls.
- Correct player targeting when NPCs or objects are nearby.
- Successful interaction requests and responses.
- Currency and inventory conservation.
- Save/load and reconnect behavior.
- No regressions to single-player gameplay.

Use automated cross-platform tests and the available real-device evidence. Identify any combinations that still require owner-device testing rather than claiming they passed.

Tests must exercise the actual gameplay interaction interface, not only call backend functions directly.

FINAL INTEGRATION ORDER

When the other Expansion 20 work is ready:

1. Freeze the integrated development baseline.
2. Integrate the multiplayer interaction correction.
3. Resolve merge conflicts without discarding earlier work.
4. Run targeted multiplayer regression tests.
5. Run the relevant combined regression and simulation gates.
6. Verify the three platform exports and interaction paths.
7. Produce the final release-readiness report.

Do not rerun expensive unrelated test campaigns when valid evidence can be reused.

RELEASE RESTRICTION

No next Expansion 20 playtest release without the multiplayer interaction fix.

This restriction includes private releases.

Record the requirement as a blocking item in the authoritative requirements register and current development handoff.

Do not silently defer it.

Mini Build 22, which was already pushed, is not being reopened.

The next Expansion 20 build must include the completed multiplayer correction.

Finish the other development work first if that is most efficient. Integrate multiplayer last. But do not ship without it.
