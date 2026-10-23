class_name GameAudio
extends Node
## MUSIC-18 and SFX-18 (owner directive 2026-10-23, docs/directives/2026-10-23_game_music.md): the game's music, the
## ambience loops and the sound effects. One node, owned by Main, driven by `update()` from Main's frame.
##
## - Music (game/data/music.json "slots"), first match wins: a fight plays "Fair Fight"; the countryside beyond the
##   village "Plain Sight"; below the surface "Misted Ancient"; else by time of day the title screen and the morning
##   play "Sunrise over the Village", the day "Prosperous Village", the evening and night "Misted Ancient".
##   A change of slot fades the old song out while the new one fades in; a song that ends is followed by a quiet gap,
##   then plays again. Played on the "Music" bus.
## - Ambience loops on the "SFX" bus: two layers at most, each crossfaded between two players of its own. The bed:
##   birds in the village by day (the Cozy forest in the countryside), crickets outdoors at night, cave wind in the
##   natural cave, drips in the mine gallery and the shafts below the cave. The accent: cicadas on summer days
##   outdoors, else wind in the countryside.
## - `play_sfx(id)`: a one-shot effect on the "SFX" bus, rate-limited per id, from a small pool of players. New effects
##   are added to game/data/music.json "sfx" and imported by tools/game_audio.py.
## - Windows and Linux carry the songs as WAV (loaded whole into memory: Godot cannot stream a WAV, so one song holds
##   40-90 MB while it plays, and a finished one is released), Android as Ogg Vorbis (streamed). The WAV is preferred when present.
##
## Audio only reads what is passed to `update()` (the hour, the level the player is on, whether the title is up). It
## never touches the world, its state or its random numbers, and without an audio device (or headless) it is silent
## and does nothing but keep its bookkeeping.

const DATA := "res://data/music.json"
const MUSIC_DIR := "res://assets/music/"
const SFX_DIR := "res://assets/sfx/"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## One fading voice: a player, the id it plays, how loud it is (0..1) and where that is heading.
class Voice:
	var player: AudioStreamPlayer
	var id := ""
	var level := 0.0
	var target := 0.0
	var base_db := 0.0

	func fade(dt: float, seconds: float) -> void:
		level = move_toward(level, target, dt / maxf(seconds, 0.01))
		player.volume_db = linear_to_db(maxf(level, 0.0001)) + base_db
		if level <= 0.0 and target <= 0.0 and player.playing:
			player.stop()
			player.stream = null            # a finished WAV is released

var cfg := {}
var active := true                  # false: nothing is loaded or played (headless, no audio device)
var music_voices: Array = []        # two voices, crossfaded
var amb_voices: Array = []
var music_id := ""                  # the song that should be playing ("" none)
var ambience_ids := ["", ""]        # the loops that should be playing, bed and accent ("" none)
var slot := ""                      # the slot the music follows: morning | day | night
var gap_left := 0.0                 # seconds of quiet before the next play
var _sfx_pool: Array = []
var _sfx_next := 0
var _last_ms := {}                  # effect id -> the time it last played
var _pending := ""                  # a WAV being loaded in the background (its path)
var _pending_id := ""
var _swing := 0                     # alternates the two sword swings (no random numbers)
var _hit := 0
var _rng := RandomNumberGenerator.new()   # this node's own random numbers (variants, pitch); never the world's
var _last_variant := {}
var played: Array = []              # the last effect ids played, newest last (kept short; the tests read it)


func _init() -> void:
	cfg = (JSON.parse_string(FileAccess.get_file_as_string(DATA)) as Dictionary) if FileAccess.file_exists(DATA) else {}
	active = DisplayServer.get_name() != "headless"


func _ready() -> void:
	GameSettings.ensure_buses()
	for i in 2:
		music_voices.append(_voice(MUSIC_BUS, 0.0))
	for layer in 2:
		amb_voices.append([_voice(SFX_BUS, -8.0), _voice(SFX_BUS, -8.0)])
	for i in int(cfg.get("sfx", {}).get("pool", 6)):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)


func _voice(bus: String, db: float) -> Voice:
	var v := Voice.new()
	v.player = AudioStreamPlayer.new()
	v.player.bus = bus
	add_child(v.player)
	v.base_db = db
	v.player.volume_db = -80.0
	return v


# ---------------------------------------------------------------- what plays when --------------------------
## What the audio is told each frame. Keys: hour (game hour), level (the depth the player is on), title (the title
## screen is up), fight (the player is in a fight), countryside (beyond the village map), summer.
static func ctx(c := {}) -> Dictionary:
	var out := {"hour": 12.0, "level": 0, "title": false, "fight": false, "countryside": false, "summer": false}
	out.merge(c, true)
	return out


