extends SceneTree
## Long-run check of property phase 2 (diagnostics): crowded households split, buy ground or an empty
## house, hire helpers and build. Builds a village for a seed, crowds `--crowd` households (a child
## from the next household moves in, so six live in a five-bed house), runs `--days` days and
## reports survival, coin and grain conservation, households founded and houses built. Exit code 1
## if coins or grain are not conserved, or most villagers die.
##   godot --headless --path game --script res://tests/households_sim.gd -- --seed 2 --days 30 --crowd 3


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: int) -> int:
		return int(args[args.find(name) + 1]) if name in args else fallback
	var seed: int = arg.call("--seed", 1)
	var days: int = arg.call("--days", 30)
	var crowd: int = arg.call("--crowd", 3)
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var crowded := _crowd(w, crowd)
	var coins0 := w.total_coins()
	var wheat0 := _wheat(w)
	var hh0 := w.households.size()
	var alive0 := w.alive_count() - w.alive_count("bandit")
	print("seed %d: %d villagers, crowded %s" % [seed, alive0, crowded.map(func(h): return "%s (%d coins)" % [w.households[h].family, w.property.purse(World.hh_ref(h))])])
	var per_day := int(1440.0 / (float(GameData.b("game_minutes_per_second")) * 0.5))
	for d in days:
		for i in per_day:
			w.update(0.5)
		var sites := w.plots.filter(func(p): return not p.site.is_empty() and not p.site.get("done", false) and str(p.site.get("owner", "")).begins_with("hh:"))
		print("  day %2d: alive %d, households %d (+%d), sites %s, helpers %d, treasury %d" % [w.day() + 1, w.alive_count() - w.alive_count("bandit"),
			w.households.size(), w.households.size() - hh0, sites.map(func(p): return "%d%%" % roundi(w.site_progress(p) * 100.0)), w.construction.contracts.size(), w.treasury])
	var st: Dictionary = w.stats
	var expect := wheat0 + int(st.get("made_wheat", 0)) - int(st.get("used_wheat", 0)) - int(st.get("feed_eaten_wheat", 0)) \
		- int(st.get("eaten_wheat", 0)) - int(st.get("exported_wheat", 0))
	var alive := w.alive_count() - w.alive_count("bandit")
	var founded := w.households.slice(hh0)
	var moved_in := founded.filter(func(h): return w.buildings.has(str(h.home)))
	var coins_ok := w.total_coins() == coins0 + w.coin_sources
	var grain_ok := _wheat(w) == expect
	print("result seed %d, %d days: alive %d/%d; households founded %d, in a house of their own %d (%s); built by NPCs %d; helper wages %d, bought %d coins; coins %s (%d = %d + %d); grain %s (%d vs %d)" % [
		seed, days, alive, alive0, founded.size(), moved_in.size(), ", ".join(founded.map(func(h): return "%s: %s" % [h.family, w.property.describe(w.buildings[h.home]) if w.buildings.has(str(h.home)) else "lodging"])),
		w.buildings.values().filter(func(b): return World.is_built(b) and str(b.owner).begins_with("hh:")).size(),
		int(st.get("helper_wages", 0)), int(st.get("helper_bought", 0)),
		"conserved" if coins_ok else "NOT CONSERVED", w.total_coins(), coins0, w.coin_sources, "conserved" if grain_ok else "NOT CONSERVED", _wheat(w), expect])
	w.dispose()
	quit(0 if coins_ok and grain_ok and alive >= alive0 * 9 / 10 else 1)


## Crowd `k` households: the richest house-dwelling households (by purse) each take in a child of the
## household after them. Returns the crowded household indexes.
func _crowd(w: World, k: int) -> Array:
	var homes := []
	for h in w.households.size():
		if w.buildings[w.households[h].home].type == "house":
			homes.append(h)
	homes.sort_custom(func(a, b): return w.property.purse(World.hh_ref(a)) > w.property.purse(World.hh_ref(b)))
	var out := []
	for h in homes:
		if out.size() >= k:
			break
		var hh: Dictionary = w.households[h]
		if not range(w.households.size()).any(func(x): return x != h and not out.has(x) and _child_of(w, x) != null):
			break
		var beds: int = w.construction.beds_in(str(hh.home))
		for x in homes:
			if (hh.members as Array).size() > beds:
				break
			if x == h or out.has(x):
				continue
			var c := _child_of(w, x)
			if c != null:
				(w.households[x].members as Array).erase(c.id)
				(hh.members as Array).append(c.id)
				c.household = h
				c.home = str(hh.home)
				c.pos = Vector2(w.building_door(c.home)) + Vector2(0.5, 0.5)
		if w.construction.crowded(h):
			out.append(h)
	return out


func _child_of(w: World, h: int) -> NPC:
	for m in w.households[h].members:
		var o: NPC = w.npc(int(m))
		if o.alive and o.role == "child" and (w.households[h].members as Array).size() > 2:
			return o
	return null


func _wheat(w: World) -> int:
	var n := w.player.inv.count("wheat") + w.granary.count("wheat") + w.player.chest.count("wheat")
	for o: NPC in w.npcs:
		n += o.inv.count("wheat")
	for hh in w.households:
		n += hh.pantry.count("wheat")
	for id in w.fauna.pens:
		n += int(w.fauna.pens[id].trough)
	for l in w.loot:
		n += l.inv.count("wheat")
	return n
