class_name JudgmentLive
extends RefCounted
## Expansion 19 (Build 19): the adapter between the live World and the judgment system.
## ON by default in Build 19 (owner 2026-10-23, docs/directives/2026-10-23_x19_complete_release_scope.md): judgment.json
## "enabled" is true, so a new game and a loaded Build 18 save (which has no judgment section and starts clean) run with
## memory, gossip, opinions, personality, family name, lies, family stories and the family-first rules. A test turns it
## off with `test_disabled` (the Build 18 path: World.judgment stays null, a saved section is carried untouched) or on with
## `test_enabled`. Every hook in live code is one guarded line, `if judgment != null`, so with it off the game runs
## exactly as Build 18 (proved by the determinism gate against its baseline when switched off, tools/sim_gate.py).
##
## What it connects, and what it leaves alone:
##   observation   World.witness (a theft seen, PAR-05's one channel for seeing), World.raise_alarm (an attack by
##                 anyone, the player or a villager), World.kill (a villager slain by the player): the same `seen`
##                 lists become an event's witnesses. Who sees, and what guards do, is unchanged.
##   conversation  Relations.share (an hour two people spend together) lets them tell each other what they know.
##   the day       World._new_day: memories fade, old events retire.
##   saving        World.to_dict/load_dict: a "judgment" section only when a store is attached (SAVE_VERSION unchanged).
##   choices       Q14 (owner, 2026-10-21): judgment is one weighted influence inside the EXISTING decision points, by
##                 the one shared interface (JudgmentWeighting.choose); the live code still decides who is feasible:
##                   trade_sell      NPCBrain._buyer_for     whom a villager sells to
##                   trade_buy_from  NPCBrain._seller_of     whom a household buys timber from
##                   hire_choice     Construction._keep_building   whom a building household hires to carry
##                   work_accept     Construction.hire, Business.hire  whether a villager takes the work offered
##                   befriend        Relations._befriend_if_close  whether close villagers become friends
##                   court_choice    Relations._villagers_court    whom a single villager takes an interest in
##                   contract_accept Contracts.evaluate      whether a seller takes on the contract or service offered
##                   contract_seller Contracts._order, Prospecting kit order   which seller a villager buyer asks first
##                   credit_lend     Credit.credit_refusal   whether a villager sells on credit
##                   barter_accept   Credit.barter_quote     whether a villager takes the swap
##                   food_seller     Credit._cheapest_food   whom a short household asks for food
##                   family_help     Construction._family_help  whether a relative household gives toward a home
##                   tool_buy        NPCBrain._buy_tool, _fetch_dress_tool  which seller of a tool a villager buys from, or
##                                                           putting it off (SJD-H C5: the owner's blacksmith example)
##                   report          World.report_crime      whether a villager who knows of a crime tells a guard (R2,
##                                                           SJD-F; integration.report OFF until measured)
##                 each on only with a store attached and its decision.integration flag set; feasibility (stock,
##                 coins, purchase_qty, can_hire, can_court, regard thresholds) and conservation are never overridden.
##                 SJD-H C1 (owner 2026-10-31; docs/expansion20/JUDGMENT_INTEGRATION_AUDIT.md): the choices among
##                 alternatives give each candidate the tier of the live rule it belongs to (its trade, its price), so the
##                 live order steps only between what the live rule can tell apart, and judgment decides among comparable
##                 options; with neutral judgment the live rule's pick still stands (JudgmentWeighting: tiers).


static var shortcut := true          # tests turn it off to compare with the full scan
const LIVE_ORDER_STEP := 10000      # live_order: 100 points for the live rule's first choice, 10 less for each after


## Whether decision point `domain` consults judgment: a store attached and decision.integration[domain] set.
static func on(w, domain: String) -> bool:
	if w == null or w.judgment == null:
		return false
	if not bool((w.judgment.cfg.decision.get("integration", {}) as Dictionary).get(domain, false)):
		return false
	if domain == "job_choice":
		return w.judgment.asp.job_choice_allowed()     # R5: needs aspiration.enabled (refused with a logged reason otherwise)
	return true


## R5 (WDR-011-C): whether the aspiration layer is on for `w` (a store attached and judgment.json aspiration.enabled).
static func aspiring(w) -> bool:
	return w != null and w.judgment != null and w.judgment.asp.enabled


static var test_enabled := false     # tests only: switch judgment on without editing judgment.json
static var test_disabled := false    # tests only: the Build 18 path, judgment off whatever judgment.json says


static func enabled() -> bool:
	if test_disabled:
		return false
	return test_enabled or bool(JudgmentStore.default_cfg().get("enabled", false))


## Attach a judgment store to `w` (reading kinship and friendship from the live world). Returns it.
static func attach(w, config: Dictionary = {}) -> JudgmentStore:
	var j := JudgmentStore.new(config, Social.new(w), int(w.seed))
	j.day = w.day()
	j.world = w                            # R5: the aspiration layer reads the live world (held weakly)
	w.judgment = j
	if "recorder" in w and w.recorder != null:
		j.rec = w.recorder                 # REC-19 D5: a store made after the recorder (a loaded game) records too
		j.pers.rec = w.recorder            # X20-FINAL: and its personality layer
	return j


## The live world's kinship and friendship, read on demand: nothing is copied (spec invariant 7).
class Social extends JudgmentSocial:
	var w

	func _init(world) -> void:
		w = world

	func kin(a: int, b: int) -> bool:
		var pa = Life.parent_of(w, a)
		var pb = Life.parent_of(w, b)
		if pa == null or pb == null:
			return false
		if int(pa.partner) == b or int(pb.partner) == a:
			return true
		return Life.kin(a, int(pa.mother), int(pa.father), b, int(pb.mother), int(pb.father))

	## The family graph of Life: mother, father, children, partner (recorded on the person; a player is their person id).
	func relatives(person: int) -> Array:
		var p = Life.parent_of(w, person)
		var out := []
		if p == null:
			return out
		for pid in [int(p.mother), int(p.father)]:
			if pid != -1:
				out.append([pid, "parent"])
		for cid in p.children:
			out.append([int(cid), "child"])
		if int(p.partner) != -1:
			out.append([int(p.partner), "partner"])
		return out

	func graph_version() -> int:
		return Life.kin_version

	## A guard of the village.
	func is_guard(person: int) -> bool:
		var n = w.npc(person) if person >= 0 else null
		return n != null and n.alive and n.job == "guard"

	## Relations.friends and Relations.peek, read without building a blank tie on every call (peek's default argument is
	## built even when the tie exists): a missing tie is not friends and regard 0, as the blank one says.
	func friends(a: int, b: int) -> bool:
		var t = w.relations.ties.get(Relations.key(a, b))
		return t != null and bool(t.friends)

	## Q06: trust in a teller reuses the existing relationship number, Relations' regard (one tie a pair), 0..100.
	func regard(a: int, b: int) -> int:
		var t = w.relations.ties.get(Relations.key(a, b))
		return 0 if t == null else roundi(float(t.regard))


static func _ids(people: Array) -> Array:
	var out := []
	for n in people:
		if n is NPC and n.role != "bandit":
			out.append(n.id)
	return out