## The music slot: "fight", "countryside", "morning", "day" or "night", first match of: the title screen (morning), a
## fight, the countryside, below the surface (night: the same song as the evening), then the hour. Hours come from the
## game's own day: the villagers wake at 6, the working day ends at 18.
static func slot_for(c: Dictionary, hours := {"morning": [6.0, 10.0], "day": [10.0, 18.0]}) -> String:
	c = ctx(c)
	if c.title:
		return "morning"
	if c.fight:
		return "fight"
	if c.countryside:
		return "countryside"
	if int(c.level) != 0:
		return "night"
	for s in ["morning", "day"]:
		if float(c.hour) >= float(hours[s][0]) and float(c.hour) < float(hours[s][1]):
			return s
	return "night"


## The two ambience layers [bed, accent] ("" none). Outdoors the bed is birds by day (the Cozy forest in the
## countryside) and crickets at night, the accent cicadas on a summer day, else wind in the countryside. Below the
## surface: cave wind in the natural cave (level -2), drips in the mine gallery (-1) and the shafts below the cave.
## Silence on the title screen.
static func ambience_for(c: Dictionary) -> Array:
	c = ctx(c)
	if c.title:
		return ["", ""]
	var level := int(c.level)
	if level != 0:
		return ["cave_wind" if level == -2 else "dungeon", ""]
	var day: bool = float(c.hour) >= 6.0 and float(c.hour) < 18.0
	var bed := ("forest" if c.countryside else "birds") if day else "crickets"
	var accent := "cicada" if (day and c.summer) else ("wind" if c.countryside else "")
	return [bed, accent]


func track_for_slot(s: String) -> String:
	return str(cfg.get("slots", {}).get(s, ""))


## The file a song plays from: its WAV when the package carries it (Windows, Linux), else its Ogg (Android, a checkout).
func music_path(id: String) -> String:
	var wav := MUSIC_DIR + id + ".wav"
	return wav if ResourceLoader.exists(wav) else MUSIC_DIR + id + ".ogg"


func sfx_path(id: String) -> String:
	return SFX_DIR + id + ".ogg"


## Each frame, from Main, with `ctx()`'s keys.
func update(dt: float, c: Dictionary) -> void:
	slot = slot_for(c, _hours())
	_set_music(track_for_slot(slot))
	var layers := ambience_for(c)
	for i in 2:
		_set_ambience(i, str(layers[i]))
	if not active or music_voices.is_empty():
		return
	_poll_load()
	var fade := float(cfg.get("fight_fade_seconds", 1.5)) if slot == "fight" else float(cfg.get("fade_seconds", 3.0))
	for v: Voice in music_voices:
		v.fade(dt, fade)
	for layer: Array in amb_voices:
		for v: Voice in layer:
			v.fade(dt, float(cfg.get("ambience", {}).get("fade_seconds", 2.5)))
	# a song that has ended is followed by a quiet gap, then plays again
	var cur: Voice = _current(music_voices)
	if music_id != "" and cur != null and cur.id == music_id and cur.target > 0.0 and not cur.player.playing and _pending == "":
		cur.id = ""
		cur.target = 0.0
		gap_left = float(cfg.get("gap_seconds", 6.0))
	if gap_left > 0.0:
		gap_left = maxf(0.0, gap_left - dt)
	if music_id != "" and gap_left <= 0.0 and (cur == null or cur.id != music_id) and _pending == "":
		_start_music(music_id)


func _hours() -> Dictionary:
	return cfg.get("slot_hours", {"morning": [6.0, 10.0], "day": [10.0, 18.0]})


func _current(voices: Array) -> Voice:
	for v: Voice in voices:
		if v.target > 0.0:
			return v
	return null


## The quieter of two voices: the one to start the next sound on (the other may still be fading out).
func _free_voice(voices: Array) -> Voice:
	return voices[0] if (voices[0] as Voice).level <= (voices[1] as Voice).level else voices[1]


func _set_music(id: String) -> void:
	if id == music_id:
		return
	music_id = id
	if _pending != "" and _pending_id != id:
		_pending = ""                       # the slot moved on while a song was loading
	var cur: Voice = _current(music_voices)
	if cur != null and cur.id != id:
		cur.target = 0.0                    # the old song fades out as the new one comes in


func _start_music(id: String) -> void:
	var path := music_path(id)
	if not ResourceLoader.exists(path):
		return
	if path.ends_with(".wav"):
		_pending = path                     # a long WAV loads in the background
		_pending_id = id
		ResourceLoader.load_threaded_request(path)
		return
	_play_music(id, load(path))


