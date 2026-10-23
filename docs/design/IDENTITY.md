# Persistent person identity (ID-01): what is built

Developer reference for the identity foundation (save version 20), on `wip/foundation-identity`. Authority: the owner's approval
`docs/directives/2026-10-23_identity_foundation_approval.md` (items 1 and 2) of the proposal
`docs/design/IDENTITY_AND_RECONCILIATION_PROPOSAL.md`. Interaction entries: INT-405 (migration keeps the person) and INT-406
(an heir keeps their own identity). Player-facing text: one sentence in the wiki page "The neighbouring settlements".

## The id space

- `World.next_person_id` (saved) is the one counter. `World.new_person_id()` returns it and raises it; it is never lowered except by
  `release_person_id` for an id issued a moment ago to nobody (a move that fell through) with nothing issued since. It also lifts
  itself above any villager record or player id it finds, so a record made by hand can never collide.
- A villager's person id **is** `NPC.id` (nobody was renumbered): Relations ties, contracts, credit, civic and economy references keep
  working. `NPCBrain._next_npc_id` now calls `new_person_id()` (it used to be the highest id plus one, which could reissue an erased id).
- A settlement member's id is the sixth entry of the member array (`OffMapSettlement.M_ID`); a member born there has `{}` as the
  fifth entry (`M_WHO`, the carried name and skills, only for someone who came from the village), so `has_who(m)` is the test for a
  carried identity. Births draw the id through `person_hook` (`World.offmap_person`), set by `Regions.bind_world`; settlements outside a
  world (some tests) leave it 0.
- Every player character has `PlayerState.pid`.

## The register

`World.people`: id -> `{name, family, sex, born, mother, father, where, since}`, saved as `people` (sorted by id). Identity and
whereabouts only; never pruned. `where`: `village`, a settlement id, `dead`, `player`, `ancestor`. `mother` and `father` are person ids
(the player's own `pid`, not -2; -1 unknown). Detailed state stays in one place: the NPC record (kept, `alive` false, while away, dead
or the player) or the settlement member. It is kept in step at: population start, birth, newcomer, outlaw arrival, leaving
(`Migration._gone`), arriving (`Migration._arrived`), death (`World.kill`, a settlement death), a settlement birth, succession.
`Identity.verify` checks the invariants (every villager, member and the player registered, ids unique, the counter above every id).

## Leaving and returning

`Migration._person_of` carries the id; the member keeps it. On return `_villager` reactivates the existing record (`_reactivate`:
alive, `away` cleared, age, skills and purse from the member, no household, home or job until housed; a partner link survives only
if still mutual) and `_arrived` makes the household lists hold the id exactly once and updates the register. `_undo_villager` puts a
reactivated person back if no home could be had. A settlement-born member has no record yet: `_villager` makes it under the id they
were born with.

## Succession (ID-D1)

`Life.make_heir`: the child's record is no longer erased: it is emptied (what they carried is in the loot), `alive` false,
`became_player` true, left in `npcs` and `by_id`. Every loop over villagers already skips `alive` false; `main.gd` does not draw a
`became_player` record. `Identity.succeed`: the heir's `pid` is the child's id (a relative heir gets a new id); the predecessor is
`ancestor`; a snapshot of the village's ties with the player id (-2) goes to `World.tie_history[pid]` (read by no rule). The live
ties under -2 continue to the heir, and links to a former player (-3) are as in Build 18. No reputation formula was added.
Differences from Build 18 worth knowing: the child's own record answers `w.npc(id)` (dead-like), so a grandchild's kin search now
finds the child as a dead parent instead of nobody.

## Save version 20 and the upgrade

Keys added: `next_person_id`, `people`, optional `identity_report`, `tie_history`; `player.pid`; member sixth entry; NPC
`became_player`. A save with no `people` (version 19 or older, including an import: `SaveTransfer.migrate` forces the number first, so
the test is the missing key) is upgraded once on load by `Identity.upgrade`, deterministic, no random numbers:

1. counter = 1 + the highest villager id (two villagers with one id refuse the load);
2. the register is built from every NPC record (`alive`, `away`, `became_player` give `where`);
3. an `away` villager is matched to the members of the settlement they are in by name, family, sex and birth day (within two days);
   exactly one member and exactly one villager for it: the member takes the villager's id (reunited);
4. every other member gets an id in settlement order (the saved order, which is `settlements.json`), household index, member index;
5. the player gets an id. Earlier player characters left no records in older saves, so they get no register entries; the report says
   how many earlier generations and links to a former player exist;
6. `Identity.verify`; any failure sets `World.load_error` and `main._load_save` refuses the save, which is then moved aside unchanged
   (as an unreadable save is) or, for an import, not imported. The original file is never written by a load.

`identity_report` (saved, plus a log line) holds `from_version`, `day`, `next_person_id`, `counts` (villagers, away, reunited,
away_unmatched, away_ambiguous, members) and `notes`: `away_unmatched` (no member matches: record and member stay separate),
`away_ambiguous` (several candidates, or one member claimed by several: all separate), `returned_as_new_record` (an older build made
a returning migrant a new villager: both records kept, nothing merged), `former_players`.

Not recoverable from old saves, and not invented: an erased child heir, a returned migrant's replaced record (reported when it can be
seen), the identities of earlier players.

## Tests

`game/tests/identity_test.gd` (registered in `.github/workflows/tests.yml`); `migration_test.gd` and `aging_test.gd` were updated for
the new rules (a returning migrant is the same record; the heir child's record is kept). The determinism gate result is in the
foundation report.
