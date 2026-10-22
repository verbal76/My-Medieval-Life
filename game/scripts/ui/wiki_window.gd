class_name WikiWindow
extends RefCounted
## The Village Encyclopedia (PL2-009; redesigned for UI-WIKI-01, Build 18): the wiki's own window,
## opened by GameUI.show_wiki from the pause menu, the title screen and the Settings window.
## A top bar (Back, Contents, the search box, Close and, during play, Resume), then a left
## navigation panel of categories and a main article panel, each scrolling on its own. Where the
## window is narrower than WIDE_MIN (a phone with a large interface, a portrait phone) the navigation
## panel is hidden and the article panel is the one column: its Contents page lists the categories,
## and the search box sits atop the article and scrolls with it, so a small screen keeps room to read.
## Lists of pages are grids of buttons of one size whose words wrap rather than clip.
## Content comes from Wiki (scripts/core/wiki.gd) and its providers; this file only draws it.
## Everything is a Button or a link, so keyboard, mouse, gamepad and touch all navigate it;
## step_back() is the Back step (the previous view, at the scroll place it was left) that
## GameUI.go_back tries before leaving the window.

const GOLD := Color(1, 0.85, 0.5)
const DIM := Color8(214, 200, 170)
const WARN := Color8(255, 190, 150)
const TEXT := Color8(246, 236, 214)
const WIDE_MIN := 840.0          # below this window width: one column, no navigation panel
const CELL := 250.0              # the width a grid of page buttons gives each column
const ITEM_H := 46.0             # every navigation item and page button is at least this tall

static var _cached: Wiki
static var _cached_providers := -1

var ui                                  # GameUI (or null in tests)
var wiki: Wiki
var root: VBoxContainer                 # the whole encyclopedia
var top: HFlowContainer                 # Back, Contents, (search when wide), Close, Resume
var search_row: HBoxContainer           # the search box's place when narrow: atop the article, scrolling with it
var search_edit: LineEdit
var back_btn: Button
var nav_panel: PanelContainer           # the left navigation (wide only)
var nav_list: VBoxContainer
var article: ScrollContainer            # the main reading panel
var host: VBoxContainer                 # the article's content, re-rendered on every navigation
var history: Array = []                 # earlier views, newest last
var view := {"kind": "home"}            # {kind: home | cat | page | search, id / q}
var narrow := false
var grids: Array = []                   # this view's grids of page buttons, re-columned on resize


static func shared() -> Wiki:
	if _cached == null or _cached_providers != Wiki.providers.size():
		_cached = Wiki.build()
		_cached_providers = Wiki.providers.size()
	return _cached