## A theft seen (World.witness): the thief is the player (World.witness is the player's channel today).
static func on_theft(w, kind: String, victim: NPC, seen: Array, value: int) -> void:
	var type := "pickpocket" if kind == "pickpocket" else "theft"
	var ev: int = w.judgment.publish(type, [w.acting_id()], [victim.id] if victim != null else [], [], value, by_tag(w, w.acting_id()))
	if ev > 0:
		w.judgment.observe_all(ev, _ids(seen))


## An attack (World.raise_alarm): anyone's, the player's (-2) or a villager's (a bandit's robbery included).
static func on_attack(w, attacker: int, aware: Dictionary) -> void:
	var v: NPC = aware.get("victim", null)
	if v != null and w.judgment.note_blow(attacker, v.id):
		w.judgment._stat("self_defence_blows")       # X19-EVENT-Q (4): an attack answered within the same fight is not judged as an attack
		return
	var ev: int = w.judgment.publish("assault", [attacker], [v.id] if v != null else [], [], 0, by_tag(w, attacker))
	if ev > 0:
		w.judgment.observe_all(ev, _ids(aware.seen))


## A8: the tag that names which player a fact's player id is, [] for a villager. MP Batch C (save 22): each player is judged under
## their own person id (World.person_id), and the tag stays, naming the same player (the talk reads either).
static func by_tag(w, actor: int) -> Array:
	return ["by:" + World.ref_of_id(actor)] if Life.is_player_id(actor) else []


## A villager slain by the player (World.kill): those who see the body fall.
static func on_killing(w, n: NPC, killer: int) -> void:
	var k = w.npc(killer) if killer >= 0 else null
	if k != null and k.job == "guard":
		w.judgment._stat("guard_killings_unjudged")  # X19-EVENT-Q (1): a guard stopping an attacker is not a killing
		return
	if w.judgment.struck_first(n.id, killer):
		w.judgment._stat("self_defence_killings")    # X19-EVENT-Q (4): the dead struck first in this same fight
		return
	var ev: int = w.judgment.publish("killing", [killer], [n.id], [], 0, by_tag(w, killer))
	if ev > 0:
		var seen: Array = w.near(n.pos, float(GameData.b("witness_radius")))
		seen.erase(n)
		w.judgment.observe_all(ev, _ids(seen))


## Publish one event whose participants are the named people; everyone awake near `at` (World.near within
## witness_radius, the one channel the world has for seeing) also saw it. Actors are not given a memory of their own
## deed (as for an attack); victims and beneficiaries are participants. Returns the event id (-1 when the catalog
## refuses it: unknown, or under its min_value).
static func _event(w, type: String, actors: Array, victims: Array, beneficiaries: Array, value := 0, at = null, tags := []) -> int:
	var ev: int = w.judgment.publish(type, actors, victims, beneficiaries, value, tags)
	if ev > 0:
		var seen := []
		if at != null:
			seen = _ids(w.near(at, float(GameData.b("witness_radius"))))
			for a in actors:
				seen.erase(int(a))
		w.judgment.observe_all(ev, seen)
	return ev


## A gift (Relations.give): the first of the day that earns the receiver's regard; a second the same day, or something
## that is no gift at all, is trivia and never reaches here. Seen by those near the receiver.
static func on_gift(w, giver: int, n: NPC, id: String) -> void:
	if GameData.value(id) < 1:
		return                                  # worth nothing: trivia (SJD-Q12)
	_event(w, "gift", [giver], [], [n.id], GameData.value(id), n.pos, ["item:" + id] + (["by:" + World.ref_of_id(giver)] if Life.is_player_id(giver) else []))   # A6: what was given, and by which player


## Help given: a quest done (help_minor), a relative's money toward a home (help_build). `helper` a person id.
static func on_help(w, helper: int, n: NPC, type: String, value: int) -> void:
	_event(w, type, [helper], [], [n.id], value, n.pos if type == "help_minor" else null)


## GM-01: a relative household's coins toward a home (Construction._family_help): the help_build deed as on_help publishes
## it, naming the household it helped (`hh`), the giving household (`giver_hh`), the plot the house stands on and its
## cost then; a significant gift (JudgmentStore.significant) becomes a historical record both households know of.
## Returns the event id.
static func on_build_help(w, giver: int, builder: NPC, value: int, giver_hh: int, hh: int, plot: String, cost: int) -> int:
	var ev := _event(w, "help_build", [giver], [], [builder.id], value, null)
	if ev <= 0:
		return ev
	var j: JudgmentStore = w.judgment
	j.set_refs(ev, {"household": hh, "giver_household": giver_hh, "plot": plot, "building": "", "item": "", "qty": value, "cost": cost,
			"links": [["contributed", "plot:" + plot]]})
	var present := [giver, builder.id]
	for h in [giver_hh, hh]:
		if h >= 0 and h < w.households.size():
			for m in w.households[h].members:
				var o: NPC = w.npc(int(m))
				if o != null and o.alive and not present.has(o.id):
					present.append(o.id)
	present.sort()
	j.make_history(ev, present)
	return ev


## GM-01: a building finished (World._finish_site): the help that went toward its plot now names it.
static func on_built(w, b: Dictionary) -> void:
	if str(b.get("parcel", "")) != "":
		w.judgment.building_done(str(b.parcel), str(b.id), w.day())


## A deal kept or broken between two people (ids; -1 for a party that is not a person: nothing is published). A contract
## fulfilled or a debt repaid on time is trade_fair, a contract lapsed or a debt defaulted is trade_cheat; `seller` is
## the one who owed the goods, work or coin. Private: only the two know.
static func on_deal(w, type: String, owed_by: int, owed_to: int, value: int, late := false) -> void:
	if owed_by == -1 or owed_to == -1 or owed_by == owed_to or value < 1:
		return                                  # not between two people, or under a coin: trivia (SJD-Q12)
	if type == "trade_fair":
		_event(w, type, [owed_by], [], [owed_to], value, null, ["late"] if late else [])    # X19-EVENT-Q (3): late = half the trust gain
		return
	else:
		_event(w, type, [owed_by], [owed_to], [], value)


## `who` (PlayerState or NPC) dug the trapped `ref` ("player" or "npc:<id>") out of a cave-in; digging yourself out is no rescue.
static func on_rescue(w, who, ref: String) -> void:
	var rescuer: int = w.person_id(who) if who is PlayerState else int(who.id)              # MP C6: that player's own id
	var saved: int = World.id_of_ref(ref) if World.is_player_ref(ref) else World.ref_id(ref)
	if saved == rescuer:
		return
	_event(w, "rescue", [rescuer], [], [saved])


## The player put down a bandit or a dangerous beast near villagers (Relations.defended): a rescue of those awake nearby,
## who all saw it. Nobody near, nothing to rescue.
static func on_defence(w, at: Vector2) -> void:
	var saved := []
	for n: NPC in w.near(at, float(GameData.b("witness_radius"))):
		if n.role != "bandit" and not w.asleep(n):
			saved.append(n.id)
	if saved.is_empty():
		return
	saved.sort()
	var ev: int = w.judgment.publish("rescue", [w.acting_id()], [], saved)     # MP C6: the player who defended them
	if ev > 0:
		w.judgment.observe_all(ev, saved)


