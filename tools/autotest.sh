#!/usr/bin/env bash
# Plays levels headlessly with the autopilot. The autopilot is a greedy bot that occasionally
# gets stuck, so each level is played RUNS times (default 3) and must be won in a majority of them.
# Any script error fails immediately.
# Usage: [RUNS=n] tools/autotest.sh [level_index ...]
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-godot}"
RUNS="${RUNS:-3}"
levels=("$@")
[ ${#levels[@]} -eq 0 ] && levels=(0 1 2)
status=0
for l in "${levels[@]}"; do
	wins=0
	for ((i = 1; i <= RUNS; i++)); do
		out=$("$GODOT" --headless --path . --fixed-fps 60 -- --autotest="$l" 2>&1)
		if echo "$out" | grep -q "SCRIPT ERROR"; then
			echo "$out" | grep -A2 "SCRIPT ERROR" | head -20
			status=1
		fi
		result=$(echo "$out" | grep "AUTOTEST level=")
		echo "${result:-AUTOTEST level=$l produced no result}"
		echo "$result" | grep -q "won=true" && wins=$((wins + 1))
	done
	echo "level $l: won $wins/$RUNS"
	[ $((wins * 2)) -gt "$RUNS" ] || status=1
done
exit $status
