# Owner directive, 2026-11-03 (received 2026-11-02 23:03 EST): DEMO-01 + Steam integration + release pipeline (consolidated)

Saved verbatim.

---

MY MEDIEVAL LIFE — BUILD 25

CONSOLIDATED OWNER DIRECTIVE: DEMO-01 + STEAM INTEGRATION + RELEASE PIPELINE

STATUS: APPROVED FOR IMPLEMENTATION

This directive supersedes the previous DEMO-01 instructions and Steam wishlist amendment. It consolidates them into one authoritative implementation specification.

It does not supersede the existing Build 25 completion directive, approved eight-stage REGION-NAV-01 plan, Living Economy requirements, or development governance rules.

1. Primary objective

Complete Build 25 with:

- All previously approved Build 25 functionality.
- All eight REGION-NAV-01 stages, S1–S8.
- Completed Living Economy integration and activation.
- Corrected confirmed defects.
- Passing required test suites.
- A successful final integrated 365-day flight recorder simulation.
- A 120-minute replayable demo.
- Steam promotional integration.
- Six verified packages in a private draft GitHub release.

No new gameplay features, unrelated optimizations, or additional expansions are authorized.

DEMO-01 is a bounded release work package, not a ninth regional-development stage.

Continue existing development and tests without unnecessary interruption.

---

2. Demo model — 120 minutes per world

Implement a fully playable demo with 120 minutes of cumulative active gameplay per world.

Requirements:

- Every newly created world receives 120 minutes.
- Unlimited new worlds may be created.
- Each world maintains its own timer.
- Multiple characters within one world share that world's allowance.
- Saving, loading, restarting, or renaming a world must not reset its timer.
- The player may replay the demo indefinitely by creating new worlds.
- All normal Build 25 gameplay systems remain available during the trial.

Do not limit the number of in-game days.

Do not disable regional exploration, Living Economy, trade, employment, crafting, relationships, businesses, NPC behavior, or other approved functionality.

The demo's primary restriction is elapsed active gameplay time.

3. Timer implementation

Use a monotonic active-play clock.

Count time while the game world is actively running, including normal gameplay interfaces that do not pause the simulation.

Do not count time during:

- Pause.
- Main menus.
- World selection.
- Loading.
- Application suspension/backgrounding.
- Application closure.
- Modal interfaces that actually pause the world.

Do not count suspended frames or system-clock jumps.

Persist accumulated active time in the world's save data.

Use an injectable clock for automated tests.

Do not make automated tests wait two real hours.

4. Demo user interface

Display a readable, unobtrusive timer.

Example:

Demo Time Remaining: 1h 42m

Show warnings at:

- 30 minutes remaining.
- 10 minutes remaining.
- 5 minutes remaining.
- 1 minute remaining.

Warnings should be noticeable without unnecessarily interrupting gameplay.

Each warning should appear only once per world, including across saves and reloads.

At world creation, explain the time allowance and full-game save compatibility.

Ensure the UI works correctly on Android phones, Windows, and Linux.

Use the existing game's visual style.

5. Expiration behavior

When a world's allowance expires:

1. Stop gameplay and simulation advancement safely.
2. Preserve the current world state.
3. Allow a safe final save.
4. Display the demo expiration screen.
5. Offer options to start a new world, return to the main menu, or exit.
6. Explain that the saved world can be continued in the full game.
7. Provide the Steam promotional action defined below.

Do not delete expired worlds.

Do not permit expired demo worlds to resume active gameplay.

Expired worlds must remain identifiable in world selection.

6. Save compatibility

Use the existing Build 25 save format and migration architecture.

Persist:

- Stable world identity.
- Accumulated active-play time.
- Demo allowance.
- Expiration state.
- Necessary save schema/version metadata.

Do not use save filenames as authoritative world identities.

A demo save must load correctly in the corresponding full Build 25 game.

When loaded in the full game:

- The timer restriction is disabled.
- The world is fully playable.
- NPCs, inventories, coins, relationships, settlements, businesses, regional systems, and progression are preserved.
- No demo expiration restriction remains active.

Existing full-game saves must remain compatible.