## A pocket picked and nobody saw: a fact, but the victim only knows something is missing (not by whom) and nobody saw,
## so nobody learns it.
static func on_unseen_pickpocket(w, victim: NPC, value: int) -> void:
	w.judgment.publish("pickpocket", [w.acting_id()], [victim.id], [], value, by_tag(w, w.acting_id()))


## A bandit's robbery of a villager: a theft by an NPC, seen as the attack is (the same `aware`).
static func on_robbery(w, thief: NPC, victim: NPC, value: int, aware: Dictionary) -> void:
	var ev: int = w.judgment.publish("theft", [thief.id], [victim.id], [], value)
	if ev > 0:
		w.judgment.observe_all(ev, _ids(aware.seen))
	costly_mistake(w, victim.id, "travel_alone", float(value) / 10.0)      # coins lost out alone, with a guard post and a home to go to


## A costly mistake of a kind the game already measures (X19-PERS-FORMULA "practical wisdom"): a meal missed with food
## within reach, coins lost, a purchase refused, an injury, while a better recorded alternative existed. `cost` is in points
## (a point is 1000 milli-points); at most one of a kind a person a day. Wisdom only grows, and reduces how much
## stubbornness weighs in a choice (JudgmentWeighting).
static func costly_mistake(w, person: int, kind: String, cost: float) -> void:
	var j: JudgmentStore = w.judgment
	if j == null or not j.pers.active or person < 0:
		return
	var nm: int = j.now_minute()
	if j.pers.recent(person, JudgmentPersonality.CH_MISTAKE, JudgmentPersonality.kind_code(kind), nm / 1440, 1) > 0:
		return
	j.pers.mistake(person, kind, clampi(roundi(cost * 1000.0), 500, 5000), nm / 1440)
	j._stat("mistakes")


## A villager starves (hunger at 0) although food or the coins to buy it were to hand: a missed meal.
static func on_hungry(w, n: NPC) -> void:
	if w.judgment == null or not w.judgment.pers.active:
		return
	var food := n.coins >= 5
	if not food and n.household >= 0:
		food = NPCBrain.store_points([w.households[n.household].pantry]) > 0.0
	if food:
		costly_mistake(w, n.id, "family_meal", 1.0)


## A new adult (Life._set_role): their parents will tell them the family stories when they are at home together.
static func on_come_of_age(w, n: NPC) -> void:
	w.judgment.story_pending[n.id] = [w.day(), 0]


## Hourly (World._on_hour): the family stories of new adults, told at home by each parent who is there with them
## (X19-STORY-LIFE). A new adult whose parents never meet them at home within family_story.expire_days goes without.
static func tell_family_tick(w) -> void:
	var j: JudgmentStore = w.judgment
	if j.story_pending.is_empty():
		return
	var ids := j.story_pending.keys()
	ids.sort()
	for id in ids:
		var rec: Array = j.story_pending[id]
		var c: NPC = w.npc(int(id))
		if c == null or not c.alive or w.day() - int(rec[0]) > j._story_days:
			j.story_pending.erase(id)
			continue
		var mask := int(rec[1])
		for i in 2:
			var pid: int = c.mother if i == 0 else c.father
			if (mask >> i) & 1 == 1:
				continue
			var p: NPC = w.npc(pid) if pid >= 0 else null
			if p == null or not p.alive:
				mask |= 1 << i                        # no parent here to tell them
			elif c.home != "" and w.place_of(c.pos) == c.home and w.place_of(p.pos) == c.home:
				j.tell_family_stories(p.id, c.id)
				j.tell_family_history(p.id, c.id)       # GM-01: and the family's history (knowledge only: nothing is judged)
				mask |= 1 << i
		if mask == 3:
			j.story_pending.erase(id)
		else:
			rec[1] = mask


## GP-DIALOGUE A5 (REPAIR_AUDIT D2): village news as a NEUTRAL fact (judgment.json family "news": known and told, never
## judged), published where the village already records it. `ref` is the party that did it ("hh:<i>" a household, its
## first adult as the actor; "npc:<id>" a villager; a player reference; "" none: the manor or the chapel). Who knows:
## the actor, and for a household's affair (HOUSEHOLD_NEWS, or a villager's own) its members, as participants; anyone
## awake near `at` (World.near, witness_radius) as witnesses; everyone else only by word of mouth. Tags carry what the
## telling needs: "hh:<i>", "by:<player ref>", "place:<id>", "price:<n>", "rent:<n>", "item:<id>", "giver:<manor|chapel>".
const HOUSEHOLD_NEWS := ["land_bought", "land_leased", "fenced", "relief"]


static func on_news(w, type: String, ref: String, tags: Array, at = null) -> int:
	if w == null or w.judgment == null:
		return -1
	var actors := []
	var t := tags.duplicate()
	var hh := -1
	if World.is_player_ref(ref):
		actors = [World.id_of_ref(ref) if World.id_of_ref(ref) != -1 else Life.PLAYER_ID]     # MP C6: that player's own id
		t.append("by:" + ref)
	elif ref.begins_with("hh:"):
		hh = World.ref_id(ref)
		var a: NPC = w.party(ref)
		if a != null:
			actors = [a.id]
	elif ref.begins_with("npc:"):
		var o: NPC = w.npc(World.ref_id(ref))
		if o != null:
			actors = [o.id]
			hh = o.household
	elif ref.begins_with("hhid:"):
		hh = int(ref.get_slice(":", 1))
	if hh >= 0:
		t.append("hh:%d" % hh)
	var members := []
	if hh >= 0 and hh < w.households.size():
		for m in w.households[hh].members:
			var o: NPC = w.npc(int(m))
			if o != null and o.alive:
				members.append(o.id)
	var benef: Array = members if type in HOUSEHOLD_NEWS else []
	var ev: int = w.judgment.publish(type, actors, [], benef, 0, t)
	if ev > 0:
		var seen := _ids(w.near(at, float(GameData.b("witness_radius")))) if at != null else []
		for a in actors:
			if int(a) >= 0:
				w.judgment.observe(ev, int(a), "participant")
		for m in members:
			w.judgment.observe(ev, int(m), "participant")
		seen.sort()
		for o in seen:
			w.judgment.observe(ev, int(o), "witnessed")
	return ev


## Where party `ref` stands (a villager, a household's first adult, a player), for who sees what they do; null for none.
static func at_of(w, ref: String):
	if World.is_player_ref(ref):
		var p: PlayerState = w.player_of_ref(ref)
		return p.pos if p != null else null
	var o: NPC = w.party(ref)
	return o.pos if o != null else null


