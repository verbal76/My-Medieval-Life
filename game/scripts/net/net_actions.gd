class_name NetActions
extends RefCounted
## Multiplayer (docs/multiplayer/BATCH_A.md section A2, BATCH_C.md): a guest's action on the shared world is a request the host
## applies in its own World, as that guest: the same verb the host's own character uses, run inside World.as_actor(guest), so every
## rule, reach check, ledger count and record is the host's and the guest never creates coins, items or events. Requests are applied
## at one fixed point of the host's frame (NetSession.apply_requests, before World.update), in arrival order, so when two players
## reach for the same thing the second finds it taken.
##
## Batch C: "verb" is the request of every player verb (VERBS): the guest's World sends the outermost verb its interface calls
## (World.mirror), its arguments encoded (enc: villagers, players, animals, the world's records and stores by what names them on
## both machines, never by object), and the host decodes them in its own world (dec), checks that every player reference, person id,
## character and store among them is the guest's own and that what it acts on is within VERB_REACH of the guest, and calls the
## verb as the guest. The answer carries the result, the guest's character as the host has it, and the world sections that changed
## (NetSync). Unknown verbs and malformed or foreign arguments are refused. Kinds of A2 and B (eat, pick_plant, heir) stay.

const KINDS := ["eat", "pick_plant", "heir", "verb", "rest", "consent"]
const VERB_REACH := 24.0              # tiles: what a guest acts on is on its screen (the interface's own reach rules apply in the verb)

## Every player verb a guest's interface can call, by the path World.mirror sends: "" the World itself, "<field>." a module the World
## holds, "<Class>:" a static verb taking the World first. The sub-batch is the BATCH_C.md checklist row it belongs to.
const VERBS := {
	# C1: needs, health, death, equipment
	"player_eat": "C1", "player_use_medicine": "C1", "player_equip": "C1", "player_unequip": "C1", "player_drop": "C1",
	"player_yield": "C1", "player_wake": "C1", "player_rest": "C1",
	# C2: gathering, inventory, crafting, stations
	"player_pick_plant": "C2", "player_pick_fruit": "C2", "player_harvest": "C2", "player_mine": "C2", "player_chop": "C2",
	"player_craft_begin": "C2", "player_craft": "C2", "player_take": "C2", "container_store": "C2", "container_pick": "C2",
	"player_home_move": "C2", "player_loot": "C2", "player_plant_sapling": "C2", "plant_bush": "C2",
	"release_player_station": "C2", "chests.store": "C2", "chests.take": "C2", "chests.set_own_lock": "C2",
	"player_pick_lock": "C2", "note_player_work": "C2", "player_xp": "C2", "player_set_down_cart": "C2",
	# C3: economy
	"player_buy_many": "C3", "player_sell_many": "C3", "player_buy_pack_row": "C3", "player_barber_visit": "C3",
	"player_learn_fireball": "C3", "contracts.propose": "C3", "contracts.deliver": "C3", "contracts.cancel": "C3",
	"contracts.accept_offer": "C3", "contracts.counter_offer": "C3", "contracts.decline_offer": "C3", "credit.repay": "C3",
	"credit.answer_request": "C3", "ContractServices:player_report": "C3", "ContractServices:player_collect": "C3",
	"quests.accept": "C3", "quests.complete": "C3", "manor_work.order_backfill": "C3", "manor_work.stock_backfill": "C3",
	"manor_work.cancel_backfill": "C3", "manor_work.take": "C3",
	"couriers.open_shop_booth": "C3", "couriers.book_route": "C3", "couriers.negotiate": "C3", "couriers.book_special": "C3", "counters.summon": "C3", "construction.hire": "C3",
	"farm.buy_seed": "C3", "farm.buy_seed_item": "C3", "farm.buy_animal": "C3", "farm.buy_horse": "C3",
	# C4: property, construction, farms, pens, chests, carts, businesses
	"buy_plot": "C4", "start_site": "C4", "deliver": "C4", "cancel_site": "C4", "player_helper_budget": "C4",
	"property.buy": "C4", "property.lease": "C4", "property.claim": "C4", "property.set_home": "C4", "property.sell": "C4",
	"property.end_lease": "C4", "construction.build_stall": "C4", "farm.till": "C4", "farm.sow": "C4", "farm.build_pen": "C4",
	"farm.collect": "C4", "farm.clear_plant": "C4", "farm_plots.claim": "C4", "farm_plots.build_fence": "C4", "fauna.feed": "C4",
	"carts.place": "C4", "carts.park": "C4", "carts.hitch": "C4", "business.build_storefront": "C4", "business.open_front": "C4",
	"business.open_shop": "C4", "business.rent": "C4", "business.set_display": "C4", "business.store_item": "C4",
	"business.upgrade": "C4", "business.set_price": "C4", "business.sell": "C4", "business.hire": "C4", "fitting.place": "C4",
	"fitting.remove": "C4", "fitting.trade": "C4",
	# C5: society
	"relations.talked": "C5", "relations.give": "C5", "relations.befriend": "C5", "relations.ask_court": "C5",
	"relations.propose": "C5", "feast.player_feast": "C5", "chapel.player_ask": "C5", "chapel.player_offer_coins": "C5",
	"chapel.player_offer_item": "C5", "Guardianship:player_adopt": "C5", "player_offer": "C5", "player_answer": "C5",
	# C6: crime and combat
	"player_strike": "C6", "player_melee_npc": "C6", "player_hit_npc": "C6", "player_hit_animal": "C6",
	"player_cast_fireball": "C6", "player_fireball_hit": "C6", "pickpocket": "C6",
	# C7: underground levels
	"player_through": "C7", "mine_works.dig": "C7", "mine_works.dig_shaft": "C7", "mine_works.fill": "C7",
	"mine_works.set_down_minecart": "C7", "pits.open_pit": "C7", "pits.dig": "C7", "pits.backfill": "C7", "pits.take": "C7",
	"pits.tip": "C7", "discovery.trial_dig": "C7", "prospecting.place": "C7", "prospecting.take_sample": "C7",
	"prospecting.assay": "C7",
}


