#!/usr/bin/env python3
"""Compare total RTL cycles for a complete batch dot-product workload."""
import argparse
import csv
import json
import re
from pathlib import Path
from statistics import median


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('log', type=Path)
    parser.add_argument('--out-dir', type=Path, default=Path('build'))
    args = parser.parse_args()
    log = args.log.read_text()
    if 'Difftest enabled.' not in log:
        parser.error('需要开启 NEMU 差分的日志')
    if 'HIT GOOD TRAP' not in log:
        parser.error('日志中未找到正常结束标志')
    if re.search(r'\b(?:FAIL|ABORT|HIT BAD TRAP)\b', log):
        parser.error('日志含失败记录')
    headers = re.findall(r'SCALE lmul=(\d+) blocks=(\d+) repeats=(\d+) samples=(\d+) elements=(\d+) seed=(\d+)', log)
    if len(headers) != 1:
        parser.error('需要一条明确的测试规模记录')
    lmul, blocks, repeats, samples, elements, seed = map(int, headers[0])
    if min(blocks, repeats) < 1 or samples != 3 or lmul not in (2, 4, 8) or elements != 16 * lmul:
        parser.error('测试规模与 LMUL 或三轮测量设置不一致')
    checks = blocks * (2 + samples * 2)
    if f'PASS: vdot-scale {checks} full-vector checks' not in log:
        parser.error('日志中未找到完整的结果检查记录')
    dots_per_run = blocks * repeats
    raw = re.findall(r'WORKLOAD_RESULT mode=(\d+) sample=(\d+) dots=(\d+) cycles=(\d+)', log)
    groups = {0: {}, 1: {}}
    rows = []
    for item in raw:
        mode, sample, dots, cycles = map(int, item)
        if mode not in groups or sample in groups[mode] or dots != dots_per_run or cycles <= 0:
            parser.error('测量记录错误或重复')
        groups[mode][sample] = cycles
        rows.append(('baseline' if mode == 0 else 'vdot', sample, dots, cycles))
    if any(set(g) != set(range(samples)) for g in groups.values()):
        parser.error('需要两种实现、每种三次完整程序测量')
    summary = {'lmul': lmul, 'blocks': blocks, 'repeats': repeats, 'dots_per_run': dots_per_run,
               'elements_per_dot': elements, 'int8_products_per_run': dots_per_run * elements,
               'samples': samples, 'seed': seed, 'full_vector_checks': checks,
               'working_set_bytes': blocks * (elements * 2 + 16), 'logical_bytes_per_run': dots_per_run * (elements * 2 + 16),
               'difftest_enabled': 'Difftest enabled.' in log}
    for mode, name in ((0, 'baseline'), (1, 'vdot')):
        cycles = [groups[mode][s] for s in range(samples)]
        summary[name] = {'total_cycles': cycles, 'median_total_cycles': median(cycles),
                         'min_total_cycles': min(cycles), 'max_total_cycles': max(cycles)}
    base = summary['baseline']['median_total_cycles']
    dot = summary['vdot']['median_total_cycles']
    summary['program_speedup'] = base / dot
    summary['cycle_reduction_percent'] = (base - dot) * 100 / base
    args.out_dir.mkdir(parents=True, exist_ok=True)
    with (args.out_dir / 'performance-samples.csv').open('w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(('implementation', 'sample', 'dots', 'total_cycles'))
        writer.writerows(rows)
    (args.out_dir / 'performance-summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print('| 轮次 | Baseline 总周期 | vdot 总周期 |')
    print('|---:|---:|---:|')
    for s in range(samples):
        print(f'| {s + 1} | {groups[0][s]} | {groups[1][s]} |')
    print(f'| 中位数 | {base} | {dot} |')
    print(f"批量程序加速比：{summary['program_speedup']:.3f}×")
    print(f"总周期减少：{summary['cycle_reduction_percent']:.2f}%")


if __name__ == '__main__':
    main()
