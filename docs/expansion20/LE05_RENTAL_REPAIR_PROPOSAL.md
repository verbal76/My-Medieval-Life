# LE-05 proposal: tool repair and tool rental (OD-LE-08 D07), NOT implemented

Owner answer OD-LE-08 (D07 answer B): "Keep existing barter. Renting, repair and substitutes selected as economic extensions: model
real assets, time, repairs and contracts in phased LE work, not an immediate overhaul or infinite transformation recipes."
X20-SCOPE authorises building it in LE-02..LE-05 behind the switch. The lead asked for a design to review before any code
(2026-10-30). Status: **proposal for review; nothing built.**

## 0. What exists today (facts, read from the code)

- **Wear exists and is saved.** Tools and weapons carry `durability` in `game/data/items.json` (axe 120, pickaxe 120, ... up to 600).
  `Inventory.wear(id, amount)` lowers the durability of the unit in use (`Inventory.durability[id]`, saved with the inventory);
  at 0 the unit breaks (removed; the next unit of that id starts full). `World._work_wear` wears a pickaxe 1 a swing and an axe 3 a
  felling, unless the worker's skill spares it (`tool_wear_save`, `axe_wear_save`). Breaks are counted (`broke_<tool>`).
- **Wear does not travel with a tool.** `Inventory.add/remove` move units only; the receiving inventory's own `durability[id]`
  applies, so a worn axe sold or given becomes as good as the receiver's (often new). This is an existing gap in asset accounting
  (design s.3 "model real assets"): a rental or a sale of a worn tool cannot be modelled honestly until it is closed.
- **No repair exists.** No recipe restores durability; a tool is used until it breaks and is replaced (EQ-19 manor support, a
  smith's forge, a merchant's stock).

So "tool wear is new persisted state" is only partly true: per-holder, per-id wear is already saved; what is new is wear that
belongs to a particular tool and moves with it.

## 1. What wears

Only what wears today: items with `durability` in `items.json`, by the existing `_work_wear` rates. No new wear source, no new rate.

## 2. Wear that moves with the tool (prerequisite; behind the switch)

With the economy on, a transfer of a durable item between holders carries the moved unit's remaining durability: the sender's
in-use unit leaves with `durability[id]` (or full when untouched), and the receiver stores it as its in-use unit only when it held
none of that id (else it queues the unit's wear in a small per-holder list, bounded by the units held). Applies to `World.trade`,
`World.transfer` and the authority's moves. Economy off: unchanged (the current per-holder rule).
**Saves:** the optional per-inventory `wear_queue` (only for units with less than full durability; bounded by the units held).
Older saves: no queue, every unit at the current rule.

## 3. Repair

- **Who:** a smith (any villager or the player with Smithing at the recipe's level and an anvil they may use), as an ordinary
  recipe step: the existing crafting path (`World.work_craft`, the player's crafting window, the smith's brain), no new work system.
- **Inputs and rate, from existing data only:** restoring a tool from durability `d` to full costs its forge recipe's inputs in
  proportion to the missing share, rounded up to whole units: `ceil(in_qty x (full - d) / full)` of each input of the item's own
  `forge_<id>` recipe, and the same share of its minutes and experience. (An axe at half wear: 1 iron bar, 1 plank, 30 minutes.)
  No new number. Items with no forge recipe are not repairable (stated, not invented).
- **As a service between people:** a CON-02-style service contract is the natural vehicle, and it is behind the `market.services`
  flag (off) until its own review; for LE-05 repair is something a holder does to its own tool, or a smith does to its own stock.

## 4. Rental (through World.transactions)

- **Who rents:** a worker short of its trade's tool (the existing `tool_short`/EQ-19 needers) may rent from a holder with a spare
  (a merchant, a smith, any villager holding more than it `keeps`), found through its own knowledge (LE-02 sources), weighed by
  `JudgmentWeighting.choose` (opinion one factor; refusal valid).
- **Terms:** a fee per day and a deposit, both coins; the deposit is the tool's value (`GameData.value`), the fee the share of its
  value its wear rate consumes a working day (the existing `_work_wear` rate x a day's uses / durability), so renting costs what
  the use wears away. No new number beyond these.
- **Mechanics:** `World.transactions.ship`-like custody: the tool moves to the renter (its wear travelling with it, section 2);
  the deposit is escrowed by the authority; each day the fee moves renter -> owner by `transfer_coins` (recorded); on return the
  tool comes back with its wear and the deposit is released; if the tool breaks or is not returned by the term's end, the deposit
  goes to the owner (`settle`), and a renter who died is settled to its estate (`settle_estate`). One rental record per tool,
  saved; closed rentals pruned (bounded, like shipments).
- **Saves:** additive optional keys only: `economy.rentals` (open rentals, bounded by tools lent) and the per-inventory
  `wear_queue` (section 2). No `SAVE_VERSION` change; an older save has none.

## 5. With the economy off

Nothing: no wear transfer, no repair recipe offered, no rental; saves gain no key; G0 identical. (If the owner wants repair in
the shipped game for the player too, that is a separate decision: it would add a recipe the player sees.)

## 6. What the player would feel (for the owner's package)

- Worn tools keep their wear when sold, given or rented (today a worn tool can become new by changing hands).
- Repair as a crafting option at an anvil, costing part of the forge inputs by the wear.
- Workers without a tool may rent one instead of waiting; the player could rent from or to villagers (a window: later).

## 7. Order of work if approved

(1) wear travels with the tool (section 2) and its tests (conservation of wear); (2) repair recipes derived from forge recipes;
(3) rental through the authority. Each behind the switch with failing-first tests, the economy-off identity shown by sim_gate.
