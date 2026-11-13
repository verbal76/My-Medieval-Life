extends SceneTree
## Stage E "actual gameplay" (Build 25 verification): an automated player journey through the real game scene (main.gd) and its
## windows, the way a player plays: the title's New game, character creation (name, family) and the origin's Begin; walking with
## the movement actions; walking up to the reeve and asking "Any work for me?", taking the manor's work and doing it for its wage;
## asking a farmer, miner or woodcutter for paid work; mining with the starting pickaxe; selling and buying through a shopkeeper's
## trade window and its quantity picker; eating from the pack (the Pack's Eat calls World.player_eat); saving, and continuing from
## the title; resting through several days, eating as needed. After each step the state is checked: the world's coins against the
## booked flows from outside (the economy suites' ledger), the purse, pack and journal identical across a save and reload, the
## clock moving, the player moving when walking, and food and paid work always within reach. Measurements are printed; outcomes of
## the simulation (what a job pays, what food costs) are not thresholds (WDR-022). Run headless:
##   godot --headless --path game --script res://tests/player_journey_test.gd

const TEST_SAVE := "user://test_saves/player_journey_test/save1.json"
const DT := 0.1

var main
var failures := 0
var checks := 0
var coins_start := 0
var stats_start := {}
var sources_start := 0
var manor_paid := false
var skip_sellers := {}            # shopkeepers the player could not reach this time (tried the next one instead)


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func note(what: String) -> void:
	print("     " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.get_script() == null or not main.has_method("interact"):
		print("FAIL the game's main script did not load (a script error above): stopping")
		quit(1)
		return
	main.save_path = TEST_SAVE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_SAVE.get_base_dir()))
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ------------------------------------------------------------------ helpers -----------------------
func _frames(n: int) -> void:
	for i in n:
		main._process(DT)


func _press(caption: String, prefix := false) -> bool:
	for b in main.ui.panel_body.find_children("*", "Button", true, false):
		var t := str((b as Button).text)
		if (t == caption or (prefix and t.begins_with(caption))) and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return true
	return false


func _buttons() -> Array:
	return main.ui.panel_body.find_children("*", "Button", true, false).map(func(b): return str(b.text))


func _picker():
	for c in main.ui.panel_body.find_children("*", "", true, false):
		if c is QuantityPicker:
			return c
	return null


## The world's coins less the net coins in from outside since the start (World.coin_sources, the ledger every flow across the
## village's edge books: caravans, newcomers, migrants, couriers, luxuries; conservation_test's and economy_sim's
## coin_sources_mismatch): 0 when no coin was made or lost.
func _leak() -> int:
	var w: World = main.world
	return w.total_coins() - coins_start - (w.coin_sources - sources_start)


func _conserved(step: String) -> void:
	var l := _leak()
	check(l == 0, "%s: coins conserved (world %d, start %d, leak %d)" % [step, main.world.total_coins(), coins_start, l])
	if l != 0:
		var w: World = main.world
		var moved := []
		for k in w.stats:
			if str(k).contains("coin") and int(w.stats[k]) != int(stats_start.get(k, 0)):
				moved.append("%s %+d" % [k, int(w.stats[k]) - int(stats_start.get(k, 0))])
		note("coin flows booked in stats since the start: %s; coin_sources (the ledger of coins in from and out to the outside) %+d" % [", ".join(moved), w.coin_sources - sources_start])


## Walk (the route a tap or auto-walk follows, Main.move_to) to within `within` tiles of `goal`. Returns whether it got there.
func _walk_to(goal: Vector2, within := 1.4, max_frames := 900) -> bool:
	var p: PlayerState = main.world.player
	main.move_to = goal
	for i in max_frames:
		if p.pos.distance_to(goal) <= within:
			main.move_to = Vector2.INF
			return true
		if main.ui.modal():
			main.ui.hide_all()
		if main.move_to == Vector2.INF:
			main.move_to = goal              # a route ends at the last reachable cell next to a solid goal: try again
		main._process(DT)
	main.move_to = Vector2.INF
	return p.pos.distance_to(goal) <= within


