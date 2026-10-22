extends SceneTree
## DVW-B5: the tax band with hysteresis, announced before it applies (TaxPolicy; NPCBrain.reeve_day).
##   godot --headless --path game --script res://tests/tax_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	rates_unchanged()
	no_flip_flop()
	announced_before_applied()
	withdrawn_when_treasury_returns()
	live_world()
	save_round_trip()
	determinism()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func rates_unchanged() -> void:
	check(is_equal_approx(TaxPolicy.rate_of(TaxPolicy.LOW), 0.12) and is_equal_approx(TaxPolicy.rate_of(TaxPolicy.NORMAL), 0.06) and TaxPolicy.rate_of(TaxPolicy.HOLIDAY) == 0.0, "rates stay 12% / 6% / 0%")
	check(int(GameData.b("treasury_reserve_days")) == 10 and int(GameData.b("treasury_tax_holiday_days")) == 30, "boundaries stay 10 and 30 days")


## Run a treasury series (days of obligations per day) through the policy; return [rates, notes].
func run_series(series: Array, start_day := 0) -> Array:
	var st := {}
	var rates := []
	var notes := []
	for i in series.size():
		var r := TaxPolicy.step(st, float(series[i]), 1.0, start_day + i)
		rates.append(r.rate)
		notes.append_array(r.notes)
	return [rates, notes, st]


func changes(rates: Array) -> int:
	var n := 0
	for i in range(1, rates.size()):
		if rates[i] != rates[i - 1]:
			n += 1
	return n


func no_flip_flop() -> void:
	# a treasury wobbling across the 10-day line (9..11): the old rule flipped 12%/6% every day
	var wob := []
	for i in 40:
		wob.append(9.0 if i % 2 == 0 else 11.0)
	var r := run_series(wob)
	check(changes(r[0]) == 0, "wobble 9/11 days around the reserve line changes no rate")
	var old_changes := 0
	for i in range(1, wob.size()):
		if (wob[i] < 10.0) != (wob[i - 1] < 10.0):
			old_changes += 1
	check(old_changes > 30, "(the old single-threshold rule would have flipped %d times)" % old_changes)
	var wob2 := []
	for i in 40:
		wob2.append(29.0 if i % 2 == 0 else 31.0)
	check(changes(run_series(wob2)[0]) == 0, "wobble around the 30-day holiday line changes no rate")


func announced_before_applied() -> void:
	# normal at 15 days, then the treasury falls to 5: low band, announced 3 days ahead
	var series := [15.0, 15.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
	var r := run_series(series)
	var rates: Array = r[0]
	check(rates[0] == 0.06 and rates[2] == 0.06 and rates[3] == 0.06 and rates[4] == 0.06, "old rate stays for the announced days (rates %s)" % str(rates))
	check(rates[5] == 0.12, "the new rate applies on day 5 = announced day 2 + 3")
	var notes: Array = r[1]
	check(notes.size() == 2 and "announces" in str(notes[0]) and "in 3 days" in str(notes[0]) and "applies from today" in str(notes[1]), "an announcement, then the change: %s" % str(notes))
	# a rise to 12.5 days (margin 20% over 10) goes back to normal; 11 does not
	var up := run_series([5.0, 5.0, 11.0, 11.0, 11.0, 11.0, 11.0, 11.0])
	check(changes(up[0]) == 0, "11 days does not lift the low band (needs 12)")
	var up2 := run_series([5.0, 13.0, 13.0, 13.0, 13.0, 13.0])
	check(up2[0][5] == 0.06 and up2[0][3] == 0.12, "13 days lifts the low band after the notice")
	# full treasury: holiday only past 36
	var hol := run_series([20.0, 33.0, 33.0, 33.0, 33.0, 33.0, 40.0, 40.0, 40.0, 40.0, 40.0])
	check(hol[0][5] == 0.06 and hol[0][10] == 0.0, "holiday begins after 36 days and its notice")


func withdrawn_when_treasury_returns() -> void:
	var r := run_series([15.0, 5.0, 5.0, 15.0, 15.0, 15.0, 15.0])
	check(changes(r[0]) == 0 and r[0][6] == 0.06, "an announced rise is withdrawn when the treasury recovers")
	check(r[1].size() == 2 and "withdraws" in str(r[1][1]), "the withdrawal is recorded")


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func live_world() -> void:
	var w := new_world()
	var ob: float = w.brain.daily_obligations()
	w.treasury = int(ob * 15.0)
	var before := w.total_coins()
	w.brain.reeve_day()
	check(int(w.tax_state.band) == TaxPolicy.NORMAL and w.tax_state.pending.is_empty(), "a new world starts in the band its treasury shows, with no announcement")
	check(w.total_coins() == before, "coins conserved by a tax day (%d)" % before)
	w.treasury = int(ob * 2.0)
	var log_n := w.log_lines.size()
	w.brain.reeve_day()
	check(not w.tax_state.pending.is_empty() and w.log_lines.slice(log_n).any(func(l): return "announces" in l), "a fall is announced in the village record")
	check(TaxPolicy.status_text(w.tax_state, w.day()).find("In 3 days") >= 0, "status text shows the coming change: %s" % TaxPolicy.status_text(w.tax_state, w.day()))
	var t0 := w.total_coins()
	w.brain.reeve_day()
	check(w.total_coins() == t0, "coins conserved across tax days")


func save_round_trip() -> void:
	var w := new_world()
	w.tax_state = {"band": 1, "pending": {"to": 0, "announced": 4, "effective": 7, "from_rate": 0.06, "to_rate": 0.12}}
	var d := w.to_dict()
	check(d.has("tax"), "the save carries the tax state")
	var w2 := new_world()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(int(w2.tax_state.band) == 1 and int(w2.tax_state.pending.effective) == 7, "tax state round trips through JSON")
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	old.erase("tax")
	var w3 := new_world()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.tax_state.is_empty(), "an old save without the key loads (state read at the next reeve evening)")
	w3.brain.reeve_day()
	check(w3.tax_state.has("band"), "...and the band is set then")


func determinism() -> void:
	var s := []
	for i in 60:
		s.append(8.0 + 6.0 * sin(i * 0.5) + (i % 7))
	check(str(run_series(s)) == str(run_series(s)), "same treasury series, same rates and notes")
