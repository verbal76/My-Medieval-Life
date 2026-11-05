extends SceneTree
## Multiplayer Batch D test guest (net_fault_test.gd): the real game joining a host and staying, so the test can kill it, freeze it
## or let it reconnect. Writes <dir><out> every 0.2 s: {welcomed, pid, guest_world, reconnecting, reconnects, refusal}.
## Args after "--": port key name password out_file dir [stall_ms: B25R1, the frame it is welcomed in lasts this much longer,
## as a slow device's building of the host's world does (main.start_guest_world), once].

var main
var a: PackedStringArray
var t := 0.0
var stall_ms := 0


func _init() -> void:
	a = OS.get_cmdline_user_args()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = str(a[5]) + "fault_guest_unused.json"
	stall_ms = int(a[6]) if a.size() > 6 else 0
	process_frame.connect(func():
		main.net.changed.connect(_stall)
		main.net.join("127.0.0.1", int(a[0]), str(a[1]), str(a[2]), str(a[3])), CONNECT_ONE_SHOT)


func _stall(text: String) -> void:
	if stall_ms > 0 and text.begins_with("Joined"):  # emitted at the end of s_welcome, in the frame the world was built
		OS.delay_msec(stall_ms)
		stall_ms = 0


func _process(delta: float) -> bool:
	t += delta
	if t < 0.2:
		return false
	t = 0.0
	var net: NetSession = main.net
	var f := FileAccess.open(str(a[5]) + str(a[4]), FileAccess.WRITE)
	f.store_string(JSON.stringify({"welcomed": main.guest_world, "pid": net.my_pid, "guest_world": main.guest_world,
		"reconnecting": net.reconnecting, "reconnects": net.reconnects, "refusal": net.refusal, "os_pid": OS.get_process_id()}))
	f.close()
	return false
