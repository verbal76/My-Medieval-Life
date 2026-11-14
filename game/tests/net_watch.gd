extends RefCounted
## B42-NET-MP4-STALE (diagnostic, tests only): what a guest's network session did around each reconnection, sampled every frame of its
## process: the frame's length (a guest frame over NetSession.RESUME_AFTER_PAUSE_MS, outside the frame that built the world, makes it
## reconnect at once, KI-12), how long since it last heard the host's ND-26 heartbeat (host_heard; over TIMEOUT_MAX_MS it takes the
## host for gone), and its counters. `step(main)` once a frame; `log` the reconnections, `gaps` the long frames.

var log: Array = []        # [msec, cause, the frame's length, ms since the host was last heard (or -1), connected, silent losses, frames]
var gaps: Array = []       # [msec, length] of frames over 300 ms, the last 30
var _last := -1
var _was := false
var _heard_age := -1
var _losses := 0
var firsts: Array = []     # each time the guest began watching the host (after building the world): [msec, ms until the host's
                           # first heartbeat was heard (or "lost" with the age when it gave up), the longest frame of the 15 s before]
var _first_t := -1         # watching began, waiting for the first heartbeat
var _peak := 0


func step(main) -> void:
	var now := Time.get_ticks_msec()
	var gap := now - _last if _last >= 0 else 0
	_last = now
	if gap > 300:
		gaps.append([now, gap])
		gaps = gaps.slice(-30)
	var net: NetSession = main.net
	if net == null:
		return
	var rec: bool = net.reconnecting
	if rec and not _was:
		var cause := "host silent (ND-26)" if net.host_silent_losses > _losses else ("own long frame (KI-12)" if gap > NetSession.RESUME_AFTER_PAUSE_MS else "connection ended")
		log.append([now, cause, gap, _heard_age, net.connected(), net.host_silent_losses, Engine.get_process_frames()])
		log = log.slice(-12)
	_was = rec
	_losses = net.host_silent_losses
	var age := now - net.host_heard if net.host_heard >= 0 else -1
	if _heard_age < 0 and age >= 0:
		_first_t = now                               # watching began (zz_playing sent)
		_peak = age
	elif _first_t >= 0:
		if age < 0:
			firsts.append([_first_t, "lost at %d" % _peak, _longest(_first_t)])
			_first_t = -1
		elif age < _peak:
			firsts.append([_first_t, _peak, _longest(_first_t)])     # the first heartbeat reset the age
			_first_t = -1
		else:
			_peak = age
	firsts = firsts.slice(-12)
	_heard_age = age


func _longest(t: int) -> int:
	var m := 0
	for g in gaps:
		if int(g[0]) <= t + 50 and int(g[0]) >= t - 15000:
			m = maxi(m, int(g[1]))
	return m
