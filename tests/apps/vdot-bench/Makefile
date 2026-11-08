NAME = vdot-bench
SRCS = main.c kernels.S
ARCH ?= riscv64-xs
MARCH ?= rv64gc
RVV_CLANG ?= /usr/local/llvm/bin/clang
RVV_OBJDUMP ?= /usr/local/llvm/bin/llvm-objdump

include $(AM_HOME)/Makefile.app

$(DST_DIR)/kernels.o: kernels.S
	@mkdir -p $(dir $@)
	@echo + AS-RVV $<
	@$(RVV_CLANG) --target=riscv64-unknown-linux-gnu -march=rv64gcv \
		-mabi=lp64d -mcmodel=medany -mno-relax -g -c $< -o $@

.PHONY: disasm
disasm: image
	$(RVV_OBJDUMP) -d $(BINARY).elf > $(BINARY).rvv.txt