func _poll_load() -> void:
	if _pending == "":
		return
	var st := ResourceLoader.load_threaded_get_status(_pending)
	if st == ResourceLoader.THREAD_LOAD_LOADED:
		var res := ResourceLoader.load_threaded_get(_pending)
		var id := _pending_id
		_pending = ""
		if id == music_id:
			_play_music(id, res)
	elif st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_pending = ""


func _play_music(id: String, stream: Resource) -> void:
	if stream == null:
		return
	var next := _free_voice(music_voices)
	for v: Voice in music_voices:
		if v != next:
			v.target = 0.0
	next.id = id
	next.player.stream = stream as AudioStream
	next.level = 0.0
	next.target = 1.0
	next.player.play()


func _set_ambience(layer: int, id: String) -> void:
	if id == ambience_ids[layer]:
		return
	ambience_ids[layer] = id
	if not active or amb_voices.is_empty():
		return
	var voices: Array = amb_voices[layer]
	var cur: Voice = _current(voices)
	if cur != null:
		cur.target = 0.0
	if id == "":
		return
	var path := SFX_DIR + id + ".ogg"
	if not ResourceLoader.exists(path):
		return
	var next := _free_voice(voices)         # two players a layer, ever
	var s := load(path) as AudioStreamOggVorbis
	if s == null:
		return
	s.loop = true
	next.id = id
	next.base_db = float(cfg.get("ambience", {}).get("db_by_id", {}).get(id, -8.0))
	next.player.stream = s
	next.level = 0.0
	next.target = 1.0
	next.player.play()


# ---------------------------------------------------------------- one-shot effects -------------------------
## Play the effect `id` once on the SFX bus. At most once per its gap (music.json sfx gaps_ms, by the effect's base
## name) so a repeated event never machine-guns, and never more than the pool at once. `db` and `pitch` shape one play.
## `now_ms` is for tests. True when it played.
func play_sfx(id: String, now_ms := -1, db := 0.0, pitch := 1.0, gap_ms := -1) -> bool:
	var t: int = now_ms if now_ms >= 0 else Time.get_ticks_msec()
	var sfx: Dictionary = cfg.get("sfx", {})
	var key := _base(id)
	var gap: int = gap_ms if gap_ms >= 0 else int(sfx.get("gaps_ms", {}).get(key, sfx.get("default_gap_ms", 150)))
	if _last_ms.has(key) and t - int(_last_ms[key]) < gap:
		return false
	if not (id in sfx.get("ids", [])) or not ResourceLoader.exists(sfx_path(id)):
		return false
	_last_ms[key] = t
	played.append(id)
	if played.size() > 16:
		played.pop_front()
	if not active or _sfx_pool.is_empty():
		return true
	var p: AudioStreamPlayer = _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	p.stream = load(sfx_path(id)) as AudioStream
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()
	return true


## "hit_on_wood_2" -> "hit_on_wood" when that is an effect with variants; any other id is its own base.
func _base(id: String) -> String:
	var i := id.rfind("_")
	if i > 0 and id.substr(i + 1).is_valid_int() and cfg.get("sfx", {}).get("variants", {}).has(id.substr(0, i)):
		return id.substr(0, i)
	return id


## An effect with variants ("bush_rustling" has _1 to _3): one of them, never the one it played last. The choice
## uses this node's own random numbers (never the world's).
func play_variant(base: String, now_ms := -1, db := 0.0, pitch_spread := 0.0, gap_ms := -1) -> bool:
	var n := int(cfg.get("sfx", {}).get("variants", {}).get(base, 0))
	if n <= 0:
		return play_sfx(base, now_ms, db)
	var pick := _rng.randi_range(1, n)
	if n > 1 and pick == int(_last_variant.get(base, 0)):
		pick = pick % n + 1
	var pitch := 1.0 + _rng.randf_range(-pitch_spread, pitch_spread)
	if play_sfx("%s_%d" % [base, pick], now_ms, db, pitch, gap_ms):
		_last_variant[base] = pick
		return true
	return false


## A footstep on `ground` (grass | dirt | stone), soft: its level, pitch spread and minimum gap are music.json's
## sfx steps. The caller spaces them by distance walked (`stride_cells`).
func step(ground: String, now_ms := -1) -> bool:
	var st: Dictionary = cfg.get("sfx", {}).get("steps", {})
	return play_variant("step_" + ground, now_ms, float(st.get("db", -16.0)), float(st.get("pitch_spread", 0.05)), int(st.get("min_gap_ms", 260)))


## The sword swing sound, the two alternating.
func swing() -> void:
	_swing += 1
	play_sfx("sword_swing_%d" % (1 + _swing % 2))


## A blow that landed: the sword, or the telling blow's own sound.
func hit(crit: bool) -> void:
	if crit:
		play_sfx("critical_hit")
		return
	_hit += 1
	play_sfx("sword_hit_%d" % (1 + _hit % 2))
