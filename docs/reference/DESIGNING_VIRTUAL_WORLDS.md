# Designing Virtual Worlds: what it means for My Medieval Life

**The book:** Richard A. Bartle, *Designing Virtual Worlds* (2003), 947 PDF pages. This edition is released
under CC BY-NC-ND 4.0. The owner supplied it on 2026-10-19 as the GitHub release "Book":
`DesigningVirtualWorlds.pdf`, sha256 `1f1581dd…3090`, checked on download. The PDF is not copied into
the repository; this file and the notes beside it quote it only briefly.

**How it was read:**
- The whole book was read by six readers in parallel, each covering a contiguous run of printed pages:
  1–156, 157–318, 319–455, 456–616, 617–821 and 822–937.
- Each reader's full notes are in `docs/reference/designing_virtual_worlds/notes_*.md`. They hold a summary per section, principles with page-cited quotes, actionable items, warnings, and a section 6 on the owner's planned player-hosted multiplayer.
- This file merges and de-duplicates those items. The lead agent checked the ones that make claims about our code; each is marked VERIFIED, NOT VERIFIED or ALREADY DONE.

**The one-paragraph lesson:** the book's strongest warnings match where the game is heading.
- A closed, real economy needs every **faucet and drain** measured (where coins and goods enter and leave).
- Players with nothing worth spending on make money worthless, and goods that never decay pile up.
- A living world must keep running away from the player.
- Permadeath must feel fair: the risk is visible beforehand and the cause clear afterwards.
- Relationships keep players longer than achievement; that is our weakest side, since villagers only remember "met".
- Fast travel and convenience shortcuts quietly break economies and geography.

## A. Fix or check now (no new mechanic, no owner decision needed)

