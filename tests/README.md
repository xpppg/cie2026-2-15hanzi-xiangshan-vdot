# 测试代码

本目录保存测试源码及构建、运行、数据分析脚本。

| 目录 | 用途 | 测试说明 |
|---|---|---|
| [apps/vdot-csr](apps/vdot-csr) | 正数、负数、边界值及 CSR 检查，基础模式为 `BASIC=1` | [基础测试文档](../基础测试文档.md) |
| [apps/vdot-bench](apps/vdot-bench) | LMUL=1、6 KiB 批量性能测试 | [协同仿真和性能分析](../协同仿真和性能分析文档.md#4-现有-rvv-指令基线) |
| [apps/vdot-scale-bench](apps/vdot-scale-bench) | LMUL=2、4、8 和 136 KiB 数据集性能测试 | [协同仿真和性能分析](../协同仿真和性能分析文档.md#7-lmul-与大数据集测试) |
| [apps/vimac-vdot-regress](apps/vimac-vdot-regress) | 共享 VIMAC 功能及交错执行回归 | [基础测试文档](../基础测试文档.md#31-共享-vimac-回归及原有向量加法) |
| [apps/vadd](apps/vadd) | 原有向量加法回归 | [基础测试文档](../基础测试文档.md#31-共享-vimac-回归及原有向量加法) |
| [rtl](rtl) | VDotCsrTest 运算通路和译码拆分测试 | [基础测试文档](../基础测试文档.md#32-模块级-rtl-测试) |

应用源码来自 `nexus-am/apps`，模块测试来自 `XiangShan/src/test`。运行时按原工程目录放置文件，并执行测试文档中的命令。`vimac-vdot-regress` 的用例头文件由 `gen_cases.py` 在构建时生成。
