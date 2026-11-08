# cie-vdot

基于香山昆明湖 V2 的自定义向量点积指令 `vdot.vv` 项目，保存设计说明、实现补丁、测试源码及验证日志。

## 核心功能

- 计算两个向量寄存器组中前 `vl` 个有符号 INT8 元素的点积。
- 在 VLEN=128 的实现中，结果写入目标寄存器低 32 位，高 96 位清零；`vl=0` 时保留目标原值。
- 复用现有 VIMAC 乘法通路，支持合法 LMUL 配置；要求 `SEW=8`、无掩码、`vstart=0`。
- 扩展 NEMU 参考模型，用于 RTL 与 NEMU 的差分验证。

## 目录说明

| 目录 | 内容 |
|---|---|
| `docs/第一阶段/` | 开发环境部署与向量加法执行分析 |
| `docs/第二阶段/` | 点积指令设计与基础测试说明 |
| `docs/第三阶段/` | 协同仿真和性能分析 |
| `patches/` | XiangShan、yunsuan 和 NEMU 实现补丁 |
| `tests/apps/` | 功能测试、向量指令回归及性能基准程序 |
| `tests/rtl/` | VDotCsrTest 硬件模块测试 |
| `logs/` | 构建、功能验证与性能测试日志 |

## 使用方式

本仓库为项目资料与补丁集合，运行测试需另行准备 [XiangShanLab](https://github.com/OpenXiangShan/XiangShanLab.git)，以及配套的 RISC-V 工具链、JDK 和仿真环境。

1. 按 [补丁说明](patches/README.md) 应用补丁。
2. 将 `tests/apps/` 下的应用放入 `nexus-am/apps/`，将 `tests/rtl/src/test/` 下的测试放入 XiangShan 对应目录。
3. 配置 `AM_HOME`、`NOOP_HOME`、`NEMU_HOME`，按测试文档构建参考模型和仿真器。例如，构建基础测试应用：

   ```bash
   make -C "$AM_HOME/apps/vdot-csr" ARCH=riscv64-xs BASIC=1 disasm
   ```

完整运行步骤见 [基础测试文档](docs/第二阶段/基础测试文档.md) 和 [协同仿真和性能分析](docs/第三阶段/协同仿真和性能分析文档.md)。迁移后需要相应调整环境。

## 实验测量结果

- 基础差分测试 6 项通过；VIMAC 回归、向量加法及两项硬件模块测试通过。
- 已完成的批量性能测试中，LMUL=1、6 KiB 工作负载相对 RVV 组合指令基线加速约 **2.566 倍**；LMUL=2/4/8 的对应测试约为 **1.39～1.44 倍**。
