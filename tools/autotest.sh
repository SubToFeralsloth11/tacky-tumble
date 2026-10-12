#!/usr/bin/env bash
# Plays every level headlessly with the autopilot and fails if any level can't be won.
# Usage: tools/autotest.sh [level_index ...]
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-godot}"
levels=("$@")
[ ${#levels[@]} -eq 0 ] && levels=(0 1 2)
status=0
for l in "${levels[@]}"; do
	out=$("$GODOT" --headless --path . --fixed-fps 60 -- --autotest="$l" 2>&1)
	code=$?
	echo "$out" | grep -E "SCRIPT ERROR|^ERROR" | sort -u
	result=$(echo "$out" | grep "AUTOTEST level=")
	echo "${result:-AUTOTEST level=$l produced no result (exit $code)}"
	if [ $code -ne 0 ] || [ -z "$result" ] || echo "$out" | grep -q "SCRIPT ERROR"; then
		status=1
	fi
done
exit $status