## Build the encyclopedia into `body` (a VBoxContainer that it fills). `owner_ui` may be null.
func open(owner_ui, body: Control) -> void:
	ui = owner_ui
	wiki = shared()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root = VBoxContainer.new()
	root.name = "Encyclopedia"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	body.add_child(root)
	# the top bar
	top = HFlowContainer.new()
	top.name = "WikiTopBar"
	top.add_theme_constant_override("h_separation", 8)
	top.add_theme_constant_override("v_separation", 8)
	root.add_child(top)
	back_btn = _bar_button("< Back", step_back_pressed, top)
	back_btn.name = "WikiBack"
	var contents := _bar_button("Contents", show_home, top)
	contents.name = "WikiContents"
	search_edit = LineEdit.new()
	search_edit.name = "WikiSearch"
	search_edit.placeholder_text = "Search (pickaxe, plank, heal...)"
	search_edit.clear_button_enabled = true
	search_edit.custom_minimum_size = Vector2(160, 48)
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.text_changed.connect(func(t: String): search_for(t, true))
	search_edit.text_submitted.connect(func(t: String): search_for(t))
	top.add_child(search_edit)
	var close := _bar_button("Close", close_window, top)
	close.name = "WikiClose"
	close.tooltip_text = "Leave the encyclopedia"
	if ui != null and ui.main != null and ui.main.running:
		var resume := _bar_button("Resume play", func(): ui.hide_all(), top)
		resume.tooltip_text = "Close the encyclopedia and the menus, and play on"
		resume.name = "WikiResume"
	# the navigation and the article, side by side
	var split := HBoxContainer.new()
	split.name = "WikiSplit"
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 10)
	root.add_child(split)
	nav_panel = PanelContainer.new()
	nav_panel.name = "WikiNav"
	nav_panel.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.22)))
	split.add_child(nav_panel)
	var nav_scroll := ScrollContainer.new()
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_scroll.follow_focus = true
	nav_panel.add_child(nav_scroll)
	nav_list = VBoxContainer.new()
	nav_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_list.add_theme_constant_override("separation", 4)
	nav_scroll.add_child(nav_list)
	_build_nav()
	article = ScrollContainer.new()
	article.name = "WikiArticle"
	article.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	article.size_flags_vertical = Control.SIZE_EXPAND_FILL
	article.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	article.follow_focus = true
	split.add_child(article)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 6)
	pad.add_theme_constant_override("margin_right", 14)   # room for the scroll bar
	article.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	pad.add_child(col)
	search_row = HBoxContainer.new()
	search_row.name = "WikiSearchRow"
	search_row.visible = false
	col.add_child(search_row)
	host = VBoxContainer.new()
	host.name = "WikiHost"
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_theme_constant_override("separation", 8)
	col.add_child(host)
	root.resized.connect(_relayout)
	article.resized.connect(_columns)
	_relayout()
	_render(ui != null and ui.scheme != "touch")


# --- layout ----------------------------------------------------------------------------------
## The window's width: its own once laid out, else the screen's.
func _width() -> float:
	if root.size.x > 0.0:
		return root.size.x
	return root.get_viewport_rect().size.x - 40.0 if root.is_inside_tree() else 1280.0


## Wide: navigation beside the article, search in the top bar. Narrow: one column, search below it.
func _relayout() -> void:
	if root == null or not is_instance_valid(root):
		return
	var w := _width()
	var was := narrow
	narrow = w < WIDE_MIN
	nav_panel.visible = not narrow
	nav_panel.custom_minimum_size.x = clampf(w * 0.24, 220.0, 300.0)
	var want: Control = search_row if narrow else top
	if search_edit.get_parent() != want:
		var had_focus := search_edit.has_focus()
		search_edit.get_parent().remove_child(search_edit)
		want.add_child(search_edit)
		if want == top:
			top.move_child(search_edit, 2)
		if had_focus:
			search_edit.grab_focus.call_deferred()
	search_row.visible = narrow
	_columns()
	if was != narrow and view.kind == "home":
		_render(false)


func _article_width() -> float:
	if article.size.x > 0.0:
		return article.size.x - 24.0
	return _width() - (0.0 if narrow else nav_panel.custom_minimum_size.x + 10.0) - 24.0


func _columns() -> void:
	var cols := maxi(1, int(_article_width() / CELL))
	for g in grids:
		if is_instance_valid(g):
			g.columns = cols


# --- navigation ------------------------------------------------------------------------------
func _go(v: Dictionary, push := true, focus := true) -> void:
	if push and not view.is_empty():
		var was := view.duplicate()
		was.scroll = article.scroll_vertical if article else 0
		history.append(was)
	view = v
	_render(focus)


func show_home() -> void:
	if search_edit and search_edit.text != "":
		search_edit.text = ""
	if view.kind == "home" and history.is_empty():
		return
	_go({"kind": "home"})


func goto(id: String) -> void:
	if wiki.pages.has(id):
		_go({"kind": "page", "id": id})


func show_category(id: String) -> void:
	_go({"kind": "cat", "id": id})


