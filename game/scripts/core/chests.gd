class_name Chests
extends RefCounted
## PL2-002: usable storage chests, crates and barrels with ownership, locks and lockpicking.
## A "unit" is one storage place: a chest spot in a building's interior ("chest:<building>:<k>") or a
## crate or barrel of village.json's containers (its id, "c12"). Ownership (agent proposal, docs/BUILD_DECISIONS.md):
##   own      the player's family chest and any container in a house or workshop the family holds:
##            store and take freely (only the family chest is p.chest; the rest is a saved stash).
##   foreign  another household's chest (its pantry), the tavern's or a stall's stock (their owner's
##            inv): you may look and take (theft, witnessed) but not store; locked ones need a lockpick.
##   decor    a chest in a building nobody holds (the manor's own are the reeve household's, locked hard): for show, holds nothing, public storage never.
## Locks (`locks`, saved): level 0 none, 1 to 3 harder. Owners lock some chests; a picked lock stays open
## for the rest of that day and is locked again at dawn. The player locks their own chest with a padlock
## (an item, forged at the anvil) and opens it with the key (free). Goods only move: nothing is made or lost.

var w: World
var locks := {}            # unit id -> {level, locked, picked_day, own}   (only what differs from the default)
var stash := {}            # unit id -> Inventory   (player-held containers other than the family chest)


func _init(world: World) -> void:
	w = world


# ---------------------------------------------------------------- units -------------------------
## The units inside a building: its chest spots, in order.
func units_in(bid: String) -> Array:
	var out := []
	var k := 0
	for s in w.interiors.get(bid, {}).get("spots", []):
		if s.kind == "chest":
			out.append({"id": "chest:%s:%d" % [bid, k], "kind": "chest", "bid": bid, "at": Vector2(int(s.at[0]), int(s.at[1])) + Vector2(0.5, 0.5)})
			k += 1
	return out


## A crate or barrel (a village.json container) as a unit; tables and stalls are not units.
func unit_of_container(c: Dictionary) -> Dictionary:
	return {"id": str(c.id), "kind": str(c.kind), "bid": str(c.at), "c": c, "at": Vector2(int(c.x), int(c.y)) + Vector2(0.5, 0.5)}


func unit(id: String) -> Dictionary:
	if id.begins_with("cart:"):                  # B14: a cart's load (Carts)
		var c: Dictionary = w.carts.by_id(int(id.trim_prefix("cart:")))
		return {} if c.is_empty() else {"id": id, "kind": "cart", "bid": "", "cart": c, "at": c.pos}
	if id.begins_with("chest:"):
		var parts := id.split(":")
		for u in units_in(parts[1]):
			if u.id == id:
				return u
		return {}
	var c := w.container(id)
	return unit_of_container(c) if not c.is_empty() and c.kind != "table" else {}


## Everything about a unit now: {access, store (Inventory or null), owner (NPC or null), whose, family,
## business}. `family` is the player's family chest (p.chest).
func info(u: Dictionary) -> Dictionary:
	var bid: String = u.bid
	var p := w.player
	if u.has("cart"):
		return _info_cart(u)
	if u.has("c"):
		return _info_container(u)
	if not w.buildings.has(bid):
		return _decor(u)
	var b: Dictionary = w.buildings[bid]
	var ref := w.holder_of(b)
	if ref == World.PLAYER:
		if bid == p.home:
			return {"access": "own", "store": p.chest, "owner": null, "whose": "your", "family": true, "business": false}
		return {"access": "own", "store": _stash(u.id), "owner": null, "whose": "your", "family": false, "business": false}
	if str(b.type) == "tavern":
		var k := w.tavern_keeper()
		if k:
			return {"access": "foreign", "store": k.inv, "owner": k, "whose": "the tavern's", "family": false, "business": true}
		return _decor(u)
	if ref.begins_with("hh:"):
		var o := w.party(ref)
		var hh: int = w.ref_id(ref)
		if o and hh >= 0 and hh < w.households.size():
			var manor := str(b.type) == "manor"
			return {"access": "foreign", "store": w.households[hh].pantry, "owner": o, "manor": manor, "family": false, "business": false,
				"whose": "the manor's" if manor else "the %s household's" % w.households[hh].family}
	return _decor(u)


## A cart's load: the owner's to fill; anyone else's to take from only as theft (its owner a household adult).
func _info_cart(u: Dictionary) -> Dictionary:
	var c: Dictionary = u.cart
	var owner := str(c.owner)
	if owner == World.PLAYER:
		return {"access": "own", "store": c.store, "owner": null, "whose": "your", "family": false, "business": false}
	return {"access": "foreign", "store": c.store, "owner": w.party(owner), "whose": w.carts.whose(c), "family": false, "business": false}