## Apply request `kind` for player `p` in world `w`. Returns {ok, text, player, result?} (and `heir_pid` after "heir").
static func apply(w: World, p: PlayerState, kind: String, args: Dictionary) -> Dictionary:
	if kind == "heir" and p != null:
		return _heir(w, p)
	if p == null or not p.alive:
		return _answer(w, p, false, "You cannot do that now.")
	match kind:
		"eat":
			return _eat(w, p, args)
		"pick_plant":
			return _pick_plant(w, p, args)
		"verb":
			return apply_verb(w, p, str(args.get("path", "")), args.get("a", []) if args.get("a", []) is Array else [])
	return _answer(w, p, false, "That cannot be done in a shared world yet.")


static func _answer(w: World, p: PlayerState, ok: bool, text: String, patches: Array = []) -> Dictionary:
	return {"ok": ok, "text": text, "player": p.to_dict() if p != null else {}, "patches": patches}


# ---------------------------------------------------------------- verbs (Batch C) ----------------
## The callable a verb path names in `w`, or an invalid Callable.
static func target(w: World, path: String) -> Callable:
	if not VERBS.has(path):
		return Callable()
	if path.contains(":"):
		var cls := path.get_slice(":", 0)
		var fn := path.get_slice(":", 1)
		if (cls == "Guardianship" and fn == "player_adopt") or (cls == "ContractServices" and fn in ["player_report", "player_collect"]):
			return func(): pass                       # called by name in apply_verb (a static verb taking the World or its contracts first)
		return Callable()
	if path.contains("."):
		var obj = w.get(path.get_slice(".", 0))
		var fn2 := path.get_slice(".", 1)
		if obj == null or not (obj is Object) or not (obj as Object).has_method(fn2):
			return Callable()
		return Callable(obj, fn2)
	return Callable(w, path) if w.has_method(path) else Callable()


