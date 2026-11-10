class_name Decay
extends RefCounted
## DVW-B4 (Designing Virtual Worlds B4, owner-approved with gentle rates: "stored grain spoils slowly; clothes, armour
## and carts wear"): goods do not last for ever, so they stop piling up.
##
## Spoilage: each dawn every perishable good (balance.json decay.spoil: a fraction a day for each item; grain slowest,
## cooked food, milk and raw meat fastest) loses that fraction of every stack wherever it is kept: villagers' packs,
## household pantries, the granary, the player's pack and family chest, the tavern tables, carts, goods left lying, the manor's lots,
## works yard and job loads, and the stock and store of every stall and shop. The whole part of count x rate goes; the
## fraction left over goes as one more unit when a draw hashed from the world seed, the day, the holder and the item
## falls under it, so the expected loss is exactly the rate, small stacks spoil too, and no world.rng draw is taken.
## What spoils is counted as spoiled_<item> (the goods ledger's drain, as carcasses left lying already are), and the
## same again as decay_<item> (diagnostics: the part of spoiled_ that is stores spoiling, not carcasses).
##
## Wear: clothes and armour worn wear by one a day of wear (items.json durability, in days worn), and by blow_wear more
## for each blow taken: the player's body and head slots, and a villager's own armour (the guards' leather). A guard
## whose armour wore out buys another from a seller with its own coins (plan_rearm). When one wears out it is gone (broke_<item>, as
## tools are counted): the player's slot is emptied, a villager loses its protection. Carts wear by the tiles they are
## pulled (decay.cart_tiles); a worn-out cart falls apart and what it held is left lying where it stood (loot), so no
## good is lost with it. Conditions are shown in words (condition): new, worn, well worn, falling apart.

const WORN_SLOTS := ["armor", "head"]

## INV-02 PROTOTYPE (B25-INV02-SPOIL-D1, owner: approved in principle, investigate before implementation;
## docs/design/INV02_SPOILAGE_PROPOSAL.md). OFF: nothing below changes the game unless `storage_on` is set (tests and
## measurement runs only, economy_sim --spoil-storage). On, each holder has a storage class whose multiplier scales the
## item's base rate (decay.spoil), and the holders Decay.dawn does not reach today (the players' other containers, the
## homestead chests, the pens' troughs) spoil too. Proposed values, not approved; the shipped version moves them to
## balance.json.
static var storage_on := false
const STORAGE := {"open": 1.5, "carried": 1.0, "home": 1.0, "cellar": 0.5}


## The multiplier of a storage class: 1.0 (today's rule, exactly) while the prototype is off.
static func smul(cls: String) -> float:
	return float(STORAGE.get(cls, 1.0)) if storage_on else 1.0


static func cfg() -> Dictionary:
	return GameData.b("decay")


## The daily spoil fraction of an item (0 for goods that keep).
static func rate(id: String) -> float:
	return float(cfg().spoil.get(id, 0.0))


## A fixed draw in [0, 1) for this world, day, holder and item (no world.rng: the same on every machine and run).
static func draw(seed: int, day: int, key: String, id: String) -> float:
	var h := ("%d|%d|%s|%s" % [seed, day, key, id]).hash()
	return float(absi(h) % 100000) / 100000.0


## How many of `count` units spoil today.
static func spoiled(count: int, r: float, u: float) -> int:
	if count <= 0 or r <= 0.0:
		return 0
	var q := float(count) * r
	var k := floori(q)
	if u < q - float(k):
		k += 1
	return mini(k, count)


## Spoil one inventory's perishables for the day. Returns the units lost.
static func spoil_inv(w: World, inv: Inventory, key: String, m: float = 1.0) -> int:
	if inv == null:
		return 0
	var lost := 0
	for id in inv.ids():
		var k := spoiled(inv.count(id), rate(id) * m, draw(w.seed, w.day(), key, id))
		if k > 0 and inv.remove(id, k):
			w.stat("spoiled_" + id, float(k))
			w.stat("decay_" + id, float(k))           # the part of spoiled_ that is stores spoiling (diagnostics)
			lost += k
	return lost


## The same for a stall's or shop's stock or store (item -> count dictionaries).
static func spoil_dict(w: World, d: Dictionary, key: String, m: float = 1.0) -> int:
	var lost := 0
	var ids := d.keys()
	ids.sort()
	for id in ids:
		var c := int(d[id])
		var k := spoiled(c, rate(id) * m, draw(w.seed, w.day(), key, id))
		if k <= 0:
			continue
		if c - k <= 0:
			d.erase(id)
		else:
			d[id] = c - k
		w.stat("spoiled_" + id, float(k))
		w.stat("decay_" + id, float(k))
		lost += k
	return lost


