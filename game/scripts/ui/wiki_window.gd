class_name WikiWindow
extends RefCounted
## The wiki's screen (PL2-009), built into a container of the Settings window (its Wiki tab, also
## reached from the title screen): a search box, then the home page (categories and guides), a
## category list, a page or search results. Content comes from Wiki (scripts/core/wiki.gd).
## Everything is a Button or a link, so keyboard, mouse, gamepad and touch all navigate it;
## step_back() is the Back step (the previous page) that GameUI.go_back tries before leaving Settings.

const GOLD := Color(1, 0.85, 0.5)
const DIM := Color8(214, 200, 170)
const WARN := Color8(255, 190, 150)

static var _cached: Wiki
static var _cached_providers := -1

var ui                                  # GameUI (or null in tests)
var wiki: Wiki
var host: VBoxContainer                 # re-rendered on every navigation
var search_edit: LineEdit
var history: Array = []                 # earlier views, newest last
var view := {"kind": "home"}            # {kind: home | cat | page | search, id / q}
var scroller: ScrollContainer


static func shared() -> Wiki:
	if _cached == null or _cached_providers != Wiki.providers.size():
		_cached = Wiki.build()
		_cached_providers = Wiki.providers.size()
	return _cached


## Build the wiki into `body` (a VBoxContainer). `owner_ui` may be null.
func open(owner_ui, body: Control) -> void:
	ui = owner_ui
	wiki = shared()
	var par := body.get_parent()
	scroller = par if par is ScrollContainer else null
	var bar := HBoxContainer.new()
	bar.name = "WikiSearchBar"
	body.add_child(bar)
	search_edit = LineEdit.new()
	search_edit.name = "WikiSearch"
	search_edit.placeholder_text = "Search the wiki (pickaxe, plank, heal...)"
	search_edit.clear_button_enabled = true
	search_edit.custom_minimum_size = Vector2(0, 48)
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.text_changed.connect(func(t: String): search_for(t, true))
	search_edit.text_submitted.connect(func(t: String): search_for(t))
	bar.add_child(search_edit)
	var home := Button.new()
	home.text = "Wiki home"
	home.custom_minimum_size = Vector2(130, 48)
	home.pressed.connect(show_home)
	bar.add_child(home)
	host = VBoxContainer.new()
	host.name = "WikiHost"
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_theme_constant_override("separation", 6)
	body.add_child(host)
	_render(false)


# --- navigation ------------------------------------------------------------------------------
func _go(v: Dictionary, push := true) -> void:
	if push and not view.is_empty():
		history.append(view)
	view = v
	_render(true)


func show_home() -> void:
	if search_edit and search_edit.text != "":
		search_edit.text = ""
	_go({"kind": "home"})


func goto(id: String) -> void:
	if wiki.pages.has(id):
		_go({"kind": "page", "id": id})


func show_category(id: String) -> void:
	_go({"kind": "cat", "id": id})


## Search; while typing (`live`) the results replace each other instead of piling up in the history.
func search_for(q: String, live := false) -> void:
	if search_edit and search_edit.text != q:
		search_edit.text = q
	if q.strip_edges() == "":
		if view.kind == "search":
			_go({"kind": "home"}, false)
		return
	_go({"kind": "search", "q": q}, not (live and view.kind == "search"))
	if live:
		_render(false)


## One step back: the previous page. False at the start, so Settings handles Back.
func step_back() -> bool:
	if history.is_empty():
		return false
	view = history.pop_back()
	if view.kind != "search" and search_edit and search_edit.text != "":
		search_edit.text = ""
	_render(true)
	return true


# --- drawing ---------------------------------------------------------------------------------
func _render(focus: bool) -> void:
	if host == null or not is_instance_valid(host):
		return
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()
	if not history.is_empty():
		var bk := _button("< Back", step_back)
		bk.name = "WikiBack"
		bk.custom_minimum_size = Vector2(160, 48)
		bk.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	match view.kind:
		"home":
			_home()
		"cat":
			_category(str(view.id))
		"page":
			_page(str(view.id))
		"search":
			_results(str(view.q))
	if scroller:
		scroller.set_deferred("scroll_vertical", 0)
	if focus and ui != null and ui.scheme != "touch":
		_focus_first.call_deferred()


func _focus_first() -> void:
	if host == null or not is_instance_valid(host):
		return
	for b in host.find_children("*", "Button", true, false):
		if b.is_inside_tree() and b.visible and not b.disabled:
			b.grab_focus()
			return


func _label(text: String, size := 16, color := Color8(246, 236, 214), parent: Control = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent else host).add_child(l)
	return l


func _button(text: String, cb: Callable, parent: Control = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	(parent if parent else host).add_child(b)
	return b


func _tex(path: String, size: float) -> TextureRect:
	var t := TextureRect.new()
	if path != "" and ResourceLoader.exists(path):
		t.texture = load(path)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## A page as a button: its icon (when it has one), its title and, optionally, its category.
func _page_button(id: String, parent: Control, with_cat := false) -> Button:
	var pg: Dictionary = wiki.pages[id]
	var b := _button(pg.title + ("   (%s)" % _cat_title(pg.category) if with_cat else ""), func(): goto(id), parent)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.name = "Link_" + id
	if pg.icon != "":
		b.icon = load(pg.icon)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 28)
		b.add_theme_constant_override("h_separation", 8)
	return b