## Host: apply verb `path` for guest `p` with the guest's encoded arguments. Refused: an unknown verb, an argument that does not
## decode in this world, anything naming another player (a reference, a person id, a character, a store of theirs), or something
## out of the guest's reach.
static func apply_verb(w: World, p: PlayerState, path: String, raw: Array) -> Dictionary:
	var c := target(w, path)
	if not c.is_valid():
		return _answer(w, p, false, "That cannot be done in a shared world.")
	var args := []
	var bad := {"why": ""}
	for v in raw:
		args.append(dec(w, p, v, bad))
	if path.begins_with("relations."):
		for a in args:                               # person ids (a giver, a suitor): only the guest's own, or a villager's
			if a is int and Life.is_player_id(a) and a != w.person_id(p):
				bad.why = "That is not yours."
	if bad.why != "":
		return _answer(w, p, false, str(bad.why))
	if path == "player_loot" and args.size() == 1 and args[0] is Dictionary:
		var i := w.loot.find(args[0])                 # the pile the guest named, wherever it is in the host's list
		if i < 0:
			return _answer(w, p, false, "That is not there any more.")
		args = [i]
	var far := _out_of_reach(w, p, args)
	if far:
		return _answer(w, p, false, "That is too far away.")
	var r = w.as_actor(p, func():
		match path:
			"Guardianship:player_adopt":
				return Guardianship.player_adopt(w, args[0]) if args.size() >= 1 else "Nothing to do."
			"ContractServices:player_report":
				return ContractServices.player_report(w.contracts, args[0]) if args.size() >= 1 else 0
			"ContractServices:player_collect":
				return ContractServices.player_collect(w.contracts, args[0]) if args.size() >= 1 else 0
		return c.callv(args))
	var text := ""
	if r is String:
		text = r
	elif r is Dictionary:
		text = str(r.get("text", r.get("why", "")))
	var out := _answer(w, p, true, text)
	out["result"] = enc(w, r)
	out["path"] = path
	return out


static func _pos_of(v) -> Variant:
	if v is NPC:
		return (v as NPC).pos
	if v is Animal:
		return (v as Animal).pos
	if v is Vector2:
		return v
	if v is Vector2i:
		return Vector2(v) + Vector2(0.5, 0.5)
	if v is Rect2i:
		return Vector2((v as Rect2i).position)
	if v is Dictionary:
		var d: Dictionary = v
		if d.has("x") and d.has("y") and (d.x is int or d.x is float):
			return Vector2(float(d.x), float(d.y))
		if d.get("pos") is Vector2:
			return d.pos
		if d.get("at") is Vector2:
			return d.at
	return null


static func _out_of_reach(w: World, p: PlayerState, args: Array) -> bool:
	for v in args:
		var at = _pos_of(v)
		if at != null and (at as Vector2).distance_to(p.pos) > VERB_REACH:
			return true
	return false


# ---------------------------------------------------------------- the codec ----------------------
## An argument as both machines can name it. Villagers, players and animals by id; the world's records by their kind and key; the
## acting player's own pack and chest by those words; other stores by their holder. Plain values as they are (ENet carries
## Vector2, Vector2i and Rect2i). `null` for what cannot be named (the caller refuses to send it).
static func enc(w: World, v) -> Variant:
	if v == null or v is bool or v is int or v is float or v is String or v is StringName or v is Vector2 or v is Vector2i:
		return v
	if v is Rect2i:
		return {"$rect": [v.position.x, v.position.y, v.size.x, v.size.y]}
	if v is NPC:
		return {"$npc": (v as NPC).id}
	if v is PlayerState:
		return {"$pid": (v as PlayerState).pid}
	if v is Animal:
		return {"$animal": (v as Animal).id}
	if v is Inventory:
		return _enc_inv(w, v)
	if v is Array:
		return (v as Array).map(func(x): return enc(w, x))
	if v is Dictionary:
		var rec := _enc_record(w, v)
		if not rec.is_empty():
			return rec
		var o := {}
		for k in v:
			o[str(k)] = enc(w, v[k])
		return o
	if v is Object:
		return {"$none": str(v)}
	return v