## Dawn (NPCBrain.dawn): a day's spoilage everywhere goods are kept, and a day's wear of what is worn.
static func dawn(w: World) -> void:
	var lost := 0
	var carried := smul("carried")                  # INV-02 prototype: every multiplier is 1.0 while it is off
	var home := smul("home")
	var open := smul("open")
	var cellar := smul("cellar")
	var g0 := lost
	for n: NPC in w.npcs:
		if n.alive:
			lost += spoil_inv(w, n.inv, "npc:%d" % n.id, carried)
	g0 = _diag(w, "npc_packs", lost, g0)
	for h in w.households.size():
		lost += spoil_inv(w, w.households[h].pantry, "hh:%d" % h, home)
	g0 = _diag(w, "pantries", lost, g0)
	lost += spoil_inv(w, w.granary, "granary", cellar)
	g0 = _diag(w, "granary", lost, g0)
	if w.chapel != null:                            # DVW-B4 "wherever it is kept": the chapel's store (food offered and grown)
		var ch := spoil_inv(w, w.chapel.store, "chapel", home)
		for pc in w.chapel.parcels:                 # CHAPEL-PURPOSE: its food on the way to a household spoils as any store does
			ch += spoil_inv(w, pc.inv, "chapel_parcel:%d" % int(pc.id), carried)
		if ch > 0:
			w.stat("chapel_spoiled", float(ch))
		lost += ch
	g0 = _diag(w, "chapel", lost, g0)
	for pl: PlayerState in w.player_list():         # MP C2: every player's pack and chest (the host's keys as before)
		var host: bool = w.is_host(pl)
		lost += spoil_inv(w, pl.inv, "player" if host else w.player_ref(pl), carried)
		lost += spoil_inv(w, pl.chest, "chest" if host else w.player_ref(pl) + ":chest", home)
	g0 = _diag(w, "players", lost, g0)
	for c in w.containers:
		if c.kind == "table" and c.has("inv"):
			lost += spoil_inv(w, c.inv, "table:" + str(c.id), open)
	g0 = _diag(w, "tables", lost, g0)
	for c in w.carts.carts:
		lost += spoil_inv(w, c.store, "cart:%d" % int(c.id), carried)
	g0 = _diag(w, "carts", lost, g0)
	for i in w.loot.size():                         # what lies on the ground (a carcass spoils whole: World._new_day)
		if not str(w.loot[i].from).begins_with("the "):
			lost += spoil_inv(w, w.loot[i].inv, "loot:%d" % i, open)
	g0 = _diag(w, "loot", lost, g0)
	var mw: ManorWork = w.manor_work
	for l in mw.lots:
		lost += spoil_inv(w, l.inv, "lot:" + str(l.id), open)
	lost += spoil_inv(w, mw.yard, "yard", home)
	for j in mw.jobs:
		lost += spoil_inv(w, j.load, "job:" + str(j.id), carried)
	g0 = _diag(w, "manor_work", lost, g0)
	var shops: Array = []
	for s in w.business.all_premises() + w.business.stalls.npc_built():
		if not shops.has(s):
			shops.append(s)
	for s: Dictionary in shops:
		for part in ["stock", "store", "work"]:
			if s.get(part) is Dictionary:
				lost += spoil_dict(w, s[part], "%s:%s:%s" % [str(s.get("id", "")), part, str(s.get("x", ""))], home)
	g0 = _diag(w, "shops", lost, g0)
	if storage_on:
		lost += _spoil_unreached(w)
	if lost > 0:
		w.stat("spoiled_total", float(lost))
	wear_clothes(w)


## INV-02 prototype only: the units a holder group lost today (inv02_spoiled_<group>, diagnostics), counted only while
## the prototype is on, so the shipped run's stats are unchanged. Returns the new running total.
static func _diag(w: World, group: String, lost: int, before: int) -> int:
	if storage_on and lost > before:
		w.stat("inv02_spoiled_" + group, float(lost - before))
	return lost


## INV-02 prototype only: the holders today's rule does not reach. The players' other containers (Chests.stash: a crate
## or chest at home, a barrel a cellar), the homestead chests (Homesteads claims' store) and the wheat in the pens'
## troughs (open). The courier booths and loads on the road, and the off-map settlements, are left out: their own books
## (deposits, delivery quantities, OffMapSettlement flows) would need a spoil line first (proposal, section F).
static func _spoil_unreached(w: World) -> int:
	var lost := 0
	var kinds := {}
	for c in w.containers:
		kinds[str(c.id)] = str(c.kind)
	var ks: Array = w.chests.stash.keys()
	ks.sort()
	for k in ks:
		var cls := "cellar" if str(kinds.get(str(k), "")) == "barrel" else "home"
		lost += spoil_inv(w, w.chests.stash[k], "stash:" + str(k), smul(cls))
	var g0 := _diag(w, "stash", lost, 0)
	if w.homesteads != null:
		for c in w.homesteads.claims:
			lost += spoil_inv(w, c.store, "homestead:" + str(c.id), smul("home"))
	g0 = _diag(w, "homesteads", lost, g0)
	var pens: Array = w.fauna.pens.keys()
	pens.sort()
	for id in pens:
		var pen: Dictionary = w.fauna.pens[id]
		var k := spoiled(int(pen.trough), rate("wheat") * smul("open"), draw(w.seed, w.day(), "trough:" + str(id), "wheat"))
		if k > 0:
			pen.trough = int(pen.trough) - k
			w.stat("spoiled_wheat", float(k))
			w.stat("decay_wheat", float(k))
			lost += k
	_diag(w, "troughs", lost, g0)
	return lost


