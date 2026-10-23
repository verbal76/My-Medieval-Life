class_name RecorderArchive
extends RefCounted
## Reads and writes the flight recorder's chunk files (schema mml-recorder/1). A chunk is a gzip text file of JSON lines:
## line 1 the header {schema, session, table, day, hour, part, columns, first_seq, last_seq}, then one JSON array per row
## (columns in header order, `seq` first), then the footer {"footer": true, "rows": N, "sha256": "<hash of the row lines>"}.
## A chunk without its footer (or whose rows do not match it) is truncated: reported, never deleted.
## How to read an archive: docs/design/FLIGHT_RECORDER.md.


## Write one chunk: header, rows, footer, as one standard gzip file (PackedByteArray.compress, so any gzip tool reads it;
## FileAccess.open_compressed would write Godot's own container, which nothing else can open). Returns the size in bytes.
## `with_footer` false writes a torn chunk (tests only).
static func write_chunk(path: String, header: Dictionary, rows: Array, with_footer := true) -> int:
	var lines := PackedStringArray([JSON.stringify(header)])
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	var body := PackedStringArray()
	for r in rows:
		body.append(JSON.stringify(r))
	var text := "\n".join(body)
	if not body.is_empty():
		text += "\n"
	hc.update(text.to_utf8_buffer())
	if not body.is_empty():
		lines.append(text.trim_suffix("\n"))
	if with_footer:
		lines.append(JSON.stringify({"footer": true, "rows": rows.size(), "sha256": hc.finish().hex_encode()}))
	var gz := ("\n".join(lines) + "\n").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return 0
	f.store_buffer(gz)
	f.close()
	return gz.size()


## Read one chunk: {ok, header, rows (Arrays), footer, truncated, state}. state: "complete", "no_footer", "unreadable",
## "mismatch" (rows or checksum differ from the footer).
static func read_chunk(path: String) -> Dictionary:
	var out := {"ok": false, "header": {}, "rows": [], "footer": {}, "truncated": true, "state": "unreadable"}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var raw := f.get_buffer(f.get_length())
	f.close()
	var plain := raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP) if raw.size() > 0 else PackedByteArray()
	if plain.is_empty():
		return out
	var lines := plain.get_string_from_utf8().split("\n")
	var head = JSON.parse_string(lines[0])
	if not (head is Dictionary):
		return out
	out.header = head
	out.state = "no_footer"
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	for i in range(1, lines.size()):
		var line := lines[i]
		if line == "":
			continue
		var v = JSON.parse_string(line)
		if v is Dictionary and bool(v.get("footer", false)):
			out.footer = v
			if int(v.rows) == (out.rows as Array).size() and str(v.sha256) == hc.finish().hex_encode():
				out.state = "complete"
				out.truncated = false
				out.ok = true
			else:
				out.state = "mismatch"
			break
		if v is Array:
			(out.rows as Array).append(v)
			hc.update((line + "\n").to_utf8_buffer())
		else:
			break                                   # a torn last line: the rest is not trusted
	return out


## Every chunk file under a session directory (absolute path), sorted.
static func chunk_files(session_dir: String) -> Array:
	var out := []
	for d in DirAccess.get_directories_at(session_dir):
		for fn in DirAccess.get_files_at(session_dir + "/" + d):
			if fn.ends_with(".jsonl.gz"):
				out.append(d + "/" + fn)
	out.sort()
	return out


## Check a session directory: {ok: chunks complete, truncated: [{file, state}], rows: {table: count in complete chunks}}.
static func scan_session(session_dir: String) -> Dictionary:
	var res := {"ok": 0, "truncated": [], "rows": {}}
	for rel in chunk_files(session_dir):
		var c := read_chunk(session_dir + "/" + rel)
		if c.ok:
			res.ok += 1
			var t := str(c.header.table)
			res.rows[t] = int(res.rows.get(t, 0)) + (c.rows as Array).size()
		else:
			res.truncated.append({"file": rel, "state": c.state})
	return res


## All rows of one table across a session's complete chunks, as Dictionaries keyed by column name, in sequence order.
static func read_table(session_dir: String, table: String) -> Array:
	var out := []
	for rel in chunk_files(session_dir):
		if not rel.get_file().begins_with(table + "."):
			continue
		var c := read_chunk(session_dir + "/" + rel)
		if not c.ok:
			continue
		var cols: Array = c.header.columns
		for r in c.rows:
			var d := {}
			for i in cols.size():
				d[cols[i]] = r[i]
			out.append(d)
	out.sort_custom(func(a, b): return int(a.seq) < int(b.seq))
	return out


static func read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f != null else null
