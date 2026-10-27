extends RefCounted
## X20 multiplayer validation (owner directive 2026-10-27, phase 4.5): one participant's copy of the shared world compared with the
## host's, for tests/net_mp4_test.gd and its guests (tests/net_interact_guest.gd). The host writes `dump.json` (tests/net_host.gd,
## "dump" with "full") while its frame is frozen: the synchronized sections, the offers between players, the villagers (alive or
## not), every player's public place and the host's records of each player's pack and purse, and the clock. A guest compares its
## own copy with that: the sections, the offers, the clock, the villager set, where every other player stands (and that it holds
## nobody else's pack), and its own pack, purse and place as the host has them. Each difference is one line; none is agreement.

const CLOCK_SLACK := 5.0              # game minutes: the guest's clock comes in the 4 Hz snapshots (NetSession.s_npcs), at most this behind
const POS_SLACK := 0.15               # tiles


static func norm(v) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(v)), "", true)


static func compare(w: World, my_pid: int, dump: Dictionary, keys: Array) -> Array:
	var bad := []
	if dump.is_empty():
		return ["no dump from the host"]
	var mine: Dictionary = w.to_dict()
	for k in keys:
		if norm(dump.get("sections", {}).get(k)) != norm(mine.get(k)):
			bad.append("section %s%s" % [k, _first_difference(JSON.parse_string(norm(dump.get("sections", {}).get(k))), JSON.parse_string(norm(mine.get(k))))])
	if norm(dump.get("offers", [])) != norm(w.offers):
		bad.append("offers (host %d, here %d)" % [(dump.get("offers", []) as Array).size(), w.offers.size()])
	var hm := float(dump.get("minutes", -1))
	if w.minutes > hm + 0.01 or w.minutes < hm - CLOCK_SLACK:
		bad.append("clock (host %.1f, here %.1f)" % [hm, w.minutes])
	var hn: Dictionary = dump.get("npcs", {})
	var here_n := {}
	for n: NPC in w.npcs:
		here_n[str(n.id)] = n.alive
	if hn.size() != here_n.size():
		bad.append("villager count (host %d, here %d)" % [hn.size(), here_n.size()])
	for id in hn:
		if not here_n.has(str(id)) or bool(here_n[str(id)]) != bool(hn[id]):
			bad.append("villager %s (host alive %s, here %s)" % [id, hn[id], here_n.get(str(id), "missing")])
			break
	var hp: Dictionary = dump.get("players", {})
	for pid_s in hp:
		var r: Dictionary = hp[pid_s]
		var q: PlayerState = w.player_by_pid(int(pid_s))
		if bool(r.get("away", false)):
			if q != null and not q.away and int(pid_s) != my_pid:
				bad.append("player %s is away on the host, in play here" % pid_s)
			continue
		if q == null:
			bad.append("player %s missing here" % pid_s)
			continue
		var at := Vector2(float(r.pos[0]), float(r.pos[1]))
		if q.pos.distance_to(at) > POS_SLACK:
			bad.append("player %s at %s here, %s on the host" % [pid_s, q.pos, at])
		if int(pid_s) == my_pid:
			if norm(q.inv.items) != norm(r.get("inv", {})) or q.coins != int(r.get("coins", -1)):
				bad.append("own pack or purse (here %s %d, host %s %d)" % [q.inv.items, q.coins, r.get("inv"), int(r.get("coins", -1))])
		elif not q.inv.items.is_empty():
			bad.append("holds player %s's pack, which is theirs only" % pid_s)
		if q.away:
			bad.append("player %s in play on the host, away here" % pid_s)
	return bad


## Where two values first differ, briefly (for a failing check's message).
static func _first_difference(a, b, path := "") -> String:
	if a is Array and b is Array:
		if a.size() != b.size():
			return " %s: %d entries on the host, %d here" % [path, a.size(), b.size()]
		for i in a.size():
			if JSON.stringify(a[i]) != JSON.stringify(b[i]):
				return _first_difference(a[i], b[i], "%s[%d]" % [path, i])
	elif a is Dictionary and b is Dictionary:
		for k in a:
			if JSON.stringify(a.get(k)) != JSON.stringify(b.get(k)):
				return _first_difference(a.get(k), b.get(k), "%s.%s" % [path, k])
		for k in b:
			if not a.has(k):
				return " %s.%s: only here" % [path, k]
	return " %s: host %s, here %s" % [path, JSON.stringify(a).left(120), JSON.stringify(b).left(120)]
