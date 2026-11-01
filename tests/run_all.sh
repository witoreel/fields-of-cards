#!/usr/bin/env bash
# Roda todas as verificações headless. Uso: tests/run_all.sh
cd "$(dirname "$0")/.." || exit 1
godot --headless --path . --import >/dev/null 2>&1
rc=0
for t in tests/check_*.gd; do
	[ "$t" = "tests/check_base.gd" ] && continue
	out=$(timeout 60 godot --headless --path . -s "$t" 2>&1); code=$?
	echo "$out" | grep -E "FALHOU|SCRIPT ERROR|concluídas" 
	[ $code -ne 0 ] && { echo "!! $t falhou (código $code)"; rc=1; }
done
exit $rc
