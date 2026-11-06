NAME = vadd
SRCS = main.c vadd.S
ARCH ?= riscv64-xs

# Keep the AM runtime compatible with the installed GCC; only vadd.S needs RVV.
MARCH ?= rv64gc
RVV_CLANG ?= /usr/local/llvm/bin/clang
RVV_OBJDUMP ?= /usr/local/llvm/bin/llvm-objdump

include $(AM_HOME)/Makefile.app

$(DST_DIR)/vadd.o: vadd.S
	@mkdir -p $(dir $@)
	@echo + AS-RVV $<
	@$(RVV_CLANG) --target=riscv64-unknown-linux-gnu -march=rv64gcv \
		-mabi=lp64d -mcmodel=medany -mno-relax -g -c $< -o $@

.PHONY: disasm
disasm: image
	$(RVV_OBJDUMP) -d $(BINARY).elf > $(BINARY).rvv.txt
	@echo "RVV disassembly: $(BINARY).rvv.txt (search for <vadd_target>)"
