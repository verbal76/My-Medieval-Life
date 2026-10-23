# Build 18: decisions made on the owner's behalf (owner review)

Kept under the owner's delegated authority of 2026-10-23 (`docs/directives/2026-10-23_build18_overnight_completion_release.md`,
section 2): narrowly scoped, reversible choices that follow an approved design. Each entry gives the question the owner would
otherwise have been asked, the options, the choice, why, the systems and files, whether it is reversible, and follow-ups.
Settled owner decisions (CHAPEL-R2 reserve and rule, REG-CIRC-D1, SET-D, DP-17, DP-18, DP-19, old-save fixes) are not
reopened here.

## D1. Who in a household receives its alms?
1. **Question:** The necessity reserve (OD-19/PAR-02A) is one need for the whole household, so the alms fill the household's
   shortfall once. Which member receives the coins?
2. **Options:** (a) the lowest-id adult, else elder; (b) the household's richest member (who already does its buying,
   `NPCBrain._richest_in_household`); (c) split among the adults.
3. **Selected:** (a).
4. **Why:** deterministic and simple; the coins are household money either way (members share the reserve and the pantry),
   and paying one member is what prevents the duplicate payments the owner asked to rule out; splitting creates rounding.
5. **Systems and files:** chapel alms, `game/scripts/core/chapel.gd::alms`.
6. **Reversible:** yes (one line).
7. **Follow-up:** none expected; a household's buyer is its richest member, which the recipient becomes.

## D2. Do the clergy and the player get alms?
1. **Question:** Are the clergy's households, and the player, eligible for alms?
2. **Options:** (a) clergy households by the same rule as any household, the player not (the player is not a household and
   already has "Ask the church for food"); (b) exclude the clergy; (c) include the player.
3. **Selected:** (a).
4. **Why:** "the poorest households" names no exception, and the clergy's low wages make them plausible recipients; the player
   has the existing food-alms path (INT-226), so a coin path would be a new rule.
5. **Systems and files:** `chapel.gd::alms`; the wiki chapel page says the player is not given alms.
6. **Reversible:** yes.
7. **Follow-up:** the owner may want player parity later (a coin alms for a poor player).

## D3. Ties and order between equally short households
1. **Question:** When two households are short by the same amount and the alms cannot cover both, who comes first?
2. **Options:** (a) the lower household index; (b) the larger household; (c) shared equally.
3. **Selected:** (a).
4. **Why:** deterministic ordering (CLAUDE.md section 6) with no new rule; ties are rare.
5. **Systems and files:** `chapel.gd::alms`.
6. **Reversible:** yes.
7. **Follow-up:** none.

## D4. Which earlier chapel coins are given out on an old save?
1. **Question:** A save made before the alms holds a large fund (thousands of coins after a long game). Should the first
   service day after loading give it all out, or only what new offerings bring?
2. **Options:** (a) the same rule as any service day: everything above the keep, up to the households' shortfalls;
   (b) only new offerings.
3. **Selected:** (a).
4. **Why:** the fund is the offerings the design always meant to give as alms; (b) would need a new saved field.
5. **Systems and files:** `chapel.gd::alms` (no save change).
6. **Reversible:** yes.
7. **Follow-up:** households are only ever filled up to their shortfall, so the payout is bounded by need; the rest stays.

## D5. The Minifantasy songs on Windows and Linux
1. **Question:** The owner's rule is WAV on PC unless Ogg has no quality loss, but the Minifantasy pack may not be
   redistributed, so its WAVs cannot be committed. How do the PC builds get them?
2. **Options:** (a) the release workflow takes them from the owner's own "Minifantasy" release zip at build time, checked
   by size and sha256; (b) Ogg on every platform; (c) commit the WAVs.
3. **Selected:** (a).
4. **Why:** lossless on PC as the owner asked, and nothing of the pack is committed.
5. **Systems and files:** `tools/fetch_music.py`, `game/data/music.json`, `game/export_presets.cfg`, `.github/workflows/release.yml`.
6. **Reversible:** yes.
7. **Follow-up:** the PC builds depend on that release staying in place (its zip is checked by checksum).