static func _enc_inv(w: World, inv: Inventory) -> Dictionary:
	if inv == w.player.inv:
		return {"$inv": "pack"}
	if inv == w.player.chest:
		return {"$inv": "chest"}
	for c in w.carts.carts:
		if c.store == inv:
			return {"$inv": "cart", "id": int(c.id)}
	for c in w.containers:
		if c.get("inv") == inv:
			return {"$inv": "container", "id": str(c.id)}
	for h in w.households.size():
		if w.households[h].pantry == inv:
			return {"$inv": "pantry", "id": h}
	for n: NPC in w.npcs:
		if n.inv == inv:
			return {"$inv": "npc", "id": n.id}
	if inv == w.granary:
		return {"$inv": "granary"}
	return {"$none": "store"}


## A world record (a Dictionary the World or a module holds) as {"$r": kind, "k": key}; {} for a plain Dictionary.
static func _enc_record(w: World, d: Dictionary) -> Dictionary:
	for id in w.buildings:
		if is_same(w.buildings[id], d):
			return {"$r": "building", "k": str(id)}
	for id in w.stalls:
		if is_same(w.stalls[id], d):
			return {"$r": "stall", "k": str(id)}
	for id in w.stations:
		if is_same(w.stations[id], d):
			return {"$r": "station", "k": str(id)}
	for kind in ["plots", "fields", "containers"]:
		for r in w.get(kind):
			if is_same(r, d):
				return {"$r": kind, "k": str(r.id)}
	for t in w.trees:
		if is_same(t, d):
			return {"$r": "tree", "k": [int(t.x), int(t.y)]}
	if d.has("species") and d.has("x") and d.has("y") and d.has("state") and is_same(w.tree_at(Vector2i(int(d.x), int(d.y))), d):
		return {"$r": "tree", "k": [int(d.x), int(d.y)]}          # a tree of the world outside the village
	for pl in w.plants:
		if is_same(pl, d):
			return {"$r": "plant", "k": [int(pl.x), int(pl.y)]}
	if d.has("kind") and d.has("x") and d.has("y") and d.has("state") and is_same(w.plant_at(Vector2i(int(d.x), int(d.y))), d):
		return {"$r": "plant", "k": [int(d.x), int(d.y)]}
	for dp in w.deposits:
		if is_same(dp, d):
			return {"$r": "deposit", "k": [int(dp.x), int(dp.y), World.level_of(dp)]}
	for b in w.boulders:
		if is_same(b, d):
			return {"$r": "boulder", "k": [int(b.x), int(b.y)]}
	for i in w.loot.size():
		if is_same(w.loot[i], d):
			return {"$r": "loot", "k": [i, w.loot[i].pos.x, w.loot[i].pos.y]}
	for i in w.households.size():
		if is_same(w.households[i], d):
			return {"$r": "household", "k": i}
	for c in w.carts.carts:
		if is_same(c, d):
			return {"$r": "cart", "k": int(c.id)}
	for pt in w.pits.pits:
		if is_same(pt, d):
			return {"$r": "pit", "k": int(pt.id)}
	for id in w.fauna.pens:
		if is_same(w.fauna.pens[id], d):
			return {"$r": "pen", "k": str(id)}
	for c in w.contracts.list:
		if is_same(c, d):
			return {"$r": "contract", "k": int(c.id)}
	for q in w.player.quests:
		if is_same(q, d):
			return {"$r": "quest", "k": str(q.id)}
	for j in w.manor_work.jobs:
		if is_same(j, d):
			return {"$r": "job", "k": int(j.id)}
	if d.has("id") and d.has("kind") and d.has("bid") and d.has("at"):
		return {"$r": "unit", "k": str(d.id)}                       # a chest unit (Chests.unit), made on asking
	return {}


