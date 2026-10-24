class_name Carts
extends RefCounted
## B14 carts in play (owner, Build 14: "this is how they move house made goods to a market"; owner answers:
## carts are pulled storage that slows walking, parked at home or at a cart stop; only the owner, their
## family or their hired help may use one; the mine cart stands in for the art).
##
## A handcart is made or bought as an item ("handcart"); set down, it becomes a cart in the world:
## {id, owner (World ref: "player" or "hh:<n>"), pos (tiles, float), store (Inventory, carts.stacks kinds),
## puller ("" parked, "player" or "npc:<id>"), facing}. A pulled cart follows a step behind its puller.
## Its store is a chest-like unit ("cart:<id>", Chests): the owner's to fill, anyone else's to take from
## only as theft. Cart stops (carts.stops) are parking places by the market: a cart of the player's parked
## at one is unloaded into the player's stall store by their attendant (the delivery service). Saved whole.
## DVW-B4: a cart wears by the tiles it is pulled (`worn`, saved; decay.cart_tiles in all): its condition is shown in
## words (Decay.condition); a worn-out cart falls apart where it stands and what it held is left lying there (loot).
## MIN-F: a cart may be a minecart ("kind": "minecart", set down from the item on track: MineWorks.set_down_minecart) on a
## level ("level": 0 the surface). A minecart follows its puller only onto track cells of its level: pulled off the rails
## it stays where they end, and once its puller is `let_go` tiles away they let go of it; on track it is pulled at
## mine_works.json minecart.track_speed of walking speed (a handcart at pull_speed). It crosses a portal with its puller
## where track lies on both stands (World.player_through, World._npc_through). Saved with "kind" and "level" when not a
## surface handcart (absent: a handcart on the surface).

var w
var carts: Array = []          # Dictionary records, by id
var next_id := 1


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("carts")


func by_id(id: int) -> Dictionary:
	for c in carts:
		if int(c.id) == id:
			return c
	return {}


## Set a handcart (or, MIN-F, a minecart on `level`) down at `at` for `owner`: the item becomes a cart in the world.
func place(owner: String, at: Vector2, kind := "handcart", level := 0) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("carts.place", place.bind(owner, at, kind, level), [owner, at, kind, level])
	var inv := Inventory.new()
	inv.max_stacks = stacks_of(kind)
	var c := {"id": next_id, "owner": owner, "pos": at, "store": inv, "puller": "", "facing": Vector2.DOWN, "worn": 0.0}
	if kind != "handcart":
		c.kind = kind
	if level != 0:
		c.level = level
	next_id += 1
	carts.append(c)
	w.stat("carts_set_down")
	w.stat("used_" + kind)                   # the item became a cart in the world (the economy ledger)
	return c


## "handcart" or "minecart" (MIN-F); absent is a handcart.
static func kind_of(c: Dictionary) -> String:
	return str(c.get("kind", "handcart"))


## Units a cart can still take (MIN-F2, Q3: a minecart holds at most minecart.capacity units; a handcart is limited by
## its stacks only).
func room(c: Dictionary) -> int:
	if kind_of(c) != "minecart":
		return 1 << 30
	return maxi(0, int(MineWorks.cfg().minecart.capacity) - (c.store as Inventory).total())


static func stacks_of(kind: String) -> int:
	return int(MineWorks.cfg().minecart.stacks) if kind == "minecart" else int(cfg().stacks)


## An owner's carts of one kind (handcarts unless asked: the market runs and the stall's deliveries use handcarts).
func of(owner: String, kind := "handcart") -> Array:
	return carts.filter(func(c): return str(c.owner) == owner and kind_of(c) == kind)


## The cart `ref` ("player" or "npc:<id>") is pulling, or {}.
func pulled_by(ref: String) -> Dictionary:
	for c in carts:
		if str(c.puller) == ref:
			return c
	return {}


## Whether `ref` may pull or fill this cart: its owner; for the player's carts the player and the player's
## hired attendants; for a household's, its members (owner rule: you, your family or your hired help).
func may_use(c: Dictionary, ref: String) -> bool:
	var owner := str(c.owner)
	if World.is_player_ref(ref):
		return World.is_player_ref(owner)
	var n: NPC = w.npc(int(ref.trim_prefix("npc:")))
	if n == null or not n.alive:
		return false
	if World.is_player_ref(owner):
		return w.business.is_attendant(n)
	return owner.begins_with("hh:") and n.household == w.ref_id(owner)