func _decor(_u: Dictionary) -> Dictionary:
	return {"access": "decor", "store": null, "owner": null, "whose": "nobody's", "family": false, "business": false}


func _info_container(u: Dictionary) -> Dictionary:
	var c: Dictionary = u.c
	if w.buildings.has(c.at) and w.holder_of(w.buildings[c.at]) == World.PLAYER:
		return {"access": "own", "store": _stash(u.id), "owner": null, "whose": "your", "family": false, "business": false}
	var store := w.container_store(c)
	if store == null:
		return _decor(u)
	return {"access": "foreign", "store": store, "owner": w.container_owner(c), "whose": w.container_whose(c), "family": false,
		"business": w.stalls.has(c.at) or w._is_tavern(c.at)}


func _stash(id: String) -> Inventory:
	if not stash.has(id):
		stash[id] = Inventory.new()
	return stash[id]


## What can be taken, in order: a business's stock excludes the owner's work tools.
func goods(u: Dictionary) -> Array:
	var i := info(u)
	if i.store == null:
		return []
	if i.business and i.owner != null:
		return w.brain.for_sale(i.owner)
	return i.store.ids()


## The place named for witnesses and messages: "the Reed household's chest".
func place(u: Dictionary) -> String:
	var i := info(u)
	return "%s %s" % [i.whose, u.kind]


# ---------------------------------------------------------------- locks -------------------------
func _default_level(u: Dictionary, i: Dictionary) -> int:
	if i.access != "foreign" or u.has("c") or u.has("cart"):
		return 0
	if i.business:
		return 2
	if i.get("manor", false):
		return 3
	var h: int = absi(hash(u.id))
	return 0 if h % 3 != 0 else 1 + (h / 3) % 3


## {level, locked, picked_day, own} now. A foreign lock is shut again from the day after it was picked.
func lock_of(u: Dictionary) -> Dictionary:
	var i := info(u)
	var d := _default_level(u, i)
	var s: Dictionary = locks.get(u.id, {})
	var level := int(s.get("level", d))
	var locked: bool = bool(s.get("locked", d > 0))
	var day := int(s.get("picked_day", -1))
	if i.access == "foreign" and locked and day == w.day():
		locked = false
	return {"level": level, "locked": level > 0 and locked, "picked_day": day, "own": i.access == "own"}


func is_locked(u: Dictionary) -> bool:
	return bool(lock_of(u).locked)


## Why the player may not open it at all ("" if they may): decorative chests, and empty owners.
func cannot_open(u: Dictionary) -> String:
	var i := info(u)
	if i.access == "decor":
		return "This chest is only for show: there is nothing in it."
	return ""


## Fit a padlock to your own chest (it uses one up) or turn the key. Returns "" or why not.
func set_own_lock(u: Dictionary, shut: bool) -> String:
	var i := info(u)
	if i.access != "own":
		return "It is not your chest."
	var s: Dictionary = locks.get(u.id, {})
	if int(s.get("level", 0)) <= 0:
		if not shut:
			return "It has no lock."
		if not w.player.inv.has("padlock"):
			return "You need a padlock. The smith sells them."
		w.player.inv.remove("padlock")
		s = {"level": int(GameData.item("padlock").get("lock_level", 2)), "locked": true}
	else:
		s["locked"] = shut
	locks[u.id] = s
	return ""


# ---------------------------------------------------------------- storing and taking ------------
## Put `qty` from the pack into a chest the player owns. Returns "" or why not.
func store(u: Dictionary, id: String, qty: int) -> String:
	var i := info(u)
	if i.access == "decor":
		return cannot_open(u)
	if i.access != "own":
		return "That is not yours to fill."
	if qty < 1 or not w.player.inv.has(id, qty):
		return "You do not have that."
	if u.has("cart") and w.carts.room(u.cart) < qty:
		return "The minecart is full."                 # MIN-F2: a minecart's capacity
	if not w.transfer(w.player.inv, i.store, id, qty):
		return "The chest is full."
	w.player.store_marks(id, qty)
	return ""