## A5 (REPAIR_AUDIT D2): a death, as news. Its household and close family (Life's graph: parents, partner, children) know
## of it as participants, those near the body as witnesses. It names the kind of death ("cause:slain", "starvation",
## "old_age", "other"), never who did it: a killer is known only from the killing itself, seen or told.
static func on_death(w, n: NPC, kind: String) -> int:
	if w == null or w.judgment == null or n.role == "bandit":
		return -1
	if w.judgment.asp.enabled:
		for pid in [n.mother, n.father, n.partner] + n.children:
			w.judgment.asp.on_loss(w, int(pid))        # R5: the loss of a partner, child or parent is a family setback, met by personality
	var t := ["cause:" + kind]
	if n.household >= 0:
		t.append("hh:%d" % n.household)
	var ev: int = w.judgment.publish("death", [], [n.id], [], 0, t)
	if ev <= 0:
		return ev
	var know := {}
	if n.household >= 0:
		for m in w.households[n.household].members:
			know[int(m)] = "participant"
	for pid in [n.mother, n.father, n.partner] + n.children:
		if int(pid) >= 0:
			know[int(pid)] = "participant"
	for o in _ids(w.near(n.pos, float(GameData.b("witness_radius")))):
		if not know.has(o):
			know[o] = "witnessed"
	var ids := know.keys()
	ids.sort()
	for id in ids:
		var o: NPC = w.npc(int(id))
		if o != null and o.alive and o != n:
			w.judgment.observe(ev, int(id), str(know[id]))
	return ev


## A partnership made (Relations.propose accepted, the player's included): a neutral fact for the two of them.
static func on_marriage(w, a: int, b: int) -> void:
	if w.judgment.asp.enabled:
		w.judgment.asp.on_marriage(w, a)                 # R5: property gains priority (villagers only; a player has no aspirations)
		w.judgment.asp.on_marriage(w, b)
	var ev: int = w.judgment.publish("marriage", [a, b])
	if ev > 0:
		w.judgment.observe_all(ev, [a, b])


## SJD-H C1: with tiers, "the other candidates" are those of later tiers (each at least one live_order step below); the
## callers handle the first's own tier.
## Round 2 (cost): whether the live rule's first pick must win whatever the other candidates are, so the full scan can
## be skipped with the same result. True only when live_order, necessity and disposition are the only weights (necessity
## is the same for every candidate): another candidate can win only by a disposition advantage worth more than
## live_order's step, and no other can have a disposition above the best the seller holds of anyone in their ledger (or
## 50, for someone they have no opinion of), plus the most the family name can colour it.
## SJD-G (2026-10-30): also under the shipped "margin" selection (SJD-Q09): there the first stands when no other can come
## within the margin of it (step - gain > margin), so the seeded near-best pick has nobody to pick (JudgmentWeighting
## _choose: the runner-up is drawn only from those within the margin). The full scan was 60% of a judgment-on day's
## simulation time, because under "margin" the shortcut never applied. Also, the first's disposition is now computed as
## the choice computes it (the personal disposition clamped, then the colour, clamped again), not as one clamp of the sum,
## which overstated it when a NET beyond +-50 points met a colour; and the aspiration layer (which adds factors and scales
## weights) and a recording run (whose archive keeps every weighed choice in full) always take the full scan.
static func _first_stands(j: JudgmentStore, seller: int, first: int, profile := "trade_sell") -> bool:
	var dc: Dictionary = j.cfg.decision
	var wt: Dictionary = dc.profiles[profile].weights
	var sel := str(dc.selection)
	if sel != "argmax" and sel != "margin":
		return false
	if j.rec != null or (j.asp != null and j.asp.enabled):
		return false
	if j.pers.active and (j.pers.holds_stubbornness(seller) or j.pers.overriding(seller, j.now_minute() / 1440, j.now_minute() % 1440)):
		return false                            # a stubborn chooser's penalties can move the choice
	for k in wt:
		if not (str(k) in ["live_order", "necessity", "disposition"]) and int(wt[k]) != 0:
			return false
	var wd := JudgmentWeighting.trait_weight(j.cfg, j.world_seed, seller, "disposition", int(wt.get("disposition", 0)), j)   # this seller's own weights (Q03/Q13)
	var wo := JudgmentWeighting.trait_weight(j.cfg, j.world_seed, seller, "live_order", int(wt.get("live_order", 0)), j)
	j._cu_read(seller)                          # the whole ledger is read below
	var d0 := int(JudgmentWeighting.opinion(j, j.cfg, profile, seller, first, true)[0])   # as JudgmentWeighting._choose computes it (C1 gain)
	var mid := int(dc.disposition_mid)
	var best_pd := mid
	for s in j.subjects(seller):
		if int(s) != first:
			best_pd = maxi(best_pd, j.personal_disposition(seller, int(s)))
	var g := JudgmentWeighting.gain(j.cfg, profile)
	var best := JudgmentMath.clampi_(mid + JudgmentMath.mul_div(best_pd - mid, g, 1000), 0, 100000)
	best = mini(100000, best + JudgmentMath.mul_div(j.colour_bound(seller), g, 1000))    # a stranger's family name can colour them up to this much
	var gain := JudgmentMath.mul_div(wd, best, 1000) - JudgmentMath.mul_div(wd, d0, 1000)
	var step := JudgmentMath.mul_div(wo, 100000, 1000) - JudgmentMath.mul_div(wo, 100000 - LIVE_ORDER_STEP, 1000)
	if sel == "margin":
		return gain < step - int(dc.margin)       # nobody else within the margin of the first: no near-best to draw
	return gain <= step


## Prototype of the first live domain: whom villager `n` sells `id` to. The candidates are exactly the live rule's
## (OUTLETS order, NPCBrain buy roles, World.purchase_qty, the one rule for every sale); judgment weighs among them
## with the live order of preference (live_order), the seller's need for coin and the price each would pay (trade_sell
## profile; price weighs 0 until calibrated), so with every judgment neutral the live choice stands and any change is
## judgment's. Returns the buyer or null.
static func pick_buyer(w, brain, n: NPC, id: String) -> NPC:
	var t := Time.get_ticks_usec()
	var b := _pick_buyer(w, brain, n, id)
	var tm: Dictionary = w.judgment.timing
	tm.trade_us = int(tm.get("trade_us", 0)) + Time.get_ticks_usec() - t
	return b


## SJD-H C1: the buyers of one trade (one OUTLETS role) are one tier: the live rule takes the first of them in villager order,
## which says nothing about them, so judgment chooses among them; the live order steps between trades. When no buyer of a
## later trade can come within the margin of the first (_first_stands), only the first's own trade is weighed: the same
## pick as the full scan (the others could not be drawn), at the cost of a few buyers.
static func _pick_buyer(w, brain, n: NPC, id: String) -> NPC:
	var first: NPC = null                     # the live rule's own pick: the first who can buy, in OUTLETS order
	var first_outlet := -1
	var outlets: Array = NPCBrain.OUTLETS.get(id, [])
	for oi in outlets.size():
		for b in brain._with_buy_role(outlets[oi]):
			if b != n and b.alive and w.purchase_qty(b, n, id, maxi(1, n.inv.count(id))) > 0:
				first = b
				first_outlet = oi
				break
		if first != null:
			break
	if first == null:
		return null
	var only_own := shortcut and _first_stands(w.judgment, n.id, first.id, "trade_sell")
	var cands := []
	var people := {}
	var top := 1
	var tier := -1
	for oi in range(first_outlet, outlets.size()):
		var in_tier := false
		for b in brain._with_buy_role(outlets[oi]):
			if b == n or not b.alive or people.has(b.id):
				continue
			var q: int = w.purchase_qty(b, n, id, maxi(1, n.inv.count(id)))
			if q <= 0:
				continue
			if not in_tier:
				in_tier = true
				tier += 1
			var unit := int(w.sale_prices(b, n, id, 1)[0])
			top = maxi(top, unit)
			people[b.id] = b
			cands.append({"id": b.id, "counterparty": b.id, "unit": unit, "tier": tier})
		if only_own:
			break                                 # later trades cannot come within the margin: the first's own trade decides
	if only_own:
		w.judgment._stat("trade_shortcut")        # the later trades were not scanned
	if cands.size() == 1:
		w.judgment._stat("trade_choices")
		return first
	var need := JudgmentMath.clampi_((50 - n.coins) * 2000, 0, 100000)      # under 50 coins a seller needs the sale more
	for i in cands.size():
		var c: Dictionary = cands[i]
		c.factors = {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * int(c.tier)), "necessity": need, "price": JudgmentMath.mul_div(int(c.unit), 100000, top)}
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "trade_sell", cands, [w.day(), id.hash()])
	w.judgment._stat("trade_choices")
	if r.chosen == null or not people.has(r.chosen):
		return null
	if int(r.chosen) != int(cands[0].id):
		w.judgment._stat("trade_choices_changed")         # judgment moved the choice from the live rule's first pick
	return people[r.chosen]