func _cat_title(id: String) -> String:
	for c in wiki.categories:
		if c.id == id:
			return c.title
	return id


func _home() -> void:
	_label("The wiki is built from the game's own data: what you can find, make and do, and how.", 16, DIM)
	_label("How do I...?", 22, GOLD)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 6)
	host.add_child(flow)
	for id in wiki.in_category("guides"):
		_page_button(id, flow).custom_minimum_size.x = 220
	_label("Browse", 22, GOLD)
	var cats := HFlowContainer.new()
	cats.add_theme_constant_override("h_separation", 8)
	cats.add_theme_constant_override("v_separation", 6)
	host.add_child(cats)
	for c in wiki.categories:
		if c.id == "guides" or wiki.in_category(c.id).is_empty():
			continue
		var cid: String = c.id
		var b := _button("%s (%d)" % [c.title, wiki.in_category(cid).size()], func(): show_category(cid), cats)
		b.name = "Cat_" + cid
		b.custom_minimum_size.x = 220
		b.tooltip_text = c.blurb


func _category(cid: String) -> void:
	_label(_cat_title(cid), 26, GOLD)
	for c in wiki.categories:
		if c.id == cid and c.blurb != "":
			_label(c.blurb, 15, DIM)
	for id in wiki.in_category(cid):
		_page_button(id, host)


func _results(q: String) -> void:
	var found := wiki.search(q)
	_label("%d result%s for \"%s\"" % [found.size(), "" if found.size() == 1 else "s", q], 20, GOLD).name = "WikiResultsTitle"
	if found.is_empty():
		_label("Nothing found. Try a shorter word (for example 'iron' or 'wood').", 15, DIM)
	for id in found.slice(0, 40):
		_page_button(id, host, true)


func _page(id: String) -> void:
	var pg: Dictionary = wiki.pages[id]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	host.add_child(head)
	if pg.icon != "":
		var ic := _tex(pg.icon, 64)
		ic.name = "PageIcon"
		head.add_child(ic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(col)
	var t := _label(pg.title, 28, GOLD, col)
	t.name = "PageTitle"
	var catb := _button(_cat_title(pg.category), func(): show_category(pg.category), col)
	catb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	catb.custom_minimum_size = Vector2(160, 36)
	for b in pg.blocks:
		_block(b)


func _block(b: Dictionary) -> void:
	match b.t:
		"h":
			_label(b.text, 20, GOLD)
		"p":
			_label(b.text)
		"bullets":
			for r in b.rows:
				_label("-  " + str(r), 15)
		"note":
			var pc := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color8(96, 40, 26)
			sb.set_content_margin_all(10)
			sb.set_corner_radius_all(6)
			pc.add_theme_stylebox_override("panel", sb)
			host.add_child(pc)
			_label(b.text, 17, WARN, pc)
		"stats":
			var g := GridContainer.new()
			g.columns = 2
			g.add_theme_constant_override("h_separation", 18)
			host.add_child(g)
			for r in b.rows:
				var k := _label(str(r[0]), 16, DIM, g)
				k.size_flags_horizontal = Control.SIZE_FILL
				k.custom_minimum_size.x = 150
				_label(str(r[1]), 16, Color8(246, 236, 214), g)
		"links":
			if str(b.get("label", "")) != "":
				_label(b.label, 17, DIM)
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 8)
			flow.add_theme_constant_override("v_separation", 6)
			host.add_child(flow)
			for id in b.ids:
				if wiki.pages.has(id):
					_page_button(id, flow).custom_minimum_size.x = 200
		"recipe":
			_recipe_row(str(b.id))
		"chain":
			var lines := wiki.chain_lines(str(b.id))
			if not lines.is_empty():
				_label("From raw materials:", 15, DIM)
				for ln in lines:
					_label(ln.replace("    ", "      "), 15)
		"controls":
			_controls_block(str(b.scheme))


func _recipe_row(rid: String) -> void:
	var r: Dictionary = GameData.recipes.get(rid, {})
	if r.is_empty():
		return
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	host.add_child(row)
	var first := true
	for i in r["in"]:
		if not first:
			_label("+", 18, DIM, row)
		first = false
		row.add_child(_tex(Wiki.icon_path(i), 28))
		_label("%d %s" % [int(r["in"][i]), GameData.item_name(i)], 16, Color8(246, 236, 214), row).size_flags_horizontal = Control.SIZE_FILL
	_label("->", 18, DIM, row).size_flags_horizontal = Control.SIZE_FILL
	for o in r.out:
		row.add_child(_tex(Wiki.icon_path(o), 28))
		_label("%d %s" % [int(r.out[o]), GameData.item_name(o)], 16, GOLD, row).size_flags_horizontal = Control.SIZE_FILL
	var st: String = Wiki.STATION_NAMES.get(r.station, str(r.station).capitalize())
	var d := _button("at the %s, %s %d" % [st.to_lower(), str(r.skill).capitalize(), int(r.level)], func(): goto("recipe:" + rid), row)
	d.custom_minimum_size.x = 0


func _controls_block(scheme: String) -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	host.add_child(g)
	for row in GameUI.CONTROLS[scheme]:
		var icons := HBoxContainer.new()
		icons.custom_minimum_size = Vector2(150, 0)
		for n in row[0]:
			icons.add_child(_tex(GameUI.PROMPT % n, 40))
		g.add_child(icons)
		_label(str(row[1]), 16, Color8(246, 236, 214), g)
