extends SceneTree
## ND-12 / B25-ND12-01 (owner 2026-11-10, docs/directives/2026-11-10_nd12_recorder_diagnostic.md). FlightRecorder.end(id, outcome,
## reason, detail) replaced the detail line an event was begun with whenever it was given one of its own. Two kinds of event
## carried both: a refused buy_from (NPCBrain._record_refused_buy: begun with "item=... qty=... price=... purse=... reserve=...
## stock=...", ended with "below_reserve"), so every such refusal in the campaigns kept only "below_reserve" and lost the figures
## that decided it (seen in campaign 42788018729: p:99's 553 refusals on day 196); and every player verb (WorldRecorder.verb_begin /
## verb_end: buy, craft, strike, loot, take, sell), which lost what was attempted (item, quantity, target) to the outcome text.
## Distinct events were never lost: each event is its own row. The fix keeps both lines ("begun; ended"), the one detail field
## the archive and the analysis tools read (flight_analyse.kv reads key=value tokens separated by spaces or ';'). Checked:
##   1 a refused buy keeps its figures (item, qty, price, purse, reserve, stock) and the refusal word
##   2 a player's purchase refused for want of coin keeps what was asked (item x qty from vendor) and the refusal text
##   3 three refusals by one villager in the same minute are three distinct events, each with its own item, none duplicated
##   4 an event given a detail only at its start, or only at its end, keeps exactly that line (no doubled text)
##   5 two identical runs record identical event rows (deterministic); the recorder changes no coins
##   godot --headless --path game --script res://tests/recorder_detail_test.gd

var checks := 0
var fails := 0
var tmp_root := ""


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	tmp_root = OS.get_cache_dir() + "/mml_recorder_detail_%d" % int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(tmp_root)
	var a := scenario("a")
	var b := scenario("b")
	check_events(a.events, a)
	check(JSON.stringify(a.rows) == JSON.stringify(b.rows) and not (a.rows as Array).is_empty(), "two identical runs record identical event rows (%d rows)" % (a.rows as Array).size())
	check(int(a.coins_before) == int(a.coins_after), "recording changes no coins (%d -> %d)" % [int(a.coins_before), int(a.coins_after)])
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## Records the cases in a fresh world and returns {events (by subtype marker), rows (comparable), coins before/after}.
func scenario(tag: String) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var rec := WorldRecorder.attach(w, {"tmp_root": tmp_root + "/" + tag})
	var buyer: NPC = null
	var seller: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult":
			if buyer == null:
				buyer = o
			elif seller == null and o.household != buyer.household:
				seller = o
	for id in ["iron_ore", "coal", "plank"]:
		seller.inv.add(id, 5)
	# 1 and 3: three refusals by one villager in one minute (the act's own refusal record)
	for id in ["iron_ore", "coal", "plank"]:
		w.brain._record_refused_buy(buyer, seller, id, 4, 3)
	# 2: a player's purchase (a verb with a detail at both ends)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper":
			v = o
			break
	v.inv.add("pottage", 2)
	w.player.pos = v.pos + Vector2(1, 0)
	w.treasury += w.player.coins                  # (conserved: the purse goes to the manor, so the purchase is refused for want of coin)
	w.player.coins = 0
	var c0 := w.total_coins()
	w.player_buy_many(v, "pottage", 1)
	# 4: begin-only and end-only details
	var e1: int = rec.begin("world", "property", "property", "nd12_begin_only", "world", {"detail": "only at begin"})
	rec.end(e1, "ok")
	var e2: int = rec.begin("world", "property", "property", "nd12_end_only", "world", {})
	rec.end(e2, "ok", "", "only at end")
	var c1 := w.total_coins()
	w.dispose()
	var rows := RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event")
	var keep := []
	for e in rows:
		keep.append([e.id, e.day, e.minute, e.subtype, e.actor, e.outcome, e.reason, e.detail])
	return {"events": rows, "rows": keep, "coins_before": c0, "coins_after": c1, "buyer": "p:%d" % buyer.id}


func check_events(rows: Array, s: Dictionary) -> void:
	var refused := rows.filter(func(e): return str(e.subtype) == "trade" and str(e.outcome) == "refused" and str(e.actor) == str(s.buyer))
	check(refused.size() == 3, "three refusals in one minute are three events (%d)" % refused.size())
	var items := {}
	var same_minute := true
	var ids := {}
	for e in refused:
		var d := str(e.detail)
		items[d.get_slice("item=", 1).get_slice(" ", 0)] = true
		ids[int(e.id)] = true
		same_minute = same_minute and int(e.day) == int(refused[0].day) and float(e.minute) == float(refused[0].minute)
	check(items.size() == 3 and ids.size() == 3 and same_minute, "each keeps its own item and id, all in the same minute (items %s)" % str(items.keys()))
	var r0 := str(refused[0].detail) if not refused.is_empty() else ""
	var has_all := true
	for k in ["item=", "qty=", "price=", "purse=", "reserve=", "stock="]:
		has_all = has_all and r0.contains(k)
	check(has_all, "a refused buy keeps the figures that decided it (detail: %s)" % r0)
	check(r0.contains("below_reserve") and str(refused[0].reason) == "refused_by_rules", "and keeps the refusal word and reason (%s / %s)" % [r0, str(refused[0].reason) if not refused.is_empty() else ""])
	var verbs := rows.filter(func(e): return str(e.subtype) == "buy" and str(e.actor).begins_with("p:") and str(e.actor) != str(s.buyer))
	var vd := str(verbs[0].detail) if not verbs.is_empty() else ""
	check(not verbs.is_empty() and vd.contains("pottage x1 from"), "a player's purchase keeps what was asked (detail: %s)" % vd)
	check(vd.contains(";") and vd.get_slice(";", 1).strip_edges() != "", "and the outcome text after it (%s)" % vd)
	var bo := rows.filter(func(e): return str(e.subtype) == "nd12_begin_only")
	var eo := rows.filter(func(e): return str(e.subtype) == "nd12_end_only")
	check(bo.size() == 1 and str(bo[0].detail) == "only at begin", "a begin-only detail is kept exactly (%s)" % (str(bo[0].detail) if not bo.is_empty() else "-"))
	check(eo.size() == 1 and str(eo[0].detail) == "only at end", "an end-only detail is kept exactly (%s)" % (str(eo[0].detail) if not eo.is_empty() else "-"))
	var seen := {}
	var dup := 0
	for e in rows:
		if seen.has(int(e.id)):
			dup += 1
		seen[int(e.id)] = true
	check(dup == 0, "no event id appears twice (%d duplicates in %d rows)" % [dup, rows.size()])
