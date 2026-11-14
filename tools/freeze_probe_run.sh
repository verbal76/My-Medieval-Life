#!/bin/bash
# B42 (B25-MOVE-STUTTER-INV): one freeze_probe.gd walk with the machine's load recorded before and after.
#   tools/freeze_probe_run.sh NAME OUTDIR [probe args...]    e.g. ... south1 /dev/shm/out dir=south hops=3 seconds=330 stay=5
# Run from the repository root; godot on PATH. Writes OUTDIR/NAME.csv and OUTDIR/NAME.log.
N=$1; O=$2; shift 2
echo "load before: $(cat /proc/loadavg) commit $(git rev-parse --short HEAD) args $*" > "$O/$N.log"
S=$(date +%s)
timeout 1500 godot --headless --fixed-fps 60 --path game -s res://tests/freeze_probe.gd -- csv="$O/$N.csv" "$@" >> "$O/$N.log" 2>&1
echo "exit $? wall $(( $(date +%s)-S )) s; load after: $(cat /proc/loadavg)" >> "$O/$N.log"