## Take hold of a parked cart. "" when done, else why not.
func hitch(c: Dictionary, ref: String) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("carts.hitch", hitch.bind(c, ref), [c, ref])
	if not may_use(c, ref):
		return "It is %s cart: only they, their family or their hired help may take it." % whose(c)
	if str(c.puller) != "" and str(c.puller) != ref:
		return "Someone is pulling it."
	if not pulled_by(ref).is_empty() and pulled_by(ref) != c:
		return "You are pulling a cart already."
	c.puller = ref
	return ""


## Let go: the cart stays where it is.
func park(c: Dictionary, actor: PlayerState = null) -> void:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		w.mirror("carts.park", park.bind(c), [c])
		return
	if actor != null and actor != w.player:
		w.as_actor(actor, park.bind(c))
		return
	c.puller = ""


## "your", "the Reed household's".
func whose(c: Dictionary) -> String:
	var owner := str(c.owner)
	if World.is_player_ref(owner):
		return "your"
	if owner.begins_with("hh:"):
		var h: int = w.ref_id(owner)
		if h >= 0 and h < w.households.size():
			return "the %s household's" % w.households[h].family
	return "a stranger's"


## Walking speed while pulling (a factor of the normal speed).
static func pull_speed() -> float:
	return float(cfg().pull_speed)


## Walking speed while pulling cart `c`: a minecart on its rails rolls at minecart.track_speed (MIN-F), else pull_speed.
func pull_speed_for(c: Dictionary) -> float:
	if kind_of(c) == "minecart" and w.mine_works != null and w.mine_works.track_at(World.level_of(c), Vector2i((c.pos as Vector2).floor())):
		return float(MineWorks.cfg().minecart.track_speed)
	return pull_speed()


## A minecart goes through a portal with its puller: it stands on the other end's stand, on its level (MIN-F).
func cross(c: Dictionary, to_end: Dictionary) -> void:
	c.pos = Vector2(to_end.stand) + Vector2(0.5, 0.5)
	if int(to_end.level) != 0:
		c.level = int(to_end.level)
	else:
		c.erase("level")


## The nearest cart within `r` tiles of `at` on `level`, or {}.
func near(at: Vector2, r: float, level := 0) -> Dictionary:
	var best := {}
	var bd := r
	for c in carts:
		if World.level_of(c) != level:
			continue
		var d: float = (c.pos as Vector2).distance_to(at)
		if d <= bd:
			bd = d
			best = c
	return best


## The cart stop within reach of `at` ({name, x, y, r}), or {}.
func stop_at(at: Vector2) -> Dictionary:
	for s in cfg().stops:
		if Vector2(float(s.x) + 0.5, float(s.y) + 0.5).distance_to(at) <= float(s.r):
			return s
	return {}


## Pulled carts follow a step behind their puller on a short rope; a puller who died or left lets go.
func update(_dt: float) -> void:
	for c in carts:
		var ref := str(c.puller)
		if ref == "":
			continue
		var at := Vector2.INF
		if World.is_player_ref(ref):
			var pl: PlayerState = w.player_for(ref)
			at = pl.pos if pl.alive else Vector2.INF
		else:
			var n: NPC = w.npc(int(ref.trim_prefix("npc:")))
			if n != null and n.alive:
				at = n.pos
		if at == Vector2.INF:
			c.puller = ""
			continue
		var d: Vector2 = at - (c.pos as Vector2)
		if d.length() > float(cfg().trail):
			var to: Vector2 = at - d.normalized() * float(cfg().trail)
			if kind_of(c) == "minecart" and not w.mine_works.track_at(World.level_of(c), Vector2i(to.floor())):
				# MIN-F: off the rails the minecart stays where they end; far enough off, its puller lets go
				if d.length() > float(MineWorks.cfg().minecart.let_go):
					c.puller = ""
					w.stat("minecart_let_go")
					if World.is_player_ref(ref):
						w.note("The minecart stays on its rails; you let go of it.")
				continue
			c.worn = float(c.get("worn", 0.0)) + (to - (c.pos as Vector2)).length()     # DVW-B4: wear by the tiles pulled
			c.pos = to
			c.facing = d.normalized()
	for c in carts.duplicate():
		if float(c.get("worn", 0.0)) >= float(Decay.cfg().cart_tiles):
			fall_apart(c)


