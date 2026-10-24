class_name NetWindow
extends RefCounted
## Build 21 (owner directive 2026-10-24, section 2): the windows that open a world to friends and join one on the same network,
## over the existing session (NetSession.host / join / stop, NetDiscovery, Main.host_game / stop_hosting / leave_guest_world).
## Compact windows in the game's own style (GameUI.compact), usable by touch, mouse, keyboard and pad.
##   Open to friends (the pause menu): this device's address and port, an optional password, who is playing, Stop hosting.
##   Join a game (the title screen): the games found on this network, the host's address typed by hand (which works when
##   discovery does not), the player's name (kept for next time), a password, the connection's progress and every refusal.

const GOLD := Color8(255, 217, 128)
const COLD := Color8(255, 178, 140)
const CONNECT_SECONDS := 20.0          # a join that has not been welcomed by then is given up (an unreachable address)


# ---------------------------------------------------------------- hosting ----------------------
static func show_host(ui: GameUI) -> void:
	var m = ui.main
	var net: NetSession = m.net
	ui._open("host", "Open to friends")
	ui.panel_back = ui.show_pause
	var addrs := NetDiscovery.lan_addresses()
	var where := "  or  ".join(addrs.map(func(a): return "%s" % a)) if not addrs.is_empty() else ""
	if net.is_host():
		ui._label("Your world is open to friends on this network. It keeps running while they play, and it stays yours: it is saved on this device.", 15)
		_address_row(ui, where, net.port)
		ui._label("Password: %s" % ("set (friends must type it)" if net.password != "" else "none"), 15)
		if not net.discovery.udp.is_bound():
			ui._label("Friends' games cannot find this one by themselves (port %d is in use): they join by typing the address." % net.discovery_port, 14, COLD)
		var who := ui._label("", 16, GOLD)
		who.name = "HostPlayers"
		_players_text(ui, who)
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		ui.panel_body.add_child(row)
		ui._button("Stop hosting", func():
			m.stop_hosting()
			ui.message("Your world is closed to friends. It carries on as your own.", 6.0)
			show_host(ui), true, row)
		ui._button("Back", ui.show_pause, true, row)
		_tick(ui, func(): _players_text(ui, who))
	else:
		ui._label("Friends on the same Wi-Fi or home network can join this world from their title screen (Join a game). It keeps running while they play, and it stays yours.", 15)
		if where == "":
			ui._label("This device has no network address: connect it to Wi-Fi or a network first.", 15, COLD)
		else:
			_address_row(ui, where, NetProtocol.GAME_PORT)
		var pw := _field(ui, "Password", "Optional", true)
		pw.name = "HostPassword"
		var err := ui._label("", 15, COLD)
		err.name = "HostError"
		err.visible = false
		var go := func(_t = ""):
			var why: String = m.host_game({"password": pw.text.strip_edges()})
			if why != "":
				err.text = why
				err.visible = true
				ui._fit_compact()
				return
			show_host(ui)
		pw.text_submitted.connect(go)
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		ui.panel_body.add_child(row)
		var open_btn := ui._button("Open to friends", go, where != "", row)
		open_btn.name = "HostOpen"
		ui._button("Back", ui.show_pause, true, row)
		ui._label("On Windows, allow My Medieval Life through the firewall on private networks (UDP ports %d and %d) when it asks." % [NetProtocol.GAME_PORT, NetProtocol.DISCOVERY_PORT], 13)
	ui.compact(560.0)


static func _address_row(ui: GameUI, where: String, port: int) -> void:
	var l := ui._label("Your address: %s   ·   port %d" % [where, port], 18, GOLD)
	l.name = "HostAddress"


static func _players_text(ui: GameUI, l: Label) -> void:
	var net: NetSession = ui.main.net
	if not is_instance_valid(l) or not net.is_host() or ui.panel_kind != "host":
		return
	var names: Array = net.player_names()
	l.text = "Playing: %d of %d  ·  %s" % [names.size(), net.max_players, ", ".join(names)] if names.size() > 1 else "Waiting for friends to join (up to %d players)." % net.max_players