# ---------------------------------------------------------------- Q14: the other existing decision points ------------
## Among `people` (in the live rule's own order of preference), the one `chooser` picks under `profile`: the live order
## and the chooser's judgment of each (plus any `extra` factors per person id). With every judgment neutral the live
## rule's first stands. null when `people` is empty.
## SJD-H C1: `tiers` (one per person, non-decreasing: the live rule's groups, e.g. its trades) make those of one tier equal in
## live order, so judgment chooses among comparable people; without tiers each person is a step below the one before.
static func _pick(w, chooser: int, people: Array, profile: String, key: Array, extra := {}, tiers := []) -> NPC:
	if people.is_empty():
		return null
	var peers: bool = not tiers.is_empty() and people.size() > 1 and tiers[1] == tiers[0]
	if extra.is_empty() and not peers and shortcut and _first_stands(w.judgment, chooser, people[0].id, profile):
		w.judgment._stat(profile + "_choices")
		return people[0]
	var cands := []
	var rank := 0
	for i in people.size():
		var o: NPC = people[i]
		if not tiers.is_empty() and i > 0 and tiers[i] != tiers[i - 1]:
			rank += 1
		var f := {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * (rank if not tiers.is_empty() else i))}
		for k in extra.get(o.id, {}):
			f[k] = extra[o.id][k]
		var cand := {"id": o.id, "counterparty": o.id, "factors": f}
		if not tiers.is_empty():
			cand.tier = rank
		cands.append(cand)
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, chooser, profile, cands, key)
	w.judgment._stat(profile + "_choices")
	for o in people:
		if r.chosen != null and o.id == int(r.chosen):
			if o != people[0]:
				w.judgment._stat(profile + "_changed")
			return o
	return people[0]


## trade_buy_from (NPCBrain._seller_of): whom household member `buyer` buys `id` from. The candidates are the live
## rule's, in its order: carpenters and raw-goods merchants with stock, then (for logs) woodcutters with logs.
static func pick_seller(w, brain, id: String, buyer: NPC) -> NPC:
	var people := []
	var tiers := []
	for o: NPC in w.npcs:
		if o.alive and o != buyer and not w.asleep(o) and (o.job == "carpenter" or brain.buy_role(o) == "merchant_raw") and o.inv.has(id):
			people.append(o)
			tiers.append(0)                       # C1: the carpenters and raw-goods merchants, in villager order: comparable
	if id == "log":
		for o: NPC in w.npcs:
			if o.alive and o != buyer and not w.asleep(o) and o.job == "woodcutter" and o.inv.has(id):
				people.append(o)
				tiers.append(1)                   # the woodcutters only after them, as the live rule has it
	return _pick(w, buyer.id, people, "trade_buy_from", [w.day(), id.hash()], {}, tiers)


## trade_buy_from among sellers the live rule takes in villager order with nothing to tell them apart (SJD-H C1: the iron-bar
## seller, NPCBrain._bar_seller; the seed merchant, NPCBrain._plan_buy_seed): one tier, so the buyer's opinion and trust
## decide, and the live rule's first stands while they are neutral. `key` names the goods. null when `people` is empty.
static func pick_comparable(w, buyer: NPC, people: Array, profile: String, key: Array) -> NPC:
	if people.size() < 2:
		return people[0] if not people.is_empty() else null
	var tiers := []
	tiers.resize(people.size())
	tiers.fill(0)
	return _pick(w, buyer.id, people, profile, [w.day()] + key, {}, tiers)


## hire_choice (Construction._keep_building): whom household `h` hires to carry for its house. The candidates are the
## live rule's (hirable, of another household, in villager order) who would take the work (work_refusal); the choice
## is the household's responsible adult's.
static func pick_helper(w, h: int, wage: int) -> NPC:
	var boss: NPC = w.construction.responsible_adult(h)
	var people := []
	for o: NPC in w.npcs:
		if o.household != h and w.construction.can_hire(o) == "":
			if boss == null or work_refusal(w, o, boss.id, wage) == "":
				people.append(o)
	if boss == null:
		return people[0] if not people.is_empty() else null
	var tiers := []
	tiers.resize(people.size())
	tiers.fill(0)                                 # C1: every hirable villager is the live rule's equal (villager order)
	return _pick(w, boss.id, people, "hire_choice", [w.day(), h], {}, tiers)


## work_accept (Construction.hire, Business.hire): why `worker` turns down work for `employer` (a person id: the player
## -2, or a household's responsible adult), or "": they weigh their need for coin (under 50 coins), the wage, and what
## they think of the employer against doing without (work_accept profile). With a neutral judgment they always accept
## (the live rule); a strong dislike can make someone with enough coin refuse; need outweighs dislike.
static func work_refusal(w, worker: NPC, employer: int, wage: int, favour := false) -> String:
	if not on(w, "work_accept") or worker == null or employer == worker.id:
		return ""
	var need := JudgmentMath.clampi_((50 - worker.coins) * 2000, 0, 100000)
	var cand := {"id": "accept", "counterparty": employer, "factors": {"necessity": need, "wage": 100000 if wage > 0 or favour else 0}}
	if wage <= 0:
		cand.serves = {"food": 0, "wealth": 0}            # R5: unpaid work feeds no one and earns nothing (read only with aspirations on)
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, worker.id, "work_accept", [cand], [w.day(), employer])
	w.judgment._stat("work_offers")
	if str(r.chosen) == "accept":
		return ""
	w.judgment._stat("work_refused")
	return "%s would rather not work for %s." % [worker.name, "you" if Life.is_player_id(employer) else "them"]