Legacy saves without demo metadata must migrate safely according to the established save-version rules.

Do not introduce accounts, DRM, online validation, or invasive anti-tamper mechanisms.

Android save transfer

Android demo and full-game applications may use separate private storage.

Implement and test an explicit, platform-compatible save export/import or transfer mechanism.

Do not assume two Android applications can read one another's private saves.

Preserve world integrity and avoid overwriting unrelated saves.

7. Steam promotional integration

Implement the same general Steam promotional system approved for Upwardly, adapted to My Medieval Life.

Use a centralized Steam destination configuration.

Temporary destination

Until My Medieval Life has an approved Steam store page, use:

https://store.steampowered.com/

The button must not falsely claim that the player can already wishlist the game.

Temporary label:

Coming Soon on Steam

Supporting text may explain that the My Medieval Life store page is being prepared.

Permanent destination

Once the owner supplies the My Medieval Life Steam App ID or actual store URL:

- Replace the generic destination with the game's Steam store page.
- Change the button label to Wishlist on Steam.
- Retain the same interface and button behavior.
- Avoid changes to unrelated gameplay systems.

Do not invent a Steam App ID.

Do not attempt to create or publish the Steam store page automatically.

Button placement

Provide the Steam promotional button in:

1. The full-game main menu.
2. The demo main menu.
3. The demo expiration screen.
4. Existing appropriate promotional screens, where applicable.

Do not place intrusive Steam advertisements over active gameplay.

Use the existing UI design language and scale correctly on all platforms.

Link handling

- Android: use the supported external browser/intent mechanism.
- Windows: use the supported system browser/Steam URL mechanism.
- Linux: use the supported external URL mechanism.

Do not introduce SteamCMD or command-line Steam deployment.

Opening the Steam link must not corrupt the world, reset the timer, or interfere with saves.

If the URL cannot open, fail gracefully.

The Steam destination must be configurable from one authoritative location rather than hardcoded throughout the UI.

8. Shared full-game and demo architecture

The full game and demo must share the same Build 25 source code.

Use a dedicated build configuration, following existing project conventions.

A build flag such as "DEMO_BUILD=true" is acceptable if appropriate.

Differences between the two configurations should be limited to:

- Demo identification and branding.
- Demo timer and UI.
- Demo expiration restrictions.
- Steam promotional messaging as applicable.
- Demo-specific persistence metadata.
- Necessary application/package identity differences.

Do not duplicate the simulation engine, procedural generation, economy, or gameplay code.

The full game must not accidentally activate demo restrictions.

9. GitHub Actions — parallel six-package workflow

Extend the existing Build 25 release pipeline.

Produce these six deliverables:

Platform| Full game| Demo
Android| APK| APK
Windows| ZIP| ZIP
Linux| ZIP| ZIP

Use the same approved release-candidate commit SHA for all six packages.

Use a GitHub Actions matrix or independent jobs.

Run independent builds in parallel rather than sequentially.

Do not wait for the Windows build before starting Linux or Android.

Do not make demo builds wait for full-game builds unless a genuine technical dependency exists.

Suggested package names:

- MyMedievalLife-B25-Android.apk
- MyMedievalLife-B25-Windows.zip
- MyMedievalLife-B25-Linux.zip
- MyMedievalLife-B25-Demo-Android.apk
- MyMedievalLife-B25-Demo-Windows.zip
- MyMedievalLife-B25-Demo-Linux.zip

Follow existing packaging conventions where necessary.

Ensure Android full and demo application identities support safe coexistence and save transfer.

Record:

- Exact source SHA.
- Build configuration.
- Package filename.
- Package size.
- SHA-256 checksum.
- Workflow run.
- Relevant test evidence.

Upload the six artifacts and attach them to a private draft GitHub release.

Do not publish publicly or upload to Steam automatically.

10. Demo automated tests

Create focused automated tests for:

Timer

- Correct initial 120-minute allowance.
- Active gameplay consumes time.
- Pausing stops time.
- Backgrounding stops time.
- Loading and menus do not consume time.
- Suspended frames do not create time jumps.
- Correct accumulation across sessions.
- Correct behavior across different frame rates.
- No negative or invalid remaining time.

