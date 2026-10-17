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
var moving := false


func cell() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func spec() -> Dictionary:
	return GameData.b("animals")[species]


func age_days(now: float) -> float:
	return (now - born) / 1440.0


func adult(now: float) -> bool:
	return age_days(now) >= float(spec().grow_days)


func wild() -> bool:
	return spec().kind == "wild"


func label() -> String:
	return GameData.b("animals")[species].one


func to_dict() -> Dictionary:
	return {"id": id, "species": species, "skin": skin, "sex": sex, "born": born, "area": area, "alive": alive,
		"hp": hp, "pos": [pos.x, pos.y], "hunger": hunger, "next_birth": next_birth}


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
	return a