## befriend (Relations._befriend_if_close): whether two villagers whose regard has reached befriend_at become friends:
## closeness (regard) weighed with what each thinks of the other (the lower of the two). With neutral judgments they
## always do (the live rule); a dislike can hold back a friendship that is only just close enough; great closeness
## outweighs it. Positive judgment never makes friends of people not close enough (the live threshold stands).
static func befriend_ok(w, a: int, b: int, regard: float) -> bool:
	if not on(w, "befriend"):
		return true
	var j: JudgmentStore = w.judgment
	var disp := mini(int(JudgmentWeighting.opinion(j, j.cfg, "befriend", a, b)[0]), int(JudgmentWeighting.opinion(j, j.cfg, "befriend", b, a)[0]))   # C1: read with the opinion gain
	var at := float(Relations.cfg().befriend_at)
	var wt: Dictionary = j.cfg.decision.profiles.befriend.weights
	var u := JudgmentMath.mul_div(int(wt.closeness), roundi(clampf(regard, 0.0, 100.0) * 1000.0), 1000) + JudgmentMath.mul_div(int(wt.disposition), disp, 1000)
	var bar := JudgmentMath.mul_div(int(wt.closeness), roundi(at * 1000.0), 1000) + JudgmentMath.mul_div(int(wt.disposition), int(j.cfg.decision.disposition_mid), 1000)
	j._stat("befriend_checks")
	if u >= bar:
		return true
	j._stat("befriend_held_back")
	return false


## court_choice (Relations._villagers_court): whom single villager `n` takes an interest in, among the live rule's
## candidates (those they may court and have come to know, attraction at least interest_at), in its order: attraction
## weighed with what `n` thinks of each. With neutral judgments the most attractive (the first of equals) stands.
static func pick_court(w, n: NPC, people: Array, attraction: Dictionary) -> NPC:
	if people.is_empty():
		return null
	var cands := []
	for o: NPC in people:
		var f := {"attraction": roundi(clampf(float(attraction[o.id]), 0.0, 100.0) * 1000.0)}
		if aspiring(w):
			f.merge(court_factors(w, n, o))                # R5 (FAD Q3): what else this villager values in a partner, weighed by their own priorities
		cands.append({"id": o.id, "counterparty": o.id, "factors": f})
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "court_choice", cands, [w.day(), n.id])
	w.judgment._stat("court_choices")
	for o: NPC in people:
		if r.chosen != null and o.id == int(r.chosen):
			return o
	return people[0]


# ---------------------------------------------------------------- Q14 stage 2: promises, credit, family help --------
## The person id of a contract party: the player, a villager, or a household's responsible adult; -1 for the manor and
## anyone judgment has no opinion of (an institution has no personal judgment).
static func person_of_ref(w, ref: String) -> int:
	if World.is_player_ref(ref):
		return World.id_of_ref(ref) if World.id_of_ref(ref) != -1 else Life.PLAYER_ID      # MP C3: each player their own
	if ref.begins_with("npc:"):
		return World.ref_id(ref)
	if ref.begins_with("hh:"):
		var boss: NPC = w.construction.responsible_adult(World.ref_id(ref))
		return boss.id if boss != null else -1
	return -1


## Whether `chooser` is willing to do a favour or a service for `counterparty` (a person id) under `profile`: the live
## rule said yes (live_order 100 points), weighed with the chooser's need for coin (`need`, when the profile weighs it)
## and what they think of the other, against doing without (the profile's forgo). With neutral judgment the live yes
## stands; a strong dislike can make someone who can spare it refuse; need outweighs dislike. Feasibility is the caller's.
## An unknown counterparty (the manor) is not judged.
static func willing(w, profile: String, chooser: NPC, counterparty: int, key: Array, need := 0) -> bool:
	if counterparty == -1 or counterparty == chooser.id:
		return true
	var j: JudgmentStore = w.judgment
	var r := JudgmentWeighting.choose(j, j.cfg, chooser.id, profile,
			[{"id": "yes", "counterparty": counterparty, "factors": {"live_order": 100000, "necessity": need}}], key)
	j._stat(profile + "_asked")
	if str(r.chosen) == "yes":
		return true
	j._stat(profile + "_declined")
	costly_mistake(w, counterparty, profile, 0.5)                          # a purchase or favour refused: a costly mistake of dealing
	return false


## A villager's need for coin as the work and sale hooks read it: rising under 50 coins.
static func coin_need(n: NPC) -> int:
	return JudgmentMath.clampi_((50 - n.coins) * 2000, 0, 100000)


## contract_accept (Contracts.evaluate): why villager `n` will not take the offer of `buyer_ref`, or "". The caller has
## found the offer feasible; this only adds the seller's own reluctance.
static func contract_refusal(w, n: NPC, buyer_ref: String) -> String:
	var who := person_of_ref(w, buyer_ref)
	if willing(w, "contract_accept", n, who, [w.day(), who], coin_need(n)):
		return ""
	return "I'd rather not take work from you." if Life.is_player_id(who) else "I'd rather not deal with them."


## contract_seller: of the sellers `people` (the live rule's order), the one villager buyer `b` asks first (the rest keep
## the live order after it, so a refusal or an infeasible seller changes nothing). Returns the sellers in the order to ask.
static func seller_order(w, b: NPC, people: Array, key: Array) -> Array:
	if people.size() < 2:
		return people
	var tiers := []
	tiers.resize(people.size())
	tiers.fill(0)                                 # C1: the live rule asks in villager order: every seller its equal
	var first := _pick(w, b.id, people, "contract_seller", key, {}, tiers)
	if first == null or first == people[0]:
		return people
	var out := [first]
	for o in people:
		if o != first:
			out.append(o)
	return out


## credit_lend (Credit.credit_refusal): why villager `seller` will not sell `buyer` on credit although the rule allows it.
static func lend_refusal(w, seller: NPC, buyer) -> String:
	var who: int = w.id_of_party(buyer)
	if willing(w, "credit_lend", seller, who, [w.day(), who], coin_need(seller)):
		return ""
	return "%s would rather not lend to you." % seller.name if Life.is_player_id(who) else "%s would rather not lend to %s." % [seller.name, buyer.name]


## barter_accept (Credit.barter_quote): whether villager `seller` takes the swap with `buyer` that is otherwise sound.
static func barter_ok(w, seller: NPC, buyer) -> bool:
	var who: int = w.id_of_party(buyer)
	return willing(w, "barter_accept", seller, who, [w.day(), who], coin_need(seller))


## food_seller (Credit._cheapest_food): among the neighbours with food to spare, `cands` [{seller, id, per}] in the live
## rule's order (cheapest per food point first, a villager before the player on a tie), the one a short household's
## member asks. The cheapest stands unless judgment moves it. Returns the entry.
static func pick_food_seller(w, buyer: NPC, cands: Array) -> Dictionary:
	var cs := []
	var rank := 0
	for i in cands.size():
		var s = cands[i].seller
		if i > 0 and float(cands[i].per) != float(cands[i - 1].per):
			rank += 1                             # C1: neighbours asking the same price per food point are comparable
		cs.append({"id": i, "counterparty": w.id_of_party(s), "tier": rank, "factors": {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * rank)}})
	var j: JudgmentStore = w.judgment
	var r := JudgmentWeighting.choose(j, j.cfg, buyer.id, "food_seller", cs, [w.day(), buyer.household])
	j._stat("food_seller_choices")
	if r.chosen == null:
		return cands[0]
	if int(r.chosen) != 0:
		j._stat("food_seller_changed")
	return cands[int(r.chosen)]


