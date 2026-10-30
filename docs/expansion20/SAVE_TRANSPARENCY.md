# Save transparency with the economy off (X20-MP-ECON-INTEGRITY, secondary investigation)

Worker A observed that, with the Living Economy off, a world saved and loaded already differs from the never-saved world right after
the load, while two worlds loaded from the same save run identically. This page records which state differs, why, and whether it
matters for save integrity (CLAUDE.md section 7) and for host recovery in multiplayer. Report only: nothing was changed.

## Method

A headless probe (not kept in the repository; a scratch script):

1. `World.setup(VillageMap.load_default(), 1)` with the economy override cleared; 600 updates of 0.5 s.
2. The save as the game writes it: `JSON.stringify(w.to_dict(), "", true, true)` (full precision, as `Main.save_game`), parsed back,
   loaded into a second world with `World.load_dict`.
3. Compared right after the load: every top-level key of `to_dict()` (JSON text), descending into the differing ones; the RNG
   (`World.rng` seed and state); every script variable of every villager (`NPC`) that is not an object.
4. Both worlds then run 400 more updates and are compared again, once as loaded and once with the loaded world's `World.rng` state
   forced equal to the original's.

## Findings

| What differs | Why | Classification |
|---|---|---|
| `World.rng` state | Not saved: `load_dict` reseeds it as `seed + minutes` | Benign by design (each save resumes deterministically: two loads of one save run identically). The main cause of the later divergence |
| Villagers' `plan`, `path`, `path_i`, `work_left`, `facing`, `anim` | Runtime state, never in `NPC.to_dict`; villagers plan again after a load | Benign for every record: intentions and the progress of the task in hand only; goods and coins are in the saved pack and purse. Behaviour diverges even with the RNG forced equal |
| Trees' `born` on stumps and regrowing trees (`null` before, a value after) | `World.load_dict` fills a missing `born` with `Trees.born_of(t)` (`regrow * DAY`), the value the game computes when it is absent | Benign: derived, the same value either way |
| Last digit of some floats (`fauna` hunger and `next_birth`, `relations` attraction, `x18_experience`) | JSON text keeps about 15 significant digits | Benign: precision of the order 1e-15 |

Nothing saved is lost or reinterpreted: no coin, good, contract, offer, shipment or other record differs after the load. It does not
threaten host recovery: `game/tests/net_econ_integrity_test.gd::_host_crash` restores a killed host from its save and finds every coin
and good, transit and escrow, contract set-asides and the open shipment exactly as saved, with the economy off and on.

## Limits

- Compared: `World.to_dict()` in full (every module that saves itself through it) and the `NPC` script variables. Not compared field
  by field: the runtime (unsaved) state of other modules and objects, such as `Animal` objects' runtime fields, `NPCBrain`, `Fauna`,
  `Construction`, `Carts`, `Business`, `Couriers`, `Regions` and `SettlementParty` caches, `Judgment` working sets, the
  `PlayerState` objects' runtime fields, and any RNG a module holds other than `World.rng`. Their saved parts are covered by the
  `to_dict()` comparison; their unsaved parts may also differ after a load and would only change behaviour, as the villagers' plans do.
- One seed (1), one moment (after 600 steps), the economy off. The economy-on save key (`economy`) was not part of this probe.
