#!/bin/sh
# Rescan repos whose remote heads moved since their scan, render the registry for the repos done so far,
# commit to inventory/registry and push (never force). Usage: batch.sh "<this batch>" "<cumulative list>" "<message>"
set -e
INV=/tmp/claude-0/-home-user/754052d8-fb21-5c64-b3f9-641f462e2c23/scratchpad/inv
REG=$INV/reg
cd $INV
for r in $(echo "$1" | tr ',' ' '); do
  [ "$r" = "808-Beats" ] && continue
  moved=$(python3 -I - "$r" <<'EOF'
import json, subprocess, sys
r = sys.argv[1]; d = json.load(open(f'data/{r}.json'))
ls = subprocess.run(['git', '-C', d['clone'], 'ls-remote', '--heads', 'origin'], capture_output=True, text=True).stdout
now = {l.split('\t')[1][11:]: l.split('\t')[0] for l in ls.splitlines()}
old = {b['name']: b['sha'] for b in d['branches']}
print('yes' if now != old else 'no')
EOF
)
  if [ "$moved" = yes ]; then echo "rescan $r (heads moved)"; python3 -I tools/scan.py /home/user/inventory-src/$r $r data/$r.json; fi
done
python3 -I tools/render.py data tools/notes.json $REG "$2"
mkdir -p $REG/tools
cp tools/scan.py tools/render.py tools/notes.json tools/batch.sh $REG/tools/
cd $REG
git fetch -q origin inventory/registry
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/inventory/registry)" ]; then
  echo "remote moved; merging"; git merge --no-edit origin/inventory/registry
fi
git add -A
git commit -q -m "$3" -m "Read-only scan; nothing in any scanned repository was changed. Repos rendered so far: $2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Twyxni5CnEyE5LMG3EMiFY"
git push origin inventory/registry
git rev-parse HEAD
