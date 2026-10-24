"""Independent check of a flight recorder archive (REC-19, schema mml-recorder/2; SIM-GATE-01).

The game writes the archive (game/scripts/core/recorder/); this module reads it with nothing but the standard library and
says whether it is whole and consistent, so the simulation gate never trusts the writer's own word:

  - session.json exists, names the schema, ended, completeness "complete", no unknown codes, nothing recovered;
  - every chunk is a gzip file with a header, one JSON array per row of the header's width, and a footer whose row count
    and sha256 (of the row lines, each followed by "\\n") match;
  - the row sequence numbers of all tables together are exactly 1..last_seq, each once (nothing lost, nothing doubled);
  - each table's row count equals the session's own count;
  - the hourly snapshots (table "snapshot") follow one another an hour apart.

It also returns the facts the gate reconciles with the simulation's own output: the last snapshot, alert counts by rule,
villager deaths, births and newcomers, and accepted trades.

    python3 tools/recorder_archive.py ARCHIVE_SESSION_DIR      # prints the report; exit 1 if the archive is not valid
"""
import glob
import gzip
import hashlib
import json
import os
import sys

SCHEMA = "mml-recorder/2"
TABLES = ["event", "participant", "decision", "alternative", "factor", "state_change", "link", "alert", "sample", "snapshot"]


def read_chunk(path):
    """(header, rows, problem) for one chunk; problem is "" when it is whole."""
    try:
        with gzip.open(path, "rt", encoding="utf-8") as f:
            lines = f.read().split("\n")
    except (OSError, EOFError, UnicodeDecodeError) as e:
        return None, [], "unreadable (%s)" % e
    lines = [l for l in lines if l != ""]
    if not lines:
        return None, [], "empty"
    try:
        head = json.loads(lines[0])
    except ValueError:
        return None, [], "header is not JSON"
    if not isinstance(head, dict) or "columns" not in head:
        return None, [], "no header"
    rows, h = [], hashlib.sha256()
    footer = None
    for line in lines[1:]:
        try:
            v = json.loads(line)
        except ValueError:
            return head, rows, "a torn line"
        if isinstance(v, dict) and v.get("footer"):
            footer = v
            break
        if not isinstance(v, list):
            return head, rows, "a row that is not an array"
        rows.append(v)
        h.update((line + "\n").encode("utf-8"))
    if footer is None:
        return head, rows, "no footer (truncated)"
    if footer.get("rows") != len(rows) or footer.get("sha256") != h.hexdigest():
        return head, rows, "footer does not match the rows"
    width = len(head["columns"])
    if any(len(r) != width for r in rows):
        return head, rows, "a row of the wrong width"
    if rows and (rows[0][0] != head.get("first_seq") or rows[-1][0] != head.get("last_seq")):
        return head, rows, "first_seq/last_seq do not match the rows"
    return head, rows, ""


