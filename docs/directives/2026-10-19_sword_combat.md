# Sword combat responsiveness and hit detection

Owner directive, received 2026-10-19T17:59:14.153Z (verbatim; kept so approved requirements stay traceable).

---

MY MEDIEVAL LIFE — SWORD COMBAT RESPONSIVENESS AND HIT DETECTION

Add this as an approved, active combat-quality issue to the existing development open-items list. Continue current approved work and address this in a safe development workstream without interrupting unfinished cart integration.

Reported gameplay defects

1. Sword attacks appear to register only every second or third button press.
2. Attack inputs may be discarded while a previous animation or cooldown is active.
3. The player must physically overlap a bandit's sprite to land a sword hit.
4. Combat feels inconsistent even when the player presses attack rapidly.

These are player-observed symptoms, not confirmed root causes. Inspect the actual combat implementation before changing it.

Required investigation and fixes

Attack responsiveness

Trace the full attack input path, including Android touch controls, keyboard/controller input, attack state transitions, animation playback, cooldowns, and damage execution.

Identify whether inputs are being dropped, blocked, overwritten, or ignored.

Implement a short, bounded attack input buffer so a valid press during recovery triggers the next attack when available.

Do not queue unlimited attacks or create uncontrolled automatic attacking.

Avoid accidental double-firing from a single button press.

Ensure the attack button provides immediate visual or audio feedback where appropriate.

Sword range and hit detection

Inspect existing attack hitboxes, enemy hurtboxes, collision masks, directional checks, and damage range calculations.

Implement or correct a directional melee attack area that extends beyond the player's body.

A sword must be able to hit a nearby enemy in front of the player without requiring sprite overlap.

Support the game's actual movement and facing directions, including diagonal directions where applicable.

Do not increase every enemy's hurtbox indiscriminately.

Prevent attacks from striking enemies through solid walls or other blocking geometry.

Animation synchronization

Separate animation playback from the underlying combat state where necessary.

Define consistent windup, active-hit, and recovery phases.

Damage must occur during the appropriate visible part of the swing.

Avoid damage being applied repeatedly to the same target during a single attack unless explicitly intended.

Allow smooth transitions between consecutive attacks.

Do not arbitrarily speed up animations without first diagnosing the underlying problem.

Platform consistency

Verify the fixes against:

- Android touch attack input.
- Keyboard attack input.
- Controller attack input.
- Different facing directions.
- Moving and stationary attacks.
- Repeated attacks.
- Multiple nearby enemies.

Tests and acceptance criteria

Add automated tests for:

1. Repeated button presses during attack recovery.
2. Exactly one queued attack within the permitted buffer.
3. No unintended duplicate damage.
4. Reliable attacks at the intended sword reach.
5. No requirement for player/enemy sprite overlap.
6. Correct hits in all supported directions.
7. No hits through walls.
8. Correct behavior while moving.
9. Stable save/load and scene transitions.
10. No regressions to NPC or enemy combat.

Use repeatable test scenarios to measure attack attempts, accepted attacks, completed swings, and successful hits separately.

The primary acceptance criterion is that normal, deliberate attack presses feel responsive and sword strikes connect at believable distances.

Do not claim that Android touch responsiveness has been verified solely from desktop automated tests. Flag real-device testing as outstanding until performed.

Scope

Focus on fixing existing sword combat first.

Archery is planned for future development but is NOT authorized for implementation under this directive.

Update the existing open-items list, relevant combat documentation, in-game Wiki, and Interlocking Systems Manifest.

Commit and push tested work to the appropriate remote staging branch.

Do not create or publish a new distributable build without explicit approval.
