# vdot 源码补丁

## 第二阶段

### src源码修改

[xiangshan-vdot.patch](xiangshan-vdot.patch) 包含 12 个 Scala 实现文件：香山的 9 个文件和 yunsuan 的 3 个文件。内容包括点积译码、按 LMUL 拆分微操作、按 vl 归约 INT8 乘积、跨组部分和、零长度目标保留、异常检查，以及底层点积操作码和完整乘积输出。不包含测试代码。

基准版本：

- XiangShan：`16ae9ddcda54fc9a2fddffad73174cf793ac7814`
- XiangShan/yunsuan：`cadd3c2f43096e253d61296b33ac697be8354e29`

先初始化 yunsuan 子模块，然后在香山根目录一次应用：

```bash
cd /path/to/xs-env/XiangShan
git submodule update --init yunsuan
git apply --check ../vdot-docs/patches/xiangshan-vdot.patch
git apply ../vdot-docs/patches/xiangshan-vdot.patch
```

补丁中的运算库路径以 `yunsuan/` 开头。使用上述工作区应用方式；不要添加 `--index` 或 `--cached`，因为父仓库索引仅跟踪 yunsuan 子模块提交，不跟踪其内部文件。后续提交时，yunsuan 的改动仍需在子模块中单独提交。

当前工作区已有这些改动，无需重复应用。合并补丁已在基准文件副本中通过应用与反向检查，应用后的 12 个文件与当前源码一致。环境工具和编辑器改动不包含在补丁中。

## 测试代码

测试代码在apps下。

香山源码编译和 `VDotCsrTest` 两项硬件模块测试已通过。测试覆盖全部合法 LMUL 及各自全部合法 `vl`、INT8 极值、零长度目标保留、点积与普通乘法连续发射、微操作拆分及非法配置检查。

```bash
cd /path/to/xs-env/XiangShan
mill -i xiangshan.test.testOnly xiangshan.backend.fu.vector.VDotCsrTest
```

测试需使用项目所需的 JDK 和 firtool 环境。见 [本轮测试日志](../logs/module-test.log)。当前整机 `build/emu` 已按此版本重建，已完成的整机结果及中止情况见 [基础测试文档](../基础测试文档.md)。

## 第三阶段

## NEMU

[nemu-vdot.patch](nemu-vdot.patch) 基于 NEMU 提交 `2ec110b618bb8f08cf0b54ca3d9cbb0f210f895d`，包含指令扩展、启动镜像传递接口、专用配置及其 Git 跟踪规则，共 6 个文件。该补丁已按当前指令语义更新：根据 `vl` 读取 INT8 源寄存器组，支持合法 LMUL 并检查源组对齐；非零 `vstart` 及非法配置触发非法指令异常；`vl=0` 保留目标，正常写回时高 96 位清零，保持 `vxrm/vxsat`。补丁不包含测试代码。

```bash
cd /path/to/xs-env/NEMU
git apply --check ../vdot-docs/patches/nemu-vdot.patch
git apply ../vdot-docs/patches/nemu-vdot.patch
make riscv64-xs-vdot-ref_defconfig
make -j16
```

专用配置将 `NMIE_INIT` 设为开启、`MDT_INIT` 设为关闭，与当前香山复位状态一致。当前工作区已应用这些改动。

NEMU 更新后，本轮仅运行 6 项基础差分测试，全部通过并触发 `HIT GOOD TRAP`。复现时使用 `make ARCH=riscv64-xs BASIC=1 disasm`，运行生成的 `vdot-basic-riscv64-xs.bin`。结果见 [协同仿真和性能分析](../协同仿真和性能分析文档.md)和 [差分日志](../logs/vdot-basic-difftest.log)。零长度、重叠及非法配置等补充差分测试本轮未运行。
