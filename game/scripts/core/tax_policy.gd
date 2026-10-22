class_name TaxPolicy
extends RefCounted
## DVW-B5: the manor's tax rate as a band with hysteresis, changed only after an announcement.
##
## Three bands, by the treasury measured in days of the manor's daily obligations (wages), with the rates and
## thresholds the game has always had: LOW (under `treasury_reserve_days`: `tax_rate_low_treasury`), NORMAL
## (`tax_rate_normal`) and HOLIDAY (at `treasury_tax_holiday_days` and above: no tax). A boundary is not one line but a
## margin either side (`tax_band_margin`): the rate falls only once the treasury has risen that margin above the
## boundary and rises only once it has fallen that margin below it, so a treasury hovering at a boundary never
## flips the rate. A change is announced (the village record) `tax_announce_days` before it applies and applies only if
## the treasury still calls for it on that day; if the treasury returns, the announcement is withdrawn.
## State (a plain Dictionary, saved under the world's optional "tax" key): {band: 0|1|2, pending: {} or
## {to, announced, effective, from_rate, to_rate}}. Empty state starts in the band the treasury plainly shows, with
## no announcement. Pure functions of (state, treasury, obligations, day, balance): deterministic, no randomness.

const LOW := 0
const NORMAL := 1
const HOLIDAY := 2


static func rate_of(band: int) -> float:
	match band:
		LOW:
			return float(GameData.b("tax_rate_low_treasury"))
		NORMAL:
			return float(GameData.b("tax_rate_normal"))
	return 0.0


static func _days(treasury: float, obligations: float) -> float:
	return treasury / obligations if obligations > 0.0 else INF


## The band the treasury plainly shows, with no hysteresis (the starting band, as the old single-threshold rule).
static func plain_band(days: float) -> int:
	if days >= float(GameData.b("treasury_tax_holiday_days")):
		return HOLIDAY
	return NORMAL if days >= float(GameData.b("treasury_reserve_days")) else LOW


## The band the treasury calls for from band `cur`, with the margin on each boundary.
static func target_band(cur: int, days: float) -> int:
	var m := float(GameData.b("tax_band_margin"))
	var r := float(GameData.b("treasury_reserve_days"))
	var h := float(GameData.b("treasury_tax_holiday_days"))
	if days >= (h * (1.0 + m) if cur < HOLIDAY else h * (1.0 - m)):
		return HOLIDAY
	if days >= (r * (1.0 + m) if cur < NORMAL else r * (1.0 - m)):
		return NORMAL
	return LOW


static func _why(to: int) -> String:
	match to:
		LOW:
			return "the treasury has run low"
		HOLIDAY:
			return "the treasury is full"
	return "the treasury has recovered"


static func _pct(rate: float) -> String:
	return "no tax" if rate <= 0.0 else "%d%%" % int(round(rate * 100.0))


## One day's step (the reeve's evening, before tax is taken). Returns {rate, notes}: the rate to collect today and the
## lines for the village record (announcements, changes, withdrawals). Mutates `state`.
static func step(state: Dictionary, treasury: float, obligations: float, day: int) -> Dictionary:
	var notes: Array[String] = []
	var days := _days(treasury, obligations)
	if not state.has("band"):
		state["band"] = plain_band(days)
		state["pending"] = {}
	var cur := int(state.band)
	var want := target_band(cur, days)
	var pend: Dictionary = state.pending
	if want == cur:
		if not pend.is_empty():
			notes.append("The manor withdraws its announced change of tax: the treasury is back where it was, and tax stays at %s." % _pct(rate_of(cur)))
			state["pending"] = {}
	else:
		if pend.is_empty() or int(pend.to) != want:
			var lead := int(GameData.b("tax_announce_days"))
			pend = {"to": want, "announced": day, "effective": day + lead, "from_rate": rate_of(cur), "to_rate": rate_of(want)}
			state["pending"] = pend
			notes.append("The manor announces: in %d days the tax on households and tills changes from %s to %s, because %s." % [
				lead, _pct(rate_of(cur)), _pct(rate_of(want)), _why(want)])
		if day >= int(pend.effective):
			state["band"] = want
			state["pending"] = {}
			cur = want
			notes.append("The manor's new tax applies from today: %s." % _pct(rate_of(cur)))
	return {"rate": rate_of(cur), "notes": notes}


## For the wiki and any display: the rate in force and the announced change, if any.
static func status_text(state: Dictionary, day: int) -> String:
	if not state.has("band"):
		return ""
	var s := "Tax is %s." % _pct(rate_of(int(state.band)))
	var pend: Dictionary = state.get("pending", {})
	if not pend.is_empty():
		s += " In %d days it becomes %s." % [maxi(0, int(pend.effective) - day), _pct(float(pend.to_rate))]
	return s
