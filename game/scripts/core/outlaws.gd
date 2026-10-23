class_name Outlaws
extends RefCounted
## BANDIT-RETURN (owner, 2026-10-23, docs/directives/2026-10-23_owner_answers_bandits.md): outlaws drift in again.
## A season after the last bandit died, 2 or 3 grown outlaws arrive from outside, walk in from the map's edge and
## make camp at the bandits' camp; from there they are the bandit band under the existing bandit behaviour, and it
## grows by the orphan rule (OD-11, FAM-07) as before.
##
## The clock is World.outlaw_gone_day, the day the last bandit died (-1 while one lives). Saved as the optional key
## "outlaw_gone_day" (no save-version bump): a save without it starts the clock on the day it is loaded when no
## bandit lives (after_load). The arrivals are drawn from a stream seeded by the world seed and that day, so they
## take nothing from any other stream and are the same on every run. Their purses come from outside (coin_sources).

const SEED_MUL := 104729
const SEED_ADD := 61


## Is any bandit (the band proper, not the camp's children) alive?
static func band_alive(w: World) -> bool:
	for n: NPC in w.npcs:
		if n.alive and n.role == "bandit":
			return true
	return false


## World.kill calls this after `n` has died: the last bandit's death starts the clock.
static func on_death(w: World, n: NPC) -> void:
	if n.role == "bandit" and not band_alive(w):
		w.outlaw_gone_day = w.day()


## After loading: an older save has no clock; with no bandit alive it starts today.
static func after_load(w: World) -> void:
	if band_alive(w):
		w.outlaw_gone_day = -1
	elif w.outlaw_gone_day < 0:
		w.outlaw_gone_day = w.day()


## A calendar season in whole game days (Life's calendar, never a fixed count).
static func wait_days() -> int:
	return maxi(1, ceili(Life.seasons_to_days(1.0)))


## Every dawn (Life.dawn): the band is gone for a season, so newcomers arrive. Returns those who came.
static func dawn(w: World) -> Array:
	if band_alive(w):
		w.outlaw_gone_day = -1
		return []
	if w.outlaw_gone_day < 0:
		w.outlaw_gone_day = w.day()          # nobody recorded the end of the band (a world set up without bandits)
		return []
	if w.day() < w.outlaw_gone_day + wait_days():
		return []
	return arrive(w)


## The camp: the map's own bandit camp, or the nearest open cell if something has since closed it.
static func camp_cell(w: World) -> Vector2i:
	var c := w.bandit_camp
	return c if not w.map.is_solid(c) else w.map.nearest_walkable(c)


## 2 or 3 outlaws come in at an edge exit of the map and head for the camp. Returns them.
static func arrive(w: World) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = w.seed * SEED_MUL + SEED_ADD + w.outlaw_gone_day
	var count := rng.randi_range(2, 3)
	var exits: Array = w.map.exits()
	var edge := Vector2(camp_cell(w)) + Vector2(0.5, 0.5)
	if not exits.is_empty():
		edge = Vector2(exits[rng.randi() % exits.size()].edge) + Vector2(0.5, 0.5)
	var taken := {}
	for o: NPC in w.npcs:
		if o.alive and o.role == "bandit":
			taken[o.name] = true
	var out := []
	for i in count:
		var n := NPC.new()
		n.id = w.brain._next_npc_id()
		n.role = "bandit"
		var names: Array = Population.BANDITS.filter(func(s: String) -> bool: return not taken.has(s))
		if names.is_empty():
			names = Population.BANDITS
		n.name = names[rng.randi() % names.size()]
		taken[n.name] = true
		n.sex = Life.sex_of_name(n.name)
		n.born = Life.born_for_age(rng.randf_range(20.0, 40.0), w.minutes)
		n.sprite = "res://assets/characters/bandit_%02d.png" % (n.id % 6)
		n.pos = edge + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4))
		n.hp = 25.0
		n.max_hp = 25.0
		n.damage = 4.0
		n.coins = rng.randi_range(5, 15)
		n.inv.add("copper_sword")
		w.stat("imported_copper_sword")             # the sword comes in from outside with the outlaw: the item ledger counts it
		n.hunger = 100.0
		w.coin_sources += n.coins                    # the purse comes in from outside
		w.stat("outlaw_coins_in", n.coins)
		w.npcs.append(n)
		w.by_id[n.id] = n
		Identity.register_npc(w, n, "outlaw")
		out.append(n)
	w.outlaw_gone_day = -1
	w.stat("outlaws_arrived", out.size())
	w.note("%d outlaws have come in from the road and made camp in the woods." % out.size())
	return out
