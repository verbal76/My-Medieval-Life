# Owner directive, 2026-11-03 (about 17:35 EST): Build 25 Revision 1, anticipatory NPC crowd management

Saved verbatim. Register: B25R1-020. Amends the presence-by-view architecture (B25R1-019, B25R1-Q6, B25R1-Q7). The owner
attached a conceptual diagram (screen, live/buffered ring, outer calculated zone) marked "Conceptual illustration, not a
proposed fixed radius. The real viewport must control what is visible."

Rationale (lead's record): presence keeps the whole world simulated; this adds a limit on unnecessary visible crowds on
Android by letting eligible ordinary NPCs begin their next legitimate activity a little sooner as the player approaches,
never by hiding or deleting anyone, and never touching protected NPCs. It is an explicit, limited owner exception to
observation neutrality.

---

MY MEDIEVAL LIFE — B25R1

OWNER DIRECTIVE: ANTICIPATORY NPC CROWD MANAGEMENT

Amendment to Presence-by-View Architecture

This directive clarifies my intended NPC population-management system. Coordinate it with the existing presence-by-view worker. Do not restart completed work or interrupt unrelated development.

My objective: Keep the world fully populated and simulated while limiting unnecessary visible crowds on Android. The village must remain lively, interactive, and believable.

1. The buffer zone is the decision zone

Use the existing visibility system with its off-screen buffer.

When NPCs enter the outer buffer surrounding the player's view, evaluate whether the approaching area is becoming unnecessarily crowded.

Do not wait until NPCs are already on screen to begin crowd management.

When crowd pressure is high, eligible NPCs may advance their next legitimate activity and physically walk toward that destination.

They must not disappear, teleport, or be deleted.

The buffer must provide enough distance for natural departures before NPCs become visible whenever practical.

2. Protected NPCs are exempt — no exceptions for crowd limits

The following NPCs must never be redirected, hidden, despawned, or made unavailable simply to meet a population target:

- Merchants operating shops, stalls, or other player-accessible businesses.
- Quest givers.
- Anyone displaying a special interaction icon above their head, including scrolls, swords, or other existing indicators.
- NPCs involved in active emergent events.
- NPCs currently interacting with the player.
- NPCs the player is approaching or actively targeting for interaction.
- Characters performing essential activities that cannot legitimately be interrupted.

I do not want to chase merchants, quest givers, or important NPCs around the village.

If an NPC is meant to be available for interaction, they must remain reasonably accessible.

Merchants should remain at their appropriate business locations during operating hours, subject to existing legitimate business and life rules.

Quest givers and special-icon NPCs should remain available long enough for the player to notice, approach, and interact with them.

Use sensible interaction locks or availability windows so these characters don't walk away just as the player reaches them.

Do not permanently immobilize them or override genuine emergencies, danger, mortality, or established schedules. The protection applies specifically to crowd-management decisions.

3. Visible population is a soft target, not a hard cap

Investigate a comfortable ordinary-NPC target around 15–20, subject to actual Android performance measurements.

This is not a maximum number of people allowed to exist or appear.

If 25 NPCs need to be present because merchants, quest givers, emergent events, or legitimate workers require it, then 25 stay.

Protect gameplay first.

Do not sacrifice interactive characters to achieve an arbitrary frame-rate target.

Optimize rendering and animation when necessary rather than removing essential NPCs.

4. Who can be encouraged to leave?

Only ordinary NPCs who have a legitimate next activity and whose current activity can reasonably conclude.

Examples:

- A shopper who has finished purchasing goods.
- A villager who has finished socializing.
- Someone waiting around after completing an errand.
- A resident ready to return home or to work.
- A traveler ready to continue an existing journey.

These NPCs may begin their next scheduled activity sooner when the player approaches a crowded area.

They must physically walk away using actual world paths.

Do not invent fake errands, cancel transactions, interrupt essential work, or create artificial economic activity.

If 15 miners are legitimately mining, let them mine.

5. Player presence triggers crowd management

When the player is absent, there is no need to thin crowds for rendering purposes.

A market may have 200 mathematically simulated residents if the economy and population systems legitimately produce that situation.

When the player approaches, the buffer activates anticipatory crowd management.

Only eligible NPCs should be encouraged to depart.

Once the player leaves, crowd pressure ends and the ordinary simulation continues.

This is an explicitly approved, limited exception to the earlier observation-neutrality rule: player proximity may accelerate eligible NPC activity transitions.

The exception must not alter identities, inventories, money conservation, completed transactions, or unrelated life decisions.

Record this exception in the decision register.

6. Prevent unnatural behavior

Implement appropriate safeguards against:

- NPCs repeatedly reversing direction.
- People abandoning errands midway.
- NPCs leaving and immediately returning because of threshold fluctuations.
- Quest givers walking away as the player approaches.
- Merchants leaving their stalls because a crowd formed.
- NPCs visibly disappearing.
- People being redirected into unsafe or inaccessible terrain.
- Crowd-management decisions changing unpredictably with frame rate.

Use hysteresis, transition cooldowns, persistent destinations, and stable simulation timing where appropriate.

The exact values should be measured and tuned rather than guessed.

7. Maintain a lively world

Do not make villages feel abandoned.

Preserve ordinary residents who are available for casual conversation, trading, observation, and spontaneous interaction.

The system should reduce excessive background crowding, not eliminate background life.

The player should still see people arriving, departing, shopping, working, and socializing.

8. Performance and verification

Have the presence worker measure:

- Frame time with different visible NPC counts.
- Performance with protected NPCs exceeding the soft target.
- Effectiveness of buffer-zone anticipatory departures.
- NPC movement and pathfinding cost.
- Android performance at normal gameplay zoom.
- Deterministic simulation behavior.
- Economic and inventory conservation.
- Interaction accessibility.

Include targeted scenarios with crowded markets, active merchants, quest givers, special-icon characters, and essential workers.

Verify that protected NPCs remain accessible even when visible population exceeds the target.

Do not claim the system is successful merely because it improves FPS. It must also preserve the gameplay experience.

9. Integration

Record this as a new owner-approved B25R1 directive, including the rationale and its relationship to the existing presence-by-view system.

Implement it through the existing NPC judgment, scheduling, movement, and visibility architecture.

Avoid creating a disconnected crowd-control AI that overrides established life behavior.

Reuse existing passing tests and integrate through the current B25R1 workflow.

Proceed without another owner approval loop unless a genuine architectural conflict arises.

Final design rule:

I would rather have 25 useful, interactive NPCs around me than 15 NPCs who make the village feel empty or force me to chase merchants and quest givers.

The background population can naturally thin out when I approach, but the people who matter to gameplay stay available.

Make the world feel alive, not artificially evacuated.
