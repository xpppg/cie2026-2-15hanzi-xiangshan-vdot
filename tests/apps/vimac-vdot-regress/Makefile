NAME = vimac-vdot-regress
SRCS = main.c vimac.S
ARCH ?= riscv64-xs
MARCH ?= rv64gc
RVV_CLANG ?= /usr/local/llvm/bin/clang
RVV_OBJDUMP ?= /usr/local/llvm/bin/llvm-objdump

include $(AM_HOME)/Makefile.app

build/cases.h: gen_cases.py
	@mkdir -p build
	python3 $< > $@

$(DST_DIR)/main.o: build/cases.h

$(DST_DIR)/vimac.o: vimac.S
	@mkdir -p $(dir $@)
	$(RVV_CLANG) --target=riscv64-unknown-linux-gnu -march=rv64gcv \
		-mabi=lp64d -mcmodel=medany -mno-relax -g -c $< -o $@

.PHONY: disasm
disasm: image
	$(RVV_OBJDUMP) -d $(BINARY).elf > $(BINARY).rvv.txt
