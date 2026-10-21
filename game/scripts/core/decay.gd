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
## Wear: clothes and armour worn wear by one a day of wear (items.json durability, in days worn): the player's body
## and head slots, and a villager's own armour (the guards' leather). When one wears out it is gone (broke_<item>, as
## tools are counted): the player's slot is emptied, a villager loses its protection. Carts wear by the tiles they are
## pulled (decay.cart_tiles); a worn-out cart falls apart and what it held is left lying where it stood (loot), so no
## good is lost with it. Conditions are shown in words (condition): new, worn, well worn, falling apart.

const WORN_SLOTS := ["armor", "head"]


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
static func spoil_inv(w: World, inv: Inventory, key: String) -> int:
	if inv == null:
		return 0
	var lost := 0
	for id in inv.ids():
		var k := spoiled(inv.count(id), rate(id), draw(w.seed, w.day(), key, id))
		if k > 0 and inv.remove(id, k):
			w.stat("spoiled_" + id, float(k))
			w.stat("decay_" + id, float(k))           # the part of spoiled_ that is stores spoiling (diagnostics)
			lost += k
	return lost


## The same for a stall's or shop's stock or store (item -> count dictionaries).
static func spoil_dict(w: World, d: Dictionary, key: String) -> int:
	var lost := 0
	var ids := d.keys()
	ids.sort()
	for id in ids:
		var c := int(d[id])
		var k := spoiled(c, rate(id), draw(w.seed, w.day(), key, id))
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
	for n: NPC in w.npcs:
		if n.alive:
			lost += spoil_inv(w, n.inv, "npc:%d" % n.id)
	for h in w.households.size():
		lost += spoil_inv(w, w.households[h].pantry, "hh:%d" % h)
	lost += spoil_inv(w, w.granary, "granary")
	lost += spoil_inv(w, w.player.inv, "player")
	lost += spoil_inv(w, w.player.chest, "chest")
	for c in w.containers:
		if c.kind == "table" and c.has("inv"):
			lost += spoil_inv(w, c.inv, "table:" + str(c.id))
	for c in w.carts.carts:
		lost += spoil_inv(w, c.store, "cart:%d" % int(c.id))
	for i in w.loot.size():                         # what lies on the ground (a carcass spoils whole: World._new_day)
		if not str(w.loot[i].from).begins_with("the "):
			lost += spoil_inv(w, w.loot[i].inv, "loot:%d" % i)
	var mw: ManorWork = w.manor_work
	for l in mw.lots:
		lost += spoil_inv(w, l.inv, "lot:" + str(l.id))
	lost += spoil_inv(w, mw.yard, "yard")
	for j in mw.jobs:
		lost += spoil_inv(w, j.load, "job:" + str(j.id))
	var shops: Array = []
	for s in w.business.premises() + w.business.stalls.npc_built():
		if not shops.has(s):
			shops.append(s)
	for s: Dictionary in shops:
		for part in ["stock", "store"]:
			if s.get(part) is Dictionary:
				lost += spoil_dict(w, s[part], "%s:%s:%s" % [str(s.get("id", "")), part, str(s.get("x", ""))])
	if lost > 0:
		w.stat("spoiled_total", float(lost))
	wear_clothes(w)


## A day's wear of the clothes and armour people wear: the player's body and head slots, and each living villager's own
## armour (the first armour item it holds, by id: the guards' leather).
static func wear_clothes(w: World) -> void:
	var p := w.player
	if p.alive:
		for slot in WORN_SLOTS:
			var id := str(p.get(slot))
			if id != "" and p.inv.has(id) and p.inv.wear(id, 1):
				w.stat("broke_" + id)
				w.note("Your %s wore out." % GameData.item_name(id).to_lower())
				if not p.inv.has(id):
					p.set(slot, "")
					p.fit_caps()
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		var id := worn_armour(n)
		if id != "" and n.inv.wear(id, 1):
			w.stat("broke_" + id)
			if not n.inv.has(id):
				n.armor = maxf(0.0, n.armor - float(GameData.item(id).get("armor", 0)))


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
