# JUICE-00: preliminary Game Juice and player-feedback assessment

Branch `wip/juice-assessment`, created from Build 17's frozen playtest code (`dfec7ec`). Authority: owner directive
2026-10-22, `docs/directives/2026-10-22_game_juice_preliminary_assessment.md` (staging `e006465`): "a separate,
unnumbered presentation workstream. This is planning and evaluation only. Do not implement effects or change gameplay
without approval." Objective: make existing simulation activity "more visible, understandable, and satisfying without
changing its underlying behavior."

**Read-only.** No code, asset, data, build, simulation or register change. Every statement is one of three kinds, labelled:
- **CONFIRMED**: observed in the Build 17 code or records, with `file::function` (scripts under `game/scripts/`);
- **RECOMMENDATION**: an agent proposal inside the directive's constraints (a real event, event-driven, cheap, same style,
  no change to rules, timing, values or determinism);
- **IDEA NEEDING APPROVAL**: touches a design choice, a register item, new art direction, or something the owner has not
  decided.

Constraints applied to every proposal: the effect is triggered by an event that already happens (a signal, a function
already called, a value that already changes); nothing is drawn that implies a mechanic the game lacks; no `World.rng`
draw (cosmetic randomness uses Godot's own `randi()`, as `main.gd::_on_bled` already does: "looks only: not the world's
RNG"); no per-frame scan of the population added; Android is the slowest target (CLAUDE.md section 8).

---

## 1. Inventory of current feedback (CONFIRMED)

### 1.1 Movement and interaction

| What | Where | Notes |
|---|---|---|
| 8-direction walk, sprint plays the walk faster | `view/actor_sprite.gd` (`ANIMS`, `speed_scale`), `main.gd::_sprint_step` | Puny Characters sheet; no footstep dust or sound |
| Target prompt ("Mine iron ore (12 left)", "Talk to ...") and cycling | `main.gd::_find_target`, `cycle_target`, `_next_hint` | Text prompt at the bottom; clear and informative |
| Gather target outline | `main.gd::_sync_gather_mark` | A gold `Line2D` rectangle round the field, tree, animal or cell being gathered |
| Action progress bar | `ui/game_ui.gd::update_hud` (`action_bar` from `main.action`), `main.gd::start_action` | One bar for every timed action (craft, dig, sample, chop) |
| Reach refusals and results as a toast | `ui/game_ui.gd::message` (4 s, bottom middle) | Used for nearly every interaction's outcome (`main.gd::_use`) |
| Roof and canopy fades | `view/roof_fade.gd::follow`, `view/canopy_fade.gd::update` | Polished: holds against flicker, cheap per-cell checks |
| Placement ghost (green/red footprint, door) | `view/placement_ghost.gd::show_at` | Building and farm placement |
| Underground darkness round the player | `view/level_view.gd::_dark_texture`, `follow` | Atmosphere only (MIN-A) |

### 1.2 Activities

| Activity | Feedback today | Where |
|---|---|---|
| **Forestry** (the most complete) | Trunk shudder per blow, four flying chips, falling leaves; the top falls away from the axe with a poof where it lands; stump redraw; growth stages | `view/tree_view.gd::_on_hit`, `_fly`, `_on_felled`, `_poof` (Living Forest `fx_chip_*`, `fx_poof_*`) |
| **Mining** | Swing with the pickaxe icon drawn in the hand; "+n ore" gain line; the seam's sprite changes when worked out; pits, spoil heaps, terraces, rails and supports drawn | `view/actor_sprite.gd::hold`, `_place_tool`; `main.gd::_gain`; `World.level_tile_changed` -> `main.gd::_on_level_tile_changed`; `view/pit_view.gd::_draw`, `view/works_view.gd`; clues `view/clue_view.gd::_draw`. No impact effect on a blow (no chips, dust or sparks) |
| **Farming** | Arms-forward gather frames; field tiles change with the crop; harvest gain line | `npc_brain.gd::work_look` ("gather"), `world.gd::_field_tiles`, `main.gd::_gain` |
| **Crafting** | Swing (anvil, forge, workbench, sawhorse) or gather frames; progress bar; gain line | `npc_brain.gd::work_look` ("craft"), `main.gd::craft`, `start_action` |
| **Construction** | A frame site with a progress bar over it; the building appears when finished | `main.gd::_sync_sites`, `_on_building_added` |
| **Tools** | Tool icon in the hand during swings (player and villagers); a broken tool is counted, with a message | `view/actor_sprite.gd::hold`; `npc_brain.gd::work_look` |
| **Skills** | Level-up text in the toast ("Mining is now level 3! Unlocked: ...") | `main.gd::_level_up` (on `World.player_leveled`) |

### 1.3 NPCs and animals

| What | Where |
|---|---|
| Villagers' work look (swing with pickaxe, axe, hammer, rusty sword; gather) | `npc_brain.gd::work_look`, applied in `main.gd::_sync_sprites` |
| Sleeping in beds under blankets, sitting on chairs | `view/actor_sprite.gd::lie`, `sit`; `main.gd::_show_sleeper`, `_show_sitter` |
| Speech bubbles (busy villagers call out a line) | `view/speech_bubble.gd`, `main.gd::say`, `approach`, `_sync_bubbles` |
| Quest markers (bobbing icon over a giver) and employer stars | `main.gd::_sync_diamonds`, `_sync_stars` (`assets/markers/*`) |
| Death: the fall frames, then the body blinks before vanishing | `main.gd::_sync_sprites` (`int(left * 12.0) % 2`) |
| Animals: idle, walk, graze, sleep, attack, hit, death rows by sheet | `view/animal_sprite.gd::show_state` (`ROWS`, `FARM`) |
| Culling: sprites only within 30 tiles of the camera | `main.gd::_sync_sprites` (`near`) |

### 1.4 Combat and danger

| What | Where |
|---|---|
| Hit flash (red modulate, 0.25 s), floating damage number, a small HP bar for 3 s | `main.gd::_hit_fx` (B8R-012 hit feedback, COMPLETE) |
| Blood pools that fade (`assets/fx/blood_*`, Kenney Splat) | `main.gd::_on_bled` on `World.bled` (OWN-25) |
| Fireball projectile | `main.gd::fireball`, `_projectiles_step` |
| Attack target marker | `main.gd::_sync_sprites` (`target_marker`) |
| The `hurt` animation (columns 19-21) exists on the sheet but is never played | `view/actor_sprite.gd` `ANIMS.hurt`; no `play("hurt")` anywhere |

### 1.5 Trade, inventory, money, notifications

| What | Where |
|---|---|
| Coins as a number in the HUD; no change animation | `ui/game_ui.gd::update_hud` (`coins_label.text`) |
| Gain lines with the item's icon, top right, 1.5 s | `ui/game_ui.gd::gain` (`GAIN_SECONDS`) |
| Village events (every `World.note`) in the same corner log, 2 lines, 3 s each; the full record under the Menu | `main.gd` (`world.event.connect(... ui.log_line)`), `ui/game_ui.gd::log_line`, `_add_log` (`LOG_LINES` 2, `LOG_SECONDS` 3.0), `world.gd::note` |
| Trade, stall, chest, inventory, quantity windows | `ui/game_ui.gd` (`show_trade`, `_deal_row`), `ui/stall_window.gd`, `ui/chest_window.gd`, `ui/inventory_window.gd`, `ui/quantity_picker.gd` |
| Stall auto-close notification | STALL-03 (COMPLETE) |

### 1.6 Atmosphere, sound, settings, accessibility

| What | State | Where |
|---|---|---|
| Day and night | **No lighting change**: the clock and the sleep schedule exist, the picture does not darken | no `CanvasModulate` or tint in `main.gd` or `view/*` (searched) |
| Weather | None in the game (no mechanic) | — |
| Seasons | Fruit trees and plants change by season; trees have seasonal variants | `world.gd::season_plants`, `view/tree_view.gd::refresh` |
| Audio | **No sound plays.** Music and SFX buses are created and volume settings exist | `ui/game_settings.gd::_buses` ("the game has no sounds yet; they will play on these"), `master`, `music`, `sfx` |
| Settings | Display mode, window size, vsync, FPS cap (0/30/60/120), UI size (small/normal/large), touch buttons (auto/always/never), phone layout | `ui/game_settings.gd` (`UI_SIZES`, `FPS_CAPS`, `LAYOUT_HEIGHT`) |
| Accessibility | UI size only; no colour-blind mode, key rebinding, text scaling beyond UI size, or option to stop the blinking | B12A-05 (APPROVED idea, NOT STARTED) lists exactly these |

### 1.7 Reusable assets already owned (CONFIRMED from `docs/assets/ASSET_REGISTRY.md` and `packs.json`)

| Asset | State | Use it could serve |
|---|---|---|
| **Living Forest: 20 sound effects (chopping, falling) and night fireflies** | Owned, licence "use, modify and ship packed in own games" (private-assets workflow); registry: "unused" | Chop and fall sounds; fireflies at night |
| Living Forest `fx_dust_0/1` | **Imported** into `game/assets/trees/` and listed in `trees.json` `effects.dust`, but no script reads it (`tree_view.gd` uses only `chips` and `poof`) | Dust puff on a fall, a footstep or a dig |
| **Puny Skills** (1,719 PNG effect sheets: hit, slash, bleeding, healing, status) | Owned (paid), 0 imported; registry opportunity "Hit and slash effects" | Impact sparks, healing glow when medicine is used, hit slashes |
| Puny Characters `hurt` frames | Imported, unused | The flinch on a blow |
| `assets/ui/*` (Sungraphica UI: coins, health, hunger, fire, gather ...) | Integrated | HUD pulses and icons |
| Forgotten Memories animated water and waterfalls (6 frames) | Owned, partial | Moving water where water already is (no new mechanic) |
| Craftpix crop growth stages and produce crates | Owned, partial (B14-10, B12A-07) | Readable crop stages; stall displays |
| **FR-08 "Music and sound" is BLOCKED with "no audio supplied"** | Register (staging) | The Living Forest sounds are supplied audio; the blocker is partly out of date (section 6, D1) |

### 1.8 Performance notes (CONFIRMED)

- `main.gd::_sync_diamonds` and `_sync_stars` walk every villager every frame (bob by `Time.get_ticks_msec`). Not new
  work, but any new marker should not add another such loop.
- Effects already use short-lived nodes and tweens freed at the end (`tree_view.gd::_fly`, `main.gd::_on_bled`,
  `_hit_fx`): the pattern to reuse.

---

## 2. Opportunities by activity

Each line: what real event triggers it, and the label.

### 2.1 Movement and interaction
- **R** A tiny dust puff under the feet when sprinting starts or turns sharply, from `fx_dust_*` (already imported).
  Trigger: `main.gd::_sprint_step` state change, not every step. Cost: one sprite and tween per trigger.
- **R** Pulse the target prompt once when the target changes (`main.gd::_find_target` result differs), so a
  phone player sees the change without reading.
- **R** A one-shot "done" pop on the action bar when an action completes (`start_action`'s `done` callback), and a
  short shake of the bar on a refusal (`ui.message` from `_use`'s reach refusals).

### 2.2 Mining and digging
- **R** Stone chips and a dust puff from the seam on each completed blow, mirroring forestry's `_on_hit` (the chips can
  be grey recolours of the existing chip sprites or a few procedural pixels, as `pit_view.gd` draws). Trigger: the
  swing's completion in `main.gd::_gather_step` / the villager's `mine` act completion, not per frame.
- **R** A brief flash on the seam when it is worked out (`World.level_tile_changed` / `tile_changed` already fires).
- **R** A puff of earth on each dug unit of a pit (`main.gd::_pit_dig`, `_trial_dig`, `_tunnel_cut` complete).
- **IDEA** A collapse shake and dust burst when a support caves in (MIN-F2 `mine_works.gd` dawn); screen shake needs
  an accessibility toggle (D4).

### 2.3 Forestry
- Already the reference. **R** Play the Living Forest chop and fall sounds on `World.tree_hit` and `tree_felled`
  (once audio is approved, D1). **R** Use the unused `fx_dust_*` at the landing alongside `_poof`.

### 2.4 Farming and animals
- **R** A few grain flecks when a field is cut or sown (the `harvest`/`sow` acts complete; `World.set_field`).
- **IDEA** Craftpix crop stages where they read better (overlaps B14-10 and B12A-07; not new work here).
- **R** A small heart/eat icon is NOT proposed: it would imply a mood mechanic the game lacks.

### 2.5 Crafting and construction
- **R** Sparks at the anvil and forge on each completed craft cycle (Puny Skills small sparkle, or procedural pixels),
  sawdust at the sawhorse; trigger: `World.work_craft` completion for the player and for villagers within view.
- **R** On a building's completion (`World.building_added`, `main.gd::_on_building_added`): a dust burst at the frame
  and a one-line toast; on each delivery to a site (`World.deliver`), the site bar ticks with a short flash.

### 2.6 NPC animation and visible activity
- **R** Play the existing `hurt` frames on a blow (`main.gd::_hit` / `_hit_animal` already call `_hit_fx`): a real
  animation the sheet has and the game never shows.
- **R** Let a villager's speech bubble say what it is doing when the player is near and it changes task
  (`n.doing` already holds "felling a tree", "buying grain for the household"). It reflects real state; throttle to
  task changes within view.
- **IDEA** Reactions to witnessed crimes (a "!" over witnesses from `World.witness`'s seen list). Real event, but it
  borders on Expansion 19's judgment display (SJD-Q10: attitudes through behaviour, no numbers): owner's call.

### 2.7 Atmosphere, lighting, particles
- **IDEA** Day/night tint from the existing clock (one `CanvasModulate` updated each game hour from `World.hour()`):
  the cheapest large atmosphere gain, but it changes how the whole game looks and must not hide anything (D2).
- **IDEA** Fireflies at night in the woods (Living Forest), only with the night tint.
- **IDEA** Lit windows at night for occupied homes (real occupancy). Needs art and D2.
- **Not proposed:** weather (no weather mechanic; rain would imply one).

### 2.8 Trade, inventory, money
- **R** Coin counter tick: the HUD number counts to the new value over 0.3 s and pulses green/red on a change
  (`update_hud` already reads `p.coins`; compare to last value, no polling of anything new).
- **R** A coin icon flies from the trade window's row to the HUD purse on a sale or purchase (`World.trade` succeeds in
  `player_buy_many` / `player_sell_many`).
- **R** Split the corner log: gains (player) and village notes (world) in two places, so a gain is not pushed out by a
  village event (`LOG_LINES` 2 today shared by both). Wording unchanged.
- **IDEA** A notification filter (which village notes appear) in Settings (D5).

### 2.9 Combat and danger
- **R** `hurt` frames (above) and a Puny Skills slash/impact sprite on a landed blow (registry opportunity).
- **R** A healing glow when medicine is used (`World.player_use_medicine` succeeds; villagers' `_plan_heal` act).
- **Overlap:** DVW-B9 (readable danger: howl/roar cues, lethal-need warnings) is an approved requirement; this
  assessment does not duplicate it, and its cues should be implemented as DVW-B9.

### 2.10 Sound
- **R (with D1)** A minimal SFX layer on the existing SFX bus: chop and fall (Living Forest), and, if owned sounds exist
  for them, pickaxe, coin, UI click. Event-driven, one `AudioStreamPlayer2D` pool, distance-culled. Overlaps **FR-08**
  (BLOCKED, "no audio supplied") and supersedes nothing: this would be FR-08's first slice.
- Music: not in any owned pack found; FR-08.

### 2.11 Mobile readability, performance, accessibility
- **R** Every new effect obeys the existing 30-tile culling and a hard cap on live effect nodes (for example 40), and is
  skipped when FPS cap is 30 and the frame budget is exceeded.
- **R** One "Reduce effects" setting (shake, flashes, particles) and a "No blinking" option for the dead body blink:
  this is part of **B12A-05** (accessibility: "turning off the blinking"), not a new requirement.
- **R** Haptics on Android for a landed blow or a felled tree: IDEA (D4; a platform feature).

---

## 3. Priority ranking (player impact, effort, performance cost; Android first)

Impact: H/M/L. Effort: S (hours), M (a day or two), L (several days). Cost: per-event nodes unless stated.

| Rank | Improvement | Impact | Effort | Perf cost | Label | Register overlap |
|---|---|---|---|---|---|---|
| 1 | Mining blow chips and dust, seam worked-out flash | H (mining is Build 17's core) | S-M | ~6 sprites a blow, culled | R | none |
| 2 | Coin counter tick and pulse; coin fly on trade | H (every trade) | S | UI only | R | none |
| 3 | Play the `hurt` frames; slash sprite on hits | M-H | S | none / one sprite | R | B8R-012 done; extends it |
| 4 | Split gains from village notes in the corner log | H (readability, phone) | S | none | R | none |
| 5 | Crafting sparks / sawdust; build completion burst; delivery tick | M | S-M | per event | R | none |
| 6 | Reduce-effects and no-blinking options | M (accessibility) | S | none | R | **B12A-05** (do it as B12A-05) |
| 7 | SFX layer: Living Forest chop and fall, then others owned | H | M | audio pool, culled | R needing D1 | **FR-08** (unblocks it) |
| 8 | Unused `fx_dust` on felling, sprint start, pit digs | L-M | S | per event | R | none |
| 9 | Day/night tint from the clock (and fireflies after) | H | M | one node, hourly update | IDEA (D2) | none found |
| 10 | Villager "what I'm doing" bubble on task change near the player | M | S | throttled bubbles | R needing D3 (chatter volume) | OWN-19 (busy-villager bubbles, PARTIALLY IMPLEMENTED: extend, not duplicate) |

Recommended order: 4, 2, 1, 3, 6 (quick wins, no decisions), then 5, 8, then 7 after D1, 9 after D2, 10 after D3.

---

## 4. Quick wins versus larger upgrades

- **Quick wins (no art, no decision):** 2, 3, 4, 6, 8, and 1 using existing chip art recoloured or procedural pixels.
- **Larger upgrades:** the SFX layer (7: import pipeline for sounds, `asset-integration-pipeline` skill, credits,
  bus mixing, Android audio latency), day/night (9: art review of every scene at night, underground interplay with
  `LevelView`'s darkness), Puny Skills effect import (sheets measured and scaled by `tools/assets/sheets.py`),
  Craftpix crop stages (B14-10).

---

## 5. Dependencies on Expansions 18-21 (read-only from their branches)

| Expansion | Bearing on presentation |
|---|---|
| **18 Settlements** (`docs/expansion18/DESIGN.md`) | Its courier window (`ui/courier_window.gd`, no menu entry until integration) and settlement reports will need the same notification and trade feedback (coin tick, delivery arrival). Capability levels change work times by data (X18 s.9a): any animation timed to work must read the actual action length, never a fixed duration, or it will drift when the hook is on. |
| **19 Judgment** (`docs/expansion19/DESIGN.md`) | SJD-Q10: "No exact numbers in normal gameplay; attitudes through behaviour". Any reaction icon (2.6 IDEA) or attitude display must follow Q10 and wait for its words. Gossip is the event channel for social reactions. |
| **20 Living Economy** (`docs/expansion20/LE00_ARCHITECTURE_AUDIT.md`) | OD-LE-14 ("player intervention and visibility of market decisions") decides what market activity may be shown (offers, bids). Trade feedback built now must not imply negotiation that ordinary trade lacks today. |
| **21 Politics** (`docs/expansion21/PRELIMINARY_PLAN.md`) | Its public election interface (directive 2026-10-19 s.31), vote privacy, "believable feedback without exposing hidden simulation" are presentation requirements of that expansion; the notification split (rank 4) is the place their announcements would go. |

None blocks the quick wins; all argue for building a small shared, event-driven effects helper once, rather than
effects scattered through `main.gd`.

---

## 6. Design decisions needed (owner)

- **D1 Audio:** may the owned Living Forest sounds be integrated as FR-08's first slice (and which other owned packs,
  if any, carry sounds)? Which events get sound first? Default volumes?
- **D2 Day and night:** should the picture darken at night (how dark at midnight; interiors; underground already dark)?
  It is visible everywhere and affects screenshots and readability on phones.
- **D3 Villager chatter:** how often may villagers show what they are doing in bubbles (OWN-19 extension)?
- **D4 Screen shake and haptics:** allowed at all, on which events, and default on or off?
- **D5 Notifications:** which village notes the player sees in the corner log by default, and whether a filter exists.
- **D6 Effect art source:** Puny Skills effect sprites versus procedural pixels for chips, sparks and dust (style
  consistency; both are in style, the pack is richer).

---

## 7. Phased plan (proposal; nothing starts without approval)

| Phase | Content | Needs |
|---|---|---|
| **J1 Quick wins** | Ranks 4, 2, 3, 6 (B12A-05 slice), 8; a small `view/effects.gd` helper (pooled short-lived sprites, cap, culling, "Reduce effects" respected) | Owner approval of J1 only; no decision |
| **J2 Activity effects** | Ranks 1 and 5: mining, digging, crafting, building, delivery effects on the helper | J1 helper |
| **J3 Sound** | Rank 7 via FR-08: Living Forest chop and fall through the asset pipeline, credits, SFX bus; then other owned sounds | D1 |
| **J4 Atmosphere** | Rank 9 day/night tint, fireflies, lit windows if art exists | D2 |
| **J5 Social visibility** | Rank 10 and reactions, aligned with Expansion 19's Q10 words | D3; Expansion 19 |

Each phase: no change to rules, timing, values or determinism (a fingerprint comparison on a short `economy_sim` run
before and after, since cosmetic code must not touch `World.rng`); Android frame-time check on device; wiki pages only
where a setting is added (Settings help).

---

## 8. Proposed register handling (for the lead; not made)

- Record JUICE-00 (this assessment) as the unnumbered presentation workstream's first entry, with the branch and commit.
- Note on **FR-08** that owned audio exists (Living Forest's 20 sound effects), so "no audio supplied" is partly out of
  date; the owner decides (D1).
- Rank 6 belongs to **B12A-05**; rank 10 extends **OWN-19**; danger cues stay **DVW-B9**; crop stages stay
  **B14-10/B12A-07**; tool-swing art stays **B8-007/B12A-07**. No duplicate entries.

## 9. Wiki and documentation

- Player-facing wiki: nothing changed; none needed (no feature).
- Developer documentation: this file is new; nothing else edited.
