LMUL ?= 2
BLOCKS ?= 64
REPEATS ?= 2
CASE ?= m$(LMUL)-b$(BLOCKS)-r$(REPEATS)
NAME = vdot-scale-$(CASE)
SRCS = main.c kernels.S
ARCH ?= riscv64-xs
MARCH ?= rv64gc
RVV_CLANG ?= /usr/local/llvm/bin/clang
RVV_OBJDUMP ?= /usr/local/llvm/bin/llvm-objdump
DST_DIR = $(CURDIR)/build/$(CASE)/$(ARCH)/
CFLAGS += -DBENCH_LMUL=$(LMUL) -DBLOCKS=$(BLOCKS) -DREPEATS=$(REPEATS)
include $(AM_HOME)/Makefile.app

$(DST_DIR)/kernels.o: kernels.S
	@mkdir -p $(dir $@)
	@$(RVV_CLANG) --target=riscv64-unknown-linux-gnu -march=rv64gcv \
	  -mabi=lp64d -mcmodel=medany -mno-relax -DBENCH_LMUL=$(LMUL) -g -c $< -o $@

.PHONY: disasm
disasm: image
	$(RVV_OBJDUMP) -d $(BINARY).elf > $(BINARY).rvv.txt
