class_name Animal
extends RefCounted
## One animal: livestock in a pen or a wild animal in the woods. Everything here is saved.

var id := 0
var species := ""            # cow, pig, sheep, chicken, boar, rabbit (balance.json "animals")
var skin := ""               # sprite sheet (res://assets/animals/<skin>.png)
var sex := "f"               # m | f
var born := 0.0              # game minutes
var area := ""               # pen id or woods id: the animal stays on that area's cells
var alive := true
var hp := 10.0
var pos := Vector2.ZERO      # tile coordinates (float)
var facing := Vector2.DOWN
var goal := Vector2.INF      # where it is wandering to
var wait := 0.0              # real seconds before it wanders again
var hunger := 100.0          # 100 = full, like the villagers
var next_birth := 0.0        # game minutes: a female can give birth again from then
var next_product := 0.0      # game minutes: a pen animal of the player makes its next egg, milk or wool then (0: not set yet; PL2-015)
var moving := false
var dest := Vector2.INF      # WR-01: a young animal out of a refuge walks to this settling point (INF: settled)
var settle_by := 0.0         # game minutes: it settles where it is by then
var origin := ""             # the refuge it came from ("" for none)
# B14 wildlife (not saved: a chase or a fight is picked up again after loading)
var hunt := -1               # the prey animal a hunter is chasing, -1 for none
var anger := ""              # who it is fighting: "player" or "npc:<id>", "" for nobody
var anger_left := 0.0        # real seconds the fight lasts unless renewed
var bite_cd := 0.0           # real seconds before it can bite again
var act := ""                # a one-off animation playing: "attack", "hit" ("" for none)
var act_left := 0.0


func cell() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func spec() -> Dictionary:
	return GameData.b("animals")[species]


func age_days(now: float) -> float:
	return (now - born) / 1440.0


func adult(now: float) -> bool:
	return age_days(now) >= float(spec().grow_days)


## newborn -> juvenile -> adult -> elderly by age in game days (balance.json "animals": juvenile_days,
## grow_days, elder_days). The stage is a pure function of `born` and the clock (B8-029).
func stage(now: float) -> String:
	var d := age_days(now)
	var sp := spec()
	if d < float(sp.juvenile_days):
		return "newborn"
	if d < float(sp.grow_days):
		return "juvenile"
	if d < float(sp.elder_days):
		return "adult"
	return "elderly"


func elderly(now: float) -> bool:
	return stage(now) == "elderly"


## In its breeding prime: grown and not yet elderly.
func breeds(now: float) -> bool:
	return stage(now) == "adult"


## The baby sheet (res://assets/animals/<skin>_baby.png) if the species has art for one.
func baby_skin() -> String:
	var path := "res://assets/animals/%s_baby.png" % skin
	return skin + "_baby" if ResourceLoader.exists(path) else ""


## The sheet's art for this animal's skin: {layout, frame} (a species may mix packs: balance "skin_art").
func art() -> Dictionary:
	var sp := spec()
	var per: Dictionary = sp.get("skin_art", {})
	if per.has(skin):
		return per[skin]
	return {"layout": sp.layout, "frame": sp.frame}


## What it eats: "graze" (grass, the default), "seeds", "hunt" (its `prey`), "omnivore" (berries, then prey).
func diet() -> String:
	return str(spec().get("diet", "graze"))


func wild() -> bool:
	return spec().kind == "wild"


func label() -> String:
	return GameData.b("animals")[species].one


func to_dict() -> Dictionary:
	var d := {"id": id, "species": species, "skin": skin, "sex": sex, "born": born, "area": area, "alive": alive,
		"hp": hp, "pos": [pos.x, pos.y], "hunger": hunger, "next_birth": next_birth, "next_product": next_product}
	if dest != Vector2.INF:                      # WR-01: dispersing from a refuge (older saves have none)
		d["dest"] = [dest.x, dest.y]
		d["settle_by"] = settle_by
	if origin != "":
		d["origin"] = origin
	return d


static func from_dict(d: Dictionary) -> Animal:
	var a := Animal.new()
	a.id = int(d.id)
	a.species = d.species
	a.skin = d.skin
	a.sex = d.sex
	a.born = float(d.born)
	a.area = d.area
	a.alive = bool(d.alive)
	a.hp = float(d.hp)
	a.pos = Vector2(d.pos[0], d.pos[1])
	a.hunger = float(d.get("hunger", 100.0))
	a.next_birth = float(d.next_birth)
	a.next_product = float(d.get("next_product", 0.0))
	if d.has("dest"):
		a.dest = Vector2(d.dest[0], d.dest[1])
		a.settle_by = float(d.get("settle_by", 0.0))
	a.origin = str(d.get("origin", ""))
	return a