## Take `qty` from a chest into the pack. In your own it is free; in anyone else's it is theft, seen by
## whoever is in the room (the same crime, witness and guard rules as before). Returns {ok, text, seen}.
func take(u: Dictionary, id: String, qty: int) -> Dictionary:
	var i := info(u)
	var p := w.player
	if i.access == "decor":
		return {"ok": false, "text": cannot_open(u), "seen": 0}
	if is_locked(u) and i.access == "foreign":
		return {"ok": false, "text": "It is locked.", "seen": 0}
	if i.store == null or qty < 1 or not goods(u).has(id) or i.store.count(id) < qty:
		return {"ok": false, "text": "There is not that much.", "seen": 0}
	if not p.inv.can_add(id):
		return {"ok": false, "text": p.inv.full_text(id), "seen": 0}
	w.transfer(i.store, p.inv, id, qty)
	if i.access == "own":
		p.take_marks(id, qty)
		return {"ok": true, "text": "You take %d %s." % [qty, GameData.item_name(id).to_lower()], "seen": 0}
	var victim: NPC = i.owner
	if victim:
		p.mark_stolen(id, victim.id, qty)
	var seen := w.witness("theft", "%d %s from %s" % [qty, GameData.item_name(id).to_lower(), place(u)], victim, {id: qty}, i.store)
	return {"ok": true, "theft": true, "seen": seen, "text": "You take %d %s from %s. %s" % [qty, GameData.item_name(id).to_lower(), place(u),
		"Nobody saw." if seen == 0 else "%d %s saw you!" % [seen, "person" if seen == 1 else "people"]]}


# ---------------------------------------------------------------- lockpicking -------------------
## Chance one attempt opens the lock: Stealth against the lock's level.
func pick_chance(u: Dictionary) -> float:
	var lv := int(lock_of(u).level)
	return clampf(float(GameData.b("lockpick_base")) + float(GameData.b("lockpick_per_skill")) * (w.player.level("stealth") - 1)
		- float(GameData.b("lockpick_per_lock")) * (lv - 1), float(GameData.b("lockpick_min")), float(GameData.b("lockpick_max")))


## Game minutes an attempt takes: longer for harder locks.
func pick_minutes(u: Dictionary) -> float:
	return float(GameData.b("lockpick_minutes")) * maxi(1, int(lock_of(u).level))


## What stops an attempt before it starts ("" if it can start).
func cannot_pick(u: Dictionary) -> String:
	var i := info(u)
	if i.access != "foreign":
		return "This is not a lock you need to pick."
	if not is_locked(u):
		return "It is not locked."
	if not w.player.inv.has("lockpick"):
		return "You need a lockpick. The smith sells them."
	return ""


## One attempt (the caller spent the time). `roll` < 0 draws from the world's RNG, tests pass a fixed one.
## Success opens the lock until dawn; failure may break the pick. Any attempt is a crime on record:
## those in the room see you (a quiet success is only seen within half the witness radius, a failure or
## a snapped pick is noisy and seen at the full radius), a guard among them fines you as for theft.
## Returns {result: open|fail|broke|cant, text, seen}.
func attempt(u: Dictionary, roll := -1.0, break_roll := -1.0) -> Dictionary:
	var why := cannot_pick(u)
	if why != "":
		return {"result": "cant", "text": why, "seen": 0}
	var p := w.player
	var r := roll if roll >= 0.0 else w.rng.randf()
	var i := info(u)
	var radius := float(GameData.b("witness_radius"))
	var res := ""
	var text := ""
	if r < pick_chance(u):
		res = "open"
		var s: Dictionary = locks.get(u.id, {})
		s["level"] = int(lock_of(u).level)
		s["locked"] = true
		s["picked_day"] = w.day()
		locks[u.id] = s
		text = "Click. The lock gives way."
		radius *= float(GameData.b("lockpick_quiet"))
	else:
		var br := break_roll if break_roll >= 0.0 else w.rng.randf()
		if br < float(GameData.b("lockpick_break")):
			p.inv.remove("lockpick")
			res = "broke"
			text = "The lockpick snaps in the lock!"
		else:
			res = "fail"
			text = "The lock holds. You scrape and fail."
	var seen := w.witness("lockpicking", "the lock of %s" % place(u), i.owner, {}, null,
			"try to pick the lock of %s" % place(u) if res != "open" else "pick the lock of %s" % place(u), radius)
	var said := text + (" Nobody noticed." if seen == 0 else " %d %s saw you!" % [seen, "person" if seen == 1 else "people"])
	if w.last_guard != "":
		said += " " + w.last_guard
	return {"result": res, "text": said, "seen": seen}


# ---------------------------------------------------------------- save --------------------------
func to_dict() -> Dictionary:
	var st := {}
	for id in stash:
		if stash[id].total() > 0:
			st[id] = stash[id].to_dict()
	return {"locks": locks.duplicate(true), "stash": st}


func load_dict(d: Dictionary) -> void:
	locks = {}
	for id in d.get("locks", {}):
		var s: Dictionary = d.locks[id]
		locks[str(id)] = {"level": int(s.get("level", 0)), "locked": bool(s.get("locked", true)), "picked_day": int(s.get("picked_day", -1))}
	stash = {}
	for id in d.get("stash", {}):
		stash[str(id)] = Inventory.from_dict(d.stash[id])
