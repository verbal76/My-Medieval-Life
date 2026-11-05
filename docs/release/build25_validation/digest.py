"""Extract DIGEST lines (recover job on wip/val-recover) from a saved job-log tool result. Usage: digest.py SAVED.txt OUT.json"""
import json, re, sys
raw = open(sys.argv[1]).read()
try: s = json.loads(raw)["logs_content"]
except Exception: s = raw
runs = []; cur = None
for l in s.split("\n"):
    l = re.sub(r"^\S+Z ", "", l)
    if l.startswith("DIGEST_RUN "): cur = {"run": json.loads(l[11:]), "samples": []}; runs.append(cur)
    elif l.startswith("DIGEST ") and cur: cur["samples"].append(json.loads(l[7:]))
json.dump(runs, open(sys.argv[2], "w"))
print(sys.argv[2], [(r["run"]["seed"], len(r["samples"])) for r in runs])
