# Multiplayer (parallel track): MP-MASTER, MP-*, MP-INET*, MP-INTERACT-01, CRT-03, Batches A-F

Status record under owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md`, DOC-RECON-01).
Vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 against:
- the code and notes on `origin/wip/expansion20` at `ad281dc`;
- the register on staging `aeaa012`;
- the multiplayer directives of 2026-10-19 to 2026-10-30.

Multiplayer is **not** a numbered expansion. It is "a separate parallel track" (OD-30, ROAD-Q1).

**One-line status: IMPLEMENTED through Batch D on loopback and fault injection; PARTIAL overall.**
- Internet play uses free methods only (owner: option A).
- No real-device or real-network check has been done.
- Batches E (performance on devices) and F (final integration) are not done.
- Everything below is in `ad281dc`, the Build 25 candidate. Its validation is running and **is not yet reported**.

## 1. Current approved scope

| Source | What it sets | Status |
|---|---|---|
| `docs/directives/2026-10-24_master_multiplayer_directive.md` (MP-MASTER) | 3-4 players in one host-authoritative persistent world; full guest parity; Android, Windows and Linux (Steam Deck included) each host and join; every cross-platform pair validated on real devices; LAN plus a documented internet method; no dedicated server and no paid service without the owner; single player intact | Current |
| `2026-10-24_owner_multiplayer_decisions.md` (MP-ARCH, MP-D1..MP-D8, MP-INET) | Architecture approved in principle. MP-D1..D8 decided: absent guests leave active play with every record kept; rest by everyone's agreement; menus never pause; death never freezes the world; free connection methods first; Android suspend and recover; newcomer guests; mutual consent between players. "Internet multiplayer is mandatory"; a virtual LAN alone is not enough | Current |
| `2026-10-24_owner_decision_player_marriage_children.md`, `2026-10-24_mp_player_family_minimal_fix.md` (MP-Q-PLAYER-CHILDREN, MP-PLAYER-FAMILY) | Biological children for male+female player couples; adoption for same-sex couples, with both spouses as parents | Current |
| `2026-10-27_multiplayer_interaction_release_blocker.md`, `2026-10-27_mp_interact_begin_now.md` (MP-INTERACT-01) | Player-to-player selection and interaction on every platform and input; merged last before any Expansion 20 build | Current; the release blocker was satisfied on 2026-10-27 |
| `2026-10-30_master_development_resumption.md` s.7 (X20-RESUME, workstream C) | Batch D: invite codes, direct IP, timeouts, Android suspension, reconnection, host loss, duplicate and delayed messages, save integrity, a cross-platform matrix; do not claim device or internet verification that was not done | Current |
| `2026-10-30_mp_batch_d_decision.md` (MP-INET-RELAY) | **Option A for now**: free methods only; no paid relay, commercial service or recurring cost; keep the transport extensible for a later relay; complete the real-device and real-network matrix and report actual limitations before paid networking is reconsidered. Also: verify that multiplayer cannot duplicate or lose economy state (X20-MP-ECON-INTEGRITY) | **Latest owner decision on networking** |
| `2026-10-19_courtship_friendship.md` (CRT-03) | Courtship between players; the other player may decline | Approved |

## 2. Implemented

| Id | What | Integration | Tests (loopback or one-process; none on devices) |
|---|---|---|---|
| MP-ARCH, Batch A (A1/A2) | `World.players`; per-player refs; actor-parameterized verbs; single player unchanged (G0) | `wip/multiplayer-b19`, Build 21 `6567c04` | `multiplayer_a1_test` 67; G0 identical |
| Batch B | Guest characters persist in the host's save; reconnect to the same character; newcomers (MP-D7); duplicate refusal | Build 21 | `multiplayer_b_test` 31, `net_batch_b_test` 44, `net_g1_test` 44 |
| Batch C (C1-C7) | Full gameplay parity: needs, death and succession choice (MP-D4); rest by agreement (MP-D2); no menu pause (MP-D3); gathering, crafting, economy, property, society, crime and combat, underground | Build 21 (`7bae490`) | `multiplayer_c_test` 241 (later 340), `net_c_test` 35 |
| B21-LAN-PLAYTEST | Host and join interface (Open to Friends, Join Game, LAN discovery, manual IP), Android networking, animal sync | Build 21 private draft `6567c04` | Register INTEGRATION VERIFIED |
| MP-PLAYER-FAMILY | Player couples' children and adoption (MP-Q-PLAYER-CHILDREN) | Build 22 `b7e1c91` | Register TARGETED TESTS PASSED |
| MP-INTERACT-01 | Other players offered as targets (prompt, outline, tap); the players window: gift, trade, contract, partner offers, answers | `87b69ab`, Build 23 `c79b12c` | `mp_interact_ui_test` 112, `net_interact_test` 67 x3; INTEGRATION VERIFIED; RELEASE CANDIDATE |
| X20-FINAL multiplayer | 1+2 and 1+3 scenarios (`net_mp4_test`); recorded multiplayer soak | `fe95add`, `8fc7ac6` | `net_mp4_test`; a 5th player is refused |
| Batch D (MP-MASTER, MP-INET) | Invite code with only reachable addresses (`net_invite.gd`); UPnP mapping on a background thread (`net_upnp.gd`); direct IPv4, IPv6 and host names; mobile-data detection; per-address timeouts; guest auto-reconnect with resume token; host pause and restart; numbered idempotent requests; atomic host saves | `de8d225` (from `wip/mp-batchd` `49932ec`); **after** Build 24, so in no build yet | `net_fault_test` 52, `net_g1_test` 44, `net_batch_b_test` 44, `multiplayer_a1_test` 67, `start_test` 523; `tests.yml` 109 scripts pass on the branch |
| X20-MP-ECON-INTEGRITY | Disconnects, retries, duplicate requests and host recovery cannot duplicate or lose coins, goods, contracts, shipments or escrow, with the economy off and on; a guest contract-ownership defect fixed | `5830c35` | `net_econ_integrity_test` 126 |
| GP-BASELINE-POLICY | The single-player baseline may change only for an approved, explained difference; applied at every baseline replacement since | `5ceffe5` (in `ad281dc`) | `sim_gate` |

Design notes are in `docs/multiplayer/BATCH_A.md`..`BATCH_C.md` and `BATCH_D_CONNECTIVITY.md`, and in
`docs/expansion20/MP_INTERACT_AUDIT.md` and `MP_TEST_MATRIX.md` (all on `wip/expansion20` only).

## 3. Partial

| Id | Done | Remaining |
|---|---|---|
| MP-MASTER | Batches A-D; four players on loopback | The real-device matrix (gates G3-G8), Batch E device performance, Batch F |
| MP-INET | Free methods: LAN, UPnP and IPv6 where networks allow, manual forward, a documented virtual-LAN fallback. The owner chose option A, the connectivity proposal having been presented (`BATCH_D_CONNECTIVITY.md` s.6) | Real devices and networks. Under option A, a host on mobile data or behind CGNAT cannot be reached. Batch D's own note: "Internet support is **not** declared complete under A" |
| CRT-03 | Between players: gifts and partner (marriage) offers over the network with accept, decline and lapse (Batch C, C5, MP-D8 "PASS"); `relations.ask_court` and `relations.propose` are networked verbs | A distinct player-to-player courtship or dating stage before a proposal was not found in the evidence. The register still says NOT STARTED and carries a stale note ("multiplayer stays isolated") |
| Batch E (three to four players) | Automated 1+3 sessions, simultaneous requests, host restart (`net_mp4_test`) | Host frame time, bandwidth and memory measured on the Pixel 10 Pro XL with four players (gate G9) |

## 4. Remaining approved work

1. **The real-device and real-network matrix** (`MP_TEST_MATRIX.md`, gates G3-G8):
   - all nine host/guest platform pairs;
   - the owner's failing Windows to Android pair, rechecked first;
   - Steam Deck in game mode, and the Windows firewall prompt;
   - UPnP on a real router, the CGNAT and mobile-data refusal messages, IPv6;
   - the Android background, lock and network-change paths, and the Pixel's interface names.

   The owner made this the prerequisite before paid networking is reconsidered.
2. **Batch E performance** on devices with four players.
3. **Batch F final integration:** full regression, security review, performance and packaging review. No publication without
   authorization.
4. **The CRT-03 remainder:** confirm or build a player-to-player courtship stage. No new rule may be invented; MP-D8 consent and
   the existing courtship rules apply.
5. **Device checks of MP-INTERACT-01, MP-PLAYER-FAMILY and B21-LAN-PLAYTEST** (`playtest` fields).

## 5. Deferred and superseded

| Item | Disposition | Source |
|---|---|---|
| MP-INTERACT-Q1 (player-to-player service contracts) | DEFERRED; goods contracts kept | Owner 2026-10-28 |
| MP-ADOPTION-AGENCY | DEFERRED | Register |
| Relay options B-E (STUN hole punching, own relay, commercial relay, Steam) | Not adopted: option A "for now"; architecture kept extensible | MP-INET-RELAY, owner 2026-10-30 |
| MP-01 (two-player LAN prototype) and `docs/multiplayer/PROTOTYPE_MULTIPLAYER_2026-10-19.md`; `wip/multiplayer` `d18d7d1` | SUPERSEDED by MP-MASTER | Register |
| `wip/mp-batch-c-snapshot` `8897246` | SUPERSEDED: an unreviewed work-in-progress snapshot; Batch C merged by another route | Branch |
| DGA-D3 "Connectivity with no server" (historical design proposal) | Answered in substance by MP-D5 and MP-INET-RELAY (SUPERSEDED; applied in the register 2026-10-31) | Register |
| `docs/multiplayer/MULTIPLAYER_PREPARATION.md` "Preparation only: nothing is implemented"; `MULTIPLAYER_BRANCH_AUDIT_2026-10-21.md` | HISTORICAL; implementation done since | This record |

## 6. Outstanding owner decisions

None open.
- MP-D1..D8, MP-Q-PLAYER-CHILDREN and MP-INTERACT-Q2 are APPROVED. For MP-INTERACT-Q2 the current selection is kept and Talk
  takes the nearest person.
- MP-INET-RELAY is APPROVED as option A.
- Paid networking returns to the owner only with the device-matrix report of real connection limitations.

**Conflicts found (agent documents against owner decisions; the decisions win).** `docs/CURRENT_DEVELOPMENT_STATE.md`
(updated 2026-10-30) says three things that are no longer true:
1. "MP-INTERACT-01 ... NOT YET INTEGRATED. Two open owner questions MP-INTERACT-Q1/Q2 remain." In fact it was integrated at
   `87b69ab` on 2026-10-27 and shipped in Build 23. Q1 is DEFERRED and Q2 APPROVED (2026-10-28).
2. "Owner decision MP-INET-RELAY open". In fact the owner answered option A on 2026-10-30.
3. The register's MP-INTERACT-01 `next_action` calls Q2 "DEFERRED". Q2's disposition is APPROVED.

No owner-against-owner conflict was found. The 2026-10-24 order (Build 19, then full multiplayer, then Expansion 20) was
carried out through Builds 20-21. It is consistent with later decisions.

## 7. Dependencies

- Host authority, saves and conservation share `World.transactions` and the economy (X20-MP-ECON-INTEGRITY).
- Device checks depend on the owner's hardware.
- Any relay needs a new owner decision on cost.

## 8. References

**Branches**
- `wip/multiplayer-b19` `6567c04` (Batches A-C, Build 21);
- `wip/x20-mp-interact` `0ce4c9e`;
- `wip/x20-mptest`, `wip/x20-mprec`;
- `wip/mp-batchd` `49932ec`;
- `wip/x20-mp-econ` `d20f63f`.

All are merged into `wip/expansion20` (`ad281dc`). Superseded: `wip/multiplayer` `d18d7d1` and `wip/mp-batch-c-snapshot`
`8897246`.

**Builds**
- Build 20 `56c24cb`: Checkpoint 1, inactive multiplayer foundations, throwaway signing key.
- Build 21 `6567c04`: LAN playtest.
- Build 22 `b7e1c91`: player families.
- Build 23 `c79b12c`: MP-INTERACT-01.
- Build 24 `4611d86`: frozen; holds no Batch D.

**Notes**
- `docs/multiplayer/BATCH_A..C.md`, `BATCH_D_CONNECTIVITY.md`; `docs/expansion20/MP_TEST_MATRIX.md`, `MP_INTERACT_AUDIT.md`
  (`wip/expansion20`).
- `docs/multiplayer/MULTIPLAYER_PREPARATION.md` (staging, historical plan with the gates G0-G10).

## 9. Next authorized phase

- Batch D and multiplayer economy integrity are inside the Build 25 candidate `ad281dc`. They are frozen with it only after the
  validation passes and the owner approves it.
- Build 26 consolidates.
- The real-device matrix needs the owner's devices and may proceed when the owner schedules it.
- No paid networking, no Steam integration, no publication.

**Pending document replacement (DOC-AUTH-01, owner 2026-10-31).** The owner is preparing a revised set of expansion
specifications. It supersedes this record's design sources only after the owner explicitly approves the final set. Until
then, the latest explicit owner decisions and the validated baseline govern.

## 10. Sources checked

- Every multiplayer directive cited is present in `docs/directives/`.
- The Batch A-D and test-matrix notes exist only on `wip/expansion20`, not on staging; they are to be consolidated in Build 26.
- No missing owner source was found for this track.