World persistence

- Save/load preserves timer.
- Restart preserves timer.
- Different worlds have independent timers.
- Characters in one world share the timer.
- Renaming or copying saves does not reset elapsed time.
- Expired worlds remain expired.
- Legacy save migration remains valid.

Expiration

- Correct warning thresholds.
- No duplicate warnings.
- Safe final save.
- Simulation stops after expiration.
- Expired world cannot resume in demo.
- New world receives fresh allowance.
- Expiration screen functions correctly.

Full-game compatibility

- Demo save loads in full game.
- Full game has no timer restriction.
- World progression is preserved.
- No coins, goods, NPCs, or relationships disappear.
- Existing full-game saves remain valid.
- Android export/import works correctly.

Steam integration

- Generic destination opens correctly.
- Future configured game-specific destination opens correctly.
- Promotional labels match destination state.
- Link failures are handled safely.
- Opening a link does not damage save or timer state.
- Full and demo interfaces display the correct button.

Cross-platform

Verify applicable functionality on Android, Windows, and Linux.

Use simulated clocks and focused automated tests where possible.

Do not perform real-time two-hour test waits.

11. Regression and simulation requirements

The demo must not alter the underlying simulation.

Verify that identical world states and inputs produce identical simulation behavior in full and demo configurations before expiration.

Run independent test suites in parallel through GitHub Actions.

Reuse valid existing evidence where source and test coverage match.

Do not restart unrelated simulations merely because a demo UI or timer changed.

Correct genuine defects and rerun affected tests.

The final integrated Build 25 source must pass all established acceptance criteria.

12. Final 365-day flight recorder

The final integrated 365-day flight recorder remains mandatory.

Run it on the completed Build 25 release-candidate source with the approved Living Economy configuration.

Use the existing flight recorder KPIs, invariants, and acceptance thresholds.

The flight must validate the full integrated simulation, including the regional systems.

If the flight passes cleanly, proceed to packaging.

If a genuine defect is found:

1. Correct the defect.
2. Run focused regression tests.
3. Repeat necessary affected validation.
4. Repeat the final 365-day acceptance flight on the corrected candidate.

Do not require a separate 365-day flight for the demo if its simulation is demonstrably identical to the full game.

Do not count baseline flights on earlier commits as final Build 25 acceptance evidence.

13. Build 25 completion priority

The previously approved Build 25 scope remains the primary development obligation.

Complete:

- REGION-NAV-01 S1–S8.
- Living Economy integration and activation.
- Other previously approved Build 25 work.
- Confirmed defect corrections.
- Final integration tests.
- Final 365-day flight recorder.
- DEMO-01 and Steam promotional integration.
- Six verified release packages.

Do not start Build 26 work.

Do not introduce unrelated optimization campaigns.

Do not defer previously approved Build 25 functionality.

14. Documentation and governance

Record this consolidated directive in the established requirements system.

Create or update:

DEMO-01 — Replayable 120-Minute Demo and Steam Integration

Preserve the original S1–S8 stage sequence.

Document significant implementation decisions and their rationale.

Record test results, source commits, and release artifacts.

Use America/New_York timestamps with the correct EST/EDT abbreviation.

Report progress against a fixed checklist with completed items, outstanding work, and genuine blockers.

Do not report unverified tests or packages as complete.

15. Authority and release restrictions

You are authorized to:

- Implement DEMO-01.
- Implement the Steam promotional integration.
- Complete existing Build 25 requirements.
- Fix confirmed defects.
- Run required validation.
- Create the six packages.
- Publish the packages to a private draft GitHub release.

You do not need additional approval for routine engineering decisions.

Owner approval remains required for new gameplay scope, major design changes, public release, or Steam store publication.

The finish line is six verified packages from one accepted Build 25 source commit, with all approved gameplay complete, all required tests passing, and the final 365-day flight recorder clean.

Proceed without unnecessary approval interruptions.

First record this directive, inspect the existing UI/save/build architecture, and integrate DEMO-01 into the fixed Build 25 completion checklist. Continue implementation automatically.