## Walk up to a villager and talk (Main.talk_to: tapping a villager), as the player does. Returns whether a window opened.
func _talk(n: NPC, max_frames := 1200) -> bool:
	var p: PlayerState = main.world.player
	main.ui.hide_all()
	_walk_to(n.pos, 2.5, max_frames)          # into the shop or house first: a villager under a roof is not tapped from outside
	for i in 200:
		if main.ui.modal():
			return true
		if main.talk_to == null:
			main.talk_to = n
		main._process(DT)
	return main.ui.modal()


func _npc_with(pred: Callable) -> Array:
	var p: PlayerState = main.world.player
	var out: Array = main.world.npcs.filter(func(n): return n.alive and pred.call(n))
	out.sort_custom(func(a, b): return a.pos.distance_to(p.pos) < b.pos.distance_to(p.pos))
	return out


func _finish_action(max_frames := 3000) -> void:
	for i in max_frames:
		if main.action.is_empty():
			return
		main._process(DT)


## A value as a save holds it (JSON: whole numbers read back as floats), so a reload is compared value for value.
static func _norm(v) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(v)))


func _snapshot() -> Dictionary:
	var w: World = main.world
	var p := w.player
	return {"coins": p.coins, "inv": _norm(p.inv.to_dict()),
		"player": _norm(p.to_dict()), "log": _norm(w.log_lines), "messages": _norm(w.player_messages()),
		"quests": _norm(p.quests), "minutes": w.minutes, "world_coins": w.total_coins(), "pos": p.pos}


## Buy food at a shopkeeper's counter or stall (the trade window, Buy, the quantity picker's confirm). Returns the id bought or "".
func _buy_food() -> String:
	var w: World = main.world
	var p := w.player
	var best := {}
	for n: NPC in _npc_with(func(n): return w.at_post(n) and not skip_sellers.has(n.id)):
		for id in w.brain.for_sale(n):
			var it := GameData.item(id)
			if not it.has("food") or it.has("harm") or not p.inv.can_add(id):
				continue
			var price: int = w.deal_price(w.sell_price(n, id), p, n)
			if price <= p.coins and (best.is_empty() or float(it.food) / maxf(1.0, price) > float(best.value)):
				best = {"npc": n, "id": id, "price": price, "value": float(it.food) / maxf(1.0, price)}
	if best.is_empty():
		note("no shopkeeper at a post sells food the player can afford now (coins %d, %s)" % [p.coins, w.clock_text()])
		return ""
	var n: NPC = best.npc
	var from := p.pos
	var f0 := Engine.get_process_frames()
	var talked := _talk(n, 600)
	if talked and main.ui.is_open("talk"):
		_press("Trade")                       # a shopkeeper with something to say first: the talk window's Trade
	if not main.ui.is_open("trade"):
		note("walking up to %s (%s) did not open their shop (window '%s'; the player %s -> %s, %.1f tiles from them; they are at their post: %s, doing '%s'; walk_stuck %.1f)" % [
			n.name, n.job, main.ui.panel_kind, str(from), str(p.pos), p.pos.distance_to(n.pos), str(w.at_post(n)), str(n.doing), main.walk_stuck])
		main.ui.hide_all()
		skip_sellers[n.id] = true
		return ""
	var purse := p.coins
	var theirs := n.coins + w.business.tills()
	var total0 := w.total_coins()
	var count0 := p.inv.count(best.id)
	main.ui.show_trade(n, {"id": best.id, "mode": "buy", "price": best.price})
	var qp = _picker()
	if qp == null:
		note("the trade window offered no quantity picker for %s" % best.id)
		return ""
	qp.confirmed.emit(1)
	var paid := purse - p.coins
	check(p.inv.count(best.id) == count0 + 1 and paid > 0 and n.coins + w.business.tills() == theirs + paid and w.total_coins() == total0,
			"bought 1 %s from %s (%s) for %d coins at their %s: their purse and the tills +%d, the player's -%d" % [best.id, n.name, n.job, paid,
			w.shop_name(n), n.coins + w.business.tills() - theirs, paid])
	main.ui.hide_all()
	return best.id


