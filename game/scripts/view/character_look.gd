class_name CharacterLook
extends RefCounted
## CC-01 (owner, 2026-10-22): a character drawn at run time from a recipe, the way tools/puny_chargen.py draws
## PUNY CHARACTERS (TDSM) sheets: uncoloured layer sheets stacked in the pack's draw order, each recoloured by
## its palette ramps. The rules are not written here: tools/import_game_assets.py writes them, from
## puny_chargen's port of the pack's manifest.tds, into game/data/character_style.json (draw order, which ramp
## and colour selection recolours each layer, the ramps, and what character creation offers); this class only
## follows them, so a recipe draws the same sheet here as puny_chargen.render does (character_look_test checks
## it pixel for pixel against the sheets the importer baked).
##
## A recipe is {"picks": {layer: option or ""}, "swatches": {colour selection: ramp row}}. The sheet it makes
## is the usual 29 x 8 frames of 32 px (ActorSprite). Composed on the CPU once per recipe and cached as one
## texture (the same 950 KB a baked sheet takes); each layer sheet is read once into a list of its opaque pixels
## (the sheets have no partly transparent pixels) and its texture let go.

const STYLE_PATH := "res://data/character_style.json"
const APPEARANCES_PATH := "res://data/appearances.json"
const CACHE_MAX := 4                # composed sheets kept (the player, the heir's look, creation's preview)

static var _style: Dictionary = {}
static var _looks: Array = []
static var _sparse := {}            # layer sheet path -> [opaque pixel indices, their colours] (PackedInt32Array)
static var _ramp_px := {}           # ramp -> rows of colours as the composer's 32-bit pixels
static var _cache := {}             # recipe key -> ImageTexture
static var _cache_order: Array = []


static func style() -> Dictionary:
	if _style.is_empty():
		_style = JSON.parse_string(FileAccess.get_file_as_string(STYLE_PATH))
	return _style


## A colour "rrggbbaa" as the 32-bit pixel of an RGBA8 image read with to_int32_array.
static func _px(hex: String) -> int:
	var b := PackedByteArray([hex.substr(0, 2).hex_to_int(), hex.substr(2, 2).hex_to_int(), hex.substr(4, 2).hex_to_int(), hex.substr(6, 2).hex_to_int()])
	return b.to_int32_array()[0]


static func _ramp(r: String) -> Array:
	if not _ramp_px.has(r):
		var rows: Array = []
		for row in style().ramps[r]:
			var a := PackedInt32Array()
			for hex in row:
				a.append(_px(hex))
			rows.append(a)
		_ramp_px[r] = rows
	return _ramp_px[r]


## The opaque pixels of a layer sheet: [indices, colours].
static func _sparse_of(path: String) -> Array:
	if not _sparse.has(path):
		var img: Image = (load(path) as Texture2D).get_image()
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var all := img.get_data().to_int32_array()
		var idx := PackedInt32Array()
		var col := PackedInt32Array()
		for i in all.size():
			var c: int = all[i]
			if c & 0xFF000000 == 0xFF000000:
				idx.append(i)
				col.append(c)
		_sparse[path] = [idx, col]
	return _sparse[path]


## A pick as stored ("" or null = none).
static func _pick(picks: Dictionary, layer: String) -> String:
	var v = picks.get(layer, "")
	return "" if v == null else str(v)


## The recipe with its worn items' layers applied (the hook for equipment, ARMOR-01): style "worn_layers" maps an
## item id to {"layer", "option", "swatches", "hides": [layers], "also": [{"layer", "option"}]} (written by
## tools/import_game_assets.py WORN_LAYERS): every armour and head item has an entry; plain clothes one with no layer.
## The recipe itself is never changed, so taking the item off draws the character's own clothes again.
static func apply_worn(recipe: Dictionary, worn: Array) -> Dictionary:
	var table: Dictionary = style().get("worn_layers", {})
	var out := {"picks": (recipe.get("picks", {}) as Dictionary).duplicate(), "swatches": (recipe.get("swatches", {}) as Dictionary).duplicate()}
	for item in worn:
		if not table.has(str(item)):
			continue
		var w: Dictionary = table[str(item)]
		for layer in w.get("hides", []):
			out.picks[str(layer)] = ""
		if w.has("layer"):
			out.picks[str(w.layer)] = str(w.option)
		for part in w.get("also", []):
			out.picks[str(part.layer)] = str(part.option)
		for s in w.get("swatches", {}):
			out.swatches[str(s)] = int(w.swatches[s])
	return out