def verify(session_dir):
    """Check a session directory. Returns a report dict with "ok" and "problems"."""
    rep = {"dir": session_dir, "ok": False, "problems": [], "chunks": 0, "bytes": 0, "counts": {}, "snapshot_hours": 0,
           "alerts": {}, "villager_deaths": 0, "births": 0, "newcomers": 0, "trades": 0, "last_snapshot": None,
           "first_snapshot": None, "events": {}}
    sp = os.path.join(session_dir, "session.json")
    try:
        sess = json.load(open(sp))
    except (OSError, ValueError):
        rep["problems"].append("session.json missing or not JSON")
        return rep
    rep["session"] = {k: sess.get(k) for k in ("schema", "session", "completeness", "ended", "seed", "commit", "bytes", "chunk_count", "last_seq", "flags")}
    if sess.get("schema") != SCHEMA:
        rep["problems"].append("schema %r, expected %r" % (sess.get("schema"), SCHEMA))
    if not sess.get("ended"):
        rep["problems"].append("the session never ended (the recording was cut off)")
    if sess.get("completeness") != "complete":
        rep["problems"].append("completeness: %s" % sess.get("completeness"))
    if sess.get("unknown_codes"):
        rep["problems"].append("unknown codes: %s" % sess.get("unknown_codes"))
    if sess.get("recovered"):
        rep["problems"].append("recovered chunks of an earlier session: %d" % len(sess.get("recovered")))
    last_seq = int(sess.get("last_seq", 0))
    seen = bytearray(last_seq + 1)
    dup = out_of_range = 0
    snaps = []
    files = sorted(glob.glob(os.path.join(session_dir, "d*", "*.jsonl.gz")))
    for path in files:
        rep["chunks"] += 1
        rep["bytes"] += os.path.getsize(path)
        head, rows, problem = read_chunk(path)
        rel = os.path.relpath(path, session_dir)
        if problem:
            rep["problems"].append("%s: %s" % (rel, problem))
            continue
        table = head.get("table")
        if head.get("schema") != SCHEMA or table not in TABLES:
            rep["problems"].append("%s: header schema %r table %r" % (rel, head.get("schema"), table))
            continue
        rep["counts"][table] = rep["counts"].get(table, 0) + len(rows)
        cols = head["columns"]
        for r in rows:
            s = r[0]
            if not isinstance(s, int) or s < 1 or s > last_seq:
                out_of_range += 1
            elif seen[s]:
                dup += 1
            else:
                seen[s] = 1
        if table == "snapshot":
            snaps.extend(dict(zip(cols, r)) for r in rows)
        elif table == "alert":
            i = cols.index("rule")
            for r in rows:
                rep["alerts"][r[i]] = rep["alerts"].get(r[i], 0) + 1
        elif table == "event":
            ci, si, oi, di = cols.index("category"), cols.index("subtype"), cols.index("outcome"), cols.index("detail")
            for r in rows:
                key = "%s|%s|%s" % (r[ci], r[si], r[oi])
                rep["events"][key] = rep["events"].get(key, 0) + 1
                if r[ci] == "life" and r[si] == "death" and "role=" in str(r[di]) and "role=bandit" not in str(r[di]):
                    rep["villager_deaths"] += 1
                elif r[ci] == "life" and r[si] == "birth":
                    rep["births"] += 1
                elif r[ci] == "identity" and r[si] in ("registered_newcomer", "registered_outlaw", "registered_arrival"):
                    rep["newcomers"] += 1
                elif r[ci] == "transaction" and r[si] == "trade" and r[oi] == "ok":
                    rep["trades"] += 1
    missing = last_seq - sum(seen[1:]) if last_seq else 0
    if missing or dup or out_of_range:
        rep["problems"].append("row sequence: %d missing, %d doubled, %d out of range (of %d)" % (missing, dup, out_of_range, last_seq))
    for t, n in (sess.get("counts") or {}).items():
        if rep["counts"].get(t, 0) != n:
            rep["problems"].append("table %s: %d rows on disk, the session counted %d" % (t, rep["counts"].get(t, 0), n))
    snaps.sort(key=lambda s: s["seq"])
    rep["snapshot_hours"] = len(snaps)
    if not snaps:
        rep["problems"].append("no hourly snapshot (schema 2 requires one an hour)")
    for a, b in zip(snaps, snaps[1:]):
        if (b["day"] * 24 + b["hour"]) - (a["day"] * 24 + a["hour"]) != 1:
            rep["problems"].append("snapshots not an hour apart: day %s hour %s -> day %s hour %s" % (a["day"], a["hour"], b["day"], b["hour"]))
            break
    if snaps:
        rep["first_snapshot"] = {k: v for k, v in snaps[0].items() if k != "stats_delta"}
        rep["last_snapshot"] = {k: v for k, v in snaps[-1].items() if k != "stats_delta"}
    rep["ok"] = not rep["problems"]
    return rep


def session_dirs(root):
    """The session directories under a recorder root (one per run in the gate)."""
    return sorted(d for d in glob.glob(os.path.join(root, "s*")) if os.path.isdir(d))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    r = verify(sys.argv[1])
    print(json.dumps({k: v for k, v in r.items() if k != "events"}, indent=1, sort_keys=True))
    sys.exit(0 if r["ok"] else 1)
