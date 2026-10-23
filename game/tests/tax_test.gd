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
	settlements_use_the_banded_rule()
	settlement_taxes_save()
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


## DVW-B5, the settlements: each of the five uses the village's banded, announced rule on its own treasury, keeps its own state,
## and writes its announcements to its own journal (never the village record).
func settlements_use_the_banded_rule() -> void:
	var w := new_world()
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var other: OffMapSettlement = w.regions.by_id["garton"]
	var ob: float = float(s._obligations())
	var log_n := w.log_lines.size()
	# the same treasury series through the settlement and through TaxPolicy alone: the same rates and the same lines
	var series := [15.0, 15.0, 2.0, 2.0, 2.0, 2.0, 2.0, 15.0, 15.0, 15.0, 15.0, 15.0, 35.0, 35.0, 35.0, 35.0, 35.0, 35.0]
	var mirror := {}
	var rates_s := []
	var rates_m := []
	var lines_m := []
	for i in series.size():
		s.day = 20 + i
		s.gov.coins = int(ob * series[i])
		var treasury_before: int = int(s.gov.coins)
		var hh_coins: int = 0
		for h in s.hh:
			hh_coins += int(h.coins)
		s._taxes_and_officials()
		var st: Dictionary = TaxPolicy.step(mirror, float(treasury_before), ob, 20 + i)
		rates_m.append(st.rate)
		lines_m.append_array(st.notes)
		rates_s.append(TaxPolicy.rate_of(int(s.tax.band)))
	check(rates_s == rates_m, "a settlement's rate follows the village's rule day for day (%s)" % str(rates_s.slice(0, 8)))
	var told := s.journal.map(func(e): return str(e.text))
	check(told == lines_m and not told.is_empty(), "its announcements are its own journal's lines (%d)" % told.size())
	check(told.any(func(l): return "announces" in l) and w.log_lines.size() == log_n, "an announcement is in the settlement's journal and not in the village log")
	check(other.tax.is_empty() and other.journal.is_empty(), "another settlement keeps its own state: untouched")
	var changes := 0
	for i in range(1, rates_s.size()):
		changes += 1 if rates_s[i] != rates_s[i - 1] else 0
	check(changes == 2, "the rate changed twice over the run, each time after notice (%d)" % changes)
	# a wobble across the 10-day line never flips the rate
	var t := OffMapSettlement.create(OffMapSettlement.data().settlements[3], 5, 3)
	var flips := 0
	var last := -1.0
	for i in 40:
		t.day = i
		t.gov.coins = int(float(t._obligations()) * (9.0 if i % 2 == 0 else 11.0))
		t._taxes_and_officials()
		var r := TaxPolicy.rate_of(int(t.tax.band))
		flips += 1 if last >= 0.0 and r != last else 0
		last = r
	check(flips <= 1, "a treasury wobbling across the line does not flip a settlement's rate (%d changes in 40 days)" % flips)
	# coins conserved: tax moves coins from households and tills to the treasury
	var u := OffMapSettlement.create(OffMapSettlement.data().settlements[0], 5, 0)
	u.day = 3
	u.gov.coins = 5
	u.start.coins = u.coins()
	for h in u.hh:
		h.coins += 200
	u.start.coins = u.coins()
	var c0 := u.coins()
	u._taxes_and_officials()
	check(u.coins() == c0 and int(u.flows.tax_households) > 0, "a low treasury taxes households at the low rate, coins conserved (%d taken)" % int(u.flows.tax_households))


func settlement_taxes_save() -> void:
	var s := OffMapSettlement.create(OffMapSettlement.data().settlements[0], 5, 0)
	s.day = 4
	s.gov.coins = 3
	s._taxes_and_officials()
	s.day = 5
	s.gov.coins = 400
	s._taxes_and_officials()
	check(s.tax.has("band") and not s.journal.is_empty(), "the settlement has a tax state and a journal to save")
	var text := JSON.stringify(s.to_dict(), "", true, true)
	var l := OffMapSettlement.from_dict(JSON.parse_string(text))
	check(JSON.stringify(l.to_dict(), "", true, true) == text, "saved and loaded, the tax state and the journal are exactly as they were")
	check(int(l.tax.band) == int(s.tax.band) and (l.tax.pending.is_empty() == s.tax.pending.is_empty()), "(band and pending notice intact)")
	var old: Dictionary = JSON.parse_string(text)
	old.erase("tax")
	old.erase("journal")
	var o := OffMapSettlement.from_dict(old)
	o.day = 9
	o._taxes_and_officials()
	check(o.tax.has("band") and o.journal.is_empty(), "a save from before this loads and starts in the band its treasury shows")