# ---------------------------------------------------------------- joining ----------------------
static func show_join(ui: GameUI, status := "") -> void:
	var m = ui.main
	var net: NetSession = m.net
	var st: GameSettings = m.settings
	ui._open("join", "Join a game", false)
	var back := func():
		if net.is_guest():
			net.leave()
		net.discovery.close()
		ui.show_title(m.can_continue())
	ui.panel_back = back
	if not net.is_guest():
		net.discovery.look([])
	ui._label("Pick a friend's game on this network, or type the address their Open to friends screen shows.", 14)
	var found := VBoxContainer.new()
	found.name = "JoinFound"
	ui.panel_body.add_child(found)
	var who_row := HBoxContainer.new()               # compact: two fields a row, so it fits a phone's screen
	ui.panel_body.add_child(who_row)
	var name_edit := _field(ui, "Name", "Your character", false, who_row)
	name_edit.name = "JoinName"
	name_edit.max_length = 16
	name_edit.text = st.net_name
	var pw := _field(ui, "Password", "If it has one", true, who_row)
	pw.name = "JoinPassword"
	var row := HBoxContainer.new()
	ui.panel_body.add_child(row)
	var addr := _field(ui, "Address", "e.g. 192.168.1.20", false, row)
	addr.name = "JoinAddress"
	addr.text = st.net_address
	var join_btn := ui._button("Join", func(): pass, true, row)
	join_btn.name = "JoinGo"
	var cancel := ui._button("Cancel", func(): pass, true, row)
	cancel.name = "JoinCancel"
	ui._button("Back", back, true, row)
	var said := ui._label(status, 15, GOLD)
	said.name = "JoinStatus"
	said.visible = status != ""
	var started := [0.0]                 # when the current attempt began (ticks, seconds); 0 for none
	var tell := func(text: String, colour: Color) -> void:
		if not is_instance_valid(said):
			return
		said.text = text
		said.add_theme_color_override("font_color", colour)
		said.visible = text != ""
		ui._fit_compact()
	var busy := func(on: bool) -> void:
		join_btn.disabled = on
		cancel.visible = on
		ui._fit_compact()
	var go := func(_t = ""):
		var who := name_edit.text.strip_edges()
		var where := addr.text.strip_edges()
		if who == "":
			tell.call(NetSession.REFUSALS["name"], COLD)
			return
		var target := parse_address(where)
		if target.is_empty():
			tell.call("Type the host's address (shown on their Open to friends screen), or pick a game above." if where == "" else "\"%s\" is not an address on this network." % where, COLD)
			return
		st.net_name = who
		st.net_address = where
		st.save_file()
		var why: String = net.join(str(target.ip), int(target.port), NetProtocol.identity_key(), who, pw.text)
		if why != "":
			tell.call(why, COLD)
			return
		started[0] = Time.get_ticks_msec() / 1000.0
		busy.call(true)
		tell.call("Connecting to %s..." % where, GOLD)
	join_btn.pressed.connect(go)
	for e: LineEdit in [name_edit, addr, pw]:
		e.text_submitted.connect(go)
	cancel.pressed.connect(func():
		net.leave()
		started[0] = 0.0
		busy.call(false)
		net.discovery.look([])
		tell.call("Cancelled.", COLD))
	cancel.visible = false
	# what the session says (refusals, a lost connection) shows here while the window is open
	var on_changed := func(text: String) -> void:
		if ui.panel_kind != "join" or not is_instance_valid(said):
			return
		if not net.is_guest() and started[0] > 0.0:
			started[0] = 0.0
			busy.call(false)
			net.discovery.look([])
			tell.call(text, COLD)
		elif net.is_guest():
			tell.call(text, GOLD)
	net.changed.connect(on_changed)
	said.tree_exiting.connect(func(): if net.changed.is_connected(on_changed): net.changed.disconnect(on_changed))
	var pick := func(g: Dictionary) -> void:
		addr.text = str(g.ip) if int(g.port) == NetProtocol.GAME_PORT else "%s:%d" % [g.ip, int(g.port)]
		if bool(g.get("locked", false)) and pw.text == "":
			tell.call("%s needs a password." % str(g.get("world", "That game")), GOLD)
			pw.grab_focus()
			return
		go.call()
	var shown := [""]
	var refresh := func() -> void:
		if not is_instance_valid(found) or ui.panel_kind != "join":
			return
		if started[0] > 0.0 and not m.guest_world and Time.get_ticks_msec() / 1000.0 - started[0] > CONNECT_SECONDS:
			net.leave()
			started[0] = 0.0
			busy.call(false)
			net.discovery.look([])
			tell.call("Could not reach that game. Check the address, that both devices are on the same network, and that the host's firewall allows the game.", COLD)
		var games: Array = net.discovery.games() if not net.is_guest() else []
		var key := JSON.stringify(games.map(func(g): return [g.ip, g.port, g.name, g.world, g.players, g.max, g.locked, g.version]))
		if key == shown[0]:
			return
		shown[0] = key
		for c in found.get_children():
			found.remove_child(c)
			c.queue_free()
		if games.is_empty():
			var l := Label.new()
			l.text = "Looking for games on this network..." if not net.is_guest() else ""
			l.add_theme_font_size_override("font_size", 15)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			found.add_child(l)
		for g: Dictionary in games:
			var same: bool = str(g.version) == NetProtocol.full_version()
			var text := "%s  (%s, %d of %d%s)%s" % [str(g.world), str(g.name), int(g.players), int(g.max), ", password" if bool(g.locked) else "", "" if same else "  ·  a different version"]
			var b := ui._button(text, func(): pick.call(g), same and int(g.players) < int(g.max), found)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.clip_text = true
		ui._fit_compact()
	refresh.call()
	_tick(ui, refresh)
	ui.compact(600.0, m.settings.phone)


## A text field after its caption, sharing the row with the rest of `row` (a row of its own when none is given).
static func _field(ui: GameUI, caption: String, hint: String, secret: bool, row: HBoxContainer = null) -> LineEdit:
	var h := row
	if h == null:
		h = HBoxContainer.new()
		ui.panel_body.add_child(h)
	var l := Label.new()
	l.text = caption
	l.add_theme_font_size_override("font_size", 16)
	h.add_child(l)
	var e := LineEdit.new()
	e.placeholder_text = hint
	e.secret = secret
	e.custom_minimum_size = Vector2(0, 48)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.max_length = 64
	h.add_child(e)
	return e


## "192.168.1.20" or "192.168.1.20:47810" (or a host name): {ip, port}, {} when it is not an address.
static func parse_address(text: String) -> Dictionary:
	var t := text.strip_edges()
	if t == "":
		return {}
	var port := NetProtocol.GAME_PORT
	var parts := t.rsplit(":", true, 1)
	if parts.size() == 2 and not parts[0].contains(":"):
		if not parts[1].is_valid_int() or int(parts[1]) < 1 or int(parts[1]) > 65535:
			return {}
		t = parts[0]
		port = int(parts[1])
	if t.is_valid_ip_address():
		return {"ip": t, "port": port}
	if t.contains(" ") or t.contains("/"):
		return {}
	var ip := IP.resolve_hostname(t, IP.TYPE_IPV4)
	return {"ip": ip, "port": port} if ip != "" else {}


## Calls `f` once a second while this window is open (the timer goes with the window).
static func _tick(ui: GameUI, f: Callable) -> void:
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(f)
	ui.panel_body.add_child(t)
