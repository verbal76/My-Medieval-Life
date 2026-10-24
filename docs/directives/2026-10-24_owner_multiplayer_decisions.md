# Owner decisions, 2026-10-24: multiplayer preparation review (MP-D1 to MP-D8)

Saved verbatim from the session.

---

Multiplayer preparation report reviewed. The proposed architecture is approved in principle: one authoritative simulation, multiple full player characters, shared gameplay systems, and single-player compatibility.
Record the following owner decisions for implementation planning:
MP-D1: Approved. Disconnected characters leave active play, but all persistent records remain in the host world. Do not automatically delete ownership, obligations, or relationships.
MP-D2: Approved. Accelerated resting requires agreement from all connected players. Anyone remaining active keeps the world at normal speed.
MP-D3: Approved. Individual menus never pause an active multiplayer world. Single-player pause behavior must remain unchanged.
MP-D4: Modified. A player's death must not freeze the world. Use the established succession mechanics and provide the appropriate player choice rather than automatically forcing an heir transition.
MP-D5: Approved conditionally. Implement free connection methods first, but internet multiplayer remains mandatory. A virtual-LAN workaround alone does not satisfy the final usability requirement. Return with a practical connectivity proposal before declaring internet support complete.
MP-D6: Modified. Android backgrounding must support temporary interruption and reconnection where technically possible. Safely suspend and recover the hosted world if the host process cannot continue. Do not promise uninterrupted background hosting without device evidence.
MP-D7: Approved. New guest characters arrive as newcomers and participate under the established world rules.
MP-D8: Approved with mutual consent required for player-to-player marriage and other actions requiring agreement from both participants. Preserve existing family, inheritance, and succession mechanics.
Additional architectural requirements:

1. Preserve the Build 19 simulation and single-player gameplay behavior.
2. Avoid a separate simplified guest simulation.
3. Use permanent identities and per-player ownership throughout.
4. Treat all platforms as potential hosts and guests.
5. Preserve the existing multiplayer prototype as reference.
6. Keep multiplayer ahead of Expansion 20 in the roadmap.
7. Maintain explicit verification gates for Android, Windows, Linux, Steam Deck, and mixed-platform sessions.
8. Track the multiplayer milestone in every status report until owner acceptance.

Record these decisions and update the integration plan.
Do not start implementation, branch integration, or release workflows until Build 19 is accepted and I explicitly authorize development.