## Draw the recipe's sheet (puny_chargen.render's order and recolouring).
static func render(recipe: Dictionary) -> Image:
	var st := style()
	var dim := int(st.dim)
	var w := dim * int(st.frames)
	var h := dim * (st.directions as Array).size()
	var canvas := PackedInt32Array()
	canvas.resize(w * h)
	var picks: Dictionary = recipe.get("picks", {})
	var sw: Dictionary = recipe.get("swatches", {})
	var human := _pick(picks, "race") == "human"
	for layer: String in st.draw_order:
		var code: String = str(st.always[layer]) if st.always.has(layer) else _pick(picks, layer)
		if code == "" or (layer in st.human_only and not human):
			continue
		var opt = (st.layers.get(layer, {}) as Dictionary).get(code)
		if opt == null:
			push_warning("CharacterLook: no %s layer %s" % [layer, code])
			continue
		var table := {}                          # reference colour -> swatch colour; the first ramp to name a colour wins
		for pair in opt.ramps:
			var rows := _ramp(str(pair[0]))
			var row := clampi(int(sw.get(str(pair[1]), 0)), 0, rows.size() - 1)
			for x in (rows[0] as PackedInt32Array).size():
				if not table.has(rows[0][x]):
					table[rows[0][x]] = rows[row][x]
		var sp := _sparse_of(str(opt.sheet))
		var idx: PackedInt32Array = sp[0]
		var col: PackedInt32Array = sp[1]
		if table.is_empty():
			for i in idx.size():
				canvas[idx[i]] = col[i]
		else:
			for i in idx.size():
				canvas[idx[i]] = table.get(col[i], col[i])
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, canvas.to_byte_array())


## The recipe's sheet as a texture, composed once and cached.
static func texture(recipe: Dictionary, worn: Array = []) -> Texture2D:
	var r := apply_worn(recipe, worn)
	var key := JSON.stringify(r, "", true)
	if _cache.has(key):
		_cache_order.erase(key)
		_cache_order.append(key)
		return _cache[key]
	var t := ImageTexture.create_from_image(render(r))
	_cache[key] = t
	_cache_order.append(key)
	while _cache_order.size() > CACHE_MAX:
		_cache.erase(_cache_order.pop_front())
	return t


## The sheet a player state is drawn with: its recipe, or (an heir who was a villager's child, an old default) the
## baked sheet at `sprite`.
static func sheet_for(sprite: String, appearance: Dictionary, worn: Array = []) -> Texture2D:
	if not appearance.is_empty():
		return texture(appearance, worn)
	var baked: Texture2D = load(sprite) if sprite != "" and ResourceLoader.exists(sprite) else null
	return over_baked(baked, sprite, worn) if baked != null else null


## ARMOR-01 (Build 22): a character with no recipe (an heir who was a villager's child, a pre-CC-01 default sheet) still
## shows what it wears: the worn items' layers, drawn from their own sheets and ramps, laid over the baked sheet (body
## armour over the clothes, the helmet over the hair, as the draw order has them); the baked sheet when nothing worn draws.
static func over_baked(baked: Texture2D, key: String, worn: Array) -> Texture2D:
	var only := apply_worn({"picks": {}, "swatches": {}}, worn)
	if (only.picks as Dictionary).values().all(func(v): return str(v) == ""):
		return baked
	var ck := "baked:%s|%s" % [key, JSON.stringify(only, "", true)]
	if _cache.has(ck):
		return _cache[ck]
	var img := Image.new()
	img.copy_from(baked.get_image())             # never the texture's own image
	img.convert(Image.FORMAT_RGBA8)
	var top := render(only)                      # the worn layers alone (no race: no eyes; the weapon overlay is the sheet's own)
	if top.get_size() == img.get_size():
		img.blend_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i.ZERO)
	var t := ImageTexture.create_from_image(img)
	_cache[ck] = t
	_cache_order.append(ck)
	while _cache_order.size() > CACHE_MAX:
		_cache.erase(_cache_order.pop_front())
	return t


