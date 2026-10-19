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


## Set a handcart down at `at` for `owner`: the item becomes a cart in the world.
func place(owner: String, at: Vector2) -> Dictionary:
	var inv := Inventory.new()
	inv.max_stacks = int(cfg().stacks)
	var c := {"id": next_id, "owner": owner, "pos": at, "store": inv, "puller": "", "facing": Vector2.DOWN}
	next_id += 1
	carts.append(c)
	w.stat("carts_set_down")
	w.stat("used_handcart")                  # the item became a cart in the world (the economy ledger)
	return c


func of(owner: String) -> Array:
	return carts.filter(func(c): return str(c.owner) == owner)


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
	if ref == World.PLAYER:
		return owner == World.PLAYER
	var n: NPC = w.npc(int(ref.trim_prefix("npc:")))
	if n == null or not n.alive:
		return false
	if owner == World.PLAYER:
		return w.business.is_attendant(n)
	return owner.begins_with("hh:") and n.household == w.ref_id(owner)


## Take hold of a parked cart. "" when done, else why not.
func hitch(c: Dictionary, ref: String) -> String:
	if not may_use(c, ref):
		return "It is %s cart: only they, their family or their hired help may take it." % whose(c)
	if str(c.puller) != "" and str(c.puller) != ref:
		return "Someone is pulling it."
	if not pulled_by(ref).is_empty() and pulled_by(ref) != c:
		return "You are pulling a cart already."
	c.puller = ref
	return ""


## Let go: the cart stays where it is.
func park(c: Dictionary) -> void:
	c.puller = ""


## "your", "the Reed household's".
func whose(c: Dictionary) -> String:
	var owner := str(c.owner)
	if owner == World.PLAYER:
		return "your"
	if owner.begins_with("hh:"):
		var h: int = w.ref_id(owner)
		if h >= 0 and h < w.households.size():
			return "the %s household's" % w.households[h].family
	return "a stranger's"


## Walking speed while pulling (a factor of the normal speed).
static func pull_speed() -> float:
	return float(cfg().pull_speed)


## The nearest cart within `r` tiles of `at`, or {}.
func near(at: Vector2, r: float) -> Dictionary:
	var best := {}
	var bd := r
	for c in carts:
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
		if ref == World.PLAYER:
			at = w.player.pos if w.player.alive else Vector2.INF
		else:
			var n: NPC = w.npc(int(ref.trim_prefix("npc:")))
			if n != null and n.alive:
				at = n.pos
		if at == Vector2.INF:
			c.puller = ""
			continue
		var d: Vector2 = at - (c.pos as Vector2)
		if d.length() > float(cfg().trail):
			c.pos = at - d.normalized() * float(cfg().trail)
			c.facing = d.normalized()


## The attendant of the player's stall unloads a cart of the player's parked at a cart stop near it into the
## stall's store, hourly (the delivery service: the owner's hired help).
func hour() -> void:
	var s: Dictionary = w.business.mine()
	if s.is_empty() or w.business.attendant_of(s) == null:
		return
	for c in of(World.PLAYER):
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
		out.append({"id": c.id, "owner": c.owner, "pos": [c.pos.x, c.pos.y], "store": (c.store as Inventory).to_dict(), "puller": c.puller})
	return {"next_id": next_id, "carts": out}


func load_dict(d: Dictionary) -> void:
	next_id = int(d.get("next_id", 1))
	carts = []
	for r in d.get("carts", []):
		var inv := Inventory.from_dict(r.store)
		inv.max_stacks = int(cfg().stacks)
		carts.append({"id": int(r.id), "owner": str(r.owner), "pos": Vector2(float(r.pos[0]), float(r.pos[1])), "store": inv,
			"puller": str(r.get("puller", "")), "facing": Vector2.DOWN})
