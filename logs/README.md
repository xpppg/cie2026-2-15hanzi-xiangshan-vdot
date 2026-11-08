# 测试与构建日志

测试源码见 [tests](../tests/README.md)。日志的来源和 SHA256 见 [manifest.json](manifest.json)。

## 1. 功能测试

| 日志 | 内容与结果 |
|---|---|
| [vdot-basic-difftest.log](vdot-basic-difftest.log) | NEMU 与 RTL 基础差分，6 项通过，HIT GOOD TRAP |
| [vimac-regression.log](vimac-regression.log) | VIMAC 62 项功能及 6 个交错结果通过，HIT GOOD TRAP |
| [vadd.log](vadd.log) | 向量加法通过，HIT GOOD TRAP |
| [module-test.log](module-test.log) | 运算通路和译码拆分两项模块测试通过 |

基础差分的版本和结果见 [basic-difftest-results.json](basic-difftest-results.json)。VIMAC 和向量加法使用 `--no-diff`，模块测试使用 Verilator。

## 2. 性能测试

| 测试 | 运行日志 | 周期统计 | 结果 |
|---|---|---|---|
| LMUL=1，6 KiB | [vdot-bench-difftest.log](vdot-bench-difftest.log) | [vdot-bench-run.log](vdot-bench-run.log) | 1024 个向量结果检查通过，加速 2.566 倍 |
| LMUL=2，5 KiB | [scale-m2-difftest.log](scale-m2-difftest.log) | [scale-m2-results.log](scale-m2-results.log) | 512 个向量结果检查通过，加速 1.439 倍 |
| LMUL=4，9 KiB | [scale-m4-difftest.log](scale-m4-difftest.log) | [scale-m4-results.log](scale-m4-results.log) | 512 个向量结果检查通过，加速 1.393 倍 |
| LMUL=8，17 KiB | [scale-m8-difftest.log](scale-m8-difftest.log) | [scale-m8-results.log](scale-m8-results.log) | 512 个向量结果检查通过，加速 1.424 倍 |
| LMUL=8，136 KiB | [scale-large-difftest.log](scale-large-difftest.log) | [scale-large-results.log](scale-large-results.log) | 4096 个向量结果检查通过，加速 1.468 倍 |

各项性能测试均开启 NEMU 差分。测试方法及分析见 [协同仿真和性能分析文档](../协同仿真和性能分析文档.md)，原始周期样本和版本记录保存在 `stage3`。

[vdot-bench-baseline5-difftest.log](vdot-bench-baseline5-difftest.log) 为循环内清零目标的初次测量，具体记录见 [baseline5](../stage3/baseline5/README.md)。

## 3. 构建日志

| 日志 | 内容 |
|---|---|
| [emu-build.log](emu-build.log) | 香山仿真器构建 |
| [nemu-config.log](nemu-config.log) | NEMU 专用配置 |
| [nemu-build.log](nemu-build.log) | NEMU 构建 |
| [vdot-basic-app-build.log](vdot-basic-app-build.log) | BASIC=1 应用构建 |
| [vdot-bench-app-build.log](vdot-bench-app-build.log) | LMUL=1 批量应用构建 |
| [scale-m2-build.log](scale-m2-build.log) | LMUL=2 应用构建 |
| [scale-m4-build.log](scale-m4-build.log) | LMUL=4 应用构建 |
| [scale-m8-build.log](scale-m8-build.log) | LMUL=8 应用构建 |
| [scale-large-build.log](scale-large-build.log) | 136 KiB 应用构建 |
| [vdot-app-build.log](vdot-app-build.log) | 点积应用构建 |
| [vdot-extended-app-build.log](vdot-extended-app-build.log) | 扩展点积应用构建 |
| [vimac-app-build.log](vimac-app-build.log) | VIMAC 回归应用构建 |
| [vadd-app-build.log](vadd-app-build.log) | 向量加法应用构建 |

## 4. 中止记录

| 日志 | 完成情况 |
|---|---|
| [vdot-csr.log](vdot-csr.log) | 基础 6 项输出 PASS，212 项套件在补充阶段停止 |
| [vdot-extended-partial.log](vdot-extended-partial.log) | 基础 6 项输出 PASS，扩展遍历随后停止 |

中止时的状态见 [test-results.json](test-results.json)。