## Search; while typing (`live`) the results replace each other instead of piling up in the history,
## and the focus stays in the search box.
func search_for(q: String, live := false) -> void:
	if search_edit and search_edit.text != q:
		search_edit.text = q
	if q.strip_edges() == "":
		if view.kind == "search":
			_go({"kind": "home"}, false, not live)
		return
	_go({"kind": "search", "q": q}, not (live and view.kind == "search"), not live)


## One step back: the previous view, scrolled to where it was left, with the page just left
## focused in its list. False at the start, so the window's caller handles Back.
func step_back() -> bool:
	if history.is_empty():
		return false
	var left := view
	view = history.pop_back()
	if view.kind != "search" and search_edit and search_edit.text != "":
		search_edit.set_block_signals(true)
		search_edit.text = ""
		search_edit.set_block_signals(false)
	elif view.kind == "search" and search_edit and search_edit.text != str(view.q):
		search_edit.set_block_signals(true)
		search_edit.text = str(view.q)
		search_edit.set_block_signals(false)
	var target := ""
	if left.kind == "page":
		target = "Link_" + str(left.id).replace(":", "_")
	elif left.kind == "cat":
		target = "Cat_" + str(left.id)
	_render(true, int(view.get("scroll", 0)), target)
	return true


func step_back_pressed() -> void:
	step_back()


## Leave the encyclopedia for wherever it was opened from, whatever the history.
func close_window() -> void:
	if ui == null:
		return
	if ui.panel_back.is_valid():
		ui.panel_back.call()
	else:
		ui.hide_all()


# --- drawing ---------------------------------------------------------------------------------
func _render(focus: bool, scroll := 0, target := "") -> void:
	if host == null or not is_instance_valid(host):
		return
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()
	grids.clear()
	back_btn.disabled = history.is_empty()
	match view.kind:
		"home":
			_home()
		"cat":
			_category(str(view.id))
		"page":
			_page(str(view.id))
		"search":
			_results(str(view.q))
	_mark_nav()
	_columns()
	_settle(focus and ui != null and ui.scheme != "touch", scroll, target)


## Once the new content has laid out (wrapped words settle a frame or two late, and focusing before
## that scrolled the article to a wrong place): focus `target` (or the first button) for keys and
## pads, then put the article at `scroll` (the top for a new view, the old place for a step back).
func _settle(focus: bool, scroll: int, target: String) -> void:
	if article == null or not article.is_inside_tree():
		return
	article.scroll_vertical = 0
	var tree := article.get_tree()
	var at := view
	for i in 2:
		await tree.process_frame
	if not is_instance_valid(article) or at != view:
		return
	if focus:
		var to: Control = host.find_child(target, true, false) if target != "" else null
		if to != null:
			to.grab_focus()
		else:
			_focus_first()
		await tree.process_frame
		if not is_instance_valid(article) or at != view:
			return
	article.scroll_vertical = scroll


func _focus_first() -> void:
	if host == null or not is_instance_valid(host):
		return
	for b in host.find_children("*", "Button", true, false):
		if is_instance_valid(b) and b.is_inside_tree() and b.visible and not b.disabled:
			b.grab_focus()
			return


