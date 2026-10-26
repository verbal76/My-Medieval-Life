class_name WantedHud
extends PanelContainer
## GP-WANTED-INDICATOR (owner, 2026-10-26: "I died 2 times without know why I was being chased"): a small note under the
## status box, out of the way of play, the prompt and the touch buttons, saying that the guards are after this machine's
## own player and why: the state (pursued, guards coming, searched for, wanted) and the gravest crime they know, with its
## victim and where it was done. Read every HUD update from Justice.alert of the local player's reference (a guest reads
## its own case from the host's copy, NetSync "justice"), so it changes as the case does and goes when the case is
## settled, lapses or closes. It shows nothing a player could not know: no guard, no guard's place.
## main.gd draws the red ring round the character from the same alert (`hunted`).

const STATE_TEXT := {"pursued": "Pursued by the guards", "coming": "The guards are coming for you",
	"searched": "The guards are searching for you", "wanted": "Wanted by the guards"}
## The crime in words: [with its victim (%s), without one].
const CRIME_TEXT := {"theft": ["stealing from %s", "theft"], "pickpocket": ["picking %s's pocket", "picking a pocket"],
	"livestock": ["taking %s's livestock", "taking livestock"], "fencing": ["selling stolen goods", "selling stolen goods"],
	"lockpicking": ["picking a lock", "picking a lock"], "assault": ["attacking %s", "assault"],
	"guard_assault": ["striking a guard", "striking a guard"], "killing": ["killing %s", "killing"]}
const RED := Color8(214, 52, 44)

var title: Label
var why: Label
var shown := {}             # the alert last drawn (tests read it)


func _init() -> void:
	name = "WantedHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.06, 0.05, 0.88)
	sb.border_color = RED
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(6)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	title = _lbl(15, Color8(255, 120, 104))
	why = _lbl(13, Color8(246, 236, 214))
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size.x = 220
	v.add_child(title)
	v.add_child(why)
	visible = false


func _lbl(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The alert for this machine's player ({} none).
static func alert_of(w: World) -> Dictionary:
	if w == null or w.justice == null or not w.player.alive:
		return {}
	return w.justice.alert(w.acting_ref())


## "for killing Ada Reed beside the Well House" (the gravest crime the guards know).
static func reason(w: World, a: Dictionary) -> String:
	if str(a.get("crime", "")) == "":
		return ""
	var t: Array = CRIME_TEXT.get(str(a.crime), [str(a.crime).replace("_", " "), str(a.crime).replace("_", " ")])
	var victim: NPC = w.npc(int(a.get("victim", -1)))
	var words: String = (str(t[0]) % ("%s %s" % [victim.name, victim.family])) if victim != null and str(t[0]).contains("%s") else str(t[1])
	var at: Array = a.get("at", [])
	if at.size() >= 2:
		var pos := Vector2(float(at[0]), float(at[1]))
		words += " below ground" if w.level_at(pos) < 0 else " " + w.where(Rect2i(Vector2i(pos.floor()), Vector2i.ONE))
	var more := int(a.get("count", 1)) - 1
	if more > 0:
		words += " (and %d more)" % more
	return "For " + words


func refresh(w: World) -> void:
	var a := alert_of(w)
	shown = a
	visible = not a.is_empty()
	if a.is_empty():
		return
	title.text = STATE_TEXT.get(str(a.state), "Wanted")
	why.text = reason(w, a)
