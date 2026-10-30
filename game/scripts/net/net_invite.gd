class_name NetInvite
extends RefCounted
## Multiplayer Batch D (docs/multiplayer/BATCH_D_CONNECTIVITY.md): the invite code a host shares and a guest pastes. It holds the game's
## port, a tag of the world (so a code is not taken for another game at the same address) and the host's addresses that can actually
## work, each marked with its kind: "lan" (a private network address: friends on the same network), "v6" (a global IPv6 address: may
## work when both have IPv6 and no firewall stops it) and "public" (the router's public IPv4 address, put in only when the router
## accepted the automatic port mapping, NetUpnp). It never holds an address that cannot be reached from outside under an internet
## kind. A checksum catches typing mistakes. Free: no server reads or relays it.
##
## Bytes: version (1), port (2), tag (4), then per address a type byte (4 or 6, + 0x10 when it is the public mapped one) and its
## 4 or 16 bytes, then 2 bytes of checksum (the start of the SHA-256 of what came before). Written in Crockford's base 32 (no I, L, O,
## U: nothing to misread), in groups of five after "MML-"; read back ignoring case, spaces and dashes, O as 0 and I or L as 1.

const PREFIX := "MML"
const CODE_VERSION := 1
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const MAX_LAN := 2
const PUBLIC_FLAG := 0x10
## The order a guest tries the kinds in, and how long each attempt may take before the next (seconds).
const ORDER := ["loopback", "lan", "v6", "public"]
const ATTEMPT_SECONDS := {"loopback": 4.0, "lan": 4.0, "v6": 6.0, "public": 8.0, "direct": 12.0}


## The code for these addresses ({ip, kind}), the port and the world's tag (8 hex characters). Addresses beyond what fits a short code
## are left out (two LAN, one IPv6, one public).
static func make(addresses: Array, port: int, tag: String) -> String:
	var b := PackedByteArray([CODE_VERSION, (port >> 8) & 0xff, port & 0xff])
	var t := tag.left(8).rpad(8, "0")
	b.append_array(t.hex_decode())
	var n := {"lan": 0, "loopback": 0, "v6": 0, "public": 0}
	for a in addresses:
		var ip := str(a.ip)
		var kind := str(a.get("kind", classify(ip)))
		if not n.has(kind) or int(n[kind]) >= (MAX_LAN if kind in ["lan", "loopback"] else 1):
			continue
		var raw := _ip_bytes(ip)
		if raw.is_empty():
			continue
		n[kind] = int(n[kind]) + 1
		b.append((4 if raw.size() == 4 else 6) | (PUBLIC_FLAG if kind == "public" else 0))
		b.append_array(raw)
	b.append_array(_check(b))
	var s := _b32(b)
	var groups := []
	for i in range(0, s.length(), 5):
		groups.append(s.substr(i, 5))
	return PREFIX + "-" + "-".join(groups)


## {ok, port, tag, addresses: [{ip, kind}] in the order to try, error}. A pasted text with words around the code is fine.
static func parse(text: String) -> Dictionary:
	var t := text.strip_edges().to_upper()
	var at := t.find(PREFIX + "-")
	if at < 0:
		return {"ok": false, "error": "not_code"}
	t = t.substr(at + PREFIX.length() + 1)
	var clean := ""
	for ch in t:
		if ch == "-" or ch == " ":
			continue
		var c := ch
		if c == "O":
			c = "0"
		elif c == "I" or c == "L":
			c = "1"
		if not ALPHABET.contains(c):
			break
		clean += c
	var b := _unb32(clean)
	if b.size() < 9:
		return {"ok": false, "error": "short"}
	var body := b.slice(0, b.size() - 2)
	if _check(body) != b.slice(b.size() - 2):
		return {"ok": false, "error": "typo"}
	if int(body[0]) != CODE_VERSION:
		return {"ok": false, "error": "version"}
	var port := (int(body[1]) << 8) | int(body[2])
	var tag := body.slice(3, 7).hex_encode()
	var out := []
	var i := 7
	while i < body.size():
		var ty := int(body[i])
		var nb := 4 if ty & 0x0f == 4 else (16 if ty & 0x0f == 6 else 0)
		if nb == 0 or i + 1 + nb > body.size():
			return {"ok": false, "error": "typo"}
		var ip := _ip_text(body.slice(i + 1, i + 1 + nb))
		var kind := "public" if ty & PUBLIC_FLAG else classify(ip)
		out.append({"ip": ip, "kind": kind, "port": port})
		i += 1 + nb
	if port < 1 or out.is_empty():
		return {"ok": false, "error": "typo"}
	out.sort_custom(func(x, y): return ORDER.find(str(x.kind)) < ORDER.find(str(y.kind)))
	return {"ok": true, "port": port, "tag": tag, "addresses": out, "error": ""}