## D6. Music slot hours, fades and the fight rule
1. **Question:** When do morning, day and night begin, how long are fades, and what counts as a fight?
2. **Options:** the game's existing clock (villagers wake at 6, work ends at 18) versus other cuts.
3. **Selected:** morning 6-10, day 10-18, night 18-6 (the title screen plays the morning song; underground plays the night
   song); 3-second fades (1.5 s into a fight), 6 s of quiet between plays; a fight is a bandit or anyone fighting the player
   within 12 cells, or a wild animal angry at the player, held 6 s after the last engagement.
4. **Why:** follows the existing day schedule and rest rule; the 10:00 end of morning is the one free choice.
5. **Systems and files:** `game/scripts/core/audio.gd`, `game/data/music.json`.
6. **Reversible:** yes (data values).
7. **Follow-up:** device playtest: whether the transitions feel right.

## D7. Footstep loudness and spacing
1. **Question:** How soft is "soft, not loud and annoying"?
2. **Options:** a level and spacing in the data file.
3. **Selected:** about -16 dB under the other effects, pitch +/-5%, a step per 1.15 cells walked, at least 260 ms apart,
   never the same variant twice running; stone underground and indoors, dirt on roads, grass elsewhere.
4. **Why:** quiet enough to sit under the music; tunable without code (`music.json` `sfx.steps`).
5. **Systems and files:** `game/scripts/core/audio.gd`, `game/data/music.json`.
6. **Reversible:** yes.
7. **Follow-up:** device playtest.

## D8. Sounds not wired
1. **Question:** Several supplied sounds have no matching event (magic other than the fireball, bow, shield, slime, iron
   doors, levers, traps, water, landing, the campfire). Should events be added for them?
2. **Options:** (a) leave them imported or recorded as opportunities; (b) add new mechanics for them.
3. **Selected:** (a).
4. **Why:** new mechanics are out of scope; recorded in `docs/assets/packs.json` opportunities.
5. **Systems and files:** `docs/assets/packs.json`.
6. **Reversible:** yes.
7. **Follow-up:** a later build may use them.

## D9. The firewood counter
1. **Question:** The nightly "no firewood" note counted ended households. Fix the count, or also change heating?
2. **Options:** (a) count live households only; (b) change heating rules.
3. **Selected:** (a): ended households' stores had already gone to the granary, so only the count was wrong.
4. **Why:** a counting artefact (RCA in `docs/build18/CHAPEL_AUDIT.md`), no behaviour changed.
5. **Systems and files:** `game/scripts/core/world.gd` (the nightly firewood loop).
6. **Reversible:** yes.
7. **Follow-up:** none.

## D10. Release despite the chapel fund still growing
1. **Question:** With the alms in place the chapel fund still ends the year at 4,400-7,600 coins (78-85% of all coins in
   three seeds). Hold the release, or ship and report?
2. **Options:** (a) ship: the alms work as approved and the growth comes from the provisional offering values, which only
   the owner may change; (b) hold and change offering rates (not authorized); (c) change the alms rule (not authorized).
3. **Selected:** (a).
4. **Why:** a probe on the release code shows the alms reach every short household each service day (seed 2: 68 coins to
   35 household payments by day 146, none left short); the four 365-day runs are clean (no leak, FATAL or script error); the
   owner's gate distinguishes defects from structural outcomes, and this is the latter.
5. **Systems and files:** none changed; evidence in `docs/build18/LONG_RUNS_365_ALMS.md`.
6. **Reversible:** yes (a later build can change the values or the rule with the owner).
7. **Follow-up:** the owner may wish to revisit the offering rate (coin_share, min_piety, keep_coins) or the alms rule
   (CHAPEL-R2) with this evidence.

## D11. Release parameters
1. **Question:** Which build number, signing and visibility for the Build 18 packages?
2. **Options:** build number 18 (the build's name) or the run number; the owner's stable test key (its secrets do not exist)
   or the workflow's temporary key; private draft or public.
3. **Selected:** build number 18; temporary key (`allow_temporary_key`), as Build 17; private draft (visible only to
   collaborators), as authorized.
4. **Why:** follows the Build 17 convention; the signing secrets are still missing; a draft is the access-controlled
   channel the owner authorized (the repository itself is public, so a published release would not be).
5. **Systems and files:** `.github/workflows/release.yml` run on `wip/build18` at `61ec528`.
6. **Reversible:** yes (a draft can be deleted or published later by the owner).
7. **Follow-up:** the APK cannot install over Build 17 (different key): export the save, uninstall, install, import.

Further decisions made while packaging are added below as they are taken.
