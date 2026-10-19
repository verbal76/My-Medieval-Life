class_name NetActions
extends RefCounted
## MP-01 the shared-interaction pattern: a guest's action on the shared world is a request the host
## checks against its own World and applies once (NetSession.c_request). Each kind validates the asker's
## reach and the thing's current state, changes the world, and returns {ok, text, gained}: what the
## asker received, which the guest adds to its own copy of its pack. Requests are handled one at a time
## in arrival order on the host, so when two players reach for the same thing the second finds it taken.
## Unknown kinds and malformed requests are refused. New shared actions are added here, one by one.

const REACH := 1.6                    # tiles from the asker's feet to the thing


static func apply(w: World, p: PlayerState, kind: String, args: Dictionary) -> Dictionary:
	match kind:
		"pick_fruit":
			return _pick_fruit(w, p, args)
	return {"ok": false, "text": "That cannot be done in a shared world yet."}


static func _pick_fruit(w: World, p: PlayerState, args: Dictionary) -> Dictionary:
	if not (args.has("x") and args.has("y")):
		return {"ok": false, "text": "Nothing there."}
	var t := w.tree_at(Vector2i(int(args.x), int(args.y)))
	if t.is_empty() or Trees.fruit_cfg(str(t.get("species", ""))).is_empty():
		return {"ok": false, "text": "There is no fruit tree there."}
	if p.pos.distance_to(Vector2(int(t.x), int(t.y)) + Vector2(0.5, 0.5)) > REACH:
		return {"ok": false, "text": "Too far away."}
	var got := w.pick_fruit(t)
	if got.is_empty():
		return {"ok": false, "text": "Someone has picked it already."}
	for id in got:
		p.inv.add(id, int(got[id]))
	return {"ok": true, "text": "", "gained": got}
