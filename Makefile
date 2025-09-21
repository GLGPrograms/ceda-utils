.POSIX:

include config.mk

.PHONY: all
all: utils-cpm utils-bin bootloader-rom

.PHONY: utils-cpm
utils-cpm:
	make -f cpm/Makefile

.PHONY: utils-bin
utils-bin:
	make -f bin/Makefile

.PHONY: bootloader-rom
bootloader-rom:
	make -f bootloader/Makefile

.PHONY: clean
clean:
	rm -rf $(OUTDIR)