## A world's tag: the same for every hosting of one world (seed and the host's character), so a code made yesterday still names it.
static func world_tag(seed: int, host_pid: int) -> String:
	return ("%d:%d" % [seed, host_pid]).sha256_text().left(8)


## What an address is, for joining: "loopback", "lan" (private IPv4, IPv6 unique-local), "cgnat" (100.64.0.0/10: the provider's
## shared address, unreachable from outside), "link" (link-local: useless), "v6" (global IPv6), "public" (a public IPv4), "" (not one).
static func classify(ip: String) -> String:
	if not ip.is_valid_ip_address():
		return ""
	if ip.contains(":"):
		var l := ip.to_lower()
		if l == "::1":
			return "loopback"
		if l.begins_with("fe8") or l.begins_with("fe9") or l.begins_with("fea") or l.begins_with("feb"):
			return "link"
		if l.begins_with("fc") or l.begins_with("fd"):
			return "lan"
		if l.begins_with("2") or l.begins_with("3"):
			return "v6"
		return ""
	var p := ip.split(".")
	var a := int(p[0])
	var b := int(p[1])
	if a == 127:
		return "loopback"
	if a == 10 or (a == 172 and b >= 16 and b <= 31) or (a == 192 and b == 168):
		return "lan"
	if a == 100 and b >= 64 and b <= 127:
		return "cgnat"
	if a == 169 and b == 254:
		return "link"
	if a == 0 or a >= 224:
		return ""
	return "public"


## This device's global IPv6 addresses (may be reachable from outside), sorted.
static func v6_addresses() -> Array:
	var out := []
	for a: String in IP.get_local_addresses():
		var bare := a.split("%")[0]
		if classify(bare) == "v6":
			out.append(bare)
	out.sort()
	return out


static func _check(b: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(b)
	return ctx.finish().slice(0, 2)


static func _ip_bytes(ip: String) -> PackedByteArray:
	if not ip.is_valid_ip_address():
		return PackedByteArray()
	if not ip.contains(":"):
		var out := PackedByteArray()
		for part in ip.split("."):
			out.append(int(part))
		return out
	# IPv6: expand "::"
	var halves := ip.to_lower().split("::")
	var head: PackedStringArray = halves[0].split(":", false) if halves[0] != "" else PackedStringArray()
	var tail: PackedStringArray = halves[1].split(":", false) if halves.size() > 1 and halves[1] != "" else PackedStringArray()
	var words := []
	for h in head:
		words.append(h.hex_to_int())
	for _i in range(8 - head.size() - tail.size()):
		words.append(0)
	for h in tail:
		words.append(h.hex_to_int())
	if words.size() != 8:
		return PackedByteArray()
	var out6 := PackedByteArray()
	for w in words:
		out6.append((int(w) >> 8) & 0xff)
		out6.append(int(w) & 0xff)
	return out6


static func _ip_text(b: PackedByteArray) -> String:
	if b.size() == 4:
		return "%d.%d.%d.%d" % [b[0], b[1], b[2], b[3]]
	var parts := []
	for i in range(0, 16, 2):
		parts.append("%x" % ((int(b[i]) << 8) | int(b[i + 1])))
	return ":".join(parts)


static func _b32(b: PackedByteArray) -> String:
	var out := ""
	var buf := 0
	var bits := 0
	for v in b:
		buf = (buf << 8) | int(v)
		bits += 8
		while bits >= 5:
			bits -= 5
			out += ALPHABET[(buf >> bits) & 31]
		buf &= (1 << bits) - 1
	if bits > 0:
		out += ALPHABET[(buf << (5 - bits)) & 31]
	return out


static func _unb32(s: String) -> PackedByteArray:
	var out := PackedByteArray()
	var buf := 0
	var bits := 0
	for ch in s:
		buf = (buf << 5) | ALPHABET.find(ch)
		bits += 5
		if bits >= 8:
			bits -= 8
			out.append((buf >> bits) & 0xff)
			buf &= (1 << bits) - 1
	return out
