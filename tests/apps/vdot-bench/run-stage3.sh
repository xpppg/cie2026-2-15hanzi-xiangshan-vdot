#!/usr/bin/env bash
set -euo pipefail

bench_app_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bench_root=$(cd "$bench_app_dir/../../.." && pwd)
source "$bench_root/env.sh"
bench_logs="$bench_root/vdot-docs/logs"
bench_results="$bench_root/vdot-docs/stage3"
mkdir -p "$bench_logs" "$bench_results"

# Reuse the current RTL simulator and updated reference model.
test -x "$NOOP_HOME/build/emu"
test -f "$NEMU_HOME/build/riscv64-nemu-interpreter-so"
make -C "$bench_app_dir" ARCH=riscv64-xs disasm > "$bench_logs/vdot-bench-app-build.log" 2>&1
"$NOOP_HOME/build/emu" \
  -i "$bench_app_dir/build/vdot-bench-riscv64-xs.bin" \
  --diff="$NEMU_HOME/build/riscv64-nemu-interpreter-so" \
  --max-cycles=300000 > "$bench_logs/vdot-bench-difftest.log" 2>&1
python3 "$bench_app_dir/analyze.py" "$bench_logs/vdot-bench-difftest.log" --out-dir "$bench_results"
