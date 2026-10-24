class_name NetActions
extends RefCounted
## Multiplayer Batch A2 (the MP-01 prototype's request, validate, apply once, reply pattern, generalized onto Batch A1): a
## guest's action on the shared world is a request the host applies in its own World, as that guest: the same World verb
## the host's own character uses, run inside World.as_actor(guest), so every rule, reach check, ledger count and record is
## the host's and the guest never creates coins, items or events. Requests are applied at one fixed point of the host's
## frame (NetSession.apply_requests, before World.update), in arrival order, so when two players reach for the same thing
## the second finds it taken. The answer carries what the guest needs to show the result: its own character as the host
## now has it (`player`, a PlayerState dict) and the world records the action changed (`patches`, apply_patch).
## Unknown kinds and malformed requests are refused. New kinds are added here one by one (Batch C: every verb).

const KINDS := ["eat", "pick_plant"]


## Apply request `kind` for player `p` in world `w`. Returns {ok, text, player, patches}.
static func apply(w: World, p: PlayerState, kind: String, args: Dictionary) -> Dictionary:
	if p == null or not p.alive:
		return _answer(w, p, false, "You cannot do that now.")
	match kind:
		"eat":
			return _eat(w, p, args)
		"pick_plant":
			return _pick_plant(w, p, args)
	return _answer(w, p, false, "That cannot be done in a shared world yet.")


static func _answer(w: World, p: PlayerState, ok: bool, text: String, patches: Array = []) -> Dictionary:
	return {"ok": ok, "text": text, "player": p.to_dict() if p != null else {}, "patches": patches}


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


## A guest applies a change the host made to the shared world (its copy only shows the host's world).
static func apply_patch(w: World, patch: Dictionary) -> void:
	if patch.has("plant"):
		var pl := w.plant_at(Vector2i(int(patch.plant[0]), int(patch.plant[1])))
		if not pl.is_empty():
			pl.state = str(patch.state)
			pl.regrow = float(patch.regrow)
			w.tile_changed.emit(Vector2i(int(pl.x), int(pl.y)), World.PLANT_LAYER, -1)