## The chapel's relief for a player with (almost) no coins: the clergy's "Ask the church for food". Returns a food id or "".
func _ask_church() -> String:
	var w: World = main.world
	var p := w.player
	if w.chapel == null or not w.chapel.present or p.coins > int(w.chapel.cfg().ask_player_max_coins):
		return ""
	for n: NPC in _npc_with(func(n): return Chapel.is_clergy(n)).slice(0, 2):
		var had := p.inv.ids().filter(func(id): return GameData.item(id).has("food"))
		if _talk(n) and main.ui.is_open("talk") and _press("Ask the church for food"):
			for id in p.inv.ids():
				if GameData.item(id).has("food") and not GameData.item(id).has("harm"):
					note("the church gave food (%s)" % id)
					main.ui.hide_all()
					return id
		main.ui.hide_all()
	return ""


## The reeve: walk up, "Any work for me?", take the first job on the manor's board and do it (walk to each step's place and use
## it) for its wage. Returns whether a job was done and paid.
func _manor_work(when: String) -> bool:
	var w: World = main.world
	var p := w.player
	var ui = main.ui
	var reeve: NPC = w.npc(w.reeve_id)
	check(reeve != null and _talk(reeve) and ui.is_open("talk"), when + ": walked up to the reeve %s and the talk window opened (%s)" % [reeve.name if reeve else "?", ui.panel_kind])
	check(_press("Any work for me?"), "the reeve is asked \"Any work for me?\" (choices: %s)" % ", ".join(_buttons()))
	var treasury0 := w.treasury
	var took := false
	if ui.is_open("manor_jobs"):
		var listing: Array = ui.panel_body.find_children("*", "Label", true, false).map(func(l): return str(l.text)).filter(func(t): return t.contains("coins"))
		note("the manor's board: %s" % " | ".join(listing))
		# the board's rows in the window's order (show_manor_jobs: one row per kind of job and wage); a job that needs no goods
		# gathered first (carrying, mending) is chosen when there is one, else the first
		var mw: ManorWork = w.manor_work
		var rows := []
		var seen := {}
		for j in mw.open_for("player"):
			var key := "%s|%d" % [mw.describe(j), mw.wage_for(j, w.acting_ref())]
			if not seen.has(key):
				seen[key] = true
				rows.append(j)
		rows = rows.slice(0, 6)
		var pick := 0
		for i in rows.size():
			if str(rows[i].kind) in ["haul", "mend"]:
				pick = i
				break
		var takes: Array = ui.panel_body.find_children("*", "Button", true, false).filter(func(b): return str(b.text) == "Take it")
		if pick < takes.size():
			(takes[pick] as Button).pressed.emit()
			took = true
	else:
		note("%s, %s: no board work: %s" % [when, w.clock_text(), _talk_text()])
		# journey finding 2: the opening hint sends a new player to the reeve, whose board is set at five in the evening; with
		# nothing on it yet the reeve says when to come back and who else hires, so the first morning is no dead end
		if w.manor_work.jobs.is_empty():
			var said := _talk_text()
			var due := "this evening" if w.last_reeve_day != w.day() else "tomorrow evening"
			check(said.contains(due) and said.contains("Any work for me?"), "%s: with nothing on the board the reeve says when to ask again (%s) and who else hires" % [when, due])
	var mj: Dictionary = w.manor_work.job_of("player")
	var manor_done := false
	if took and not mj.is_empty():
		var wage := int(mj.reserved)
		check(wage > 0 and w.treasury == treasury0 - wage, "took the manor's work \"%s\": its wage %d set aside from the treasury (%d -> %d)" % [w.manor_work.describe(mj), wage, treasury0, w.treasury])
		_conserved("after taking the manor's work")
		var purse := p.coins
		var steps := 0
		var log := []
		while not w.manor_work.job_of("player").is_empty() and steps < 40:
			steps += 1
			var cell: Vector2i = w.manor_work.step_cell(mj)
			if not _walk_to(Vector2(cell) + Vector2(0.5, 0.5), 1.4, 1500):
				log.append("could not reach %s" % str(cell))
				break
			main._find_target()
			for k in 8:
				if str(main.target.get("kind", "")) == "manor_job":
					break
				main.cycle_target(1)
			if str(main.target.get("kind", "")) != "manor_job":
				log.append("no manor-job target at %s (step %s, target %s)" % [str(cell), w.manor_work.step(mj), str(main.target.get("kind", ""))])
				break
			log.append(w.manor_work.step(mj))
			main.interact()
			_finish_action()
			if main.ui.modal():
				main.ui.hide_all()
		note("manor work steps: %s" % ", ".join(log))
		var done: bool = w.manor_work.job_of("player").is_empty()
		check(done, "the manor's work is done by walking to it and using it (%d steps)" % steps)
		if done:
			manor_done = true
			check(p.coins == purse + wage, "the manor paid its wage: %d coins (purse %d -> %d)" % [wage, purse, p.coins])
		elif w.manor_work.job_of("player").get("kind", "") == "quarry":
			note("a quarry job needs stone mined first: left to the mining step")
	else:
		note("the player took no manor job (board shown: %s)" % ui.panel_kind)
	return manor_done


