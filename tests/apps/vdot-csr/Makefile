NAME = vdot-csr
SRCS = main.c vdot.S
ARCH ?= riscv64-xs
MARCH ?= rv64gc
RVV_CLANG ?= /usr/local/llvm/bin/clang
RVV_OBJDUMP ?= /usr/local/llvm/bin/llvm-objdump

ifeq ($(BASIC),1)
ifeq ($(EXTENDED),1)
$(error BASIC=1 and EXTENDED=1 cannot be used together)
endif
NAME = vdot-basic
DST_DIR = $(CURDIR)/build/basic/$(ARCH)/
CFLAGS += -DVDOT_BASIC_ONLY
endif

ifeq ($(EXTENDED),1)
NAME = vdot-csr-extended
DST_DIR = $(CURDIR)/build/extended/$(ARCH)/
CFLAGS += -DVDOT_EXTENDED
endif

include $(AM_HOME)/Makefile.app

$(DST_DIR)/vdot.o: vdot.S
	@mkdir -p $(dir $@)
	@echo + AS-RVV $<
	@$(RVV_CLANG) --target=riscv64-unknown-linux-gnu -march=rv64gcv \
		-mabi=lp64d -mcmodel=medany -mno-relax -g -c $< -o $@

.PHONY: disasm
disasm: image
	$(RVV_OBJDUMP) -d $(BINARY).elf > $(BINARY).rvv.txt
