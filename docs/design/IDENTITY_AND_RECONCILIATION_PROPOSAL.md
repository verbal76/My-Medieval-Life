# Persistent person identity and overlap reconciliation: proposal for approval (2026-10-23)

> **HISTORICAL** (documentation reconciliation DOC-RECON-01, 2026-10-31). Current status: `docs/expansions/EXPANSION_19.md`. The proposal was approved on 2026-10-23 and built: ID-01 is merged (`801d24b`, `b2f7dc2`) and released in Build 19 (save version 20). "Nothing here is built" below is no longer true. The open baseline question is ID-D3 (PROVISIONAL, owner 2026-10-28). Content below is kept unchanged as the historical record.

Owner directive: `docs/directives/2026-10-23_post_audit_foundation_repairs.md` items 3 and 4 (register ID-01, RECON-01). This is
the design checkpoint the directive requires "before implementing a major identity schema change". **Nothing here is built.**
Facts are read from the released Build 18 code (`origin/wip/build18`); everything else is a PROPOSAL.

## 1. Identity today (facts)

| Who | Identity | Problem |
|---|---|---|
| Village NPC | `NPC.id` int, `World.by_id`, refs `npc:<id>`; Relations ties keyed `"a:b"` by id | ids are `max(existing) + 1` (`NPCBrain._next_npc_id`), so an id freed by an erasure can be issued again |
| Migrant leaving | `Migration._person_of` packs name, family, age, sex, skills, **no id**; the NPC stays in `npcs` with `alive = false`, `away = <settlement>` | the person loses identity in the settlement |
| Off-map person | a member array `[born_day, sex, pair, unwilling, {n, f, sk}]` in an off-map household (`offmap.gd:_member_of`) | **no id at all** |
| Migrant returning | `Migration._villager` creates a **new** NPC with a new id | a replacement person: relations, judgment, civic history and refs all restart |
| Player | `Life.PLAYER_ID = -2`; earlier players become `FORMER_PLAYER = -3` in their kin's links (`retire_player_id`) | all earlier player characters share one id (-3) |
| Child heir | `Life.make_heir` **erases** the child from `npcs` and `by_id` | its own history is lost and its id can be reused |

## 2. Proposed design

**One person-id space, issued once, never reused.**
- `World.next_person_id` (saved): a counter only ever increased. `_next_npc_id` reads and advances it instead of `max + 1`.
- The person id **is** the existing `NPC.id` for village people (no renumbering of anyone who exists), so every existing system
  keyed by `NPC.id` (Relations, judgment, civic refs, economy refs, contracts, credit) keeps working unchanged.

**A person registry (identity and lineage index, never pruned).**
- `World.people`: id -> `{name, family, sex, born, mother, father, where, since}` where `where` is `village`, a settlement id,
  `dead`, `player` (the current player character) or `ancestor` (a former player character).
- It owns **identity and whereabouts only**. Detailed state stays in exactly one representation at a time: the `NPC` record when
  detailed, the off-map member when abstract. The registry is the one place that says which.

**Migration keeps the person.**
- `_person_of` carries the id; the off-map member stores it (a sixth element, absent in older data).
- Leaving the village: the NPC record stays (as today, `alive = false`, `away` set); the registry says `where = <settlement>`.
- Returning: `_villager` **reactivates the same NPC record** (`alive = true`, `away = ""`, age, skills, purse and goods from the
  member) instead of creating a new one. Relations ties, judgment ledgers, civic legacy and economy refs keyed by that id are
  simply there again.
- A person born off-map gets a fresh id at birth (from the same counter); arriving in the village creates their first NPC record
  under that id.
- Moving between two settlements (future) moves the member and updates `where`.

**Death keeps the person.** Already true for NPCs (kept with `alive = false`); the registry records `where = dead`. Off-map deaths
mark the registry instead of losing the member silently.

**Detailed and abstract transitions (future, E22-OD-01)** convert an `NPC` record to a member and back under the same id; the
registry's `where` changes; nothing is copied into both.

**Inheritance and the player.**
- Each player character gets a person id at the start of their generation.
- The child heir is **no longer erased**: its NPC record is kept (`where = player`), so its own history survives and its id is
  never reissued.