func _box(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_content_margin_all(8)
	sb.set_corner_radius_all(6)
	return sb


func _label(text: String, size := 18, color := TEXT, parent: Control = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent else host).add_child(l)
	return l


## An article heading: gold words over a thin rule.
func _heading(text: String, size := 21) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	host.add_child(gap)
	_label(text, size, GOLD)
	var rule := ColorRect.new()
	rule.color = Color(GOLD, 0.35)
	rule.custom_minimum_size.y = 2
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(rule)


func _button(text: String, cb: Callable, parent: Control = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, ITEM_H)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(cb)
	(parent if parent else host).add_child(b)
	return b


func _bar_button(text: String, cb: Callable, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## A grid of equal buttons, its columns set from the article's width.
func _grid(parent: Control = null) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 1
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 6)
	(parent if parent else host).add_child(g)
	grids.append(g)
	return g


## A label that never wraps, for rows of icons and amounts.
func _plain(text: String, size: int, color: Color, parent: Control) -> Label:
	var l := _label(text, size, color, parent)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return l


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


## A page as a button of the grid's size: its icon (when it has one), its title and, optionally, its category.
func _page_button(id: String, parent: Control, with_cat := false) -> Button:
	var pg: Dictionary = wiki.pages[id]
	var b := _button(pg.title + ("  -  %s" % _cat_title(pg.category) if with_cat else ""), func(): goto(id), parent)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.name = "Link_" + id.replace(":", "_")
	if pg.icon != "" and ResourceLoader.exists(pg.icon):
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


## The categories that have pages, guides first.
func _cats() -> Array:
	var out := []
	for c in wiki.categories:
		if c.id == "guides" and not wiki.in_category("guides").is_empty():
			out.push_front(c)
		elif not wiki.in_category(c.id).is_empty():
			out.append(c)
	return out


# --- the navigation panel --------------------------------------------------------------------
func _build_nav() -> void:
	_label("Topics", 18, GOLD, nav_list)
	var home := _nav_item("Contents", show_home)
	home.name = "Nav_home"
	for c in _cats():
		var cid: String = c.id
		var b := _nav_item("%s (%d)" % [c.title, wiki.in_category(cid).size()], func(): show_category(cid))
		b.name = "Nav_" + cid
		b.tooltip_text = c.blurb


func _nav_item(text: String, cb: Callable) -> Button:
	var b := _button(text, cb, nav_list)
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## Light the navigation item of the category on show (a page lights its own category).
func _mark_nav() -> void:
	var on := "home"
	match view.kind:
		"cat":
			on = str(view.id)
		"page":
			on = str(wiki.pages[view.id].category)
		"search":
			on = ""
	for b in nav_list.get_children():
		if b is Button:
			b.set_pressed_no_signal(b.name == "Nav_" + on)


# --- the article panel -----------------------------------------------------------------------
func _home() -> void:
	_label("Village Encyclopedia", 28, GOLD).name = "PageTitle"
	_label("Built from the game's own data: what you can find, make and do, and how. Search above, or choose a topic.", 16, DIM)
	var guides := wiki.in_category("guides")
	if not guides.is_empty():
		_heading("How do I...?")
		var g := _grid()
		for id in guides:
			_page_button(id, g)
	_heading("Topics")
	for c in _cats():
		if c.id == "guides":
			continue
		var cid: String = c.id
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		host.add_child(row)
		var b := _button("%s (%d)" % [c.title, wiki.in_category(cid).size()], func(): show_category(cid), row)
		b.name = "Cat_" + cid
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.x = 210 if narrow else 240
		if c.blurb != "":
			var l := _label(c.blurb, 17, DIM, row)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _category(cid: String) -> void:
	_label(_cat_title(cid), 28, GOLD).name = "PageTitle"
	for c in wiki.categories:
		if c.id == cid and c.blurb != "":
			_label(c.blurb, 16, DIM)
	var ids := wiki.in_category(cid)
	_label("%d page%s" % [ids.size(), "" if ids.size() == 1 else "s"], 14, DIM)
	var g := _grid()
	for id in ids:
		_page_button(id, g)


func _results(q: String) -> void:
	var found := wiki.search(q)
	_label("%d result%s for \"%s\"" % [found.size(), "" if found.size() == 1 else "s", q], 22, GOLD).name = "WikiResultsTitle"
	if found.is_empty():
		_label("Nothing found. Try a shorter word (for example 'iron' or 'wood').", 16, DIM)
		return
	if found.size() > 40:
		_label("Showing the first 40. Add a word to narrow the search.", 14, DIM)
	var g := _grid()
	for id in found.slice(0, 40):
		_page_button(id, g, true)


func _page(id: String) -> void:
	var pg: Dictionary = wiki.pages[id]
	var crumb := _button("%s" % _cat_title(pg.category), func(): show_category(pg.category))
	crumb.name = "PageCategory"
	crumb.autowrap_mode = TextServer.AUTOWRAP_OFF
	crumb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	crumb.custom_minimum_size = Vector2(150, 40)
	crumb.tooltip_text = "All pages in this topic"
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	host.add_child(head)
	if pg.icon != "":
		var ic := _tex(pg.icon, 56)
		ic.name = "PageIcon"
		head.add_child(ic)
	var t := _label(pg.title, 28, GOLD, head)
	t.name = "PageTitle"
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var rule := ColorRect.new()
	rule.color = Color(GOLD, 0.35)
	rule.custom_minimum_size.y = 2
	host.add_child(rule)
	for b in pg.blocks:
		_block(b)


func _block(b: Dictionary) -> void:
	match b.t:
		"h":
			_heading(b.text)
		"p":
			_label(b.text)
		"bullets":
			var list := VBoxContainer.new()
			list.add_theme_constant_override("separation", 3)
			host.add_child(list)
			for r in b.rows:
				var row := HBoxContainer.new()
				list.add_child(row)
				var dot := _plain("  -", 17, GOLD, row)
				dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				_label(str(r), 17, TEXT, row)
		"note":
			var pc := PanelContainer.new()
			var sb := _box(Color8(96, 40, 26))
			sb.set_content_margin_all(10)
			pc.add_theme_stylebox_override("panel", sb)
			host.add_child(pc)
			_label(b.text, 17, WARN, pc)
		"stats":
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.2)))
			host.add_child(pc)
			var g := GridContainer.new()
			g.columns = 2
			g.add_theme_constant_override("h_separation", 18)
			g.add_theme_constant_override("v_separation", 4)
			pc.add_child(g)
			for r in b.rows:
				var k := _label(str(r[0]), 17, DIM, g)
				k.size_flags_horizontal = Control.SIZE_FILL
				k.custom_minimum_size.x = 140 if narrow else 170
				_label(str(r[1]), 17, TEXT, g)
		"links":
			_label(str(b.label) if str(b.get("label", "")) != "" else "See also", 17, DIM)
			var g := _grid()
			for id in b.ids:
				if wiki.pages.has(id):
					_page_button(id, g)
		"recipe":
			_recipe_row(str(b.id))
		"chain":
			var lines := wiki.chain_lines(str(b.id))
			if not lines.is_empty():
				_label("From raw materials:", 16, DIM)
				for ln in lines:
					_label(ln.replace("    ", "      "), 16)
		"controls":
			_controls_block(str(b.scheme))


func _recipe_row(rid: String) -> void:
	var r: Dictionary = GameData.recipes.get(rid, {})
	if r.is_empty():
		return
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.2)))
	host.add_child(pc)
	var col := VBoxContainer.new()
	pc.add_child(col)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	col.add_child(row)
	var first := true
	for i in r["in"]:
		if not first:
			_plain("+", 18, DIM, row)
		first = false
		row.add_child(_tex(Wiki.icon_path(i), 28))
		_plain("%d %s" % [int(r["in"][i]), GameData.item_name(i)], 16, TEXT, row)
	_plain("->", 18, DIM, row)
	for o in r.out:
		row.add_child(_tex(Wiki.icon_path(o), 28))
		_plain("%d %s" % [int(r.out[o]), GameData.item_name(o)], 16, GOLD, row)
	var st: String = Wiki.STATION_NAMES.get(r.station, str(r.station).capitalize())
	var d := _button("at the %s, %s %d" % [st.to_lower(), str(r.skill).capitalize(), int(r.level)], func(): goto("recipe:" + rid), col)
	d.autowrap_mode = TextServer.AUTOWRAP_OFF
	d.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	d.custom_minimum_size = Vector2(0, 40)


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
		_label(str(row[1]), 16, TEXT, g)