## tool_buy (SJD-H C5; NPCBrain._buy_tool, _fetch_dress_tool): which seller of `tool` villager `n` buys from, or whether they put
## it off. `cands` are the live rule's feasible sellers in its own order, [{seller: NPC, tier, price}] (tier: the live rule's
## group, e.g. its trade; price: the bargained price buy_qty pays); `necessity` 0..100000 (100 points for the tool of their
## trade). The live rule's first costs nothing; a seller of a later tier costs `later`, a dearer one `dearer`; the buyer's
## opinion, trust, fear, loyalty and ambivalence (JudgmentWeighting fill) and the seller's skill (respect) compete with them and
## with the need (necessity, sole_source) against putting it off (the profile's forgo). Returns {seller: NPC or null, forgo}.
static func pick_tool_seller(w, n: NPC, tool: String, cands: Array, necessity: int) -> Dictionary:
	var j: JudgmentStore = w.judgment
	if cands.is_empty():
		return {"seller": null, "forgo": false}
	var p0 := maxi(1, int(cands[0].price))
	var cs := []
	var rank := 0
	for i in cands.size():
		var c: Dictionary = cands[i]
		if i > 0 and int(c.tier) != int(cands[i - 1].tier):
			rank += 1
		var o: NPC = c.seller
		var dearer := clampi((int(c.price) - p0) * 100000 / p0, 0, 100000)
		cs.append({"id": i, "counterparty": o.id, "tier": rank, "factors": {"later": 10000 * rank, "dearer": dearer, "necessity": necessity, "respect": respect(o)}})
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "tool_buy", cs, [w.day(), tool.hash()])
	j._stat("tool_buy_choices")
	if str(r.chosen) == "forgo":
		j._stat("tool_buy_forgone")
		return {"seller": null, "forgo": true}
	if r.chosen == null:
		return {"seller": null, "forgo": false}
	if int(r.chosen) != 0:
		j._stat("tool_buy_changed")
	return {"seller": cands[int(r.chosen)].seller, "forgo": false}


## Respect for ability (C5): the best level `o` holds in the skills of their trade (Skills job_skills), 0..100000.
static func respect(o: NPC) -> int:
	var best := 0
	for sk in (Skills.cfg().get("job_skills", {}) as Dictionary).get(o.job, []):
		best = maxi(best, Skills.level(o, str(sk)))
	return clampi(best * 100000 / maxi(1, Skills.max_level()), 0, 100000)


## family_help (Construction._family_help): whether the responsible adult of a relative household `giver` gives toward
## `builder`'s home. The amount and the means are the live rule's.
static func family_gives(w, giver: NPC, builder: NPC) -> bool:
	return willing(w, "family_help", giver, builder.id, [w.day(), builder.id])


# ---------------------------------------------------------------- SJD-F crime: whether to report (R2) ---------------
## report (World.report_crime): whether villager `n`, who knows of `offender`'s crime (`how`: "saw", "victim" or
## "sighting"; `crime`: "attack" or "theft"), tells a guard or keeps quiet. Both options are feasible (who may report
## and how a report travels stay the live rule's); the choice between them is weighed by the one shared interface,
## never decided by a cutoff (owner, 2026-10-26: judgment influences, never dictates). Telling: the live rule's yes
## (live_order) and the harm done. Keeping quiet: what `n` thinks of the offender (disposition, the family name's colour
## included), kinship with them, and fear of them (the violence `n` holds against them). Each person weighs these by
## their own personality (trait_spread, life shift, stubbornness), so two witnesses of the same crime may decide
## differently. Every choice is recorded by the flight recorder when one is attached (JudgmentWeighting.choose).
static func will_report(w, n: NPC, offender: int, how: String, crime: String) -> bool:
	var j: JudgmentStore = w.judgment
	if offender == n.id:
		return true
	var rc: Dictionary = j.cfg.decision.get("report", {})
	var harm := int(rc.get("harm_victim", 0)) if how == "victim" else int(rc.get("harm_attack" if crime == "attack" else "harm_theft", 0))
	var kin := 100000 if j.social != null and j.social.kin(n.id, offender) else 0
	var fear := JudgmentMath.clampi_(JudgmentMath.mul_div(int(j.ledger(n.id, offender)[6]), int(rc.get("fear_permille_per_point", 0)), 1000), 0, 100000)
	var cands := [
		{"id": "report", "counterparty": -1, "factors": {"live_order": 100000, "harm": harm, "disposition": 0, "kinship": 0, "fear": 0}},
		{"id": "silent", "counterparty": offender, "factors": {"live_order": 0, "harm": 0, "kinship": kin, "fear": fear}},
	]
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "report", cands, [w.day(), offender, how.hash(), crime.hash()])
	j._stat("report_choices")
	if str(r.chosen) == "silent":
		j._stat("report_kept_quiet")
		return false
	return true


# ---------------------------------------------------------------- R5 aspirations (WDR-011-C) -----------------------
## court_choice (FAD Q3): the courting factors of candidate `x` for chooser `n`, each from real state, 0..100000. Their
## weights (judgment.json aspiration.court) are scaled by n's own effective priority of a domain in JudgmentWeighting, so
## one villager weighs security, another wealth, another the bond they already have. Nothing gates: a poor candidate is
## weighed, never removed. Kinship, age, existing partners and consent stay the live rules' (Relations.can_court and the
## pool, villagers only: no NPC ever chooses a player). No ledger entry counts twice: disposition is n's own opinion of x,
## family_compat n's opinions of x's parents and siblings, standing everyone else's personal opinion of x.
## `x` is a villager, or a player (PROP-EQ, WDR-012, D39 follow-up: a player's proposal is weighed by the same factors, read
## in the player's own form: the player's household is Guardianship.player_household (a couple household; none for a
## single player, read as a villager without a household is), the wealth the player's purse, no trade (the game records
## none for a player), the parents and siblings by the player's own mother and father, standing by their person id).
static func court_factors(w, n: NPC, x) -> Dictionary:
	var j: JudgmentStore = w.judgment
	var a: JudgmentAspiration = j.asp
	var cc: Dictionary = a.c.get("court", {})
	var mid := int(j.cfg.decision.disposition_mid)
	var pl: bool = x is PlayerState
	var xid: int = w.person_id(x) if pl else x.id
	var xh: int = Guardianship.player_household(w, x) if pl else x.household
	var xjob: String = "" if pl else x.job
	var tt: Dictionary = w.relations.peek(n.id, xid)
	var bond := roundi(clampf(float(tt.regard), 0.0, 100.0) * float(int(cc.get("bond_regard_permille", 700)))) \
			+ mini(int(tt.days_known), int(cc.get("bond_days_full", 16))) * (100000 - 100 * int(cc.get("bond_regard_permille", 700))) / maxi(1, int(cc.get("bond_days_full", 16)))
	var econ: Dictionary = w.households[xh].get("econ", {}) if xh >= 0 else {}
	var savings := maxf(1.0, float(GameData.b("household_savings_days")))
	var security := 0
	if not econ.is_empty():
		security = (50000 if bool(econ.sustainable) else 0) + roundi(minf(float(econ.days) / savings, 1.0) * 50000.0)
	var wx: int = w.property.purse(World.hh_ref(xh)) if xh >= 0 else int(x.coins)
	var wn: int = w.property.purse(World.hh_ref(n.household)) if n.household >= 0 else n.coins
	var wealth := 50000 if wx + wn <= 0 else JudgmentMath.mul_div(maxi(0, wx), 100000, maxi(1, wx + wn))
	var prop := int(a.rows[xid].sat[JudgmentAspiration.PROPERTY]) if a.rows.has(xid) else 0
	var streak := int(econ.get("streak", 0)) if not econ.is_empty() else 0
	var stability := maxi(0, 50000 - streak * int(cc.get("stability_streak_step", 20000)))
	if xjob != "":
		stability += clampi((w.day() - int(x.job_since)) * 50000 / maxi(1, a.n_("profession_tenure_full", 16)), 0, 50000)
	# family compatibility: n's own personal opinions of x's parents and siblings (x excluded: that is disposition)
	var rel := []
	for pid in [x.mother, x.father]:
		if int(pid) >= 0:
			rel.append(int(pid))
			var p: NPC = w.npc(int(pid))
			if p != null:
				for cid in p.children:
					if int(cid) != xid and not rel.has(int(cid)):
						rel.append(int(cid))
	rel.sort()
	var fsum := 0
	var fcnt := 0
	for r in rel:
		if r != n.id and j.ledgers.has(n.id) and JudgmentStore._lfind(j.ledgers[n.id], int(r)) >= 0:
			fsum += j.personal_disposition(n.id, int(r))
			fcnt += 1
	var compat := fsum / fcnt if fcnt > 0 else mid
	var ln := int(a.rows[n.id].lead) if a.rows.has(n.id) else -1
	var lx := int(a.rows[xid].lead) if a.rows.has(xid) else -1
	var shared := 100000 if ln >= 0 and ln == lx else (50000 if ln < 0 or lx < 0 else 0)
	return {"bond": clampi(bond, 0, 100000), "security": clampi(security, 0, 100000), "wealth": wealth, "property": prop,
		"stability": clampi(stability, 0, 100000), "family_compat": clampi(compat, 0, 100000), "shared_ambition": shared,
		"standing": a.standing_excluding(xid, n.id)}