## The value `v` names in the host's world, for guest `p`. Sets bad.why when it names nothing here, or something of another player.
static func dec(w: World, p: PlayerState, v, bad: Dictionary) -> Variant:
	if v is Array:
		return (v as Array).map(func(x): return dec(w, p, x, bad))
	if v is String and World.is_player_ref(v) and v != w.player_ref(p):
		bad.why = "That is not yours."
		return v
	if not (v is Dictionary):
		return v
	var d: Dictionary = v
	if d.has("$none"):
		bad.why = "That cannot be done in a shared world."
		return null
	if d.has("$rect"):
		var r: Array = d["$rect"]
		return Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	if d.has("$npc"):
		var n := w.npc(int(d["$npc"]))
		if n == null:
			bad.why = "They are not here."
		return n
	if d.has("$pid"):
		if int(d["$pid"]) != p.pid:
			bad.why = "That is not yours."
			return null
		return p
	if d.has("$animal"):
		var a: Animal = w.fauna.by_id(int(d["$animal"]))
		if a == null:
			bad.why = "It is not here."
		return a
	if d.has("$inv"):
		return _dec_inv(w, p, d, bad)
	if d.has("$r"):
		var rec := _dec_record(w, p, str(d["$r"]), d.get("k"))
		if rec.is_empty():
			bad.why = "That is not there any more."
		return rec
	var o := {}
	for k in d:
		o[k] = dec(w, p, d[k], bad)
	return o


static func _dec_inv(w: World, p: PlayerState, d: Dictionary, bad: Dictionary) -> Inventory:
	match str(d["$inv"]):
		"pack":
			return p.inv
		"chest":
			return p.chest
		"cart":
			var c: Dictionary = w.carts.by_id(int(d.id))
			if not c.is_empty():
				return c.store
		"container":
			var cn: Dictionary = w.container(str(d.id))
			if cn.get("inv") is Inventory:
				return cn.inv
		"pantry":
			if int(d.id) >= 0 and int(d.id) < w.households.size():
				return w.households[int(d.id)].pantry
		"npc":
			var n := w.npc(int(d.id))
			if n != null:
				return n.inv
		"granary":
			return w.granary
	bad.why = "That store is not there."
	return null


static func _dec_record(w: World, p: PlayerState, kind: String, k) -> Dictionary:
	match kind:
		"building":
			return w.buildings.get(str(k), {})
		"stall":
			return w.stalls.get(str(k), {})
		"station":
			return w.stations.get(str(k), {})
		"plots", "fields", "containers":
			for r in w.get(kind):
				if str(r.id) == str(k):
					return r
		"tree":
			var t: Dictionary = w.tree_at(Vector2i(int(k[0]), int(k[1])))
			return t if not t.is_empty() and int(t.x) == int(k[0]) and int(t.y) == int(k[1]) else {}
		"plant":
			return w.plant_at(Vector2i(int(k[0]), int(k[1])))
		"deposit":
			return w.deposit_at(Vector2i(int(k[0]), int(k[1])), int(k[2]))
		"boulder":
			for b in w.boulders:
				if int(b.x) == int(k[0]) and int(b.y) == int(k[1]):
					return b
		"loot":
			var i := int(k[0])
			var at := Vector2(float(k[1]), float(k[2]))
			if i >= 0 and i < w.loot.size() and w.loot[i].pos.distance_to(at) < 0.01:
				return w.loot[i]
			for l in w.loot:
				if l.pos.distance_to(at) < 0.01:
					return l
		"household":
			if int(k) >= 0 and int(k) < w.households.size():
				return w.households[int(k)]
		"cart":
			return w.carts.by_id(int(k))
		"pit":
			return w.pits.pit(int(k))
		"pen":
			return w.fauna.pens.get(str(k), {})
		"contract":
			return w.contracts.get_contract(int(k))
		"quest":
			for q in p.quests:
				if str(q.id) == str(k):
					return q
		"job":
			for j in w.manor_work.jobs:
				if int(j.id) == int(k):
					return j
		"unit":
			return w.chests.unit(str(k))
	return {}