## DVW-B4: how worn a cart is, in words ("new", "worn", "well worn", "falling apart").
func condition(c: Dictionary) -> String:
	var full := float(Decay.cfg().cart_tiles)
	return Decay.condition(full - float(c.get("worn", 0.0)), full)


## A worn-out cart falls apart where it stands: the cart is gone (carts_broken), and what it held is left lying there,
## for its owner to take up (loot), so no good is lost with it.
func fall_apart(c: Dictionary) -> void:
	var inv: Inventory = c.store
	var held := inv.total()
	if held > 0:
		var bag := Inventory.new()
		for id in inv.ids():
			bag.add(id, inv.count(id))
		w.loot.append({"pos": c.pos, "inv": bag, "coins": 0, "from": "a broken cart"})
		if World.level_of(c) != 0:
			w.loot[w.loot.size() - 1].level = World.level_of(c)      # MIN-F: it lies on the cart's level
	carts.erase(c)
	w.stat("carts_broken")
	var who := whose(c)
	w.note("%s cart fell apart from wear%s." % [who.substr(0, 1).to_upper() + who.substr(1), ", and its load lies where it stood" if held > 0 else ""])


## The attendant of the player's stall unloads a cart of the player's parked at a cart stop near it into the
## stall's store, hourly (the delivery service: the owner's hired help).
func hour() -> void:
	for p: PlayerState in w.player_list():        # MP C4: each player's own stall and carts (single player: the one)
		w.as_actor(p, _hour_one)


func _hour_one() -> void:
	var s: Dictionary = w.business.mine()
	if s.is_empty() or w.business.attendant_of(s) == null:
		return
	for c in of(w.acting_ref()):
		if str(c.puller) != "" or (c.store as Inventory).total() == 0:
			continue
		var stop := stop_at(c.pos)
		if stop.is_empty() or Vector2(int(s.x), int(s.y)).distance_to(c.pos) > float(cfg().deliver_range):
			continue
		var moved := unload(c, s)
		if moved > 0:
			w.note("Your attendant unloaded %d goods from your cart at %s into the stall's store." % [moved, stop.name])


## Move everything in the cart into a stall's or shop's store. Returns how many units moved.
func unload(c: Dictionary, s: Dictionary) -> int:
	var inv: Inventory = c.store
	var n := 0
	if not s.has("store"):
		s["store"] = {}
	for id in inv.ids():
		var q := inv.count(id)
		inv.remove(id, q)
		s.store[id] = int(s.store.get(id, 0)) + q
		n += q
	w.stat("cart_delivered", n)
	return n


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var out := []
	for c in carts:
		out.append({"id": c.id, "owner": c.owner, "pos": [c.pos.x, c.pos.y], "store": (c.store as Inventory).to_dict(), "puller": c.puller,
			"worn": float(c.get("worn", 0.0))})
		if c.has("kind"):
			out[out.size() - 1].kind = str(c.kind)          # MIN-F: a minecart
		if World.level_of(c) != 0:
			out[out.size() - 1].level = World.level_of(c)   # MIN-F: below the surface
	return {"next_id": next_id, "carts": out}


func load_dict(d: Dictionary) -> void:
	next_id = int(d.get("next_id", 1))
	carts = []
	for r in d.get("carts", []):
		var inv := Inventory.from_dict(r.store)
		inv.max_stacks = stacks_of(str(r.get("kind", "handcart")))
		carts.append({"id": int(r.id), "owner": str(r.owner), "pos": Vector2(float(r.pos[0]), float(r.pos[1])), "store": inv,
			"puller": str(r.get("puller", "")), "facing": Vector2.DOWN, "worn": float(r.get("worn", 0.0))})     # older saves: unworn
		if r.has("kind"):
			carts[carts.size() - 1].kind = str(r.kind)        # MIN-F (absent: a handcart)
		if int(r.get("level", 0)) != 0:
			carts[carts.size() - 1].level = int(r.level)      # MIN-F (absent: the surface)
