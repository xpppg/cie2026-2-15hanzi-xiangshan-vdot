# 单条 vadd.vv 测试

用于观察香山向量指令的执行过程。测试数据和流程参考
[XiangShanLab 的 vadd.vv.S](https://github.com/OpenXiangShan/XiangShanLab/blob/master/xiangshan-course/docs/3-riscv-specification/riscv-xs-unified-db/tests/isa/rv64uv/vadd.vv.S)，
改为使用 nexus-am 启动代码和 klib，不依赖 riscv_test.h/test_macros.h。

## 测试流程

`main.c` 只调用一次 `vadd_once`。`vadd.S` 启用 mstatus.VS，清零 vstart、vcsr，
设置 SEW=8、LMUL=1、VL=2，加载 v2、v3 后，执行一次：

```asm
vadd_target:
    vadd.vv v4, v2, v3
```

然后用 `vse8.v` 存回两个元素。C 程序检查实际 VL、两个加法结果和未被写入的
两个哨兵字节。这里不检查向量寄存器的 tail 元素。

| 数据 | byte 0 | byte 1 |
| --- | --- | --- |
| 输入 a | 0x2c | 0x2d |
| 输入 b | 0x23 | 0x25 |
| 预期结果 | 0x4f | 0x52 |

通过时输出 `PASS: VL=2, result=4f 52 ff ff`，返回 0，仿真显示 `HIT GOOD TRAP`。
失败时打印实际结果并返回 1。

## 编译

先在 xs-env 根目录加载环境，然后进入本目录：

```bash
source ./env.sh
cd "$AM_HOME/apps/vadd"
make ARCH=riscv64-xs
make ARCH=riscv64-xs disasm
```

默认 C/AM 代码使用当前项目的 GCC 和 `rv64gc`；只有 `vadd.S` 使用 Clang 19
的 RISC-V RVV 汇编器，指定 `rv64gcv`、`lp64d`。无需用旧 GCC 汇编向量指令，
也无需重新编译香山仿真器。工具默认位于 `/usr/local/llvm/bin`，可覆盖：

```bash
make ARCH=riscv64-xs disasm \
  RVV_CLANG=/path/to/clang RVV_OBJDUMP=/path/to/llvm-objdump
```

产物位于 `build/`：

- `vadd-riscv64-xs.bin`：运行镜像。
- `vadd-riscv64-xs.elf`：包含符号及调试信息。
- `vadd-riscv64-xs.rvv.txt`：LLVM 反汇编，可以识别 RVV 指令。

在 `.rvv.txt` 中搜索 `<vadd_target>`，即可找到目标指令的 PC；程序也会打印该地址。
本次验证得到 `0x800001f8`，修改程序或构建选项后应重新查询。

## 运行及记录波形

```bash
cd "$NOOP_HOME"
set -o pipefail
./build/emu -i "$AM_HOME/apps/vadd/build/vadd-riscv64-xs.bin" \
  --no-diff -b 0 -e 0 -C 2000000 2>&1 | tee "$AM_HOME/apps/vadd/build/run.log"
```

这里 `-e 0` 关闭后续周期的调试日志，`-C` 限制最长运行周期，防止测试异常时无限运行。
这是 RTL 功能测试，没有启用 NEMU 差分验证。

已经用 `EMU_TRACE=1` 构建仿真器时，可以记录 VCD 波形：

```bash
./build/emu -i "$AM_HOME/apps/vadd/build/vadd-riscv64-xs.bin" \
  --no-diff --dump-wave --wave-path="$AM_HOME/apps/vadd/build/vadd.vcd" \
  -C 2000000 > "$AM_HOME/apps/vadd/build/wave-run.log" 2>&1
```

波形可能较大；确定目标指令出现的周期后，可用 `-b 起始周期 -e 结束周期`
缩小记录范围。不要在记录波形时沿用上一个命令的 `-e 0`。

先通过目标 PC 在译码入口定位指令，再沿重命名、分发、发射、执行、写回及 ROB 提交
跟踪它。后续阶段可能需要通过 ROB 索引或物理寄存器号关联，不能仅依赖 PC。

## 已验证

当前 ARM64 主机、Clang 19、GCC 9.4、现有 MinimalConfig 仿真器下：
编译成功；反汇编中只有一条 `vadd.vv v4, v2, v3`；RTL 仿真输出 PASS 和 GOOD TRAP。
尚未记录和分析波形，也未进行 NEMU 差分验证。