| # | Item | Book | Our code | Plan |
|---|---|---|---|---|
| A1 | Stale heir comment: `world.gd` said the heir keeps "half of each skill's experience"; the owner's rule is that skills start from nothing | E, pp. 561–570 | VERIFIED; **fixed in this commit** | Done |
| A2 | Keep several dated save backups, not one `.bak` replaced on every save | A, p. 154 | VERIFIED: `save_store.gd` kept one `.bak` | **Done 2026-10-20:** the game's save also keeps the previous save under each day's date, three days, and Continue falls back to them (`SaveStore.dated_backups`; tests in `run_tests.gd`, `start_test.gd`) |
| A3 | Re-measure the money supply on today's rules: 100 and 365 days, 2–3 seeds, no player. Record currency per head, who holds it and the treasury | CD, pp. 353, 408 | VERIFIED: `LONG_RUN_SIMULATION.md` dates from Build 7 | Agent: rerun `econ_report`, publish the numbers |
| A4 | One faucet and drain ledger for coins, and one per item: what enters and leaves the village, kept apart from transfers inside it | CD, p. 354 | `coin_sources` exists; no single breakdown | Agent: generate the table from stats |
| A5 | An "exploit player" test: buy low, sell high, round trips, cornering a good, flooding with local pricing | A, pp. 151–152; CD, pp. 402–404; F1, p. 751 | VERIFIED: from Trading 4 the margin (0.736 vs 0.778 × value) allows a small profit, up to about 35% at Trading 10. Merchants' purses and stock bound it; it moves coins, it does not mint them | Agent: a test pinning the bound. **Owner:** is honest arbitrage intended (a medieval merchant's trade)? Recommended: yes, bounded |
| A6 | Coins and goods conserved across save/load and between the near and far simulation tiers | CD; F1, p. 754 | Coin conservation is tested in runs; save round trips are not | Agent: add the test |
| A7 | Over-production from raising skills by use (Ultima Online's flood) | F1, p. 751 | NOT VERIFIED | Agent: measure goods made only for XP over a long run |
| A8 | Audit perks only the player gets, against "the same rules" | CD, pp. 391–393, 432 | NOT VERIFIED: saplings from felling, overworld gathering, the fireball | Agent: list them; each is shared or gets a written reason |
| A9 | The player can always get away: wolves, bears and bandits give up a chase | E, p. 555 | NOT VERIFIED (B14 predators chase within their wood) | Agent: a test that a level-1 heir escapes |
| A10 | No "black hole" spaces you can enter but not leave | F1, p. 644 | — | Built into the cliff-steps task (B14-07) |
| A11 | Threats never scale to the player's skill or wealth | F1, p. 821; F2, p. 909 | VERIFIED: none do | Keep it; recorded as a rule |
| A12 | Keep game rules in `game/scripts/core/`, not the UI, so a future host can be the authority | A, pp. 140–148 | `main.gd` holds some rules (crime, storefront targets) | Agent: an audit list. Moving them is later work |
| A13 | Every visible object has a use: no dead props, no items that go nowhere | F2, p. 859 | Mostly: `resources.json` exceptions list feathers and handcarts | Handcarts get their use in B14-06 |
| A14 | Before each release, someone plays one whole life, from a new game to the heir | B, p. 272; F1, p. 625 | Never done; headless only | **Owner** or a tester: a release checklist line |

## B. Owner decisions: new mechanics the book argues for (CLAUDE.md §11)

These are ordered by how strongly the book and our gaps support them. Each is a recommendation only.

| # | Proposal | Why (book) | Gap in the game now | Recommendation |
|---|---|---|---|---|
| B1 | **Villager relationships:** a memory of favours, gifts and harms that greetings, prices and help read; villagers sharing news (gossip) | Relationships retain players more than achievement does (B, pp. 201, 205, 249) | Villagers remember only "met" and a few event strings. Socializer players are the least served | **Yes, first.** It feeds quests, crime, trading and heirs |
| B2 | **Assault and killing as recorded crimes**, weighted above theft, with fines; decide what passes to an heir (unpaid fines, a fading family stain) | The world permitting something reads as permission (F1, pp. 728–737, 734) | VERIFIED: theft is recorded and fined; an attack only turns guards and the victim hostile (`main.gd::_crime`) | Yes |
| B3 | **Spending people enjoy (coin sinks):** luxury caravan imports, feasts and weddings, chapel offerings, a heriot or relief paid to the manor on succession | Ultima Online's economy broke because there was nothing to buy (CD, pp. 408, 417; E, p. 566) | Build 7 had median household wealth of 842 coins; the treasury idles | Yes, after A3 measures the need |
| B4 | **Goods decay:** stored grain spoils slowly; clothes, armour and carts wear | Sinks for goods stop accumulation (CD, pp. 408, 413) | Only 8 tools and carcasses wear or spoil; farmers held 14,495 wheat in Build 7 | Yes, gentle rates |
| B5 | **Predictable taxes:** a band with hysteresis (a rate change waits for a margin, so it doesn't flip back and forth), announced with a reason; lower taxes when the treasury is full | Players hate changing tax rates (F1, pp. 752–756) | VERIFIED: the rate jumps between 6% and 12% at one threshold | Yes (small) |
| B6 | **Wildlife regrowth from outside:** game wanders in from the overworld at about the rate it is taken, never from fixed respawn points | E, pp. 462–465; A, p. 30 | B14 protects a breeding pair from NPCs, but the player can still kill the last pair | Yes; it also suits the skeletons' respawn |
| B7 | **A chronicle of each life:** titles from deeds, a biography, a memorial, a definite end per life before the heir | B, p. 249; E, p. 587; F2, pp. 908–912 | Only a death cause and a note line | Yes; strengthens permadeath |
| B8 | **Skills for farming, husbandry, hunting and healing** | Selective depth tells players what the game is about (E, pp. 482–483) | Combat has the richest skill effects | Consider |
| B9 | **Readable danger:** threat cues (a predator's howl or roar, bandit signs), warnings before needs turn lethal, the cause on the succession screen | E, pp. 549, 563–565 | Partly (the death screen names the cause) | Yes (uses unused MiniFolks roar and howl rows) |
| B10 | **Onboarding:** the first ten minutes (a greeter, something striking within five minutes, controls revealed gradually) | B, pp. 192–193, 287, 301 | One hint line | Yes, before a public build |
| B11 | **No instant fast travel;** any shortcut costs time and money | B, p. 314; F1, p. 759 | None exists (good) | Record as a rule |
| B12 | **Ethics and lore:** decide thralldom (Morris's Utterbol) as an evil to oppose, never trade in; the Church present but with no mechanical effects; a short content note (permadeath, family deaths, violence, hunting) | F2, pp. 892–916 | U21 is open | Owner's call |
| B13 | **Story kept as sparks:** the Well stays world history, never the player's main quest; story quests short and optional; quests that leave lasting changes | F2, pp. 872–877 | Matches Confirmed 7. Need-based quests already change the world | Keep; agent audit of `story: true` quests |

## C. Already consistent with the book

These need no work now:
- **A real, managed open economy:** "nothing from nowhere", with the caravan as a controlled faucet. The book's warning against a closed currency matches our own Build 7 failure.
- **The same economic rules for the player and NPCs.**
- **Stealable physical money,** with no banks.
- **Need-based quests** that change the simulation.
- **Shallow, optional carts:** four parts, and a finished cart can be bought. This answers the book's "50 components to make a cart" warning.
- **Permadeath with heirs** and no softened consequences.
- **No threat scaling,** and no compulsion loot loops.

## D. For the future player-hosted multiplayer (3–4 players; Confirmed 10)

The details are in section 6 of each notes file. The core items:
- **Host authority:** only the host creates coins and items, and checks every guest request. This makes A12 the groundwork.
- **Atomic trades:** a trade saves both sides together, so nothing duplicates on a disconnect or reload.
- **Ownership:** an explicit owner on every item and property.
- **Player-versus-player:** harm between players is off by default, set when the world is created and shown to guests; permadeath is a separate setting.
- **Absent guests:** their characters leave the world, or are kept per world, rather than starving under the NPC rules. This is an owner decision.
- **Shared clock:** one clock for everyone, with no solo time skips.
- **Shared resources:** quests, plots, ore and animals are shared by up to four players, so the long simulation needs a four-player run.
- **Testing:** an early two-player test.

## What the agent does next without waiting

- **A1:** done in this commit.
- **A2 to A9 and A12:** checks, tests and measurements. They change no rules and are folded into the queue after carts in play (B14-06).
- **A10:** goes into the cliff-steps task.
- **B items:** wait for the owner's choice.
