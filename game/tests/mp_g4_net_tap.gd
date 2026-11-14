extends NetSession
## Build 42 G4 (tests/mp_g4_loopback_test.gd): the guest's own network session with a tap on what the host sends it. Every welcome
## (s_welcome) and section sync (s_sync) is kept as the text that came over the wire (decompressed), then handled exactly as the game
## does (NetSession's own method). Test code only: the game never uses it.

var wire_welcomes: Array = []      # the JSON text of each welcome, as received
var wire_syncs: Array = []         # the JSON text of each section sync, as received


@rpc("authority", "call_remote", "reliable")
func s_welcome(blob: PackedByteArray, id: int) -> void:
	wire_welcomes.append(blob.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	super.s_welcome(blob, id)


@rpc("authority", "call_remote", "reliable")
func s_sync(blob: PackedByteArray) -> void:
	wire_syncs.append(blob.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	super.s_sync(blob)