## job_choice (FAD Q2; NPCBrain.seek_work with decision.integration.job_choice and aspiration.enabled on): which of the open
## jobs the live search found feasible (`opts` [[job, live score], ...] in the live list's order) villager `n` takes, or ""
## to stay in the job they have. Who looks for work, what is open and affordable, and that skilled trades need training
## stay the live rule's; this only weighs among those options: the live rule's own preference (live_order), the pay
## (wage), the pay gain as hardship magnifies it (need_wage: coin need and the household's unsustainable days), skill and
## room to improve (both scaled by the person's own profession priority, which survival pressure lowers), tenure and career
## satisfaction for staying. With equal career factors the live answer stands. `live_best` is the live rule's best option,
## `live_switch` whether the live rule would take it. No occupation is preferred by a fixed rule.
static func pick_job(w, n: NPC, opts: Array, unemployed: bool, current: float, live_best: String, live_switch: bool, econ: Dictionary) -> String:
	var j: JudgmentStore = w.judgment
	var a: JudgmentAspiration = j.asp
	var jc: Dictionary = a.c.get("job", {})
	var order := []
	var rest := opts.duplicate()
	rest.sort_custom(func(x, y) -> bool: return float(x[1]) > float(y[1]))
	var best_entry = null
	for o in rest:
		if str(o[0]) == live_best:
			best_entry = o
	if best_entry != null:
		rest.erase(best_entry)
	if live_switch or unemployed:
		if best_entry != null:
			order.append(best_entry)
		if not unemployed:
			order.append(["", current])
	else:
		order.append(["", current])
		if best_entry != null:
			order.append(best_entry)
	order.append_array(rest)
	var top := maxf(0.001, current)
	for o in order:
		top = maxf(top, float(o[1]))
	var hardship := maxi(coin_need(n), mini(100000, int(econ.get("streak", 0)) * int(jc.get("hardship_per_streak_day", 20000))))
	var full := maxi(1, int(jc.get("need_gain_full_permille", 100)))
	var cands := []
	for i in order.size():
		var job := str(order[i][0])
		var score := float(order[i][1])
		var f := {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * i), "wage": clampi(roundi(maxf(0.0, score) / top * 100000.0), 0, 100000)}
		if job == "":
			var sk := a.skill_fit(n, n.job)
			f.skill = maxi(0, sk)
			f.growth = a.growth_fit(n, n.job)
			f.tenure = clampi((w.day() - n.job_since) * 100000 / maxi(1, a.n_("profession_tenure_full", 16)), 0, 100000)
			f.career_sat = a.profession_sat(n, w)
			f.need_wage = 0
		else:
			f.skill = maxi(0, a.skill_fit(n, job))
			f.growth = a.growth_fit(n, job)
			var gain := clampi(roundi((score - current) * 1000.0 / maxf(1.0, current)), 0, 100000)
			f.need_wage = JudgmentMath.mul_div(mini(1000, gain * 1000 / full), hardship, 1000)
		cands.append({"id": job if job != "" else "stay", "factors": f})
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "job_choice", cands, [w.day(), n.id])
	j._stat("job_choices")
	var chosen := "" if r.chosen == null or str(r.chosen) == "stay" else str(r.chosen)
	var live := live_best if (live_switch or unemployed) else ""
	if chosen != live:
		j._stat("job_choices_changed")                 # the weighing moved the choice from the live rule's
	return chosen


## proposal_accept (WDR-011-Q8, owner answer A, 2026-10-27, D39; with aspirations on only): whether villager `n` accepts the
## eligible proposal of villager `suitor`. Called by Relations.propose only AFTER every hard limit has passed (courting,
## Relations.can_court: kinship, age, existing partners; Relations.refusal: willingness, regard, a rival; the separate-days
## and too-soon gate), so weighting can only refuse an eligible proposal, never allow an ineligible one. Weighed by the one
## shared interface with the courting factors (court_factors: bond, own opinion, circumstances, shared ambitions, standing
## without the chooser's own entry), each scaled by n's own priorities and spread, against doing without (the profile's
## forgo). No financial cutoff: wealth is one weighed factor. `suitor` is a villager or a player (PROP-EQ, WDR-012, D39
## follow-up): a player's proposal to a villager is weighed the same way, the player read in their own form
## (court_factors). Only the villager's own answer is weighed: no NPC ever answers for a player, and a proposal between two
## players is theirs alone (World.player_offer), never here.
static func accepts_proposal(w, n: NPC, suitor) -> bool:
	var j: JudgmentStore = w.judgment
	var sid: int = w.person_id(suitor) if suitor is PlayerState else suitor.id
	var t: Dictionary = w.relations.peek(n.id, sid)
	var f := court_factors(w, n, suitor)
	f.attraction = roundi(clampf(float(t.attraction), 0.0, 100.0) * 1000.0)
	var r := JudgmentWeighting.choose(j, j.cfg, n.id, "proposal_accept", [{"id": "accept", "counterparty": sid, "factors": f}], [w.day(), sid])
	j._stat("proposal_weighed")
	if str(r.chosen) == "accept":
		return true
	j._stat("proposal_refused_by_preference")
	return false