static func player_sheet(p: PlayerState) -> Texture2D:
	return sheet_for(p.sprite, p.appearance, [p.armor, p.head])


## A recipe as saved: every creation layer's pick ("" = none) and whole-number swatches.
static func normalize(recipe: Dictionary) -> Dictionary:
	if recipe.is_empty():
		return {}
	var picks := {}
	var src: Dictionary = recipe.get("picks", {})
	for layer in src:
		picks[str(layer)] = _pick(src, str(layer))
	for layer in style().creation.picks:
		if not picks.has(layer):
			picks[layer] = ""
	var sw := {}
	var s: Dictionary = recipe.get("swatches", {})
	for k in s:
		sw[str(k)] = int(s[k])
	return {"picks": picks, "swatches": sw}


## The recipe of a look from before CC-01 (Builds 7-17: game/data/appearances.json), by the sheet the player was
## drawn with (by the look's id only when no sheet is named); {} for any other sheet (a villager's child's, the
## old default), which stays drawn from that sheet.
static func from_legacy(look: String, sprite: String) -> Dictionary:
	if _looks.is_empty():
		_looks = JSON.parse_string(FileAccess.get_file_as_string(APPEARANCES_PATH)).looks
	for l in _looks:
		if (sprite != "" and l.sprite == sprite) or (sprite == "" and look != "" and l.id == look):
			return normalize(l.recipe)
	return {}


## The options character creation offers for a layer ("" = none) or swatch rows for a colour selection.
static func options(layer: String) -> Array:
	return (style().creation.picks.get(layer, []) as Array).map(func(o): return "" if o == null else str(o))


static func rows(selection: String) -> Array:
	return (style().creation.swatches.get(selection, []) as Array).map(func(r): return int(r))


## Set a colour selection and those linked to it (a beard takes the hair's colour).
static func set_swatch(recipe: Dictionary, selection: String, row: int) -> void:
	recipe.swatches[selection] = row
	var linked: Dictionary = style().creation.get("linked", {})
	for s in linked:
		if str(linked[s]) == selection:
			recipe.swatches[str(s)] = row


## A colour selection's swatch as one colour for a button (the ramp row's second shade: the main tone of skin,
## hair and cloth, the iris of an eye).
static func swatch_color(selection: String, row: int) -> Color:
	var r: Array = style().ramps[str(style().selections[selection])]
	var line: Array = r[clampi(row, 0, r.size() - 1)]
	return Color.html(str(line[mini(1, line.size() - 1)]))


## A random ordinary villager within what creation offers, with the generator's chances of "none" (hair as
## likely absent as any one style, eyelashes and boots half the time); a woman has no beard.
static func random_recipe(rng: RandomNumberGenerator, sex := "male") -> Dictionary:
	var picks := {}
	for layer in style().creation.picks:
		var opts := options(layer)
		var real := opts.filter(func(o): return o != "")
		var none_ok := opts.has("")
		var pick := ""
		if layer == "hair":
			pick = opts[rng.randi_range(0, opts.size() - 1)]
		elif layer == "facial-hair":
			pick = "" if sex == "female" or rng.randf() < 0.5 else real[rng.randi_range(0, real.size() - 1)]
		elif none_ok and rng.randf() < 0.5:
			pick = ""
		else:
			pick = real[rng.randi_range(0, real.size() - 1)]
		picks[layer] = pick
	var r := {"picks": picks, "swatches": {}}
	for sel in style().creation.swatches:
		var rs := rows(sel)
		r.swatches[sel] = rs[rng.randi_range(0, rs.size() - 1)]
	for s in style().creation.get("linked", {}):
		r.swatches[s] = r.swatches[str(style().creation.linked[s])]
	return r


## Forget composed sheets and read layers (tests measure from a cold start with it).
static func clear_cache() -> void:
	_cache.clear()
	_cache_order.clear()
	_sparse.clear()