# ---------------------------------------------------------------- A2 and B kinds ------------------
## Eat a food from the pack (World.player_eat, as the guest).
static func _eat(w: World, p: PlayerState, args: Dictionary) -> Dictionary:
	var id := str(args.get("id", ""))
	if not GameData.items.has(id) or not GameData.item(id).has("food"):
		return _answer(w, p, false, "That is not food.")
	if not w.player_eat(id, p):
		return _answer(w, p, false, "You have no %s." % GameData.item_name(id).to_lower())
	return _answer(w, p, true, "You eat the %s." % GameData.item_name(id).to_lower())


## Pick a ripe wild plant within reach (World.player_reach_cell and World.pick_plant, as the guest): into the guest's pack.
static func _pick_plant(w: World, p: PlayerState, args: Dictionary) -> Dictionary:
	if not (args.has("x") and args.has("y")):
		return _answer(w, p, false, "Nothing there.")
	var c := Vector2i(int(args.x), int(args.y))
	var pl := w.plant_at(c)
	if pl.is_empty():
		return _answer(w, p, false, "There is nothing to pick there.")
	var far := w.player_reach_cell(c, false, p)
	if far != "":
		return _answer(w, p, false, far)
	if str(pl.state) != "ripe":
		return _answer(w, p, false, "Someone has picked it already.")
	var products := ResourceNodes.products(ResourceNodes.def_for("plant", str(pl.kind)))
	if not p.inv.can_add_all(products):
		return _answer(w, p, false, p.inv.full_text_all(products))
	var got := w.pick_plant(pl, p)
	for id in got:
		p.inv.add(id, int(got[id]))
	return _answer(w, p, true, "You pick " + ", ".join(got.keys().map(func(k): return "%d %s" % [int(got[k]), GameData.item_name(k).to_lower()])) + ".",
			[{"plant": [c.x, c.y], "state": str(pl.state), "regrow": float(pl.regrow)}])


## MP Batch B (MP-D4): a guest whose character died chose to go on as the heir: the established succession
## (World.continue_as_heir, as that guest), the same rules as the host's own line; never automatic, and the world never
## waited for the choice. The heir keeps the identity and the line's reference; its new pid comes back as `heir_pid`.
static func _heir(w: World, p: PlayerState) -> Dictionary:
	if p.alive:
		return _answer(w, p, false, "You are alive.")
	var key := p.net_key
	w.continue_as_heir(p)
	var h: PlayerState = null
	for q: PlayerState in w.player_list():
		if not w.is_host(q) and q.net_key == key and q.alive:
			h = q
			break
	if h == null:
		return _answer(w, p, false, "No heir could take up the family's life.")
	var r := _answer(w, h, true, "%s %s takes up the family's life." % [h.name, h.family])
	r["heir_pid"] = h.pid
	return r


## A guest applies a change the host made to the shared world (its copy only shows the host's world).
static func apply_patch(w: World, patch: Dictionary) -> void:
	if patch.has("plant"):
		var pl := w.plant_at(Vector2i(int(patch.plant[0]), int(patch.plant[1])))
		if not pl.is_empty():
			pl.state = str(patch.state)
			pl.regrow = float(patch.regrow)
			w.tile_changed.emit(Vector2i(int(pl.x), int(pl.y)), World.PLANT_LAYER, -1)