func _eat_if_hungry(step: String) -> void:
	var w: World = main.world
	var p := w.player
	if p.hunger >= 60.0:
		return
	var food := ""
	for id in p.inv.ids():
		if GameData.item(id).has("food") and not GameData.item(id).has("harm"):
			food = id
			break
	var waited := 0
	while food == "" and waited < 10:
		food = _buy_food()
		if food == "":
			food = _buy_food()                # the next best shop when the first could not be reached
		skip_sellers = {}
		if food == "":
			food = _ask_church()
		if food == "":
			waited += 1                       # shops shut (night, early morning): rest a while and look again, as a player would
			main._rest_now()
			main.ui.hide_all()
			_frames(5)
	if waited > 0:
		note("%s: waited %d rests for food to be within reach (%s)" % [step, waited, w.clock_text()])
	check(food != "", "%s: hungry (%.0f), the player can get food (%s; coins %d)" % [step, p.hunger, food, p.coins])
	if food != "":
		var h0 := p.hunger
		check(w.player_eat(food) and p.hunger > h0, "%s: ate %s (hunger %.0f -> %.0f)" % [step, food, h0, p.hunger])


# ------------------------------------------------------------------ the journey --------------------
func _run() -> void:
	var ui = main.ui
	# 1. the title: New game, character creation, the origin's Begin
	check(ui.is_open("title") and main.world == null, "the game opens on its title (no world yet)")
	check(not _buttons().any(func(t): return t.to_lower().contains("debug") or t.to_lower().contains("cheat")), "the title offers no debug or cheat entry (%s)" % ", ".join(_buttons()))
	check(_press("New game"), "New game pressed")
	check(ui.is_open("creation"), "character creation opens")
	var edits: Array = ui.panel_body.find_children("*", "LineEdit", true, false)
	check(edits.size() >= 2, "the creator has name and family fields (%d)" % edits.size())
	_press("Begin")
	check(ui.is_open("creation") and main.world == null, "Begin with no name stays in creation (asks for a name)")
	if edits.size() >= 2:
		(edits[0] as LineEdit).text = "Ada"
		(edits[1] as LineEdit).text = "Thorne"
	check(_press("Begin"), "Begin pressed with a name")
	await process_frame
	check(main.world != null and ui.is_open("origin"), "the world is made and the origin story shown")
	check(_press("Begin"), "the origin's Begin pressed")
	await process_frame
	var w: World = main.world
	var p := w.player
	check(main.running and not main.paused and not ui.modal(), "play begins (running, not paused, no window)")
	check(p.name == "Ada" and p.family == "Thorne", "the player is the character created (%s %s)" % [p.name, p.family])
	check(p.coins == int(GameData.b("start_coins_player")) and p.inv.has("rusty_pickaxe"), "the starting purse (%d coins) and kit" % p.coins)
	check(FileAccess.file_exists(TEST_SAVE), "the new world is saved at once")
	check(w.player_messages().size() >= 1 and str(w.player_messages()[0][2]).contains("Any work for me?"), "the journal's first message says where paid work is")
	coins_start = w.total_coins()
	stats_start = w.stats.duplicate()
	sources_start = w.coin_sources
	note("start: %s, coins in the world %d, villagers %d" % [w.clock_text(), coins_start, w.npcs.size()])

	# 2. walking with the movement actions (keys, stick)
	var moved := []
	for a in ["move_right", "move_down", "move_left", "move_up"]:
		var at := p.pos
		Input.action_press(a)
		_frames(10)
		Input.action_release(a)
		_frames(1)
		moved.append("%s %.2f" % [a, at.distance_to(p.pos)])
		check(at.distance_to(p.pos) > 0.5 or main.walk_stuck > 0.0, "walking %s moves the player or meets something solid (%.2f tiles)" % [a, at.distance_to(p.pos)])
	var m0: float = w.minutes
	_frames(50)
	check(w.minutes > m0, "the clock runs while playing (%.1f -> %.1f game minutes)" % [m0, w.minutes])
	_conserved("after walking")

	# 3. the reeve: "Any work for me?" and the manor's work, done for its wage
	manor_paid = _manor_work("day %d" % w.day())
	_conserved("after the manor's work")

	# 4. paid work from a villager: "Any work for me?" to a farmer, miner or woodcutter
	main.ui.hide_all()
	var asked := 0
	var offered := ""
	for n: NPC in _npc_with(func(n): return w.quests.hires(n)).slice(0, 4):
		if not _talk(n) or not ui.is_open("talk"):
			continue
		if not _press("Any work for me?"):
			continue
		asked += 1
		var said := _talk_text()
		if _press("I'll do it"):
			offered = "%s (%s): %s" % [n.name, n.job, said.substr(0, 120)]
			break
		note("%s (%s): %s" % [n.name, n.job, said.substr(0, 120)])
	check(asked > 0, "villagers who hire were asked \"Any work for me?\" (%d)" % asked)
	if offered != "":
		check(not p.quests.is_empty(), "paid work accepted and written in the journal's quests: %s" % offered)
	else:
		note("nobody offered paid work just now (asked %d)" % asked)
	main.ui.hide_all()
	_conserved("after asking for paid work")

	# 5. gathering: mine with the starting pickaxe at a real seam (walked to), then sell what was mined
	var mined := {}
	for ore in ["stone", "coal", "iron_ore", "copper_ore"]:
		var d := w.nearest_deposit(Vector2i(p.pos), [ore])
		if d.is_empty():
			continue
		var cell := Vector2i(int(d.x), int(d.y))
		var stand: Vector2i = w.brain.beside(cell, cell + Vector2i(0, 1))
		if not _walk_to(Vector2(stand) + Vector2(0.5, 0.5), 0.8, 2500):
			note("could not walk to the %s seam at %s (stood at %s)" % [ore, str(cell), str(p.pos)])
			continue
		main.player_sprite.face(Vector2(cell) + Vector2(0.5, 0.5) - p.pos)
		main._find_target()
		for k in 8:
			if str(main.target.get("kind", "")) == "deposit":
				break
			main.cycle_target(1)
		if str(main.target.get("kind", "")) != "deposit":
			note("no seam to use at the %s deposit (target %s)" % [ore, str(main.target.get("kind", ""))])
			continue
		for i in 4:
			main._find_target()
			if str(main.target.get("kind", "")) != "deposit":
				break
			var c0 := p.inv.total() if p.inv.has_method("total") else 0
			main.interact()
			_finish_action()
		for id in ["stone", "coal", "iron_ore", "copper_ore", "tin_ore"]:
			if p.inv.count(id) > 0:
				mined[id] = p.inv.count(id)
		if not mined.is_empty():
			break
	check(not mined.is_empty(), "walked to a seam and mined with the starting pickaxe: %s" % str(mined))
	_conserved("after mining")
	var mj2: Dictionary = w.manor_work.job_of("player")
	if not mj2.is_empty():
		note("still holding manor work: %s" % w.manor_work.describe(mj2))
	var earned := 0
	for id in mined:
		for n: NPC in _npc_with(func(n): return w.brain.wants(n, id) > 0 and w.purchase_qty(n, p, id, p.inv.count(id)) > 0).slice(0, 2):
			if p.inv.count(id) == 0:
				break
			if not _talk(n):
				continue
			main.ui.show_trade(n, {"id": id, "mode": "sell", "price": w.deal_price(w.buy_price(n, id), n, p)})
			var qp = _picker()
			if qp == null:
				continue
			var q := mini(p.inv.count(id), w.purchase_qty(n, p, id, p.inv.count(id)))
			var purse := p.coins
			var theirs := n.coins
			qp.confirmed.emit(q)
			var got := p.coins - purse
			check(got >= 0 and theirs - n.coins == got, "sold %s to %s (%s) through the trade window: +%d coins, from their own purse" % [id, n.name, n.job, got])
			earned += got
			main.ui.hide_all()
	note("earned by selling what was mined: %d coins" % earned)
	_conserved("after selling")

	# 6. the shop: buy food and eat it
	var food := _buy_food()
	check(food != "", "bought food at a shop (%s)" % food)
	if food != "":
		var h0 := p.hunger
		p.hunger = minf(p.hunger, 50.0) if h0 > 50.0 else h0
		var h1 := p.hunger
		var n0 := p.inv.count(food)
		check(w.player_eat(food) and p.inv.count(food) == n0 - 1 and p.hunger > h1, "ate the %s from the pack (hunger %.0f -> %.0f)" % [food, h1, p.hunger])
	_conserved("after buying and eating")

	# 7. save, and continue from the title: the purse, pack and journal come back exactly
	main.ui.hide_all()
	_frames(5)
	var before := _snapshot()
	check(main.save_game(false), "saved")
	main.ui.show_title(main.can_continue())
	check(_press("Continue"), "Continue pressed on the title")
	var after := _snapshot()                  # (before a frame of play passes: the player's hunger falls frame by frame)
	await process_frame
	w = main.world
	p = w.player
	for k in ["coins", "inv", "player", "log", "messages", "quests", "minutes", "world_coins", "pos"]:
		check(str(before[k]) == str(after[k]), "after the reload, %s is exactly as saved%s" % [k, "" if str(before[k]) == str(after[k]) else " (%s)" % _diff(str(before[k]), str(after[k]))])
	check(main.running and not main.paused and not ui.modal(), "play resumes after Continue")
	_conserved("after the reload")

	# 8. several days: rest through them, eat as needed, walk, and keep the books
	var day0 := w.day()
	var at := p.pos
	for d in 3:
		var day_before := w.day()
		var guard := 0
		while w.day() == day_before and guard < 14 and p.alive:
			guard += 1
			_eat_if_hungry("day %d" % w.day())
			main._rest_now()
			main.ui.hide_all()
			_frames(5)
		check(p.alive and w.day() > day_before, "a day passes (day %d -> %d, %d rests): %s, hunger %.0f, health %.0f, coins %d" % [day_before, w.day(), guard, w.clock_text(), p.hunger, p.hp, p.coins])
		_conserved("day %d" % w.day())
		var here := p.pos
		Input.action_press("move_left" if d % 2 == 0 else "move_right")
		_frames(10)
		Input.action_release("move_left" if d % 2 == 0 else "move_right")
		_frames(1)
		var moved_px: float = here.distance_to(p.pos)
		if moved_px < 0.5:
			Input.action_press("move_down")
			_frames(10)
			Input.action_release("move_down")
			_frames(1)
		check(here.distance_to(p.pos) > 0.5, "day %d: the player can still walk (%.2f tiles)" % [w.day(), here.distance_to(p.pos)])
		# work stays within reach: the reeve's board or a villager who hires
		if not manor_paid and w.manor_work.open_for("player").size() > 0:
			manor_paid = _manor_work("day %d" % w.day())
			_conserved("day %d, after the manor's work" % w.day())
		var hires: int = w.npcs.filter(func(n): return n.alive and w.quests.hires(n)).size()
		var board: int = w.manor_work.open_for("player").size()
		check(hires + board > 0, "day %d: paid work is within reach (%d jobs on the manor's board, %d villagers who hire)" % [w.day(), board, hires])
		var sellers := 0
		for n: NPC in w.npcs:
			if n.alive and w.brain.for_sale(n).any(func(id): return GameData.item(id).has("food")):
				sellers += 1
		check(sellers > 0, "day %d: food is for sale (%d villagers sell food)" % [w.day(), sellers])
	check(manor_paid, "the manor's work was taken from the reeve's board, done and paid within the days")
	check(w.day() >= day0 + 3, "three days went by (day %d -> %d)" % [day0, w.day()])
	_eat_if_hungry("the last day")

	# 9. a last save and reload after the days
	main.ui.hide_all()
	var b2 := _snapshot()
	check(main.save_game(false), "saved after the days")
	main.continue_game()
	var a2 := _snapshot()
	await process_frame
	for k in ["coins", "inv", "player", "log", "messages", "quests", "world_coins"]:
		check(str(b2[k]) == str(a2[k]), "after the second reload, %s is exactly as saved%s" % [k, "" if str(b2[k]) == str(a2[k]) else " (%s)" % _diff(str(b2[k]), str(a2[k]))])
	w = main.world
	_conserved("at the end")
	note("end: %s, purse %d, pack %s, hunger %.0f, health %.0f, journal %d lines, %d messages" % [w.clock_text(), w.player.coins,
		str(w.player.inv.ids()), w.player.hunger, w.player.hp, w.log_lines.size(), w.player_messages().size()])
	print("%d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)


func _talk_text() -> String:
	var out := []
	for l in main.ui.panel_body.find_children("*", "Label", true, false):
		out.append(str(l.text))
	for l in main.ui.panel_body.find_children("*", "RichTextLabel", true, false):
		out.append(str(l.text))
	return " / ".join(out).replace("\n", " ")


## What differs between two JSON texts: the top-level keys whose values differ (a dictionary), else the first differing place.
func _diff(a: String, b: String) -> String:
	var da = JSON.parse_string(a)
	var db = JSON.parse_string(b)
	if da is Dictionary and db is Dictionary:
		var out := []
		var keys: Array = (da as Dictionary).keys()
		for k in (db as Dictionary).keys():
			if not keys.has(k):
				keys.append(k)
		for k in keys:
			var va := JSON.stringify(da.get(k))
			var vb := JSON.stringify(db.get(k))
			if va != vb:
				out.append("%s: %s -> %s" % [k, va.substr(0, 200), vb.substr(0, 200)])
		return "; ".join(out)
	var i := 0
	while i < mini(a.length(), b.length()) and a[i] == b[i]:
		i += 1
	return "first difference at %d: %s -> %s" % [i, a.substr(maxi(0, i - 40), 120), b.substr(maxi(0, i - 40), 120)]