## A day's wear of the clothes and armour people wear: the player's body and head slots, and each living villager's own
## armour (the first armour item it holds, by id: the guards' leather).
static func wear_clothes(w: World) -> void:
	for pl: PlayerState in w.active_players():          # a guest away (MP-D1) wears nothing out
		wear_player(w, 1, pl)
	for n: NPC in w.npcs:
		if n.alive:
			wear_npc(w, n, 1)


## Wear what the player wears (body and head) by `amount`; a piece worn out is gone and its slot empties.
static func wear_player(w: World, amount: int, actor: PlayerState = null) -> void:
	if actor != null and actor != w.player:
		w.as_actor(actor, wear_player.bind(w, amount))
		return
	var p := w.player
	if not p.alive:
		return
	for slot in WORN_SLOTS:
		var id := str(p.get(slot))
		if id != "" and p.inv.has(id) and p.inv.wear(id, amount):
			w.stat("broke_" + id)
			w.note("Your %s wore out." % GameData.item_name(id).to_lower())
			if not p.inv.has(id):
				p.set(slot, "")
				p.fit_caps()


## Wear a villager's own armour by `amount`; worn out, it is gone and its protection with it.
static func wear_npc(w: World, n: NPC, amount: int) -> void:
	var id := worn_armour(n)
	if id != "" and n.inv.wear(id, amount):
		w.stat("broke_" + id)
		if not n.inv.has(id):
			n.armor = maxf(0.0, n.armor - float(GameData.item(id).get("armor", 0)))


## A blow taken (World.damage_player, World.harm_npc): what is worn takes decay.blow_wear more wear. Hunger and spoiled
## food are not blows.
static func blow_player(w: World, source: String, actor: PlayerState = null) -> void:
	if actor != null and actor != w.player:
		w.as_actor(actor, blow_player.bind(w, source))
		return
	if source in ["hunger", "spoiled food"]:
		return
	wear_player(w, int(cfg().blow_wear))


static func blow_npc(w: World, n: NPC) -> void:
	if n.alive:
		wear_npc(w, n, int(cfg().blow_wear))


## A guard whose armour wore out buys decay.rearm_item again from a villager selling it, with its own coins, by the
## ordinary buying rule (NPCBrain act buy_from; World.can_afford keeps its household's reserve): nothing is given. In
## shop hours, and only when it can pay now. Once it holds armour again, the armour's protection comes back (never
## lowering what it has). True when it set off to buy (NPCBrain._guard).
static func plan_rearm(w: World, n: NPC) -> bool:
	var have := worn_armour(n)
	if have != "":
		n.armor = maxf(n.armor, float(GameData.item(have).get("armor", 0)))
		return false
	var h := w.hour()
	if h < NPCBrain.WORK_START or h >= NPCBrain.WORK_END or n.role != "adult":
		return false
	var item := str(cfg().rearm_item)
	var v := armour_seller(w, n, item)
	if v == null:
		return false
	n.doing = "buying new %s" % GameData.item_name(item).to_lower()
	n.plan = [w.brain.go(w.brain._workplace_cell(v)), w.brain.doit("buy_from", {"vendor": v.id, "item": item, "qty": 1})]
	return true


## The villager selling `item` that `n` can pay for now (the cheapest, then the lowest id), or null: someone holding one
## it does not keep (the goods merchant, the tanner who makes it), at the price it would ask `n`, within World.can_afford.
static func armour_seller(w: World, n: NPC, item: String) -> NPC:
	var best: NPC = null
	var best_p := 1 << 30
	for o: NPC in w.npcs:
		if o == n or not o.alive or o.role != "adult" or not o.inv.has(item) or w.brain.keeps(o, item):
			continue
		var price := w.deal_price(w.sell_price(o, item), n, o)
		if price < best_p and w.can_afford(n, price, false, item):
			best = o
			best_p = price
	return best


## The armour item a villager wears: the first armour or head piece it holds that wears (items.json durability), by id.
static func worn_armour(n: NPC) -> String:
	for id in n.inv.ids():
		var it := GameData.item(id)
		if str(it.get("type", "")) in ["armor", "head"] and int(it.get("durability", 0)) > 0:
			return id
	return ""


## A word for how worn something is, from what is left of `full`: "new", "worn", "well worn", "falling apart".
static func condition(left: float, full: float) -> String:
	if full <= 0.0:
		return ""
	var f := left / full
	if f > 0.75:
		return "new"
	if f > 0.4:
		return "worn"
	if f > 0.15:
		return "well worn"
	return "falling apart"


## How a perishable keeps, for the player ("" for goods that keep): "spoils slowly", "spoils within days".
static func keeping_text(id: String) -> String:
	var r := rate(id)
	if r <= 0.0:
		return ""
	if r < 0.01:
		return "Keeps well, but spoils slowly in store (about %s in a hundred a day)." % str(snappedf(r * 100.0, 0.1))
	if r < 0.05:
		return "Spoils in store, about %d in a hundred a day." % roundi(r * 100.0)
	return "Spoils quickly: about %d in a hundred are lost each day." % roundi(r * 100.0)
