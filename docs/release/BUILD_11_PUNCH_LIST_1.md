# Build 11 punch list 1 (PL1)

The owner's Build 11 Windows playtest findings and approved feature direction ("My Medieval Life Build
11 Punch List 1 Master Prompt", received 2026-10-19), kept as open items next to punch list 2
(`BUILD_11_PUNCH_LIST_2.md`). IDs PL1-01 to PL1-13 follow the document's 13 sections. Sections 1-9 and
12-13 are the repair and usability queue; 10 and 11 are staged larger features. Report each as Fixed,
Partially Fixed, Not Started or Blocked. Owner's guidance: confirm what exists before changing it; root
causes; reuse systems and assets; keep saves where feasible; Windows, Android, Linux and Steam Deck,
with mouse, keyboard, touch and controller; conserve tokens; plan and ask before large architecture or
security decisions.

"Related" names work already done or under way that touches the item; it is not a claim the item is fixed.

| ID | Item | Kind | Status | Related |
|---|---|---|---|---|
| PL1-01 | **Critical:** closing Settings > Controls (X) leaves a grey world with the HUD on and the game unresponsive; trace visibility, camera, pause, input focus; repeat enter/exit with every input; no stacked menus or orphaned HUD | Bug | Not Started | — |
| PL1-02 | One Settings screen with tabs and a Back button (Esc and controller Back too), returning to the right screen with pause and input restored; settings persist; readable at all resolutions; must not bring back PL1-01 | UI | Not Started | — |
| PL1-03 | Merchant Buy/Sell quantity control: item, unit price, stock or owned, slider, -/+, Max, live total, Confirm, Cancel; buy max = min(stock, affordable), sell max = owned (merchant limits); atomic, never negative; all inputs | UI and trade | Not Started | PL2-012 asks the same controls for storage: one shared quantity control |
| PL1-04 | Dependable health recovery: audit damage, healing, food, rest, recipes; fix or add healing consumables (proposed: Linen Bandage 15 HP 3c, Herbal Poultice 30 HP 6c, Healing Tonic 50 HP 12c, Strong Healing Tonic 80 HP 22c, configurable) and an Apothecary shop; gatherable herbs, crafted bandages; one or two starting bandages; never above max, consumed only on success, no unbounded regeneration | Feature | Not Started | Herbal tonic at the stove exists (flowers, B8-015 of the old register) |
| PL1-05 | current/max centred inside the health, hunger and stamina bars (e.g. 85/100), high contrast with outline, live, correct with changing maxima; same icons, colours, size; no balance change | HUD | Partially Fixed (staging) | B8-019 (merged): bars show "Health 9/100", "Food 12%", "Stamina 42/100"; to finish: plain current/max for all three (Food shows a percentage), outline, check on phone and Steam Deck |
| PL1-06 | Every visible stone or boulder object minable with the pickaxe; small ones yield less and take less effort, large ones more; missing-tool message; depleted sprite and collision removed; saved; no invisible obstacles | Bug | Partially Fixed (staging) | B8-026 (merged): small grey boulders give stone (3 uses), village and overworld, saved; to check: other stone variants and size-based yield |
| PL1-07 | Manor family NPCs sunk into beds and chairs: anchors, sprite origins, poses, y-sort; proper sleep and sit, stand up after; no moving furniture to hide it; apply to other homes | Rendering bug | Done: pl-furniture (local, awaiting integration) | B8-025 (merged) y-sorts solid overlay tiles; PL2-013 (player sitting and lying) shares the pose work |
| PL1-08 | Consumables show their real health/hunger/stamina effects everywhere (inventory, hotbar, merchants, medicine) from item data; no double use, nothing consumed on a failed action; no silent rebalancing | UI | Not Started | Pack item details show uses ("Used for:"); effects not yet listed everywhere |
| PL1-09 | Gold star over the specific NPC whose job the player accepted and has not been paid for (not over everyone offering work); follows them, survives save/load by NPC id, clears only after delivery and payment; test: the eight-iron job | Feature | Not Started | Quests and the reeve's job board exist |
| PL1-10 | Optional player businesses and a demand-driven economy, staged: (1) rentable stall about 5 coins a day with listings, prices, sales records, no unattended magic sales; (2) NPCs buy only for real modelled needs within budgets, goods go into their inventories; (3) larger stalls, shops, equipment placement; (4) attendants, production chains | Major feature, staged | Not Started | Market stalls and their re-letting exist; economy work B7-014 to B7-016; PL2-008/014 building foundation |
| PL1-11 | Optional Google Drive cloud saves (bring your own cloud), staged: save portability audit; OAuth with drive.appdata, upload/download; conflicts (Keep Local / Use Cloud / Cancel) with backups and interrupted-transfer handling; opt-in auto sync; visible export/import. Tokens never in saves; offline play always works | Major feature, staged | Not Started; **needs owner approval** before implementation (online feature, CLAUDE.md section 11; Google OAuth app registration and consent screen) | SaveStore (atomic writes, backups, refusing unreadable saves) is the local base |
| PL1-12 | The low red flowering plant cannot be picked: identify its asset and definition, make every instance gatherable (feedback, item, icon, regrowth, saved); audit other decorative-looking plants; give harvested plants real uses | Bug | Not Started | PL2-006 (flowers outside the village); flowers and berry bushes in the village are pickable |
| PL1-13 | Stove unrecognisable among pots and pans: find the real station and its interaction zone; make it read as a medieval stove or hearth (cooking surface, firebox, stonework, chimney) in the same style; prompt "Use Stove", window "Stove — Cooking & Tonics"; hitbox matches; recipes kept | Visual | Not Started | PL2-010 (sawhorse) is the same kind of station redesign |

## Owner's recommended order

1. PL1-01 settings freeze; 2. PL1-02 tabbed Settings; 3. PL1-04 healing and Apothecary; 4. PL1-05 HUD
numbers and PL1-08 consumable clarity; 5. PL1-03 trade quantities and PL1-09 employer stars; 6. PL1-06
stones and PL1-12 red plant; 7. PL1-07 furniture poses and PL1-13 stove. Then the staged systems:
PL1-10 (stall, then real demand, then expansions) and PL1-11 (portability audit, manual Drive transfer,
conflict safety, then optional sync). The order may change for dependencies or to avoid interfering
with other agents; deferred stages are reported, never silently dropped.


**Status (updated for Build 13, 2026-10-19):** the Status column above is the list as received and is
no longer kept current. The current status of every item, with evidence, is in
`docs/DEVELOPMENT_LEDGER.md`; the Build 12 state is audited in `docs/release/BUILD_12_FULL_AUDIT.md`.
