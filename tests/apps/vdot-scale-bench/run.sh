#!/usr/bin/env bash
set -euo pipefail
app_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$app_dir/../../.." && pwd)
source "$project_root/env.sh"
cd "$project_root"
if [ "$#" -eq 0 ]; then
  set -- m2 m4 m8 large
fi
for name in "$@"; do
    case "$name" in
      m2) lmul=2; blocks=64 ;;
      m4) lmul=4; blocks=64 ;;
      m8) lmul=8; blocks=64 ;;
      large) lmul=8; blocks=512 ;;
      *) echo "Unknown case: $name" >&2; exit 1 ;;
    esac
    logs="$project_root/vdot-docs/logs"
    results="$project_root/vdot-docs/stage3/scale/$name"
    mkdir -p "$logs" "$results"
    make -C "$app_dir" ARCH=riscv64-xs LMUL="$lmul" BLOCKS="$blocks" REPEATS=2 disasm \
      > "$logs/scale-$name-build.log" 2>&1
    "$NOOP_HOME/build/emu" \
      -i "$app_dir/build/vdot-scale-m$lmul-b$blocks-r2-riscv64-xs.bin" \
      --diff="$NEMU_HOME/build/riscv64-nemu-interpreter-so" \
      --max-cycles=2000000 > "$logs/scale-$name-difftest.log" 2>&1
    python3 "$app_dir/analyze.py" "$logs/scale-$name-difftest.log" --out-dir "$results" \
      > "$logs/scale-$name-results.log"
    cat "$logs/scale-$name-results.log"
done
