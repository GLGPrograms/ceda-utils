.POSIX:

include config.mk

.PHONY: all
all: utils-cpm utils-bin

.PHONY: utils-cpm
utils-cpm:
	make -f cpm/Makefile

.PHONY: utils-bin
utils-bin:
	make -f bin/Makefile

.PHONY: clean
clean:
	rm -rf $(OUTDIR)

