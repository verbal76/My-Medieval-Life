# MY MEDIEVAL LIFE — MESSAGES JOURNAL CORRECTION (owner directive, Expansion 20, 2026-10-26)

Received in the session of 2026-10-26, verbatim:

MY MEDIEVAL LIFE — MESSAGES JOURNAL CORRECTION

OWNER DIRECTIVE — EXPANSION 20

The new Messages page is a good addition, but I do not approve the current behavior of deleting its history whenever a saved game is loaded.

A journal should preserve the player's history.

If a notification is important enough to record in the journal, it should not disappear simply because the player saves, exits, and returns later.

1. MAKE MESSAGE HISTORY PERSISTENT

Implement persistent message history using the game's existing save architecture.

Requirements:

- Messages survive saving and loading.
- Messages survive closing and reopening the game.
- Each saved world maintains its own message history.
- Loading another world displays that world's messages.
- Starting a genuinely new game starts with a new message history.
- Messages remain in chronological order.
- Each entry retains its original in-game day and time.
- Dismissing a notification does not delete its journal entry.
- Automatic notification fading does not delete its journal entry.
- New messages are recorded even when the player never opens the journal.

Do not use a temporary UI array as the only storage location.

2. MAINTAIN BACKWARD SAVE COMPATIBILITY

Claude stated that the message history was not saved because this would require changing the save format.

That is not sufficient justification.

Extend the existing save structure in a backward-compatible manner.

- Existing Build 21 and Build 22 saves must continue loading.
- Older saves without message history should initialize an empty history safely.
- Newer saves should restore their recorded messages.
- No other save data may be lost or altered.
- Existing player, NPC, economy, inventory, relationship, and world state must remain intact.
- Do not reset an existing world merely because it lacks the new journal field.

Use an optional field or another compatible persistence mechanism.

Do not introduce a separate save system when the existing architecture can support this feature.

3. DISTINGUISH IMPORTANT EVENTS FROM TEMPORARY UI FEEDBACK

Not every interface notification needs to become permanent history.

Record meaningful information such as:

- NPC communications.
- Employment and contract notifications.
- Trading and financial events affecting the player.
- Criminal accusations, fines, and legal consequences.
- Relationship and household developments.
- Significant village events.
- Important quest and gameplay notifications.

Routine messages such as repeatedly selecting a workbench, changing targets, or pressing a menu button should not flood the journal.

Preserve the existing immediate notification behavior.

The Messages journal should provide a useful historical record, not become an archive of every interface interaction.

Use existing event sources where possible. Do not duplicate the simulation flight recorder or create another economic ledger.

4. HISTORY MANAGEMENT

The current implementation retains approximately 200 messages in memory.

Review whether that limit is appropriate for a game intended to run over many generations.

Do not silently discard important historical information simply because the player received too many routine notifications.

Implement bounded storage with sensible retention rules.

If older entries must be removed for performance or storage reasons, distinguish routine notifications from significant historical events.

Avoid unbounded save-file growth.

5. JOURNAL USABILITY

Preserve the new compact Messages page.

Ensure:

- Messages are ordered by game day and time.
- Long messages wrap properly.
- Players can scroll through their history.
- The journal remains readable on Android and desktop.
- Messages do not overlap navigation controls.
- Returning to the journal does not erase its contents.

Do not enlarge the gameplay notification box to accommodate journal features. The compact notification layout should remain unchanged.

6. TESTING

Add targeted tests covering:

1. Receive several messages.
2. Dismiss one manually.
3. Allow another to fade automatically.
4. Save the game.
5. Exit and reload.
6. Verify every retained message is restored correctly.
7. Load an older save without a message-history field.
8. Confirm that older saves remain valid.
9. Switch between two saved worlds and verify their histories remain separate.
10. Confirm that message logging does not change authoritative simulation outcomes or determinism.

Reuse existing passing test evidence.

Do not rerun unrelated large simulation campaigns merely for this interface correction.

7. INTEGRATION

This correction belongs in the current Expansion 20 message-box workstream.

The worker has already implemented the notification layout and journal page on "wip/x20-msg".

Extend that implementation rather than restarting it.

Coordinate the merge with the running Expansion 20 tests. Do not modify a working directory while its test campaign is active.

Once the correction is complete:

- Commit it.
- Run targeted save/load and interface tests.
- Verify integration with the active Expansion 20 branch.
- Update the requirements register.
- Report the commit and test results.

FINAL REQUIREMENT

The Messages journal must be a permanent part of the saved world's history, not a temporary session log.

Players should be able to return to their game days or weeks later and review important messages they previously received.

Preserve save compatibility, preserve performance, and retain the smaller notification boxes.

Implement this as part of the current Expansion 20 work.