- **Owner decision ID-D1** (it changes Build 18 gameplay): today the village's opinion of the player (Relations ties with -2)
  carries straight on to the heir. Options:
  - (a) keep that: the heir inherits the village's view of the parent (Build 18 behaviour);
  - (b) the parent's ties move to the parent's own id (an ancestor), and the heir starts from the ties the child had as a villager;
    family reputation (Expansion 19, switched off) carries an impression of the parent.
  - Recommendation: (a) in the identity change itself, so Build 18 behaviour is preserved; (b) later, with Expansion 19 on.

## 3. Save migration (version 19 to 20)

1. `next_person_id` = 1 + the highest id among NPCs (living, dead, away).
2. Registry built from every NPC record (where from `alive`, `away`).
3. Off-map members get ids in a fixed order (settlement order of `settlements.json`, household index, member index), so two loads of
   the same save give the same ids.
4. A villager who left (`away` set) and is still alive in a settlement: matched to an off-map member by name, family, sex and
   birth day; when exactly one member matches, the member takes the NPC's id (the person is reunited); when none or several match,
   the member gets a new id and the old NPC record keeps its own, and the case is written to a migration report (never guessed).
5. Former players: one `ancestor` registry entry per earlier generation from the save's player records where they exist (name,
   family); links to `FORMER_PLAYER` (-3) stay as they are (not reassigned to a guessed person).
6. **Data already lost in old saves cannot be recovered** (an erased child heir, a returned migrant's old record that was replaced):
   the migration keeps both records as found and reports them; it never merges or deletes.
7. A fixture test loads a version 19 save (and the existing Build 17 fixture) and checks the counts, the order, the report and that
   no record was dropped.

## 4. Where the change lives and what it touches

- It changes Build 18 code (`world.gd`, `npc_brain.gd`, `migration.gd`, `offmap.gd`, `life.gd`, `player_state.gd`), so it goes on
  a new foundation branch from Build 18 (`wip/foundation-identity`), never on `wip/build18`; Expansions 19, 20 and 21 take it
  when they are combined.
- Gameplay change: a returning migrant is the same person (their old friendships return). The determinism gate will change on any
  seed where someone returns within 30 days; that is expected and will be shown before any re-baseline.
- Save version 20 with the migration above (CLAUDE.md section 7: every format change ships a migration and a fixture test).

## 5. Tests (to be written with the change)

Leave and return keeps the id and the old ties; two settlements; save and load mid-journey; birth off-map then arrival; death in a
settlement; the heir keeps their record and the counter never reissues an id; household and partner changes keep ids; a v19 save
migrates deterministically with the report; nothing dropped (record counts before and after); conservation and the gate.

## 6. Overlap reconciliation (RECON-01)

**Tolerance (temperament vs personality).** Today two accumulators move tolerance for the same firsthand event: the store's `life`
shift (SJD-Q13, agent numbers, live inside the prototype) and the personality layer's drift (inert). Proposal: the **personality
layer becomes the one owner of tolerance change**; the `life` tolerance shift moves into it as its first configured effect with
the same numbers, so results are identical; `life` keeps only the disposition-weight shift (which personality does not model).
Both are inside the switched-off judgment, so nothing changes in the game.

**Goods earmarks (contract holds vs economic reservations).** `Contracts.held_for` is the live, working earmark for contract goods;
`EconReservations` is new and unused. Proposal: **`held_for` stays the authority while the economy is off**; the reservation
record's `available()` subtracts what `held_for` already earmarks, so the two can never claim the same goods; when the owner
approves Expansion 20's integration, contract holds are re-expressed as reservations with purpose `contract:<id>` and `held_for`
reads from them (one mechanism), with a test that contract behaviour is unchanged. Coins set aside (contracts, quests, manor work,
courier escrow) are escrow moved out of purses, not earmarks, and stay as they are.

## 7. Decisions for the owner at this checkpoint

1. Approve the identity design (sections 2-5), including save version 20 and the foundation branch.
2. ID-D1: the heir's inherited view (recommendation: keep Build 18's behaviour now).
3. Approve the two reconciliations (section 6); they can be done on the Expansion 19 and 20 branches respectively.
